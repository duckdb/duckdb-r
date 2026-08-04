#!/bin/bash
# Bring a series' -dev branch level with `main` — stage 4 of the series loop
# (.claude/skills/series-loop.md).
#
# The goal is identity, not curation: after a successful --apply, the tooling
# paths — .github/, scripts/, .claude/ — of <S>-dev are byte-identical to
# `main`'s, and a tooling change never waits for a forward.
#
# The script lists EVERY commit on `main` since the series' base that has no
# patch-id equivalent on <S>-dev (`git cherry`), oldest first, classified by
# what it touches: TOOLING (only tooling paths), MIXED (tooling and more),
# OTHER (no tooling), VENDOR, VERSION.
# --apply cherry-picks everything except VENDOR and VERSION — a MIXED or OTHER
# commit is a forward-port like any other, judged by CI like every -dev commit —
# or exactly the SHAs given, for when judgement says a commit cannot work
# against this series' engine yet. Picks are always whole commits: a pick
# that matches its main commit is skipped by patch-id at the next rebase,
# a half-pick would only replay. VENDOR commits are never auto-picked,
# because main's engine is not this series' engine: the series' own
# vendoring owns that strand.
#
# **A VERSION commit is not auto-picked either**, because `main`'s R-client
# counter is not this series'. A series' version says which release line it was
# seeded from and how far its own vendoring has run; what `main` is at today is
# read from `main` (#2496). Porting fledge's bumps made the fourth component
# free-run behind `main` instead of staying at the seed, which is the opposite
# of the model handbook/operations/releases/versioning/ describes. The class is
# read from the content -- the commit moves `Version:` and carries nothing but
# release paperwork -- not from the `fledge:` subject, so a bump under another
# name is caught and a bump riding on real content is not. Dropping one leaves
# NEWS.md at the state the series was seeded with; that file is the release
# strand's and already outside the sync commit's path set. Naming a VERSION
# commit explicitly still ports it, like any other SHA.
#
# **The subject is what decides a VENDOR commit, never the path.** The patch
# stack is applied to the vendored tree in place, so CRAN and
# compiler-warning fixes land under src/duckdb/ carrying no upstream SHA, and
# excluding them by path made exactly those fixes wait for a forward — the
# one thing this script exists to end. The readers of the vendor strand look
# past such commits by subject and say so when their bound is exhausted
# (vendored_sha() in scripts/series-advance.sh and scripts/series-check.sh,
# the base scans in scripts/vendor-one.sh and scripts/vendor.sh), so a ported
# commit under src/duckdb/ is invisible to them whether or not this class
# names it. After the picks, whatever tooling
# delta remains (history that diverged inside vendor commits, picks dropped
# as empty) is closed with one sync commit that takes `main`'s tooling tree
# verbatim; its diff is the residue the commit walk could not explain, and
# reading it is part of the port. In steady state the residue is empty and
# no sync commit is created.
#
# A frozen series takes no ports by default: a line seeded from a release
# branch keeps the R code it was seeded with, so `main`'s development line is
# not a backlog it is behind on. The walk is skipped for those and the sync
# commit is the whole default port, so their tooling still follows `main` — a
# frozen R side is not a frozen CI. The freeze is not a refusal, though: a fix
# the build genuinely needs is picked by name, and --list shows the walk when
# you are looking for one. Frozen is detected from the lineage under the seed,
# not configured; see the seed check below.
#
# A conflict stops the sequence in place and keeps the worktree: resolving it
# is the routine's judgement. Continue the sequence there, push, and rerun
# this script to finish — the patch-id filter makes reruns cheap and exact.
#
# Ported and sync commits are ordinary -dev commits: they vendor nothing (the
# consumption anchor in scripts/series-advance.sh reads vendor subjects), and
# they are transient — a forward's seed already carries their content, and a
# rebase drops patch-id equivalents and empty leftovers.
#
# Usage: series-port.sh <series> [--list] [--apply [sha...]]

set -euo pipefail

S=${1:?usage: series-port.sh <series> [--list] [--apply [sha...]]}
shift
# --list walks a frozen series anyway, for when the question is which commit of
# `main` to name. No effect on any other series: the walk is their default.
list=
if [ "${1:-}" = "--list" ]; then
  list=1
  shift
fi
apply=
if [ "${1:-}" = "--apply" ]; then
  apply=1
  shift
fi
remote=origin

