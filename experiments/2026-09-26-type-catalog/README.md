# Every DuckDB type, in and out of R

*What it measures:* for every DuckDB type, what a value becomes in R on each read route,
and whether each write route puts that value back as the same type and value;
the Arrow round trip of every type, with and without `arrow_lossless_conversion`;
and the cases where a value changes, collides with `NA`, or fails, before and after the fixes the record prompted.

*When and on what:* 2026-09-26, duckdb 1.5.5.9026 (DuckDB 1.5.5, linked through the fast path), Linux,
with `json`, `inet`, `spatial` and `icu` from the extension store,
bit64 4.8.6, nanoarrow 0.9.0, arrow 25.0.1, geoarrow 0.4.4, wk 0.9.5.
The `.md` records without a suffix ran on `main` at 66c7fb1f with the five fixes listed below applied;
`edges-main.md` ran the same script on `main` at 66c7fb1f alone.
Two of the fixes have since landed on `main` as [#2818](https://github.com/duckdb/duckdb-r/pull/2818) and [#2819](https://github.com/duckdb/duckdb-r/pull/2819),
and the other three are [#2808](https://github.com/duckdb/duckdb-r/pull/2808).
The reference list of types is DuckDB's own documentation for that release,
the pages under [`docs/current/sql/data_types/`](https://github.com/duckdb/duckdb-web/tree/15add337444fcba7a88f48ea5abd33c1358c9d37/docs/current/sql/data_types)
of `duckdb/duckdb-web` at 15add337 (served at `duckdb.org/docs/current/`, whose `_config.yml` names 1.5.5),
plus the extension pages for [`json`](https://github.com/duckdb/duckdb-web/blob/15add337444fcba7a88f48ea5abd33c1358c9d37/docs/current/data/json/json_type.md),
[`inet`](https://github.com/duckdb/duckdb-web/blob/15add337444fcba7a88f48ea5abd33c1358c9d37/docs/current/core_extensions/inet.md)
and [`spatial`](https://github.com/duckdb/duckdb-web/blob/15add337444fcba7a88f48ea5abd33c1358c9d37/docs/current/core_extensions/spatial/overview.md).

*What it supports:* [`usage/types/`](/handbook/usage/types/README.md) and [`usage/spatial/`](/handbook/usage/spatial/README.md),
and the open work in [`plan/PLAN-type-documentation.md`](/plan/PLAN-type-documentation.md).

## Method

[`types.R`](types.R) lists the types with a value of each:
every name the documentation's type pages list, the widths at which `DECIMAL` changes storage,
and every type name `json`, `inet` and `spatial` add.
[`catalog.R`](catalog.R) proves the list complete against the engine:
every type id `duckdb_types()` reports, and every type name an extension adds, has a row.
Its two `character(0)` lines in [`catalog.md`](catalog.md) are that check.

Each script is rendered with `reprex::reprex(si = TRUE)` from this directory, which `types.R` needs:

* [`catalog.R`](catalog.R) → [`catalog.md`](catalog.md): the read routes (`dbGetQuery()` with the defaults,
  with the one option that changes the type's R shape, `dbGetQueryArrow()`, and the value as text),
  then the write routes for the value the best read returned
  (`dbWriteTable()` without and with `field.types`, `dbAppendTable()` into a typed column, a bound parameter,
  and the text through `field.types`), each compared with the original in SQL.
* [`arrow.R`](arrow.R) → [`arrow.md`](arrow.md): each type out through `dbGetQueryArrow()` and back through `duckdb_register_arrow()`,
  with the default export and with `arrow_lossless_conversion`, then Arrow arrays built in R for the types no R class writes.
* [`edges.R`](edges.R) → [`edges.md`](edges.md) and [`edges-main.md`](edges-main.md): one case per row,
  on the fixed build and on its parent.
  The bound data frame runs in a subprocess, because on the parent it crashes R.

## Findings

What each type does is the leaf's; what the run found beyond that:

* **Reading covers every type but four, and Arrow covers those.**
  `BIT`, `BIGNUM`, `TIME_NS` and `UNION` have no R vector, and the parent refused them at prepare time,
  on the Arrow routes too, where no R vector is needed.
  The fix lets an Arrow result carry them (`TIME_NS` converts to `hms`, `UNION` to a data frame),
  and the DBI route now names the column it refuses.
  `VARIANT` is the one type the engine's Arrow export does not implement.
* **Text is the universal write route for scalars.**
  The value cast to `VARCHAR`, written as `character` with `field.types`, lands the same value for every scalar type;
  only `MAP` fails, because `field.types` wraps a `MAP` column in `map_from_entries()`, which takes no text;
  `UNION` takes its text as the `VARCHAR` member, and the `spatial` extension's
  point, line, polygon and box types do not parse WKT.
* **The value R reads writes back as the same type, except for `TIME`, `TIMETZ`, `GEOMETRY` and `VARIANT`.**
  `TIME` and `TIMETZ` come back as `difftime`, which writes `INTERVAL`, which does not cast to `TIME`;
  `GEOMETRY` comes back as WKB, which does not cast to `GEOMETRY`;
  and `VARIANT` comes back as a list, which writes as a `LIST` inside the variant.
* **Arrow with `arrow_lossless_conversion` round-trips every type but `VARIANT`** and the `spatial` alias types,
  which arrive as their plain `STRUCT` or `LIST` storage.
  Without it, `HUGEINT` and `UHUGEINT` come back as `DECIMAL(38,0)`, `UUID` and `JSON` as `VARCHAR`,
  `BIT` as `BLOB`, and `TIMETZ` as `TIME` with its offset lost.
* **Registering an Arrow result that is still open hangs.**
  A `dbGetQueryArrow()` stream registered back on the connection it came from waits on that connection forever;
  read to the end first, it registers.
  [`arrow.R`](arrow.R) does so; the hang is not in a record because a hanging script cannot render.

[`edges-main.md`](edges-main.md) shows the defects the fixes remove, and [`edges.md`](edges.md) shows them gone:

* an `integer64` column or parameter written as the double its bits spell (`2.08e-322` for 42) unless the connection read
  with `bigint = "integer64"`, and as parameters always;
* an integer-stored `Date` or `difftime` `NA` written as a real value (`5877642-06-23 (BC)`, `-1491308 days`);
* a data frame column of two fields refused by `dbWriteTable()` with "the condition has length > 1";
* a one-row data frame bound as a parameter read as many rows as it has columns, past its end: R crashed;
* `dbExistsTable()` answering `FALSE`, and `dbListFields()` failing, for a table holding one of the four types,
  so `dbWriteTable(overwrite = TRUE)` failed on it with "already exists";
* and those four types refused on the Arrow routes.

Replicate with the vendored build or the fast path ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
from this directory, `reprex::reprex(input = "catalog.R", si = TRUE)` and likewise for the other two;
`INSTALL` needs network access to `extensions.duckdb.org`.
