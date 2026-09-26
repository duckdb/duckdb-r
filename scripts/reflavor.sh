#!/bin/bash
# Change an already-flavored tree from one flavor to another, in place:
# `duckdb.dev` -> `duckdb.2.0.dev`, renamed files and regenerated binding
# included. See handbook/branches/flavors/README.md.
#
# `flavor.sh` builds a flavor onto an *unflavored* tree and refuses an already
# flavored one, which is what a series cut from another series needs
# (.claude/skills/series-open/SKILL.md): the cut takes its parent's tree entire,
# so it arrives carrying the parent's package name and nothing else is wrong
# with it.
#
# **It renames rather than re-patching, and that is the whole design.**
# Reversing the old flavor to re-apply the new one needs `scripts/flavor.patch`
# to still describe the tree, and on a series it does not: the file is the
# unflavored template that `main` owns, and every commit since the flavor was
# applied has moved the context it would reverse against. Reversing the template
# against the v2.0 cut failed four hunks of nine. A rename needs no context.
#
# The surface is exactly what `flavor.patch` touches, taken from the patch
# rather than from a grep: `duckdb.dev` also appears in `handbook/` and `plan/`
# as prose about the series that carries that flavor, and renaming those would
# rewrite the documentation to say something false.
#
# Generated files are regenerated, never renamed: `src/cpp11.cpp` and `R/cpp11.R`
# from `cpp11::cpp_register()` -- which needs the `krlmlr/cpp11` fork, for the
# reason flavor.sh gives -- and the two READMEs from `README.Rmd`.
#
# Usage: reflavor.sh <package-name>
#   reflavor.sh 2.0.dev      # duckdb.dev -> duckdb.2.0.dev

set -euxo pipefail

usage='usage: reflavor.sh <package-name>'
argerr() { echo "$usage" >&2; exit 2; }

args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help) echo "$usage"; exit 0 ;;
    -*) argerr ;;
    *) args+=("$1"); shift ;;
  esac
done
[ ${#args[@]} -eq 1 ] || argerr
new=${args[0]}

# The tree to reflavor, found the way every scripts/series-*.sh finds it, so a
# copy of this script outside the worktree still reflavors the worktree.
toplevel=${VENDOR_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || true)}
[ -n "$toplevel" ] || { echo "Error: $PWD is not a git worktree" >&2; exit 1; }
cd "$toplevel"

if command -v gsed >/dev/null 2>&1; then gnu_sed=gsed; else gnu_sed=sed; fi
case "$("$gnu_sed" --version 2>/dev/null || true)" in
*"GNU sed"*) ;;
*) echo "$0: '$gnu_sed' is not GNU sed." >&2; exit 1 ;;
esac

[ -z "$(git status --porcelain)" ] ||
  { echo "$0: the working tree is not clean; commit or stash first." >&2; exit 1; }

