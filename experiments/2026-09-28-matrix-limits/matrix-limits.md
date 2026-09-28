``` r
## A matrix column that carries a class, through every write route,
## and an ARRAY column read by rel_to_altrep() under array = "matrix".
library(DBI)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))
con <- dbConnect(duckdb::duckdb(shared_home = FALSE), array = "matrix")

## A Date matrix column ---------------------------------------------------------
d <- structure(as.Date("2024-01-01") + 0:3, dim = c(2L, 2L))
format(d)
#> [1] "2024-01-01" "2024-01-02" "2024-01-03" "2024-01-04"
df <- data.frame(id = 1:2)
df$m <- d

dbWriteTable(con, "written", df)
dbGetQuery(con, "SELECT typeof(m) AS type, m FROM written")
#>   type          m
#> 1 DATE 2024-01-01
#> 2 DATE 2024-01-02

duckdb::duckdb_register(con, "registered", df)
dbGetQuery(con, "SELECT typeof(m) AS type, m FROM registered")
#>   type          m
#> 1 DATE 2024-01-01
#> 2 DATE 2024-01-02

dbExecute(con, "CREATE TABLE appended (id INTEGER, m DATE)")
#> [1] 0
dbAppendTable(con, "appended", df)
dbGetQuery(con, "SELECT typeof(m) AS type, m FROM appended")
#>   type          m
#> 1 DATE 2024-01-01
#> 2 DATE 2024-01-02
dbExecute(con, "CREATE TABLE appended_array (id INTEGER, m DATE[2])")
#> [1] 0
tryCatch(dbAppendTable(con, "appended_array", df), error = first_line)
#> [1] "Conversion Error: Unimplemented type for cast (DATE -> DATE[2]) when casting from source column m"

# As the only column of a data frame of two rows
single <- df["m"]
dim(single)
#> [1] 2 1
dbWriteTable(con, "single", single)
dbGetQuery(con, "SELECT typeof(m) AS type, m FROM single")
#>   type          m
#> 1 DATE 2024-01-01
#> 2 DATE 2024-01-02
#> 3 DATE 2024-01-03
#> 4 DATE 2024-01-04

# As the first of two columns
first <- df[c("m", "id")]
dbWriteTable(con, "first", first)
dbGetQuery(con, "SELECT typeof(m) AS type, m, id FROM first")
#>   type          m        id
#> 1 DATE 2024-01-01         1
#> 2 DATE 2024-01-02         2
#> 3 DATE 2024-01-03 536870954
#> 4 DATE 2024-01-04         0

## Other classes, and a plain matrix --------------------------------------------
write_matrix <- function(m) {
  x <- data.frame(id = 1:2)
  x$m <- m
  dbWriteTable(con, "classed", x, overwrite = TRUE)
  dbGetQuery(con, "SELECT typeof(m) AS type, m::VARCHAR AS m FROM classed")
}
lapply(
  list(
    POSIXct = structure(
      as.POSIXct("2024-01-01", tz = "UTC") + 0:3,
      dim = c(2L, 2L)
    ),
    difftime = structure(
      as.difftime(c(1, 2, 3, 4), units = "secs"),
      dim = c(2L, 2L)
    ),
    hms = structure(hms::hms(1:4), dim = c(2L, 2L)),
    factor = structure(factor(c("a", "b", "c", "d")), dim = c(2L, 2L)),
    integer = matrix(1:4, 2)
  ),
  write_matrix
)
#> $POSIXct
#>        type                   m
#> 1 TIMESTAMP 2024-01-01 00:00:00
#> 2 TIMESTAMP 2024-01-01 00:00:01
#> 
#> $difftime
#>       type        m
#> 1 INTERVAL 00:00:01
#> 2 INTERVAL 00:00:02
#> 
#> $hms
#>       type        m
#> 1 INTERVAL 00:00:01
#> 2 INTERVAL 00:00:02
#> 
#> $factor
#>                       type m
#> 1 ENUM('a', 'b', 'c', 'd') a
#> 2 ENUM('a', 'b', 'c', 'd') b
#> 
#> $integer
#>         type      m
#> 1 INTEGER[2] [1, 3]
#> 2 INTEGER[2] [2, 4]

## As a parameter ---------------------------------------------------------------
tryCatch(
  dbGetQuery(con, "SELECT $1 AS p", params = list(matrix(1:4, 2))),
  error = first_line
)
#> [1] "Unsupported RTypeId"
dbGetQuery(con, "SELECT typeof($1) AS type, $1 AS p", params = list(d))
#>   type          p
#> 1 DATE 2024-01-01
#> 2 DATE 2024-01-02
#> 3 DATE 2024-01-03
#> 4 DATE 2024-01-04

## An ARRAY column through rel_to_altrep() --------------------------------------
sql <- "SELECT [range, range + 10]::INTEGER[2] AS a FROM range(%d)"
dbGetQuery(con, sprintf(sql, 4))$a
#>      [,1] [,2]
#> [1,]    0   10
#> [2,]    1   11
#> [3,]    2   12
#> [4,]    3   13
lazy <- duckdb:::rel_to_altrep(duckdb:::rel_from_sql(con, sprintf(sql, 4)))
lazy$a
#>      [,1] [,2]
#> [1,]    0    2
#> [2,]    1    3
length(lazy$a)
#> [1] 4

altrep_array <- function(conn, query) {
  tryCatch(
    duckdb:::rel_to_altrep(duckdb:::rel_from_sql(conn, query))$a,
    error = first_line
  )
}
altrep_array(con, sprintf(sql, 1))
#> [1] "dims [product 0] do not match the length of object [1]"
altrep_array(con, sprintf(sql, 3))
#> [1] "dims [product 2] do not match the length of object [3]"
altrep_array(con, sprintf(sql, 0))
#>      [,1] [,2]
altrep_array(
  con,
  "SELECT [range, range + 10, range + 20]::INTEGER[3] AS a FROM range(6)"
)
#>      [,1] [,2] [,3]
#> [1,]    0    2    4
#> [2,]    1    3    5
altrep_array(
  con,
  "SELECT [range::VARCHAR, (range + 10)::VARCHAR]::VARCHAR[2] AS a FROM range(4)"
)
#>      [,1] [,2]
#> [1,] "0"  "2" 
#> [2,] "1"  "3"
altrep_array(
  con,
  "SELECT [range::VARCHAR, (range + 10)::VARCHAR]::VARCHAR[2] AS a FROM range(3)"
)
#> [1] "dims [product 2] do not match the length of object [3]"

# The same failure under the default array = "none"
con_none <- dbConnect(duckdb::duckdb(shared_home = FALSE))
altrep_array(con_none, sprintf(sql, 3))
#> [1] "dims [product 2] do not match the length of object [3]"
tryCatch(dbGetQuery(con_none, sprintf(sql, 3)), error = first_line)
#> [1] "Use `dbConnect(array = \"matrix\")` to enable arrays to be returned to R."

# An ARRAY column runs the relation when the data frame is built.
tryCatch(
  duckdb:::rel_to_altrep(duckdb:::rel_from_sql(
    con,
    "SELECT [range, range]::INTEGER[2] AS a, error('boom')::INTEGER AS i FROM range(4)"
  )),
  error = first_line
)
#> [1] "GetQueryResult: Error evaluating duckdb query: Invalid Input Error: boom"
# Without one, the same error waits for a value to be touched.
lazy <- duckdb:::rel_to_altrep(duckdb:::rel_from_sql(
  con,
  "SELECT error('boom')::INTEGER AS i FROM range(4)"
))
tryCatch(lazy$i[1], error = first_line)
#> [1] "GetQueryResult: Error evaluating duckdb query: Invalid Input Error: boom"

dbDisconnect(con)
dbDisconnect(con_none)
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
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb        1.5.5.9029 2026-09-28 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  hms           1.1.4      2025-10-17 [2] RSPM (R 4.5.0)
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  otel          0.2.0      2025-08-29 [2] RSPM
#>  pillar        1.11.1     2025-09-17 [2] RSPM
#>  pkgconfig     2.0.3      2019-09-22 [2] RSPM
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
