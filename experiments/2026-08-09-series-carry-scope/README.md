# How much a forward series' carry has to move, and what it is

*What it measures:* how many of a buffer's vendor commits have a fix
waiting on the base series' `-dev`,
what kind of fix it is,
and how much of the raw difference between the two branches
is not a fix at all.

*When and on what:* 2026-08-09,
`main-build` at 472b425 and `main-dev` at 9bf9287,
`main-fwd-build` at 808193f above `main-fwd-build-base` at efd6549,
all as fetched from `krlmlr/duckdb-r`.

*What it supports:* the stage-5 carry at
[`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) —
both that it is worth doing,
and the two exclusions it applies.

Run [`run.sh`](run.sh); it reads refs and writes nothing.

## The whole `main` series

Every vendor commit on the buffer, against its `main-dev` twin.

```
$ sh run.sh origin/main-build origin/main-dev

vendor commits:   3354
  with a twin:    3346
  carrying:       14
    incl. glue:   4
  excluded only:  15  (difference was buffer strand or regenerated files)
```

Two things this settles.

**The carry is rare and concentrated.**
14 commits in 3346 — under half a percent.
Which is the point rather than an objection:
each one is a commit that would go red on a forward series,
costing a repair and a replay of everything above it,
so the ratio says the mechanism is cheap to run
and the absolute number says what it saves.

**Most of the raw difference is not a fix.**
15 further commits differ between the two branches
and carry nothing this stage should move:
`src/duckdb/` and `patch/`, which a forward regenerates from its own
patches, and the files vendoring rewrites every run —
`R/version.R`, `src/include/sources.mk`.
More commits are excluded than carried,
which is why the carry is a filtered difference
rather than the twin's diff replayed wholesale.

**Glue is a real part of it.**
4 of the 14 touch `src/`, and the ranked list names them:
`src/transform.cpp` twice,
then `src/types.cpp`, `src/reltoaltrep.cpp`, `src/register.cpp`,
`src/include/typesr.hpp`, `src/include/rapi.hpp`,
`src/database.cpp`, `src/connection.cpp`.
The buffer compiles at every commit by the vendor gate,
so glue the `-dev` twin holds on top of it
was demanded by something later than the compiler.
An allow-list of `tests/`, `R/` and `man/` would strand all of it.

## What `main-fwd` has left to consume

The same read bounded to the part of the buffer
`main-fwd` has not yet minted onto `-dev`.

```
$ sh run.sh origin/main-fwd-build origin/main-dev origin/main-fwd-build-base

vendor commits:   802
  with a twin:    794
  carrying:       10
    incl. glue:   3
  excluded only:  0
```

Ten reds this series has not paid for yet, three of them glue.
`excluded only: 0` here rather than 15
because `main-fwd-build` was replayed out of `main-build`:
the replay already dropped the strand
the exclusions exist to drop.

Eight commits in each range have no twin —
folded pairs, where a transiently broken upstream commit
was squashed into the one that repaired it,
so the older SHA no longer heads a commit of its own.
They carry nothing and want nothing.
