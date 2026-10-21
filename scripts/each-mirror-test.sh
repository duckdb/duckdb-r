#!/bin/bash
# Check scripts/each-mirror.sh, offline, against a synthetic canonical
# repository, a synthetic store and a stand-in for `gh api` built here: no
# network, no fixtures on disk.
#
# The claim the script makes is that every commit of an open pull request from
# the fork shows the verdict the store holds for it, that nothing already
# shown is posted again, and that a run's API use is bounded. Nine things are
# checked.
#
#   1. Only pull requests whose head is in the fork are covered, and a
#      pull request's commits are read with git from its base, so a stacked
#      one covers its own commits and not those below it.
#   2. A status shown with the same state and URL is not posted again; every
#      other judged commit gets the state, URL and description of its record,
#      and the newest line of a record wins.
#   3. A run with nothing new reads nothing and posts nothing: the watermark
#      holds every record confirmed as it stands.
#   4. A record that changed is a candidate again, and its new verdict is posted.
#   5. A lost watermark costs one status query per hundred commits, and posts
#      nothing that is already shown.
#   6. A pull request of more than 250 commits is covered whole, and its
#      statuses are read 100 commits to a query.
#   7. MAX_WRITES caps a run's posts and MAX_READS its reads; what is left is
#      taken by the next run.
#   8. A refused post stops the posting, fails the run, and leaves the refused
#      commit and those after it to the next run.
#   9. A dry run posts nothing and confirms nothing.
#
# Usage:
#   scripts/each-mirror-test.sh
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

export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
unset GITHUB_STEP_SUMMARY DRY_RUN

# --- the fixture -------------------------------------------------------------
#
# The canonical repository serves `refs/pull/<n>/head` as GitHub does; the
# fork's store serves filters; the clone the script runs in is the canonical
# repository's.

CANON=$SCRATCH/canonical.git
FORKREPO=$SCRATCH/fork.git
BUILD=$SCRATCH/build
STORE=$SCRATCH/store
WORK=$SCRATCH/work
FAKE=$SCRATCH/fake
git init -q --bare -b main "$CANON"
git init -q --bare -b main "$FORKREPO"
git -C "$FORKREPO" config uploadpack.allowFilter true
mkdir -p "$FAKE" "$SCRATCH/bin"

git init -q -b main "$BUILD"
cd "$BUILD"
git config commit.gpgsign false
c() { echo "$1" > "$1.txt"; git add -A; git commit -qm "vendor: $1"; git rev-parse HEAD; }
M0=$(c seed)
P1=$(c p1); P2=$(c p2); P3=$(c p3); P4=$(c p4)
git branch p-head
R1=$(c r1)
git checkout -q -b q "$M0"
Q1=$(c q1)
git checkout -q -b big "$M0"
BIG=()
for i in $(seq 1 260); do BIG+=("$(c "big$i")"); done
git checkout -q main
git reset -q --hard "$M0"
git push -q "$CANON" main p-head "$P4:refs/pull/1/head" "$Q1:refs/pull/2/head" \
  "$R1:refs/pull/3/head" "${BIG[259]}:refs/pull/4/head"

git clone -q "$CANON" "$WORK"

# The store: one file per commit, a line per verdict, the newest last.
git init -q -b rcc2 "$STORE"
git -C "$STORE" remote add origin "$FORKREPO"
url() { echo "https://github.com/krlmlr/duckdb-r/actions/runs/1/job/$1"; }
rec() { # <sha> <state> <job> -- appends, so a second call is a newer line
  mkdir -p "$STORE/runs2.d/${1:0:2}"
  printf '{"commit":"%s","status":{"context":"rcc","state":"%s","target_url":"%s","description":"each-rcc / shard %s"}}\n' \
    "$1" "$2" "$(url "$3")" "$3" >> "$STORE/runs2.d/${1:0:2}/$1.ndjson"
}
store() { git -C "$STORE" add -A; git -C "$STORE" commit -qm "$1"; git -C "$STORE" push -q origin rcc2; }
rec "$P1" success 11
rec "$P2" failure 12
rec "$P3" failure 13
rec "$P3" success 23
rec "$Q1" success 14
rec "$R1" success 15
store 'chore: The store'

