<img src="https://duckdb.org/images/DuckDB_Logo_dl.png" height="50">

# duckdb R package

## Installation from CRAN

```r
install.packages("duckdb")
```

## Building

The default build compiles a release version from an amalgamation.

```sh
R CMD INSTALL .
```


## Dependencies

To build the R package, you first need to install the dependencies:

```r
# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pak()
```
