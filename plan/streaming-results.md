# Streaming result sets for `dbSendQuery()`

## Problem

`dbSendQuery()` (after the deferred-execution PR) materializes the entire
query result into `res@env$resultset` the first time `dbFetch()` is called.
Memory consumption scales with the size of the result set, even when the
caller only wants the first N rows via `dbFetch(n = ...)`.

DuckDB itself supports incremental, chunk-based result iteration via
`StreamQueryResult`. The materialized result type used today
(`MaterializedQueryResult`) is convenient because the conversion code
allocates one big set of R vectors and fills them, but it is not required
by the API surface.

## Goal

Add an opt-in `stream = TRUE` argument to `dbSendQuery()` (and a matching
`dbConnect(stream = ...)` default) that flips the underlying execution to
use `StreamQueryResult` and converts chunks lazily inside `dbFetch()`.

`stream = FALSE` (the default) must keep today's behaviour byte-for-byte
so the change is risk-free for existing callers.

## Non-goals

- Changing the default. The streaming path holds a live cursor on the
  connection; making it the default would change observable semantics
  (snapshotting, single-active-result) and is out of scope here.
- Arrow streaming. The Arrow path (`arrow = TRUE`) already exposes a
  `StreamQueryResult`-like object via `duckdb_fetch_record_batch()`; this
  plan only addresses the data.frame path.
- Re-architecting the conversion code. We reuse the existing chunk
  conversion (`duckdb_r_allocate` / `duckdb_r_transform`) and only change
  who drives the loop.

## Current execute pipeline (one-line tour)

```
R: dbSendQuery -> duckdb_result -> rapi_execute / rapi_bind
C++: PreparedStatement::Execute(allow_stream_result = false)
     -> MaterializedQueryResult (collects all chunks)
     -> duckdb_execute_R_impl
        -> duckdb_r_allocate (sizes R vectors once)
        -> for each DataChunk: duckdb_r_transform (fill vectors)
     -> data.frame back to R
R: store in res@env$resultset; dbFetch slices it
```

The streaming version keeps everything from `duckdb_r_allocate` /
`duckdb_r_transform` and replaces the upstream materialize step with a
chunk pull driven from R.

## Architecture

- C++ holds a `StreamQueryResult` (and the `Connection` lease it needs)
  inside a new `stream_result` `externalptr` with a `cpp11` finalizer.
- R-side `duckdb_result` gains a `stream_result` slot (parallel to the
  existing `query_result` slot used for Arrow). When `stream = TRUE` the
  `resultset` slot stays `NULL` for the lifetime of the result.
- `dbFetch(n)` pulls chunks from C++ until it has `n` rows (or hits EOF
  for `n = -1`). Partial chunks are split in C++ to avoid unnecessary
  copies in R.
- `dbHasCompleted()` reads a new `env$stream_eof` flag set by the C++
  fetch entrypoint when the underlying stream is drained.
- `dbBind()` on a streaming result drops the active stream (if any)
  before storing `pending_params`; the next `dbFetch()` opens a fresh
  stream.
- `dbClearResult()` releases the stream externalptr in addition to the
  statement.

## Risks / open questions

- **Single active stream per connection?** DuckDB allows multiple
  prepared statements, but a live `StreamQueryResult` keeps a chunk
  iterator on the connection. The connection lock model and what happens
  when two streams are open at once needs verification (T1 + T3).
- **Transactions.** A long-lived stream during an open transaction could
  pin MVCC state. Document the caveat; do not try to fix here.
- **`tz_force` path.** Today's code calls `tz_force` in
  `duckdb_post_execute` once on the whole resultset. With streaming it
  has to run per chunk. Small but easy to forget; covered by T4.
- **`dbFetch(EXPLAIN)`** wraps the data.frame in a `duckdb_explain`
  class. EXPLAIN results are tiny — keep the materialized path for
  EXPLAIN even when `stream = TRUE`, to avoid edge cases.

## Tasks

Each task is intended to land as its own PR. Each task leaves the test
suite green and ships its own tests.

### T1. Audit the current execute/conversion pipeline

**Type:** Investigation, no code change.
**Depends on:** nothing.
**Deliverable:** Comments / notes added to this plan (or a sibling file)
covering:

- Exact call path from `rapi_execute` to the returned data.frame.
- Where `duckdb_r_allocate` decides total row count today and what it
  would need to do per chunk.
