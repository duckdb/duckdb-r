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
    list(root = session_home_path(), source = "session")
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
  # Accepting also emits a short confirmation of what was created.
  expect_message(resolved <- resolve_storage_home(), "created")
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
    list(root = session_home_path(), source = "session")
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
    list(root = session_home_path(), source = "session")
  )
})

test_that("duckdb() rejects home combined with shared_home, and bad shared_home", {
  expect_error(duckdb(home = "/opt/home", shared_home = TRUE), "not both")
  expect_error(duckdb(home = "/opt/home", shared_home = FALSE), "not both")
  expect_error(duckdb(shared_home = "yes"), "TRUE, FALSE, or NULL")
  expect_error(duckdb(shared_home = NA), "TRUE, FALSE, or NULL")
})

test_that("a cancelled prompt (NA) aborts with the storage-location message", {
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  storage_message_state[["home_prompt_declined"]] <- NULL
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    session_temp_dir = function() "/tmp/sess",
    consent_to_create_home = function(path) NA
  )
  # Cancel is not a decision: it errors (reusing the message) and creates nothing.
  expect_error(resolve_storage_home(), "temporary directory")
  expect_false(dir.exists(shared))
})

test_that("an explicit no proceeds with a tempdir, no error", {
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  storage_message_state[["home_prompt_declined"]] <- NULL
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    session_temp_dir = function() "/tmp/sess",
    consent_to_create_home = function(path) FALSE
  )
  expect_equal(resolve_storage_home()$source, "session")
  expect_false(dir.exists(shared))
})

# The two tests below drive the *un-mocked* prompt, so they need a process where
# `readline()` cannot be answered -- which is every automated run, but not a
# developer's `devtools::test()`. There the prompt would block on real input, so
# they skip. That leaves the other half of `default = interactive()` -- a real
# console, where the default is still "yes" -- outside the suite; verify it by
# hand in an interactive R session, with the package attached and no ~/.duckdb:
#
#   dir.exists("~/.duckdb")            # FALSE to start
#   con <- DBI::dbConnect(duckdb())
#   #> duckdb: create /home/you/.duckdb? (Yes/no/cancel)
#   # press Enter: the capitalized "Yes" is the default, ~/.duckdb is created

test_that("consent_to_create_home declines when it cannot be answered", {
  skip_if(interactive(), "the prompt would wait for real input")

  # readline() returns "" at once here, so askYesNo() falls back to its default.
  out <- capture.output(answer <- consent_to_create_home("/tmp/nope/.duckdb"))
  expect_false(answer)
  expect_match(out, "/tmp/nope/.duckdb", all = FALSE, fixed = TRUE)
})

test_that("a forced-interactive session does not get ~/.duckdb created for it", {
  skip_if(interactive(), "the prompt would wait for real input")

  # `rlang_interactive = TRUE` is a common idiom in reverse dependencies' test
  # suites. It opens the prompt tier of resolve_storage_home() in a process that
  # cannot answer, so the un-mocked seam must decline rather than consent --
  # otherwise `R CMD check` writes to the user's home directory.
  shared <- file.path(withr::local_tempdir(), ".duckdb")
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  storage_message_state[["home_prompt_declined"]] <- NULL
  local_mocked_bindings(
    duckdb_shared_home = function() shared,
    session_temp_dir = function() "/tmp/sess"
  )

  # consent_to_create_home() is deliberately left un-mocked.
  out <- capture.output(resolved <- resolve_storage_home())

  expect_match(out, "create", all = FALSE)
  expect_equal(resolved, list(root = session_home_path(), source = "session"))
  expect_false(dir.exists(shared))
})

test_that("resolve_temp_directory redirects in-memory only, honors override", {
  tmp <- withr::local_tempdir()
  local_mocked_bindings(session_temp_dir = function() tmp)

  resolved <- resolve_temp_directory(":memory:")
  expect_equal(resolved$source, "session")

  # The per-instance spill directory sits under the session spill root ...
  spill_root <- file.path(tmp, get_package_name(), "temp")
  expect_equal(dirname(resolved$directory), spill_root)
  # ... which resolving created, so the engine's own single-level directory
  # creation can create the leaf lazily at first spill.
  expect_true(dir.exists(spill_root))
  # The leaf itself is left to the engine: nothing exists until a query
  # actually spills.
  expect_false(dir.exists(resolved$directory))
  # Every resolution yields a fresh leaf: concurrent in-memory instances must
  # not share a spill directory (deterministic file names, shutdown cleanup).
  expect_false(
    identical(resolve_temp_directory(":memory:")$directory, resolved$directory)
  )

  # An on-disk database keeps the engine's own `<dbdir>.tmp` default.
  expect_equal(
    resolve_temp_directory("/path/to/my.db"),
    list(directory = NULL, source = "default")
  )

  # An override is passed through verbatim, and never created here.
  withr::local_options(
    duckdb.temp_directory = file.path(tmp, "no-such-dir", "spill")
  )
  expect_equal(
    resolve_temp_directory(":memory:"),
    list(directory = file.path(tmp, "no-such-dir", "spill"), source = "option")
  )
  expect_equal(
    resolve_temp_directory("/path/to/my.db"),
    list(directory = file.path(tmp, "no-such-dir", "spill"), source = "option")
  )
  expect_false(dir.exists(file.path(tmp, "no-such-dir", "spill")))
})

