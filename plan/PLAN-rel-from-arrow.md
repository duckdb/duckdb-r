# Plan: `rel_from_arrow()`, a relational scan of an Arrow source

**Open.** The relational API as it stands today is
[`usage/relational/`](/handbook/usage/relational/README.md)'s,
and the Arrow surface is
[`usage/integrations/`](/handbook/usage/integrations/README.md)'s;
this file is a proposal, and where it and a leaf disagree,
the leaf is right.

A step towards
[#98](https://github.com/duckdb/duckdb-r/issues/98).
The issue is about registration, but registration is only half the
surface: duckplyr drives relations, not SQL, and an Arrow source that
can only be reached by name through `rel_from_sql()` is reachable by
accident rather than by design.

Measured evidence:
[`experiments/2026-08-08-rel-from-arrow/`](/experiments/2026-08-08-rel-from-arrow/README.md).

## What the measurement settled

* Neither existing constructor reaches an Arrow scan.
  `rel_from_df()` takes an Arrow table only through `as.data.frame()`,
  which materializes it — an order of magnitude slower than starting
  from a data frame already in R.
  `rel_from_table_function()` cannot express `arrow_scan`,
  because its three arguments are `POINTER` values and the R side
  builds scalars.
* `rel_from_sql()` over a registered name does work,
  and the verbs compose over the resulting relation —
  project, filter, and a join against a data-frame-backed relation.
  So what is missing is a constructor, not engine support.
* That route binds late.
  `ArrowScanReplacement()` attaches no external dependency,
  so the name is resolved again at materialization:
  re-registering different data under the same name changes what an
  existing relation returns,
  and unregistering it leaves a `Catalog Error` that surfaces at first
  access rather than at `rel_to_altrep()`.
  A data frame found by the environment scan does not behave this way —
  `EnvironmentScanReplacement()` marks the reference as an external
  dependency, and `QueryRelation::Bind()` freezes the pointer into a
  CTE.
* Filter pushdown reaches the producer through the relational API
  exactly as it does through SQL,
  so a producer that cannot filter is as wrong under `rel_filter()`
  as under `WHERE`.

## Decisions

* **Bind by pointer, not by name.**
  `rel_from_arrow()` builds the table function reference directly from
  the stream factory pointer, the way `rel_from_df()` builds
  `r_dataframe_scan` from the data frame pointer.
  A relation then no longer depends on a catalog entry:
  it survives unregistration, and it cannot have its data swapped
  underneath it.
  This is the difference that makes it worth adding rather than
  documenting `rel_from_sql()` as the answer.
* **The relation owns the factory.**
  The factory external pointer and the source object go into the
  relation's protection list, so `rel_to_altrep()` can materialize
  long after the R-level handle is gone.
  `make_external_prot<RelationWrapper>()` already takes that list.
* **Registration is not required.**
  `rel_from_arrow(con, x)` takes the source directly.
  A name in the catalog is a separate concern
  (`PLAN-nanoarrow-df-scan.md`, proposed alongside this one under
  [#98](https://github.com/duckdb/duckdb-r/issues/98)),
  and the two should not be entangled:
  duckplyr wants a relation, not a view.
* **One constructor, two producers.**
  `rel_from_arrow()` builds an arrow-package producer with pushdown
  when handed something the `arrow` package owns,
  and a nanoarrow producer without pushdown otherwise —
  the same capability flag that decides
  `arrow_scan` against `arrow_scan_dumb`.
  A caller that wants to force the pushdown-free route passes
  `pushdown = FALSE`.
* **Unexported, like the rest.**
  Every function in `R/relational.R` is `@noRd`
  and reached through `:::` by duckplyr;
  a new one follows that, and the addition is negotiated with duckplyr
  rather than merely reviewed.

## Commits

Each commit is self-contained and keeps the suite green.

### 1. refactor(arrow): make the stream factory constructible outside registration

`RArrowTabularStreamFactory` is defined inside `src/register.cpp` and
built only by `rapi_register_arrow()`.
Move the class to a header (`src/include/arrow_factory.hpp`) and give
`src/register.cpp` a small function that builds one and returns the
protecting list, so registration and the relational constructor share
one implementation.

Pure refactor, no behaviour change; the existing arrow tests cover it.

### 2. feat(relational): `rel_from_arrow()`

* `src/relational.cpp`: `rapi_rel_from_arrow(con, funs, x, pushdown)`
  builds the factory, then
  `con->conn->TableFunction(pushdown ? "arrow_scan" : "arrow_scan_dumb", {…})`
  with the three `Value::POINTER` arguments,
  and wraps the resulting relation with the factory external pointer
  and the source in its protection list.
* Regenerate `src/cpp11.cpp`, `R/cpp11.R`, `R/rethrow-gen.R`.
* `R/relational.R`: `rel_from_arrow(con, x, ..., pushdown = NULL)`,
  choosing the arrow-package closures when
  `inherits(x, c("Table", "RecordBatch", "RecordBatchReader", "Dataset", "Scanner", "arrow_dplyr_query"))`
  and the nanoarrow closures otherwise,
  with `pushdown` overriding the choice.
  `@noRd`, documented in the file the way its neighbours are.
* Tests (`tests/testthat/test-relational.R`, or a sibling file):
  a relation over an arrow table and over a nanoarrow-able object;
  `rel_names()`, `rel_project()`, `rel_filter()`, `rel_order()`,
  a join against `rel_from_df()`;
  `rel_to_altrep()` materializing correctly;
  and the two lifetime cases the experiment measured —
  materialization succeeds after `duckdb_unregister_arrow()` of an
  unrelated same-named entry, and re-registering that name does not
  change the relation's rows.

### 3. feat(relational): route filters honestly for a pushdown-free source

With `pushdown = FALSE` the scan is `arrow_scan_dumb`,
so `rel_filter()` is applied by the engine.
Add the test that pins it: the same filter over the same data returns
the same rows through both producers.

### 4. docs: state the constructor and its binding

`handbook/usage/relational/README.md` gains `rel_from_arrow()` beside
`rel_from_df()`, and states the binding difference —
a relation from a pointer outlives the catalog,
a relation from `rel_from_sql()` over a registered name does not.
`handbook/usage/integrations/README.md` cross-links it from the Arrow
section.

## Out of scope

* **Exporting the relational API.**
  It stays internal; this adds one more `@noRd` function to it.
* **Fixing the late binding of `rel_from_sql()` over a registered
  Arrow name.**
  Attaching an `ExternalDependency` in `ArrowScanReplacement()` the way
  `EnvironmentScanReplacement()` does would change the behaviour of an
  existing route, and the experiment does not say whether anything
  depends on the current one.
  Worth its own issue.
* **Filter pushdown into a source that has an engine.**
  The Polars plan proposed alongside this one under
  [#98](https://github.com/duckdb/duckdb-r/issues/98).
* **A registration entry point for nanoarrow sources.**
  `PLAN-nanoarrow-df-scan.md`, proposed alongside this one under
  [#98](https://github.com/duckdb/duckdb-r/issues/98).

## Open questions

* Whether `rel_from_df()` should recognise an Arrow-shaped argument and
  delegate, instead of quietly taking the `as.data.frame()` route.
  It would be a behaviour change for a `:::` caller,
  which is duckplyr's call to make.
* Whether the `pushdown` argument should exist at all,
  or whether the producer should be asked
  (a `supports_pushdown` attribute on the closure list) so the choice
  travels with the source rather than the call.
