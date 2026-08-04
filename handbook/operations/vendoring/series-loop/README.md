# The series loop

The scheduled routine that vendors every series.
The procedures are machine-loaded playbooks under
[`.claude/skills/`](/.claude/skills) —
[`series-loop.md`](/.claude/skills/series-loop.md) with its
siblings `series-forward`, `series-rebase`, `series-open` —
linked from here, never restated:
a reader who wants to *run* the loop follows the link;
what runs is this page's topic.

The loop is a scheduled **agent routine**, not a workflow —
nothing under `.github/workflows/` starts it,
and its schedule lives with the routine, outside this tree.
A firing serves every series discovered from the refs
([`branches/model/`](/handbook/branches/model/README.md)).
Setup always runs; every stage after it is skipped when it has nothing
to do, and they run in this order:

* **Vendor onto `<S>-build`** — extend the buffer with `vendor-one.sh`,
  fixing glue where the gate stops;
  red never blocks the buffer.
* **Repair the oldest `<S>-dev` failure** — classify by what a
  log positively contains: the tree's fault is folded into the
  offending commit and the tail replayed;
  the infrastructure's fault is retried once via a `retry-` ref
  that also serves as the ledger.
* **Advance the frontier, and read what r-universe made of the last one**
  — fast-forward `-green` over commits with recorded *successful* runs,
  move `-build-base` to match, and read back what the previous green
  became on the platforms the per-commit gate never covers
  ([`scripts/r-universe-check.sh`](/scripts/r-universe-check.sh)).
  A red there never rewinds green; it is recorded in the commit
  message of the `-dev` commit that answers it, which is where the
  next forward reads it.
* **Forward-port** — bring `main`'s R-side work onto the series
  ([`scripts/series-port.sh`](/scripts/series-port.sh)).
* **Extend `<S>-dev`** — consume the buffer in bounded chunks,
  at most 100 commits per firing
  ([`scripts/series-advance.sh`](/scripts/series-advance.sh)).
* **Suggest a cutover** — a caught-up `-fwd` counterpart is *reported*
  with the command, never executed; that move is a human's.
* **Report what the tooling got wrong** — a firing that had to work
  around a script opens a pull request against it,
  so the next firing does not have to.

[`scripts/series-check.sh`](/scripts/series-check.sh) prints each
series' verdict read-only and is always safe to run
([`troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)).
