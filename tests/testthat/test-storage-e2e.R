# End-to-end tests against the bundled DuckDB engine: a persistent secret and a
# downloaded extension should land under the home directory the storage-location
# policy resolves (see ?duckdb_storage). These exercise the real engine, so they
# skip on CRAN; the extension test additionally skips, best effort, when the
# download/install fails (e.g. no network).

test_that("a non-interactive connect queues the storage location, unless chosen", {
  skip_on_cran()
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-msg")
  )

  # Auto-resolved (no ~/.duckdb, no args) -> connect is silent; the tempdir
  # message is deferred to INSTALL, where a flush fires it once.
  storage_message_state[["storage_location"]] <- NULL
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["pending"]] <- NULL
  drv <- NULL
  expect_no_message({ drv <- duckdb() })
  expect_message(flush_pending_storage_message(), "temporary directory")
  duckdb_shutdown(drv)

  # Explicit opt-out with shared_home = FALSE -> nothing queued, flush silent.
  storage_message_state[["storage_location"]] <- NULL
  storage_message_state[["pending"]] <- NULL
  expect_no_message({ drv <- duckdb(shared_home = FALSE) })
  expect_silent(flush_pending_storage_message())
  duckdb_shutdown(drv)
})

test_that("an interactive yes announces creation; a no announces the tempdir", {
  skip_on_cran()
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  drv <- NULL

  # "yes" -> ~/.duckdb created, short confirmation shown.
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  storage_message_state[["home_prompt_declined"]] <- NULL
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    consent_to_create_home = function(path) TRUE
  )
  expect_message({ drv <- duckdb() }, "created")
  duckdb_shutdown(drv)
  expect_true(dir.exists(shared))

  # "no" -> tempdir; the storage-location message is deferred to INSTALL, so
  # connect is silent and a flush emits it. (The "created" confirmation above is
  # a separate message and still fires at connect.)
  storage_message_state[["home_prompt_declined"]] <- NULL
  storage_message_state[["storage_location"]] <- NULL
  storage_message_state[["choice_made"]] <- NULL
  storage_message_state[["pending"]] <- NULL
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-home-int"),
    consent_to_create_home = function(path) FALSE
  )
  expect_no_message({ drv <- duckdb() })
  expect_message(flush_pending_storage_message(), "temporary directory")
  duckdb_shutdown(drv)
})

test_that("a persistent secret is written under the configured home", {
  skip_on_cran()
  home <- withr::local_tempdir("e2e-home-")
  withr::local_envvar(DUCKDB_R_HOME = NA)
  withr::local_options(duckdb.home = home)

  con <- local_con()

  # "http" is a built-in secret type, so this needs no extension.
  dbExecute(
    con,
    "CREATE PERSISTENT SECRET e2e_secret (TYPE http, BEARER_TOKEN 'token')"
  )

  secrets <- dbGetQuery(con, "SELECT name FROM duckdb_secrets()")
  expect_true("e2e_secret" %in% secrets$name)
  expect_true(file.exists(file.path(
    home,
    "stored_secrets",
    "e2e_secret.duckdb_secret"
  )))
})

test_that("the httpfs extension installs and loads under the configured home", {
  skip_on_cran()
  # Disabled on a libc++ Linux build (loading a prebuilt extension crashes R --
  # duckdb/duckdb-r#1107).
  skip_if(!extensions_supported(), "DuckDB extensions disabled on this build (duckdb/duckdb-r#1107)")
  home <- withr::local_tempdir("e2e-home-ext-")
  withr::local_envvar(DUCKDB_R_HOME = NA)
  withr::local_options(duckdb.home = home)

  con <- local_con()

  tryCatch(
    dbExecute(con, "INSTALL httpfs"),
    error = function(e) {
      msg <- conditionMessage(e)
      # The engine throws "Failed to download extension ..." / "Failed to
      # install ..." (extension_install.cpp) when the repository is
      # unreachable; treat that as "not installable here" rather than a failure.
      if (grepl("Failed to (download|install)", msg)) {
        skip(paste0("httpfs extension not installable: ", msg))
      }
      stop(e)
    }
  )

  dbExecute(con, "LOAD httpfs")
  loaded <- dbGetQuery(
    con,
    "SELECT loaded FROM duckdb_extensions() WHERE extension_name = 'httpfs'"
  )
  expect_true(isTRUE(loaded$loaded))

  # The binary was cached under the extensions sub-directory of the home.
  cached <- list.files(
    file.path(home, "extensions"),
    recursive = TRUE,
    pattern = "httpfs"
  )
  expect_gt(length(cached), 0)
})
