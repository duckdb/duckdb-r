# Scanning a registered ALTREP data frame with a packed column

*What it measures:* what a scan returns when it reaches a registered
ALTREP data frame's packed column itself, on a DuckDB task thread,
rather than being handed one bind already read —
right answer, silently wrong answer, or no session left —
across thread count and struct field type,
before and after bind started walking into such a column.

*When and on what:* 2026-08-08, duckdb 1.5.5.9012
(DuckDB 1.5.5, fast-path build against the release `libduckdb`),
R 4.5.3, Linux, 4 cores, 3,000,000 rows.

*What it supports:*
[`architecture/glue/threading/`](/handbook/architecture/glue/threading/README.md).

Run [`run.sh`](run.sh) under `ulimit -c 0`;
one attempt is [`scan.R`](scan.R),
and the recorded runs are [`before.md`](before.md) and
[`after.md`](after.md).

**The shape being measured.**
`rel_to_altrep()` returns a data frame whose `s` column is itself a data
frame, of ALTREP vectors.
`nrow()` runs the relation and caches its result,
which leaves the per-column transforms undone.
`duckdb_register()` then binds that data frame on a second connection:
bind reads the pointer of every flat column,
and before `TouchColumn()` handed the packed one back unread,
so that the scan was what reached inside `s` —
allocating R vectors, and evaluating R,
on whichever thread took the scan task.
A list column is packed differently and is not measured here.
The walk covers its cells too — a cell can hold an ALTREP vector,
even though one rarely does — but no shape that reaches one
through a list was found to build cheaply.

**`SET threads` is a ceiling, not the count.**
What decides how many threads meet one column is the scan's own split,
one task per million rows
(`DataFrameScanMaxThreads()`, [`src/scan.cpp`](/src/scan.cpp)),
so the `threads=4` cell is three tasks at three million rows
and two at two million.
Two is already enough to corrupt and, at that size, not enough to kill:
the spot check at the end of [`before.md`](before.md)
is where the regression test in `tests/testthat/test-scan.R`
takes its row count from.

**What the numbers say.**
Nothing failed on one thread, in either field type.
On more than one, nothing succeeded.
A numeric field failed silently every time —
20 wrong sums in 20 attempts, no warning, no message, exit status 0.
A character field ended the session in 18 of 20 attempts
(10 stopped by R, 8 by SIGABRT),
and returned a wrong answer in the other 2.
The character field is the louder one
because its transform allocates a CHARSXP per row
and so meets R's global string cache and its collector;
the numeric one only writes doubles into a vector
another thread has already replaced.
