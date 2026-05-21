local_secret_dirs <- function(.local_envir = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = .local_envir)
  r_dir <- file.path(root, "rdir")
  c_dir <- file.path(root, "common")
  dir.create(r_dir)
  dir.create(c_dir)
  testthat::local_mocked_bindings(
    default_secret_directory = function() r_dir,
    common_secret_directory = function() c_dir,
    .env = .local_envir
  )
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA, .local_envir = .local_envir)
  withr::local_options(
    duckdb.secret_directory = NULL,
    .local_envir = .local_envir
  )
  list(root = root, r_dir = r_dir, c_dir = c_dir)
}

redact_paths <- function(lines, dirs) {
  lines <- gsub(dirs$r_dir, "<R-DEFAULT>", lines, fixed = TRUE)
  lines <- gsub(dirs$c_dir, "<COMMON>", lines, fixed = TRUE)
  lines <- gsub(dirs$root, "<TMP>", lines, fixed = TRUE)
  lines
}

test_that("resolve_secret_directory uses option, env var, default in that order", {
  dirs <- local_secret_dirs()

  expect_equal(resolve_secret_directory(), dirs$r_dir)

  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = dirs$c_dir)
  expect_equal(resolve_secret_directory(), dirs$c_dir)

  withr::local_options(duckdb.secret_directory = "/from/option")
  expect_equal(resolve_secret_directory(), "/from/option")
})

test_that("resolve_secret_directory expands `~` and rejects bad option values", {
  local_secret_dirs()

  withr::local_options(duckdb.secret_directory = "~/dir")
  expect_equal(resolve_secret_directory(), path.expand("~/dir"))

  withr::local_options(duckdb.secret_directory = "")
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = "~/env")
  expect_message(expect_equal(resolve_secret_directory(), path.expand("~/env")))

  withr::local_options(duckdb.secret_directory = c("a", "b"))
  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = NA)
  expect_message(expect_equal(resolve_secret_directory(), default_secret_directory()))
})

test_that("secret_directory_is_configured reflects option/env var", {
  local_secret_dirs()
  expect_false(secret_directory_is_configured())

  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = "/x")
  expect_true(secret_directory_is_configured())

  withr::local_envvar(DUCKDB_SECRET_DIRECTORY = "")
  expect_false(secret_directory_is_configured())

  withr::local_options(duckdb.secret_directory = "/x")
  expect_true(secret_directory_is_configured())
})

test_that("maybe_secret_directory_message is silent until both stores hold files", {
  local_secret_dirs()

  expect_silent(maybe_secret_directory_message())

  writeLines("a", file.path(default_secret_directory(), "a"))
  expect_silent(maybe_secret_directory_message())

  writeLines("b", file.path(common_secret_directory(), "b"))
  expect_message(
    withCallingHandlers(
      maybe_secret_directory_message(),
      packageStartupMessage = function(m) {
        message(conditionMessage(m), appendLF = FALSE)
        invokeRestart("muffleMessage")
      }
    ),
    "stored secrets exist in two locations"
  )
})

test_that("maybe_secret_directory_message is silenced by configuring either knob", {
  dirs <- local_secret_dirs()
  writeLines("a", file.path(dirs$r_dir, "a"))
  writeLines("b", file.path(dirs$c_dir, "b"))

  withr::with_envvar(
    list(DUCKDB_SECRET_DIRECTORY = dirs$r_dir),
    expect_silent(maybe_secret_directory_message())
  )
  withr::with_options(
    list(duckdb.secret_directory = dirs$c_dir),
    expect_silent(maybe_secret_directory_message())
  )
})

test_that("maybe_secret_directory_message text is stable", {
  dirs <- local_secret_dirs()
  writeLines("a", file.path(dirs$r_dir, "a"))
  writeLines("b", file.path(dirs$c_dir, "b"))

  expect_snapshot(
    transform = function(x) redact_paths(x, dirs),
    {
      withCallingHandlers(
        maybe_secret_directory_message(),
        packageStartupMessage = function(m) {
          cat(conditionMessage(m))
          invokeRestart("muffleMessage")
        }
      )
    }
  )
})

test_that("duckdb_consolidate_secrets reports when there is nothing to do", {
  dirs <- local_secret_dirs()
  target <- file.path(dirs$root, "target")
  withr::local_options(duckdb.secret_directory = target)

  expect_snapshot(
    transform = function(x) redact_paths(x, dirs),
    {
      duckdb_consolidate_secrets(ask = FALSE)
    }
  )

  writeLines("a", file.path(dirs$r_dir, "a"))
  file.remove(file.path(dirs$r_dir, "a"))
  expect_snapshot(
    transform = function(x) redact_paths(x, dirs),
    {
      duckdb_consolidate_secrets(ask = FALSE)
    }
  )
})

