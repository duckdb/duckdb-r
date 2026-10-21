``` r
## R values that write, or create a table, as something other than their type,
## and a column R cannot hold that is refused only after its statement ran.
library(DBI)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))

## NaN and Inf in a Date, difftime or POSIXct stored as double -----------------
x <- c(NaN, Inf, -Inf, NA)
dbWriteTable(
  con,
  "nonfinite",
  data.frame(
    d = as.Date(x),
    dt = as.difftime(x, units = "secs"),
    ts = as.POSIXct(x, tz = "UTC")
  )
)
dbGetQuery(
  con,
  "SELECT d::VARCHAR AS d, dt::VARCHAR AS dt, epoch_us(ts) AS ts_us FROM nonfinite"
)
#>                    d                               dt         ts_us
#> 1 5877642-06-23 (BC) -106751991 days -04:00:54.775808 -9.223372e+18
#> 2 5877642-06-23 (BC) -106751991 days -04:00:54.775808 -9.223372e+18
#> 3 5877642-06-23 (BC) -106751991 days -04:00:54.775808 -9.223372e+18
#> 4               <NA>                             <NA>            NA
tryCatch(
  dbGetQuery(con, "SELECT ts::VARCHAR FROM nonfinite"),
  error = first_line
)
#> [1] "Conversion Error: Date out of range in timestamp conversion"

## A POSIXct stored as integer ---------------------------------------------------
p <- .POSIXct(c(0L, 86400L), tz = "UTC")
typeof(p)
#> [1] "integer"
dbWriteTable(con, "posix_int", data.frame(p = p))
dbGetQuery(con, "SELECT column_type FROM (DESCRIBE posix_int)")
#>   column_type
#> 1     INTEGER
str(dbReadTable(con, "posix_int"))
#> 'data.frame':    2 obs. of  1 variable:
#>  $ p: int  0 86400
dbDataType(con, p)
#> [1] "INTEGER"
dbGetQuery(con, "SELECT typeof($1) AS type", params = list(p[1]))
#>      type
#> 1 INTEGER

## A data frame column -----------------------------------------------------------
two <- data.frame(id = 1:2)
two$s <- data.frame(a = 1:2, b = c("x", "y"))
tryCatch(dbDataType(con, two), error = first_line)
#> [1] "values must be length 1,"
tryCatch(sqlCreateTable(con, "two", two, row.names = FALSE), error = first_line)
#> [1] "values must be length 1,"
tryCatch(dbCreateTable(con, "two", two), error = first_line)
#> [1] "values must be length 1,"
dbWriteTable(con, "two", two)
dbGetQuery(con, "SELECT column_type FROM (DESCRIBE two)")
#>                    column_type
#> 1                      INTEGER
#> 2 STRUCT(a INTEGER, b VARCHAR)

one <- data.frame(id = 1:2)
one$s <- data.frame(a = 1:2)
dbDataType(con, one)
#>        id         s 
#> "INTEGER" "INTEGER"
dbCreateTable(con, "one", one)
dbGetQuery(con, "SELECT column_type FROM (DESCRIBE one)")
#>   column_type
#> 1     INTEGER
#> 2     INTEGER
tryCatch(dbAppendTable(con, "one", one), error = first_line)
#> [1] "Conversion Error: Unimplemented type for cast (STRUCT(a INTEGER) -> INTEGER) when casting from source column s"

## An ARRAY column under array = "none" -----------------------------------------
dbExecute(con, "CREATE TABLE side (i INTEGER)")
#> [1] 0
tryCatch(
  dbGetQuery(
    con,
    "INSERT INTO side VALUES (1) RETURNING [i, i]::INTEGER[2] AS a"
  ),
  error = first_line
)
#> [1] "Use `dbConnect(array = \"matrix\")` to enable arrays to be returned to R."
dbGetQuery(con, "SELECT count(*) AS n FROM side")
#>   n
#> 1 1
# A type with no R vector is refused before the statement runs.
tryCatch(
  dbGetQuery(con, "INSERT INTO side VALUES (2) RETURNING i::BIT AS b"),
  error = first_line
)
#> [1] "Unknown type for column `b`: BIT"
dbGetQuery(con, "SELECT count(*) AS n FROM side")
#>   n
#> 1 1

dbDisconnect(con)
```

<sup>Created on 2026-09-27 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

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
#>  date     2026-09-27
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb        1.5.5.9028 2026-09-27 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  otel          0.2.0      2025-08-29 [2] RSPM
#>  pillar        1.11.1     2025-09-17 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  vctrs         0.7.3      2026-04-11 [2] RSPM
#>  withr         3.0.3      2026-06-19 [2] RSPM
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
