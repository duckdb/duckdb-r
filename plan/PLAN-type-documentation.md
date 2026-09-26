# Plan: the type reference, and the gaps the catalog found

*This is a plan: work proposed, not a description of the system.
[`usage/types/`](/handbook/usage/types/README.md) and [`usage/spatial/`](/handbook/usage/spatial/README.md) own what each type does today,
and where this plan and a leaf disagree, the leaf is right.
The evidence is [`experiments/2026-09-26-type-catalog/`](/experiments/2026-09-26-type-catalog/README.md), run on DuckDB 1.5.5.
It works toward [#2566](https://github.com/duckdb/duckdb-r/issues/2566).*

## Where it stands

[`usage/types/`](/handbook/usage/types/README.md) covers every type the DuckDB documentation lists for the vendored release,
and every type the `json`, `inet` and `spatial` extensions add, in both directions,
checked against `duckdb_types()` so that a type the engine gains shows up as a missing row.
The change that wrote it fixed what the record found broken and a few lines could mend:
`integer64` written as the double its bits spell, integer-stored `Date` and `difftime` `NA` written as values,
a data frame column of several fields refused by `dbWriteTable()`, a bound data frame read past its end,
`dbExistsTable()` blind to a table holding a type R cannot hold,
and `BIT`, `BIGNUM`, `TIME_NS` and `UNION` refused on the Arrow routes, which need no R vector.

## 1. Derive the reference page

#2566 asks for a user-facing page generated from the handbook,
and the handbook is `.Rbuildignore`d ([`meta/local/`](/handbook/meta/local/README.md)), so the page has to stand without it.
The proposal is a generator in the shape of [`docs-readme.R`](/.claude/skills/docs-consistency/docs-readme.R):
it reads the per-type sections of the leaf, rewrites links into the tree as links to the repository on GitHub,
and writes a roxygen block that renders as `?duckdb_types`, with `--check` run by the handbook workflow so the two cannot drift.
The generated file declares the leaf in `derived_from:`, and the leaf's deepen line is deleted with it.

## 2. Settle the gaps that are decisions

Each of these is a behaviour the record shows and the leaf states;
none is a few-line fix, because each changes what an existing call returns.

* **`dbDataType()` disagrees with the write routes** for `difftime` and `hms` (`TIME` against `INTERVAL`),
  `integer64` (`DOUBLE` against `BIGINT`), `factor` (`VARCHAR` against `ENUM`) and matrices (the element type against `ARRAY`),
  so a `difftime` column cannot be appended to the table `dbCreateTable()` made for it.
  The write routes are what `dbWriteTable()` uses, so `dbDataType()` should follow them, checked against what DBItest expects.
* **`TIME` has no R class that writes it.**
  `hms` is R's time of day, and writing it as `TIME` rather than `INTERVAL` would give the type a route;
  a plain `difftime` stays an `INTERVAL`.
* **`UBIGINT` above 2^63 wraps to a negative `integer64`** without a word.
  Falling back to `numeric`, or refusing, would each be better than a wrong value.
* **A refused column reports `std::exception`.**
  A raw vector or a complex column is refused when it is registered, with a message naming neither the column nor its class.
* **The `TIMESTAMP_NS` warning fires once per R process**, not once per result,
  so the second query that loses nanoseconds says nothing.

## 3. Measure what the record does not cover

The relational routes (`rel_to_df()`, `rel_to_altrep()`), the environment scan (`duckdb(environment_scan = TRUE)`),
DBI's default `dbWriteTableArrow()` and `dbAppendTableArrow()`, and `dbQuoteLiteral()` each convert types their own way,
and the code suggests they differ: `rel_to_df()` reads with default options whatever the connection says.
Each is a column added to [`catalog.R`](/experiments/2026-09-26-type-catalog/catalog.R), re-rendered.

## Upstream

* **`VARIANT` has no Arrow export**, in the engine's Arrow converter; nothing in this package can supply one.
* **`duckdb_register_arrow()` takes no `nanoarrow` stream**, which [`plan/PLAN-spatial-interop.md`](/plan/PLAN-spatial-interop.md) already carries.
