# Plan: `dbSendQueryArrow()` and the DBI Arrow API

Implements the `dbSendQueryArrow()` part of
<https://github.com/duckdb/duckdb-r/issues/1997>.

The DBI Arrow API (`dbSendQueryArrow()`, `dbFetchArrow()`,
`dbFetchArrowChunk()`, `dbBindArrow()`) returns nanoarrow objects. We back it
with DuckDB's existing C-level `ArrowArrayStream` so that results stream
chunk-by-chunk rather than materializing up front.

## Decisions

- New S4 class `duckdb_result_arrow` extending `DBIResultArrow`.
- Fetch returns `nanoarrow_array_stream` / `nanoarrow_array`. `nanoarrow`
  goes into `Suggests`; missing-package error includes an install hint.
- `duckdb_fetch_arrow()` and `duckdb_fetch_record_batch()` stay; new docs
  cross-link them and flag them for future deprecation.
- Streaming is opt-in via a dedicated `streaming` flag on `ConvertOpts`, set
  only by the new `duckdb_result_arrow` paths. The legacy
  `dbSendQuery(arrow = TRUE)` path keeps materializing results, so it remains
  fully backward compatible (results survive interleaved queries on the same
  connection, and the existing single-row-bind restriction is preserved).
- Multi-row binding is supported for the new Arrow API: streams cannot
  coexist on one prepared statement, so multi-row binds materialize one
  result per row and `dbFetchArrow()` concatenates them into a single stream.

## Commits

Each commit is self-contained and keeps the existing test suite green.

### 1. feat(arrow): add an opt-in `streaming` flag and stream when requested

In `src/statement.cpp`, `rapi_execute` calls
`stmt->Execute(stmt->parameters, /*allow_stream_result=*/false)` even when
arrow is enabled, materializing the result up front. Allow streaming, but
gate it behind a new `streaming` flag so only the new Arrow API opts in.

- Add `ConvertOpts::ResultStreaming { DISABLED, ENABLED }` and a `streaming`
  field (`src/include/convert.hpp`), parsed from the `streaming` list element
  (`src/convert.cpp`). Thread it through the R helper `duckdb_convert_opts()` /
  `duckdb_convert_opts_impl()` (`R/convert.R`), defaulting to `FALSE`.
- `rapi_execute`: `allow_stream_result = arrow && streaming`.
- `rapi_bind`: `allow_stream_result = arrow && streaming && n_rows == 1`;
  keep the historical "length one for arrow queries" error for the
  non-streaming (legacy) arrow path.
- Existing arrow tests (`test-fetch_arrow.R`, `test-arrow_stream.R`,
  `test-register_arrow.R`) keep passing unchanged: the legacy path never sets
  `streaming`, so it still materializes. `QueryResultChunkScanState` consumes
  both streaming and materialized results.

### 2. feat(arrow): add `duckdb_result_arrow` class and `dbSendQueryArrow()`

Introduce the new result class and the send-query method with the
non-fetching surface of the result API. No nanoarrow dependency yet — the
result can be inspected and cleared, but not fetched.

- `R/Result.R`: add `setClass("duckdb_result_arrow", contains =
  "DBIResultArrow", ...)`.
- New files:
  - `R/dbSendQueryArrow__duckdb_connection_character.R`
  - `R/dbClearResult__duckdb_result_arrow.R`
  - `R/dbIsValid__duckdb_result_arrow.R`
  - `R/dbColumnInfo__duckdb_result_arrow.R`
  - `R/dbGetStatement__duckdb_result_arrow.R`
  - `R/dbHasCompleted__duckdb_result_arrow.R`
  - `R/show__duckdb_result_arrow.R`
- Tests cover: send-with-no-params returns a `duckdb_result_arrow`,
  `dbIsValid()`/`dbColumnInfo()`/`dbGetStatement()` behave, and
  `dbClearResult()` closes the result.

### 3. feat(arrow): implement `dbFetchArrow()` and `dbFetchArrowChunk()`

Wire up nanoarrow-based fetching against DuckDB's
`ResultArrowArrayStreamWrapper`.

- C++ (`src/statement.cpp`, `src/include/rapi.hpp`):
  - Extend `RQueryResult` with `unique_ptr<ResultArrowArrayStreamWrapper>
    stream_wrapper` for incremental fetch state.
  - `rapi_fetch_arrow_stream_into(qry_res, stream_xptr, chunk_size)`:
    populate a nanoarrow-allocated `ArrowArrayStream` by transferring the
    `QueryResult` into a fresh wrapper and POD-copying the wired-up stream.
    The wrapper deletes itself when nanoarrow's finalizer calls
    `stream.release(stream)`.
  - `rapi_fetch_arrow_array(qry_res, array_xptr, schema_xptr, chunk_size)`:
    lazily create the wrapper, call `get_next` once, and write the
    `ArrowArray` (plus first-time `ArrowSchema`) into nanoarrow-allocated
    structs. Returns whether a chunk was produced.
- Regenerate `src/cpp11.cpp`, `R/cpp11.R`, `R/rethrow-gen.R`.
- `DESCRIPTION`: add `nanoarrow` to `Suggests`.
- New files:
  - `R/dbFetchArrow__duckdb_result_arrow.R` (both methods).
- Tests cover: round-trip via `dbFetchArrow()`, chunked iteration via
  `dbFetchArrowChunk()` until empty (sets `dbHasCompleted()`), error when
  fetching from a cleared result, error when `nanoarrow` is missing, and
  a streaming-proof test that calling `dbSendQueryArrow()` on a `range()`
  query without fetching completes immediately (no materialization).

### 4. feat(arrow): implement `dbBind()`, `dbBindArrow()`, and multi-row binding

- `R/dbBind__duckdb_result_arrow.R`: `dbBind()` rebinds the result, resetting
  completion/schema state. A single bound row keeps the streaming result;
  multiple rows materialize one result per row, stored as
  `query_result` + `pending_query_results` so fetching drains them in order.
- `R/dbBindArrow__duckdb_result_arrow.R`: converts the nanoarrow stream params
  into the list form and delegates to `dbBind()`. Multi-row streams therefore
  run the query once per row.
- `R/dbFetchArrow__duckdb_result_arrow.R`: for a single execution, hands the
  streaming wrapper to nanoarrow directly; for multiple pending results,
  drains every per-row result via `dbFetchArrowChunk()` and emits one unified
  `basic_array_stream`.
- Tests cover: bind a parameterized arrow query and fetch the result,
  `dbBind()` rebind/reset, `dbBindArrow()` with a stream, and a multi-row
  stream running the query once per row.

## Out of scope

- Soft-deprecation of `duckdb_fetch_arrow()` / `duckdb_fetch_record_batch()`
  — only cross-link via `@seealso`.
- The plain `dbFetch()` (data-frame) streaming work mentioned in the same
  issue thread.
