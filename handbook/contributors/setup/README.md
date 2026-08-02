# Setup

*Stub — this leaf will own its topic;
today it routes to where the knowledge lives.
The writing protocol is in [`meta/handbook/`](../../meta/handbook/);
the last section holds this leaf's parameters.*

Scope: a working development environment in minutes —
clone, fast build, test loop.

Today:

* [`AGENTS.md`](../../../AGENTS.md) — the bootstrap and fast-path sections

To write this leaf:

* route, don't duplicate: the fast build is `build/fast-paths/`'s,
  the test loop `testing/suite/`'s —
  this leaf sequences them for a first-time contributor
* keep it to one screen:
  clone, install libduckdb, `load_all()`, `test_local()`
