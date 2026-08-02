# The model

Why this package carries a complete copy of the DuckDB C++ engine,
and why that copy advances one upstream commit at a time.

Vendoring is keeping a dependency's sources inside the depending
repository instead of resolving them at build time.
`src/duckdb/` is that copy — regenerated from an upstream clone by
the scripts, never edited in place.
Why: self-contained builds on machines with no DuckDB;
glue compiled against exactly the engine commit it was tested with
(it includes internal headers that are ABI-compatible only with
the matching library);
CRAN's expectation that a package is self-contained;
reproducible builds.
The one supported way around compiling the copy is the developer
fast path, guarded by a commit match
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).

**The invariant** every `-dev` branch keeps:

1. **Linear** — first-parent history, no merges.
2. **One upstream commit per vendor commit**, forming a
   contiguous first-parent walk of the tracked branch.
   Upstream commits that change nothing the vendored tree carries
   produce no commit at all — the walk skips them without
   breaking contiguity.
3. **Green per commit** — every commit builds and passes on its
   own; a needed fix is folded into the commit, never appended,
   because a follow-up leaves a red commit in history forever.
4. **Auditable R-side delta** — vendor commits touch only the
   mechanical path set; anything else is a folded glue fix,
   reviewable as a path-filtered diff.

What enforces the green claim is
[`ci/per-commit/`](/handbook/operations/ci/per-commit/README.md);
the scripts that keep the rest are
[`pipeline/`](/handbook/operations/vendoring/pipeline/README.md)'s.
