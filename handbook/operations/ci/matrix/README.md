# The matrix

Which platforms and R versions the `rcc` check covers
([`per-commit/`](/handbook/operations/ci/per-commit/README.md)),
and how an entry gets added.
The matrix is *derived, not listed*:
[`.github/workflows/versions-matrix/action.R`](/.github/workflows/versions-matrix/action.R)
reads the live R tag list and this package's `Depends: R` floor,
and builds the base entries from them —
so a new R release enters the matrix without a commit.

The base shape: R-devel and the recent releases on Linux amd64,
fewer of them on macOS, Windows, and Linux arm64,
plus a coverage entry.
Which versions land where is the action's,
and the reasoning is in its comments.

[`.github/versions-matrix.R`](/.github/versions-matrix.R) is this
repository's extension of that base — the named special entries:

* **older Windows** — extends the Windows sweep further back
  than the base shape carries it.
* **engine poisoning** —
  builds the engine with the `-DDUCKDB_R_POISON_ENGINE` tripwire
  and forces `DUCKDB_R_RUN_TESTS=false`,
  verifying that the CRAN guards keep the engine untouched
  ([`testing/guards/`](/handbook/testing/guards/README.md)).
* **vendored builds** — one Linux and one macOS entry pin
  `DUCKDB_R_USE_SYSTEM_LIB=0`
  so the CRAN-shaped artifact still compiles,
  because regular Linux and macOS entries default to the fast path
  ([`build/fast-paths/`](/handbook/build/fast-paths/README.md));
  Windows always builds from source, for now
  ([#22](https://github.com/duckdb/duckdb-r/issues/22#issuecomment-5158085048)).

Entries carry extra environment through the generic `env` field —
the mechanism by which one matrix row can flip any knob
([`build/configuration/`](/handbook/build/configuration/README.md)).

*To deepen: state how the base action derives its version window,
and what `Config/gha/filter` would remove from it —
this package sets no such field today.*
