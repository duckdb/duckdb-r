<div align="center">
  <a href="https://r.duckdb.org/"><picture>
    <source media="(prefers-color-scheme: light)" srcset="https://duckdb.org/images/logo-dl/DuckDB_Logo-horizontal.svg">
    <source media="(prefers-color-scheme: dark)" srcset="https://duckdb.org/images/logo-dl/DuckDB_Logo-horizontal-dark-mode.svg">
    <img alt="DuckDB logo" src="https://duckdb.org/images/logo-dl/DuckDB_Logo-horizontal.svg" height="100">
  </picture></a>
</div>

# duckdb

[DuckDB](https://duckdb.org/) is an in-process SQL OLAP database management system.
It is designed to support analytical query workloads and is optimized for fast query execution.
This repository contains the R bindings for DuckDB.

## Installation from CRAN

Installing the package from source may take up to an hour.
Consider using binary Windows/macOS packages from CRAN for recent R versions, or [Posit Package Manager](https://p3m.dev/) for various flavors of Linux or older R versions.

``` r
install.packages("duckdb")
```

## Installation from r-universe

Installing the package from source may take up to an hour.
Binaries are available for recent versions of R.
Review <https://docs.r-universe.dev/install/binaries.html> for configuring installation of binary packages on Linux.

``` r
install.packages("duckdb", repos = c("https://duckdb.r-universe.dev", "https://cloud.r-project.org"))
```

## Installation from GitHub

Installing the package from GitHub may take up to an hour.

``` r
# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pak("duckdb/duckdb-r")
```

## User Guide

See the [R API in the DuckDB documentation](https://duckdb.org/docs/api/r).

## Building

To build the R package, you first need to clone this repository and install the dependencies:

``` r
# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pak()
```

Then, install:

``` sh
~duckdb-r: R CMD INSTALL .
```

Set the `MAKEFLAGS` environment variable to `-j8` or similar for parallel builds.
Configure `ccache` for faster repeated builds.

If you wish to test new DuckDB functionality with duckdb-r, make sure your clone of `duckdb-r` is one level deeper than your clone of `duckdb` (e.g. `R/duckdb-r` and `duckdb`).
Then run the following commands:

``` sh
~ (cd duckdb && git checkout {{desired_branch}})
~ (cd R/duckdb-r && scripts/vendor.sh)
~ (cd R/duckdb-r && R CMD INSTALL .)
```

It helps if both the duckdb directory and duckdb-r directory are clean.

## Contributors

Thanks to all [contributors](https://github.com/duckdb/duckdb-r/graphs/contributors) to this repository, and to those who contributed when the code was still hosted in the main [duckdb/duckdb](https://github.com/duckdb/duckdb) repository:

Mark Raasveldt, Pedro Holanda, Tom Ebergen, Reijo Sund, Nicolas Bennett, Patrik Schratz, Tishj, Laurens Kuiper, Sam Ansmink, Andy Teucher, Hadley Wickham, Jonathan Keane, Lindsay Wray, Richard Wesley, Elliana May, Edwin de Jonge, Dewey Dunnington, Carlo Piovesan, Andre Beckedorf, Tania Bogatsch, Pedro Ferreira, Maximilian Girlich, James Lamb, James Atkins, usurai, Ubuntu, Noam Ross, Michael Antonov, Jeroen Ooms, Jamie Lentin, Jacob, and Chilarai.