# The stand-in for `gh api`: the open pull requests from a file, and a status
# table that a post appends to and a GraphQL read answers from, the newest row
# per commit and context winning, as GitHub's does. Every call is logged.
cat > "$SCRATCH/bin/gh" <<'EOF'
#!/bin/bash
echo "$*" >> "$FAKE/calls"
[ "$1" = api ] || exit 2
shift
case "$1" in
  --paginate) cat "$FAKE/pulls.json" ;;
  graphql)
    shift
    q='' ctx=''
    while [ $# -gt 0 ]; do
      case "$2" in query=*) q=${2#query=} ;; context=*) ctx=${2#context=} ;; esac
      shift 2
    done
    grep -o 'c[0-9]*: object(oid: "[0-9a-f]*")' <<<"$q" |
      sed 's/^\(c[0-9]*\): object(oid: "\([0-9a-f]*\)")$/\1 \2/' |
      while read -r alias sha; do
        row=$(awk -F'\t' -v s="$sha" -v c="$ctx" '$1 == s && $2 == c' "$FAKE/statuses" | tail -n 1)
        if [ -n "$row" ]; then
          jq -nc --arg a "$alias" --arg s "$(cut -f3 <<<"$row" | tr a-z A-Z)" --arg u "$(cut -f4 <<<"$row")" \
            '{($a): {status: {context: {state: $s, targetUrl: $u}}}}'
        else
          jq -nc --arg a "$alias" '{($a): {status: null}}'
        fi
      done | jq -sc '{data: {repository: add}}'
    ;;
  -X)
    sha=${3##*/}
    shift 3
    declare -A kv=()
    while [ $# -gt 0 ]; do kv[${2%%=*}]=${2#*=}; shift 2; done
    if [ -f "$FAKE/refuse" ] && grep -qx "$sha" "$FAKE/refuse"; then
      echo "gh: You have exceeded a secondary rate limit (HTTP 403)" >&2
      exit 1
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$sha" "${kv[context]}" "${kv[state]}" "${kv[target_url]:-}" \
      "${kv[description]}" >> "$FAKE/statuses"
    echo '{}'
    ;;
esac
EOF
chmod +x "$SCRATCH/bin/gh"

pull() { # <number> <head repo or null> <base>
  jq -nc --argjson n "$1" --arg r "$2" --arg b "$3" \
    '{number: $n, head: {repo: (if $r == "null" then null else {full_name: $r} end)}, base: {ref: $b}}'
}
{
  pull 1 krlmlr/duckdb-r main
  pull 2 duckdb/duckdb-r main
  pull 3 krlmlr/duckdb-r p-head
  pull 5 null main
} | jq -sc . > "$FAKE/pulls.json"

# Already shown: P1 as its record says, P3 as an older verdict did.
printf '%s\teach-rcc (fork)\tsuccess\t%s\teach-rcc / shard 11\n' "$P1" "$(url 11)" > "$FAKE/statuses"
printf '%s\teach-rcc (fork)\tfailure\t%s\teach-rcc / shard 13\n' "$P3" "$(url 13)" >> "$FAKE/statuses"

STATE=$SCRATCH/state/watermark
run() { # -> the output, then EXIT=<status>; the calls of this run in $FAKE/calls
  : > "$FAKE/calls"
  set +e
  (cd "$WORK" && PATH="$SCRATCH/bin:$PATH" FAKE="$FAKE" GH_TOKEN=x REPO=duckdb/duckdb-r \
    FORK=krlmlr/duckdb-r RCC_REMOTE="file://$FORKREPO" STORE_DIR="$SCRATCH/store-clone" \
    STATE="$STATE" PAUSE=0 "$@" "$HERE/each-mirror.sh" 2>&1)
  echo "EXIT=$?"
  set -e
}
calls() { grep -c "^api $1" "$FAKE/calls" || true; }
shown() { # <sha> -> state, URL and description of the newest status
  awk -F'\t' -v s="$1" '$1 == s && $2 == "each-rcc (fork)" { r = $3 " " $4 " " $5 } END { print r }' "$FAKE/statuses"
}
short() { git -C "$BUILD" rev-parse --short "$1"; }

# --- 1, 2: the first run ------------------------------------------------------

echo "== 1, 2. the first run"
out=$(run env)
has "it succeeds" "$out" "EXIT=0"
has "covering the two pull requests from the fork" "$out" "2 pull request(s) from krlmlr/duckdb-r"
has "and their five commits, four of them judged" "$out" "5 commit(s), 4 judged"
is "one query reads what the four show" "$(calls graphql)" 1
is "three statuses are posted" "$(calls '-X POST')" 3
has "the one already shown is not" "$out" "1 already shown, 3 posted"
is "a red is posted red, linked to its leg" "$(shown "$P2")" "failure $(url 12) each-rcc / shard 12"
is "a record's newest line wins over the status shown" "$(shown "$P3")" "success $(url 23) each-rcc / shard 23"
is "a stacked pull request's own commit is posted" "$(shown "$R1")" "success $(url 15) each-rcc / shard 15"
is "a pull request from elsewhere is not covered" "$(shown "$Q1")" ""
is "no post goes to the commit already shown" "$(grep -c "statuses/$P1" "$FAKE/calls" || true)" 0

# --- 3, 4: the watermark ------------------------------------------------------

echo
echo "== 3. nothing new"
out=$(run env)
is "reads nothing" "$(calls graphql)" 0
is "and posts nothing" "$(calls '-X POST')" 0
has "and says so" "$out" "0 not confirmed yet"

echo
echo "== 4. a record that changed"
rec "$R1" failure 16
store 'chore: R1 judged again'
out=$(run env)
is "is read" "$(calls graphql)" 1
is "and posted" "$(calls '-X POST')" 1
is "with its new verdict" "$(shown "$R1")" "failure $(url 16) each-rcc / shard 16"

# --- 5: a lost watermark ------------------------------------------------------

echo
echo "== 5. a lost watermark"
rm -f "$STATE"
out=$(run env)
is "costs one query for the four" "$(calls graphql)" 1
is "and posts nothing already shown" "$(calls '-X POST')" 0
has "it confirms all four" "$out" "4 already shown, 0 posted"

# --- 6, 7: a long pull request, and the caps ---------------------------------

echo
echo "== 6, 7. a long pull request under the caps"
for x in "${BIG[@]}"; do rec "$x" success 17; done
store 'chore: The long pull request judged'
{ jq -c '.[]' "$FAKE/pulls.json"; pull 4 krlmlr/duckdb-r main; } | jq -sc . > "$FAKE/pulls.json.new"
mv "$FAKE/pulls.json.new" "$FAKE/pulls.json"
out=$(run env MAX_WRITES=200)
has "every one of its 260 commits is judged" "$out" "265 commit(s), 264 judged"
is "its statuses are read 100 to a query" "$(calls graphql)" 3
is "and MAX_WRITES caps the posts" "$(calls '-X POST')" 200
has "the rest is left" "$out" "60 left for the next run"
out=$(run env MAX_WRITES=200)
is "the next run reads what was left" "$(calls graphql)" 1
is "and posts it" "$(calls '-X POST')" 60
is "down to its first commit, past the API's 250" "$(shown "${BIG[0]}" | cut -d' ' -f1)" success
rm -f "$STATE"
out=$(run env MAX_READS=100)
is "MAX_READS caps the reads" "$(calls graphql)" 1
has "and says how many waited" "$out" "264 not confirmed yet, 100 read this run"

# --- 8: a refused post --------------------------------------------------------

echo
echo "== 8. a refused post"
run env >/dev/null
rec "$P4" success 18
rec "$P2" success 19
store 'chore: P4 judged, P2 judged again'
echo "$P4" > "$FAKE/refuse"
out=$(run env)
has "fails the run" "$out" "EXIT=1"
has "naming the commit" "$out" "the post for $P4 was refused"
is "and posts nothing after it" "$(calls '-X POST')" 1
is "the commit below is left as it was" "$(shown "$P2" | cut -d' ' -f1)" failure
rm -f "$FAKE/refuse"
out=$(run env)
is "the next run posts both" "$(calls '-X POST')" 2
is "the refused one" "$(shown "$P4" | cut -d' ' -f1)" success
is "and the one after it" "$(shown "$P2" | cut -d' ' -f1)" success

# --- 9: a dry run -------------------------------------------------------------

echo
echo "== 9. a dry run"
rec "$P1" failure 20
store 'chore: P1 judged again'
out=$(run env DRY_RUN=1)
has "says what it would post" "$out" "[dry-run] POST repos/duckdb/duckdb-r/statuses/$P1 failure"
is "posts nothing" "$(calls '-X POST')" 0
out=$(run env)
is "and confirms nothing, so the next run posts it" "$(calls '-X POST')" 1

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
