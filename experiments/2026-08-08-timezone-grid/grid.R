# Timestamp labeling grid: local zone x timezone_out x tz_out_convert
# x session TimeZone, for TIMESTAMP and TIMESTAMPTZ.
# Values: TIMESTAMP '2024-01-10 13:03:12' (naive),
#         TIMESTAMPTZ '2024-01-10 13:03:12-08:00' (= 21:03:12 UTC).
# Writes output.txt next to this script.
library(duckdb)
options(duckdb.storage_message = FALSE)

cell <- function(local_tz, tz_out, tz_conv, session) {
  withr::with_timezone(local_tz, {
    drv <- if (session == "none") duckdb(allow_extensions = FALSE) else duckdb()
    con <- dbConnect(drv, timezone_out = tz_out, tz_out_convert = tz_conv)
    on.exit(dbDisconnect(con, shutdown = TRUE))
    if (session == "LA") {
      dbExecute(con, "INSTALL icu")
      dbExecute(con, "LOAD icu")
      dbExecute(con, "SET TimeZone = 'America/Los_Angeles'")
    }
    res <- dbGetQuery(con, "
      SELECT
        TIMESTAMP '2024-01-10 13:03:12' AS ts,
        TIMESTAMPTZ '2024-01-10 13:03:12-08:00' AS tstz
    ")
    fmt <- function(x) {
      tz <- attr(x, "tzone")
      data.frame(
        label = if (is.null(tz)) "<none>" else tz,
        epoch = as.numeric(x),
        clock = format(x, "%H:%M:%S")
      )
    }
    cbind(
      data.frame(local = local_tz, tz_out = tz_out, conv = tz_conv, session = session),
      setNames(fmt(res$ts), paste0("ts_", names(fmt(res$ts)))),
      setNames(fmt(res$tstz), paste0("tstz_", names(fmt(res$tstz))))
    )
  })
}

grid <- expand.grid(
  local_tz = c("UTC", "Pacific/Tahiti"),
  tz_out = c("UTC", "Pacific/Tahiti", ""),
  tz_conv = c("with", "force"),
  session = c("none", "LA"),
  stringsAsFactors = FALSE
)

out <- do.call(rbind, Map(cell, grid$local_tz, grid$tz_out, grid$tz_conv, grid$session))
rownames(out) <- NULL

sink(file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE))), "output.txt"))
cat("duckdb", as.character(packageVersion("duckdb")),
    "| DuckDB", duckdb:::get_duckdb_version(),
    "| vendored build, icu from the extension store |",
    format(Sys.Date()), "\n\n")
print(out, right = FALSE)
sink()
