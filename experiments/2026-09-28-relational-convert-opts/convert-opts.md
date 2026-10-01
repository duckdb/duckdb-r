``` r
## What each route out of a relation makes of the connection's conversion options,
## with `bigint`, `array`, `map`, `geometry`, `time`, `blob` and `interval` set away from their defaults.
library(DBI)

con <- dbConnect(
  duckdb::duckdb(shared_home = FALSE),
  bigint = "integer64",
  array = "matrix",
  map = "list_of",
  geometry = "wk",
  time = "hms",
  blob = "blob",
  interval = "Period"
)

sql <- "SELECT
  42::BIGINT AS big,
  MAP {'a': 1} AS map,
  'POINT (1 2)'::GEOMETRY AS geom,
  TIME '01:02:03' AS time,
  '\\xAA'::BLOB AS blob,
  INTERVAL '1 month' AS interval"
classes <- function(df) vapply(df, function(x) class(x)[[1]], character(1))

## One column of each type, through each route ---------------------------------
rel <- duckdb:::rel_from_sql(con, sql)
rbind(
  dbGetQuery = classes(dbGetQuery(con, sql)),
  rel_to_altrep = classes(duckdb:::rel_to_altrep(rel)),
  as.data.frame = classes(as.data.frame(rel)),
  rel_sql = classes(duckdb:::rel_sql(rel, "SELECT * FROM _"))
)
#>               big         map             geom     time       blob   interval  
#> dbGetQuery    "integer64" "vctrs_list_of" "wk_wkb" "hms"      "blob" "Period"  
#> rel_to_altrep "integer64" "vctrs_list_of" "wk_wkb" "hms"      "blob" "Period"  
#> as.data.frame "numeric"   "list"          "list"   "difftime" "list" "difftime"
#> rel_sql       "numeric"   "list"          "list"   "difftime" "list" "difftime"

## An ARRAY column, which the default `array = "none"` refuses ------------------
arr_sql <- "SELECT [1, 2]::INTEGER[2] AS arr"
dim(dbGetQuery(con, arr_sql)$arr)
#> [1] 1 2
arr <- duckdb:::rel_from_sql(con, arr_sql)
tryCatch(as.data.frame(arr), error = function(e) conditionMessage(e))
#> [1] "Use `dbConnect(array = \"matrix\")` to enable arrays to be returned to R.\nℹ Context: duckdb_r_allocate"

## Writing: an hms and a column of named lists, into a view and into a relation --
df <- data.frame(i = 1:2)
df$t <- hms::hms(c(1, 2))
df$m <- list(list(a = 1), list(b = 2))
types <- "SELECT typeof(t) AS t, typeof(m) AS m FROM %s LIMIT 1"
duckdb::duckdb_register(con, "registered", df)
dbGetQuery(con, sprintf(types, "registered"))
#>      t                                       m
#> 1 TIME STRUCT("key" VARCHAR, "value" DOUBLE)[]
duckdb:::rel_sql(duckdb:::rel_from_df(con, df, strict = FALSE), sprintf(types, "_"))
#> # A data frame: 1 × 2
#>   t        m         
#>   <chr>    <chr>     
#> 1 INTERVAL DOUBLE[][]

dbDisconnect(con)
```

<sup>Created on 2026-09-28 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

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
#>  date     2026-09-28
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  bit           4.6.0      2025-03-06 [2] RSPM
#>  bit64         4.8.6      2026-09-01 [2] RSPM
#>  blob          1.3.0      2026-01-14 [2] RSPM
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb        1.5.5.9029 2026-09-28 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  generics      0.1.4      2025-05-09 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  hms           1.1.4      2025-10-17 [2] RSPM (R 4.5.0)
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  lubridate     1.9.5      2026-02-04 [2] RSPM
#>  otel          0.2.0      2025-08-29 [2] RSPM
#>  pillar        1.11.1     2025-09-17 [2] RSPM
#>  pkgconfig     2.0.3      2019-09-22 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  timechange    0.4.0      2026-01-29 [2] RSPM
#>  utf8          1.2.6      2025-06-08 [2] RSPM
#>  vctrs         0.7.3      2026-04-11 [2] RSPM
#>  withr         3.0.3      2026-06-19 [2] RSPM
#>  wk            0.9.5      2025-12-18 [2] RSPM (R 4.5.0)
#>  xfun          0.61       2026-09-16 [2] RSPM
#>  yaml          2.3.12     2025-12-10 [2] RSPM
#> 
#>  [1] <fast-path build library>
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
