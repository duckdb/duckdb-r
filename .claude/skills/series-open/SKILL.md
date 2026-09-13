---
name: series-open
description: Open a new vendoring series for a release branch upstream has just cut — cut the parent series' strands at the fork point, reflavor them, and forward both lines onto current `main`. Use when upstream cuts a release branch and it needs a series of its own, or when asked to open, seed or bootstrap a series.
---

# Opening a new series

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) —
what this routine is, and when it runs.*

When upstream cuts a release branch, it gets a series of its own.
**The cut comes long before the release** — upstream branched `v2.0-cyanoptera`
on 2026-09-02 and `main` read `2.1.0-dev` the same week, with 2.0 still
unreleased weeks later — so the line exists, and needs serving, while no
released version names it.
That gap is why an opening is dated from the branch rather than from the
release, and why a series opened here usually takes a preview prefix
([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
What the `main` series *tracks* does not change: it keeps following upstream
`main`, which now simply contains the next line's work. Its refs do change —
see below.
This skill is the release branch's birth certificate.

**Nothing here is derived twice.** The new series is minted out of commits its
parent has already vendored and CI has already called green: below the fork point
the two lines are one history, so the opening takes that work rather than
rebuilding it. `series-cut.sh` reports how deep that goes, and leaves the commits
`<U>` has of its own to the loop.

**It leaves two lines standing on the fork point, so both are forwarded.**
The cut puts `<S>` on the fork point's R side, months behind `main`, and
everything below that point has just stopped being `<P>`'s, so `<P>` is re-rooted
there too. Neither forward is tidying afterwards — step 4 opens both, and the
re-root's saving is what makes them affordable.

**Prerequisite: `main` has no `-fwd` in flight.** A series has exactly one set of
`<S>-fwd-*` refs, and an opening needs `main`'s: opening while one is pending
means overwriting it or abandoning the cutover it was built for. Cut the pending
one over first, or wait for it —
`git ls-remote --heads <remote> 'main-fwd-*'` answers this in one line.
`<S>`'s own `-fwd` refs are free by construction, since the series did not exist
until now.

`<S>` is the new series (e.g. `v2.0-<codename>`),
`<F>` its dev flavor (e.g. `2.0.dev`),
`<U>` the upstream release branch.

## Steps

1. **Cut the parent's strands at the fork point.**

   ```bash
   scripts/series-cut.sh <S> --upstream <duckdb-clone> --check --next
   scripts/series-cut.sh <S> --upstream <duckdb-clone> --next
   ```

   Everything here is derivable, which is why it is a script: the fork point is a
   function of two upstream branches, each strand's cut a function of that fork
   point and the strand, the four refs a function of the two cuts. `--check`
   writes nothing and reports; `--next` prints the rest of this list with the
   series' own names filled in. `--parent` defaults to `main`, `--flavor` to the
   version in the series name.

   It writes `<S>-build` and `<S>-build-base` at `<P>-build`'s cut, `<S>-dev` and
   `<S>-green` at `<P>-dev`'s. Local refs only; nothing is pushed until step 3.
   No `-fwd` refs yet — a forward counterpart protects a green consumers are
   already reading, and nobody is reading this one. Step 4 creates them.

   **Why the fork point is not the merge base**, and why below it the parent has
   already vendored, glued and judged everything the new line inherits, are
   [`vendoring/model/`](/handbook/operations/vendoring/model/README.md)'s. The
   script implements that rule; opening v2.0 measured the two a week apart.

   **Do not replay onto a fresh seed instead.** `main` vendors a *released*
   engine, which sits on no branch's first-parent chain, so no range start
   satisfies the range rule and the first pick lays one line's delta over
   another's tree.

2. **Reflavor both strands, immediately.**

   ```bash
   scripts/reflavor.sh <F>        # on <S>-build, then on <S>-dev
   ```

   **The cut is not complete without this.** It takes `<P>`'s tree entire, so
   `DESCRIPTION` names `<P>`'s package and the binding exports `<P>`'s symbols —
   a series that reached r-universe in that state would publish under a name that
   is already taken. One commit per strand, above its cut, so `-green` stays where
   the evidence is and the gate carries it over the rename like any other commit.

   `-build` as well as `-dev`: the buffer is what `-dev` replays from, so a buffer
   left on the old name mints commits that carry it forward.

   `reflavor.sh` renames rather than re-patching. `flavor.sh` builds a flavor onto
   an unflavored tree and refuses one that already has it, and reversing the old
   flavor first does not work on a series — `scripts/flavor.patch` is the
   unflavored template `main` owns, and the context it would reverse against has
   moved; against the v2.0 cut it failed four hunks of nine. A rename needs no
   context. It needs `krlmlr/cpp11`, for the reason `flavor.sh` gives, and refuses
   the run when the symbols come out wrong.

3. **Push all four refs, together.**
   `git push --atomic`, as `--next` spells it. The loop discovers series from
   refs and serves them in one firing, so a ref landing alone invites a firing
   into half a series — and a series pushed before step 2 is one that grows under
   the wrong name. Up to this push the opening is local branches and a deletion
   undoes it.

   **This hands the walk over.** Nobody vendors `<U>` by hand afterwards: the
   loop's stage 1 runs `vendor-one.sh --commits 100` against the buffer of every
   series it discovers, which is now this one
   ([`series-loop/SKILL.md`](series-loop)). Opening v2.0 pushed four refs and the
   next firing had walked the buffer 25 commits and `-dev` 72, unasked.
   `series-cut.sh` reports how many are left to walk; that number is the loop's
   backlog, not a task.

4. **Open both forwards.** Two invocations of
   [`series-forward/SKILL.md`](series-forward), neither waiting on the other:

   * **`<S>` onto current `main`.** The cut left it on the fork point's R side,
     months behind: every R-side fix `main` took after the fork is missing from
     the glue until this lands. An ordinary forward, regenerated seed and all.
     Read a red in the opening's first commits as that outstanding work rather
     than as a broken opening.
   * **`<P>` onto current `main`, grafted at the fork point.** Everything below it
     belongs to `<S>` now, so `<P>` stops carrying it: one commit with the
     fork-point commit's tree verbatim, parented on current `main`, then
     everything `<P>` has taken since replayed onto that. The tree is one the loop
     has already judged, so the base is sound by construction rather than by a
     replay that has to be checked. Opening v2.0 turned 6606 commits into 14 and
     6731 into 50, both heads byte-identical to the live branches outside
     `DESCRIPTION` — the version prefix of the line `<P>` previews next is the
     graft's only edit
     ([`releases/versioning/`](/handbook/operations/releases/versioning/README.md)).

   Both run beside their live refs as `-fwd-*` and swap in at cutover, so no green
   anyone reads is rewritten.

5. **Announce `<F>` in both tables** — the `Flavors` table in
   [`README.Rmd`](/README.Rmd), see below, and the one in
   [`branches/flavors/`](/handbook/branches/flavors/README.md), which says where
   each flavor publishes from. Those two are the only places a new series is named
   by hand; everything else is discovered from refs.

6. **Update the fork's mirror configuration — derived, not remembered.**
   A series' *ahead* badge measures against a branch the fork mirrors, which stays
   current only while [`.github/pull.yml`](/.github/pull.yml) carries a rule for
   it. Which rules the file owes is a function of the table step 5 just moved, so
   [`scripts/pull-config.sh`](/scripts/pull-config.sh) evaluates that function and
   prints what is missing (`--check` exits non-zero). A line still releasing from
   `main` is measured against `main`, which is ruled already, so most openings add
   no rule.

   Two halves the script cannot do. **Push the branch into the fork first** — a
   rule whose base the fork lacks is skipped silently and forever. **Then carry
   the merged file to the fork's default branch**, where Pull reads it; `pull.yml`
   names the URL that triggers a sync, so it takes effect today rather than within
   six hours ([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).

   Nothing else lives outside the refs: the loop discovers every series from them
   and writes the mirror configuration too, from the same detection
   ([`series-loop/SKILL.md`](series-loop)).

7. **Register the new flavor with r-universe.**
   `<F>` is a package nothing in this repository creates: a universe is configured
   by `<user>/<user>.r-universe.dev`, whose `packages.json` gives each package a
   `url` and the `branch` to build — `<S>-green` for a series. Adding `<F>` is an
   entry there, so a pull request against that repository is the request, and where
   it is not yours to open, its owner is who to reach; a base series belongs in
   `duckdb.r-universe.dev`, a forward counterpart in `krlmlr.r-universe.dev`
   ([`branches/flavors/`](/handbook/branches/flavors/README.md)).
   Where the universe does not answer,
   [`r-universe-org/help`](https://github.com/r-universe-org/help) is its issue
   tracker. Open the request early — the wait is someone else's queue — but it
   cannot build until step 2's rename is pushed and the gate has carried `-green`
   over it. [`scripts/r-universe-check.sh`](/scripts/r-universe-check.sh) says it
   took. Until then the series is covered by the per-commit gate alone, which is
   Linux on one R version, and stage 3 of the loop has nothing to read back
   ([`series-loop/SKILL.md`](series-loop)).

## Patching the README

Edit [`README.Rmd`](/README.Rmd): `README.md` and `.github/README.md` are
rendered from it, and all three carry the table.
Copy the row of the nearest `.dev` flavor and substitute `<F>`, `<U>` and the
series' refs, keeping the table's order — CRAN, then LTS, then the `.dev` flavors
newest series first.

Two things a copied row gets wrong.

**Which branch *ahead* measures from.** It is the branch the series releases from,
which for a line still releasing from `main` *is* `main` — not `<U>`, and not the
parked baseline a retired line uses.

**Which repository each badge is counted in**, because that differs within one
row. shields.io compares two refs of a single repository, and the row's three
comparisons do not all live in the same one:

* ***ahead*** is counted in `duckdb/duckdb-r`. Both its refs are there — the
  release branch natively, and `<S>-green` because the loop mirrors it
  ([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).
* ***in flight*** and ***buffered*** are counted in `krlmlr/duckdb-r`, the only
  repository carrying `<S>-dev` and `<S>-build`.

A badge whose base the named repository lacks renders as an error rather than a
count, and one reading a stale mirror is worse because it renders: it counts
commits that have already shipped. Step 6 settles both.

**The table must stay clear of `scripts/flavor.patch`.**
`README.Rmd` is a flavored file and the patch rewrites the installation hunks near
the top, so `git apply --check --include=README.Rmd scripts/flavor.patch` has to
still pass. Name the `.Rmd`: `--include` matching no path exits 0, so checking the
rendered `README.md` — which the patch does not touch — passes whatever the edit
did.

The edit lands on `main` and is forward-ported like any other R-side change.
When the series later releases, it gains a stable row of its own.

## Later, when the line parks

A line that stops being the current one parks on its own `vX-codename` baseline,
and its `.dev` badge follows it there — the *ahead* base is the branch the series
releases from, which is no longer `main`.
That move is what earns the outgoing line a mirror and a rule, on the day it
parks rather than on the day it was opened, and `pull-config.sh` reports it as
soon as the badge base moves: step 6 arriving by itself rather than being
remembered.

What is left of the walk-backwards problem when `<S>` releases is
[`plan/PLAN-v2-series-open.md`](/plan/PLAN-v2-series-open.md)'s.
