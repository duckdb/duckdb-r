# allow_materialization = TRUE: compatibility with duckplyr <= 0.4.1
rapi_rel_to_altrep <- function(rel, conn, allow_materialization = TRUE) {
  .Call(`_duckdb_rapi_rel_to_altrep`, rel, conn, allow_materialization)
}
