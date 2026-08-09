# `experiments/` — measured evidence

*Handbook: [`meta/plans/`](/handbook/meta/plans/README.md)
explains this directory alongside `plan/`.*

One directory per experiment, holding everything it needs:
a `README.md` that says what was measured, when, on what,
and which handbook page relies on it,
plus whatever the run took — scripts, inputs, recorded output.

An experiment is evidence, not a check.
It does not re-run itself, and nothing here gates a build:
what a test can pin is a test
([`testing/suite/`](/handbook/testing/suite/README.md)),
and what a scan can enforce is a check
([`testing/guards/`](/handbook/testing/guards/README.md)).
What lands here is the finding too expensive to re-derive on demand —
a measurement, a survey, a build that takes an hour —
kept so the leaf that cites it can be trusted
without the reader repeating the work.

A record ages rather than rots:
it is true of the day it names,
and a leaf that leans on it says so.
Re-running is how it is refreshed;
the directory keeps the method so that is possible.

* [`2026-03-vendor-build-cost/`](2026-03-vendor-build-cost/) —
  churn per vendor commit, ccache hit rate on adjacent commits,
  archive size; supports
  [`operations/ci/per-commit/planning/`](/handbook/operations/ci/per-commit/planning/README.md).
* [`2026-07-main-dev-review/`](2026-07-main-dev-review/) —
  how much of a series' active range is R-side work rather than
  vendoring, and what kind; supports
  [`branches/invariants/`](/handbook/branches/invariants/README.md).
* [`2026-08-02-lts-drift/`](2026-08-02-lts-drift/) —
  how far the v1.4 LTS flavor has drifted from its baseline; supports
  [`branches/invariants/`](/handbook/branches/invariants/README.md).
* [`2026-08-05-windows-extension-coverage/`](2026-08-05-windows-extension-coverage/) —
  which prebuilt extensions DuckDB's repositories serve R's Windows
  builds, and whether the MSVC arm64 artifact can be hand-loaded;
  supports [`usage/extensions/`](/handbook/usage/extensions/README.md).
* [`2026-08-08-altrep-scan-threads/`](2026-08-08-altrep-scan-threads/) —
  what a scan returned when it reached a registered ALTREP data frame's
  packed column itself, per thread count and field type, before and
  after bind started walking into one; supports
  [`architecture/glue/threading/`](/handbook/architecture/glue/threading/README.md).
* [`2026-08-08-interrupt-reach/`](2026-08-08-interrupt-reach/) —
  which running DuckDB work a Ctrl+C stops in R and in the DuckDB CLI,
  and what each host does when it stops nothing; supports
  [`usage/interactive/`](/handbook/usage/interactive/README.md).
* [`2026-08-08-timezone-grid/`](2026-08-08-timezone-grid/) —
  which zone labels a `TIMESTAMP` and a `TIMESTAMPTZ` column,
  and when an instant changes, across every setting combination;
  supports [`usage/timestamps/`](/handbook/usage/timestamps/README.md).
* [`2026-08-09-distinct-on-cost/`](2026-08-09-distinct-on-cost/) —
  what `DISTINCT ON` would cost against the `ROW_NUMBER()` plan dbplyr
  emits for `distinct(.keep_all = TRUE)`, across cardinality, width,
  `LIMIT` and thread count; supports
  [`usage/integrations/`](/handbook/usage/integrations/README.md).
* [`2026-08-09-distinct-on-override/`](2026-08-09-distinct-on-override/) —
  whether a caller can register `DISTINCT ON` as their own `distinct()`
  method, how far into dbplyr that reaches, and what `window_order()`
  already states without it; supports
  [`usage/integrations/`](/handbook/usage/integrations/README.md).
* [`2026-08-09-dbplyr-version-warning/`](2026-08-09-dbplyr-version-warning/) —
  which API reports the version of the dbplyr a session has loaded
  rather than the one in the library, when a `packageEvent()` hook
  fires, and what a warning raised from one can do to the load it
  interrupts; supports
  [`usage/integrations/`](/handbook/usage/integrations/README.md).
* [`2026-08-09-series-carry-scope/`](2026-08-09-series-carry-scope/) —
  how many of a buffer's vendor commits have a fix waiting on the base
  series' `-dev`, what kind, and how much of the raw difference is not a
  fix at all; supports
  [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md).
* [`2026-08-temp-storage-spill/`](2026-08-temp-storage-spill/) —
  whether larger-than-memory work actually spills, per connection
  idiom, on duckdb 1.3.2, the current CRAN release, `main`, and the
  fix in [#2562](https://github.com/duckdb/duckdb-r/pull/2562);
  supports [`usage/memory/`](/handbook/usage/memory/README.md).
* [`2026-08-streaming-tpch-bench/`](2026-08-streaming-tpch-bench/) —
  wall time and memory of moving a TPC-H result into R, per fetch
  strategy, on the CRAN build and
  [#2292](https://github.com/duckdb/duckdb-r/pull/2292)'s streaming
  build; gathered for
  [`plan/PLAN-streaming-thread.md`](/plan/PLAN-streaming-thread.md).

Adding one: create the directory, name it for the date and the topic,
open its `README.md` with what and when and on what,
and link it from the leaf that relies on it.
