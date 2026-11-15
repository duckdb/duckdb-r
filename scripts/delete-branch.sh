#!/bin/bash
# Delete a branch only where something that stays proves the deletion loses
# nothing: a closed pull request's head in the same repository at the branch's
# tip, which GitHub keeps as `refs/pull/<n>/head` for as long as the pull
# request exists, or, for a forward's branch, its twin at the same tip.
#
# .github/workflows/delete-branch.yaml runs it on dispatch, for a cloud
# session whose git proxy refuses a deletion; why, and what it is for:
# handbook/branches/model/README.md.
#
# **The proof**, one of two, both decided by `pinned_by` below:
#   - with a <pr>, that pull request's head is the branch's tip, and the pull
#     request is closed, since deleting its head branch would close it;
#   - without one, the branch is a forward's, its name holding `-fwd-` exactly
#     once, and its twin, the same name with that `-fwd-` replaced by `-`
#     (`v2.0-cyanoptera-fwd-green` and `v2.0-cyanoptera-green`), is at the same
#     tip: what a cutover leaves, which swaps the series' refs to the forward's
#     tips. The twin is derived from the name, never passed in, so no other
#     branch can serve as the proof.
#
# **What it refuses**, each before anything is pushed, with exit 1 and the
# reason in the step summary: a branch that does not exist, the repository's
# default branch, or a default branch that cannot be read; with a <pr>, a
# pull request whose head ref does not exist, whose head is not the branch's
# tip, or that is not closed or whose state cannot be read; without one, a
# twin that does not exist or is at another tip, or an open pull request whose
# head is the branch, or one that cannot be ruled out.
# The branch and its proof are read with one `git ls-remote`. The deletion is
# leased on the branch tip read, so a branch that moved since is not deleted.
# The proof is not leased: a pull request reopened between the read of its
# state and the push is closed by the deletion, its commits staying under its
# `refs/pull/<n>/head`, and a twin that moves after the read takes the tip
# along only where it moves forward, as the series refs do.
#
# Usage:
#   scripts/delete-branch.sh <branch> [<pr>]
#     <branch>  the branch's name without `refs/heads/`, a valid ref name
#               that does not start with `-`, and without <pr> one holding
#               `-fwd-` exactly once
#     <pr>      the pull request's number, a positive whole number
#   Anything else is a usage error, exit 2, before anything is read.
#
# Environment variables:
#   GH_TOKEN  - token with pull-requests:read on REPO (required by `gh` with a
#               <pr>)
#   REPO      - the repository, `owner/repo`, whose pull request's state is
#               read (default: $GITHUB_REPOSITORY)
#   REMOTE    - the git remote of that repository, which takes the deletion
#               (default: origin)
#
# Exit status: 0 deleted; 1 refused; 2 a usage error.

set -euo pipefail

REMOTE="${REMOTE:-origin}"

report() {
  echo "$*"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n\n' "$*" >> "${GITHUB_STEP_SUMMARY}"
  fi
}
refuse() {
  report "delete-branch: refused, ${branch} is kept: $*"
  exit 1
}
usage() {
  echo "delete-branch: $*" >&2
  echo "usage: delete-branch.sh <branch> [<pr>]" >&2
  exit 2
}

[ $# -eq 1 ] || [ $# -eq 2 ] || usage "expected one or two arguments, got $#"
branch=$1
pr=${2-}
# The inputs come from a dispatch, so they are checked before they reach a command.
case "${branch}" in
  -* | '') usage "the branch name must not be empty or start with '-'" ;;
esac
git check-ref-format "refs/heads/${branch}" || usage "'${branch}' is not a valid branch name"
if [ $# -eq 2 ]; then
  [[ "${pr}" =~ ^[1-9][0-9]{0,8}$ ]] || usage "the pull request must be a positive whole number, not '${pr}'"
  proof="refs/pull/${pr}/head"
  named="the head of pull request #${pr}"
else
  # Occurrences of `-fwd-`, overlapping ones included, as in `a-fwd-fwd-b`: each strip keeps the dash that ends one.
  rest=${branch} count=0
  while [[ "${rest}" == *-fwd-* ]]; do rest=${rest#*-fwd} count=$((count + 1)); done
  case "${count}" in
    1) ;;
    0) usage "without a pull request, only a forward's branch, holding '-fwd-', can be deleted, not '${branch}'" ;;
    *) usage "'${branch}' holds '-fwd-' more than once, so it has no one twin" ;;
  esac
  twin=${branch/-fwd-/-}
  proof="refs/heads/${twin}"
  named="the tip of its twin ${twin}"
fi
REPO="${REPO:-${GITHUB_REPOSITORY:?REPO or GITHUB_REPOSITORY is required}}"

# Whether the proof's tip, a pull request's head or the twin's tip, shows that
# deleting the branch loses nothing: the branch's tip is that tip. The one
# check of what pins a branch.
pinned_by() { # <branch tip> <proof tip>
  [ "$1" = "$2" ]
}

# The default branch, the branch and its proof. Only exact names count, since
# `git ls-remote` matches a pattern against the end of a ref name.
default=$(git ls-remote --symref "${REMOTE}" HEAD | sed -n 's#^ref: refs/heads/\(.*\)\tHEAD$#\1#p')
[ -n "${default}" ] || refuse "the default branch of ${REPO} could not be read"
[ "${branch}" != "${default}" ] || refuse "it is the default branch"
tips=$(git ls-remote "${REMOTE}" "refs/heads/${branch}" "${proof}")
tip=$(awk -v r="refs/heads/${branch}" '$2 == r { print $1 }' <<<"${tips}")
held=$(awk -v r="${proof}" '$2 == r { print $1 }' <<<"${tips}")
[ -n "${tip}" ] || refuse "no such branch in ${REPO}"
if [ -n "${pr}" ]; then
  [ -n "${held}" ] || refuse "pull request #${pr} has no head in ${REPO}"
else
  [ -n "${held}" ] || refuse "its twin ${twin} does not exist in ${REPO}"
fi
pinned_by "${tip}" "${held}" || refuse "its tip ${tip} is not ${named}, ${held}"

if [ -n "${pr}" ]; then
  state=$(gh api "repos/${REPO}/pulls/${pr}" --jq .state) || state=''
  case "${state}" in
    closed) named="the head of closed pull request #${pr}" ;;
    '') refuse "the state of pull request #${pr} could not be read" ;;
    *) refuse "pull request #${pr} is ${state}; deleting its head branch would close it" ;;
  esac
else
  # A twin proves the commits safe, but an open pull request from the branch would still be closed by its deletion.
  open=$(gh api "repos/${REPO}/pulls?state=open&head=${REPO%%/*}:$(jq -rn --arg b "${branch}" '$b | @uri')" --jq length) ||
    open=''
  case "${open}" in
    0) ;;
    '' | *[!0-9]*) refuse "whether an open pull request has ${branch} as its head could not be read" ;;
    *) refuse "an open pull request has it as its head; deleting it would close that pull request" ;;
  esac
fi

if ! git push --force-with-lease="refs/heads/${branch}:${tip}" "${REMOTE}" ":refs/heads/${branch}"; then
  refuse "push rejected (lease, protection or ruleset); see the log above"
fi
report "delete-branch: deleted ${branch} at ${tip}, ${named} in ${REPO}"
