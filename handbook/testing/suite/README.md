# The suite

How the package's own tests are laid out under `tests/`,
and how to run them —
the whole suite, one file, or the edit-and-test loop.

## Layout

`tests/testthat.R` is the entry point `R CMD check` runs.
It attaches testthat and the package,
decides whether the suite runs at all,
and hands the run to `test_check()`.
That decision is the CRAN guard and belongs to
[`testing/guards/`](/handbook/testing/guards/README.md);
nothing else lives in that file.

Every test is a file directly under `tests/testthat/` —
close to seventy of them, flat, named `test-<topic>.R`.
A name is one of three things:

* the name of the `R/` file it covers
  (`test-sql.R`, `test-relational.R`,
  `test-backend-dbplyr__duckdb_connection.R`);
* a DuckDB type or feature the R layer has to round-trip
  (`test-map.R`, `test-struct.R`, `test-interval.R`, `test-timezone.R`);
* a shared prefix, where one area is covered in several passes
  (`test-storage-*.R`, `test-rfuns-*.R`).

There are no subdirectories:
the file name is the unit of selection, and the only one.

Beside the tests, the same directory holds
`helper-*.R` and `setup.R` (below),
`data/` — three Parquet fixtures,
read either through `test_path("data/userdata1.parquet")`
or, since testthat runs with `tests/testthat/` as the working directory,
by the bare relative path inside SQL
(`parquet_scan('data/userdata1.parquet')`) —
and `_snaps/`, the recorded snapshot output,
one `.md` per test file that snapshots, owned by
[`testing/snapshots/`](/handbook/testing/snapshots/README.md).

## Helpers and fixtures

testthat sources every `helper-*.R` before the first test,
then `setup.R` once for the run.

* `helper-DBItest.R` creates the driver `drv`
  on a temporary `.duckdb` file,
  with a finalizer that unlinks the file,
  and — when DBItest is installed —
  registers the context `test-DBItest.R` runs from:
  `dbitest_version` `"1.8.3"`, `?` placeholders,
  no temporary tables, explicit `CAST` for timestamps, dates, times and blobs.
  The `make_context()` call has to stay in the helper;
  moved into the test file, `DBItest::test_some()` stops working.
* `helper-arrow.R` loads arrow first, when `NOT_CRAN` is `true`.
  Loading it after the relational tests have run
  hits a garbage-collection problem
  in how arrow releases its resources.
* `helper-skip.R` holds the three skip predicates the tests share:
  `skip_on_dev_version()` for anything that needs a released version —
  a development snapshot is not `x.y.z`
  and has no signed extensions on `extensions.duckdb.org` —
  `skip_on_flavor()` for anything that depends on another package
  hard-coding the mainline `duckdb` name — arrow's DuckDB integration
  is the case that forces it —
  and `skip_on_cran_except_r_universe()`.
* `helper-snapshot.R` holds `transform_package_name()`,
  which rewrites the running package's name to the mainline one
  at capture time so one recorded snapshot serves every flavor.
* `helper-storage.R` holds `session_home_path()`,
  the expected storage path for the running package name.

Fixtures are not in the helpers.
`local_con()` — a connection that disconnects itself
when the calling test exits — is package code,
`R/test-fixtures.R`, unexported, and has a test of its own.
The suite runs with the package's namespace loaded,
so internal functions are callable from a test unqualified:
`default_conn()`, `sql_exec()`, `extensions_supported()`,
`get_duckdb_version()`, `get_package_name()`.
Ask for the package name rather than writing it,
for the reason [`branches/flavors/`](/handbook/branches/flavors/README.md)
gives.

`setup.R` is a single line:
it points the `arrow_duck_con` option at `default_conn()`
for the length of the run,
so arrow's DuckDB integration reuses the suite's connection
instead of opening one of its own.

## Running

The whole suite, about 45 seconds:

```sh
R -q -e 'testthat::test_local()'
```

`test_local()` runs `tests/testthat/` directly.
It never goes through `tests/testthat.R`,
so the CRAN guard in that file has no say over a local run —
only over `R CMD check`.

One file, by the name with `test-` and `.R` stripped off:

```sh
R -q -e 'testthat::test_local(filter = "^array$")'
```

`filter` is a regular expression, not a file name.
Anchor it, or it selects every file whose name contains the string:
unanchored, `filter = "storage"` runs all eight `test-storage-*.R` files,
which is occasionally what you want.

## The edit-test loop

`test_local()` loads the package the way `pkgload::load_all()` does,
which means it honours `DUCKDB_R_USE_SYSTEM_LIB`:
with a prebuilt libduckdb linked,
only the glue in `src/` is compiled — fifteen files —
and a no-op load takes a second,
a load after one edited glue file about four.
Without it, the first build compiles the vendored engine:
ten to fifteen minutes.
That is the difference between a loop and a wait,
so set it up once —
[`build/fast-paths/`](/handbook/build/fast-paths/README.md)
owns the mechanism, the version-match guard,
and when to fall back to a source build.

```sh
export DUCKDB_R_USE_SYSTEM_LIB=1
R -q -e 'pkgload::load_all()'
R -q -e 'testthat::test_local(filter = "^array$")'
```

The loop's limit is the same as the fast path's:
a run under `DUCKDB_R_USE_SYSTEM_LIB` proves the glue,
not the engine it was built with.
Anything a test asserts about engine configuration
has to be confirmed against a vendored build.

## Manual checks

A green suite is not the same as a working package.
After a change to the glue, drive a full scenario by hand —
connect, create, insert, query, disconnect:

```r
library(duckdb)
con <- dbConnect(duckdb())
dbExecute(con, "CREATE TABLE test (id INTEGER, name VARCHAR)")
dbExecute(con, "INSERT INTO test VALUES (1, 'Alice'), (2, 'Bob')")
dbGetQuery(con, "SELECT * FROM test ORDER BY id")
dbDisconnect(con, shutdown = TRUE)
```

A reproduction script at the repository root runs with `R -q -f bug.R`.
Nothing ignores such a file —
not `.gitignore`, not `.Rbuildignore` —
so keep it out of the commit.
Once it reproduces a bug you then fix,
it has already done the work of a regression test:
turn it into one under `tests/testthat/`.
A fix without a test is unfinished.

## Boundaries

The suite is what runs; it is not where the running is decided.
Which platforms and R versions execute it, and what the result gates,
is [`operations/ci/`](/handbook/operations/ci/README.md)'s.
Accepting a changed snapshot is
[`testing/snapshots/`](/handbook/testing/snapshots/README.md)'s,
the CRAN and flavor guards are
[`testing/guards/`](/handbook/testing/guards/README.md)'s,
and checking the packages that depend on this one before a release is
[`testing/revdep/`](/handbook/testing/revdep/README.md)'s.

The suite is not green on every platform it is run on.
`test-duckdb-extensions.R` asserts that `INSTALL icu` succeeds
wherever extensions are supported at all,
and on Windows ARM64 it does not:
DuckDB publishes no prebuilt extensions for arm64 MinGW,
so the r-universe build for that platform fails there
([#2425](https://github.com/duckdb/duckdb-r/issues/2425)).
There is no platform skip for it today.
The fix is in the test — a skip, or an extension that already uses
DuckDB's C extension API — and the issue stays open until one lands.
