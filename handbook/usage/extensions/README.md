# Extensions

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](/handbook/meta/handbook/);
the last section holds this leaf's parameters.*

Scope: the bundled extension set, autoload vs autoinstall,
and installing more.

Today:

* no single owner yet;
  the natural home is a `?duckdb_extensions` reference page, not yet written

To write this leaf:

* state the shipped set and the autoload / autoinstall defaults,
  verified against a **vendored build** — never under
  `DUCKDB_R_USE_SYSTEM_LIB=1`: the release libduckdb links extra
  extensions (`icu`, `json`, `autocomplete`) and flips
  `autoinstall_known_extensions`
* drain: #66, #100, #117, #202, #1083, #1581, #2306
* stage the facts here until a `?duckdb_extensions` reference page
  exists, then invert to a pointer
