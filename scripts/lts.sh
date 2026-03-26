#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

patch -p1 < scripts/lts.patch
R -q -e 'cpp11::cpp_register(); devtools::document()'
