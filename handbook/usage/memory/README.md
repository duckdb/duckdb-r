# Memory

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: what `memory_limit` bounds and what it does not,
`temp_directory` and spill, streaming results.

Today:

* no single owner yet;
  the natural home is a `?duckdb_memory` reference page, not yet written

To write this leaf:

* own: what `memory_limit` bounds and what it does not
  (not R-side result buffers), `temp_directory` and spill,
  streaming via the Arrow interface
* drain: #72, #97, #1065, #1604, #1997
* stage the facts here until a `?duckdb_memory` reference page exists,
  then invert to a pointer
