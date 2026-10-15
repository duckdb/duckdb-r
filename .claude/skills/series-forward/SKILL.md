---
name: series-forward
description: Forward a series onto a newer `main` by building an `-fwd` sibling beside it from the series' own `-dev`, so its commits keep what the series proved, and swapping it in once it has caught up, so the green ref consumers depend on is never rewritten. Use when `main` has moved under a series and its branches need the newer base, or when asked to forward a series.
---

# Forwarding a series to a newer base

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) —
what this routine is, and when it runs.*

`main` moves under a series:
R-side fixes, workflow changes, version bumps.
The series' branches are built on yesterday's `main`,
and rebasing them in place would rewrite `<S>-green` —
the one ref consumers depend on.
So the rebase happens **beside** the series, not in it:
a forward counterpart is built as a sibling series,
out of the commits the series has already had judged,
verified again by the ordinary loop on the new base,
and swapped in atomically once it has caught up.

**A release is the largest instance of `main` moving, and not a rule of its own.**
Nothing schedules a forward; what makes one due is drift worth resolving.
For a series whose own line has just released, the version is one reading of that drift:
its seed sits below the release it produced, `1.5.5.9020.36` being under `1.5.6`,
and re-seeding is what restores the correspondence.
A preview line is the exception, its prefix being deliberately not `main`'s
([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)),
so a bump on `main` moves nothing under it and only the R-side drift counts.

## Create the forward series

Bootstrap first, populate second —
like any series,
the four `-fwd` refs start **equal** at the regenerated seed tip;
the replay then populates `<S>-fwd-build`.

1. **`<S>-fwd-build`**: rebuild `<S>-dev`, and the buffer above it, on current `main`.
   The whole of step 1, with the reasoning behind each rule and every stop the replay makes,
   is [`references/create.md`](references/create.md); read it before the first replay and at every stop.
   The procedure:

   * **Regenerate the seed** on current `main`: `scripts/flavor.sh <F>` (needs `krlmlr/cpp11`),
     then a separate `chore: Add fifth version component` commit appending the counter's `.0`;
     a preview line takes its own prefix there, and a seed on a released `main` takes fledge's first dev version.
   * **Read the whole glue set and what the base learned, and judge it**, before the first pick:

     ```sh
     scripts/series-glue.sh <old-base>..<old-build>
     scripts/series-learned.sh <S>          # per commit, what -dev carries beyond its -build twin
     scripts/series-learned.sh <S> --diff   # the changes themselves
     ```

   * **Replay `-dev`, then the buffer above it**, on the fresh seed; `scripts/setup-git.sh` first:

     ```sh
     scripts/series-forward-build.sh <S>-dev <old-base> --buffer <S>-build
     ```

     Only `vendor:` subjects are replayed, the counter is renumbered, every message is kept,
     and a pick never stops a test the seed runs.
     The range's foot is read from the trees; a preview line's buffer opens on a rewind, which the script rebuilds.
     A forward that re-roots is a graft, and the parent's next forward takes it from the child with `--graft-from`.
   * **It refuses to start while the buffer carries a change the new base does not have**, naming each:
     read it, find the commit it belongs to, rerun with `--placed <sha>`, fold each change into its commit and replay the tail,
     and verify by tree: `git diff --name-only <S>-build <S>-fwd-build -- src/duckdb patch/` must be empty.
   * **Where the glue gate stops, adapt minimally** and fold the fix into the commit it stopped on;
     `main`'s glue meeting an older engine at a rewind is stepped back and restored in the commit that brings the API back,
     and a test asking for behaviour the engine lacks is gated, never rewound.
     Everything else the forward learns, it learns from CI once `-fwd-dev` is extended, folded with
     [`scripts/series-fold.sh`](/scripts/series-fold.sh) and mirrored onto `-fwd-build` where it is glue.
   * **Write the vendor strand, and read the forward against it:**

     ```sh
     git checkout --detach <seed>                                   # the commit -fwd-build stands on
     scripts/series-forward-build.sh <S>-build <old-base> [--placed <sha>]...
     git branch -f <S>-fwd-vendor HEAD
     scripts/series-learned.sh <S>-fwd --vendor          # per commit, what -fwd-build carries beyond pure vendoring
     scripts/series-learned.sh <S>-fwd --vendor --diff   # the changes themselves
     ```

     A fix found wanting on the new base is answered with a correction on the forward commit that carries it,
     folded with `series-fold.sh`, so that `-fwd-build` is the better buffer before the loop starts verifying it.

2. **`<S>-fwd-dev` = `<S>-fwd-green` = `<S>-fwd-build-base`** =
   the seed tip:
   green contains the flavor change from day one,
   so whatever consumes it builds the flavored package;
   the loop's stage 5 extends `-fwd-dev` from the populated buffer.
   Up to the commit the base `-dev` had reached when the forward was built, there is nothing left to carry,
   and the stage recognises a fix the buffer commit already holds;
   above it, where the buffer came from `-build`, it folds the base's fixes in as it always has.

