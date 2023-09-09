<img src="https://duckdb.org/images/DuckDB_Logo_dl.png" height="50">

# duckdb R package

## Installation from CRAN

```r
install.packages("duckdb")
```

## Building

To build the bleeding edge of duckdb-r, you can clone this repository and run 

```sh
~duckdb-r: R CMD INSTALL .
```

If you wish to test new duckdb functionality with duckdb-r, make sure your clones of `duckdb-r` and `duckdb` share the same parent directory. Then run the following commands
```sh
~ (cd duckdb && git checkout {{desired_branch}})
~ (cd ducdkb-r && ./vendor.sh)
~ (cd duckdb-r && R CMD INSTALL .)
```

It helps if both the duckdb directory and duckdb-r directory are clean. If you encounter linker errors, merge both duckdb-r and duckdb with their respective main branches. 


## Dependencies

To build the R package, you first need to install the dependencies:

```r
# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pak()
```
