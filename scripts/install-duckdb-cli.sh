#!/bin/sh
# Download the standalone DuckDB CLI matching the vendored DuckDB sources under
# src/duckdb/. Used to drive the CLI<->R secret-sharing end-to-end tests
# (tests/testthat/test-storage-cli-e2e.R), which need a CLI whose version
# matches the bundled engine.
#
# Unlike libduckdb (scripts/install-libduckdb.sh), the CLI is published for
# Windows too, so this script is cross-platform and runs under Git Bash on the
# Windows runners.
#
# Prints the absolute path to the installed `duckdb` binary on stdout -- and
# nothing else; all diagnostics go to stderr -- so a caller can capture it:
#
#   DUCKDB_CLI="$(scripts/install-duckdb-cli.sh --prefix "$RUNNER_TEMP/duckdb-cli")"
#
# Released versions only. For a development snapshot (no published CLI) the
# script prints nothing and exits 0, so callers fall back to skipping the
# CLI-dependent tests.
#
# Usage:
#   scripts/install-duckdb-cli.sh [--prefix DIR] [--version vX.Y.Z] [--url URL]
#
# Environment:
#   DUCKDB_R_LIB_VERSION  override the version (same as --version)
#   DUCKDB_CLI_URL        explicit URL of the duckdb_cli-<platform>.zip to use

set -eu

prefix=""
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

case "${version}" in
  *-dev*|*-dev)
    # No public per-commit CLI is published for development snapshots between
    # releases. Exit cleanly so the caller skips the CLI-dependent tests.
    echo "DuckDB ${version} is a development snapshot; no published CLI. Skipping." >&2
    exit 0
    ;;
esac

if [ -z "${url}" ] && [ -n "${DUCKDB_CLI_URL:-}" ]; then
  url="${DUCKDB_CLI_URL}"
fi

binary="duckdb"
uname_s=$(uname -s)
uname_m=$(uname -m)
case "${uname_s}" in
  Linux)
    case "${uname_m}" in
      x86_64)        platform=linux-amd64 ;;
      aarch64|arm64) platform=linux-arm64 ;;
      *) echo "Unsupported Linux arch: ${uname_m}" >&2; exit 1 ;;
    esac
    ;;
  Darwin)
    platform=osx-universal
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    platform=windows-amd64
    binary="duckdb.exe"
    ;;
  *)
    echo "Unsupported platform: ${uname_s}-${uname_m}" >&2
    exit 1
    ;;
esac

if [ -z "${prefix}" ]; then
  prefix="${repo_root}/.duckdb-cli"
fi

if [ -z "${url}" ]; then
  url="https://github.com/duckdb/duckdb/releases/download/${version}/duckdb_cli-${platform}.zip"
fi

echo "Downloading DuckDB CLI ${version} for ${platform}" >&2
echo "  from: ${url}" >&2
echo "  to:   ${prefix}" >&2

tmpdir=$(mktemp -d)
trap 'rm -rf "${tmpdir}"' EXIT

zip="${tmpdir}/duckdb_cli-${platform}.zip"
if command -v curl >/dev/null 2>&1; then
  curl --fail --location --silent --show-error --output "${zip}" "${url}"
elif command -v wget >/dev/null 2>&1; then
  wget --quiet -O "${zip}" "${url}"
else
  echo "Neither curl nor wget is available." >&2
  exit 1
fi

mkdir -p "${prefix}"
unzip -q -o "${zip}" -d "${prefix}"
chmod +x "${prefix}/${binary}" 2>/dev/null || true

if [ ! -f "${prefix}/${binary}" ]; then
  echo "Expected ${binary} in the CLI archive but it was not found." >&2
  exit 1
fi

echo "Installed DuckDB CLI ${version} to ${prefix}/${binary}" >&2

# The captured value: absolute path to the binary, the only line on stdout.
printf '%s/%s\n' "$(cd "${prefix}" && pwd)" "${binary}"
