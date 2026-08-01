#!/bin/bash
# shellcheck disable=SC2317  # gates are dispatched indirectly as gate_${gate}
#
# Run the per-commit `rcc` gate against the working tree, once.
#
# This is the gate set that the `rcc-smoke` job of `.github/workflows/
# R-CMD-check.yaml` applies on its per-commit `workflow_dispatch` path -- the
# path the retired per-commit dispatcher drove -- expressed as a script so that
# `scripts/each-shard.sh` can run it many times in one job. A workflow cannot
# loop over composite actions, so the gates have to be callable from a shell
# loop; this file is that seam.
#
# Deliberately a *subset* of what `rcc-smoke` does, matching what actually runs
# under `workflow_dispatch`:
#
#   | rcc-smoke step        | here                                            |
#   |-----------------------|-------------------------------------------------|
#   | versions-matrix       | skipped upstream too (workflow_dispatch, no opt-in) |
#   | dep-suggests-matrix   | skipped upstream too                            |
#   | style                 | gate `style`                                    |
#   | update-snapshots      | gate `snapshots`, incl. the snapshot-<sha> branch |
#   | roxygenize            | gate `roxygen`                                  |
#   | commit                | gate `clean` -- workflow_dispatch fails on any diff |
#   | check                 | gate `check`                                    |
#   | pkgdown-build         | gate `pkgdown`                                  |
#   | pkgdown-deploy        | skipped upstream too (push only)                |
#
# Outcome semantics mirror `rcc-smoke` exactly: every gate runs even when an
# earlier one failed, and the exit status is the AND over all of them. That is
# what makes a failing commit's log show *all* the problems, not just the first.
#
# Assumes the caller has already installed R, the package dependencies, ccache,
# and the formatting tools, and that the working tree is a clean checkout of the
# commit under test.
#
# Usage:
#   scripts/rcc-one.sh
#
# Environment variables:
#   EACH_GATES            - space-separated subset of
#                           "style snapshots roxygen clean check pkgdown"
#                           (default: all of them, parity with rcc-smoke)
#   EACH_SNAPSHOT_BRANCH  - publish the snapshot-<sha>-rcc-smoke-null branch when
#                           the snapshots gate changed anything
#                           (default: true under GITHUB_ACTIONS, false locally)
#   EACH_STAGE_DIR        - when set, each stage's combined output is also kept
#                           in <dir>/<stage>.log and its verdict appended to
#                           <dir>/outcomes.tsv, so scripts/each-shard.sh can
#                           quote the failing stage into the run summary
#   RCMDCHECK_ERROR_ON    - passed through to rcmdcheck (default: note)

set -uo pipefail

ALL_GATES="style snapshots roxygen clean check pkgdown"
GATES="${EACH_GATES:-${ALL_GATES}}"
SNAPSHOT_BRANCH="${EACH_SNAPSHOT_BRANCH:-${GITHUB_ACTIONS:-false}}"
STAGE_DIR="${EACH_STAGE_DIR:-}"

# peter-evans/create-pull-request commits as this identity by default, not as
# the repository's git config. Reproduced verbatim so the published branches stay
# byte-comparable with the ~950 the retired dispatch path created.
CPR_NAME="github-actions[bot]"
CPR_EMAIL="41898282+github-actions[bot]@users.noreply.github.com"
CPR_MESSAGE="[create-pull-request] automated change"

rscript_dir="$(mktemp -d)"
trap 'rm -rf "${rscript_dir}"' EXIT

names=()
outcomes=()
status=0

if [ -n "${STAGE_DIR}" ]; then
  mkdir -p "${STAGE_DIR}"
  : > "${STAGE_DIR}/outcomes.tsv"
fi

