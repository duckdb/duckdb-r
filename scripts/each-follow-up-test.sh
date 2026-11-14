#!/bin/bash
# Check scripts/each-follow-up.sh, offline, against a synthetic branch, a
# synthetic store and a stand-in for `gh api` built here, and the part of
# scripts/each-plan.sh it relies on: no network, no fixtures on disk.
#
# The claim the script makes is that a run dispatches one follow-up exactly
# when the follow-up can decide something the run left undecided and the run
# decided something itself, so that a chain of follow-ups ends. Ten things are
# checked.
#
#   1. Nothing is dispatched when every commit the run planned or deferred has
#      a record, nor when the run decided none of what it set out to.
#   2. A run that made progress dispatches, with its inputs but `force`, and
#      with `follow-up-of` and `follow-up-head` of its own.
#   3. Commits deferred past the shard cap are asked of the store, not counted
#      at plan time: undecided they bring a follow-up, decided since they do not.
#   4. A branch that moved, or was deleted, since the plan brings none; neither
#      does another run waiting on the branch, while the run's own does not
#      count as waiting.
#   5. A store that cannot be reached fails the job rather than reading as
#      "nothing decided".
#   6. A forced run counts the commits it judged again as progress, by the run
#      its records name, and its follow-up does not force.
#   7. A retry tip this run did not judge again remains, and the follow-up is
#      sent without the head, so that it forces the tip; one judged again is
#      sent with it.
#   8. A dispatch refused after the branch moved ends the job quietly; one
#      refused while the branch stayed fails it.
#   9. A push's run, which has no inputs, sends only the two of its own; a dry
#      run sends nothing.
#  10. The planner forces a retry tip unless it is the follow-up's head, and
#      lists the commits it deferred past the shard cap.
#
# Usage:
#   scripts/each-follow-up-test.sh
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
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3"; echo "            in: $2" ;; esac; }

export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
unset GITHUB_STEP_SUMMARY GITHUB_OUTPUT GITHUB_REPOSITORY GITHUB_RUN_ID RUNNER_TEMP \
  DRY_RUN INPUTS EACH_DECIDED_FILE RCC_READ_DIR FORCE FOLLOW_UP_OF FOLLOW_UP_HEAD

# --- the fixture -------------------------------------------------------------
#
# The repository the run belongs to, with a series branch and its green; the
# store, a repository whose `rcc2` branch serves filters; and the clone the
# script runs in.

ORIGIN=$SCRATCH/origin.git
STORE=$SCRATCH/store.git
BUILD=$SCRATCH/build
STOREW=$SCRATCH/store
WORK=$SCRATCH/work
FAKE=$SCRATCH/fake
git init -q --bare -b main "$ORIGIN"
git init -q --bare -b rcc2 "$STORE"
git -C "$STORE" config uploadpack.allowFilter true
mkdir -p "$FAKE" "$SCRATCH/bin"

git init -q -b x-dev "$BUILD"
cd "$BUILD"
git config commit.gpgsign false
# The planner's cost estimator reads the unity objects from here; none is fine.
mkdir -p src/include
echo 'SOURCES=' > src/include/sources.mk
c() { echo "$1" > "$1.txt"; git add -A; git commit -qm "$1"; git rev-parse HEAD; }
C0=$(c seed)
C1=$(c one); C2=$(c two); C3=$(c three); C4=$(c four); C5=$(c five)
git checkout -q -b moved
C6=$(c six)
git checkout -q x-dev
git push -q "$ORIGIN" "$C0:refs/heads/x-green" "$C5:refs/heads/x-dev"
git clone -q -b x-dev "$ORIGIN" "$WORK"
move() { git -C "$BUILD" push -q -f "$ORIGIN" "$1:refs/heads/x-dev"; }

git init -q -b rcc2 "$STOREW"
git -C "$STOREW" config commit.gpgsign false
git -C "$STOREW" remote add origin "$STORE"
git -C "$STOREW" commit -q --allow-empty -m 'chore: The store'
store() { # <sha>:<run id> ... -- the store holds exactly these records
  local e sha
  rm -rf "$STOREW/runs2.d"
  for e in "$@"; do
    sha=${e%%:*}
    mkdir -p "$STOREW/runs2.d/${sha:0:2}"
    printf '{"commit":"%s","status":{"context":"rcc","state":"success"},"run":{"id":%s}}\n' \
      "$sha" "${e#*:}" > "$STOREW/runs2.d/${sha:0:2}/$sha.ndjson"
  done
  git -C "$STOREW" add -A
  git -C "$STOREW" commit -q --allow-empty -m 'chore: The store'
  git -C "$STOREW" push -q origin rcc2
}