test_that("duckdb_consolidate_secrets moves files from common and R-default sources", {
  dirs <- local_secret_dirs()
  target <- file.path(dirs$root, "target")
  withr::local_options(duckdb.secret_directory = target)

  writeLines("c1", file.path(dirs$c_dir, "alpha"))
  writeLines("r1", file.path(dirs$r_dir, "beta"))

  expect_snapshot(
    transform = function(x) redact_paths(x, dirs),
    {
      out <- duckdb_consolidate_secrets(ask = FALSE)
      cat("returned:", redact_paths(out, dirs), "\n")
    }
  )

  expect_setequal(list.files(target), c("alpha", "beta"))
  expect_length(list.files(dirs$r_dir), 0)
  expect_length(list.files(dirs$c_dir), 0)
})

test_that("duckdb_consolidate_secrets accepts an additional `from` directory", {
  dirs <- local_secret_dirs()
  extra <- file.path(dirs$root, "extra")
  dir.create(extra)
  writeLines("x1", file.path(extra, "gamma"))
  target <- file.path(dirs$root, "target")
  withr::local_options(duckdb.secret_directory = target)

  expect_message(duckdb_consolidate_secrets(from = extra, ask = FALSE), "gamma")
  expect_setequal(list.files(target), "gamma")
  expect_length(list.files(extra), 0)
})

test_that("duckdb_consolidate_secrets aborts on collisions unless overwrite = TRUE", {
  dirs <- local_secret_dirs()
  target <- file.path(dirs$root, "target")
  withr::local_options(duckdb.secret_directory = target)
  writeLines("c1", file.path(dirs$c_dir, "shared"))
  writeLines("r1", file.path(dirs$r_dir, "shared"))

  expect_snapshot(
    error = TRUE,
    transform = function(x) redact_paths(x, dirs),
    {
      duckdb_consolidate_secrets(ask = FALSE)
    }
  )

  expect_false(dir.exists(target))
  expect_true(file.exists(file.path(dirs$c_dir, "shared")))
  expect_true(file.exists(file.path(dirs$r_dir, "shared")))

  duckdb_consolidate_secrets(ask = FALSE, overwrite = TRUE)
  expect_setequal(list.files(target), "shared")
})

test_that("duckdb_consolidate_secrets skips a source that equals the target", {
  dirs <- local_secret_dirs()
  withr::local_options(duckdb.secret_directory = dirs$c_dir)
  writeLines("c1", file.path(dirs$c_dir, "stay"))
  writeLines("r1", file.path(dirs$r_dir, "stay"))

  expect_snapshot(
    error = TRUE,
    transform = function(x) redact_paths(x, dirs),
    {
      duckdb_consolidate_secrets(ask = FALSE)
    }
  )

  duckdb_consolidate_secrets(ask = FALSE, overwrite = TRUE)
  expect_setequal(list.files(dirs$c_dir), "stay")
})

test_that("duckdb_consolidate_secrets respects interactive ask = TRUE", {
  dirs <- local_secret_dirs()
  target <- file.path(dirs$root, "target")
  withr::local_options(duckdb.secret_directory = target)
  writeLines("c1", file.path(dirs$c_dir, "a"))

  local_mocked_bindings(prompt_proceed = function(prompt) "n")
  expect_message(duckdb_consolidate_secrets(ask = TRUE), "Aborted")
  expect_true(file.exists(file.path(dirs$c_dir, "a")))
  expect_false(dir.exists(target))

  local_mocked_bindings(prompt_proceed = function(prompt) "y")
  expect_message(
    duckdb_consolidate_secrets(ask = TRUE),
    "Consolidated 1 secret"
  )
  expect_setequal(list.files(target), "a")
})

test_that("duckdb_consolidate_secrets validates its arguments", {
  local_secret_dirs()
  expect_error(duckdb_consolidate_secrets(overwrite = NA))
  expect_error(duckdb_consolidate_secrets(overwrite = c(TRUE, FALSE)))
  expect_error(duckdb_consolidate_secrets(overwrite = "yes"))
  expect_error(duckdb_consolidate_secrets(ask = NA))
  expect_error(duckdb_consolidate_secrets(from = c("a", "b")))
  expect_error(duckdb_consolidate_secrets(from = 1L))
})
