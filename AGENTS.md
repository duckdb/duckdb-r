# DuckDB R Package - Operational Instructions

R package that contains a vendored copy of the DuckDB C++ library and glue code for R, including a DBI and a relational interface.

## Where to look

This file and `README.md` are the roots of the documentation tree:
`README.md` for using the package, this file for working on it.
Each row names the single document that owns a topic;
start there rather than searching.

| To solve | Read |
|---|---|
| Build and install the package; every build knob | `BUILD.md` |
| Run and extend the testsuite; validate a change | this file (below) |
| Branch model, package flavors, series invariants | `BRANCHES.md` |
| Release process, modelled as a state machine | `RELEASE.md` |
| Vendoring mechanics: scripts, invariants, troubleshooting | `scripts/VENDORING.md` |
| Per-commit CI (sharded matrix): design and limits | `scripts/EACH.md` |
| Operating the vendoring loop (routine playbooks) | `.claude/skills/`: `series-loop.md`, `series-forward.md`, `series-rebase.md`, `series-open.md` |
| Designs, plans, and historical documents | `plan/` |

## Working Effectively

### Bootstrap and Build

- `sudo apt-get install -y r-base r-base-dev build-essential` -- installs R and development tools
- `mkdir -p ~/R/library && echo '.libPaths("~/R/library")' > ~/.Rprofile` -- sets up local R library

Then set up the fast path once, and use it for everything below:

```sh
sudo scripts/install-libduckdb.sh
export DUCKDB_R_USE_SYSTEM_LIB=1 MAKEFLAGS="-j$(nproc)"
R CMD INSTALL . --no-byte-compile      # ~90 s instead of 10-15 minutes
```

[`BUILD.md`](BUILD.md) owns the build system:
the three install paths and when each is valid,
every environment variable, the generated makefile fragments,
the `.dd` dependency files, the tarball layout, formatting, and the C++ warning policy.

Two rules from there are worth repeating because getting them wrong is silent:

- **Never export `UserNM=true` for `R CMD check`** -- it blinds the symbol scan
  and fails a package that registers its routines correctly.
- **Never verify engine configuration under `DUCKDB_R_USE_SYSTEM_LIB`** -- the release
  libduckdb links a different extension set and a different `autoinstall` default
  than the vendored build. See [`BUILD.md`](BUILD.md#the-fast-path-is-not-the-package).

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

- **Automated Process**: Runs daily via GitHub Actions in `krlmlr/duckdb-r`, gated on the per-commit `rcc` build status
- **Branch Strategy**: one dev branch per upstream branch (`main-dev` ← `main`, `v1.5-variegata-dev` ← `v1.5-variegata`, `v1.4-andium-dev` ← `v1.4-andium`); see [BRANCHES.md](BRANCHES.md)
- **One commit at a time**: each vendor commit corresponds to exactly one upstream commit, and must build and pass tests on its own — fold any required glue fix into that commit rather than adding a follow-up
- **Never modify `src/duckdb/` directly** - changes will be overwritten by vendoring
- **Patching**: Add files to the `patch/` directory to apply R-specific modifications to vendored code. Send patches upstream as pull requests every once in a while. A patch that no longer applies is deleted by the next vendor run.
- **Manual vendoring**: Use `scripts/vendor.sh /path/to/duckdb/repo` for testing
- **Full documentation**: See [VENDORING.md](scripts/VENDORING.md) for complete details

## Common Tasks

Build and install commands, the fast paths, and every build knob live in
[`BUILD.md`](BUILD.md). The rest of this file covers testing and conventions.

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

## Never Hard-Code the Package Name

The package is published under several names —
`duckdb` on CRAN, and `duckdb.dev`, `duckdb.1.5.dev`, `duckdb.1.4` and friends on r-universe —
all built from the same sources with `scripts/flavor.sh` applying the rename
(see [BRANCHES.md](BRANCHES.md#r-package-flavors)).
Anything that writes `duckdb` literally works on `main` and breaks on every other branch.

`R/package.R` is the seam for this:

| Helper | Returns |
|---|---|
| `get_package_name()` | the current package name, via `utils::packageName()` |
| `get_package_env()` | that package's namespace, via `asNamespace()` |
| `get_package_spec()`, `get_package_version()` | the namespace spec and version |
| `system_file_path(...)` | a path inside the installed package (also the mockable seam tests stub) |

`simulate_duckdb()` exposes the first two as `$pkg` and `$env`,
which is what makes `@examplesIf simulate_duckdb()$env$examples_enabled()` work under any flavor.

Use them anywhere the package refers to itself:

* `system.file(..., package = get_package_name())`, never the package name as a string literal;
* `get_package_env()$some_internal`, never a `:::` qualifier on our own name;
* in roxygen too — an inline chunk `` `r get_package_env()$CONSTANT` `` resolves under any name,
  while the same chunk written with a `:::` qualifier fails everywhere except `main`.

The roxygen case is worth calling out because it fails in a confusing way.
roxygen2 evaluates inline chunks in the package's own namespace,
so an unresolvable reference does not raise an error:
the chunk, **and every other inline chunk in the same roxygen block**,
is emitted verbatim as `\verb{r ...}`.
A single hard-coded qualifier therefore silently de-evaluates its neighbours —
a single qualified reference in `R/storage.R` also took out the `lifecycle::badge()` chunk beside it.
The regenerated `.Rd` then differs from the committed one
and CI fails at the `roxygenize` step, before anything is compiled.

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
