# Threading

Which thread may read R, which may not, and what makes each path from
the engine into R safe — including the one that is safe only because
R is not running.

**Only R's thread reads R.**
The engine executes on a task scheduler,
so a table function's scan runs on whichever thread takes the task,
and reading an R vector there is not safe:
an ALTREP method allocates,
may evaluate R code,
and may collect garbage.
Bind is where that is avoided.
It runs on the thread that issued the query, which is R's,
and it reduces the whole data frame to plain memory
before the engine can schedule anything.
[`src/scan.cpp`](/src/scan.cpp)'s `TouchColumn()` walks a column to its leaves —
the vectors packed inside a struct column or a matrix,
and every cell of a list column —
so that what the scan later dereferences is a pointer bind already took.
It descends by SEXP rather than by type,
and covers more than the scan reads:
a list cell is not expected to hold an ALTREP vector,
and the walk goes there anyway,
because over-covering costs a wide data frame some bind time
and under-covering costs a session.
Eagerness is the same trade,
since bind does not know which columns a query projects.
Both are what a scan cannot do for itself —
holding a task thread, it has no way to ask R for a value —
and a producer thread
([#2583](https://github.com/duckdb/duckdb-r/pull/2583))
is what would supply one,
keeping every R allocation on R's thread
so the work could move back to the value that is read.
What breaking the rule costs —
a wrong answer with no diagnostic, or a killed session —
is measured in
[`experiments/2026-08-08-altrep-scan-threads/`](/experiments/2026-08-08-altrep-scan-threads/README.md).

**The other paths into R, and what keeps each of them safe.**
The Arrow scan calls R to produce its stream,
and that call is moved onto the scheduling thread by
`INITIALIZE_ON_SCHEDULE`
([`src/database.cpp`](/src/database.cpp));
the batches that follow come from an Arrow C++ reader
[`R/register.R`](/R/register.R) exports,
so pulling one never re-enters R.
The progress display evaluates an R callback,
but its only caller runs under the client context lock,
which is to say on the thread that issued the query.
Materializing a relation
([`altrep/`](/handbook/architecture/glue/altrep/README.md))
evaluates R too,
and is reached only from an ALTREP method or from bind,
both of them R's thread.
Underneath all three sits the same load-bearing fact:
for the length of a query,
R's thread is blocked inside the engine and mutates nothing,
which is what makes even a plain read of an R object from a task thread safe.
The scan still takes such reads —
a cell out of a list, a `class` attribute,
a factor cell's levels through R's translation buffer.
So the inventory is not a licence to run R concurrently:
a producer thread ends the blocking that underwrites it,
which is why #2583 guards per connection
rather than trusting this list.

**The engine runs R code while it holds the client context lock.**
The replacement scans and the Arrow stream factory in
[`src/register.cpp`](/src/register.cpp),
and the progress display in
[`src/connection.cpp`](/src/connection.cpp),
are all reached from underneath a query the engine is already executing.
R may collect garbage in any of them,
and a collection runs the finalizer of every engine handle
the session has stopped referencing,
at a point no R code chose.
So no such finalizer may re-enter the client context it belongs to:
the context lock is not recursive,
and the callback's caller already owns it.
The rule binds the finalizers rather than the callbacks,
because a callback cannot know what R will collect inside it;
[`tests/testthat/test-progress_display.R`](/tests/testthat/test-progress_display.R)
pins it by collecting an abandoned handle
from inside the display's callback lookup.

*To deepen: name the scan's remaining task-thread reads per call site,
as #2583's audit settles each.*
