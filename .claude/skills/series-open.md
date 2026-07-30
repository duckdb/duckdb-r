# Opening a new series

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

   **Check the generated cpp11 files before trusting a fresh seed.**
   `flavor.sh` runs `cpp11::cpp_register()`,
   whose symbol names depend on the cpp11 that happens to be installed:
   0.5.5 replaces only the *first* dot of the package name,
   so a `1.5.dev` flavor comes out as `_duckdb_1.5.dev_rapi_connect`,
   which is not a valid C identifier.
   Compare `R/cpp11.R` against an existing series' seed;
   this is also why a forward series is rebased rather than reseeded
   (`series-rebase.md`).

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

6. The routine discovers every series from its refs
   and serves them all in one firing;
   a new series needs no configuration, only its refs.

## The other half of a release cut

The `main` series' base and glue
now describe the *next* minor version.
If `main` itself has moved on
(release commits, R-side work),
forward the `main` series onto it
rather than rebasing in place —
see `series-forward.md`.
The old `main-green` keeps serving until cutover.
