#!/bin/bash
# Check scripts/series-green.sh, offline, against a synthetic fork and clones
# built here: no network, no fixtures on disk.
#
# The claim the script makes is that `<S>-green` moves forward by the rule its
# kind takes, and by nothing else. Twelve things are checked.
#
#   1. Without --push the run says where green would move and writes nothing.
#   2. A series' green takes the passed prefix and stops at the first commit
#      without a success, naming it; a rerun with nothing new leaves it there.
#   3. A red above the prefix holds green where it is, and the newest line of a
#      record wins, so a retry that overturned the red moves green past it.
#   4. A landing's green moves all or nothing: it holds at the base while any
#      commit above is undecided, and goes to the tip once every one passed.
#   5. An iteration's `<L>-land-v<n>` takes the landing rule too, where the
#      series rule would have moved it over the passed prefix.
#   6. What is not the loop's is left alone: a `-dev` with no buffer and no
#      landing's name, and a branch with no green.
#   7. Cutover litter is left alone, and a live forward is served.
#   8. A green off `-dev`'s lineage stops the run with an error and moves
#      nothing.
#   9. A writer that moved green between the read and the push is not
#      overwritten: the run reads again and walks on from where green stands.
#  10. A push refused over a workflow file moves a series' green as far as the
#      newest commit that leaves `.github/workflows/` alone, names the commit
#      it could not cross, and fails; a landing's does not move.
#  11. The store is read from a records-only clone when RCC_READ_DIR is set.
#  12. In a treeless partial clone, the shape of the job's checkout, green
#      moves, and the workflow fallback reads the trees it needs lazily.
#
# Usage:
#   scripts/series-green-test.sh
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

# The runs below leave the scratch fork's own identity alone.
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
unset GITHUB_STEP_SUMMARY RCC_READ_DIR SERIES_REMOTE

# --- the fixture -------------------------------------------------------------
#
# A bare fork plus a clone that writes it. Every series has refs of its own,
# so the checks below do not lean on each other's moves. The fork serves
# filters and objects by id, as GitHub does, so a partial clone can be made of
# it and can fetch lazily.

REMOTE=$SCRATCH/remote.git
WORK=$SCRATCH/work
STORE=$SCRATCH/store
GREEN=$HERE/series-green.sh
git init -q --bare -b main "$REMOTE"
git -C "$REMOTE" config uploadpack.allowFilter true
git -C "$REMOTE" config uploadpack.allowAnySHA1InWant true

git init -q -b main "$WORK"
cd "$WORK"
git config commit.gpgsign false
git remote add origin "$REMOTE"
mkdir -p .github/workflows
echo 'jobs: as the seed has them' > .github/workflows/w.yaml
git add -A
git commit -qm 'chore: The seed'
M0=$(git rev-parse HEAD)

# A commit on top of HEAD, printed; `wf` as the second argument changes a
# workflow file as well.
c() { # <name> [wf]
  echo "$1" > "$1.txt"
  [ "${2:-}" != wf ] || echo "jobs: changed at $1" > .github/workflows/w.yaml
  git add -A
  git commit -qm "vendor: $1"
  git rev-parse HEAD
}
# A chain of commits on a new branch from <base>, their SHAs on one line; a
# commit spelled `<name>:wf` changes a workflow file.
chain() { # <branch> <base> <commit>...
  local branch=$1 base=$2 x shas=()
  shift 2
  git checkout -q -b "$branch" "$base"
  for x in "$@"; do
    case "$x" in
      *:wf) shas+=("$(c "${x%:wf}" wf)") ;;
      *) shas+=("$(c "$x")") ;;
    esac
  done
  git checkout -q main
  echo "${shas[@]}"
}

