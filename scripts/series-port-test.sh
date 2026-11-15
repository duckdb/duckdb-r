#!/bin/bash
# Check which commits stage 4 offers, offline, against a synthetic remote and
# clone built here -- no network, no fixtures on disk.
#
# The question is what "the branch has it and the series does not" means. The
# walk reads the branch's first parents by patch-id, so a lineage merged in is
# never offered commit by commit: one merged for its ancestry alone -- a merge
# whose tree is its first parent's -- brings nothing, and one merged for its
# content, a forward merge among them, is offered as one port of its change.
# What is checked:
#
#   1. An ordinary `main` commit the series lacks is offered.
#   2. A commit that reached `main` only through an ancestry-only merge is not.
#   3. Nor is the ancestry-only merge itself.
#   4. A real merge is not an ancestry-only one: it changed main's tree, so
#      it is offered, as one port, and its side commits are not offered alone.
#      The test is the tree, not the shape of the commit.
#   5. Release paperwork is held back whether or not it moves `Version:`:
#      notes written into NEWS.md for main's next release belong to the release
#      strand, and the series has no section to put them in. A commit that
#      edits DESCRIPTION without moving the version is package content and is
#      still offered.
#   6. A forward merge of a release branch, keeping main's engine, is offered
#      as one port carrying its R-side fix and the glue folded into its vendor
#      commit and no engine; neither commit behind it is offered alone, and a
#      rerun names the same port. --apply of one that changes only engine
#      paths says there is nothing to port and picks nothing.
#   7. A series whose `releases_from` names a release branch takes its R side
#      from that branch and not from `main`; one declared `stale: true` is
#      frozen, its forward with it; one releasing from `main` takes `main`'s.
#   8. --apply keeps the series' NEWS.md on every pick. A commit that brings
#      code and a NEWS.md entry applies cleanly after `main` has renamed the
#      section the series carries too, under its own author and trailer, and
#      leaves the series' NEWS.md as it was; a commit that writes nothing but
#      NEWS.md comes out empty and is committed empty, so its trailer retires it.
#   9. A ported commit keeps the whole message of the commit it ports, a
#      `# Conflicts:` line in its body included, and then the trailer; so does
#      the commit the guidance prints when a pick conflicts. The message is
#      byte for byte the one a real `cherry-pick -x` writes, for a message with
#      a `---` line above its trailers, one already ending in a cherry-pick
#      line, one with CRLF line ends and one with trailing whitespace.
#  10. A conflict on the last commit named by hand prints no rerun, because a
#      bare --apply would port what the named subset left out, and says the
#      tooling sync waits; one on an earlier commit prints a rerun with the
#      commits named after it. The commands it prints forget what rerere
#      recorded, as a clean pick does.
#  11. On a stale series the default set is empty, so a conflict on the only
#      commit named prints the bare --apply, and running it adds the tooling
#      sync and nothing else.
#  12. The NEWS.md merge driver and the port do not fight. A forward merge
#      whose sides both opened a NEWS.md section merges cleanly by the driver,
#      and its port onto a series with a NEWS.md of its own, the driver
#      registered there too, applies with no conflict, keeps the series'
#      NEWS.md as it was, records nothing for rerere, and is not offered again.
#
# And one thing about *which* `main` answers. The series live in a fork whose
# `main` is a mirror the Pull app refreshes every six hours, so the fork's copy
# is routinely behind the canonical repository's. The walk reads the canonical
# one, so a commit merged since the last sync is offered rather than silently
# reverted by the tooling sync; with no canonical remote to read, the mirror is
# the fallback and answers with the subset it has.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)

SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "     unexpected: $3" ;; *) ok "$1" ;; esac; }

# --- the fixture -----------------------------------------------------------
#
# A bare remote plus a clone, because stage 4 reads `origin/*`. The shape is
# `main` with three things above the series' seed: an ordinary commit, a
# lineage merged for its ancestry alone, and a lineage merged for its content.

REMOTE=$SCRATCH/remote.git
CANON=$SCRATCH/canonical.git
WORK=$SCRATCH/work
git init -q --bare -b main "$REMOTE"
git init -q --bare -b main "$CANON"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$REMOTE"
git remote add upstream "$CANON"

mkdir -p scripts .github R
for s in series-port.sh setup-git.sh merge-version.sh merge-news.sh series-config.sh series-lib.sh vendor-lib.sh; do
  cp "$HERE/$s" scripts/
