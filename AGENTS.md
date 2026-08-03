# Working on duckdb-r

This repository is the R package for DuckDB:
the R layer that presents a DBI driver and a relational API,
the C++ glue in `src/` that bridges it to the engine,
and a vendored copy of the DuckDB C++ engine in `src/duckdb/`.

Everything this project documents lives in
[`handbook/`](/handbook/README.md), the single source of truth.
This page only routes there.

## The first five minutes

| To | Read |
|---|---|
| get a working environment, cold start | [`contributors/setup/`](/handbook/contributors/setup/README.md) |
| build in seconds instead of minutes | [`build/fast-paths/`](/handbook/build/fast-paths/README.md) |
| build from source, the way CRAN does | [`build/source-build/`](/handbook/build/source-build/README.md) |
| find the build knobs and what they cost | [`build/configuration/`](/handbook/build/configuration/README.md) |
| run the suite, or one test file | [`testing/suite/`](/handbook/testing/suite/README.md) |
| write R the way this package does, flavor seam included | [`architecture/r-layer/`](/handbook/architecture/r-layer/README.md) |
| write C++ glue the way this package does | [`architecture/glue/`](/handbook/architecture/glue/README.md) |
| operate the vendoring loop | [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) and `.claude/skills/` |

## Everything else

Anything not on this page is in the tree,
and walking down from [`handbook/`](/handbook/README.md) is how
you find it:
internal nodes navigate, leaves explain,
and every fact has exactly one leaf that owns it —
including the limits, the declined requests, and the reasons
([the rules](/handbook/meta/handbook/README.md)).
Start at the root and follow the scope sentences;
searching the tree is the slower path.