plan() { # [head=<sha>] [without=<n>] [planned=<shas>] [replanned=<shas>] [deferred=<shas>] [retry=<sha>]
  local head=$C5 without=0 planned='' replanned='' deferred='' retry='' kv
  for kv in "$@"; do local "$kv"; done
  jq -n --arg head "$head" --argjson without "$without" --arg planned "$planned" \
    --arg replanned "$replanned" --arg deferred "$deferred" --arg retry "$retry" '
    def list($s): $s | split(" ") | map(select(length > 0));
    {branch: "x-dev", head: $head, planned_without_verdict: $without,
     commits_deferred: (list($deferred) | length), deferred_shas: list($deferred),
     replanned_despite_verdict: list($replanned), retry_tip: $retry,
     shards: [{index: 1, commits: (list($planned) | map({sha: .}))}]}' > "$SCRATCH/plan.json"
}

# The stand-in for `gh api`: the runs of the workflow from a file, filtered as
# `--jq` asks; a dispatch kept in a file, refused with the status in post-rc,
# after running the hook in on-post if there is one. Every call is logged.
cat > "$SCRATCH/bin/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "$FAKE/calls"
[ "$1" = api ] || exit 2
shift
case "$1 $2" in
  "-X GET")
    q=''
    while [ $# -gt 0 ]; do [ "$1" = --jq ] && q=$2; shift; done
    jq -r "$q" "$FAKE/runs.json"
    ;;
  "--method POST")
    cat > "$FAKE/dispatch"
    [ ! -x "$FAKE/on-post" ] || "$FAKE/on-post"
    rc=$(cat "$FAKE/post-rc" 2>/dev/null || echo 0)
    [ "$rc" = 0 ] || echo 'gh: Unexpected inputs provided: ["follow-up-head"] (HTTP 422)' >&2
    exit "$rc"
    ;;
  *) echo "gh: unexpected call: api $*" >&2; exit 2 ;;
esac
EOF
chmod +x "$SCRATCH/bin/gh"
runs() { # <id>:<status> ... -- the runs of the workflow on the branch
  local e
  for e in "$@"; do jq -nc --argjson id "${e%%:*}" --arg s "${e#*:}" '{id: $id, status: $s}'; done |
    jq -sc '{workflow_runs: .}' > "$FAKE/runs.json"
}
runs 111:in_progress

run() { # [VAR=value ...] -> the output, then EXIT=<status>; this run's calls in $FAKE/calls
  : > "$FAKE/calls"
  rm -f "$FAKE/dispatch"
  set +e
  (cd "$WORK" && env PATH="$SCRATCH/bin:$PATH" FAKE="$FAKE" GH_TOKEN=x PLAN="$SCRATCH/plan.json" \
    RUN_ID=111 RCC_REMOTE="$STORE" RCC_READ_DIR="$SCRATCH/read" "$@" "$HERE/each-follow-up.sh" 2>&1)
  echo "EXIT=$?"
  set -e
}
calls() { grep -c -- "$1" "$FAKE/calls" || true; }
sent() { jq -c . "$FAKE/dispatch" 2>/dev/null || echo none; }
body() { # [<non-empty: without the head>] [<the run's inputs passed on, as JSON>] -> the dispatch expected
  local nohead=${1:-} x=${2:-}
  [ -n "$x" ] || x='{}'
  jq -nc --arg h "$C5" --arg nohead "$nohead" --argjson x "$x" \
    '{ref: "x-dev", inputs: ($x + {"follow-up-of": "111"}
                             + (if $nohead == "" then {"follow-up-head": $h} else {} end))}'
}

# --- 1, 2: whether, and what -------------------------------------------------

