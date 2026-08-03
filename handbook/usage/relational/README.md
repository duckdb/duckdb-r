# The relational API

Building a query as a *relation* — a lazy node graph — instead of a SQL
string, and handing the result to R as an ALTREP data frame.
It is **internal**: nothing here is exported or documented for users,
and the one supported consumer is duckplyr
([`integrations/`](/handbook/usage/integrations/README.md)).
The DBI and dbplyr routes are what a user reaches for
([`connections/`](/handbook/usage/connections/README.md)).

**Can I use it?** Not supportedly.
Every function in [`R/relational.R`](/R/relational.R) is marked `@noRd`,
so none reaches `NAMESPACE` and none gets a reference page;
calling one means `duckdb:::`, and a `:::` caller has no promise that the
next release keeps the signature.
The answer is deliberate rather than an oversight —
see the coupling below for what it costs to change.

**What a relation is.**
`rel_from_df()` turns a data frame into a relation without copying it;
`rel_from_table()`, `rel_from_table_function()` and `rel_from_sql()`
start from the database side.
From there the verbs compose —
project, filter, aggregate, order, limit, the joins, the set operations —
each returning a new relation and executing nothing.
Expressions are built separately (`expr_reference()`, `expr_constant()`,
`expr_function()`, `expr_comparison()`, `expr_window()`),
so a caller assembles a tree rather than splicing text,
and the engine never parses a string the caller built.

**How a result comes back.**
`rel_to_altrep()` wraps an unexecuted relation as a data frame:
nothing runs until R touches the values, materialization is budgeted by
`n_rows` and `n_cells`, and an execution error is stored and re-raised at
every later access.
`rel_from_altrep_df()` is the way back.
The C++ side of that, and its known weak point around raising an R error
from inside an ALTREP method, is
[`architecture/glue/`](/handbook/architecture/glue/README.md)'s.
`rel_to_parquet()`, `rel_to_csv()`, `rel_to_table()` and `rel_to_view()`
execute to a destination instead.

**The coupling is the reason this page exists.**
The API grew to serve duckplyr — `NEWS.md` records rounds of "internal
changes to support the duckplyr package" — and being internal does not
make it free to change:
`rel_to_altrep()` still carries
`# FIXME: Move dots after `rel` for duckplyr >= 1.1.0`,
a signature held in place by a downstream version.
So a change here is negotiated with duckplyr rather than merely reviewed,
and duckplyr is the reverse dependency a behaviour change is checked
against first
([`testing/revdep/`](/handbook/testing/revdep/README.md)).

*To deepen: state which verbs duckplyr actually calls, so a change can be
scoped against real use rather than the whole surface;
drain the `rel_to_altrep()` signature FIXME when duckplyr's floor allows.*
