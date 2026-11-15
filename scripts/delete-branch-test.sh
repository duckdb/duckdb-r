#!/bin/bash
# Check scripts/delete-branch.sh, offline, against a bare repository built
# here as the remote and a stand-in for `gh api` that answers a pull request's
# state: no network, no fixtures on disk.
#
# The claim the script makes is that it deletes a branch only where a closed
# pull request's head is the branch's tip, or a forward's branch where its
# twin is at the same tip, and refuses everything else before it pushes.
# Seven things are checked.
#
#   1. Arguments that are not one valid branch name, not starting with `-`,
#      and an optional positive whole number are a usage error, exit 2, and
#      nothing is read; so is a branch without a pull request whose name does
#      not hold `-fwd-`, or holds it twice.
#   2. A branch that does not exist, and the default branch, are refused.
#   3. A pull request with no head ref, and one whose head is not the branch's
#      tip, are refused.
#   4. An open pull request is refused, and so is one whose state cannot be
#      read.
#   5. A branch at the head of a closed pull request is deleted, and the step
#      summary says so; a refusal writes its reason there too.
#   6. A branch that moves after its tip was read is not deleted: the lease
#      refuses it.
#   7. Without a pull request, a forward's branch at its twin's tip is
#      deleted, and one whose twin is at another tip or missing, or that an
#      open pull request has as its head, or where that cannot be read, is refused;
#      a twin that moves forward after the read still holds the tip.
#
# Usage:
#   scripts/delete-branch-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }

# --- the fixture -----------------------------------------------------------
#
# A remote with `main`, its default branch, and branches `a` and `b`,
# and pull requests 1 to 4: #1 closed at `a`, #2 open at `b`, #3 closed at
# `main`, #4 closed with no state the stand-in can tell.

REMOTE_DIR=$SCRATCH/remote.git
WORK=$SCRATCH/work
BIN=$SCRATCH/bin
git init -q --bare -b main "$REMOTE_DIR"
git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$REMOTE_DIR"
c() { git commit -q --allow-empty -m "$1"; git rev-parse HEAD; }
MAIN=$(c main)
A=$(c a)
B=$(c b)
git push -q origin "$MAIN:refs/heads/main" "$A:refs/heads/a" "$B:refs/heads/b"
for p in "1 $A" "2 $B" "3 $MAIN" "4 $A"; do
  read -r n sha <<<"$p"
  git -C "$REMOTE_DIR" update-ref "refs/pull/$n/head" "$sha"
done

