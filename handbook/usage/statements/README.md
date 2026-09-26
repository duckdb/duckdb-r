# Statements

Running SQL and changing what is in the database:
statements and their results, transactions, tables, and quoting.
What a value becomes on the way across is
[`types/`](/handbook/usage/types/README.md);
the connection the statement runs on is
[`connections/`](/handbook/usage/connections/README.md)'s.

DBI's own reference pages define what each generic promises,
and this package implements them one file per method,
named for the generic and the signature —
so `R/` is the list
([`architecture/r-layer/conventions/`](/handbook/architecture/r-layer/conventions/README.md)).
A reader asking "does `dbAppendTable()` work here" answers it by
finding the file, not by consulting an inventory that can go stale.

The departures from that baseline are what this leaf owns:

* `dbSendQuery()` does not defer:
  a statement executes at `dbSendQuery()` time —
  at `dbBind()` time when it has parameters —
  and the full result is fetched into R before `dbFetch()` is ever
  called, so `dbFetch(n = )` limits what is returned, not what is held
  ([#1997](https://github.com/duckdb/duckdb-r/issues/1997);
  the memory consequences and the streaming work that will change
  this are [`memory/reading/`](/handbook/usage/memory/reading/README.md)'s).
* In a multi-statement string,
  everything before the final statement executes at prepare time,
  and `?` placeholders bind only in the last statement
  ([#179](https://github.com/duckdb/duckdb-r/issues/179)).
  DBI's `immediate = TRUE` is no way around this and no way to opt out:
  the driver has no unprepared path — every route reaches
  [`src/statement.cpp`](/src/statement.cpp)'s prepare, which is where the
  earlier statements run — and the argument lands in `...` unread,
  which it will stop doing
  ([#2498](https://github.com/duckdb/duckdb-r/issues/2498)).
  One statement per call is the way to keep execution where the
  caller put it.
* A streaming result is ended by the next statement on its connection,
  whichever helper runs it, `dbExistsTable()` and `dbAppendTable()` included,
  and it then reads as drained rather than failing;
  a second connection to the same instance is the way to keep one open while
  the first works, until
  [`plan/PLAN-result-contexts.md`](/plan/PLAN-result-contexts.md) lands.
  The object each DBI class wraps, and why the stream and the connection
  share a session, is
  [`architecture/glue/objects/`](/handbook/architecture/glue/objects/README.md)'s.

**A failing statement raises `duckdb_error`, and the classification is a field.**
The engine's exception type, whatever it attached as extra info, the operation that failed,
and its own unformatted wording ride on the condition as
`error_type`, `extra_info`, `context` and `raw_message` —
so a caller telling a constraint violation from an I/O failure reads a field
rather than matching on the message
([#2711](https://github.com/duckdb/duckdb-r/issues/2711), `?duckdb_error`).
The fields survive the rethrow that points the error at the user's call
([`architecture/r-layer/conventions/`](/handbook/architecture/r-layer/conventions/README.md)),
and the no-rlang fallback carries the same ones on a plainer message.

**The message stays prose and the rest stays data.**
`error_type` is the one field also rendered, because it is short and bounded;
`extra_info` is not, because the engine puts a resolved stack trace and lists of candidate names in there.
So a field absent from the message is not a field absent from the condition —
and a field the engine did not supply is absent from the condition too, reading as `NULL`,
which is why classification code needs a fallback branch.
The engine, not this package, owns which types and which `extra_info` keys exist,
so both grow without a release here.

*To deepen: state the remaining departures, what `dbWriteTable()` does
about types it cannot round-trip and which identifiers need quoting the
engine would otherwise fold, each with the test that pins it.*
