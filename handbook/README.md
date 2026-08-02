# The duckdb-r handbook

The single source of truth
for every documentable aspect of this package;
internal pages like this one navigate and state their area's principles,
leaves explain ([the rules](meta/handbook/)).

Three constraints run through every area below,
and a reader who does not carry them will misread all of them.

**No page here may assume the package is called `duckdb`.**
One source tree is published under several names,
applied per branch rather than chosen at build time,
so the name is a question asked at run time wherever it appears —
in the R code, in the tests, in what a user installs.

**The engine is carried in this repository, not depended on.**
A question about DuckDB and a question about the R package
are therefore answered in the same tree, at different leaves,
and drawing that boundary is part of what every area does.

**Every commit is built and tested on its own.**
History advances one upstream commit at a time and stays linear,
which is what makes a regression attributable;
much of the machinery described below exists to keep that affordable,
and nothing else explains the shape it has.

The areas divide by what a question is about, not by who is asking it:
a user and a maintainer with the same question arrive at the same leaf.

* [`usage/`](usage/) — installation and flavors, connections,
  types, extensions, memory, data import, storage, integrations
* [`architecture/`](architecture/) — the R layer, the C++ glue,
  the embedded engine
* [`build/`](build/) — source build, fast paths, build knobs
* [`testing/`](testing/) — suite, snapshots, guards, revdep
* [`branches/`](branches/) — series, flavors, invariants
* [`operations/`](operations/) — vendoring, triage, review,
  CI, releases
* [`contributors/`](contributors/) — setup, workflow, where to help
* [`meta/`](meta/) — the rules, the plans
