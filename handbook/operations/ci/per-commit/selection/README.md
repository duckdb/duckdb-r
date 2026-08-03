# Selection

Which commits a run plans, and which it skips.
Everything here is a pure function of durable state —
the range the branch declares and the verdicts already on the `rcc` branch
([`store/`](/handbook/operations/ci/per-commit/store/README.md)) —
so a run recomputes rather than remembers.

## Bounded by `<S>-green`

On a `<S>-dev` branch with a sibling `<S>-green`, only `<S>-green..HEAD` is
scanned — everything at or before green is trusted and never rebuilt.
If green exists but is not an ancestor of HEAD, *nothing* is planned:
the branch is mid-surgery or on another lineage,
and an unbounded scan would flood the queue.
Branches without a green sibling fall back to first-parent history since `SINCE`.

The per-commit logs stay readable to `series-check.sh`,
which classifies a failure by what its harvested log contains.
`rcc-one.sh` therefore emits `Changes detected in workflow_dispatch build`
verbatim when the tree is dirty,
so style and roxygen drift is recognised as such
rather than landing in the `unclassified` bucket.

## The green marker

Setting the commit status *is* the job, so the leg does it directly:
`each-shard.sh` POSTs `pending` to `repos/.../statuses/<sha>` before a commit
and `success`/`failure` after it, context `rcc` —
the same call `rcc-smoke` makes inline in its own "Update status for rcc" steps.

## What selection actually reads

A commit is planned or skipped according to the **verdict store** —
the record the `rcc` branch holds at `runs2.d/<xx>/<sha>.ndjson`,
which the deciding leg publishes within seconds.
[`scripts/rcc-decided.sh`](/scripts/rcc-decided.sh) is that read,
for the planner and for a resuming leg alike,
and it is one tree-only fetch rather than a request per commit.
A dead leg simply writes nothing, and no record means undecided,
which is the truth — so no marker needs ageing out.

The remaining selection details:

* A commit the store does not mention is planned rather than skipped:
  the enumeration drives the decision, not the store's contents.
* Reachability is not emptiness.
  A store that cannot be read stops the plan rather than reporting nothing
  decided, which would replan the whole range.
* A `retry-<S>-dev` branch — the series' own branch name with a prefix, see
  [`series-loop.md`](/.claude/skills/series-loop.md) — replans **its tip**
  even when that commit already carries a verdict,
  so one commit can be judged again on its own SHA
  instead of being amended and taking its descendants with it.
  The prefix is stripped to derive the series,
  so the scan anchors on `<S>-green` and needs no ref of its own;
  a retry branch naming a series with no green plans nothing at all,
  because the fallback scan reaches into `main`,
  where no commit has a verdict.

## No running marker, by design

Nothing anywhere records "this commit is being built right now",
and nothing should.
Two mechanisms keep a commit from being built twice, and neither is a marker:

1. **One planning-and-building pass per branch at a time.**
   `each.yaml`'s `concurrency` group is `each-rcc-<ref>`, with
   `cancel-in-progress: false` — a second push queues behind the first
   rather than killing it,
   because a killed leg leaves its in-flight commit undecided.
   So two runs never plan the same branch concurrently.
2. **Work selection is a pure function of durable verdicts.**
   The planner asks one question per commit — is there a verdict for it? —
   and the answer lives on the `rcc` branch, which outlives every runner.
   A leg that dies takes no state with it: its decided commits are already
   published, and the rest are simply undecided again.

The `pending` status is a **display** artifact:
it tells a human looking at the commit list that something is happening.
`each-shard.sh` treats it as undecided,
because it is the state a killed leg leaves behind.
