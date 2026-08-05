# Which platforms DuckDB publishes extension binaries for, and which it does
# not.
#
# Two tests install a real extension over the network, so they have to know
# whether that can work at all on the platform running them.
# `handbook/usage/extensions/` owns the fact; this helper is how the suite asks
# for it.

# The platform name this build fetches extensions under -- the directory
# component of every extensions.duckdb.org URL it requests. Asked of the engine
# rather than derived from `R.version`, because the engine is what builds the
# URL and the naming is DuckDB's to change.
duckdb_extension_platform <- function(conn = default_conn()) {
  dbGetQuery(conn, "PRAGMA platform")[[1L]]
}

# Platforms the engine can be built for but that DuckDB publishes no extension
# binaries for. `windows_arm64_mingw` -- what R's Windows/arm64 toolchain
# produces -- is the whole list as of 2026-08: DuckDB builds
# `windows_amd64_mingw` and the MSVC `windows_arm64`, but arm64 MinGW is not a
# distribution target at all, and there is no timeline for adding one
# (duckdb/duckdb-r#2425). Every `INSTALL` there is an HTTP 404.
platforms_without_extensions <- c("windows_arm64_mingw")

# Skip a test that installs an extension where there is nothing to install.
# The gap is not this package's to close, so it is skipped rather than failed --
# and pinned by the canary in `test-duckdb-extensions.R`, so the skip cannot
# outlive it.
skip_if_no_extension_binaries <- function() {
  platform <- duckdb_extension_platform()
  if (platform %in% platforms_without_extensions) {
    skip(paste0(
      "DuckDB publishes no extensions for ",
      platform,
      " (duckdb/duckdb-r#2425)."
    ))
  }
}
