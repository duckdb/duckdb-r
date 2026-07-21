# End-to-end tests against the bundled DuckDB engine: a persistent secret and a
# downloaded extension should land under the home directory the storage-location
# policy resolves (see ?duckdb_storage). These exercise the real engine, so they
# skip on CRAN; the extension test additionally skips, best effort, when the
# download/install fails (e.g. no network).

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
