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
  A series seeded from a release branch rather than from `main` takes
  no wholesale port: its R side belongs to that line, so only the
  tooling sync and fixes named by hand apply.
  That is read from the lineage under the seed rather than configured,
  so opening or retiring a release line changes no script.
* **Extend `<S>-dev`** — consume the buffer in bounded chunks,
  at most 100 commits per firing
  ([`scripts/series-advance.sh`](/scripts/series-advance.sh)).
* **Suggest a cutover** — a caught-up `-fwd` counterpart is *reported*
  with the command, never executed; that move is a human's.
* **Report what the tooling got wrong** — a firing that had to work
  around a script opens a pull request against it,
  so the next firing does not have to.

**A forward carries the vendor strand, and the rest is placed by hand.**
`<S>-fwd-build` is replayed from the buffer's `vendor:` commits alone, so
the buffer's own `patch/` entries do not travel with it; and a series
seeded from a release branch regenerates its seed on that branch, with
the tooling that branch carries rather than `main`'s, which the port
stage restores on the next firing.
Neither is reported — a vendor commit replayed onto a tree missing a
patch applies cleanly — so what settles it is a comparison of the
forward's `src/duckdb/` and `patch/` against the buffer's, never the
script's exit status
([#2545](https://github.com/duckdb/duckdb-r/issues/2545)).

[`scripts/series-check.sh`](/scripts/series-check.sh) prints each
series' verdict read-only and is always safe to run
([`troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)).
