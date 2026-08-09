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

The departures from that baseline are what this leaf owns.
One so far:

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

*To deepen: state the remaining departures — what a transaction does to
an in-flight result, what `dbWriteTable()` does about types it cannot
round-trip, and which identifiers need quoting the engine would
otherwise fold — each with the test that pins it.*
