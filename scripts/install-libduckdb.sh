#!/bin/sh
# Install the libduckdb prebuilt binary matching the vendored DuckDB
# sources under src/duckdb/. Linux and macOS only.
#
# Used by .github/workflows/custom/before-install (CI) and by developers
# who want to opt into DUCKDB_R_USE_SYSTEM_LIB locally.
#
# Usage:
#   scripts/install-libduckdb.sh                 # install to /usr/local
#   scripts/install-libduckdb.sh --prefix DIR    # install to DIR (DIR/lib, DIR/include)
#   scripts/install-libduckdb.sh --version vX.Y.Z  # override the version
#
# Environment:
#   DUCKDB_R_LIB_VERSION  override the version (same as --version)
#   DUCKDB_R_LIB_URL      explicit URL of the libduckdb-<platform>.zip to use
#                         (overrides version-based URL construction)

set -eu

prefix=/usr/local
version=""
url=""

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)  prefix="$2"; shift 2 ;;
    --version) version="$2"; shift 2 ;;
    --url)     url="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
version_file="${repo_root}/src/duckdb/src/function/table/version/pragma_version.cpp"

if [ -z "${version}" ] && [ -n "${DUCKDB_R_LIB_VERSION:-}" ]; then
  version="${DUCKDB_R_LIB_VERSION}"
fi
if [ -z "${version}" ] && [ -f "${version_file}" ]; then
  version=$(sed -n 's/^#define DUCKDB_VERSION "\(.*\)"$/\1/p' "${version_file}")
fi
if [ -z "${version}" ]; then
  echo "Could not determine DuckDB version. Pass --version or set DUCKDB_R_LIB_VERSION." >&2
  exit 1
fi

if [ -z "${url}" ] && [ -n "${DUCKDB_R_LIB_URL:-}" ]; then
  url="${DUCKDB_R_LIB_URL}"
fi

uname_s=$(uname -s)
uname_m=$(uname -m)
case "${uname_s}-${uname_m}" in
  Linux-x86_64)  platform=linux-amd64 ;;
  Linux-aarch64) platform=linux-arm64 ;;
  Linux-arm64)   platform=linux-arm64 ;;
  Darwin-*)      platform=osx-universal ;;
  *)
    echo "Unsupported platform: ${uname_s}-${uname_m}" >&2
    exit 1
    ;;
esac

if [ -z "${url}" ]; then
  url="https://github.com/duckdb/duckdb/releases/download/${version}/libduckdb-${platform}.zip"
fi

echo "Downloading libduckdb ${version} for ${platform}"
echo "  from: ${url}"
echo "  to:   ${prefix}/lib (and ${prefix}/include)"

tmpdir=$(mktemp -d)
trap 'rm -rf "${tmpdir}"' EXIT

zip="${tmpdir}/libduckdb-${platform}.zip"
if command -v curl >/dev/null 2>&1; then
  curl --fail --location --silent --show-error --output "${zip}" "${url}"
elif command -v wget >/dev/null 2>&1; then
  wget --quiet -O "${zip}" "${url}"
else
  echo "Neither curl nor wget is available." >&2
  exit 1
fi

unzip -q -o "${zip}" -d "${tmpdir}/extracted"

mkdir -p "${prefix}/lib" "${prefix}/include"

case "${uname_s}" in
  Linux)
    install -m 0755 "${tmpdir}/extracted/libduckdb.so" "${prefix}/lib/libduckdb.so"
    ;;
  Darwin)
    install -m 0755 "${tmpdir}/extracted/libduckdb.dylib" "${prefix}/lib/libduckdb.dylib"
    ;;
esac

if [ -f "${tmpdir}/extracted/duckdb.h" ]; then
  install -m 0644 "${tmpdir}/extracted/duckdb.h"   "${prefix}/include/duckdb.h"
fi
if [ -f "${tmpdir}/extracted/duckdb.hpp" ]; then
  install -m 0644 "${tmpdir}/extracted/duckdb.hpp" "${prefix}/include/duckdb.hpp"
fi

if [ "${uname_s}" = "Linux" ] && [ "$(id -u)" = "0" ] && command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi

echo "Installed libduckdb ${version} to ${prefix}"
