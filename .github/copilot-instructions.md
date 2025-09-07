# GitHub Copilot Instructions for DuckDB R Package

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively
- Bootstrap, build, and test the repository:
  - `sudo apt-get install -y r-base r-base-dev build-essential` -- installs R and development tools
  - `mkdir -p ~/R/library && echo '.libPaths("~/R/library")' > ~/.Rprofile` -- sets up local R library
  - `export MAKEFLAGS="-j$(nproc)"` -- enables parallel compilation 
  - `R CMD INSTALL . --no-byte-compile` -- builds and installs the package. NEVER CANCEL: takes 10-15 minutes on first build. Set timeout to 30+ minutes.
  - Alternative build: `UserNM=true R CMD INSTALL . --no-byte-compile` -- alternative build command from CLAUDE.md
- Run tests:
  - `R -q -e "testthat::test_local()"` -- runs all tests. Takes about 45 seconds. NEVER CANCEL: set timeout to 5+ minutes.
  - `R -q -e "testthat::test_local(filter = '^name$')"` -- runs specific test file by name
- Manual validation:
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
- Format checking (optional - has known issues):
  - `pip3 install cmake-format && export PATH="$HOME/.local/bin:$PATH"` -- installs formatter
  - `make format-check` -- checks code formatting (currently shows formatting differences)

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
- `scripts/`: Build and maintenance scripts - vendor.sh, format.py, setup-makeflags.R
- `configure`/`configure.win`: Build configuration scripts
- `DESCRIPTION`: R package metadata and dependencies
- `README.md`: Main documentation with build instructions
- `CLAUDE.md`: Operational instructions for developers
- `.github/workflows/`: CI/CD workflows for testing on multiple platforms

## Common Tasks
The following are validated commands and their typical execution times:

### Building
```bash
# First time build (clean state)
export MAKEFLAGS="-j$(nproc)"
time R CMD INSTALL . --no-byte-compile
# Time: 10-15 minutes. NEVER CANCEL - set timeout to 30+ minutes

# Subsequent builds (with cache)  
time UserNM=true R CMD INSTALL . --no-byte-compile
# Time: ~3 seconds with existing build cache
```

### Testing
```bash
# Run all tests
time R -q -e "testthat::test_local()"
# Time: ~45 seconds. Expected: 1 failure (clock functions), 75 skipped, 5800+ passed

# Run specific test
R -q -e "testthat::test_local(filter = '^connect$')"
# Time: ~3 seconds

# Manual functionality test
R -q -e 'library(duckdb); con <- dbConnect(duckdb()); dbGetQuery(con, "SELECT 42 as answer"); dbDisconnect(con, shutdown=TRUE)'
```

### Dependencies
System requirements already satisfied in typical development environment:
- R >= 4.1.0 
- build-essential (gcc, g++, make)
- Standard R packages: DBI, testthat, methods, utils
- Optional: cmake-format for code formatting

### Package Information  
- **Package Type**: R package providing DBI interface to DuckDB
- **Core Functionality**: In-process SQL OLAP database for R
- **Installation Time**: Up to 60 minutes from source (mentioned in README)
- **Build Architecture**: C++ database engine with R bindings
- **Key Features**: DBI compliance, Arrow integration, analytical query performance
