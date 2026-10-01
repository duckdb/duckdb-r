# What the session TimeZone is when nobody sets it.
#
# The grid sets it in every cell, so this is the missing half: which of those
# rows a user lands in by default. icu reads the zone once when it loads, so
# each machine zone needs its own process, which is why this script spawns
# one per zone rather than looping in place.
ZONES <- c("UTC", "Etc/UTC", "Europe/Zurich", "America/New_York", "Asia/Tokyo")

report <- function() {
  suppressMessages(library(duckdb))
  con <- suppressMessages(dbConnect(duckdb()))
  on.exit(dbDisconnect(con, shutdown = TRUE))

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
}

if (nzchar(Sys.getenv("DUCKDB_R_ZONE_CHILD"))) {
  report()
} else {
  for (zone in ZONES) {
    cat(
      system2(
        "Rscript",
        "default-zone.R",
        env = c(paste0("TZ=", zone), "DUCKDB_R_ZONE_CHILD=1"),
        stdout = TRUE,
        stderr = TRUE
      ),
      sep = "\n"
    )
  }
}
