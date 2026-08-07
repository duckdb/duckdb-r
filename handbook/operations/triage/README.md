# Triage

Issue intake: the verdicts an item can close under,
and where each routes the knowledge.
The per-issue dispositions and drafted answers for the current queue
are a plan, not a leaf: when one lands in [`plan/`](/plan/README.md)
the leaves here consume it rather than re-derive it.

**Every open item gets exactly one verdict, an owner, and a next
action** — an issue that stays open is a decision, not a leftover:

* `MERGE` / `FINISH` — the PR is sound; land it, or complete then land.
* `FIX` — valid, scheduled work; stays open with priority and vehicle.
* `CLOSE-DOCS` — works as designed or known limitation;
  the close carries the doc.
* `CLOSE-FIXED` — already fixed; the close cites version or commit.
* `CLOSE-UPSTREAM` — engine, extension, or dbplyr matter;
  upstream link filed or found.
* `CLOSE-STALE-ASK` — needs info, reporter gone; invite a fresh report.
* `KEEP-ROADMAP` — deliberately open epic with a named next step.

**A close without a code change
is a close *with* a documentation change.**
The answer lands in the handbook leaf that owns the topic,
in the same pull request that closes the issue,
and the closing comment links it
([`meta/handbook/`](/handbook/meta/handbook/README.md#growing-a-leaf)).
Every open issue can name the leaf that would absorb its answer;
an issue with no addressable leaf is a defect of the tree.
Closing credits the reporter and names the reopen condition.

The label vocabulary readers act on is
[`contributors/where-to-help/`](/handbook/contributors/where-to-help/README.md)'s;
the lock bot ([`lock.yaml`](/.github/workflows/lock.yaml))
locks a thread after a year without activity —
it neither closes nor reopens anything.

*To deepen: absorb the triage plan's guardrails —
issue templates, queue-state labels, the sweep routine — as they
are adopted.*
