# What the session TimeZone is when nobody sets it.
#
# The grid sets it in every cell, so this is the missing half: which of those
# rows a user lands in by default. ICU reads the zone once when it loads, so
# each machine zone needs its own process; run.sh supplies TZ.
suppressMessages(library(duckdb))

con <- suppressMessages(dbConnect(duckdb()))
session <- dbGetQuery(con, "SELECT current_setting('TimeZone') AS tz")$tz
res <- dbGetQuery(
  con,
  "SELECT TIMESTAMP '2024-01-10 13:03:12' AS ts,
          TIMESTAMPTZ '2024-01-10 13:03:12-08:00' AS tstz"
)
cat(sprintf(
  "TZ=%-18s session %-18s ts label %-8s tstz label %s\n",
  Sys.getenv("TZ"),
  session,
  attr(res$ts, "tzone"),
  attr(res$tstz, "tzone")
))
dbDisconnect(con, shutdown = TRUE)
