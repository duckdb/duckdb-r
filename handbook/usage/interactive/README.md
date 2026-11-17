# Interactive use

What a session does while you work, rather than what a call returns
once it is over — and whether this package does it,
or hands it to something that does.

## The progress display

The progress display is the engine calling back into R.
The C++ side holds the symbol it invokes
(`get_progress_display_sym` in
[`src/include/rapi.hpp`](/src/include/rapi.hpp)),
and [`R/progress_display.R`](/R/progress_display.R) draws it.
The engine calls it every time R's thread runs or polls a task of a running query, whether or not the progress moved
([#2748](https://github.com/duckdb/duckdb-r/issues/2748)).
Single-threaded the calls come between task slices;
with several threads R's thread can poll in a loop while the workers run,
where the engine's loops around `ExecuteTaskInternal()` go back to `WaitForTask()` on `BLOCKED` or `NO_TASKS_AVAILABLE`
and the wait returns without blocking
([`src/duckdb/src/main/client_context_execution.cpp`](/src/duckdb/src/main/client_context_execution.cpp)).
A callback that returns at once is then called without pause, and one that takes longer thins the calls out by its own cost.
A function set as `duckdb.progress_display` receives one number per call:
the display's `Update()` passes the percentage and its `Finish()` passes 100.
The glue sets the engine's own wait, `wait_time`, to zero in [`src/connection.cpp`](/src/connection.cpp).
Throttling is left to the R side.
A query paints nothing in its first half second, so a fast query never paints, and at most one line every half second after that.
Completion bypasses the throttle, so a painted line is cleared when its query completes.
Its display is built by `get_progress_display()`, which clears the line, if nothing was printed after it, and restarts the throttle.
The display keeps one state for the session, not one per query.
A query that starts while another connection's stream is still being read clears that stream's line and restarts its throttle too.

**What the percentage measures.**
`Executor::GetPipelinesProgress()` sums the query's pipelines,
each one's source progress scaled to its source's estimated row count
(`Pipeline::GetDetailedProgress()` in [`src/duckdb/src/parallel/pipeline.cpp`](/src/duckdb/src/parallel/pipeline.cpp)),
and a pipeline that has not started counts as none of its rows.
While a pipeline's source cannot report, `ProgressBar::Update()` skips the call
([`src/duckdb/src/common/progress_bar/progress_bar.cpp`](/src/duckdb/src/common/progress_bar/progress_bar.cpp)).
So a large local query reports its execution, not only its fetches, but the bar moves with estimated rows rather than time:

* a scan moves the bar evenly, and the work after it shows as a jump;
* a sort goes silent while it finishes its runs, and its scan owns only the share its estimated rows give it, whatever its duration;
* a filter the optimizer estimates at a few rows shrinks its scan's weight, so the bar stops short of the end
  until `Finish()` takes it to 100.

**When a query is done.**
Every DBI call that sends SQL (`dbGetQuery()`, `dbExecute()`, `dbSendQuery()`, `dbSendStatement()`, `dbGetQueryArrow()`)
prepares the last statement of its string with `ClientContext::Prepare()`,
which runs a `PREPARE` as a query of its own, so the statement's calls open with that query's `Finish()`, a 100, before its own run from 0.
The statements before the last run through `Connection::Query()` in [`src/statement.cpp`](/src/statement.cpp) without a `PREPARE`,
and every statement has its own display and `Finish()`,
so a multi-statement string passes a 100 per statement and one more for the last statement's `PREPARE`.
The statement's own `Finish()` comes when it ends:
inside the call for a materialized result, `dbSendQuery()` included, whose `dbFetch()` reads then get no call,
and with the read that ends the query for a stream, which is the first read when the result fits the buffer.
That a stream's `Finish()` waits for its end is observed, not guaranteed.
Its caller, `ClientContext::UpdateProgressInternal()`, asks `ProgressBar::Update()` for a final update on any state a caller can observe,
a ready chunk included, and marks that as not yet correct for streaming results;
`Executor::IdleState()` reports a ready state while the result collector is blocked
([`src/duckdb/src/parallel/executor.cpp`](/src/duckdb/src/parallel/executor.cpp)).
If a poll before a fetch ([`src/arrow_export.cpp`](/src/arrow_export.cpp)) reached that state mid-stream,
the display would finish then, the `Finish()` at the end would be dropped, and a line painted after it would stay.
A query that fails or is interrupted never gets its `Finish()`, and the last line painted stays until the next query starts.

**Why a stream goes quiet.**
A stream read takes chunks already buffered without running the engine
(`BufferedData::Participate()` in [`src/duckdb/src/main/buffered_data/buffered_data.cpp`](/src/duckdb/src/main/buffered_data/buffered_data.cpp)),
and the engine computes ahead until the buffer holds `max_streaming_buffer_size`.
A new connection starts at 10 MiB
(`ClientConfig` in [`src/duckdb/src/include/duckdb/main/client_config.hpp`](/src/duckdb/src/include/duckdb/main/client_config.hpp)),
and `RESET` sets the smaller of 10 MiB and the available memory
(`ClientConfig::SetDefaultStreamingBufferSize()` in [`src/duckdb/src/main/client_config.cpp`](/src/duckdb/src/main/client_config.cpp)).
A result that fits the buffer is computed by the first read, which gets every call, and the reads after it get none.
A query whose expensive part runs before its first row, such as a sort or an aggregate, runs that part in the first read too,
and only the reads that refill the buffer with its output report after it.
A larger buffer leaves fewer reads that run the engine, and a smaller one spreads the calls over more of them.

**A remote part and a local part** share the bar by their sources' estimated rows, not by their duration.
A slow remote scan stretches its share in time without widening it,
and with several threads its progress moves in steps, standing still while the ranges it fetches at once download.
The local part after it then moves the bar quickly, and a final jump to 100 is common.

The measurements behind this section, with the percentages and read counts per query shape, thread count and buffer size, are in
[`experiments/2026-11-17-progress-display/`](/experiments/2026-11-17-progress-display/README.md).

## Interrupting a query

Ctrl+C during a DuckDB call is caught by the package rather than by R.
[`src/signal.cpp`](/src/signal.cpp) installs a handler for the duration
of the call, asks the engine to stop through
`ClientContext::Interrupt()`, and raises the R interrupt once the call
returns — so the condition surfaces at the R level, catchable, instead
of the engine unwinding on its own.
Only one such handler is installed at a time, so a DuckDB call entered
while another is running — from a progress display callback, say —
fails with `Connection already working on another query` rather than
deadlocking.
A query that materializes an ALTREP relation while it binds a data frame scan is the exception:
a relation of another connection runs under the outer call's handler,
and one of the same connection fails, since its query holds the lock it would wait for.

**It reaches work the engine executes** — scans, joins, aggregations,
anything running as executor tasks — because the engine reads the
interrupt flag between them.

**It does not reach a wait that never returns to that read**, and a
network request in flight is one.
The flag is set and stays set: the call ends when the request does, and
the interrupt is raised then.
Whether such a wait can be cancelled at all is the extension's to
arrange, not this package's: MotherDuck's sign-in wait arranges it for
the DuckDB CLI and not for R, which is
[#202](https://github.com/duckdb/duckdb-r/issues/202).
Pressing Ctrl+C again changes nothing — the package holds one interrupt
and never escalates, since what a signal handler could do instead costs
more than the wait
([`plan/PLAN-query-cancellation.md`](/plan/PLAN-query-cancellation.md),
measurements in
[`experiments/2026-08-08-interrupt-reach/`](/experiments/2026-08-08-interrupt-reach/README.md)).

## The Connections pane

The Connections pane is RStudio-only and lives in
[`R/Viewer.R`](/R/Viewer.R), adapted from the odbc package's.
It queries `information_schema` to decide which object types the
database actually has, so a database with no views does not advertise
them, and it tells the IDE when a connection closes.

## The DuckDB UI

The DuckDB UI is a browser interface the engine serves,
and it arrives as the `ui` extension rather than as part of this
package: `INSTALL ui` once, then `CALL start_ui()` on a connection
starts the server and opens a browser at it
([#1083](https://github.com/duckdb/duckdb-r/issues/1083)).
Nothing about it is R-side — no function to call, nothing to configure —
so what the UI can do, and whether it installs on a platform at all,
are the extension's and its repository's
([`extensions/`](/handbook/usage/extensions/README.md)).
The DuckDB CLI's `-ui` flag is that program's own installation
and says nothing about this one's;
a page that comes up empty is the extension's to answer, in
[duckdb/duckdb-ui](https://github.com/duckdb/duckdb-ui).

*To deepen: state what turns the progress display on and off, what
the pane does with a connection the user closes from the IDE, and how
much of a connection's own state the UI sees.*
