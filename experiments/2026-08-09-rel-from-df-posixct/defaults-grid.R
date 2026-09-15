# The same round trips, but with nobody calling `SET TimeZone`.
#
# grid.R sets the session zone in every cell, which is what a caller who
# knows about it would do. This is the other half: what the defaults do, and
# whether the answer moves with the machine's TZ. run.sh supplies TZ and
# POLICY; icu reads the zone once when it loads, so each TZ needs a process.
suppressMessages(library(duckdb))
options(width = 200)

rel_from_df <- duckdb:::rel_from_df
rel_to_altrep <- duckdb:::rel_to_altrep

policy <- Sys.getenv("POLICY", "shipped")
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

verdict_of <- function(out, df) {
  if (inherits(out, "error")) {
    return(c("refused", NA_character_))
  }
  same_label <- identical(attr(out$a, "tzone"), attr(df$a, "tzone"))
  same_instant <- isTRUE(all.equal(as.numeric(out$a), INSTANT))
  v <- if (!same_instant) {
    "wrong-instant"
  } else if (same_label) {
    "ok"
  } else {
    "relabeled"
  }
  c(v, label_of(out$a))
}

cell <- function(col, tz_out) {
  df <- data.frame(a = make_col(col))
  con <- suppressMessages(dbConnect(duckdb(), timezone_out = tz_out))
  on.exit(dbDisconnect(con, shutdown = TRUE))

  session <- dbGetQuery(con, "SELECT current_setting('TimeZone') AS tz")$tz
  rel <- verdict_of(
    tryCatch(rel_to_altrep(rel_from_df(con, df)), error = function(e) e),
    df
  )
  dbi <- verdict_of(
    tryCatch(
      {
        dbWriteTable(con, "t", df)
        dbReadTable(con, "t")
      },
      error = function(e) e
    ),
    df
  )

  data.frame(
    policy = policy,
    TZ = Sys.getenv("TZ"),
    col = label_of(df$a),
    tz_out = if (nzchar(tz_out)) tz_out else "<empty>",
    session = session,
    rel = rel[[1]],
    rel_back = rel[[2]],
    dbi = dbi[[1]],
    dbi_back = dbi[[2]]
  )
}

grid <- expand.grid(
  col = c("UTC", "empty", "absent", "America/New_York"),
  tz_out = c("UTC", "", "America/New_York"),
  stringsAsFactors = FALSE
)

out <- do.call(rbind, Map(cell, grid$col, grid$tz_out))
rownames(out) <- NULL
print(out, right = FALSE)
