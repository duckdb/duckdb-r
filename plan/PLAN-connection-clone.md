# Plan: a connection that clones its session, and a result that owns one

**Open.**
The mapping as it stands, and why a context per result is refused as the mapping, is
[`architecture/glue/objects/`](/handbook/architecture/glue/objects/README.md)'s;
this file proposes the explicit form of the idea,
and where the two disagree the leaf is right.
The measurements it rests on are
[`experiments/2026-09-26-connection-per-result/`](/experiments/2026-09-26-connection-per-result/README.md).

## Problem

A streaming result is its connection's one open result, and any statement on the connection ends it.
The package's own helpers are statements,
so the DBI chunked loop, a stream read in batches with each batch appended through the same connection,
stops after one batch,
and the Connections pane can end a stream from the IDE.
Since [#2775](https://github.com/duckdb/duckdb-r/pull/2775) reading the ended stream is an error
whose message sends the caller to a separate connection.
Today the exposure is `dbSendQueryArrow()`'s;
once `dbSendQuery(stream = TRUE)` lands
([#2584](https://github.com/duckdb/duckdb-r/pull/2584),
[#2586](https://github.com/duckdb/duckdb-r/pull/2586),
[#2587](https://github.com/duckdb/duckdb-r/pull/2587))
it is every streaming `dbSendQuery()`'s.

The separate connection the message names is `dbConnect(drv)`,
and it carries nothing of the session the caller is working in:
not a `SET TimeZone`, not the `USE`d database, not the frames `duckdb_register()` made queryable,
so the caller repeats each by hand, or forgets one and reads a result labelled in another zone.
DBI defines the shorter form: `dbConnect()` takes "an existing DBIConnection object (in order to clone an existing connection)",
and this package has no method for it, so `dbConnect(con)` fails to dispatch today.
The producer thread of [`PLAN-streaming-thread.md`](PLAN-streaming-thread.md) has the same need from the other side:
a pumped result wants a context the R thread does not touch.

## Why explicit, and not a guarded default

The first draft of this plan gave every qualifying streaming result a private context by default,
behind guards (auto-commit mode, a single `SELECT` that writes nothing and reads no temp catalog),
with the connection's context as a silent fallback.
That is refused:

* A private context is a different contract, a snapshot with no temp tables, no open transaction and no `PREPARE`s,
  and a contract is asked for, not inferred.
  Guards make the behaviour flip on state the caller cannot see:
  inside `dbWithTransaction()` the stream ends at the next statement, outside it survives.
  Go's `database/sql` pool is the standing example of session state landing where the next statement does not look
  (<https://pkg.go.dev/database/sql#DB.Conn>).
* The common case pays for the rare one.
  `dbGetQuery()` and `collect()` never hold two results open,
  and a default would cost every streaming query a second bind,
  because the properties the guards read exist only once the statement is bound on the connection's context.
* A context is cheap here and unmeasured elsewhere.
  The engine runs every extension's `OnConnectionOpened()` for each one
  (`ConnectionManager::AddConnection()`, vendored `src/duckdb/src/main/connection_manager.cpp`),
  and what an extension backing a remote database does there is not the experiment's to say.
* Precedent agrees: Python's cursor is explicit
  (<https://duckdb.org/docs/stable/guides/python/multiple_threads>),
  the streaming mode itself is opt-in, and so is the pump's prefetch.
* A result-owned context that replays registered frames must protect them itself,
  since `duckdb_unregister()` on the connection drops the only protection the frame has,
  while a clone that is a connection carries its own attributes, as every connection does.

## Design

1. **`dbConnect(con)` clones the connection.**
   A method for `duckdb_connection` (`R/dbConnect__duckdb_connection.R`) opens a new `Connection` on the same instance
   and copies the session onto it in the glue:
   `ClientConfig`, which is a value and carries the session `SET`s and the progress display hook,
   and the search path, through `CatalogSearchPath::Set()` with what `GetSetPaths()` returns
   (both verified to compile against the vendored headers).
   The R side copies the driver, `convert_opts`, `debug` and `reserved_words` from the source,
   so a clone runs no keywords query and no `OlsonNames()`,
   and registers the source's frames again, their protection on the clone's own pointer,
   the way `rapi_register_df()` protects every registration.
   Arrow registrations are instance-wide already.
   Not carried, and said so on the reference page: the open transaction, the temp tables, the `PREPARE`d statements, `SETSEED()`.
   A clone is a connection: `dbDisconnect()` closes it, and it holds the instance as any connection does.
2. **The ended-stream error names the clone.**
   The message from #2775 says "run the other statement on a separate connection";
   it adds that `dbConnect(con)` makes one that carries the session.
3. **A result that owns a clone, later and by argument.**
   When the pump lands, `dbSendQueryArrow()` and `dbSendQuery(stream = TRUE)` take `isolated = TRUE`:
   the result clones the connection for itself and closes the clone in `dbClearResult()`,
   `prefetch = TRUE` implies it, and inside an open transaction it is refused with an error rather than quietly served
   from the connection's context.
   Nothing about it is built before the pump needs it.

## Consequences to state

* A clone is a session of its own: a snapshot per statement, its own temp catalog, its own transaction.
  Registered frames cross at clone time; a registration made later on either side does not.
* `FORCE CHECKPOINT` on one connection while a stream is parked on another does not return (measured),
  clone or not; [`usage/statements/`](/handbook/usage/statements/README.md) states it.
* Both connections hold the instance; closing one leaves the other, and the last one out releases it.

## Tasks

1. `dbConnect(con)`: the method, the session copy in the glue, the replay of registrations,
   and tests: a `SET TimeZone` on the source read back from the clone, a registered frame queried through the clone,
   a temp table not seen, the chunked loop completing with its writes on the clone, and `dbDisconnect()` of either side.
2. The error message of #2775 pointing at the clone.
3. The reference page (`?duckdb`, the connect section) and [`usage/connections/`](/handbook/usage/connections/README.md); `NEWS.md`.
4. Deferred: the result-owned clone, with the pump.

## Open questions

* Whether cloning inside an open transaction is refused, since the clone cannot see it, or allowed and documented; proposed: allowed.
* Whether `duckdb_register()` should become instance-wide, as the Arrow registrations are,
  which would remove the replay and make a registration visible from every connection; not proposed here.
