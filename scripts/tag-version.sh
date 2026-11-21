#!/bin/bash
# Tag a commit as `v<version>`, annotated with a message in fledge's shape; run by .github/workflows/tag-version.yaml.
# Handbook: handbook/operations/releases/versioning/README.md
#
# The message is the subject `<package> <version>`, a blank line, and then
#   - the section NEWS.md has for the version at that commit, matched up to the version
#     so that a date after it is left out, where it has one, or
#   - the commits since the previous version tag the commit reaches, grouped as fledge
#     groups them into NEWS sections: first-parent subjects, merge commits and version bumps
#     left out, a conventional-commit type mapped to its section ("fix" to "Bug fixes", ...),
#     a scope as a `###` heading under its section, a `!` repeated under "Breaking changes",
#     anything else under "Uncategorized".
#
# The version is DESCRIPTION's at that commit unless given. A release version, three
# components, is refused: .github/workflows/cran-submission.yaml tags a release. A given
# version must be DESCRIPTION's or, for the landing of a release, DESCRIPTION's with `.9900`.
# The commit must lie on a branch of the remote, and the tag must not exist there yet.
#
# Usage:
#   scripts/tag-version.sh [--remote <name>] [--version <version>] [--dry-run] <commit>
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
    --remote) remote=$2; shift 2 ;;
    --version) version=$2; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
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

git fetch -q "$remote" "+refs/heads/*:refs/remotes/$remote/*" "+refs/tags/*:refs/tags/*"
sha=$(git rev-parse --verify -q "$commit^{commit}" || git rev-parse --verify -q "refs/remotes/$remote/$commit^{commit}") ||
  refuse "\`$commit\` is not a commit here." "Pass a branch name, a tag or a full commit SHA of the repository."
branches=$(git for-each-ref --contains "$sha" --format='%(refname:lstrip=3)' "refs/remotes/$remote/")
branches=$(grep -v '^HEAD$' <<<"$branches" || true)
[ -n "$branches" ] ||
  refuse "Commit \`${sha:0:10}\` lies on no branch of \`$remote\`." \
    "Tag a commit that a branch holds, such as the tip of \`main\` or of a release branch after its landing."

desc=$(git show "$sha:DESCRIPTION") ||
  refuse "Commit \`${sha:0:10}\` has no DESCRIPTION." "Tag a commit of the package."
package=$(sed -n 's/^Package: *//p' <<<"$desc")
desc_version=$(sed -n 's/^Version: *//p' <<<"$desc")
[ -n "$version" ] || version=$desc_version

[[ $version =~ ^[0-9]+(\.[0-9]+)+$ ]] ||
  refuse "\`$version\` is not a version." "Pass the version as dot-separated numbers, such as 2.0.99.9001."
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] &&
  refuse "\`$version\` is a release version, which this workflow does not tag." \
    "A release is tagged by the CRAN submission (.github/workflows/cran-submission.yaml)." \
    "For the landing of a release, pass the version \`$version.9900\`."
[ "$version" = "$desc_version" ] || [ "$version" = "$desc_version.9900" ] ||
  refuse "\`$version\` is neither DESCRIPTION's version at \`${sha:0:10}\`, \`$desc_version\`, nor that version with \`.9900\`." \
    "Leave the version empty to take DESCRIPTION's, or pick the commit whose DESCRIPTION carries it."

tag="v$version"
if existing=$(git rev-parse -q --verify "refs/tags/$tag^{commit}"); then
  refuse "The tag \`$tag\` exists already, on \`${existing:0:10}\`." \
    "If it is the right tag, there is nothing to do." \
    "If it is wrong, delete it first, after reading it: \`git push $remote :refs/tags/$tag\`, then dispatch again."
fi

# --- the message ---------------------------------------------------------------

news_version=$desc_version
news=$(git show "$sha:NEWS.md" 2>/dev/null |
  awk -v h="# $package $news_version" 'index($0, h) == 1 && ($0 == h || substr($0, length(h) + 1, 1) == " ") {f = 1; next} /^# / {f = 0} f' |
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

previous=$(git describe --tags --abbrev=0 --match 'v[0-9]*' "$sha" 2>/dev/null) || previous=
range=$sha
[ -z "$previous" ] || range="$previous..$sha"

entries=$(mktemp)
trap 'rm -f "$entries"' EXIT
count=0
while IFS= read -r subject; do
  [ -n "$subject" ] || continue
  count=$((count + 1))
  case "$subject" in "chore: Bump version to "* | "fledge: "*) continue ;; esac
  if [[ $subject =~ ^([A-Za-z]*)(\((.*)\))?(!?):[[:space:]](.*)$ ]]; then
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
  awk -F'\t' -v s="$s" '$1 == s && $2 == "" {print "- " $3 "\n"}' "$entries"
  while IFS= read -r scope; do
    printf '### %s\n\n' "$scope"
    awk -F'\t' -v s="$s" -v c="$scope" '$1 == s && $2 == c {print "- " $3 "\n"}' "$entries"
  done < <(awk -F'\t' -v s="$s" '$1 == s && $2 != "" && !seen[$2]++ {print $2}' "$entries")
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
  "- Previous version tag: \`${previous:-none}\`" "- Message from $source:" "" '```' "$(cat "$message")" '```'

if [ -n "$dry_run" ]; then
  echo "Dry run: nothing tagged or pushed."
  exit 0
fi

git tag -a "$tag" --cleanup=whitespace -F "$message" "$sha"
git push "$remote" "refs/tags/$tag"
echo "Pushed $tag."
