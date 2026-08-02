# Triage

Issue intake: the verdicts an item can close under,
and where each routes the knowledge.
The worked instance is the 2026-07 triage of the whole open queue
(`plan/PLAN-inbox-zero.md` on branch
`claude/review-open-issues-prs-46alwv` of `krlmlr/duckdb-r`),
whose per-issue dispositions and drafted answers the leaves here
consume rather than re-derive.

**Every open item gets exactly one verdict, an owner, and a next
action** — an issue that stays open is a decision, not a leftover:

| Verdict | Meaning |
|---|---|
| `MERGE` / `FINISH` | PR is sound; land it, or complete then land |
| `FIX` | valid, scheduled work; stays open with priority and vehicle |
| `CLOSE-DOCS` | works as designed or known limitation; the close carries the doc |
| `CLOSE-FIXED` | already fixed; the close cites version or commit |
| `CLOSE-UPSTREAM` | engine, extension, or dbplyr matter; upstream link filed or found |
| `CLOSE-STALE-ASK` | needs info, reporter gone; invite a fresh report |
| `KEEP-ROADMAP` | deliberately open epic with a named next step |

**A close without a code change is a close *with* a documentation
change.**
The answer lands in the handbook leaf that owns the topic,
in the same pull request that closes the issue,
and the closing comment links it
([the rules](/handbook/meta/handbook/README.md#growing-a-leaf)).
Every open issue can name the leaf that would absorb its answer;
an issue with no addressable leaf is a defect of the tree.
Closing credits the reporter and names the reopen condition.

The label vocabulary readers act on is
[`contributors/where-to-help/`](/handbook/contributors/where-to-help/README.md)'s;
the lock bot (`.github/workflows/lock.yaml`) closes threads a year
after they close, not open ones.

*To deepen: absorb the guardrails from the triage plan § 7 —
issue templates, queue-state labels, the sweep routine — as they
are adopted.*
