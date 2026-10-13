``` r
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
#> machine TZ = America/New_York
probe("session as opened (UTC), tz_out=UTC", "UTC", NULL)
#> session as opened (UTC), tz_out=UTC      naive ok    (label UTC             ) | tz ok    (label UTC)
probe("session as opened (UTC), tz_out=NY", "America/New_York", NULL)
#> session as opened (UTC), tz_out=NY       naive ok    (label America/New_York) | tz ok    (label UTC)
probe(
  "session set to timezone_out, tz_out=NY",
  "America/New_York",
  "America/New_York"
)
#> session set to timezone_out, tz_out=NY   naive MOVED (label America/New_York) | tz ok    (label America/New_York)
probe("session set to the machine zone, tz_out=UTC", "UTC", "America/New_York")
#> session set to the machine zone, tz_out=UTC naive MOVED (label UTC             ) | tz ok    (label America/New_York)
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
#>  tz       America/New_York
#>  date     2026-09-26
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9026 2026-09-26 [1] local
#>  evaluate      1.0.5      2025-08-27 [1] RSPM
#>  fastmap       1.2.0      2024-05-15 [1] RSPM
#>  fs            2.1.0      2026-04-18 [1] RSPM
#>  glue          1.8.1      2026-04-17 [1] RSPM
#>  htmltools     0.5.9      2025-12-04 [1] RSPM
#>  knitr         1.52       2026-09-06 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.32       2026-09-01 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  withr         3.0.3      2026-06-19 [1] RSPM
#>  xfun          0.60       2026-07-09 [1] RSPM
#>  yaml          2.3.12     2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
