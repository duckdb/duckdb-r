#' Run an SQL query or statement
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' `sql_query()` runs an arbitrary SQL query using [DBI::dbGetQuery()]
#' and returns a [data.frame] with the query results.
#' `sql_exec()` runs an arbitrary SQL statement using [DBI::dbExecute()]
#' and returns the number of affected rows.
#'
#' These functions are intended as an easy way to interactively run DuckDB
#' without having to manage connections.
#' By default, data frame objects are available as views.
#'
#' Scripts and packages should manage their own connections
#' and prefer the DBI methods for more control.
#'
#' @param sql A SQL string
#' @param conn An optional connection, defaults to [default_conn()]
#' @return A data frame with the query result
#' @export
#' @examples
#' # Queries
#' sql_query("SELECT 42")
#'
#' # Statements with side effects
#' sql_exec("CREATE TABLE test (a INTEGER, b VARCHAR)")
#' sql_exec("INSERT INTO test VALUES (1, 'one'), (2, 'two')")
#' sql_query("FROM test")
#'
#' # Data frames available as views
#' sql_query("FROM mtcars")
sql_query <- function(sql, conn = default_conn()) {
  stopifnot(dbIsValid(conn))
  dbGetQuery(conn, sql)
}

#' @rdname sql_query
#' @export
sql_exec <- function(sql, conn = default_conn()) {
  stopifnot(dbIsValid(conn))
  DBI::dbExecute(conn, sql)
}

the <- new.env(parent = emptyenv())

#' Get the default connection
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' `default_conn()` returns a default, built-in connection.
#'
#' @details
#' Currently, the connection is established with `duckdb(environment_scan = TRUE)`
#' and `dbConnect(timezone_out = "", array = "matrix")`
#' so that data frames are automatically available as tables,
#' timestamps are returned in the local timezone,
#' and DuckDB's array type is returned as an R matrix.
#' The details of how the connection is established are subject to change.
#' In particular, returning the output as a tibble or other object may be supported
#' in the future.
#'
#' This connection is intended for interactive use.
#' There is no way for this or other packages to comprehensively track the state
#' of this connection, so scripts and packages should manage their own connections.
#'
#' @return A DuckDB connection object
#' @export
#' @examples
#' conn <- default_conn()
#' sql_query("SELECT 42", conn = conn)
default_conn <- function() {
  if(!exists("con", the)) {
    con <- DBI::dbConnect(
      duckdb::duckdb(environment_scan = TRUE),
      timezone_out = "",
      array = "matrix"
    )

    the$con <- con
  }
  the$con
}
