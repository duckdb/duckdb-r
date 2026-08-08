# What the relational API can do with an Arrow or nanoarrow source today,
# and where the seams are. There is no rel_from_arrow(): the only route
# in is rel_from_sql() over a name registered with duckdb_register_arrow(),
# so what follows measures that route.

# The recorded run is rel.md, rendered with reprex::reprex(si = TRUE).

library(duckdb)
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
packageVersion("arrow")
packageVersion("nanoarrow")

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

# rel_from_table_function() cannot express arrow_scan: its arguments are
# three POINTER values, and the R side only builds scalars.
try(duckdb:::rel_from_table_function(con, "arrow_scan", list(0, 0, 0)))

# --- 2. rel_from_sql() over a registered name --------------------------

duckdb_register_arrow(con, "arrow_tbl", tbl)
rel <- duckdb:::rel_from_sql(con, "FROM arrow_tbl")
duckdb:::rel_names(rel)
duckdb:::rel_tostring(rel)

# The verbs compose over it like any other relation.
proj <- duckdb:::rel_project(rel, list(duckdb:::expr_reference("a")))
filt <- duckdb:::rel_filter(rel, list(duckdb:::expr_comparison(
  ">", list(duckdb:::expr_reference("a"), duckdb:::expr_constant(3L))
)))
materialize(proj)
materialize(filt)

# Joining an Arrow-backed relation with a data-frame-backed one works.
rel_b <- duckdb:::rel_from_df(con, data.frame(a = 3:6, z = 1:4))
joined <- duckdb:::rel_inner_join(rel, rel_b, list(duckdb:::expr_comparison(
  "==", list(duckdb:::expr_reference("a", rel), duckdb:::expr_reference("a", rel_b))
)))
materialize(joined)

# --- 3. The filter reaches the producer, for better and worse ----------

# With arrow, the pushed-down filter is translated to an Arrow expression
# and applied by the scanner: the plan shows Filters on the scan.
cat(duckdb:::rel_explain(filt)[[2]])

# With the nanoarrow shim, the same relation returns unfiltered rows,
# because the producer ignores the filter and nothing above re-applies it.
register_nanoarrow(con, "na_tbl", df)
rel_na <- duckdb:::rel_from_sql(con, "FROM na_tbl")
filt_na <- duckdb:::rel_filter(rel_na, list(duckdb:::expr_comparison(
  ">", list(duckdb:::expr_reference("a"), duckdb:::expr_constant(3L))
)))
materialize(filt_na)

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

dbDisconnect(con2)
dbDisconnect(con)
