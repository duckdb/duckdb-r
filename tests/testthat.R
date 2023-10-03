if (!requireNamespace("testthat", quietly=TRUE)) {
  library("testthat")
  library("DBI")
  test_check("duckdb")
} else {
  cat("Unit tests has been skipped. Install 'testthat' package and retry.\n")
}
