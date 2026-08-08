# Plan: a producer thread for streaming results

**Open.**
Builds on the streaming-results work in
[#2292](https://github.com/duckdb/duckdb-r/pull/2292)
(`dbSendQuery(stream = TRUE)`, designed in that branch's
`plan/streaming-results.md`);
this file proposes what comes after it lands.
The memory facts as they stand today are owned by
[`usage/memory/`](/handbook/usage/memory/README.md),
the glue conventions by
[`architecture/glue/`](/handbook/architecture/glue/README.md);
where this plan and a leaf disagree, the leaf is right.

## Problem

With #2292, `dbFetch(n = )` on a streaming result pulls chunks on demand
and converts them to R vectors as they arrive.
That bounds memory ([#1997](https://github.com/duckdb/duckdb-r/issues/1997)),
but it serializes two kinds of work on the one R thread:

* the engine produces the next chunks
  (inside `StreamQueryResult::Fetch()`, which executes pipeline tasks),
* the glue converts fetched chunks to R vectors
  (`duckdb_r_transform()`, one `Rf_mkCharLenCE()` per string cell).

The engine's own worker threads do not help between fetch calls:
once the streaming buffer is full, every producing task is parked
(details below), so while R converts, the engine idles,
and while the engine produces, R waits.
For string-heavy results the conversion half dominates,
and the wall clock pays for both halves in sequence.

The goal is to overlap the two halves:
the engine keeps producing on threads that are not the R thread,
while every R allocation — in particular every string —
keeps happening on the R thread, which is the only thread
that may touch the R API at all.
The switch must be flippable at runtime, per call or per session,
and the synchronous path must remain first-class:
it is the mandatory fallback wherever the concurrent path cannot run,
so the two paths coexist by design, not as a transition.

## What the engine already does (verified on the vendored tree)

The design leans on engine behavior that was read, not assumed;
paths are relative to this repository.

* **Streaming results buffer through a bounded, blocking queue.**
  `PhysicalBufferedCollector::Sink()` copies each produced chunk into
  `SimpleBufferedData`
  (`src/duckdb/src/execution/operator/helper/physical_buffered_collector.cpp`,
  `src/duckdb/src/main/buffered_data/simple_buffered_data.cpp`).
  The buffer is capped by the `streaming_buffer_size` client setting,
  default 1,000,000 bytes
  (`ClientConfig::streaming_buffer_size`,
  `src/duckdb/src/include/duckdb/main/client_config.hpp`).
  A full buffer makes the sink return `BLOCKED`:
  the producing task is descheduled and queued in `blocked_sinks`.
  **The producer waits; it does not spill.**
  Parked tasks cost no CPU, but they hold the pipeline alive:
  operator state (hash tables, sort runs), the active transaction,
  and the buffered chunks themselves —
  which are allocated from the default allocator,
  outside `memory_limit` accounting.
* **Parked producers are woken only by the consumer.**
  `BufferedData::ReplenishBuffer()` — called from `Fetch()` —
  runs `UnblockSinks()` and lets the calling thread execute tasks
  until the buffer is full again, then `Scan()` pops one chunk
  (`src/duckdb/src/main/buffered_data/buffered_data.cpp`).
  Between two `Fetch()` calls nothing refills the buffer:
  production happens inside `Fetch()`, on the fetching thread
  plus whatever worker threads pick up the rescheduled tasks.
  This is why the current streaming path alternates
  instead of overlapping.
* **`dbSendQuery(stream = TRUE)` returns at the first full buffer.**
  `PendingQueryResult::ExecuteInternal()` loops until the executor
  reports `RESULT_READY`, which for a buffered collector means
  "the result collector is blocked", i.e. the buffer filled once
  (`src/duckdb/src/parallel/executor.cpp`, `Executor::ExecuteTask()`).
  Opening a stream therefore costs planning plus production up to the
  first full buffer (or the query finishing first), on the R thread —
  and binding runs there too, which matters below.
* **One live stream per connection.**
  The client context tracks a single open result;
  starting any other statement invalidates the live stream,
  and a drained stream closes itself
  (`src/duckdb/src/main/stream_query_result.cpp`).
  #2292 already documents this and closes streams on
  `dbBind()` / `dbClearResult()`.
* **Interrupts are thread-safe.**
  `ClientContext::Interrupt()` sets an atomic flag;
  `SimpleBufferedData::ExecuteTaskInternal()` checks it even when the
  buffer is full, so a blocked stream can always be cancelled.
  The glue's `ScopedInterruptHandler` (`src/signal.cpp`)
  already routes SIGINT to exactly this call.
* **Worker threads exist, but the client seat is one of them.**
  The scheduler launches `threads - external_threads` OS workers
  (`src/duckdb/src/parallel/task_scheduler.cpp`);
  the thread that calls `Fetch()` occupies the client seat
  and participates in execution.
  With `threads = 1` there are no workers at all:
  every task runs on whichever thread fetches.
* **This engine series can keep results in spillable memory.**
  `PhysicalResultCollector::CreateCollection()` supports
  `QueryResultMemoryType::BUFFER_MANAGED`:
  the materialized result's `ColumnDataCollection` is allocated through
  the buffer manager, counted against `memory_limit`,
  evictable to `temp_directory`, and tracked by the
  `ResultSetManager` so it may outlive the client context
  (`src/duckdb/src/execution/operator/helper/physical_result_collector.cpp`,
  `src/duckdb/src/main/result_set_manager.cpp`).
  It is selected per query via
  `PendingQueryParameters::query_parameters.memory_type` —
  available on the prepared-statement path the glue already uses.
  duckdb-r requests `IN_MEMORY` (the default) today,
  so materialized results live in untracked heap memory.
  `ColumnDataConsumer`
  (`src/duckdb/src/common/types/column/column_data_consumer.hpp`)
  can additionally scan a collection *destructively*,
  freeing blocks as they are read.

### Answers to the sponsoring questions

* *Does DuckDB ever wait because R has not consumed yet?*
  Yes, by design: the streaming buffer is bounded and blocking.
  The wait is a parked task, not a busy loop, and stays interruptible.
  What the wait holds open is the real cost:
  pipeline operator state, the transaction, and — untracked —
  the buffered chunks.
* *Is the system smart enough to spill the stream instead?*
  No. The streaming buffer never spills; blocking *is* the mechanism.
  Spilling belongs to the materialized side:
  a buffer-managed result (above) or an engine-side table.
* *Can results be spilled to disk and read piecemeal, without a
  duplicated copy?*
  Yes, on two levels.
  Today, at the user level:
  `CREATE TEMP TABLE ... AS <query>` materializes into buffer-managed
  storage that respects `memory_limit` and spills to `temp_directory`
  (working again since
  [#2562](https://github.com/duckdb/duckdb-r/pull/2562);
  measured in
  [`experiments/2026-08-temp-storage-spill/`](/experiments/2026-08-temp-storage-spill/README.md)),
  then stream-fetch from that table and drop it.
  After stage 2 below, at the package level:
  materialized results themselves become buffer-managed,
  so `dbGetQuery()` holds at most one engine copy under `memory_limit`
  (spilling if needed) plus the R vectors being filled,
  and the consuming scan frees the engine copy as conversion advances.
  That is the direct lever on the
  [#1065](https://github.com/duckdb/duckdb-r/issues/1065) class of
  reports — fetching even "simple" data costs roughly twice the data
  today: one untracked engine copy plus the R copy.

## Design

Three coordinated pieces, in increasing order of ambition.
Piece 1 is this plan's core; piece 3 can land independently.

### 1. A prefetch thread between the stream and `dbFetch()`

One dedicated native thread per *active streaming result* — the pump —
whose only job is to move chunks out of the engine:

```
engine workers ──► streaming buffer ──► pump thread ──► chunk queue ──► R thread
     (produce)       (bounded, engine)   Fetch() loop     (bounded, glue)   convert
```

* The pump runs `StreamQueryResult::Fetch()` in a loop.
  Each call replenishes the engine buffer
  (the pump occupies the client seat, so with `threads = 1`
  the pump *is* the engine thread — overlap still happens)
  and yields one flattened `DataChunk`, engine memory only.
* Chunks land in a bounded queue owned by the glue
  (`std::mutex` + two condition variables + byte budget;
  default budget: `streaming_buffer_size`, so end-to-end in-flight
  data is roughly two buffers plus the chunk being converted).
  Queue full → the pump sleeps before calling `Fetch()` again;
  the engine buffer then fills; the engine sinks park.
  Backpressure composes end to end, unchanged.
* `dbFetch(n)` pops chunks on the R thread and feeds the *existing*
  conversion loop from #2292 (`duckdb_r_chunks_to_df()`):
  every allocation, including every `Rf_mkCharLenCE()`,
  stays on the R thread.
  The split-tail bookkeeping for exact `n`
  (`RQueryResult::pending_chunk`) also stays on the R side —
  the pump only ever transfers whole chunks.
* While the queue is empty and the stream not done,
  the R thread waits in slices
  (`wait_for` ~100 ms, then `cpp11::check_user_interrupt()`);
  on interrupt it calls `ClientContext::Interrupt()`,
  which unblocks the pump wherever it is,
  then joins and rethrows as the usual interrupt condition.
  This replaces `ScopedInterruptHandler` for the pumped path —
  no signal handler swapping, same observable behavior.
* The pump never touches the R API. Not for allocation, not for errors,
  not for interrupt checks. Any exception is caught,
  stored as `ErrorData`, the queue is closed,
  and the R thread rethrows it on the next pop.
  This is the hard rule that makes the whole design safe,
  and it becomes a stated convention in
  [`architecture/glue/`](/handbook/architecture/glue/README.md).
* Lifecycle: created lazily by the first `dbFetch()` on an eligible
  streaming result; stopped (interrupt + join) by drain, error,
  `dbBind()`, `dbClearResult()`, the externalptr finalizer,
  and connection shutdown.
  Every stop path is bounded because `Interrupt()` reaches
  a parked or fetching pump promptly.

### 2. Runtime switch, and why the synchronous path stays

The pump is an accelerator with a guard list, not a replacement.

* **Switch.** `dbSendQuery(..., stream = TRUE, prefetch = NA)`:
  `NA` consults `getOption("duckdb.stream_prefetch", FALSE)`,
  `TRUE`/`FALSE` force per call.
  Flippable at runtime in both directions, per result.
  Default off for at least one release;
  flipping the default later is a one-line change
  plus a NEWS entry.
* **Guards.** The pump silently degrades to the synchronous pull
  (today's #2292 behavior, same results, same API) when:
  * the connection has R-backed tables registered
    (`duckdb_register()` data frames, `duckdb_register_arrow()`):
    their scans may touch R memory from execution threads.
    Reading plain vectors is pointer access resolved at bind time
    (`DataFrameScanBind()` calls `DATAPTR_RO()` on the R thread),
    but nested columns and Arrow readers have execution-time touch
    points, and today's safety argument —
    "the R thread is blocked inside the engine while workers read" —
    stops holding once R runs concurrently.
    Until the audit (T1) shrinks it, the guard is per connection,
    which is coarse but cheap to reason about.
  * the progress display cannot run on a pumped query:
    `RProgressBarDisplay::Update()` evaluates R from whichever thread
    drives execution (`src/connection.cpp`), which would be the pump —
    and it is on by default in interactive sessions,
    so guarding on it would switch prefetch off exactly where people
    sit. Instead of a guard, the open (still on the R thread) turns
    `enable_progress_bar` off for the stream's lifetime and restores
    it on close: progress reporting and prefetch are mutually
    exclusive per result, never per session.
  * the statement is not stream-eligible anyway
    (EXPLAIN, non-SELECT, multi-row bind — #2292 already routes these).
* **Coexistence as architecture.**
  The C++ seam is one function: "give me the next chunk" —
  a synchronous implementation that calls `Fetch()` on the R thread
  (today's code, verbatim) and a pumped implementation that pops
  the queue.
  Everything downstream — accumulation, tail splitting, conversion,
  `eof` bookkeeping — is shared and unaware of the mode.
  The R surface does not fork at all beyond the `prefetch` argument.
  Parity is enforced the way #2292 already enforces
  stream-vs-materialized parity:
  the same test body runs under both modes
  (plus a slow-consumer stress test and an interrupt test per mode).
  Neither path is scheduled for deletion;
  the synchronous pull is the guard fallback permanently,
  so "keep both maintainable" is the steady state,
  and the seam keeps the shared surface at one copy.

### 3. Spillable materialized results (independent, complements 1)

Streaming bounds memory but pins the connection and trades backpressure
for engine idleness when R is slow.
The materialized side deserves the symmetric fix:

* Switch duckdb-r's materialized execution to
  `QueryResultMemoryType::BUFFER_MANAGED`,
  behind `getOption("duckdb.results_buffer_managed", FALSE)` initially.
  Results then count against `memory_limit` and spill to
  `temp_directory` under pressure instead of growing untracked heap —
  the engine's own `Connection::Query(query, params...)` overloads
  already request it (`QueryParamsRecursive`,
  `src/duckdb/src/main/connection.cpp`),
  so the code path is exercised upstream.
* Convert with a consuming scan (`ColumnDataConsumer`) so engine blocks
  are freed as column conversion advances:
  peak memory for `dbGetQuery()` drops from
  "engine copy + R copy" to "R copy + a window of engine blocks",
  and the engine copy that does exist is spillable.
  Row count is known before conversion,
  so allocation stays exact and single-pass — no growing, no `rbind`.
* This is the recommended answer when the consumer is slow or the
  result exceeds memory *and* the connection must stay usable:
  materialize (spillable, engine-side), then fetch piecemeal.
  Streaming remains the answer when the result is consumed promptly
  and incrementally.

## Trade-offs, stated plainly

* **Synchronous streaming** (after #2292, `prefetch` off):
  minimal memory, minimal machinery;
  production and conversion alternate, so wall time is their sum;
  the connection is pinned while the stream lives;
  a slow consumer parks the engine with pipeline state held —
  nothing spills.
* **Prefetched streaming** (this plan):
  hides the smaller of production time and conversion time —
  up to 2× wall clock when the two are balanced
  (sorts, aggregating joins with wide output),
  but only the engine's share when conversion dominates:
  the first harness numbers put that share at roughly a fifth for a
  bare `SELECT *` scan and less for pure string columns,
  so a pump alone buys ~1.15–1.3× there, not 2×.
  Costs one thread, one bounded queue
  (~2 × `streaming_buffer_size` extra in-flight memory),
  and real lifecycle code (stop paths, error transport);
  inherits every streaming caveat (pinned connection, no spill);
  guarded off exactly where the engine could re-enter R.
  The complementary lever for conversion-dominated shapes is making
  conversion cheaper — deferred string materialization in the spirit
  of the relational API's ALTREP columns — which composes with the
  pump and is noted as future work, not designed here.
* **Buffer-managed materialization** (piece 3):
  memory-bounded and spillable on the engine side,
  connection free immediately, row count known, rescan possible;
  but first-row latency is full execution,
  spilling costs disk I/O,
  and the data still crosses into R vectors —
  it caps duplication, it does not remove conversion cost.
* **Doing nothing** keeps `dbGetQuery()` at
  untracked engine copy + R copy,
  which is precisely the class of report in #1065 and #1997.

The three compose rather than compete:
prefetch accelerates the streaming lane;
buffer-managed materialization fixes the default lane;
`streaming_buffer_size` (a plain `SET`, already effective) is the
first knob to reach for before any of it.

## Benchmark

[`experiments/2026-08-streaming-tpch-bench/`](/experiments/2026-08-streaming-tpch-bench/README.md)
holds a self-contained TPC-H harness (`bench.R`) built for this plan:

* one file, DBI + duckdb only;
  TPC-H data via the `tpch` extension when downloadable,
  otherwise a deterministic, schema-faithful synthetic `lineitem` —
  the harness never fails for want of infrastructure;
* every scenario × query cell runs in a fresh R subprocess,
  so peak RSS (`VmHWM`, reset per cell) and allocation deltas are
  attributable;
* scenarios bracket the design space:
  `materialize` (status quo), `stream_all` / `stream_chunked`
  (#2292's two modes), `arrow_drain` (production cost as seen from R),
  `engine_only` (`CREATE TEMP TABLE AS`, no conversion at all),
  `spill_then_stream` (the temp-table idiom);
  `engine_only` vs `materialize` estimates the conversion share,
  i.e. the Amdahl ceiling a pump can reclaim, per query shape;
* knobs for the interesting parameters:
  `--buffer` (`streaming_buffer_size`), `--memlimit`, `--chunk`,
  `--sf`, and `DUCKDB_LIB` to point at any build.

Prior art, and why it is not reused directly:
Tom Ebergen's `db-benchmark` continuation (duckdblabs/db-benchmark)
is the reference for cross-solution group-by/join comparisons,
but it benchmarks query engines against each other,
carries a multi-solution harness that is genuinely hard to run
piecemeal, and does not isolate the R transfer boundary —
which is the only thing this plan changes.
The harness here is the wrapped-away version:
one script, no setup, engine constant, boundary varied.
DuckDB's in-tree `benchmark/tpch/` runner measures the C++ engine
and never crosses into R, so it brackets from the other side.

## Tasks

Each task lands separately and keeps the suite green.

* **T1 — audit execution-time R touchpoints.**
  Inventory every place engine execution can reach R memory or the
  R API off the R thread:
  `src/scan.cpp` nested/struct columns, the Arrow scan's batch pulls,
  the progress display, relational-API materialization.
  Deliverable: the guard list for piece 1, recorded in this file,
  each entry marked safe / guarded / needs-fix.
* **T2 — extract the next-chunk seam.**
  Pure refactor of `rapi_stream_fetch()` so the accumulation loop asks
  a `NextChunk()` provider; synchronous provider only.
  No behavior change; existing #2292 tests must not notice.
* **T3 — the pump.**
  `StreamPrefetcher` in a new glue unit:
  thread, bounded queue, error slot, stop protocol
  (`Interrupt()` + join), byte budget.
  Internal-only entry points; tests via `:::` cover
  clean drain, early close, mid-stream engine error,
  interrupt while empty-waiting, interrupt while full-parked,
  and finalizer-driven teardown under `gc()`.
* **T4 — the switch and the guards.**
  `prefetch` argument + option, guard checks
  (registered tables, progress display), silent fallback,
  parity run of the #2292 stream tests under both modes,
  slow-consumer stress test asserting bounded RSS.
* **T5 — measure and record.**
  Run the harness against the T4 build
  (CRAN build and PR build already recorded alongside),
  store CSVs in the experiment directory,
  and state the achieved overlap against the `engine_only` ceiling.
* **T6 — buffer-managed materialized results.**
  `memory_type` plumbed through `rapi_execute`/`rapi_bind` behind its
  option; consuming-scan conversion; tests under a tight
  `memory_limit` proving spill-not-fail and the reduced peak;
  builds on the #2562 spill-directory fix.
* **T7 — documentation.**
  Roxygen for the new argument and option,
  NEWS via PR description,
  and the handbook entries drafted below,
  placed by their owning leaves.

Suggested order: T1–T2 (cheap, de-risking) → T3 → T4 → T5;
T6 independent after T1; T7 last.

## Risks and open questions

* **The guard list is load-bearing.**
  If T1 finds an execution-time R touchpoint that cannot be guarded
  per connection (a scan that materializes ALTREP lazily, say),
  the guard stays coarse and the pump simply engages less often —
  safe, just less useful. The design degrades, it does not break.
* **Progress display interplay.**
  The pumped path switches the bar off per result;
  *supporting* progress on pumped queries would need callback
  marshalling to the R thread — explicitly out of scope.
  A user who wants the bar keeps it by leaving `prefetch` off,
  which is one more reason the synchronous path is permanent.
* **Pump-thread stacks on Windows.**
  `std::thread` under Rtools is fine, but stack sizes and DLL unload
  order at session end deserve a test on the CI matrix
  (`operations/ci/matrix/`).
* **Async open.**
  `dbSendQuery(stream = TRUE)` still plans, binds, and fills the first
  buffer on the R thread — binding may evaluate R
  (replacement scans), so moving the *open* off-thread needs a
  bind-complete barrier. Deliberately not in this plan.
* **Where `n`-row fairness lives.**
  The pump transfers whole chunks; a tiny `dbFetch(n = 10)` against a
  huge buffered queue still converts only what it needs —
  but the queue keeps filling. Acceptable: the budget bounds it.
* **Choice of default queue budget** (= `streaming_buffer_size`)
  is a guess until T5 measures it; the option exists from day one.

## Tentative handbook entries

Drafts for the owning leaves, to be placed by T7.
Wording follows each leaf's existing style; links abbreviated here.

For [`usage/statements/`](/handbook/usage/statements/README.md):

> **Streaming results.**
> `dbSendQuery(con, sql, stream = TRUE)` opens a cursor instead of
> materializing: `dbFetch(n)` converts chunks as they arrive, and
> memory stays bounded by the batch size.
> One stream per connection — any other statement on the same
> connection invalidates it — and the stream pins the connection's
> transaction until drained or cleared.
> With `prefetch = TRUE` (or `options(duckdb.stream_prefetch = TRUE)`)
> the engine keeps producing on its own threads while R converts;
> results are identical, and the option is ignored where it cannot
> apply (registered R tables, progress display, non-SELECT).

For [`usage/memory/`](/handbook/usage/memory/README.md),
extending the existing bullets:

> * **Streaming fetch bounds R memory:**
>   `dbSendQuery(stream = TRUE)` plus `dbFetch(n = )` holds one batch
>   of R vectors at a time.
>   The engine buffers at most `streaming_buffer_size`
>   (default ~1 MB, a plain `SET`) ahead of R;
>   when R stops consuming, the engine *waits* — parked, not spinning,
>   interruptible — and never spills the stream buffer.
>   A stream held open holds query state open with it.
> * **Spill is for materialized data:**
>   to detach from the connection and stay under `memory_limit`,
>   materialize engine-side — `CREATE TEMP TABLE ... AS`, spillable to
>   `temp_directory` — and stream from that.
>   [Once T6 lands: `options(duckdb.results_buffer_managed = TRUE)`
>   gives `dbGetQuery()` the same property: the engine copy of a
>   result counts against `memory_limit`, spills instead of failing,
>   and is freed progressively while it converts to R vectors.]

For [`architecture/glue/`](/handbook/architecture/glue/README.md):

> **Threads.**
> The R thread is the only thread that may touch the R API —
> allocate, warn, error, check interrupts, run finalizers.
> A streaming result may own a pump thread that drives
> `StreamQueryResult::Fetch()`; it handles engine objects only,
> transports exceptions as `ErrorData` into a slot the R thread
> rethrows from, and is stopped by `ClientContext::Interrupt()`
> plus join on every teardown path.
> Conversion — every `duckdb_r_allocate()` / `duckdb_r_transform()`
> call, every string — runs on the R thread, pumped or not.
> The pump never runs for connections with registered R tables, and a
> pumped result runs with the progress bar disabled: both paths let
> the engine reach back into R, and the reach-back contract (see "The
> engine runs R code while it holds the client context lock") assumes
> the R thread is parked inside the engine, which a pumped fetch no
> longer guarantees.

For [`architecture/engine/`](/handbook/architecture/engine/README.md):

> **Streaming buffer.**
> Streaming results flow through `SimpleBufferedData`:
> bounded by `streaming_buffer_size`, producer tasks park when it is
> full and are rescheduled by the consumer's next fetch.
> Blocking is the only backpressure — the stream buffer never spills,
> and it is allocated outside `memory_limit`.
> Materialized results can instead be collected buffer-managed
> (`QueryResultMemoryType::BUFFER_MANAGED`): counted, evictable,
> spillable — the package requests the untracked default today.
