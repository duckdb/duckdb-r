``` r
library(DBI)
packageVersion("duckdb")
#> [1] '1.3.2'

# The default connection is an in-memory database. The package points its
# temporary storage below tempdir(), away from the current working directory:
drv <- duckdb::duckdb()
con <- dbConnect(drv)
spill <- dbGetQuery(
  con,
  "SELECT current_setting('temp_directory') AS temp_directory"
)[[1]]
spill
#> [1] ".tmp"

# Any operation that outgrows memory_limit must offload to that directory:
# a ~460 MB sort under a 300 MB limit.
dbExecute(con, "SET memory_limit = '300MB'")
#> [1] 0
dbExecute(
  con,
  "CREATE TABLE big_sort AS SELECT hash(i) AS h, i FROM range(30000000) t(i) ORDER BY h"
)
#> [1] 3e+07
dbGetQuery(con, "SELECT count(*) AS n FROM big_sort")
#>       n
#> 1 3e+07

# The spill directory exists while the instance is live ...
dir.exists(spill)
#> [1] TRUE

dbDisconnect(con)
duckdb::duckdb_shutdown(drv)

# ... and the engine removes it again at instance shutdown.
dir.exists(spill)
#> [1] FALSE
```

<sup>Created on 2026-08-08 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

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
#>  date     2026-08-08
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version date (UTC) lib source
#>  cli           3.6.6   2026-04-09 [1] RSPM
#>  DBI         * 1.3.0   2026-02-25 [1] RSPM
#>  digest        0.6.39  2025-11-19 [1] RSPM
#>  duckdb        1.3.2   2025-07-09 [1] RSPM (R 4.5.0)
#>  evaluate      1.0.5   2025-08-27 [1] RSPM
#>  fastmap       1.2.0   2024-05-15 [1] RSPM
#>  fs            2.1.0   2026-04-18 [1] RSPM
#>  glue          1.8.1   2026-04-17 [1] RSPM
#>  htmltools     0.5.9   2025-12-04 [1] RSPM
#>  knitr         1.51    2025-12-20 [1] RSPM
#>  lifecycle     1.0.5   2026-01-08 [1] RSPM
#>  otel          0.2.0   2025-08-29 [1] RSPM
#>  reprex        2.1.1   2024-07-06 [1] RSPM
#>  rlang         1.3.0   2026-07-05 [1] RSPM
#>  rmarkdown     2.31    2026-03-26 [1] RSPM
#>  sessioninfo   1.2.4   2026-06-04 [1] RSPM
#>  withr         3.0.3   2026-06-19 [1] RSPM
#>  xfun          0.60    2026-07-09 [1] RSPM
#>  yaml          2.3.12  2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
