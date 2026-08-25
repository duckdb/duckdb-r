# Whether the verdict store can be retired

*What it measures:* the three things D6 asks for before the `rcc2` store is cut —
whether the gap it alone covers has ever been felt,
whether the commit status D6 would read instead agrees with the record it would replace,
and what keeping the branch costs in the meantime.
Plus the one thing D6 says to settle with the cut rather than after it:
whether anything but the `each-rcc` leg writes the `rcc` context.

*When and on what:* 2026-08-09 17:11 UTC, against `krlmlr/duckdb-r`,
with `rcc2` at cf4802b and the six live series at the refs the run prints.
`duckdb/duckdb-r` cannot answer any of it:
both store workflows carry `if: github.repository == 'krlmlr/duckdb-r'`,
so every run of them there is skipped,
and the series refs, the `each-rcc` runs and the store live in the fork besides.

*What it supports:* D6 and question 6 of
[`plan/PLAN-vendoring-simplification.md`](/plan/PLAN-vendoring-simplification.md).
The store's own page,
[`operations/ci/per-commit/store/`](/handbook/operations/ci/per-commit/store/README.md),
describes the branch this weighs but does not lean on these numbers.

Run [`run.sh`](run.sh); it fetches refs and reads the API, and writes nothing.
The full output of the run described here is
[`measured-2026-08-09.txt`](measured-2026-08-09.txt).

The counts move between runs, and that is not noise:
a run was deciding commits while this one was measuring,
so in-flight totals and `pending` counts differ
between two passes minutes apart.
Nothing below turns on those figures to the unit.

## 1. The gap has never been felt — over one day

A `workflow_dispatch` of `rcc-logs.yaml` is a firing saying it needed the store
and found it incomplete. There have been two, ever, both by `krlmlr`:

```
  total: 2   since 2026-08-08: 1
  2026-08-08T09:58:23Z  run 31251750340  by krlmlr  success
  2026-08-07T13:05:27Z  run 31181036396  by krlmlr  success
```

Neither is a firing that needed the store.
Both predate #2578, which merged at 2026-08-08T14:46:49Z,
and the later one is the verification dispatch that PR's own body names —
run 31251750340, dispatched *before* changing anything
to confirm the route the skill was about to depend on.
So the count since the schedule stopped is **zero**,
and the schedule itself stopped exactly when it should have:
of 118 runs, 76 are `schedule` and none since #2578,
22 are `push` (the workflow exercising itself on a change to its own paths),
and 2 are the dispatches above.

**The number is right and the window is not.**
Zero dispatches is what question 6 wanted,
but it has only been possible to dispatch-and-not for **1.1 days**.
Question 6 asked for a full cycle, and this is not one.
This measurement is the one that will change by being re-run,
which is the argument for re-running it rather than for reading it harder.

## 2. The replacement agrees, everywhere it was asked

Two answers per commit in `<S>-green..<S>-dev`, over all six live series:
a record via [`scripts/rcc-decided.sh`](/scripts/rcc-decided.sh),
which is what selection reads today,
and an `rcc` commit status of `success` or `failure`,
which is what D6 would read instead.
`pending` and absent are undecided on both sides.

```
  main: 0 in flight
  main-fwd: 409 in flight
  v1.4-andium: 0 in flight
  v1.4-andium-fwd: 1 in flight
  v1.5-variegata: 0 in flight
  v1.5-variegata-fwd: 10 in flight
  total: 420 commits
  status side:     372 none      23 pending      25 success
  decided by status: 25   by record: 25
  disagreements:
    (no lines above means the two answers agree on every commit in flight)
```

No status without a record, no record without a status,
and — checked beyond what D6 needs — no commit where the two name a different state.

**On its own this is a thin sample.**
The range is bounded by `-green`, so 395 of the 420 are simply not built yet;
25 decided commits is not a go signal.
So the run asks the same question of the sample the range cannot give:
the store's 250 newest records, every one of them decided by construction,
each a chance for a record to exist where a status does not.

```
  agree: 250   disagree: 0   (of 250)
```

That is the direction that would break D6 — a record the status read cannot see —
and it does not happen in 250 consecutive verdicts.

The batched GraphQL query D6 would actually make is in the script,
recovered from `each-plan.sh`'s pre-D1 form (#2440),
and it did not run here: the token this session holds serves only a pinned set
of GraphQL operations. The REST answer above is the same question by a route
every token serves, at one request per commit instead of one per hundred —
which is why the pre-D1 planner batched, and why D6's read should too.
Re-running with an ordinary token exercises the batched path and cross-checks it.

