# The model

The series and their refs: what a series is, where its branches live,
what each ref means and how far it may move.
[`BRANCHES.md`](/BRANCHES.md) is the detailed record of the model
(diagrams, release-cycle phases, synchronization),
being absorbed here leaf by leaf.

**A series** is one upstream branch of `duckdb/duckdb` —
`main`, `v1.5-variegata`, `v1.4-andium` —
together with the R package branches that carry it.
A series is *discovered, not configured*:
the vendoring routine serves every `<S>-build` ref that has a
sibling `<S>-dev`, so opening one is creating refs
([`.claude/skills/series-open.md`](/.claude/skills/series-open.md)).

**Two repositories.**
`duckdb/duckdb-r` is canonical:
`main`, the parked stable baselines, the LTS flavor branch;
CRAN and the numbered r-universe packages publish from here.
`krlmlr/duckdb-r` is a fork used for CI/CD
so the per-commit builds do not consume
the `duckdb` organization's Actions quota;
every series' working refs live there,
and [`sync.yaml`](/.github/workflows/sync.yaml)
fast-forwards the fork's `main` hourly —
to be replaced by wei/pull once the fork is a true fork
([#2494](https://github.com/duckdb/duckdb-r/issues/2494)).

**The four refs** of a series `<S>`, all in the fork:

| Ref | Moves by | Meaning |
|---|---|---|
| `<S>-build` | append; force-push to repair | the buffer: one commit per upstream commit, glue compiling, no CI |
| `<S>-dev` | append; force-push | what CI judges commit by commit; `-build` consumed in bounded chunks (default 100, `scripts/series-advance.sh`) plus forward-ports from `main` |
| `<S>-green` | fast-forward only | the trusted frontier — every commit behind it has a successful run; what r-universe should build |
| `<S>-build-base` | forward only | the `-build` commit equivalent to `-green` |

All four exist from a series' first day, equal at its seed,
so there is never a "no green yet" state.
The buffer is deliberately untested on CI/CD —
`each.yaml` triggers on `*-dev`, never on `*-build` —
so vendoring can run ahead while CI catches up
([`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)).
Rebasing a series happens *beside* it as a `<S>-fwd` counterpart,
verified from scratch and swapped in by a human-run cutover;
a serving `-green` never moves sideways on its own.
The badges in the root `README.md` count the gaps between these
refs: ahead, in flight, buffered.

*To deepen: absorb `BRANCHES.md` §§ Branch Overview,
Source of Truth, and Release Cycle Mapping.*
