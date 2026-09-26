# Plan: a private context behind a streaming result

**Open.**
The mapping as it stands, and why a context per result is refused as the mapping, is
[`architecture/glue/objects/`](/handbook/architecture/glue/objects/README.md)'s;
this file proposes what to do with the part of the idea that is sound,
and where the two disagree the leaf is right.
The measurements it rests on are
[`experiments/2026-09-26-connection-per-result/`](/experiments/2026-09-26-connection-per-result/README.md).

## Problem

A streaming result is its connection's one open result, and any statement on the connection ends it.
The package's own helpers are statements,
so the DBI chunked loop, a stream read in batches with each batch appended through the same connection,
stops after one batch,
and the Connections pane can end a stream from the IDE.
Until [#2775](https://github.com/duckdb/duckdb-r/pull/2775) the ended stream read as drained and the loop reported success;
now it is an error that names the cause, and the loop still does not complete.
Today the exposure is `dbSendQueryArrow()`'s;
once `dbSendQuery(stream = TRUE)` lands
([#2584](https://github.com/duckdb/duckdb-r/pull/2584),
[#2586](https://github.com/duckdb/duckdb-r/pull/2586),
[#2587](https://github.com/duckdb/duckdb-r/pull/2587))
it is every streaming `dbSendQuery()`'s,
and the producer thread of [`PLAN-streaming-thread.md`](PLAN-streaming-thread.md) cannot pump two results at once
while they share a context, nor keep pumping one through a statement on its connection.

DBI permits more than one open result per connection,
and this package has never limited it:
`send_query_only_one_result_set` is skipped as a wontfix in
[`tests/testthat/test-DBItest.R`](/tests/testthat/test-DBItest.R),
which the materialized route honours by copying every row into R at send time.
The streaming route should honour it without giving up its memory bound.

## What the engine offers

Read on the vendored tree, and measured in the experiment above where a number is given.

* A context costs 16 µs to open and close, and 8 to 14 KB to keep.
* A bound statement's `StatementProperties` names the catalogs it reads and the ones it modifies
  (`read_databases`, `modified_databases` in
  vendored `src/duckdb/src/include/duckdb/common/enums/statement_type.hpp`),
  so a statement that reads the temp catalog, or writes anywhere, is known before it runs.
* `ClientConfig` is a value, and `CatalogSearchPath::Set()` takes what `GetSetPaths()` returns,
  so a session's settings and default database copy onto a new context.
* The connection's context says whether an explicit transaction is open
  (`Connection::IsAutoCommit()` and `HasActiveTransaction()`).
* The frames a connection registered are on the connection object already,
  as the `_registered_df_<name>` attributes `rapi_register_df()` sets,
  so they can be registered again on another context.
* A stream on a context of its own reads a snapshot:
  `INSERT`, `CHECKPOINT` and `DROP TABLE` on the connection run, and the stream yields on.

## Design

1. **An ended stream fails loudly, on every route.**
   The Arrow route does since #2775 (`RArrowArrayStreamWrapper` in [`src/arrow_export.cpp`](/src/arrow_export.cpp));
   a streaming `dbFetch()` (#2584) does the same before it lands.
2. **A private context, when the statement qualifies.**
   At `dbSendQueryArrow()` and `dbSendQuery(stream = TRUE)` the statement is prepared on the connection's context as today.
   Then, when the connection is in auto-commit mode,
   the string holds one statement,
   and that statement is a `SELECT` whose properties modify nothing and read no temp catalog,
   the result gets a context of its own:
   the glue opens one, copies the connection's `ClientConfig` and search path,
   registers the connection's frames again as temporary views,
   prepares the statement there under the same environment-scan window, and executes there.
   Otherwise the statement runs on the connection's context, with one live stream and the error of step 1.
3. **Lifetime.**
   The private context is a member of `RQueryResult`, and of `RStatement` for the `dbFetch()` route;
   it dies with `dbClearResult()` or with the result's finalizer.
   The engine's `ConnectionManager` counts it, so the instance-cache patch reports it as a connection.
   `dbDisconnect()` does not reach it, which is the leaf's separate fact about results and their connections.
4. **Interrupts and progress.**
   `ScopedInterruptHandler` takes the context it is given, and the progress display comes with the copied config.
5. **A switch.**
   An option, `duckdb.result_context` or a better name, set to `FALSE` forces the connection's context:
   for the fallback tests, and for a caller who needs a stream inside a transaction to see that transaction.

## Consequences to state

* A stream on a private context is a snapshot as of its start; a commit on the connection after that is not in it.
  Under auto-commit this is what a materialized result already is.
* `FORCE CHECKPOINT` on the connection while such a stream is parked deadlocks the session (measured):
  it waits for the stream's transaction, and the stream waits for the R thread.
  The glue refuses it while private streams are open, naming them,
  rather than leaving the wait to be found.
* Registered frames are replayed per private context.
  `duckdb_register()` costs about 1 ms at the R level today;
  the C++ view alone should cost far less, to be measured at implementation.
  A connection with many registrations and many streams pays it per stream.
  Moving `duckdb_register()` onto an instance-wide replacement scan, as the Arrow registrations are,
  would remove the replay and make a registration visible from every connection; not proposed here.
* `SETSEED()` state does not copy.
* dbplyr's `collect()` of a `compute()`d temp table reads the temp catalog, so it stays on the connection's context:
  one live stream there, and the error of step 1.

## Tasks

1. The error for an ended stream on the `dbFetch()` route, once #2584 lands, with the interleave cases of the experiment as tests.
2. The qualification check over `StatementProperties` and the transaction state, one test per guard.
3. The private context: open, copy the config and the search path, replay the registrations, prepare, execute;
   the chunked loop through one connection, and two streams on one connection read alternately, as tests.
4. The `FORCE CHECKPOINT` refusal while private streams are open.
5. The switch, its documentation on the reference pages and in
   [`usage/statements/`](/handbook/usage/statements/README.md), and `NEWS.md`.

## Open questions

* Whether `dbDisconnect()` should close the private contexts, and the results, it knows of,
  which is the same question as an uncleared result keeping an instance alive past its connection.
* Whether the pump of [`PLAN-streaming-thread.md`](PLAN-streaming-thread.md) makes the private context
  a requirement of a pumped result rather than a guarded choice:
  a pumped result on the connection's context would hold the context's lock between fetches
  and be ended by the next statement on the connection, the same failure only racier.
* Whether the legacy `dbSendQuery(arrow = TRUE)` route wants any of this; it materializes, so no.
