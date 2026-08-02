# `vendoring/`

How upstream DuckDB becomes `src/duckdb/`, one commit at a time.

**The copy is advanced, never edited.**
Every change to the vendored tree arrives as a vendor commit
or as a patch with a recorded home,
so the copy's history stays an audit trail of upstream's.

* [`model/`](model/) — why vendor, and the invariants a `-dev` branch keeps
* [`pipeline/`](pipeline/) — the scripts that do it
* [`series-loop/`](series-loop/) — the routine, its playbooks, its schedule
* [`troubleshooting/`](troubleshooting/) — when a run is red
