# Flavors

One source tree, published under several package names:
`duckdb` on CRAN,
and numbered and `.dev` names on r-universe,
tabulated under [The flavors](#the-flavors) below.
A flavor is a mechanical rename applied on top of a series' branch —
nothing else distinguishes one published package from another.

## Why more than one package

DuckDB cuts a new minor version roughly every four months
(the [upstream release cycle](https://duckdb.org/docs/stable/dev/release_cycle)
describes the schedule).
CRAN carries only one version of a given package name at a time,
so a release line that has to stay installable
next to the current one needs a name of its own.
LTS lines receive patch updates for a year —
about three minor cycles — and are archived after that.
The `.dev` names follow the bleeding edge of the matching upstream branch,
so the next release can be tried out without waiting for CRAN.

Because the names differ, the flavors coexist in one R library:
installing `duckdb.1.4` leaves `duckdb` alone.

## The flavors

| Flavor | Kind | Built from | Upstream series |
|---|---|---|---|
| `duckdb` | CRAN, also on r-universe | `main` in `duckdb/duckdb-r` | `v1.5-variegata` |
| `duckdb.1.4` | LTS, r-universe | `v1.4-andium-lts` in `duckdb/duckdb-r` | `v1.4-andium` |
| `duckdb.dev` | dev, r-universe | the `main` series in `krlmlr/duckdb-r` | `main` |
| `duckdb.1.5.dev` | dev, r-universe | the `v1.5-variegata` series in `krlmlr/duckdb-r` | `v1.5-variegata` |
| `duckdb.1.4.dev` | dev, r-universe | the `v1.4-andium` series in `krlmlr/duckdb-r` | `v1.4-andium` |

Which ref inside a series r-universe builds,
and how the series advance,
is [`model/`](/handbook/branches/model/README.md)'s.
Which flavor to install is
[`usage/installation/`](/handbook/usage/installation/README.md)'s.

There is no `duckdb.1.5`:
v1.5 was not designated an LTS line,
and the current release already ships as `duckdb`.
A numbered flavor without the `.dev` suffix exists only for an LTS line,
and so does the `-lts` branch it is built from.

The set grows when a new series opens.
The `Flavors` table in the root [`README.md`](/README.md)
is the only place a new flavor is announced by hand;
everything else about a series is discovered from its refs
(`.claude/skills/series-open.md`).

## What the rename touches

The flavor lives in a handful of files,
and the diff between an unflavored branch and its flavored counterpart
is exactly this:

* `DESCRIPTION` — the `Package:` field.
* `R/duckdb-package.R` — the `@useDynLib` directive
  and the `@name` of the package topic.
  `NAMESPACE` and `man/duckdb-package.Rd` carry the same change,
  patched directly rather than regenerated,
  so no roxygen2 run is needed.
* `src/include/rapi.hpp` — the `DUCKDB_PACKAGE_NAME` macro.
* `inst/include/duckdb_types.hpp` — renamed,
  with dots turned into underscores,
  so `duckdb.1.5.dev` gives `duckdb_1_5_dev_types.hpp`.
  It is the public C++ header that downstream packages include by name.
* `tests/testthat.R` — the `library()` call.
* `README.md` — the CRAN and Posit Public Package Manager sections
  collapse into a single sentence,
  and the r-universe `install.packages()` call takes the new name.
* `src/cpp11.cpp` and `R/cpp11.R` — regenerated rather than patched.
  cpp11 derives the `.Call` symbol prefix from the package name,
  so `_duckdb_rapi_connect` becomes `_duckdb_1_4_rapi_connect`,
  and the generated include follows the renamed public header.

Nothing else differs:
no vendored engine source, no glue logic, no R logic.
That the difference stays this small,
and that the names inside a branch agree with each other,
are stated as invariants in
[`invariants/`](/handbook/branches/invariants/README.md).

Everywhere else, the package asks for its own name at run time
through `get_package_name()`,
the seam described in
[`architecture/r-layer/`](/handbook/architecture/r-layer/README.md).
A name hard-coded outside the rename surface keeps pointing at `duckdb`
under every other flavor,
silently and usually only for the user;
the scan that prevents that is
[`testing/guards/`](/handbook/testing/guards/README.md)'s.

## Producing a flavor

[`scripts/flavor.sh`](/scripts/flavor.sh) takes the *suffix*, not the name:
`1.4` yields `duckdb.1.4`, `1.5.dev` yields `duckdb.1.5.dev`,
and `dev` yields `duckdb.dev`.
It works on the branch that is checked out and leaves two commits:

1. It rewrites [`scripts/flavor.patch`](/scripts/flavor.patch) in place,
   replacing the `1.3` placeholder with the target suffix.
   A single substitution covers both spellings —
   `.1.3` in package names and `_1_3` in the header filename —
   because it matches the separator in front of the number
   and reuses it for every dot in the suffix.
   Committed as `chore: Update flavor patch to <suffix>`.
2. It applies the patch with `patch -p1`,
   re-runs `cpp11::cpp_register()` to regenerate the two cpp11 files,
   drops the `.orig` leftovers,
   and commits everything as `chore: Update version to <suffix>`.

The second commit's subject says "version",
but the script never touches `Version:` —
both commits are the rename.
A series' dev branch carries a third commit on top of the pair
to add the fifth version component; that one is
[`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)'s.

## Limits

* `flavor.sh` invokes `gsed`.
  On a system where GNU sed is simply `sed` — most Linux —
  the script fails unless `gsed` is on `PATH`.
* The rewrite is one-shot.
  `flavor.sh` edits the patch template in place and commits it,
  so after the first run the placeholder is gone
  and the branch's template names that flavor.
  Re-flavoring means starting from an unflavored tree again,
  which is why a series is rebased rather than reseeded.
* The blurb the patch writes into `README.md` says
  "This package contains the LTS version 1.3 of DuckDB".
  The `1.3` there is preceded by a space rather than by `.` or `_`,
  so the substitution does not reach it,
  and every flavored branch's README claims 1.3 whatever the line —
  visible today on the published `duckdb.1.4`.
  The rest of the rename is unaffected.
* The regenerated cpp11 symbols depend on
  whichever cpp11 is installed when `flavor.sh` runs.
  cpp11 0.5.5 replaces only the first dot of the package name,
  producing `_duckdb_1.5.dev_rapi_connect`,
  which is not a valid C identifier.
  Compare `R/cpp11.R` against an existing series' seed
  before trusting a fresh one (`.claude/skills/series-open.md`).
* A flavor is a property of a branch, not a build-time option:
  one tree produces one name,
  and there is no environment variable or configure flag that selects it.
