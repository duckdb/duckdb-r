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
| `duckdb.dev` | [`main`](https://github.com/duckdb/duckdb/tree/main) | dev | [![ahead](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=main&head=main-fwd-green&label=ahead&color=green)](https://github.com/krlmlr/duckdb-r/compare/main...main-fwd-green) [![in flight](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=main-fwd-green&head=main-fwd-dev&label=in%20flight&color=yellow)](https://github.com/krlmlr/duckdb-r/compare/main-fwd-green...main-fwd-dev) [![buffered](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=main-fwd-build-base&head=main-fwd-build&label=buffered&color=blue)](https://github.com/krlmlr/duckdb-r/compare/main-fwd-build-base...main-fwd-build) |
| `duckdb.1.5.dev` | [`v1.5-variegata`](https://github.com/duckdb/duckdb/tree/v1.5-variegata) | dev | [![ahead](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=main&head=v1.5-variegata-green&label=ahead&color=green)](https://github.com/krlmlr/duckdb-r/compare/main...v1.5-variegata-green) [![in flight](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.5-variegata-green&head=v1.5-variegata-dev&label=in%20flight&color=yellow)](https://github.com/krlmlr/duckdb-r/compare/v1.5-variegata-green...v1.5-variegata-dev) [![buffered](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.5-variegata-build-base&head=v1.5-variegata-build&label=buffered&color=blue)](https://github.com/krlmlr/duckdb-r/compare/v1.5-variegata-build-base...v1.5-variegata-build) |
| `duckdb.1.4.dev` | [`v1.4-andium`](https://github.com/duckdb/duckdb/tree/v1.4-andium) | dev | [![ahead](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.4-andium&head=v1.4-andium-dev&label=ahead&color=green)](https://github.com/krlmlr/duckdb-r/compare/v1.4-andium...v1.4-andium-green) [![in flight](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.4-andium-green&head=v1.4-andium-green&label=in%20flight&color=yellow)](https://github.com/krlmlr/duckdb-r/compare/v1.4-andium-green...v1.4-andium-dev) [![buffered](https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=v1.4-andium-build-base&head=v1.4-andium-build&label=buffered&color=blue)](https://github.com/krlmlr/duckdb-r/compare/v1.4-andium-build-base...v1.4-andium-build) |

The badges track each `.dev` series: *ahead* counts commits ahead of the
branch the series releases from, *in flight* counts commits in CI but
not yet trusted, *buffered* counts commits vendored but not yet
verified. See [`BRANCHES.md`](https://r.duckdb.org/BRANCHES.md) for the
full model.

## User Guide

See the [R API in the DuckDB
documentation](https://duckdb.org/docs/api/r).

## Documentation

Documentation is organized as a tree; this section is its root for
users, and [`AGENTS.md`](https://r.duckdb.org/AGENTS.md) is the root for
maintainers and coding agents.

- [`AGENTS.md`](https://r.duckdb.org/AGENTS.md) — working on the
  package: build, test, and where to look for everything else
- [`BRANCHES.md`](https://r.duckdb.org/BRANCHES.md) — branch model,
  package flavors, series invariants
- [`RELEASE.md`](https://r.duckdb.org/RELEASE.md) — the release process
- [`scripts/VENDORING.md`](https://r.duckdb.org/scripts/VENDORING.md) —
  vendoring mechanics
- [`plan/README.md`](https://r.duckdb.org/plan/README.md) — designs,
  plans, and historical documents, each named there by path

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
parallel builds. Configure `ccache` for faster repeated builds.

If you wish to test new DuckDB functionality with duckdb-r, make sure
your clone of `duckdb-r` is one level deeper than your clone of `duckdb`
(e.g. `R/duckdb-r` and `duckdb`). Then run the following commands:

``` sh
~ (cd duckdb && git checkout {{desired_branch}})
~ (cd R/duckdb-r && scripts/vendor.sh)
~ (cd R/duckdb-r && R CMD INSTALL .)
```

It helps if both the duckdb directory and duckdb-r directory are clean.

## Vendoring

This package includes a vendored copy of the DuckDB C++ library. The
vendoring process is automated — a scheduled routine synchronizes each
release series with the upstream DuckDB repository, commit by commit.
For detailed information about how vendoring works and manual vendoring
procedures, see
[`scripts/VENDORING.md`](https://r.duckdb.org/scripts/VENDORING.md).

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
