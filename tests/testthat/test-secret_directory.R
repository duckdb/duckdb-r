skip_on_cran()
skip_on_os("windows")
skip_on_os("mac")

local_secret_dir <- function(.local_envir = parent.frame()) {
  r_dir <- withr::local_tempdir(.local_envir = .local_envir)
  testthat::local_mocked_bindings(
    default_secret_directory = function() r_dir,
    .env = .local_envir
  )
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA, .local_envir = .local_envir)
  withr::local_options(
    duckdb.secret_directory = NULL,
    .local_envir = .local_envir
  )
  r_dir
}

test_that("resolve_secret_directory uses option, env var, default in that order", {
  r_dir <- local_secret_dir()

  expect_equal(resolve_secret_directory(), r_dir)

  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = "/from/env")
  expect_equal(resolve_secret_directory(), "/from/env")

  withr::local_options(duckdb.secret_directory = "/from/option")
  expect_equal(resolve_secret_directory(), "/from/option")
})

test_that("resolve_secret_directory expands `~` and rejects bad option values", {
  r_dir <- local_secret_dir()

  withr::local_options(duckdb.secret_directory = "~/dir")
  expect_equal(resolve_secret_directory(), path.expand("~/dir"))

  withr::local_options(duckdb.secret_directory = "")
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = "~/env")
  expect_message(expect_equal(resolve_secret_directory(), path.expand("~/env")))

  withr::local_options(duckdb.secret_directory = c("a", "b"))
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA)
  expect_message(expect_equal(resolve_secret_directory(), r_dir))
})
