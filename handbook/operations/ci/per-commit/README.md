# `per-commit/`

Every commit on a series branch gets a gate verdict of its own:
[`each.yaml`](/.github/workflows/each.yaml) plans contiguous,
cost-balanced **shards** of commits and gives each shard one job,
which builds and tests its commits one by one in a single workspace,
and the verdicts live on the orphan `rcc` branch —
so every `*-dev` branch is bisectable end to end
([`branches/invariants/`](/handbook/branches/invariants/README.md)).

**Nothing here coordinates; everything recomputes.**
No part of this system asks another what it is doing,
and none of it holds a lock or a running marker.
Each run derives its own work from durable state and writes only what it
decided — which is what makes a lost runner cost exactly its own work,
and a re-run cost only what was lost.

* [`contract/`](contract/) — what consumers rely on
* [`selection/`](selection/) — which commits a run plans
* [`planning/`](planning/) — the cost model and the shard partition
* [`legs/`](legs/) — the jobs, the scripts, one leg's workspace
* [`store/`](store/) — the `rcc` branch and its writers
* [`operating/`](operating/) — knobs, failures, what to do
