#!/bin/bash
# Tag a commit as `v<version>`, annotated with a message in fledge's shape; run by .github/workflows/tag-version.yaml.
# Handbook: handbook/operations/releases/versioning/README.md
#
# The message is the subject `<package> <version>`, a blank line, and then
#   - the section NEWS.md has for the version at that commit, matched up to the version
#     so that a date after it is left out, where it has one, or
#   - the commits since the highest version tag the parents of the commit reach, grouped as fledge
#     groups them into NEWS sections: first-parent subjects, merge commits and version bumps
#     left out, a conventional-commit type mapped to its section ("fix" to "Bug fixes", ...),
#     a scope as a `###` heading under its section, a `!` repeated under "Breaking changes",
#     anything else under "Uncategorized".
#
# The version is DESCRIPTION's at that commit, or, where that is a release's three components,
# the landing's `<version>.9900`, as scripts/series-land.sh tags a landing. A release version is
# refused: .github/workflows/cran-submission.yaml tags a release. A given version must be the one
# this would pick. The commit must lie on `main` or a release branch of the remote,
# `v<major>.<minor>-<name>`, and the tag must not exist there yet.
#
# Usage:
#   scripts/tag-version.sh [--remote <name>] [--version <version>] [--dry-run] [--] <commit>
#
# Without --dry-run the tag is created and pushed to the remote; with it, nothing is written.
# A summary goes to $GITHUB_STEP_SUMMARY when set. Exit status 1 refuses, with a reason
# and a "How to resolve" section.

set -euo pipefail

