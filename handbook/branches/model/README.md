# The model

Each DuckDB minor line the R package follows gets a **series** of branches.
The series and its refs are the branch model:
what a series is, where its branches live,
what each ref means and how far it may move,
which branch is the source of truth for the code that is not vendored,
and what the upstream release cycle asks of all of this at each phase.

## A series

A series is one upstream branch of `duckdb/duckdb` —
`main`, `v1.5-variegata`, `v1.4-andium` —
together with the R package branches that carry it.
Upstream cuts a branch per minor version
and ships a new minor roughly every four months
(<https://duckdb.org/docs/stable/dev/release_cycle>);
each such branch the R package still follows is a series here.

A series is *discovered*, not configured.
The vendoring routine lists `refs/heads/*-build`
and serves every one that has a sibling `-dev`,
so opening a series is a matter of creating its refs and nothing else —
no CI configuration, and no list anywhere to keep up to date.
The birth certificate is
[`.claude/skills/series-open.md`](/.claude/skills/series-open.md);
the routine that then serves it is
[`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md).

## Two repositories

`duckdb/duckdb-r` is canonical.
It holds `main`, the parked stable baselines
(`v1.5-variegata`, `v1.4-andium`),
and the LTS flavor branch `v1.4-andium-lts`.
CRAN and the numbered r-universe packages are published from here.

`krlmlr/duckdb-r` is a disconnected fork used only for CI/CD,
so that the automated per-commit builds
do not consume the `duckdb` organization's GitHub Actions quota.
Every series' working refs live there.
[`.github/workflows/sync.yaml`](/.github/workflows/sync.yaml)
keeps the fork's `main` level with the canonical one:
hourly, it clones `duckdb/duckdb-r` and fast-forwards — never merges.

The C++ engine is vendored from `duckdb/duckdb` into the fork's series refs;
the R code that wraps it is written on `duckdb/duckdb-r@main`
and travels the other way.
Why the engine is vendored at all is
[`operations/vendoring/model/`](/handbook/operations/vendoring/model/README.md).

## The four refs

Each series `<S>` carries four refs in `krlmlr/duckdb-r`:

| Ref | Moves by | What it is |
|---|---|---|
| `<S>-build` | append; force-push to repair | The buffer: every upstream first-parent commit vendored one to one, with the glue compiling at each. No CI runs here. |
| `<S>-dev` | append; force-push | What CI judges, commit by commit: `-build` commits consumed in chunks, with test, R and patch adaptations folded into the commit that needs them, plus what was forward-ported from `main`. |
| `<S>-green` | fast-forward only | The trusted frontier — the newest commit such that every commit in `<S>-green..it` has a successful run. What r-universe should build from. |
| `<S>-build-base` | forward only | The `-build` commit equivalent to `-green`. Marks how much of the buffer has been consumed and verified. |

All four exist from a series' first day, equal at its seed tip,
so there is never a "no green yet" state
and every walk the routine makes is bounded below by `<S>-green`.

The buffer is deliberately untested.
[`each.yaml`](/.github/workflows/each.yaml) triggers on `*-dev` and `each-*`,
never on `*-build`,
so vendoring can run ahead — red or not —
while CI works through what has already been consumed.
Consumption is bounded:
[`scripts/series-advance.sh`](/scripts/series-advance.sh)
appends at most 100 `-build` commits to `-dev` in one pass by default.

Which `-build` commit corresponds to which `-dev` commit
is decided by the `duckdb/duckdb@<sha>` reference in the commit subject,
never by the paths a commit touched:
the patch stack is applied to the vendored tree in place,
so commits that change `src/duckdb/` while vendoring nothing are routine.

The gaps between these refs are what the badges
in the root [`README.md`](/README.md) count:
*ahead* is what `-green` has over the branch the series releases from,
*in flight* what `-dev` has over `-green` — consumed, not yet all green —
and *buffered* what `-build` has over `-build-base` — vendored, not yet consumed.

### Forward counterparts

`main` moves under a series.
Rebasing a series in place would rewrite `<S>-green`,
the one ref consumers read,
so the rebase happens beside it:
a counterpart series `<S>-fwd` is built with the same four refs,
verified from scratch by the same routine,
and swapped in once it has caught up.
That swap — a cutover — is the single sanctioned sideways move
of a serving `-green`, and it is always a human's call:
the routine reports that a counterpart has caught up and prints the command,
and never runs it
([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).

### What exists today

Three base series — `main`, `v1.5-variegata`, `v1.4-andium` —
each with all four refs in `krlmlr/duckdb-r`,
and `main` additionally with a live forward counterpart, `main-fwd`.
In `duckdb/duckdb-r`: `main`, the two parked baselines, and `v1.4-andium-lts`.
There is no `v1.5-variegata-lts`; v1.5 is not an LTS line.

Every series also still carries a `<S>-dev-base` ref
from the layout that preceded the loop,
in which `-dev` was vendored into directly
and `-dev-base` marked the last released point.
No script and no workflow in the tree reads it any more.
It survives because the release state machine still models it —
moving it is a release step, not a loop step —
so two layouts describe the same branches at once,
and which one answers depends on the question:
the four refs for what is vendored and verified,
`-dev-base` for what was released
([`operations/releases/process/`](/handbook/operations/releases/process/README.md)).

Beside these the fork carries litter from retired designs —
`broken-<sha>-dev` branches from a repair mechanism that was never made to work,
a stray `retry-<sha>-green`, `main-dev-old`, `main-rewind-*`.
Only `retry-<S>-dev` is live:
it is how a single commit is asked for a second verdict
without rewriting anything.

## The source of truth

`duckdb/duckdb-r@main` is the source of truth
for everything the package does not vendor:
the glue code (`src/*.cpp`, `src/include/`),
the R code and the tests,
the CI/CD infrastructure (`.github/`, `scripts/`, `.claude/`),
and the vendored cpp11 headers.
The engine comes from upstream, per series;
the published package name is applied mechanically per branch
([`branches/flavors/`](/handbook/branches/flavors/README.md));
and the R API itself is external —
it constrains what the glue may do rather than being owned anywhere here.

The consequence is a direction.
Glue is never *born* on a `-dev` branch;
it is written on `main` and carried down.
The one exception is the preview line that tracks upstream `main`,
where an adaptation forced by a new upstream C++ API has nowhere else to be born,
because `main` does not yet carry that upstream version.
As a checkable guarantee this is invariant S4 —
[`branches/invariants/`](/handbook/branches/invariants/README.md).

### Keeping derived branches in sync

The order is always newer to older:

```txt
duckdb/duckdb-r@main
  →  krlmlr/duckdb-r@main-dev
  →  krlmlr/duckdb-r@v1.5-variegata-dev
  →  krlmlr/duckdb-r@v1.4-andium-dev
```

with `duckdb/duckdb-r@v1.4-andium` fed from `main` at release time.
Never in reverse.
A new series joins at the front of the chain, directly below `main-dev`.

Keeping it that way is automated.
[`scripts/series-port.sh`](/scripts/series-port.sh) lists every commit
`main` has that the series lacks, by patch-id, oldest first,
classifies each as TOOLING, MIXED, OTHER or VENDOR by what it touches,
and cherry-picks all but VENDOR —
`main`'s engine is not this series' engine,
and the series' own vendoring owns that strand.
Picks are whole commits, never split.
Whatever the commit walk cannot explain
is closed by one sync commit taking `main`'s tooling tree verbatim,
so the goal is identity rather than curation:
afterwards `.github/`, `scripts/` and `.claude/` on `<S>-dev`
are byte-identical to `main`'s.

A series never keeps its own fork of the tooling.
Where a series genuinely needs different behavior,
the difference is made conditional on `main`
and ported down like anything else.

Three mechanisms proposed for this before the port stage existed
were never built, and are not planned:
a `scripts/sync-to-derived.sh` that would print `git cherry-pick` commands,
a scheduled stale-branch workflow that would flag forward-porting debt,
and a `needs-forward-port` label on pull requests to `-dev` branches.
The port stage runs every firing and leaves no debt,
so there is nothing left for a reminder to remind about.

## The release cycle

Upstream ships a new minor roughly every four months
and patches an LTS line for a year — about three minor cycles —
after which it is archived.
What the branches do at each phase:

**Mid-cycle**, which is most of the time.
Nothing to manage: each firing of the loop vendors and consumes,
upstream patch releases land on the series that follows them,
and forward-porting happens in the same firing.

**Pre-release**, when upstream creates the next minor's branch.
Two things are created:
the future stable branch in `duckdb/duckdb-r`, from `main`;
and the series in `krlmlr/duckdb-r` —
seeded from `main` with `scripts/flavor.sh` for the new `.dev` flavor
plus the separate fifth-component commit,
its four refs equal at that seed tip,
and `-build` populated starting from the fork-point tree
([`.claude/skills/series-open.md`](/.claude/skills/series-open.md)).
The new series then joins the front of the forward-port chain.

The `main` series needs nothing here.
Under the loop it keeps walking upstream `main`'s first-parent chain,
which passes through the fork point,
so nothing jumps and nothing is re-seeded;
the layout that preceded the loop needed an explicit fork-point re-seed
at exactly this moment,
and the one-commit-at-a-time walk is what removed that hazard.
The fork point matters for the *new* series instead,
and it is not `git merge-base` —
it is the newest commit on the first-parent chain of both upstream branches,
computed as in
[`scripts/VENDORING.md`](/scripts/VENDORING.md#starting-a-new-dev-line-the-fork-point-rule).

**Feature freeze** is indistinguishable from pre-release on the R side:
only bug fixes flow into the new branch, new features target `main`,
and no branch management is required.

**On a new minor release.**
The new series' verified content is brought onto its stable branch
in `duckdb/duckdb-r`, and `duckdb` is published to CRAN from there.
Then the outgoing line is either designated LTS —
create its `-lts` branch from the stable branch,
apply `scripts/flavor.sh` for the numbered flavor,
register that package on r-universe,
and add the line to the forward-port chain —
or it is not, in which case vendoring into its series stops
and its branches are archived.

**On a patch release**, the most common release event.
In ref terms: the tagged upstream commit reaches `-dev` by ordinary vendoring,
CI proves it green, `-green` advances to it,
the commit is merged onto the stable branch with the release version set by
`fledge`, the `-lts` branch is rebased on top, and the tag is pushed.
The states, gates and rollbacks of that sequence belong to the release state
machine —
[`operations/releases/process/`](/handbook/operations/releases/process/README.md);
the version numbers it sets belong to
[`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md).

**On LTS expiry** — undecided, and undecided since the model was written.
What becomes of `v1.4-andium-lts`, of its r-universe registration
and of its series a year after designation
is written down nowhere, here or elsewhere.

## Limits

The model says which ref *should* be published, and cannot say which one is.
The mapping from an r-universe package to the branch it is built from
lives in the r-universe registry, outside this repository,
so a change there is invisible in the tree;
[`branches/flavors/`](/handbook/branches/flavors/README.md)
names the intended mapping.

How often the refs move is likewise not visible here.
Nothing in `.github/workflows/` fires the series loop:
it is a scheduled Claude routine,
and its cadence is configured outside the repository.
The workflows that do carry a schedule serve other jobs —
`sync.yaml` hourly, `rcc-logs.yaml` twice an hour, `fledge.yaml` daily.

How the refs are actually moved — the routine's stages,
its repairs, its judgement calls — is
[`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md),
and the mechanics of a single vendor commit are
[`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

Intent for how this model is meant to shrink —
one owner per fact, the vendoring re-tellings collapsed —
is carried in
[`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md).
