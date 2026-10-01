# Which zone the connect-time alignment has to name.
#
# defaults.md measured a pin set to `timezone_out`, which looked right and is
# not: under `tz_out_convert = "with"` the read side takes a naive wall clock
# as UTC whatever `timezone_out` says -- that setting only relabels. So the
# session has to be UTC for a naive column to round-trip, and naming
# `timezone_out` fixes nothing when it is not UTC.
#
# Each row overrides the session zone the connection starts on, so the rows
# differ only where the machine is not on UTC:
#   TZ=America/New_York Rscript pin-target.R
suppressMessages(library(duckdb))

INSTANT <- as.POSIXct("2024-01-10 13:03:12", tz = "UTC")

probe <- function(label, tz_out, session) {
  con <- suppressMessages(dbConnect(duckdb(), timezone_out = tz_out))
  on.exit(dbDisconnect(con, shutdown = TRUE))
  if (!is.null(session)) {
    dbExecute(con, paste0("SET TimeZone = '", session, "'"))
  }

  dbExecute(con, "CREATE TABLE t (naive TIMESTAMP, tz TIMESTAMPTZ)")
  dbAppendTable(con, "t", data.frame(naive = INSTANT, tz = INSTANT))
  back <- dbReadTable(con, "t")
  ok <- function(x) {
    if (identical(as.numeric(x), as.numeric(INSTANT))) "ok" else "MOVED"
  }

  cat(sprintf(
    "%-40s naive %-5s (label %-16s) | tz %-5s (label %s)\n",
    label,
    ok(back$naive),
    attr(back$naive, "tzone"),
    ok(back$tz),
    attr(back$tz, "tzone")
  ))
}

cat("machine TZ =", Sys.getenv("TZ"), "\n")
probe("session as opened (UTC), tz_out=UTC", "UTC", NULL)
probe("session as opened (UTC), tz_out=NY", "America/New_York", NULL)
probe(
  "session set to timezone_out, tz_out=NY",
  "America/New_York",
  "America/New_York"
)
probe("session set to the machine zone, tz_out=UTC", "UTC", "America/New_York")
