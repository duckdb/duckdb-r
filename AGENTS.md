# Working on duckdb-r

This repository is the R package for DuckDB: the R layer that presents a
DBI driver and a relational API, the C++ glue in `src/` that bridges it
to the engine, and a vendored copy of the DuckDB C++ engine in
`src/duckdb/`.

Everything this project documents lives in
[`handbook/`](https://r.duckdb.org/handbook/README.md), the single
source of truth. This page only routes there.

## The first five minutes

- get a working environment, cold start:
  [`contributors/setup/`](https://r.duckdb.org/handbook/contributors/setup/README.md)
- build in seconds instead of minutes:
  [`build/fast-paths/`](https://r.duckdb.org/handbook/build/fast-paths/README.md)
- build from source, the way CRAN does:
  [`build/source-build/`](https://r.duckdb.org/handbook/build/source-build/README.md)
- find the build knobs and what they cost:
  [`build/configuration/`](https://r.duckdb.org/handbook/build/configuration/README.md)
- run the suite, or one test file:
  [`testing/suite/`](https://r.duckdb.org/handbook/testing/suite/README.md)
- write R the way this package does, flavor seam included:
  [`architecture/r-layer/conventions/`](https://r.duckdb.org/handbook/architecture/r-layer/conventions/README.md)
- know which tidyverse rules are enforced here, and where we deviate:
  [`architecture/r-layer/style/`](https://r.duckdb.org/handbook/architecture/r-layer/style/README.md)
- write C++ glue the way this package does:
  [`architecture/glue/`](https://r.duckdb.org/handbook/architecture/glue/README.md)
- operate the vendoring loop:
  [`operations/vendoring/series-loop/`](https://r.duckdb.org/handbook/operations/vendoring/series-loop/README.md)
  and `.claude/skills/`
- write a sentence the way this repository does, before you write one:
  [`meta/authoring/`](https://r.duckdb.org/handbook/meta/authoring/README.md)
  and
  [`meta/style/`](https://r.duckdb.org/handbook/meta/style/README.md)
- know what this repository decides for itself, and the rules it adopts
  beyond the shared ones:
  [`meta/local/`](https://r.duckdb.org/handbook/meta/local/README.md)

## Everything else

Anything not on this page is in the tree, and walking down from
[`handbook/`](https://r.duckdb.org/handbook/README.md) is how you find
it: internal nodes navigate, leaves explain, and every fact has exactly
one leaf that owns it — including the limits, the declined requests, and
the reasons ([the
rules](https://r.duckdb.org/handbook/meta/handbook/README.md)). Start at
the root and follow the scope sentences; searching the tree is the
slower path.

## Behaviour

- Every document outside `handbook/` either derives from it or
  backreferences the node it serves. In Claude Code the prose rules load
  on their own when you touch a file carrying prose; run `/docs:check`
  after touching documentation.

------------------------------------------------------------------------

*The shared pages under `handbook/meta/` point to their home,
[`cynkra/handbook-tools`](https://github.com/cynkra/handbook-tools); the
rule file and the skills are carried from there unchanged, and
[`.handbook-source`](https://r.duckdb.org/.handbook-source) names the
files and the state of the source this handbook was last checked
against.*
