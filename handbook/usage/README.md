# `usage/`

Using the package from R:
connect, query, and configure DuckDB.
The area divides by what the reader is trying to do,
and every leaf is about the R package's behaviour.
The SQL dialect, the storage format and the engine's own tuning
are DuckDB's to document;
this area defers to that documentation instead of restating it,
and a leaf here is worth writing where the two sides meet —
where R's idea of a type, a lifetime or a file location
has to be reconciled with the engine's.

**The package decides as little as it can, and says so when it must.**
A default that commits the user to something —
a location on disk, a download, a silent conversion —
is announced, reversible, or refused outright, never taken quietly;
the leaves say which of the three, because they do not all choose the same one.
Making the choice explicit is then the interface,
and it is what turns the announcement off.

* [`installation/`](installation/) — CRAN, r-universe, and the flavors
* [`connections/`](connections/) — `dbConnect()`, instances, shutdown
* [`types/`](types/) — the R ↔ DuckDB type mapping
* [`extensions/`](extensions/) — what ships, what installs
* [`memory/`](memory/) — limits, spill, streaming
* [`data-import/`](data-import/) — CSV and Parquet ingestion
* [`storage/`](storage/) — where extensions and secrets live
* [`integrations/`](integrations/) — dbplyr and Arrow
