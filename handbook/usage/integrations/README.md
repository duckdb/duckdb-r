# Integrations

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: the dbplyr backend and Arrow interchange.

Today:

* `?backend-duckdb` — the dbplyr backend reference
* [`plan/PLAN-dbSendQueryArrow.md`](../../../plan/PLAN-dbSendQueryArrow.md) — the DBI Arrow API plan

To write this leaf:

* own: dbplyr backend semantics (what pushes down, translation
  boundaries) and Arrow interchange; `?backend-duckdb` stays the
  translation reference
* drain: #162, #209, #384, #1064, #1585, #1982, #2029, #2230
  (#642's Polars recipe lands in `types/`, per the triage)
