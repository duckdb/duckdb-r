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
  The translation takes no zone to apply either — `tz =` is not part of
  it, and `as.POSIXct(x, tz = "UTC")` fails as an unused argument —
  and no other constructor fills the gap: `ISOdatetime()` is not
  translated at all and reaches the engine as a call it does not have.
  The escaped path converts the instant to UTC and writes a naive
  `::timestamp` literal, so what is sent depends on the zone the R
  value was built in: one unchanged line yields
  `'2025-03-01 23:00:00'` from an Indiana session,
  `'2025-03-01 18:00:00'` from UTC and `'2025-03-01 17:00:00'` from
  Zurich.
  So an inline comparison reads right and is off by the offset, while
  an escaped one is right against a UTC-naive column and off against
  anything else.
  Build the value in R with the zone meant and inject it with `!!`;
  what the column's own zone then is, is
  [`timestamps/`](/handbook/usage/timestamps/README.md)'s.
* A bare `Inf` literal escapes as the string `'Infinity'`
  ([#1585](https://github.com/duckdb/duckdb-r/issues/1585),
  blocked on
  [tidyverse/dbplyr#1838](https://github.com/tidyverse/dbplyr/issues/1838)).
* `n_distinct()` reaches dbplyr's unexported `glue_sql2()` through
  `getFromNamespace()` — a private-API dependency any dbplyr release
  can break.
  The public replacement `sql_glue()` has shipped, so the migration is
  unblocked; what it still needs is a `dbplyr (>= 2.6.0)` floor, which
  `DESCRIPTION`'s `Suggests` does not carry
  ([#1982](https://github.com/duckdb/duckdb-r/issues/1982)).

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
The stream is the interchange:
any Arrow-C-stream consumer takes a result onward
without an R data frame in between —
`polars::as_polars_df()`, `arrow::as_arrow_table()`,
`nanoarrow::convert_array_stream()` —
so a dedicated writer per frame library
(Polars was the one asked for) is this route, not new C++
([#642](https://github.com/duckdb/duckdb-r/issues/642)).
The stream feeds one consumer, draining as it is read,
so a second pass over the same object sees zero rows
rather than the result again.
Reach for the stream where the result should not be held twice.
`nanoarrow::convert_array_stream(to = )` takes a prototype and builds
that class directly instead of a data frame to convert afterwards,
and `dbSendQueryArrow()` with `dbFetchArrowChunk()` converts a batch
at a time.

`arrow::to_duckdb()` and `to_arrow()`
bridge dplyr pipelines both ways.
The DBI Arrow API plan is
[`plan/PLAN-dbSendQueryArrow.md`](/plan/PLAN-dbSendQueryArrow.md).

## ADBC

`duckdb_adbc()` ([`R/Driver.R`](/R/Driver.R)) hands the engine to
`adbcdrivermanager`, a `Suggests` like dbplyr, and its three methods
register at load time the same way —
`adbc_database_init`, `adbc_connection_init`, `adbc_statement_init`,
all on classes this package defines for the purpose.
It is the one route here that does not go through DBI at all.

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
Both routes need `adbcdrivermanager`, which rules out Windows arm64:
there it has no binary to install and does not build from source
([`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md)
carries what CI does about that).

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
