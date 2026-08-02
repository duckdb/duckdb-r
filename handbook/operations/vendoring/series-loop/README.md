# The series loop

The routine that vendors every series —
what fires it, what its stages decide, and which playbook carries each one.
The procedures themselves are machine-loaded from `.claude/skills/`
and are linked here, never restated:
a reader who wants to *run* the loop follows the link,
a reader who wants to know what runs stays here.

## What fires it

The loop is a **scheduled agent routine**, not a workflow.
Nothing under [`.github/workflows/`](/.github/workflows/) starts it —
there is no vendoring workflow in the repository at all —
and the schedule lives with the routine that invokes the playbook,
outside this tree.
What the repository schedules is adjacent to the loop rather than part of it:
[`sync.yaml`](/.github/workflows/sync.yaml) fast-forwards the fork's `main`
and [`rcc-logs.yaml`](/.github/workflows/rcc-logs.yaml) harvests run results
onto the `rcc` branch, each on the schedule its own `cron:` line sets,
and [`each.yaml`](/.github/workflows/each.yaml) triggers on every push
to a `*-dev` branch.
Those cadences bound how fast a firing can learn anything;
they do not decide when a firing happens.

A firing serves **all** series in one pass,
and a series is discovered rather than configured:
the firing lists `refs/heads/*-build`,
and every `<S>-build` with a sibling `<S>-dev` is a series it serves —
base series and forward (`-fwd`) counterparts alike.
Opening a series therefore takes no configuration change, only refs.
The refs themselves, and what each of them guarantees,
belong to [`branches/model/`](/handbook/branches/model/)
and [`branches/invariants/`](/handbook/branches/invariants/).

## One firing

Setup runs first and is never skipped;
each numbered stage is skipped when it has nothing to do.

**0. Setup** decides what the firing is allowed to believe.
It fetches every branch, unshallowed, with tags —
a narrowed clone enumerates zero series and reports a clean pass over nothing —
and reads the open pull requests that touch `.github/`, `scripts/`
or `.claude/`.
Those are context, not instructions:
an open PR is tooling the series does *not* have yet,
so a failure it already documents is one to work around
rather than diagnose again.

**1. Vendor onto `<S>-build`** decides how far the buffer reaches.
It runs `main`'s copy of `vendor-one.sh` against the buffer worktree,
which is the one place the port stage below cannot reach:
`-build` carries no ports by design.
The script gates itself, syntax-checking the glue against the freshly
vendored headers after each commit and stopping at the first break,
so the stage's real work is fixing glue.
`-build` is pushed unconditionally — no CI runs on it, and red never
blocks the buffer.
The vendoring mechanics are owned by
[`vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/).

**2. Repair the oldest `<S>-dev` failure** decides whether a red commit
is the tree's fault or the run's.
Only the range `<S>-green..<S>-dev` is ever examined,
and classification is by what a log positively contains, never by a
missing marker.
A commit the tree broke is repaired by folding the fix into the offending
commit and replaying the tail, so every commit stays independently green;
a commit the infrastructure broke is asked for again by pushing a
`retry-<S>-dev` ref at it, which rewrites nothing and re-mints no
descendants.
That ref doubles as the ledger: already sitting on the commit, it means
the one rerun was spent and the failure is real.
The failure taxonomy — glue gate, base scans, dropped patches, stale
snapshots — is owned by
[`vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/).

**3. Advance `<S>-green` and `<S>-build-base`** decides how far the series
is trusted.
Green fast-forwards to the newest commit with a `success` run for
everything below it, and `-build-base` follows to the equivalent buffer
commit.
Fast-forward only: if green cannot fast-forward, verified history was
rewritten and the firing stops and says so.

**4. Port from `main`** decides nothing — its goal is identity, not
curation.
After the stage, `.github/`, `scripts/` and `.claude/` on `<S>-dev` are
byte-identical to `main`'s.
Because CI reads workflows and scripts from the branch it checks, this is
what puts a tooling fix into effect, and it is why a fix never waits for a
forward.
`scripts/series-port.sh` lists every commit `main` has that the series
lacks, classified `TOOLING` / `MIXED` / `OTHER` / `VENDOR`, and applies all
but `VENDOR`; conflicts and engine-incompatible commits stay judgement.

**5. Extend `<S>-dev`** decides how much of the buffer is consumed —
one chunk per firing — a hundred commits by default,
overridable per call —
and only when everything in flight is green.
What the bound buys is [`branches/model/`](/handbook/branches/model/)'s to explain.
A series with a live forward counterpart is being replaced, so it is
verified and promoted but never extended.

**6. Suggest a cutover** decides only to report one.
When a forward series has caught up, the firing prints the
`series-cutover.sh` command and stops.
The swap moves a serving green *sideways* and deletes the counterpart that
would let it be undone, so a human owns it;
the script enforces its own half by refusing to run without a terminal
and a typed confirmation.

**7. Open a pull request for whatever the tooling got wrong.**
A firing that worked around a bug in a script or a workflow owes `main` a
PR before it ends — one per cause, small, with the failing firing linked as
evidence.
The workaround is done by hand first, so the fix is never load-bearing for
the firing that found it, and the routine never merges its own PR.
Review is owned by [`operations/review/`](/handbook/operations/review/).

## The playbooks

| Playbook | When it is used |
|---|---|
| [`series-loop.md`](/.claude/skills/series-loop.md) | Every firing: the stages above, in order. |
| [`series-open.md`](/.claude/skills/series-open.md) | Once per series, when upstream cuts a release branch. |
| [`series-forward.md`](/.claude/skills/series-forward.md) | When `main` has moved far enough under a series that it needs a new base: a `-fwd` counterpart is built beside it and swapped in by hand. |
| [`series-rebase.md`](/.claude/skills/series-rebase.md) | While a `-fwd` series is still work in progress, to move it onto a newer mainline. |

The mechanical helpers the loop calls — `series-check.sh` for a read-only
verdict per series, `series-advance.sh` for stages 3 and 5,
`series-port.sh` for stage 4, `series-cutover.sh` for the manual swap —
are listed under this leaf in the generated
[`scripts/` index](/scripts/README.md).

## Limits

The loop owns verification and promotion, and nothing beyond that.
It never performs a cutover, never merges a tooling PR, and never moves
`-green` or `-build-base` anywhere but forward.
It advances on completed, successful runs and never on the absence of a
failure, so a commit missing from the harvest makes it wait rather than
guess.
It also keeps no state of its own: git alone is sufficient in principle,
richer tools shorten diagnosis but are never depended on.

Shard planning, the verdict store, and how a commit gets a run at all
belong to [`ci/per-commit/`](/handbook/operations/ci/per-commit/).
Why the engine is vendored one commit at a time is
[`vendoring/model/`](/handbook/operations/vendoring/model/).
Intent — where the loop is still heading, and which pieces are landed
versus proposed — lives in
[`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md).
