#!/bin/bash
# Read-only diagnosis for the series loop: what should a firing do?
#
# For every series (or the ones named), walks `<S>-green..<S>-dev`, looks each
# commit up in the verdict store on branch `rcc2` (read via `git show`, no
# checkout of it), classifies failures by what their log CONTAINS, and prints
# one verdict per series:
#
#   ADVANCE            every in-flight commit has a success run
#   WAIT               runs still missing from the harvest (age of harvest shown);
#                      green holds, but the buffer may still extend onto -dev
#   RETRY <sha> <why>  the oldest failure, and nothing in the commit caused it
#   REPAIR <sha> <why>  the oldest failure and its classification
#
# A forward series that has caught up with the green it replaces additionally
# gets a CUTOVER line: the command to run, for a human to run. The loop never
# swaps a serving green itself (.claude/skills/series-loop.md).
#
# Classification is by positive evidence only (.claude/skills/series-loop.md);
# "Job is waiting for a hosted runner" appears in every log and means nothing.
#
# The record decides before the log does, for the one thing the log cannot say:
# a commit the shard's `timeout` killed at its budget (exit 124) stops mid-run
# with its stage output still buffered, which reads exactly like a cancelled
# leg. That is a REPAIR — the commit did not finish — and calling it transient
# spends another whole budget to learn the same thing.
#
# RETRY and REPAIR split on the retry ledger: `retry-<S>-dev` pointing at the
# failing commit means it has already had its one rerun, so a failure that still
# looks transient is not, and the verdict is REPAIR regardless. The branch
# pointing anywhere else is a spent retry of some earlier commit, and says
# nothing about this one.
#
# The ledger only decides once the rerun has reported. The retry pair rewrites
# nothing, so the pre-retry `failure` record survives on the same SHA until the
# rerun's own record replaces it; reading the ref alone turns a rerun that is
# still building into REPAIR, and invites amending a commit that is about to go
# green. The harvested run's `head_branch` is what tells the two apart.
#
# Usage: series-check.sh [<series>...]     # default: discover all from refs

set -euo pipefail

remote=origin
rcc=${RCC_BRANCH:-rcc2}
git fetch -q "$remote"

rcc_tip() { git rev-parse -q --verify "refs/remotes/$remote/$rcc" 2>/dev/null; }

