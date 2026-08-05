# Integrations

The routes into DuckDB beside plain SQL:
dplyr pipelines by two different mechanisms, Arrow interchange,
and ADBC.
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
* `pivot_longer()` expands SQL generically instead of `UNPIVOT`
  ([#2029](https://github.com/duckdb/duckdb-r/issues/2029)).
* An inline `as.POSIXct("…")` is translated, not escaped,
  so the session time zone is not applied; `!!as.POSIXct(…)`
  is escaped R-side and is
  ([#1064](https://github.com/duckdb/duckdb-r/issues/1064), dbplyr-wide).
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

*To deepen: absorb the translation inventory and refused arguments
from `?backend-duckdb`'s source; drain
[#209](https://github.com/duckdb/duckdb-r/issues/209).*
