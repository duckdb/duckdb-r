# Scanning a data frame with nanoarrow alone

*What it measures:* what a data frame scan built only on `nanoarrow`
can and cannot do, against the built-in `r_dataframe_scan` —
which queries answer correctly, which R column types survive,
and what the Arrow export costs on a million rows.

*When and on what:* 2026-08-08, duckdb 1.5.5.9012
(this repository, built against the prebuilt libduckdb v1.5.5 via
`DUCKDB_R_USE_SYSTEM_LIB=1`), nanoarrow 0.9.0, R 4.5.3, Linux.

*What it supports:*
[`plan/PLAN-nanoarrow-df-scan.md`](/plan/PLAN-nanoarrow-df-scan.md).

Run [`scan.R`](scan.R); the recorded run is [`scan.md`](scan.md),
rendered with `reprex::reprex(si = TRUE)`.

No C++ was changed to measure this.
`rapi_register_arrow()` takes five R closures —
an exporter, three Arrow expression factories, and a schema exporter —
and nothing in the C++ requires them to come from the `arrow` package,
so substituting nanoarrow for arrow at that seam is a 25-line shim.
What the shim can do is what a nanoarrow-only scan could do.

What the run compresses to:

* **A nanoarrow-only scan works for everything except filters.**
  Full scans, projection pushdown by column name, `count(*)`,
  repeated scans, and self-joins all return the right answer:
  the exporter is called afresh for every scan,
  so a data frame source replays as often as the plan needs it.
* **A filter it ignores is a wrong answer, not a slow one.**
  `arrow_scan` sets `filter_pushdown = true`, and
  `PhysicalTableScan` does not re-apply what it hands to the producer:
  `WHERE a > 3` over five rows returns all five,
  and `EXPLAIN` shows the filter sitting on the scan.
  This is the finding that decides the design —
  a producer that cannot filter must not be bound to `arrow_scan`.
  The engine already carries the alternative:
  `arrow_scan_dumb` registers the same scan function with
  `projection_pushdown`, `filter_pushdown` and `filter_prune` all false
  ([`src/duckdb/src/function/table/arrow.cpp`](/src/duckdb/src/function/table/arrow.cpp)).
* **Two workarounds exist at R level, and neither is good enough.**
  Raising an error from the expression factories fails every filtered
  query rather than only the unrepresentable ones.
  Wrapping the scan in a materialized CTE gets the right answer back,
  but not by suppressing the pushdown:
  the plan shows the filter still pushed into the scan and still
  ignored there, with a second `FILTER` above the CTE scan doing the
  work — the whole source crosses the boundary either way.
* **A one-shot stream is not a table.**
  Registering a `nanoarrow_array_stream` rather than something that
  produces one fails on the first projection —
  the source has no columns to subset and nothing to replay.
* **Type fidelity differs in both directions.**
  nanoarrow is better on `integer64` (`BIGINT`, not `DOUBLE`),
  on `hms` (`TIME`, not `INTERVAL`),
  and on `POSIXct` (`TIMESTAMP WITH TIME ZONE`, not naive `TIMESTAMP`).
  It is worse on `factor` (`VARCHAR`, losing the `ENUM`)
  and it refuses a bare list column outright,
  which `r_dataframe_scan` maps to `INTEGER[]`.
  Everything else — logical, integer, double, character, `Date`,
  `difftime`, `blob`, and a nested data frame — agrees.
* **An R error inside the producer arrives as `std::exception`.**
  The list-column refusal reaches the caller as
  `Invalid Error: std::exception`;
  the nanoarrow message that explains it is lost at the seam.
* **The export costs between one and a half and two times the scan.**
  On a million rows and three columns,
  per-query elapsed time against `r_dataframe_scan`:
  `count(*)` 0.010 s vs 0.006 s,
  `sum(i)` 0.010 s vs 0.006 s,
  `count(DISTINCT s)` 0.077 s vs 0.047 s,
  full fetch 0.083 s vs 0.058 s.
  The cost is paid on every scan, not once at registration,
  because the exporter runs per scan.
