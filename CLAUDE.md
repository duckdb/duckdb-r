# DuckDB R Package - Operational Instructions

R package that contains a vendored copy of the DuckDB C++ library and
glue code for R, including a DBI and a relational interface.

## Working Effectively

### Bootstrap, Build, and Test the Repository

- `sudo apt-get install -y r-base r-base-dev build-essential` – installs
  R and development tools
- `mkdir -p ~/R/library && echo '.libPaths("~/R/library")' > ~/.Rprofile`
  – sets up local R library
- `export MAKEFLAGS="-j$(nproc)"` – enables parallel compilation
- `UserNM=true R CMD INSTALL . --no-byte-compile` – builds and installs
  the package. NEVER CANCEL: takes 10-15 minutes on first build. Set
  timeout to 30+ minutes.

### Run Tests

- `R -q -e "testthat::test_local()"` – runs all tests. Takes about 45
  seconds. NEVER CANCEL: set timeout to 5+ minutes.
- `R -q -e "testthat::test_local(filter = '^name$')"` – runs specific
  test file by name

### Manual Validation

- ALWAYS test basic DuckDB functionality after making changes by running
  a complete scenario

- Test connection, table creation, data insertion, and querying:

  ``` r
  library(duckdb)
  con <- dbConnect(duckdb())
  dbExecute(con, "CREATE TABLE test (id INTEGER, name VARCHAR)")
  dbExecute(con, "INSERT INTO test VALUES (1, 'Alice'), (2, 'Bob')")
  result <- dbGetQuery(con, "SELECT * FROM test ORDER BY id")
  print(result)
  dbDisconnect(con, shutdown=TRUE)
  ```

### Format Checking (Optional - Has Known Issues)

- `pip3 install cmake-format && export PATH="$HOME/.local/bin:$PATH"` –
  installs formatter
- `make format-check` – checks code formatting (currently shows
  formatting differences)

### Markdown Linting

- `npm install -g markdownlint-cli` – installs markdownlint
- `markdownlint *.md scripts/*.md` – checks markdown files for style
  issues

## Validation

- ALWAYS run through a complete end-to-end scenario after making changes
  to ensure DuckDB R package functionality works correctly.
- The package can be built and tested successfully, though some
  formatting issues exist in the current codebase.
- One test failure is expected in clock function tests (unrelated to
  core functionality).
- Format checking will show differences but should not block
  development.

## Repository Structure and Key Locations

- `R/`: R source code (17 files) - DBI interface, connection handling,
  result processing
- `src/*.cpp`: C++ glue code (~30 files) - R to DuckDB interface
- `src/duckdb/`: Vendored DuckDB C++ source code (~1700 C++ files, ~1400
  headers) - DO NOT modify except in rare cases
- `tests/testthat/`: Unit tests (~40 test files) - comprehensive test
  coverage
- `scripts/`: Build and maintenance scripts - vendor.sh, vendor-one.sh,
  format.py, setup-makeflags.R
- `configure`/`configure.win`: Build configuration scripts
- `DESCRIPTION`: R package metadata and dependencies
- `README.md`: Main documentation with build instructions
- `CLAUDE.md`: Operational instructions for AI
- `scripts/VENDORING.md`: Comprehensive vendoring documentation
- `.github/workflows/`: CI/CD workflows for testing on multiple
  platforms

## Vendoring

The duckdb-r package vendors (includes a copy of) the DuckDB C++ core
library. Key points:

- **Automated Process**: Runs hourly via GitHub Actions, vendors from
  upstream DuckDB
- **Branch Strategy**: `main` tracks stable `v1.3-ossivalis`,
  [`next`](https://rdrr.io/r/base/Control.html) tracks bleeding-edge
  `main`
- **Never modify `src/duckdb/` directly** - changes will be overwritten
  by vendoring
- **Patching**: Add files to the `patch/` directory to apply R-specific
  modifications to vendored code. Send patches upstream as pull requests
  every once in a while.
- **Manual vendoring**: Use `scripts/vendor.sh /path/to/duckdb/repo` for
  testing
- **Full documentation**: See
  [VENDORING.md](https://r.duckdb.org/scripts/VENDORING.md) for complete
  details

## Common Tasks

The following are validated commands and their typical execution times:

### Building

``` bash
# From the duckdb-r directory
UserNM=true R CMD INSTALL . --no-byte-compile
```

## Running Tests

``` bash
# Run all tests
R -q -e "testthat::test_local()"

# Run specific test file (replace 'array' with the test name, or use more complex regex)
R -q -e "testthat::test_local(filter = '^array$')"
```

## Manual Testing Scripts

``` bash
# Run bug reproduction script
R -q -f bug.R

# Run any R script
R -q -f script_name.R
R
```

## Test Development

- Test files located in `tests/testthat/`
- Use `testthat::test_local(filter = "name")` for running specific test
  files
- Always add tests when fixing bugs to prevent regression

## Code Style Guidelines

- All files must end with an end-of-line (EOL) character
- Ensure proper code formatting and consistent indentation
- Follow R package development best practices

## Dependencies

System requirements already satisfied in typical development
environment:

- R \>= 4.1.0
- build-essential (gcc, g++, make)
- Standard R packages: DBI, testthat, methods, utils
- Optional: cmake-format for code formatting

## Package Information

- **Package Type**: R package providing DBI interface to DuckDB
- **Core Functionality**: In-process SQL OLAP database for R
- **Installation Time**: Up to 60 minutes from source (mentioned in
  README)
- **Build Architecture**: C++ database engine with R bindings
- **Key Features**: DBI compliance, Arrow integration, analytical query
  performance
