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
   [`vendoring/model/`](/handbook/operations/vendoring/model/README.md)'s.
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

3. **Split both strands onto the seed.**
   `<P>` is the parent series, the one whose line `<U>` was cut from.
   Below the fork point `<P>` and `<U>` are one history,
   so `<P>` has already vendored every commit `<U>` inherits,
   each with the glue it needed and the CI that judged it.
   Take that work; do not re-derive it.

   A strand's fork-point commit is its newest commit whose `duckdb/duckdb@<sha>`
   subject names a commit on `<U>`'s first-parent chain.
   Replay each strand's range onto the seed, with the seed checked out:

   ```bash
   scripts/series-forward-build.sh <P-build's fork-point commit> <P's seed>
   scripts/series-forward-build.sh <P-dev's fork-point commit>   <P's seed>
   ```

   The second argument only delimits the range, so this is the forward routine's
   replay with a different seed under it, and everything
   [`series-forward/SKILL.md`](series-forward) says about running one holds:
   read the glue set first (`scripts/series-glue.sh`), register the merge driver
   with `scripts/setup-git.sh`, and let it refuse rather than drop a `patch/`
   entry it cannot place.
   Only `vendor:` subjects replay, and that is right rather than a shortfall:
   a strand's other commits are ports, and the seed is regenerated from the
   `main` that has them. The few born on `<P>-dev` stop the run and are named,
   to be `--placed` or folded.

   **Begin each range where its chain begins.**
   A replay may start above a buffer's beginning only where the new base already
   vendors the commit the range starts at, because a vendor commit's diff is what
   vendoring changed and not the tree it produced.
   Start it higher and the first pick lays a delta from one line over the tree of
   another — quietly, since the pick applies and the counter advances.

   **Replay rather than point a ref, and the flavor is why.**
   Branching into `<P>`'s history would share the commits and cost nothing up front,
   but the strands would carry `<P>`'s flavor under an `<F>` series, and every commit
   stage 5 mints would cross flavors for the life of the line.
   A replay crosses once, here. The two series then share content and not objects,
   which is the point rather than a cost.

4. **Write the four refs — last, and not equal.**
   `<S>-build` and `<S>-dev` at their replayed tips.
   `<S>-green` and `<S>-build-base` **at the seed**, on every opening, without exception:
   a green records that *this series'* CI passed on a commit, and nothing has built
   these commits under `<F>`. `<P>` earned its green under `<P>`'s flavor, on a tree
   naming a different package. Content is inheritable; a verdict is not
   ([`branches/model/`](/handbook/branches/model/README.md)).
   There is no `-fwd`: a forward counterpart protects a green consumers already read,
   and a line opened today has none.

   **Nothing is pushed until all four are built.**
   The routine discovers series from refs and serves them in one firing,
   so a ref that lands mid-build invites a firing into a half-built series.
   Up to that push the opening is local branches and a deletion undoes it.

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

9. **Forward once, to align the line.**
   An opening is two moves, and this is the second.
   Each strand was split at the fork point, so the series starts on that moment's
   R side while its seed carries `main`'s of today, and nothing reconciles the two:
   every R-side fix that landed on `main` after the fork is absent from the glue
   until it arrives the way R-side work always reaches a series, as a forward-port.
   So the opening makes the line exist and vendorable,
   and the first forward brings it onto current `main` and re-ports the rest
   ([`series-forward/SKILL.md`](series-forward)).
   Read a red in the opening's first commits as that outstanding work
   rather than as a broken opening.

10. **Register the new flavor with r-universe.**
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
