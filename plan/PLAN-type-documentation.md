# Plan: the type reference, and the gaps the catalog found

*This is a plan: work proposed, not a description of the system.
[`usage/types/`](/handbook/usage/types/README.md) and [`usage/arrow-types/`](/handbook/usage/arrow-types/README.md)
own what each type does today, geometry included,
and where this plan and a leaf disagree, the leaf is right.
The evidence is [`experiments/2026-09-26-type-catalog/`](/experiments/2026-09-26-type-catalog/README.md)
and [`experiments/2026-09-27-arrow-types/`](/experiments/2026-09-27-arrow-types/README.md), run on DuckDB 1.5.5.
It works toward [#2566](https://github.com/duckdb/duckdb-r/issues/2566).*

## Where it stands

[`usage/types/`](/handbook/usage/types/README.md) covers every type the DuckDB documentation lists for the vendored release,
and every type the `json`, `inet` and `spatial` extensions add, in both directions,
checked against `duckdb_types()` so that a type the engine gains shows up as a missing row.
[`usage/arrow-types/`](/handbook/usage/arrow-types/README.md) covers the same types through Arrow,
every Arrow type on the way in, and which R functions keep Arrow's types.
What the catalog found broken and a few lines could mend is fixed:
`integer64` written as the double its bits spell ([#2819](https://github.com/duckdb/duckdb-r/pull/2819)),
a bound data frame read past its end ([#2818](https://github.com/duckdb/duckdb-r/pull/2818)),
and, in [#2808](https://github.com/duckdb/duckdb-r/pull/2808),
integer-stored `Date` and `difftime` `NA` written as values, a data frame column of several fields refused by `dbWriteTable()`,
`dbExistsTable()` blind to a table holding a type R cannot hold,
and `BIT`, `BIGNUM`, `TIME_NS` and `UNION` refused on the Arrow routes, which need no R vector.
The user-facing pages #2566 asks for, `?duckdb_types` and `?duckdb_types_arrow`,
are rendered from the two leaves by [`scripts/types-rd.R`](/scripts/types-rd.R), whose `--check` CI runs.

## 1. Settle the gaps that are decisions

Each of these is a behaviour the records show and a leaf states;
none is a few-line fix, because each changes what an existing call returns or adds one.

* **`dbDataType()` disagrees with the write routes** for `difftime` and `hms` (`TIME` against `INTERVAL`),
  `integer64` (`DOUBLE` against `BIGINT`), `factor` (`VARCHAR` against `ENUM`) and matrices (the element type against `ARRAY`),
  so a `difftime` column cannot be appended to the table `dbCreateTable()` made for it.
  The write routes are what `dbWriteTable()` uses, so `dbDataType()` should follow them, checked against what DBItest expects.
* **`TIME` has no R class that writes it** except through Arrow, which truncates an `hms` to milliseconds or seconds.
  `hms` is R's time of day, and writing it as `TIME` rather than `INTERVAL` would give the type a route;
  a plain `difftime` stays an `INTERVAL`.
* **`UBIGINT` above 2^63 wraps to a negative `integer64`** without a word.
  Falling back to `numeric`, or refusing, would each be better than a wrong value.
* **A refused column reports `std::exception`.**
  A raw vector or a complex column is refused when it is registered, with a message naming neither the column nor its class,
  and so is a nanoarrow stream handed to `duckdb_register_arrow()`.
* **The `TIMESTAMP_NS` warning fires once per R process**, not once per result,
  so the second query that loses nanoseconds says nothing.
* **The DBI Arrow write methods go through R.**
  `dbWriteTableArrow()`, `dbCreateTableArrow()` and `dbAppendTableArrow()` are DBI's defaults,
  which convert each batch to a data frame, so every Arrow type R cannot hold is lost or refused;
  `dbBindArrow()` does the same, and refuses a stream whose fields have names.
  Implemented on the scan `duckdb_register_arrow()` does, they would keep Arrow's types;
  that wants a scan of a nanoarrow stream, which [`plan/PLAN-spatial-interop.md`](/plan/PLAN-spatial-interop.md) also needs.
* **dbplyr cannot open a table holding a type R cannot hold.**
  The backend could answer dbplyr's field query from `DESCRIBE`, as `dbListFields()` does,
  so that `tbl()`, `arrow::to_duckdb()` and `to_arrow()` open the table, and fail only on collecting such a column.

## 2. Measure what the records do not cover

The relational routes (`rel_to_df()`, `rel_to_altrep()`), the environment scan (`duckdb(environment_scan = TRUE)`)
and `dbQuoteLiteral()` each convert types their own way,
and the code suggests they differ: `rel_to_df()` reads with default options whatever the connection says.
Each is a column added to [`catalog.R`](/experiments/2026-09-26-type-catalog/catalog.R), re-rendered.
Run-end encoded arrays are the one Arrow layout neither R package builds, so the Arrow record has no row for them.

## Upstream

* **`VARIANT` has no Arrow export**, in the engine's Arrow converter; nothing in this package can supply one.
* **The default Arrow export overflows `decimal128(38, 0)`.**
  `HUGEINT` and `UHUGEINT` values of more than 38 digits export as bits that type cannot hold, and the largest `UHUGEINT` reads as `-1`.
* **Arrow's `interval_day_time` is misread**, as one 64-bit count of milliseconds rather than days and milliseconds,
  in the vendored `src/duckdb/src/function/table/arrow_conversion.cpp`.
