# What `DISTINCT ON` would cost, against the plan dbplyr emits

*What it measures:* whether
[#384](https://github.com/duckdb/duckdb-r/issues/384)'s premise holds —
that `DISTINCT ON` is "much faster" than the `ROW_NUMBER()` subquery
dbplyr writes for `distinct(.keep_all = TRUE)` — and whether any regime
turns the comparison around.
Whether a caller can have the clause anyway is
[`2026-08-09-distinct-on-override/`](/experiments/2026-08-09-distinct-on-override/README.md).

*When and on what:* 2026-08-09, Linux x86_64 (4 cores, 15 GB RAM),
R 4.5.3, duckdb 1.5.5 from CRAN, dbplyr 2.6.0.
20M rows per table, timings the median of two runs, one thread unless
the row says otherwise.
[`cost.R`](cost.R) rendered to [`cost.md`](cost.md) with
`reprex::reprex(input = "cost.R", venue = "gh")`.

*What it supports:* the `distinct(.keep_all = TRUE)` bullet in
[`usage/integrations/`](/handbook/usage/integrations/README.md).

## The grid

Seconds, for the same answer — one determined row per group — except
the "unordered" column, which is `DISTINCT ON` with no `ORDER BY` and
so picks an arbitrary member:

* 4,000 groups, narrow — `ROW_NUMBER` 0.60, `DISTINCT ON` 1.14,
  unordered 0.40; with `LIMIT 10`, 0.58 against 1.15.
* 4,000 groups, wide (13 columns) — 0.56, 1.12, 0.39;
  with `LIMIT 10`, 0.56 against 1.11.
* 15.7M groups, narrow — 7.07, 8.97, 3.08;
  with `LIMIT 10`, 3.87 against 4.82.
* 15.7M groups, wide — 4.46, 8.15, 3.04;
  with `LIMIT 10`, 3.83 against 5.35.
* 15.7M groups, narrow, four threads — 0.71, 1.94, 0.46.

Cardinality, width, a `LIMIT` and the thread count all leave the
ordering intact: `DISTINCT ON` costs 1.4× to 2.7× the window plan.

## The three regimes where it might have won

Each asks whether `DISTINCT ON`'s mandatory sort could stop being
wasted work. None of them lands:

* **Nothing to tie-break on** — order by the `ON` list itself:
  3.09 against 5.06.
* **Input already stored in that order** — the same query over a table
  written `ORDER BY k, k2, ord`: 2.86 against 6.03.
  The engine does not know the table is sorted, and sorts again.
* **Output wanted sorted anyway**, so the sort would have had to happen
  regardless: 5.02 against 7.24.

## The comparison that decides it

The rows above give `DISTINCT ON` a tie-break because that is what a
determined pick needs. But dbplyr, with no `arrange()` in the pipeline,
emits `ORDER BY` on the *first column* — one of the partition keys — so
its pick is arbitrary too. Against that plan, which is what a caller
actually gets, the two answer the same question:

```
dbplyr's ROW_NUMBER  2.81 s | DISTINCT ON, unordered  2.96 s
```

— and return the same number of rows. Within noise.

**What it shows.** There is no regime here where `DISTINCT ON` is
faster for the question being asked. Where the pick is arbitrary the
two plans are equivalent; where it is determined the window plan is
1.4× to 2.7× ahead. So the clause is worth having for what it says, not
for what it costs, and no pipeline is waiting on it for speed.
