# Flavors

One source tree, published under several package names.
A flavor is a mechanical rename applied on top of a series' branch —
nothing else distinguishes one published package from another.

CRAN carries one version of one name at a time,
so a release line that must stay installable beside the current
one needs its own name.
An LTS line is frozen for its year
([`invariants/`](/handbook/branches/invariants/README.md)).
Because the names differ, flavors coexist in one library.

| Flavor | Kind | Published from | Upstream series |
|---|---|---|---|
| `duckdb` | CRAN, also r-universe | `main` in `duckdb/duckdb-r` | `v1.5-variegata` |
| `duckdb.1.4` | LTS, r-universe | `v1.4-andium-lts` in `duckdb/duckdb-r` | `v1.4-andium` |
| `duckdb.dev` | dev, r-universe | `main-green` | `main` |
| `duckdb.2.0.dev` | dev, r-universe | `v2.0-cyanoptera-green` | `v2.0-cyanoptera` |
| `duckdb.1.5.dev` | dev, r-universe | `v1.5-variegata-green` | `v1.5-variegata` |
| `duckdb.1.4.dev` | dev, r-universe | `v1.4-andium-green` | `v1.4-andium` |

There is no `duckdb.1.5`: v1.5 is not an LTS line,
and the current release already ships as `duckdb`.
The `Flavors` table in the root [`README.md`](/README.md) is where
a new flavor is announced.

**The rename surface** is exactly the set of places
that cannot ask for the name at run time —
package metadata, generated binding symbols,
and the public C++ header among them —
and the authoritative list is
[`scripts/flavor.patch`](/scripts/flavor.patch) itself:
what the patch rewrites is the surface, by construction.
[`scripts/flavor.sh`](/scripts/flavor.sh) takes the suffix
(`1.4`, `1.5.dev`, `dev`) and applies it,
regenerating `src/cpp11.cpp` and `R/cpp11.R` instead of patching them,
because cpp11 derives the `.Call` symbol prefix from the name —
which is also why the cpp11 that generates them has to be the fork
([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)).
The two READMEs are regenerated for the same reason:
the patch renames [`README.Rmd`](/README.Rmd),
and `README.md` and `.github/README.md` are written from it
([`meta/handbook/`](/handbook/meta/handbook/README.md)),
so the rename is spelled once rather than in three files kept in step
by hand.
Everywhere else the package asks for its name at run time
([`architecture/r-layer/conventions/`](/handbook/architecture/r-layer/conventions/README.md));
the scan that keeps it that way is
[`testing/guards/`](/handbook/testing/guards/README.md)'s.

This handbook is written for the mainline flavor:
where a page spells the package `duckdb`,
a reader on another flavor substitutes its name.

## Where r-universe is told

A universe is a repository of its own, `<user>/<user>.r-universe.dev`,
whose `packages.json` gives each package a `url` and a `branch`.
The registration lives outside this repo, so adding a flavor is a pull request
against that one ([`series-open`](/.claude/skills/series-open/SKILL.md)),
and [`scripts/r-universe-check.sh`](/scripts/r-universe-check.sh) says it took.

**Every base flavor names `duckdb/duckdb-r`, and a `.dev` one names `<S>-green`.**
r-universe reads ownership from that URL, so a `duckdb.*` package built from the
fork is published as the fork owner's.
The `-green` refs are therefore mirrored from the fork into the canonical
repository, which is the only branch that travels that way
([`branches/mirrors/`](/handbook/branches/mirrors/README.md)).

The fork's own universe carries the `-fwd-green` refs and nothing else.
A forward counterpart is a rebuild nobody installs, published only so a cutover
can be verified across fifteen targets before it happens,
so it belongs where it is built and not beside the flavor it will become.
