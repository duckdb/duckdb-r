# Storage locations

Where the package and the embedded engine write on disk —
the extension cache, the secret store, spill, and the database file —
and how to move or share the store.
`?duckdb_storage` ([`R/storage.R`](/R/storage.R)) owns this topic:
it ships in the package, documents every kind of state and the full
resolution order, and `duckdb_storage_status()` reports where each
kind resolves right now, side-effect-free.

The shape, briefly:
extensions and secrets share one *home* root,
resolved afresh for every new database instance —
`shared_home` / `home` arguments first,
then the `duckdb.home` option, then `DUCKDB_R_HOME`,
then `~/.duckdb` if it exists,
then an interactive one-time offer to create it,
else a per-session temporary directory.
`~/.duckdb` is resolved the way the engine resolves it,
so the store is genuinely shared with the DuckDB CLI and
the other clients.
Nothing is written into the package library,
and no logs or profiling output are written unless configured.
The design record is
[`plan/PLAN-storage-locations.md`](/plan/PLAN-storage-locations.md).
