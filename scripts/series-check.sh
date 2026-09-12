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
# The store is the *copy* of what an `each-rcc` leg wrote, not the source: the
# leg writes the same record and log into its artifact and publishes them here
# (scripts/each-shard.sh). A firing reads the run first and this branch only
# when it cannot (.claude/skills/series-loop.md stage 2), so where a verdict
# here and one read from a run disagree, the run is right. The ref geometry
# below -- in flight, buffered, the retry ledger, a ready cutover -- does not
# depend on the source at all, which is why this stays worth running either way.
# Teaching it to read runs directly needs API access this script does not
# assume; that is a change to make when a firing needs it, not before.
#
# The `harvest:` line below is the store's tip, and it is no longer bounded by a
# schedule: `rcc-logs.yaml` is dispatch-only, so what keeps the tip moving is
# the legs publishing as they decide commits. An old timestamp therefore means
# "no leg has decided anything since", which on a quiet series is normal and not
# a fault. Only a record the dispatched sweep alone could supply -- a run
# cancelled whole -- is a reason to ask for one.
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
# One more line is about no series at all: `UNSERVED`, last and in its own
# block, names an upstream release line this repository does not serve yet. A
# series is discovered from its refs, so a line that has none is invisible to
# every other part of the loop, and stays invisible while upstream builds on it.
# Reported, never acted on, like the cutover above: opening a series is
# .claude/skills/series-open.md's job, and a human's.
#
# Usage: series-check.sh [<series>...]     # default: discover all from refs
#   UPSTREAM_CLONE=../duckdb series-check.sh   # fork point too, not just names

set -euo pipefail

remote=origin
rcc=${RCC_BRANCH:-rcc2}

# Where the release-line check at the end reads upstream. Branch names are all
# that check needs, and `git ls-remote` supplies those from the URL alone, so a
# firing with no clone still gets it; a clone is preferred because it also
# answers with the fork point.
upstream=${UPSTREAM_CLONE:-}
upstream_url=${UPSTREAM_URL:-https://github.com/duckdb/duckdb}

git fetch -q "$remote"

rcc_tip() { git rev-parse -q --verify "refs/remotes/$remote/$rcc" 2>/dev/null; }

# How deep the base scan looks; see scripts/series-advance.sh for why the four
# scanning scripts share the variable and the default.
base_scan_depth="${BASE_SCAN_DEPTH:-20}"

# See scripts/series-advance.sh: the pathspec narrows the walk, the subject
# decides, and an empty answer explains itself on stderr.
vendored_sha() {
  local subjects sha n
  subjects=$(git log -n "$base_scan_depth" --format=%s "$1" -- src/duckdb || true)
  sha=$(sed -nr 's/^.*duckdb.duckdb@([0-9a-f]+)( .*)?$/\1/p' <<<"$subjects" | head -n 1)
  if [ -z "$sha" ]; then
    n=$(grep -c . <<<"$subjects" || true)
    if [ "$n" -ge "$base_scan_depth" ]; then
      echo "vendored_sha: $base_scan_depth src/duckdb commits on $1, none of them vendoring;" >&2
      echo "  if that is genuine, raise BASE_SCAN_DEPTH" >&2
    else
      echo "vendored_sha: no vendor commit among $n src/duckdb commits on $1" >&2
    fi
  fi
  echo "$sha"
}

# How many commits of a buffer range are still work for stage 5.
#
# series-advance.sh replays them with `cherry-pick --empty=drop`, so a commit
# whose every path `-dev` already carries at that commit's post-image produces
# nothing and is dropped. Counting one leaves the series reading ADVANCE for
# ever: the firing runs the advance, is told `dev -> … (+0)`, and reads the
# same verdict again next time. Only a new vendor commit on the buffer would
# clear it, by moving the anchor past the whole run.
#
# Observed on v1.4-andium since 2026-08-06 (f52ed130b). A buffer takes no ports
# by design, so its `.github/` predates the removal of the `v*.*-*` push filter
# from R-CMD-check.yaml, and a series ref move still triggers `rcc` there; its
# auto-update step committed a `Config/roxygen2/version` bump onto `-build`
# that `-dev` already carried.
#
# The comparison is by content and not by patch-id: `git cherry` reports such a
# commit as unmerged, because the same post-image was reached on `-dev` by a
# different diff.
consumable_count() { # <range> <dev> -> commits of <range> that are not no-ops on <dev>
  local range=$1 dev=$2 n=0 c f
  while IFS= read -r c; do
    while IFS= read -r -d '' f; do
      if [ "$(git rev-parse -q --verify "$c:$f" || true)" \
        != "$(git rev-parse -q --verify "$dev:$f" || true)" ]; then
        n=$((n + 1))
        break
      fi
    done < <(git diff-tree --no-commit-id --name-only -r -z "$c")
  done < <(git rev-list "$range")
  echo "$n"
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
  elif grep -qE '^Error: R CMD check found (ERROR|WARNING|NOTE)' <<<"$log"; then
    # The check gate's own verdict, and it is definite: `--as-cran` named the
    # checks it is unhappy about, so a rerun buys the same answer. Ahead of the
    # network rule for that reason, and behind the three above it because a
    # snapshot, a test or a style diff says more precisely what to fix.
    echo "check|$(grep -oE 'R CMD check found .*' <<<"$log" | head -1)" \
      "($(grep -E '^❯ checking' <<<"$log" | sed 's/^❯ //; s/ \.\.\..*//' |
        tr '\n' '\a' | sed 's/\a$//; s/\a/; /g'))"
  elif grep -qE "$net_re" <<<"$log"; then
    gate=$(failed_gate "$log")
    echo "transient|network failure in the ${gate:-unnamed} gate ($(grep -oE "$net_re" <<<"$log" | head -1))"
  elif ! grep -q "test_local\|testthat" <<<"$log"; then
    echo "transient|cancelled or infra (no test phase in log)"
  else
    echo "unknown|unclassified: review logs2.d/${1:0:2}/$1.log on branch $rcc by hand"
  fi
}