echo "== 1. nothing left, or nothing decided"
store "$C3:111" "$C4:111" "$C5:111"
plan without=3 planned="$C3 $C4 $C5"
out=$(run)
has "every planned commit decided: not dispatched" "$out" "Not dispatched: nothing the run planned or deferred is left"
has "and the job succeeds" "$out" "EXIT=0"
is "without asking GitHub anything" "$(calls api)" 0
store
out=$(run)
has "none decided: not dispatched" "$out" "Not dispatched: the run decided none of the 3 commit(s)"
is "nor asked about" "$(calls api)" 0

echo
echo "== 2. progress"
store "$C3:111"
out=$(run INPUTS='{"since":"","max-commits":"5","force":true,"follow-up-of":"99","follow-up-head":"0ld","branch":"refs/heads/x-dev"}')
has "is dispatched" "$out" "Dispatched a follow-up run on x-dev: this run decided 1 commit(s), and 2 remain"
is "with the run's inputs but force, and the two of its own" "$(sent)" "$(body '' '{"max-commits":"5"}')"
is "after asking for the waiting runs on the branch" "$(calls 'branch=x-dev')" 1

# --- 3: the shard cap ----------------------------------------------------------

echo
echo "== 3. deferred past the shard cap"
store "$C4:111" "$C5:111"
plan without=2 planned="$C4 $C5" deferred="$C1 $C2"
out=$(run)
has "undecided, and the run decided its own: dispatched" "$out" "this run decided 2 commit(s), and 2 remain"
store "$C1:7" "$C2:7" "$C4:111" "$C5:111"
out=$(run)
has "decided since the plan: not dispatched" "$out" "Not dispatched: nothing the run planned or deferred is left"

# --- 4: the branch, and the queue ---------------------------------------------

echo
echo "== 4. a moved branch, and a waiting run"
store "$C3:111"
plan without=3 planned="$C2 $C3 $C4" head="$C4"
out=$(run)
has "moved: not dispatched" "$out" "Not dispatched: x-dev has moved from $C4 to $C5"
is "nor asked about" "$(calls api)" 0
git -C "$BUILD" push -q "$ORIGIN" :refs/heads/x-dev
plan without=3 planned="$C3 $C4 $C5"
out=$(run)
has "deleted: not dispatched" "$out" "has moved from $C5 to nothing"
has "and the job succeeds" "$out" "EXIT=0"
move "$C5"
runs 111:in_progress 222:pending
out=$(run)
has "another run waiting: not dispatched" "$out" "Not dispatched: another each.yaml run on x-dev is waiting"
is "and nothing is sent" "$(sent)" none
runs 111:in_progress 100:completed
out=$(run)
has "the run's own and a finished one do not count" "$out" "Dispatched a follow-up run"

# --- 5: the store ---------------------------------------------------------------

echo
echo "== 5. an unreachable store"
out=$(run RCC_REMOTE="$SCRATCH/nowhere.git" RCC_READ_DIR="$SCRATCH/read-nowhere")
has "fails the job" "$out" "EXIT=1"
is "and dispatches nothing" "$(calls api)" 0

# --- 6, 7: commits planned despite a record ---------------------------------------

echo
echo "== 6. a forced run"
store "$C4:111" "$C5:111"
plan planned="$C4 $C5" replanned="$C4 $C5" deferred="$C1 $C2"
out=$(run INPUTS='{"force":true,"max-commits":"4"}')
has "judged again by this run is progress, and the capped remain: dispatched" "$out" \
  "this run decided 2 commit(s), and 2 remain"
is "and the follow-up does not force" "$(sent)" "$(body '' '{"max-commits":"4"}')"
store "$C4:50" "$C5:50"
out=$(run INPUTS='{"force":true}')
has "records of another run are no progress: not dispatched" "$out" \
  "Not dispatched: the run decided none of the 2 commit(s)"
store "$C4:111" "$C5:111"
plan planned="$C4 $C5" replanned="$C4 $C5"
out=$(run INPUTS='{"force":true}')
has "a forced commit is never left for a follow-up" "$out" "Not dispatched: nothing the run planned or deferred is left"

