# DuckDB R Package - Operational Instructions

R package that contains a vendored copy of the DuckDB C++ library and glue code for R, including a DBI and a relational interface.

## Package layout

- `R/`: R scripts and package code
- `src/*.cpp`: C++ glue
- `src/duckdb/`: C++ source code for DuckDB, can be reviewed but only modified in rare cases
- `tests/`: Unit tests for the package

## Compilation

```bash
# From the duckdb-r directory
UserNM=true R CMD INSTALL . --no-byte-compile
```

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
