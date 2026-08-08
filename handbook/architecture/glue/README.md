# The C++ glue

The translation units in `src/` that bridge R and DuckDB,
and the conventions that govern C++ source in this package.
The engine underneath is
[`engine/`](/handbook/architecture/engine/README.md).

**The roster.**
`src/` holds two disjoint bodies of code:
the vendored engine under `src/duckdb/`,
and the glue translation units directly in `src/`,
listed in [`src/include/glue.mk`](/src/include/glue.mk)'s `GLUE` variable —
the split that lets the
[`build/fast-paths/`](/handbook/build/fast-paths/README.md)
compile the glue alone.
[`src/include/rapi.hpp`](/src/include/rapi.hpp) is the central
header: the external-pointer wrappers that carry engine objects
through R, every entry point,
`DUCKDB_PACKAGE_NAME` (the C++ half of the flavor seam),
and `DUCKDB_R_POISON_GUARD()` (the C++ half of the CRAN guard).

**cpp11 is vendored, not depended on** —
`inst/include/cpp11/` carries the copy,
taken from [`krlmlr/cpp11`](https://github.com/krlmlr/cpp11),
a patch stack on top of
[`r-lib/cpp11`](https://github.com/r-lib/cpp11):
this package needs extensions upstream does not ship.
An entry point is a function marked `[[cpp11::register]]`;
`cpp11::cpp_register()` writes both halves of the binding
(`src/cpp11.cpp`, `R/cpp11.R`),
which are generated and never edited.

**The generator is the fork too, and it is not vendored.**
`cpp_register()` does not come from `inst/include/cpp11/` —
it is an R function, resolved from whatever cpp11 the library holds,
and so it is the one part of cpp11 this repository cannot pin.
It has to be the fork as well,
because the flavor names it derives the `.Call` prefix from
carry more dots than CRAN's cpp11 replaces.
Install it from GitHub —
`remotes::install_github("krlmlr/cpp11")` —
beside `decor`, which `cpp_register()` also needs;
`krlmlr.r-universe.dev` does not build cpp11,
so naming that repository ahead of CRAN installs CRAN's.
[`scripts/flavor.sh`](/scripts/flavor.sh) refuses a generated binding
whose entry points are not C identifiers, which is what a wrong cpp11
produces.

**`RStrings`.**
R string constants and `Rf_install()` symbols used from C++
live in `struct RStrings` (`rapi.hpp`, built in `src/utils.cpp`) —
allocated once, preserved for the session.
Always add there rather than calling `Rf_mkString()` or
`Rf_install()` inline: an inline allocation in a conversion loop
runs per row, on exactly the paths that move data.

**No warning is suppressed.**
CRAN rejects `-Wno-*` flags and `#pragma` silencing;
fix the root cause instead,
and for vendored code fix it as a patch under `patch/` or upstream
([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
Where a fix is truly not possible —
mbedtls's own `-Wvla` suppression is the standing example —
the pragma is respelled with widened spacing
(`#pragma  GCC  diagnostic  ignored`),
which the compiler honours unchanged
while `R CMD check`'s single-space scan does not report it
([`patch/0016-Avoid-mbedtls-diagnostic-pragmas.patch`](/patch/0016-Avoid-mbedtls-diagnostic-pragmas.patch)).
Formatting runs through the Makefile `format-*` targets,
driving [`scripts/format.py`](/scripts/format.py).

**ALTREP relations.**
The R-facing half of this, and who consumes it, is
[`usage/relational/`](/handbook/usage/relational/README.md).
`rapi_rel_to_altrep()` wraps an unexecuted relation as a data frame;
nothing runs until R touches the values,
materialization is budgeted by `n_rows` and `n_cells`,
unlimited by default ([`R/relational.R`](/R/relational.R)),
and an execution error is stored and re-raised at every later access.
Raising an R error from inside an ALTREP method
is the known weak point —
a crash-class bug with a guard under review
([#1796](https://github.com/duckdb/duckdb-r/issues/1796),
[#1797](https://github.com/duckdb/duckdb-r/pull/1797)).

**The engine runs R code while it holds the client context lock.**
The replacement scans and the Arrow stream factory in
[`src/register.cpp`](/src/register.cpp),
and the progress display in
[`src/connection.cpp`](/src/connection.cpp),
are all reached from underneath a query the engine is already executing.
R may collect garbage in any of them,
and a collection runs the finalizer of every engine handle
the session has stopped referencing,
at a point no R code chose.
So no such finalizer may re-enter the client context it belongs to:
the context lock is not recursive,
and the callback's caller already owns it.
The rule binds the finalizers rather than the callbacks,
because a callback cannot know what R will collect inside it;
[`tests/testthat/test-progress_display.R`](/tests/testthat/test-progress_display.R)
pins it by collecting an abandoned handle
from inside the display's callback lookup.

**One header is public.**
[`inst/include/duckdb_types.hpp`](/inst/include/duckdb_types.hpp)
is what a downstream R package compiles against;
everything under `src/include/` is this package's own.
Being public makes it part of the rename surface — it is installed
under a name carrying the flavor
([`branches/flavors/`](/handbook/branches/flavors/README.md)).

*To deepen: absorb the per-unit responsibility table and the error
rethrow path from the sources; drain
[#540](https://github.com/duckdb/duckdb-r/issues/540),
[#1147](https://github.com/duckdb/duckdb-r/issues/1147).*
