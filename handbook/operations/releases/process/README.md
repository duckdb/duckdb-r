# The process

Releasing one DuckDB line is a finite state machine —
four clusters of states, the transitions between them,
what several lines releasing together must synchronize on,
and what each step does when its gate fails.

Every state has an entry condition, a gate to leave, and a failure response.
The clusters, not the individual states, are the unit of coordination.

The branch model the machine operates on is
[`branches/model/`](/handbook/branches/model/README.md),
and the invariants every cluster must leave standing are
[`branches/invariants/`](/handbook/branches/invariants/README.md).
What the states name but do not define lives at its own leaf:
the reverse-dependency runs at
[`testing/revdep/`](/handbook/testing/revdep/README.md),
the version counters and `fledge` at
[`versioning/`](/handbook/operations/releases/versioning/README.md),
and CRAN submission and policy at
[`cran/`](/handbook/operations/releases/cran/README.md).

A **series** is one DuckDB minor line `L` (for example `v1.4-andium`)
together with its branches.
Four of them carry state through the machine:
`stable`, the published branch on `duckdb/duckdb-r`
(literally `main` for the current line);
`lts`, `stable` plus the flavor rename, for an LTS line only;
`dev`, the bleeding edge on `krlmlr/duckdb-r`, vendored daily;
and `dev-base`, the last reviewed and released point of `dev`.

## Clusters

At any moment a series is in exactly one of four clusters.

| Cluster | States | Driver | Mutates `main` glue? | Vendored commits → mainline? | Loops? |
|---------|--------|--------|----------------------|------------------------------|--------|
| **TRACK** | 0 | automation (daily) | no — forward-ports pass *through* | no | — |
| **STABILIZE** | 0.1–0.5 | calendar / human (window → tag) | **yes** (fold-back fixes are born here) | no | revdep ⇄ fold-back |
| **CUT** | 1–5 | upstream tag, then mechanical | no | **yes — the only cluster that does** | red ⇄ fix-in-commit |
| **RESET** | 6 | script | no | no | — |

The design's single most important property lives in the last two columns.
Vendored commits enter the mainline in exactly one cluster, CUT,
and `main`'s glue changes only in TRACK and STABILIZE.
The two never overlap,
which is what keeps `main` CRAN-releasable at all times.

## State diagram

```mermaid
stateDiagram-v2
    [*] --> TRACK

    state TRACK {
        Tracking : 0 TRACKING — daily vendor + forward-port, all green
    }

    state STABILIZE {
        Pinned : 0.1 CANDIDATE PINNED
        Revdep1 : 0.2 REVDEP-1
        FoldBack : 0.3 FOLD-BACK (fix on main, forward-port)
        Revdep2 : 0.4 REVDEP-2 (go / no-go)
        Freeze : 0.5 GLUE FREEZE (barrier)
        Pinned --> Revdep1
        Revdep1 --> FoldBack
        FoldBack --> Revdep2
        Revdep2 --> FoldBack : regressions
        Revdep2 --> Freeze : go
        Freeze --> Freeze : late glue re-arms
    }

    state CUT {
        Vendored : 1 VENDORED
        Review : 2 REVIEW
        Promoted : 3 PROMOTED (FF dev-base)
        Merged : 4 MERGED (stable bump, lts rebase)
        Published : 5 PUBLISHED (tag, r-universe, CRAN)
        Vendored --> Vendored : red / fix-in-commit
        Vendored --> Review : green
        Review --> Vendored : drift
        Review --> Promoted : ok
        Promoted --> Merged
        Merged --> Published
    }

    state RESET {
        Rebaselined : 6 RE-BASELINED (recreate dev / dev-base)
    }

    TRACK --> STABILIZE : open release window
    STABILIZE --> CUT : upstream tag vX.Y.Z
    CUT --> RESET : published
    RESET --> TRACK
    note right of CUT : CRAN acceptance is an async tail (current line only)
```

## States

