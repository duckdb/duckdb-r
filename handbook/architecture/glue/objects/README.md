# Objects

Which engine object each DBI object wraps, what that object scopes,
and what follows from the mapping:
one live stream per connection, a result that closes with its connection,
and why a context per result is refused as the mapping and kept as a plan.
The user-facing halves live where a user meets them:
instance lifetime in [`usage/connections/`](/handbook/usage/connections/README.md),
what a statement does and when in [`usage/statements/`](/handbook/usage/statements/README.md),
what a result costs in [`usage/memory/reading/`](/handbook/usage/memory/reading/README.md).

**The mapping.**
The wrappers are [`src/include/rapi.hpp`](/src/include/rapi.hpp)'s.

* `duckdb_driver` wraps `DBWrapper`: one `DuckDB` handle, which is one database *instance*,
  beside the state every connection to it shares, the Arrow registrations, the environment-scan hook and the extensions flag.
  It is reached through a `DualWrapper`, which is what lets a connection hold the instance's only strong reference.
* `duckdb_connection` wraps `ConnWrapper`: one `duckdb::Connection`, which is one `ClientContext`, the engine's session,
  beside the conversion options the connection was opened with and the set of results open on it.
* `duckdb_result` wraps `RStatement`: one `PreparedStatement` and its bound parameters,
  with the rows themselves in R, materialized at send time.
  `duckdb_result_arrow` wraps `RQueryResult`: one streaming `QueryResult`, and the Arrow stream over it once fetching starts.
* A relation wraps `RelationWrapper`: one `Relation` ([`altrep/`](/handbook/architecture/glue/altrep/README.md)).

A prepared statement and a streaming result each hold a `shared_ptr` to the context they were made on,
a relation only a weak one,
and a context holds its instance, which is the lifetime fact everything below turns on.

**What a context scopes.**
The engine's session is the context: the transaction, the temporary catalog,
which holds temp tables and the temporary views `duckdb_register()` creates
(`rapi_register_df()` in [`src/register.cpp`](/src/register.cpp)),
the session settings (`SET` without `GLOBAL`), the `PREPARE`d statements, the `USE`d default database, the random state,
and one active query with at most one open streaming result:
starting any statement on a context runs its `InitialCleanup()`, which ends the query before it and closes that stream
(vendored `src/duckdb/src/main/client_context.cpp`).
What the instance owns crosses every context: committed data, `ATTACH`, a global `SET`, a loaded extension,
and this package's Arrow registrations, which live on the `DBWrapper`.
Each of these was read from a second context in
[`experiments/2026-09-26-connection-per-result/`](/experiments/2026-09-26-connection-per-result/README.md).

**DBI's session is the engine's session.**
`dbBegin()`, `dbWriteTable(temporary = TRUE)`, `duckdb_register()` and dbplyr's `compute()` all act on the connection's context,
and every later statement on the connection sees them because it runs on that context.
That is what the mapping buys.

