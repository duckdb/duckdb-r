# Storage locations

Where the package puts downloaded extensions and persisted secrets on disk,
how that location is resolved, and how to move it.

The topic's home is the `?duckdb_storage` reference page,
which ships in the package tarball
and is where a user meets it from R.
It catalogs the kinds of state DuckDB writes to the file system,
gives the precedence order that resolves the extension and secret home,
names `duckdb_storage_status()` as the way to see where each one lands today,
and documents the message that announces an auto-chosen location.
That page is written as roxygen in [`/R/storage.R`](/R/storage.R);
`man/duckdb_storage.Rd` is generated from it and never edited by hand.

The intent behind the policy — why it looks the way it does,
and which parts of it are still unimplemented —
is carried by
[`/plan/PLAN-storage-locations.md`](/plan/PLAN-storage-locations.md).
Where the plan and the reference page disagree,
the reference page is the one describing today's behavior.

Three neighboring topics are deliberately not covered here.
Which extensions ship and where an extension is installed *from*
belong to [`/handbook/usage/extensions/`](/handbook/usage/extensions/).
Temporary and spill files, and what fills them,
belong to [`/handbook/usage/memory/`](/handbook/usage/memory/).
The database file itself is chosen by the caller through `dbdir`,
which belongs to
[`/handbook/usage/connections/`](/handbook/usage/connections/).
