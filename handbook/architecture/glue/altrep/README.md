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
Touching is R's to do:
every method that can materialize runs on R's thread and nowhere else,
which is [`threading/`](/handbook/architecture/glue/threading/README.md)'s
to hold.

Raising an R error from inside an ALTREP method
is the known weak point:
`rapi_error_with_context()` reports through an R function,
so duckdb's and rlang's closures run
with the method still on the C stack,
where R allows neither allocation nor re-entry.
The report is also the deepest point of the call,
and it costs about 70 KB of C stack that way
against about 9 KB through `Rf_errorcall()` —
so in between, the failure that was already diagnosed
is replaced by *C stack usage is too close to the limit*
([`experiments/2026-08-07-altrep-error-path/`](/experiments/2026-08-07-altrep-error-path/README.md)
measures both).
Guarded by
([#1796](https://github.com/duckdb/duckdb-r/issues/1796),
[#1797](https://github.com/duckdb/duckdb-r/pull/1797)),
at the cost of the `duckdb_error` class on those paths.
A guard that counts down from a destructor
binds everything below it:
every call into R from inside an ALTREP method
goes through `cpp11::safe[]`,
never the R API directly,
or a long-jmp leaves the guard on for the rest of the session.

*To deepen: state what each ALTREP method does with an unmaterialized
relation, and what a duplicated one costs.*
