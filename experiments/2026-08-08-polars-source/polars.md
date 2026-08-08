``` r
# What it takes to scan a Polars frame from DuckDB, and what the
# pushdown is worth. Uses no C++ changes: the five closures that
# rapi_register_arrow() takes are ordinary R functions, so both the
# export and the filter translation can be written against Polars.

# The recorded run is polars.md, rendered with reprex::reprex(si = TRUE).

library(duckdb)
#> Loading required package: DBI
library(polars)
library(nanoarrow)
options(width = 200)

new_con <- function() dbConnect(duckdb(shared_home = FALSE))

packageVersion("duckdb")
#> [1] '1.5.5.9012'
packageVersion("polars")
#> [1] '1.14.0.9000'

# --- 1. What nanoarrow already knows about Polars -----------------------

pdf <- as_polars_df(data.frame(a = 1:5, b = letters[1:5]))
class(pdf)
#> [1] "polars_data_frame" "polars_object"

# polars registers as_nanoarrow_array_stream() for its frames, eager and
# lazy alike -- so an Arrow C stream is available without the arrow
# package, and without duckdb knowing what a Polars frame is.
grep("nanoarrow", ls(asNamespace("polars"), all.names = TRUE), value = TRUE)
#> [1] "as_nanoarrow_array_stream.polars_data_frame" "as_nanoarrow_array_stream.polars_lazy_frame" "as_nanoarrow_array_stream.polars_series"     "as_polars_series.nanoarrow_array"           
#> [5] "as_polars_series.nanoarrow_array_stream"     "infer_polars_dtype.nanoarrow_array"          "infer_polars_dtype.nanoarrow_array_stream"

# It does not register infer_nanoarrow_schema(), so the schema has to be
# taken from a zero-row stream rather than asked for directly.
try(nanoarrow::infer_nanoarrow_schema(pdf))
#> Error in infer_nanoarrow_schema.default(pdf) : 
#>   Can't infer Arrow type for object of class polars_data_frame/polars_object
polars_schema <- function(x) {
  nanoarrow::infer_nanoarrow_schema(
    nanoarrow::as_nanoarrow_array_stream(x$head(0))
  )
}
names(polars_schema(pdf)$children)
#> [1] "a" "b"

# Note the string type: Polars exports `string_view`, not `string`.
polars_schema(pdf)$children$b$format
#> [1] "vu"

# --- 2. The pushdown-free route -----------------------------------------

# The nanoarrow shim, with projection expressed as a Polars select.
register_polars_eager <- function(con, name, x) {
  export_fun <- function(x, stream_ptr, projection = NULL, filter = TRUE) {
    if (!is.null(projection)) x <- x$select(projection)
    nanoarrow::nanoarrow_pointer_export(
      nanoarrow::as_nanoarrow_array_stream(x), stream_ptr
    )
  }
  get_schema_fun <- function(x, schema_ptr) {
    nanoarrow::nanoarrow_pointer_export(polars_schema(x), schema_ptr)
  }
  expr_factory <- function(...) stop("this producer cannot filter")
  duckdb:::rapi_register_arrow(
    con@conn_ref, name,
    list(export_fun, expr_factory, expr_factory, expr_factory, get_schema_fun),
    x
  )
  invisible(TRUE)
}

con <- new_con()
register_polars_eager(con, "pl_eager", pdf)
dbGetQuery(con, "SELECT * FROM pl_eager")
#>   a b
#> 1 1 a
#> 2 2 b
#> 3 3 c
#> 4 4 d
#> 5 5 e
dbGetQuery(con, "SELECT b FROM pl_eager")
#>   b
#> 1 a
#> 2 b
#> 3 c
#> 4 d
#> 5 e
dbGetQuery(con, "SELECT count(*) FROM pl_eager")
#>   count_star()
#> 1            5

# --- 3. What string_view does to pushdown -------------------------------

# arrow_scan refuses to push any filter when the table has a view type,
# so a Polars frame with a string column never reaches the expression
# factories: DuckDB applies the filter itself, and the answer is right
# even though the producer cannot filter.
dbGetQuery(con, "SELECT * FROM pl_eager WHERE a > 3")
#>   a b
#> 1 4 d
#> 2 5 e
cat(dbGetQuery(con, "EXPLAIN SELECT * FROM pl_eager WHERE a > 3")[[2]])
#> ┌───────────────────────────┐
#> │           FILTER          │
#> │    ────────────────────   │
#> │          (#0 > 3)         │
#> │                           │
#> │           ~1 row          │
#> └─────────────┬─────────────┘
#> ┌─────────────┴─────────────┐
#> │         ARROW_SCAN        │
#> │    ────────────────────   │
#> │    Function: ARROW_SCAN   │
#> │                           │
#> │        Projections:       │
#> │             a             │
#> │             b             │
#> │                           │
#> │           ~1 row          │
#> └───────────────────────────┘

# Drop the string column and the protection goes with it: the filter is
# pushed, the producer refuses it, and the query fails.
register_polars_eager(con, "pl_num", pdf$select("a"))
try(dbGetQuery(con, "SELECT * FROM pl_num WHERE a > 3"))
#> Error in duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow) : 
#>   Invalid Error: Invalid Error: std::exception
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID
cat(dbGetQuery(con, "EXPLAIN SELECT * FROM pl_num WHERE a > 3")[[2]])
#> ┌───────────────────────────┐
#> │         ARROW_SCAN        │
#> │    ────────────────────   │
#> │    Function: ARROW_SCAN   │
#> │       Projections: a      │
#> │        Filters: a>3       │
#> │                           │
#> │           ~1 row          │
#> └───────────────────────────┘

# The exporter decides which it is. Polars exports the newest Arrow
# layouts by default; asking for the oldest turns string_view into
# large_utf8, and the filter becomes pushable again.
nanoarrow::infer_nanoarrow_schema(
  nanoarrow::as_nanoarrow_array_stream(pdf$head(0), polars_compat_level = "oldest")
)$children$b$format
#> [1] "U"

# --- 4. The pushdown route: translate the filter into Polars ------------

# DuckDB hands the filter to the same three factories the arrow package
# uses -- an expression builder, a column reference, and a scalar.
# Nothing says they have to build Arrow expressions.
polars_expr <- function(name, op1, op2 = NULL) {
  switch(name,
    equal = op1 == op2,
    not_equal = op1 != op2,
    greater = op1 > op2,
    greater_equal = op1 >= op2,
    less = op1 < op2,
    less_equal = op1 <= op2,
    and_kleene = op1 & op2,
    or_kleene = op1 | op2,
    is_null = op1$is_null(),
    invert = !op1,
    stop("no Polars translation for ", name)
  )
}

register_polars_lazy <- function(con, name, x) {
  lf <- as_polars_lf(x)
  export_fun <- function(lf, stream_ptr, projection = NULL, filter = TRUE) {
    if (!isTRUE(filter)) lf <- lf$filter(filter)
    if (!is.null(projection)) lf <- lf$select(projection)
    nanoarrow::nanoarrow_pointer_export(
      nanoarrow::as_nanoarrow_array_stream(lf$collect()), stream_ptr
    )
  }
  get_schema_fun <- function(lf, schema_ptr) {
    nanoarrow::nanoarrow_pointer_export(polars_schema(lf), schema_ptr)
  }
  duckdb:::rapi_register_arrow(
    con@conn_ref, name,
    list(export_fun, polars_expr, pl$col, pl$lit, get_schema_fun),
    lf
  )
  invisible(TRUE)
}

register_polars_lazy(con, "pl_lazy", pdf$select("a"))
dbGetQuery(con, "SELECT * FROM pl_lazy")
#>   a
#> 1 1
#> 2 2
#> 3 3
#> 4 4
#> 5 5
dbGetQuery(con, "SELECT * FROM pl_lazy WHERE a > 3")
#>   a
#> 1 4
#> 2 5
dbGetQuery(con, "SELECT * FROM pl_lazy WHERE a > 1 AND a < 4")
#>   a
#> 1 2
#> 2 3
dbGetQuery(con, "SELECT * FROM pl_lazy WHERE a IN (2, 4)")
#>   a
#> 1 2
#> 2 4
dbGetQuery(con, "SELECT * FROM pl_lazy WHERE a IS NOT NULL")
#>   a
#> 1 1
#> 2 2
#> 3 3
#> 4 4
#> 5 5

# --- 5. Type fidelity ---------------------------------------------------

types <- list(
  logical = c(TRUE, FALSE, NA),
  integer = c(1L, 2L, NA),
  double = c(1.5, 2.5, NA),
  character = c("a", "äöü", NA),
  factor = factor(c("x", "y", NA)),
  Date = as.Date(c("2024-01-01", "2024-06-15", NA)),
  POSIXct = as.POSIXct(c("2024-01-01 10:00:00", "2024-06-15 10:00:00", NA), tz = "UTC"),
  difftime = as.difftime(c(1, 2, NA), units = "secs"),
  integer64 = bit64::as.integer64(c(1, 2, NA)),
  list_int = NULL
)
types$list_int <- list(1:2, integer(), NULL)

probe_one <- function(value, how) {
  df <- data.frame(row.names = seq_len(3))
  df[["x"]] <- value
  con <- new_con()
  on.exit(dbDisconnect(con), add = TRUE)
  tryCatch(
    {
      if (how == "r_dataframe_scan") {
        duckdb_register(con, "t", df)
      } else {
        register_polars_lazy(con, "t", as_polars_df(df))
      }
      type <- dbGetQuery(con, "SELECT typeof(x) AS t FROM t LIMIT 1")$t[[1]]
      list(type = type, value = dbGetQuery(con, "SELECT * FROM t")$x)
    },
    error = function(e) list(type = paste("ERROR:", conditionMessage(e)), value = NULL)
  )
}

grid <- do.call(rbind, lapply(names(types), function(name) {
  native <- probe_one(types[[name]], "r_dataframe_scan")
  pl_res <- probe_one(types[[name]], "polars")
  data.frame(
    column = name,
    native_type = substr(native$type, 1, 40),
    polars_type = substr(pl_res$type, 1, 40),
    agree = identical(native$value, pl_res$value),
    stringsAsFactors = FALSE
  )
}))
grid
#>       column    native_type              polars_type agree
#> 1    logical        BOOLEAN                  BOOLEAN  TRUE
#> 2    integer        INTEGER                  INTEGER  TRUE
#> 3     double         DOUBLE                   DOUBLE  TRUE
#> 4  character        VARCHAR                  VARCHAR  TRUE
#> 5     factor ENUM('x', 'y')                  VARCHAR FALSE
#> 6       Date           DATE                     DATE  TRUE
#> 7    POSIXct      TIMESTAMP TIMESTAMP WITH TIME ZONE FALSE
#> 8   difftime       INTERVAL                 INTERVAL  TRUE
#> 9  integer64         DOUBLE                   BIGINT FALSE
#> 10  list_int      INTEGER[]                INTEGER[]  TRUE

# --- 6. What the export and the pushdown cost ---------------------------

n <- 5e6
big <- data.frame(i = seq_len(n), d = as.numeric(seq_len(n)))
big_pl <- as_polars_df(big)

con2 <- new_con()
duckdb_register(con2, "native", big)
register_polars_eager(con2, "pl_eager", big_pl)
register_polars_lazy(con2, "pl_lazy", big_pl)

timing <- function(label, expr) {
  expr <- substitute(expr)
  eval(expr, parent.frame())
  t <- system.time(for (i in 1:3) eval(expr, parent.frame()))
  data.frame(what = label, elapsed_per_run = round(unname(t[["elapsed"]]) / 3, 3))
}

# Unfiltered: what the Arrow export costs over the built-in scan.
do.call(rbind, list(
  timing("native  sum(d)", dbGetQuery(con2, "SELECT sum(d) FROM native")),
  timing("polars  sum(d), eager", dbGetQuery(con2, "SELECT sum(d) FROM pl_eager")),
  timing("polars  sum(d), lazy", dbGetQuery(con2, "SELECT sum(d) FROM pl_lazy"))
))
#>                    what elapsed_per_run
#> 1        native  sum(d)           0.014
#> 2 polars  sum(d), eager           0.015
#> 3  polars  sum(d), lazy           0.016

# Filtered to ten rows in five million, in memory. The pushdown saves
# the transfer but not the scan, because Polars still walks every row.
do.call(rbind, list(
  timing("native  selective filter",
    dbGetQuery(con2, "SELECT sum(d) FROM native WHERE i > 4999990")),
  timing("polars  selective filter, pushed",
    dbGetQuery(con2, "SELECT sum(d) FROM pl_lazy WHERE i > 4999990")),
  timing("polars  selective filter, not pushed",
    dbGetQuery(con2, "WITH t AS MATERIALIZED (SELECT * FROM pl_lazy) SELECT sum(d) FROM t WHERE i > 4999990"))
))
#>                                   what elapsed_per_run
#> 1             native  selective filter           0.020
#> 2     polars  selective filter, pushed           0.012
#> 3 polars  selective filter, not pushed           0.012

# --- 7. What crosses the boundary ---------------------------------------

# Wall clock hides the point at this scale -- DuckDB and Polars are both
# fast enough that a few hundred megabytes barely register. What the
# pushdown changes is how much data is produced at all, so measure that
# instead: an instrumented producer records the shape of every export.

exported <- NULL
register_polars_counting <- function(con, name, x) {
  lf <- as_polars_lf(x)
  export_fun <- function(lf, stream_ptr, projection = NULL, filter = TRUE) {
    if (!isTRUE(filter)) lf <- lf$filter(filter)
    if (!is.null(projection)) lf <- lf$select(projection)
    out <- lf$collect()
    exported <<- rbind(exported, data.frame(rows = out$height, cols = out$width))
    nanoarrow::nanoarrow_pointer_export(
      nanoarrow::as_nanoarrow_array_stream(out), stream_ptr
    )
  }
  get_schema_fun <- function(lf, schema_ptr) {
    nanoarrow::nanoarrow_pointer_export(polars_schema(lf), schema_ptr)
  }
  duckdb:::rapi_register_arrow(
    con@conn_ref, name,
    list(export_fun, polars_expr, pl$col, pl$lit, get_schema_fun), lf
  )
  invisible(TRUE)
}

# Ten numeric columns and two million rows, on disk. The query needs one
# column and ten rows.
wide <- as.data.frame(setNames(
  lapply(1:10, function(k) as.numeric(seq_len(2e6)) * k),
  paste0("c", 1:10)
))
path <- tempfile(fileext = ".parquet")
as_polars_df(wide)$write_parquet(path)
round(file.size(path) / 1e6, 1)
#> [1] 88.8

register_polars_counting(con2, "pl_scan", pl$scan_parquet(path))
exported <- NULL
dbGetQuery(con2, "SELECT sum(c1) FROM pl_scan WHERE c1 > 1999990")
#>    sum(c1)
#> 1 19999955
exported
#>   rows cols
#> 1   10    1

# The same file with one string column added. Nothing else changes, but
# the view type disables filter pushdown for the whole table, so Polars
# is asked for every row and DuckDB throws all but ten of them away.
wide$s <- rep(letters, length.out = 2e6)
path2 <- tempfile(fileext = ".parquet")
as_polars_df(wide)$write_parquet(path2)

register_polars_counting(con2, "pl_scan_s", pl$scan_parquet(path2))
exported <- NULL
dbGetQuery(con2, "SELECT sum(c1) FROM pl_scan_s WHERE c1 > 1999990")
#>    sum(c1)
#> 1 19999955
exported
#>      rows cols
#> 1 2000000    1

# Which is also what it costs.
do.call(rbind, list(
  timing("duckdb  read_parquet",
    dbGetQuery(con2, sprintf("SELECT sum(c1) FROM read_parquet('%s') WHERE c1 > 1999990", path))),
  timing("polars  scan_parquet, filter pushed",
    dbGetQuery(con2, "SELECT sum(c1) FROM pl_scan WHERE c1 > 1999990")),
  timing("polars  scan_parquet, filter not pushable",
    dbGetQuery(con2, "SELECT sum(c1) FROM pl_scan_s WHERE c1 > 1999990"))
))
#>                                        what elapsed_per_run
#> 1                      duckdb  read_parquet           0.006
#> 2       polars  scan_parquet, filter pushed           0.018
#> 3 polars  scan_parquet, filter not pushable           0.027

unlink(c(path, path2))
dbDisconnect(con2)
dbDisconnect(con)
```

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
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
#> ─ Packages ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  package     * version     date (UTC) lib source
#>  bit           4.6.0       2025-03-06 [1] RSPM
#>  bit64         4.8.2       2026-05-19 [1] RSPM (R 4.5.0)
#>  cli           3.6.6       2026-04-09 [1] RSPM
#>  DBI         * 1.3.0       2026-02-25 [1] RSPM
#>  digest        0.6.39      2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9012  2026-08-08 [1] local
#>  evaluate      1.0.5       2025-08-27 [1] RSPM
#>  fastmap       1.2.0       2024-05-15 [1] RSPM
#>  fs            2.1.0       2026-04-18 [1] RSPM
#>  glue          1.8.1       2026-04-17 [1] RSPM
#>  htmltools     0.5.9       2025-12-04 [1] RSPM
#>  knitr         1.51        2025-12-20 [1] RSPM
#>  lifecycle     1.0.5       2026-01-08 [1] RSPM
#>  nanoarrow   * 0.9.0       2026-08-04 [1] RSPM (R 4.5.0)
#>  otel          0.2.0       2025-08-29 [1] RSPM
#>  pillar        1.11.1      2025-09-17 [1] RSPM
#>  polars      * 1.14.0.9000 2026-08-08 [1] https://rpolars.r-universe.dev (R 4.5.3)
#>  reprex        2.1.1       2024-07-06 [1] RSPM
#>  rlang         1.3.0       2026-07-05 [1] RSPM
#>  rmarkdown     2.31        2026-03-26 [1] RSPM
#>  S7            0.2.2       2026-04-22 [1] RSPM
#>  sessioninfo   1.2.4       2026-06-04 [1] RSPM
#>  vctrs         0.7.3       2026-04-11 [1] RSPM (R 4.5.0)
#>  withr         3.0.3       2026-06-19 [1] RSPM (R 4.5.0)
#>  xfun          0.60        2026-07-09 [1] RSPM
#>  yaml          2.3.12      2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

</details>
