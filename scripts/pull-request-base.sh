#!/bin/bash
# Fail a pull request to `main` that belongs on the oldest active release
# branch, by the rule handbook/operations/review/README.md owns: a change
# targets that branch and reaches `main` by a forward merge, unless it concerns
# only the line `main` previews or changes nothing but the tooling every series
# takes from `main`.
#
# .github/workflows/pull-request-base.yaml runs it on the pull requests to
# `main` in the canonical repository, with what GitHub's API says about the
# pull request and its files; what the guard is for:
# handbook/operations/ci/workflows/README.md.
#
# **It passes** a pull request whose base is not `main`, and one to `main`
# that meets one of four conditions, decided by `belongs_on_main` below:
#   - its head is a forward merge's, `forward/<branch>-<version>`
#     (.claude/skills/series-land/SKILL.md);
#   - its head is a landing's review, `<line>-land-review` with or without a
#     suffix (scripts/series-land.sh);
#   - it carries the label `next-line-only`, for a change that concerns only
#     the line `main` previews, or tooling together with the handbook pages
#     that describe it;
#   - every file it changes, and every old path of a file it renames, lies
#     under `series_tooling` (scripts/series-config.sh).
# It passes too where the declaration names no active release branch
# (`series_release_branches`, scripts/series-lib.sh), since `main` is then the
# only base there is.
#
# **It fails** every other pull request to `main`, naming the oldest active
# release branch and the three ways on: retarget it, split the tooling out, or
# add the label. The reason goes to stdout, to the step summary and, as one
# line, to an error annotation on the run.
#
# A file list shorter than the count of changed files the pull request reports
# is never read as tooling-only: GitHub lists 3000 files at most, and the
# vendored engine alone holds more.
#
# Usage:
#   scripts/pull-request-base.sh <pull> <files>
#     <pull>   the pull request, as `gh api repos/<repo>/pulls/<n>` prints it
#     <files>  its files, as `gh api --paginate repos/<repo>/pulls/<n>/files`
#              prints them: one array per page
#   Anything else is a usage error, exit 2, and so is a file that does not
#   hold that JSON.
#
# Environment variables:
#   SERIES_YAML - the declaration the release branches are read from
#                 (default: series.yaml beside this script)
#
# Exit status: 0 the pull request may stay where it is; 1 it belongs on a
# release branch; 2 a usage error, or a declaration that cannot be read.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
SERIES_YAML="${SERIES_YAML:-${here}/series.yaml}"
# shellcheck source=series-lib.sh
. "${here}/series-lib.sh"

label=next-line-only
leaf=handbook/operations/review/README.md

report() {
  echo "$*"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n\n' "$*" >> "${GITHUB_STEP_SUMMARY}"
  fi
}
usage() {
  echo "pull-request-base: $*" >&2
  echo "usage: pull-request-base.sh <pull> <files>" >&2
  exit 2
}

[ $# -eq 2 ] || usage "expected two arguments, got $#"
pull=$1
files=$2
[ -r "${pull}" ] || usage "cannot read the pull request from '${pull}'"
[ -r "${files}" ] || usage "cannot read its files from '${files}'"

field() { # <jq filter> -> its raw value from the pull request
  jq -er "$1" "${pull}" 2>/dev/null || usage "'${pull}' holds no $1"
}
number=$(field .number)
base_ref=$(field .base.ref)
head_ref=$(field .head.ref)
counted=$(field .changed_files)
labels=$(field '[.labels[].name] | join("\n")')
# A rename counts at both paths: moving a file into the tooling moves it out of somewhere else.
changed=$(jq -r '.[] | .filename, (.previous_filename // empty)' "${files}" 2>/dev/null) ||
  usage "'${files}' does not hold the files API's output"
listed=$(jq -n '[inputs[]] | length' "${files}")
outside=$(grep -vE "$(series_tooling_re)" <<<"${changed}" || true)

# Why the pull request may stay on `main`, empty when it may not: the one place
# the four conditions are decided.
belongs_on_main() {
  case "${head_ref}" in
    forward/*) echo "its head ${head_ref} is a forward merge's"; return ;;
    *-land-review*) echo "its head ${head_ref} is a landing's review"; return ;;
  esac
  if grep -qxF "${label}" <<<"${labels}"; then
    echo "it carries the label ${label}"
  elif [ "${listed}" -ge "${counted}" ] && [ -z "${outside}" ]; then
    echo "it changes nothing but the tooling (${series_tooling[*]})"
  fi
}

if [ "${base_ref}" != main ]; then
  report "pull-request-base: #${number} targets ${base_ref}, not main; nothing to check."
  exit 0
fi
why=$(belongs_on_main)
if [ -n "${why}" ]; then
  report "pull-request-base: #${number} may target main: ${why}."
  exit 0
fi

[ -r "${SERIES_YAML}" ] || usage "cannot read the declaration '${SERIES_YAML}'"
oldest=$(series_release_branches < "${SERIES_YAML}" | sed -n 1p)
if [ -z "${oldest}" ]; then
  report "pull-request-base: #${number} may target main: ${SERIES_YAML##*/} declares no active release branch."
  exit 0
fi

if [ "${listed}" -lt "${counted}" ]; then
  found="GitHub lists ${listed} of its ${counted} changed files, so it cannot be read as tooling-only."
else
  n=$(grep -c . <<<"${outside}")
  found="It changes ${n} file(s) outside the tooling every series takes from main (${series_tooling[*]}):"
  # shellcheck disable=SC2016  # Markdown code spans, not a command
  found+=$'\n'$(head -n 10 <<<"${outside}" | sed 's/^/  - `/; s/$/`/')
  [ "${n}" -le 10 ] || found+=$'\n'"  - and $((n - 10)) more"
fi
echo "::error title=pull-request-base::#${number} targets main but belongs on ${oldest}:" \
  "retarget it, split its tooling out, or add the label ${label}; the job summary says how."
# One report per paragraph, so the step summary's Markdown keeps the lists apart.
report "pull-request-base: #${number} targets main, but belongs on ${oldest}, the oldest active release branch (${leaf})."
report "${found}"
report "Either:
  - retarget it to ${oldest}, with Edit beside the title, after rebasing its branch onto ${oldest} if it started from main;
  - split it: the tooling in a pull request to main, the rest in one to ${oldest};
  - or, if it concerns only the line main previews, or is tooling with the handbook pages that describe it, add the label ${label}."
exit 1
