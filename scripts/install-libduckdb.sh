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
# The vendored DuckDB version may be a tagged release (e.g. v1.5.3) or a
# development snapshot between releases (e.g. v1.5.4-dev157). Released
# versions are fetched from the GitHub release assets; development
# snapshots are fetched from the DuckDB nightly staging bucket, keyed by
# the commit recorded in the vendored pragma_version.cpp (DUCKDB_SOURCE_ID).
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

# The commit hash recorded by upstream in the vendored sources. This is the
# same `git log -1 --format=%h` value DuckDB's release workflow uses as the
# staging path segment, so it doubles as the nightly artifact key.
source_id=""
if [ -f "${version_file}" ]; then
  source_id=$(sed -n 's/^#define DUCKDB_SOURCE_ID "\(.*\)"$/\1/p' "${version_file}")
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
  case "${version}" in
    *-dev*|*-dev)
      # No public per-commit libduckdb is published for development
      # snapshots between releases (the DuckDB staging bucket is not
      # exposed via a stable HTTP gateway). Exit cleanly so callers can
      # fall back to compiling the vendored sources; an explicit
      # DUCKDB_R_LIB_URL override is honored above for cases where a
      # caller has a private build.
      echo "libduckdb ${version} is a development snapshot (commit ${source_id:-unknown})." >&2
      echo "No matching prebuilt is published; skipping install." >&2
      echo "Set DUCKDB_R_LIB_URL to a libduckdb-${platform}.zip if you have one." >&2
      exit 0
      ;;
    *)
      # Tagged release: GitHub release assets.
      url="https://github.com/duckdb/duckdb/releases/download/${version}/libduckdb-${platform}.zip"
      ;;
  esac
fi

echo "Downloading libduckdb ${version} (commit ${source_id:-unknown}) for ${platform}"
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

# Use sudo only when we're not root and the prefix isn't writable. This
# keeps callers from having to special-case Linux (/usr/local typically
# needs root) vs. macOS (writable by the runner user on GitHub Actions)
# vs. local dev (`--prefix=$HOME/.local`).
SUDO=
if [ "$(id -u)" != "0" ]; then
  probe="${prefix}"
  while [ ! -d "${probe}" ]; do
    probe=$(dirname "${probe}")
  done
  if [ ! -w "${probe}" ]; then
    if command -v sudo >/dev/null 2>&1; then
      SUDO=sudo
    else
      echo "${prefix} is not writable and sudo is not available." >&2
      exit 1
    fi
  fi
fi

${SUDO} mkdir -p "${prefix}/lib" "${prefix}/include"

case "${uname_s}" in
  Linux)
    ${SUDO} install -m 0755 "${tmpdir}/extracted/libduckdb.so" "${prefix}/lib/libduckdb.so"
    ;;
  Darwin)
    ${SUDO} install -m 0755 "${tmpdir}/extracted/libduckdb.dylib" "${prefix}/lib/libduckdb.dylib"
    ;;
esac

if [ -f "${tmpdir}/extracted/duckdb.h" ]; then
  ${SUDO} install -m 0644 "${tmpdir}/extracted/duckdb.h"   "${prefix}/include/duckdb.h"
fi
if [ -f "${tmpdir}/extracted/duckdb.hpp" ]; then
  ${SUDO} install -m 0644 "${tmpdir}/extracted/duckdb.hpp" "${prefix}/include/duckdb.hpp"
fi

if [ "${uname_s}" = "Linux" ] && command -v ldconfig >/dev/null 2>&1; then
  ${SUDO} ldconfig
fi

echo "Installed libduckdb ${version} to ${prefix}"
