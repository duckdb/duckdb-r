# ALTREP relations

The C++ half of the data frame R holds before the query behind it has
run: what `rapi_rel_to_altrep()` builds, and what makes it run.
The R-facing half, and who consumes it, is
[`usage/relational/`](/handbook/usage/relational/README.md).

`rapi_rel_to_altrep()` wraps an unexecuted relation as a data frame;
nothing runs until R touches the values,
materialization is budgeted by `n_rows` and `n_cells`,
unlimited by default ([`R/relational.R`](/R/relational.R)),
and an execution error is stored and re-raised at every later access.
What materializing allocates, and when the engine's copy of the result
is released after conversion, is
[`usage/memory/reading/`](/handbook/usage/memory/reading/README.md)'s.
Touching is R's to do:
every method that can materialize runs on R's thread and nowhere else,
which is [`threading/`](/handbook/architecture/glue/threading/README.md)'s
to hold.

An error inside an ALTREP method stays a plain R error.
The glue leaves its errors pending for the `rethrow_rapi_*()` wrapper around an entry point to raise
([`conventions/`](/handbook/architecture/glue/conventions/README.md)),
but R calls an ALTREP method wherever it needs a length or a pointer, and no wrapper is on the stack there.
So while an `AltrepGuard` is live, `rapi_error_with_context()` throws a plain exception,
and the method's `END_CPP11` raises it with `Rf_errorcall()`, without the `duckdb_error` class
([#1796](https://github.com/duckdb/duckdb-r/issues/1796), [#1797](https://github.com/duckdb/duckdb-r/pull/1797)).
Raised through an R function instead, duckdb's and rlang's closures ran with the method still on the C stack,
where R allows neither allocation nor re-entry, and at the deepest point of the call:
about 70 KB of C stack against about 9 KB through `Rf_errorcall()`,
so in between the failure already diagnosed was replaced by *C stack usage is too close to the limit*
([`experiments/2026-08-07-altrep-error-path/`](/experiments/2026-08-07-altrep-error-path/README.md) measures both).
A guard that counts down from a destructor
binds everything below it:
every call into R from inside an ALTREP method
goes through `cpp11::safe[]`,
never the R API directly,
or a long-jmp leaves the guard on for the rest of the session.
The allocations part way through converting a column are the exception.
They call R directly, because protecting each one would slow down every list column.
Running out of memory there still leaves the guard on.

*To deepen: state what each ALTREP method does with an unmaterialized
relation, and what a duplicated one costs.*
