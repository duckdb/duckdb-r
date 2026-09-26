# Integrations

The routes into DuckDB beside plain SQL:
dplyr pipelines by two different mechanisms, Arrow interchange,
ADBC, and the frame libraries that take none of them.
What a value becomes across the boundary is
[`types/`](/handbook/usage/types/README.md).

## dbplyr

`?backend-duckdb`
([`R/backend-dbplyr__duckdb_connection.R`](/R/backend-dbplyr__duckdb_connection.R))
is the backend reference.
dbplyr and dplyr are `Suggests`;
the methods register at load time, edition 2.
dbplyr is floored at 2.6.0,
the first release to export `sql_glue()` —
`n_distinct()` renders through it,
having previously reached the unexported `glue_sql2()`
that a dbplyr release was free to drop
([#1982](https://github.com/duckdb/duckdb-r/issues/1982)).

**A `Suggests` floor is advisory, so the floor also warns.**
Nothing stops an older dbplyr from being loaded beside this package,
and what it produces then is a missing-function error
from inside a translation, naming neither package nor remedy.
So `warn_if_dbplyr_too_old()` ([`R/dbplyr-version.R`](/R/dbplyr-version.R))
says it plainly instead, from `.onAttach()` when dbplyr is already loaded
and from a `packageEvent("dbplyr", "onLoad")` hook when it arrives later.
It reads the version of the *loaded* namespace, not the library copy:
those differ for the rest of a session after `install.packages("dbplyr")`,
and it is the loaded one whose code the backend will reach —
which is why the warning says to restart R.
The check never loads dbplyr to perform it, so a session that
does not use the backend pays nothing and hears nothing —
which is also what keeps `R CMD check` quiet,
since it reads `R CMD INSTALL`'s output for warnings
and a `Suggests` package is never loaded there
([`2026-08-09-dbplyr-version-warning/`](/experiments/2026-08-09-dbplyr-version-warning/README.md)).
Coercions translate to `TRY_CAST()`,
so a value that will not convert yields `NULL` rather than failing
the query
([#2230](https://github.com/duckdb/duckdb-r/issues/2230)).
`tbl_file()` and `tbl_function()` turn files and table functions
into lazy tables;
`simulate_duckdb()` renders SQL without a connection.

The backend translates *expressions*, not verbs,
and literals are escaped by dbplyr —
the boundaries users keep hitting:

* `distinct(.keep_all = TRUE)` is a `ROW_NUMBER()` subquery,
  not `DISTINCT ON` — needs dbplyr support
  ([#384](https://github.com/duckdb/duckdb-r/issues/384),
  [tidyverse/dbplyr#1620](https://github.com/tidyverse/dbplyr/pull/1620)).
  An experiment with v1.5.5 measured that `DISTINCT ON` is actually slower
  in many cases, and never faster
  ([`experiments/2026-08-09-distinct-on-cost/`](/experiments/2026-08-09-distinct-on-cost/README.md)).
  A caller who wants the clause anyway can render the pipeline and wrap it,
  and register that as their own `distinct()` method
  ([`experiments/2026-08-09-distinct-on-override/`](/experiments/2026-08-09-distinct-on-override/README.md)).
* `pivot_longer()` expands SQL generically instead of `UNPIVOT`
  ([#2029](https://github.com/duckdb/duckdb-r/issues/2029)).
* An inline `as.POSIXct("…")` is translated, not escaped,
  so the session time zone is not applied; `!!as.POSIXct(…)`
  is escaped R-side and is
  ([#1064](https://github.com/duckdb/duckdb-r/issues/1064), dbplyr-wide).
  Build the value in R with the zone meant and inject it with `!!`.
* A bare `Inf` literal escapes as the string `'Infinity'`
  ([#1585](https://github.com/duckdb/duckdb-r/issues/1585),
  blocked on
  [tidyverse/dbplyr#1838](https://github.com/tidyverse/dbplyr/issues/1838)).

## duckplyr

The other dplyr route, and it is not a dbplyr backend:
duckplyr drives the **relational API** directly
([`relational/`](/handbook/usage/relational/README.md)),
so a pipeline becomes a relation tree rather than a SQL string,
and the result arrives as an ALTREP data frame that computes on access.
Nothing is translated to SQL and back, which is the point —
and which is also why the two routes fail differently:
where dbplyr's boundaries are translation gaps
(the ones listed above), duckplyr's are the verbs the relational API
does not yet express, and it falls back to dplyr for those.

The dependency runs the other way from the rest of this page:
duckplyr consumes this package rather than being consumed by it.
It is the closest reverse dependency, so a behaviour change here is
checked against it before release
([`testing/revdep/`](/handbook/testing/revdep/README.md)),
and its version pins parts of the relational API in place.
`compute_parquet()` is its route to a Parquet file
([`data-import/`](/handbook/usage/data-import/README.md)).

## Arrow

In: `duckdb_register_arrow()` registers an Arrow object as a
scannable table, zero-copy, with projection and filter pushdown.
Out: `dbGetQueryArrow()` returns a `nanoarrow_array_stream`,
and `dbSendQueryArrow()` / `dbFetchArrowChunk()` stream a result
batch by batch — true streaming since 1.5.4
([#162](https://github.com/duckdb/duckdb-r/issues/162)).
The query result keeps its columns from execution on (`RQueryResult` in [`src/include/rapi.hpp`](/src/include/rapi.hpp)).
So its Arrow schema is there before the first fetch (`rapi_arrow_schema()` in [`src/arrow_export.cpp`](/src/arrow_export.cpp)).
So is an empty batch, which the engine's own converter builds from an empty chunk (`rapi_arrow_empty_array()`).
It has the layout of the batches a fetch returns, which `nanoarrow_array_init()` would not:
that leaves out the one offset a zero-length string, binary, list or map array still carries, and arrow refuses the array without it.
Once `dbFetchArrowChunk()` has drained a result, it answers with that empty batch, and `dbFetchArrow()` with an empty stream.
So does a result that `dbFetchArrow()` has handed over.
Both keep the result's columns, `INTERVAL` included
([#2773](https://github.com/duckdb/duckdb-r/issues/2773)).
Only a zero-length `dbBind()` executes nothing, so what it answers has no columns.
The stream is the interchange:
any Arrow-C-stream consumer takes a result onward
without an R data frame in between —
`polars::as_polars_df()`, `arrow::as_arrow_table()`,
`nanoarrow::convert_array_stream()` —
so a dedicated writer per frame library
(Polars was the one asked for) is this route, not new C++
([#642](https://github.com/duckdb/duckdb-r/issues/642)).
The stream feeds one consumer, draining as it is read.
A `$get_next()` loop over it ends in `NULL`.
A conversion such as `as.data.frame()` or `arrow::as_arrow_table()` releases it.
A second conversion is then an error ("has already been released"), not the result again.
It also holds its connection until the engine has seen the end of the result, in a batch shorter than `chunk_size` or in an empty read.
Another statement on that connection invalidates it.
The next read is then an error, not an early end that would pass for a complete result
([#2772](https://github.com/duckdb/duckdb-r/issues/2772)).
So a stream whose last batch held exactly `chunk_size` rows is invalidated, although every row has arrived.
The engine's own Arrow stream reports an invalidated result as ended
(vendored `src/duckdb/src/common/arrow/arrow_wrapper.cpp`),
so the glue wraps it and checks first (`RArrowArrayStreamWrapper`, [`src/arrow_export.cpp`](/src/arrow_export.cpp)).
The wrapper also keeps the connection's client context alive until the stream is released.
The engine's callbacks read it, so a stream can still be read after `dbDisconnect()`.
Statements that must run between reads need a connection of their own.
That includes a query that scans the stream itself, say after `duckdb_register_arrow()`.
On the stream's own connection, that query hangs instead of failing.
It holds the connection while it reads, and each read of the stream waits for the connection.
A multi-row `dbBind()` is not affected, because its results are materialized.
Reach for the stream where the result should not be held twice;
what every route holds, and for how long, is
[`memory/reading/`](/handbook/usage/memory/reading/README.md)'s.
`nanoarrow::convert_array_stream(to = )` takes a prototype and builds
that class directly instead of a data frame to convert afterwards,
and `dbSendQueryArrow()` with `dbFetchArrowChunk()` converts a batch
at a time.

`arrow::to_duckdb()` and `to_arrow()`
bridge dplyr pipelines both ways.
`to_arrow()` still reads through the `arrow = TRUE` route, which materializes the whole result first.
The same reader built from `dbGetQueryArrow()` and `arrow::as_record_batch_reader()` streams instead, and takes on the stream's limits.
A statement on its connection invalidates it before it is read to the end, and handed back to that connection with `to_duckdb()` it hangs.
Arrow's `MakeSafeRecordBatchReader()`, which `to_arrow()` wraps around its reader, reports a read error as the end of the stream.
So it cannot be kept around a stream, which can fail after its first batch.
The measurements, on arrow 25.0.1, are in [`experiments/2026-09-26-to-arrow-stream/`](/experiments/2026-09-26-to-arrow-stream/README.md).
The DBI Arrow API plan is
[`plan/PLAN-dbSendQueryArrow.md`](/plan/PLAN-dbSendQueryArrow.md).

## ADBC

`duckdb_adbc()` ([`R/Driver.R`](/R/Driver.R)) hands the engine to
`adbcdrivermanager`, and its three methods
register at load time the way dbplyr's do —
`adbc_database_init`, `adbc_connection_init`, `adbc_statement_init`,
all on classes this package defines for the purpose.
It is the one route here that does not go through DBI at all.

Those three methods are why the dependency is an `Enhances` and not a
`Suggests`:
providing methods for another package's generics is what the field is for,
and `Enhances` is the one optional field `R CMD check` does not insist on
installing.
That distinction stopped being academic when CRAN archived
`adbcdrivermanager`
([apache/arrow-adbc#4638](https://github.com/apache/arrow-adbc/issues/4638)) —
a `Suggests` that cannot be installed fails the check outright
(`Package suggested but not available`, an ERROR under `--as-cran`),
where an `Enhances` that cannot be installed is reported and passed over.
`Additional_repositories` does not change that,
and is not an alternative to the move:
it answers the separate incoming-feasibility NOTE
about a dependency outside the mainstream repositories,
so this package carries both —
the field pointed at `apache.r-universe.dev`,
which is where the ADBC monorepo publishes the package now.

The move is paid for in coverage, and it is worth knowing the price.
`--as-cran` runs tests and examples against a restricted library
that `tools:::setRlibs()` builds from
`Depends`, `Imports`, `Suggests` and `LinkingTo`.
It never reads `Enhances`,
and no environment variable changes that —
neither `_R_CHECK_SUGGESTS_ONLY_` nor `_R_CHECK_DEPENDS_ONLY_` does;
only dropping `--as-cran` does.
So the package is installed on the machine
and absent from the library the check's tests see,
which is exactly what `Enhances` claims about it.
`test-adbc.R` therefore skips under `--as-cran`,
here and on CRAN alike,
where it used to run while the dependency was a `Suggests`.
Exercising that route again means running it outside the check.

The driver manager also loads a DuckDB ADBC driver that is *not* this
package's — a library built by whatever toolchain the platform's own
DuckDB build uses — and that is the one way to reach an extension this
package cannot install, because the extensions a driver can install
follow the platform it was built for
([`extensions/`](/handbook/usage/extensions/README.md),
[reported working on Windows](https://github.com/duckdb/duckdb-r/issues/100#issuecomment-4095552832)).
It costs everything this package adds:
the DBI methods, the relational API, registration and the R type
mapping are this package's rather than the driver's,
and a second engine in the session shares nothing with this one.
Both routes need `adbcdrivermanager`, which no longer installs itself:
it comes from `apache.r-universe.dev`, which is what
`Additional_repositories` names
([`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md)
carries what CI does about that).
That universe publishes a prebuilt binary for every platform this package
is checked on — Linux, macOS and Windows, x86_64 and aarch64 —
so Windows arm64 is no longer the exception it was
while CRAN was the only source and had no binary for it.

## data.table and collapse

The other frame libraries
[#642](https://github.com/duckdb/duckdb-r/issues/642) asks for,
data.table and collapse,
operate on subclasses of data frames internally.
Unless this changes fundamentally,
handing these packages a data frame is good enough:
any other reader in these packages would still have to build R vectors.

*To deepen: absorb the translation inventory and refused arguments
from `?backend-duckdb`'s source; drain
[#209](https://github.com/duckdb/duckdb-r/issues/209).*