# Every series this repository serves, discovered from the refs and never from
# configuration (handbook/branches/model/): an `<X>-build` with a sibling
# `<X>-dev`. Discovered even when the caller named series, because the
# release-line check at the end asks what is served, and a run narrowed to one
# series would otherwise report the rest of them as unserved.
all_series=()
while IFS= read -r b; do
  s=${b#refs/heads/}; s=${s%-build}
  case "$s" in *-build-base) continue ;; esac
  git rev-parse -q --verify "refs/remotes/$remote/$s-dev" >/dev/null && all_series+=("$s")
done < <(git ls-remote --heads "$remote" '*-build' | cut -f2)

series=("$@")
if [ ${#series[@]} -eq 0 ]; then
  series=("${all_series[@]}")
fi

# The shape upstream gives a release line, and the only branches the check at
# the end looks at. `main` is not one: it is a line the package serves under
# that name, and it never stops being the newest.
release_line_re='^v[0-9]+\.[0-9]+-[A-Za-z0-9-]+$'

# `major.minor` as one number, so lines are compared as versions rather than as
# strings -- a string compare puts `v1.10` below `v1.9`, and the floor below
# would then fall silent on the newer line.
line_rank() { # v<major>.<minor>-<codename>[-fwd] -> integer
  local v=${1#v} major minor
  major=${v%%.*}; minor=${v#*.}; minor=${minor%%-*}
  echo $((major * 1000 + minor))
}

# How the clone names an upstream branch: a clone made by `git clone` carries it
# as a remote-tracking ref, and a mirror as a head.
upstream_ref() { # <branch> -> full ref, empty if the clone has none
  local r
  for r in "refs/remotes/origin/$1" "refs/heads/$1"; do
    if git -C "$upstream" rev-parse -q --verify "$r" >/dev/null; then echo "$r"; return; fi
  done
}

# The upstream branch names, from the clone when there is one and from the
# remote otherwise. Empty is not "upstream has no release branches" -- it never
# has none -- it is the reading having failed, and the caller says so rather
# than printing the silence as a clean result.
upstream_branches() {
  if [ -n "$upstream" ]; then
    git -C "$upstream" for-each-ref --format='%(refname:lstrip=3)' 'refs/remotes/*/v*' 2>/dev/null || true
    git -C "$upstream" for-each-ref --format='%(refname:lstrip=2)' 'refs/heads/v*' 2>/dev/null || true
  else
    git ls-remote --heads "$upstream_url" 'v*' 2>/dev/null | cut -f2 | sed 's|^refs/heads/||' || true
  fi
}

# The fork point of a release line: the newest commit on the first-parent chain
# of both upstream branches (scripts/VENDORING.md, "Starting a New Dev Line: the
# Fork-Point Rule"). Not `git merge-base`, which upstream's back-merges of the
# release branch into `main` drag forward by weeks; a series seeded from that
# answer jumps the commits in between in one step, and none of them is ever
# built against the glue. Printed only when a clone can compute it, because a
# wrong fork point is worse than none.
fork_point() { # <upstream branch> -> sha, empty without a clone
  local main_ref rel_ref
  [ -n "$upstream" ] || return 0
  main_ref=$(upstream_ref main); rel_ref=$(upstream_ref "$1")
  [ -n "$main_ref" ] && [ -n "$rel_ref" ] || return 0
  awk 'NR==FNR { seen[$0]; next } $0 in seen { print; exit }' \
    <(git -C "$upstream" rev-list --first-parent "$main_ref") \
    <(git -C "$upstream" rev-list --first-parent "$rel_ref")
}

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
  # as the anchor in scripts/series-advance.sh. It counts what that stage would
  # actually mint, which is why a commit it would drop as empty is not buffered
  # work (consumable_count above).
  mb=$(git merge-base "$dev" "$build")
  if [ "$mb" = "$(git rev-parse "$dev")" ]; then
    buffered=$(consumable_count "$dev..$build" "$dev")
  else
    dev_up=$(vendored_sha "$dev")
    anchor=$(git log --format='%H %s' "$build" | grep -m 1 "duckdb@${dev_up:-NONE}" | cut -d' ' -f1 || true)
    if [ -n "$anchor" ]; then
      buffered=$(consumable_count "$anchor..$build" "$dev")
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
    echo "           Coverage is only half of it; what the two branches carry is"
    echo "           the other half, and the cutover prints it before it asks:"
    echo "           scripts/series-converge.sh $cutover"
  fi
done

# An upstream release line this repository does not serve. Printed last and in
# a block of its own, because everything above it is per-series: a firing where
# every series reads ADVANCE or IDLE is the quietest report the loop produces,
# and exactly the one a line lost at the bottom of would be skimmed past. It is
# reported again on every firing until the series exists, because nothing else
# notices it at all -- a series is discovered from refs
# (handbook/branches/model/), so a line that has none is absent rather than
# late, and absence raises nothing anywhere.
#
# The floor is the greatest `major.minor` among the served series. Upstream
# keeps every release branch it ever cut alive, and this repository serves the
# recent ones only, so a line at or below the floor is a decision already taken
# and only a line above it is news. That is the whole rule, and it is why there
# is no list of lines to ignore: such a list is maintained by hand, and the
# firing it would be stale on is the one where a line was just cut. With no
# served series carrying a version token there is no floor, and every release
# line upstream carries is reported -- a repository serving none of them is one
# where each is genuinely unserved.
floor=0
for S in "${all_series[@]}"; do
  case "$S" in
    v[0-9]*.[0-9]*-*) r=$(line_rank "$S"); [ "$r" -gt "$floor" ] && floor=$r ;;
  esac
done

unserved=()
branches=$(upstream_branches | sort -u)
while IFS= read -r b; do
  [ -n "$b" ] || continue
  grep -qE "$release_line_re" <<<"$b" || continue
  [ "$(line_rank "$b")" -gt "$floor" ] || continue
  # Served is the same question every other stage asks, asked of one branch:
  # does a series of that name exist? A line may be served by a `-fwd` series
  # alone, which is one that started as a forward and has no base to replace.
  served=
  for S in "${all_series[@]}"; do
    case "$S" in "$b" | "$b-fwd") served=1; break ;; esac
  done
  [ -n "$served" ] || unserved+=("$b")
done <<<"$branches"

if [ -z "$branches" ]; then
  # A reading that failed reads exactly like a clean result, so say which this
  # is. The same degradation rule as the cutover gate's missing clone.
  echo
  echo "UNSERVED  could not read the upstream branches from ${upstream:-$upstream_url},"
  echo "          so this firing does not know whether a release line was cut."
  echo "          That is missing data, not a clean result."
elif [ ${#unserved[@]} -gt 0 ]; then
  echo
  echo "=============================================================================="
  for b in "${unserved[@]}"; do
    echo "UNSERVED  $b is cut upstream and no series here serves it:"
    echo "          neither $b-build nor $b-dev exists."
    fp=$(fork_point "$b")
    if [ -n "$fp" ]; then
      echo "          Fork point $fp,"
      echo "          $(git -C "$upstream" rev-list --count --first-parent "$fp..$(upstream_ref "$b")") first-parent commits back. That is not what"
      echo "          git merge-base answers here (scripts/VENDORING.md)."
    fi
  done
  # Said once, however many lines are listed: what waiting costs. It is a
  # decision owed an answer rather than a fault -- a line may be opened
  # deliberately, on a released tree, once the current one ships -- and the
  # loop cannot open it either way, so all this block can do is be impossible
  # to miss and stay inside what branch names can support. How much of the
  # line another series has already vendored is not one of those things:
  # upstream back-merges the release branch into `main`, so some of it may
  # well be built here, and a check that reads names cannot say how much.
  echo "          Open the series: .claude/skills/series-open.md"
  echo "          No release can be cut from a line nothing here serves, and"
  echo "          the catch-up walk that opening one costs grows with every"
  echo "          upstream commit on it."
  echo "=============================================================================="
fi
