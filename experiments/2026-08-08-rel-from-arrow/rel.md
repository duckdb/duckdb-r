``` r
# What the relational API can do with an Arrow or nanoarrow source today,
# and where the seams are. There is no rel_from_arrow(): the only route
# in is rel_from_sql() over a name registered with duckdb_register_arrow(),
# so what follows measures that route.

# The recorded run is rel.md, rendered with reprex::reprex(si = TRUE).

library(duckdb)
#> Loading required package: DBI
library(arrow, warn.conflicts = FALSE)
library(nanoarrow)
options(width = 200)

new_con <- function() dbConnect(duckdb(shared_home = FALSE))

# rel_to_altrep() defers everything, including errors, to first access;
# row.names() is enough to force the whole frame.
materialize <- function(rel) {
  df <- duckdb:::rel_to_altrep(rel)
  force(row.names(df))
  df
}

packageVersion("duckdb")
#> [1] '1.5.5.9012'
packageVersion("arrow")
#> [1] '25.0.0'
packageVersion("nanoarrow")
#> [1] '0.9.0'

# A nanoarrow-only producer at the same seam, to stand in for a source
# that cannot apply a filter.
register_nanoarrow <- function(con, name, x) {
  export_fun <- function(x, stream_ptr, projection = NULL, filter = TRUE) {
    if (!is.null(projection)) x <- x[projection]
    nanoarrow::nanoarrow_pointer_export(
      nanoarrow::as_nanoarrow_array_stream(x), stream_ptr
    )
  }
  get_schema_fun <- function(x, schema_ptr) {
    nanoarrow::nanoarrow_pointer_export(
      nanoarrow::infer_nanoarrow_schema(x), schema_ptr
    )
  }
  expr_factory <- function(...) structure(list(...), class = "unused_expression")
  duckdb:::rapi_register_arrow(
    con@conn_ref, name,
    list(export_fun, expr_factory, expr_factory, expr_factory, get_schema_fun), x
  )
  invisible(TRUE)
}

df <- data.frame(a = 1:5, b = letters[1:5])
tbl <- arrow::as_arrow_table(df)

# --- 1. There is no rel_from_arrow() -----------------------------------

# rel_from_df() takes the data frame route: as.data.frame() materializes
# the Arrow table into R vectors first, so nothing Arrow survives.
con <- new_con()
rel_df <- duckdb:::rel_from_df(con, tbl)
duckdb:::rel_tostring(rel_df)
#> [1] "---------------------\n--- Relation Tree ---\n---------------------\nr_dataframe_scan(0x563063ce5e48)\n\n---------------------\n-- Result Columns  --\n---------------------\n- a (INTEGER)\n- b (VARCHAR)\n"

# rel_from_table_function() cannot express arrow_scan: its arguments are
# three POINTER values, and the R side only builds scalars.
try(duckdb:::rel_from_table_function(con, "arrow_scan", list(0, 0, 0)))
#> Error : {"exception_type":"Binder","exception_message":"No function matches the given name and argument types 'arrow_scan(DOUBLE, DOUBLE, DOUBLE)'. You might need to add explicit type casts.\n\tCandidate functions:\n\tarrow_scan(POINTER, POINTER, POINTER)\n","error_subtype":"NO_MATCHING_FUNCTION","catalog":"system","schema":"main","call":"arrow_scan(DOUBLE, DOUBLE, DOUBLE)","candidates":"arrow_scan(POINTER, POINTER, POINTER)","name":"arrow_scan"}

# --- 2. rel_from_sql() over a registered name --------------------------

duckdb_register_arrow(con, "arrow_tbl", tbl)
rel <- duckdb:::rel_from_sql(con, "FROM arrow_tbl")
duckdb:::rel_names(rel)
#> [1] "a" "b"
duckdb:::rel_tostring(rel)
#> [1] "---------------------\n--- Relation Tree ---\n---------------------\nSubquery\n\n---------------------\n-- Result Columns  --\n---------------------\n- a (INTEGER)\n- b (VARCHAR)\n"

# The verbs compose over it like any other relation.
proj <- duckdb:::rel_project(rel, list(duckdb:::expr_reference("a")))
filt <- duckdb:::rel_filter(rel, list(duckdb:::expr_comparison(
  ">", list(duckdb:::expr_reference("a"), duckdb:::expr_constant(3L))
)))
materialize(proj)
#>   a
#> 1 1
#> 2 2
#> 3 3
#> 4 4
#> 5 5
materialize(filt)
#>   a b
#> 1 4 d
#> 2 5 e

# Joining an Arrow-backed relation with a data-frame-backed one works.
rel_b <- duckdb:::rel_from_df(con, data.frame(a = 3:6, z = 1:4))
joined <- duckdb:::rel_inner_join(rel, rel_b, list(duckdb:::expr_comparison(
  "==", list(duckdb:::expr_reference("a", rel), duckdb:::expr_reference("a", rel_b))
)))
materialize(joined)
#>   a b a z
#> 1 3 c 3 1
#> 2 4 d 4 2
#> 3 5 e 5 3

# --- 3. The filter reaches the producer, for better and worse ----------

# With arrow, the pushed-down filter is translated to an Arrow expression
# and applied by the scanner: the plan shows Filters on the scan.
cat(duckdb:::rel_explain(filt)[[2]])
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

# With the nanoarrow shim, the same relation returns unfiltered rows,
# because the producer ignores the filter and nothing above re-applies it.
register_nanoarrow(con, "na_tbl", df)
rel_na <- duckdb:::rel_from_sql(con, "FROM na_tbl")
filt_na <- duckdb:::rel_filter(rel_na, list(duckdb:::expr_comparison(
  ">", list(duckdb:::expr_reference("a"), duckdb:::expr_constant(3L))
)))
materialize(filt_na)
#>   a b
#> 1 1 a
#> 2 2 b
#> 3 3 c
#> 4 4 d
#> 5 5 e

# --- 4. A relation over a name is bound late ---------------------------

# rel_from_sql() records the *query*, not the source. For a data frame
# found by environment scan, EnvironmentScanReplacement marks the table
# reference as depending on external state, so the pointer is frozen into
# a CTE at relation-creation time and later re-binds see the old data.
local({
  con <- dbConnect(duckdb(shared_home = FALSE, environment_scan = TRUE))
  env_df <- data.frame(a = 1:3)
  rel <- duckdb:::rel_from_sql(con, "FROM env_df", env = environment())
  env_df <- data.frame(a = 101:103)
  materialize(rel)
})
#>   a
#> 1 1
#> 2 2
#> 3 3

# ArrowScanReplacement sets no such dependency, so the name is resolved
# again at materialization: re-registering it under the same name swaps
# the data out from under a relation that already exists.
local({
  con <- new_con()
  duckdb_register_arrow(con, "swap", arrow::as_arrow_table(data.frame(a = 1:3)))
  rel <- duckdb:::rel_from_sql(con, "FROM swap")
  duckdb_unregister_arrow(con, "swap")
  duckdb_register_arrow(con, "swap", arrow::as_arrow_table(data.frame(a = 101:103)))
  materialize(rel)
})
#>     a
#> 1 101
#> 2 102
#> 3 103

# And unregistering without re-registering leaves the relation pointing
# at a name that no longer resolves. Run out of process: an unbound
# arrow scan is the kind of thing that can take the session with it.
callr::r(function(materialize) {
  library(duckdb)
  con <- dbConnect(duckdb(shared_home = FALSE))
  duckdb_register_arrow(con, "gone", arrow::as_arrow_table(data.frame(a = 1:3)))
  rel <- duckdb:::rel_from_sql(con, "FROM gone")
  duckdb_unregister_arrow(con, "gone")
  tryCatch(
    materialize(rel),
    error = function(e) paste("error:", conditionMessage(e))
  )
}, args = list(materialize = materialize))
#> [1] "error: Error evaluating duckdb query: Catalog Error: Table with name gone does not exist!\nDid you mean \"pg_index\"?\n\nLINE 1: SELECT * FROM gone\n             ^\nℹ Context: GetQueryResult"

# A data frame registered by name behaves the same way, so the freezing
# above is the environment scan's doing and not the data frame's: what
# survives an unregistration is a relation built from a pointer, not one
# built from a name.
callr::r(function(materialize) {
  library(duckdb)
  con <- dbConnect(duckdb(shared_home = FALSE))
  duckdb_register(con, "gone", data.frame(a = 1:3))
  rel <- duckdb:::rel_from_sql(con, "FROM gone")
  duckdb_unregister(con, "gone")
  tryCatch(
    materialize(rel),
    error = function(e) paste("error:", conditionMessage(e))
  )
}, args = list(materialize = materialize))
#> [1] "error: Error evaluating duckdb query: Catalog Error: Table with name gone does not exist!\nDid you mean \"pg_index\"?\n\nLINE 1: SELECT * FROM gone\n             ^\nℹ Context: GetQueryResult"

# --- 5. What the data frame detour costs -------------------------------

n <- 1e6
big <- data.frame(i = seq_len(n), d = as.numeric(seq_len(n)),
                  s = rep(letters, length.out = n), stringsAsFactors = FALSE)
big_tbl <- arrow::as_arrow_table(big)

con2 <- new_con()
duckdb_register_arrow(con2, "arrow_big", big_tbl)
register_nanoarrow(con2, "na_big", big)

timing <- function(label, expr) {
  expr <- substitute(expr)
  t <- system.time(for (i in 1:3) eval(expr, parent.frame()))
  data.frame(what = label, elapsed_per_run = round(unname(t[["elapsed"]]) / 3, 3))
}

sum_of <- function(name) {
  rel <- duckdb:::rel_from_sql(con2, paste0("SELECT sum(i) AS s FROM ", name))
  materialize(rel)
}

do.call(rbind, list(
  timing("rel_from_df(arrow table)", duckdb:::rel_from_df(con2, big_tbl)),
  timing("rel_from_df(data frame)", duckdb:::rel_from_df(con2, big)),
  timing("rel over arrow_scan", sum_of("arrow_big")),
  timing("rel over nanoarrow shim", sum_of("na_big"))
))
#>                       what elapsed_per_run
#> 1 rel_from_df(arrow table)           0.026
#> 2  rel_from_df(data frame)           0.002
#> 3      rel over arrow_scan           0.008
#> 4  rel over nanoarrow shim           0.021

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
#>  arrow       * 25.0.0     2026-07-16 [1] RSPM (R 4.5.0)
#>  assertthat    0.2.1      2019-03-21 [1] RSPM (R 4.5.0)
#>  bit           4.6.0      2025-03-06 [1] RSPM
#>  bit64         4.8.2      2026-05-19 [1] RSPM (R 4.5.0)
#>  callr         3.8.0      2026-06-05 [1] RSPM
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9012 2026-08-08 [1] local
#>  evaluate      1.0.5      2025-08-27 [1] RSPM
#>  fastmap       1.2.0      2024-05-15 [1] RSPM
#>  fs            2.1.0      2026-04-18 [1] RSPM
#>  glue          1.8.1      2026-04-17 [1] RSPM
#>  htmltools     0.5.9      2025-12-04 [1] RSPM
#>  knitr         1.51       2025-12-20 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  magrittr      2.0.5      2026-04-04 [1] RSPM
#>  nanoarrow   * 0.9.0      2026-08-04 [1] RSPM (R 4.5.0)
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  pillar        1.11.1     2025-09-17 [1] RSPM
#>  processx      3.9.0      2026-04-22 [1] RSPM
#>  ps            1.9.3      2026-04-20 [1] RSPM
#>  purrr         1.2.2      2026-04-10 [1] RSPM
#>  R6            2.6.1      2025-02-15 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.31       2026-03-26 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  tidyselect    1.2.1      2024-03-11 [1] RSPM
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
