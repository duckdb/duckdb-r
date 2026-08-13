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
is the known weak point —
a crash-class bug with a guard under review
([#1796](https://github.com/duckdb/duckdb-r/issues/1796),
[#1797](https://github.com/duckdb/duckdb-r/pull/1797)).

*To deepen: state what each ALTREP method does with an unmaterialized
relation, and what a duplicated one costs.*
