# Storage roots and marker helpers (plan/PLAN-storage-locations.md, Phase 2).

test_that("storage_dir maps known roots and kinds, and rejects unknown roots", {
  local_mocked_bindings(
    session_temp_dir = function() "/tmp/sess",
    default_user_directory = function() "/userdir",
    duckdb_shared_home = function() "/home/.duckdb",
    system_file_path = function(...) file.path("/pkg", ...)
  )
  expect_equal(
    storage_dir("session", "extensions"),
    "/tmp/sess/duckdb/extensions"
  )
  expect_equal(storage_dir("user", "secrets"), "/userdir/stored_secrets")
  expect_equal(storage_dir("shared", "secrets"), "/home/.duckdb/stored_secrets")
  expect_equal(storage_dir("library", "extensions"), "/pkg/extensions")
  expect_error(
    storage_dir("/explicit/path", "extensions"),
    "Unknown storage root"
  )
})

test_that("write_keep_marker creates the marker, leaves it, and is detectable", {
  d <- withr::local_tempdir()
  expect_false(has_keep_marker(d))
  expect_true(write_keep_marker(d))
  expect_true(has_keep_marker(d))
  expect_true(file.exists(file.path(d, KEEP_MARKER_NAME)))
  remove_keep_marker(d)
  expect_false(has_keep_marker(d))
})

test_that("marked_storage_dir returns NULL, the one marked root, or warns on duplicates", {
  user <- withr::local_tempdir()
  shared <- withr::local_tempdir()
  local_mocked_bindings(
    default_user_directory = function() user,
    duckdb_shared_home = function() shared
  )

  expect_null(marked_storage_dir("secrets"))

  write_keep_marker(storage_dir("user", "secrets"))
  expect_equal(
    normalizePath(marked_storage_dir("secrets")),
    normalizePath(file.path(user, "stored_secrets"))
  )

  # Two markers -> ambiguous -> message + NULL (fall back to default).
  write_keep_marker(storage_dir("shared", "secrets"))
  storage_message_state[["duplicate_marker_secrets"]] <- NULL
  expect_message(expect_null(marked_storage_dir("secrets")), "more than one")
})

test_that("inform_once_every throttles within the interval (mocked clock)", {
  storage_message_state[["probe"]] <- NULL
  local_mocked_bindings(now_seconds = function() 0)
  expect_true(inform_once_every("probe", 100, "x"))
  expect_false(inform_once_every("probe", 100, "x"))
  local_mocked_bindings(now_seconds = function() 1000)
  expect_true(inform_once_every("probe", 100, "x"))
})
