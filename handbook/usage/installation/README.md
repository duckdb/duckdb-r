# Installation

Choosing where to install the package from, and which flavor.
The exact commands stay in the root [`README.md`](/README.md),
which CRAN renders and which keeps the full install text
and the `Flavors` table.

Four sources serve the package:

* **CRAN** publishes the released `duckdb`,
  with binaries for recent R on Windows and macOS;
  elsewhere it is a source install,
  which compiles the whole vendored engine —
  tens of minutes rather than seconds.
* **[Posit Public Package Manager](https://p3m.dev/)** serves binaries
  of the same CRAN release for many platforms, including Linux.
* **[r-universe](https://duckdb.r-universe.dev)** serves
  development versions and every flavor, `duckdb` included.
* **GitHub** installs this repository's current state from source,
  `pak::pak("duckdb/duckdb-r")`.

Use `duckdb` unless you need to pin a minor version or to test
unreleased builds.
Which flavors exist is
[`branches/flavors/`](/handbook/branches/flavors/README.md)'s,
and the root `README.md`'s `Flavors` table
is where a new one is announced.
Picking a flavor changes the package name and little else,
and a flavor installs alongside `duckdb` instead of replacing it;
only `duckdb` reaches CRAN.

Compiling a clone yourself, and making that fast,
is [`build/source-build/`](/handbook/build/source-build/README.md)
and [`build/fast-paths/`](/handbook/build/fast-paths/README.md).