remote=origin
version=
dry_run=
commit=
while [ $# -gt 0 ]; do
  case "$1" in
    --remote | --version) [ $# -ge 2 ] || { echo "$1 needs a value" >&2; exit 2; }
      if [ "$1" = --remote ]; then remote=$2; else version=$2; fi
      shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    --) shift; [ $# -eq 1 ] || { echo "one commit after --, please" >&2; exit 2; }; commit=$1; shift ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) [ -z "$commit" ] || { echo "only one commit, please" >&2; exit 2; }; commit=$1; shift ;;
  esac
done
[ -n "$commit" ] || { echo "usage: $0 [--remote <name>] [--version <version>] [--dry-run] <commit>" >&2; exit 2; }

summary() { [ -z "${GITHUB_STEP_SUMMARY:-}" ] || printf '%s\n' "$@" >>"$GITHUB_STEP_SUMMARY"; }

# <reason> <how to resolve...> -> exit 1
refuse() {
  local reason=$1
  shift
  echo "::error title=Not tagged::$reason"
  echo "Not tagged: $reason" >&2
  printf '  %s\n' "$@" >&2
  summary "## Not tagged" "" "$reason" "" "### How to resolve" ""
  local line
  for line in "$@"; do summary "- $line"; done
  exit 1
}

git fetch -q --prune "$remote" "+refs/heads/*:refs/remotes/$remote/*"
git fetch -q "$remote" "+refs/tags/*:refs/tags/*"
# A branch name means the remote's branch, fetched just now; HEAD and anything else resolve here.
sha=
[ "$commit" = HEAD ] || sha=$(git rev-parse --verify -q "refs/remotes/$remote/$commit^{commit}") || true
[ -n "$sha" ] || sha=$(git rev-parse --verify -q "$commit^{commit}") ||
  refuse "\`$commit\` is not a commit here." "Pass a branch name, a tag or a full commit SHA of the repository."
branches=$(git for-each-ref --contains "$sha" --format='%(refname:lstrip=3)' "refs/remotes/$remote/")
branches=$(grep -E '^(main|v[0-9]+\.[0-9]+-[a-z]+)$' <<<"$branches" || true)
[ -n "$branches" ] ||
  refuse "Commit \`${sha:0:10}\` lies neither on \`main\` nor on a release branch of \`$remote\`." \
    "Tag a commit that \`main\` or a release branch holds, such as its tip after a landing."

desc=$(git show "$sha:DESCRIPTION" | tr -d '\r') ||
  refuse "Commit \`${sha:0:10}\` has no DESCRIPTION." "Tag a commit of the package."
package=$(sed -n 's/^Package: *//p' <<<"$desc" | sed 's/[[:space:]]*$//')
desc_version=$(sed -n 's/^Version: *//p' <<<"$desc" | sed 's/[[:space:]]*$//')
expected=$desc_version
[[ ! $desc_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || expected=$desc_version.9900
[ -n "$version" ] || version=$expected

[[ $version =~ ^[0-9]+(\.[0-9]+)+$ ]] ||
  refuse "\`$version\` is not a version." "Pass the version as dot-separated numbers, such as 2.0.99.9001."
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] &&
  refuse "\`$version\` is a release version, which this workflow does not tag." \
    "A release is tagged by the CRAN submission (.github/workflows/cran-submission.yaml)." \
    "For the landing of a release, leave the version empty to take \`$version.9900\`."
[ "$version" = "$expected" ] ||
  refuse "\`$version\` is not the version for \`${sha:0:10}\`, \`$expected\` from DESCRIPTION's \`$desc_version\`." \
    "Leave the version empty to take \`$expected\`, or pick the commit whose DESCRIPTION carries the version."

tag="v$version"
# The remote decides, so that a tag deleted there and still in a local clone does not count.
remote_tags=$(git ls-remote "$remote" "refs/tags/$tag^{}" "refs/tags/$tag") ||
  refuse "\`$remote\` did not answer whether \`$tag\` exists." "Dispatch again; if it keeps failing, check that the remote is reachable."
existing=$(awk 'NR == 1 || /\^\{\}$/ {s = $1} END {print s}' <<<"$remote_tags")
if [ -n "$existing" ]; then
  refuse "The tag \`$tag\` exists already, on \`${existing:0:10}\`." \
    "If it is the right tag, there is nothing to do." \
    "If it is wrong, delete it first, after reading it: \`git push $remote :refs/tags/$tag\`, then dispatch again."
fi

# --- the message ---------------------------------------------------------------

news_version=$desc_version
news=$(git show "$sha:NEWS.md" 2>/dev/null |
  awk -v h="# $package $news_version" -v p="# $package " 'index($0, h) == 1 && ($0 == h || substr($0, length(h) + 1, 1) == " ") {f = 1; next} index($0, p) == 1 {f = 0} f' |
  sed -e '/./,$!d' | sed -e ':a' -e '/^\n*$/{$d;N;ba' -e '}') || news=

# <section name> for a conventional-commit type, as fledge maps it
section_of() {
  case "$(tr '[:upper:]' '[:lower:]' <<<"$1")" in
    fix) echo "Bug fixes" ;;
    feat) echo "Features" ;;
    build) echo "Build system, external dependencies" ;;
    chore) echo "Chore" ;;
    ci) echo "Continuous integration" ;;
    docs) echo "Documentation" ;;
    style) echo "Code style" ;;
    refactor) echo "Refactoring" ;;
    perf) echo "Performance" ;;
    test) echo "Testing" ;;
    *) echo "$1" ;;
  esac
}
standard_sections=("Bug fixes" "Features" "Build system, external dependencies" "Chore" "Continuous integration"
  "Documentation" "Code style" "Refactoring" "Performance" "Testing" "Breaking changes")

# <description> -> capitalized, with a full stop, as fledge normalizes it
normalize() {
  local d=$1
  case "$d" in "$package "* | "$package's"*) ;; *) d="$(tr '[:lower:]' '[:upper:]' <<<"${d:0:1}")${d:1}" ;; esac
  case "$d" in *. | *! | *\?) ;; *) d="$d." ;; esac
  printf '%s' "$d"
}

# The highest version tag the commit's parents reach, through forward merges too, and never one on the commit itself;
# a landing's `vX.Y.Z.9900` ranks as the release X.Y.Z it lands, below the `X.Y.Z.90xx` that follow it.
previous=$(git tag --merged "$sha^" --list 'v[0-9]*' 2>/dev/null | grep -E '^v[0-9]+(\.[0-9]+)+$' |
  awk '{k = substr($0, 2); if (k ~ /^[0-9]+\.[0-9]+\.[0-9]+\.9900$/) sub(/\.9900$/, "", k); print k "\t" $0}' |
  sort -t "$(printf '\t')" -k1,1Vr | sed -n 1p | cut -f2) || previous=
range=$sha
[ -z "$previous" ] || range="$previous..$sha"

