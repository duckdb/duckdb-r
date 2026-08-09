# Interactive use

What a session does while you work, rather than what a call returns
once it is over — and whether this package does it,
or hands it to something that does.

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

## The DuckDB UI

The DuckDB UI is a browser interface the engine serves,
and it arrives as the `ui` extension rather than as part of this
package: `INSTALL ui` once, then `CALL start_ui()` on a connection
starts the server and opens a browser at it
([#1083](https://github.com/duckdb/duckdb-r/issues/1083)).
Nothing about it is R-side — no function to call, nothing to configure —
so what the UI can do, and whether it installs on a platform at all,
are the extension's and its repository's
([`extensions/`](/handbook/usage/extensions/README.md)).
The DuckDB CLI's `-ui` flag is that program's own installation
and says nothing about this one's;
a page that comes up empty is the extension's to answer, in
[duckdb/duckdb-ui](https://github.com/duckdb/duckdb-ui).

*To deepen: state what turns the progress display on and off, what
the pane does with a connection the user closes from the IDE, and how
much of a connection's own state the UI sees.*