- Whether the connection lock model allows multiple concurrent
  `StreamQueryResult` instances on one connection.
- Where `tz_force`, factor handling, and ALTREP row-names interact with
  the conversion loop.

**Testability in isolation:** N/A (write-up only).

### T2. Refactor chunk conversion into a reusable helper

**Type:** Pure C++ refactor.
**Depends on:** T1.
**Scope:**

- Split `duckdb_execute_R_impl` into:
  - `convert_query_result_to_df(QueryResult&)` — today's behaviour, used
    by the materialized path.
  - `convert_chunks_to_df(vector<unique_ptr<DataChunk>>&, types, names)`
    — operates on an already-collected set of chunks.
- The first becomes a thin wrapper around the second.

**Testability:** All existing `test-bind`, `test-fetch`, `test-array`,
`test-date`, `test-factor`, `test-integer64`, `test-geometry` tests must
pass unchanged. No new R-visible behaviour.

### T3. Add `stream_result` externalptr type

**Type:** New C++ type, no R API exposure yet.
**Depends on:** T1.
**Scope:**

- New `StreamResultWrapper` holding a `unique_ptr<StreamQueryResult>`
  and any required `Connection` keepalive.
- `cpp11` finalizer that closes the stream.
- Internal-only `rapi_stream_open(stmt, opts)` and
  `rapi_stream_close(stream)` entrypoints. Not registered in the public
  R namespace yet; reachable from tests via `:::`.

**Testability:**
- New `tests/testthat/test-stream-internal.R` that opens and closes a
  stream against a small in-memory query, verifies no leaks (use
  `gc()` + `pryr::mem_used()` or simply that the finalizer fires via a
  counter).

### T4. Add `rapi_stream_fetch(stream, n)` returning a data.frame

**Type:** New C++ entrypoint.
**Depends on:** T2, T3.
**Scope:**

- Pulls chunks until accumulated rows >= `n` or EOF. Splits the
  trailing chunk if necessary so the returned data.frame has exactly
  `min(n, remaining)` rows.
- `n = -1` exhausts the stream.
- Returns a list with two elements: the data.frame and an `eof`
  logical, so the R side can flip `stream_eof` without a second call.
- Uses `convert_chunks_to_df` from T2.
- Applies `tz_force` per chunk.

**Testability:**
- `test-stream-internal.R` extended:
  - Open stream on `mtcars` (32 rows), fetch in chunks of 10, verify
    last fetch returns 2 rows + `eof = TRUE`.
  - Across types: BIGINT, DOUBLE, VARCHAR, DATE, TIMESTAMP, BLOB,
    LIST, STRUCT, NULLs — compare bit-for-bit to a fully-materialized
    `dbGetQuery` of the same query.

### T5. Expose `stream = TRUE` on `dbSendQuery()`

**Type:** R-side wiring.
**Depends on:** T4.
**Scope:**

- New `stream` argument on `dbSendQuery__duckdb_connection_character`,
  default `FALSE`.
- New slot `stream_result` on `duckdb_result` (parallel to
  `query_result`). Slot stays `NULL` for non-streaming results.
- `duckdb_result()`: when `stream && n_param == 0 && is_data_query`,
  defer (same as today) but mark the result as streaming so
  `dbFetch` knows to open a stream.
- `dbFetch__duckdb_result`: when the result is streaming, call
  `rapi_stream_fetch` for the requested `n` and concatenate with any
  previously-fetched-but-not-returned chunk. Do not touch
  `res@env$resultset`.
- `dbClearResult`: release stream if open.

**Testability:**
- All existing tests continue to pass (default unchanged).
- New `test-stream.R`:
  - `dbSendQuery(stream = TRUE)` returns immediately.
  - `dbFetch(rs, n = 10)` returns 10 rows; `dbFetch(rs, n = 10)` again
    returns the next 10; `dbFetch(rs, n = -1)` returns the rest.
  - `dbGetRowCount()` increments per call.
  - Memory: with `bench::mark()` or a simple `gc()` delta, confirm
    that streaming a 1M-row query and discarding chunks uses
    materially less peak memory than the non-streaming path.

### T6. Re-binding on a streaming result

**Type:** R-side, small C++ touch.
**Depends on:** T5.
**Scope:**

