# A user-side `DISTINCT ON`, and what dbplyr can already say without it

*What it measures:* whether a caller who wants
[#384](https://github.com/duckdb/duckdb-r/issues/384)'s `DISTINCT ON`
can have it without waiting for dbplyr,
how far into dbplyr's internals that reaches,
and what the verb can already express as it stands.
Whether the clause is worth wanting for speed is
[`2026-08-09-distinct-on-cost/`](/experiments/2026-08-09-distinct-on-cost/README.md).

*When and on what:* 2026-08-09, Linux x86_64, R 4.5.3,
duckdb 1.5.5 from CRAN, dbplyr 2.6.0, dplyr 1.2.1.
[`override.R`](override.R) rendered to [`override.md`](override.md) with
`reprex::reprex(input = "override.R", venue = "gh")`.

*What it supports:* the `distinct(.keep_all = TRUE)` bullet in
[`usage/integrations/`](/handbook/usage/integrations/README.md).

## Which row survives is already sayable

`.keep_all = TRUE` keeps one row per group, and dbplyr can be told
which:

* `window_order(desc(x))` above `distinct()` renders
  `ROW_NUMBER() OVER (PARTITION BY grp ORDER BY x DESC)`,
  and keeps 3, 6, 9 of the nine rows;
  `window_order(x)` keeps 1, 4, 7.
* `arrange(desc(x))` in the same position warns
  (*"ORDER BY is ignored in subqueries without LIMIT"*)
  and renders **the same SQL**, ordering the window the same way.
  The warning is generic; here nothing was ignored.
  `window_order()` is the spelling that says it without one.

So the gap #384 names is `DISTINCT ON` as a *clause*, not the ability
to determine the pick. A pipeline that says nothing gets
`ORDER BY` on the first column, which is arbitrary — and, per the cost
experiment, exactly as fast as `DISTINCT ON` with no ordering at all.

## The override reaches no internals

The wrapper renders the pipeline it is given, wraps the result in
`SELECT DISTINCT ON (…) * FROM (…) ORDER BY …`,
and hands that back as a lazy table.
Everything it needs is exported: `remote_con()`, `sql_render()`,
`translate_sql_()` (which turns `desc(x)` into `"x" DESC`),
`ident()`, `escape()` and `sql()`.
Nothing comes from `:::`, so no dbplyr release can break it by
rearranging its private surface — the risk
[#1982](https://github.com/duckdb/duckdb-r/issues/1982) carries for
`n_distinct()`.

**The opt-in is an argument, not a setting.**
Registered as `distinct.tbl_duckdb_connection`, the method takes
`.order_by` and hands straight back to dbplyr through `NextMethod()`
whenever it is absent — so registering it changes nothing until a call
asks, `.keep_all = FALSE` never reaches it, and an explicit
`.order_by = NULL` behaves like saying nothing.
An earlier draft gated it on a global option instead; the argument is
better on both counts.
It is per call rather than per session, and it cannot change an
existing pipeline's answer silently, because the calls it fires on are
exactly the calls that stated which row they meant.

Asked, it complies: `.order_by = desc(x)` keeps 3, 6, 9 and
`.order_by = x` keeps 1, 4, 7, and the result composes like any other
lazy table.

## What it still costs

The wrapper starts a new `tbl()` over rendered SQL, so it reads nothing
dbplyr was tracking — including a `window_order()` the caller already
wrote. The ordering has to be stated again, in `.order_by`, and a
pipeline carrying both says it twice.

Which is the argument for the clause landing in dbplyr rather than in a
wrapper
([tidyverse/dbplyr#1620](https://github.com/tidyverse/dbplyr/pull/1620)):
dbplyr builds the query and already knows the window ordering the
pipeline asked for.
