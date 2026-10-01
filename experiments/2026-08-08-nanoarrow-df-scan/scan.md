``` r
# What a nanoarrow-only data frame scan does today, measured against the
# built-in r_dataframe_scan. Uses no C++ changes: the closures that
# duckdb_register_arrow() passes to rapi_register_arrow() are ordinary R
# functions, so nanoarrow can be substituted for arrow at that seam.

# The recorded run is scan.md, rendered with reprex::reprex(si = TRUE).

library(duckdb)
#> Loading required package: DBI
library(nanoarrow)
options(width = 200)

# Keep the run hermetic: no shared extension/secret home.
new_con <- function() dbConnect(duckdb(shared_home = FALSE))

packageVersion("duckdb")
#> [1] '1.5.5.9012'
packageVersion("nanoarrow")
#> [1] '0.9.0'

# --- The nanoarrow-only registration shim ------------------------------

# rapi_register_arrow() takes five closures: an exporter, three Arrow
# expression factories used for filter pushdown, and a schema exporter.
# Only the exporter and the schema exporter need Arrow semantics; the
# expression factories are reached only when DuckDB pushes a filter down.
register_nanoarrow <- function(con, name, x, on_filter = c("ignore", "error")) {
  on_filter <- match.arg(on_filter)

  export_fun <- function(x, stream_ptr, projection = NULL, filter = TRUE) {
    if (!is.null(projection)) {
      x <- x[projection]
    }
    stream <- nanoarrow::as_nanoarrow_array_stream(x)
    nanoarrow::nanoarrow_pointer_export(stream, stream_ptr)
  }

  get_schema_fun <- function(x, schema_ptr) {
    schema <- nanoarrow::infer_nanoarrow_schema(x)
    nanoarrow::nanoarrow_pointer_export(schema, schema_ptr)
  }

  expr_factory <- switch(on_filter,
    ignore = function(...) structure(list(...), class = "unused_expression"),
    error = function(...) stop("nanoarrow source cannot apply filters")
  )

  duckdb:::rapi_register_arrow(
    con@conn_ref,
    name,
    list(export_fun, expr_factory, expr_factory, expr_factory, get_schema_fun),
    x
  )
  invisible(TRUE)
}

con <- new_con()

# --- 1. Does it scan at all? -------------------------------------------

df <- data.frame(a = 1:5, b = letters[1:5])
register_nanoarrow(con, "na_tbl", df)

dbGetQuery(con, "SELECT * FROM na_tbl")
#>   a b
#> 1 1 a
#> 2 2 b
#> 3 3 c
#> 4 4 d
#> 5 5 e

# Projection pushdown: DuckDB asks for the columns it needs, by name.
dbGetQuery(con, "SELECT b FROM na_tbl")
#>   b
#> 1 a
#> 2 b
#> 3 c
#> 4 d
#> 5 e

# count(*) still projects one column, so the exporter is never called
# with a NULL projection in practice.
dbGetQuery(con, "SELECT count(*) FROM na_tbl")
#>   count_star()
#> 1            5

# The source is scanned afresh every time, so repeated scans and
# self-joins both work.
dbGetQuery(con, "SELECT sum(a) FROM na_tbl")
#>   sum(a)
#> 1     15
dbGetQuery(con, "SELECT count(*) FROM na_tbl x JOIN na_tbl y USING (a)")
#>   count_star()
#> 1            5

# --- 2. Filter pushdown is not optional --------------------------------

# arrow_scan sets filter_pushdown = true, and PhysicalTableScan does not
# re-apply what it hands to the producer: a producer that ignores the
# filter returns the wrong rows, silently.
dbGetQuery(con, "SELECT * FROM na_tbl WHERE a > 3")
#>   a b
#> 1 1 a
#> 2 2 b
#> 3 3 c
#> 4 4 d
#> 5 5 e

cat(dbGetQuery(con, "EXPLAIN SELECT * FROM na_tbl WHERE a > 3")[[2]])
#> ┌───────────────────────────┐
#> │         ARROW_SCAN        │
#> │    ────────────────────   │
#> │    Function: ARROW_SCAN   │
#> │                           │
#> │        Projections:       │
#> │             a             │
#> │             b             │
#> │                           │
#> │        Filters: a>3       │
#> │                           │
#> │           ~1 row          │
#> └───────────────────────────┘

# Failing loudly instead is a one-line change in the shim, and it fails
# for every filtered query rather than only the unrepresentable ones.
register_nanoarrow(con, "na_strict", df, on_filter = "error")
try(dbGetQuery(con, "SELECT * FROM na_strict WHERE a > 3"))
#> Error in duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow) : 
#>   Invalid Error: Invalid Error: std::exception
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID

# A materialized CTE gets the right answer back -- but not by
# suppressing the pushdown. The filter is still pushed into the scan and
# still ignored there; what fixes the answer is that DuckDB applies it a
# second time above the materialization barrier.
dbGetQuery(
  con,
  "WITH t AS MATERIALIZED (SELECT * FROM na_tbl) SELECT * FROM t WHERE a > 3"
)
#>   a b
#> 1 4 d
#> 2 5 e

cat(dbGetQuery(
  con,
  "EXPLAIN WITH t AS MATERIALIZED (SELECT * FROM na_tbl) SELECT * FROM t WHERE a > 3"
)[[2]])
#> ┌───────────────────────────┐
#> │            CTE            │
#> │    ────────────────────   │
#> │        CTE Name: t        │
#> │       Table Index: 0      ├──────────────┐
#> │                           │              │
#> │           ~1 row          │              │
#> └─────────────┬─────────────┘              │
#> ┌─────────────┴─────────────┐┌─────────────┴─────────────┐
#> │         ARROW_SCAN        ││           FILTER          │
#> │    ────────────────────   ││    ────────────────────   │
#> │    Function: ARROW_SCAN   ││          (a > 3)          │
#> │                           ││                           │
#> │        Projections:       ││                           │
#> │             a             ││                           │
#> │             b             ││                           │
#> │                           ││                           │
#> │        Filters: a>3       ││                           │
#> │                           ││                           │
#> │           ~1 row          ││           ~1 row          │
#> └───────────────────────────┘└─────────────┬─────────────┘
#>                              ┌─────────────┴─────────────┐
#>                              │          CTE_SCAN         │
#>                              │    ────────────────────   │
#>                              │        CTE Index: 0       │
#>                              │                           │
#>                              │           ~1 row          │
#>                              └───────────────────────────┘

# --- 3. A one-shot stream is not a table -------------------------------

# Anything that is consumed on read cannot back a view: it has no
# columns to project and nothing to replay.
register_nanoarrow(con, "one_shot", nanoarrow::as_nanoarrow_array_stream(df))
try(dbGetQuery(con, "SELECT count(*) FROM one_shot"))
#> Error in duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow) : 
#>   Invalid Error: Invalid Error: std::exception
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID

# --- 4. Type fidelity, nanoarrow against r_dataframe_scan --------------

types <- list(
  logical = c(TRUE, FALSE, NA),
  integer = c(1L, 2L, NA),
  double = c(1.5, 2.5, NA),
  character = c("a", "äöü", NA),
  factor = factor(c("x", "y", NA)),
  Date = as.Date(c("2024-01-01", "2024-06-15", NA)),
  POSIXct_utc = as.POSIXct(c("2024-01-01 10:00:00", "2024-06-15 10:00:00", NA), tz = "UTC"),
  POSIXct_tz = as.POSIXct(c("2024-01-01 10:00:00", "2024-06-15 10:00:00", NA), tz = "Europe/Zurich"),
  difftime_secs = as.difftime(c(1, 2, NA), units = "secs"),
  difftime_days = as.difftime(c(1, 2, NA), units = "days"),
  integer64 = bit64::as.integer64(c(1, 2, NA)),
  hms = hms::as_hms(c(1, 2, NA)),
  blob = blob::blob(as.raw(1:3), as.raw(4:6), NULL),
  list_int = list(1:2, integer(), NULL),
  struct = NULL # filled in below, a data frame column
)
types$struct <- data.frame(x = 1:3, y = c("a", "b", NA))

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
        register_nanoarrow(con, "t", df)
      }
      type <- dbGetQuery(con, "SELECT typeof(x) AS t FROM t LIMIT 1")$t[[1]]
      list(type = type, value = dbGetQuery(con, "SELECT * FROM t")$x)
    },
    error = function(e) {
      list(type = paste("ERROR:", conditionMessage(e)), value = NULL)
    }
  )
}

grid <- do.call(rbind, lapply(names(types), function(name) {
  native <- probe_one(types[[name]], "r_dataframe_scan")
  nano <- probe_one(types[[name]], "nanoarrow")
  data.frame(
    column = name,
    native_type = native$type,
    nanoarrow_type = nano$type,
    native_roundtrips = identical(native$value, types[[name]]),
    nanoarrow_roundtrips = identical(nano$value, types[[name]]),
    agree = identical(native$value, nano$value),
    stringsAsFactors = FALSE
  )
}))
grid$native_type <- substr(grid$native_type, 1, 32)
grid$nanoarrow_type <- substr(grid$nanoarrow_type, 1, 32)
grid
#>           column                  native_type                   nanoarrow_type native_roundtrips nanoarrow_roundtrips agree
#> 1        logical                      BOOLEAN                          BOOLEAN              TRUE                 TRUE  TRUE
#> 2        integer                      INTEGER                          INTEGER              TRUE                 TRUE  TRUE
#> 3         double                       DOUBLE                           DOUBLE              TRUE                 TRUE  TRUE
#> 4      character                      VARCHAR                          VARCHAR              TRUE                 TRUE  TRUE
#> 5         factor               ENUM('x', 'y')                          VARCHAR              TRUE                FALSE FALSE
#> 6           Date                         DATE                             DATE              TRUE                 TRUE  TRUE
#> 7    POSIXct_utc                    TIMESTAMP         TIMESTAMP WITH TIME ZONE              TRUE                FALSE FALSE
#> 8     POSIXct_tz                    TIMESTAMP         TIMESTAMP WITH TIME ZONE             FALSE                FALSE FALSE
#> 9  difftime_secs                     INTERVAL                         INTERVAL              TRUE                 TRUE  TRUE
#> 10 difftime_days                     INTERVAL                         INTERVAL             FALSE                FALSE  TRUE
#> 11     integer64                       DOUBLE                           BIGINT             FALSE                FALSE FALSE
#> 12           hms                     INTERVAL                             TIME             FALSE                FALSE  TRUE
#> 13          blob                         BLOB                             BLOB             FALSE                FALSE  TRUE
#> 14      list_int                    INTEGER[] ERROR: Invalid Error: std::excep              TRUE                FALSE FALSE
#> 15        struct STRUCT(x INTEGER, y VARCHAR)     STRUCT(x INTEGER, y VARCHAR)              TRUE                 TRUE  TRUE

# The one column nanoarrow cannot take at all is the bare list, and the
# reason is lost on the way through the seam: an R error raised inside
# the schema exporter reaches the caller as `std::exception`.
try(nanoarrow::infer_nanoarrow_schema(types$list_int))
#> Error in infer_nanoarrow_schema.default(types$list_int) : 
#>   Can't infer Arrow type for object of class list

# --- 5. What the export costs ------------------------------------------

n <- 1e6
big <- data.frame(
  i = seq_len(n),
  d = as.numeric(seq_len(n)),
  s = rep(letters, length.out = n),
  stringsAsFactors = FALSE
)

con2 <- new_con()
duckdb_register(con2, "native", big)
register_nanoarrow(con2, "na", big)

timing <- function(label, expr) {
  expr <- substitute(expr)
  t <- system.time(for (i in 1:3) eval(expr, parent.frame()))
  data.frame(what = label, elapsed_per_run = round(unname(t[["elapsed"]]) / 3, 3))
}

do.call(rbind, list(
  timing("native  count(*)", dbGetQuery(con2, "SELECT count(*) FROM native")),
  timing("nanoarrow count(*)", dbGetQuery(con2, "SELECT count(*) FROM na")),
  timing("native  sum(i)", dbGetQuery(con2, "SELECT sum(i) FROM native")),
  timing("nanoarrow sum(i)", dbGetQuery(con2, "SELECT sum(i) FROM na")),
  timing("native  one string column", dbGetQuery(con2, "SELECT count(DISTINCT s) FROM native")),
  timing("nanoarrow one string column", dbGetQuery(con2, "SELECT count(DISTINCT s) FROM na")),
  timing("native  full fetch", dbGetQuery(con2, "SELECT * FROM native")),
  timing("nanoarrow full fetch", dbGetQuery(con2, "SELECT * FROM na"))
))
#>                          what elapsed_per_run
#> 1            native  count(*)           0.006
#> 2          nanoarrow count(*)           0.010
#> 3              native  sum(i)           0.006
#> 4            nanoarrow sum(i)           0.010
#> 5   native  one string column           0.047
#> 6 nanoarrow one string column           0.077
#> 7          native  full fetch           0.058
#> 8        nanoarrow full fetch           0.083

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
#>  package     * version    date (UTC) lib source
#>  bit           4.6.0      2025-03-06 [1] RSPM
#>  bit64         4.8.2      2026-05-19 [1] RSPM (R 4.5.0)
#>  blob          1.3.0      2026-01-14 [1] RSPM (R 4.5.0)
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9012 2026-08-08 [1] local
#>  evaluate      1.0.5      2025-08-27 [1] RSPM
#>  fastmap       1.2.0      2024-05-15 [1] RSPM
#>  fs            2.1.0      2026-04-18 [1] RSPM
#>  glue          1.8.1      2026-04-17 [1] RSPM
#>  hms           1.1.4      2025-10-17 [1] RSPM (R 4.5.0)
#>  htmltools     0.5.9      2025-12-04 [1] RSPM
#>  knitr         1.51       2025-12-20 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  nanoarrow   * 0.9.0      2026-08-04 [1] RSPM (R 4.5.0)
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  pillar        1.11.1     2025-09-17 [1] RSPM
#>  pkgconfig     2.0.3      2019-09-22 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.31       2026-03-26 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  vctrs         0.7.3      2026-04-11 [1] RSPM (R 4.5.0)
#>  withr         3.0.3      2026-06-19 [1] RSPM (R 4.5.0)
#>  xfun          0.60       2026-07-09 [1] RSPM
#>  yaml          2.3.12     2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

</details>
