#!/bin/sh
# Re-derive the two findings in this directory's README.md: what the
# published Windows libduckdb exports, and how much of what the glue needs
# is in there. Run from anywhere; writes nothing outside its work directory.
#
# Usage: probe.sh [--version vX.Y.Z] [--workdir DIR]
#
# The comparison reads glue-members.txt, the duckdb::Class::member names the
# glue resolves from the engine. Regenerate it on Linux from a fast-path
# build's object files (handbook/build/fast-paths/README.md), which is the
# one step this script cannot do on its own:
#
#   cd src
#   nm -u *.o | awk '{print $2}' | grep -E '^_Z.*6duckdb' | sort -u > /tmp/u
#   nm --defined-only *.o | awk '{print $3}' | grep -E '^_Z' | sort -u > /tmp/d
#   comm -23 /tmp/u /tmp/d | c++filt |
#     grep -oE '\bduckdb::[A-Za-z0-9_]+::[A-Za-z0-9_~]+' | sort -u

set -eu

version=v1.5.5
here="$(cd "$(dirname "$0")" && pwd)"
workdir=""

while [ $# -gt 0 ]; do
  case "$1" in
    --version) version="$2"; shift 2 ;;
    --workdir) workdir="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "${workdir}" ]; then
  workdir=$(mktemp -d)
  trap 'rm -rf "${workdir}"' EXIT
fi
mkdir -p "${workdir}"

url="https://github.com/duckdb/duckdb/releases/download/${version}/libduckdb-windows-amd64.zip"
echo "Fetching ${url}"
curl --fail --location --silent --show-error --output "${workdir}/win.zip" "${url}"
unzip -q -o "${workdir}/win.zip" -d "${workdir}/win"

# The DLL's exported names, one per line.
objdump -x "${workdir}/win/duckdb.dll" |
  sed -n '/\[Ordinal\/Name Pointer\] Table/,$p' |
  sed -nE 's/^[[:space:]]*\[[[:space:]]*[0-9]+\][[:space:]]+//p' |
  sort -u > "${workdir}/exports.txt"

echo
echo "Export table of libduckdb ${version} (windows-amd64):"
echo "  total exported names:  $(wc -l < "${workdir}/exports.txt")"
echo "  MSVC-mangled C++ (?):  $(grep -c '^?' "${workdir}/exports.txt")"
echo "  Itanium-mangled (_Z):  $(grep -c '^_Z' "${workdir}/exports.txt" || true)"
echo "  plain C API:           $(grep -c '^duckdb_' "${workdir}/exports.txt")"

# Match each duckdb::Class::member the glue needs against the export table,
# by MSVC's mangling of that name: ?member@Class@duckdb@@ for a method,
# ??0Class@duckdb@@ for a constructor, ??1Class@duckdb@@ for a destructor.
# The match ignores signatures, so it is generous to the DLL: a name counted
# present may still be a different overload.
hit=0
: > "${workdir}/absent.txt"
while IFS= read -r qualified; do
  rest="${qualified#duckdb::}"
  class="${rest%%::*}"
  member="${rest#*::}"
  case "${member}" in
    "${class}")  pattern="??0${class}@duckdb@@" ;;
    "~${class}") pattern="??1${class}@duckdb@@" ;;
    *)           pattern="?${member}@${class}@duckdb@@" ;;
  esac
  if grep -qF -- "${pattern}" "${workdir}/exports.txt"; then
    hit=$((hit + 1))
  else
    echo "${qualified}" >> "${workdir}/absent.txt"
  fi
done < "${here}/glue-members.txt"

echo
echo "Engine members the glue calls:  $(wc -l < "${here}/glue-members.txt")"
echo "  name present in the DLL:      ${hit}"
echo "  absent:                       $(wc -l < "${workdir}/absent.txt")"
echo
echo "Absent list written to ${workdir}/absent.txt"
diff -u "${here}/absent-from-windows-dll.txt" "${workdir}/absent.txt" &&
  echo "Matches the recorded run." ||
  echo "Differs from the recorded run -- the record is of ${version} on the day named in README.md."