# The `gh` stand-in, first on PATH: the state of each pull request, from a
# file, and a failure for one it does not know.
mkdir -p "$BIN"
cat > "$BIN/gh" <<'EOF'
#!/bin/bash
case "$1 $3 $4" in
  "api --jq .state")
    state=$(sed -n "s#^${2##*/} ##p" "$GH_STATES")
    [ -n "$state" ] || { echo "gh: HTTP 404" >&2; exit 1; }
    echo "$state"
    ;;
  "api --jq length")
    # The open pull requests whose head is the branch named, from a file of branch names; one marked broken fails.
    b=${2##*:}
    grep -qx "broken" "$GH_OPEN" && { echo "gh: HTTP 502" >&2; exit 1; }
    grep -cx "$b" "$GH_OPEN" || true
    ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$BIN/gh"
export GH_STATES=$SCRATCH/states GH_OPEN=$SCRATCH/open
: > "$SCRATCH/open"
printf '1 closed\n2 open\n3 closed\n' > "$GH_STATES"
export PATH="$BIN:$PATH" REPO=test/repo GITHUB_STEP_SUMMARY=$SCRATCH/summary

run() { "$HERE/delete-branch.sh" "$@" 2>&1 && echo "EXIT=0" || echo "EXIT=$?"; }
tip() { git ls-remote origin "refs/heads/$1" | cut -f1; }

echo "=== 1. usage errors"
for args in "a" "x-fwd-y-fwd-z" "a-fwd-fwd-b" "a 1 2" "-a 1" "a..b 1" "a 0" "a 01" "a -1" "a 1x" "'' 1"; do
  eval "set -- $args"
  out=$(run "$@")
  has "'$args' is a usage error" "$out" "EXIT=2"
done

echo "=== 2. a missing branch and the default branch"
out=$(run nope 1)
has "a missing branch is refused" "$out" "refused, nope is kept: no such branch in test/repo"
has "with exit 1" "$out" "EXIT=1"
out=$(run main 3)
has "the default branch is refused, even at a closed pull request's head" "$out" "refused, main is kept: it is the default branch"

echo "=== 3. no head, another head"
out=$(run a 9)
has "a pull request without a head ref is refused" "$out" "pull request #9 has no head in test/repo"
out=$(run b 1)
has "a head that is not the tip is refused" "$out" "its tip $B is not the head of pull request #1, $A"

echo "=== 4. an open pull request, an unknown state"
out=$(run b 2)
has "an open pull request is refused" "$out" "pull request #2 is open; deleting its head branch would close it"
is "and its branch kept" "$(tip b)" "$B"
out=$(run a 4)
has "a state that cannot be read is refused" "$out" "the state of pull request #4 could not be read"

echo "=== 5. a branch at a closed pull request's head"
: > "$GITHUB_STEP_SUMMARY"
out=$(run a 1)
has "is deleted" "$out" "EXIT=0"
is "and gone" "$(tip a)" ""
has "the summary says so" "$(cat "$GITHUB_STEP_SUMMARY")" \
  "delete-branch: deleted a at $A, the head of closed pull request #1 in test/repo"
: > "$GITHUB_STEP_SUMMARY"
out=$(run b 1)
has "a refusal is in the summary too" "$(cat "$GITHUB_STEP_SUMMARY")" "refused, b is kept"

echo "=== 6. a branch that moves after the read"
git push -q origin "$A:refs/heads/a"
# A git first on PATH that moves the branch just before the push, after the script read its tip.
mkdir -p "$SCRATCH/movebin"
cat > "$SCRATCH/movebin/git" <<EOF
#!/bin/bash
if [ "\$1" = push ]; then $(command -v git) -C "$REMOTE_DIR" update-ref refs/heads/a $B; fi
exec $(command -v git) "\$@"
EOF
chmod +x "$SCRATCH/movebin/git"
out=$(PATH="$SCRATCH/movebin:$PATH" run a 1)
has "the leased deletion is refused" "$out" "push rejected (lease, protection or ruleset); see the log above"
is "and the moved branch is kept" "$(tip a)" "$B"

echo "=== 7. a forward's branch at its twin's tip"
git push -q -f origin "$A:refs/heads/v9.9-x-fwd-green" "$A:refs/heads/v9.9-x-green" "$A:refs/heads/main-fwd-green" \
  "$B:refs/heads/main-green" "$A:refs/heads/v9.9-x-fwd-dev"
: > "$GITHUB_STEP_SUMMARY"
out=$(run v9.9-x-fwd-green)
has "is deleted without a pull request" "$out" "EXIT=0"
is "and gone" "$(tip v9.9-x-fwd-green)" ""
has "the summary names the twin" "$(cat "$GITHUB_STEP_SUMMARY")" \
  "delete-branch: deleted v9.9-x-fwd-green at $A, the tip of its twin v9.9-x-green in test/repo"
is "and the twin stays" "$(tip v9.9-x-green)" "$A"
out=$(run main-fwd-green)
has "a twin at another tip is refused" "$out" "its tip $A is not the tip of its twin main-green, $B"
is "and the branch kept" "$(tip main-fwd-green)" "$A"
out=$(run v9.9-x-fwd-dev)
has "a missing twin is refused" "$out" "its twin v9.9-x-dev does not exist in test/repo"
out=$(run a)
has "a name without -fwd- is a usage error" "$out" "only a forward's branch, holding '-fwd-', can be deleted, not 'a'"
out=$(run x-fwd-y-fwd-z)
has "and so is one with -fwd- twice" "$out" "'x-fwd-y-fwd-z' holds '-fwd-' more than once"
out=$(run a-fwd-fwd-b)
has "even overlapping" "$out" "'a-fwd-fwd-b' holds '-fwd-' more than once"
git push -q -f origin "$A:refs/heads/v9.9-x-fwd-build" "$A:refs/heads/v9.9-x-build"
echo v9.9-x-fwd-build > "$GH_OPEN"
out=$(run v9.9-x-fwd-build)
has "a branch at its twin's tip that an open pull request has as its head is refused" "$out" \
  "an open pull request has it as its head; deleting it would close that pull request"
echo broken > "$GH_OPEN"
out=$(run v9.9-x-fwd-build)
has "and so is one where that cannot be read" "$out" "whether an open pull request has v9.9-x-fwd-build as its head could not be read"
is "and the branch is kept" "$(tip v9.9-x-fwd-build)" "$A"
: > "$GH_OPEN"
# The twin moves forward between the read and the push, as a series ref does: the tip stays in its history.
git push -q -f origin "$B:refs/heads/main-green" "$A:refs/heads/main-fwd-green"
git push -q -f origin "$A:refs/heads/main-green"
cat > "$SCRATCH/movebin/git" <<EOF
#!/bin/bash
if [ "\$1" = push ]; then $(command -v git) -C "$REMOTE_DIR" update-ref refs/heads/main-green $B; fi
exec $(command -v git) "\$@"
EOF
out=$(PATH="$SCRATCH/movebin:$PATH" run main-fwd-green)
has "a twin that moves forward after the read does not stop the deletion" "$out" "EXIT=0"
is "and the deleted tip is in the twin's history" "$(git -C "$REMOTE_DIR" merge-base --is-ancestor "$A" main-green && echo yes)" yes

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
