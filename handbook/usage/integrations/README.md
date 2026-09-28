# Integrations

The routes into DuckDB beside plain SQL:
dplyr pipelines by two different mechanisms, Arrow interchange,
ADBC, and a result's way into Polars, data.table and collapse.
What a value becomes across the boundary is
[`types/`](/handbook/usage/types/README.md)'s,
and through Arrow [`arrow-types/`](/handbook/usage/arrow-types/README.md)'s.

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

* `tbl()` cannot open a table holding a type R cannot hold, `BIT`, `BIGNUM` or `UNION`:
  dbplyr reads the fields through a query R has to convert, and reports "Can't query fields".
  `arrow::to_duckdb()` returns such a `tbl()` and `to_arrow()` takes one, so both fail the same way.
  A `tbl()` over a query that casts the column, as `tbl(con, sql("SELECT b::VARCHAR AS b FROM t"))` for a `BIT` column, opens
  ([`tests/testthat/test-backend-dbplyr__duckdb_connection.R`](/tests/testthat/test-backend-dbplyr__duckdb_connection.R)).
* dbplyr refuses a `difftime`, an `hms` or a lubridate `Period` as a value in a verb, with "Cannot translate",
  before the backend sees it and whatever the connection's options say.
  `!!dbQuoteLiteral(con, x)` passes one, quoted as the options say ([`types/`](/handbook/usage/types/README.md))
  ([`tests/testthat/test-backend-dbplyr__duckdb_connection.R`](/tests/testthat/test-backend-dbplyr__duckdb_connection.R)).
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
The stream is the interchange: any Arrow C stream consumer takes a result onward without an R data frame in between.
`arrow::as_arrow_table()` and `nanoarrow::convert_array_stream()` are such consumers.
The stream feeds one consumer, draining as it is read, and a drained stream reads as empty rather than as the result again.
A `$get_next()` loop over it ends in `NULL`, and a second `nanoarrow::convert_array_stream()` returns zero rows.
`as.data.frame()` and `arrow::as_arrow_table()` also release it, so a read after either is an error ("has already been released").
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
That includes a query that scans the stream itself.
Registering `arrow::as_record_batch_reader(stream)` with `duckdb_register_arrow()` and querying it is one.
On the stream's own connection it waits for good, as the entry below says.
A multi-row `dbBind()` is not affected, because its results are materialized.
Reach for the stream where the result should not be held twice;
what every route holds, and for how long, is
[`memory/reading/`](/handbook/usage/memory/reading/README.md)'s.
`nanoarrow::convert_array_stream(to = )` takes a prototype and builds
that class directly instead of a data frame to convert afterwards,
and `dbSendQueryArrow()` with `dbFetchArrowChunk()` converts a batch
at a time.

**A query that scans a stream on the stream's own connection waits instead of failing.**
Starting the query invalidates the stream.
A read learns that only under the connection's lock, which the query holds until the scan returns.
Neither the size of the result nor the number of threads changes that.
Ctrl+C does not end the wait, so the R session has to be killed ([`interactive/`](/handbook/usage/interactive/README.md)).
The engine's own stream waits the same way, in the Python client and in this package before [#2775](https://github.com/duckdb/duckdb-r/pull/2775).
A second connection to the same database scans the stream.
So does its own connection once the stream has been read to the end or the result materialized
([`2026-09-27-stream-self-scan/`](/experiments/2026-09-27-stream-self-scan/README.md)).
Writing a stream back to its own connection fails instead, with the invalidation error.
DBI's methods for that run statements between their reads.
`dbWriteTableArrow()` of a bare stream fails before it creates the table, and of an Arrow reader after, leaving it empty.
`dbAppendTableArrow()` fails at the second batch, after appending the first.
So a stream longer than one batch leaves a partial copy.

