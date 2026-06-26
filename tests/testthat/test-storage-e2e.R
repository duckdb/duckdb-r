# End-to-end tests against the bundled DuckDB engine: a persistent secret and a
# downloaded extension should land in the directories the storage-location
# policy resolves (plan/PLAN-storage-locations.md). These exercise the real
# engine, so they skip on CRAN; the extension test additionally skips, best
# effort, when the download/install fails (e.g. no network).

test_that("a persistent secret is written to the configured secret directory", {
  skip_on_cran()
  secret_dir <- withr::local_tempdir("e2e-secrets-")
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA)
  withr::local_options(duckdb.secret_directory = secret_dir)

  con <- local_con()

  # "http" is a built-in secret type, so this needs no extension.
  dbExecute(
    con,
    "CREATE PERSISTENT SECRET e2e_secret (TYPE http, BEARER_TOKEN 'token')"
  )

  secrets <- dbGetQuery(con, "SELECT name FROM duckdb_secrets()")
  expect_true("e2e_secret" %in% secrets$name)
  expect_true(file.exists(file.path(secret_dir, "e2e_secret.duckdb_secret")))
})

test_that("the httpfs extension installs and loads into the configured cache", {
  skip_on_cran()
  ext_dir <- withr::local_tempdir("e2e-ext-")
  withr::local_envvar(DUCKDB_EXTENSION_DIRECTORY = NA)
  withr::local_options(duckdb.extension_directory = ext_dir)

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

  # The binary was cached under the directory we pointed the setting at.
  cached <- list.files(ext_dir, recursive = TRUE, pattern = "httpfs")
  expect_gt(length(cached), 0)
})

test_that("sql_exec warns when it writes ephemeral data (no disconnect)", {
  skip_on_cran()
  # No override: secrets resolve to a tempdir we control, so the write is
  # ephemeral. sql_exec() never disconnects, so the warning must come from the
  # post-call check rather than the at-exit backstop.
  tmp <- withr::local_tempdir("eph-sql-")
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA)
  withr::local_options(duckdb.secret_directory = NULL)
  local_mocked_bindings(session_temp_dir = function() tmp)
  state <- getNamespace("duckdb")[["storage_message_state"]]
  state[["ephemeral_warned"]] <- NULL

  con <- local_con()
  expect_message(
    sql_exec(
      "CREATE PERSISTENT SECRET sql_demo (TYPE http, BEARER_TOKEN 'x')",
      conn = con
    ),
    "will not persist"
  )
})
