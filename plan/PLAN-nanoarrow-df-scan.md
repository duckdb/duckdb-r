# Plan: scanning a data frame with nanoarrow alone

**Open.** The Arrow surface as it stands today is
[`usage/integrations/`](/handbook/usage/integrations/README.md)'s,
and the C++ that implements it is
[`architecture/glue/`](/handbook/architecture/glue/README.md)'s;
this file is a proposal, and where it and a leaf disagree,
the leaf is right.

A step towards
[#98](https://github.com/duckdb/duckdb-r/issues/98):
the issue asks for one generic registration function,
and the answer in the thread was that a new `duckdb_register_*()`
is fine if the C++ has to change anyway.
What the C++ needs is the piece this plan adds —
a scan that takes any Arrow C stream producer,
rather than one that can only talk to the `arrow` package.

Measured evidence:
[`experiments/2026-08-08-nanoarrow-df-scan/`](/experiments/2026-08-08-nanoarrow-df-scan/README.md).

## Why nanoarrow

`duckdb_register_arrow()` is the only route in for a source that is not
an R data frame, and it hard-codes the `arrow` package:
the closures it hands to C++ call `arrow::Scanner$create()` and
`arrow::Expression$…`.
That makes a heavyweight dependency the price of admission for every
Arrow-shaped source — including nanoarrow objects,
which are already what this package *returns* from
`dbGetQueryArrow()` and `dbFetchArrow()`.

nanoarrow is the small end of the same interface,
and it is already in `Suggests`.
Registering *into* DuckDB through it closes the loop
without adding a dependency.

## What the measurement settled

* A nanoarrow-only producer answers full scans, projections,
  `count(*)`, repeated scans, and self-joins correctly today,
  through nothing but the five R closures the existing seam takes.
* It cannot answer a filtered query.
  `arrow_scan` declares `filter_pushdown = true`, and
  `PhysicalTableScan` does not re-apply what it pushes:
  a producer that ignores the filter returns every row and the plan
  still reads `Filters: a>3`.
* The engine already carries the right function for a producer that
  cannot filter: `arrow_scan_dumb`, registered alongside `arrow_scan`
  with `projection_pushdown`, `filter_pushdown` and `filter_prune`
  all false.
* Type fidelity differs in both directions —
  better for `integer64`, `hms`, and `POSIXct`,
  worse for `factor`, and a bare list column is refused outright.
* The Arrow export costs about twice the built-in scan per query,
  and it is paid per scan rather than once at registration.

So nanoarrow is a *new source*, not a replacement for
`r_dataframe_scan`, and the design must let a producer say what it
can do rather than assume it can filter.

## Decisions

* **Capability, not package.**
  The C++ side learns a producer capability —
  whether the producer can apply projection and filters —
  and binds to `arrow_scan` when it can and `arrow_scan_dumb` when it
  cannot.
  Nothing in the engine has to change;
  both functions are already registered.
* **One new registration entry point, shared unregistration.**
  `rapi_register_arrow_stream()` joins `rapi_register_arrow()`,
  storing into the same `DBWrapper::arrow_scans` map,
  so `duckdb_unregister_arrow()` and `duckdb_list_arrow()` keep working
  for both.
  The existing `rapi_register_arrow()` stays byte-for-byte as it is:
  the arrow path is the one with pushdown, and it should not change
  shape while a second path is being introduced.
* **R surface: `duckdb_register_nanoarrow()`.**
  Takes anything `nanoarrow::as_nanoarrow_array_stream()` accepts —
  a data frame, a nanoarrow array or stream-producing object,
  an `arrow` table, a Polars frame.
  A separate name rather than an argument to `duckdb_register()`,
  because the semantics differ:
  no pushdown, a per-scan export, and a different type mapping.
* **`duckdb_register()` keeps `r_dataframe_scan`.**
  The measurement says the nanoarrow route is about twice as slow,
  drops `ENUM` for factors, and refuses list columns.
  Changing the default would be a regression for the common case;
  the generic in #98 is about reaching more sources, not fewer.
* **A source consumed on read is refused at registration.**
  A bare `nanoarrow_array_stream` cannot back a view —
  it has nothing to replay for the second scan.
  Detect it and say so, rather than failing on the first projection
  with a message about subsetting.
* **R errors keep their message.**
  An R condition raised inside a producer currently reaches the caller
  as `Invalid Error: std::exception`.
  The producer calls get a wrapper that catches the R error and
  re-raises it with its own message and the producer's name.

## Commits

Each commit is self-contained and keeps the suite green.

### 1. fix(arrow): carry the R producer's error message across the seam

`RArrowTabularStreamFactory::Produce()` and `GetSchema()` call R
closures directly, so an R error unwinds through C++ and arrives as
`std::exception`.
Route both through a helper that evaluates the call with
`R_tryCatchError()` and converts a caught condition into a
`duckdb::InvalidInputException` carrying the R message.

Standalone: it improves the existing arrow path on its own,
and every later commit depends on the diagnostics.
Test: register an arrow source whose exporter stops with a known
message, and assert the message survives.

### 2. feat(arrow): bind pushdown-incapable producers to `arrow_scan_dumb`

Give `RArrowTabularStreamFactory` a `bool supports_pushdown` and store it
in the registration state list.
`ArrowScanReplacement()` reads it and emits
`FunctionExpression("arrow_scan_dumb", …)` when it is false,
in which case `Produce()` is never called with a projection or a filter.

No R-visible change yet — `rapi_register_arrow()` sets the flag true —
but the two-function split is in place and testable through the
existing arrow path by flipping the flag in a test-only registration.

### 3. feat(nanoarrow): `duckdb_register_nanoarrow()`

The R surface and the C++ entry point behind it.

* `src/register.cpp`: `rapi_register_arrow_stream(conn, name, funs, x)`,
  storing `supports_pushdown = false`.
  It takes two closures rather than five — an exporter and a schema
  exporter — since the expression factories are unreachable without
  pushdown.
* Regenerate `src/cpp11.cpp`, `R/cpp11.R`, `R/rethrow-gen.R`.
* `R/register.R`: `duckdb_register_nanoarrow(conn, name, x)`,
  building the two closures over
  `nanoarrow::as_nanoarrow_array_stream()` and
  `nanoarrow::infer_nanoarrow_schema()`,
  and `nanoarrow::nanoarrow_pointer_export()` to fill the address the
  C++ side passes in.
  Guarded by the existing `require_nanoarrow()` helper.
* Refuse a source that is itself a stream:
  `inherits(x, "nanoarrow_array_stream")` is an error naming the
  problem.
* `_pkgdown.yml` and the `duckdb_register_arrow` reference page gain
  the new function; `NEWS.md` gains a bullet.
* Tests (`tests/testthat/test-register_nanoarrow.R`):
  full scan, projection, `count(*)`, repeated scan, self-join,
  a filtered query returning the right rows through `arrow_scan_dumb`,
  registration of a nanoarrow array and of an `arrow` table,
  the stream refusal, unregistration through
  `duckdb_unregister_arrow()`, and the type grid from the experiment
  pinned as expectations.

### 4. docs: state the second Arrow route

`handbook/usage/integrations/README.md` gains the nanoarrow-in
direction beside the existing arrow-in and stream-out ones, with the
pushdown difference stated as the reason there are two.
`handbook/architecture/glue/README.md` gains the capability flag and
the `arrow_scan` / `arrow_scan_dumb` split.

## Out of scope

* **Making `duckdb_register()` generic.**
  That is #98's actual request and it should follow this,
  once there is more than one non-data-frame source to dispatch to
  ([`PLAN-polars-source.md`](PLAN-polars-source.md) is the second).
  Dispatching to a single method is not a generic, it is a rename.
* **Filter pushdown for nanoarrow sources.**
  nanoarrow has no compute layer, so there is nothing to push *to*.
  A source that carries its own query engine is a different case
  and is [`PLAN-polars-source.md`](PLAN-polars-source.md)'s.
* **Replacing `r_dataframe_scan`.**
  Measured as slower and lossier for the default path.
  Worth revisiting only if the type mapping is fixed upstream and the
  export cost falls.
* **The relational constructor.**
  [`PLAN-rel-from-arrow.md`](PLAN-rel-from-arrow.md).

## Open questions

* Whether `duckdb_register_nanoarrow()` should accept a
  `nanoarrow_array_stream` after all,
  by wrapping it in a one-shot producer that errors on the second scan
  with a message that explains why.
  A single-scan query would then work,
  and the failure would be legible rather than incidental.
* Whether the type differences that favour nanoarrow —
  `BIGINT` for `integer64`, `TIME` for `hms`,
  `TIMESTAMP WITH TIME ZONE` for `POSIXct` —
  are bugs in `r_dataframe_scan` worth filing separately.