`arrow::to_duckdb()` and `to_arrow()`
bridge dplyr pipelines both ways.
`to_arrow()` still reads through the `arrow = TRUE` route, which materializes the whole result first.
The same reader built from `dbGetQueryArrow()` and `arrow::as_record_batch_reader()` streams instead, and takes on the stream's limits.
Arrow's `MakeSafeRecordBatchReader()`, which `to_arrow()` wraps around its reader, reports a read error as the end of the stream.
So it cannot be kept around a stream, which can fail after its first batch.
The measurements, on arrow 25.0.1, are in [`experiments/2026-09-26-to-arrow-stream/`](/experiments/2026-09-26-to-arrow-stream/README.md).
The DBI Arrow API plan is
[`plan/PLAN-dbSendQueryArrow.md`](/plan/PLAN-dbSendQueryArrow.md).

**`to_arrow_stream()` is better than nothing, within hard limits.**
The package exports that reader as the experimental `to_arrow_stream()` ([`R/to_arrow_stream.R`](/R/to_arrow_stream.R)).
It holds a large result once where `to_arrow()` holds it twice, but it is no drop-in replacement.
Its reference page points here for them.
The reader is its connection's open result until it has been read to the end:

* Any other statement on that connection breaks it, and the next read fails with the invalidation error.
  dplyr and dbplyr run such statements unasked: `tbl()` asks for the columns, and printing or collecting a lazy table runs its query.
  A second `to_arrow_stream()` on the same connection is one too.
* A query that scans the reader on its own connection never returns, and Ctrl+C does not end it, as the entry above says.
  `to_duckdb(reader, con = con)` is one, and so is a query on `con` after `duckdb_register_arrow()` of the reader.
* Tables from `to_duckdb()` share the one connection arrow keeps unless `con` is given.
  For those, a later `to_duckdb()` without `con` breaks the reader, and one on the reader itself never returns.
* Writing the reader back to its own connection fails partway.
  `dbWriteTableArrow()` leaves an empty table behind, and `dbAppendTableArrow()` the first batch.
* A read runs outside the package's interrupt handler, so Ctrl+C does not stop it.
  Ctrl+C does stop `to_arrow()`, which reads inside `dbSendQuery()`.
* A query that fails after its first batch fails at the read, not in `to_arrow_stream()`.
* The reader is read once, and a second read gives zero rows, not the result again.

A second connection to the same database, `dbConnect(con@driver)`, is independent of the reader in both directions.
It sees neither the first connection's temporary tables nor its open transaction
([`2026-09-27-stream-self-scan/`](/experiments/2026-09-27-stream-self-scan/README.md)).
[`plan/PLAN-connection-clone.md`](/plan/PLAN-connection-clone.md) would let a result own such a connection (`isolated = TRUE`).
That would lift the first four.
The reader keeps the database instance open until it is garbage-collected, even once it has been read to the end
([`connections/`](/handbook/usage/connections/README.md)).

**A result goes into Polars, data.table or collapse without a writer of its own.**
Each takes what a DBI call returns:

* Polars: `polars::as_polars_df(dbGetQueryArrow(con, sql))`.
  It keeps each batch as a chunk, and numbers and characters where the stream put them.
  A string column gains a 16-byte view per value, unless the export already sends views,
  as it does with `produce_arrow_string_view = true` and an `arrow_output_version` from `'1.4'`
  ([`experiments/2026-09-28-type-rereview/`](/experiments/2026-09-28-type-rereview/README.md)).
* data.table: `data.table::setDT(dbGetQuery(con, sql))`.
  It makes the data frame a data.table in place and keeps every column, where `as.data.table()` copies each one.
* collapse: its functions take the data frame as it is, and `collapse::qDT()` makes a data.table that keeps every column.

Polars keeps Arrow memory, which the stream already is, and data.table and collapse keep R vectors, which `dbGetQuery()` already builds.
So a writer of its own would build the same memory that these calls reach without one ([#642](https://github.com/duckdb/duckdb-r/issues/642)).
Measured on data.table 1.18.6.1, collapse 2.1.8 and the development version of polars from r-universe, not its release
([`experiments/2026-09-28-frame-libraries/`](/experiments/2026-09-28-frame-libraries/README.md)).

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

*To deepen: absorb the translation inventory and refused arguments
from `?backend-duckdb`'s source; drain
[#209](https://github.com/duckdb/duckdb-r/issues/209).*
