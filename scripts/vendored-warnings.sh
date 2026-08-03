#!/bin/bash
# Guard for suppressed compiler warnings in the vendored engine.
#
# Two halves, because the failure mode has two halves.
#
# 1. THE SUPPRESSION INVENTORY (lexical, no compiler).
#    `tools:::.check_pragmas()` -- what `R CMD check` runs -- greps for
#    `^\s*#pragma (GCC|clang) diagnostic ignored`: single spaces, and no space
#    between `#` and `pragma`. Every other spelling the preprocessor accepts
#    (`#  pragma clang ...`, `#pragma  GCC  diagnostic  ignored ...`) is
#    honoured by the compiler and invisible to the check. So a suppression can
#    sit in the tree indefinitely with nothing reporting it.
#
#    This half greps the patch stack -- not the tree -- for every
#    `diagnostic ignored` an added line introduces, whatever its spacing, and
#    compares it against the inventory below. A new suppression fails until
#    someone writes it down with a reason.
#
#    Scanning the patches rather than `src/duckdb/` is what keeps upstream out
#    of it: pdqsort, yyjson and cpp11 all ship suppressions in the same evasive
#    spelling, and none of them is ours to respell -- normalising them would
#    mean carrying a patch against files that are re-vendored from upstream.
#    No patch of ours adds them, so this scan never sees them.
#
# 2. WARNING-FREE VENDORED LIBRARIES (needs clang).
#    A correctly spelled suppression is still a suppression, and nothing in CI
#    compiled this code with the warnings on. This half syntax-checks the
#    libraries whose patches exist to make them warning-free, under the
#    diagnostics CRAN's clang flavour uses (`-Wall -pedantic`), and fails on
#    any warning. `-fsyntax-only`, so it costs seconds, not a build.
#
#    Only clang: the two diagnostics `patch/0003-Fix-clang-warnings-in-re2.patch`
#    addresses (`-Wnested-anon-types`, `-Wdtor-name`) do not exist in GCC, which
#    is silent on the unfixed code.
#
# Usage (from anywhere in the repository):
#   scripts/vendored-warnings.sh
#
# Set DUCKDB_R_WARNING_CXX to use a compiler other than `clang++`.
#
# Explained in handbook/testing/guards/README.md; the policy this enforces --
# no warning is suppressed -- is handbook/architecture/glue/README.md's.

set -e
set -u
set -o pipefail

cd "$(dirname "$0")/.."

status=0

# --- 1. the suppression inventory --------------------------------------

# Every `diagnostic ignored` the patch stack introduces, one per line, as
# `<patch file> <diagnostic>`. A line joins this list only with a reason, and
# the reason belongs in the patch's own commit message or in the handbook leaf:
#
# * 0016 / -Wvla: guards the `asm volatile ("" : : "m" (*(char (*)[len]) buf) :)`
#   barrier that stops `mbedtls_platform_zeroize()` from being optimised away.
#   The VLA type is the whole point of the "m" operand. Kept in the widened
#   spelling deliberately; normalising it would make `R CMD check --as-cran`
#   report the pragma, which is a submission-affecting change and not this
#   guard's call to make (duckdb/duckdb-r#2492).
expected_suppressions="patch/0016-Avoid-mbedtls-diagnostic-pragmas.patch -Wvla"

# Added lines in the patch stack that turn a diagnostic off, whatever the
# spacing, reduced to `<patch file> <diagnostic>` and deduplicated: the same
# suppression written once for clang and once for GCC is one decision.
actual_suppressions=$(
  grep -HE '^\+[[:space:]]*#[[:space:]]*pragma[[:space:]]+(GCC|clang)[[:space:]]+diagnostic[[:space:]]+ignored' \
    patch/*.patch |
    sed -E 's/^([^:]*):.*"(-W[^"]*)".*$/\1 \2/' |
    sort -u
)

if [ "$actual_suppressions" != "$expected_suppressions" ]; then
  echo "The patch stack's suppressions do not match the inventory in $0." >&2
  echo "" >&2
  echo "Inventory:" >&2
  echo "$expected_suppressions" | sed 's/^/  /' >&2
  echo "Found:" >&2
  echo "${actual_suppressions:-  (none)}" | sed 's/^/  /' >&2
  echo "" >&2
  echo "A suppression is not the fix. Fix the warning at the source, in the" >&2
  echo "patch or upstream; if it genuinely cannot be fixed, add it to the" >&2
  echo "inventory above together with the reason." >&2
  status=1
else
  echo "Suppression inventory: matches ($(echo "$expected_suppressions" | wc -l) entries)."
fi

# --- 2. warning-free vendored libraries --------------------------------

CXX=${DUCKDB_R_WARNING_CXX:-clang++}

if ! command -v "$CXX" >/dev/null 2>&1; then
  echo "$CXX not found; this guard needs clang to see -Wnested-anon-types and" >&2
  echo "-Wdtor-name, which GCC does not implement. Install clang, or point" >&2
  echo "DUCKDB_R_WARNING_CXX at another compiler that does." >&2
  exit 1
fi

# Syntax-check every named translation unit and fail on any warning.
# $1 is the library, for the log line; the rest is compiler arguments followed
# by the sources. One invocation rather than one per file: clang keeps going
# after a failing translation unit, and the diagnostics come out in order
# instead of interleaved.
check_library() {
  local library=$1
  shift

  if "$CXX" -std=c++17 -fsyntax-only -Wall -pedantic -Werror "$@"; then
    echo "$library: no warnings under $CXX -Wall -pedantic."
  else
    echo "$library warns under $CXX -Wall -pedantic; fix it at the source." >&2
    status=1
  fi
}

# re2 -- patch/0003-Fix-clang-warnings-in-re2.patch names the two diagnostics
# it fixes rather than hides, and every re2 translation unit sees the headers
# both of them live in.
check_library re2 \
  -Isrc/duckdb/third_party/re2 \
  src/duckdb/third_party/re2/re2/*.cc \
  src/duckdb/third_party/re2/util/*.cc

# mbedtls -- patch/0016-Avoid-mbedtls-diagnostic-pragmas.patch removed one
# suppression outright and keeps the -Wvla one above. This pins both: the
# removal has to stay warning-free, and deleting the -Wvla pragma without
# replacing the barrier turns red here.
check_library mbedtls \
  -Isrc/duckdb/third_party/mbedtls/include \
  -Isrc/duckdb/third_party/mbedtls/library \
  src/duckdb/third_party/mbedtls/library/*.cpp

# Not covered, deliberately: the vendored libraries no patch of ours makes a
# warning claim for. zstd's dict/ sources warn upstream under -Wall, and
# patch/0033-clang-macos.patch fixes a libc++ deprecation that a Linux runner
# with libstdc++ cannot reach. Extending the list means verifying the library
# is clean first -- a guard that starts red teaches people to ignore it.

exit $status
