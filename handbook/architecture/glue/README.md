# The C++ glue

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: the translation units bridging R and DuckDB —
cpp11, `RStrings`, ALTREP relations, error rethrow —
and the C++ source conventions:
formatting, and the no-warning-suppression policy.

Today:

* [`AGENTS.md`](../../../AGENTS.md) — "C++ Glue Code Conventions"
  and "C++ Warning Policy"
* [`scripts/format.py`](../../../scripts/format.py) —
  formats `src/`, driven by the Makefile's `format-*` targets

To write this leaf:

* absorb: `AGENTS.md` §§ "C++ Glue Code Conventions" and
  "C++ Warning Policy" — the `RStrings` rule, no warning
  suppression; formatting runs via the Makefile `format-*` targets
* drain: #540, #1147, #1796
