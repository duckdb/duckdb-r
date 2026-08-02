# `plan/` — designs, decisions, and history

*Handbook: [`meta/plans/`](/handbook/meta/plans/README.md)
owns this directory's conventions.*

This directory holds documents that are *not* part of the
description of how the system works today:
plans for work that is not finished,
and records of designs and reviews that have been superseded.
This file is what names the contents,
so nothing under `plan/` is an orphan.

What is current is owned by the
[handbook](/handbook/README.md) —
walking down from its root finds the leaf for any topic —
with [`.claude/skills/`](/.claude/skills/) holding the routines'
machine-loaded playbooks.
A document here may describe something that has since changed;
when the two disagree, the handbook leaf is right.

## Plans — work proposed or in progress

| To read about | Read |
|---|---|
| Simplifying the vendoring pipeline: one verdict store, tooling from `main`, a docs tree | [`PLAN-vendoring-simplification.md`](PLAN-vendoring-simplification.md) |
| Implementing `dbSendQueryArrow()` and the DBI Arrow API | [`PLAN-dbSendQueryArrow.md`](PLAN-dbSendQueryArrow.md) |
| The CRAN-safe storage-location policy, and the work to implement it | [`PLAN-storage-locations.md`](PLAN-storage-locations.md) |

## `history/` — superseded designs and one-off artifacts

Kept for the reasoning and the measurements, not as a description of the
system. Each says so in its own first lines. They live in their own
directory because the distinction is the point:
a plan may still come true, a history never will.

| To read about | Read |
|---|---|
| The agentic-loop design that preceded the series loop, and Appendix A's ccache measurements that the cost model still cites | [`history/vendoring-loop.md`](history/vendoring-loop.md) |
| A 2026-07 review of the non-vendored R-side delta on `main-dev` | [`history/main-dev-review-2026-07.md`](history/main-dev-review-2026-07.md) |

## Adding a document here

A plan goes in `plan/` as `PLAN-<topic>.md`; a superseded design or a one-off
review goes in `plan/history/`, named for what it is. Either way, open it with
a line saying what it is and which document owns the topic today, and add a row
above. A file under `plan/` that this table does not name is an orphan, which
is the one thing the tree's structure exists to prevent — and when a plan is
overtaken by events, moving it into `history/` and moving its row with it is
what retiring it looks like.
