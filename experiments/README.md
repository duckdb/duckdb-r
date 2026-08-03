# `experiments/` — measured evidence

*Handbook: [`meta/plans/`](/handbook/meta/plans/README.md)
explains this directory alongside `plan/`.*

One directory per experiment, holding everything it needs:
a `README.md` that says what was measured, when, on what,
and which handbook page relies on it,
plus whatever the run took — scripts, inputs, recorded output.

An experiment is evidence, not a check.
It does not re-run itself, and nothing here gates a build:
what a test can pin is a test
([`testing/suite/`](/handbook/testing/suite/README.md)),
and what a scan can enforce is a check
([`testing/guards/`](/handbook/testing/guards/README.md)).
What lands here is the finding too expensive to re-derive on demand —
a measurement, a survey, a build that takes an hour —
kept so the leaf that cites it can be trusted
without the reader repeating the work.

A record ages rather than rots:
it is true of the day it names,
and a leaf that leans on it says so.
Re-running is how it is refreshed;
the directory keeps the method so that is possible.

* [`2026-03-vendor-build-cost/`](2026-03-vendor-build-cost/) —
  churn per vendor commit, ccache hit rate on adjacent commits,
  archive size; supports
  [`operations/ci/per-commit/planning/`](/handbook/operations/ci/per-commit/planning/README.md).
* [`2026-07-main-dev-review/`](2026-07-main-dev-review/) —
  how much of a series' active range is R-side work rather than
  vendoring, and what kind; supports
  [`branches/invariants/`](/handbook/branches/invariants/README.md).
* [`2026-08-02-lts-drift/`](2026-08-02-lts-drift/) —
  how far the v1.4 LTS flavor has drifted from its baseline; supports
  [`branches/invariants/`](/handbook/branches/invariants/README.md).

Adding one: create the directory, name it for the date and the topic,
open its `README.md` with what and when and on what,
and link it from the leaf that relies on it.
