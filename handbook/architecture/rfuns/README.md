# The `rfuns` extension

A DuckDB extension compiled into this package that gives the engine
R's own semantics for a handful of functions,
so a computation pushed down to DuckDB answers the way R would.

[`src/rfuns.cpp`](/src/rfuns.cpp) and
[`src/include/rfuns_extension.hpp`](/src/include/rfuns_extension.hpp)
register it like any DuckDB extension, in `namespace duckdb::rfuns`.
What it covers is what its tests cover —
`tests/testthat/test-rfuns*.R`, on `sum`, `min`/`max`, `na.rm`
handling, and mixed argument types — which is where the R-versus-SQL
differences are.

**It is a second vendored upstream**, on its own schedule.
The sources come from a `duckdb-rfuns` checkout by
[`scripts/vendor-rfuns.sh`](/scripts/vendor-rfuns.sh),
one commit per import, carrying the upstream log —
not by the engine's pipeline
([`operations/vendoring/`](/handbook/operations/vendoring/README.md)),
which advances `src/duckdb/` alone.

*To deepen: name the functions it defines and what each does
differently from the engine's own, and state how an import is
verified.*
