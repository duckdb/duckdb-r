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
([`branches/model/`](/handbook/branches/model/README.md)),
in stages that are skipped when they have nothing to do:

* **Vendor onto `<S>-build`** — extend the buffer with
  `vendor-one.sh`, fixing glue where the gate stops;
  red never blocks the buffer.
* **Repair the oldest `<S>-dev` failure** — classify by what a
  log positively contains: the tree's fault is folded into the
  offending commit and the tail replayed;
  the infrastructure's fault is retried once via a `retry-` ref
  that also serves as the ledger.
* **Advance** — consume `-build` into `-dev` in bounded chunks,
  and fast-forward `-green` over commits with recorded runs.
* **Forward-port** — bring `main`'s R-side work onto the series
  ([`scripts/series-port.sh`](/scripts/series-port.sh)).
* **Report** — one summary per firing;
  a caught-up `-fwd` counterpart is *reported* with the cutover
  command, never executed — that move is a human's.

[`scripts/series-check.sh`](/scripts/series-check.sh) prints each
series' verdict read-only and is always safe to run
([`troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)).
