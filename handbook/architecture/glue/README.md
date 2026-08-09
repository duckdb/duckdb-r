# The C++ glue

The translation units in `src/` that bridge R and DuckDB:
the code this package writes to make two runtimes work as one.
The engine underneath is
[`engine/`](/handbook/architecture/engine/README.md).

Where the two disagree, R's rules win.
The engine can be told to behave differently —
a flag, a patch, a setting, a build of its own —
and R can be told nothing at all:
its allocator, its collector and its single thread
are the fixed points every leaf here is written around.

* [`conventions/`](conventions/) — what the glue is made of, and the rules its C++ obeys
* [`altrep/`](altrep/) — the unexecuted relation R holds as a data frame
* [`threading/`](threading/) — which thread may read R, and what keeps each path into it safe
