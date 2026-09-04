# Plan: a Polars frame as a SQL table or a relation

**Open.** The frame-library situation as it stands today is
[`usage/integrations/`](/handbook/usage/integrations/README.md)'s;
this file is a proposal, and where the two disagree the leaf is right.

The third step towards
[#98](https://github.com/duckdb/duckdb-r/issues/98),
and the one the issue actually names:
its author asked for one registration function because they wanted to
register "a nanoarrow array or polars DataFrame".
[#642](https://github.com/duckdb/duckdb-r/issues/642) asks the same
from the other side.

Measured evidence:
[`experiments/2026-08-08-polars-source/`](/experiments/2026-08-08-polars-source/README.md).

## The constraint that shapes everything

polars is not on CRAN.
It cannot go in `Suggests`, its tests cannot run on the check farm,
and a `polars::` call cannot appear in this package's R sources.
So the design cannot be "add a Polars method";
it has to be "make registration extensible enough that Polars needs no
method".

That is a stronger requirement than #98 asks for,
and it is also the one that makes #98 worth doing:
a generic with one method is a rename,
a generic that a package outside CRAN can satisfy is an interface.

## What the measurement settled

* Polars is already reachable through nanoarrow.
  polars registers `as_nanoarrow_array_stream()` for eager and lazy
  frames, so a nanoarrow-based registration takes a Polars frame today
  without naming the package —
  measured working for scans, projections, and `count(*)`.
* It does not register `infer_nanoarrow_schema()`,
  so the schema has to come from a zero-row stream rather than from the
  object.
  A generic registration must not assume the schema is askable.
* The filter DuckDB pushes down translates to Polars in about fifteen
  lines, because the three expression factories the C++ calls are
  ordinary R closures that need not build Arrow expressions.
  Comparisons, conjunctions, `IN`, and null tests all measured working
  against a `LazyFrame`.
* Whether DuckDB pushes a filter at all depends on the Arrow *layout*
  the source exports.
  Polars exports `string_view` by default, and `arrow_scan` disables
  filter pushdown for the whole table when any column has a view type.
  A Polars frame with a string column is therefore safe by accident,
  and the same frame without one is not.
* Pushing the filter changed the volume by five orders of magnitude
  (10 rows exported against 2,000,000 for the same answer)
  and the elapsed time barely at all.
  The pushdown earns its place as correctness, not as a speed-up.

## Decisions

* **No Polars-specific code in this package.**
  Not a method, not a class name, not a `requireNamespace("polars")`.
  Everything Polars needs is the generic interface below;
  what stays here is a test that exercises it with a stub rather than
  with polars.
* **`duckdb_register()` becomes an S3 generic** — #98's request.
  `duckdb_register.data.frame()` keeps today's `r_dataframe_scan`
  behaviour byte for byte;
  `duckdb_register.default()` registers anything
  `nanoarrow::as_nanoarrow_array_stream()` accepts,
  through the pushdown-free route.
  A Polars frame lands in `default` and works with no further code.
* **A source opts into pushdown by supplying a producer.**
  A second generic, `duckdb_arrow_producer(x)`, returns the closure
  list plus a capability flag;
  the default method builds the nanoarrow producer,
  and a package that has a query engine — polars, and in principle
  arrow — implements it to get the filter.
  The implementing package registers it from its own `.onLoad()`,
  the same delayed-registration trick this package uses in the other
  direction for dbplyr and adbcdrivermanager
  ([`R/s3_register.R`](/R/s3_register.R), [`R/zzz.R`](/R/zzz.R)),
  so no dependency is created either way.
* **The schema comes from a zero-row stream by default.**
  `infer_nanoarrow_schema()` is tried first and the empty-slice route
  is the fallback, because the measurement says a real source does not
  necessarily have a method.
* **Pushdown capability is declared, never inferred.**
  Not from the Arrow layout — the `string_view` accident is exactly
  what a design must not depend on —
  and not from the class.
  The producer says so, and the C++ binds `arrow_scan` or
  `arrow_scan_dumb` accordingly.
* **The relational side comes along for free.**
  `rel_from_arrow()` takes the same producer, so a Polars frame is a
  relation as well as a view, and duckplyr can build on one.

## Commits

Each commit is self-contained and keeps the suite green.
The first two are the prerequisites, planned separately under #98;
this plan assumes them rather than restating them.

### 1. feat(register): `duckdb_arrow_producer()`, the extension point

* `R/register.R`: an S3 generic `duckdb_arrow_producer(x, ...)`
  returning `list(export = , schema = , expr = , col = , lit = ,
  pushdown = )`.
  The default method builds the nanoarrow producer with
  `pushdown = FALSE`;
  a `data.frame` method is *not* added, so the data frame path stays on
  `r_dataframe_scan`.
* Exported and documented, because a package outside CRAN has to be
  able to implement it.
* Tests: a stub producer in `tests/testthat/helper-producer.R` that
  records what it is asked for, asserting that the filter and
  projection arrive as expected and that `pushdown = TRUE` reaches
  `arrow_scan` while `FALSE` reaches `arrow_scan_dumb`.

### 2. feat(register): make `duckdb_register()` an S3 generic

* `duckdb_register()` becomes `UseMethod("duckdb_register", df)`.
  `duckdb_register.data.frame()` is today's body, unchanged.
  `duckdb_register.default()` resolves a producer through
  `duckdb_arrow_producer()` and registers it.
  `duckdb_unregister()` drops either kind.
* The argument is still named `df`, since renaming it would break
  callers who name it.
  The documentation says what it now accepts.
* Tests: `duckdb_register()` on a nanoarrow array, on an `arrow` table,
  and on the stub producer; the data frame path unchanged;
  `duckdb_unregister()` for both.

### 3. docs: state the extension point and what implements it

`handbook/usage/integrations/README.md` gains the inbound direction for
frame libraries: any package that can produce an Arrow C stream is a
source, with pushdown if it implements `duckdb_arrow_producer()`.
The data.table and collapse paragraph gets its counterpart —
those libraries operate on data frames and need nothing;
Polars is the case that needed an interface.

### 4. A worked producer, outside this repository

The Polars-side method belongs in polars, or in a small bridge package.
This plan's obligation is to make it writable in about forty lines;
the experiment's `register_polars_lazy()` is what it looks like.
Filing it as an issue on the polars side, with a link to the
experiment, is the last step here.

## Out of scope

* **Adding polars to `Suggests` or to CI.**
  It is not on CRAN, and building it from source takes tens of minutes.
  The stub producer is what the suite tests.
* **A Polars *writer*.**
  Results already leave as a nanoarrow stream that
  `polars::as_polars_df()` consumes
  ([`usage/integrations/`](/handbook/usage/integrations/README.md)),
  and [#642](https://github.com/duckdb/duckdb-r/issues/642) is
  answered on that side already.
* **Translating everything DuckDB can push.**
  The measured translation covers comparisons, conjunctions, `IN`, and
  null tests.
  A producer may raise `NotImplemented` for the rest, and DuckDB's
  `OPTIONAL_FILTER` handling already degrades to a `TRUE` literal
  rather than failing the query.
* **The two prerequisite plans.**
  The nanoarrow scan and `rel_from_arrow()`, both proposed alongside
  this one under
  [#98](https://github.com/duckdb/duckdb-r/issues/98).

## Open questions

* Whether `duckdb_arrow_producer()` should be one generic returning a
  list, or several small generics
  (`duckdb_arrow_export()`, `duckdb_arrow_schema()`, …).
  The list is one dispatch and one thing to document;
  separate generics are easier to implement partially.
* Whether the `string_view` interaction deserves a report upstream.
  A source whose only string column is a view silently loses filter
  pushdown for every other column too,
  which is a performance cliff nothing announces.
* Whether `duckdb_register()` should refuse a source it cannot replay,
  or accept it and fail on the second scan with an explanation.
  Same question as the nanoarrow plan's, and it should be answered the
  same way in both.
