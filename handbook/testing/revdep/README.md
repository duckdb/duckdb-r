# Reverse dependencies

Checking the packages that depend on this one before a release.

**[`revdep4.yaml`](/.github/workflows/revdep4.yaml) is the route.**
A reverse-dependency check is a dispatch of that workflow against the ref to test.
It runs a package's two halves in their own containers one after the other,
and wins the parallelism that costs back across packages with a work queue.
Sequential is the whole point.
Two simultaneous checks of one package share ports, caches and locks that nothing in the R toolchain
promises to support, which is where `revdep2`'s false `newly_broken` verdicts came from.
The engine is [`.github/workflows/revdep4/`](/.github/workflows/revdep4/README.md)'s
and the machinery under it [`.github/workflows/revdepx/`](/.github/workflows/revdepx/README.md)'s.

**`which` and `depth` decide how much work a run is**, and the workflow documents them with the rest of its inputs.
`strong` at depth 1 is the default; `most` also takes the packages that merely suggest this one,
and each further level of `depth` takes the reverse dependencies of what the level above found.
The two ends of that range are far apart, so the size is measured rather than assumed:
run 34690774944 checked 130 packages at `most`, depth 1, on 2026-09-12,
where the `most`, depth 2 pair that revdepx's shard arithmetic is measured against enumerated 3435.
A set that large is dealt into shards and can still need `part=i/G` to fit inside a run.

**The report is this repository's record, and the run writes it.**
`revdep/README.md` and its siblings are committed onto the checked branch by the run that produced them,
unless the repository variable `REVDEPX_COMMIT_REPORT` is `false`,
and a later run given `packages: broken` reads them back to re-check only what the last one found broken.
That directory carries no backreference to this leaf and cannot:
revdepcheck's own report writer produces it, and the generator is upstream's
([`meta/handbook/`](/handbook/meta/handbook/README.md)).

## The routes revdep4 replaced

They are kept because a check still has to be possible with no runner to dispatch to,
and because `revdep2.yaml` and `revdep.yaml` record the design their successor is the outcome of.
Neither workflow feeds a revdep4 run: `REVDEPX_WORKFLOWS` defaults to `revdep4.yaml` alone,
so only revdep4's own runs offer the next plan its baselines and its measured timings.

* **revdepcheck, run locally**, against the `.dev` build at the pinned release candidate,
  is the fallback with no runner.
  It installs each reverse dependency twice, old engine and new, and writes the same `revdep/` report.

  ```r
  revdepcheck::revdep_check(
    num_workers = 8,
    env = c(revdepcheck::revdep_env_vars(), MAKEFLAGS = "-j8")
  )
  ```

* **[`revdep2.yaml`](/.github/workflows/revdep2.yaml)**, on dispatch, is revdep4's predecessor:
  the same sharding and reporting, with both halves of a package running at once on one host.
  Its runs are never offered as baselines, because they checked on a different platform;
  [`.github/workflows/revdep2/`](/.github/workflows/revdep2/README.md) keeps the history of the design.

* **[`revdep.yaml`](/.github/workflows/revdep.yaml)**, on push to a `revdep*` branch and never on `main`,
  builds one job per reverse dependency and uploads the old and new `rcmdcheck` pair only when they differ.

When the runs happen, an early pass and a go/no-go gate before the tag, is
[`operations/releases/process/`](/handbook/operations/releases/process/README.md)'s.
duckplyr, the closest downstream, also gates individual changes
(for instance the untyped-`NULL` flip,
declined in [#155](https://github.com/duckdb/duckdb-r/issues/155)).

*To deepen: state what blocks a release versus what is noted and
waved through, from the last release's record.*
