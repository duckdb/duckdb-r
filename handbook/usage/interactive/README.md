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
`ATTACH` over HTTP blocks there, and so does `ATTACH 'md:'` while it
waits for a browser sign-in, which is why Ctrl+C does not cancel
MotherDuck authentication
([#202](https://github.com/duckdb/duckdb-r/issues/202), open).
Cancelling in the browser ends the wait, and the interrupt lands then;
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
Where the shell still differs is for `ATTACH 'md:'` in particular, and
by what means is not yet established.
The measurements live in
[`experiments/2026-08-08-interrupt-reach/`](/experiments/2026-08-08-interrupt-reach/README.md),
along with the probe that would settle it,
which reads the handler from inside the process and so needs no
debugger on either platform.

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

*To deepen: state what turns the progress display on and off, what the
pane does with a connection the user closes from the IDE, and — once
[#202](https://github.com/duckdb/duckdb-r/issues/202) has been measured
in a session that reaches MotherDuck — what the shell does there that
this package does not.*
