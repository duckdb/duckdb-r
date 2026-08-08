# A Polars frame as a DuckDB table

*What it measures:* what it takes to scan a Polars frame from DuckDB
without either package knowing about the other,
what the type mapping does,
and what filter pushdown into Polars is worth —
in rows crossing the boundary, not only in seconds.

*When and on what:* 2026-08-08, duckdb 1.5.5.9012
(this repository, built against the prebuilt libduckdb v1.5.5 via
`DUCKDB_R_USE_SYSTEM_LIB=1`),
polars 1.14.0.9000 (r-universe, built from source),
nanoarrow 0.9.0, R 4.5.3, Linux.

*What it supports:*
[`plan/PLAN-polars-source.md`](/plan/PLAN-polars-source.md).

Run [`polars.R`](polars.R); the recorded run is [`polars.md`](polars.md),
rendered with `reprex::reprex(si = TRUE)`.

No C++ was changed to measure this.
`rapi_register_arrow()` takes five R closures — an exporter,
three expression factories, and a schema exporter — and nothing in the
C++ requires them to build *Arrow* expressions,
so the filter that DuckDB pushes down can be assembled as a Polars
expression instead.

What the run compresses to:

* **Polars is already reachable, and duckdb needs to know nothing
  about it.**
  polars registers `as_nanoarrow_array_stream()` for its eager and lazy
  frames alike, so a generic nanoarrow-based registration would take a
  Polars frame without naming the package.
  Which matters, because polars is not on CRAN and cannot be a
  `Suggests`.
* **The schema needs a detour.**
  polars does *not* register `infer_nanoarrow_schema()`,
  so the schema has to be taken from a zero-row stream
  (`x$head(0)`) rather than asked for directly.
* **The string type decides whether filters are pushed at all.**
  Polars exports `string_view` by default, and `arrow_scan` disables
  filter pushdown for the whole table when any column has a view type.
  So a Polars frame with a string column silently gets the safe
  behaviour — DuckDB applies the filter itself and the plan shows a
  `FILTER` above the scan — while the same frame without the string
  column has the filter pushed into a producer that may not be able to
  apply it.
  The exporter controls this: `polars_compat_level = "oldest"` turns
  `string_view` into `large_utf8` and pushdown comes back.
  A design that relies on the view type for safety is relying on an
  accident.
* **The filter translates.**
  Mapping DuckDB's expression factories onto Polars is about fifteen
  lines: comparisons, `and_kleene`/`or_kleene`, `is_null`, `invert`,
  `pl$col` for a column reference and `pl$lit` for a scalar.
  Measured working: `>`, a two-sided range, `IN` (which DuckDB expands
  into a balanced tree of equalities), and `IS NOT NULL`.
* **Type fidelity is the nanoarrow mapping, plus list columns.**
  Against `r_dataframe_scan`, a Polars source agrees on logical,
  integer, double, character, `Date`, `difftime`,
  and — unlike the plain nanoarrow route — bare list columns,
  which `as_polars_df()` converts to a Polars list dtype and DuckDB
  reads back as `INTEGER[]`.
  It differs on `factor` (`VARCHAR`, losing the `ENUM`),
  `POSIXct` (`TIMESTAMP WITH TIME ZONE` rather than naive `TIMESTAMP`),
  and `integer64` (`BIGINT` rather than `DOUBLE`).
* **The export is not the bottleneck.**
  Summing a column of a five-million-row frame:
  0.015 s through `r_dataframe_scan`,
  0.017 s through an eager Polars producer,
  0.016 s through a lazy one.
* **What the pushdown changes is the volume, not the clock.**
  Ten numeric columns, two million rows, on disk as an 89 MB Parquet
  file, for a query that needs one column and ten rows:
  with the filter pushed, the producer exports 10 rows × 1 column;
  with one string column added — which is all it takes to disable
  pushdown — it exports 2,000,000 rows × 1 column for the same answer.
  Elapsed time barely moves (0.021 s against 0.023 s, and 0.010 s for
  DuckDB's own `read_parquet`), because Polars is fast enough that
  200,000 times the data is still cheap at this size.
  The pushdown is a correctness requirement first and a volume
  argument second.