read -r A1 A2 A3 A4 <<<"$(chain a-dev "$M0" A1 A2 A3 A4)"
git branch a-green "$M0"; git branch a-build a-dev
read -r B1 B2 B3 <<<"$(chain b-land-dev "$M0" B1 B2 B3)"
git branch b-land-green "$M0"
read -r C1 C2 <<<"$(chain c-land-v2-dev "$M0" C1 C2)"
git branch c-land-v2-green "$M0"
read -r D1 <<<"$(chain d-dev "$M0" D1)"
git branch d-green "$M0"
read -r E1 <<<"$(chain e-rc-dev "$M0" E1)"
read -r F1 <<<"$(chain a-fwd-dev "$M0" F1)"
git branch a-fwd-green "$M0"; git branch a-fwd-build a-fwd-dev
read -r G0 G1 <<<"$(chain g-fwd-dev "$M0" G0 G1)"
git branch g-fwd-green "$G0"; git branch g-fwd-build g-fwd-dev
git branch g-green "$M0"; git branch g-dev "$M0"; git branch g-build "$M0"
read -r H1 H2 <<<"$(chain h-dev "$M0" H1 H2)"
read -r X1 <<<"$(chain h-other "$M0" X1)"
git branch h-green "$X1"; git branch h-build h-dev
read -r I1 I2 I3 <<<"$(chain i-dev "$M0" I1 I2 I3)"
git branch i-green "$M0"; git branch i-build i-dev
read -r W1 W2 W3 <<<"$(chain w-dev "$M0" W1 W2:wf W3)"
git branch w-green "$M0"; git branch w-build w-dev
read -r V1 V2 <<<"$(chain v-land-dev "$M0" V1:wf V2)"
git branch v-land-green "$M0"
read -r J1 <<<"$(chain j-dev "$M0" J1)"
git branch j-green "$M0"; git branch j-build j-dev
read -r K1 K2 K3 <<<"$(chain k-dev "$M0" K1 K2:wf K3)"
git branch k-green "$M0"; git branch k-build k-dev
git push -q origin --all

# The store, written from a clone of its own: one record per commit, one line
# each unless a check adds a newer one.
git init -q -b rcc2 "$STORE"
git -C "$STORE" remote add origin "$REMOTE"
rec() { # <sha> <state> -- appends, so a second call is a newer line
  mkdir -p "$STORE/runs2.d/${1:0:2}"
  printf '{"commit":"%s","status":{"context":"rcc","state":"%s"}}\n' "$1" "$2" \
    >> "$STORE/runs2.d/${1:0:2}/$1.ndjson"
}
store() { # <message>
  git -C "$STORE" add -A
  git -C "$STORE" commit -qm "$1"
  git -C "$STORE" push -q origin rcc2
}
for x in "$A1" "$A2" "$A4" "$B1" "$B2" "$C1" "$D1" "$E1" "$F1" "$G1" "$H1" "$H2" \
  "$I1" "$I2" "$I3" "$W1" "$W2" "$W3" "$V1" "$V2" "$J1" "$K1" "$K2" "$K3"; do
  rec "$x" success
done
rec "$C2" failure
store 'chore: The store'

# Where a ref stands on the fork.
at() { git ls-remote "$REMOTE" "refs/heads/$1" | cut -f1; }
run() { # <series> <args>... -> the output, then EXIT=<status>
  set +e
  "$GREEN" "$@" 2>&1
  echo "EXIT=$?"
  set -e
}
short() { git rev-parse --short "$1"; }

# --- 1, 2: a series takes the passed prefix ----------------------------------

echo "== 1. without --push nothing moves"
out=$(run a)
has "it says where green would move" "$out" "a-green would move $(short "$M0") -> $(short "$A2")"
has "and that --push moves it" "$out" "--push moves it"
is "the fork's green has not moved" "$(at a-green)" "$M0"

echo
echo "== 2. a series' green takes the passed prefix"
out=$(run a --push)
is "green takes the two that passed" "$(at a-green)" "$A2"
has "and names the first that has not" "$out" "first not passed: $(short "$A3") (missing)"
has "and exits 0" "$out" "EXIT=0"
out=$(run a --push)
has "a rerun leaves it there" "$out" "a-green stays at $(short "$A2")"
is "and moves nothing" "$(at a-green)" "$A2"

# --- 3: a red, and a retry that overturned it --------------------------------

echo
echo "== 3. a red holds green; the newest line of its record wins"
rec "$A3" failure
store 'chore: A3 is red'
out=$(run a --push)
has "green holds below the red" "$out" "first not passed: $(short "$A3") (failure)"
is "where it was" "$(at a-green)" "$A2"
rec "$A3" success
store 'chore: A3 retried, green'
out=$(run a --push)
is "the retry's verdict moves green over every commit" "$(at a-green)" "$A4"
has "and says every commit has passed" "$out" "every commit has passed"

# --- 4, 5: a landing moves all or nothing ------------------------------------

echo
echo "== 4. a landing's green moves all or nothing"
out=$(run b-land --push)
is "it holds at the base while one commit is undecided" "$(at b-land-green)" "$M0"
has "naming it" "$out" "first not passed: $(short "$B3") (missing)"
has "under the landing rule" "$out" "(landing rule)"
rec "$B3" success
store 'chore: B3 green'
out=$(run b-land --push)
is "and goes to the tip once every commit passed" "$(at b-land-green)" "$B3"

