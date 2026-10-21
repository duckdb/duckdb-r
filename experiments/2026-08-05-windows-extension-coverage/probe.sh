#!/bin/sh
# HTTP status of prebuilt-extension artifacts on the core repository,
# by DuckDB version, platform, and extension.
# Reads the repository, writes nothing.
set -eu

repo=https://extensions.duckdb.org

status() {
  curl -s -o /dev/null -w '%{http_code}' -I "$1"
}

echo "== icu, by version and platform"
for v in v1.4.1 v1.4.3 v1.5.5; do
  for p in windows_amd64_mingw windows_arm64_mingw windows_arm64; do
    printf '%s %-21s %s\n' "$v" "$p" \
      "$(status "$repo/$v/$p/icu.duckdb_extension.gz")"
  done
done

echo "== v1.5.5 windows_amd64_mingw, by extension"
for e in postgres_scanner spatial excel icu httpfs; do
  printf '%-18s %s\n' "$e" \
    "$(status "$repo/v1.5.5/windows_amd64_mingw/$e.duckdb_extension.gz")"
done

echo "== v1.5.5 windows_amd64 (MSVC), for contrast"
for e in postgres_scanner spatial; do
  printf '%-18s %s\n' "$e" \
    "$(status "$repo/v1.5.5/windows_amd64/$e.duckdb_extension.gz")"
done