# The flavor the tree carries, read from the one file that always states it.
pkg=$("$gnu_sed" -rn 's/^Package: (.*)$/\1/p' DESCRIPTION)
cur=${pkg#duckdb}
cur=${cur#.}
[ -n "$cur" ] ||
  { echo "$0: $pkg is unflavored; use flavor.sh to give it a flavor." >&2; exit 1; }
[ "$cur" != "$new" ] && echo "reflavor: $pkg -> duckdb.$new" ||
  { echo "$0: already duckdb.$new"; exit 0; }

cur_u=${cur//./_}
new_u=${new//./_}

start=$(git rev-parse HEAD)
committed=
restore() {
  [ -n "$committed" ] && return 0
  echo "$0: nothing committed; restoring the tree to $start" >&2
  git reset -q --hard "$start"
  git clean -qfd
}
trap restore EXIT

# The surface, from the patch that defines it. Its paths are the `1.3` template's,
# so they are read with the template spelling and rewritten to this tree's.
mapfile -t patched < <(
  grep -E '^(diff --git a/|rename to )' scripts/flavor.patch |
    sed -e 's|^diff --git a/||' -e 's| b/.*$||' -e 's|^rename to ||' |
    sed -e "s/duckdb\.1\.3/duckdb.$cur/g" -e "s/duckdb_1_3/duckdb_${cur_u}/g" |
    sort -u
)
# Process substitution reports no status and `pipefail` does not reach it, so an
# unreadable or reshaped patch would leave this empty -- and an empty pathspec
# makes the guard below a whole-tree grep, which then fails on the very prose
# this promises not to touch.
[ ${#patched[@]} -gt 0 ] ||
  { echo "$0: scripts/flavor.patch named no files; it is the rename surface." >&2; exit 1; }

for f in "${patched[@]}"; do
  [ -e "$f" ] || continue
  "$gnu_sed" -i -e "s/duckdb\.$cur/duckdb.$new/g" -e "s/duckdb_${cur_u}/duckdb_${new_u}/g" "$f"
done

# The three files whose own name carries the flavor.
for f in "${patched[@]}"; do
  case "$f" in
    *"duckdb.$cur"* | *"duckdb_${cur_u}"*)
      [ -e "$f" ] || continue
      t=${f//duckdb.$cur/duckdb.$new}
      t=${t//duckdb_${cur_u}/duckdb_${new_u}}
      git mv "$f" "$t"
      ;;
  esac
done

R -q -e 'cpp11::cpp_register()'

# **The READMEs are renamed, never rendered.** `flavor.sh` renders them because on
# `main` the source and the two rendered files are in step. On a series they are
# not, by design: all three are per-branch flavored documents that the port stage
# never carries, each keeping its own seed's wording (scripts/series-port.sh,
# duckdb/duckdb-r#2517). Rendering here would rewrite a `.dev` branch's front page
# back into `main`'s -- CRAN install instructions and all -- inside a commit whose
# subject says it only renamed a package.
for f in README.Rmd README.md .github/README.md; do
  [ -e "$f" ] || continue
  "$gnu_sed" -i -e "s/duckdb\.$cur/duckdb.$new/g" -e "s/duckdb_${cur_u}/duckdb_${new_u}/g" "$f"
done
git clean -f -- "*.orig"

# The same guard flavor.sh keeps: CRAN's cpp11 leaves the dots in, and a flavor
# carrying two of them comes out as `_duckdb_2.0.dev_rapi_connect`.
if grep -qE '^extern "C" SEXP [A-Za-z_][A-Za-z0-9_]*\.' src/cpp11.cpp; then
  echo "$0: cpp11::cpp_register() wrote entry points that are not C identifiers:" >&2
  grep -E '^extern "C" SEXP [A-Za-z_][A-Za-z0-9_]*\.' src/cpp11.cpp | head -n 3 >&2
  echo "  Install the fork -- R -q -e 'remotes::install_github(\"krlmlr/cpp11\")'" >&2
  exit 1
fi

# Nothing may still name the old flavor inside the surface; prose elsewhere may.
#
# Checked on the paths as they are **now**: three of them were renamed above, and
# a pathspec matching nothing makes `git grep` exit 1 in silence -- so guarding
# the old names would pass a rename that never happened. The regenerated files
# are guarded too, because they carry the symbol prefix and the patch does not
# name them.
guarded=()
for f in "${patched[@]}"; do
  t=${f//duckdb.$cur/duckdb.$new}
  t=${t//duckdb_${cur_u}/duckdb_${new_u}}
  [ -e "$t" ] && guarded+=("$t")
done
for f in src/cpp11.cpp R/cpp11.R README.Rmd README.md .github/README.md; do
  [ -e "$f" ] && guarded+=("$f")
done
[ ${#guarded[@]} -gt 0 ] ||
  { echo "$0: nothing to guard; the rename cannot have happened." >&2; exit 1; }

cur_re=${cur//./\\.}
if git grep -qE "duckdb\\.$cur_re\\b|duckdb_${cur_u}\\b" -- "${guarded[@]}"; then
  echo "$0: the old flavor survives in the renamed surface:" >&2
  git grep -nE "duckdb\\.$cur_re\\b|duckdb_${cur_u}\\b" -- "${guarded[@]}" >&2
  exit 1
fi

git add -A
git commit -m "chore: Reflavor to $new"
committed=1
