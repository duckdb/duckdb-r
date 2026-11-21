#!/bin/bash
# Check scripts/tag-version.sh offline, against scratch repositories and a local bare remote.
# Handbook: handbook/operations/releases/versioning/README.md
#
#   1. Without a NEWS section for the version, the message groups the first-parent subjects
#      since the previous version tag as fledge does, newest first, leaving out merges and version bumps.
#   2. With a NEWS section for the version, dated or not, the message is that section.
#   3. A release version is refused, and the same version with `.9900` is tagged.
#   4. An existing tag, a commit on no branch, and a version that is not DESCRIPTION's are refused,
#      each with a "How to resolve" section in the step summary.
#   5. A dry run writes no tag; a real run pushes an annotated tag with the message.
#   6. A commit with nothing but a version bump since the previous tag says so.
#
# Usage:
#   scripts/tag-version-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRATCH=$(mktemp -d)
cleanup() { [ -n "${KEEP:-}" ] || rm -rf "$SCRATCH"; }
trap cleanup EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3"; echo "        in: $2" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "       present: $3" ;; *) ok "$1" ;; esac; }

export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

git init -q --bare "$SCRATCH/remote.git"
git init -q -b main "$SCRATCH/repo"
cd "$SCRATCH/repo"
git remote add origin "$SCRATCH/remote.git"

# <version> -> DESCRIPTION at that version
describe() { printf 'Package: duckdb\nTitle: Test\nVersion: %s\n' "$1" >DESCRIPTION; }
commit() { git commit -q --allow-empty -m "$1"; }

describe 2.0.0.9000
printf '# duckdb 2.0.0.9000\n\n- Old.\n' >NEWS.md
git add DESCRIPTION NEWS.md
commit "chore: Bump version to 2.0.0.9000"
git tag -a v2.0.0.9000 -m "duckdb 2.0.0.9000"

commit "fix: Release parked objects on dbDisconnect() (#3058)"
commit "feat: fetch only the columns read (#3010)"
commit "fix(patch): Keep a function entry alive (#3011)"
commit "feat!: drop the legacy scan"
commit "docs: Explain the progress display (#3012)"
commit "Tidy up"
commit "vendor: Update vendored sources to duckdb/duckdb@8d78114e90"
git switch -q -c side
commit "fix: a fix inside the merged branch"
git switch -q main
git merge -q --no-ff -m "Merge pull request #1 from side" side
describe 2.0.0.9001
git add DESCRIPTION
commit "chore: Bump version to 2.0.0.9001"
git push -q origin main side

run() { GITHUB_STEP_SUMMARY="$SCRATCH/summary" "$HERE/tag-version.sh" "$@" 2>&1; }

echo "1. the message from the log"
: >"$SCRATCH/summary"
out=$(run --dry-run main)
msg=$(sed -n 's/^  | //p' <<<"$out")
expected='duckdb 2.0.0.9001

## Bug fixes

- Release parked objects on dbDisconnect() (#3058).

### patch

- Keep a function entry alive (#3011).

## Features

- Breaking change: drop the legacy scan.

- Fetch only the columns read (#3010).

## Documentation

- Explain the progress display (#3012).

## Breaking changes

- Breaking change: drop the legacy scan.

## vendor

- Update vendored sources to duckdb/duckdb@8d78114e90.

## Uncategorized

- Tidy up.'
is "grouped like fledge's NEWS" "$msg" "$expected"
hasnt "no merge commit" "$msg" "Merge pull request"
hasnt "no commit inside the merged branch" "$msg" "inside the merged branch"
hasnt "no version bump" "$msg" "Bump version"
has "the source is the log" "$out" "the log since v2.0.0.9000"
has "summary heading" "$(cat "$SCRATCH/summary")" "## Dry run: would tag \`v2.0.0.9001\`"
has "summary names the branch" "$(cat "$SCRATCH/summary")" "- On: \`main\`"
is "dry run writes no tag" "$(git tag -l v2.0.0.9001)" ""

echo "2. the message from NEWS.md"
printf '# duckdb 2.0.0.9001 (2026-11-20)\n\n## Features\n\n- From NEWS.\n\n\n# duckdb 2.0.0.9000\n\n- Old.\n' >NEWS.md
git add NEWS.md
commit "docs: Write NEWS for 2.0.0.9001"
git push -q origin main
out=$(run --dry-run main)
msg=$(sed -n 's/^  | //p' <<<"$out")
is "the dated NEWS section" "$msg" "duckdb 2.0.0.9001

## Features

- From NEWS."
has "the source is NEWS.md" "$out" "the section of NEWS.md for 2.0.0.9001"

echo "3. release versions"
describe 2.0.1
printf '# duckdb 2.0.1\n\n- Released.\n\n\n# duckdb 2.0.0.9000\n\n- Old.\n' >NEWS.md
git add DESCRIPTION NEWS.md
commit "chore: Bump version to 2.0.1"
git push -q origin main
: >"$SCRATCH/summary"
if out=$(run --dry-run main); then no "a release version is refused"; else ok "a release version is refused"; fi
has "names the CRAN submission" "$out" "cran-submission.yaml"
has "suggests .9900" "$out" "2.0.1.9900"
has "summary resolves" "$(cat "$SCRATCH/summary")" "### How to resolve"
out=$(run --version 2.0.1.9900 main)
has "the landing of a release is tagged" "$out" "Pushed v2.0.1.9900."
is "the tag is annotated" "$(git cat-file -t v2.0.1.9900)" "tag"
is "it is on the remote" "$(git ls-remote "$SCRATCH/remote.git" refs/tags/v2.0.1.9900^{} | cut -f1)" "$(git rev-parse main)"
is "its message is the NEWS section" "$(git tag -l --format='%(contents)' v2.0.1.9900 | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')" "duckdb 2.0.1.9900

- Released."

echo "4. refusals"
if out=$(run --version 2.0.1.9900 main); then no "an existing tag is refused"; else ok "an existing tag is refused"; fi
has "says how to delete it" "$out" "git push origin :refs/tags/v2.0.1.9900"
if out=$(run --version 2.0.2.9000 main); then no "a version not DESCRIPTION's is refused"; else ok "a version not DESCRIPTION's is refused"; fi
git switch -q --detach main
describe 2.0.1.9000
git add DESCRIPTION
commit "chore: Bump version to 2.0.1.9000"
loose=$(git rev-parse HEAD)
git switch -q main
if out=$(run --dry-run "$loose"); then no "a commit on no branch is refused"; else ok "a commit on no branch is refused"; fi
has "says so" "$out" "lies on no branch"
if out=$(run --dry-run nonexistent); then no "a missing commit is refused"; else ok "a missing commit is refused"; fi

git branch -q -D side
out=$(run --dry-run side) || true
has "a branch only the remote has resolves" "$out" "The tag \`v2.0.0.9000\` exists already"

echo "5. only a version bump since the previous tag"
git switch -q -c next main
describe 2.0.1.9000
git add DESCRIPTION
commit "chore: Bump version to 2.0.1.9000"
git push -q origin next
out=$(run --dry-run next)
msg=$(sed -n 's/^  | //p' <<<"$out")
is "same as previous" "$msg" "duckdb 2.0.1.9000

## Uncategorized

- Same as previous version."

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
