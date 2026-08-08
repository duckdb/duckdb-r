# Temporary storage across duckdb-r versions

What happens when a query outgrows `memory_limit`,
for the two common connection idioms,
across four builds of the package.
Run 2026-08-07/08 on Ubuntu 24.04 (x86_64, 4 cores, 16 GB RAM,
R 4.5.3), each run rendered with reprex
(`reprex::reprex(input = <script>, venue = "gh", session_info = TRUE)`);
supports [`usage/memory/`](/handbook/usage/memory/README.md).
Gathered for
[#2562](https://github.com/duckdb/duckdb-r/pull/2562),
which reviews
[#1604](https://github.com/duckdb/duckdb-r/issues/1604);
the four runs quoted in that PR's description are the
`main-1fc15f5` and `branch-c947f6f` files here, verbatim.

The scripts:

* [`disk-1604.R`](disk-1604.R) —
  the #1604 report: an on-disk database opened as
  `dbConnect(duckdb(), dbdir = ...)`,
  the reported settings and data shape
  (12,880,502 rows × 5 integer columns, ~257 MB,
  `memory_limit = '3GB'`),
  then two harder variants:
  the same append under a 200 MB limit,
  and a ~460 MB sort under that limit.
* [`memory.R`](memory.R) —
  the default in-memory connection:
  where `temp_directory` points,
  a ~460 MB sort under a 300 MB limit,
  and whether the spill directory appears at first spill
  and disappears at `duckdb_shutdown()`.

The builds, one rendered markdown per script per build:

* `duckdb-1.3.2` —
  the version #1604 was reported on,
  installed as a binary from the Posit Package Manager snapshot
  `cran/__linux__/noble/2025-09-01`.
* `duckdb-1.5.5-cran` —
  the CRAN release current on the run date,
  installed from Posit Package Manager.
* `main-1fc15f5` —
  the repository's `main` before the fix, built from source.
* `branch-c947f6f` —
  [#2562](https://github.com/duckdb/duckdb-r/pull/2562)'s fix,
  built from source.

What was measured:

* **1.3.2** left the engine's defaults untouched,
  and spilling worked everywhere:
  the on-disk database spilled to `db.duckdb.tmp`
  and the in-memory database to `.tmp`
  in the current working directory.
  The failure reported in #1604 did not reproduce on this hardware —
  the reported append passed at the reported 3 GB limit,
  and again at 200 MB, less than the data itself.
* **1.5.5 (CRAN) and `main`** redirect both idioms at
  `<tempdir()>/duckdb/temp`, which nothing creates,
  so the first actual spill fails with
  `IO Error: Failed to create directory` —
  the sort step in both scripts —
  and the on-disk database never uses `<dbdir>.tmp`.
  The regression shipped: the release current on the run date
  is affected.
* **branch c947f6f** restores the CLI's semantics:
  the on-disk database keeps the engine's own `<dbdir>.tmp`,
  the in-memory database gets a per-instance directory
  below `tempdir()`,
  created at first spill and removed at shutdown.
  Every step passes.

To refresh: install the build under test,
render both scripts with reprex as above,
and name the output after the build.
