# PLAN — The documentation tree meets the filesystem

Status: **proposed** (2026-08-01, branch `claude/docs-tree-filesystem-v9hns3`).

Inputs:
the documentation-tree design in
[`plan/PLAN-vendoring-simplification.md`](PLAN-vendoring-simplification.md) §8;
its draft generalization to the whole package —
the docs-tree draft, reviewed on branch `claude/r-package-docs-tree-r45c4q`
and closed without landing —
whose five rules and draft ownership manifest this plan builds on,
restated inline wherever this plan relies on them;
and GitHub's rendering rules for `README.md` files.

Scope:
how the **engineering subtree** is *navigated* and where its nodes *live* —
the relationship between the documentation tree and the filesystem tree.
Not in scope:
the semantics subtree (`.Rd` concept pages are routed by `_pkgdown.yml`
and `?topic`, and are not filesystem-shaped by construction);
the contents of any leaf;
and the order in which the concept pages
and engineering leaves get written.

---

## 1. The observation

### 1.1 The tree is invisible from inside the tree

The draft's extended documentation tree is a *logical* tree:
two roots, purpose-shaped leaves, and routing tables inside the roots.
It is navigable only by a reader who starts at a root —
which means a reader who already knows
that `AGENTS.md` exists and what it is for.

That is not how repositories present themselves.
GitHub, editors, and `ls` all present the *filesystem* tree,
and readers land in the middle of it:
a search hit in `scripts/each-shard.sh`,
a review comment on `scripts/rcc-one.sh`,
a checkout opened at `scripts/`.
Standing in `scripts/`, nothing in `scripts/` says
that `each-*` and `rcc-*` belong to `EACH.md`,
that `vendor*` and `series-*` belong to `VENDORING.md`,
or that the flavor tooling is explained two levels away
in a root file named after branches.
The tree's edges exist only inside files the reader is not looking at.

The result is unintuitive in exactly the way that matters:
the documentation tree and the filesystem tree are both trees
over the same files, and they disagree —
one is walked by routing tables, the other by directories,
and only the second one has a user interface.

### 1.2 What purpose-ownership gets right

The opposite rule — "docs live in the directory they document" —
does not survive contact with the surface either.
The docs-tree draft is correct that
**inventories are owned by purpose, not by directory**:

* Build is not a directory.
  `BUILD.md` owns `configure` at the root, `src/Makevars.in` and the
  `.mk` includes under `src/`, and installer scripts under `scripts/`.
  Splitting that topic across three per-directory documents
  would break the single-owner rule in the other direction.
* A directory is not a topic.
  `scripts/` holds vendoring, CI, build, flavor, and release tooling;
  one document per directory would be five topics in one leaf.

So the purpose-shaped leaves stay.
The mistake would be to conclude that the filesystem
therefore carries no documentation structure at all.

### 1.3 The resolution: two projections of one relation

The draft ownership manifest —
globs to owning documents, to land as `.github/docs-owners.yml` —
maps every path to exactly one owning document.
That relation has two useful projections:

* **by purpose** — the routing tables in the roots:
  "to solve X, read Y".
  This is the projection a reader with a *question* needs.
* **by place** — for each directory, the owners of its files:
  "you are standing in `scripts/`; here is what each file is,
  and where each one is explained".
  This is the projection a reader with a *location* needs.

The draft builds the first projection and its checker.
This plan adds the second — and it is a projection in the strict sense:
generated from the same relation, adding no facts of its own.

**Ownership by purpose, navigation by place.**

## 2. The mechanism: a generated `README.md` per directory

`README.md` is the one filename GitHub renders in place:
browse a directory, and its README is displayed under the file listing.
It is therefore the only medium through which
a directory can answer questions *in situ*.

Each covered directory gets a `README.md` that is a **routing node**
under rule 2 of the tree ("nodes route, leaves explain"):

* one line of scope, and a pointer to the tree root
  (`AGENTS.md` → "Where to look");
* one table row per tracked file:
  the file, its one-line purpose, grouped by owning document;
* no prose about behavior — the owning leaf explains,
  the README points.

