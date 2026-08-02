# The C++ glue

The translation units in `src/` that bridge R and DuckDB —
the cpp11 entry points, the cached R constants in `RStrings`,
the ALTREP relations, and the path an error takes back into R —
together with the conventions that govern C++ source in this package.
The vendored engine underneath is
[`architecture/engine/`](/handbook/architecture/engine/README.md);
the R code on the other side of the seam is
[`architecture/r-layer/`](/handbook/architecture/r-layer/README.md).

## The translation units

`src/` holds two disjoint bodies of code:
the vendored engine under `src/duckdb/`,
and the glue translation units directly in `src/`.
`src/include/glue.mk` is the roster: its `GLUE` variable names them all,
and keeps them apart from the engine's `SOURCES` list —
the split that lets the
[fast build paths](/handbook/build/fast-paths/README.md)
compile the glue alone and link a prebuilt engine.

| Unit | Responsibility |
|---|---|
| `database.cpp` | `rapi_startup()` and `rapi_shutdown()`: build the `DBConfig`, install the replacement scans, register the data-frame scan table function and the `r_string` → `VARCHAR` cast; the `DualWrapper` lock/unlock entry points |
| `connection.cpp` | connect, disconnect, validity; the garbage-collection warning in `ConnDeleter`; the R progress-bar display |
| `statement.cpp` | prepare, bind, execute, release; the Arrow result stream and record-batch entry points |
| `register.cpp` | `rapi_register_df()`, which creates a view over the data-frame scan and pins the `SEXP` as an attribute on the connection so it outlives the call; `rapi_register_arrow()`; and the two replacement scans that resolve an unknown table name to a registered Arrow object or to a binding in the calling R environment |
| `relational.cpp` | the relational API: the `rapi_rel_*` and `rapi_expr_*` entry points, which build `Relation` trees and `ParsedExpression`s without executing them |
| `scan.cpp` | `DataFrameScanFunction`, the table function that reads R vectors as DuckDB vectors |
| `transform.cpp` | the other direction: allocate, decorate, and fill R vectors from DuckDB vectors |
| `types.cpp` | `RType`: detecting the R type of a vector, and mapping it to a `LogicalType` |
| `convert.cpp` | `ConvertOpts`, the per-connection conversion settings parsed out of an R list |
| `utils.cpp` | `RStrings`, `StringsToSexp()`, `RStringsType::Get()`, scalar `Value` ↔ `SEXP` conversion, the `rapi_error_with_context()` overloads, the ADBC init pointer, and `rapi_cxx_stdlib()` |
| `signal.cpp` | `ScopedInterruptHandler`: a SIGINT handler that calls `ClientContext::Interrupt()`, and refuses to nest |
| `reltoaltrep.cpp` | the ALTREP classes and the lazy relation wrapper behind them |
| `altrepdataframe_relation.cpp` | `AltrepDataFrameRelation`, the `Relation` subclass that carries an ALTREP data frame back into a relation tree |
| `rfuns.cpp` | `RfunsExtension`, a static DuckDB extension supplying scalar functions with base R semantics (integer overflow yields `NA`, not an error) |
| `cpp11.cpp` | generated; the `.Call()` shims and `R_init_duckdb()` |

`src/include/rapi.hpp` is the seam's central header,
included directly or indirectly by almost all of them.
It defines the external-pointer wrappers that carry engine objects
through R — `DBWrapper`, `ConnWrapper`, `RStatement`,
`RelationWrapper`, `RQueryResult` — and declares every entry point.
A database handle is a `DualWrapper`,
which holds its target either as a `shared_ptr` (locked, "precious")
or as a `weak_ptr` (unlocked, "disposable");
that is how `duckdb_shutdown()` and instance caching are expressed in C++.
Both the database and the connection wrapper warn from their destructor
when R's garbage collector reclaims a handle
that was never explicitly closed.

`DUCKDB_PACKAGE_NAME`, defined in `rapi.hpp`, is the C++ half of the
flavor seam: the glue calls back into the package namespace by that name,
and `scripts/flavor.patch` rewrites the macro for every non-CRAN flavor
(see [`branches/flavors/`](/handbook/branches/flavors/README.md)).
`DUCKDB_R_POISON_GUARD()`, also in `rapi.hpp`, is the C++ half of the
CRAN test guard — [`testing/guards/`](/handbook/testing/guards/README.md).

