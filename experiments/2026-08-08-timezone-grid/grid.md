``` r
# Timestamp labeling grid: local zone x timezone_out x tz_out_convert
# x session TimeZone, for TIMESTAMP and TIMESTAMPTZ.
# Values: TIMESTAMP '2024-01-10 13:03:12' (naive),
#         TIMESTAMPTZ '2024-01-10 13:03:12-08:00' (= 21:03:12 UTC).
# The recorded run is grid.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
#> Loading required package: DBI
options(duckdb.storage_message = FALSE)
options(width = 300)

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
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
rownames(out) <- NULL

cat(
  "duckdb", as.character(packageVersion("duckdb")),
  "| DuckDB", duckdb:::get_duckdb_version(),
  "| vendored build, icu from the extension store\n"
)
#> duckdb 1.5.5.9010 | DuckDB 1.5.5 | vendored build, icu from the extension store
print(out, right = FALSE)
#>    local          tz_out         conv  session ts_label       ts_epoch   ts_clock tstz_label          tstz_epoch tstz_clock
#> 1  UTC            UTC            with  none    UTC            1704891792 13:03:12 UTC                 1704920592 21:03:12  
#> 2  Pacific/Tahiti UTC            with  none    UTC            1704891792 13:03:12 UTC                 1704920592 21:03:12  
#> 3  UTC            Pacific/Tahiti with  none    Pacific/Tahiti 1704891792 03:03:12 UTC                 1704920592 21:03:12  
#> 4  Pacific/Tahiti Pacific/Tahiti with  none    Pacific/Tahiti 1704891792 03:03:12 UTC                 1704920592 21:03:12  
#> 5  UTC                           with  none    <none>         1704891792 13:03:12 UTC                 1704920592 21:03:12  
#> 6  Pacific/Tahiti                with  none    <none>         1704891792 03:03:12 UTC                 1704920592 21:03:12  
#> 7  UTC            UTC            force none    UTC            1704891792 13:03:12 UTC                 1704920592 21:03:12  
#> 8  Pacific/Tahiti UTC            force none    UTC            1704891792 13:03:12 UTC                 1704920592 21:03:12  
#> 9  UTC            Pacific/Tahiti force none    Pacific/Tahiti 1704927792 13:03:12 Pacific/Tahiti      1704956592 21:03:12  
#> 10 Pacific/Tahiti Pacific/Tahiti force none    Pacific/Tahiti 1704927792 13:03:12 Pacific/Tahiti      1704956592 21:03:12  
#> 11 UTC                           force none                   1704891792 13:03:12                     1704920592 21:03:12  
#> 12 Pacific/Tahiti                force none                   1704927792 13:03:12                     1704956592 21:03:12  
#> 13 UTC            UTC            with  LA      UTC            1704891792 13:03:12 America/Los_Angeles 1704920592 13:03:12  
#> 14 Pacific/Tahiti UTC            with  LA      UTC            1704891792 13:03:12 America/Los_Angeles 1704920592 13:03:12  
#> 15 UTC            Pacific/Tahiti with  LA      Pacific/Tahiti 1704891792 03:03:12 America/Los_Angeles 1704920592 13:03:12  
#> 16 Pacific/Tahiti Pacific/Tahiti with  LA      Pacific/Tahiti 1704891792 03:03:12 America/Los_Angeles 1704920592 13:03:12  
#> 17 UTC                           with  LA      <none>         1704891792 13:03:12 America/Los_Angeles 1704920592 13:03:12  
#> 18 Pacific/Tahiti                with  LA      <none>         1704891792 03:03:12 America/Los_Angeles 1704920592 13:03:12  
#> 19 UTC            UTC            force LA      UTC            1704891792 13:03:12 UTC                 1704920592 21:03:12  
#> 20 Pacific/Tahiti UTC            force LA      UTC            1704891792 13:03:12 UTC                 1704920592 21:03:12  
#> 21 UTC            Pacific/Tahiti force LA      Pacific/Tahiti 1704927792 13:03:12 Pacific/Tahiti      1704956592 21:03:12  
#> 22 Pacific/Tahiti Pacific/Tahiti force LA      Pacific/Tahiti 1704927792 13:03:12 Pacific/Tahiti      1704956592 21:03:12  
#> 23 UTC                           force LA                     1704891792 13:03:12                     1704920592 21:03:12  
#> 24 Pacific/Tahiti                force LA                     1704927792 13:03:12                     1704956592 21:03:12
```

<sup>Created on 2026-08-08 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-08-08
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9010 2026-08-07 [1] local
#>  evaluate      1.0.5      2025-08-27 [1] RSPM
#>  fastmap       1.2.0      2024-05-15 [1] RSPM
#>  fs            2.1.0      2026-04-18 [1] RSPM
#>  glue          1.8.1      2026-04-17 [1] RSPM
#>  htmltools     0.5.9      2025-12-04 [1] RSPM
#>  knitr         1.51       2025-12-20 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.31       2026-03-26 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  withr         3.0.3      2026-06-19 [1] RSPM
#>  xfun          0.60       2026-07-09 [1] RSPM
#>  yaml          2.3.12     2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

</details>
