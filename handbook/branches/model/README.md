# The model

The series and their refs: what a series is, where its branches live,
what each ref means and how far it may move.
[`BRANCHES.md`](/BRANCHES.md) keeps what is not yet absorbed:
the package components and the repository diagrams.

**A series** is one upstream branch of `duckdb/duckdb` —
`main`, `v1.5-variegata`, `v1.4-andium` —
together with the R package branches that carry it.
A series is *discovered, not configured*:
the vendoring routine serves every `<S>-build` ref that has a
sibling `<S>-dev`, so opening one is creating refs
([`.claude/skills/series-open/SKILL.md`](/.claude/skills/series-open/SKILL.md)).

**Two repositories.**
`duckdb/duckdb-r` is canonical:
`main`, the parked stable baselines, the LTS flavor branch;
CRAN and the numbered r-universe packages publish from here.
`krlmlr/duckdb-r` is a fork of it — a fork object in the same fork
network, not a copy that shares its name — used for CI/CD
so the per-commit builds do not consume
the `duckdb` organization's Actions quota;
every series' working refs live there,
beside mirrors of the canonical branches
they are seeded from and measured against
([`mirrors/`](/handbook/branches/mirrors/README.md)).
The fork carries only the refs the loop serves;
what it does not carry stands in `krlmlr/duckdb-r-old`,
an archive that nothing reads and nothing writes to.
The `<S>-dev-base` refs of the older `dev`/`dev-base` layout are there:
every series is a series-loop series now, and none of the four below is that baseline.

**The four refs** of a series `<S>`, all in the fork:

| Ref | Moves by | Meaning |
|---|---|---|
| `<S>-build` | append; force-push to repair | the buffer: one commit per upstream commit, glue compiling, no CI |
| `<S>-dev` | append; force-push | what CI judges commit by commit, and what r-universe builds; `-build` consumed in bounded chunks plus forward-ports from `main` |
| `<S>-green` | fast-forward only | the trusted frontier — every commit behind it has a successful run; what the per-commit planner and the cutover gate measure from |
| `<S>-build-base` | forward only | the `-build` commit equivalent to `-green` |

All four exist from a series' first day, so there is never a "no green yet" state.
An opening cuts the parent's strands at the fork point and writes all four there
([`series-open`](/.claude/skills/series-open/SKILL.md)).
A green records that CI passed on a commit, and here it did: the cut moves no
commit, so `<S>-dev`'s tip *is* the parent's, same tree and same run.
That is what makes the green honest — not inheritance, but the absence of any
change to inherit across.
The buffer is deliberately untested on CI/CD,
so vendoring can run ahead while CI catches up
([`ci/per-commit/selection/`](/handbook/operations/ci/per-commit/selection/README.md)).

**Untested is a property of the tooling on the ref, not of the ref's name.**
A workflow fires from the branch it sits on,
so what keeps the buffer quiet is that the workflows it carries
match no branch it is called —
and a buffer carrying the copies it was seeded with
is judged by that day's filters instead.
`v1.4-andium-build` was: a 2026-03-26 `R-CMD-check.yaml`
whose release pattern matches the buffer's own name
put an `rcc` status on a commit no per-commit leg had decided.
So the port stage syncs the buffer's tooling too
([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)),
and the model's "no CI" holds because something maintains it.
Rebasing a series happens *beside* it as a `<S>-fwd` counterpart,
verified from scratch and swapped in by a human-run cutover;
a serving `-green` never moves sideways on its own.
**The badges in the root [`README.md`](/README.md) count the gaps between these refs**,
and both counts stay linear by construction —
`-green` is always an ancestor of `-dev`, and `-build-base` of `-build`:

* **in flight** — pushed to CI, not yet trusted: `<S>-green..<S>-dev`
* **buffered** — vendored, not yet consumed: `<S>-build-base..<S>-build`
* **ahead** — against the branch the series releases from

`-build-base` is a display ref and exists for exactly this; no script reads it back.
shields.io renders a count from the public repository:

```text
https://img.shields.io/github/commits-difference/krlmlr/duckdb-r?base=<S>-green&head=<S>-dev&label=in%20flight
```

It compares **within one repository**, which is what forces every ref a badge names
to live in `krlmlr/duckdb-r`, release branches included, and kept fresh
([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).
Link each badge to `https://github.com/krlmlr/duckdb-r/compare/<base>...<head>`, its drill-down.
An upstream-lag badge — how far behind `duckdb/duckdb` itself — is not expressible this way,
because that comparison crosses repositories.
The table's upkeep is [`series-open`](/.claude/skills/series-open/SKILL.md)'s.

**`main` in `duckdb/duckdb-r` is the source of truth** for four of the seven components
a branch is made of, and the other three come from elsewhere:

| Component | Source of truth | |
|---|---|---|
| DuckDB core | `duckdb/duckdb` upstream | vendored independently into each series |
| Flavor | per branch, via [`flavor.sh`](/scripts/flavor.sh) | applied mechanically on top of the baseline |
| **Glue code** | **`main`** | forward-ported to every series |
| **R code and tests** | **`main`** | forward-ported to every series |
| **CI/CD infrastructure** | **`main`** | forward-ported to every series |
| **cpp11** | **`main`** | forward-ported to every series |
| R core | external — `r-devel`, CRAN policy | monitored; fixes land in `main` first |

**Forward-porting runs newer to older, and never in reverse**:
`main` to the preview line and to each parked baseline,
then down the `.dev` branches in release order.
The series loop's forward-port stage keeps it consistent,
running [`series-port.sh`](/scripts/series-port.sh) on every firing
([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).
The fork's `main` takes no part in it: it is a mirror and moves on its own
([`mirrors/`](/handbook/branches/mirrors/README.md)).

That ordering is what makes the vendor strand the only thing a series owns.
Everything else it carries was born on `main` and arrived by port,
which is why a regenerated seed is allowed to replace a series' whole R side
and why a replay takes the new base for everything the vendor commits do not touch
([`series-forward`](/.claude/skills/series-forward/SKILL.md)).

*To deepen: absorb `BRANCHES.md` §§ Package Components and Branch Overview.*
