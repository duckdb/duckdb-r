# The C++ glue

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.*

Scope: the translation units bridging R and DuckDB —
cpp11, `RStrings`, ALTREP relations, error rethrow —
and the C++ source conventions:
formatting, and the no-warning-suppression policy.

Today:

* [`AGENTS.md`](../../../AGENTS.md) — "C++ Glue Code Conventions"
  and "C++ Warning Policy"
* [`scripts/format.py`](../../../scripts/format.py) —
  formats `src/`, driven by the Makefile's `format-*` targets
* `src/GLUE.md` is proposed in
  [#2443](https://github.com/duckdb/duckdb-r/pull/2443)
