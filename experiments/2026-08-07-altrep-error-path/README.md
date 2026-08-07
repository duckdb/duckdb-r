# Raising an error from inside an ALTREP method

*What it measures:* what actually runs when an ALTREP method of a
duckdb relation fails — which R code executes with the method still on
the C stack, what the caller receives, and what the `AltrepGuard` of
[#1797](https://github.com/duckdb/duckdb-r/pull/1797) changes.
It exists because [#1796](https://github.com/duckdb/duckdb-r/issues/1796)
names a symptom (stack overflows) without a reproducer,
and the fix should be judged against what is measurable.

*When and on what:* 2026-08-07, Linux x86_64,
R 4.5.3, rlang 1.3.0, duckdb 1.5.5.9010,
built from `main` at a159e0d9 and from the branch of #1797
rebased onto it, both through the
[fast path](/handbook/build/fast-paths/README.md)
against the same prebuilt libduckdb v1.5.5.
Three legs: `main`, #1797 as proposed, and #1797 with the
`cpp11::safe[Rf_eval]` fix that section 3 below argues for.
[`run.sh`](run.sh) builds two legs and runs [`probe.R`](probe.R)
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

With the guard, the same two-frame tail R would produce for any C-level
error:

```
   10. .row_names_info
   11. .handleSimpleError
   12. h
```

No package code, no rlang. That is the claim of #1797, and it holds.

The C stack below the caller measures 42,864 bytes on `main` and
47,360 with the guard — the guard leg is *larger* by about 4.5 KB,
because `Rf_errorcall()`'s own machinery sits where the nested
`Rf_eval()` used to. **The change does not buy stack headroom**;
it buys not running R code in a place R does not allow it.

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
every call into R below it to unwind rather than long-jmp. One does
not: `AltrepRelationWrapper::GetQueryResult()` evaluates the
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

## 4. Re-entrant access still ends at the C stack limit

A condition handler that touches the failing object again, installing
a fresh handler each round so nothing truncates the cycle:

```
main             251 rounds, then "C stack usage 7970260 is too close to the limit"
#1797            232 rounds, then "C stack usage 7973348 is too close to the limit"
#1797 + safe[]   232 rounds, then "C stack usage 7987860 is too close to the limit"
```

Both end in a catchable R error, neither crashes, and the guard leg
gets *fewer* rounds. So the guard is not a fix for stack exhaustion
under re-entrant access, and #1796's stack overflows are not
reproduced by this shape — whatever produced them needs a separate
reproducer.

**What it shows.**
#1797's premise is correct and measurable: on `main`, duckdb and rlang
closures execute inside ALTREP methods, and the guard removes them.
What it does not do is what #1796 asked for by name — nothing here
consumes less stack, and re-entrant recursion is unchanged. Against
that, ALTREP-raised errors lose their class and fields. And the guard
needs the `Rf_eval()` above it to be unwind-safe: without that one
line, a single erroring materialize callback degrades every duckdb
error for the rest of the session, which is a wider regression than the
one the guard repairs.
