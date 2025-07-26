#' Create or Replace a View from a `tbl` in DuckDB
#'
#' This function creates or replaces a view in DuckDB from a `dbplyr`-based `tbl` object.
#' It converts the lazy query associated with the `tbl` into SQL and defines a named view in the database.
#'
#' @param data A `tbl_dbi` object, typically produced by `dplyr::tbl()` or `dbplyr` pipelines.
#' @param view_name A character string specifying the name of the view to create.
#'
#' @return A `tbl` object pointing on the created view (invisible)
#'
#' @details
#' The function uses `CREATE OR REPLACE VIEW`, which means it will overwrite an existing view with the same name.
#' The view is created in the same DuckDB connection used by the `tbl`. The query is lazily evaluated.
#'
#' @examples
#'   con <- DBI::dbConnect(duckdb::duckdb())
#'   copy_to(con, tibble(a = 1:3, b = letters[1:3]), "source_table", temporary = TRUE)
#'   data <- dplyr::tbl(con, "source_table") %>% dplyr::filter(a > 1)
#'   create_view(data, "filtered_view")
#'   DBI::dbGetQuery(con, "SELECT * FROM filtered_view")
#'   DBI::dbDisconnect(con, shutdown = TRUE)
#'
#' @importFrom DBI dbExecute dbQuoteIdentifie
#' @importFrom dbplyr remote_con sql_render
#' @export
create_view <- function(data, view_name) {
  if (!inherits(data, "tbl_dbi")) stop("'data' must be a 'tbl_dbi' object.")

  con <- dbplyr::remote_con(data)
  sql <- dbplyr::sql_render(data, con = con)

  sql <- sprintf("CREATE OR REPLACE VIEW %s AS %s", DBI::dbQuoteIdentifier(con, view_name), sql)

  DBI::dbExecute(con, sql)

  invisible(tbl(con, view_name))
}
