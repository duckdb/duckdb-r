# Installation

Choosing where to install the package from, and which flavor to install.
The exact commands stay in the root [`README.md`](/README.md):
CRAN renders it, so it is the first thing a user sees,
and it keeps the full install text and the `Flavors` table.

## Where to install from

Four sources serve the package, and they differ in what they carry.

* **CRAN** publishes the released `duckdb`.
  It is the recommended source for recent R versions on Windows and macOS,
  which have binaries there.
  For Linux or an older R it offers sources only,
  and a source install may take up to an hour.
* **The [Posit Public Package Manager](https://p3m.dev/)** serves binary
  builds of the same CRAN release for a wide variety of platforms,
  including Linux —
  the way around the hour-long source build.
  Setup instructions, a ManyLinux one-liner,
  and the page that shows which binaries exist for a platform
  are linked from the root `README.md`.
* **[r-universe](https://duckdb.r-universe.dev)** serves development versions,
  and it is where every flavor other than the CRAN `duckdb` is published.
  Binaries are available for recent versions of R and for some platforms;
  where they are not, the source install applies again.
* **GitHub** installs the current state of this repository with
  `pak::pak("duckdb/duckdb-r")`, always from source.

## Which flavor

One source tree is published under several package names.
Use `duckdb` unless you need to pin to a minor version
or to test unreleased functionality:

* `duckdb` — the current stable release, on CRAN and on r-universe.
* `duckdb.1.4` — the LTS line, on r-universe, receiving bug fixes only.
  There is no `duckdb.1.5`, because v1.5 is not an LTS version.
* `duckdb.dev`, `duckdb.1.5.dev`, `duckdb.1.4.dev` — bleeding-edge builds
  of the corresponding upstream branch, on r-universe.
  They let you test what a release will contain without waiting for CRAN.

Picking a flavor changes the package name and little else.
The rename rewrites `DESCRIPTION`, the loaded shared library,
and the name of the C++ header a downstream package links to,
but no exported function or method,
so code written against `duckdb` runs unchanged
once `library()` names the flavor you installed.
Because the names differ, a flavor installs alongside `duckdb`
instead of replacing it.

## Boundaries

Only `duckdb` reaches CRAN;
a flavored package's own `README.md` states that it is available
from r-universe and GitHub only,
and drops the CRAN and package-manager sections accordingly.
Which flavors exist at a given time is the root `README.md` table;
what a flavor *is* — one source tree, many names,
and the series that produce them —
belongs to [`branches/flavors/`](/handbook/branches/flavors/).

Installing a published package is not the same as building the tree:
compiling from a clone,
and the switches that make that fast,
are [`build/source-build/`](/handbook/build/source-build/)
and [`build/fast-paths/`](/handbook/build/fast-paths/).
Which DuckDB extensions an installed package can reach,
and how further ones are obtained,
is a separate question — see [`usage/extensions/`](/handbook/usage/extensions/).
