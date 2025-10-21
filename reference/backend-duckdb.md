# DuckDB SQL backend for dbplyr

This is a SQL backend for dbplyr tailored to take into account DuckDB's
possibilities. This mainly follows the backend for PostgreSQL, but
contains more mapped functions.

`tbl_file()` is an experimental variant of
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) to
directly access files on disk. It is safer than
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) because
there is no risk of misinterpreting the request, and paths with special
characters are supported.

`tbl_function()` is an experimental variant of
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) to
create a lazy table from a table-generating function, useful for reading
nonstandard CSV files or other data sources. It is safer than
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) because
there is no risk of misinterpreting the query. See
<https://duckdb.org/docs/data/overview> for details on data importing
functions.

As an alternative, use
`dplyr::tbl(src, dplyr::sql("SELECT ... FROM ..."))` for custom SQL
queries.

`tbl_query()` is deprecated in favor of `tbl_function()`.

Use `simulate_duckdb()` with `lazy_frame()` to see simulated SQL without
opening a DuckDB connection.

## Usage

``` r
tbl_file(src = NULL, path, ..., cache = FALSE)

tbl_function(src, query, ..., cache = FALSE)

tbl_query(src, query, ...)

simulate_duckdb(...)
```

## Arguments

- src:

  A duckdb connection object,
  [`default_conn()`](https://r.duckdb.org/reference/default_conn.md) if
  omitted.

- path:

  Path to existing Parquet, CSV or JSON file

- ...:

  Any parameters to be forwarded

- cache:

  Enable object cache for Parquet files

- query:

  SQL code, omitting the `FROM` clause

## Examples

``` r
if (FALSE) { # duckdb:::TEST_RE2 && rlang::is_installed("dbplyr")
library(dplyr, warn.conflicts = FALSE)
con <- DBI::dbConnect(duckdb(), path = ":memory:")

db <- copy_to(con, data.frame(a = 1:3, b = letters[2:4]))

db %>%
  filter(a > 1) %>%
  select(b)

path <- tempfile(fileext = ".csv")
write.csv(data.frame(a = 1:3, b = letters[2:4]))

db_csv <- tbl_file(con, path)
db_csv %>%
  summarize(sum_a = sum(a))

db_csv_fun <- tbl_function(con, paste0("read_csv_auto('", path, "')"))
db_csv %>%
  count()

DBI::dbDisconnect(con, shutdown = TRUE)
}
```
