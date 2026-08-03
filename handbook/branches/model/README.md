# The model

The series and their refs: what a series is, where its branches live,
what each ref means and how far it may move.
[`BRANCHES.md`](/BRANCHES.md) keeps what is not yet absorbed:
the package components, the repository diagrams,
and the legacy `dev`/`dev-base` layout some series still carry.

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
| `<S>-dev` | append; force-push | what CI judges commit by commit, and what r-universe builds; `-build` consumed in bounded chunks plus forward-ports from `main` |
| `<S>-green` | fast-forward only | the trusted frontier — every commit behind it has a successful run; what the per-commit planner and the cutover gate measure from |
| `<S>-build-base` | forward only | the `-build` commit equivalent to `-green` |

All four exist from a series' first day, equal at its seed,
so there is never a "no green yet" state.
The buffer is deliberately untested on CI/CD,
so vendoring can run ahead while CI catches up
([`ci/per-commit/selection/`](/handbook/operations/ci/per-commit/selection/README.md)).
Rebasing a series happens *beside* it as a `<S>-fwd` counterpart,
verified from scratch and swapped in by a human-run cutover;
a serving `-green` never moves sideways on its own.
The badges in the root [`README.md`](/README.md) count these gaps:
*in flight* and *buffered* between these refs,
*ahead* against the branch the series releases from.

*To deepen: absorb `BRANCHES.md` §§ Package Components,
Branch Overview, and Source of Truth.*
