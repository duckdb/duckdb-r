# End-to-end tests that the "shared" storage root the R package computes
# (`duckdb_shared_home()`) is the *same* `~/.duckdb` the standalone DuckDB CLI
# uses. This is the behavior the home-directory fix is about: on Windows the old
# `path.expand("~/.duckdb")` pointed at the Documents folder, where the CLI never
# looks. Rather than re-encode the platform rule in the test, we let a real CLI
# tell us where it stores secrets and check that a secret crosses the boundary in
# both directions.
#
# These tests need a DuckDB CLI whose version matches the bundled engine (secret
# files are version-specific). They are therefore conditional: the package
# "injects" them only when such a CLI is present. Point DUCKDB_CLI at the binary
# (CI does this, see .github/workflows/custom/before-install) or put a matching
# `duckdb` on the PATH; otherwise they skip.

# Resolve the CLI to test against: an explicit DUCKDB_CLI wins, else `duckdb` on
# the PATH. Returns "" when none is available.
duckdb_cli_bin <- function() {
  explicit <- Sys.getenv("DUCKDB_CLI", unset = "")
  if (nzchar(explicit) && file.exists(explicit)) {
    return(explicit)
  }
  unname(Sys.which("duckdb"))
}

# Run a single SQL statement through the CLI against an in-memory database and
# return stdout as a character vector. Persistent secrets are loaded from the
# CLI's secret directory regardless of the database, so `:memory:` is enough.
run_cli <- function(cli, sql) {
  suppressWarnings(system2(
    cli,
    c("-c", shQuote(sql)),
    stdout = TRUE,
    stderr = TRUE
  ))
}

# TRUE when the CLI reports the same version as the bundled engine. Secret files
# are version-specific, so a mismatched CLI cannot reliably read what the engine
# wrote (and vice versa); such a CLI is treated as "not present" for these tests.
cli_version_matches <- function(cli) {
  out <- tryCatch(
    system2(cli, "--version", stdout = TRUE, stderr = TRUE),
    error = function(e) character()
  )
  any(grepl(get_duckdb_version(), out, fixed = TRUE))
}

# Skip unless a usable, version-matched CLI is available, and return its path.
local_matching_cli <- function() {
  skip_on_cran()
  cli <- duckdb_cli_bin()
  if (!nzchar(cli)) {
    skip("No DuckDB CLI found (set DUCKDB_CLI or put `duckdb` on PATH).")
  }
  if (!cli_version_matches(cli)) {
    skip(sprintf(
      "DuckDB CLI does not match the bundled engine version (%s).",
      get_duckdb_version()
    ))
  }
  cli
}

# Point both the engine (via Sys.getenv-based duckdb_shared_home()) and the CLI
# (via its own HOME/USERPROFILE expansion) at the same throwaway home, so the
# "shared" root resolves to one place for both. Returns the shared
# stored-secrets directory the R side will use.
local_shared_home <- function(.local_envir = parent.frame()) {
  home <- withr::local_tempdir("e2e-cli-home-", .local_envir = .local_envir)
  # HOME for the CLI on Unix, USERPROFILE for the CLI on Windows; the engine in
  # this R process reads the same variables through duckdb_home_directory().
  withr::local_envvar(
    HOME = home,
    USERPROFILE = home,
    DUCKDB_SECRET_DIRECTORY = NA,
    .local_envir = .local_envir
  )
  file.path(duckdb_shared_home(), "stored_secrets")
}

test_that("a secret created in R is visible to the DuckDB CLI", {
  cli <- local_matching_cli()
  shared_secret_dir <- local_shared_home()

  # The R engine writes its persistent secret into the shared root. We resolve
  # the path through duckdb_shared_home() (the function under test) rather than
  # hard-coding it, so a wrong home base fails this test.
  withr::local_options(duckdb.secret_directory = shared_secret_dir)

  con <- local_con()
  dbExecute(
    con,
    "CREATE PERSISTENT SECRET r_to_cli (TYPE http, BEARER_TOKEN 'token')"
  )
  expect_true(file.exists(file.path(
    shared_secret_dir,
    "r_to_cli.duckdb_secret"
  )))

  # The CLI, using its own default secret directory (<home>/.duckdb), must see
  # the same secret -- proving the two notions of `~/.duckdb` coincide.
  out <- run_cli(cli, "SELECT name FROM duckdb_secrets() ORDER BY name")
  expect_true(any(grepl("r_to_cli", out, fixed = TRUE)))
})

test_that("a secret created by the DuckDB CLI is visible to R", {
  cli <- local_matching_cli()
  shared_secret_dir <- local_shared_home()

  # The CLI writes a persistent secret into its default <home>/.duckdb.
  cli_out <- run_cli(
    cli,
    "CREATE PERSISTENT SECRET cli_to_r (TYPE http, BEARER_TOKEN 'token')"
  )
  # The file should appear where R expects the shared root to be.
  expect_true(
    file.exists(file.path(shared_secret_dir, "cli_to_r.duckdb_secret")),
    info = paste(cli_out, collapse = "\n")
  )

  # R, reading the shared root, must see the CLI's secret.
  withr::local_options(duckdb.secret_directory = shared_secret_dir)
  con <- local_con()
  secrets <- dbGetQuery(con, "SELECT name FROM duckdb_secrets()")
  expect_true("cli_to_r" %in% secrets$name)
})
