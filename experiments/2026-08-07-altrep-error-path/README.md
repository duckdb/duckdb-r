# Raising an error from inside an ALTREP method

*What it measures:* what actually runs when an ALTREP method of a
duckdb relation fails, how much C stack that costs, and what the
`AltrepGuard` of
[#1797](https://github.com/duckdb/duckdb-r/pull/1797) changes.
It exists because [#1796](https://github.com/duckdb/duckdb-r/issues/1796)
names a symptom — stack overflows — without a reproducer.
Section 4 is that reproducer.

*When and on what:* 2026-08-07, Linux x86_64,
8 MB stack (`ulimit -s 8192`),
R 4.5.3, rlang 1.3.0, duckdb 1.5.5.9010,
built from `main` at a159e0d9 and from the branch of #1797
rebased onto it, both through the
[fast path](/handbook/build/fast-paths/README.md)
against the same prebuilt libduckdb v1.5.5.
Four legs: `main` as built, `main` with
`duckdb:::rapi_error()` swapped for a plain `stop()` before the first
error (which isolates rlang's share), #1797 as proposed, and #1797
with the `cpp11::safe[Rf_eval]` fix section 3 argues for.
[`run.sh`](run.sh) builds two refs and runs [`probe.R`](probe.R)
against each; the probe alone takes an installed library.

*What it supports:* the ALTREP paragraph in
[`architecture/glue/`](/handbook/architecture/glue/README.md).

## 1. What runs inside the ALTREP method

`nrow(x)` reaches `RelToAltrep::RownamesLength()` through
`.row_names_info()`, so a condition handler can name every R frame
below it. On `main`, four:

```
   10. .row_names_info
   11. function (context, message, error_type = NULL, ...)   <- duckdb:::rapi_error_rlang
   12. rlang::abort
   13. signal_abort
   14. signalCondition
```

Those are R closures — one of duckdb's, three of rlang's — evaluated
by `rapi_error_with_context()` with the ALTREP method live on the C
stack, and they are the whole of what #1796 objects to. R does not
support this: an ALTREP method is called from wherever the interpreter
needs a length or a pointer, and evaluating R there allocates, can
collect, runs condition handlers, and can re-enter the same object.

With the guard, the same two-frame tail R produces for any C-level
error, and no package code at all:

```
   10. .row_names_info
   11. .handleSimpleError
   12. h
```

## 2. What the caller sees

`main`:

```
class  : duckdb_error/rlang_error/error/condition
message: Materialization is disabled, use `collect()` or `as_tibble()` to materialize.
         ℹ Context: GetQueryResult
```

with the guard:

```
class  : simpleError/error/condition
message: GetQueryResult: Materialization is disabled, use `collect()` or `as_tibble()` to materialize.
```

The cost is real and larger than a reformatting: errors raised from
ALTREP methods lose the `duckdb_error` class and the structured
`context` / `error_type` / `raw_message` / `extra_info` fields, so
`tryCatch(duckdb_error = )` no longer catches them. The flat text is
exactly the shape `rapi_error()` produces when rlang is absent
(`paste0(context, ": ", message)`), so the package now has one message
format across two paths rather than a third one.

## 3. A long-jmp leaves the guard stuck on

`AltrepGuard` decrements its counter from a destructor, so it needs
every call into R below it to unwind rather than long-jmp. One did
not: `AltrepRelationWrapper::GetQueryResult()` evaluated the
`duckdb.materialize_callback` option with a bare `Rf_eval()`
(`src/reltoaltrep.cpp`). An R error there jumps straight past
`~AltrepGuard()`.

The probe raises one, then asks an entry point with no ALTREP method
anywhere on the stack for an error and looks at its shape:

```
                        main         #1797        #1797 + safe[]
before the long-jmp     bullet form  bullet form  bullet form
after the long-jmp      bullet form  FLAT FORM    bullet form
```

`FLAT FORM` is the counter stuck at 1 for the rest of the session:
from then on *every* `rapi_error_with_context()` on that thread takes
the guarded branch, and every duckdb error — connection, query,
registration, nothing to do with ALTREP — loses its condition class and
its fields. duckplyr sets that callback, so the trigger is not exotic.

Spelling the call `cpp11::safe[Rf_eval]` fixes it: cpp11 turns the
long-jmp into a C++ exception, the destructor runs, `END_CPP11`
re-raises. It is what `RProgressBarDisplay::Update()`
(`src/connection.cpp`) already does with its callback, and the same
line also stops the `cpp11::sexp` holding the call from leaking off
the preserve list. `tests/testthat/test-relational.R` pins it.

## 4. The stack overflow

Reporting an error costs stack, and the report happens at the deepest
point of the call — so below some amount of free stack, the error path
overflows while trying to describe a failure that has already been
diagnosed. The caller is then told

```
Error: C stack usage  7971860 is too close to the limit
```

when the truth was "materialization is disabled". That is #1796's
symptom, and it is a property of the error path, not of the workload.

The probe recurses in R until that happens and reports the free stack
at the ALTREP entry on either side of the crossover:

```
                                real error through   C-stack error from
main, as built                        71,433 bytes         68,089 bytes
main, plain stop() rapi_error         34,681 bytes         31,337 bytes
#1797 (guard)                         11,465 bytes          8,121 bytes
#1797 + safe[]                        11,353 bytes          8,009 bytes
```

One run each; repeats move the figures by a kilobyte or so, and the
separation between the legs is an order of magnitude larger than that.

So the guard cuts what the error path demands by about **8×**, from
~70 KB to ~9 KB, and any workload that reaches an ALTREP method with
between 9 KB and 70 KB of C stack left is told the wrong thing on
`main` and the right thing with the guard. On this machine that band
is R recursion depth 2352 to 2368; at `ulimit -s 512` it is depth 200
to 240, which ordinary recursive user code reaches.

The middle row splits the cost. Calling *any* R closure from the
ALTREP method costs ~35 KB; rlang's `abort()` — the backtrace capture
and the condition machinery — roughly doubles that. So a cheaper
`rapi_error()` would have bought half the headroom, and only not
calling into R at all buys the rest.

What does **not** happen in any leg is a crash: R's stack check fires
first and raises a catchable error every time. Attempts to get past it
— materializing at near-limit stack so DuckDB's bind and execute run
with no `R_CheckStack()` between them, relation trees up to 30,000
projections deep, `on.exit()` re-entry while unwinding, and stack
limits down to 512 KB — all ended in the same clean R error. The
overflow of #1796 is the diagnostic being lost, not the process dying.

## 5. Re-entrant access

A condition handler that touches the failing object again, installing
a fresh handler each round so nothing truncates the cycle:

```
main, as built                 191 rounds
main, plain stop() rapi_error  148 rounds
#1797 (guard)                  173 rounds
```

all ending in `C stack usage ... is too close to the limit`. The
ordering is not a ranking of the legs: it tracks how deep in the error
path the handler happens to be invoked, which is shallower on `main`
(rlang signals the condition before its own peak) and deeper under the
guard (`Rf_errorcall()` signals from further down). Re-entrant
recursion is bounded by R in every leg, and the guard neither helps
nor hurts it.

**What it shows.**
#1797's premise is correct and measurable: on `main`, duckdb and rlang
closures execute inside ALTREP methods, and the guard removes them.
So is #1796's symptom — the error path needs ~70 KB of C stack on
`main` and ~9 KB with the guard, and in between the real message is
replaced by a stack-overflow message. Against that, ALTREP-raised
errors lose their class and fields. And the guard needs the
`Rf_eval()` above it to be unwind-safe: without that one line, a
single erroring materialize callback degrades every duckdb error for
the rest of the session, which is a wider regression than the one the
guard repairs.