done
chmod +x scripts/*.sh
printf '%s\n' 'DESCRIPTION merge=ours-version' 'NEWS.md merge=news' > .gitattributes

# The attributes are committed and the name -> command mappings are not, so a
# fresh clone has the first and never the second. Register them here, as every
# real clone does, so every pick below meets both drivers.
scripts/setup-git.sh >/dev/null

printf 'Package: duckdb\nVersion: 1.0.0\n' > DESCRIPTION
echo 'workflow' > .github/ci.yml
echo 'foo <- function() 1' > R/foo.R
git add -A
git commit -qm 'chore: The base both lineages share'
git branch fork-point

# --- the series: a seed on `main`, so the walk is not frozen ----------------

git checkout -q -b s-dev
echo 'flavored' > R/flavor.R
git add -A
git commit -qm 'chore: Update flavor patch to duckdb.test'

# --- what `main` gains ------------------------------------------------------

git checkout -q main
echo 'foo <- function() 2' > R/foo.R
git add -A
git commit -qm 'fix: An ordinary commit the series lacks'

# A lineage from another era, merged for its ancestry alone: `-s ours` keeps
# main's tree, so nothing of it is in the package `main` builds.
git checkout -q -b old-line fork-point
echo 'ancient <- function() 1' > R/ancient.R
git add -A
git commit -qm 'feat: Ancient work that never reached the tree'
echo 'ancient <- function() 2' > R/ancient.R
git add -A
git commit -qm 'fix: More of the same'
git checkout -q main
git merge -q -s ours --no-ff -m 'chore: Record the old tag on the mainline' old-line

# A lineage merged for its content: an ordinary merge, whose commits did reach
# main's tree and are therefore still the series' to take.
git checkout -q -b live-line main
echo 'live <- function() 1' > R/live.R
git add -A
git commit -qm 'feat: Live work that did reach the tree'
git checkout -q main
git merge -q --no-ff -m 'chore: Merge the live line' live-line

# The release strand, in the shapes that reach `main`: the hand-written bump,
# whose NEWS.md starts with the section it closes, the same under another
# subject, the notes written beside it before the bump lands, and a
# DESCRIPTION edit that is not a bump at all.
printf '# duckdb 1.0.0\n\n- Something a user meets.\n' > NEWS.md
git add -A
git commit -qm 'docs(news): Bullets for what merged since the last bump'

printf 'Package: duckdb\nVersion: 1.0.1\n' > DESCRIPTION
printf '# duckdb 1.0.1\n\n- Something a user meets.\n' > NEWS.md
git add -A
git commit -qm 'chore: Bump version to 1.0.1'

printf 'Package: duckdb\nVersion: 1.0.1.9000\n' > DESCRIPTION
git add -A
git commit -qm 'chore: Move on to the development version'

printf 'Package: duckdb\nVersion: 1.0.1.9000\nImports: DBI\n' > DESCRIPTION
git add -A
git commit -qm 'chore: Declare the dependency the package gained'

git push -q origin main s-dev
git push -q upstream main

# --- the mirror falls behind ------------------------------------------------
#
# One more commit reaches the canonical repository and not the fork's copy of
# `main`, which is the state the fork is in for most of the Pull app's cycle.

echo 'foo <- function() 3' > R/foo.R
git add -A
git commit -qm 'fix: A commit the mirror has not picked up yet'
git push -q upstream main
git checkout -q s-dev

# --- the read ---------------------------------------------------------------

out=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out"

echo "series-port.sh: which commits stage 4 offers"
has "an ordinary commit is offered" "$out" 'An ordinary commit the series lacks'
hasnt "ancestry-only content is not offered" "$out" 'Ancient work that never reached the tree'
hasnt "nor the rest of that lineage" "$out" 'More of the same'
hasnt "nor the ancestry-only merge itself" "$out" 'Record the old tag on the mainline'
has "a real merge is offered as one port" "$out" 'chore: Merge the live line'
hasnt "  and the commit behind it is not offered alone" "$out" 'Live work that did reach the tree'

# The class of the listed commit whose subject contains the given text.
klass() { echo "$out" | grep -F -- "$2" | head -n 1 | awk '{print $1}'; }
is() { # <name> <subject text> <expected class>
  local got
  got=$(klass "$1" "$2")
  if [ "$got" = "$3" ]; then ok "$1"; else no "$1"; echo "       $3 expected, got ${got:-nothing}"; fi
}

echo
echo "series-port.sh: what the release strand covers"
is "the hand-written bump is release paperwork" 'Bump version to 1.0.1' VERSION
is "so is a bump under any other subject" 'Move on to the development version' VERSION
is "so are notes written without a bump" \
  'Bullets for what merged since the last bump' VERSION
is "a DESCRIPTION edit that is not a bump is package content" \
  'Declare the dependency the package gained' OTHER

echo
echo "series-port.sh: which \`main\` answers"
has "a commit the mirror lacks is offered" "$out" 'A commit the mirror has not picked up yet'
hasnt "and a behind mirror is not a refusal" "$out" 'commit(s) behind'

# With no canonical remote to read, the mirror answers -- with the subset it
# has, and saying so, rather than with a refusal.
out_fork=$(SERIES_CANONICAL= scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_fork"
hasnt "the fallback offers only what the mirror has" "$out_fork" 'A commit the mirror has not picked up yet'
has "and still offers what it does have" "$out_fork" 'An ordinary commit the series lacks'

echo
echo "series-port.sh: a line on a release branch of its own"
# The series is seeded on `main`, and its line has a release branch cut from
# `main` where that seed sits. Its R side comes from that branch: a fix there is
# offered, and `main`'s later work is not.
git checkout -q -B s-baseline "$(git merge-base s-dev main)"
mkdir -p R
echo 'release fix' > R/release-fix.R
git add -A; git commit -qm 'fix: A fix on the release branch'
git push -q -f upstream s-baseline
git checkout -q main
cat > scripts/series.yaml <<'EOF'
flavors:
  - flavor: duckdb.test
    kind: dev
    series: s
    releases_from: s-baseline
    publishes_from: s-green

  - flavor: duckdb.other
    kind: dev
    series: other
    releases_from: main
    publishes_from: other-green
EOF
git add scripts/series.yaml
git commit -qm 'chore: Release the line of series s from its own branch'
git push -q upstream main
git checkout -q s-dev
out_rel=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_rel"
hasnt "a line on its own release branch is not frozen" "$out_rel" "frozen"
has "it is offered that branch's fix" "$out_rel" 'A fix on the release branch'
hasnt "and not main's R side" "$out_rel" 'An ordinary commit the series lacks'

echo
echo "series-port.sh: a stale line"
git checkout -q main
sed -i 's/releases_from: s-baseline/releases_from: s-baseline\n    stale: true/' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Mark the line of series s stale'
git push -q upstream main
git checkout -q s-dev
out_parked=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_parked"
has "a stale line is frozen" "$out_parked" "s: frozen (stale)"
hasnt "and offers no R-side commit" "$out_parked" 'A fix on the release branch'

# Its forward is the same line, stale with it.
git push -q origin s-dev:refs/heads/s-fwd-dev
out_fwd=$(scripts/series-port.sh s-fwd 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_fwd"
has "and so is its forward" "$out_fwd" "s-fwd: frozen (stale)"

# A branch it cannot read stops the port, rather than reading as stale.
git checkout -q main
sed -i 's/releases_from: s-baseline/releases_from: s-nowhere/; /stale: true/d' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Name a branch that does not exist'
git push -q upstream main
git checkout -q s-dev
out_gone=$(scripts/series-port.sh s 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_gone"
has "a branch it cannot read is said so" "$out_gone" "could not read s-nowhere"
hasnt "  and not called stale" "$out_gone" "(stale)"
if [ "$st" -ne 0 ]; then ok "  and stops the port"; else no "  and stops the port"; fi
git checkout -q main
sed -i 's/releases_from: s-nowhere/releases_from: s-baseline/' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Name the release branch again'
git push -q upstream main

# A line declared on `main` is live, and says nothing about freezing.
git checkout -q main
sed -i 's/releases_from: s-baseline/releases_from: main/; /stale: true/d' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Release the line of series s from main again'
git push -q upstream main
git checkout -q s-dev
out_live=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_live"
hasnt "a line releasing from main is not frozen" "$out_live" "frozen"
has "and is offered main's R side" "$out_live" 'An ordinary commit the series lacks'

# A forward merge: the release branch, cut from main, takes a vendor commit
# whose engine main must not take, with glue folded into it, and an R-side fix;
# main merges it forward keeping its own engine. The merge is offered as one
# port, its change outside the engine; neither commit behind it is offered alone.
git checkout -q main
git checkout -q -b rel-line
mkdir -p src/duckdb src
echo 'engine of the release line' > src/duckdb/engine.cpp
echo 'glue the release engine needed' > src/glue.cpp
git add -A; git commit -qm 'vendor: Update vendored sources to duckdb/duckdb@abcdef0123'
echo 'fix rel' > R/rel-fix.R
git add -A; git commit -qm 'fix: A fix written on the release branch'
git checkout -q main
git merge -q --no-commit --no-ff rel-line
git rm -rq --cached --ignore-unmatch -- src/duckdb
git checkout HEAD -- src/duckdb 2>/dev/null || true
git clean -fdq -- src/duckdb
git commit -qm 'Merge rel-line forward into main'
MERGE=$(git rev-parse HEAD)
git push -q upstream main
git checkout -q s-dev
out_fwd=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_fwd"
has "the forward merge is offered as one port" "$out_fwd" 'Merge rel-line forward into main'
hasnt "the fix behind it is not offered alone" "$out_fwd" 'A fix written on the release branch'
hasnt "nor the vendor commit behind it" "$out_fwd" 'duckdb/duckdb@abcdef0123'
PORT=$(sed -n 's/^[A-Z]* *\([0-9a-f]*\) Merge rel-line forward into main$/\1/p' <<<"$out_fwd")
same() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
same "the port carries the fix" "$(git show "$PORT:R/rel-fix.R" 2>&1)" 'fix rel'
same "and the glue folded into the vendor commit" "$(git show "$PORT:src/glue.cpp" 2>&1)" 'glue the release engine needed'
same "and no engine" "$(git ls-tree -r --name-only "$PORT" -- src/duckdb | wc -l)" 0
out_again=$(GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=true \
  GIT_CONFIG_KEY_1=gpg.program GIT_CONFIG_VALUE_1=false scripts/series-port.sh s 2>&1 || true)
has "a rerun names the same commit, signing configured or not" "$out_again" "$PORT Merge rel-line forward into main"

# A fresh clone has no stand-in until it walks; --apply of the port's short SHA,
# or of the merge's own, ports the merge's change all the same.
SDEV=$(git rev-parse s-dev)
for named in "${PORT:0:10}" "$(git rev-parse --short "$MERGE")"; do
  rm -rf "$SCRATCH/fresh"
  git clone -q "$REMOTE" "$SCRATCH/fresh"
  # shellcheck disable=SC2015  # any failure is read off the output below
  out_apply=$(cd "$SCRATCH/fresh" &&
    git config user.name Test && git config user.email test@example.invalid && git config commit.gpgsign false &&
    git remote add upstream "$CANON" && git checkout -q s-dev && scripts/setup-git.sh >/dev/null &&
    scripts/series-port.sh s --apply "$named" 2>&1 || true)
  [ -z "${KEEP:-}" ] || echo "$out_apply"
  # The pick is what is checked; the fixture carries no tooling tree for the
  # sync that follows it to compare, so nothing reaches the remote here, and
  # the pick is read in the worktree the failed sync keeps.
  kept=$(git -C "$SCRATCH/fresh" worktree list --porcelain | sed -n 's/^worktree //p' | sed -n 2p)
  has "--apply $named in a fresh clone picks the merge's port" "$out_apply" "picked ${PORT:0:7}"
  has "  under the trailer of the port" "$(git -C "${kept:-/nonexistent}" log -1 --format=%B 2>&1)" "(cherry picked from commit $(git rev-parse "$PORT"))"
  same "  carrying its fix" "$(git -C "${kept:-/nonexistent}" show HEAD:R/rel-fix.R 2>&1)" 'fix rel'
  [ -z "$kept" ] || rm -rf "$kept"
  git push -q -f origin "$SDEV:refs/heads/s-dev"
done

# A forward merge that brings only an engine change has nothing to port:
# --apply of it says so and picks nothing.
git checkout -q rel-line
echo 'engine of the release line, again' > src/duckdb/engine.cpp
git add -A; git commit -qm 'vendor: Update vendored sources to duckdb/duckdb@abcdef4567'
git checkout -q main
git merge -q --no-commit --no-ff rel-line >/dev/null 2>&1 || true
git rm -rq --cached --ignore-unmatch -- src/duckdb
git checkout HEAD -- src/duckdb 2>/dev/null || true
git clean -fdq -- src/duckdb
git commit -qm 'Merge an engine-only change forward into main'
EMERGE=$(git rev-parse HEAD)
git push -q upstream main
git checkout -q s-dev
out_eng=$(scripts/series-port.sh s --apply "$EMERGE" 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_eng"
has "--apply of an engine-only merge says there is nothing to port" "$out_eng" \
  "$(git rev-parse --short "$EMERGE"): nothing to port: the merge changes only engine paths"
same "  and succeeds" "$st" 0
same "  and picks nothing" "$(git ls-remote origin refs/heads/s-dev | cut -f1)" "$SDEV"
hasnt "  not even what the walk offers" "$out_eng" $'\npicked '

echo
echo "series-port.sh: --apply keeps the series' NEWS.md"
# A series cut from `main`, carrying a NEWS.md entry of its own, and `main`
# renaming the section both carry afterwards and starting a new one above it.
# Picked whole, that commit conflicts in NEWS.md on the series.
git checkout -q main
printf '# duckdb (development version)\n\n- A bullet both have.\n\n# duckdb 1.0.1\n\n- Something a user meets.\n' > NEWS.md
git add -A
git commit -qm 'docs(news): A bullet both have'
git push -q upstream main
git checkout -q -b t-dev
echo 'flavored t' > R/flavor.R
printf '# duckdb (development version)\n\n- A bullet of the series.\n\n- A bullet both have.\n\n# duckdb 1.0.1\n\n- Something a user meets.\n' > NEWS.md
git add -A
git commit -qm 'chore: Update flavor patch to duckdb.t'
git push -q origin t-dev
series_news=$(git show HEAD:NEWS.md)
git checkout -q main
printf 'Package: duckdb\nVersion: 1.1.0\nImports: DBI\n' > DESCRIPTION
sed -i 's/^# duckdb (development version)$/# duckdb 1.1.0/' NEWS.md
git add -A
git commit -qm 'chore: Bump version to 1.1.0'
echo 'foo <- function() 4' > R/foo.R
{ printf '# duckdb (development version)\n\n- Code with its bullet.\n\n'; cat NEWS.md; } > NEWS.md.new
mv NEWS.md.new NEWS.md
git add -A
GIT_AUTHOR_NAME='Main Author' GIT_AUTHOR_EMAIL=main@example.invalid \
  git commit -qm 'feat: Code with its bullet'
CODE=$(git rev-parse HEAD)
sed -i 's/^- Code with its bullet\.$/&\n\n- A bullet alone./' NEWS.md
git add -A
git commit -qm 'docs(news): A bullet alone'
NEWS_ONLY=$(git rev-parse HEAD)
git push -q upstream main
git checkout -q --detach

out_apply=$(scripts/series-port.sh t --apply 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_apply"
git fetch -q origin
if [ "$st" = 0 ]; then ok "the code-and-bullet commit applies after the rename"; else no "the code-and-bullet commit applies after the rename"; printf '%s\n' "$out_apply" | sed 's/^/       /'; fi
hasnt "with no conflict on the way" "$out_apply" CONFLICT
has "and says it picked it" "$out_apply" "picked $(git rev-parse --short "$CODE") feat: Code with its bullet"
if [ "$(git show origin/t-dev:NEWS.md)" = "$series_news" ]; then ok "the series' NEWS.md is unchanged"; else no "the series' NEWS.md is unchanged"; fi
if [ "$(git show origin/t-dev:R/foo.R)" = "$(git show "$CODE:R/foo.R")" ]; then ok "and the code arrived"; else no "and the code arrived"; fi
has "under the original author" "$(git log -1 --format='%an <%ae>' origin/t-dev)" 'Main Author <main@example.invalid>'
has "with the trailer that retires the pick" "$(git log -1 --format=%B origin/t-dev)" "(cherry picked from commit $CODE)"
out_again=$(scripts/series-port.sh t 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_again"
hasnt "so the pick is not offered again" "$out_again" 'Code with its bullet'
has "while the NEWS-only commit is listed as release paperwork" "$out_again" "VERSION $(git rev-parse --short "$NEWS_ONLY") docs(news): A bullet alone"

tip=$(git rev-parse origin/t-dev)
out_news=$(scripts/series-port.sh t --apply "$NEWS_ONLY" 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_news"
git fetch -q origin
if [ "$st" = 0 ]; then ok "a NEWS-only commit named by hand is no error"; else no "a NEWS-only commit named by hand is no error"; printf '%s\n' "$out_news" | sed 's/^/       /'; fi
has "it is committed empty, and says why" "$out_news" "picked $(git rev-parse --short "$NEWS_ONLY") docs(news): A bullet alone, empty: nothing but NEWS.md is left of it"
if [ "$(git rev-parse origin/t-dev^)" = "$tip" ] && git diff --quiet "$tip" origin/t-dev; then ok "as one empty commit on the series"; else no "as one empty commit on the series"; fi
has "whose trailer records the pick" "$(git log -1 --format=%B origin/t-dev)" "(cherry picked from commit $NEWS_ONLY)"
out_again=$(scripts/series-port.sh t 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_again"
hasnt "so a rerun no longer lists it" "$out_again" 'A bullet alone'

echo
echo "series-port.sh: a message whose body lists conflicts"
# A squash keeps the messages of the commits it squashed, and a merge resolved
# by hand writes a `# Conflicts:` list into its own, so `main` has such lines in
# commit bodies. The commit touches NEWS.md as well, so its port has no patch-id
# in common with it, and only the trailer stops it being offered again.
git checkout -q main
echo 'bar <- function() 1' > R/bar.R
sed -i 's/^- Code with its bullet\.$/&\n\n- A bullet beside more code./' NEWS.md
git add -A
printf '%s\n' 'feat: Code squashed from a merge resolved by hand' '' \
  'The squashed branch merged main and resolved it.' '' \
  '# Conflicts:' '#	R/bar.R' '' 'What follows the list is the rest of the body.' |
  git commit -q --cleanup=verbatim -F -
SQUASH=$(git rev-parse HEAD)
git push -q upstream main
git checkout -q --detach
out_squash=$(scripts/series-port.sh t --apply 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_squash"
git fetch -q origin
if [ "$st" = 0 ]; then ok "the squash applies"; else no "the squash applies"; printf '%s\n' "$out_squash" | sed 's/^/       /'; fi
has "and is picked" "$out_squash" "picked $(git rev-parse --short "$SQUASH") feat: Code squashed from a merge resolved by hand"
squash_msg=$(printf '%s\n\n(cherry picked from commit %s)' "$(git log -1 --format=%B "$SQUASH")" "$SQUASH")
if [ "$(git log -1 --format=%B origin/t-dev)" = "$squash_msg" ]; then
  ok "the port keeps the whole body, then the trailer"
else
  no "the port keeps the whole body, then the trailer"
  git log -1 --format=%B origin/t-dev | sed 's/^/       /'
fi
out_again=$(scripts/series-port.sh t 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_again"
hasnt "so the squash is not offered again" "$out_again" 'Code squashed from a merge resolved by hand'

echo
echo "series-port.sh: the message a real \`cherry-pick -x\` writes"
# Shapes whose layout a verbatim commit, or a footer read only up to a `---`
# line, got wrong; each committed verbatim on `main`, and all ported in one run.
git checkout -q main
shapes=(
  $'feat: A divider above the trailers\n\nBody.\n---\nNotes after the divider.\n\nReviewed-by: A Reviewer <r@example.invalid>'
  $'fix: A message already picked once\n\nBody.\n\n(cherry picked from commit 0123456789abcdef0123456789abcdef01234567)'
  $'fix: A message with CRLF line ends\r\n\r\nBody.\r\n\r\nSigned-off-by: A U Thor <a@example.invalid>\r\n'
  $'fix: A message with trailing whitespace  \n\nBody.\t\n\n\n\nMore body.   \n\n\n'
)
labels=('a --- line above the trailers' 'a message already ending in a cherry-pick line'
  'CRLF line ends' 'trailing whitespace and repeated blank lines')
shape_shas=()
for k in "${!shapes[@]}"; do
  echo "msg $k" > "R/msg$k.R"
  git add -A
  printf '%s' "${shapes[$k]}" | git commit -q --cleanup=verbatim -F -
  shape_shas+=("$(git rev-parse HEAD)")
done
git push -q upstream main
git checkout -q --detach
out_shapes=$(scripts/series-port.sh t --apply "${shape_shas[@]}" 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_shapes"
git fetch -q origin
if [ "$st" = 0 ]; then ok "the shapes apply"; else no "the shapes apply"; printf '%s\n' "$out_shapes" | sed 's/^/       /'; fi
message_of() { git cat-file commit "$1" | sed '1,/^$/d'; }
for k in "${!shape_shas[@]}"; do
  c=${shape_shas[$k]}
  git checkout -q --detach "$c^"
  git cherry-pick -x "$c" >/dev/null
  message_of HEAD > "$SCRATCH/real.msg"
  port=$(git log -1 --format=%H -F --grep="(cherry picked from commit $c)" origin/t-dev)
  if [ -n "$port" ] && message_of "$port" > "$SCRATCH/port.msg" &&
    cmp -s "$SCRATCH/real.msg" "$SCRATCH/port.msg"; then
    ok "${labels[$k]}: the port's message is cherry-pick -x's"
  else
    no "${labels[$k]}: the port's message is cherry-pick -x's"
    diff <(od -c "$SCRATCH/real.msg") <(od -c "$SCRATCH/port.msg") | sed 's/^/       /' || true
  fi
done
git checkout -q --detach

echo
echo "series-port.sh: a conflict on a commit named by hand"
# Three commits on `main`: one the named subset leaves out, one that applies,
# and one that conflicts with the series' own flavor file, its body listing
# conflicts of its own.
git checkout -q main
echo 'baz <- function() 1' > R/baz.R
git add -A
git commit -qm 'feat: Code the named subset leaves out'
echo 'qux <- function() 1' > R/qux.R
git add -A
git commit -qm 'feat: Code that applies'
CLEAN=$(git rev-parse HEAD)
echo 'flavored on main' > R/flavor.R
git add -A
printf '%s\n' 'fix: Code that conflicts with the flavor' '' \
  '# Conflicts:' '#	R/flavor.R' '' 'The body goes on after the list.' |
  git commit -q --cleanup=verbatim -F -
CONFLICT=$(git rev-parse HEAD)
git push -q upstream main
git checkout -q --detach

out_last=$(scripts/series-port.sh t --apply "$CLEAN" "$CONFLICT" 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_last"
if [ "$st" != 0 ]; then ok "a conflict on the last named commit stops the port"; else no "a conflict on the last named commit stops the port"; fi
has "after the commit before it is picked" "$out_last" "picked $(git rev-parse --short "$CLEAN") feat: Code that applies"
has "and names the conflicted file" "$out_last" '  R/flavor.R'
hasnt "with nothing named left, it prints no rerun" "$out_last" 'series-port.sh t --apply'
has "and says the tooling sync waits for the next --apply" "$out_last" 'The tooling sync waits for the next --apply'

# The printed commands, run after a resolution that keeps the series' file: the
# resolution is empty, the commit still carries the whole message, and rerere
# keeps no resolution of the pick, as after a clean one.
kept_at() { printf '%s\n' "$1" | sed -n 's/^Conflict; worktree kept at \(.*\), conflicted files:$/\1/p'; }
printed() { printf '%s\n' "$1" | grep -E "^  git -C [^ ]+ $2" || true; }
recorded() { find "$(git rev-parse --git-common-dir)/rr-cache" -name postimage 2>/dev/null | wc -l; }
wt=$(kept_at "$out_last")
clear_cmd=$(printed "$out_last" 'rerere clear$')
commit_cmd=$(printed "$out_last" 'commit ')
if [ -n "$wt" ] && [ -n "$clear_cmd" ] && [ -n "$commit_cmd" ]; then
  echo 'flavored t' > "$wt/R/flavor.R"
  git -C "$wt" add R/flavor.R
  before=$(recorded)
  eval "$clear_cmd" >/dev/null 2>&1
  eval "$commit_cmd" >/dev/null 2>&1
  if [ "$(recorded)" = "$before" ]; then ok "the printed commands record no resolution"; else no "the printed commands record no resolution"; fi
  conflict_msg=$(printf '%s\n\n(cherry picked from commit %s)' "$(git log -1 --format=%B "$CONFLICT")" "$CONFLICT")
  if [ "$(git -C "$wt" log -1 --format=%B)" = "$conflict_msg" ]; then
    ok "the printed commit keeps the whole body, then the trailer"
  else
    no "the printed commit keeps the whole body, then the trailer"
    git -C "$wt" log -1 --format=%B | sed 's/^/       /'
  fi
  if git -C "$wt" diff --quiet HEAD^ HEAD; then ok "and commits an empty resolution"; else no "and commits an empty resolution"; fi
  git worktree remove --force "$wt"
else
  no "the guidance names the worktree and the commit to run"
fi

out_first=$(scripts/series-port.sh t --apply "$CONFLICT" "$CLEAN" 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_first"
has "a conflict on an earlier named commit prints a rerun with the rest" "$out_first" "scripts/series-port.sh t --apply $CLEAN "
wt=$(kept_at "$out_first")
[ -z "$wt" ] || git worktree remove --force "$wt"

echo
echo "series-port.sh: a conflict on a frozen series"
# A stale line, parked on its own baseline, and `main` moving its tooling and
# the file the line flavors. The one commit named conflicts, and the bare --apply is
# what finishes the port, since on this series it takes nothing else. The
# tooling `main` gains includes a `.claude/`, so the sync finds every tooling
# path it takes.
git checkout -q -b f-dev main
git push -q upstream main:refs/heads/f-baseline
echo 'flavored f' > R/flavor.R
git add -A
git commit -qm 'chore: Update flavor patch to duckdb.f'
git push -q origin f-dev
git checkout -q main
printf '%s\n' '' '  - flavor: duckdb.f' '    kind: dev' '    series: f' \
  '    releases_from: f-baseline' '    stale: true' '    publishes_from: f-green' >> scripts/series.yaml
mkdir -p .claude
echo '{}' > .claude/settings.json
git add scripts/series.yaml .claude
git commit -qm 'chore: Mark the line of series f stale'
echo 'flavored on main again' > R/flavor.R
git add -A
git commit -qm 'fix: Code that conflicts with the parked flavor'
FROZEN_CONFLICT=$(git rev-parse HEAD)
git push -q upstream main
git checkout -q --detach
out_frozen=$(scripts/series-port.sh f --apply "$FROZEN_CONFLICT" 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_frozen"
if [ "$st" != 0 ]; then ok "a conflict on the only named commit stops the port"; else no "a conflict on the only named commit stops the port"; fi
rerun=$(printf '%s\n' "$out_frozen" | grep -E '^  scripts/series-port\.sh f --apply +# ' || true)
has "and prints the bare --apply that finishes the tooling sync" "$rerun" 'finish: the tooling sync'
hasnt "  and not that the sync waits" "$out_frozen" 'The tooling sync waits'
wt=$(kept_at "$out_frozen")
if [ -n "$wt" ] && [ -n "$rerun" ]; then
  echo 'flavored f' > "$wt/R/flavor.R"
  git -C "$wt" add R/flavor.R
  before=$(recorded)
  for step in 'rerere clear$' 'commit ' 'push '; do
    eval "$(printed "$out_frozen" "$step")" >/dev/null 2>&1
  done
  if [ "$(recorded)" = "$before" ]; then ok "the printed commands record no resolution"; else no "the printed commands record no resolution"; fi
  resolved=$(git -C "$wt" rev-parse HEAD)
  git worktree remove --force "$wt"
  out_rerun=$(eval "$rerun" 2>&1) && st=0 || st=$?
  [ -z "${KEEP:-}" ] || echo "$out_rerun"
  git fetch -q origin
  if [ "$st" = 0 ]; then ok "running it succeeds"; else no "running it succeeds"; printf '%s\n' "$out_rerun" | sed 's/^/       /'; fi
  added=$(git log --format=%s "$resolved..origin/f-dev")
  if [ "$added" = 'chore(series): Sync tooling with main' ]; then
    ok "and adds the tooling sync alone"
  else
    no "and adds the tooling sync alone"
    printf '%s\n' "${added:-nothing}" | sed 's/^/       /'
  fi
else
  no "the guidance names the worktree and the rerun"
fi

echo
echo "series-port.sh: a forward merge onto a series with a NEWS.md of its own"
# `main` and a release branch cut from it each open a NEWS.md section, so a
# line merge conflicts at the top of the file, and the news driver merges the
# forward merge by section instead. A series cut before the merge carries a
# bullet of its own. Its port of the merge meets the same driver, which would
# merge the release's section into the series' file cleanly; the port keeps
# the series' NEWS.md all the same, so the driver's result never reaches it.
git checkout -q main
printf '# duckdb 1.1.0.9000\n\n- A bullet both have.\n\n# duckdb 1.1.0\n\n- Something a user meets.\n' > NEWS.md
git add -A
git commit -qm 'docs(news): Lay the sections out by version'
git checkout -q -b rel2-line
{ printf '# duckdb 1.1.1\n\n- A fix with its bullet.\n\n'; cat NEWS.md; } > NEWS.md.new
mv NEWS.md.new NEWS.md
echo 'fix rel2' > R/rel2-fix.R
git add -A
git commit -qm 'fix: A fix with its bullet on the release branch'
git checkout -q main
{ printf '# duckdb 1.1.99.9000\n\n- A bullet of the newer line.\n\n'; cat NEWS.md; } > NEWS.md.new
mv NEWS.md.new NEWS.md
git add -A
git commit -qm 'docs(news): Open the section of the newer line'
git push -q upstream main
git checkout -q -b u-dev
echo 'flavored u' > R/flavor.R
sed -i 's/^- A bullet both have\.$/- A bullet of the series.\n\n&/' NEWS.md
git add -A
git commit -qm 'chore: Update flavor patch to duckdb.u'
git push -q origin u-dev
series_news=$(git show HEAD:NEWS.md)
git checkout -q main
if git merge -q --no-ff -m 'Merge rel2-line forward into main' rel2-line >/dev/null 2>&1; then
  ok "the forward merge takes both sections with no conflict"
else
  no "the forward merge takes both sections with no conflict"
  git merge --abort
fi
same "  newest version first" "$(grep '^# duckdb ' NEWS.md | tr '\n' ' ')" \
  '# duckdb 1.1.99.9000 # duckdb 1.1.1 # duckdb 1.1.0.9000 # duckdb 1.1.0 '
git push -q upstream main
git checkout -q --detach

out_list=$(scripts/series-port.sh u 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_list"
PORT2=$(sed -n 's/^[A-Z]* *\([0-9a-f]*\) Merge rel2-line forward into main$/\1/p' <<<"$out_list")
has "the forward merge is offered as one port" "$out_list" 'Merge rel2-line forward into main'
# What the driver alone makes of the series' file, for comparison.
git worktree add --detach -q "$SCRATCH/driver" origin/u-dev
if git -C "$SCRATCH/driver" cherry-pick -n "${PORT2:-HEAD}" >/dev/null 2>&1; then
  ok "  a plain pick of it merges NEWS.md by the driver, cleanly"
else
  no "  a plain pick of it merges NEWS.md by the driver, cleanly"
fi
has "  taking the release's section into the series' file" "$(git -C "$SCRATCH/driver" show :NEWS.md 2>&1)" '# duckdb 1.1.1'
git worktree remove --force "$SCRATCH/driver"

before=$(recorded)
out_fm=$(scripts/series-port.sh u --apply 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out_fm"
git fetch -q origin
if [ "$st" = 0 ]; then ok "the port applies"; else no "the port applies"; printf '%s\n' "$out_fm" | sed 's/^/       /'; fi
hasnt "with no conflict on the way" "$out_fm" CONFLICT
has "and picks the merge's port" "$out_fm" "picked ${PORT2:0:7}"
same "the series' NEWS.md is unchanged" "$(git show origin/u-dev:NEWS.md)" "$series_news"
same "and the fix arrived" "$(git show origin/u-dev:R/rel2-fix.R 2>&1)" 'fix rel2'
same "and rerere recorded no resolution" "$(recorded)" "$before"
out_again=$(scripts/series-port.sh u 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_again"
hasnt "so the port is not offered again" "$out_again" 'Merge rel2-line forward into main'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
