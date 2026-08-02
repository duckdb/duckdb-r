# The duckdb-r handbook

The single source of truth
for every documentable aspect of this package;
internal pages like this one navigate and state their area's principles,
leaves explain ([the rules](meta/handbook/)).

The areas divide by what a question is about,
not by who is asking it.
A reader who will only ever install the package
and one who maintains the repository that produces it
are served by the same tree,
and the same question brings them both to the same leaf.
That is why the list below mixes using, building and operating
rather than separating them by audience:
an audience split would need the same fact in two places,
and the tree holds every fact once.

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
