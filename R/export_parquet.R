#' Export a DuckDB table to a Parquet file using COPY TO
#'
#' This function exports a `dbplyr`-based table or SQL query to a Parquet file
#' using DuckDB's native `COPY TO` command.
#'
#' @param data A `tbl_dbi` object representing a DuckDB table or query.
#' @param output Path to the output Parquet file (a single character string).
#' @param options A named list of key-value COPY options. Values can be character,
#'   numeric, logical, or vectors (which will be converted to tuples).
#'   Examples include `compression = "zstd"` or `ROW_GROUP_SIZE = 1000000`.
#'   see https://duckdb.org/docs/sql/statements/copy.html#parquet-options for details.
#'
#' @return Returns the number of rows affected by the `COPY TO` command.
#'   The function will stop with an error if the input types are invalid.
#'
#' @details
#' Option values of length >1 are wrapped in parentheses and comma-separated
#' (e.g., for `columns = c("a", "b")`, DuckDB will receive `COLUMNS (a,b)`).
#'
#' @examples
#' con <- DBI::dbConnect(duckdb::duckdb())
#' DBI::dbWriteTable(con, "iris", iris)
#' tbl <- dplyr::tbl(con, "iris")
#' export_parquet(tbl, "iris.parquet", options = list(compression = "zstd"))
#' export_parquet(tbl, "iris_ds", options = list(partition_by = "Species", row_group_size = 1000))
#'
#' @importFrom DBI dbExecute
#' @importFrom dbplyr remote_con sql_render
#' @export
export_parquet <- function(data, output, options = NULL, print_sql = FALSE) {
  if (!inherits(data, "tbl_dbi")) stop("'data' must be a 'tbl_dbi' object.")
  if (!is.character(output) || length(output) != 1) stop("'output' must be a single character string.")
  if (!is.null(options) && !is.list(options)) stop("'options' must be a list or NULL.")

  con <- dbplyr::remote_con(data)
  sql_query <- dbplyr::sql_render(data, con = con)

  # Normalize and format options
  if (is.null(options)) options <- list()
  formatted_options <- format_copy_to_options(options)
  formatted_options$FORMAT <- 'PARQUET'

  parquet_opts <- paste(paste0(names(formatted_options), " ", formatted_options), collapse = ", ")
  sql <- sprintf("COPY (%s) TO '%s' (%s)", sql_query, output, parquet_opts)
  DBI::dbExecute(con, sql)
}


format_copy_to_options <- function(options) {
  options <- lapply(options, function(x) {
    if (is.logical(x) || is.character(x) || is.numeric(x)) as.character(x)
    else stop("All option values must be character, numeric, or logical.")

    if (length(x) > 1) x <- paste0("(",paste0(x,collapse=","),")")
    x
  })
  setNames(options, toupper(names(options)))
}