# The identity set: what CI and the routine execute. patch/ stays out
# (vendor-coupled: applied by vendor runs, refreshed by repairs), as do the
# root docs (README.md is flavored per branch, NEWS.md belongs to the release
# strand) — commits touching them are still listed and picked like any other,
# but the sync commit never rewrites them.
tooling=(.github scripts .claude)
paths_re='^(\.github/|scripts/|\.claude/)'
# A vendor commit is one whose subject says it vendored: the `vendor:` prefix
# vendor-one.sh writes, or the `<owner>/<repo>@<sha>` reference that carries the
# upstream commit as machine-readable state. Same rule as every other reader of
# the strand — see the header on why the path is not the rule.
vendor_subject_re='^vendor:|duckdb/duckdb@[0-9a-f]+'

# scripts/flavor.sh's first commit, and so the foot of every seed
# (series-open.md step 2, series-forward.md step 1).
seed_re='^chore: Update flavor patch to '

git fetch -q "$remote"
dev="$remote/$S-dev" main="$remote/main"
git rev-parse -q --verify "$dev" >/dev/null || { echo "Error: no $S-dev on $remote"; exit 1; }

mb=$(git merge-base "$dev" "$main" 2>/dev/null || true)
if [ -z "$mb" ]; then
  # A series seeded from an orphan mirror shares no history with `main`, so
  # there is no base to bound the walk at and `git cherry` has nothing to
  # compare against. Say so instead of dying on the empty expansion.
  echo "$S: no merge base with main — the series is an unrelated lineage," >&2
  echo "  so stage 4 cannot port onto it; sync its tooling by hand" >&2
  exit 2
fi

# Frozen is read off the series, not listed here. A series is seeded from the R
# package's `main` (series-open.md step 2), and a forward regenerates that seed
# on current `main` (series-forward.md step 1), so a well-seeded series has its
# flavor commit sitting directly on the merge base and `git cherry` offers what
# `main` gained since the last port. Seeded from a release line instead, the
# seed sits on that line's own commits, and the walk reaches back to where that
# lineage left `main` — the whole R development line of another engine.
#
# The lineage under the seed is what separates them, and it is the one quantity
# that does not move: the candidate list and the distance to the join both grow
# as `main` does, while a well-seeded series stays at zero however long it runs.
# Naming the series here instead would age — every LTS line opened or retired
# would be an edit to this script, and a firing would trust the list over the
# branch in front of it.
seed=$(git rev-list "$mb..$dev" --grep="$seed_re" | tail -n 1)
under=0
[ -n "$seed" ] && under=$(git rev-list --count "$mb..$seed^")
frozen=
[ "$under" != 0 ] && frozen=1

# Files a version bump is allowed to carry and still be nothing but a bump:
# DESCRIPTION itself, plus the release paperwork fledge writes beside it. Both
# belong to the release strand, and neither is in the tooling set the sync
# commit rewrites, so dropping the commit drops nothing the series executes.
bump_paths_re='^(DESCRIPTION|NEWS\.md|cran-comments\.md)$'

# Is this commit a version bump and nothing else? Two questions, both of which
# have to answer yes:
#
#   * `Version:` moved -- read against the first parent rather than from the
#     diff, so a merge commit answers as truthfully as an ordinary one. The
#     content is the fact, not the subject: a bump is one whatever it is called,
#     and `fledge:` is only today's name for it.
#   * it carries nothing else. A commit that bumps the version *and* changes the
#     package is a forward-port that happens to bump, and it is ported like any
#     other, because a pick is a whole commit and never half of one. `Sync with
#     main` (4e41675f9) is the shape this guards: a bump riding on 130 files of
#     tooling, R code, tests and patches, which classifying by the version line
#     alone would have dropped whole.
version_bump() { # <sha>
  local before after f
  before=$(git show "$1^:DESCRIPTION" 2>/dev/null | sed -n 's/^Version: //p' || true)
  after=$(git show "$1:DESCRIPTION" 2>/dev/null | sed -n 's/^Version: //p' || true)
  [ -n "$after" ] && [ "$before" != "$after" ] || return 1
  while IFS= read -r f; do
    [[ "$f" =~ $bump_paths_re ]] || return 1
  done < <(git diff-tree --no-commit-id --name-only -r "$1")
  return 0
}

classify() { # <sha> -> TOOLING | MIXED | OTHER | VENDOR | VERSION
  local f t= o=
  if [[ "$(git log -1 --format=%s "$1")" =~ $vendor_subject_re ]]; then echo VENDOR; return; fi
  if version_bump "$1"; then echo VERSION; return; fi
  while IFS= read -r f; do
    if [[ "$f" =~ $paths_re ]]; then t=1; else o=1; fi
  done < <(git diff-tree --no-commit-id --name-only -r "$1")
  if [ -n "$t" ] && [ -n "$o" ]; then
    echo MIXED
  elif [ -n "$t" ]; then
    echo TOOLING
  else
    echo OTHER
  fi
}

candidates=()
declare -A klass=()

