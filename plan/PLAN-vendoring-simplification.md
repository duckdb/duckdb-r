# PLAN — Vendoring: a smaller kernel, tooling from `main`, and a docs tree

**Open.** How vendoring works today is
[`operations/vendoring/`](/handbook/operations/vendoring/README.md)'s,
and the documentation tree's own rules are
[`meta/handbook/`](/handbook/meta/handbook/README.md)'s;
this file is the proposal, and where the two disagree the leaf is right.

Status: **in progress** (2026-07-30, branch `claude/vendoring-tooling-design-3swawc`;
Phase 1 landed as #87, the README root as #88 — see §9;
revised after a clean-context review of this document against `origin/main`).
Inputs: `BRANCHES.md`, `scripts/VENDORING.md`, `scripts/EACH.md`,
`scripts/VENDORING-LOOP.md` (historical), the four skills in `.claude/skills/`,
the loop scripts (`series-*.sh`, `each-*`, `rcc-*`, `vendor*`),
`.github/workflows/each.yaml`, the remote refs, and the merged-PR history.
Scope: the vendoring pipeline only —
not the release FSM (`RELEASE.md`) and not the package itself.

The system works: the series loop vendored ~1000 commits through the `main`
rewind, every published commit is green, and forward/cutover moves are atomic.
What this plan addresses is that the *machinery around* the loop has grown
faster than the loop itself, and the growth is where the brittleness lives.
It also folds in two new requirements:
the same machinery will be **ported to `rigraph`** (vendoring the igraph C
core, same goals, currently on the legacy `vendor.yaml` model),
and the documentation will be **rebuilt as a tree**.

---

## 1. The three properties, and what they actually require

1. **Every vendored commit is green.**
   Requires: a per-commit verdict, a monotone trusted frontier (`-green`),
   and repairs folded into the commit that needs them.
2. **Vendoring can be rebased and rerooted.**
   Requires: the vendor chain to be *replayable* —
   one upstream commit per vendor commit, machine-readable subject,
   adaptations folded in — and a way to rebuild a series beside itself
   and swap atomically (forward + cutover).
   Verdicts are keyed by SHA, so any replay forfeits them;
   re-verification is the accepted price of a rebase, not a defect.
3. **Automated through Claude routines and GHA as much as possible.**
   Requires: judgement (repair, review, snapshot acceptance) in the routine;
   everything deterministic (build, verdicts, ref motion) in scripts and CI;
   and — this is the part that was underweighted so far —
   a **defined, automated path from `main` to every series** for the
   deterministic part, because a tooling fix that has to be hand-carried
   into each branch becomes a firing that runs old code.

## 2. Where the complexity actually is

An inventory of the moving parts, as of today
(counts verified against `origin/main` and `git ls-remote`):

| Layer | Parts |
|---|---|
| Refs per series | 4 (`-build`, `-dev`, `-green`, `-build-base`) + `retry-<S>-dev`, + `-fwd-*` while forwarding. Live series today: `v1.5-variegata`, `main-fwd`, `v1.4-andium-fwd` — `main` itself has no `-build` pair pending cutover. Beside them: the legacy `*-dev-base` trio (release-FSM state), and stray refs — `main-dev-old`, `main-fwd-build-rich`, `main-rewind-dev-*`, a `retry-*-green` half from the pre-retry-ledger design — that §6's fork replacement retires |
| Verdict stores | **2**: commit statuses (what selection reads) and the `rcc` branch records (what the loop reads) |
| Layouts on `rcc` | 2 current (`runs2.d/<xx>/<sha>.ndjson` parts, the `runs2.ndjson` aggregate) + `logs2/`, plus the legacy `runs.json` / `runs.ndjson` / `logs/` already marked "scheduled for removal" |
| Writers to `rcc` | 4 automated (leg publish, run fan-in, 30-min backstop, aggregate merge) + 1 manual (consolidate) |

*Since:* D1 and D2 have landed. Selection reads the record store, and the store is
one layout on a new branch — `runs2.d/<xx>/<sha>.ndjson` and
`logs2.d/<xx>/<sha>.log` on `rcc2`, written by three producers through one
publisher, with `rcc` left behind whole. See
[`operations/ci/per-commit/store/`](/handbook/operations/ci/per-commit/store/README.md).
| Scripts | 26 shell/python executables + 3 data/jq files serve the loop |
| Skills | 4 (`series-loop`, `series-forward`, `series-rebase`, `series-open`) |
| Workflows | `each.yaml`, `rcc-logs.yaml`, `rcc-consolidate.yaml` — the legacy dispatch path, which also spanned `cancel-rcc-dispatch.yaml`, is retired (D4). `R-CMD-check.yaml` (whose workflow *name* is `rcc`) and `R-CMD-check-status.yaml` stay: the ordinary push/PR check and the commit status branch protection reads, both core-set from `cynkra/cynkratemplate` |

