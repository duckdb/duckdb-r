# The duckdb-r handbook

The single source of truth
for every documentable aspect of this package;
internal pages like this one only navigate — leaves explain
([the rules](meta/handbook/)).

* [`usage/`](usage/) — using the package from R,
  one leaf per user-visible subsystem:
  installation and flavors, connections, the type mapping,
  extensions, memory, data import, storage locations,
  and the dbplyr and Arrow integrations
* [`architecture/`](architecture/) — what the shipped code is:
  the R layer and its conventions,
  the C++ glue and its source rules,
  and the embedded DuckDB engine
* [`build/`](build/) — from tree to installed package:
  the source build, the fast paths, and the build knobs
* [`testing/`](testing/) — proving the package works:
  the suite, snapshot discipline,
  the CRAN and flavor guards, and reverse dependencies
* [`branches/`](branches/) — the branch model:
  the series and their refs, the package flavors,
  and the invariants every series guarantees
* [`operations/`](operations/) — running the repository:
  vendoring (model, pipeline, series loop, troubleshooting),
  issue triage, pull-request review,
  continuous integration (workflows, per-commit builds,
  the platform matrix),
  and releases (process, CRAN, versioning)
* [`contributors/`](contributors/) — getting productive here:
  environment setup, the change workflow,
  and where help is wanted
* [`meta/`](meta/) — the documentation system itself:
  the handbook's rules and the plans index
