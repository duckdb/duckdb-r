``` r
## Whether a caller can have DISTINCT ON today without waiting for dbplyr,
## how far into dbplyr that reaches, and what it costs when switched on.
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

# Gated on an option, so registering it changes nothing until asked.
registerS3method(
  "distinct",
  "tbl_duckdb_connection",
  function(.data, ..., .keep_all = FALSE) {
    if (!.keep_all || !isTRUE(getOption("duckdb.distinct_on", FALSE))) {
      return(NextMethod())
    }
    distinct_on_tbl(.data, ...)
  }
)

## Off by default -----------------------------------------------------------

getOption("duckdb.distinct_on", FALSE)
#> [1] FALSE
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

## Switched on --------------------------------------------------------------

options(duckdb.distinct_on = TRUE)
tbl(con, "iris") |>
  distinct(Petal.Width, Species, .keep_all = TRUE) |>
  show_query()
#> <SQL>
#> SELECT DISTINCT ON ("Petal.Width", Species) * FROM (SELECT *
#> FROM iris) AS q ORDER BY "Petal.Width", Species

# `.keep_all = FALSE` is not this method's business either way
tbl(con, "iris") |>
  distinct(Petal.Width, Species) |>
  show_query()
#> <SQL>
#> SELECT DISTINCT "Petal.Width", Species
#> FROM iris

# The result is a lazy tbl like any other, and composes
tbl(con, "iris") |>
  distinct(Petal.Width, Species, .keep_all = TRUE) |>
  filter(Species == "setosa") |>
  count() |>
  collect()
#> # A tibble: 1 × 1
#>       n
#>   <dbl>
#> 1     6

## What it costs: the pipeline's ordering ------------------------------------
## Three groups of three rows, so which row `.keep_all` keeps is visible.

dbExecute(
  con,
  "CREATE TABLE g AS SELECT * FROM (VALUES
     ('a', 1), ('a', 2), ('a', 3),
     ('b', 4), ('b', 5), ('b', 6),
     ('c', 7), ('c', 8), ('c', 9)) v(grp, x)"
)
#> [1] 9

# dbplyr, asked for the largest x per group and then for the smallest.
# It warns both times that the arrange() is ignored -- and the two answers
# differ anyway, so on this engine it is not ignored. Which row survives is
# left to how the subquery happens to feed the window: implementation
# defined either way, and not something the pipeline stated.
options(duckdb.distinct_on = FALSE)
largest <- tbl(con, "g") |>
  arrange(desc(x)) |>
  distinct(grp, .keep_all = TRUE) |>
  collect()
#> Warning: ORDER BY is ignored in subqueries without LIMIT
#> ℹ Do you need to move arrange() later in the pipeline or use window_order() instead?
smallest <- tbl(con, "g") |>
  arrange(x) |>
  distinct(grp, .keep_all = TRUE) |>
  collect()
#> Warning: ORDER BY is ignored in subqueries without LIMIT
#> ℹ Do you need to move arrange() later in the pipeline or use window_order() instead?
largest
#> # A tibble: 3 × 2
#>   grp       x
#>   <chr> <int>
#> 1 b         6
#> 2 c         9
#> 3 a         3
identical(largest, smallest)
#> [1] FALSE

# The override does what it is told, and the two orderings differ as they
# should -- first row per group by x, then by desc(x).
options(duckdb.distinct_on = TRUE)
tbl(con, "g") |> distinct_on_tbl(grp, .order_by = x) |> collect()
#> # A tibble: 3 × 2
#>   grp       x
#>   <chr> <int>
#> 1 a         1
#> 2 b         4
#> 3 c         7
tbl(con, "g") |> distinct_on_tbl(grp, .order_by = desc(x)) |> collect()
#> # A tibble: 3 × 2
#>   grp       x
#>   <chr> <int>
#> 1 a         3
#> 2 b         6
#> 3 c         9

# But it has to be told at the call. The wrapper starts a new tbl() over
# rendered SQL and sees no pipeline, so an upstream arrange() reaches it no
# further than it reaches dbplyr's own plan:
tbl(con, "g") |>
  arrange(desc(x)) |>
  distinct(grp, .keep_all = TRUE) |>
  show_query()
#> <SQL>
#> SELECT DISTINCT ON (grp) * FROM (SELECT *
#> FROM g
#> ORDER BY x DESC) AS q ORDER BY grp

# Which is the argument for the clause landing in dbplyr rather than here.
# dbplyr builds the query and is the only layer that knows what the pipeline
# asked for; a wrapper can only be handed the answer a second time.

options(duckdb.distinct_on = FALSE)
dbDisconnect(con, shutdown = TRUE)
```

<sup>Created on 2026-08-09 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
