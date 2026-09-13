---
name: series-open
description: Open a new vendoring series for a release branch upstream has just cut — cut the parent series' strands at the fork point, write the new refs there, and forward once to give the line its own flavor. Use when upstream cuts a release branch and it needs a series of its own, or when asked to open, seed or bootstrap a series.
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
   The newest commit on the first-parent chain of *both* upstream branches.
   `git merge-base` is dragged forward by back-merges; opening v2.0 measured the
   two a week apart. The rule and the recipe are
   [`vendoring/model/`](/handbook/operations/vendoring/model/README.md)'s.

2. **Cut both strands there.**
   `<P>` is the parent series, the one whose line `<U>` was cut from.
   A strand's fork-point commit is its newest commit whose `duckdb/duckdb@<sha>`
   subject names a commit on `<U>`'s first-parent chain:

   ```bash
   git rev-list --first-parent <U> | sort -u > /tmp/chain
   git log --format='%H|%s' <remote>/<P>-build |
     awk -F'|' '$2 ~ /^vendor: Update vendored sources to duckdb\/duckdb@/ {
       n = split($2, a, "@"); print $1, a[n] }' |
     awk 'NR==FNR{c[$0];next} ($2 in c){print $1; exit}' /tmp/chain -
   ```

   All four refs go there — `<S>-build` and `<S>-build-base` at `<P>-build`'s,
   `<S>-dev` and `<S>-green` at `<P>-dev`'s. There is no `-fwd`: a forward
   counterpart protects a green consumers already read, and a line opened today
   has none.

   No seed and no replay. Below the cut `<P>` has vendored every commit `<U>`
   inherits, with the glue it needed and the CI that judged it; sharing those
   objects is how that evidence travels rather than being claimed again. A green
   here is earned because nothing changed.

3. **Reflavor both strands, on top of the cut.**
   The one thing a cut gets wrong is the name: it takes `<P>`'s tree entire, so
   `DESCRIPTION` says `<P>`'s package and the binding exports `<P>`'s symbols.

   ```bash
   scripts/reflavor.sh <F>        # on <S>-build, then on <S>-dev
   ```

   One commit per strand, both above their cut, so `-green` stays where the
   evidence is and the gate advances it over the rename like any other commit.
   `-build` too, and not only `-dev`: the buffer is what `-dev` replays from, so
   a buffer left on the old name mints commits that carry it forward.

   `reflavor.sh` renames rather than re-patching. `flavor.sh` builds a flavor
   onto an unflavored tree and refuses one that already has it, and reversing
   the old flavor first does not work on a series: `scripts/flavor.patch` is the
   unflavored template `main` owns, and the context it would reverse against has
   moved — against the v2.0 cut it failed four hunks of nine. A rename needs no
   context. It needs `krlmlr/cpp11`, for the reason `flavor.sh` gives, and
   refuses the run when the symbols come out wrong.

   **Do this before the loop fires.** The routine discovers the series from its
   refs and will extend `-dev` from `-build` on its next firing, so a series
   pushed without the rename is a series that grows under the wrong name.

   **Do not replay onto a fresh seed.** `main` vendors a *released* engine,
   which sits on no branch's first-parent chain, so no range start satisfies the
   range rule ([`vendoring/model/`](/handbook/operations/vendoring/model/README.md))
   and the first pick lays one line's delta over another's tree.

4. **Walk forward** along `<U>` with the gated
   `scripts/vendor-one.sh --commits 100 <upstream-clone>`,
   fixing glue breaks in place as the gate stops on them.
   Push only once all four refs exist: the routine discovers series from refs and
   serves them in one firing, so a ref landing alone invites a firing into half a
   series.

5. **Add the series to the README's `Flavors` table** — see below.

6. **Update the fork's mirror configuration — derived, not remembered.**
   A series' *ahead* badge measures against a mirror in the fork, which stays
   current only while [`.github/pull.yml`](/.github/pull.yml) carries a rule for
   it. Which rules the file owes is a function of the table step 5 just moved, so
   [`scripts/pull-config.sh`](/scripts/pull-config.sh) evaluates that function and
   prints what is missing (`--check` exits non-zero). Run it after step 5 and put
   what it prints in the same change. A line still releasing from `main` is
   measured against `main`, which is ruled already, so most openings add no rule.

   Two halves the script cannot do. **Push the branch into the fork first** — a
   rule whose base the fork lacks is skipped silently and forever. **Then carry
   the merged file to the fork's default branch**, where Pull reads it; `pull.yml`
   names the URL that triggers a sync, so it takes effect today rather than within
   six hours ([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).

   Nothing else lives outside the refs: the loop discovers every series from them
   and serves them in one firing, and writes the mirror configuration too, from
   the same detection ([`series-loop/SKILL.md`](series-loop)).

7. **Forward once, to align the R side.**
   The cut took `<P>`'s tree entire, so the series stands on the fork point's R
   side: every R-side fix `main` took after the fork is missing from the glue
   until the first forward brings the line onto current `main`
   ([`series-forward/SKILL.md`](series-forward)).
   Read a red in the opening's first commits as that outstanding work rather
   than as a broken opening.
   The flavor is not part of it — step 3 settled that, and a forward regenerates
   its seed with `flavor.sh <F>` from an unflavored `main` in any case.

8. **Register the new flavor with r-universe.**
   `<F>` is a package nothing in this repository creates: a universe is configured
   by `<user>/<user>.r-universe.dev`, whose `packages.json` gives each package a
   `url` and the `branch` to build — `<S>-green` for a series. Adding `<F>` is an
   entry there, so a pull request against that repository is the request, and where
   it is not yours to open, its owner is who to reach; a base series belongs in
   `duckdb.r-universe.dev`, a forward counterpart in `krlmlr.r-universe.dev`
   ([`branches/flavors/`](/handbook/branches/flavors/README.md)).
   Where the universe does not answer,
   [`r-universe-org/help`](https://github.com/r-universe-org/help) is its issue
   tracker. Open the request while the refs are being written — the wait is someone
   else's queue, and it will not build until step 7 has given the series `<F>`
   anyway. [`scripts/r-universe-check.sh`](/scripts/r-universe-check.sh) says it
   took. Until then the series is covered by the per-commit gate alone, which is
   Linux on one R version, and stage 3 of the loop has nothing to read back
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
which is step 6 arriving by itself rather than being remembered.

**An opening re-roots the parent, through the forward it already needs.**
`<P>` walks its line from the series' own beginning,
and everything below the fork point now belongs to `<S>`.
Rather than rewriting the live branches, put the re-root in `<P>`'s next forward,
as a **graft**: one commit carrying the fork-point commit's tree verbatim,
parented on current `main`, then everything `<P>` has taken since replayed onto it
(`series-forward/SKILL.md`).
The graft is a tree the loop has already judged, so the base of the new line is
sound by construction rather than by a replay that has to be checked — and the
version prefix the preview line owes the line it previews next is the one thing
about the fork point that is no longer true of it, so it is the graft's only edit.
Opening v2.0 re-rooted `main` this way: 6606 commits became 14, 6731 became 50,
and both heads came out byte-identical to the live branches outside `DESCRIPTION`.
What is left of the walk-backwards problem when `<S>` releases is
[`plan/PLAN-v2-series-open.md`](/plan/PLAN-v2-series-open.md)'s.
