# Summaries over a lazy column

*What it measures:* what a summary costs on a converted column of `rel_to_altrep()`
against the same values in a plain vector, before and after
[#2890](https://github.com/duckdb/duckdb-r/issues/2890) gave the atomic classes `Length`, `Dataptr`, `Elt` and `Get_region` methods
that read the converted vector without the guard.
Ten million rows of a double, an integer, a logical and a string column,
seconds per call as the mean of five, and the first call on an unconverted column, conversion included.

*When and on what:* 2026-11-17, Linux x86_64, Ubuntu 24.04, R 4.5.3.
Two fast-path builds linking the release `libduckdb` of DuckDB 2.0.0 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
each rendered from [`summaries.R`](summaries.R) by [`scripts/render-reprex.R`](/scripts/render-reprex.R):

* [`head.md`](head.md): duckdb 2.0.0.9000 at f0691f9, before the change.
* [`fix.md`](fix.md): the same with the change, the commit of
  [`claude/issue-2890-lazy-vector-summaries`](https://github.com/duckdb/duckdb-r/tree/claude/issue-2890-lazy-vector-summaries)
  that adds this record.

The session info names the scratch library that held each build as `<base build library>` and `<branch build library>`.

*What it supports:* the per-element methods in [`architecture/glue/altrep/`](/handbook/architecture/glue/altrep/README.md).

## Findings

Altrep over plain, from the two records and two more runs of each build, which agree within noise:

| op | before | after |
|---|---|---|
| `range()`, double | 10x | 2x |
| `range()`, integer | 20x | 4x |
| `c()`, double / integer | 25x / 45x | 4x / 7x |
| `mean()`, integer | 45x | 6x |
| `anyNA()`, logical / string | 45x / 45x | 6x / 7x |
| `unique()`, string | 22x | 4x |
| `c()`, logical / string | 45x / 18x | 7x / 3x |

`sum()`, `max()`, `anyNA()` of a number and arithmetic were already even, because they take the whole payload through `Dataptr_or_null`.
The first call on an unconverted column, which converts it, drops from 1.5 to 0.9 seconds for `anyNA()` and from 5.5 to 1.8 for `unique()` of the string column.

Before, every element cost a pass through `BEGIN_CPP11`, the guard and the external pointer's checks,
and `c()` paid it twice: a callgrind profile counts one `Dataptr` call per element it copies, from `RealAnswer()` in R's `bind.c`,
and a fast `Length` alone halved its time, so the length is asked for as often.
What remains is R's own dispatch: an ALTREP vector is read through a method call per element where a plain one is read in place.

## Replicating

From this directory, with the build under test first in the library path,
`Rscript ../../scripts/render-reprex.R summaries.R fix`.
The script needs no network, and takes about a minute.
