#!/bin/bash
# Check which commits stage 4 offers, offline, against a synthetic remote and
# clone built here -- no network, no fixtures on disk.
#
# The question is what "`main` has it and the series does not" means. `git
# cherry` answers by patch-id over `mb..main`, which counts a commit `main`
# merged for its ancestry alone -- a merge whose tree is its first parent's, so
# nothing of the lineage it records ever entered main's tree. Porting one
# applies a tree from another era on top of this one. What is checked:
#
#   1. An ordinary `main` commit the series lacks is offered.
#   2. A commit that reached `main` only through an ancestry-only merge is not.
#   3. Nor is the ancestry-only merge itself.
#   4. A real merge is not an ancestry-only one: its side commits did reach
#      main's tree, so they are still offered. The test is the tree, not the
#      shape of the commit.
#   5. Release paperwork is held back whether or not it moves `Version:`:
#      notes written into NEWS.md for main's next release belong to the release
#      strand, and the series has no section to put them in. A commit that
#      edits DESCRIPTION without moving the version is package content and is
#      still offered.
#   6. A graft, a release branch taken with `git merge -s ours` after `main`
#      picked what it wanted, offers that pick and nothing the second parent
#      brings.
#   7. --apply keeps the series' NEWS.md on every pick. A commit that brings
#      code and a bullet under `main`'s open section applies cleanly after a
#      landing has renamed that heading, under its own author and trailer, and
#      leaves the series' NEWS.md as it was; a commit that writes nothing but
#      NEWS.md comes out empty and is committed empty, so its trailer retires it.
#   8. A ported commit keeps the whole message of the commit it ports, a
#      `# Conflicts:` line in its body included, and then the trailer; so does
#      the commit the guidance prints when a pick conflicts. The message is
#      byte for byte the one a real `cherry-pick -x` writes, for a message with
#      a `---` line above its trailers, one already ending in a cherry-pick
#      line, one with CRLF line ends and one with trailing whitespace.
#   9. A conflict on the last commit named by hand prints no rerun, because a
#      bare --apply would port what the named subset left out; one on an
#      earlier commit prints a rerun with the commits named after it. The
#      commands it prints forget what rerere recorded, as a clean pick does.
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
for s in series-port.sh setup-git.sh merge-version.sh series-config.sh series-lib.sh vendor-lib.sh; do cp "$HERE/$s" scripts/; done
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes

# The attribute is committed and the name -> command mapping is not, so a fresh
# clone has the first and never the second. Register it here, as every real
# clone does.
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
has "a real merge's content is still offered" "$out" 'Live work that did reach the tree'

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
echo "series-port.sh: a line parked in \`main\`'s declaration"
# The series is seeded on `main`, so its lineage says it is not frozen, and a
# line parked by a landing is in exactly that shape: `main` keeps the history
# its seed sits on. The declaration is what says it parked.
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
git commit -qm 'chore: Park the line of series s'
git push -q upstream main
git checkout -q s-dev
out_parked=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_parked"
has "a parked line is frozen" "$out_parked" "s: frozen (parked on s-baseline)"
hasnt "and offers no R-side commit" "$out_parked" 'An ordinary commit the series lacks'

# Its forward is the same line, parked with it.
git push -q origin s-dev:refs/heads/s-fwd-dev
out_fwd=$(scripts/series-port.sh s-fwd 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_fwd"
has "and so is its forward" "$out_fwd" "s-fwd: frozen (parked on s-baseline)"

# A line declared on `main` is live, and says nothing about parking.
git checkout -q main
sed -i 's/releases_from: s-baseline/releases_from: main/' scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: Release the line of series s from main again'
git push -q upstream main
git checkout -q s-dev
out_live=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_live"
hasnt "a line releasing from main is not frozen" "$out_live" "frozen"
has "and is offered main's R side" "$out_live" 'An ordinary commit the series lacks'

# A graft: `main` takes a release branch cut from it with `-s ours`, after
# picking the one fix it wants. Only that pick, a commit of `main`'s own, is
# offered; what the graft's second parent brings never is.
git checkout -q main
git checkout -q -b rel-line
echo 'fix rel' > R/rel-fix.R
git add -A; git commit -qm 'fix: A fix on the release branch, picked onto main'
RELFIX=$(git rev-parse HEAD)
echo 'only rel' > R/rel-only.R
git add -A; git commit -qm 'fix: A fix main declines'
git checkout -q main
git cherry-pick -x "$RELFIX" >/dev/null
git merge -q -s ours --no-edit -m 'chore: Graft rel-line

Declined: the fix main does without.' rel-line
git push -q upstream main
git checkout -q s-dev
out_graft=$(scripts/series-port.sh s 2>&1)
[ -z "${KEEP:-}" ] || echo "$out_graft"
has "the pick main made is offered" "$out_graft" 'A fix on the release branch, picked onto main'
hasnt "the commit the graft declined is not" "$out_graft" 'A fix main declines'
hasnt "nor the graft itself" "$out_graft" 'Graft rel-line'

echo
echo "series-port.sh: --apply keeps the series' NEWS.md"
# A series cut from `main` while its section was open, carrying a bullet of its
# own, and `main` releasing that section afterwards: the bump turns the heading
# into the version's, and the next bullet opens a new section above it. Picked
# whole, that commit conflicts in NEWS.md on the series.
git checkout -q main
printf '# duckdb (development version)\n\n- A bullet both have.\n\n# duckdb 1.0.1\n\n- Something a user meets.\n' > NEWS.md
git add -A
git commit -qm 'docs(news): A bullet under the open section'
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
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
