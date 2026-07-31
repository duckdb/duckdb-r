# Documentation for DuckDB's extension mechanism as this package configures it.
# See `?duckdb_extensions`.
#
# Rationale kept out of the user-facing docs:
#
# The bundled set and the two autoload/autoinstall defaults are compile-time
# facts, set in src/Makevars.in:
#
#   -DDUCKDB_EXTENSION_PARQUET_LINKED -DDUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED
#   -DDUCKDB_EXTENSION_AUTOLOAD_DEFAULT
#
# and *not* -DDUCKDB_EXTENSION_AUTOINSTALL_DEFAULT. The two settings resolve
# their defaults from those macros in
# src/duckdb/src/include/duckdb/main/settings.hpp. Leaving autoinstall off is
# deliberate: CRAN policy does not allow a package to reach the network as a
# side effect of an ordinary operation, and an autoinstalling engine would do
# exactly that on the first query that touches an unloaded extension.
#
# This is also why the page cannot be verified under DUCKDB_R_USE_SYSTEM_LIB:
# the release libduckdb links icu, json, and autocomplete as well, and defaults
# autoinstall to true. See BUILD.md, "The fast path is not the package".

#' DuckDB extensions: what ships, what you install, and what can go wrong
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' DuckDB's functionality is split into a small core and a set of extensions.
#' This package bundles **two** of them and downloads nothing on its own.
#' Everything else -- `icu`, `httpfs`, `spatial`, `json`, `h3`, and the rest --
#' is installed once, explicitly, and then loads itself automatically forever after.
#'
#' That combination (automatic *loading*, no automatic *installing*)
#' is the source of most extension surprises,
#' including the common report that a "bundled" extension is missing.
#'
#' # What is bundled
#'
#' The package statically links exactly two extensions:
#'
#' * `parquet` -- Parquet reading and writing
#' * `core_functions` -- the bulk of DuckDB's scalar and aggregate functions
#'
#' Nothing else is compiled in.
#' In particular `icu` is **not** bundled,
#' so time-zone-aware operations that need it require an explicit install.
#'
#' The DuckDB documentation describes several extensions as bundled or
#' statically linked. That refers to the DuckDB CLI and to the released
#' `libduckdb` shared library, both of which link a larger set.
#' It does not describe this R package, which is compiled from the same
#' sources with a different extension list.
#'
#' To see the truth for your installation:
#'
#' ```r
#' dbGetQuery(con, "
#'   SELECT extension_name, installed, loaded, install_mode
#'   FROM duckdb_extensions()
#'   WHERE installed OR loaded
#' ")
#' ```
#'
#' `install_mode` is `STATICALLY_LINKED` for the bundled two
#' and `REPOSITORY` for anything you installed yourself.
#'
#' # Autoload is on, autoinstall is off
#'
#' Two engine settings govern the behavior, and this package sets them apart:
#'
#' \describe{
#'   \item{`autoload_known_extensions` (`true`)}{A known extension that is
#'     already installed is loaded automatically the first time a query needs
#'     it. You do not have to say `LOAD`.}
#'   \item{`autoinstall_known_extensions` (`false`)}{Nothing is downloaded
#'     behind your back. A query that needs an extension you have never
#'     installed fails with a message naming it, rather than silently reaching
#'     out to the network.}
#' }
#'
#' So the workflow is: install once, then forget about it.
#'
#' ```r
#' dbExecute(con, "INSTALL icu")   # once per DuckDB version and platform
#' # from now on, any query that needs ICU loads it by itself
#' ```
#'
#' The DuckDB CLI ships with `autoinstall_known_extensions` enabled, which is
#' why a statement that works there can fail here. To opt into the same
#' behavior for a session:
#'
#' ```r
#' dbExecute(con, "SET autoinstall_known_extensions = true")
#' ```
#'
#' The default is deliberate: an R package may not reach the network as a side
#' effect of an ordinary operation, so the first download has to be something
#' you asked for.
#'
#' # Installed once per version and platform
#'
#' Installed extensions are cached on disk under the extension directory --
#' see [duckdb_storage] for where that is and how to move it --
#' keyed by the DuckDB version and the platform string.
#'
#' Two consequences:
#'
#' * After the package updates its vendored DuckDB, previously installed
#'   extensions no longer match and must be installed again.
#' * `FORCE INSTALL <name>` re-downloads an extension whose cached copy is
#'   stale or truncated.
#'
#' Extension downloads are the caller's responsibility, and can fail on
#' machines without network access. Tests that need an extension should skip
#' when the install fails; see [duckdb_storage] for the pattern.
#'
#' # Platforms
#'
#' \describe{
#'   \item{Windows (x86-64)}{R builds identify as `windows_amd64_mingw`.
#'     Extensions built for that platform have been published since DuckDB
#'     1.4.1; before that, many out-of-tree extensions returned HTTP 403 or 404
#'     for it. If you see such an error, check the DuckDB version first.}
#'   \item{Windows (ARM64)}{No extension distribution exists for
#'     `windows_arm64_mingw` yet, so extension installs fail there.}
#'   \item{macOS, Linux (x86-64, ARM64)}{Fully supported, subject to the
#'     C++ standard library note below.}
#'   \item{webR / WebAssembly}{Extension loading is not supported yet.}
#' }
#'
#' # Linux builds not compiled with libstdc++
#'
#' DuckDB's prebuilt extensions are compiled against `libstdc++`.
#' Loading one into a package that was itself compiled against a different C++
#' standard library is ABI-incompatible and crashes R rather than failing
#' cleanly.
#'
#' The package therefore disables extensions automatically on a Linux build
#' that was not compiled against `libstdc++`, and says so once per session.
#' `INSTALL` and `LOAD` then error, and automatic loading is off.
#'
#' Every other platform is unaffected -- macOS uses `libc++`, but its prebuilt
#' extensions match.
#'
#' Override the decision, in precedence order, with the `allow_extensions`
#' argument of [duckdb()], the `duckdb.allow_extensions` option, or the
#' `DUCKDB_R_ALLOW_EXTENSIONS` environment variable:
#'
#' ```r
#' con <- dbConnect(duckdb(allow_extensions = FALSE))  # accept, and stay quiet
#' con <- dbConnect(duckdb(allow_extensions = TRUE))   # try anyway; may crash R
#' ```
#'
#' # Troubleshooting
#'
#' \describe{
#'   \item{"Extension X is not installed"}{Expected: autoinstall is off.
#'     Run `INSTALL X` once.}
#'   \item{An `icu` function is missing, or time zones behave oddly}{`icu` is
#'     not bundled. `INSTALL icu`, then reconnect or re-run the query.}
#'   \item{HTTP 403 or 404 downloading an extension}{The extension has no build
#'     for your platform and DuckDB version. Check `INSTALL` against a newer
#'     DuckDB, and read the troubleshooting URL in the error, which names the
#'     version, platform, and extension it looked for.}
#'   \item{`INSTALL` errors saying extensions are disabled}{A Linux build not
#'     compiled against `libstdc++`; see the section above.}
#'   \item{An extension worked yesterday and is gone today}{The package was
#'     updated and vendors a new DuckDB. Install it again.}
#'   \item{It works in the DuckDB CLI but not from R}{Most often autoinstall,
#'     sometimes a different extension directory. Compare
#'     `SELECT * FROM duckdb_extensions()` on both sides.}
#' }
#'
#' @seealso [duckdb()] for the `allow_extensions` argument,
#'   [duckdb_storage] for where extensions are cached.
#' @name duckdb_extensions
NULL
