<div align="center">
  <img src="https://duckdb.org/images/logo-dl/DuckDB_Logo-stacked.svg" height="120">
</div>

# duckdb R package

## Installation from CRAN

``` r
install.packages("duckdb")
```

## Installation from r-universe

``` r
install.packages("duckdb", repos = c("https://duckdb.r-universe.dev", "https://cloud.r-project.org"))
```

## Installation from GitHub

``` r
# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pak("duckdb/duckdb-r")
```

## User Guide

See the [R API in the DuckDB documentation](https://duckdb.org/docs/api/r).

## Building

To build the bleeding edge of duckdb-r, you can clone this repository and run

``` sh
~duckdb-r: R CMD INSTALL .
```

If you wish to test new duckdb functionality with duckdb-r, make sure your clones of `duckdb-r` and `duckdb` share the same parent directory.
Then run the following commands

``` sh
~ (cd duckdb && git checkout {{desired_branch}})
~ (cd ducdkb-r && ./vendor.sh)
~ (cd duckdb-r && R CMD INSTALL .)
```

It helps if both the duckdb directory and duckdb-r directory are clean.
If you encounter linker errors, merge both duckdb-r and duckdb with their respective main branches.

## Dependencies

To build the R package, you first need to install the dependencies:

``` r
# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pak()
```

### Developing with Extensions

If you wish to build or add extensions to the R package you first need to build duckdb with the `extension_static_build` flag.
The following commands allow you to add the [`httpfs` extension](https://duckdb.org/docs/extensions/httpfs) to a DuckDB R build.
See the [extension ReadMe](https://github.com/duckdb/duckdb/tree/master/extension#readme) for more information about extensions

``` sh
cd duckdb/
EXTENSION_STATIC_BUILD=1 make
```

Then in R, run:

``` r
library(duckdb)
con <- DBI::dbConnect(duckdb(config=list('allow_unsigned_extensions'='true')))
dbExecute(con, "LOAD '{{path_to_duckdb}}/build/release/extension/httpfs/httpfs.duckdb_extension'")
```

For more information about using extensions, see the [documentation on extensions](https://duckdb.org/docs/extensions/overview).
For instructions on building them, see [extension README](https://github.com/duckdb/duckdb/tree/main/extension#readme).
