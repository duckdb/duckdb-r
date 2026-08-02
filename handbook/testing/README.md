# `testing/`

Proving the package works, locally and under CRAN's rules.
The area divides by what a check asserts —
what the suite proves, what a recorded expectation means,
what a guard refuses, what the packages downstream of this one need.
Where and when any of it executes, and what the result gates,
is [`operations/ci/`](/handbook/operations/ci/README.md)'s.

**Nothing here passes by being silent.**
A check that declines to run says so, and says how to enable it;
a verdict that is absent is undecided rather than green;
and a run is read for what it proved,
never for the absence of something red.
Every mechanism in this area is arranged so that not running
is louder than failing,
because a failure gets looked at and a skip does not —
which is why so much of what follows is about how a check announces
itself rather than about what it measures.

* [`suite/`](suite/) — layout, helpers, the fast loop
* [`snapshots/`](snapshots/) — snapshot discipline
* [`guards/`](guards/) — CRAN guard, flavor guard
* [`revdep/`](revdep/) — `revdep/` before release
