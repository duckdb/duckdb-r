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
([`architecture/r-layer/`](/handbook/architecture/r-layer/README.md)).
A reader asking "does `dbAppendTable()` work here" answers it by
finding the file, not by consulting an inventory that can go stale.

What this leaf will own is where DuckDB departs from the DBI baseline —
what a transaction does to an in-flight result, what `dbWriteTable()`
does about types it cannot round-trip, and which identifiers need
quoting the engine would otherwise fold.

*To deepen: state the departures from the DBI baseline for
transactions, table writes, and quoting, each with the test that
pins it.*
