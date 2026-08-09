# The context the DBI conformance suite runs against: a driver, and the tweaks
# that say how DuckDB answers wherever the standard leaves a choice.
# `test-DBItest.R` runs the suite; everything it needs to know about this
# backend is here, so a suite failure is read as either a tweak that misstates
# the backend or a genuine deviation from DBI.
#
# The driver is on disk rather than in memory, so the suite exercises the file
# backend; the finalizer removes that file once the database reference is
# collected. It is created here because the context is, and the context is
# created here because it must be -- see below.

drv <- duckdb(tempfile(fileext = ".duckdb"))
reg.finalizer(drv@database_ref, function(x) {
  unlink(drv@dbdir, force = TRUE)
})

# remotes::install_github("r-dbi/dblog")
# Then, use DBItest::test_some() to see the DBI calls emitted by the tests
#
# This call must stay here, otherwise DBItest::test_some() doesn't work
if (rlang::is_installed("DBItest")) {
  DBItest::make_context(
    drv,
    # dblog::dblog(drv),
    list(debug = FALSE),
    tweaks = DBItest::tweaks(
      dbitest_version = "1.8.3",
      omit_blob_tests = FALSE,
      temporary_tables = FALSE,
      placeholder_pattern = "?",
      timestamp_cast = function(x) sprintf("CAST('%s' AS TIMESTAMP)", x),
      date_cast = function(x) sprintf("CAST('%s' AS DATE)", x),
      time_cast = function(x) sprintf("CAST('%s' AS TIME)", x),
      blob_cast = function(x) sprintf("%s::BLOB", x)
    ),
    name = get_package_name()
  )
}
