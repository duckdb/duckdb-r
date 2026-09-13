#' DuckDB error conditions
#'
#' @description
#' Every error the database engine raises reaches R as a condition of class
#' `duckdb_error`, carrying DuckDB's own classification alongside the message.
#' Catch it with [tryCatch()] or `rlang::try_fetch()` and branch on the fields
#' rather than on the message text, which is formatted for display and is not a
#' stable interface.
#'
#' @details
#' The condition is raised against the call that caused it -- [DBI::dbGetQuery()],
#' [DBI::dbExecute()], [DBI::dbBind()], [DBI::dbFetch()], and the relational API
#' alike -- and the fields survive that rethrow.
#'
#' # Fields
#'
#' \describe{
#'   \item{`error_type`}{DuckDB's exception type as a string, such as
#'     `"BINDER"`, `"PARSER"`, `"CONSTRAINT"`, `"CONVERSION"`, `"IO"` or
#'     `"OUT_OF_MEMORY"`. This is the field to classify on. The set is the
#'     engine's and grows with it, so treat an unrecognized value as "some
#'     other error" rather than failing on it.}
#'   \item{`extra_info`}{A named character vector of whatever else the engine
#'     attached to the error, for instance the position within the query.
#'     Which names appear depends on the error, and empty is a normal answer.}
#'   \item{`context`}{The internal operation that failed, such as
#'     `"rapi_prepare"` or `"rapi_execute"`. Useful to tell a failure at
#'     prepare time from one at execution time; the individual names are an
#'     implementation detail and may change.}
#'   \item{`raw_message`}{The message as the engine phrased it, without the
#'     exception type prefix and without the display formatting.}
#' }
#'
#' A field the engine did not supply is absent from the condition, so reading it
#' gives `NULL`. Classification code should therefore treat `NULL` as "unknown"
#' and keep a fallback branch: an error raised before the engine is reached, by
#' an R-level check or by a failing callback, is an ordinary error with none of
#' these fields.
#'
#' Errors are formatted with bullets when rlang is installed; without it the
#' message is a single line, and the class and the fields are the same.
#'
#' @examplesIf simulate_duckdb()$env$examples_enabled()
#' con <- dbConnect(duckdb())
#'
#' err <- tryCatch(dbGetQuery(con, "SELECT missing_column"), error = identity)
#' class(err)
#' err$error_type
#' err$context
#'
#' dbDisconnect(con, shutdown = TRUE)
#' @name duckdb_error
NULL
