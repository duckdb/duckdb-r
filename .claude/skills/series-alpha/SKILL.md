---
name: series-alpha
description: Cut and keep aligned the alpha strand of a series, `<S>-alpha` and `<S>-rc-alpha`, a green commit and its unflavored twin stamped with the version of upstream's newest alpha build of their engine, so that `INSTALL` finds the extensions upstream published for it. Use when asked to cut or move an alpha strand, when a revdep run or a test needs extensions on a dev series, or when a firing serves a series that has one.
---

# The alpha strand

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md),
what this routine is, and when it runs.*

A series stamps its engine `-dev`, `v2.0.0-dev87878` for `v2.0-cyanoptera`,
and the engine looks up the extensions of a `-dev` build under its commit hash, where upstream publishes nothing.
Upstream also dispatches builds by hand, about daily, named `v2.0.0-alpha<run number>`,
and publishes the extensions of one that passes under that version.
`<S>-alpha` is the newest `<S>-green` commit carrying the engine of such a build, stamped with its version,
so that `INSTALL` and autoloading reach those extensions.
`<S>-rc-alpha` is the same stamp on that commit's unflavored twin on `<S>-rc-dev`
([`series-rc`](/.claude/skills/series-rc/SKILL.md)), which is the package a revdep run checks.

**The version is the alpha's, byte for byte.**
The engine downloads from `<repository>/<version>/<platform>/`, and a custom repository replaces only the host.
A core extension is built against the C++ API and names the version it was built for,
the engine loads it under that exact version only, and the file is signed, so it cannot be relabelled.
The R side needs nothing:
`DESCRIPTION` keeps the series' version, and `./configure` compares `DUCKDB_SOURCE_ID`, which the stamp leaves alone.

**Each strand is one commit on a verified one.**
It is derived, never vendored, repaired or ported, and nothing is committed on it but what a revdep run adds.
No workflow's push filter matches an `-alpha` name, so a write starts no CI.

## Cut

```sh
scripts/series-alpha.sh <S>          # report: what it would write, exit 1 when not aligned
scripts/series-alpha.sh <S> --push   # write it, leased on what the remote held
```

The script reads `release/<upstream branch>/latest_alpha_version.txt` from `https://duckdb-staging.duckdb.org`,
`<sha10>/<version>`, which upstream's `Main.yml` writes only for a build on its default branch whose extensions deployed;
`--alpha <sha10>/<version>` names a build by hand instead.
It probes `icu` and `httpfs` on the five platforms R builds for, and stops on a gap.
The stamp stands on the newest green commit carrying that engine, the one under the next vendor commit,
so the R-side fixes CI demanded for that engine come along.
It rewrites what upstream's build derives from the version, as `DUCKDB_VERSION=<version>` would have,
and checked against `scripts/rconfigure.py` for `v2.0.0-alpha46057`, the two write the same tree.
Message, author and dates are a function of the green commit, so a rerun mints the same SHA.

A series takes an alpha strand when someone cuts it, once, with `--push`.
Upstream writes the pointer for its default branch only, `v2.0-cyanoptera` today,
and any other series reports that there is nothing to stamp.

## Keep it aligned

> An alpha strand is aligned when `scripts/series-alpha.sh <S>` reports it aligned.
> A firing that serves a series with an `<S>-alpha` realigns it with `--push` after the rc strand.

The strand moves when upstream points at a newer alpha and green has vendored its commit,
and until green has, it stays and the script says so.
A commit stacked on a stamp leaves the strand aligned:
a revdep run dispatched on `<S>-rc-alpha` commits its report there, and the report stays until a newer alpha moves the strand.
An alpha with a gap in its extensions stops the run before anything is written;
the gap is upstream's, and it is reported rather than worked around.

## Use

* **A revdep run whose packages need extensions** is dispatched on `<S>-rc-alpha`
  ([`testing/revdep/`](/handbook/testing/revdep/README.md)).
* **r-universe keeps publishing `<S>-green`.**
  An alpha lags the green tip by days, so publishing it would trade the newer engine for working extensions;
  that trade is a human's, made in `publishes_from` in [`scripts/series.yaml`](/scripts/series.yaml).

## At a cutover, and after

A cutover points r-universe at another generation's green and moves no ref
([`series-forward`](/.claude/skills/series-forward/SKILL.md)), so an alpha strand is untouched by it:
each generation that has one keeps it, `<L>-v<NNN>-alpha` and `<L>-v<NNN>-rc-alpha`,
realigned for as long as the loop serves the generation, and cut on a newly published generation once, by hand.
When a generation is pruned, its alpha strands go with it, in the commands
[`scripts/series-prune.sh`](/scripts/series-prune.sh) prints, so no alpha strand outlives its source.
