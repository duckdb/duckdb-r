``` r
## Whether a caller can have DISTINCT ON today without waiting for dbplyr,
## how far into dbplyr that reaches, and what dbplyr can already state
## without it.
library(duckdb)
#> Loading required package: DBI
library(dplyr, warn.conflicts = FALSE)
library(dbplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
#> [1] '1.5.5'
packageVersion("dbplyr")
#> [1] '2.6.0'

con <- dbConnect(duckdb())
dbExecute(
  con,
  "CREATE TABLE g AS SELECT * FROM (VALUES
     ('a', 1), ('a', 2), ('a', 3),
     ('b', 4), ('b', 5), ('b', 6),
     ('c', 7), ('c', 8), ('c', 9)) v(grp, x)"
)
#> [1] 9

## What dbplyr already states -----------------------------------------------
## Which row `.keep_all` keeps is sayable today. `arrange()` above
## `distinct()` warns -- and reaches the window's ORDER BY regardless;
## `window_order()` is the spelling that says the same thing without the
## warning, and renders the same SQL.

tbl(con, "g") |>
  arrange(desc(x)) |>
  distinct(grp, .keep_all = TRUE) |>
  show_query()
#> Warning: ORDER BY is ignored in subqueries without LIMIT
#> ℹ Do you need to move arrange() later in the pipeline or use window_order() instead?
#> <SQL>
#> SELECT grp, x
#> FROM (
#>   SELECT *, ROW_NUMBER() OVER (PARTITION BY grp ORDER BY x DESC) AS col01
#>   FROM g
#> ) AS q01
#> WHERE (col01 = 1)

tbl(con, "g") |>
  window_order(desc(x)) |>
  distinct(grp, .keep_all = TRUE) |>
  show_query()
#> <SQL>
#> SELECT grp, x
#> FROM (
#>   SELECT *, ROW_NUMBER() OVER (PARTITION BY grp ORDER BY x DESC) AS col01
#>   FROM g
#> ) AS q01
#> WHERE (col01 = 1)

tbl(con, "g") |>
  window_order(desc(x)) |>
  distinct(grp, .keep_all = TRUE) |>
  collect() |>
  arrange(grp)
#> # A tibble: 3 × 2
#>   grp       x
#>   <chr> <int>
#> 1 a         3
#> 2 b         6
#> 3 c         9

tbl(con, "g") |>
  window_order(x) |>
  distinct(grp, .keep_all = TRUE) |>
  collect() |>
  arrange(grp)
#> # A tibble: 3 × 2
#>   grp       x
#>   <chr> <int>
#> 1 a         1
#> 2 b         4
#> 3 c         7

## The override -------------------------------------------------------------
## Exported dbplyr only: remote_con(), sql_render(), translate_sql_(),
## ident(), escape(), sql(). Nothing from `:::`.

distinct_on_tbl <- function(.data, ..., .order_by = NULL) {
  con <- dbplyr::remote_con(.data)
  on <- names(tidyselect::eval_select(rlang::expr(c(...)), .data))
  keys <- dbplyr::escape(dbplyr::ident(on), con = con)
  order <- rlang::enquo(.order_by)
  tiebreak <- if (!rlang::quo_is_null(order)) {
    as.character(dbplyr::translate_sql_(list(order), con = con))
  }
  dplyr::tbl(
    con,
    dbplyr::sql(paste0(
      "SELECT DISTINCT ON (",
      paste(keys, collapse = ", "),
      ") * FROM (",
      dbplyr::sql_render(.data),
      ") AS q ",
      "ORDER BY ",
      paste(c(keys, tiebreak), collapse = ", ")
    ))
  )
}

# The opt-in is the argument, not a setting: without `.order_by` the method
# hands straight back to dbplyr, so registering it changes nothing until a
# call asks for it -- and a call that asks has said which row it means.
registerS3method(
  "distinct",
  "tbl_duckdb_connection",
  function(.data, ..., .keep_all = FALSE, .order_by = NULL) {
    order <- rlang::enquo(.order_by)
    if (!.keep_all || rlang::quo_is_null(order)) {
      return(NextMethod())
    }
    distinct_on_tbl(.data, ..., .order_by = !!order)
  }
)

## Not asked for: dbplyr's plan, unchanged ----------------------------------

tbl(con, "g") |>
  distinct(grp, .keep_all = TRUE) |>
  show_query()
#> <SQL>
#> SELECT grp, x
#> FROM (
#>   SELECT *, ROW_NUMBER() OVER (PARTITION BY grp ORDER BY grp) AS col01
#>   FROM g
#> ) AS q01
#> WHERE (col01 = 1)

# `.keep_all = FALSE` is never this method's business
tbl(con, "g") |>
  distinct(grp) |>
  show_query()
#> <SQL>
#> SELECT DISTINCT grp
#> FROM g

# and an explicit NULL is the same as saying nothing
tbl(con, "g") |>
  distinct(grp, .keep_all = TRUE, .order_by = NULL) |>
  show_query()
#> <SQL>
#> SELECT grp, x
#> FROM (
#>   SELECT *, ROW_NUMBER() OVER (PARTITION BY grp ORDER BY grp) AS col01
#>   FROM g
#> ) AS q01
#> WHERE (col01 = 1)

## Asked for ----------------------------------------------------------------

tbl(con, "g") |>
  distinct(grp, .keep_all = TRUE, .order_by = desc(x)) |>
  show_query()
#> <SQL>
#> SELECT DISTINCT ON (grp) * FROM (SELECT *
#> FROM g) AS q ORDER BY grp, x DESC

tbl(con, "g") |>
  distinct(grp, .keep_all = TRUE, .order_by = desc(x)) |>
  collect() |>
  arrange(grp)
#> # A tibble: 3 × 2
#>   grp       x
#>   <chr> <int>
#> 1 a         3
#> 2 b         6
#> 3 c         9

tbl(con, "g") |>
  distinct(grp, .keep_all = TRUE, .order_by = x) |>
  collect() |>
  arrange(grp)
#> # A tibble: 3 × 2
#>   grp       x
#>   <chr> <int>
#> 1 a         1
#> 2 b         4
#> 3 c         7

# The result is a lazy tbl like any other, and composes
tbl(con, "g") |>
  distinct(grp, .keep_all = TRUE, .order_by = desc(x)) |>
  filter(x > 3) |>
  count() |>
  collect()
#> # A tibble: 1 × 1
#>       n
#>   <dbl>
#> 1     2

## What it still costs ------------------------------------------------------
## The wrapper renders the pipeline and starts a new tbl() over the SQL, so
## it reads nothing dbplyr was tracking -- including a window_order() the
## caller already wrote. The ordering has to be stated in its own argument.

tbl(con, "g") |>
  window_order(desc(x)) |>
  distinct(grp, .keep_all = TRUE, .order_by = desc(x)) |>
  show_query()
#> <SQL>
#> SELECT DISTINCT ON (grp) * FROM (SELECT *
#> FROM g) AS q ORDER BY grp, x DESC

dbDisconnect(con, shutdown = TRUE)
```

<sup>Created on 2026-08-09 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
