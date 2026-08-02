# Vendoring as an Agentic Loop — Design Plan

Status: **historical** — superseded by the series loop
(`.claude/skills/series-loop.md`);
kept as design context.
It lives under `plan/` because it is history, not routing:
what the pipeline does *today* is owned by
[`scripts/VENDORING.md`](/scripts/VENDORING.md) (mechanics),
[`scripts/EACH.md`](/handbook/operations/ci/per-commit/README.md) (per-commit CI),
and the skills in `.claude/skills/` (procedure).
Nothing here is current;
the measurements it once carried now live in
[`experiments/2026-03-vendor-build-cost/`](/experiments/2026-03-vendor-build-cost/README.md).
References to `vendor.yaml` and the `rcc-smoke-fix` /
`advance-green-dev` skills below describe artifacts
that no longer exist.
Target repo for implementation: `krlmlr/duckdb-r` (the CI/CD fork; see
[`BRANCHES.md`](/BRANCHES.md)). Source-of-truth CI/CD lives in
`duckdb/duckdb-r@main` and is forward-ported.
Author context: drafted on branch `claude/vibrant-ride-i4b5r2`.

This document proposes a re-architecture of the DuckDB-R vendoring pipeline as
a **modular agentic loop**: Claude drives the creative steps, while GitHub
Actions runs the predictable, parallelisable work and serves as the single
**ground truth** for build results. It builds directly on the existing system
documented in [`BRANCHES.md`](/BRANCHES.md) and
[`scripts/VENDORING.md`](/scripts/VENDORING.md), and supersedes parts of the
three repair skills in `.claude/skills/`.

---

## 1. Where we are today (baseline)

| Concern | Today | Mechanism |
|---|---|---|
| **Vendor** upstream C++ into `*-dev` | hourly, commit-by-commit, ≤30/run | `vendor.yaml` → `scripts/vendor-one.sh ./duckdb --commits 30` |
| **Trigger** per-commit CI | fire-and-forget dispatch, no cap | `each.yaml` → `scripts/each-rcc.sh` → `gh workflow run rcc -f ref=<sha>` (since superseded by the sharded matrix, [`scripts/EACH.md`](/handbook/operations/ci/per-commit/README.md)) |
| **Build / smoke-test** a commit | one independent `rcc` run per commit | `R-CMD-check.yaml` (job *Smoke test: stock R*) |
| **Record** the result marker | commit-status `rcc` = pending/success/failure | `R-CMD-check-status.yaml` (via `workflow_run`) |
| **Harvest** logs to ground truth | **delayed**, 4×/day | `rcc-logs.yaml` → `scripts/rcc-logs.sh` → orphan branch `rcc` (`runs2.ndjson`, `logs2/<sha>.log`). Since [`scripts/EACH.md`](/handbook/operations/ci/per-commit/README.md) §3 the `each-rcc` legs publish their own records as each commit is decided, and this is the backstop. |
| **Repair** a red commit | fork `broken-<sha>-dev`, amend the failing commit, **cherry-pick (replay) the whole tail**, force-push | skill `rcc-smoke-fix.md` |
| **Advance** a repaired branch | cherry-pick next 30 vendor commits, matched by vendored upstream SHA | skill `advance-green-dev.md` |
| **Self-heal** transient breaks | squash (window 1) / transient patch (≥2) | skill `rcc-smoke-fix-self-heal.md` |
| **Promote / publish** | r-universe builds `.dev` **directly from `*-dev`** (bleeding edge); promotion to `-dev-base`/stable is **manual** | `BRANCHES.md` patch-release flow |

### Pain points this plan addresses

1. **Latency to ground truth.** Build logs land on the `rcc` branch only on the
   4×/day `rcc-logs.yaml` schedule — long after a run completes. The loop wants
   results *right after completion*.
2. **r-universe coupled to bleeding edge.** Because r-universe publishes from
   `*-dev`, any red tip breaks the published `.dev` package. There is no
   decoupled "known-green" source.
3. **Replay cost & branch sprawl.** `broken-<sha>-dev` forks plus full-tail
   cherry-picks create parallel histories and re-run CI on commits that were
   already green.
4. **No bounded backlog.** Nothing caps how far `*-dev` may run ahead of the
   last green build, so the repair debt is unbounded.

---

## 2. Design principles

- **Separation of concerns.** Four orthogonal primitives — *vendor*, *build*,
  *promote*, *repair* — each independently invokable and individually testable.
- **GHA is ground truth, Claude is the brain.** Everything deterministic
  (vendoring, building, status-keeping, promotion) runs in GHA. Claude only
  performs the irreducibly creative step: **repair**. The loop never trusts
  Claude's local build over the GHA marker.
- **Modularity over a monolith.** Each primitive is callable three ways — by
  Claude (tight loop), by a `schedule:` cron, or by an external API call /
  `workflow_dispatch` / `workflow_call`. No primitive assumes who invoked it.
- **Indistinguishable markers.** The new build path produces the *same* commit
  statuses (context `rcc`) and the *same* `rcc`-branch records as today, so
  every existing consumer (the skills, dashboards, `advance-green-dev`) keeps
  working unchanged.
- **Bounded work.** Normal batches are ≤25 commits. The bleeding edge may run
  at most **25 commits ahead of its first failing build** (cap), with a floor of
  ~3–5 commits past any failure so transient breaks are detectable (§3.2 A).
  The cap also bounds the repair blast radius to ≤25 rebuilds (§3.2 D).
- **Every glue tweak is auditable after the fact.** Any change Claude folds into
  the history (glue `src/*.cpp` / `src/include/`, `R/`, snapshots, `patch/`)
  must be recoverable and reviewable as an isolated delta — without trusting a
  commit message. This falls out **for free from path filtering**: the vendored
  content lives under a fixed, known path set, so the R-side delta is just the
  diff *outside* those paths. An agentic review surface (primitive **E**, §3.4)
  turns that path-filtered delta into a sign-off workflow with tool assistance.

