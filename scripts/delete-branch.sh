#!/bin/bash
# Delete a branch only where a closed pull request's head in the same
# repository is the branch's tip, so the deletion loses nothing: GitHub keeps
# `refs/pull/<n>/head` for as long as the pull request exists.
#
# .github/workflows/delete-branch.yaml runs it on dispatch, for a cloud
# session whose git proxy refuses a deletion; why, and what it is for:
# handbook/branches/model/README.md.
#
# **What it refuses**, each before anything is pushed, with exit 1 and the
# reason in the step summary:
#   - a branch that does not exist, or is the repository's default branch, or
#     a default branch that cannot be read;
#   - a pull request whose head ref does not exist;
#   - a pull request whose head is not the branch's tip (`pinned_by` below,
#     the one place that decides what proves the deletion loses nothing);
#   - a pull request that is not closed, since deleting its head branch would
#     close it, or whose state cannot be read.
# Both tips are read with one `git ls-remote`. The deletion is leased on the
# branch tip read, so a branch that moved since is not deleted.
#
# Usage:
#   scripts/delete-branch.sh <branch> <pr>
#     <branch>  the branch's name without `refs/heads/`, a valid ref name
#               that does not start with `-`
#     <pr>      the pull request's number, a positive whole number
#   Anything else is a usage error, exit 2, before anything is read.
#
# Environment variables:
#   GH_TOKEN  - token with pull-requests:read on REPO (required by `gh`)
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
  echo "usage: delete-branch.sh <branch> <pr>" >&2
  exit 2
}

[ $# -eq 2 ] || usage "expected two arguments, got $#"
branch=$1
pr=$2
# The inputs come from a dispatch, so they are checked before they reach a command.
case "${branch}" in
  -* | '') usage "the branch name must not be empty or start with '-'" ;;
esac
git check-ref-format "refs/heads/${branch}" || usage "'${branch}' is not a valid branch name"
[[ "${pr}" =~ ^[1-9][0-9]{0,8}$ ]] || usage "the pull request must be a positive whole number, not '${pr}'"
REPO="${REPO:-${GITHUB_REPOSITORY:?REPO or GITHUB_REPOSITORY is required}}"

# Whether the head of a pull request proves that deleting the branch loses
# nothing: the branch's tip is that head. The one check of what pins a branch.
pinned_by() { # <branch tip> <pull request head>
  [ "$1" = "$2" ]
}

# The default branch and both tips. Only exact names count, since
# `git ls-remote` matches a pattern against the end of a ref name.
default=$(git ls-remote --symref "${REMOTE}" HEAD | sed -n 's#^ref: refs/heads/\(.*\)\tHEAD$#\1#p')
[ -n "${default}" ] || refuse "the default branch of ${REPO} could not be read"
[ "${branch}" != "${default}" ] || refuse "it is the default branch"
tips=$(git ls-remote "${REMOTE}" "refs/heads/${branch}" "refs/pull/${pr}/head")
tip=$(awk -v r="refs/heads/${branch}" '$2 == r { print $1 }' <<<"${tips}")
head=$(awk -v r="refs/pull/${pr}/head" '$2 == r { print $1 }' <<<"${tips}")
[ -n "${tip}" ] || refuse "no such branch in ${REPO}"
[ -n "${head}" ] || refuse "pull request #${pr} has no head in ${REPO}"
pinned_by "${tip}" "${head}" ||
  refuse "its tip ${tip} is not the head ${head} of pull request #${pr}"

state=$(gh api "repos/${REPO}/pulls/${pr}" --jq .state) || state=''
case "${state}" in
  closed) ;;
  '') refuse "the state of pull request #${pr} could not be read" ;;
  *) refuse "pull request #${pr} is ${state}; deleting its head branch would close it" ;;
esac

if ! git push --force-with-lease="refs/heads/${branch}:${tip}" "${REMOTE}" ":refs/heads/${branch}"; then
  refuse "the leased deletion was rejected; the branch may have moved since ${tip} was read"
fi
report "delete-branch: deleted ${branch} at ${tip}, the head of closed pull request #${pr} in ${REPO}"
