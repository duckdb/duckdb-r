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
   The recipe,
   and what to rewind when the fork point predates the release
   the glue was written for,
   is in `scripts/VENDORING.md`
   under *Starting a New Dev Line: the Fork-Point Rule*.
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
   rebased rather than reseeded (`series-rebase.md`).

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
   if the fork point predates the current glue.

5. **Walk forward** along `<U>`
   with the gated `scripts/vendor-one.sh --commits 100 <upstream-clone>`,
   fixing glue breaks in place as the gate stops on them.

6. **Add the series to the README's `Flavors` table** — see below.

7. **Give the fork the mirror the badges measure against,
   and `.github/pull.yml` the rule that keeps it fresh.**
   The series' own four refs never get a rule —
   [`.github/pull.yml`](/.github/pull.yml) says why the app cannot reach them,
   and a rule that could would hard-reset the loop's work away.
   What may need one is the branch the *ahead* badge measures against:
   a line that is still current releases from `main`,
   which has a rule already, so a series measured against `main` adds nothing;
   a line measured against a parked `vX-codename` baseline needs that baseline
   mirrored in the fork and ruled here.
   Three moves, in this order.
   Push the branch into the fork once by hand:
   a rule whose base the fork lacks is skipped silently and forever,
   so the rule never creates the mirror.
   Add the rule here, on `main`, where the file is authored.
   Then carry it to where Pull reads it —
   the fork's default branch, itself a mirror of this `main` —
   because until that mirror has the edit the rule does not exist for the app.
   `pull.yml` names the URL that validates it
   and the URL that triggers a sync,
   which is how the last move takes effect today
   rather than within six hours
   ([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).

8. The routine discovers every series from its refs
   and serves them all in one firing;
   the loop itself needs no configuration for a new series.
   The fork's mirror configuration is the one thing that lives outside
   the refs, and it is step 7's.

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
see `series-forward.md`.
The old `main-green` keeps serving until cutover.

A line that stops being the current one parks on its own
`vX-codename` baseline,
and its `.dev` badge follows it there —
the *ahead* base is the branch the series releases from,
which is no longer `main`.
That move is what earns the outgoing line a mirror and a rule,
by step 7, on the day it parks rather than on the day it was opened.
