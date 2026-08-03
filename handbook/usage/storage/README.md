# Storage locations

Where the package and the embedded engine write on disk —
the extension cache, the secret store, spill, and the database file —
and how to move or share the store.
`?duckdb_storage` ([`R/storage.R`](/R/storage.R)) owns this topic:
it ships in the package, documents every kind of state and the full
resolution order, and `duckdb_storage_status()` reports where each
kind resolves right now, side-effect-free.

Two facts a reader must not miss, and the reference page has the rest:
**nothing is written into the package library**, ever,
and where `~/.duckdb` exists it is resolved the way the engine
resolves it — so the extension cache and the secret store are
genuinely shared with the DuckDB CLI and the other clients,
not a private copy.
The home root is resolved afresh for every new database instance.

*To deepen: absorb the resolution order from `?duckdb_storage`.*