| State | Enter when | `dev` | `dev-base` | `stable` / `lts` | Gate to leave | On failure |
|-------|-----------|-------|-----------|------------------|---------------|------------|
| **0 TRACKING** | RESET done | grows: vendor + forward-port, all green | frozen | frozen at `X.Y.(Z-1)` | maintainer opens the release window | — |
| **0.1 CANDIDATE PINNED** | window opens | fixes only; pin likely release commit | frozen | frozen | candidate green | — |
| **0.2 REVDEP-1** | candidate pinned | — | — | — | revdep run triaged | — |
| **0.3 FOLD-BACK** | findings exist | fold-back forward-ports land | frozen | **fixes born here**, then ported | findings resolved/accepted | loop to 0.4 |
| **0.4 REVDEP-2** | fold-back settled | — | — | — | **go / no-go** | fail → 0.3 |
| **0.5 GLUE FREEZE** | go | frozen (barrier; all lines aligned) | frozen | frozen | upstream tags `vX.Y.Z` | late glue → re-arm 0.5 |
| **1 VENDORED** | tag lands on `dev` | tagged vendor commit present | frozen | frozen | tagged commit **green** (`each.yaml`) | red → fix in-commit, force-push `dev` |
| **2 REVIEW** | green | — | — | — | `dev-base..tagged` clean | drift → fix on `main`, forward-port |
| **3 PROMOTED** | review ok | — | **FF → tagged commit** | — | dev-base advanced | — |
| **4 MERGED** | promoted | frozen at tagged commit | — | PR `tagged → stable` green; version bumped to `X.Y.Z`; `lts` rebased | stable green | version conflict (merge driver) / red CI |
| **5 PUBLISHED** | merged | — | — | tag `vX.Y.Z` pushed; r-universe builds; CRAN submitted (current line) | tag pushed | CRAN reject → new patch cycle |
| **6 RE-BASELINED** | published | force-recreated from new `stable` + flavor | recreated | — | back to TRACK | — |

## TRACK — steady state

