# Handbook: handbook/usage/integrations/README.md (what the reader streams, and its limits)
#' Stream a dbplyr table on DuckDB into Arrow
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `to_arrow_stream()` is a streaming counterpart of `arrow::to_arrow()`
#' for dbplyr tables on a DuckDB connection.
#' It sends the query with [DBI::dbGetQueryArrow()]
#' and hands the stream to `arrow::as_record_batch_reader()`,
#' so the rows arrive batch by batch and the result is not held twice.
#' `arrow::to_arrow()` materializes the whole result first,
#' through `dbSendQuery(arrow = TRUE)`.
#'
#' The streaming comes with hard limits, listed under "Limitations" below.
#' Use `to_arrow_stream()` where a large result goes straight into Arrow
#' and nothing else runs on its connection until the reader has been read
#' to the end.
#' Where that cannot be arranged, use `arrow::to_arrow()`,
#' or run everything else on a second connection.
#'
#' @section Limitations:
#' The reader is its connection's open result until it has been read to the
#' end.
#'
#' - **Any other statement on the connection breaks the reader.**
#'   The next read fails with "The query result was invalidated by another
#'   statement on its connection".
#'   dplyr and dbplyr run such statements without being asked:
#'   `dplyr::tbl()` asks for the columns of a table,
#'   and printing or collecting a lazy table runs its query.
#'   A second `to_arrow_stream()` on the same connection breaks the first
#'   reader too.
#' - **A query that scans the reader on its own connection never returns.**
#'   `arrow::to_duckdb(reader, con = con)` is such a query,
#'   and so is a query on `con` after `duckdb_register_arrow(con, name, reader)`.
#'   Ctrl-C does not stop it, and the R session has to be killed.
#' - **Tables from `arrow::to_duckdb()` share one connection.**
#'   Without `con`, `to_duckdb()` uses the one connection that arrow keeps.
#'   For such a table, a later `to_duckdb()` without `con` breaks the reader,
#'   and one on the reader itself never returns.
#' - **Writing the reader back to its own connection fails partway.**
#'   [DBI::dbWriteTableArrow()] creates the table, then fails and leaves it
#'   empty.
#'   [DBI::dbAppendTableArrow()] appends the first batch of rows, then fails.
#' - **Ctrl-C does not interrupt a read.**
#'   Arrow reads the reader on its own threads,
#'   outside the package's interrupt handler.
#' - **Errors arrive late.**
#'   A query that fails after its first batch fails at a later read,
#'   not in `to_arrow_stream()`.
#' - **The reader is read once.**
#'   Reading it again gives zero rows, not the result again.
#'
#' A second connection to the same database, such as
#' `DBI::dbConnect(con@driver)`, neither affects the reader nor is affected by
#' it.
#' It does not see the first connection's temporary tables or open
#' transaction.
#' The reader stays readable after [DBI::dbDisconnect()].
#' It keeps the database instance open until it is garbage-collected,
#' even once it has been read to the end ([duckdb()]).
#'
#' @param .data A dbplyr table on a DuckDB connection, or an Arrow object,
#'   which is returned unchanged.
#' @return An Arrow `RecordBatchReader`,
#'   or an `arrow_dplyr_query` over it if `.data` is grouped.
#' @export
#' @examplesIf simulate_duckdb()$env$examples_enabled() && all(vapply(c("arrow", "dbplyr", "dplyr", "nanoarrow"), requireNamespace, logical(1), quietly = TRUE))
#' con <- dbConnect(duckdb())
#' dbWriteTable(con, "mtcars", mtcars)
#'
#' # Read the reader to the end before anything else runs on `con`.
#' reader <- to_arrow_stream(dplyr::filter(dplyr::tbl(con, "mtcars"), cyl == 4))
#' as.data.frame(reader$read_table())
#'
#' # Another statement on `con` breaks a reader that has not been read yet.
#' reader <- to_arrow_stream(dplyr::tbl(con, "mtcars"))
#' dbGetQuery(con, "SELECT 1")
#' try(reader$read_table())
#'
#' # A second connection to the same database leaves the reader alone.
#' other <- dbConnect(con@driver)
#' reader <- to_arrow_stream(dplyr::tbl(con, "mtcars"))
#' dbGetQuery(other, "SELECT count(*) FROM mtcars")
#' reader$read_table()$num_rows
#'
#' dbDisconnect(other)
#' dbDisconnect(con)
to_arrow_stream <- function(.data) {
  if (inherits(.data, c("arrow_dplyr_query", "ArrowObject"))) {
    return(.data)
  }
  for (pkg in c("arrow", "dbplyr", "dplyr", "nanoarrow")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      abort(sprintf("`to_arrow_stream()` requires the `%s` package.", pkg))
    }
  }

  con <- if (inherits(.data, "tbl_lazy")) dbplyr::remote_con(.data)
  # simulate_duckdb() is an S3 list that carries the class of a connection.
  if (!isS4(con) || !inherits(con, "duckdb_connection")) {
    abort(paste(
      "`to_arrow_stream()` takes a dbplyr table on a DuckDB connection",
      "or an Arrow object."
    ))
  }
  if (!dbIsValid(con)) {
    abort("`to_arrow_stream()` needs the connection of `.data` to be open.")
  }
  groups <- dplyr::groups(.data)

  # dbGetQueryArrow() clears the DBI result as it hands the stream over;
  # the stream owns the engine's query result from then on,
  # and the reader owns the stream.
  stream <- DBI::dbGetQueryArrow(con, dbplyr::remote_query(.data))
  out <- arrow::as_record_batch_reader(stream)

  if (length(groups) > 0) {
    out <- dplyr::group_by(out, !!!groups)
  }
  out
}
