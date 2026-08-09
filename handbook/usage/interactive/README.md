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
Only one such handler is installed at a time, so a DuckDB call entered
while another is running — from a progress display callback, say —
fails with `Connection already working on another query` rather than
deadlocking.

**It reaches work the engine executes** — scans, joins, aggregations,
anything running as executor tasks — because the engine reads the
interrupt flag between them.

**It does not reach a wait that never returns to that read**, and a
network request in flight is one.
The flag is set and stays set: the call ends when the request does, and
the interrupt is raised then.
Whether such a wait can be cancelled at all is the extension's to
arrange, not this package's: MotherDuck's sign-in wait arranges it for
the DuckDB CLI and not for R, which is
[#202](https://github.com/duckdb/duckdb-r/issues/202).
Pressing Ctrl+C again changes nothing — the package holds one interrupt
and never escalates, since what a signal handler could do instead costs
more than the wait
([`plan/PLAN-query-cancellation.md`](/plan/PLAN-query-cancellation.md),
measurements in
[`experiments/2026-08-08-interrupt-reach/`](/experiments/2026-08-08-interrupt-reach/README.md)).

## The Connections pane

The Connections pane is RStudio-only and lives in
[`R/Viewer.R`](/R/Viewer.R), adapted from the odbc package's.
It queries `information_schema` to decide which object types the
database actually has, so a database with no views does not advertise
them, and it tells the IDE when a connection closes.

*To deepen: state what turns the progress display on and off, and what
the pane does with a connection the user closes from the IDE.*