echo
echo "== 5. an iteration takes the landing rule"
out=$(run c-land-v2 --push)
is "the passed commit below the red does not move it" "$(at c-land-v2-green)" "$M0"
has "and the red is named" "$out" "first not passed: $(short "$C2") (failure)"

# --- 6, 7: what the loop does not serve --------------------------------------

echo
echo "== 6. what is not the loop's is left alone"
out=$(run d --push)
has "a -dev with no buffer" "$out" "neither a series (no d-build) nor a landing"
is "does not move" "$(at d-green)" "$M0"
has "and is no error" "$out" "EXIT=0"
out=$(run e-rc --push)
has "an rc strand has no green" "$out" "no e-rc-green on origin"

echo
echo "== 7. cutover litter is left alone, a live forward is served"
out=$(run a-fwd --push)
has "a forward whose green its base's contains is litter" "$out" "cutover litter"
is "and does not move" "$(at a-fwd-green)" "$M0"
out=$(run g-fwd --push)
is "a live forward moves" "$(at g-fwd-green)" "$G1"

# --- 8: off the lineage -------------------------------------------------------

echo
echo "== 8. a green off -dev's lineage moves nothing"
out=$(run h --push)
has "it says so" "$out" "h-green ($(short "$X1")) is not an ancestor of h-dev"
has "and fails" "$out" "EXIT=1"
is "green is where it was" "$(at h-green)" "$X1"

# --- 9, 10: the push refused --------------------------------------------------
#
# The fork's hook plays two parts. Once, it is another writer moving `i-green`
# while this run's push is in flight, and refuses the push the way a lost race
# is refused. And it refuses, with GitHub's words, any update of a green that
# changes a file under `.github/workflows/`, which is what a token without the
# `workflows` permission meets. Hooks run in a quarantine that forbids ref
# updates, which the other writer is not subject to.
cat > "$REMOTE/hooks/pre-receive" <<EOF
#!/bin/bash
while read -r old new ref; do
  if [ "\$ref" = refs/heads/i-green ] && [ ! -f "$SCRATCH/raced" ]; then
    touch "$SCRATCH/raced"
    env -u GIT_QUARANTINE_PATH git update-ref refs/heads/i-green $I1
    echo "cannot lock ref 'refs/heads/i-green'" >&2
    exit 1
  fi
  case "\$ref" in refs/heads/*-green) ;; *) continue ;; esac
  [ "\$old" != 0000000000000000000000000000000000000000 ] || continue
  if ! git diff --quiet "\$old" "\$new" -- .github/workflows; then
    echo "refusing to allow a GitHub App to create or update workflow \\\`.github/workflows/w.yaml\\\` without \\\`workflows\\\` permission" >&2
    exit 1
  fi
done
EOF
chmod +x "$REMOTE/hooks/pre-receive"

echo
echo "== 9. a green another writer moved is read again, not overwritten"
out=$(run i --push)
has "the run notices" "$out" "i-green moved from $(short "$M0") to ${I1:0:7} under this run"
is "and walks on from there" "$(at i-green)" "$I3"
has "and succeeds" "$out" "EXIT=0"

echo
echo "== 10. a push refused over a workflow file"
out=$(run w --push)
is "a series' green stops below the commit that changes one" "$(at w-green)" "$W1"
has "naming it" "$out" "$(short "$W2") changes .github/workflows/"
has "and fails, so the job says so" "$out" "EXIT=1"
out=$(run v-land --push)
is "a landing's green does not move" "$(at v-land-green)" "$M0"
has "and says why" "$out" "moves all or nothing"
has "and fails" "$out" "EXIT=1"

# --- 11, 12: the job's shape --------------------------------------------------

echo
echo "== 11. the store from a records-only clone"
out=$(export RCC_REMOTE="file://$REMOTE" RCC_READ_DIR="$SCRATCH/rcc-read"; run j --push)
is "green moves on the clone's records" "$(at j-green)" "$J1"
is "and the clone was made where it was asked" \
  "$(git -C "$SCRATCH/rcc-read" rev-parse refs/remotes/origin/rcc2)" "$(at rcc2)"

echo
echo "== 12. a treeless partial clone"
git clone -q --filter=tree:0 --no-checkout "file://$REMOTE" "$SCRATCH/treeless"
cd "$SCRATCH/treeless"
set +e
out=$(RCC_REMOTE="file://$REMOTE" RCC_READ_DIR="$SCRATCH/rcc-read-2" "$GREEN" k --push 2>&1)
st=$?
set -e
cd "$WORK"
is "green moves as far as a workflow change, read from trees fetched lazily" "$(at k-green)" "$K1"
has "naming the commit it could not cross" "$out" "${K2:0:7}"
is "and fails" "$st" 1

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