Fully automated; there is nothing to do.
The series loop vendors upstream commit by commit,
consumes the buffer into the `-dev` branch,
and fast-forwards `-green` behind the per-commit verdicts —
see [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)
for the routine and
[`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)
for the gate it reads.
`each.yaml` checks every new commit,
and glue changes flow in from `main` along the forward-port chain.
`-green` is "what would ship if we released now."

A maintainer leaves TRACK by **opening the release window**,
far enough before the expected upstream release date
that the reverse-dependency gates can run and their findings be acted on,
which enters STABILIZE.

## STABILIZE — pre-release (window open → tag)

The goal is to prove the release *candidate* — the `dev` branch —
against reverse dependencies **before upstream cuts the tag**,
so that regressions can be folded back
(into our glue, into `patch/`, or reported upstream)
while there is still time.
STABILIZE mutates only `main`, where fold-back fixes are born,
and `dev`, which takes the forward-ports and the ongoing vendor;
the release branches stay at the previous release (invariant **P1**),
so the whole cluster is abortable with zero rollback.

### Preflight

Before pinning anything, read the current check reports.
The upstream **R workflow** R CMD check for the candidate revision
(<https://github.com/duckdb/duckdb/actions/workflows/R.yml>)
must be free of errors and warnings.
The current **CRAN checks** page for the published package
(<https://cran.r-project.org/web/checks/check_results_duckdb.html>)
must be free of anything red.
Which notes are tolerable and which are not is CRAN policy,
at [`cran/`](/handbook/operations/releases/cran/README.md);
in both reports the package-size note is the expected one.

### 0.1 Pin the release candidate

Upstream commits land up to and including release day,
so the release commit is a moving target.
**Ask upstream for the most likely release commit** and pin it.
From there on, only fixes — not features — flow into the glue source of truth.
Re-pin as upstream advances.
A re-pin forces a re-run of the reverse-dependency checks
only if the delta touches anything risky
(invariant **P2**: what ships must have been tested).

### 0.2 / 0.4 Reverse-dependency gates

Two reverse-dependency passes bracket the fold-back loop.
The first runs as soon as the candidate is pinned, early enough to act on;
the second, once the fold-back loop has settled,
is the **go/no-go gate** for the whole release.
Both run against the `.dev` build at the pinned commit;
how they are run and what counts as a blocker is
[`testing/revdep/`](/handbook/testing/revdep/README.md).

They sit *before* the tag rather than after
because CRAN policy requires contacting affected maintainers well beforehand.
That timing constraint is the reason STABILIZE exists as a cluster at all.

### 0.3 Fold back

Every fold-back fix is **born on `main`**
and forward-ported down the chain —
never authored directly on a `dev` branch
(invariants **P3** / **S4**).
C++ issues go into `patch/`
and are simultaneously sent upstream as a pull request,
so the patch can eventually be retired.
Contact the maintainers of any broken reverse dependencies.
Loop back to 0.4 until clean or explained.

### 0.5 Glue freeze (barrier)

Freeze glue across **all** releasing series
and confirm `git cherry main dev` is empty for each (invariant **P4**):
every releasing line now carries identical glue.
A late glue change after this point is allowed,
but it **re-arms the freeze** —
land it on `main`,
forward-port it to every releasing `dev`,
re-run a targeted revdep,
and only then proceed.
The clock resets to 0.5; it is not a scramble.

## CUT — release execution

Triggered by upstream tagging `vX.Y.Z`.
This is the only cluster that moves vendored commits into the mainline,
and it does so through reviewed, green, gated steps.
**You release the tagged commit, not the `dev` tip** —
upstream has usually moved on by now,
and the post-tag commits stay queued for the next cycle.

### 1 VENDORED → 2 REVIEW → 3 PROMOTED

1. The series loop produces the `vendor: … (tag vX.Y.Z) …` commit on `-dev`;
   wait for `each.yaml` to show it **green**.
   If vendoring broke the build,
   fix it in the same commit and force-push `dev`.
2. Review the pending window —
   `https://github.com/krlmlr/duckdb-r/compare/<dev-base>...<tagged>` —
   and confirm it contains only the expected vendor commits
   and the intended forward-ports, with no glue drift.
3. Fast-forward `dev-base` to the tagged commit:

   ```bash
   git push krlmlr <tagged>:refs/heads/L-dev-base
   ```

   A `scripts/promote-dev.sh L` wrapper is proposed but does not exist;
   see [Boundaries](#boundaries).

### 4 MERGED — stable, version, lts

Bring the tagged `dev` content onto `stable`
**linearly — never as a merge commit** (invariant **L**):
fast-forward or rebase the tagged range onto `stable`,
dropping the `flavor.sh` rename commit.
Because the release content is already contained in `dev-base`,
which is contained in `dev` (invariant **A1**),
dropping that one rename commit is the only rewriting needed.

The `DESCRIPTION` version conflict resolves automatically
via the merge driver registered by `scripts/setup-git.sh`
([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md));
run that script first on a fresh clone or CI runner.
The package version is then set explicitly to match the upstream tag —
it is not derived from the git tag; see
[`versioning/`](/handbook/operations/releases/versioning/README.md).

Finally rebase the `lts` branch,
which is one rename commit on top of `stable`:

```bash
# in the L-lts worktree
git rebase origin/L && git push origin L-lts
```

### WinBuilder and final checks

Obtain the source tarball from the CI build artifact (`r-package-source`)
or from the post-CI GitHub release (`duckdb_<version>.tar.gz`).
Build it from `duckdb/duckdb@main` rather than a fork,
so the git revision ids used to fetch extensions are correct.
Upload it to WinBuilder for R-devel
(<https://win-builder.r-project.org/upload.aspx>).
Apart from the known package-size note,
warnings and notes are blockers.

### 5 PUBLISHED — tag and publish

Tag the release and push; r-universe rebuilds automatically:

```bash
git tag vX.Y.Z origin/L-lts   # or origin/L per series convention
git push origin vX.Y.Z
```

The current line is then submitted to CRAN,
which is where the cluster stops being synchronous:
CRAN acceptance can take days and overlaps RESET and the next TRACK.
Submission mechanics and what to do on rejection are
[`cran/`](/handbook/operations/releases/cran/README.md);
for the state machine what matters is that a rejection
re-enters CUT as a follow-up patch cycle on `stable`.
LTS lines publish to r-universe only and have no CRAN tail.

## RESET — re-baseline

Recreate the dev baseline
from the freshly released `stable` tip plus the flavor rename,
returning the series to TRACK:

```bash
git checkout -b L-dev-base origin/L
scripts/flavor.sh L.dev
git push krlmlr L-dev-base --force-with-lease
git push krlmlr L-dev-base:L-dev --force-with-lease
```

The glue source of truth moves to its ongoing development version
at the same time,
and the `dev` branches resume counting from the new baseline —
both counters at
[`versioning/`](/handbook/operations/releases/versioning/README.md).

## Multi-line coordination

When several series release together —
a current line bound for CRAN plus an LTS line bound for r-universe —
coordination happens at the **cluster** level, not the state level.

**STABILIZE ends on a shared barrier.**
All releasing lines must reach 0.5 GLUE FREEZE together.
That is the forward-port barrier
guaranteeing identical glue across lines (invariant **P4**),
and it is the one hard synchronization point in the whole process.

**CUT runs per line, pipelined, CRAN line first.**
The CRAN line goes early because its acceptance is asynchronous;
the r-universe-only LTS line finishes alongside it with no CRAN tail.

**The preview line runs the same machine on a longer clock.**
The next major line, tracking upstream `main`,
lives in a long-running TRACK/STABILIZE:
its STABILIZE *is* the upstream release-candidate window,
and its CUT *is* the atomic fast-forward flip of `main`.
The flip requires `main` to be contained in `main-dev` (invariant **A2**),
which is *not* maintained continuously —
it is established once, just before the flip,
by the rewind-to-bifurcation and replay linearization.
The only other difference is that vendor-coupled glue
may be *born* on that line's `dev`,
the one documented exception to invariant **S4**.

## Failure and rollback

| Failure | State | Response |
|---------|-------|----------|
| Vendor breaks the build | 1 VENDORED | fix in the same commit, force-push `dev`, re-green |
| Glue drift found in review | 2 REVIEW | fix on `main`, forward-port, back to 1 |
| Revdep regression | 0.2 / 0.4 | fold back on `main` (0.3), loop |
| Late glue change | 0.5 / CUT | land on `main`, forward-port to all, re-revdep, re-freeze |
| Merge conflict on version | 4 MERGED | resolved by the merge driver; run `scripts/setup-git.sh` |
| CRAN rejection | after 5 | fix on `stable`, re-enter CUT as a follow-up patch |
| Upstream re-tags | any | treat as a fresh CUT entry on the new tag |

Nothing above rolls a released artifact back.
STABILIZE is abortable because it never touches a release branch;
once CUT has advanced `stable`, the only way out is forward,
through another cycle.

## Invariants preserved per cluster

Each cluster must leave the series satisfying the
[series invariants](/handbook/branches/invariants/README.md),
which name the FSM's states in their own definitions.

* **TRACK and STABILIZE** maintain **S1–S4**, **G1–G2**, **C1–C2**,
  and the prerelease invariants **P1–P4**.
* **CUT** is the controlled transition where `dev-base` catches up
  to the tagged commit and `stable`/`lts` advance;
  **V1–V4** and **F1–F2** must hold at the new release point.
* **RESET** re-establishes **S2**, baseline purity, for the next cycle.

## Boundaries

The machine is described here as it is *practised*, not as it is enforced.
No script or workflow knows about clusters or states:
nothing validates the order, and nothing prevents a state from being skipped.
The gates are maintainer discipline
plus the CI signals the states read.

The steps from 3 PROMOTED through 5 PUBLISHED are still typed by hand.
The wrappers that would automate them —
`scripts/promote-dev.sh`, which fast-forwards `dev-base`,
and `scripts/release-lts.sh`, which would chain promotion,
the merge pull request, the version bump, the `lts` rebase, the tag,
and a submission checklist for an LTS series —
exist only as intent in [`BRANCHES.md`](/BRANCHES.md#proposed-tooling).
That is why those steps appear as commands above rather than as script names.

Reverse-dependency runs, version counters, and CRAN submission
are named by the states but explained at the leaves linked above,
as are the branch model and its invariants.
What the machine releases is the R package;
the DuckDB extensions have their own release cadence upstream and are
[`usage/extensions/`](/handbook/usage/extensions/README.md)'s subject,
not a state here.
