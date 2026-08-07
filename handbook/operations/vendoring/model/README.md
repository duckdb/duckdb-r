# The model

Why this package carries a complete copy of the DuckDB C++ engine,
and why that copy advances one upstream commit at a time.

Vendoring is keeping a dependency's sources inside the depending
repository instead of resolving them at build time.
`src/duckdb/` is that copy — regenerated from an upstream clone by
the scripts, never edited in place.
Why:

* **Self-contained builds.** The package compiles on a machine with no
  DuckDB installed, which is also what CRAN expects of a package.
* **The glue compiles against exactly the engine commit it was tested
  with.** It reaches into internal DuckDB headers that are
  ABI-compatible only with the matching library.
* **A clone is the whole thing.** No submodule to initialise, update, or
  forget — `git clone` gives a tree that builds.
* **Reproducible builds**, since nothing is resolved at build time.
* **A maintainer preference**, not only a derivation: a vendored tree is
  preferred over a submodule for this package, and the points above are
  why rather than the other way round.

The one supported way around compiling the copy is the developer
fast path, guarded by a commit match
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).

**The invariants** every `-dev` branch keeps:

1. **Linear** — first-parent history, no merges.
2. **One upstream commit per vendor commit**, forming a
   contiguous first-parent walk of the tracked branch.
   Upstream commits that change nothing the vendored tree carries
   produce no commit at all — the walk skips them without
   breaking contiguity.
3. **Green per commit** — every commit builds and passes on its
   own; a needed fix is folded into the commit, never appended,
   because a follow-up leaves a red commit in history forever.
4. **Auditable R-side delta** — vendor commits touch only the paths
   `rconfigure.py` regenerates, the generator being the list
   ([`pipeline/`](/handbook/operations/vendoring/pipeline/README.md));
   anything else is a folded glue fix,
   reviewable as a path-filtered diff.

What enforces the green claim is the gate every commit passes
([`ci/per-commit/contract/`](/handbook/operations/ci/per-commit/contract/README.md));
the scripts that keep the rest are `pipeline/`'s.
