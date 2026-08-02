# Where to help

Finding work: the label vocabulary, and how to turn it into a live
list of entry points.
The tracker is the list — a saved query is never out of date,
so no curated selection is kept here.

One label invites outside work:
[`help wanted ❤️`](https://github.com/duckdb/duckdb-r/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted+%3Aheart%3A%22).
GitHub renders the shortcode, so the label is *typed* as
`label:"help wanted :heart:"`;
`upstream 🐟` and `duckplyr 🗜️` carry the emoji character and
paste verbatim.
The full vocabulary is the tracker's
[label index](https://github.com/duckdb/duckdb-r/labels);
the boundaries that matter when choosing work:

* `upstream 🐟` — the cause is in the DuckDB engine;
  the fix belongs in `duckdb/duckdb` and arrives here by
  vendoring. `src/duckdb/` is never edited in this repository.
* `reprex` — the report is not yet actionable;
  producing the missing reproducible example is help in its own
  right and needs no build.
* `documentation` — the answer is a page of this handbook,
  the cheapest kind of contribution to finish
  ([the rules](/handbook/meta/handbook/README.md#growing-a-leaf)).

Verdicts and closes are the maintainer's —
[`operations/triage/`](/handbook/operations/triage/README.md) —
so comment on an issue before starting; nothing in the vocabulary
records who is working on what.
Longer-range intent lives in [`plan/`](/plan/README.md)
([`meta/plans/`](/handbook/meta/plans/README.md)).
