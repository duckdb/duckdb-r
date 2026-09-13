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
([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)).
The two READMEs are regenerated for the same reason:
the patch renames [`README.Rmd`](/README.Rmd),
and `README.md` and `.github/README.md` are written from it
([`meta/handbook/`](/handbook/meta/handbook/README.md)),
so the rename is spelled once rather than in three files kept in step
by hand.

**Changing one flavor for another is a rename, not a second patch.**
`flavor.sh` builds a flavor onto an unflavored tree and refuses one that
already has it, which is what a series cut from another series arrives as
([`.claude/skills/series-open/SKILL.md`](/.claude/skills/series-open/SKILL.md)):
the cut takes its parent's tree entire, so the name is the only thing wrong
with it.
Reversing the old flavor to re-apply the new one is what does not work —
`flavor.patch` is the unflavored template `main` owns, and the tree has moved
since the flavor was applied, so the reverse fails on context that has nothing
to do with the name.
[`scripts/reflavor.sh`](/scripts/reflavor.sh) substitutes one name for the
other across the same surface, which needs no context at all.
It renames only inside that surface: `duckdb.dev` also appears in `handbook/`
and `plan/` as prose about the series that carries it, and renaming those would
make the documentation say something false.
Everywhere else the package asks for its name at run time
([`architecture/r-layer/conventions/`](/handbook/architecture/r-layer/conventions/README.md));
the scan that keeps it that way is
[`testing/guards/`](/handbook/testing/guards/README.md)'s.

This handbook is written for the mainline flavor:
where a page spells the package `duckdb`,
a reader on another flavor substitutes its name.

*To deepen: state where r-universe is told
which branch serves which flavor — the registration lives outside this repo.*
