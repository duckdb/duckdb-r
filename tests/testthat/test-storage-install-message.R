# The storage-location message is deferred from duckdb() to the first INSTALL.
# Whether a statement is an INSTALL is detected in the engine glue from the
# parsed LoadInfo (see rapi_prepare()) and surfaced as stmt_lst$is_install; the
# end-to-end test below exercises that path.

test_that("duckdb() queues the message but does not emit it; a flush emits once", {
  skip_on_cran()
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-defer")
  )
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["storage_location"]] <- NULL
  storage_message_state[["pending"]] <- NULL

  drv <- NULL
  expect_no_message({
    drv <- duckdb()
  })
  # The message is queued, not shown.
  expect_false(is.null(storage_message_state[["pending"]]))
  duckdb_shutdown(drv)

  # Flushing emits it; a second flush is silent (session dedupe).
  expect_message(flush_pending_storage_message(), "temporary directory")
  expect_silent(flush_pending_storage_message())
})

test_that("an INSTALL statement flushes the deferred storage message", {
  skip_on_cran()
  # On a libc++ Linux build INSTALL is refused at prepare (before the flush), and
  # extensions are disabled anyway -- there is nothing to announce.
  skip_if(!extensions_supported(), "extensions disabled on this build")

  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-install")
  )
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["storage_location"]] <- NULL
  storage_message_state[["pending"]] <- NULL

  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # Preparing an INSTALL flushes the queued message. Use a nonexistent extension
  # and tolerate the execution error -- the message fires at prepare, before it.
  expect_message(
    try(
      dbExecute(con, "INSTALL this_extension_does_not_exist_xyz"),
      silent = TRUE
    ),
    "temporary directory"
  )
})
