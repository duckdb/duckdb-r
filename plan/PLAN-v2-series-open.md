# Opening the v2.0 series

*Executed 2026-09-13. This is the record and what is left, not the routine —
[`.claude/skills/series-open/SKILL.md`](/.claude/skills/series-open/SKILL.md) owns that,
[`.claude/skills/series-forward/SKILL.md`](/.claude/skills/series-forward/SKILL.md) the forward,
and [`operations/releases/process/`](/handbook/operations/releases/process/README.md) the release around it.
Where a skill and this document disagree, the skill is right.*

## What was done

Upstream cut `v2.0-cyanoptera` off `main` at
`duckdb/duckdb@a00803f7687ca3d7188d417216e288c5c4b22b58`, 2026-09-02 —
the newest commit on the first-parent chain of both.
`git merge-base` gives `7074015a34`, a week newer, so the recipe is load-bearing.

Both halves were cuts at that point, not replays.

* **`v2.0-cyanoptera`** took `main-build` and `main-dev` at their fork-point commits
  (`01aa52689f`, `6cfcf36653`), with all four refs there.
  The series then walked forward on its own: 25 commits on `-build`, 72 on `-dev`,
  within the hour.
* **`main-fwd-*`** took one graft commit each — the fork-point commit's tree
  verbatim, parented on `main` — then everything the branch had taken since,
  replayed in order. 6606 commits became 14, 6731 became 50.
  Both heads came out byte-identical to the live branches outside `DESCRIPTION`,
  whose `Version:` takes `2.0.99.9000`, the prefix of the 2.1 line `main` now previews.

## What the run established

* **A replay onto a fresh seed cannot open a series.** `main` vendors a *released*
  engine — 1.5.5, `duckdb/duckdb@d8cdaa33fda`, on `v1.5-variegata` — which is on
  neither branch's first-parent chain, so no range start satisfies the range rule.
  The first pick laid a December-2024 delta over that tree and conflicted in some
  four hundred files.
* **A graft that keeps only the vendored surface does not build.** Taking
  `src/duckdb/` and the generated bookkeeping from the fork point while keeping the
  seed's R side pairs a 1.5.5-era glue with a 2.0-dev engine: 108 compile errors,
  `rfuns.cpp` alone losing `BinaryExecutor::ExecuteWithNulls` and four more.
  The whole tree is the graft; anything less is a merge nobody reviewed.
* **`in_base()` needed an ancestry test.** A commit the new base descends from is in
  the new base, whatever later commits did to the lines it touched; neither content
  test can see that. The v2.0 range stranded 906 commits, 903 of them plain ancestors.
* **A vendor-only replay drops ports a graft's base lacks.** Four `main` commits that
  landed after the fork point (#2649, #2687, #2698, #2714) strand against a graft,
  correctly — which is why a graft replays every subject, not only `vendor:`.

## What is left

* **v2.0's first forward.** The cut took `main`'s tree entire, so the series answers
  to `duckdb.dev` and stands on the fork point's R side. The forward gives it
  `2.0.dev` and current `main`'s R side, and only then is the line its own.
* **`duckdb.2.0.dev` in `duckdb.r-universe.dev`.** A package nothing here creates;
  the entry is a pull request against that repository. It cannot build until the
  forward above lands, but the queue is someone else's, so the request goes first.
  [`scripts/r-universe-check.sh`](/scripts/r-universe-check.sh) says it took.
* **The README `Flavors` row and `.github/pull.yml`.** v2.0 still releases from
  `main`, which is ruled already, so
  [`scripts/pull-config.sh`](/scripts/pull-config.sh) should print nothing —
  run it rather than assume.
* **`scripts/series-check.sh` and `scripts/series-converge.sh` against a cut series.**
  Both were written for a series with one lineage; a cut one shares objects with its
  parent, which they do not know about.
* **The open question: whether the buffer needs a flavor at all.** Nothing publishes
  `-build` and the compile gate does not care about the package name, so an
  unflavored buffer would let one chain serve every series sharing upstream history.
  Larger than anything above.
