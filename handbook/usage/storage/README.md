# Storage locations

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](/handbook/meta/handbook/);
the last section holds this leaf's parameters.*

Scope: where extensions and secrets live on disk, and how to move them.

Today:

* `?duckdb_storage` ([`R/storage.R`](/R/storage.R)),
  backed by [`plan/PLAN-storage-locations.md`](/plan/PLAN-storage-locations.md)

To write this leaf:

* nothing to absorb: `?duckdb_storage` (`R/storage.R`) owns the topic;
  keep this pointer in step with it
* add the backreference to this leaf in `R/storage.R`'s roxygen —
  the `.Rd` is generated, the source carries it
