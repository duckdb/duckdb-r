# The storage-location message is deferred from duckdb() until an extension is
# actually installed. duckdb() only *queues* it (stashing the resolved home);
# the first INSTALL flushes it. An explicit `home`/`shared_home` choice this
# session suppresses it entirely (nothing is queued).

test_that("mark/read of the session choice flag round-trips", {
  storage_message_state[["choice_made"]] <- NULL
  expect_false(storage_choice_made())
  mark_storage_choice_made()
  expect_true(storage_choice_made())
})

test_that("an explicit shared_home choice suppresses the deferred install message", {
  skip_on_cran()
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-once")
  )
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["storage_location"]] <- NULL
  storage_message_state[["pending"]] <- NULL

  # Connecting never emits now (the message is deferred to INSTALL); the explicit
  # opt-out also records the choice, so nothing is queued to announce later.
  drv <- NULL
  expect_no_message({
    drv <- duckdb(shared_home = FALSE)
  })
  duckdb_shutdown(drv)
  expect_null(storage_message_state[["pending"]])

  # A subsequent bare call auto-resolves to a tempdir but the choice persists,
  # so still nothing is queued and a flush stays silent.
  expect_no_message({
    drv <- duckdb()
  })
  duckdb_shutdown(drv)
  expect_silent(flush_pending_storage_message())
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
  storage_message_state[["pending"]] <- NULL
  dbfile <- withr::local_tempfile(fileext = ".db")

  # First creation resolves storage (a tempdir); no explicit choice yet.
  drv <- duckdb(dbdir = dbfile)

  # A second call for the same path reuses the cached driver and silently
  # ignores shared_home. That ignored argument must NOT record a choice.
  drv2 <- duckdb(dbdir = dbfile, shared_home = TRUE)
  expect_true(identical(drv, drv2))
  expect_false(storage_choice_made())
  duckdb_shutdown(drv)

  # So a later bare call still queues the (deferred) message, which a flush emits.
  storage_message_state[["storage_location"]] <- NULL
  storage_message_state[["pending"]] <- NULL
  d <- NULL
  expect_no_message({
    d <- duckdb()
  })
  expect_message(flush_pending_storage_message(), "temporary directory")
  duckdb_shutdown(d)
})

test_that("without a prior choice, a bare duckdb() queues the deferred install message", {
  skip_on_cran()
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-once2")
  )
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["storage_location"]] <- NULL
  storage_message_state[["pending"]] <- NULL

  # Connecting is silent now; the message is queued and emitted on INSTALL.
  drv <- NULL
  expect_no_message({
    drv <- duckdb()
  })
  expect_message(flush_pending_storage_message(), "temporary directory")
  duckdb_shutdown(drv)
})
