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

**Where a walk begins is the fork point, and that is what protects invariant 2.**
When upstream cuts a release branch off the line a series already tracks,
the tempting shortcut is to point a `-dev` branch at the new upstream branch
and let [`vendor-one.sh`](/scripts/vendor-one.sh) catch up.
That breaks the invariant silently, because the branch's recorded base is a commit
on the *old* line: the walk enumerates from there, so its first commit moves the
vendored sources backwards *and* skips ahead in one step.
`main-dev` took that step once — from a released `v1.5.0` tree to a `main` commit two
weeks older, landing 101 first-parent commits past the fork point at once,
none of them ever built against the glue, and a `git bisect` across it answers nothing.

> A new line starts with a vendor commit **at the fork point** of the two upstream
> branches, and walks forward from there one upstream commit at a time.

The fork point is the newest commit on the **first-parent chain of both** branches,
and it is *not* `git merge-base`: upstream merges a release branch back into `main`,
which drags the merge base forward to just after the most recent back-merge.
Opening v2.0 measured the two a week apart.

```bash
git rev-list --first-parent origin/main          > /tmp/main-fp
git rev-list --first-parent origin/v2.0-codename > /tmp/rel-fp
awk 'NR==FNR{a[$0];next} $0 in a{print; exit}' /tmp/main-fp /tmp/rel-fp
```

A line opened at that commit inherits the parent's walk unbroken, because it is
cut from the parent rather than replayed onto a base of its own
([`series-open`](/.claude/skills/series-open/SKILL.md)).
A replay is what would break it: a vendor commit carries a delta, not a tree, so
one may start above a chain's beginning only where the base already vendors the
commit the range starts at.

What enforces the green claim is the gate every commit passes
([`ci/per-commit/contract/`](/handbook/operations/ci/per-commit/contract/README.md));
the scripts that keep the rest are `pipeline/`'s.
