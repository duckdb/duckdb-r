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

# The patch file has 1.4
gsed -i.bak -r 's/([._])1\14/\1'$replacer'/g' scripts/lts.patch
rm scripts/lts.patch.bak
git add scripts/lts.patch
git commit -m "chore: Update LTS patch to $package_name"

# Updates to man/ and NAMESPACE are handled in the patch file for efficiency
patch -p1 < scripts/lts.patch
R -q -e 'cpp11::cpp_register()'
# Avoid storing .orig files
git clean -f -- "*.orig"
git add .
git commit -m "chore: Update version to $package_name"
