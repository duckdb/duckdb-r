---
name: series-open
description: Open a new vendoring series for a release branch upstream has just cut — seed its branches, apply the flavor rename, and take the first vendor commit. Use when upstream cuts a release branch and it needs a series of its own, or when asked to open, seed or bootstrap a series.
---

# Opening a new series

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) —
what this routine is, and when it runs.*

When upstream cuts a release branch —
v2.0 is released, upstream `main` becomes the 2.1 line —
the release gets a series of its own.
Nothing about the `main` series changes on a release cut:
it keeps tracking upstream `main`,
which now simply contains 2.1 work.
This skill is the release branch's birth certificate.

`<S>` is the new series (e.g. `v2.0-<codename>`),
`<F>` its dev flavor (e.g. `2.0.dev`),
`<U>` the upstream release branch.

## Steps

1. **Find the fork point — not the merge base.**
   The fork point is the newest commit
   on the first-parent chain of *both* upstream branches.
   `git merge-base` is dragged forward by upstream back-merges
   and has been observed months off.
   The rule and the recipe are
   [`vendoring/model/`](/handbook/operations/vendoring/model/README.md)'s;
   what to rewind when the fork point predates the release the glue was written for
   is `scripts/VENDORING.md`'s.
   Compute it in the upstream clone;
   write it down in the seed commit's message.

2. **Seed from the R package's `main`**:
   branch, then apply the flavor — `scripts/flavor.sh <F>` —
   which leaves the two flavor commits.
   Top them with a third commit,
   `chore: Add fifth version component`,
   appending `.0` to `Version:` in `DESCRIPTION` —
   the vendor counter's zero.
   The fifth component is a dev-branch affair:
   `flavor.sh` never stamps it,
   because regular LTS flavors keep their four-component version.

   **A series previewing an unreleased line takes that line's prefix in the same commit.**
   `main` carries the released line's version,
   so a series tracking upstream `main` sets `Version:` to fledge's prefix for the line it previews,
   `a.b.99.9000` before a minor release and `a.99.99.9000` before a major one,
   and appends the counter's `.0` to that
   ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
   Stamping it here is what puts it on all four refs at once.
   On `-dev` alone it splits the series' two version strands,
   and the `DESCRIPTION` merge driver stops resolving them.
   A series opened for a release branch takes no preview prefix
   **once that line has been released**,
   because its version is then the one `main` already carries.
   Where upstream cut the branch ahead of the release, nothing carries that line's version yet,
   and the series takes the prefix like any other preview line.

   **Install `krlmlr/cpp11` before running `flavor.sh`**, from GitHub —
   `remotes::install_github("krlmlr/cpp11")`, beside `decor`.
   `flavor.sh` runs `cpp11::cpp_register()`,
   whose symbol names come from the installed cpp11 rather than from the
   vendored headers
   ([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)).
   The script refuses the result when it is wrong
   and restores the tree, so a missing fork costs a rerun and nothing
   else — but it costs the whole run, and `cpp_register()` is the last
   step.
   That the two cpp11s differ at all is also why a forward series is
   rebased rather than reseeded (`series-rebase/SKILL.md`).

3. **Create all four refs at the seed tip**
   (day-one rule, no exceptions):
   `<S>-green` = `<S>-build-base` = `<S>-build` = `<S>-dev`,
   equal, "after flavoring", before any vendor commit.
   Green contains the flavor change from day one.

