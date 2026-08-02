# Fast paths

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: linking a prebuilt libduckdb (`DUCKDB_R_USE_SYSTEM_LIB`)
for seconds-long builds and test loops.

Today:

* [`AGENTS.md`](../../../AGENTS.md) — "Fast build with system libduckdb"
* [`scripts/install-libduckdb.sh`](../../../scripts/install-libduckdb.sh)

To write this leaf:

* absorb: `AGENTS.md` §§ "Fast build with system libduckdb" and
  "Testing with prebuilt DuckDB"; state the commit-match guard and
  the rule that engine configuration is never verified on the fast
  path (see `usage/extensions/`)
* drain: #22
