``` r
## duckdb-r#384 -- DISTINCT ON for the dbplyr backend: where would it go?
library(duckdb)
#> Loading required package: DBI
library(dplyr, warn.conflicts = FALSE)
library(dbplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
#> [1] '1.5.5'
packageVersion("dbplyr")
#> [1] '2.6.0'

con <- dbConnect(duckdb())
duckdb_register(con, "iris", iris)

# Today's translation, as reported: a ROW_NUMBER() subquery
tbl(con, "iris") |>
  distinct(Petal.Width, Species, .keep_all = TRUE) |>
  show_query()
#> <SQL>
#> SELECT "Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", Species
#> FROM (
#>   SELECT
#>     *,
#>     ROW_NUMBER() OVER (PARTITION BY "Petal.Width", Species ORDER BY "Sepal.Length") AS col01
#>   FROM iris
#> ) AS q01
#> WHERE (col01 = 1)

# The same shape on other backends -- this SQL is written by dbplyr's
# distinct.tbl_lazy(), not by anything in the duckdb dialect
lazy_frame(a = 1, b = 2, con = simulate_postgres()) |>
  distinct(a, .keep_all = TRUE) |>
  show_query()
#> <SQL>
#> SELECT "a", "b"
#> FROM (
#>   SELECT *, ROW_NUMBER() OVER (PARTITION BY "a" ORDER BY "a") AS "col01"
#>   FROM "df"
#> ) AS "q01"
#> WHERE ("col01" = 1)
lazy_frame(a = 1, b = 2, con = simulate_mssql()) |>
  distinct(a, .keep_all = TRUE) |>
  show_query()
#> <SQL>
#> SELECT [a], [b]
#> FROM (
#>   SELECT *, ROW_NUMBER() OVER (PARTITION BY [a] ORDER BY [a]) AS [col01]
#>   FROM [df]
#> ) AS [q01]
#> WHERE ([col01] = 1)

# ... and duckdb-r defines no distinct method of its own to intercept it
grep(
  "distinct",
  as.character(methods(class = "duckdb_connection")),
  value = TRUE
)
#> character(0)
grep("^distinct", as.character(methods(class = "tbl_lazy")), value = TRUE)
#> [1] "distinct.tbl_lazy"

# The engine has supported DISTINCT ON all along; the two queries agree
by_hand <- dbGetQuery(
  con,
  'SELECT DISTINCT ON ("Petal.Width", "Species") * FROM iris ORDER BY "Petal.Width", "Species", "Sepal.Length"'
)
by_dbplyr <- tbl(con, "iris") |>
  distinct(Petal.Width, Species, .keep_all = TRUE) |>
  collect()

nrow(by_hand)
#> [1] 27
nrow(by_dbplyr)
#> [1] 27
identical(
  dplyr::arrange(by_hand, Petal.Width, Species),
  as.data.frame(dplyr::arrange(by_dbplyr, Petal.Width, Species))
)
#> [1] TRUE

dbDisconnect(con)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
