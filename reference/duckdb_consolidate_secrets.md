# Consolidate DuckDB secrets into the configured secret directory

**\[experimental\]**

Consolidates DuckDB stored secrets from up to three source directories
into the directory currently configured as the target for this R
session.

## Usage

``` r
duckdb_consolidate_secrets(from = NULL, overwrite = FALSE, ask = interactive())
```

## Arguments

- from:

  Optional path to an additional source directory to merge in, or `NULL`
  (the default) for none.

- overwrite:

  If `FALSE` (the default), the function aborts when any source file
  would overwrite an existing secret of the same name at the target. Set
  to `TRUE` to allow overwriting.

- ask:

  If `TRUE` (the default in interactive sessions), confirm the plan
  before executing it.

## Value

The target directory, invisibly.

## Details

The target directory is the one DuckDB would write to on the next
connection, determined by:

1.  `getOption("duckdb.secret_directory")`,

2.  the `DUCKDB_SECRET_DIRECTORY` environment variable,

3.  the R-specific default returned by
    [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

Two source directories are considered automatically:

- the location shared with the DuckDB CLI and Python client
  (`~/.duckdb/stored_secrets`), and

- the R-specific default location under
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

Whichever of these equals the target is skipped. An additional source
directory may be supplied via `from`. Source files are moved into the
target (copied and then removed).

To consistently share secrets with the DuckDB CLI and Python client, set
the `duckdb.secret_directory` R option, typically in `~/.Rprofile`:

    options(duckdb.secret_directory = "~/.duckdb/stored_secrets")

Alternatively, set the `DUCKDB_SECRET_DIRECTORY` environment variable in
`~/.Renviron` (e.g.\\ via
[`usethis::edit_r_environ()`](https://usethis.r-lib.org/reference/edit.html)).
Either way, then call `duckdb_consolidate_secrets()` to move existing
secrets into the chosen location.

The package emits a startup message when secret files exist in both the
R-default and common locations and neither `duckdb.secret_directory` nor
`DUCKDB_SECRET_DIRECTORY` is set. Pointing either at any location both
configures the resolver and silences the message.