# See scripts/series-advance.sh: the pathspec narrows the walk, the subject
# decides, and an empty answer explains itself on stderr.
vendored_sha() {
  local subjects sha n
  subjects=$(git log -n 20 --format=%s "$1" -- src/duckdb || true)
  sha=$(sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p' <<<"$subjects" | head -n 1)
  if [ -z "$sha" ]; then
    n=$(grep -c . <<<"$subjects" || true)
    if [ "$n" -ge 20 ]; then
      echo "vendored_sha: 20 src/duckdb commits on $1, none of them vendoring;" >&2
      echo "  if that is genuine, raise the bound in this helper" >&2
    else
      echo "vendored_sha: no vendor commit among $n src/duckdb commits on $1" >&2
    fi
  fi
  echo "$sha"
}

# The store's record for a commit: one small blob, published by the matrix leg
# seconds after it decided the commit. One read for every question below, so they
# cannot disagree about which verdict they are describing — which they could
# while the same record lived both in a per-commit part and in an aggregate line
# that caught up later.
record_of() { # <sha> -> the record, empty if the store has none
  git show "$remote/$rcc:runs2.d/${1:0:2}/$1.ndjson" 2>/dev/null || true
}

record_field() { # <sha> <sed expression> -> the first match, empty if none
  local rec
  rec=$(record_of "$1")
  [ -z "$rec" ] && return
  sed -nr "$2" <<<"$rec" | head -n 1
}

state_of() { # <sha> -> success|failure|pending|missing
  local rec
  rec=$(record_of "$1")
  [ -z "$rec" ] && { echo missing; return; }
  sed -nr 's/.*"status":[^}]*"state": *"([a-z]+)".*/\1/p' <<<"$rec" | head -n 1
}

# The branch the harvested record's run was triggered on. This is what tells a
# spent rerun from one still in flight: the retry pair rewrites nothing, so the
# pre-retry record survives on the same SHA until the rerun's replaces it.
run_branch_of() { # <sha> -> head_branch of the harvested run, empty if none
  record_field "$1" 's/.*"head_branch": *"([^"]*)".*/\1/p'
}

# The shard's own verdict on how the commit ended. `timeout` in
# scripts/each-shard.sh reports 124 when it kills rcc-one.sh at the budget, and
# that is the one thing the log cannot say: the killed stage buffers its output
# through run_stage and loses it, so the log simply stops mid-run and reads like
# a cancelled leg. Without this the log rules below call a commit that ran out
# of budget `transient` and the loop reruns it, which costs another full budget
# to learn the same thing.
exit_code_of() { # <sha> -> exit code the shard recorded, empty if none
  record_field "$1" 's/.*"exit_code": *([0-9]+).*/\1/p'
}

duration_of() { # <sha> -> seconds the shard spent on it, empty if none
  record_field "$1" 's/.*"duration_seconds": *([0-9]+).*/\1/p'
}

# Positive evidence that a gate reached out over the network and was refused.
# Checked only after the tree-shaped classifications above it, so a real test
# failure that happens to mention a URL is not mistaken for a flake.
net_re="cannot open URL|SSL connect error|Could not resolve host"
net_re="$net_re|Connection (timed out|refused|reset)|Timeout was reached"
net_re="$net_re|Failed to connect|curl: \([0-9]+\)|50[234] (Bad Gateway|Service Unavailable|Gateway Time-out)"

failed_gate() { # <log> -> name of the first gate rcc-one.sh's summary marks FAIL
  grep -oE '^\| [A-Za-z0-9_-]+ \| FAIL ' <<<"$1" | head -1 | awk '{print $2}'
}

last_gate() { # <log> -> the gate rcc-one.sh opened last, i.e. where it stopped
  grep -oE '^::group::gate: [a-z]+' <<<"$1" | tail -1 | awk '{print $NF}'
}

classify() { # <sha> -> "<kind>|<one line>"; kind `transient` means rerun, do not repair
  local log gate rc
  log=$(git show "$remote/$rcc:logs2.d/${1:0:2}/$1.log" 2>/dev/null || true)
  [ -z "$log" ] && { echo "unknown|failure, no log harvested yet"; return; }
  # Budget first, and ahead of every log rule: a commit the shard killed never
  # reached a verdict on its own content, so whatever the log shows is what it
  # got through, not what went wrong. Rerunning it buys the same kill again.
  rc=$(exit_code_of "$1")
  if [ "$rc" = 124 ]; then
    gate=$(last_gate "$log")
    echo "budget|killed at the shard budget after $(duration_of "$1")s," \
      "stuck in the ${gate:-unnamed} gate — not a flake, it did not finish"
    return
  fi
  # The same thing one level down: scripts/rcc-one.sh bounds each stage, so a
  # stuck gate is now killed on its own and the leg lives to report it. The leg
  # then exits 1 like any failure, and only this line says the stage ran out of
  # time rather than failing on its merits.
  if grep -q "exceeded its .* budget -- presumed stuck" <<<"$log"; then
    echo "budget|$(grep -oE "stage [a-z]+: exceeded its [0-9]+s budget" <<<"$log" | head -1)" \
      "— the gate did not finish, rerunning it buys the same kill"
    return
  fi
  if grep -qE "Updating snapshots: '" <<<"$log"; then
    echo "snapshot|snapshot drift ($(grep -oE "Updating snapshots: [^.]*" <<<"$log" | head -1))"
  elif grep -qE "Error \('test-[^']+'\)" <<<"$log"; then
    echo "test|test failure ($(grep -oE "Error \('test-[^']+'\)" <<<"$log" | head -1))"
  elif grep -q "Changes detected in workflow_dispatch build" <<<"$log"; then
    echo "style|style/roxygen drift"
  elif grep -qE "$net_re" <<<"$log"; then
    gate=$(failed_gate "$log")
    echo "transient|network failure in the ${gate:-unnamed} gate ($(grep -oE "$net_re" <<<"$log" | head -1))"
  elif ! grep -q "test_local\|testthat" <<<"$log"; then
    echo "transient|cancelled or infra (no test phase in log)"
  else
    echo "unknown|unclassified: review logs2.d/${1:0:2}/$1.log on branch $rcc by hand"
  fi
}

series=("$@")
if [ ${#series[@]} -eq 0 ]; then
  while IFS= read -r b; do
    s=${b#refs/heads/}; s=${s%-build}
    case "$s" in *-build-base) continue ;; esac
    git rev-parse -q --verify "refs/remotes/$remote/$s-dev" >/dev/null && series+=("$s")
  done < <(git ls-remote --heads "$remote" '*-build' | cut -f2)
fi

tip=$(rcc_tip) || { echo "no $rcc branch on $remote"; exit 1; }
echo "harvest: $(git log -1 --format='%ci (%ar)' "$tip")"
echo

for S in "${series[@]}"; do
  green="$remote/$S-green"; dev="$remote/$S-dev"; build="$remote/$S-build"
  for r in "$green" "$dev" "$build"; do
    git rev-parse -q --verify "$r" >/dev/null || { echo "$S: missing ${r#"$remote"/}, skipping"; continue 2; }
  done
  # cutover litter: a forward series whose green is an ancestor of its base's
  # (the base moves on after cutover, so equality cannot be the test)
  cutover=""
  case "$S" in *-fwd)
    base=${S%-fwd}
    if git rev-parse -q --verify "$remote/$base-green" >/dev/null; then
      if git merge-base --is-ancestor "$green" "$remote/$base-green"; then
        echo "$S: green is an ancestor of $base's — cutover litter, ignoring"; continue
      fi
      # Ready to cut over once the forward green vendors the upstream commit the
      # base green vendors: coverage may never regress. Tested by subject, like
      # every other equivalence here, and bounded by the mainline the forward
      # seed was built on — `main`'s own vendor commits sit below that seed and
      # must not answer for the forward chain. A base green that vendors nothing
      # asks for no coverage, exactly as in series-cutover.sh.
      base_up=$(vendored_sha "$remote/$base-green")
      # Collected, not piped into grep: `grep -q` leaves early, and under
      # `pipefail` the SIGPIPE it hands `git log` would read as a failed test.
      fwd_vendored=$(git log --format=%s "$remote/main..$green" -- src/duckdb || true)
      if [ -z "$base_up" ] || grep -q "duckdb@$base_up" <<<"$fwd_vendored"; then
        cutover=$base
      fi
    fi ;;
  esac

  inflight=$(git rev-list --count "$green..$dev")
  # the buffer counts from -dev's consumption anchor on -build: the -dev tip
  # while it sits on -build's line, otherwise the -build commit equivalent to
  # -dev's newest vendor commit — the identical rule, and the identical reasons,
  # as the anchor in scripts/series-advance.sh.
  mb=$(git merge-base "$dev" "$build")
  if [ "$mb" = "$(git rev-parse "$dev")" ]; then
    buffered=$(git rev-list --count "$dev..$build")
  else
    dev_up=$(vendored_sha "$dev")
    anchor=$(git log --format='%H %s' "$build" | grep -m 1 "duckdb@${dev_up:-NONE}" | cut -d' ' -f1 || true)
    if [ -n "$anchor" ]; then
      buffered=$(git rev-list --count "$anchor..$build")
    else
      buffered="?"
    fi
  fi
  echo "=== $S: $inflight in flight, $buffered buffered, green=$(git rev-parse --short "$green") dev=$(git rev-parse --short "$dev")"

  verdict="ADVANCE" oldest="" why="" missing=0
  while IFS= read -r sha; do
    st=$(state_of "$sha")
    case "$st" in
      success) ;;
      missing|pending) missing=$((missing + 1)) ;;
      *) oldest="$sha"; why=$(classify "$sha") ;;   # keep last seen = oldest (list is newest-first)
    esac
  done < <(git rev-list "$green..$dev")

  if [ -n "$oldest" ]; then
    kind=${why%%|*}; desc=${why#*|}
    retried=$(git rev-parse -q --verify "refs/remotes/$remote/retry-$S-dev" || true)
    if [ "$retried" = "$oldest" ]; then
      if [ "$(run_branch_of "$oldest")" = "retry-$S-dev" ]; then
        echo "  REPAIR $oldest"
        echo "         $desc"
        echo "         retry-$S-dev reported on this commit: the rerun was spent, this failure is real"
      else
        echo "  WAIT   retry-$S-dev is on this commit, rerun not harvested yet"
        echo "         the record below is the pre-retry one; do not repair on it"
        echo "         $desc"
      fi
    elif [ "$kind" = transient ]; then
      echo "  RETRY  $oldest"
      echo "         $desc"
    else
      echo "  REPAIR $oldest"
      echo "         $desc"
    fi
  elif [ "$missing" -gt 0 ]; then
    # Pending verdicts hold green, not the buffer: stage 5 extends on pending
    # and stops only on red (.claude/skills/series-loop.md stage 5).
    if [ "$buffered" != 0 ]; then
      echo "  WAIT   $missing run(s) not harvested yet — green holds, buffer may still extend"
    else
      echo "  WAIT   $missing run(s) not harvested yet"
    fi
  elif [ "$inflight" -eq 0 ] && [ "$buffered" = 0 ]; then
    echo "  IDLE   nothing in flight, buffer empty — vendor"
  else
    echo "  ADVANCE"
  fi

  # Suggested, never done: a firing reports a ready cutover and stops
  # (.claude/skills/series-loop.md). Printed beside the verdict rather than as
  # one, because it is orthogonal — a forward series that has caught up still
  # needs repairing, advancing or waiting like any other.
  if [ -n "$cutover" ]; then
    echo "  CUTOVER  $S covers $cutover's green — a manual step, never a firing's:"
    echo "           scripts/series-cutover.sh $cutover $remote <upstream-clone>"
  fi
done