3. Nothing else is special:
   a forward series is a series,
   and the loop discovers and drives it like any other.
   **The base series keeps consuming too**, at full speed,
   vendoring, repairing, porting and extending as if no forward existed;
   `<S>-green` still serves consumers, unchanged, on the old lineage.
   The two run level until a human swaps them,
   which is what the invariant below needs
   and what the loop's stage 5 used to prevent.

## A WIP forward series is not pinned to its base

Until cutover, a forward series is work in progress:
nothing consumes its refs —
the base `<S>-green` is still the serving ref —
so the fast-forward-only discipline that protects a serving green
does not yet bind the `-fwd` refs.
A WIP forward series can therefore **always be moved
onto the current mainline**,
and this is the normal way to pick up `main`-side fine-tuning —
CI changes, script fixes, R-side work —
that landed while the forward series was being built or verified.

That move is a rebase of the series onto itself, `series-rebase/SKILL.md`,
and it is not this skill.
Forwarding is `<S>` → `<S>-fwd`, across lineages:
`-fwd-build` is replayed out of the base series' `-dev`, and its buffer above that,
and `-fwd-dev` starts empty, for the loop to rederive.
A rebase is `<S>-fwd` → `<S>-fwd`, one lineage,
all four refs replayed as they stand, nothing rederived.

A series that has cut over is no longer WIP:
its green serves consumers,
and moving it means a new forward series, not a rebase.

## What the forward guarantees

> Every commit of `<S>-fwd-build` replayed from `<S>-dev` has the tree of its `-dev` twin plus `main`'s delta since the old seed,
> except where the glue gate or the test guard adapted it, and each adaptation is named in the commit.

Work the base series did survives by construction, and the only new work is where `main`'s delta meets the series.
Three limits bound that claim, and each is somebody's work rather than a gap in the claim:

* **The glue gate is a compile check.**
  It does not see behaviour `main`'s delta changes, so per-commit CI still judges every commit of `-fwd-dev`,
  and a red there gets a minimal fix folded into the commit that introduced it (above).
  "Adapt minimally" covers a test failure as much as a build failure.
* **Keeping `-dev` keeps its defects along with its fixes.**
  The forward is no better than its base where `main` did not move;
  improvement over the incumbent comes from `main`'s side alone, and a defect the base carries is fixed on the base, where stage 2 fixes one.
* **`-dev` covers only what the base has consumed.**
  The buffer beyond its tip is replayed from `-build`, compile side only, and the loop's carry serves it as before.

## What a forwarding has to end up with

A forward is the same series rebuilt on a newer `main`,
so its history differs by construction
and its content must not.
That is the invariant:

> At the end of a forwarding,
> `<S>-dev` and `<S>-fwd-dev` are **identical**,
> or every difference between them is **explicable**.

Read it as a claim about trees, never about ancestry —
the two share a seed generation and nothing below it,
the version counters are renumbered,
and the ported commits the replay leaves behind
are content the new seed already carries.
Ancestry says nothing here; the working trees say everything.

```sh
scripts/series-converge.sh <S>
```

prints the difference and sorts it into the two.
What is explicable is a short, evidenced list —
`DESCRIPTION`'s `Version:` line, which the replay renumbers;
`NEWS.md`, the release paperwork stage 4 never ports;
the flavored docs, `README.Rmd`, `README.md` and `.github/README.md`, which are per-branch by design;
the Windows export list, `src/*-win.def`, while the two vendor different engines;
and the **vendored strand** —
`src/duckdb/`, `patch/`, `R/version.R`, `src/include/sources.mk`
and the Makevars —
*only while the two vendor different upstream commits*,
where it is the gap and not a finding.
Every file in that strand is a function of the upstream tree:
`R/version.R` carries the engine's own version,
the source list and the Makevars are generated from it,
and `patch/` retires entries as upstream absorbs them.
Once both sit on the same upstream SHA the whole strand must agree:
a forward regenerates the vendored tree from its own patch stack,
which is what step 1's tree check verifies at replay time.

Everything else is a finding —
glue, tests, R code, the tooling directories —
and it belongs to whichever stage should have moved it:
a carry stage 5 could not make,
a port that reached one branch and not the other,
a fix folded on one and not the other.
A forward replayed from `-dev` starts with none of these up to the commit the base had reached,
so what the read shows afterwards is what the two lineages did since, and a test the replay kept.
The swap does not resolve a finding; it inherits it,
onto the lineage r-universe builds from.

**An explanation can go stale, and then it reads like a clean result.**
So the class list stays short,
and an explained difference is still printed with its line counts
rather than filed away.
A class is earned by evidence that the difference is benign —
not by another script excluding the same path,
which it may do for a reason that has nothing to do with this one.
Stage 5's carry excludes the generated files
so the twin's copy cannot overwrite what the buffer just regenerated;
that says nothing about whether the two branches may differ there,
and on the live series they do not.

## Cut over — by hand, always

