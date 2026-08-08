# An Arrow source under the relational API

*What it measures:* what the relational API can already do with an Arrow
or nanoarrow source, and how the one available route —
`rel_from_sql()` over a name registered with `duckdb_register_arrow()` —
behaves around binding, lifetime, filter pushdown, and cost.

*When and on what:* 2026-08-08, duckdb 1.5.5.9012
(this repository, built against the prebuilt libduckdb v1.5.5 via
`DUCKDB_R_USE_SYSTEM_LIB=1`), arrow 25.0.0, nanoarrow 0.9.0,
R 4.5.3, Linux.

*What it supports:*
[`plan/PLAN-rel-from-arrow.md`](/plan/PLAN-rel-from-arrow.md).

Run [`rel.R`](rel.R); the recorded run is [`rel.md`](rel.md),
rendered with `reprex::reprex(si = TRUE)`.
The nanoarrow shim it uses is the one from
[`2026-08-08-nanoarrow-df-scan/`](/experiments/2026-08-08-nanoarrow-df-scan/README.md).

What the run compresses to:

* **Neither `rel_from_*()` reaches an Arrow scan.**
  `rel_from_df()` accepts an Arrow table only by way of
  `as.data.frame()`, which materializes it into R vectors first;
  `rel_from_table_function()` cannot express `arrow_scan` at all,
  because its three arguments are `POINTER` values and the R side
  builds scalars — the binder answers
  `arrow_scan(DOUBLE, DOUBLE, DOUBLE)` does not exist.
* **`rel_from_sql()` over a registered name does work.**
  The relation reports its columns, prints, and composes with
  `rel_project()`, `rel_filter()`, and `rel_inner_join()` against a
  data-frame-backed relation.
  So the gap is a constructor, not engine support.
* **A relation built from a name is bound late.**
  A data frame found by the environment scan is frozen at
  relation-creation time — `EnvironmentScanReplacement` marks the table
  reference as an external dependency, so `QueryRelation::Bind()`
  bakes the pointer into a CTE, and rebinding the R variable afterwards
  does not change what the relation returns.
  `ArrowScanReplacement` sets no such dependency:
  unregistering the name and registering different data under it
  swaps the data out from under a relation that already exists,
  and the relation returns the new rows.
  Unregistering without replacing leaves a `Catalog Error` that
  surfaces at first access, not at `rel_to_altrep()` —
  the same way for an Arrow source and for a plain
  `duckdb_register()`ed data frame, which is what shows the freezing
  is the environment scan's doing rather than the data frame's.
* **The filter reaches the producer through the relational API too.**
  `rel_filter()` on an Arrow-backed relation puts `Filters: a>3` on the
  scan and arrow applies it;
  the same relation over the nanoarrow shim returns every row.
  The correctness constraint is the scan's, not the SQL parser's.
* **The data frame detour costs an order of magnitude.**
  On a million rows and three columns,
  `rel_from_df()` on an Arrow table takes 0.026 s against 0.002 s for a
  data frame already in R —
  the difference is the conversion.
  Summing one column through the relational API costs 0.008 s over
  `arrow_scan` and 0.021 s over the nanoarrow shim.
