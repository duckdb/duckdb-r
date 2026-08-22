# One policy's worth of the rel_from_df() POSIXct grid.
#
# For every (column tzone x timezone_out x session TimeZone) cell, hand the
# column to rel_from_df() and read it back with rel_to_altrep(), and record
# which of four things happened:
#
#   ok            accepted, and the data frame comes back unchanged
#   relabeled     accepted, same instant, different `tzone` -- the silent one
#   refused       the strict check rejected the column
#   wrong-instant accepted and the value moved (nothing should produce this)
#
# POLICY names the build; run.sh sets it. See README.md.
suppressMessages(library(duckdb))
options(width = 200)

rel_from_df <- duckdb:::rel_from_df
rel_to_altrep <- duckdb:::rel_to_altrep

policy <- Sys.getenv("POLICY", "shipped")

# One instant, four ways of labeling it in R. "absent" is what `Sys.time()`
# returns; "empty" is what `as.POSIXct()` leaves behind. Both mean "local".
INSTANT <- 1745781814.84963

make_col <- function(label) {
  switch(
    label,
    absent = structure(INSTANT, class = c("POSIXct", "POSIXt")),
    empty = structure(INSTANT, class = c("POSIXct", "POSIXt"), tzone = ""),
    structure(INSTANT, class = c("POSIXct", "POSIXt"), tzone = label)
  )
}

label_of <- function(x) {
  z <- attr(x, "tzone")
  if (is.null(z)) {
    "<absent>"
  } else if (!nzchar(z)) {
    "<empty>"
  } else {
    z
  }
}

cell <- function(col, tz_out, session) {
  df <- data.frame(a = make_col(col))
  # The storage-location notice is an `inform()`, not an option
  con <- suppressMessages(dbConnect(duckdb(), timezone_out = tz_out))
  on.exit(dbDisconnect(con, shutdown = TRUE))
  dbExecute(con, paste0("SET TimeZone = '", session, "'"))

  out <- tryCatch(rel_to_altrep(rel_from_df(con, df)), error = function(e) e)

  if (inherits(out, "error")) {
    verdict <- "refused"
    back <- NA_character_
  } else {
    back <- label_of(out$a)
    same_label <- identical(attr(out$a, "tzone"), attr(df$a, "tzone"))
    same_instant <- isTRUE(all.equal(as.numeric(out$a), INSTANT))
    verdict <- if (!same_instant) {
      "wrong-instant"
    } else if (same_label) {
      "ok"
    } else {
      "relabeled"
    }
  }

  data.frame(
    policy = policy,
    col = label_of(df$a),
    tz_out = if (nzchar(tz_out)) tz_out else "<empty>",
    session = session,
    verdict = verdict,
    back = back
  )
}

grid <- expand.grid(
  col = c("UTC", "empty", "absent", "America/New_York"),
  tz_out = c("UTC", "", "America/New_York"),
  session = c("UTC", "Etc/UTC", "America/New_York"),
  stringsAsFactors = FALSE
)

out <- do.call(rbind, Map(cell, grid$col, grid$tz_out, grid$session))
rownames(out) <- NULL

cat(
  "policy",
  policy,
  "| duckdb",
  as.character(packageVersion("duckdb")),
  "| DuckDB",
  duckdb:::get_duckdb_version(),
  "| local zone",
  Sys.timezone(),
  "\n\n"
)
print(out, right = FALSE)
cat("\ntally:\n")
print(table(out$verdict))
