# Summaries over a lazy column

*What it measures:* what a summary costs on a converted column of `rel_to_altrep()`
against the same values in a plain vector, before and after
[#2890](https://github.com/duckdb/duckdb-r/issues/2890) gave the atomic classes `Length`, `Dataptr`, `Elt` and `Get_region` methods
that read the converted vector without the guard,
and after the follow-up that caches that vector's data pointer and length in the column's wrapper.
Ten million rows of a double, an integer, a logical and a string column,
seconds per call as the mean of five, and the first call on an unconverted column, conversion included.

*When and on what:* 2026-11-17, Linux x86_64, Ubuntu 24.04, R 4.5.3.
Three fast-path builds linking the release `libduckdb` of DuckDB 2.0.0 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)),
each rendered from [`summaries.R`](summaries.R) by [`scripts/render-reprex.R`](/scripts/render-reprex.R):

* [`head.md`](head.md): duckdb 2.0.0.9000 at f0691f9, before the change.
* [`fix.md`](fix.md): the same with the change, the commit of
  [`claude/issue-2890-lazy-vector-summaries`](https://github.com/duckdb/duckdb-r/tree/claude/issue-2890-lazy-vector-summaries)
  that adds this record.
* [`cache.md`](cache.md): the follow-up, the commit of
  [`claude/issue-2890-altrep-summary-methods`](https://github.com/duckdb/duckdb-r/tree/claude/issue-2890-altrep-summary-methods)
  that adds it.

The session info names the scratch library that held each build as `<base build library>` and `<branch build library>`.

*What it supports:* the per-element methods in [`architecture/glue/altrep/`](/handbook/architecture/glue/altrep/README.md).

## Findings

Altrep over plain, from the records and two more runs of each build, which agree within noise:

| op | before | after | cached |
|---|---|---|---|
| `range()`, double | 10x | 2x | 1.7x |
| `range()`, integer | 20x | 4x | 2.7x |
| `c()`, double / integer | 25x / 45x | 4x / 7x | 3x / 5x |
| `mean()`, integer | 45x | 6x | 5x |
| `anyNA()`, logical / string | 45x / 45x | 6x / 7x | 2.3x / 5.5x |
| `unique()`, string | 22x | 4x | 3x |
| `c()`, logical / string | 45x / 18x | 7x / 3x | 4.5x / 2x |

`sum()`, `max()`, `anyNA()` of a number and arithmetic were already even, because they take the whole payload through `Dataptr_or_null`.
The first call on an unconverted column, which converts it, drops from 1.5 to 0.9 seconds for `anyNA()` and from 5.5 to 1.8 for `unique()` of the string column.

Before, every element cost a pass through `BEGIN_CPP11`, the guard and the external pointer's checks,
and `c()` paid it twice: a callgrind profile counts one `Dataptr` call per element it copies, from `RealAnswer()` in R's `bind.c`,
and a fast `Length` alone halved its time, so the length is asked for as often.
After that a callgrind profile still put about 65 instructions per element in the methods against about 10 in R:
six calls into R to find the converted vector, and for strings an 8 KB error buffer that `BEGIN_CPP11` reserved in the frame of the fast path too.
The follow-up caches the converted vector's data pointer and length in the column's wrapper on the first read after conversion,
so a method makes two calls into R, `R_altrep_data1()` and `R_ExternalPtrAddr()`, and moves its slow path out of line.
What remains is R's own dispatch and those two calls: R 4.5 reads an ALTREP vector through a method call per element where it reads a plain one in place,
in `c()` (`RealAnswer()` and friends in `bind.c` ask for the length and the data pointer of every element), `range()` (which is `c()`, then `min()` and `max()`),
integer `mean()` (`integer_mean()` in `summary.c`), `anyNA()` of a logical or string (`coerce.c`) and `unique()` of a string (`unique.c`).
Of the class-level methods, `Sum`, `Min` and `Max` are consulted only for integer and double vectors and `No_NA` only by `anyNA()` of those,
which already read the payload whole through `Dataptr_or_null` and cost what a plain vector does,
so none of them would change these numbers.

## Replicating

From this directory, with the build under test first in the library path,
`Rscript ../../scripts/render-reprex.R summaries.R fix`.
The script needs no network, and takes about a minute.
