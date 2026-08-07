# `plan/` — designs, decisions, and history

*Handbook: [`meta/plans/`](/handbook/meta/plans/README.md)
owns this directory's conventions.*

This directory holds documents that are *not* part of the
description of how the system works today:
plans for work that is not finished,
records of plans that came true,
and records of designs that never will.
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

## `done/` — plans that came true

The handbook states the outcome as fact; these are kept for the reasoning
that got there.

| To read about | Read |
|---|---|
| The CRAN-safe storage-location policy, and the work that implemented it | [`done/PLAN-storage-locations.md`](done/PLAN-storage-locations.md) |

## `superseded/` — designs overtaken by events

Kept for the reasoning, not as a description of the system;
each says so in its own first lines.
They live in their own directory because the distinction is the point:
a plan may still come true, a superseded design never will.

| To read about | Read |
|---|---|
| The agentic-loop design that preceded the series loop (its measurements now live in [`experiments/`](/experiments/README.md)) | [`superseded/vendoring-loop.md`](superseded/vendoring-loop.md) |

## `history/` — what a piece of work left behind

Not a plan and not a design: a record of something that happened,
kept because closing it would otherwise lose a fact.
Each says in its first lines what it is and which document owns its
topic today.

| To read about | Read |
|---|---|
| Findings verified against the code by the closed handbook wave, and the issues its defects became | [`history/2026-08-handbook-wave-salvage.md`](history/2026-08-handbook-wave-salvage.md) |
| The glue adaptations the August 2026 forward of all three series replayed, where each modification was placed, and what the run found out about the routine | [`history/2026-08-series-forward-glue.md`](history/2026-08-series-forward-glue.md) |

## Adding a document here

A plan goes in `plan/` as `PLAN-<topic>.md`, and opens with a line saying
what it is and which document owns its topic today; add a row above.
A file under `plan/` that this table does not name is an orphan, which is
the one thing the tree's structure exists to prevent.
Where a plan leaves depends on what happened to it:
one that came true moves to `done/`, one overtaken by events to
`superseded/`, and its row moves with it.
A record of work that is over rather than a proposal for work goes in
`history/`, named for when it happened, and never moves again.
A measurement is not a plan at all — it belongs in
[`experiments/`](/experiments/README.md), one directory per run.