4. **Populate `<S>-build`, starting with the fork-point tree.**
   Check the upstream clone out at the fork point
   and run `scripts/vendor.sh` —
   one commit,
   subject carrying the `duckdb/duckdb@<sha>` reference as always;
   that subject is how `vendor-one.sh` finds its base.
   Rewind the glue as `VENDORING.md` describes
   if the fork point predates the current glue,
   and rewind the `patch/` stack with it —
   whole, out of `<P>-build`'s fork-point commit, before the run,
   rather than adjudicating the entries `vendor.sh` stops on.

   **This commit walks the engine backwards, and that is the design.**
   The seed comes from `main`, which carries the released line,
   and the series starts where its line forked, which is older.
   So every series begins with one backwards step,
   at a known commit, at the root, where a bisect can see it —
   which is what the fork-point rule buys
   in place of the same step appearing in the middle of a chain
   ([`VENDORING.md`](/scripts/VENDORING.md)).
   It is the first commit of every series from now on, not an anomaly in one.

   **It is generated here, and can never be replayed from another series.**
   Every other commit of a buffer can be cherry-picked,
   which is what a forward and a derived opening do.
   This one cannot: a vendor commit's diff is what vendoring changed,
   not the tree it produced,
   so picking it onto a base that does not vendor its predecessor
   lays a delta from one line over the tree of another.
   That is the range rule stated from the other side,
   and it fails quietly — the pick applies, the counter advances,
   and `R/version.R` names a version the sources are not.
   Measured on this repository: replaying the fork-point commit onto a seed
   from `main` left `R/version.R` reading `2.1.0-dev84198`
   over sources still 1.5.5 in 3274 files.

5. **Walk forward** along `<U>`
   with the gated `scripts/vendor-one.sh --commits 100 <upstream-clone>`,
   fixing glue breaks in place as the gate stops on them.

6. **Add the series to the README's `Flavors` table** — see below.

