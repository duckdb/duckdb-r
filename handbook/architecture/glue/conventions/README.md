# Conventions

What the glue is made of, and the rules its C++ obeys —
the roster of translation units, the vendored cpp11 that binds them to
R, and the house rules a new one is written to.

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
Install it from
[`krlmlr.r-universe.dev`](https://krlmlr.r-universe.dev),
which builds the fork and serves it as a binary —
name that repository ahead of CRAN and `install.packages("cpp11")`
picks up the fork, beside `decor`, which `cpp_register()` also needs.
`remotes::install_github("krlmlr/cpp11")` does the same from source.
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
fix the root cause instead.
Which warnings the glue is held to, who answers for a warning raised
in vendored code, and where either is checked, is
[`build/warnings/`](/handbook/build/warnings/README.md)'s.
Where a fix is truly not possible —
mbedtls's own `-Wvla` suppression is the standing example —
the pragma is respelled with widened spacing
(`#pragma  GCC  diagnostic  ignored`),
which the compiler honours unchanged
while `R CMD check`'s single-space scan does not report it
([`patch/0016-Avoid-mbedtls-diagnostic-pragmas.patch`](/patch/0016-Avoid-mbedtls-diagnostic-pragmas.patch)).

**Layout is the formatter's, include order is not.**
Formatting runs through the Makefile `format-*` targets,
driving [`scripts/format.py`](/scripts/format.py),
and [`.clang-format`](/.clang-format) alone decides the result —
a bare `clang-format -style=file`, which is what an editor and the
pull-request formatter
([`.github/workflows/style/action.yml`](/.github/workflows/style/action.yml))
run, prints the same tree.
The one thing it will not rewrite is the order of the `#include`s:
`SortIncludes: Never` and `IncludeBlocks: Preserve` pin them,
because in this glue the order compiles or does not.
`rapi.hpp` has to see `cpp11.hpp` before the R headers,
and its `#undef TRUE` / `#undef FALSE` guards only work
where they are written relative to the header that defines them.
So the includes of a translation unit are the author's to order,
and a review argues them the way it argues code.

*To deepen: absorb the per-unit responsibility table and the error
rethrow path from the sources; drain
[#540](https://github.com/duckdb/duckdb-r/issues/540),
[#1147](https://github.com/duckdb/duckdb-r/issues/1147).*
