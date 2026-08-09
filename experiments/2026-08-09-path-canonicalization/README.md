# Path canonicalization: what the engine knows that R does not

*What it measures:* what DuckDB reports as a database's path once it has
opened it, how that compares to R's `normalizePath()` for the same
spelling, and whether the two ever disagree —
the facts a driver cache keyed on the path depends on
([`usage/connections/`](/handbook/usage/connections/README.md)).
Nine questions, asked identically on three platforms:
canonicalization of spellings for a database that does not exist yet
and one that does, symlinks, case, Windows separators and short names,
a parent directory that cannot be read
([#455](https://github.com/duckdb/duckdb-r/issues/455)'s shape),
whether anything canonicalizes without creating a database,
read-only attach, and cost.

*When and on what:* 2026-08-09,
`ubuntu-latest`, `macos-latest` and `windows-latest` GitHub runners,
R release with DBI and duckdb installed from CRAN — no source build,
because the questions are about path semantics
and a released binary answers them as well.
Method: [`probe.R`](probe.R), driven by
`.github/workflows/probe-path-facts.yaml` on the branch that carries
this directory. That branch drops every other workflow on purpose
and is not meant to merge.

*What it supports:* the normalization bullet in
[`usage/connections/`](/handbook/usage/connections/README.md),
and the decision on whether the driver cache key should come from
`normalizePath()` or from the engine.

## Results

Pending the first matrix run; this section is filled in from it.

The Linux pre-run that shaped the questions
(2026-08-09, DuckDB v1.5.5, in the development container, as root —
so its section 6 proves nothing about permissions):

* Every spelling collapsed to one key: `..`, doubled separators,
  a trailing separator, a relative path, and `./` all reduced to the
  same string, and it was the string `normalizePath()` produced.
* Symlinks resolved, both a symlinked directory and a symlinked
  *file* — the engine's canonicalization is `realpath`-equivalent,
  not string arithmetic.
* Nothing else canonicalizes. `glob()` resolves a symlinked directory
  but leaves `..` untouched, returns nothing for a path that does not
  exist, and `parse_path()` is pure string splitting. `ATTACH` is the
  only route.
* Read-only attach of a database that does not exist fails and creates
  nothing.
* **A zero-byte file is not a valid database**: the engine refuses it
  with `exists, but it is not a valid DuckDB database file!`. The
  placeholder the package writes today is exactly that, which makes
  deleting it load-bearing rather than tidy.
* Cost per call: ~40 ms for a throwaway instance plus attach and
  detach, ~4 ms for attach and detach on a connection already open,
  ~0.3 ms for the current create-normalize-unlink.