- `dbBind__duckdb_result`: if `res@env$stream_result` is set, close it
  (`rapi_stream_close`) before assigning `pending_params`.
- Re-fetch starts a fresh stream on the next `dbFetch()`.

**Testability:**
- `test-stream.R`: parameterized SELECT, bind with `cyl = 6`, partial
  fetch (n = 3); bind with `cyl = 4` (drops old stream); fetch all,
  assert row counts.
- Confirm the closed stream's finalizer fired (counter).

### T7. EOF tracking and `dbHasCompleted()`

**Type:** R-side.
**Depends on:** T5.
**Scope:**

- Add `res@env$stream_eof <- FALSE` at result construction (when
  streaming).
- `rapi_stream_fetch` returns `eof` flag; `dbFetch` sets
  `res@env$stream_eof <- TRUE` when seen.
- `dbHasCompleted__duckdb_result`: for streaming results, return
  `res@env$stream_eof`.
- `dbBind` resets the flag.

**Testability:**
- `test-stream.R`: `dbHasCompleted` is `FALSE` until the last fetch
  drains the stream, then `TRUE`. After re-bind it is `FALSE` again
  until the new stream drains.

### T8. `dbClearResult()` releases the stream

**Type:** R-side.
**Depends on:** T5.
**Scope:**

- `dbClearResult__duckdb_result`: if `stream_result` is non-NULL, call
  `rapi_stream_close` before `rapi_release`.
- Mark `res@env$stream_result <- NULL`.

**Testability:**
- `test-stream.R`: open a stream, `dbClearResult` without fully
  fetching, verify finalizer fired and no warnings on
  `dbDisconnect(con, shutdown = TRUE)`.

### T9. Type-conversion parity sweep

**Type:** Tests only.
**Depends on:** T5–T8.
**Scope:**

- Parameterize a focused subset of existing type tests over
  `stream = c(FALSE, TRUE)` (helper that runs the same body twice).
- Cover: integer / bigint / double / varchar / date / timestamp / tz /
  blob / list / struct / array / factor / NULL handling /
  multi-statement RETURNING.

**Testability:** the tests themselves are the deliverable. They must
all pass against the implementation from T5–T8 with no behaviour
diff between modes.

### T10. Connection-level default

**Type:** R-side.
**Depends on:** T5.
**Scope:**

- `dbConnect(..., stream = FALSE)` argument stored on the connection
  object.
- `dbSendQuery()` falls back to the connection default when the
  argument is missing.
- Mirrors how `arrow` and `bigint` connection options work today.

**Testability:**
- `test-stream.R`: create a connection with `stream = TRUE`, call
  `dbSendQuery()` without `stream`, verify the result is streaming.
- Per-query `stream = FALSE` overrides the connection default.

### T11. Documentation

**Type:** Docs only.
**Depends on:** T5+.
**Scope:**

- Roxygen on `dbSendQuery` and `dbConnect`: describe the streaming mode,
  the single-active-stream caveat, and the snapshot-vs-cursor
  difference vs the default.
- One paragraph in the relevant vignette (`vignettes/duckdb.Rmd`) with a
  short example.
- NEWS entry — note in PR description so `fledge` picks it up
  (NEWS.md itself is auto-generated, see top-of-file comment).

**Testability:** N/A (docs only); roxygen rebuild + R CMD check must
stay clean.

## Suggested merge order

1. T1 (notes) — informational, lands quickly.
2. T2 (refactor) — keeps tests green; sets up the chunk helper.
3. T3 (externalptr type) — hidden, enabled by helper test.
4. T4 (stream fetch entrypoint) — still hidden from the public API.
5. T5 (opt-in `stream = TRUE`) — first user-visible step.
6. T6, T7, T8 — flesh out lifecycle on top of T5; can land in
   parallel as they touch different files.
7. T9 — parity tests once the lifecycle is stable.
8. T10 — connection default.
9. T11 — docs.

## Effort estimate

- T1: half a day.
- T2: half a day.
- T3: half a day.
- T4: one to two days (most of the conversion edge cases live here).
- T5: one day.
- T6, T7, T8: half a day each.
- T9: one day (parametrising and chasing diffs between modes).
- T10: a couple of hours.
- T11: a couple of hours.

Total: roughly one to two weeks of focused work, dominated by
type-conversion parity testing.
