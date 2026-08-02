# `testing/`

Proving the package works, locally and under CRAN's rules.
The area divides by what a check asserts;
where and when any of it executes, and what the result gates,
is [`operations/ci/`](/handbook/operations/ci/README.md)'s.

**Nothing here passes by being silent.**
A check that declines to run says so, and says how to enable it,
and a run is read for what it proved,
never for the absence of something red.

* [`suite/`](suite/) — layout, helpers, the fast loop
* [`snapshots/`](snapshots/) — snapshot discipline
* [`guards/`](guards/) — CRAN guard, flavor guard
* [`revdep/`](revdep/) — `revdep/` before release
