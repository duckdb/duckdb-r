#!/bin/bash
# Apply a package flavor: rewrite scripts/flavor.patch to the target name
# (say, duckdb.dev), apply it, and commit the rename; see BRANCHES.md.

set -euxo pipefail

cd "$(dirname "$0")/.."

package_name="${1-}"
if [ -z "$package_name" ]; then
  echo "Usage: $0 <package-name>"
  echo "  $0 1.5"
  echo "  $0 1.5.dev"
  echo "  $0 dev"
  exit 1
fi

# GNU sed, wherever it is called: on Linux that is `sed`, on macOS it is `gsed`
# and the system `sed` is BSD. Prefer `gsed`, then verify -- silently accepting
# BSD sed would write a subtly wrong patch that the commit below then records.
if command -v gsed >/dev/null 2>&1; then
  gnu_sed=gsed
else
  gnu_sed=sed
fi
sed_version="$("$gnu_sed" --version 2>/dev/null || true)"
case "$sed_version" in
*"GNU sed"*) ;;
*)
  echo "$0: '$gnu_sed' is not GNU sed." >&2
  echo "  Install GNU sed as 'gsed' -- on macOS, 'brew install gnu-sed'." >&2
  exit 1
  ;;
esac

# The patch file spells the flavor suffix 1.3, dot-separated in package names
# and underscore-separated in file names.
"$gnu_sed" -i \
  -e "s/duckdb\.1\.3/duckdb.$package_name/g" \
  -e "s/duckdb_1_3/duckdb_${package_name//./_}/g" \
  scripts/flavor.patch
git add scripts/flavor.patch
git commit -m "chore: Update flavor patch to $package_name"

# Updates to man/ and NAMESPACE are handled in the patch file for efficiency
patch -p1 < scripts/flavor.patch
R -q -e 'cpp11::cpp_register()'

# cpp11 derives the .Call prefix from `Package:`, replacing dots with
# underscores -- but only the fork replaces every one of them, so a flavor
# carrying two comes out of CRAN's cpp11 as `_duckdb_1.5.dev_rapi_connect`.
# Refuse it here: the next reader is the compiler, and the seed is committed
# before then. handbook/architecture/glue/README.md says which cpp11 to install.
if grep -qE '^extern "C" SEXP [A-Za-z_][A-Za-z0-9_]*\.' src/cpp11.cpp; then
  echo "$0: cpp11::cpp_register() wrote entry points that are not C identifiers:" >&2
  grep -E '^extern "C" SEXP [A-Za-z_][A-Za-z0-9_]*\.' src/cpp11.cpp | head -n 3 >&2
  echo "  Install the fork -- R -q -e 'remotes::install_github(\"krlmlr/cpp11\")' --" >&2
  echo "  then rerun cpp11::cpp_register(). The flavor patch is already committed;" >&2
  echo "  the rename itself is applied but uncommitted." >&2
  exit 1
fi

# Avoid storing .orig files
git clean -f -- "*.orig"
git add .
git commit -m "chore: Update version to $package_name"