**One live stream per connection.**
A materialized result survives any statement on its connection, because its rows are already R's.
A streaming result is the context's open result,
`dbSendQueryArrow()`'s today and `dbSendQuery(stream = TRUE)`'s once
[#2584](https://github.com/duckdb/duckdb-r/pull/2584) lands,
and the package's own helpers run statements:
`dbExistsTable()`, `dbListTables()`, `dbListFields()`, `duckdb_register()`, `dbAppendTable()` and the Connections pane each end it.
The engine's Arrow stream wrapper reports an ended stream as the end of the stream
(`MyStreamGetNext()` in vendored `src/duckdb/src/common/arrow/arrow_wrapper.cpp`),
which is what the experiment above met: an empty batch, `dbHasCompleted()` saying `TRUE`,
and the DBI chunked loop that appends each batch through the same connection stopping after its first batch and reporting success.
Since [#2775](https://github.com/duckdb/duckdb-r/pull/2775) the glue wraps that stream and reports the ended result as an error instead
(`RArrowArrayStreamWrapper` in [`src/arrow_export.cpp`](/src/arrow_export.cpp);
what the error says, and when a stream counts as read to the end, is
[`usage/integrations/`](/handbook/usage/integrations/README.md)'s),
so the loop now stops at its second batch with the reason.
The way through is a second connection to the same instance:
a stream on each interleaves, and the loop completes with its writes on the other connection.
DBI names that second connection a clone, `dbConnect(con)`, and this package has no method for it yet:
[`plan/PLAN-connection-clone.md`](/plan/PLAN-connection-clone.md).

**A result closes with its connection.**
The prepared statement behind a result holds the context, and a streaming result holds it once more,
so a result left open at `dbDisconnect()` would keep the connection's session alive, and the instance with it,
with nobody to see it: the driver's `dbIsValid()` says `FALSE`, and the engine counts no connection,
the in-use-result state of
[`experiments/2026-09-19-instance-cache-in-use/`](/experiments/2026-09-19-instance-cache-in-use/README.md).
For a file that is the lock: another process is refused,
while this process, whose driver registry has forgotten the instance, opens the file a second time,
because a POSIX record lock is held per process,
and the two instances neither see nor exclude each other
(measured in the experiment above, on the tree before the change that follows).
So the connection owns its results, as DBI has it: `dbDisconnect()` discards the pending work.
The `ConnWrapper` keeps the set of prepared statements, streaming results and handed-over streams open on it,
and closing the connection closes each, which lets go of the last references to the context,
so nothing of the connection outlives it
(`ConnWrapper::~ConnWrapper()` in [`src/connection.cpp`](/src/connection.cpp)).
The R objects stay: `dbIsValid()` on such a result says `FALSE`,
every other method refuses it naming the closed connection,
a stream `dbFetchArrow()` handed over reports the same instead of reading on,
and `dbClearResult()` still succeeds, once and without a word.
DBI asks for results to be cleared before the connection closes, and for a warning otherwise,
which `dbDisconnect()` gives, counting the results it closed
([`R/dbDisconnect__duckdb_connection.R`](/R/dbDisconnect__duckdb_connection.R)).
A relation needs none of this: it holds the context weakly, and the engine refuses it once the context is gone
(`ClientContextWrapper::GetContext()` in vendored `src/duckdb/src/main/client_context_wrapper.cpp`).
The other shape, a result that keeps the instance reachable through the driver registry so that `duckdb(path)` reuses it,
was weighed and declined: it keeps the file locked against every other process, and the session's state alive,
for as long as a forgotten result lives, after a `dbDisconnect()` that promised to free both.

**A context is cheap, so cost is not the argument.**
16 µs to open and close, and 8 KB resident, 14 KB once it has run a statement,
against 255 µs for `SELECT 1` and 5 ms for `dbConnect()` itself (measured).

**Parallelism is the engine's, per context.**
Queries on different contexts run at once; queries on one context queue on its lock.
What that buys is bounded by the query:
one that leaves cores idle finishes beside a twin in the time of one,
one that uses every core gains nothing,
and a stream parked on one context does not block another (measured).
From R only one engine call runs at a time,
so a second query executes in parallel only once a producer thread
([`plan/PLAN-streaming-thread.md`](/plan/PLAN-streaming-thread.md)) runs it off R's thread,
and only if the two results do not share a context.

**A context per result is refused as the mapping, and kept as a plan.**
Wrapping a context of its own in every result would make each result a session of its own:
it would not see the connection's open transaction, its temp tables, its registered frames, its `SET`s or its `PREPARE`s,
so `dbWithTransaction()`, `dbWriteTable(temporary = TRUE)` and dbplyr's `compute()` would stop meaning what DBI says.
Go's `database/sql` is the standing example of that mapping, a pooled connection per open `Rows`,
and its documented trap is session state landing on a connection the next statement does not get,
which `Tx` and `Conn` exist to pin (<https://pkg.go.dev/database/sql#DB.Conn>).
The engine's other clients settle it the same way:
Python's `cursor()` is a duplicate of the connection, and its multithreading guide has each thread make one
(<https://duckdb.org/docs/stable/guides/python/multiple_threads>),
while the engine's own ADBC driver keeps one context and materializes an open stream when another statement runs
([`usage/memory/reading/`](/handbook/usage/memory/reading/README.md)).
What the idea is good for, an open stream that leaves its connection usable and, with a producer thread, results that produce at once,
is kept in the explicit form DBI already defines:
`dbConnect(con)` cloning the connection, with its session settings, default database and registered frames,
and a result that owns such a clone when asked to by argument, which is also what a pumped result needs.
A private context taken by default behind guards was drafted and refused;
[`plan/PLAN-connection-clone.md`](/plan/PLAN-connection-clone.md) carries the design and the reasons.

*To deepen: state what the driver-side mapping, a driver that owns its instance, costs against a factory driver
over the engine's own instance cache, which [#2644](https://github.com/duckdb/duckdb-r/pull/2644) would settle.*
