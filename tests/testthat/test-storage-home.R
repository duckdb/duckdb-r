# Home resolution, temp/spill resolution, and the throttled messages.

test_that("resolve_storage_home honors argument, then option, then env", {
  # An explicit argument wins over everything.
  expect_equal(
    resolve_storage_home("/opt/home"),
    list(root = path.expand("/opt/home"), source = "argument")
  )

  withr::local_options(duckdb.home = "/opt/opt-home")
  withr::local_envvar(DUCKDB_R_HOME = "/opt/env-home")
  # The option beats the environment variable.
  expect_equal(
    resolve_storage_home(),
    list(root = path.expand("/opt/opt-home"), source = "option")
  )

  withr::local_options(duckdb.home = NULL)
  expect_equal(
    resolve_storage_home(),
    list(root = path.expand("/opt/env-home"), source = "env")
  )
})

test_that("resolve_storage_home uses an existing ~/.duckdb", {
  shared <- withr::local_tempdir()
  withr::local_options(duckdb.home = NULL)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(duckdb_shared_home = function() shared)
  expect_equal(
    resolve_storage_home(),
    list(root = shared, source = "shared")
  )
})

test_that("resolve_storage_home falls back to a session tempdir non-interactively", {
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() file.path(tempdir(), "no-such-duckdb-home"),
    session_temp_dir = function() "/tmp/sess"
  )
  expect_equal(
    resolve_storage_home(),
    list(root = "/tmp/sess/duckdb", source = "session")
  )
})

test_that("an interactive yes creates and uses ~/.duckdb", {
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  storage_message_state[["home_prompt_declined"]] <- NULL
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    consent_to_create_home = function(path) TRUE
  )
  resolved <- resolve_storage_home()
  expect_equal(resolved, list(root = shared, source = "created"))
  expect_true(dir.exists(shared))
})

test_that("an interactive no uses tempdir and is not re-asked this session", {
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  storage_message_state[["home_prompt_declined"]] <- NULL
  calls <- 0L
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    session_temp_dir = function() "/tmp/sess",
    consent_to_create_home = function(path) {
      calls <<- calls + 1L
      FALSE
    }
  )
  expect_equal(resolve_storage_home()$source, "session")
  # Declined once -> not asked again for the rest of the session.
  expect_equal(resolve_storage_home()$source, "session")
  expect_equal(calls, 1L)
  expect_false(dir.exists(shared))
})

test_that("describe_storage_home is read-only: no prompt, no creation", {
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    session_temp_dir = function() "/tmp/sess",
    consent_to_create_home = function(path) stop("must not prompt")
  )
  expect_equal(
    describe_storage_home(),
    list(root = "/tmp/sess/duckdb", source = "session")
  )
  expect_false(dir.exists(shared))
})

test_that("resolve_storage_home rejects a malformed home argument", {
  expect_error(resolve_storage_home(123), "single non-empty string")
  expect_error(resolve_storage_home(c("a", "b")), "single non-empty string")
  expect_error(resolve_storage_home(""), "single non-empty string")
})

test_that("shared_home = TRUE opts into ~/.duckdb, creating it, without prompting", {
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  withr::local_options(duckdb.home = NULL, rlang_interactive = FALSE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    consent_to_create_home = function(path) stop("must not prompt")
  )
  resolved <- resolve_storage_home(shared_home = TRUE)
  expect_equal(resolved, list(root = shared, source = "shared"))
  expect_true(dir.exists(shared))
})

test_that("shared_home = FALSE forces tempdir even when ~/.duckdb exists", {
  shared <- withr::local_tempdir() # exists
  withr::local_options(duckdb.home = "/opt/should-be-ignored")
  withr::local_envvar(DUCKDB_R_HOME = "/opt/also-ignored")
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    session_temp_dir = function() "/tmp/sess"
  )
  # Ignores the existing ~/.duckdb and the option/env override.
  expect_equal(
    resolve_storage_home(shared_home = FALSE),
    list(root = "/tmp/sess/duckdb", source = "session")
  )
})

test_that("duckdb() rejects home combined with shared_home, and bad shared_home", {
  expect_error(duckdb(home = "/opt/home", shared_home = TRUE), "not both")
  expect_error(duckdb(home = "/opt/home", shared_home = FALSE), "not both")
  expect_error(duckdb(shared_home = "yes"), "TRUE, FALSE, or NULL")
  expect_error(duckdb(shared_home = NA), "TRUE, FALSE, or NULL")
})

test_that("a cancelled prompt (NA) declines without error", {
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  storage_message_state[["home_prompt_declined"]] <- NULL
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    session_temp_dir = function() "/tmp/sess",
    consent_to_create_home = function(path) NA
  )
  expect_equal(resolve_storage_home()$source, "session")
  expect_false(dir.exists(shared))
})

test_that("resolve_temp_directory redirects in-memory only, honors override", {
  local_mocked_bindings(session_temp_dir = function() "/tmp/sess")
  expect_equal(
    resolve_temp_directory(":memory:"),
    list(directory = "/tmp/sess/duckdb/temp", source = "session")
  )
  expect_equal(
    resolve_temp_directory("/path/to/my.db"),
    list(directory = NULL, source = "default")
  )

  withr::local_options(duckdb.temp_directory = "/opt/tmp")
  expect_equal(
    resolve_temp_directory(":memory:"),
    list(directory = "/opt/tmp", source = "option")
  )
  expect_equal(
    resolve_temp_directory("/path/to/my.db"),
    list(directory = "/opt/tmp", source = "option")
  )
})

test_that("storage-location message: tempdir wording, throttled once", {
  storage_message_state[["storage_location"]] <- NULL
  resolved <- list(root = "/tmp/sess/duckdb", source = "session")
  expect_message(
    maybe_storage_location_message(resolved),
    "temporary directory"
  )
  # Throttled within the session.
  expect_silent(maybe_storage_location_message(resolved))
})

test_that("storage-location message: ~/.duckdb wording mentions shared_home = FALSE", {
  storage_message_state[["storage_location"]] <- NULL
  resolved <- list(root = "/home/me/.duckdb", source = "shared")
  expect_message(
    maybe_storage_location_message(resolved),
    "shared_home = FALSE"
  )
})

test_that("inform_once_every throttles within the interval (mocked clock)", {
  storage_message_state[["probe"]] <- NULL
  local_mocked_bindings(now_seconds = function() 0)
  expect_true(inform_once_every("probe", 100, "x"))
  expect_false(inform_once_every("probe", 100, "x"))
  local_mocked_bindings(now_seconds = function() 1000)
  expect_true(inform_once_every("probe", 100, "x"))
})