And it is **generated, not written**:

* the one-liner is the file's *own* header comment —
  the roxygen model, applied to scripts:
  the description lives with the code, the index is compiled from it;
* the grouping is the §6 ownership manifest;
* the file is committed, and a `--check` mode regenerates and diffs,
  so CI can fail on staleness
  the same way it fails on a stale `man/` page.

Generation is what makes the pattern safe. It buys four properties:

1. **It cannot drift.**
   The stale-inventory failure the docs-tree review recorded
   (`BRANCHES.md`'s tooling section missing ten scripts)
   is mechanically excluded: the index is recomputed from `git ls-files`.
2. **It cannot become a second owner.**
   The single-owner risk of hand-written READMEs is structural:
   prose accretes.
   A generator emits routing rows and nothing else.
3. **It enforces header discipline.**
   A file with no header line renders with an em-dash purpose —
   a visible gap.
   Writing this plan's demonstration found five such files in `scripts/`
   (`flavor.sh`, `rconfigure.py`, `rethrow.R`,
   `python_helpers.py`, `vendor-rfuns.sh`),
   plus four whose first line lacked sentence punctuation
   and therefore indexed as a run-on
   (`vendor.sh`, `vendor-one.sh`, `setup-makeflags.R`, `format.py`).
   The fixes are split out to #2453,
   folded into this branch as its first commit until that merges.
   `flavor.patch` keeps the em-dash:
   the patch format carries no place for a header.
4. **It makes orphan surface visible in place.**
   A file matching no manifest glob renders under **Unowned** —
   the §1.3 failure mode, surfaced at the point where
   someone is already looking at the file.

## 3. The demonstration: `scripts/` (this PR)

`scripts/docs-readme.R` generates `scripts/README.md`
from the headers and an inline ownership mapping
that follows the draft ownership manifest,
deviating only where the projection showed the draft to be wrong.
Which it did, immediately — projecting the manifest onto one directory
caught six defects in it:

1. **`scripts/python_helpers.py` is unowned.**
   No `own:` glob matches it.
   It is imported by `format.py`, so it follows `format.py`'s owner.
2. **`scripts/rconfigure.py` is assigned to `BUILD.md`, wrongly.**
   It is called only by `vendor.sh` and `vendor-one.sh`,
   and `scripts/VENDORING.md` already documents it as the regenerator
   of `src/duckdb/`, `src/include/sources.mk`, and `R/version.R`.
   It is vendoring surface; the mapping here assigns it to `VENDORING.md`.
3. **`scripts/rethrow.R` is double-claimed.**
   The manifest assigns it to `TESTING.md`;
   the draft's node table says `R/ARCHITECTURE.md` owns
   "generated files (`cpp11.R`, `rethrow-gen.R`) and what regenerates them" —
   and `rethrow.R` is what regenerates one of them.
   One of the two must win before phase D makes the check blocking.
4. **`scripts/docs-coverage.R` would flag itself.**
   The planned checker appears in no `own:` glob of its own manifest.
5. **The history files matched nothing until their move.**
   `scripts/VENDORING-LOOP.md` and `scripts/main-dev-review.md`
   were unmatched by any glob,
   with the moves that would retire them two phases away.
   #2438 has since landed those moves
   (`plan/history/`, indexed by a new hand-written `plan/README.md`),
   which resolves the finding on `main` —
   and shows the check would have caught it mechanically.
6. **`scripts/merge-version.sh` is assigned to `BRANCHES.md`, wrongly.**
   The `DESCRIPTION` merge driver exists
   to keep version counters mergeable across vendor commits —
   it is vendoring machinery, and moves to `VENDORING.md`'s group.

The first five took no judgment to find; they fell out of one projection
onto one directory.
The sixth was caught by a reviewer reading the rendered index.
That is the practical argument for maintaining both views:
each is a check on the other.

The tarball is unaffected:
`^scripts$` is already in `.Rbuildignore`,
so the README and the generator never reach `R CMD build`.

## 4. The `.github` exception

`.github` cannot take the pattern's filename.
GitHub resolves *the repository's* front-page README
from three locations, in precedence order:
`.github/README.md`, then `README.md` at the root, then `docs/README.md`
(see GitHub Docs, "About READMEs").
A `.github/README.md` would therefore silently replace
the root `README.md` on the repository landing page —
the user root of the documentation tree, hijacked by a routing index.

So `.github` keeps a *named* document.
This settles an open question the docs-tree draft left
("does `.github/CI.md` belong under `.github/`?"):
yes — congruence wants the CI doc co-located with the workflows it owns,
and the deviant filename is forced by GitHub's precedence rule,
not chosen.

`inst/` is excluded for the symmetric reason at the other end:
its contents are installed into the package root,
so an `inst/README.md` would ship into every user's library.
Generated and vendored trees
(`man/`, `revdep/`, `tests/testthat/_snaps/`, `src/duckdb/`)
are excluded exactly as the manifest excludes them.

## 5. Leaf placement under congruence

The README layer is navigation; it does not move any leaf.
But congruence does have an opinion about where leaves sit:

* **Directory-shaped leaves are co-located** —
  `scripts/VENDORING.md` and `scripts/EACH.md` already are,
  and the draft's placement of `src/GLUE.md`, `R/ARCHITECTURE.md`,
  and `.github/CI.md` is endorsed by the same logic.
* **Cross-cutting leaves live at the root** —
  `BUILD.md`, `BRANCHES.md`, `RELEASE.md`.
  The root is the directory of repo-wide topics;
  that is congruence, not an exception to it.
* **`TESTING.md` is the boundary case.**
  Most of what it owns is `tests/**`,
  which argues for `tests/` placement;
  its root-level siblings argue for the root.
  Left open below.

There is a stronger variant:
where a directory has exactly one owner,
the leaf could *be* the README —
`R/README.md` as the architecture doc,
rendered in place when the directory is browsed.
The cost is uniformity:
mixed-ownership directories (`scripts/`, `src/`)
still need generated routing READMEs,
so the repo would carry two kinds of README —
some generated indexes, some hand-written leaves —
and the generator could no longer treat every README as its output.
Leaning: uniform generated routers everywhere,
with the leaf one click away.
Left open below.

## 6. Rollout

| Step | Directories | Notes |
|---|---|---|
| this PR | `scripts/` | generator + index + the five headers |
| landed by #2438 | `plan/` | `plan/README.md` exists, hand-written; whether it becomes generated from each plan's `Status:` line is open (§7) |
| next | `patch/` | two rows and a pointer to `VENDORING.md`'s patching section |
| when the engineering leaves land | `R/`, `src/`, `tests/` | needs `.Rbuildignore` entries (`^R/README\.md$` etc.) — unlike `scripts/` and `plan/`, these directories ship in the tarball, and `R CMD check` flags non-standard files |
| when the manifest lands | mapping moves | the inline mapping in `docs-readme.R` becomes `.github/docs-owners.yml`; `docs-coverage.R` and `docs-readme.R` are the same walk with two outputs, and should be one tool |
| never | `.github/` (§4), `inst/` (§4), generated and vendored trees | |

## 7. Open questions

1. **Uniform routers, or README-as-leaf?**
   Where a directory has a single owning document (`R/`, `tests/`),
   should the leaf simply be the directory's `README.md` (§5),
   or should every README stay a generated routing node?
2. **`TESTING.md` at the root or under `tests/`?**
3. **Mapping now vs. manifest now.**
   The demonstration inlines the ownership mapping in `docs-readme.R`
   and defers `.github/docs-owners.yml` until the manifest lands.
   Acceptable, or should the manifest file be pulled forward
   so there is never a second encoding of ownership?
4. **`plan/README.md` landed hand-written (#2438), and works.**
   Convert it to a generated index
   (each plan's `Status:` line is the extractable header),
   or leave routing nodes hand-written
   where a directory is small and the prose carries judgment?
   And does `patch/` get its two-row index in the next pass?
5. **Strictly mechanical generation only?**
   Where headers are too thin to index well,
   is an agent-regenerated, human-reviewed README acceptable,
   or does everything stay extraction-only?
