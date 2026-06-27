# The "shared" storage root must resolve to the same `~/.duckdb` the bundled
# DuckDB engine, its CLI, and the Python client use. DuckDB derives the home
# from USERPROFILE on Windows and HOME elsewhere (see
# FileSystem::GetHomeDirectory() in src/duckdb/src/common/file_system.cpp), not
# from R's `path.expand("~")`, which on Windows points at the Documents folder.

test_that("duckdb_home_directory follows HOME on non-Windows", {
  local_mocked_bindings(is_windows = function() FALSE)
  withr::local_envvar(HOME = "/home/someone")
  expect_equal(duckdb_home_directory(), "/home/someone")
})

test_that("duckdb_home_directory follows USERPROFILE on Windows", {
  local_mocked_bindings(is_windows = function() TRUE)
  withr::local_envvar(
    USERPROFILE = "C:/Users/someone",
    # HOME must be ignored on Windows, matching the engine.
    HOME = "C:/Users/someone/Documents"
  )
  expect_equal(duckdb_home_directory(), "C:/Users/someone")
})

test_that("duckdb_home_directory falls back to path.expand when the env var is unset", {
  local_mocked_bindings(is_windows = function() FALSE)
  withr::local_envvar(HOME = NA)
  # Whatever R considers home, never the empty/rootless ".duckdb".
  expect_equal(duckdb_home_directory(), path.expand("~"))
})

test_that("duckdb_shared_home appends .duckdb to the home directory", {
  local_mocked_bindings(duckdb_home_directory = function() "/home/someone")
  expect_equal(duckdb_shared_home(), file.path("/home/someone", ".duckdb"))
})

test_that("duckdb_shared_home does not use the Windows Documents folder", {
  # Regression test for the original `path.expand('~/.duckdb')`, which on
  # Windows expands to `<USERPROFILE>/Documents/.duckdb`.
  local_mocked_bindings(is_windows = function() TRUE)
  withr::local_envvar(USERPROFILE = "C:/Users/someone")
  expect_equal(duckdb_shared_home(), file.path("C:/Users/someone", ".duckdb"))
  expect_false(grepl("Documents", duckdb_shared_home(), fixed = TRUE))
})
