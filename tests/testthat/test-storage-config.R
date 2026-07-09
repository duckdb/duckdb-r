# User-facing storage configuration (plan/PLAN-storage-locations.md, Phase 3).

local_storage_roots <- function(.local_envir = parent.frame()) {
  roots <- list(
    user = withr::local_tempdir("user-", .local_envir = .local_envir),
    shared = withr::local_tempdir("shared-", .local_envir = .local_envir),
    session = withr::local_tempdir("session-", .local_envir = .local_envir)
  )
  withr::local_envvar(
    DUCKDB_EXTENSION_DIRECTORY = NA,
    DUCKDB_SECRET_DIRECTORY = NA,
    .local_envir = .local_envir
  )
  withr::local_options(
    duckdb.extension_directory = NULL,
    duckdb.secret_directory = NULL,
    .local_envir = .local_envir
  )
  testthat::local_mocked_bindings(
    default_user_directory = function() roots$user,
    duckdb_shared_home = function() roots$shared,
    session_temp_dir = function() roots$session,
    .env = .local_envir
  )
  roots
}

test_that("duckdb_extension_storage writes a marker, status reports it", {
  roots <- local_storage_roots()

  dir <- duckdb_extension_storage("user", migrate = FALSE)
  expect_equal(
    normalizePath(dir),
    normalizePath(file.path(roots$user, "extensions"))
  )
  expect_true(has_keep_marker(file.path(roots$user, "extensions")))

  st <- duckdb_storage_status()
  expect_s3_class(st, "data.frame")
  expect_named(st, c("kind", "source", "directory"))
  expect_setequal(st$kind, c("extensions", "stored_secrets"))
  ext <- st[st$kind == "extensions", ]
  expect_equal(
    normalizePath(ext$directory),
    normalizePath(file.path(roots$user, "extensions"))
  )
  expect_equal(ext$source, "marker")
})

test_that("setting a location clears markers in the other roots", {
  roots <- local_storage_roots()

  duckdb_extension_storage("user", migrate = FALSE)
  duckdb_extension_storage("shared", migrate = FALSE)

  expect_false(has_keep_marker(file.path(roots$user, "extensions")))
  expect_true(has_keep_marker(file.path(roots$shared, "extensions")))
  expect_equal(
    duckdb_storage_status()[1, "source"],
    "marker"
  )
})

test_that('location = "session" removes the marker and reverts to the default', {
  roots <- local_storage_roots()

  duckdb_secret_storage("user", migrate = FALSE)
  expect_true(has_keep_marker(file.path(roots$user, "stored_secrets")))

  dir <- duckdb_secret_storage("session")
  expect_false(has_keep_marker(file.path(roots$user, "stored_secrets")))
  expect_equal(dir, file.path(roots$session, "duckdb", "stored_secrets"))
  sec <- duckdb_storage_status()
  expect_equal(sec[sec$kind == "stored_secrets", "source"], "session")
})

test_that("migrate moves cached files between roots", {
  roots <- local_storage_roots()

  duckdb_secret_storage("user", migrate = FALSE)
  src <- file.path(roots$user, "stored_secrets")
  writeLines("k", file.path(src, "a.json"))

  duckdb_secret_storage("shared")
  expect_true(file.exists(file.path(roots$shared, "stored_secrets", "a.json")))
  expect_false(file.exists(file.path(src, "a.json")))
})

test_that("migrate preserves nested layout (extensions)", {
  roots <- local_storage_roots()

  duckdb_extension_storage("user", migrate = FALSE)
  nested <- file.path(roots$user, "extensions", "v1.0.0", "linux_amd64")
  dir.create(nested, recursive = TRUE)
  writeLines("bin", file.path(nested, "spatial.duckdb_extension"))

  duckdb_extension_storage("shared")
  expect_true(file.exists(file.path(
    roots$shared,
    "extensions",
    "v1.0.0",
    "linux_amd64",
    "spatial.duckdb_extension"
  )))
})