## cpp11 and the entry points

cpp11 is **vendored**, not depended on:
`inst/include/cpp11/` carries a copy,
stamped with its version and vendoring date at the top of
`inst/include/cpp11.hpp`, and `DESCRIPTION` has no `LinkingTo:` field.
Upgrading cpp11 means re-vendoring those headers.

An entry point is a free function marked `[[cpp11::register]]`.
`cpp11::cpp_register()` reads the annotations and writes both halves of
the binding: `src/cpp11.cpp` and `R/cpp11.R`,
which between them are the current list of entry points.
Both are generated and are never edited by hand;
the R half belongs to
[`architecture/r-layer/`](/handbook/architecture/r-layer/README.md).
`R_init_duckdb()` in the generated file registers the call entries,
then disables dynamic symbol lookup and forces symbol use,
and finally runs the `[[cpp11::init]]` hook that installs the ALTREP
classes.
Adding, removing, or changing the signature of an entry point therefore
requires regenerating.
`scripts/flavor.sh` also regenerates, because a flavor rename changes
every `.Call()` symbol from `_duckdb_*` to `_duckdb_<flavor>_*`.

## `RStrings`

R string constants and symbols used from C++ live in one place:
`struct RStrings` in `src/include/rapi.hpp`, constructed in
`RStrings::RStrings()` in `src/utils.cpp`.
Always add a new constant or `Rf_install()` symbol there
rather than calling `StringsToSexp()`, `Rf_mkString()`, or
`Rf_install()` inline.

The reason is allocation.
`RStrings::get()` returns a function-local static, built once on first
use; the constructor allocates the character vectors, hands them to
`R_PreserveObject()`, and marks them not mutable, so the members stay
valid for the life of the session and no caller has to protect them.
Symbols need no protection at all — R interns them.
An inline `Rf_mkString()` in a conversion loop, by contrast, allocates
on every row and adds pressure to the very paths that move data.

`RStrings` is not `RStringsType`, despite the names.
`RStringsType::Get()` returns the `r_string` logical type —
a `POINTER` type aliased `r_string` that lets the engine hold `CHARSXP`
pointers without copying them, with a cast to `VARCHAR` registered at
startup for when a real string is finally needed.

## ALTREP relations

`rapi_rel_to_altrep()` turns an unexecuted relation into something R
accepts as a data frame: each column is an ALTREP vector, and the row
names are an ALTREP integer vector, all sharing one
`AltrepRelationWrapper` that holds the relation and, eventually, its
result.
Nothing runs until R asks for data.
The first ALTREP method that needs the values —
a length, a `DATAPTR`, an element — calls `GetQueryResult()`,
which executes the relation once and caches the result.

