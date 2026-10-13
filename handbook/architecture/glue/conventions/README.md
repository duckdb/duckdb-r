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
`src/vendor/cpp11/` carries the copy,
taken from [`krlmlr/cpp11`](https://github.com/krlmlr/cpp11),
a patch stack on top of
[`r-lib/cpp11`](https://github.com/r-lib/cpp11):
this package needs extensions upstream does not ship.
Refreshing that copy is
[`.claude/skills/vendor-cpp11/`](/.claude/skills/vendor-cpp11/SKILL.md)'s.
An entry point is a function marked `[[cpp11::register]]`;
`cpp11::cpp_register()` writes both halves of the binding
(`src/cpp11.cpp`, `R/cpp11.R`),
which are generated and never edited.

**The generator is the fork too, and it is not vendored.**
`cpp_register()` does not come from `src/vendor/cpp11/` —
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

**An error is reported without calling R.**
Wherever the engine may be underneath,
the glue reports an error through `rapi_error_with_context()` ([`src/utils.cpp`](/src/utils.cpp)),
and it never raises the R condition itself.
Raised from C++, the condition's R code would run wherever the glue happens to be:
underneath the engine, while task threads may still read R objects
and with a catch that keeps nothing of cpp11's unwind but `std::exception`,
or inside an ALTREP method, where R may evaluate nothing.
Instead it leaves the error in `the$rapi_error_pending`, with its context, message, and the engine's type, raw message and extra info,
and throws it as an engine exception.
Underneath the engine that exception is an ordinary query error, carried back to the entry point.
An entry point that reports it again leaves its own report pending in its place,
and one that lets it through leaves the original.
At the entry point cpp11 turns it into a plain R error,
and the `rethrow_rapi_*()` wrapper ([`R/rethrow.R`](/R/rethrow.R)) raises the pending error from R, class and fields included.
It takes the pending error only if that is the error being raised, compared on the exception's text:
one the engine caught and never passed on is stale, not the next error's.
Without rlang the wrappers are rebuilt on `tryCatch()` and do the same, in `rapi_error_base()`'s format.
An ALTREP method keeps a plain error, since no wrapper surrounds it ([`altrep/`](/handbook/architecture/glue/altrep/README.md)).
Off R's thread nothing is left pending, since nothing may touch R there ([`threading/`](/handbook/architecture/glue/threading/README.md)):
the engine carries the exception back, and the entry point's report is the one R raises.

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
([cynkratemplate's `style/`](https://github.com/cynkra/cynkratemplate/blob/main/.github/actions/style/action.yml))
run, prints the same tree.
The one thing it will not rewrite is the order of the `#include`s:
`SortIncludes: Never` and `IncludeBlocks: Preserve` pin them,
because in this glue the order compiles or does not.
`rapi.hpp` has to see `cpp11.hpp` before the R headers,
and its `#undef TRUE` / `#undef FALSE` guards only work
where they are written relative to the header that defines them.
So the includes of a translation unit are the author's to order,
and a review argues them the way it argues code.

*To deepen: absorb the per-unit responsibility table from the sources; drain
[#540](https://github.com/duckdb/duckdb-r/issues/540).*
