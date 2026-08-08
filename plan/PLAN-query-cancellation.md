# Making a blocked DuckDB call cancellable from R

*This is a plan: work proposed, not work done.
What the package does today is
[`usage/interactive/`](/handbook/usage/interactive/README.md)'s,
and where the two disagree, that leaf is right.*

Ctrl+C stops DuckDB work the engine executes, and stops nothing else.
A call that blocks inside an operation — a network request above all —
never returns to the point where the engine reads its interrupt flag,
so the interrupt sits recorded until the wait ends on its own.
[#202](https://github.com/duckdb/duckdb-r/issues/202) is the case users
meet: `ATTACH 'md:'` waits there for a browser sign-in.
The measurements are
[`experiments/2026-08-08-interrupt-reach/`](/experiments/2026-08-08-interrupt-reach/README.md);
what they establish, and matters here, is that the package's handler is
armed throughout such a wait and does set the engine's flag —
so nothing on this list is about making it ask harder.

This plan exists because the fix is larger than the limitation:
two routes lead out, neither of them small, and one of them is not this
repository's to take.

## Step 0 — settle what MotherDuck watches

A single Ctrl+C does abort the `ATTACH 'md:'` wait in the DuckDB CLI,
with a message MotherDuck prints itself.
It cannot be reading the engine flag, since R sets that flag identically
and nothing happens.
Until it is known what it does read, neither route below can be aimed at
[#202](https://github.com/duckdb/duckdb-r/issues/202) specifically —
Route 1 might already be someone else's to finish, or the difference
might turn out to live in the process-wide SIGINT disposition, which is
this package's doing and nobody else's.
The experiment carries the probe and what to run it against.

## Route 1 — the wait observes the flag

The durable fix is that the blocking operation checks
`ClientContext::interrupted` while it waits, so an interrupt ends the
wait instead of outliving it.
That is engine and extension work, not R work:
upstream `HTTPUtil::RunRequestWithRetry` checks nothing while a request
is in flight and nothing between retries,
and an extension that runs its own sign-in loop would need the same
check in that loop.

Nothing in this repository can substitute for it,
and everything below is a way of surviving its absence.
The package's part is to keep asking:
the handler already sets the flag the moment Ctrl+C arrives,
so the day a wait starts reading it, R inherits the fix for free.

## Route 2 — the R main thread stops being the one that waits

Run the engine call on a worker thread and leave the R main thread in a
loop of `R_CheckUserInterrupt()` and a bounded wait.
Then Ctrl+C is R's ordinary interrupt again, and it returns control
whether or not the engine can be persuaded to stop.

This is the shape the issue's own discussion reached, and its cost is
the callbacks.
Several things the engine does during a call run R code, and R's API is
single-threaded: scanning a registered data frame
([`architecture/glue/`](/handbook/architecture/glue/README.md)),
drawing the progress display, and calling an R function registered as a
UDF.
Moving the call off the main thread means every one of those has to be
marshalled back to it, with the worker blocked meanwhile —
which is the actual project here, and is what makes this more than a
patch to [`src/signal.cpp`](/src/signal.cpp).

Returning control while the worker is still blocked leaves the
connection in use by a thread nobody is waiting for;
the connection would have to be marked unusable rather than closed,
since closing it means joining that thread.

## Not taken: abandoning the call from the handler

Escalating in the handler — a second Ctrl+C calling `Rf_onintr()` — is
what would return the prompt today, without threads or upstream work.
It is rejected rather than deferred.
The longjmp leaves the C++ frames of a running query unwound: the
`ClientContext` lock is never released, so the connection deadlocks on
next use rather than erroring, destructors that free engine state never
run, and the handler's own instance pointer is left dangling into a
stack frame that no longer exists.
Trading a hung call for a corrupted session is not an improvement, and
the CLI's version of the same idea is `exit(1)` — honest there because
the process is disposable, and not available to an R session.