Materialization is budgeted.
The wrapper carries a row limit and a cell limit;
a budget of zero cells disables materialization entirely, and the error
tells the caller to ask for it explicitly.
When a budget applies, the glue pushes a `LimitRelation` of one row more
than the budget and fails if that extra row comes back — so a runaway
query is stopped rather than silently truncated.
Execution runs under a `ScopedInterruptHandler`, so an interrupt
reaches the engine, and under a temporarily doubled
`max_expression_depth`, because deeply nested relation trees otherwise
hit the engine's limit
([#101](https://github.com/duckdb/duckdb-r/issues/101)).
Two R options observe the moment it happens:
`duckdb.materialize_callback`, called with the relation pointer, and
`duckdb.materialize_message`, a legacy flag that prints a line.
An execution error is not thrown from `Materialize()`;
it is stored on the wrapper and raised at every later access,
so the failure surfaces wherever the data is touched.

The seam runs backwards too.
`rapi_rel_from_altrep_df()` recovers the relation from a data frame that
is still ALTREP, and wraps it in an `AltrepDataFrameRelation` —
a `Relation` subclass that remembers the R data frame it came from, so a
pipeline can pass through R without losing the query behind it.

Raising an R error from inside an ALTREP method is the known weak point.
`rapi_error_with_context()` transfers control into R, which is not safe
from an ALTREP method, and has produced stack overflows; the fix under
discussion is a guard that makes the error helper throw a C++ exception
instead while an ALTREP method is on the stack
([#1796](https://github.com/duckdb/duckdb-r/issues/1796)).
Until that lands, the materialization paths above call it directly.

## Errors across the seam

There are two ways an error crosses from C++ into R, and they meet in
the same place.

Anything that escapes an entry point as a C++ exception is caught by the
`BEGIN_CPP11` / `END_CPP11` frame that `cpp11::cpp_register()` wraps
around every binding, and becomes an R condition.
Anything the glue detects itself calls
`rapi_error_with_context(context, …)` in `src/utils.cpp`, which is
`[[noreturn]]` and takes a message, a `std::exception`, or a DuckDB
`ErrorData`.
It looks up the R function `rapi_error()` in the package namespace and
calls it; the `ErrorData` overload passes the message, the raw message,
the exception type, and the engine's extra-info map along, so the
structured part of an engine error survives the crossing.
Most of the glue calls it, which is why the `context`
argument — the name of the C++ function raising the error — is worth
passing accurately.

What happens next is the R layer's: `rapi_error()` is redirected to an
rlang implementation when rlang is available, and the generated
`rethrow_*()` wrappers in `R/rethrow-gen.R` re-raise the condition with
the user-facing call attached.
See
[`architecture/r-layer/`](/handbook/architecture/r-layer/README.md).

The seam converts only exceptions that unwind through it.
A C++ exception thrown where no glue frame is on the stack reaches
`std::terminate()` and takes the R process with it — the shape of the
crash reported for repeated `CALL start_ui()` on a replaced connection
([#1147](https://github.com/duckdb/duckdb-r/issues/1147)), which no
maintainer has since reproduced.

## Source conventions

**Formatting.**
`scripts/format.py`, driven by the `format-*` targets in the root
`Makefile`, formats `src/` and nothing else, skipping `src/duckdb/`.
C++ sources and headers go through `clang-format` with the repository's
`.clang-format` and `--sort-includes=0`, so the formatter never reorders
an include block; `src/CMakeLists.txt` goes through `cmake-format`.
`make format-check` checks every file, `make format-fix` rewrites them,
and `format-head`, `format-changes`, and `format-main` fix only what
changed against a revision.
The check has known issues and does not gate development:
`cmake-format` ships separately from `clang-format`, and without it the
check does not merely report a difference — it aborts on
`src/CMakeLists.txt` before reaching a verdict.
Where formatting has to be suspended, the suspension is scoped and
carries its reason, as `// clang-format off` does around the
`[[cpp11::init]]` hook in `src/reltoaltrep.cpp`,
where the comment names the upstream issue (`r-lib/decor#6`) that the
exception waits on.

**No warning suppression.**
Do not silence a compiler warning with
`#pragma clang diagnostic ignored` or its equivalents;
CRAN rejects packages that hide warnings instead of fixing them, and no
glue translation unit contains such a pragma today.
Fix the cause.
When the cause is in vendored code, the fix is a patch file in
`patch/`, which the next vendor run reapplies — for instance
`patch/0033-clang-macos.patch`, which replaces the `std_string_view`
alias in the bundled fmt with a struct that only derives from
`std::basic_string_view<Char>` for the standard character types, so
libc++ never instantiates a deprecated `char_traits<T>` and
`-Wdeprecated-declarations` never fires.
Patching mechanics are
[`operations/vendoring/`](/handbook/operations/vendoring/README.md);
the CRAN policy this convention serves is
[`operations/releases/cran/`](/handbook/operations/releases/cran/README.md).

## Limits

`rapi_rel_sql()` is still there, and its future is not settled.
It registers the relation as a view named `_`, runs the caller's SQL
against it, and returns a materialized data frame — not a relation,
whatever its R-side documentation says.
The argument for deleting it was that the useful parts should be
first-class instead
([#540](https://github.com/duckdb/duckdb-r/issues/540));
those parts now exist, as `rel_to_table()`, `rel_to_view()`, and
`rel_from_table()`, but the removal has not been made, and `rel_sql()`
remains internal — `@noRd`, absent from `NAMESPACE`.

The engine's own C++ is out of bounds:
`src/duckdb/` is never edited in place, only patched
([`operations/vendoring/`](/handbook/operations/vendoring/README.md)).
How the glue is compiled and linked belongs to
[`build/source-build/`](/handbook/build/source-build/README.md);
which R type a DuckDB type becomes, and why, belongs to
[`usage/types/`](/handbook/usage/types/README.md).
