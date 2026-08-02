# The model

Why this package carries a complete copy of the DuckDB C++ engine,
and why that copy advances one upstream commit at a time.

Vendoring is keeping a dependency's sources inside the depending repository
instead of resolving them at build time.
`src/duckdb/` is that copy — the whole DuckDB C++ core —
regenerated from an upstream clone by the vendoring scripts
and never edited in place.
What the engine is, and which commit of it is embedded, is
[`architecture/engine/`](/handbook/architecture/engine/README.md);
how the copy is produced is
[`pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Why vendor

* **Self-contained builds.**
  The package builds from source on a machine that has no DuckDB installed.
* **Version compatibility.**
  The glue is compiled against exactly the engine commit it was tested with.
  This is not a preference:
  the glue includes internal DuckDB C++ headers,
  which are ABI-compatible only with the matching commit's library,
  and `configure` refuses a mismatch outright.
* **CRAN compliance.**
  CRAN expects a package to be self-contained,
  with no external library resolved at install time.
* **Reproducible builds.**
  Two builds of the same package version compile the same engine sources.

The one supported way to skip compiling those sources is
`DUCKDB_R_USE_SYSTEM_LIB=1`,
which links a prebuilt `libduckdb` instead.
That is a developer fast path, not a second distribution model:
`configure` compares the installed library's `DUCKDB_SOURCE_ID`
against the vendored headers' and fails when they differ.
See [`build/fast-paths/`](/handbook/build/fast-paths/README.md).

## The invariant

Everything the pipeline does exists to keep four properties true
for every `-dev` branch.
They are what makes the history useful rather than merely present.

1. **Linear.**
   First-parent history only, no merge commits.
   A merge lands a batch of changes as a single step
   whose components were never built individually.
2. **One upstream commit per vendor commit.**
   Each vendor commit corresponds to exactly one upstream commit
   on the tracked branch,
   and the vendored SHAs form a contiguous first-parent walk
   of that upstream branch — no gaps, no jumps, no going backwards.
3. **Green per commit.**
   Every commit builds and passes the testsuite on its own.
   That is what `each.yaml` verifies.
   If a vendor commit needs an R-side fix to build,
   the fix is folded into that commit,
   never added as a follow-up —
   a follow-up leaves a red commit in the history forever.
4. **Auditable R-side delta.**
   Vendor commits touch only the mechanical path set
   (`src/duckdb/`, `R/version.R`, `src/include/sources.mk`, `DESCRIPTION`).
   Anything else in a vendor commit is a folded glue fix,
   and must be reviewable as a path-filtered diff
   ([`plan/history/vendoring-loop.md`](/plan/history/vendoring-loop.md) §3.4).

Upstream commits that change nothing the vendored tree carries —
test-only, CI-only, documentation, other clients —
produce no vendor commit at all.
The walk skips forward to the next one that does,
which does not break the contiguity invariant 2 asks for:
nothing vendorable happened in between.
How that decision is made is
[`pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## What it buys, and what it costs

It buys bisectability across the engine boundary.
`git bisect` over a `-dev` branch lands on a single vendor commit,
and that commit names a single upstream commit,
so a regression is attributable either to that upstream change
or to the glue fix folded in with it.
Both halves are needed:
without invariant 2, a bisect step spans an arbitrary batch of upstream work;
without invariant 3, the step cannot be tested at all.
That is the whole reason a package repository replays upstream history
commit by commit rather than jumping to the next release.

The price is paid in several places:

* **Every vendorable upstream commit gets its own build and testsuite run.**
  A backlog of *n* commits costs *n* builds; there is no shortcut.
  Making that affordable is what the sharded per-commit CI is for
  ([`ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)),
  and what the local ccache-warm replay loop is for
  ([`pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
* **A broken commit blocks the walk.**
  The fix belongs in the commit that needs it, by amend,
  so the walk stops until someone repairs it
  rather than moving on and patching over it later
  ([`troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)).
* **The branch cannot be reshaped freely.**
  No merges into it, no squashing vendor commits together,
  no re-pointing it at a different upstream branch.
* **Glue fixes lose their own history.**
  Folding a fix into a vendor commit is what keeps every commit green,
  but it also means the fix has no separate commit of its own;
  invariant 4 is what keeps it reviewable anyway.

Invariant 2 is the one that is easy to lose,
and it is lost silently — see
[starting a new dev line](#starting-a-new-dev-line).

## The vendor commit is the record

A vendor commit's subject is machine-readable state, not prose:

```text
vendor: Update vendored sources to duckdb/duckdb@<commit_hash>

Date: <author date of the upstream commit>

<subjects of the upstream first-parent commits since the previous one>
```

A commit that upstream tagged is marked in the same line:

```text
vendor: Update vendored sources (tag v1.x.x) to duckdb/duckdb@<commit_hash>
```

The `duckdb/duckdb@<sha>` in the subject is the *only* record
of where a branch stands in upstream history.
`vendor-one.sh`, `series-advance.sh`, `series-port.sh`
and the repair playbooks under `.claude/skills/`
all recover that position by parsing it back out of the commit message.
So the subject is not free-form:
do not reword it,
and do not squash vendor commits together
without keeping the newest SHA in the subject of the result.

## Starting a new dev line

When upstream cuts a release branch off `main`,
the package gains a new dev line,
and the tempting shortcut breaks invariant 2 without saying so:
point an existing dev branch at the new upstream branch
and let the walk catch up.
It fails because the branch's recorded base is a commit
on the *old* upstream line,
so the enumeration spans two branches that diverged long ago.

This is not hypothetical — it happened to `main-dev`,
and the record of it is worth keeping.
The branch was created from the v1.5-era package,
vendoring the released `v1.5.0` tree,
then re-pointed at upstream `main`.
The enumeration then started from the v1.5 base,
whose oldest entries are commits `main` accumulated
after the fork point but *before* the release.
The first mainline vendor commit therefore moved the vendored sources
backwards in time — to a `main` commit predating the release —
while simultaneously landing everything `main` had accumulated
past the fork point, in a single step.
None of that upstream work was ever built against the glue,
and a bisect across that one commit answers nothing.

The rule that avoids it:

> A new dev line starts with a vendor commit at the fork point
> of the two upstream branches,
> and walks forward from there, one upstream commit at a time.

The fork point is the newest commit
on the first-parent chain of *both* upstream branches.
It is not `git merge-base`:
upstream merges the release branch back into `main`,
which drags the merge base forward
to just after the most recent release.

Seeding a line at that commit is a procedure, not a principle,
and it lives elsewhere:
the branch bootstrap is
[`series-loop/`](/handbook/operations/vendoring/series-loop/README.md),
and the scripts that seed and then walk are
[`pipeline/`](/handbook/operations/vendoring/pipeline/README.md).

## Boundaries

This leaf owns the rationale and the invariant, nothing operational.

* The engine itself, and how this build of it differs from a stock one —
  [`architecture/engine/`](/handbook/architecture/engine/README.md).
* The series-wide guarantees each branch of a series carries,
  and what enforces them —
  [`branches/invariants/`](/handbook/branches/invariants/README.md).
  The four properties above are the vendoring side of the same story:
  they say what a vendor commit must be,
  not what a series promises.
* The scripts, the regeneration, the patch stack, the version counters —
  [`pipeline/`](/handbook/operations/vendoring/pipeline/README.md).
* The routine that runs the walk, its stages and its schedule —
  [`series-loop/`](/handbook/operations/vendoring/series-loop/README.md).
* A red run —
  [`troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md).

Intent lives under `plan/`:
[`PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md)
carries the current direction of the vendoring system,
and [`history/vendoring-loop.md`](/plan/history/vendoring-loop.md)
the design notes that led to the commit-by-commit loop.