test_that("an in-memory database spills to temporary storage out of the box", {
  drv <- duckdb()
  con <- dbConnect(drv)
  on.exit(
    {
      dbDisconnect(con)
      duckdb_shutdown(drv)
    },
    add = TRUE
  )

  spill <- dbGetQuery(
    con,
    "SELECT current_setting('temp_directory') AS dir"
  )$dir
  expect_equal(dirname(spill), file.path(session_home(), "temp"))
  expect_false(dir.exists(spill))

  # A sort that outgrows the memory limit: it can only complete by offloading
  # to the spill directory, which the engine creates on first use.
  dbExecute(con, "SET memory_limit = '80MB'")
  dbExecute(
    con,
    "CREATE TABLE spilled AS
       SELECT hash(i) AS h, i FROM range(10000000) t(i) ORDER BY h"
  )
  expect_true(dir.exists(spill))
  expect_equal(
    dbGetQuery(con, "SELECT count(*) AS n FROM spilled")$n,
    10000000
  )

  # The engine removes the per-instance directory at instance shutdown.
  dbDisconnect(con)
  duckdb_shutdown(drv)
  on.exit()
  expect_false(dir.exists(spill))
})

test_that("storage-location message: tempdir wording", {
  withr::local_options(rlang_interactive = FALSE)
  storage_message_state[["storage_location"]] <- NULL
  resolved <- list(root = "/tmp/sess/duckdb", source = "session")
  expect_message(
    maybe_storage_location_message(resolved),
    "temporary directory"
  )
})

test_that("storage-location message: ~/.duckdb wording mentions shared_home = FALSE", {
  withr::local_options(rlang_interactive = FALSE)
  storage_message_state[["storage_location"]] <- NULL
  resolved <- list(root = "/home/me/.duckdb", source = "shared")
  expect_message(
    maybe_storage_location_message(resolved),
    "shared_home = FALSE"
  )
})

test_that("non-interactive reminder is bounded by a count, interactive by time", {
  resolved <- list(root = "/tmp/sess/duckdb", source = "session")

  # Non-interactive: bounded by STORAGE_MESSAGE_MAX, then silent.
  withr::local_options(rlang_interactive = FALSE)
  storage_message_state[["storage_location"]] <- STORAGE_MESSAGE_MAX - 1L
  expect_message(maybe_storage_location_message(resolved), "not be shown again")
  expect_silent(maybe_storage_location_message(resolved))

  # Interactive: time-throttled instead (still emits once the count is spent).
  withr::local_options(rlang_interactive = TRUE)
  storage_message_state[["storage_location"]] <- NULL
  local_mocked_bindings(now_seconds = function() 0)
  expect_message(maybe_storage_location_message(resolved), "temporary directory")
  expect_silent(maybe_storage_location_message(resolved))
})

test_that("inform_once_every throttles within the interval (mocked clock)", {
  storage_message_state[["probe"]] <- NULL
  local_mocked_bindings(now_seconds = function() 0)
  expect_true(inform_once_every("probe", 100, "x"))
  expect_false(inform_once_every("probe", 100, "x"))
  local_mocked_bindings(now_seconds = function() 1000)
  expect_true(inform_once_every("probe", 100, "x"))
})

test_that("inform_up_to emits up to max times, notes the last, then goes silent", {
  storage_message_state[["probe"]] <- NULL
  expect_message(inform_up_to("probe", 2L, "hi"), "hi")
  expect_message(inform_up_to("probe", 2L, "hi"), "not be shown again")
  expect_silent(inform_up_to("probe", 2L, "hi"))
})

# Snapshots of the exact wording of every storage message and error. `cat()`
# drops the bullet names, so these capture the text deterministically (no cli
# version or tempdir path leaks in).
test_that("storage message wording is stable", {
  tempdir_home <- list(root = "/tmp/Rtmpxx/duckdb", source = "session")
  shared_home <- list(root = "/home/alice/.duckdb", source = "shared")

  expect_snapshot({
    cat("# non-interactive, temporary directory:\n")
    cat(storage_location_message(tempdir_home), sep = "\n")
    cat("\n\n# non-interactive, existing ~/.duckdb:\n")
    cat(storage_location_message(shared_home), sep = "\n")
    cat("\n\n# cancelled interactive prompt (error text):\n")
    cat(storage_location_message(tempdir_home, interactive = TRUE), sep = "\n")
    cat("\n\n# confirmation after creating ~/.duckdb:\n")
    cat(home_created_message("/home/alice/.duckdb"), sep = "\n")
  })
})

test_that("a cancelled prompt aborts with a stable error", {
  withr::local_options(duckdb.home = NULL, rlang_interactive = TRUE)
  withr::local_envvar(DUCKDB_R_HOME = NA)
  storage_message_state[["home_prompt_declined"]] <- NULL
  local_mocked_bindings(
    duckdb_shared_home = function() "/home/alice/.duckdb",
    session_temp_dir = function() "/tmp/Rtmpxx",
    consent_to_create_home = function(path) NA
  )
  expect_snapshot(resolve_storage_home(), error = TRUE, transform = transform_package_name)
})
