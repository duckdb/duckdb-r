# allow_materialization = TRUE: compatibility with duckplyr <= 0.4.1
rapi_rel_to_altrep <- function(rel, allow_materialization = TRUE, n_row = Inf, n_cells = Inf) {
  .Call(`_duckdb_rapi_rel_to_altrep`, rel, allow_materialization, n_row, n_cells)
}
