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
| `duckdb.dev` | dev, r-universe | `main-dev` in the fork | `main` |
| `duckdb.1.5.dev` | dev, r-universe | `v1.5-variegata-dev` in the fork | `v1.5-variegata` |
| `duckdb.1.4.dev` | dev, r-universe | `v1.4-andium-dev` in the fork | `v1.4-andium` |

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
([`architecture/glue/`](/handbook/architecture/glue/README.md)).
Everywhere else the package asks for its name at run time
([`architecture/r-layer/`](/handbook/architecture/r-layer/README.md));
the scan that keeps it that way is
[`testing/guards/`](/handbook/testing/guards/README.md)'s.

This handbook is written for the mainline flavor:
where a page spells the package `duckdb`,
a reader on another flavor substitutes its name.

*To deepen: state where r-universe is told
which branch serves which flavor — the registration lives outside this repo.*
