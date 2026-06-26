# Resolution layer (plan/PLAN-storage-locations.md, Phase 1).

test_that("resolve_extension_directory honors option then env override", {
  withr::local_options(duckdb.extension_directory = "/opt/ext")
  expect_equal(resolve_extension_directory(), "/opt/ext")

  withr::local_options(duckdb.extension_directory = NULL)
  withr::local_envvar(DUCKDB_EXTENSION_DIRECTORY = "/env/ext")
  expect_equal(resolve_extension_directory(), "/env/ext")
})

test_that("resolve_extension_directory uses a marked root over the library", {
  user <- withr::local_tempdir()
  shared <- withr::local_tempdir()
  local_mocked_bindings(
    default_user_directory = function() user,
    duckdb_shared_home = function() shared
  )
  write_keep_marker(storage_dir("user", "extensions"))
  expect_equal(
    normalizePath(resolve_extension_directory()),
    normalizePath(file.path(user, "extensions"))
  )
})

test_that("resolve_extension_directory uses the library when writable, announcing once", {
  lib <- withr::local_tempdir()
  local_mocked_bindings(
    marked_storage_dir = function(kind) NULL,
    system_file_path = function(...) file.path(lib, ...)
  )
  # First use writes the marker and announces the library cache once.
  expect_message(
    expect_equal(
      normalizePath(resolve_extension_directory()),
      normalizePath(file.path(lib, "extensions"))
    ),
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
  expect_equal(resolve_extension_directory(), "/tmp/sess/duckdb/extensions")
})

test_that("resolve_temp_directory redirects in-memory only, honors override", {
  local_mocked_bindings(session_temp_dir = function() "/tmp/sess")
  expect_equal(resolve_temp_directory(":memory:"), "/tmp/sess/duckdb/temp")
  expect_null(resolve_temp_directory("/path/to/my.db"))

  withr::local_options(duckdb.temp_directory = "/opt/tmp")
  expect_equal(resolve_temp_directory(":memory:"), "/opt/tmp")
  expect_equal(resolve_temp_directory("/path/to/my.db"), "/opt/tmp")
})

test_that("note_ephemeral_dir records only tempdir locations", {
  local_mocked_bindings(session_temp_dir = function() "/tmp/sess")
  rm(list = ls(ephemeral_dirs), envir = ephemeral_dirs)

  note_ephemeral_dir("extensions", "/persistent/ext")
  expect_length(ls(ephemeral_dirs), 0L)

  note_ephemeral_dir("stored_secrets", "/tmp/sess/duckdb/stored_secrets")
  expect_equal(
    ephemeral_dirs[["/tmp/sess/duckdb/stored_secrets"]],
    "stored_secrets"
  )
})

test_that("maybe_warn_ephemeral warns once, and only once data was written", {
  local_mocked_bindings(session_temp_dir = function() tempdir())
  rm(list = ls(ephemeral_dirs), envir = ephemeral_dirs)
  storage_message_state[["ephemeral_warned"]] <- NULL

  ext_dir <- withr::local_tempdir("eph-ext-")
  nested <- file.path(ext_dir, "v1.0.0", "linux_amd64")
  dir.create(nested, recursive = TRUE)
  note_ephemeral_dir("extensions", ext_dir)

  # Nothing downloaded yet -> silent.
  expect_silent(maybe_warn_ephemeral())

  writeLines("bin", file.path(nested, "spatial.duckdb_extension"))
  expect_message(maybe_warn_ephemeral(), "will not persist")
  # Once per session.
  expect_silent(maybe_warn_ephemeral())
})
