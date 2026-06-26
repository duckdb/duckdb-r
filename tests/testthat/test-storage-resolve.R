# Resolution layer (plan/PLAN-storage-locations.md, Phase 1).

test_that("resolve_extension_directory honors option then env override", {
  withr::local_options(duckdb.extension_directory = "/opt/ext")
  expect_equal(
    resolve_extension_directory(),
    list(directory = "/opt/ext", source = "option")
  )

  withr::local_options(duckdb.extension_directory = NULL)
  withr::local_envvar(DUCKDB_EXTENSION_DIRECTORY = "/env/ext")
  expect_equal(
    resolve_extension_directory(),
    list(directory = "/env/ext", source = "env")
  )
})

test_that("resolve_extension_directory uses a marked root over the library", {
  user <- withr::local_tempdir()
  shared <- withr::local_tempdir()
  local_mocked_bindings(
    default_user_directory = function() user,
    duckdb_shared_home = function() shared
  )
  write_keep_marker(storage_dir("user", "extensions"))
  resolved <- resolve_extension_directory()
  expect_equal(
    normalizePath(resolved$directory),
    normalizePath(file.path(user, "extensions"))
  )
  expect_equal(resolved$source, "marker")
})

test_that("resolve_extension_directory uses the library when writable, announcing once", {
  lib <- withr::local_tempdir()
  local_mocked_bindings(
    marked_storage_dir = function(kind) NULL,
    system_file_path = function(...) file.path(lib, ...)
  )
  # First use writes the marker and announces the library cache once.
  expect_message(
    {
      resolved <- resolve_extension_directory()
      expect_equal(
        normalizePath(resolved$directory),
        normalizePath(file.path(lib, "extensions"))
      )
      expect_equal(resolved$source, "library")
    },
    "package library"
  )
  expect_true(has_keep_marker(file.path(lib, "extensions")))
  # Marker now present: no second announcement.
  expect_silent(resolve_extension_directory())
})

test_that("resolve_extension_directory falls back to tempdir when library is read-only", {
  local_mocked_bindings(
    marked_storage_dir = function(kind) NULL,
    has_keep_marker = function(dir) FALSE,
    write_keep_marker = function(dir) FALSE,
    session_temp_dir = function() "/tmp/sess"
  )
  expect_equal(
    resolve_extension_directory(),
    list(directory = "/tmp/sess/duckdb/extensions", source = "session")
  )
})

test_that("resolve_temp_directory redirects in-memory only, honors override", {
  local_mocked_bindings(session_temp_dir = function() "/tmp/sess")
  expect_equal(
    resolve_temp_directory(":memory:"),
    list(directory = "/tmp/sess/duckdb/temp", source = "session")
  )
  expect_equal(
    resolve_temp_directory("/path/to/my.db"),
    list(directory = NULL, source = "default")
  )

  withr::local_options(duckdb.temp_directory = "/opt/tmp")
  expect_equal(
    resolve_temp_directory(":memory:"),
    list(directory = "/opt/tmp", source = "option")
  )
  expect_equal(
    resolve_temp_directory("/path/to/my.db"),
    list(directory = "/opt/tmp", source = "option")
  )
})

test_that("ephemeral-storage message fires only for a tempdir cache, once", {
  local_mocked_bindings(session_temp_dir = function() tempdir())
  storage_message_state[["ephemeral_state"]] <- NULL

  # A persistent cache says nothing.
  expect_silent(maybe_ephemeral_state_message("/persistent/extensions"))

  tmp_cache <- file.path(tempdir(), "duckdb", "extensions")
  expect_message(
    maybe_ephemeral_state_message(tmp_cache),
    "temporary directory"
  )
  # Throttled within the session.
  expect_silent(maybe_ephemeral_state_message(tmp_cache))
})
