# An explicit `home`/`shared_home` choice this session silences the
# storage-location message for subsequent auto-resolved duckdb() calls.

test_that("mark/read of the session choice flag round-trips", {
  storage_message_state[["choice_made"]] <- NULL
  expect_false(storage_choice_made())
  mark_storage_choice_made()
  expect_true(storage_choice_made())
})

test_that("an explicit shared_home choice silences a later bare duckdb()", {
  skip_on_cran()
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-once")
  )
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["storage_location"]] <- NULL

  # The explicit opt-out is itself silent, and marks the choice.
  drv <- NULL
  expect_no_message({
    drv <- duckdb(shared_home = FALSE)
  })
  duckdb_shutdown(drv)

  # A subsequent bare call auto-resolves to a tempdir but now stays quiet.
  expect_no_message({
    drv <- duckdb()
  })
  duckdb_shutdown(drv)
})

test_that("reusing a cached on-disk driver does not record a storage choice", {
  skip_on_cran()
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-reuse")
  )
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["storage_location"]] <- NULL
  dbfile <- withr::local_tempfile(fileext = ".db")

  # First creation resolves storage (a tempdir); no explicit choice yet.
  drv <- duckdb(dbdir = dbfile)

  # A second call for the same path reuses the cached driver and silently
  # ignores shared_home. That ignored argument must NOT record a choice.
  drv2 <- duckdb(dbdir = dbfile, shared_home = TRUE)
  expect_true(identical(drv, drv2))
  expect_false(storage_choice_made())
  duckdb_shutdown(drv)

  # So a later bare call still announces.
  storage_message_state[["storage_location"]] <- NULL
  d <- NULL
  expect_message(
    {
      d <- duckdb()
    },
    "temporary directory"
  )
  duckdb_shutdown(d)
})

test_that("without a prior choice, a bare duckdb() still announces", {
  skip_on_cran()
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-once2")
  )
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["storage_location"]] <- NULL

  drv <- NULL
  expect_message(
    {
      drv <- duckdb()
    },
    "temporary directory"
  )
  duckdb_shutdown(drv)
})
