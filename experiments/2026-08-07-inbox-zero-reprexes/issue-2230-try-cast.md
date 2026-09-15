``` r
## duckdb-r#2230 -- does the dbplyr translation use TRY_CAST?
library(duckdb)
#> Loading required package: DBI
library(dplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
#> [1] '1.5.5'

con <- dbConnect(duckdb())
duckdb_register(con, "iris", iris)

# The request: as.numeric() and friends should translate to TRY_CAST
tbl(con, "iris") |>
  mutate(Petal.Width = as.numeric(Petal.Width)) |>
  dbplyr::sql_render()
#> <SQL> SELECT
#>   "Sepal.Length",
#>   "Sepal.Width",
#>   "Petal.Length",
#>   TRY_CAST("Petal.Width" AS DOUBLE) AS "Petal.Width",
#>   Species
#> FROM iris

tbl(con, "iris") |>
  transmute(
    n = as.numeric(Species),
    i = as.integer(Species),
    d = as.Date(Species),
    ts = as.POSIXct(Species),
    chr = as.character(Species)
  ) |>
  dbplyr::sql_render()
#> <SQL> SELECT
#>   TRY_CAST(Species AS DOUBLE) AS n,
#>   TRY_CAST(Species AS INTEGER) AS i,
#>   TRY_CAST(Species AS DATE) AS d,
#>   TRY_CAST(Species AS TIMESTAMP) AS ts,
#>   TRY_CAST(Species AS TEXT) AS chr
#> FROM iris

# What TRY_CAST buys: unparseable values become NA instead of aborting the query
dbExecute(
  con,
  "CREATE TABLE t AS SELECT * FROM (VALUES ('1.5'), ('nope')) v(s)"
)
#> [1] 2

tbl(con, "t") |>
  mutate(n = as.numeric(s)) |>
  collect()
#> # A tibble: 2 × 2
#>   s         n
#>   <chr> <dbl>
#> 1 1.5     1.5
#> 2 nope   NA

# The same cast written by hand still errors, as it should
try(dbGetQuery(con, "SELECT CAST(s AS DOUBLE) FROM t"))
#> Error in duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow) : 
#>   Invalid Error: Conversion Error: Could not convert string 'nope' to DOUBLE when casting from source column s
#> 
#> LINE 1: SELECT CAST(s AS DOUBLE) FROM t
#>                ^
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID

dbDisconnect(con)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
