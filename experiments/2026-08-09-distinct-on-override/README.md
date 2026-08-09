# A user-side `DISTINCT ON`, and what switching it on costs

*What it measures:* whether a caller who wants
[#384](https://github.com/duckdb/duckdb-r/issues/384)'s `DISTINCT ON`
can have it without waiting for dbplyr,
how far into dbplyr's internals that reaches,
and what changes about a pipeline when it is switched on.
The companion measurement — whether the clause is worth wanting for
speed — is
[`2026-08-09-distinct-on-cost/`](/experiments/2026-08-09-distinct-on-cost/README.md).

*When and on what:* 2026-08-09, Linux x86_64, R 4.5.3,
duckdb 1.5.5 from CRAN, dbplyr 2.6.0, dplyr 1.2.1.
[`override.R`](override.R) rendered to [`override.md`](override.md) with
`reprex::reprex(input = "override.R", venue = "gh")`.

*What it supports:* the `distinct(.keep_all = TRUE)` bullet in
[`usage/integrations/`](/handbook/usage/integrations/README.md).

## It reaches no internals

The wrapper renders the pipeline it is given, wraps the result in
`SELECT DISTINCT ON (…) * FROM (…) ORDER BY …`,
and hands that back as a lazy table.
Everything it needs is exported: `remote_con()`, `sql_render()`,
`translate_sql_()` (which is what turns `desc(x)` into `"x" DESC`),
`ident()`, `escape()` and `sql()`.
Nothing comes from `:::`, so no dbplyr release can break it by
rearranging its private surface — the risk that
[#1982](https://github.com/duckdb/duckdb-r/issues/1982) carries for
`n_distinct()`.

Registered as `distinct.tbl_duckdb_connection` it becomes the verb,
and it stays inert until asked:
the method consults `getOption("duckdb.distinct_on", FALSE)` and calls
`NextMethod()` otherwise, so an unset session sees dbplyr's plan
unchanged.
`.keep_all = FALSE` is never its business — that path is already
`SELECT DISTINCT` and falls through either way.

## What it costs: the pipeline's ordering

Which row of each group survives is the whole content of
`.keep_all = TRUE`, and neither route states it:

* dbplyr warns that an `arrange()` above `distinct()` is ignored
  (*"ORDER BY is ignored in subqueries without LIMIT"*) —
  and on DuckDB the two orderings nevertheless answer differently,
  so it is not ignored.
  What decides is how the subquery happens to feed the window.
* The override cannot see the pipeline at all.
  It starts a new `tbl()` over rendered SQL, so an upstream `arrange()`
  reaches it no further than it reaches dbplyr's own plan,
  and the ordering has to be repeated as `.order_by`.

Said explicitly, the override complies and is the only one of the three
that is a contract: `.order_by = x` keeps 1, 4, 7 and
`.order_by = desc(x)` keeps 3, 6, 9, from the same nine rows.

**Why the switch, and why off.**
Two reasons the same wrapper should not simply become the behaviour.
It is not faster — the companion experiment finds the window plan
ahead of `DISTINCT ON` wherever the pick is determined —
and it silently changes which row `.keep_all` keeps in any pipeline
that was leaning on the ordering it can no longer see.
A caller who wants the clause for its readability can opt in per
session and pass `.order_by`; anyone else keeps what they had.

Which is also the argument for where the clause belongs:
dbplyr builds the query and is the only layer that knows what the
pipeline asked for
([tidyverse/dbplyr#1620](https://github.com/tidyverse/dbplyr/pull/1620)).
A wrapper can only be handed the answer a second time.