# Every commit of `main` the series does not carry, oldest first. Two dedupe
# layers make reruns exact: `git cherry` bounds the walk at the merge base and
# drops patch-id equivalents (clean picks), and the `-x` trailer written into
# every ported commit excludes picks whose resolution diverged from the
# original patch — those would otherwise be re-offered and re-conflict on
# every rerun.
#
# A frozen series skips the walk rather than listing what it will not take by
# default: the list is long — an LTS line joins `main` far back, so `git cherry`
# offers the whole development line since the fork — and reading it every firing
# is the cost the freeze exists to remove. --list asks for it anyway, which is
# what to do when the series needs a fix `main` already has.
if [ -n "$frozen" ] && [ -z "$list" ]; then
  echo "$S: frozen — nothing is ported by default; tooling follows main." \
    "Name a fix the build needs with --apply <sha>, or --list to see candidates"
else
  declare -A ported=()
  while IFS= read -r x; do ported[$x]=1; done < <(
    git log --format=%B "$mb..$dev" |
      sed -n 's/^(cherry picked from commit \([0-9a-f]\{40\}\))$/\1/p')
  mapfile -t all < <(git cherry "$dev" "$main" | sed -n 's/^+ //p')
  for sha in "${all[@]}"; do
    [ -n "${ported[$sha]:-}" ] && continue
    candidates+=("$sha")
    klass[$sha]=$(classify "$sha")
    printf '%-7s %s %s\n' "${klass[$sha]}" \
      "$(git rev-parse --short "$sha")" "$(git log -1 --format=%s "$sha")"
  done
fi

if git diff --quiet "$dev" "$main" -- "${tooling[@]}"; then
  echo "tooling: identical to main"
else
  echo "tooling: differs from main —$(git diff --shortstat "$dev" "$main" -- "${tooling[@]}")"
fi

[ -n "$apply" ] || exit 0

# A pick can still meet DESCRIPTION's `Version:` -- a named VERSION commit, a
# forward-port that carries one -- and the ours-version merge driver is what
# keeps that line off the conflict list. Idempotent; .git/config is shared with
# the worktree.
if [ -x "$(dirname "$0")/setup-git.sh" ]; then
  "$(dirname "$0")/setup-git.sh" >/dev/null
fi

# The default fill is what a frozen series does not get: `--list --apply` shows
# the walk and still ports nothing, because seeing the candidates is not the
# same as choosing them. Explicit SHAs are the choosing, and they always apply.
picks=("$@")
if [ ${#picks[@]} -eq 0 ] && [ -z "$frozen" ]; then
  for sha in "${candidates[@]}"; do
    case "${klass[$sha]}" in VENDOR | VERSION) continue ;; esac
    picks+=("$sha")
  done
fi

wt=$(mktemp -d)
git worktree add --detach -q "$wt" "$dev"

# `-x` records the main commit in the message; `--empty=drop` skips a pick
# whose content arrived some other way. On conflict the worktree stays: the
# sequencer holds the remaining picks, so one --continue walks the rest.
if [ ${#picks[@]} -gt 0 ] && ! git -C "$wt" cherry-pick -x --empty=drop "${picks[@]}"; then
  echo "Conflict; worktree kept at $wt, conflicted files:"
  git -C "$wt" diff --name-only --diff-filter=U | sed 's/^/  /'
  echo "Resolve toward main's intent, then:"
  echo "  git -C $wt cherry-pick --continue    # repeats through the rest"
  echo "  git -C $wt push $remote HEAD:refs/heads/$S-dev"
  echo "  git worktree remove --force $wt"
  echo "  scripts/series-port.sh $S --apply    # finish: leftovers + sync"
  exit 1
fi

# Close the residue: make the tooling paths byte-identical to main's. `git rm`
# first, so a file the series has and main does not is deleted rather than
# kept — checkout alone only adds and overwrites.
if ! git -C "$wt" diff --quiet "$main" -- "${tooling[@]}"; then
  git -C "$wt" rm -qr --ignore-unmatch -- "${tooling[@]}"
  git -C "$wt" checkout "$main" -- "${tooling[@]}"
  git -C "$wt" commit -q -m "chore(series): Sync tooling with main" \
    -m "Takes main's ${tooling[*]} verbatim on top of the ported commits;
the diff is the residue the commit walk could not explain."
fi
git -C "$wt" diff --quiet "$main" -- "${tooling[@]}" ||
  { echo "Error: tooling still differs after sync"; exit 1; }

next=$(git -C "$wt" rev-parse HEAD)
git worktree remove --force "$wt"
if [ "$next" = "$(git rev-parse "$dev")" ]; then
  echo "nothing to port"
  exit 0
fi
git push "$remote" "$next:refs/heads/$S-dev"
echo "dev -> $(git rev-parse --short "$next")"
