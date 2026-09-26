``` r
library(DBI)
packageVersion("duckdb")
#> [1] '1.5.5'

# The scenario of duckdb/duckdb-r#1604: append a data.frame to a table of an
# on-disk database under a memory_limit, with the settings reported there.
dbdir <- file.path(tempdir(), "db.duckdb")
con <- dbConnect(duckdb::duckdb(), dbdir = dbdir)
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /root/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.

dbExecute(con, "SET memory_limit = '3GB'")
#> [1] 0
dbExecute(con, "SET max_temp_directory_size = '20GB'")
#> [1] 0
dbExecute(con, "SET threads TO 1")
#> [1] 0
dbExecute(con, "SET preserve_insertion_order = false")
#> [1] 0

# Temporary storage is on, beside the database file (the engine's own default):
dbGetQuery(con, "SELECT current_setting('temp_directory') AS temp_directory")
#>                temp_directory
#> 1 /tmp/RtmpB931U4/duckdb/temp

# The reported data: 12,880,502 rows x 5 integer columns, ~257 MB.
n <- 12880502L
dat <- data.frame(
  a = seq_len(n),
  b = rev(seq_len(n)),
  c = seq_len(n) %% 1000L,
  d = seq_len(n) %/% 7L,
  e = seq_len(n) %% 33333L
)
format(object.size(dat), units = "MB")
#> [1] "245.7 Mb"

# "insert a data.frame into existing database": create the table, then append.
dbWriteTable(con, "tbl", dat[0, ], overwrite = TRUE)
dbWriteTable(con, "tbl", dat, append = TRUE) # <- failed in #1604 under 3 GB
dbGetQuery(con, "SELECT count(*) AS n FROM tbl")
#>          n
#> 1 12880502

# Harder than reported: repeat the append with a memory_limit *below* the data
# size, so it can only succeed by offloading to temporary storage.
dbExecute(con, "SET memory_limit = '200MB'")
#> [1] 0
dbWriteTable(con, "tbl", dat, append = TRUE)
dbGetQuery(con, "SELECT count(*) AS n FROM tbl")
#>          n
#> 1 25761004

# Was the temporary directory used at any point?
dir.exists(paste0(dbdir, ".tmp"))
#> [1] FALSE

# Harder still: a full ~460 MB sort under the 200 MB limit.
dbExecute(con, "SET preserve_insertion_order = true")
#> [1] 0
dbExecute(
  con,
  "CREATE TABLE big_sort AS SELECT hash(i) AS h, i FROM range(30000000) t(i) ORDER BY h"
)
#> Error in `duckdb_result()`:
#> ! Invalid Error: IO Error: Failed to create directory "/tmp/RtmpB931U4/duckdb/temp": No such file or directory
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID
dbGetQuery(con, "SELECT count(*) AS n FROM big_sort")
#> Error in `dbSendQuery()`:
#> ! Catalog Error: Table with name big_sort does not exist!
#> Did you mean "pg_description"?
#> 
#> LINE 1: SELECT count(*) AS n FROM big_sort
#>                                   ^
#> ℹ Context: rapi_prepare
#> ℹ Error type: CATALOG
dir.exists(paste0(dbdir, ".tmp"))
#> [1] FALSE

dbDisconnect(con)
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
#>  duckdb        1.5.5   2026-07-25 [1] RSPM (R 4.5.0)
#>  evaluate      1.0.5   2025-08-27 [1] RSPM
#>  fastmap       1.2.0   2024-05-15 [1] RSPM
#>  fs            2.1.0   2026-04-18 [1] RSPM
#>  glue          1.8.1   2026-04-17 [1] RSPM
#>  htmltools     0.5.9   2025-12-04 [1] RSPM
#>  knitr         1.51    2025-12-20 [1] RSPM
#>  lifecycle     1.0.5   2026-01-08 [1] RSPM
#>  otel          0.2.0   2025-08-29 [1] RSPM
#>  pillar        1.11.1  2025-09-17 [1] RSPM
#>  reprex        2.1.1   2024-07-06 [1] RSPM
#>  rlang         1.3.0   2026-07-05 [1] RSPM
#>  rmarkdown     2.31    2026-03-26 [1] RSPM
#>  sessioninfo   1.2.4   2026-06-04 [1] RSPM
#>  vctrs         0.7.3   2026-04-11 [1] RSPM
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
