# Fixtures for the tests that let a query autoload icu (duckdb/duckdb-r#2883):
# an extension directory that holds icu installed but not loaded, and a driver
# that starts on it with autoload on.
#
# The bug shows only on the first query that autoloads icu, so every test needs
# an instance that has never loaded it. INSTALL runs in an instance of its own,
# shut down before the one under test starts on the same directory.

# A fresh extension directory with icu installed in it, removed when `.env`
# exits. Skips where icu cannot be downloaded, or is built into the binary.
local_icu_installed_dir <- function(.env = parent.frame()) {
  skip_if_no_icu()

  dir <- withr::local_tempdir(.local_envir = .env)
  con <- dbConnect(icu_autoload_drv(dir))
  on.exit(dbDisconnect(con, shutdown = TRUE))
  skip_if_builtin_icu(con)
  dbExecute(con, "INSTALL icu")
  dir
}

# A fresh driver on `dir`, with autoload on: the engine default where
# extensions are allowed, and allowed explicitly here so that an option or
# environment variable turning them off does not make INSTALL fail. Forcing
# them is safe, since `skip_if_no_icu()` has skipped every build that cannot
# load them. Secrets stay in `dir` too, so nothing resolves `~/.duckdb`.
icu_autoload_drv <- function(dir) {
  duckdb(
    config = list(
      extension_directory = dir,
      secret_directory = file.path(dir, "secrets")
    ),
    allow_extensions = TRUE
  )
}

# Whether icu is loaded in the instance behind `con`.
icu_loaded <- function(con) {
  isTRUE(
    dbGetQuery(
      con,
      "SELECT loaded FROM duckdb_extensions() WHERE extension_name = 'icu'"
    )$loaded
  )
}
