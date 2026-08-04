#!/bin/bash
# Read-only: what did r-universe make of the refs this repository publishes?
#
# `<S>-green` is what r-universe builds (.claude/skills/series-loop.md), on
# platforms the per-commit `rcc` gate never touches -- Windows on x86_64 and
# arm64, macOS on both, wasm. A series can therefore be green commit by commit
# and still ship a package that does not build, and nothing in the harvest on
# branch `rcc` would say so. This script is that missing read.
#
# For every package in the universe it prints the version, the commit it was
# built from, the local ref that commit is (when this clone knows it), and one
# line per target that is not OK, with the URL of the log that says why.
#
# Usage:
#   r-universe-check.sh [<package>...]   # default: every package in the universe
#   r-universe-check.sh --log <job-id>   # the full job log, to stdout
#   RUNIVERSE=<name> r-universe-check.sh # another universe (default: duckdb)
#
# Three access facts, each paid for once (2026-08-03):
#
#   * The `/builds` dashboard answers 403 to some fetchers, and the apex
#     `r-universe.dev` may be unreachable where the per-universe subdomain is
#     not. Everything below is on `https://<universe>.r-universe.dev`, which
#     answers a plain curl.
#   * The build logs live in the GitHub repository `r-universe/<universe>`,
#     which needs authentication and is not a repository this project can be
#     granted. r-universe proxies them: `/api/actions/logs/<job-id>` serves the
#     complete job log anonymously. That is the `--log` mode, and it is the
#     difference between "Windows failed" and the compiler error.
#   * `/api/packages` alone cannot answer this question. Its `_binaries` array
#     is one row per *artifact*, so a target whose build failed outright leaves
#     no row -- and the row from the last version that did build stays, wearing
#     that older version. Reading it as the current state reports success for a
#     target that has been failing for a fortnight. The per-package page's check
#     table is version-scoped and complete, so that is the verdict source here;
#     `_binaries` is read only to report how stale the published binary is.

set -euo pipefail

universe=${RUNIVERSE:-duckdb}
host="https://$universe.r-universe.dev"

fetch() { curl -fsSL --retry 3 --max-time 120 "$1"; }

if [ "${1:-}" = "--log" ]; then
  job=${2:?usage: r-universe-check.sh --log <job-id>}
  fetch "$host/api/actions/logs/$job"
  exit
fi

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

packages=$(fetch "$host/api/packages")

wanted=("$@")
if [ ${#wanted[@]} -eq 0 ]; then
  mapfile -t wanted < <(jq -r '.[].Package' <<<"$packages")
fi

# The ref this clone knows the built commit as. Exact hits only: the built
# commit is a tip by construction (r-universe builds a branch), and walking
# `--contains` over 1300 refs to maybe name an ancestor costs more than the
# answer is worth.
ref_for() {
  git for-each-ref --points-at "$1" --format='%(refname:short)' \
    refs/remotes/origin 2>/dev/null | paste -sd, - || true
}

# One row of the package page's check table -> "<target>\t<result>\t<seconds>\t<job-id>".
# The table is server-rendered, so this parses HTML: split on rows, keep the
# ones carrying a log link, and pull the four fields out of each.
checktable() {
  fetch "$host/$1" |
    sed -e 's|<tr>|\n<tr>|g' |
    grep 'data-apilink="logs/' |
    sed -E 's|.*<td[^>]*>([^<]*)</td>.*<b[^>]*>([A-Z]+)</b>.*<td[^>]*>([0-9]+)</td>.*data-apilink="logs/([0-9]+)".*|\1\t\2\t\3\t\4|'
}

status=0

for pkg in "${wanted[@]}"; do
  meta=$(jq --arg p "$pkg" '.[] | select(.Package == $p)' <<<"$packages")
  [ -n "$meta" ] || { echo "=== $pkg: not in $universe.r-universe.dev"; status=1; continue; }

  version=$(jq -r '.Version' <<<"$meta")
  commit=$(jq -r '._commit.id' <<<"$meta")
  upstream=$(jq -r '._upstream' <<<"$meta")
  ref=$(ref_for "$commit")

  echo "=== $pkg $version -- ${commit:0:9} ${ref:+($ref) }<$upstream>"

  rows=$(checktable "$pkg" || true)
  if [ -z "$rows" ]; then
    echo "  no check table -- the page moved, or the first build has not finished"
    status=1
    continue
  fi

  bad=0
  while IFS=$'\t' read -r target result seconds job; do
    [ "$result" = OK ] && continue
    bad=$((bad + 1))
    printf '  %-8s %-24s %5ss  %s/api/actions/logs/%s\n' \
      "$result" "$target" "$seconds" "$host" "$job"
  done <<<"$rows"
  [ "$bad" -eq 0 ] && echo "  all $(grep -c . <<<"$rows") targets OK"
  [ "$bad" -eq 0 ] || status=1

  # A target whose newest binary is *older* than the indexed version is one
  # whose build stopped producing artifacts: whoever installs from this
  # universe is served that older one, however long ago it was built. Rows
  # ahead of the index are the ordinary lag between building and indexing and
  # say nothing. Versions compare component-wise as numbers, not as strings:
  # `.9006` is not less than `.999`.
  jq -r --arg v "$version" '
      def vnum: [splits("[.]")] | map(tonumber);
      ($v | vnum) as $cur
      | [ ._binaries[]? | select(.version | vnum < $cur) ]
      | group_by(.os + "-" + (.arch // "?"))
      | map(max_by(.date))
      | .[]
      | [ "\(.os)-\(.arch // "?")", .version, .date[0:10] ]
      | @tsv
    ' <<<"$meta" |
    sort |
    while IFS=$'\t' read -r target older when; do
      printf '  %-8s %-24s newest binary is %s, built %s\n' STALE "$target" "$older" "$when"
    done
done

exit "$status"
