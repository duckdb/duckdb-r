# Interactive use

What a session does while a query runs, rather than what the call
returns once it is over:
the progress display, how far Ctrl+C reaches, and the RStudio
Connections pane.

## The progress display

The progress display is the engine calling back into R.
The C++ side holds the symbol it invokes
(`get_progress_display_sym` in
[`src/include/rapi.hpp`](/src/include/rapi.hpp)),
and [`R/progress_display.R`](/R/progress_display.R) draws it,
throttled so that a fast query never paints:
updates closer together than half a second are dropped.

## Interrupting a query

Ctrl+C during a DuckDB call is caught by the package rather than by R.
[`src/signal.cpp`](/src/signal.cpp) installs a handler for the duration
of the call, asks the engine to stop through
`ClientContext::Interrupt()`, and raises the R interrupt once the call
returns — so the condition surfaces at the R level, catchable, instead
of the engine unwinding on its own.

**It reaches work the engine executes**: scans, joins, aggregations,
and anything else that runs as executor tasks,
because the engine reads the interrupt flag between them.

**It does not reach a wait that never returns to that read.**
A network request in flight is the case that matters:
an `ATTACH` over HTTP blocks there, and so does `ATTACH 'md:'` while it
waits for a browser sign-in.
Letting the request fail, or dismissing the browser page, ends the wait,
and the interrupt lands then;
until it does, the way out is another R session, or ending this one.
Pressing Ctrl+C again changes nothing — the package holds one interrupt
and never escalates, deliberately, since the alternatives available to
a signal handler cost more than the hang
([`plan/PLAN-query-cancellation.md`](/plan/PLAN-query-cancellation.md)).

Neither the ceiling nor the flag is the package's alone.
R's own interrupt stops at the same place, C code that never calls
`R_CheckUserInterrupt()` being uninterruptible whoever wrote it;
and the handler here sets the same engine flag the DuckDB CLI's does,
so a wait that ignores the flag ignores it in the shell too.

**A wait is cancellable only if the code doing the waiting makes it so**,
and that code is the extension's.
MotherDuck's sign-in wait is the worked example: in the DuckDB CLI it
installs a SIGINT handler of its own for the duration of the wait, which
is why Ctrl+C ends it there, and under this package it installs none —
so the key reaches the handler here, which sets a flag that wait does
not read.
Nothing in the package's own signal handling can substitute for that:
it is not displacing anything, and it already sets the only flag it has
to offer.

What decides is the name the client announces.
The package announces `duckdb_api = "r-dbi"`
([`src/database.cpp`](/src/database.cpp)) where the shell announces
`cli`, and MotherDuck installs its handler for the one and not the
other — so telling the connection to use the shell's name makes the
sign-in wait cancellable:

```r
library(duckdb)

# Ctrl+C does not reach the sign-in wait
con <- dbConnect(duckdb())
dbExecute(con, "ATTACH 'md:'")

# ... and does, when the connection answers to the shell's name
con <- dbConnect(duckdb(config = list(duckdb_api = "cli")))
dbExecute(con, "ATTACH 'md:'")
```

That is a diagnosis before it is a remedy, and the cost is the name
itself: nothing else that asks can tell such a connection from the
shell either, so every answer keyed on the client is now the shell's.
What ends the wait is then MotherDuck's handler rather than this
package's, so the statement fails with MotherDuck's own error and no R
interrupt condition is raised — `HandleInterrupt()` raises only when the
handler here is the one that ran, and it did not.
Closing [#202](https://github.com/duckdb/duckdb-r/issues/202) properly
is MotherDuck's, either by installing that handler for every client or
by reading the flag this package already sets.
The measurements are
[`experiments/2026-08-08-interrupt-reach/`](/experiments/2026-08-08-interrupt-reach/README.md),
which carries the probe that reads the handler from inside a blocked
process, and needs no debugger on either platform.

Only one interrupt handler is installed at a time.
A second DuckDB call entered while one is running — from a progress
display callback, say — fails fast with `Connection already working on
another query` rather than deadlocking.

## The Connections pane

The Connections pane is RStudio-only and lives in
[`R/Viewer.R`](/R/Viewer.R), adapted from the odbc package's.
It queries `information_schema` to decide which object types the
database actually has, so a database with no views does not advertise
them, and it tells the IDE when a connection closes.

*To deepen: state what turns the progress display on and off, and what
the pane does with a connection the user closes from the IDE.*