Findings, in order of how much brittleness they explain —
diagnosis kept as written at review time,
with a status line each as the work lands:

- **F1 — Two verdict stores, reconciled instead of unified.**
  Selection reads commit statuses
  (`each-plan.sh` via GraphQL, `each-shard.sh`'s resume check via REST);
  the loop reads `rcc` records;
  and the 30-minute backstop (`rcc-logs.sh`) *derives records from
  statuses*, so the record store's own repair path runs through the
  other store. They agree *eventually*, through five writers, a
  newest-verdict-wins rule with run-id comparisons, a
  `PENDING_TTL_HOURS` heuristic for wedged statuses, and a 12-hour
  "presume lost" rule in the skill.
  Every one of those mechanisms exists to bridge the two stores;
  none would exist with one store.
  *Status:* open — Phase 2 is the cut.
- **F2 — The aggregate is a convenience with three scripts attached.**
  `runs2.ndjson` buys "read everything in one `git show`" and costs
  `rcc-merge.sh`, the stale-line replacement rule, half of
  `rcc-consolidate.sh`, and the two-layout fallback in every reader.
  *Status:* landed — the aggregate is gone, and so are `rcc-merge.sh`,
  `rcc-push.sh` and `rcc-part-push.sh`; one publisher
  (`rcc-publish.sh`) writes the store, and `rcc-cutover.sh` builds the
  new branch rather than sweeping the old one in place.
  On the many-small-files worry that motivated the aggregate:
  the branch is built to be used **without a checkout**.
  The loop reads records via `git show`
  (`series-check.sh` says so in its header),
  and a leg publishes through a blobless, checkout-less plumbing clone
  (`rcc-part-push.sh` measures ~2 MB moved against a branch it puts at
  ~218 MB; `series-check.sh`'s header speaks of a 1.7 GB tree —
  the two recorded figures disagree, and the argument survives either:
  the bulk is harvested logs at ~1 MB each, under 30-day retention,
  while a record part is ~2 KB under a 256-way fan-out
  that keeps every tree object small).
  The full checkouts that remain are the 30-minute backstop
  (`rcc-logs.yaml` adds a `runs/` worktree) and manual consolidation.
  File count is not the constraint;
  if the backstop's checkout ever grows heavy,
  it moves to the legs' blobless pattern, not back to the aggregate.
- **F3 — The lost "running marker" was a proxy, and the replacement is
  implicit.** The old per-commit dispatch never re-checked a commit because
  `pending` was set at dispatch time. That guarantee was weaker than it
  looked — a dead runner left `pending` wedged forever, which is why the TTL
  heuristic exists at all. What actually prevents double work today is the
  per-branch concurrency group (queued, never cancelled) plus
  work-selection as a pure function of durable verdicts. That is the right
  design, but it is nowhere *stated* as the design, so changes keep being
  evaluated against the old marker intuition.
  *Status:* stated — §3.1's kernel and D5 are that statement
  (`each.yaml` and `EACH.md` already carry the pieces; D5 is the
  one-place statement, not a new mechanism).
- **F4 — Per-branch workflow copies are a standing migration tax** (pain
  point 1). `each.yaml` and its scripts run from the branch being checked,
  so every tooling fix must be forward-ported into every `-dev` branch
  before it takes effect there — and a series opened last month runs last
  month's tooling. The skills have the same problem in miniature: they say
  `scripts/vendor-one.sh`, which resolves to the *series worktree's* copy.
  *Status:* solved for `-dev` by the port stage (#87);
  still live for stage 1, which runs `vendor-one.sh` from the
  `-build` worktree that ports never touch —
  Phase 1a closes it by having the routine invoke the `main`
  checkout's copy there (script execution by the routine,
  not a CI cross-branch reference).
  What remains is by design:
  workflows read from the branch they check,
  and each ported commit costs one verdict.
- **F5 — The tooling fix loop is long** (pain point 2): the routine finds a
  bug, opens a PR, waits for review and merge, then the fix still has to
  reach the `-dev` branches (F4). The cadence is real but young:
  the loop itself exists since 2026-07-28, and in its first eight days
  ~29 loop-tooling commits landed on `main`
  (38 touching the tooling paths overall).
  They concentrate in two places: the F1/F2 reconciliation machinery
  (newest-writer verdicts, retry semantics — latest: the
  rerun-in-flight disambiguation via the record's `head_branch`, #74),
  and the buffer-equivalence rule —
  six of the last ten merged loop fixes were anchor fixes (#79–#85),
  until #85 consolidated the anchor into one helper.
  *Status:* reframed — see §5.
  The loop runs close to perfectly against a deliberately high bar;
  the glitches left are within the routine's judgement budget,
  and the distribution half of the pain went with F4.
- **F6 — `-build-base` is a display ref, and should be said to be.**
  Nothing *decides* from its value: the consumption anchor is recomputed
  from `-dev`'s newest vendor subject every time (the anchor-fix cluster
  hardened exactly that rule; #85 consolidated it into the bounded,
  20-deep `vendored_sha()` helper). The tooling does still *handle* the
  ref — `series-advance.sh` requires it and guards its own writes with a
  fast-forward check, `series-cutover.sh` swaps it atomically, the
  skills create it on day one — so "no script reads it back" was too
  strong: it is written and guarded by the loop, and swapped at cutover
  (by hand — §3.1 rule 7), but it is an input to nothing.
  Its consumer is the human: it is the ref that makes
  "how much is vendored but not yet verified" a clean linear range,
  `-build-base..-build`, renderable as a compare URL and as a badge
  (§3.4). The gap was that no document stated that contract,
  so it kept being re-examined as if it were coordination state.
  *Status:* moot — the badges are the consumption:
  the README's `Flavors` table renders *buffered* from exactly this ref
  (#88, since fleshed out; upkeep documented in `series-open.md`),
  and the contract is stated here (D3, §3.4).
- **F7 — The docs describe the system three times.** `BRANCHES.md`
  §Vendoring, `scripts/VENDORING.md`, and the skills each re-tell the loop;
  `VENDORING-LOOP.md` tells a superseded version of it at 865 lines;
  `BRANCHES.md` §Tooling carries a fourth script inventory that misses
  ten of the loop's current scripts.
  Every behaviour change needs three edits, and gets an average of two.
  *Status:* this is the docs tree — §8, Phase 4;
  the README root landed (#88).

What is **not** a brittleness source, and stays:
the sharded matrix with its measured cost model, fold-in-place repair,
the forward/cutover mechanism, and the subject-encoded upstream SHA.
The buffer/`-dev` split also stays — its *blast-radius bound* is earned
(§3.2) — but honestly: its equivalence rule was the second fix magnet
(F5), and what makes it safe to keep is #85's consolidation of that rule
into one loud, bounded helper, not an absence of incidents.

## 3. The target: a kernel and its earned extensions

The simplest design that satisfies §1 is small.
Everything else must justify itself as a measured optimisation
or carry a retirement date.

### 3.1 The kernel

Per series `<S>`, **three refs**:

| ref | motion | meaning |
|---|---|---|
| `<S>-build` | append; force-push only to mirror a fold | every upstream first-parent commit, glue compiling, no CI — the buffer |
| `<S>-dev` | extend ≤ N from the buffer; force-push to fold repairs | the proposed chain; what CI judges |
| `<S>-green` | fast-forward only | the trusted frontier; what consumers build |

(`<S>-build-base` is not part of the kernel's *decisions* —
it is a display ref, §3.4 — though today's scripts require and
maintain it, per F6.)

**One verdict store**: one small file per commit
(`runs2.d/<xx>/<sha>.ndjson` + `logs2.d/<xx>/<sha>.log` on branch `rcc2`),
written by the leg that decided the commit — with the run fan-in and the
scheduled backstop recovering what a dead leg could not publish —
and replaced only by an explicit retry.
Git-native, batch-readable in one blobless fetch, reachable from a
Claude web session without API access.
Commit statuses become a **write-only display surface**;
today they are still selection's input, which is what D1 changes.

**One brain**: the series loop routine — the only writer of series refs,
the only party that repairs, retries, and extends.
**One judge**: CI as a pure function `judge(sha) → verdict + log`,
idempotent, restartable, self-selecting its work as
"commits in `green..tip` that are undecided"
(the selection key today is the status; D1 makes it the record).

**Seven rules** — deliberately restating `series-loop.md`'s invariants
as one checklist; this plan is analysis, not a routing node:

1. One upstream first-parent commit per vendor commit;
   the subject carries `<upstream>@<sha>` and is machine-readable state.
2. Repairs fold into the commit that needs them; nothing stacks on top.
3. `-green` fast-forwards over contiguous green only; it never rewinds
   (the sanctioned exception: cutover swaps a whole series atomically).
4. `-dev` extends only when everything in flight is green, by ≤ 100 —
   the cap bounds what a repair can invalidate.
5. A verdict is written once; re-judging is explicit
   (the retry ledger, one ref per series) and replaces the record.
6. A series is discovered from its refs, never configured.
7. Rebasing or rerooting replays the vendor chain onto a fresh seed
   beside the serving series and re-verifies from scratch;
   cutover is one atomic swap, and the one move the loop only suggests —
   a human runs it, from a terminal.

### 3.2 Extensions that earn their keep

- **The buffer (`-build`).** During bulk walks (reroot, rewind, upstream
  sprints) it holds vendored-but-unconsumed history so a repair near the
  front re-mints ≤ 100 commits instead of the whole backlog, and it
  preserves glue adaptations made at vendor time.
  Cost: the vendored-SHA equivalence rule and fold mirroring —
  the loop's second fix magnet until #85 centralised the rule (F5).
  Verdict: keep, with the rule staying in exactly one helper.
- **The sharded matrix and cost model** (`each.yaml`, `each-plan`,
  `each-cost`, `each-partition`). Measured 2.6–3.6× compute saving and
  hours-vs-days wall clock; constants fitted to real legs. Keep.
- **The retry ledger** (`retry-<S>-dev`). One ref that re-judges one SHA
  without rewriting anything, and remembers that it did. Keep.
  (A stray `retry-*-green` half from the pre-ledger design survives on
  the remote as litter — §6 retires it.)
- **Leg-direct publishing** (`rcc-publish.sh`, from the leg). Verdict
  latency in seconds instead of end-of-run; measured cheap. Keep.
- **The run fan-in** (`each-harvest.sh`). Not deletable, contrary to an
  earlier revision of this plan: it holds the only path to a
  **per-commit log** for a leg that died before publishing —
  the backstop can reconstruct records, but only a *run*-level log,
  which `series-check.sh`'s classifier can misread
  (`each.yaml` and `each-harvest.sh` both record
  this). Keep; D2 only removes its aggregate work.

### 3.3 What goes

| # | Cut | Replaces / removes |
|---|---|---|
| D1 | Selection reads the **record store**, not statuses — in `each-plan.sh`, `each-shard.sh`'s resume check, and the backstop. A commit without a record is undecided and gets replanned; nothing reconstructs records *from* statuses any more | GraphQL status scan, REST resume reads, `PENDING_TTL_HOURS`, the wedged-`pending` state, and the backstop's status-derived record repair (rebuild, don't reconstruct) |
| D2 | Drop `runs2.ndjson` outright — no replacement. Readers go parts-only, and `rcc-merge.sh` retires with the file | the aggregate, `rcc-merge.sh`, the stale-line rule, the two-layout fallback in every reader, and half of `rcc-consolidate.sh` (what remains: the retention GC and the squash) |
| D3 | State `-build-base`'s contract: maintained and self-guarded by the loop, an input to no decision, consumed by humans (compare URLs and badges, §3.4) | the recurring temptation to treat it as coordination state — or to drop it and lose the only clean "buffered" range |
| D4 | Retire the legacy dispatch path whole: `vendor-gate.sh`, `each-rcc.sh` + `each.yaml`'s dispatch mode, `cancel-rcc-dispatch.yaml`, ~~and `R-CMD-check-status.yaml`'s rcc role~~ (that last one was wrong — see the status note below). `R-CMD-check.yaml` itself stays — it is also the ordinary push/PR check — it only stops being dispatched per commit | four legacy surfaces that still have to be reasoned about on every change |
| D5 | State the concurrency design in one place: per-series group + durable idempotent verdicts; **no pending markers, by design** | the recurring "did we lose the running marker" doubt (F3). The pieces exist in `each.yaml` and `EACH.md`; the one-place statement is what is missing |

*Status of D4:* landed, minus one item this document had wrong.
`vendor-gate.sh`, `each-rcc.sh`, `each.yaml`'s dispatch mode and
`cancel-rcc-dispatch.yaml` are gone.
`R-CMD-check-status.yaml` **stays**, and so does the `rcc-smoke-sha` artifact
that feeds it: the commit status it writes is what **branch protection** reads,
and both are core-set content from `cynkra/cynkratemplate` — the status file is
byte-identical to the template's — so editing them would fork this repository
from the template to no end. They were never part of the dispatch path; what
went is the per-commit *dispatcher*, not the check it dispatched.
`R-CMD-check.yaml` likewise stays, as the ordinary push/PR check; what it
stopped being is dispatched per commit. The one thing the retirement costs is
the escape hatch: rollback is now a revert rather than an `EACH_RCC_MODE` flip.
That is the trade — an escape hatch nobody reaches for is not insurance, it is a
second path everything else has to stay correct against.

With D1/D2 the writers simplify to three, all parts-only:
the leg publishes its own record and log;
the fan-in recovers what a dead leg could not publish (§3.2 — it stays);
consolidation stays manual.
No writer touches an aggregate, because there is none.
The backstop stops writing altogether:
its record-repair duty inverts into *replanning* —
a recordless commit is undecided, and the planner rebuilds it —
and its schedule survives only as the nudge that dispatches
`each.yaml` when undecided commits sit idle,
which also closes `EACH.md`'s known
"nothing schedules `each-rcc` after a lost leg" gap.
Dropping the aggregate supersedes `EACH.md`'s
"extension, not migration" reasoning openly rather than quietly —
and answers the argument recorded in `rcc-consolidate.sh`
("one file makes a range read a single fetch"):
after the sweep, a range read is N 2-KB `git show`s,
which is how the loop reads the range today anyway;
the single-fetch convenience has no consumer left.
Order matters only once: sweep, then readers, then the file.

### 3.4 Human-facing lag: compare URLs and badges

Two quantities tell a human how far a series is,
and both are clean linear counts by construction:
**in flight** (`<S>-green..<S>-dev`; green is always an ancestor of dev)
and **buffered** (`<S>-build-base..<S>-build`; likewise).
`-build-base` exists for the second:
`-green` lives on `-dev`'s lineage,
so `-green...-build` crosses lineages after any repair
and both sides of that comparison go nonzero;
the display ref pins the same point on `-build`'s own line,
where the count stays linear.

The rendering is owned elsewhere, once each:
the live table is the README's `Flavors` section
(#88, since fleshed out — per dev flavor an *ahead* badge against the
release branch plus these two, version badges for CRAN/LTS rows),
its upkeep including the mirror-freshness constraint is
`series-open.md` §"Patching the README",
and the endpoint mechanics are `scripts/VENDORING.md` §Monitoring.
True upstream lag ("how far behind `duckdb/duckdb` itself") cannot be a
badge — the comparison would cross repositories — and stays with the
routine's reports.

## 4. Tooling distribution: authored on `main`, ported by the loop

`main` stays the source of truth for the tooling —
workflows, `scripts/`, and skills are authored and reviewed there —
and CI keeps its GHA-native shape:
a workflow runs from the branch it checks.
The alternative — a scheduled entry point on the default branch
checking out other branches' trees — was considered and rejected:
the vendoring tooling should not depend on brittle cross-branch
references, and a driver that judges a tree with another branch's
scripts is exactly that.

So distribution becomes a **stage of the series loop**
(Phase 1 — landed as #87),
inclusive and with an identity goal:
after each firing,
`.github/`, `scripts/`, and `.claude/` on `<S>-dev`
are byte-identical to `main`'s —
a tooling change never waits for a forward.
A deterministic helper, `scripts/series-port.sh`,
lists every commit `main` has that the series lacks
(patch-id plus trailer dedupe keep reruns exact),
classified by what it touches,
cherry-picks them all by default, whole commits only —
a mixed or package-side commit is a forward-port like any other (S4),
judged by CI like every `-dev` commit,
and a wholesale pick is dropped by patch-id at the next rebase
where a split pick would only replay —
and closes whatever tooling delta the picks cannot explain
with one sync commit taking `main`'s tooling tree verbatim
(empty, and not created, in steady state).
The routine keeps the judgement:
conflicts are resolved toward `main`'s intent in the kept worktree,
and a commit that cannot work against the series' engine
is excluded by applying an explicit subset
and fixed on `main` instead.

**The vendor-strand exclusion, and an unresolved contradiction.**
Vendor-strand commits are listed and never auto-picked —
`main`'s engine is not this series' engine.
The landed class excludes by **path**
(`src/duckdb/`, the generated version files) as well as by subject,
and the landed rationale (in `series-port.sh`'s header and
`series-loop.md` stage 4) asserts that the scans *rely on* every
`src/duckdb`-touching `-dev` commit being a vendor commit.
The principle that landed on `main` in the same day's batch (#85)
asserts the opposite:
*the subject is what decides, never the path* —
the patch stack is applied to the vendored tree in place,
so CRAN and warning fixes land under `src/duckdb/` vendoring nothing
(the skill counts 89 such commits on `main`; recount at
implementation), and `vendored_sha()` was rebuilt to look past them,
20 deep, loudly on stderr when the window is exhausted.
The two claims cannot both stand, and the path-based class makes
exactly those patch fixes wait for a forward —
the one thing the port exists to end.
**Phase 1a resolves it in the subject's favour, in safe order:**
first make the two remaining subject scanners bounded-and-loud like
`vendored_sha()` — `vendor-one.sh` scans 10 deep and `vendor.sh`
3 deep, both today returning *silently empty* when exhausted, which
turns into an unbounded vendoring range downstream —
then relax `classify()` to subject-decided
(`vendor:` prefix, `duckdb/duckdb@` in the subject),
and rewrite the landed rationale in both places to match.
`vendor-one.sh` runs against `-build`, which ports never touch,
so the hardening there is defence in depth, not a blocker.
Port volume needs no bound under either class —
the boundary is content, and the content boundary is the subject.

Ported commits are **transient by construction**:

- a forward replays only `vendor:` subjects onto a seed that already
  carries the tooling, so the port ends there (`series-forward.md`);
- a rebase drops them by patch-id once `main` contains them,
  and a sync commit whose delta `main` absorbed rebases to empty
  (`series-rebase.md`);
- they vendor nothing, so the consumption anchor is untouched —
  the loop already reads the anchor from the newest *vendor* subject
  precisely because `-dev` carries such commits (`series-advance.sh`).

Every ported commit is still judged like any other `-dev` commit (C1):
a green port proves the tooling change did not break the series, and a
red one is caught before it can poison a batch.
That is also the cost — one verdict per ported commit per series —
which is why the helper ports batches, not drips.

Stage 1 is the port's blind spot (F4):
`vendor-one.sh` runs in the `-build` worktree,
whose tooling only refreshes at a forward.
Phase 1a closes it the routine-side way —
stage 1 invokes the `main` checkout's copy against the buffer worktree;
that is a script the routine runs, not a CI cross-branch reference.

The known gap that nothing schedules `each.yaml` after a lost leg
is covered by the routine today (the 12-hour rule and the retry ledger)
and structurally by Phase 2, where the backstop's schedule becomes the
dispatcher for idle undecided commits (§3.3).

## 5. The tooling-fix loop (pain point 2)

The loop now runs close to perfectly,
and the bar it clears is deliberately high —
every vendored commit green, bisectable, automated end to end.
The glitches that remain are occasional,
and LLM judgement in the routine is the right tool for them;
the distribution half of the pain went with the port stage (F4).
What remains is review and merge, which should stay human,
kept light by habit rather than process:

- The routine opens **small, single-cause PRs**,
  each with the failing firing linked as evidence;
  a fix must never be load-bearing for the *current* firing
  (the firing works around by hand; the PR prevents the next one).
  *Status:* landed as stage 7 of `series-loop.md`,
  with the **reading** of open PRs moved up into that skill's setup,
  where it is context applied with judgement rather than a step:
  an open PR is tooling the series does not have
  (stage 4 ports what merged), so it names a workaround
  still to be paid this firing, and a cause not to re-diagnose.
  It was written here and nowhere else until then —
  the skills said nothing about PRs at all —
  so the habit depended on the routine improvising it every firing.
  A rule that lives only in the plan is a rule the routine never reads:
  this document is analysis, and the playbook is what executes.
- The deeper lever is §3: the fixes to date cluster in the F1/F2
  reconciliation machinery and in the buffer-equivalence rule —
  the first is what Phase 2 deletes,
  the second is now one helper (#85).
  Deleted code needs no fixes, no review, and no distribution.
- The health signal: firings that required a workaround, per month —
  near zero today; the cuts exist to keep it there as the system ages.

## 6. A fresh fork replaces the standalone repo

`krlmlr/duckdb-r` is a standalone copy, not a GitHub fork object
(the docs call it "the fork" colloquially);
the intent is to replace it with a fresh, genuine fork —
which also retires the accumulated ref litter as a side effect
(`broken-*-dev`, stale `retry-*` including the `retry-*-green` half,
`main-rewind-dev*`, `main-dev-old`, `main-fwd-build-rich`),
so no separate hygiene pass is needed.

**Actions budget: confirmed unchanged.**
Usage and concurrency attach to the account that owns the repository
where the workflow runs, not to a fork's upstream:
a public fork under `krlmlr` has free standard-runner minutes and draws
on the same per-account concurrency pool
(shared across all of the account's repos, sized by its plan)
that the standalone repo draws on today.
Nothing about vendoring throughput changes.

Fork-specific switches to flip at creation:

- **Workflows in a fresh fork are disabled until enabled once** in the
  fork's Actions tab, and **scheduled workflows are disabled by default
  in forks of public repositories** — re-enable all six explicitly:
  `sync.yaml` (hourly), `rcc-logs.yaml` (half-hourly),
  `fledge.yaml`, `R-CMD-check.yaml`, `R-CMD-check-dev.yaml`,
  `lock.yaml` (daily).
  The unrelated 60-day inactivity auto-disable for schedules in public
  repositories is moot here: the loop pushes daily.
- Recreate what a fork does not carry: repository variables
  (`EACH_RCC_*`), any secrets, and the non-default refs —
  the series refs, the `rcc` branch, and the snapshot branches are
  pushed fresh or migrated (see the open question on migration depth).
- **Mirroring comes from the fork itself, not from `sync.yaml`.**
  The Flavors badges compare within `krlmlr/duckdb-r`
  (their *ahead* base names the release branches),
  and `sync.yaml` fast-forwards only `main`,
  so today's `duckdb.1.4.dev` *ahead* badge compares against a
  `v1.4-andium` mirror nothing refreshes —
  a **live defect**, counting commits that have already shipped.
  An earlier revision of this plan proposed extending `sync.yaml`
  to every release line and carrying the extension into the fork;
  that was written, reviewed and **not merged**
  (the branch is in the history if the argument is ever needed again).
  The decision instead: a *genuine* fork keeps its branches current
  through the **Pull app**, which is what a fork is for.
  `sync.yaml` exists because the standalone copy is not a fork
  and has no upstream to be pulled from;
  replacing the copy with a fork replaces the need,
  and one hand-written mirroring job is exactly the kind of machinery
  §3 says has to justify itself against a mechanism that already exists.
  Until the move, the mirrors are refreshed by hand —
  which is what `series-open.md` says today,
  and what it goes on saying rather than promising automation
  that is not there yet.

Keeping the repository name keeps r-universe and every
`krlmlr/duckdb-r` URL — badges, compare links — valid.

## 7. Portability: `rigraph` / igraph

`rigraph` today is the *pre-series-loop* model: `vendor.yaml`
(matrix over one `main-dev`), `each-rcc.sh`, `vendor-one.sh`, vendoring the
igraph C core from `krlmlr/igraph` with a `patch/` stack —
the same shape `duckdb-r` had a year ago, with the same goals.
The port is therefore a second consumer of the kernel, and the split falls
out cleanly:

| Kernel (repo-agnostic) | Adapter (per repo) |
|---|---|
| Series refs + rules 1–7, loop skill, `series-check/advance/cutover/forward-build/port` | upstream remote + branch map |
| `vendor-one.sh` walk, subject format `<owner>/<repo>@<sha>` | tree regeneration (`rconfigure.py` ↔ igraph's) |
| Sharded judge, record store, retry ledger | per-commit gate stages (`rcc-one.sh` contents), cost estimator (`each-cost.py` reads the unity-build include graph — igraph needs its own, or a constant weight to start) |
| Docs-tree conventions (§8) | flavor machinery (duckdb-only), fifth version component policy |

Sequencing: **do not extract yet.**
Phases 1a–3 first, inside `duckdb-r`, so the kernel is minimal before it
is shared; extract when the `rigraph` port actually starts —
a shared tooling repo whose reusable workflows are consumed `@main`
gives both repos "tooling from main" across repositories with zero
forward-porting, and a per-repo config file
(paths, upstream, gate stages, estimator hook) carries the adapter.
Generalising the subject marker from the literal `duckdb/duckdb@` to the
config value is the only kernel change the port needs early;
do it as part of the extraction, not before.

## 8. The documentation tree

Full rewrite, with this structure discipline:

- **Two roots.** `README.md` for users of the package;
  `AGENTS.md` for maintainers and coding agents.
  Every doc is reachable from a root by following child pointers.
- **Nodes route, leaves explain.** An intermediate node is at most a screen:
  one sentence of scope, then a table "to solve X, read Y".
  Detail lives in exactly one leaf (single-owner rule);
  other docs point, never paraphrase.
- **Links are conveniences, paths are the contract.**
  Cross-links may exist, but navigation must survive without them:
  every node names its children by repo path,
  and every child opens with one line saying what it is and
  which node owns the neighbouring topics.
  No orphan docs.
- **History is quarantined.** Superseded designs and one-off review
  artifacts live under `plan/`, marked historical, out of the routing tree.

Target tree — both roots route to the shared level-2 nodes,
which is also the shape the landed README already has
(#88's `Documentation` section lists them directly):

```
README.md ──┐                  users: install, use, build
AGENTS.md ──┤                  maintainers & agents: quickstart + router
            ├─ BRANCHES.md              branch model, flavors, invariants
            ├─ RELEASE.md               release FSM
            ├─ scripts/VENDORING.md     vendoring mechanics
            │    └─ scripts/EACH.md     per-commit CI design
            ├─ .claude/skills/          playbooks the routine executes
            │    series-loop.md · series-forward.md ·
            │    series-rebase.md · series-open.md
            └─ plan/README.md           designs and decisions
                 PLAN-*.md
                 └─ plan/superseded/         designs overtaken by events
                      vendoring-loop.md (← scripts/VENDORING-LOOP.md)
                      main-dev-review-2026-07.md (← scripts/main-dev-review.md)
```

History gets a directory of its own, not just a filename prefix:
the distinction the tree cares about is that a plan may still come true
and a history never will,
and a directory says that at a glance from the path alone —
which is the contract, links being the convenience.

A directory cannot route, and both roots pointed at one:
`plan/` was named as a node while nothing named its contents by path,
so every document in it was an orphan by this tree's own rule —
three of them with zero inbound references before the moves.
`plan/README.md` is the node; the roots point at the file.

Per-node target state:

| Node | Today | Target |
|---|---|---|
| `AGENTS.md` | router table at top (this PR); below it, stale content — a pointer to a `CLAUDE.md` that does not exist, "runs daily via GitHub Actions" for the routine-driven loop, `main-dev ← main` for a series that now lives as `main-fwd` | router + build/test essentials; the stale rows fixed in the Phase 4 node rewrite |
| `BRANCHES.md` | model + invariants + a re-telling of the loop + a fourth, stale script inventory (§Tooling misses ten current loop scripts) + stale "Proposed tooling" | model + invariants; vendoring section and script inventory shrink to pointers (`scripts/VENDORING.md` owns the inventory) |
| `scripts/VENDORING.md` | mechanics + another re-telling | mechanics + troubleshooting only; owns the script inventory |
| `scripts/EACH.md` | design + Q&A, current | keep; it is already the single owner of its topic |
| skills | current | procedure only; mechanics by pointer |
| `scripts/VENDORING-LOOP.md` | 865-line superseded design | move to `plan/superseded/vendoring-loop.md`; fix the 11 inbound references across 6 files |
| `scripts/main-dev-review.md` | one-off review artifact in `scripts/`, currently orphaned (zero inbound references) | move to `experiments/2026-07-main-dev-review/` |
| `plan/` | named as a node by both roots; nothing named its children | `plan/README.md` routes: scope, then one row per document, by path — and the rule that a file the table does not name is an orphan |

Migration: mechanical moves first (one PR), then one node per PR,
router kept in sync in the same PR as each move —
never a big-bang rewrite of the content itself.
The README root landed early (#88):
a Flavors section carrying the per-series badges,
and a Documentation section pointing into the tree.

**Is there a popular Claude skill for this?**
No off-the-shelf one: the marketplace and public skill collections cover
document *production* (docx/pdf/pptx) and CLAUDE.md bootstrapping
(`/init`), not maintaining a routed doc tree.
The convention this tree implements is the same **progressive disclosure**
principle Anthropic's skill-authoring guidance uses for skills themselves
(short entry point, detail behind named files).
So: encode the four rules above as a small repo-local skill
(`.claude/skills/docs-tree.md`, authored with `skill-creator`),
invoked whenever docs are touched — and port it to `rigraph` with the rest
of the kernel.

## 9. Phases

| Phase | Delivers | Risk / rollback |
|---|---|---|
| **0 (PR #86, this PR)** | this plan; router in `AGENTS.md`; badge semantics + pointers in `scripts/VENDORING.md` and `scripts/EACH.md` | none — docs only |
| **1 — landed (#87)** | the port stage: `scripts/series-port.sh` plus the amended `series-loop` / `series-forward` / `series-rebase` skills | first real `--apply` still runs supervised |
| **1a (follow-up)** | resolve the subject-vs-path contradiction (§4), in order: harden `vendor-one.sh` and `vendor.sh`'s subject scans to bounded-and-loud; relax `classify()` to subject-decided; rewrite the landed rationale in `series-port.sh`'s header and `series-loop.md` stage 4; stage 1 invokes `main`'s `vendor-one.sh` against the buffer worktree | wider than first scoped — two scanners, one classifier, two rationale blocks, one skill rule; each independently shippable |
| **2** | single verdict store (D1: selection and resume by record; backstop stops writing, its schedule dispatches idle undecided work); one sweep, then drop the aggregate outright (D2); the fan-in stays (per-commit logs, §3.2) | verdicts are already dual-written today; rollback = read statuses again |
| **3** | replace the standalone repo with a fresh fork (§6), configured with the Pull app so the release-branch mirrors stay current without a job of our own; mirrors stay manual until then | one-time move; keep the standalone until the fork has served one full loop cycle |
| **4** | docs tree (§8): README root landed (#88); next the moves, then node rewrites (including `AGENTS.md`'s and `BRANCHES.md`'s stale rows); `docs-tree` skill | docs only |
| **5** | kernel extraction + `rigraph` port (config file, generalized subject marker, igraph cost estimator or constant weight) | new repo consumed `@main`; rollback = vendored copy of the kernel |

Phases 1a–3 are independently shippable; the deletions concentrate in
Phase 2.

## 10. Open questions

1. **Port batching (Phase 1).** Land a firing's port as individual
   cherry-picks (patch-id equivalence keeps forwards and rebases
   dropping them automatically) or squash into one port commit per
   firing (fewer CI verdicts, but squashing breaks the patch-id match
   and with it the automatic drop)? Leaning individual.
2. **Record-store scale.** One commit per record keeps `rcc` growing
   (~1 commit/record; consolidation squashes). Is the current
   consolidation cadence enough once statuses stop being a second copy?
3. **Fork migration depth (§6).** Carry the `rcc` records/logs and the
   1175 snapshot branches into the fresh fork, or restart them and keep
   the standalone repo read-only as the archive? Records at or below a
   series' green are never re-read by the loop, so a restart may be
   cheap.
4. **Extraction home (Phase 5).** Shared repo (`krlmlr/vendor-loop`?)
   consumed `@main`, vs. copy-with-config in each consumer.
   Leaning shared repo; decide when the port starts.
5. **Review artifacts.** Should routine-generated review digests
   (like `main-dev-review.md`) land under `plan/` by convention,
   or in PR comments only?