echo
echo "== 7. a retry tip"
store "$C4:111" "$C5:50"
plan without=1 planned="$C4 $C5" replanned="$C5" retry="$C5"
out=$(run)
has "not judged again: it remains" "$out" "this run decided 1 commit(s), and 1 remain"
is "and the follow-up is sent without the head, so it forces the tip" "$(sent)" "$(body 1)"
store "$C5:111"
out=$(run)
has "judged again, with a commit left" "$out" "this run decided 1 commit(s), and 1 remain"
is "the follow-up is sent with the head" "$(sent)" "$(body)"

# --- 8: a refused dispatch ------------------------------------------------------

echo
echo "== 8. a refused dispatch"
store "$C3:111"
plan without=3 planned="$C3 $C4 $C5"
printf '#!/bin/bash\ngit -C "%s" push -q -f "%s" "%s:refs/heads/x-dev"\n' "$BUILD" "$ORIGIN" "$C6" > "$FAKE/on-post"
chmod +x "$FAKE/on-post"
echo 1 > "$FAKE/post-rc"
out=$(run)
has "after a move: not dispatched" "$out" "Not dispatched: x-dev moved from $C5 to $C6 while dispatching"
has "and the job succeeds" "$out" "EXIT=0"
rm -f "$FAKE/on-post"
move "$C5"
out=$(run)
has "on an unmoved branch: the job fails" "$out" "EXIT=1"
has "and says so" "$out" "the dispatch on x-dev was refused"
rm -f "$FAKE/post-rc"

# --- 9: inputs ------------------------------------------------------------------

echo
echo "== 9. a push's run, and a dry run"
run INPUTS='{}' > /dev/null
is "no inputs: only the follow-up's own" "$(sent)" "$(body)"
run > /dev/null
is "inputs unset: the same" "$(sent)" "$(body)"
out=$(run DRY_RUN=1)
has "a dry run says what it would send" "$out" "[dry-run] POST repos/{owner}/{repo}/actions/workflows/each.yaml/dispatches"
has "and that it would" "$out" "Would dispatch a follow-up run"
is "and sends nothing" "$(sent)" none

# --- 10: the planner --------------------------------------------------------------

echo
echo "== 10. the planner"
git -C "$BUILD" push -q "$ORIGIN" "$C5:refs/heads/retry-x-dev"
git -C "$WORK" fetch -q origin
git -C "$WORK" checkout -q -b retry-x-dev origin/retry-x-dev
printf '%s\n' "$C3" "$C5" > "$SCRATCH/decided"
planner() { # [VAR=value ...] -> the plan, as the follow-up reads it
  (cd "$WORK" && env OUT="$SCRATCH/each-plan.json" EACH_DECIDED_FILE="$SCRATCH/decided" SINCE=2000-01-01 "$@" \
    "$HERE/each-plan.sh" > "$SCRATCH/each-plan.log" 2>&1) || { cat "$SCRATCH/each-plan.log"; return 1; }
  jq -c '{retry_tip, replanned_despite_verdict, planned_without_verdict,
          planned: [.shards[].commits[].sha | .[0:7]], deferred_shas: (.deferred_shas | map(.[0:7])), commits_deferred}' \
    "$SCRATCH/each-plan.json"
}
s() { git -C "$BUILD" rev-parse --short=7 "$1"; }
out=$(planner)
has "a retry tip is forced" "$out" "\"retry_tip\":\"$C5\",\"replanned_despite_verdict\":[\"$C5\"]"
has "beside the commits without a record" "$out" "\"planned_without_verdict\":3,\"planned\":[\"$(s "$C1")\",\"$(s "$C2")\",\"$(s "$C4")\",\"$(s "$C5")\"]"
out=$(planner FOLLOW_UP_OF=111 FOLLOW_UP_HEAD="$C5")
has "not when it is the follow-up's head" "$out" "\"retry_tip\":\"\",\"replanned_despite_verdict\":[]"
out=$(planner FOLLOW_UP_OF=111 FOLLOW_UP_HEAD="$C4")
has "but when the branch moved since" "$out" "\"retry_tip\":\"$C5\""
out=$(planner MAX_SHARDS=1 SHARD_BUDGET_MINUTES=7 SETUP_MINUTES=0 FULL_BUILD_MINUTES=6)
has "the commits past the shard cap are listed, oldest first" "$out" \
  "\"deferred_shas\":[\"$(s "$C1")\",\"$(s "$C2")\",\"$(s "$C4")\"],\"commits_deferred\":3"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
