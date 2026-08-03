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
# Avoid storing .orig files
git clean -f -- "*.orig"
git add .
git commit -m "chore: Update version to $package_name"
