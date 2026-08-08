#!/bin/bash

set -euxo pipefail

cd "$(dirname "$0")/.."

package_name="$1"
if [ -z "$package_name" ]; then
  echo "Usage: $0 <package-name>"
  echo "  $0 1.5"
  echo "  $0 1.5.dev"
  echo "  $0 dev"
  exit 1
fi

# Replace all dots with \1 for the sed expression
replacer=${package_name//./\\1}

# The patch file has 1.3
gsed -i.bak -r 's/([._])1\13/\1'$replacer'/g' scripts/flavor.patch
rm scripts/flavor.patch.bak
git add scripts/flavor.patch
git commit -m "chore: Update flavor patch to $package_name"

# Updates to man/ and NAMESPACE are handled in the patch file for efficiency
patch -p1 < scripts/flavor.patch
R -q -e 'cpp11::cpp_register()'

# README.md and .github/README.md are generated, so the patch renames their
# source and they are rewritten from it -- the same reason cpp11.cpp is
# regenerated rather than patched. Patching all three would mean three copies
# of one rename, kept in step by hand.
R -q -e 'rmarkdown::render("README.Rmd", quiet = TRUE)'

# Avoid storing .orig files
git clean -f -- "*.orig"
git add .
git commit -m "chore: Update version to $package_name"
