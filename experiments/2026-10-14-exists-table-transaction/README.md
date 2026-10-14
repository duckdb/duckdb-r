# `dbExistsTable()` inside a transaction

*What it measures:* whether `dbExistsTable()` leaves an open transaction usable,
and how six ways of asking answer eighteen names inside one:
the probe the package sent before [#2892](https://github.com/duckdb/duckdb-r/issues/2892),
that probe with the transaction's invalidation policy relaxed while it runs,
the probe on a second connection to the same instance,
a lookup in `duckdb_tables()` and `duckdb_views()`,
the lookup followed by the second connection for what it lacks,
and whatever the package under test sends.
Also what each answers in a transaction that has already failed,
what relaxing the policy does under `lock_configuration`,
what an instance created with DuckDB 1.x's policy does with a user's own failing query,
and what each costs per call.

*When and on what:* 2026-10-14, Linux x86_64 with 4 cores, Ubuntu 24.04, R 4.5.3, DBI 1.3.0, dplyr 1.2.1, dbplyr 2.6.0.
Four builds, each rendered from [`candidates.R`](candidates.R) by [`scripts/render-reprex.R`](/scripts/render-reprex.R):

* [`v1.5.6.md`](v1.5.6.md): duckdb 1.5.6, the CRAN binary.
* [`v1.5.6-fix.md`](v1.5.6-fix.md): duckdb 1.5.6.9004, the branch that fixes #2892,
  a fast-path build linking the release `libduckdb` of DuckDB 1.5.6 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
* [`v2.0.md`](v2.0.md): duckdb.2.0.dev 1.99.99.9000.2146 from r-universe, built from source, engine `v2.0.0-dev87878`.
* [`v2.0-fix.md`](v2.0-fix.md): the same source with the branch's `R/dbExistsTable__duckdb_connection_ANY.R`,
  whose session info still names r-universe as the source it came from.

The branch builds are bb30a06 of https://github.com/duckdb/duckdb-r/pull/2893,
which asked `duckdb_settings()` whether the engine has the policy where the pull request now compares engine versions;
the statements each call sends are the same.
The session info names the scratch library that held a branch build as `<branch build library>`.

*What it supports:* the transaction entry in [`usage/statements/`](/handbook/usage/statements/README.md).

## The failure

On 2.0, `dbWriteTable()` of a new table inside `dbBegin()` fails with "Current transaction is aborted (please ROLLBACK)",
and so do `duckdb_read_csv()` and dplyr's `copy_to()`, both of which open a transaction of their own.
On 1.5.6 all three succeed, and with the branch they succeed on both engines.
The probe, `DESCRIBE SELECT * FROM <name> WHERE FALSE`, raises a catalog error for a missing name,
and 2.0's `default_transaction_invalidation_policy`, `ALL_ERRORS_INVALIDATE_TRANSACTION`, lets that error abort the transaction,
where 1.x exempts catalog, binder and parser errors.

## Ways of asking

From the matrix in each record:

* **The probe** answers every name right, a Parquet path through a replacement scan included,
  and on 2.0 every miss aborts the transaction.
* **The probe with the policy relaxed** answers every name right and aborts nothing on a miss.
  It sets `current_transaction_invalidation_policy` to `SYNTACTIC_ERRORS_DO_NOT_INVALIDATE` and back to `STANDARD_POLICY`,
  which resolves to the default, so a misspelt query afterwards still aborts the transaction on 2.0.
  On 1.5.6 it sends the probe alone, because 1.5.6 does not have that policy.
* **A second connection** misses a temporary table, a registered data frame and a table the transaction created, three names of eighteen.
* **The catalog lookup** misses the Parquet path, which `tbl()` relies on finding,
  and its search path is an approximation.
* **The lookup, then the second connection** answers every name right and is the only way that aborts nothing for a missing file.
  A miss costs the lookup, a connection and the probe.
* **The branch** answers what the probe answers, on both engines, and aborts nothing on 2.0 for a missing table.

A path to a file that is not there aborts the transaction on both engines whichever way the probe is sent,
because no policy exempts an IO error.
On 2.0 the relaxed probe as written in the script then fails to restore the policy and raises;
the branch ignores that failure, and answers `FALSE`.

## A transaction that has already failed

Asked about a table that exists, the probe answers `FALSE` on both engines, and the second connection `TRUE`.
The branch raises "Current transaction is aborted", as the catalog lookup does.

## A locked configuration

Under `lock_configuration`, 2.0 refuses the `SET` with "Cannot change configuration option",
and the refusal aborts the transaction even when the table exists.
The engine's own handling of a multi-statement string in a transaction still runs,
though it sets the same option (`AddStatements()` in `statement_preprocessor.cpp`).
The branch reads `lock_configuration` before relaxing and sends the probe alone when it is set,
so it finds an existing table and leaves the transaction usable, and a missing one aborts the transaction as it did before.

## An instance with 1.x's policy

1.5.6 refuses `default_transaction_invalidation_policy` when the driver is created, "The following options were not recognized".
On 2.0, `SYNTACTIC_ERRORS_DO_NOT_INVALIDATE` lets `dbWriteTable()` succeed in a transaction,
and the user's own query on a missing table no longer aborts it either.

## Cost

Milliseconds per call, the mean of 200, for a table that exists and one that does not:

* On 2.0, the branch costs about 10.6 for a hit where the probe costs 3.1,
  for the three statements it adds: reading the lock, and setting the policy twice.
  On 1.5.6 it adds none, and the two cost the same within a millisecond.
* A miss costs 38 to 58 for every way that raises an error, and 3.5 to 8 for the catalog lookup, which raises none.
* A single run each, so differences of a millisecond or two are noise.

## Replicating

From this directory, with the build under test first in the library path,
`DUCKDB_PKG=duckdb Rscript ../../scripts/render-reprex.R candidates.R v1.5.6`,
and `DUCKDB_PKG=duckdb.2.0.dev` for the 2.0 flavor,
which `install.packages("duckdb.2.0.dev", repos = "https://duckdb.r-universe.dev")` builds from source on Linux.
The script needs dplyr and dbplyr, no network, and does not wait.
