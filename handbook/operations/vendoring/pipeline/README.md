# The pipeline

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: `vendor-one.sh`, `rconfigure.py`, the patch stack,
and the `DESCRIPTION` merge driver that keeps version counters
mergeable across vendor commits.

Today:

* [`scripts/VENDORING.md`](../../../../scripts/VENDORING.md)
* [`scripts/merge-version.sh`](../../../../scripts/merge-version.sh)
* a generated `scripts/` directory index is proposed in
  [#2447](https://github.com/duckdb/duckdb-r/pull/2447)

To write this leaf:

* absorb: the mechanics and script inventory from
  `scripts/VENDORING.md`; own `rconfigure.py` (regenerates
  `src/duckdb/`, `src/include/sources.mk`, `R/version.R`),
  the patch-stack lifecycle, `merge-version.sh`,
  and `setup-git.sh` which registers the driver
