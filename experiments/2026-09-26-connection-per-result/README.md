# One engine context per result, or one per connection

*What it measures:* what the engine's session, a `ClientContext`, scopes,
and what a second context to the same instance therefore does not see;
what a statement on a connection does to a streaming result open on that connection, and to one open on another;
what a context costs to open, to keep and to use for the first time;
whether a result outlives the connection it was sent on, and what that keeps open;
and what two contexts buy in wall time that one cannot.
Together they answer whether a DBI result should wrap a context of its own instead of sharing its connection's.

*When and on what:* 2026-09-26, Linux x86_64, 4 cores, 15 GB, R 4.5.3.
The package built from this tree at `bf16009` on the fast path
([`build/fast-paths/`](/handbook/build/fast-paths/README.md))
against the released `libduckdb` v1.5.5 (upstream commit `d8cdaa33fd`) that
[`scripts/install-libduckdb.sh`](/scripts/install-libduckdb.sh) installs,
with nanoarrow 0.9.0, bench 1.1.4 and callr 3.8.0 beside it.
The C++ case compiles against the vendored headers and links that same library.
Method: [`run.sh`](run.sh), one script per question, output in [`transcript.txt`](transcript.txt);
the one case run again after #2775 is named where it is read.

*What it supports:* [`architecture/glue/objects/`](/handbook/architecture/glue/objects/README.md),
which states the mapping and what follows from it,
and the problem statement of [`plan/PLAN-result-contexts.md`](/plan/PLAN-result-contexts.md).

## How it asks

Five cases, each a file of its own:

* [`interleave.R`](interleave.R):
  a result is opened on a connection, one batch is read, one other call is made on the same connection,
  and the next batch is the verdict.
  Once per route, the materialized `dbSendQuery()` and the streaming `dbSendQueryArrow()`,
  and per interfering call, from `dbQuoteIdentifier()`, which runs no statement, to a second stream.
  Then the DBI chunked loop, reading a stream and appending each batch through the same connection and through a second one,
  and two streams on two connections read alternately.
* [`session-state.R`](session-state.R):
  two connections to one file database; each kind of session state is set on the first and read from the second.
  Then a stream is opened on the second while `INSERT`, `CHECKPOINT`, `DROP TABLE` and `FORCE CHECKPOINT` run on the first,
  the last in a child process under a 20-second budget, because it is expected not to return.
* [`context-cost.R`](context-cost.R):
  `bench::mark()` over a bare engine context opened and closed through the glue's own entry points,
  over `dbConnect()` and `dbDisconnect()`, over `SELECT 1` on a warm and on a fresh context, and over `duckdb_register()`;
  then the resident memory 5000 open contexts add, before and after each ran a statement, each batch in a process of its own.
* [`result-lifetime.R`](result-lifetime.R):
  a result is sent, its connection closed, and the result fetched, re-bound and re-executed;
  then the same file is opened again from another process and from this one, and what each open meets is recorded.
* [`concurrent.cpp`](concurrent.cpp):
  two client threads run one query on one context and on two, against a sequential baseline,
  for a query that runs on one thread and for one that uses every thread, at `threads = 4` and at `threads = 1`;
  then a stream is opened on one context and parked after its first batch while the other context runs a query.

## What it found

**A context is the session, and none of it crosses to a second context.**
A temp table, a `duckdb_register()`ed frame, which is a temporary view, a `PREPARE`d statement,
a session `SET` and the `USE`d default database set on the first connection are absent from the second,
and an `INSERT` inside an open transaction is invisible there until it commits.
What does cross is what the instance owns: committed data, `ATTACH`, a global `SET`.

