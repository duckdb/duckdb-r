# PLAN — The documentation tree, extended to the whole package

Status: **proposed** (2026-07-30, branch `claude/r-package-docs-tree-r45c4q`).

Inputs:
the documentation-tree design in
[`plan/PLAN-vendoring-simplification.md`](PLAN-vendoring-simplification.md) §8
(the "vendoring doc tree", landed as krlmlr/duckdb-r#86);
the triage in `plan/PLAN-inbox-zero.md` §2 and §5
(branch `claude/review-open-issues-prs-46alwv` on `krlmlr/duckdb-r`),
which names the five concept pages issue triage needs;
the component model in [`BRANCHES.md`](../BRANCHES.md#package-components);
and the current tree at 1.5.5.9002, vendored DuckDB 1.5.5.

Scope:
review the vendoring doc tree,
generalize it from "how this package is vendored"
to "what this package *is*" —
its user-visible semantics, its build, its tooling, its tests, its CI —
and sequence the result so that the documentation
which lets triaged issues close lands first.

Not in scope:
the vendoring pipeline itself (owned by `PLAN-vendoring-simplification.md`),
and issue dispositions (owned by `PLAN-inbox-zero.md`).
This plan owns only the *shape* of the documentation
and the order in which it gets written.

---

## 1. Review of the vendoring doc tree

§8 states four rules.
All four survive generalization, and are adopted here unchanged:

1. **Two roots.**
   `README.md` for users, `AGENTS.md` for maintainers and coding agents.
2. **Nodes route, leaves explain.**
   An intermediate node is at most a screen:
   scope in one sentence, then a "to solve X, read Y" table.
   Detail lives in exactly one leaf — the single-owner rule.
3. **Links are conveniences, paths are the contract.**
   Navigation must survive without hyperlinks;
   every node names its children by repo path.
4. **History is quarantined.**
   Superseded designs live under `plan/`, out of the routing tree.

Rule 2 is the load-bearing one.
It is what turns "search the repo" into "read one file",
and it is the rule everything below is in service of.

Five findings, in descending order of how much they cost today.

### 1.1 The tree has two roots but only one subtree

Every node §8 routes to —
`BRANCHES.md`, `RELEASE.md`, `scripts/VENDORING.md`, `scripts/EACH.md`,
`.claude/skills/`, `plan/` —
is maintainer-facing.
`README.md` is *declared* a root,
but the `Documentation` section it grew lists exactly those maintainer documents.
A user who follows the user root lands in the branch model.

So the user-facing half of the tree does not exist.
Not "is thin" — does not exist.
There is no node that owns what a connection *is*,
which types survive a round trip,
which extensions ship in the tarball,
or what `memory_limit` does and does not bound.

This is not an aesthetic gap.
It is the direct cause of eight open issues
that `PLAN-inbox-zero.md` classifies `CLOSE-DOCS` —
issues whose answer is known, is written down in the triage table,
and has nowhere to land.
The tree cannot absorb them because the tree has no user-facing leaves.

### 1.2 The medium is assumed to be Markdown in the repo

Every node in §8's tree is a `.md` file read on GitHub.
That is right for the engineering half and wrong for the other one.

A user asking "why isn't ICU loaded?" types `?` at an R prompt,
or lands on <https://r.duckdb.org/> from a search engine.
They do not read `README.md#extensions`.
The medium that reaches them is R documentation —
roxygen comments compiled to `.Rd`,
served by `?topic`, by `help.start()`, and by pkgdown,
and shipped offline in the tarball CRAN distributes.

So the tree needs **two media under one routing discipline**:
`.md` nodes for the engineering subtree,
`.Rd` concept pages for the semantics subtree.
And it needs to name the router for the second medium,
which §8 does not: `_pkgdown.yml`'s `reference:` index
is the user subtree's routing table,
exactly as the "Where to look" table is the maintainer subtree's.

The package already has one page in this shape and it works:
`?duckdb_storage` (`R/storage.R`), backed by `plan/PLAN-storage-locations.md`,
listed under `Storage locations` in `_pkgdown.yml`.
It is a documentation-only roxygen block owned by one `R/*.R` file —
the pattern generalizes as-is.
`PLAN-inbox-zero.md` §2.1 reaches the same conclusion from the triage side.

### 1.3 "No orphan docs" is the less damaging of the two orphan problems

§8 forbids orphan *documents* — a file no node routes to.
The opposite failure is worse and goes unnamed: **orphan surface** —
a script, workflow, build knob, or R file that no document owns.

An orphan document is found by reading; it is merely untidy.
Orphan surface is found when somebody files an issue,
and it is how a 46-issue backlog accumulates.

The tree already demonstrates it.
§8 itself records that `BRANCHES.md`'s §Tooling
"misses ten current loop scripts",
and that `scripts/main-dev-review.md` has zero inbound references.
Both were found by hand, once, during one review.
Neither would have been found by rule 3, which only checks the other direction.

Today's unowned surface, counted against the current tree:
35 files under `scripts/`, of which `scripts/VENDORING.md` and `scripts/EACH.md`
between them describe the vendoring and per-commit-CI subsets;
18 workflow files and 18 composite actions under `.github/`,
of which `each.yaml` is documented and the rest are not;
74 files under `R/` and 15 glue translation units under `src/`,
described only by a four-line summary in `AGENTS.md`;
and the build system — `configure`, `configure.win`, `src/Makevars.in`,
four `.mk` includes, `cleanup`, `install.libs.R` —
whose knobs are documented in `AGENTS.md` prose
that no rule keeps in step with the scripts.

### 1.4 Single-owner is asserted per topic, but topics are never enumerated

"Detail lives in exactly one leaf" is only checkable
against a list of topics to own.
§8's table enumerates *documents* and lets topics fall out of them.

That works for seven documents about one subject.
It does not work for a package whose surface is
five user-visible subsystems, five engineering subsystems,
and roughly 160 files that are neither vendored nor generated.
At that size the list has to run the other way:
enumerate the topics, assign each an owner,
and let *unowned* be a computable result rather than a discovery.

§6 below is that inversion.

### 1.5 The docs tree is sequenced behind work it does not depend on

§8's migration sits in Phase 4 of §9,
after the port stage, the verdict store, and the fork move.

The user subtree depends on none of that.
It depends on the triage in `PLAN-inbox-zero.md`, which is done,
and on facts about the package, which are knowable today.
Eight `CLOSE-DOCS` issues and eleven further closes
whose residual knowledge needs a home
are blocked behind a phase ordering that has no technical reason to hold them.

§7 re-sequences: the user subtree goes first, and goes alone.

### 1.6 One correction to the inherited plan

§8 assigns the script inventory to `scripts/VENDORING.md`.
That is right today and wrong as a rule:
`scripts/` also holds `format.py`, `rconfigure.py`, `install-libduckdb.sh`,
`flavor.sh` / `flavor.patch` / `flavor-package-name.R`, `merge-version.sh`,
`setup-git.sh`, `setup-makeflags.R`, `snapshot-accept.sh`, and `rethrow.R` —
none of which are vendoring.

**Inventories are owned by purpose, not by directory.**
Vendoring scripts belong to `scripts/VENDORING.md`,
build scripts to `BUILD.md`,
CI scripts and actions to `.github/CI.md`,
release scripts to `RELEASE.md`.
A reader looking for "how do I make a build faster"
should not have to know that the answer lives in a file named after vendoring.

## 2. The extended tree

Two roots, two subtrees, one discipline.

```
README.md ──┐  users: install, use, and the semantics guides
AGENTS.md ──┤  maintainers & agents: quickstart + router
            │
            ├─ SEMANTICS  (.Rd concept pages; routed by _pkgdown.yml)
            │    ?duckdb_connections   connection & instance model      [new]
            │    ?duckdb_types         R <-> DuckDB type mapping        [new]
            │    ?duckdb_extensions    what ships, what installs        [new]
            │    ?duckdb_memory        limits, spill, streaming         [new]
            │    ?duckdb_csv           CSV ingestion                    [new]
            │    ?duckdb_storage       file-system locations            (exists)
            │    ?backend-duckdb       dbplyr backend                   (exists)
            │    + the function reference already in _pkgdown.yml
            │
            └─ ENGINEERING  (.md nodes)
                 BUILD.md              configure, Makevars, fast paths  [new]
                 TESTING.md            testthat, DBItest, snapshots     [new]
                 .github/CI.md         workflows & composite actions    [new]
                 src/GLUE.md           C++ glue layer, cpp11, ALTREP    [new]
                 R/ARCHITECTURE.md     R layer conventions              [new]
                 BRANCHES.md           branch model, flavors, invariants
                 RELEASE.md            release FSM
                 scripts/VENDORING.md  vendoring mechanics
                      scripts/EACH.md  per-commit CI design
                 .claude/skills/       playbooks the routine executes
                 plan/                 designs, decisions, history
```

Both roots route into both subtrees, with different emphasis:
`README.md` leads with SEMANTICS and points at ENGINEERING for contributors;
`AGENTS.md` leads with ENGINEERING and points at SEMANTICS
as the place a user-visible behavior change must be reflected.

The five rules the tree runs on
are §1's four, plus one:

5. **Every path has exactly one owner** (§6).
   Unowned is a failure the repo can detect, not a discovery a review makes.

## 3. The semantics subtree

Each page owns one subsystem of user-visible behavior.
Other pages link to it; none of them re-explain it.
The `Fed by` column is the triage evidence from `PLAN-inbox-zero.md` §5 —
the page is not invented, it is the written-up form of answers already reached.

| Page | Owns | Fed by |
|---|---|---|
| `?duckdb_extensions` | the bundled set (`parquet` + `core_functions` only), autoload vs autoinstall, `INSTALL` once per version and platform, Windows and webR status, the libc++ guard | #2306; backs the closes of #1581, #100, #1083; roadmap pointers to #66, #117 |
| `?duckdb_types` | R ↔ DuckDB edges: UTF-8 strictness and `iconv()` recipes, sf/geometry via WKB, MAP, Arrow extension types read as storage type, `Inf`/`NaN`, `NULL` vs `NA` | #12, #1670, #642; notes from #590, #200, #1064 |
| `?duckdb_connections` | `dbConnect()` semantics: instance caching, `config`/`read_only` binding at instance creation, `dbdir` precedence, `duckdb_shutdown()`, multi-statement queries, prepared statements | #83, #171, #179 |
| `?duckdb_memory` | what `memory_limit` bounds and what it does not (not R-side results), `temp_directory` and spill, larger-than-memory patterns, streaming via `dbSendQueryArrow()` / `dbFetchArrowChunk()` | knowledge from #1065, #72, #1604; caveats of #97; the streaming answer from #162 |
| `?duckdb_csv` | `duckdb_read_csv()` versus `read_csv` in SQL, globs and the `filename` virtual column, sniffing limits until the #1511 rewrite | #1733; interim guidance for #1511, #118 |

`?duckdb_storage` already exists in this shape and is the reference implementation.

### 3.1 Why these five, and why first

`PLAN-inbox-zero.md` classifies 26 of 47 open issues as closable
without a line of package code.
Its §2.3 rule is that a close without a code change
is a close *with* a documentation change,
so that closing the queue does not destroy the knowledge in it.

Under that rule these five pages are not documentation debt —
they are the blocking dependency of 8 closes,
and the knowledge sink for 11 more:

| Verdict | Count | How many need a semantics page |
|---|---|---|
| `CLOSE-DOCS` | 8 | 8 — the page *is* the close |
| `CLOSE-FIXED` | 7 | 4 (#162, #200, #590 → types; #1581 → extensions) |
| `CLOSE-UPSTREAM` | 5 | 4 (#100, #1083 → extensions; #1064 → types; #1829 → `BUILD.md`) |
| `CLOSE-STALE-ASK` | 6 | 3 (#72, #1065, #1604 → memory) |

The remainder close on evidence alone:
#2030 is answered by `BRANCHES.md`,
#2230 by the existing `?backend-duckdb` reference,
#22 by `BUILD.md` (§4),
and #384, #202, #98, #1147 need no page.

### 3.2 Routing

`_pkgdown.yml` gains one `Guides` section listing the concept pages,
ahead of the function reference.
`README.md`'s `Documentation` section leads with that list,
so the user root routes to user documentation
before it routes to `AGENTS.md`.

The pages are Rd, not vignettes.
`PLAN-inbox-zero.md` §8.1 settled this and it holds here:
no vignette infrastructure exists,
Rd works offline and is cheap under `R CMD check`,
and none of the five needs executable chunks.
Revisit per page if one does.

## 4. The engineering subtree

Five nodes exist and are kept.
Five are new, and each takes ownership of surface that today has none.

| Node | Owns | Absorbed from |
|---|---|---|
| `BUILD.md` | `configure` / `configure.win` / `rconfigure.py`; `src/Makevars.in` and the `glue.mk` / `sources.mk` / `deps.mk` / `from-tar.mk` / `to-tar*.mk` includes; `.dd` dependency files; `cleanup`; `install.libs.R`; `CMakeLists.txt`; every build knob (`MAKEFLAGS`, ccache, `UserNM`, `DUCKDB_R_USE_SYSTEM_LIB`, `DUCKDB_R_PREBUILT_ARCHIVE`); `scripts/install-libduckdb.sh` and `scripts/install-duckdb-cli.sh`; the C++ warning policy | `AGENTS.md` §§Bootstrap, Fast build, Testing with prebuilt DuckDB, C++ Warning Policy |
| `TESTING.md` | `tests/testthat/` layout and helpers; DBItest; snapshot tests and `scripts/snapshot-accept.sh`; the CRAN guard; `test-flavor-package-name.R`; `revdep/`; how to run one file, and what needs a real engine | `AGENTS.md` §§Run Tests, Test Development, Manual Validation |
| `.github/CI.md` | the 18 workflows and 18 composite actions: what each gates, which run on which branch, `.github/versions-matrix.R`, the fast-path defaults in `custom/before-install`, the flavor scan in `custom/after-install` | `BRANCHES.md` §Tooling (partly), scattered prose |
| `src/GLUE.md` | the C++ bridge: translation-unit map, cpp11 and the `krlmlr/cpp11` patch stack, `RStrings` and the SEXP-constant convention, the wrapper types in `rapi.hpp`, ALTREP relations, `rethrow` and error context, `rfuns` | `AGENTS.md` §C++ Glue Code Conventions |
| `R/ARCHITECTURE.md` | the R layer: one-file-per-method convention, generated files (`cpp11.R`, `rethrow-gen.R`) and what regenerates them, the `get_package_name()` flavor seam, S4 classes, deferred S3 registration (`s3_register.R`, `zzz.R`) | `AGENTS.md` §Never Hard-Code the Package Name |

Note the `Absorbed from` column: four of the five new nodes
are largely a *move*, not new prose.
`AGENTS.md` currently holds correct, detailed content on all four subjects.
It is simply holding it as a root, which rule 2 forbids —
a root routes, it does not explain.
The move makes the single-owner rule true;
it does not have to make the content longer.

### 4.1 `BUILD.md` and the fast paths

`BUILD.md` is the first engineering node to write,
because it owns the two recipes that make every other kind of work cheap,
and because #22 (`CLOSE-FIXED`, "tricks to speed up install time")
is asking for exactly its contents.

Three install paths, and the rule for choosing:

| Path | Time | Use for | Do not use for |
|---|---|---|---|
| Vendored source build (`R CMD INSTALL .`) | 10–15 min cold | anything that must match what ships; the CRAN artifact | routine iteration |
| System libduckdb (`DUCKDB_R_USE_SYSTEM_LIB=1`) | ~90 s cold, ~4 s incremental | glue and R-level iteration, `load_all()`, `test_local()`, agent sessions | `R CMD build`; **any question about engine configuration** (§4.2) |
| Published binary (r-universe / P3M / CRAN) | seconds | reproducing a user report against a released build | testing local changes |

The second path is set up by `scripts/install-libduckdb.sh`,
which resolves the version from the vendored
`src/duckdb/src/function/table/version/pragma_version.cpp`,
fetches the matching release asset
(or the nightly staging artifact keyed by `DUCKDB_SOURCE_ID` for `-dev` snapshots),
and `configure` hard-fails if the installed library
was not built from the vendored commit.

Documentation work needs one more piece, and it belongs here too:
regenerating `man/*.Rd` requires the roxygen2 version
pinned in `DESCRIPTION`'s `Config/roxygen2/version`,
which is routinely a development version and therefore not on CRAN.
It installs from r-universe:

```r
install.packages("roxygen2", repos = c("https://r-lib.r-universe.dev", "https://cloud.r-project.org"))
```

Together with the libduckdb path
that turns "edit a roxygen block and regenerate the manual"
from a 15-minute proposition into about 90 seconds,
which is the difference between a documentation tree that is maintained
and one that is written once.

### 4.2 The fast path is not the package — record it

`DUCKDB_R_USE_SYSTEM_LIB=1` links the **release** `libduckdb`,
which is not configured the way the vendored build is configured.
Two differences are already known, and both are load-bearing
for the very page §3 puts first:

* **Linked extension set.**
  `src/Makevars.in` compiles with
  `-DDUCKDB_EXTENSION_PARQUET_LINKED -DDUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED`.
  The release `libduckdb` additionally links `icu`, `json`, and `autocomplete`.
  Asking `duckdb_extensions()` under the fast path therefore reports
  extensions the shipped package does not have — including `icu`,
  which is the entire subject of #2306.
* **Autoinstall default.**
  `src/Makevars.in` defines `DUCKDB_EXTENSION_AUTOLOAD_DEFAULT`
  and does **not** define `DUCKDB_EXTENSION_AUTOINSTALL_DEFAULT`.
  Per `src/duckdb/src/include/duckdb/main/settings.hpp`,
  that makes the shipped package autoload-on, autoinstall-**off**.
  The release library defines both, so under the fast path
  `autoinstall_known_extensions` reads `true`.

So the rule `BUILD.md` must state, in the imperative:
**never verify engine configuration under `DUCKDB_R_USE_SYSTEM_LIB`.**
Behavior that depends on how DuckDB was compiled —
linked extensions, autoload/autoinstall defaults, allocator,
anything guarded by a `-D` in `Makevars.in` —
must be checked against a vendored build.
Glue and R-level behavior may use the fast path freely.

This is exactly the class of fact that has no owner today,
costs an afternoon to rediscover,
and produces a confidently wrong sentence in a user-facing page if missed.

## 5. What the roots become

Neither root is rewritten in this plan's first phases;
both gain a routing section and lose, over time, the prose that moves out.

| Root | Today | Target |
|---|---|---|
| `README.md` | install, flavors + lag badges, a `Documentation` section listing maintainer docs, build, vendoring, contributors | install, flavors, **Guides** (the §3 pages) first, then a one-line pointer to `AGENTS.md` for contributors; build prose shrinks to a pointer at `BUILD.md` |
| `AGENTS.md` | router table, then ~270 lines that explain build, test, vendoring, flavor seam, and glue conventions | router table, a short quickstart (install the fast path, run the suite), and pointers; the five explaining sections move to their nodes per §4 |

`AGENTS.md`'s stale rows are fixed as part of the moves,
not before them:
the pointer to a `CLAUDE.md` that does not exist,
"runs daily via GitHub Actions" for what is now a routine-driven loop,
and the `main-dev ← main` mapping for a series that now lives as `main-fwd`.
`PLAN-vendoring-simplification.md` §8 already lists these;
they are repeated here only because the §4 moves are what will touch those lines.

## 6. Ownership, made checkable

The rule: **every path in the repository is owned by exactly one document.**
Not "should be" — *is*, verifiably, or CI says so.

A manifest, `.github/docs-owners.yml`, maps globs to owning documents:

```yaml
exclude:                          # not ours to document
  - src/duckdb/**                 # vendored engine, owned upstream
  - inst/include/cpp11/**         # vendored cpp11
  - man/**                        # generated from R/
  - NAMESPACE                     # generated by roxygen2
  - revdep/**                     # generated by revdepcheck
  - tests/testthat/_snaps/**      # generated by testthat
  - patch/**                      # owned by scripts/VENDORING.md as a set

own:
  BUILD.md:            [configure, configure.win, cleanup*, CMakeLists.txt,
                        src/Makevars*, src/include/*.mk, src/install.libs.R,
                        src/*.dd, scripts/rconfigure.py, scripts/install-*.sh,
                        scripts/setup-makeflags.R, scripts/format.py, Makefile]
  TESTING.md:          [tests/**, scripts/snapshot-accept.sh, scripts/rethrow.R]
  .github/CI.md:       [.github/workflows/**, .github/versions-matrix.R,
                        .github/copilot-instructions.md]
  src/GLUE.md:         [src/*.cpp, src/include/*.hpp, inst/include/duckdb_types.hpp]
  R/ARCHITECTURE.md:   [R/**]
  BRANCHES.md:         [scripts/flavor*, scripts/merge-version.sh, scripts/setup-git.sh]
  RELEASE.md:          [cran-comments.md, .Rbuildignore]
  scripts/VENDORING.md: [scripts/vendor*.sh, scripts/series-*.sh, patch/]
  scripts/EACH.md:     [scripts/each-*.{sh,py}, scripts/rcc-*.{sh,jq}]
  README.md:           [_pkgdown.yml, pkgdown/**, DESCRIPTION, docker/**, docker-compose.yml]
```

`scripts/docs-coverage.R` walks the tracked file list and fails on:

* **unowned** — a tracked path matched by no `own` glob and no `exclude` glob;
* **double-owned** — a path matched by two owners, which is a single-owner violation;
* **dangling** — an `own` key naming a document that does not exist,
  or a glob matching nothing (the stale-inventory failure of §1.3);
* **unrouted** — a `.md` document under the tree that no node links to
  (§8's original orphan-document rule, kept).

It runs in `R-CMD-check.yaml` as a fast non-blocking job first,
and becomes blocking once the tree is complete (§7 phase D).
Adding a script without documenting it then fails the same way
adding an undocumented exported function fails `R CMD check`.

The manifest doubles as the router's source of truth:
"to solve X, read Y" tables can be generated from it,
which is how the routing tables stop drifting from the tree.

## 7. Why not generate this

The obvious alternative is a generated wiki —
[DeepWiki](https://deepwiki.com/) is the well-known instance,
and `duckdb/duckdb-r` is a public repo it can already index.
It is worth being explicit about why generation is a complement here, not the plan.

What such systems do, per the
[Devin documentation](https://docs.devin.ai/work-with-devin/deepwiki)
and the [open-source implementation](https://asyncfunc.mintlify.app/reference/architecture):
clone, scan and filter files, chunk, embed, build a vector index;
then ask a model to decide a page structure from the file tree and README,
and generate each page with retrieved context, citing files.

That solves **discovery** — "where is this handled?" — and solves it well.
It does not solve the two problems this plan is about.

* **Ownership.** A generated wiki is a second copy of the truth,
  regenerated from the code, with no claim that the code has exactly one
  explanation. It cannot fail a pull request for adding an undocumented
  script, because it will cheerfully describe the new script instead.
  §6 is the part that cannot be generated, because it is a *constraint*,
  not a description.
* **Knowledge that is not in the code.** The five pages of §3 exist to record
  answers reached in issue threads, upstream rulings, and CRAN-policy
  trade-offs. "DuckDB requires valid UTF-8 and checks strictly — this is a
  feature, per the 2025-09 ruling" is not recoverable from the source tree at
  any embedding quality. Neither is the fast-path caveat of §4.2, which took a
  vendored build to establish.

The honest summary: the index a generated wiki produces
is the part this repo already has (the routing tables),
and the part it is missing is the part generation cannot supply.
So: keep the tree hand-written and authoritative;
add §6's coverage check, which is deterministic and cheap;
and link a generated wiki from `AGENTS.md` as a search aid if it proves useful,
clearly marked as unowned and non-authoritative.

The one piece of automation worth building is
`.claude/skills/docs-tree.md` —
the five rules encoded as a repo-local skill, invoked whenever docs are touched,
as `PLAN-vendoring-simplification.md` §8 already proposed.
That is progressive disclosure applied to the tree itself.

## 8. Phases

Each phase is independently shippable and docs-only except where noted.

| Phase | Delivers | Unblocks |
|---|---|---|
| **A (this PR)** | this plan; `BUILD.md` with the three install paths, the roxygen-from-r-universe recipe, and the §4.2 fast-path caveat; `AGENTS.md` routes to it and drops the moved sections | #22 closable; every later phase gets a 90-second doc loop |
| **B** | the five semantics pages of §3, one PR each, in the order `extensions` → `types` → `connections` → `csv` → `memory`; `_pkgdown.yml` gains `Guides`; `README.md` leads with it | the 8 `CLOSE-DOCS` closes, and the doc homes for 11 more (§3.1) |
| **C** | `TESTING.md`, `src/GLUE.md`, `R/ARCHITECTURE.md`, `.github/CI.md`; the matching `AGENTS.md` sections shrink to pointers | #1829, #2234, #2365 get a home; new contributors stop reading 270 lines of root |
| **D** | `.github/docs-owners.yml`, `scripts/docs-coverage.R`, wired non-blocking then blocking; `.claude/skills/docs-tree.md` | the tree stops drifting |
| **E** | the §8 moves inherited from `PLAN-vendoring-simplification.md`: `scripts/VENDORING-LOOP.md` → `plan/HISTORY-vendoring-loop.md`, `scripts/main-dev-review.md` → `plan/REVIEW-main-dev-2026-07.md`, and the `BRANCHES.md` / `scripts/VENDORING.md` node rewrites | history quarantined; inventories split by purpose per §1.6 |

Phase B is the point of the plan.
A exists to make B cheap; C–E exist so that B does not rot.

Ordering note: E is Phase 4 of `PLAN-vendoring-simplification.md` §9
and stays owned there;
it is listed for completeness because it touches the same routing tables.

## 9. Open questions

1. **Where does the dbplyr backend's semantics live?**
   `?backend-duckdb` is a reference page for the translation methods.
   The *semantics* — which verbs push down, what `DISTINCT ON` (#384)
   and `pivot_longer()` (#2029) do today — may deserve a sixth guide,
   or may belong in `?duckdb_types` and the reference page.
   Leaning: defer until B is done and the shape is visible.
2. **Does `.github/CI.md` belong under `.github/`?**
   It is co-located with what it owns, which is consistent with
   `scripts/VENDORING.md`, but `.github/` is otherwise machine-facing.
   Alternative: `CI.md` at the root, next to `BUILD.md` and `TESTING.md`.
3. **Blocking threshold for §6.**
   Making `docs-coverage` blocking before the tree is complete
   would fail every PR. Proposed: blocking after phase C,
   with `exclude` carrying an explicit, shrinking `# TODO(phase C)` list
   so the remaining debt is visible rather than silent.
4. **Does `patch/` want its own node?**
   It is currently excluded as a set owned by `scripts/VENDORING.md`.
   If the "send patches upstream" sweep becomes routine
   (krlmlr/duckdb-r#57 is the tool), it may earn one.