test_that("conflict modes decide who wins a name collision", {
  roots <- local_storage_roots()

  setup_collision <- function() {
    duckdb_secret_storage("user", migrate = FALSE)
    writeLines("ours", file.path(roots$user, "stored_secrets", "a.json"))
    dir.create(
      file.path(roots$shared, "stored_secrets"),
      recursive = TRUE,
      showWarnings = FALSE
    )
    writeLines("theirs", file.path(roots$shared, "stored_secrets", "a.json"))
  }

  setup_collision()
  expect_error(duckdb_secret_storage("shared", conflict = "error"), "overwrite")
  expect_equal(
    readLines(file.path(roots$shared, "stored_secrets", "a.json")),
    "theirs"
  )
  expect_true(file.exists(file.path(roots$user, "stored_secrets", "a.json")))

  setup_collision()
  duckdb_secret_storage("shared", conflict = "ours")
  expect_equal(
    readLines(file.path(roots$shared, "stored_secrets", "a.json")),
    "ours"
  )
  expect_false(file.exists(file.path(roots$user, "stored_secrets", "a.json")))

  setup_collision()
  duckdb_secret_storage("shared", conflict = "theirs")
  expect_equal(
    readLines(file.path(roots$shared, "stored_secrets", "a.json")),
    "theirs"
  )
  expect_false(file.exists(file.path(roots$user, "stored_secrets", "a.json")))
})

test_that("storage functions reject stray dots and non-root locations", {
  local_storage_roots()
  expect_error(duckdb_extension_storage("session", "oops"))
  # arg_match() enforces the roots: the retired "library" root and arbitrary
  # paths are not accepted.
  expect_error(duckdb_extension_storage("library"), "one of")
  expect_error(duckdb_secret_storage("library"), "one of")
  expect_error(duckdb_extension_storage("/tmp/whatever"), "one of")
})

test_that("storage functions default location to \"session\"", {
  roots <- local_storage_roots()
  write_keep_marker(file.path(roots$user, "stored_secrets"))
  # A bare call resolves to the first choice, "session": the opt-out.
  dir <- duckdb_secret_storage()
  expect_false(has_keep_marker(file.path(roots$user, "stored_secrets")))
  expect_equal(dir, file.path(roots$session, "duckdb", "stored_secrets"))
})

test_that("migration sweeps every marked root (duplicate-marker recovery)", {
  roots <- local_storage_roots()
  # Abnormal state: a kind is marked in two roots at once.
  write_keep_marker(file.path(roots$user, "extensions"))
  write_keep_marker(file.path(roots$shared, "extensions"))
  writeLines("u", file.path(roots$user, "extensions", "u.txt"))
  writeLines("s", file.path(roots$shared, "extensions", "s.txt"))

  # Relocating to one of the marked roots still sweeps in the files orphaned in
  # the other root whose marker is cleared.
  duckdb_extension_storage("user")

  expect_true(file.exists(file.path(roots$user, "extensions", "u.txt")))
  expect_true(file.exists(file.path(roots$user, "extensions", "s.txt")))
  expect_false(file.exists(file.path(roots$shared, "extensions", "s.txt")))
})

test_that("a malformed directory option warns once, then is ignored", {
  local_storage_roots()
  storage_message_state[["bad_option_extension"]] <- NULL
  withr::local_options(duckdb.extension_directory = 123)

  expect_warning(describe_storage("extensions"), "not a non-empty string")
  # Throttled within the session.
  expect_silent(describe_storage("extensions"))
})

test_that("duckdb_storage_status returns a visible kind/source/directory frame", {
  local_storage_roots()
  result <- withVisible(duckdb_storage_status())
  expect_true(result$visible)
  st <- result$value
  expect_s3_class(st, "duckdb_storage_status")
  expect_named(st, c("kind", "source", "directory"))
  expect_equal(st$kind, c("extensions", "stored_secrets"))
})

test_that("duckdb_storage_status prints a readable summary", {
  withr::local_envvar(
    DUCKDB_EXTENSION_DIRECTORY = NA,
    DUCKDB_SECRET_DIRECTORY = NA
  )
  withr::local_options(
    duckdb.extension_directory = NULL,
    duckdb.secret_directory = NULL
  )
  local_mocked_bindings(
    session_temp_dir = function() "/tmp/sess",
    default_user_directory = function() "/userdir",
    duckdb_shared_home = function() "/home/.duckdb",
    system_file_path = function(...) file.path("/pkg", ...)
  )
  expect_snapshot(duckdb_storage_status())
})
