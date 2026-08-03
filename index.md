# duckdb

[![DuckDB
logo](https://duckdb.org/images/logo-dl/DuckDB_Logo-horizontal.svg)](https://r.duckdb.org/)

[DuckDB](https://duckdb.org/) is an in-process SQL OLAP database
management system. It is designed to support analytical query workloads
and is optimized for fast query execution. This repository contains the
R bindings for DuckDB.

## Installation from CRAN

This is the recommended method for recent R versions on Windows or macOS
which have binaries available on CRAN.

``` r

install.packages("duckdb")
```

For Linux or older R versions, installing the package from source may
take up to an hour. Consider the [Posit Public Package
Manager](https://p3m.dev/) for binary installs (see the next section).

## Installation from the Posit Public Package Manager

This repository serves binary builds of CRAN packages for a wide variety
of platforms. Follow setup instructions from
<https://p3m.dev/client/#/repos/cran/setup>. For example, to install the
ManyLinux version of duckdb that is likely to work on your Linux, use:

``` r

install.packages("duckdb", repos = sprintf(
  "https://p3m.dev/cran/latest/bin/linux/manylinux_2_28-%s/%s", R.version["arch"], substr(getRversion(), 1, 3)
))
```

To check the availability of binaries for your platform, navigate to the
[duckdb search
page](https://p3m.dev/client/#/repos/cran/packages/overview?search=duckdb).

## Installation from r-universe

This repository serves development versions. Binaries are available for
recent versions of R and for some platforms. Review
<https://docs.r-universe.dev/install/binaries.html> for configuring
installation of binary packages on Linux.

``` r

install.packages("duckdb", repos = c("https://duckdb.r-universe.dev", "https://cloud.r-project.org"))
```

Installing the package from source may take up to an hour.

## Installation from GitHub

``` r

# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pak("duckdb/duckdb-r")
```

Installing the package from GitHub may take up to an hour.

## Flavors

The sources in this repository are published under several names —
`duckdb` on CRAN, and every flavor on
[r-universe](https://duckdb.r-universe.dev/builds). The `.dev` flavors
are created by an automated vendoring process; the CRAN and LTS flavors
always point at a stable upstream release.

| Flavor | Series | Kind | Progress |
|----|----|----|----|
| `duckdb` | [`v1.5-variegata`](https://github.com/duckdb/duckdb/tree/v1.5-variegata) | CRAN | [![CRAN version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fpackagemanager.posit.co%2F__api__%2Frepos%2Fcran%2Fpackages%2Fduckdb&query=%24.version&label=version&color=green)](https://cran.r-project.org/package=duckdb) |
| `duckdb.1.4` | [`v1.4-andium`](https://github.com/duckdb/duckdb/tree/v1.4-andium) | LTS | [![r-universe version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fduckdb.r-universe.dev%2Fapi%2Fpackages%2Fduckdb.1.4&query=%24.Version&label=version&color=green)](https://duckdb.r-universe.dev/duckdb.1.4) |
| `duckdb.dev` | [`main`](https://github.com/duckdb/duckdb/tree/main) | dev | [![ahead](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=main&head=main-green&label=ahead&color=green)](https://github.com/krlmlr/duckdb-r/compare/main...main-green) [![in flight](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=main-green&head=main-dev&label=in%20flight&color=yellow)](https://github.com/krlmlr/duckdb-r/compare/main-green...main-dev) [![buffered](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=main-build-base&head=main-build&label=buffered&color=blue)](https://github.com/krlmlr/duckdb-r/compare/main-build-base...main-build) |
| `duckdb.1.5.dev` | [`v1.5-variegata`](https://github.com/duckdb/duckdb/tree/v1.5-variegata) | dev | [![ahead](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=main&head=v1.5-variegata-green&label=ahead&color=green)](https://github.com/krlmlr/duckdb-r/compare/main...v1.5-variegata-green) [![in flight](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.5-variegata-green&head=v1.5-variegata-dev&label=in%20flight&color=yellow)](https://github.com/krlmlr/duckdb-r/compare/v1.5-variegata-green...v1.5-variegata-dev) [![buffered](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.5-variegata-build-base&head=v1.5-variegata-build&label=buffered&color=blue)](https://github.com/krlmlr/duckdb-r/compare/v1.5-variegata-build-base...v1.5-variegata-build) |
| `duckdb.1.4.dev` | [`v1.4-andium`](https://github.com/duckdb/duckdb/tree/v1.4-andium) | dev | [![ahead](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.4-andium&head=v1.4-andium-green&label=ahead&color=green)](https://github.com/krlmlr/duckdb-r/compare/v1.4-andium...v1.4-andium-green) [![in flight](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.4-andium-green&head=v1.4-andium-dev&label=in%20flight&color=yellow)](https://github.com/krlmlr/duckdb-r/compare/v1.4-andium-green...v1.4-andium-dev) [![buffered](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.4-andium-build-base&head=v1.4-andium-build&label=buffered&color=blue)](https://github.com/krlmlr/duckdb-r/compare/v1.4-andium-build-base...v1.4-andium-build) |

The badges track each `.dev` series: *ahead* counts commits ahead of the
branch the series releases from, *in flight* counts commits in CI but
not yet trusted, *buffered* counts commits vendored but not yet
verified. See the handbook’s
[`branches/`](https://github.com/duckdb/duckdb-r/blob/main/handbook/branches/README.md)
for the full model.

## User Guide

See the [R API in the DuckDB
documentation](https://duckdb.org/docs/api/r).

## Documentation

Everything this repository documents is reachable from the
[handbook](https://github.com/duckdb/duckdb-r/blob/main/handbook/README.md),
a strict topic hierarchy;
[`AGENTS.md`](https://github.com/duckdb/duckdb-r/blob/main/AGENTS.md) is
the door for maintainers and coding agents, and
[`plan/README.md`](https://github.com/duckdb/duckdb-r/blob/main/plan/README.md)
names the designs, plans, and historical documents.
[`BRANCHES.md`](https://github.com/duckdb/duckdb-r/blob/main/BRANCHES.md)
and
[`scripts/VENDORING.md`](https://github.com/duckdb/duckdb-r/blob/main/scripts/VENDORING.md)
hold detail the handbook is still absorbing.

## Building

To build the R package, you first need to clone this repository and
install the dependencies:

``` r

# install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch))
pak::pak()
```

Then, install:

``` sh
~duckdb-r: R CMD INSTALL .
```

Set the `MAKEFLAGS` environment variable to `-j8` or similar for
parallel builds. Configure `ccache` for faster repeated builds. A build
that links a prebuilt engine and finishes in seconds, and other details,
are described in the handbook under
[`build/`](https://github.com/duckdb/duckdb-r/blob/main/handbook/build/README.md).

## Vendoring

This package includes a vendored copy of the DuckDB C++ library. The
vendoring process is automated — a scheduled routine synchronizes each
release series with the upstream DuckDB repository, commit by commit.
How it works, and how to vendor by hand, is in the handbook under
[`operations/vendoring/`](https://github.com/duckdb/duckdb-r/blob/main/handbook/operations/vendoring/README.md).

## Contributors

Thanks to all
[contributors](https://github.com/duckdb/duckdb-r/graphs/contributors)
to this repository, and to those who contributed when the code was still
hosted in the main [duckdb/duckdb](https://github.com/duckdb/duckdb)
repository:

Mark Raasveldt, Pedro Holanda, Tom Ebergen, Reijo Sund, Nicolas Bennett,
Patrik Schratz, Tishj, Laurens Kuiper, Sam Ansmink, Andy Teucher, Hadley
Wickham, Jonathan Keane, Lindsay Wray, Richard Wesley, Elliana May,
Edwin de Jonge, Dewey Dunnington, Carlo Piovesan, Andre Beckedorf, Tania
Bogatsch, Pedro Ferreira, Maximilian Girlich, James Lamb, James Atkins,
usurai, Ubuntu, Noam Ross, Michael Antonov, Jeroen Ooms, Jamie Lentin,
Jacob, and Chilarai.
