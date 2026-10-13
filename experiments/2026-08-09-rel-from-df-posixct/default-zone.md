``` r
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
#> TZ=UTC                session UTC                ts label UTC      tstz label UTC
#> TZ=Etc/UTC            session Etc/UTC            ts label UTC      tstz label Etc/UTC
#> TZ=Europe/Zurich      session Europe/Zurich      ts label UTC      tstz label Europe/Zurich
#> TZ=America/New_York   session America/New_York   ts label UTC      tstz label America/New_York
#> TZ=Asia/Tokyo         session Asia/Tokyo         ts label UTC      tstz label Asia/Tokyo
```

<sup>Created on 2026-09-26 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-09-26
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version date (UTC) lib source
#>  cli           3.6.6   2026-04-09 [1] RSPM
#>  digest        0.6.39  2025-11-19 [1] RSPM
#>  evaluate      1.0.5   2025-08-27 [1] RSPM
#>  fastmap       1.2.0   2024-05-15 [1] RSPM
#>  fs            2.1.0   2026-04-18 [1] RSPM
#>  glue          1.8.1   2026-04-17 [1] RSPM
#>  htmltools     0.5.9   2025-12-04 [1] RSPM
#>  knitr         1.52    2026-09-06 [1] RSPM
#>  lifecycle     1.0.5   2026-01-08 [1] RSPM
#>  otel          0.2.0   2025-08-29 [1] RSPM
#>  reprex        2.1.1   2024-07-06 [1] RSPM
#>  rlang         1.3.0   2026-07-05 [1] RSPM
#>  rmarkdown     2.32    2026-09-01 [1] RSPM
#>  sessioninfo   1.2.4   2026-06-04 [1] RSPM
#>  withr         3.0.3   2026-06-19 [1] RSPM
#>  xfun          0.60    2026-07-09 [1] RSPM
#>  yaml          2.3.12  2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