**One live stream per connection, and it ends without a word.**
A materialized result survives any statement in between, because its rows already live in R.
A streaming result survives only a call that runs no statement:
`dbExistsTable()`, `dbListTables()`, `dbListFields()`, `duckdb_register()`, `dbAppendTable()`, `dbBegin()`,
a second stream and a materialized `dbSendQuery()` each end it.
And an ended stream does not fail: the next `dbFetchArrowChunk()` returns zero rows and `dbHasCompleted()` reads `TRUE`.
The engine's Arrow stream wrapper reports a closed stream as the end of the stream
(`MyStreamGetNext()` in vendored `src/duckdb/src/common/arrow/arrow_wrapper.cpp`),
where the C++ `Fetch()` on the same stream raises `Attempting to execute an unsuccessful or closed pending query result`.
So the DBI chunked loop that appends each batch through the same connection stops after 10,000 of 100,000 rows and reports success.
With the writes on a second connection to the same instance it completes, and two streams on two connections read alternately.
[#2775](https://github.com/duckdb/duckdb-r/pull/2775), merged after this run, wraps the engine's stream in the glue
and reports the ended result as an error instead;
[`interleave.R`](interleave.R) run again on a tree carrying it, in [`transcript-after-2775.txt`](transcript-after-2775.txt),
fails every ended case with `The query result was invalidated by another statement on its connection before it was read to the end`,
and the loop through one connection stops at its second batch with that error rather than with success.
The stream still ends; only what reading it says has changed.

**A stream on another context is a snapshot, and one statement waits on it forever.**
`INSERT`, `CHECKPOINT` and `DROP TABLE` on the first connection all run while the second's stream is parked, and the stream yields on.
`FORCE CHECKPOINT` after that sequence does not return within 20 seconds:
it waits for the stream's transaction, and the stream is parked until the thread that issued the checkpoint fetches.

**A context is cheap.**
16 µs to open and close, against 255 µs for `SELECT 1`
and 5 ms for `dbConnect()` with `dbDisconnect()`, 1.6 ms of which is `check_tz()` listing `OlsonNames()`, plus a keywords query;
a fresh context's first statement costs within noise of a warm one's.
5000 open contexts add 40 MB resident, 8 KB each, 14 KB once each has run a statement.
`duckdb_register()` costs 1 ms at the R level, which is what replaying one registration onto a new context would cost as the code stands.

**A result outlives its connection, and holds the instance with it.**
After `dbDisconnect()` the result is valid, its copy fetches, and a `dbBind()` re-executes:
the prepared statement holds the context, and the context holds the instance.
The driver reports no instance, another process is refused the file (`Conflicting lock is held in ... R (PID ...)`),
and this process opens it again, since a POSIX record lock is held per process and the driver registry has forgotten the instance.
A table created through the second instance is not seen by the first,
so the file has two instances in one process until the result is cleared.

**Two contexts run at once, one context serializes, and what that buys depends on the query.**

| query | `threads` | one | two, sequential | two at once, two contexts | two at once, one context |
|---|---|---|---|---|---|
| runs on one thread | 4 | 2.90 s | 5.68 s | 2.99 s | 5.70 s |
| runs on one thread | 1 | 2.90 s | 5.88 s | 2.93 s | 5.85 s |
| uses every thread | 4 | 0.15 s | 0.28 s | 0.30 s | 0.30 s |
| uses every thread | 1 | 0.41 s | 0.96 s | 0.48 s | 0.84 s |

Two contexts overlap where a query leaves cores idle:
`sum()` over `range()` runs on one thread, and a table scan at `threads = 1` runs on the calling thread,
so either finishes beside a twin in the time of one.
A query that already uses every core gains nothing from a twin.
One context serializes its callers whatever the query, on its lock.
A stream parked on one context does not block a query on another, and yields on afterwards.

## Replicating

```sh
scripts/install-libduckdb.sh
DUCKDB_R_USE_SYSTEM_LIB=1 R CMD INSTALL . --no-byte-compile
R -q -e 'install.packages(c("nanoarrow", "bench", "callr"))'
experiments/2026-09-26-connection-per-result/run.sh
```

`ROWS` and `TABLE_ROWS` size the C++ case's two queries (400,000,000 and 150,000,000 by default),
and `--lib DIR` points it at another build of the same commit.
The R scripts run against whichever `duckdb` is installed, so the package has to come from this tree.