has_gate() {
  case " ${GATES} " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

# The per-stage verdict, in execution order. A stage that has a log here but no
# line in this file is one that never returned -- which is exactly the stage the
# leg's timeout killed, and the one worth showing.
note_stage() {
  [ -n "${STAGE_DIR}" ] || return 0
  printf '%s\t%s\n' "$1" "$2" >> "${STAGE_DIR}/outcomes.tsv"
}

record() {
  names+=("$1")
  outcomes+=("$2")
  note_stage "$1" "$2"
  [ "$2" = "failure" ] && status=1
  return 0
}

# Run one stage, keeping a copy of its combined output when EACH_STAGE_DIR is
# set. Nothing is lost by buffering it: the caller (scripts/each-shard.sh)
# already redirects the whole commit to a file and prints it once the commit is
# over, so there is no live stream here to interleave with. What is gained is a
# log that begins and ends at the stage boundary, which is what makes a useful
# excerpt -- slicing the combined log back apart would mean parsing it.
run_stage() {
  local name="$1"
  shift
  local rc=0
  if [ -z "${STAGE_DIR}" ]; then
    "$@" || rc=$?
    return "${rc}"
  fi
  "$@" > "${STAGE_DIR}/${name}.log" 2>&1 || rc=$?
  cat "${STAGE_DIR}/${name}.log"
  return "${rc}"
}

run_gate() {
  local gate="$1"
  if ! has_gate "${gate}"; then
    record "${gate}" "skipped"
    return 0
  fi
  echo "::group::gate: ${gate}"
  local outcome="success"
  if ! run_stage "${gate}" "gate_${gate}"; then
    outcome="failure"
  fi
  echo "::endgroup::"
  echo "gate ${gate}: ${outcome}"
  record "${gate}" "${outcome}"
}

# Writes an R program to a temp file and runs it, the way `shell: Rscript {0}`
# does in the workflow, so the R sources here stay byte-comparable with the
# composite actions they mirror.
rscript() {
  local file="${rscript_dir}/gate.R"
  cat > "${file}"
  Rscript "${file}"
}

# ------------------------------------------------------------------ install --
# Not a gate: `rcc-smoke` installs before the continue-on-error block, so an
# install failure ends the commit right there. Everything downstream needs the
# package loadable anyway (roxygen2, testthat, pkgdown).
echo "::group::install"
if ! run_stage install env _R_SHLIB_STRIP_=true R CMD INSTALL .; then
  note_stage install failure
  echo "::endgroup::"
  echo "install: failure -- skipping the remaining gates"
  echo "| install | failure |"
  exit 1
fi
note_stage install success
echo "::endgroup::"

# -------------------------------------------------------------------- gates --

# Mirrors .github/workflows/style/action.yml. Tool installation is the caller's
# job; this only runs the formatters.
gate_style() {
  local rc=0
  if [ -f air.toml ]; then
    air format . || rc=1
  fi
  if [ -f .clang-format ]; then
    shopt -s nullglob
    clang-format-21 -i src/*.{c,cc,cpp,h,hpp} || rc=1
    shopt -u nullglob
  fi
  git status --short
  return "${rc}"
}

# Mirrors the "Create pull request" step of
# .github/workflows/update-snapshots/action.yml, which publishes the accepted
# snapshots as a branch off the commit under test. The pull request itself never
# materialises on this path -- its base is a SHA, not a branch -- but the branch
# does, and tooling looks those up by name, so it has to keep being produced.
#
# The name is deliberately frozen rather than derived. Upstream builds it from
# `github.job` (`rcc-smoke`) and an empty matrix (`null`); here the job is
# `build` and there *is* a matrix, so deriving it the same way would silently
# rename ~950 existing branches' successors.
#
# Committed through a temporary index so the working tree keeps its diff -- the
# `clean` gate still has to see it and fail the commit.
publish_snapshot_branch() {
  if [ "${SNAPSHOT_BRANCH}" != "true" ]; then
    return 0
  fi
  if [ -z "$(git status --porcelain -- tests/testthat/_snaps)" ]; then
    return 0
  fi

  local sha branch tree commit index
  sha="$(git rev-parse HEAD)"
  branch="snapshot-${sha}-rcc-smoke-null"
  index="${rscript_dir}/snapshot-index"
  rm -f "${index}"

  # `mkdir -p` because a commit may have deleted the last snapshot, and
  # `git add` on a missing pathspec is an error.
  mkdir -p tests/testthat/_snaps

  GIT_INDEX_FILE="${index}" git read-tree HEAD || return 1
  GIT_INDEX_FILE="${index}" git add -A -- tests/testthat/_snaps || return 1
  tree="$(GIT_INDEX_FILE="${index}" git write-tree)" || return 1
  commit="$(
    GIT_AUTHOR_NAME="${CPR_NAME}" GIT_AUTHOR_EMAIL="${CPR_EMAIL}" \
    GIT_COMMITTER_NAME="${CPR_NAME}" GIT_COMMITTER_EMAIL="${CPR_EMAIL}" \
      git commit-tree "${tree}" -p "${sha}" -m "${CPR_MESSAGE}"
  )" || return 1

  echo "Publishing accepted snapshots as ${branch}"
  git push --force origin "${commit}:refs/heads/${branch}"
}

# Mirrors the "Run tests on test files that use snapshots" step of
# .github/workflows/update-snapshots/action.yml. Accepting the snapshots leaves
# the diff in the tree; the `clean` gate below is what turns it into a failure,
# exactly as the upstream `commit` step does on workflow_dispatch.
gate_snapshots() {
  local rc=0
  rscript <<'EOF' || rc=1
rx <- "^test-(.*)[.][rR]$"
files <- dir("tests/testthat", pattern = rx)
has_snapshot <- vapply(
  files,
  function(.x) any(grepl("snapshot", readLines(file.path("tests/testthat", .x)), fixed = TRUE)),
  logical(1)
)
if (any(has_snapshot)) {
  patterns <- gsub(rx, "^\\1$", files[has_snapshot])
  pattern <- paste0(patterns, collapse = "|")
  tryCatch(
    {
      Sys.setenv(TESTTHAT_PARALLEL = FALSE)
      result <- as.data.frame(testthat::test_local(pattern = pattern, reporter = "location", stop_on_failure = FALSE))
      failures <- result[result$failed + result$warning > 0, ]
      if (nrow(failures) > 0) {
        writeLines("Snapshot tests failed/warned.")
        print(failures[names(failures) != "result"])
        print(failures$result)
        testthat::snapshot_accept()
      } else {
        writeLines("Snapshot tests ran successfully.")
      }
    },
    error = print
  )
} else {
  writeLines("No snapshots found.")
}
EOF
  publish_snapshot_branch || rc=1
  return "${rc}"
}

# Mirrors .github/workflows/roxygenize/action.yml.
gate_roxygen() {
  rscript <<'EOF'
roxygen2::roxygenize()
EOF
}

# Mirrors the "Write diff and fail for workflow_dispatch" step of
# .github/workflows/commit/action.yml: on a per-commit build, any change the
# gates above produced means the commit is not canonical.
gate_clean() {
  if [ -z "$(git status --porcelain)" ]; then
    return 0
  fi
  # Wording matched to the upstream `commit` action verbatim: series-check.sh
  # classifies a failure as style/roxygen drift by grepping the harvested log
  # for this exact string.
  echo "Changes detected in workflow_dispatch build. Diff:"
  git --no-pager diff
  git status --porcelain
  return 1
}

# Mirrors r-lib/actions/check-r-package@v2 as invoked by
# .github/workflows/check/action.yml.
gate_check() {
  local rc=0
  RCMDCHECK_ERROR_ON="${RCMDCHECK_ERROR_ON:-note}" rscript <<'EOF' || rc=1
# The action's own defaults, set before the check and only when unset.
# `--as-cran` otherwise turns the CRAN incoming checks on, and a flavored
# package is not on CRAN, so every commit picks up a "New submission" NOTE.
if (Sys.getenv("_R_CHECK_FORCE_SUGGESTS_", "") == "") Sys.setenv("_R_CHECK_FORCE_SUGGESTS_" = "false")
if (Sys.getenv("_R_CHECK_CRAN_INCOMING_", "") == "") Sys.setenv("_R_CHECK_CRAN_INCOMING_" = "false")
rcmdcheck::rcmdcheck(
  args = c("--no-manual", "--as-cran", "--no-multiarch"),
  build_args = "--no-manual",
  error_on = Sys.getenv("RCMDCHECK_ERROR_ON", "note"),
  check_dir = "check"
)
EOF
  # The upstream action always shows the test output, pass or fail.
  echo "::group::Test output"
  find check -name '*.Rout*' -exec head -n 1000000 '{}' \; 2>/dev/null || true
  echo "::endgroup::"
  return "${rc}"
}

# Mirrors .github/workflows/pkgdown-build/action.yml.
gate_pkgdown() {
  rscript <<'EOF'
pkgdown::build_site()
EOF
}

for gate in style snapshots roxygen clean check pkgdown; do
  run_gate "${gate}"
done

# ----------------------------------------------------------------- summary ---
echo
echo "| Gate | Result |"
echo "| --- | --- |"
for i in "${!names[@]}"; do
  case "${outcomes[$i]}" in
    success) icon="OK" ;;
    skipped) icon="--" ;;
    *) icon="FAIL" ;;
  esac
  printf '| %s | %s %s |\n' "${names[$i]}" "${icon}" "${outcomes[$i]}"
done

exit "${status}"