---

## 3. Target architecture

### 3.1 Branch model — decouple the r-universe source

Introduce a new **`*-green` branch** per release line as the *only* thing
r-universe builds from. (Decision: a dedicated branch, distinct from
`*-dev-base`, which keeps its current meaning in the release flow.)

```
duckdb/duckdb (upstream)
      │  vendor (bounded)
      ▼
krlmlr/duckdb-r@*-dev          ← bleeding edge; may be red, but ≤25 commits
      │                          ahead of its first failing build (the frontier)
      │  deterministic promotion (GHA): fast-forward to the
      │  longest all-green contiguous prefix
      ▼
krlmlr/duckdb-r@*-green        ← ALWAYS green; r-universe publishes .dev from HERE
```

Mapping (illustrative, mirror for every active line):

| Line | bleeding edge (`*-dev`) | green source (`*-green`, NEW) | published as |
|---|---|---|---|
| main | `main-dev` | `main-green` | `duckdb.dev` |
| v1.5 | `v1.5-variegata-dev` | `v1.5-variegata-green` | `duckdb.1.5.dev` |
| v1.4 | `v1.4-andium-dev` | `v1.4-andium-green` | `duckdb.1.4.dev` |

Invariants:

- `*-green` is always a **first-parent ancestor** of `*-dev`.
- **Green from the last release tag forward.** Every commit from the most
  recently vendored upstream release tag `vx.y.z` up to the `*-green` tip is
  `rcc`-green. The tag is the trust *floor* (and the natural `SINCE` anchor,
  replacing the skills' hardcoded dates like `2026-04-11`): it bounds every
  scan/promotion walk and gives a meaningful guarantee — "everything published
  since the last release is clean." `vendor-one.sh` already *always* vendors
  tags, so the anchor is reliable; a release tag that is not green is a
  release-blocker that repair must clear before promotion can cross it.
  The tag is the floor, **not** a promotion ceiling — promotion still advances
  to the freshest green commit (§3.2 C), or `.dev` would go stale between
  releases (~every 4 months).
- The **frontier** = the first commit after `*-green`'s tip on `*-dev` whose
  `rcc` status is not `success` (red or, transiently, absent). The distance
  `green-tip … frontier` must stay ≤ 25; the vendor primitive refuses to extend
  `*-dev` beyond that until the frontier is repaired.

> r-universe repointing (`*-dev` → `*-green`) is a config change in the
> r-universe org's package registry, done once per line at rollout (see §7).

### 3.2 The four primitives

```
 ┌──────────────┐   ┌─────────────────────────┐   ┌────────────────────┐
 │ A. VENDOR     │──►│ B. BUILD (matrix+fan-in) │──►│ C. PROMOTE (green) │
 │ append ≤N     │   │ legs: build+test+status; │   │ ff *-green to the  │
 │ (floor L,     │   │ fan-in: harvest rcc once │   │ green prefix (GHA) │
 │  cap 25)      │   │ (idempotent, repeatable) │   │                    │
 └──────────────┘   └─────────────────────────┘   └────────────────────┘
        ▲                       │ frontier is red                │
        │                       ▼                                │
        │             ┌────────────────────┐                     │
        └─────────────│ D. REPAIR (Claude)  │◄────────────────────┘
                      │ amend/squash IN     │
                      │ PLACE on *-dev,     │
                      │ force-push          │
                      └────────────────────┘
```

#### A. Vendor primitive *(extends `vendor-one.sh` / `vendor.yaml`)*

- Input: `(dev-branch, upstream-branch, budget)`.
- Effect: append ≤ budget vendor commits to `*-dev`, re-apply `patch/`, push.
- **Budget = self-heal floor, 25-ahead cap.** Replaces the flat
  `vendor-one.sh --commits 30`:
  - **Cap:** never let `*-dev` get more than **25 commits ahead of the first
    failing build** (§3.1). Convenient side effect: a normal batch is ≤25 legs —
    comfortably under the 256-job matrix cap, so steady state never needs
    sharding.
  - **Floor:** do **not** pause the instant a commit goes red — keep vendoring a
    small lookahead `L` (≈3–5) past the first failure so the self-heal
    classifier can fire (a green within `L` ⇒ transient ⇒ squash/transient
    patch; all-`L`-red ⇒ persistent ⇒ hand to repair). Without this lookahead
    you cannot tell a transient break from a real one.
  - So: `advance until (25 ahead of first failing build) OR (caught up with
    upstream)`, guaranteeing `≥ L` commits past any failure before pausing.
- Unchanged: commit-message format, `duckdb/duckdb@<sha>` marker, patch-drop
  behaviour.

#### B. Build primitive — synchronous **sharded matrix** CI *(NEW: `rcc-matrix.yaml`)*

> **Landed, in narrower form.** This primitive is now implemented inside the
> existing `each.yaml` rather than as a separate `rcc-matrix.yaml`, because the
> commit-selection semantics were already there. See [`scripts/EACH.md`](/handbook/operations/ci/per-commit/README.md) for
> what was built, the GitHub Actions limits it works within, and two corrections
> to the analysis below: within-shard reuse comes from **ccache**, not
> incremental `make` (§4.2), and the reverse-include estimator of §4.3 exists as
> `scripts/each-cost.py`.

Replaces fire-and-forget dispatch (`each-rcc.sh`) **and** the 4×/day harvest
(`rcc-logs.yaml`). One workflow that, given a branch and a set of commits:

1. **Plan step** enumerates the target commits (default: every commit between
   `*-green` tip and `*-dev` tip lacking a current `rcc` success), orders them
   first-parent oldest-first, and partitions them into **cost-balanced shards**
   (see §4). It **does not stop at the first red** — it builds the whole frontier
   batch (bounded by the ≤25 window), so the self-heal classifier always has
   lookahead past a failure (§3.2 A floor). Promotion stops at the frontier;
   only *scanning* runs ahead.
2. **Matrix step** — one leg per shard. Each leg, for each commit in its shard
   *in chronological order*:
   - checks out the commit, builds from source (incremental `make` reuses the
     previous commit's objects within the shard; cache-free, see §4) + runs the
     smoke test,
   - **sets the `rcc` commit-status** (pending→success/failure) — an idempotent,
     per-SHA GitHub API call, so it is fresh per commit with **no contention**,
   - **uploads its log tail as a per-leg artifact** (no git push from legs).
3. **Fan-in (reduce) job** — `needs: [matrix]`, **`if: always()`** (so it runs
   even when some legs fail — we *want* the failure records). A single writer
   reconstructs the `rcc`-branch records from this run's commits and does **one**
   commit + push. Concretely it runs the existing idempotent harvester
   (`scripts/rcc-logs.sh`) **scoped to this run's commit set**, which derives
   `{commit,status,run}` + log purely from ground truth (commit status + run
   logs). No concurrent-push loop; no partial state.
4. Markers are **byte-compatible** with today's (context `rcc`, same
   `runs2.ndjson` schema, same `logs2/<sha>.log` layout).

**Why a fan-in instead of per-leg pushes, and how it stays repeatable.** Per-leg
pushes to one orphan branch race and leave partial state on cancel. The fan-in
is a single writer. More importantly, the `rcc`-branch content is a **pure
function of durable ground truth** (statuses live on the commits; logs live in
run artifacts/API) — so the *same* harvester runs in three modes that are all
the same idempotent code:
- *fast path:* the `if: always()` fan-in (fresh within seconds of the last leg);
- *backstop:* a low-frequency `schedule:` invocation (unscoped) that backfills
  anything a cancelled run missed;
- *on demand:* `repository_dispatch`/manual to rebuild the branch from scratch.

Because it is idempotent and reconstructs from ground truth, **a missed fan-in
is self-healing** — the next reconcile makes it whole. *Honest limit:*
`if: always()` covers leg failures, but a full *workflow* cancellation can still
skip the fan-in; that is exactly why the scheduled reconciler stays as the
correctness backstop, and why the matrix workflow's `concurrency` is scoped so a
newer run does not cancel an in-flight one.

Invocation (all three supported — the workflow doesn't care who called it):

- **Claude tight loop:** `workflow_dispatch` with an explicit commit range,
  then wait on run completion and read the `rcc` branch.
- **Scheduled:** `schedule:` cron replaces the hourly each + 4×/day harvest.
- **From another workflow / API:** `workflow_call` (e.g. invoked by the vendor
  primitive right after it pushes) or `repository_dispatch` from an external
  API caller.

> **Incremental rebuilds make this cheap** (see §4, measured in Appendix A): the
> build is a **unity build** (~340 `ub_*.o`/object groups, not ~1700 separate
> TUs), and a typical vendor commit changes ~2 `.cpp` in zero or one header — so
> it invalidates only a handful of unity objects (~5 of 351; ~90 s vs cold).
> The normal per-commit path gets this from the existing CI caches; the bulk
> path gets it from **incremental `make` within a shard** (§4.2) — no shared
> cache. The `DUCKDB_R_USE_SYSTEM_LIB` fast path from `AGENTS.md` is *not* usable
> either way — we are validating that each commit builds *from source*.

#### C. Promote primitive — deterministic green advance *(NEW: `promote-green.yaml` + `scripts/promote-green.sh`)*

A pure function of commit statuses; **no building, no judgement, fully in GHA**:

- Walk `*-dev` first-parent from the `*-green` tip forward.
- Advance a cursor while each commit's `rcc` status is `success`.
- Fast-forward `*-green` to the last such commit and push.
- Stop at the first non-success commit (the frontier) — never skip it.

Idempotent and safe to run on any trigger (post-build `workflow_call`, cron, or
Claude). Because `*-green` only ever fast-forwards along `*-dev`, r-universe
always sees a clean, buildable, monotonically advancing history.

#### D. Repair primitive — agentic, **in place** *(evolves `rcc-smoke-fix.md`)*

When the frontier is red, Claude repairs it **directly on `*-dev`**, not on a
`broken-<sha>-dev` fork:

- Reproduce locally (triage from `logs2/<sha>.log` first; full `R CMD INSTALL`
  to confirm), apply the smallest fix in the existing priority order
  (`patch/` → glue → `R/` → snapshots → tests).
- **Amend or squash the fix into the failing commit itself**, then let
  `git rebase` carry the descendants forward mechanically (their *content* is
  unchanged — adjacent vendor commits are independent snapshots — so no replay
  / re-derivation is needed). Force-push `*-dev` (allowed; `*-dev` is
  unprotected per `BRANCHES.md`).
- The self-heal cases (squash window 1 / transient patch ≥2) from
  `rcc-smoke-fix-self-heal.md` carry over unchanged, now applied in place.

This is the "fix by amending/squashing the failing run and **not replaying the
rest**" model. See §6 for the hybrid transition away from `broken-<sha>-dev`.

**Blast radius = the bound.** Amending `F → F'` rebases every descendant onto
`F'`, giving them new SHAs that lose their `rcc` status, so GOTO 2 rebuilds
exactly the commits `*-dev` had vendored *past* `F`. By construction that is
≤ 25 (the §3.1 cap; `F` is the first failing build), typically the self-heal
lookahead (~3–5). This is the concrete meaning of "not replaying the rest":
the old `broken-<sha>-dev` model cherry-picked the *entire* subsequent history
(unbounded), whereas in-place repair rewrites only the bounded lookahead. Those
≤25 rebuilds are cheap — they were almost certainly red too (same break
cascading) and the fix flips them green, and incremental rebuilds recompile only
the few unity objects the tiny fix touches (Appendix A).

**Reviewability of the fold.** Amending keeps history bisectable and the vendor
markers intact, and it does *not* hide the R-side edit: the vendored content is
confined to a fixed path set, so the tweak is recoverable by **path filter**
(see primitive **E**, §3.4) — the diff outside the vendored paths *is* the
R-side delta, whether it sits in its own commit or is folded into a vendor
commit. An optional `Glue-tweak:` trailer (classifying the change, e.g.
`api-rename`, `snapshot`, `warning-fix`, `patch-refresh`) aids discovery and
records intent, but the path-filtered diff is the source of truth.

C++ core fixes belong in `patch/` (already discrete, reviewable files); their
expansion into `src/duckdb/` is filtered out as mechanical, so you review the
`patch/*.patch` file, not its expansion — exactly as today.

### 3.3 The loop / orchestration

Each iteration (driven by Claude, or by a chained set of GHA triggers):

```
1. VENDOR   A: append ≤budget commits to *-dev, respecting the ≤25 bound.
2. BUILD    B: synchronously build all commits lacking a green status;
               wait for ground truth on the `rcc` branch.
3. PROMOTE  C: fast-forward *-green over the all-green prefix.
4. REPAIR?  if a red frontier exists:
              D: amend/squash it in place, force-push *-dev;
              GOTO 2 — but only for the rewritten range (new SHAs only),
              which is ≤25 commits (the bound) and incremental-rebuild cheap.
            else: iteration done.
```

The loop terminates an iteration when `*-green == *-dev` (fully caught up) or
when the bound is hit and the frontier still needs human/Claude attention.
Ground truth is *always* re-read from GHA between steps; Claude never advances
`*-green` on the strength of a local build.

### 3.4 E. Review primitive — glue-tweak audit *(NEW: `scripts/glue-tweaks.sh` + `.github/workflows/glue-review.yaml`)*

A standing requirement: **every tweak Claude folds into the glue code must be
reviewable after the fact**, agentically and with tool assistance — not by
re-reading giant vendor diffs by hand. This primitive is the review surface.

**Extraction (path filter — no re-vendoring needed).** The mechanical
(vendor-generated) content lives under a fixed, known path set — **verified by
inspecting 163 vendor commits** (Appendix A): every vendor commit touches only
these, plus the two generated files `R/version.R` (the version bump, all 163
commits) and `src/include/sources.mk` (the compiled-object list, when the file
set changes):

```
src/duckdb/                 # vendored DuckDB C++ core
inst/include/cpp11/         # vendored cpp11
inst/include/cpp11.hpp      # vendored cpp11 single header
R/version.R                 # generated: version string per vendor run
src/include/sources.mk      # generated: unity-build object list
```

(Flavor files managed by `scripts/flavor.sh` — `DESCRIPTION` `Package:`,
`src/include/rapi.hpp`'s `DUCKDB_PACKAGE_NAME`, etc. — are likewise mechanical
and can be excluded or reported in their own bucket.)

Everything *else* a commit touches is, by construction, a glue/R/test/`patch/`
tweak. (In the 163-commit sample the only non-mechanical touches were 3 genuine
folded fixes — a test + two snapshots — exactly what review should surface.) So
`scripts/glue-tweaks.sh` is a thin path-filtered `git` wrapper:

```bash
# All R-side tweaks folded into a range, mechanical paths excluded:
git log -p --first-parent <green-tip>..<dev-tip> -- \
  ':(exclude)src/duckdb' \
  ':(exclude)inst/include/cpp11' ':(exclude)inst/include/cpp11.hpp' \
  ':(exclude)R/version.R' ':(exclude)src/include/sources.mk'
```

It emits per-commit tweak patches and an aggregate "all glue tweaks since
`<ref>`" diff. A clean vendor commit contributes nothing under these filters; a
repaired one contributes exactly its fix. **No scratch build, no pristine
reconstruction** — the filter alone isolates the delta. The optional
`Glue-tweak:` trailer (§3.2 D) is just an index to find candidates fast; the
filtered diff is authoritative.

**Agentic review loop.** `glue-review.yaml` runs the extraction over the range
since the last reviewed point (a `*-reviewed` marker ref, advanced on sign-off),
and hands the residuals to a Claude review task that:

- classifies each tweak (API rename, behavioural snapshot change, warning fix,
  patch refresh, test adaptation),
- flags anything that changes R-visible behaviour or weakens a test
  (cross-checking against the priority order in `rcc-smoke-fix.md`),
- posts a digest (PR comment / issue / summary) for human sign-off, and
- on approval, advances the `*-reviewed` marker.

This decouples *correctness* (the `rcc` green gate, which lets promotion
proceed) from *review* (human accountability for R-side edits): promotion does
not block on review, but no glue tweak escapes the audit trail. The review
marker can trail `*-green` without holding up publication.

### 3.5 (Optional) `*-vendor` — a derived pure-vendoring branch

The path filter (§3.4) cannot see a stray edit *inside* `src/duckdb/`. To make
both that integrity check **and** the review baseline a cheap `git diff` with a
stable compare URL — no rebuild — optionally maintain a **derived `*-vendor`
branch**: one commit per vendored `duckdb/duckdb@<sha>`, equal to `vendor-one.sh`
output + patch stack, with **no R-side fix folded in**. It is a *purely derived,
idempotent artifact* (like the `rcc` branch), regenerable from scratch anytime;
the invariant is **`*-dev ≡ *-vendor + repairs`**.

Then, matched by the `duckdb@<sha>` marker:

- `*-vendor..*-dev` (vendored paths) — any non-`patch/` difference = a stray
  hand-edit (the continuous integrity guard).
- `*-vendor..*-dev` (everything) — the *complete* human contribution, including
  any inside-vendored deviation the path filter would miss; a superset of the
  §3.4 review surface.

**Worth it?** In the common case `*-vendor` is identical to `*-dev` except at the
handful of repaired commits, so its marginal value over "path-filtered residual
+ a periodic re-vendor guard" is small, at the cost of a second branch kept in
lockstep and regenerated each cycle. Recommendation: **start without it** (cheap
confinement guard + amortized determinism guard on the green tip), and add
`*-vendor` only if continuous cheap comparison or a human-facing compare URL is
wanted. See §8 Q9.

---

### 3.6 The routine — what Claude actually runs *(REVISED)*

§3.3 describes the loop as a peer set of primitives. Running the `main-rewind-dev`
rebuild end to end (1001 commits, ~1180 first-parent upstream commits from the
fork point to the mainline tip) showed the division of labour is more lopsided
than that, and in a useful direction: **CI does all the heavy lifting, and the
only thing worth doing locally is the cheap gate that CI cannot afford to be
the first to discover.**

So the loop is a **Claude Code Web routine** — a scheduled session, not a
workflow — that on each firing does exactly four things, in order:

```
1. PROMOTE  fast-forward <line>-green to the youngest commit on <line>-dev
            whose `rcc` status is success (and whose ancestors are all green).
            Ground truth only; never a local build.
2. VENDOR   append the newest upstream first-parent commits to <line>-dev,
            one commit each, gated locally on the glue compiling.
3. REPAIR   take the OLDEST failing commit past <line>-green -- and only that
            one -- fold the fix into it, replay the tail, force-push <line>-dev.
4. PRs      update any pull request whose base moved under the force-push.
```

**Why only the oldest failure.** Reds past the first one are usually the same
break re-reported: every later commit inherits the broken glue. Repairing the
oldest and letting CI re-run is cheaper and less error-prone than triaging a
frontier. It also keeps the blast radius of each force-push to the tail of one
commit. In the rebuild, all four upstream API breaks past the replay window
behaved this way — one adaptation each, every later commit green again.

**The local gate is a syntax-only glue compile, not a build.**

```bash
clang-format -i src/*.{c,cc,cpp,h,hpp}          # must be a no-op
g++ $FLAGS -fsyntax-only <the 15 glue TUs>      # 4 at a time
```

Roughly 20 s per commit against a fully vendored header tree, versus minutes
for a real build, and it catches *every* upstream API change — which is the
only class of breakage a vendor commit can introduce into the glue. It does not
link and it does not test; both are CI's job. Over 320 vendored commits this
gate found four breaks and cost about six seconds of vendoring plus twenty of
checking per commit.

**The style gate is not optional.** The per-commit `rcc` runs are
`workflow_dispatch`, and `.github/workflows/commit/action.yml` has:

```yaml
- name: Write diff and fail for workflow_dispatch
  if: steps.check.outputs.has_changes == 'true' && github.event_name == 'workflow_dispatch'
  run: |
    echo "Changes detected in workflow_dispatch build. Diff:"
    git diff
    exit 1
```

Anything the auto-style, roxygenize or snapshot steps rewrite is an immediate
failure rather than a commit-back. A glue tweak that is merely *correct* is not
enough: it must also be clang-format clean, or every commit from that index
onwards goes red. This is the single most likely way for an otherwise good
adaptation to poison a long chain, and it is invisible to a local build. Run
the formatter before the compiler, and treat a non-empty `git diff` as a
failure of the same severity as a compile error.

**Version skew is a real risk here.** CI installs `clang-format-21`; whatever
the routine has locally may format differently in edge cases. The routine
should pin the same major version where it can, and otherwise treat the first
CI run after a push as the authority — CI prints the diff it wants, which is
directly appliable.

**Fold, do not append.** The adaptation belongs in the commit that vendors the
upstream change which requires it, so that every commit of the chain is
independently green and a bisect over the chain stays meaningful. A fixup
commit on top is acceptable only as a temporary measure to avoid disturbing
in-flight CI, and must be squashed back into its target before the next
promotion. To find the target from the log alone:

```bash
git log --oneline -S'<the removed symbol>' <line>-dev -- src/duckdb
```

## 4. Compute model & sharding (measured)

All numbers here are measured, not assumed — see **Appendix A** for the
experiment (8 consecutive v1.5 vendor commits, ccache 4.9.1, in-place full
rebuilds). Three facts drive the design:

- **Cold build ≈ 841 s** (351 unity objects). The build is a **unity build**
  (~340 object groups), and it links with **LTO** (`-flto=auto`).
- **A typical adjacent commit is ~98% cached (~90 s).** Zero-header commits
  (66% of all vendor commits) recompile only ~5 of 351 objects.
- **Header cost is bimodal — driven by *reach*, not count.** A *narrow* header
  invalidates ~26 objects (92% hit, ~170 s); a *widely-included* header can
  invalidate >50% of the build (measured: 3 wide headers → 190 misses, 45% hit,
  738 s — nearly cold). Header *count* is a poor predictor; what matters is how
  many unity objects transitively include the changed header.

The Appendix-A numbers are from a fast local box; on the **GHA runners** a cold
build is ≈36 min (~10 fit a 6 h job). The bulk path (§4.2) realises the ~98%
adjacent-commit reuse via **incremental `make` within a shard**, not ccache — the
hit-rate figures describe the same "only the changed unity objects recompile"
effect either way.

### 4.1 Two build paths with different economics

- **Normal path (unchanged):** a single commit, or a small daily batch (§3.2 A,
  ≤25), is checked by the existing per-commit `rcc` workflow, which already uses
  the bespoke caches in `custom/after-install` (the `duckdb.tar` tree-archive +
  `ccache-action`). Cached, fast, near-zero Actions pressure — the common case.
- **Bulk path (new, this section):** rebuild *many* commits at once after a
  force-push or first-time backfill. This is the matrix primitive, and it is
  deliberately **cache-free** (§4.2).

### 4.2 Massive builds are cache-free; incremental make within a shard, bounded by 6 h

**No shared cache for the bulk path.** The bespoke caches are **GHA-action-bound**:
`actions/cache` restore/save run once per *job*, and the `duckdb.tar` key is per
*whole tree* (`hashFiles('src/duckdb/**')`). A shard that builds many commits in
one job cannot restore/save a per-commit archive mid-job, and invoking those
actions per commit is impractical — so the matrix path does not reuse them.

Instead, each shard builds its slice **sequentially in one workspace with
incremental `make`**: build the first commit cold, then `git checkout` each next
commit (≈2 files change) and rebuild **without cleaning**. Make recompiles only
the changed unity objects (via the `.dd` dependency tracking) — the same ~98%
reuse Appendix A measured, but from make timestamps rather than ccache. No
`actions/cache` calls, no cross-job state. The price is one cold build per shard
(not per commit), which is cheap amortized over ~20 commits, and **massive builds
are infrequent** anyway (force-push / backfill). The normal per-commit `rcc`
runs are untouched and stay cached.

**Capacity / the 6-hour job limit.** On the GHA runners (slower than the
Appendix-A local box): ~**10 cold builds** fit in 6 h (≈36 min each, from
source) and a check is ~**4 min**/version. Since only the *first* build in a
shard is cold and the rest are incremental, a shard comfortably builds and tests
**~20 consecutive versions** in 6 h (1 cold + ~19 incremental + check). With the
256-job matrix cap that is **~256 × 20 ≈ 5 000 commits per run** before the
limit forces multi-run continuation (§4.3). 5 000 ≫ any realistic backlog
(`main` produces ~2 500 commits/year), so a timeout is effectively unreachable;
the continuation path exists only for completeness.

### 4.3 Header-aware (cost-balanced) sharding for bulk replay

When a genuine backlog must be (re)built (large force-push, or first-time
catch-up), the plan step:

1. **Predicts per-commit cost** from `git diff --numstat` + a **reverse-include
   map** (header → number of unity objects that transitively include it,
   computed once per build). Weight ≈ fixed floor + `Σ reach(changed header)`.
   This correctly makes wide-header commits heavy and isolates them.
2. **Partitions the contiguous sequence into cost-balanced shards** of
   **≤~20 commits** (the 6 h bound, §4.2; contiguity preserves within-shard
   *incremental-make* reuse). Balance by *predicted cost*, not commit count, so
   shards finish together (no straggler) — a wide-header commit costs a
   near-cold incremental, so it weighs heavily and gets isolated. Pick the
   *fewest* shards that keep each ≤20 / under 6 h (good-neighbour runner budget).
3. **Frontier-first ordering** so the ≤25 commits past `*-green` build first and
   promotion can advance immediately; backfill the rest.
4. **Multi-run continuation** if commits exceed `256 × 20 ≈ 5 000` (or the
   runner budget): build a prefix, re-dispatch
   (`workflow_call`/`repository_dispatch`) for the remainder as `*-green`
   advances.

Worked example — **v1.5.3 → v1.5.4 (101 commits, ~3 weeks)**: at ≤20 commits per
shard that is **~6 cost-balanced shards**, each one cold build (~36 min) plus
~14–18 incremental builds + checks ≈ **2–3 h**, comfortably under 6 h, on 6
concurrent runners. Shard *sizes* are uneven (cheap/R-only commits packed
densely, header-cascade commits isolated) but wall-times match — that is the
header-aware balancing. The whole range fits in **one** matrix run.

### 4.4 The real floor is per-commit test cost, not compilation

~36 of those 101 commits are pure R-side (no vendored C++) and build in seconds;
the rest carry a **~70–90 s fixed floor** that is mostly **LTO link of the big
`.so` + R install + smoke test**, *not* compilation. So 65 C++ commits × ~90 s
≈ 100 min is irreducible overhead if every commit is tested. The lever that
actually moves this is **dropping LTO for the smoke build**: it is irrelevant to
verifying a commit compiles and tests pass, and it dominates the link (hence the
floor); keep LTO only on the shipped artifact. In the **bulk (cache-free) path**
the smoke build may also compile **`-g0`** for faster cold builds — a failure
just yields a red status, and the repair primitive reproduces it *standalone*
with `-g` for the trace, so debug info is not needed during a massive run. (The
`-g` + archive-strip discussion of the earlier draft applied only to a cached
path; with no archive in the bulk path, `-g0` is the simpler win.)

(Only-missing-status filtering — never rebuild a commit that already has a
current `rcc=success` — is assumed baseline throughout, not an optimization: it
is already how the §3.2 B plan step enumerates work.)

### 4.5 Restart, repeated, and concurrent runs

The build primitive is **idempotent and resumable** because progress is durable
*per commit*, not per run:

- **Unit of progress = the per-SHA `rcc` commit-status**, set the moment each
  commit finishes (§3.2 B). It is a pure function of the deterministic build,
  written last-write-wins with the same value on re-run; the `rcc`-branch logs
  are reconstructable from ground truth by the idempotent reconciler.
- **Work selection** is always "commits between `*-green` and `*-dev` lacking
  `rcc=success`", so any run computes its own to-do list from current ground
  truth — no run depends on another's in-memory state.

**Restart (timeout / cancellation).** A shard that dies mid-slice has already
published statuses for the commits it finished; the in-progress commit has no
final status and the rest never started. The next run re-enumerates
missing-status commits and resumes. Correctness is unaffected; the only cost is
that the resumed slice loses its in-job incremental-make state and pays one fresh
cold build. No checkpointing is needed beyond the commit-status.

**Repeated runs (cron + manual, or back-to-back).** Only-missing-status
filtering makes a second run mostly a no-op — it skips already-decided commits.
Re-checking a decided commit is allowed (deterministic ⇒ same result); an
explicit `force` input can re-run a range to refresh stale logs.

**Concurrent runs.**
- *Two build runs overlapping* re-enumerate the same commits and duplicate work —
  harmless (idempotent status writes) but wasteful, and doubling 256 runners on a
  5 000-commit run is antisocial. Guard with a **`concurrency` group per branch**,
  `cancel-in-progress: false` so a queued run waits rather than killing a long
  bulk build.
- *Build concurrent with vendor / repair* (which force-push the branch): the
  build targets **explicit SHAs**, so a mid-flight rewrite cannot corrupt it — it
  finishes the old SHAs and attaches their statuses (now-unreachable commits are
  simply ignored by promotion), while the new post-rewrite SHAs lack status and
  are picked up next run. To avoid wasting a run on orphaned SHAs, put the daily
  vendor, repair, and bulk build for a line in a **shared per-line concurrency
  group**. The cheap per-commit `rcc` runs need no coordination (they self-heal).
- *Concurrent writes to the `rcc` branch* are already avoided by the single
  `if: always()` fan-in writer + idempotent reconciler (§3.2 B), not per-leg
  pushes.

Net: **nothing requires a lock for correctness** — idempotent, ground-truth-derived
state makes restarts and repeats safe by construction; the concurrency groups
exist only to avoid *wasted* compute.

> Implementation choices deferred to §8: shard-count policy, whether the bulk
> smoke build drops LTO and `-g0`, and the exact concurrency-group scoping
> between vendor / repair / build.

---

## 5. Modularity & invocation matrix

| Primitive | Claude (tight loop) | Scheduled (cron) | API / chained GHA |
|---|---|---|---|
| A Vendor | dispatch + wait | hourly (as today) | `workflow_call` from orchestrator |
| B Build | dispatch range + wait, read `rcc` branch | cron (replaces each + harvest) | `workflow_call` after vendor; `repository_dispatch` |
| C Promote | dispatch + read tip | cron (frequent, cheap) | `workflow_call` after build |
| D Repair | Claude does the work | n/a (needs Claude) | triggered by a "frontier red" signal (status / issue / `repository_dispatch`) |
| E Review | Claude reviews residuals, advances `*-reviewed` on approval | cron extracts + opens a digest | `workflow_call` after promotion; `repository_dispatch` |

Each primitive reads its inputs from ground truth (git refs + `rcc` branch) and
writes only its own outputs, so any subset can run in any order without a shared
orchestrator. A "tight loop" is just Claude calling A→B→C→(D)→B… ; a
"hands-off" mode is the same primitives wired by GHA triggers, with D raised to
Claude only when a red frontier is detected.

---

## 6. Migration / transition (hybrid)

Decision: **hybrid** — stand up the new model without breaking the existing
`broken-<sha>-dev` skills during transition.

- **Phase 0 — additive plumbing.** Add `rcc-matrix.yaml`, `promote-green.yaml`,
  `scripts/promote-green.sh`, and create `*-green` branches at the current
  `*-dev-base` tips. Run the new build path **in parallel** with the existing
  `each`/`rcc-logs` path; verify markers are byte-identical. r-universe stays on
  `*-dev` for now.
- **Phase 1 — cut over reads.** Point the matrix build at the orphan-branch
  push, confirm `advance-green-dev.md` and `rcc-smoke-fix.md` still read correct
  status. Repoint r-universe `.dev` packages to `*-green` (one line at a time,
  starting with the least critical, e.g. v1.4).
- **Phase 2 — cut over repair.** Switch the repair primitive to in-place
  amend/squash on `*-dev`. Keep `broken-<sha>-dev` + `advance-green-dev`
  available as a fallback until in-place repair has handled several real breaks.
- **Phase 3 — retire the async path.** Remove fire-and-forget dispatch and the
  4×/day harvest once the matrix path is authoritative. Fold the surviving
  repair logic into a single updated skill; archive `advance-green-dev.md`
  (catch-up becomes automatic promotion) and the fork-specific parts of
  `rcc-smoke-fix.md`.

Roll back at any phase by reverting r-universe to `*-dev` and re-enabling the
async workflows; the branch model and markers are unchanged, so no data is lost.

---

## 7. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Concurrent writers clobber the `rcc` branch | no per-leg pushes: legs upload artifacts; a single `if: always()` fan-in writes once (§3.2 B) |
| Fan-in skipped on full workflow cancellation | idempotent scheduled/on-demand reconciler (`rcc-logs.sh`) is the backstop; `rcc`-state is a pure function of ground truth (§3.2 B) |
| Bulk run hits the 6 h job timeout | a shard does ≤~20 commits (1 cold + ~19 incremental); restart resumes from per-commit status — no checkpoint needed (§4.2, §4.5) |
| Fine-grained sharding explodes compute (cold floor) | bound shards to ≤~20 commits balanced by predicted cost; one cold build amortized over ~20 (§4.2–4.3) |
| Per-commit floor dominated by LTO link | drop LTO (and `-g`/`-g0` in the bulk path) for the smoke build; keep them on the shipped artifact (§4.4) |
| Concurrent / repeated build runs waste compute or race | per-branch `concurrency` group (`cancel-in-progress: false`); shared per-line group across vendor/repair/build; correctness needs no lock — state is idempotent and ground-truth-derived (§4.5) |
| Matrix > 256 jobs | cost-balanced shards + multi-run continuation (§4.3) |
| In-place force-push on `*-dev` races with hourly vendor | single concurrency group across A/D per line; vendor guard refuses while a repair is open |
| r-universe build of `*-green` still fails despite green `rcc` | `rcc` smoke test must be a faithful subset of the r-universe build env; add an r-universe-parity check to the smoke job before cut-over |
| Promotion advances over a *transiently* green commit | ruled out by construction: promotion only fast-forwards the **contiguous** green prefix and stops at the first red (§3.2 C). A transiently-green commit lies *beyond* a red one, so it is unreachable — promotion can never cross the frontier to reach it |
| Bound (≤25) too tight/loose | make it a workflow input / repo variable; default 25 |
| Folding a fix into a vendor commit hides the R-side tweak from review | path-filtered diff (primitive E) isolates everything outside the vendored path set; `Glue-tweak:` trailer indexes candidates |
| Undeclared glue tweak folded *outside* the vendored tree | confinement guard: assert a vendor commit's diff outside the mechanical path set is empty (else it must be an intentional, trailer-tagged tweak) — cheap path-filter check |
| A stray edit slips *into* a vendored path (`src/duckdb/` by hand) | path filter can't see this (it excludes `src/duckdb/`); detect by **re-vendoring** and diffing the vendored paths — any non-`patch/` difference is a stray edit. Run as a periodic determinism guard on the green tip (amortized), or continuously via an optional `*-vendor` branch (§3.5) |

---

## 8. Open questions (for implementation)

1. **Caching — settled:** the normal per-commit path keeps the existing CI caches
   (`duckdb.tar` + `ccache-action`); the **bulk path is cache-free** (the bespoke
   caches are GHA-action-bound and don't fit a multi-commit job), relying on
   incremental `make` within a shard (§4.2). No new cache backend needed.
2. **Shard policy:** cost-balanced by predicted reach into ≤~20-commit shards
   (§4.2–4.3); open is the concurrency cap (how many runners is "good-neighbour"
   for a big run) and whether the bulk smoke build drops LTO/`-g0` (§4.4).
3. **`*-green` bootstrap point:** create from current `*-dev-base`, or from the
   latest already-green `*-dev` commit per line?
4. **r-universe parity:** how closely must the `rcc` smoke job mirror the
   r-universe build matrix to guarantee `*-green` is installable there?
5. **Repair trigger in hands-off mode:** GitHub issue, a dedicated commit
   status, or `repository_dispatch` to wake a Claude session?
6. **Bound semantics:** is the ≤25 measured in commits, or should tagged
   upstream releases always be allowed through regardless of distance?
7. **Review marker & cadence:** one `*-reviewed` marker per line vs. a single
   global ledger; review per-promotion, daily, or on demand. May the
   `*-reviewed` marker lag arbitrarily behind `*-green`, or should a maximum
   review backlog raise an alert?
8. **Tweak-trailer schema:** exact `Glue-tweak:` field set and whether to also
   materialise the path-filtered delta into a tracked ledger (e.g.
   `review/tweaks/<sha>.patch`) for offline/diff-tool review, or compute it on
   demand only. Also: is the `Glue-tweak:` trailer worth requiring at all, given
   the path filter already isolates the delta without it?
9. **Derived `*-vendor` branch (§3.5):** materialise a pure-vendoring branch for
   continuous cheap stray-edit detection + review baseline, or rely on a
   periodic re-vendor determinism guard on the green tip? Trade-off is
   integrity-continuity vs. the upkeep of a second lockstep branch.

---

## 9. Concrete first deliverables (Phase 0)

1. `scripts/promote-green.sh` — deterministic green fast-forward (pure git +
   `rcc` status reads from the orphan branch).
2. `.github/workflows/promote-green.yaml` — wraps (1); `schedule` +
   `workflow_call` + `workflow_dispatch`.
3. `.github/workflows/rcc-matrix.yaml` — plan (cost-balanced ≤20-commit shards
   via the reverse-include estimator) + cache-free matrix build (each leg builds
   its slice sequentially with incremental `make`, `DUCKDB_R_USE_SYSTEM_LIB` off,
   per-commit status + log artifact) + `if: always()` fan-in running `rcc-logs.sh`
   scoped to the run; per-branch + shared per-line `concurrency` groups (§4.5).
4. Vendor guard: add the ≤25-ahead-of-frontier check to `vendor-one.sh` /
   `vendor.yaml`.
5. Create `*-green` branches; document the model in `BRANCHES.md` and
   `scripts/VENDORING.md`.
6. Parallel-run validation harness comparing new vs old markers byte-for-byte.
7. `scripts/glue-tweaks.sh` — path-filtered tweak extractor (a thin
   `git log -p`/`git diff` wrapper excluding the vendored path set), plus a CI
   guard that vendor commits stay confined to the vendored paths. Pairs with
   `glue-review.yaml` and the `*-reviewed` marker for the agentic glue-tweak
   audit (primitive E).

Items (1)–(2) are the smallest useful slice and have no dependency on the matrix
work, so they can land first and be exercised against today's `rcc` markers.

---

## Appendix A — Empirical validation

Moved to [`experiments/2026-03-vendor-build-cost/`](/experiments/2026-03-vendor-build-cost/README.md),
which the cost model cites:
churn per vendor commit, ccache behaviour on adjacent commits,
and the object-archive size.
