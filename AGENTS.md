# DuckDB R Package - Operational Instructions

R package that contains a vendored copy of the DuckDB C++ library and glue code for R, including a DBI and a relational interface.

## Working Effectively

### Bootstrap, Build, and Test the Repository

- `sudo apt-get install -y r-base r-base-dev build-essential` -- installs R and development tools
- `mkdir -p ~/R/library && echo '.libPaths("~/R/library")' > ~/.Rprofile` -- sets up local R library
- `export MAKEFLAGS="-j$(nproc)"` -- enables parallel compilation
- `UserNM=true R CMD INSTALL . --no-byte-compile` -- builds and installs the package. NEVER CANCEL: takes 10-15 minutes on first build. Set timeout to 30+ minutes.

For an interactive edit-build-test loop, prefer the prebuilt-libduckdb fast path (seconds instead of 10-15 minutes) -- see ["Fast build with system libduckdb"](#fast-build-with-system-libduckdb-linuxmacos-opt-in) and ["Testing with prebuilt DuckDB"](#testing-with-prebuilt-duckdb-the-fast-iterate-loop) below.

### Run Tests

- `R -q -e "testthat::test_local()"` -- runs all tests. Takes about 45 seconds. NEVER CANCEL: set timeout to 5+ minutes.
- `R -q -e "testthat::test_local(filter = '^name$')"` -- runs specific test file by name

### Manual Validation

- ALWAYS test basic DuckDB functionality after making changes by running a complete scenario
- Test connection, table creation, data insertion, and querying:

    ```r
    library(duckdb)
    con <- dbConnect(duckdb())
    dbExecute(con, "CREATE TABLE test (id INTEGER, name VARCHAR)")
    dbExecute(con, "INSERT INTO test VALUES (1, 'Alice'), (2, 'Bob')")
    result <- dbGetQuery(con, "SELECT * FROM test ORDER BY id")
    print(result)
    dbDisconnect(con, shutdown=TRUE)
    ```

### Format Checking (Optional - Has Known Issues)

- `pip3 install cmake-format && export PATH="$HOME/.local/bin:$PATH"` -- installs formatter
- `make format-check` -- checks code formatting (currently shows formatting differences)

### Markdown Linting

- `npm install -g markdownlint-cli` -- installs markdownlint
- `markdownlint *.md scripts/*.md` -- checks markdown files for style issues

## Validation

- ALWAYS run through a complete end-to-end scenario after making changes to ensure DuckDB R package functionality works correctly.
- The package can be built and tested successfully, though some formatting issues exist in the current codebase.
- One test failure is expected in clock function tests (unrelated to core functionality).
- Format checking will show differences but should not block development.

## Repository Structure and Key Locations

- `R/`: R source code (17 files) - DBI interface, connection handling, result processing
- `src/*.cpp`: C++ glue code (~30 files) - R to DuckDB interface
- `src/duckdb/`: Vendored DuckDB C++ source code (~1700 C++ files, ~1400 headers) - DO NOT modify except in rare cases
- `tests/testthat/`: Unit tests (~40 test files) - comprehensive test coverage
- `scripts/`: Build and maintenance scripts - vendor.sh, vendor-one.sh, format.py, setup-makeflags.R
- `configure`/`configure.win`: Build configuration scripts
- `DESCRIPTION`: R package metadata and dependencies
- `README.md`: Main documentation with build instructions
- `CLAUDE.md`: Operational instructions for AI
- `scripts/VENDORING.md`: Comprehensive vendoring documentation
- `.github/workflows/`: CI/CD workflows for testing on multiple platforms

## Vendoring

The duckdb-r package vendors (includes a copy of) the DuckDB C++ core library. Key points:

- **Automated Process**: Runs hourly via GitHub Actions, vendors from upstream DuckDB
- **Branch Strategy**: `main` tracks stable `v1.3-ossivalis`, `next` tracks bleeding-edge `main`
- **Never modify `src/duckdb/` directly** - changes will be overwritten by vendoring
- **Patching**: Add files to the `patch/` directory to apply R-specific modifications to vendored code. Send patches upstream as pull requests every once in a while.
- **Manual vendoring**: Use `scripts/vendor.sh /path/to/duckdb/repo` for testing
- **Full documentation**: See [VENDORING.md](scripts/VENDORING.md) for complete details

## Common Tasks

The following are validated commands and their typical execution times:

### Building

```bash
# From the duckdb-r directory
UserNM=true R CMD INSTALL . --no-byte-compile
```

### Fast build with system libduckdb (Linux/macOS, opt-in)

For iteration during development (and for coding agent sessions), the R
package can skip compiling the ~1700 vendored .cpp files and link
against a system-installed libduckdb instead. Drops a clean
`R CMD INSTALL .` from 10–15 minutes to about 5 seconds.

```bash
# One-time: install libduckdb matching the vendored DuckDB version
sudo scripts/install-libduckdb.sh        # to /usr/local
# or: scripts/install-libduckdb.sh --prefix "$HOME/.local"

# Each install
DUCKDB_R_USE_SYSTEM_LIB=1 R CMD INSTALL . --no-byte-compile
```

**What this mode actually does.** The R glue compiles against the
**vendored headers** in `src/duckdb/src/include/` (the amalgamated
`duckdb.hpp` shipped with libduckdb releases is missing ~37 of the 71
internal C++ headers the glue needs — templates like `GenericExecutor`,
the Arrow integration, core-functions extension internals). Only the
**implementation** is swapped for the system-installed `libduckdb.so`
/ `.dylib` at link time and at runtime.

That is only safe if the vendored sources and the installed library
were built from the **same commit**. `configure` extracts the
`DUCKDB_SOURCE_ID` from the vendored `pragma_version.cpp`, greps for
it inside the shared library, and aborts with a clear error if it is
not present. Re-run `scripts/install-libduckdb.sh` after every
vendoring bump.

The opt-in only applies to `R CMD INSTALL .` — not to `R CMD build`,
since the resulting installation depends on libduckdb being present at
runtime. The installed `duckdb.so` carries an rpath pointing at the
libduckdb directory; do not move libduckdb after installing.

### Testing with prebuilt DuckDB (the fast iterate loop)

`pkgload::load_all()` / `devtools::load_all()` — and therefore
`testthat::test_local()`, which loads the package the same way — honor
`DUCKDB_R_USE_SYSTEM_LIB` too: they compile only the ~30 glue `.cpp`
files in `src/` and link against the prebuilt libduckdb, exactly like
`R CMD INSTALL .`. This is the recommended setup for any
edit-build-test loop (including coding-agent sessions), because it turns
the otherwise 10–15 minute first build into seconds.

```bash
# One-time, matching the vendored DuckDB version (see above)
sudo scripts/install-libduckdb.sh          # or --prefix "$HOME/.local"

# Then, in every shell that builds/tests the package:
export DUCKDB_R_USE_SYSTEM_LIB=1
export MAKEFLAGS="-j$(nproc)"

R -q -e 'pkgload::load_all()'              # ~1 s warm, no source changes
R -q -e 'testthat::test_local()'           # runs the suite against the glue
```

Measured on a clean container (R 4.5.3, ccache warm): a no-op
`load_all()` takes about 1 second, and a `load_all()` after editing a
single glue file (recompile one `.cpp` + relink) about 4 seconds —
versus 10–15 minutes when the vendored sources are compiled. The same
`configure` commit-match guard applies, so re-run
`scripts/install-libduckdb.sh` after every vendoring bump; if it
reports a `-dev` snapshot with no published prebuilt, drop
`DUCKDB_R_USE_SYSTEM_LIB` and fall back to a source build.

In CI, `.github/workflows/custom/before-install/action.yml` defaults all
Linux/macOS builds (the smoke test and the regular matrix) to the fast
path, except:

* the `krlmlr/duckdb-r` fork, which hosts the vendoring pipeline and
  must always build from source;
* any matrix entry that pins `DUCKDB_R_USE_SYSTEM_LIB` itself through the
  generic `env` field in `.github/versions-matrix.R`. That file carries a
  dedicated "vendored build" entry (`DUCKDB_R_USE_SYSTEM_LIB=0`) so one
  regular matrix build still compiles the bundled sources — the artifact
  that ships to CRAN.

The libduckdb that `scripts/install-libduckdb.sh` fetches matches the
vendored commit: tagged versions come from the GitHub release assets,
development snapshots (e.g. `v1.5.4-dev157`) from the DuckDB nightly
staging bucket keyed by `DUCKDB_SOURCE_ID`.

IMPORTANT: `.dd` files in `src/` are dependency tracking files for development (source files that need rebuilding when a header file changes) and should be kept in version control.
These files are generated by the `%.dd: %.d` rule in `src/include/deps.mk`, which filters compiler-generated `.d` files to keep only local `include/` dependencies.
The files should only change when new `#include` directives for local headers are added to `.cpp` files.
If a build regenerates them with system paths (`/opt/R/...`) or `../inst/include/...` entries, that is a spurious change — revert with `git checkout -- src/*.dd`.
The root cause of spurious regeneration was a bug in `deps.mk` where the filter used `^  ` (exactly two spaces) but compiler continuation lines have only one space; this has been fixed to `^ *`.

## Running Tests

```bash
# Run all tests
R -q -e "testthat::test_local()"

# Run specific test file (replace 'array' with the test name, or use more complex regex)
R -q -e "testthat::test_local(filter = '^array$')"
```

## Manual Testing Scripts

```bash
# Run bug reproduction script
R -q -f bug.R

# Run any R script
R -q -f script_name.R
R
```

## Test Development

- Test files located in `tests/testthat/`
- Use `testthat::test_local(filter = "name")` for running specific test files
- Always add tests when fixing bugs to prevent regression

## Code Style Guidelines

- All files must end with an end-of-line (EOL) character
- Ensure proper code formatting and consistent indentation
- Follow R package development best practices

## C++ Warning Policy

- **Do not suppress warnings with `#pragma clang diagnostic ignored` or similar.** CRAN rejects packages that silence warnings rather than fixing the underlying issue.
- Fix the root cause instead. For vendored code in `src/duckdb/`, add a patch file in `patch/` that corrects the source of the warning (e.g. by changing template definitions to avoid instantiating deprecated types).
- Example: `-Wdeprecated-declarations` from `char_traits<T>` for non-char `T` in libc++ was fixed by changing the `std_string_view` alias in `src/duckdb/third_party/fmt/include/fmt/core.h` to a struct that only provides `std::basic_string_view<Char>` for standard char types.

## C++ Glue Code Conventions

- R string constants and symbols (SEXP) used in C++ glue code are defined in `src/utils.cpp` (in `RStrings::RStrings()`) and declared in `src/include/rapi.hpp` (in `struct RStrings`).
- Always add new string constants and `Rf_install()` symbols to `RStrings` rather than using inline `StringsToSexp()`, `Rf_mkString()`, or `Rf_install()` calls in hot paths.

## Dependencies

System requirements already satisfied in typical development environment:

- R >= 4.2.0
- build-essential (gcc, g++, make)
- Standard R packages: DBI, testthat, methods, utils
- Optional: cmake-format for code formatting

## Package Information

- **Package Type**: R package providing DBI interface to DuckDB
- **Core Functionality**: In-process SQL OLAP database for R
- **Installation Time**: Up to 60 minutes from source (mentioned in README)
- **Build Architecture**: C++ database engine with R bindings
- **Key Features**: DBI compliance, Arrow integration, analytical query performance