A line has **one forward at a time**:
the loop serves the series r-universe publishes and the forward being built beside it, and nothing else
([`series-loop/SKILL.md`](../series-loop/SKILL.md)).
A second forward is not opened while one is in flight;
it is cut over, rebased (above), or abandoned first.

When `<S>-fwd-green` vendors at least the upstream commit
`<S>-green` vendors —
coverage may never regress — run

```sh
scripts/series-cutover.sh <S> --remote origin --upstream ../../../duckdb --prepare --out <dir>
scripts/series-cutover.sh <S> --remote origin --upstream ../../../duckdb
```

**A human runs this, never the loop.**
The series loop reports a ready cutover and stops there
(`series-loop/SKILL.md`, stage 6),
and the script refuses to swap without a terminal
and a typed confirmation.
`--prepare` is the half that needs neither:
it prints the gates and the reads below, writes the review, and moves nothing,
so the decision is made on a page that can be read twice.
Pass the upstream clone:
without it the coverage gate degrades to a warning,
and a warning is not what should authorize
retiring the lineage consumers are reading.

**The review comes before the swap.**
The script prints, as a stat, everything `<S>-fwd-green` changes against current `main` outside the engine,
and writes the full diff to `--out`:
the glue, the R code, the tests and the patch stack.
The forward's seed is a recent `main`, so that diff is the series' own work,
and it is read before consumers are pointed at it,
each part held to the leaf that owns it:
glue to [`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md),
tests to [`testing/`](/handbook/testing/README.md),
patches to [`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).
The convergence read beside it is the other half, what the forward carries against what it replaces;
a finding there is inherited by the swap, never resolved by it.

The report names the package on both sides —
`Package:` once, and `Version:` for each of the four refs,
before and after —
so the confirmation is given with the version
consumers will be offered on screen.
A version that would go **backwards** is warned about, not refused:
the replay renumbers the fifth component
as a counter of its own chain,
which starts well below the one the base series accumulated,
and the fourth component usually covers it
because the forward is seeded on a newer `main`.
Where it does not, r-universe, which publishes from `<S>-green`, has no upgrade to offer
until the new chain climbs past the old one's counter —
a cost rather than a corruption,
and whether it is worth paying is the judgement
the typed confirmation already asks for.
On a preview line it never does, and a version going back is normal there:
the prefix is pinned to the line being previewed rather than taken from `main`
([`scripts/preview-prefix.sh`](/scripts/preview-prefix.sh)),
so only the restarted counter differs.

**The replaced history is kept before anything moves.**
The swap takes `<S>-dev` and `<S>-build` off their lineages in the fork,
and the canonical repository's copy of `<S>-green` off its own,
and a ref nothing points at is history nothing can read.
So, after the confirmation and before the push,
each of those lineages becomes the head of a **draft pull request opened and closed on the spot**,
against the forward ref that takes its place:
`<S>-dev` against `<S>-fwd-dev` and `<S>-build` against `<S>-fwd-build` in the fork,
`<S>-green` against `<S>-fwd-green` in the canonical repository,
which carries every green ([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).
GitHub keeps a pull request's head as `refs/pull/<n>/head` for as long as the pull request exists, closed or not,
so the commits stay reachable, and the pull request is where to find them.
Green and `-build-base` are on those lineages already and need none of their own.
Nothing is merged, and the names stay what they were:
r-universe keeps building `<S>-green`, and no entry anywhere changes.
A remote that is not on GitHub cannot be archived that way;
the script refuses rather than swapping anyway, and `--no-archive` is the explicit override.

It then swaps all four refs in a single `git push --atomic`
with a per-ref lease,
so consumers never observe a half-replaced series.
A base ref that does not exist yet is **created** rather than swapped,
leased as "must not exist" —
a series opened directly as `-fwd`
has no counterpart to replace,
and its first cutover is what brings `<S>-*` into being.
The swap is the **one sanctioned non-fast-forward move
of a serving green ref**;
a WIP `-fwd-green` may be reset by a rebase (above),
but a green that consumers read
moves fast-forward only, before and after the swap.
The canonical copy of `<S>-green` is forced to the new green afterwards, under a lease,
the one place that copy is ever forced.

**Then it cleans up, and `series-prune.sh` lists what it could not.**
The `-fwd` refs are deleted in the fork,
with the forward's rc and alpha strands and its retry ledger,
and `<S>-fwd-green`'s copy is deleted in the canonical repository:
their tips are the series' refs now, and the derived strands are re-cut from the swapped-in series
([`series-rc/SKILL.md`](../series-rc/SKILL.md), [`series-alpha/SKILL.md`](../series-alpha/SKILL.md)).
If the remote refuses ref deletion (some git proxies do),
or a cutover predates this cleanup,
what stays is cutover litter:
the loop ignores a forward series
whose green is an ancestor of its base series' green,
and

```sh
scripts/series-prune.sh <S>
```

lists the litter in both repositories with the commands that remove it, and runs none of them.
It offers nothing of a live forward, and nothing it offers is lost by deletion:
the replaced lineages are the archive pull requests' heads, and the rest is recomputed from `<S>-dev`.
