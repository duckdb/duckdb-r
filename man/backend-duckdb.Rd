% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/backend-dbplyr__duckdb_connection.R
\name{backend-duckdb}
\alias{simulate_duckdb}
\alias{translate_duckdb}
\title{DuckDB SQL backend for dbplyr}
\usage{
simulate_duckdb(...)

translate_duckdb(...)
}
\arguments{
\item{...}{Any parameters to be forwarded}
}
\description{
This is a SQL backend for dbplyr tailored to take into account DuckDB's
possibilities. This mainly follows the backend for PostgreSQL, but
contains more mapped functions.
}
\examples{
\dontshow{if (rlang::is_installed("dbplyr")) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
library(dplyr, warn.conflicts = FALSE)
con <- DBI::dbConnect(duckdb(), path = ":memory:")

dbiris <- copy_to(con, iris, overwrite = TRUE)

dbiris \%>\%
  select(Petal.Length, Petal.Width) \%>\%
  filter(Petal.Length > 1.5) \%>\%
  head(5)

DBI::dbDisconnect(con, shutdown = TRUE)
\dontshow{\}) # examplesIf}
}