## 3. Keeping it costs 223 MB and about 400 commits a day

```
  commits: 1563
  records: 8453
  logs:    4242
  total      21447 objects    2651.3 MB  (223.0 MB packed)
  oldest record: 2026-04-11T11:43:01Z
  retention window: RCC_RETENTION_DAYS=180 days
  runs of rcc-consolidate.yaml (nothing is pruned without one):
    total: 0
```

`rcc-consolidate.yaml` has **never run** — not once, by anyone, dry or otherwise.
So nothing has been pruned since the cutover minted the branch on 2026-08-05,
and the 1562 commits above the root are 4.0 days of verdicts: about 389 a day.

Two things follow that the retention window alone would not tell you.

**A consolidation dispatched today would drop nothing.**
The oldest surviving record is 120 days old against a 180-day window.
Retention is not what is deferred; the squash is.
The whole of what consolidation would buy right now is
1563 commits collapsing to 2.

**The bill is the copy, not the verdicts.**
Records are ~2 KB and there are 8453 of them;
the 223 MB is the 4242 harvested logs,
which is what the branch exists to make readable without an API.

## What this decides

**Proceed after a cycle of notice**, and start the work that does not depend on it.

Measurement 2 is D6's go/no-go and it says go: the status read agrees with the
record read on every commit either was asked about, states included, and the
`rcc` context on every one of those commits was written by the leg.
Measurement 3 says the standing bill is real, dull and bounded — the reason to
stop deferring, not a reason to rush.
Measurement 1 is the only one not yet supporting *now*: the count is zero, but
one day is not the cycle question 6 asked for, and it is the cheapest of the
three to re-run.

So: keep the branch and the leg's publish for one full series cycle, re-run this,
and cut when the dispatch count is still zero. Nothing waits on that —
porting `series-check.sh` off `git show` is the one piece of real work in D6, it
is needed under every outcome, and it can land first.

## The wrinkle is not hypothetical

D6 says the `rcc` context is not the leg's alone, and to decide with the cut
whether the per-commit verdict gets its own. The fork already contains the
answer.

`R-CMD-check.yaml` runs from the branch it checks, so every series ref carries
its own copy of the push filter. Today all six `-dev` branches carry `main`'s:

```
    v1.5-variegata-dev: [main master release next cran-*]
```

None of those patterns matches a series ref, so the plan's claim holds — nothing
but the leg writes `rcc` on a `*-dev` branch. That is verified twice over here:
statically, in the filter on every live series' `-dev`, and empirically, in all
73 `rcc` status posts across the 420 commits in flight and every post across the
250 widened commits, each of them `each-rcc / shard N`.

But the claim is a ported commit deep, and it is **already false one ref over**:

```
    v1.4-andium-build: [main master release next cran-* v*.*-*]
      FIRES ON ITSELF via 'v*.*-*' -- a second writer of the rcc context
    on a series ref: 2026-08-06T09:23:58Z  v1.4-andium-build  push  head=6e7dd75ce  failure
    6e7dd75ce2fe15d3e707814edf0d3db5d26ed4c0
      rcc statuses: 11, newest failure (rcc)
      record on rcc2: NO
      in a <S>-green..<S>-dev range now: no
```

`v1.4-andium-build`'s copy of the workflow is from 2026-03-26 and still carries
the `v*.*-*` release-branch pattern, which matches its own name. Four pushes on
2026-08-06 therefore started the template check on the buffer, and
`R-CMD-check-status.yaml` stamped `rcc=failure` on `6e7dd75ce` — a
**status without a record**, exactly the class D6's read would misread, sitting
in this fork today.

It is harmless for one reason only, and the run checks it rather than assuming
it: a buffer commit is re-minted when it is consumed onto `-dev`, so its SHA
never enters selection's range.

```
    SHAs shared between (<S>-build-base..<S>-build) and (<S>-green..<S>-dev):
      main: 0 … v1.5-variegata-fwd: 0
```

That is a property of buffer/dev lineage, not of the context. The `-dev` copies
are clean because the port stage keeps them level with `main`; the buffer is
dirty because ports never touch it (F4's stated blind spot). A `-dev` branch
regaining the glob — a series opened from an old buffer, a forward that replays
onto a stale seed — puts a whole-branch matrix verdict directly into selection's
range, where D6 would read it as the commit's own.

So the answer to D6's wrinkle is not "decide it with the cut": give the
per-commit verdict its own context **before** the status read goes in. It costs
one line in `each-shard.sh`, and the alternative has already produced the failure
once.