7. **Update the fork's mirror configuration — derived, not remembered.**
   The branch a series' *ahead* badge measures against is not one of the
   series' refs: it is a mirror in the fork, and it stays current only while
   [`.github/pull.yml`](/.github/pull.yml) carries a rule for it.
   Which rules the file owes is a function of the badge table step 6 just
   moved, so [`scripts/pull-config.sh`](/scripts/pull-config.sh) evaluates that
   function against the file and prints the block that is missing;
   `--check` exits non-zero on a disagreement.
   Run it after step 6, and put what it prints in the same change.
   A line still releasing from `main` is measured against `main`,
   which is ruled already,
   so most openings add no rule at all and the script says so.

   Two halves of this the script cannot do.
   **Push the branch into the fork once by hand, first** —
   a rule whose base the fork lacks is skipped silently and forever,
   so adding the rule never creates the mirror,
   and the script says which of the two is missing.
   **Then carry the merged file to where Pull reads it**,
   the fork's default branch, itself a mirror of this `main`:
   until that mirror has the edit, the rule does not exist for the app.
   `pull.yml` names the URL that validates it and the URL that triggers
   a sync, which is how that takes effect today rather than within six hours
   ([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).

8. The routine discovers every series from its refs
   and serves them all in one firing;
   the loop itself needs no configuration for a new series.
   The fork's mirror configuration is the one thing that lives outside
   the refs — and the routine writes that too,
   from the same detection, on the firing that sees the series change
   ([`series-loop/SKILL.md`](series-loop)).

9. **Register the new flavor with r-universe.**
   `<F>` is a package that does not exist yet,
   and nothing in this repository creates it:
   the registration is the universe's own, outside this tree
   ([`branches/flavors/`](/handbook/branches/flavors/README.md)).
   A base series belongs in `duckdb.r-universe.dev`,
   a forward counterpart in `krlmlr.r-universe.dev`.

   **Ask for it, in one of two places.**
   A universe is configured by a repository of its own,
   `<user>/<user>.r-universe.dev`,
   whose `packages.json` gives each package a `url` and the `branch` to build —
   for a series that branch is `<S>-green`, which is what r-universe builds
   ([`series-loop/SKILL.md`](series-loop)).
   Adding `<F>` is an entry there, so a pull request against that repository is the request,
   and where it is not yours to open, its owner is who to reach.
   Where the universe does not answer, or the entry lands and no build appears,
   [`r-universe-org/help`](https://github.com/r-universe-org/help) is r-universe's own issue tracker.
   Neither is this repository, and neither is instant:
   open the request when the refs exist rather than when the series is finished,
   because the wait is someone else's queue.
   [`scripts/r-universe-check.sh`](/scripts/r-universe-check.sh) is what says it took,
   listing exactly the packages whose upstream is this repository.
   Until the entry exists, the series is covered by the per-commit gate alone,
   which is Linux on one R version,
   and stage 3 of the loop has nothing to read back
   ([`series-loop/SKILL.md`](series-loop)).

## When another series already vendors the line

Steps 4 and 5 assume the line is new to this repository, and a release branch cut off a tracked line is not.
Below the fork point `<U>` and the branch it was cut from are one history,
so the parent series' buffer, `<P>-build` for a parent series `<P>`,
already carries a vendor commit for every upstream commit `<U>` inherits,
each with the glue the gate made that commit fix.
Walking them again pays the catch-up cost the loop's report warns about
and rediscovers those fixes one gate stop at a time,
which is the difference between opening a line on the day it is cut and opening it whenever someone gets to it.
Inherit them instead; steps 4 and 5 stay for a line nothing has vendored.

The replay is the forward routine's, run on the new seed, and the range is what changes:

1. **Find the parent buffer's fork-point commit**:
   the newest `<P>-build` commit whose `duckdb/duckdb@<sha>` subject names a commit
   on `<U>`'s first-parent chain.
   For a branch cut today that is the fork point itself.
   For one cut earlier it is wherever `<P>`'s vendoring had reached by then,
   and step 3 below is correspondingly longer.
2. **Replay onto the seed**, with the seed checked out:
   `scripts/series-forward-build.sh <that commit> <P's seed>`.
   The second argument only delimits the range,
   so this is an ordinary forward replay with a different seed under it,
   and everything `series-forward/SKILL.md` says about running one holds:
   read the whole glue set first (`scripts/series-glue.sh`), register the merge driver,
   and let it refuse rather than drop a `patch/` entry it cannot place.
3. **Re-root `<P>-dev` the same way**, onto the same seed, with the same script.
   Its fork-point commit is the newest `<P>-dev` commit whose subject names the same upstream SHA.
   Only `vendor:` subjects replay here too, and that is correct rather than a shortfall:
   a `-dev` branch's other commits are ports, and the seed is regenerated from the `main` that has them.
   The script checks rather than assumes, so the few born on `<P>-dev` stop the run and are named
   — `--placed` them, or fold them into the commit that wants them.
   What the strand is inherited *for* is its vendor commits:
   stage 5 folds the base series' test-side fixes into them as it consumes the buffer,
   so `-dev`'s copy of a commit carries what CI taught and `-build`'s does not.
4. **Walk forward from there** with `vendor-one.sh`, as step 5, over what `<U>` has of its own.

**A derived opening inherits commits. It does not inherit the green.**
`<S>-build` and `<S>-dev` are written at their re-rooted tips, because content is what a replay moves.
**`<S>-green` and `<S>-build-base` start at the seed, on every opening, without exception.**

A green is not a property of a commit, it is a record that *this series'* CI ran on it and passed
([`branches/model/`](/handbook/branches/model/README.md)).
The parent earned its green under the parent's flavor:
a different `Package:`, a different `library()` call in `tests/testthat.R`,
a different shared object and every `.Call()` entry point renamed.
Nothing built the commits under `<F>`, so nothing may claim they are green under `<F>`.
That the rename surface measures empty says the replay is unlikely to have broken them.
Unlikely is not evidence, and `-green` is the ref that means evidence.

The temptation is real and worth naming, because the saving looks large:
green at the re-rooted tip makes `<S>-green..<S>-dev` empty,
the per-commit planner considers nothing
([`ci/per-commit/selection/`](/handbook/operations/ci/per-commit/selection/README.md)),
and a 1400-commit opening costs one 23-second run.
What that buys is a series whose green ref has never been earned,
and whose first genuine verdict arrives whenever someone happens to walk it forward.
Opening a line costs its CI. Pay it.

There is still no `-fwd`:
a forward counterpart protects a green consumers already read, and a line opened today has none.
`series-forward-build.sh` is borrowed for the replay
and says nothing about which refs the opening writes.

**Nothing is pushed until every strand is built.**
The routine discovers series from its refs and serves them all in one firing (step 8),
so a ref that lands mid-build invites it into a half-built series --
a buffer with no `-dev` above it, or a `-green` naming a commit whose twin does not exist yet.
Build all four locally, check them against each other, and push them together at the end.
Everything before that point is reversible by deleting a local branch;
the push is what is not.

**Replay rather than branch, and the flavor is why.**
Pointing a new ref into `<P>-build` would share the commits outright and cost nothing up front,
but the buffer would then carry `<P>`'s flavor under an `<F>` series,
and every commit stage 5 mints would cross flavors for the life of the line.
A replay crosses once, here, where a human is already watching for conflicts:
a picked glue fix that touched one of the files `scripts/flavor.patch` rewrites conflicts on the name,
and the resolution keeps the seed's name and the commit's change.
The two buffers then share content and not objects, which is the point rather than a cost.

**Both strands are inherited, and the green comes with them.**
`-build` holds what the vendor gate checks, and everything `<P>` learned from CI afterwards lives on `<P>-dev`.
A forward folds that back from its twin, matched by vendored SHA
([`series-loop/SKILL.md`](series-loop), stage 5).
A derived opening needs no such fold, because it re-roots `<P>-dev` itself
and those fixes ride in the commits that carry them.
What makes it sound is the range:
where the fork-point commit sits below `<P>-green`,
every commit the new series inherits is one the parent has already proven,
so the series opens green instead of opening at its seed and earning that back one red at a time.
Where it does not, `<S>-green` stops at the last inherited commit that does.
How the opening this repository has next is sequenced around the release before it
is [`plan/PLAN-v2-series-open.md`](/plan/PLAN-v2-series-open.md)'s.

## Patching the README

The `Flavors` table in `README.md` is the only place
a new series has to be announced by hand;
everything else is discovered from refs.
Add one row for `<F>`, in the table's order —
CRAN, then LTS, then the `.dev` flavors newest series first:

* **Series** — `<U>` linked to
  `https://github.com/duckdb/duckdb/tree/<U>`.
* **Kind** — `dev`.
* **Progress** — three badges, outward from the released state:
  *ahead* (green) over `<release-branch>..<S>-dev`,
  *in flight* (yellow) over `<S>-green..<S>-dev`,
  *buffered* (blue) over `<S>-build-base..<S>-build`.
  Copy an existing row and substitute the refs;
  the shields.io endpoint is
  `github/commits-difference/krlmlr/duckdb-r?base=…&head=…`.

When the series later releases,
add its stable row too,
with a version badge instead of the lag badges.

Two things to check before pushing:

* **Every ref a badge names must live in `krlmlr/duckdb-r`.**
  A base that exists only in the canonical repo
  renders as an error, not a count.
  Reading a base the fork does carry but nothing keeps current
  is worse than that, because it renders:
  a mirror left behind counts commits that have already shipped
  ([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).
  Step 7 is where both are settled.
* **The table must stay clear of `scripts/flavor.patch`.**
  `README.md` is a flavored file;
  the patch rewrites the installation hunks near the top.
  `git apply --check --include=README.md scripts/flavor.patch`
  passes as long as the edit stays below them.

The edit lands on `main` and is forward-ported like any other R-side change.

## The other half of a release cut

The `main` series' base and glue
now describe the *next* minor version.
If `main` itself has moved on
(release commits, R-side work),
forward the `main` series onto it
rather than rebasing in place —
see `series-forward/SKILL.md`.
The old `main-green` keeps serving until cutover.

A line that stops being the current one parks on its own
`vX-codename` baseline,
and its `.dev` badge follows it there —
the *ahead* base is the branch the series releases from,
which is no longer `main`.
That move is what earns the outgoing line a mirror and a rule,
on the day it parks rather than on the day it was opened —
and `pull-config.sh` reports it as soon as the badge base moves,
which is step 7 arriving by itself rather than being remembered.

**A derived opening re-roots the parent, through the forward it already needs.**
`<P>-build` walks its line from the series' own beginning,
and everything below the fork point now belongs to `<S>`.
Rather than rewriting the live buffer, put the re-root in `<P>`'s next forward:
the regenerated seed, then one vendor commit at the fork point as in step 4,
then a replay of the buffer's commits above it.
The prefix a preview line owes the line it previews next is stamped in the same seed,
so one forward carries all three changes and the cutover installs them together.
The saving is what makes that forward affordable:
`<P>-fwd-dev` has the line's own commits to verify and nothing below the fork point.
That, and what is left of the walk-backwards problem when `<S>` releases, are
[`plan/PLAN-v2-series-open.md`](/plan/PLAN-v2-series-open.md)'s.