entries=$(mktemp)
trap 'rm -f "$entries"' EXIT
count=0
# type, optional (scope), optional !, colon, description: fledge's header, the scope without a ")"
header='^([A-Za-z]+)(\(([^)]*)\))?(!?):[[:space:]](.*)$'
while IFS= read -r subject; do
  [ -n "$subject" ] || continue
  count=$((count + 1))
  case "$subject" in "chore: Bump version to "* | "fledge: "*) continue ;; esac
  if [[ $subject =~ $header ]]; then
    section=$(section_of "${BASH_REMATCH[1]}")
    scope=${BASH_REMATCH[3]}
    breaking=${BASH_REMATCH[4]}
    description=${BASH_REMATCH[5]}
  else
    section=Uncategorized scope='' breaking='' description=$subject
  fi
  [ -z "$breaking" ] || description="Breaking change: $description"
  description=$(normalize "$description")
  printf '%s\t%s\t%s\n' "$section" "$scope" "$description" >>"$entries"
  [ -z "$breaking" ] || printf '%s\t%s\t%s\n' "Breaking changes" "$scope" "$description" >>"$entries"
done < <(git log --first-parent --no-merges --format=%s "$range")

# <section> -> its block: unscoped items first, then each scope under a ### heading
section_block() {
  local s=$1 scope
  printf '## %s\n\n' "$s"
  S=$s awk -F'\t' '$1 == ENVIRON["S"] && $2 == "" {print "- " $3 "\n"}' "$entries"
  while IFS= read -r scope; do
    printf '### %s\n\n' "$scope"
    S=$s C=$scope awk -F'\t' '$1 == ENVIRON["S"] && $2 == ENVIRON["C"] {print "- " $3 "\n"}' "$entries"
  done < <(S=$s awk -F'\t' '$1 == ENVIRON["S"] && $2 != "" && !seen[$2]++ {print $2}' "$entries")
}

log_body() {
  if [ ! -s "$entries" ]; then
    if [ "$count" -le 1 ]; then
      printf '## Uncategorized\n\n- Same as previous version.\n'
    else
      printf '## Uncategorized\n\n- Internal changes only.\n'
    fi
    return
  fi
  local s present custom
  present=$(cut -f1 "$entries" | awk '!seen[$0]++')
  for s in "${standard_sections[@]}"; do
    grep -qxF "$s" <<<"$present" && section_block "$s"
  done
  custom=$(grep -vxF -e Uncategorized "${standard_sections[@]/#/-e}" <<<"$present" || true)
  while IFS= read -r s; do
    [ -n "$s" ] && section_block "$s"
  done <<<"$custom"
  grep -qxF Uncategorized <<<"$present" && section_block Uncategorized
  return 0
}

message=$(mktemp)
trap 'rm -f "$entries" "$message"' EXIT
if [ -n "$news" ]; then
  source="the section of NEWS.md for $news_version"
  printf '%s %s\n\n%s\n' "$package" "$version" "$news" >"$message"
else
  source="the log since ${previous:-the first commit}, as NEWS.md has no section for $news_version"
  { printf '%s %s\n\n' "$package" "$version"; log_body | sed -e ':a' -e '/^\n*$/{$d;N;ba' -e '}'; } >"$message"
fi

echo "Tag $tag on ${sha:0:10}, on $(tr '\n' ' ' <<<"$branches")"
echo "Message from $source:"
sed 's/^/  | /' "$message"

on=$(awk '{printf "%s`%s`", (NR > 1 ? ", " : ""), $0}' <<<"$branches")
heading="Tagged"
[ -z "$dry_run" ] || heading="Dry run: would tag"
summary "## $heading \`$tag\`" "" \
  "- Commit: \`$sha\`" "- On: $on" \
  "- Previous version tag: \`${previous:-none}\`" "- Message from $source:" "" '``````' "$(cat "$message")" '``````'

if [ -n "$dry_run" ]; then
  echo "Dry run: nothing tagged or pushed."
  exit 0
fi

# -f replaces a stale local tag the remote no longer has; the remote was checked above.
git tag -f -a "$tag" --cleanup=whitespace -F "$message" "$sha"
git push "$remote" "refs/tags/$tag"
echo "Pushed $tag."
[ -z "${GITHUB_OUTPUT:-}" ] || echo "tag=$tag" >>"$GITHUB_OUTPUT"
