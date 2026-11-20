#!/bin/bash
# Check the landing of a series on `main`, offline, against a synthetic fork,
# canonical repository and clone built here: no network, no fixtures on disk.
#
# The claim scripts/series-land.sh makes is that `<L>-land-dev` is `main` plus
# the series' vendor commits and a version bump, and nothing else, and that its tip is the package
# the series' rc strand holds. Fifteen things are checked.
#
#   1. Without --push the build writes no ref, and says what it would write.
#   2. Only vendor commits land, on `main` itself, unflavored.
#   3. Each is stamped with the series' prefix and a counter of its own.
#   4. A first pick whose old parent vendors another engine than `main` takes
#      the vendored strand whole, and the glue and test fix it folded with it.
#      A later pick that conflicts with what `main` changed stops the build,
#      which resumes on a rerun without skipping a version number.
#   5. A tooling sync the base cannot reverse-apply is placed by its subject
#      rather than stranding the run, and a port `main` carries is not replayed.
#   6. The tree check explains what the landing takes from `main` by
#      construction, `NEWS.md` and the READMEs, and nothing else; the counter
#      reproduces the series' version even where `main` carries five components
#      of its own, so `DESCRIPTION` agrees.
#   7. --push writes `<L>-land-dev` and `<L>-land-green` at the base together.
#   8. A rebuild from the same inputs mints the same SHAs, and the conflict
#      resolved once is resolved again by rerere without stopping.
#   9. --status advances green over the commits the store passed, names the
#      first one it has not, and prints the fast-forward once every one passed.
#      --review writes the landing's R side alone onto `main`, one commit per
#      landing commit that changes it, with every workflow removed first.
#      A fix above the vendor commits is out of place, though its subject names
#      the engine it was made against.
#      A landing is ready only on its hand-written version bump, which may
#      change nothing but NEWS.md, the Version: line and the
#      Config/duckdb/upstream: line, the full SHA of the engine the last vendor
#      commit vendors, with nothing above it, whatever NEWS.md holds, and the
#      alpha stamp of its parent's engine, READY only while upstream's pointer
#      names that alpha and not when the pointer cannot be read, until the
#      branch is the bump, which needs the pointer no longer. --stamp-alpha
#      refuses an engine with no alpha or one with a gap in its extensions,
#      and names the stamp a worktree holds of an alpha the pointer has moved
#      past, with the checkout that drops it; it succeeds again on its own stamp, warns on an engine not the source's, and
#      writes nothing for a release engine, whose bump needs no stamp; a rebuild
#      drops a bump added to the kept worktree. Step 6's tag block, read off
#      the series-land skill, runs the tag commands printed with the
#      fast-forward only on READY; run once `main` has the bump, they tag it
#      `duckdb <version>`, with NEWS.md's section for it below where there is,
#      its heading bare or dated; run before that, even with a tag named like
#      the branch at the bump, or over a stale local tag of that name, they
#      fail and send nothing. On a landing not READY the block stops before
#      them. A release's version is tagged `v<version>.9900`,
#      `duckdb <version>.9900` with the version's section, and never
#      `v<version>`, the release's own: that tag on another commit does not
#      stop it, and a stale local tag of the new name does.
#  10. A resolution rerere replays wrongly is named when the check fails, and
#      an attended rebuild stops there so it can be forgotten and redone. A
#      kept build follows the rc strand when the series moves on.
#  11. A landing stands on a base above `main`: the base's own commit lands
#      with it, is expected by the tree check, is judged by CI from `main` up,
#      and shows in the review as it is.
#  12. The tests are held to the base's: a landing whose tip runs them all says
#      so, and one that stops a test the base runs is refused before anything
#      is pushed, naming the test and the commit, though the tree check passes.
#  13. A `main` that moved stops a kept build and is not READY, and a rebuild
#      on it that the series has not ported is refused before anything is
#      pushed, `DESCRIPTION` included.
#  14. A fresh build up to a ref --source names fetches it first, so a stale
#      copy from an earlier fetch is not what it builds.
#  15. The branch landed on is the series' `releases_from` in `main`'s
#      scripts/series.yaml: the build stands on its tip, --status prints its
#      fast-forward, --review targets it, and the version bump has to rise
#      above that branch's version too. A `-fwd` series is refused, and so is
#      one series.yaml does not declare, except `main`'s own; a bump with no
#      vendor commit under it is not a landing; and without a canonical remote
#      the script says so itself.
#
# Usage:
#   scripts/series-land-test.sh
#
# Environment variables:
#   KEEP - if non-empty, do not delete the scratch directory

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SCRATCH=$(mktemp -d)
[ -n "${KEEP:-}" ] || trap 'rm -rf "$SCRATCH"' EXIT
[ -z "${KEEP:-}" ] || echo "scratch: $SCRATCH"
export TMPDIR=$SCRATCH

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok   $1"; }
no() { fail=$((fail + 1)); echo "  FAIL $1"; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1"; echo "         actual: $2"; echo "       expected: $3"; fi; }
has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1"; echo "       missing: $3" ;; esac; }
hasnt() { case "$2" in *"$3"*) no "$1"; echo "     unexpected: $3" ;; *) ok "$1" ;; esac; }

# --- the fixture -----------------------------------------------------------
#
# `main` at a base B, a series seeded on B the way series-forward seeds one, and
# `main` moving on from B: it vendors a newer engine of its own line, takes an
# R-side fix and two tooling changes, and bumps its version. The series ports
# the fix and syncs the tooling twice, and vendors three commits of its own line.

FORK=$SCRATCH/fork.git
CANON=$SCRATCH/canonical.git
WORK=$SCRATCH/work
git init -q --bare -b main "$FORK"
git init -q --bare -b main "$CANON"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name Test
git config user.email test@example.invalid
git config commit.gpgsign false
git remote add origin "$FORK"
git remote add upstream "$CANON"

mkdir -p scripts R src/duckdb/src/function/table/version tests/testthat .github/workflows
for s in series-land.sh series-forward-build.sh series-rc.sh series-tests.sh setup-git.sh merge-version.sh \
  series-config.sh series-lib.sh vendor-lib.sh; do
  cp "$HERE/$s" scripts/
done
chmod +x scripts/*.sh
echo 'DESCRIPTION merge=ours-version' > .gitattributes
scripts/setup-git.sh >/dev/null

desc() { printf 'Package: %s\nVersion: %s\n' "$1" "$2" > DESCRIPTION; }
engine() { # <id> <R version>
  echo "engine $1" > src/duckdb/engine.cpp
  echo "#define DUCKDB_SOURCE_ID \"$1\"" > src/duckdb/src/function/table/version/pragma_version.cpp
  echo "duckdb_version <- \"$2\"" > R/version.R
}
commit() { git add -A; git commit -qm "$1"; }

desc duckdb 1.5.5.9000
engine aaaa111 1.5.5
echo 'rename duckdb.1.3 duckdb_1_3' > scripts/flavor.patch
echo 'tool v1' > scripts/tool.sh
echo 'on: pull_request' > .github/workflows/ci.yaml
echo 'pkg <- "duckdb"' > R/package.R
echo 'foo <- function() 1' > R/foo.R
echo 'glue 1' > src/glue.cpp
echo 'test 1' > tests/testthat/test-foo.R
printf 'a\nb\nc\n' > tests/testthat/test-bar.R
echo '# duckdb 1.5.5.9000' > NEWS.md
printf 'flavors:\n  - flavor: duckdb.x.dev\n    kind: dev\n    series: v2.0-x\n    releases_from: main\n' > scripts/series.yaml
echo 'readme at the base' > README.md
commit 'vendor: Update vendored sources to duckdb/duckdb@aaaa111 (#1)'
B=$(git rev-parse HEAD)

# `main` moves on.
engine aaaa112 1.5.6
commit 'vendor: Update vendored sources to duckdb/duckdb@aaaa112 (#2)'
echo 'foo <- function() 2' > R/foo.R
commit 'fix: An R-side fix on main (#3)'
P=$(git rev-parse HEAD)
printf 'a\nb main\nc\n' > tests/testthat/test-bar.R
commit 'test: A test main adjusted (#9)'
Q=$(git rev-parse HEAD)
echo 'tool v2' > scripts/tool.sh
commit 'ci: A tooling change (#4)'
echo 'tool v3' > scripts/tool.sh
commit 'ci: Another tooling change (#5)'
desc duckdb 1.5.6.9001.7
echo '# duckdb 1.5.6.9001.7' > NEWS.md
commit 'chore: Bump version to 1.5.6.9001.7 (#6)'
echo 'readme on main' > README.md
commit 'docs: The README main renders today (#7)'
M=$(git rev-parse HEAD)
git push -q upstream main
git push -q origin main

# The series: three seed commits on B, as flavor.sh and series-forward write them.
git checkout -q -b s "$B"
echo 'rename duckdb.2.0.dev duckdb_2_0_dev' > scripts/flavor.patch
commit 'chore: Update flavor patch to duckdb.2.0.dev'
echo 'pkg <- "duckdb.2.0.dev"' > R/package.R
desc duckdb.2.0.dev 1.5.5.9000
commit 'chore: Update version to 2.0.dev'
desc duckdb.2.0.dev 1.99.99.9000.0
commit 'chore: Add fifth version component'

engine bbbb222 1.99.99-dev1
echo 'glue 2, adapted to bbbb222' > src/glue.cpp
echo 'test 2, as bbbb222 answers' > tests/testthat/test-foo.R
desc duckdb.2.0.dev 1.99.99.9000.1
commit 'vendor: Update vendored sources to duckdb/duckdb@bbbb222'
git cherry-pick -x "$P" >/dev/null
echo 'tool v2' > scripts/tool.sh
commit 'chore(series): Sync tooling with main'
engine cccc333 1.99.99-dev2
printf 'a\nb v2\nc\n' > tests/testthat/test-bar.R
desc duckdb.2.0.dev 1.99.99.9000.2
commit 'vendor: Update vendored sources to duckdb/duckdb@cccc333'
# The port of `main`'s test change meets the line cccc333 adapted, and is
# resolved by hand, as stage 4 resolves one.
git cherry-pick -x "$Q" >/dev/null 2>&1 || true
printf 'a\nb v2 main\nc\n' > tests/testthat/test-bar.R
git add tests/testthat/test-bar.R
GIT_EDITOR=true git cherry-pick --continue >/dev/null
echo 'tool v3' > scripts/tool.sh
commit 'chore(series): Sync tooling with main'
engine dddd444 1.99.99-dev3
echo 'test 3, as dddd444 answers' > tests/testthat/test-foo.R
desc duckdb.2.0.dev 1.99.99.9000.3
commit 'vendor: Update vendored sources to duckdb/duckdb@dddd444'
git push -q origin s:refs/heads/v2.0-x-dev
git checkout -q main

scripts/series-rc.sh v2.0-x --push >/dev/null 2>&1
git fetch -q origin
RC=$(git rev-parse origin/v2.0-x-rc-dev)

# The resolution the port above recorded would answer the landing's conflict
# too, since rerere matches the hunk whichever side it is on; a clone that never
# saw it is the case to check first.
rm -rf "$(git rev-parse --git-common-dir)/rr-cache"

# --- 1: a build without --push ------------------------------------------------

echo "== a build stops on a conflict, and resumes"
out=$(scripts/series-land.sh v2.0-x --no-check-glue 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "the build stops" "$st" 1
has "on the pick that meets main's change" "$out" "Conflict at"
has "and keeps the build" "$out" "the build stopped and is kept"
read -r WT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
printf 'a\nb v2 main\nc\n' > "$WT/tests/testthat/test-bar.R"
git -C "$WT" add tests/testthat/test-bar.R

echo
echo "== a build without --push writes no ref"
out=$(scripts/series-land.sh v2.0-x --no-check-glue 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "it reports the landing" "$out" "3 vendor commits on $(git rev-parse --short "$M")"
has "and that it was not pushed" "$out" "Not pushed; --push writes v2.0-x-land-dev"
is "no land-dev on the fork" "$(git ls-remote origin refs/heads/v2.0-x-land-dev | wc -l)" 0
rout=$(scripts/series-land.sh v2.0-x --review 2>&1) && st=0 || st=$?
is "nothing to review before the landing is pushed" "$st" 1
has "and it says so" "$rout" "build and --push it first"

TIP=$(git -C "$WT" rev-parse HEAD)

# --- 2, 3, 4, 5: what landed ------------------------------------------------

echo
echo "== only vendor commits land, on main, unflavored, counted"
is "the first landing commit stands on main" "$(git rev-parse "$TIP~3")" "$M"
is "every commit above main vendors" \
  "$(git log --format=%s "$M..$TIP" | grep -vc '^vendor:' || true)" 0
is "the subjects are the series' own, oldest first" \
  "$(git log --reverse --format=%s "$M..$TIP" | sed 's/.*@//' | tr '\n' ' ')" \
  "bbbb222 cccc333 dddd444 "
is "the versions count this chain" \
  "$(for c in $(git rev-list --reverse "$M..$TIP"); do
       git show "$c:DESCRIPTION" | sed -n 's/^Version: //p'; done | tr '\n' ' ')" \
  "1.99.99.9000.1 1.99.99.9000.2 1.99.99.9000.3 "
is "the package is main's name" "$(git show "$TIP:DESCRIPTION" | sed -n 's/^Package: //p')" duckdb
is "and so is the R code the flavor renames" "$(git show "$TIP:R/package.R")" 'pkg <- "duckdb"'

FIRST=$(git rev-parse "$TIP~2")
is "the rewind took the strand whole" "$(git show "$FIRST:src/duckdb/engine.cpp")" "engine bbbb222"
is "R/version.R with it" "$(git show "$FIRST:R/version.R")" 'duckdb_version <- "1.99.99-dev1"'
is "and the glue it folded" "$(git show "$FIRST:src/glue.cpp")" "glue 2, adapted to bbbb222"
is "and the test fix" "$(git show "$FIRST:tests/testthat/test-foo.R")" "test 2, as bbbb222 answers"
is "main's R-side fix is there from the start" "$(git show "$FIRST:R/foo.R")" 'foo <- function() 2'
is "and main's tooling" "$(git show "$FIRST:scripts/tool.sh")" "tool v3"

# --- 6: the tree check ------------------------------------------------------

echo
echo "== the tip is the package the rc strand holds"
has "NEWS.md is main's" "$out" "NEWS.md"
has "the README is main's" "$out" "README.md"
is "the tip carries the series' version" "$(git show "$TIP:DESCRIPTION" | sed -n 's/^Version: //p')" \
  "$(git show "$RC:DESCRIPTION" | sed -n 's/^Version: //p')"
hasnt "so DESCRIPTION is no difference at all" "$out" "DESCRIPTION"
hasnt "nothing is unexplained" "$out" "UNEXPLAINED"
has "and every test main runs, the landing runs" "$out" "TESTS KEPT"
is "the trees agree everywhere else" \
  "$(git diff --name-only "$TIP" "$RC" -- . ':(exclude)NEWS.md' ':(exclude)README.md' ':(exclude)DESCRIPTION')" ""

# --- 7: --push --------------------------------------------------------------

echo
echo "== --push writes both refs"
out=$(scripts/series-land.sh v2.0-x --no-check-glue --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
git fetch -q origin
is "land-dev is the tip" "$(git rev-parse origin/v2.0-x-land-dev)" "$TIP"
is "land-green is main" "$(git rev-parse origin/v2.0-x-land-green)" "$M"

# --- 8: a rebuild mints the same SHAs ---------------------------------------

echo
echo "== a rebuild from the same inputs is the same chain"
scripts/series-land.sh v2.0-x --abort >/dev/null
out=$(scripts/series-land.sh v2.0-x --no-check-glue --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "rerere resolved the conflict" "$out" "rerere resolved that stop; continuing"
has "nothing to push" "$out" "v2.0-x-land-dev: already on origin"

# --- 9: --status ------------------------------------------------------------

echo
echo "== --status moves green over what passed"
C1=$(git rev-parse "$TIP~2")
C2=$(git rev-parse "$TIP~1")
git checkout -q --orphan rcc2
git rm -rqf .
rec() { # <sha> <state>
  mkdir -p "runs2.d/${1:0:2}"
  printf '{"commit":"%s","status":{"context":"rcc","state":"%s"}}\n' "$1" "$2" \
    > "runs2.d/${1:0:2}/$1.ndjson"
}
rec "$C1" success
rec "$C2" success
commit 'chore: store stub'
git push -q origin rcc2
git checkout -q main

out=$(scripts/series-land.sh v2.0-x --status --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "it counts what passed" "$out" "2 of 3 commits above v2.0-x-land-green passed"
has "and names the first that has not" "$out" "first not passed: $(git rev-parse --short "$TIP") (missing)"
git fetch -q origin
is "green moved over the two" "$(git rev-parse origin/v2.0-x-land-green)" "$C2"
hasnt "it is not ready" "$out" "READY"

git checkout -q rcc2
rec "$TIP" success
commit 'chore: store stub, the tip'
git push -q origin rcc2
git checkout -q main
out=$(scripts/series-land.sh v2.0-x --status --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "every commit passed, but the landing does not end on the bump" "$out" "NOT READY: v2.0-x-land-dev does not end on the version bump"
hasnt "so it prints no fast-forward" "$out" "git push upstream"

echo
echo "== --review writes the R side alone"
# The canonical remote is a path here, so its repository is named in the config.
git config remote.upstream.github test/canonical
out=$(scripts/series-land.sh v2.0-x --review --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "it counts the commits that change the R side" "$out" "3 of 3 landing commits change the R side"
has "and prints the draft pull request" "$out" "gh pr create --repo test/canonical --draft"
has "with what the landing does to the tests" "$out" "changed   tests/testthat/test-foo.R"
git fetch -q upstream v2.0-x-land-review
REV=$(git rev-parse upstream/v2.0-x-land-review)
is "it stands on main" "$(git rev-parse "$REV~4")" "$M"
is "its first commit removes every workflow" "$(git ls-tree -r --name-only "$REV~3" -- .github/workflows | wc -l)" 0
is "the engine is main's" "$(git show "$REV:src/duckdb/engine.cpp")" "engine aaaa112"
is "and so is the version" "$(git show "$REV:DESCRIPTION" | sed -n 's/^Version: //p')" "1.5.6.9001.7"
is "everything else is the landing's" \
  "$(git diff --name-only "$REV" "$TIP" -- . ':(exclude)src/duckdb' ':(exclude)R/version.R' \
    ':(exclude)DESCRIPTION' ':(exclude).github/workflows')" ""
is "no subject reads as a vendor commit" "$(git log --format=%s "$M..$REV" | grep -c 'duckdb/duckdb@' || true)" 0
is "each names the landing commit it halves" \
  "$(git log -1 --format=%B "$REV" | sed -n 's/^Landing-commit: //p')" "$TIP"
sleep 1 # a date not pinned would differ by now
out=$(scripts/series-land.sh v2.0-x --review --push 2>&1) || true
has "a rerun mints the same branch" "$out" "v2.0-x-land-review: already on upstream"

# --- 9b: the version bump ------------------------------------------------------

echo
echo "== a hand-written version bump is the last commit"
dev_at() { git push -q -f origin "$1:refs/heads/v2.0-x-land-dev"; }
passed() { # <sha>
  git checkout -q rcc2
  rec "$1" success
  commit 'chore: store stub'
  git push -q origin rcc2
  git checkout -q main
}
bump_msg='chore: Bump version to 1.99.99.9001 with hand-written release notes'
ENGINE_FULL=dddd444000000000000000000000000000000000
# DESCRIPTION alone: a landing's bump writes the version's NEWS.md section,
# but the script does not read that file, so a bump without it is accepted.
write_bump() { # <version> [<engine record>]
  sed -i "/^Config\/duckdb\/upstream:/d; s/^Version: .*/Version: $1\nConfig\/duckdb\/upstream: ${2-$ENGINE_FULL}/" DESCRIPTION
}
# Step 6's tag block, read off the skill by the marker above it and set to this
# fixture's series rather than `main`: it reruns --status and runs the tag
# commands printed there only on READY, so its gate and its sed are the skill's
# own, and a drift between the skill and --status fails here.
awk '$0 == "<!-- series-land: tag block -->" {m = 1; next} m && $0 == "```sh" {f = 1; next} f && $0 == "```" {exit} f' \
  "$HERE/../.claude/skills/series-land/SKILL.md" | sed 's/^S=main /S=v2.0-x /' > "$SCRATCH/tag-block"
is "step 6's tag block is read off the skill, for this series" "$(grep -c '^S=v2.0-x ' "$SCRATCH/tag-block")" 1
# Runs it as a maintainer pastes it, and prints whether it failed, then the
# tag's target and message upstream, or that upstream is as it was.
tag_as_printed() { # <tag>
  local refs
  refs=$(git -C "$CANON" for-each-ref)
  bash "$SCRATCH/tag-block" >/dev/null 2>&1 || echo "the tag block failed"
  [ "$(git -C "$CANON" for-each-ref)" != "$refs" ] || { echo "upstream is unchanged"; return; }
  git -C "$CANON" rev-parse -q --verify "refs/tags/$1^{commit}" || echo "no $1 on upstream"
  git -C "$CANON" tag -l --format='%(contents)' "$1"
}
# The fast-forward --status prints, and its undoing.
landed() { git push -q upstream "$1:refs/heads/main"; }
unlanded() { git push -q -f upstream "$M:refs/heads/main"; }
status_of() { # <sha>: put it at the tip of land-dev, passed, and ask
  dev_at "$1"
  git cat-file -e "rcc2:runs2.d/${1:0:2}/$1.ndjson" 2>/dev/null || passed "$1"
  out=$(PATH="${STUB:+$STUB:}$PATH" scripts/series-land.sh v2.0-x --status 2>&1) && st=0 || st=$?
  [ -z "${KEEP:-}" ] || echo "$out"
}
refused() { # <label>: the probe in the working tree is committed under the bump's subject
  commit "${BSUBJ:-$bump_msg}"
  local sha
  sha=$(git rev-parse HEAD)
  status_of "$sha"
  is "$1" "$st" 1
  has "  and names it" "$out" "carries a commit out of place: $(git rev-parse --short "$sha")"
  [ -z "${2:-}" ] || has "  and says why" "$out" "$2"
  git checkout -q -f main
}
probe() { git checkout -q -f -B probe "$TIP"; }

dev_at "$TIP"
is "on a landing that does not end on the bump, the tag block stops at its READY gate and sends nothing" \
  "$(tag_as_printed v1.99.99.9001)" "the tag block failed"$'\n'"upstream is unchanged"

probe
write_bump 1.99.99.9001
commit "$bump_msg"
BUMP=$(git rev-parse HEAD)
status_of "$BUMP"
is "the bump leaves NEWS.md alone" "$(git diff --name-only "$BUMP~1" "$BUMP")" DESCRIPTION
has "the landing ending on the bump is ready" "$out" "READY: every commit has passed"
has "and the fast-forward names the bump" "$out" "git push upstream $BUMP:refs/heads/main"
has "and so does the tag" "$out" "git tag -a v1.99.99.9001 --cleanup=whitespace -F - $BUMP"
has "which goes to the canonical repository" "$out" "git push upstream refs/tags/v1.99.99.9001"
hasnt "  under its version as it is, four components being no release" "$out" ".9900"
has "they fetch the branch by its full name into its remote-tracking ref" "$out" \
  "git fetch -q upstream +refs/heads/main:refs/remotes/upstream/main &&"
has "  and look for the bump there, not in FETCH_HEAD" "$out" "git merge-base --is-ancestor $BUMP refs/remotes/upstream/main ||"
is "run as printed while main lacks the bump, as after a fast-forward refused, they send nothing and fail" \
  "$(tag_as_printed v1.99.99.9001)" "the tag block failed"$'\n'"upstream is unchanged"
# A tag named like the branch, at the bump: a fetch by the short name takes it for the branch.
git push -q upstream "$BUMP:refs/tags/main"
is "nor do they while a tag named like the branch has the bump" \
  "$(tag_as_printed v1.99.99.9001)" "the tag block failed"$'\n'"upstream is unchanged"
git push -q upstream :refs/tags/main
git tag -d main >/dev/null 2>&1 || true
landed "$BUMP"
status_of "$BUMP"
has "once main is the bump, the landing is still ready" "$out" "READY: every commit has passed"
is "and run as printed, the tag is the subject alone, NEWS.md having no section for the version" \
  "$(tag_as_printed v1.99.99.9001)" "$BUMP"$'\n''duckdb 1.99.99.9001'
git tag -d v1.99.99.9001 >/dev/null
git push -q upstream :refs/tags/v1.99.99.9001
unlanded
probe; write_bump 1.99.99.9001
{ printf '# duckdb (development version)\n\nCommits since v1.99.99.9001: <https://example.invalid>.\n\n\n'
  printf '# duckdb 1.99.99.9001 (2026-11-17)\n\n## Features\n\n- Something for users.\n\n\n'; cat NEWS.md; } > NEWS.md.new
mv NEWS.md.new NEWS.md
commit "$bump_msg"
NEWS_BUMP=$(git rev-parse HEAD)
status_of "$NEWS_BUMP"
has "a bump that writes the version's section is ready too" "$out" "READY: every commit has passed"
landed "$NEWS_BUMP"
is "and its tag carries the section, its heading dated, below the subject" "$(tag_as_printed v1.99.99.9001)" \
  "$NEWS_BUMP"$'\n''duckdb 1.99.99.9001'$'\n\n''## Features'$'\n\n''- Something for users.'
git push -q upstream :refs/tags/v1.99.99.9001
unlanded
# That bump dropped, its local tag stays behind, and the one that replaces it lands.
status_of "$BUMP"
landed "$BUMP"
is "run as printed over a stale local tag of that name, they send nothing and fail" \
  "$(tag_as_printed v1.99.99.9001)" "the tag block failed"$'\n'"upstream is unchanged"
git tag -d v1.99.99.9001 >/dev/null
unlanded
git checkout -q -f main
probe; write_bump 2.0.0
{ printf '# duckdb 2.0.0\n\n## Features\n\n- The release.\n\n\n'; cat NEWS.md; } > NEWS.md.new
mv NEWS.md.new NEWS.md
commit 'chore: Bump version to 2.0.0'
REL=$(git rev-parse HEAD)
status_of "$REL"
has "a bump to a release is ready" "$out" "READY: every commit has passed"
has "and is tagged with .9900 appended to the release" "$out" "git tag -a v2.0.0.9900 --cleanup=whitespace -F - $REL"
has "  which goes to the canonical repository" "$out" "git push upstream refs/tags/v2.0.0.9900"
is "  never with the release's own tag" "$(grep -cE 'v2\.0\.0( |$)' <<<"$out" || true)" 0
rel_msg="$REL"$'\n''duckdb 2.0.0.9900'$'\n\n''## Features'$'\n\n''- The release.'
landed "$REL"
is "run as printed once main has it, the tag carries the release's section below its own subject" \
  "$(tag_as_printed v2.0.0.9900)" "$rel_msg"
is "  and the release's own tag is not set" "$(git -C "$CANON" tag -l v2.0.0; git tag -l v2.0.0)" ""
git tag -d v2.0.0.9900 >/dev/null
git push -q upstream :refs/tags/v2.0.0.9900
# The release's own tag, on another commit here and upstream.
git tag -a -m 'duckdb 2.0.0' v2.0.0 "$TIP"
git push -q upstream refs/tags/v2.0.0
is "the release's own tag on another commit does not stop it" "$(tag_as_printed v2.0.0.9900)" "$rel_msg"
is "  nor does it move" "$(git -C "$CANON" rev-parse 'refs/tags/v2.0.0^{commit}')" "$TIP"
git push -q upstream :refs/tags/v2.0.0.9900
git tag -f -a -m 'duckdb 2.0.0.9900' v2.0.0.9900 "$TIP" >/dev/null
is "run as printed over a stale local tag of that name, they send nothing and fail" \
  "$(tag_as_printed v2.0.0.9900)" "the tag block failed"$'\n'"upstream is unchanged"
git tag -d v2.0.0 v2.0.0.9900 >/dev/null
git push -q upstream :refs/tags/v2.0.0
unlanded
git checkout -q -f main
dev_at "$BUMP"
out=$(scripts/series-land.sh v2.0-x --review 2>&1) && st=0 || st=$?
is "the review takes it" "$st" 0
hasnt "and does not call it out of place" "$out" "out of place"
git checkout -q -f main

echo "== a bump replayed over a changed DESCRIPTION is refused until stamped again"
# A fold below the bump that touched DESCRIPTION: the replay meets the driver.
GR=$(git ls-remote origin refs/heads/v2.0-x-land-green | cut -f1)
git push -q -f origin "$TIP~1:refs/heads/v2.0-x-land-green"
git checkout -q -f -B replay "$TIP~1"
git checkout -q "$TIP" -- .
sed -i 's/^Package: .*/&\nTitle: Folded/' DESCRIPTION
git add -A
git commit -q -m "$(git log -1 --format=%B "$TIP")"
FOLDED=$(git rev-parse HEAD)
git cherry-pick "$BUMP" >/dev/null 2>&1 || true
is "the replay applies" "$(git log -1 --format=%s)" "$bump_msg"
REPLAYED=$(git rev-parse HEAD)
passed "$FOLDED"
status_of "$REPLAYED"
is "the replayed bump is refused" "$st" 1
has "  for its engine record" "$out" "Config/duckdb/upstream:"
git checkout -q -f replay
eng=$(sed -rn 's/^#define DUCKDB_SOURCE_ID "([0-9a-f]+)"$/\1/p' src/duckdb/src/function/table/version/pragma_version.cpp)
full=${eng}$(printf '0%.0s' $(seq $((40 - ${#eng}))))
v=$(git log -1 --format=%s | sed -n 's/^chore: Bump version to \([^ ]*\).*/\1/p')
sed -i "/^Config\/duckdb\/upstream:/d; s/^Version: .*/Version: $v\nConfig\/duckdb\/upstream: $full/" DESCRIPTION
git commit -q --amend --no-edit DESCRIPTION
STAMPED=$(git rev-parse HEAD)
status_of "$STAMPED"
has "stamped again from the vendored source id, it is ready" "$out" "READY: every commit has passed"
git checkout -q -f main
git branch -q -D replay
git push -q -f origin "$GR:refs/heads/v2.0-x-land-green"

echo "== and it is nothing else"
probe; write_bump 1.99.99.9001; echo 'foo <- function() 99' > R/foo.R
refused "a bump that changes R code is refused" "changes more than NEWS.md and DESCRIPTION"
out=$(scripts/series-land.sh v2.0-x --review 2>&1) && st=0 || st=$?
is "the review refuses it" "$st" 1
probe; write_bump 1.99.99.9001; printf 'Imports: DBI\n' >> DESCRIPTION
refused "nor may it change DESCRIPTION beyond Version: and the engine record"
probe; write_bump 1.99.99.9001; sed -i '/^Config\/duckdb\/upstream:/d' DESCRIPTION
refused "a bump without the engine record is refused" "exactly one Config/duckdb/upstream: line"
probe; write_bump 1.99.99.9001 dddd444
refused "an abbreviated engine record is refused" "is not a full SHA"
probe; write_bump 1.99.99.9001 cccc333000000000000000000000000000000000
refused "an engine record naming another engine is refused" "is not the engine the landing vendors, dddd444"
probe; write_bump 1.99.99.9001; sed -i 's/^Version: .*/&\nVersion: 1.99.99.9002/' DESCRIPTION
refused "nor may it carry two Version: lines"
probe
refused_empty() { git commit -q --allow-empty -m "$bump_msg"; status_of "$(git rev-parse HEAD)"; is "an empty commit is refused" "$st" 1; git checkout -q -f main; }
refused_empty
probe; printf '# duckdb 1.99.99.9001\n\n- Something.\n' > NEWS.md
refused "a NEWS-only commit is refused"
probe; mkdir -p patch; echo 'a regenerated patch' > patch/0001-fix.patch
BSUBJ='fix(patch): Regenerate patch/0001 against the engine at duckdb/duckdb@dddd444' \
  refused "a fix that names the engine it was made against is no vendor commit, and is refused"
probe; write_bump 1.99.99.8999
refused "a lowered version is refused" "does not raise the version"
probe; write_bump 1.99.99.9001.1
refused "a version that keeps a fifth component is refused" "keeps a fifth component"
probe; write_bump 1.99.99.9000
commit 'chore: Bump version to 1.99.99.9000 with hand-written release notes'
status_of "$(git rev-parse HEAD)"
has "the series' version without its vendor counter is a bump, a first landing's" "$out" "READY: every commit has passed"
git checkout -q -f main
probe; write_bump 1.99.99.9001
BSUBJ='chore: Bump version to 1.99.99.9002' refused "a subject naming another version is refused"
probe; write_bump 1.99.99.9001; printf '# duckdb 1.5.5\n\n- Old.\n' > NEWS.md
commit "$bump_msg"
status_of "$(git rev-parse HEAD)"
has "a bump that rewrites NEWS.md without the version's section is still READY" "$out" "READY: every commit has passed"
git checkout -q -f main
probe; write_bump 1.99.99.9001
git checkout -q -f -B side "$TIP"; write_bump 1.99.99.9001; commit "$bump_msg"
git checkout -q -f probe; git merge -q --no-ff side -m "$bump_msg"
status_of "$(git rev-parse HEAD)"
is "a merge commit is refused" "$st" 1
git checkout -q -f main; git branch -q -D side

echo "== the bump carries the alpha stamp of the engine it ends on"
status_of "$BUMP"
has "a bump without the stamp is ready, with a note that it carries none" "$out" "Note: the bump carries no alpha stamp"
# `curl` answers upstream's per-commit pointer from $NET/pointer-<sha10>, absent
# for a 404, and every extension but those listed in $NET/missing; with
# $NET/down it reaches nothing.
NET=$SCRATCH/net
mkdir -p "$SCRATCH/bin" "$NET"
: > "$NET/missing"
cat > "$SCRATCH/bin/curl" <<'EOF'
#!/bin/bash
[ ! -f "$NET/down" ] || { echo 000; echo "curl: (6) Could not resolve host" >&2; exit 6; }
out=/dev/null url=
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out=$2; shift 2 ;;
    -w | -m) shift 2 ;;
    http*) url=$1; shift ;;
    *) shift ;;
  esac
done
case "$url" in
  https://duckdb-staging.duckdb.org/*/latest_alpha_version.txt)
    p=${url#https://duckdb-staging.duckdb.org/}; p=$NET/pointer-${p%%/*}
    if [ -f "$p" ]; then cp "$p" "$out"; echo 200; else echo 404; fi ;;
  https://extensions.duckdb.org/*)
    if grep -qxF "${url#https://extensions.duckdb.org/}" "$NET/missing"; then echo 404; else echo 200; fi ;;
  *) echo 500 ;;
esac
EOF
chmod +x "$SCRATCH/bin/curl"
export NET
STUB=$SCRATCH/bin
stamp() { out=$(PATH="$SCRATCH/bin:$PATH" scripts/series-land.sh v2.0-x --stamp-alpha 2>&1) && st=0 || st=$?; }
# A vendor commit above the landing's last, of an engine upstream built as an
# alpha, -dev stamped in the three files the stamp rewrites, as the real tree is.
ALPHA=abcdef0123
PRAGMA=src/duckdb/src/function/table/version/pragma_version.cpp
LOADER=src/duckdb/generated_extension_loader_package_build.cpp
probe
printf '#define DUCKDB_PATCH_VERSION "0-dev7"\n#define DUCKDB_VERSION "v2.0.0-dev7"\n#define DUCKDB_SOURCE_ID "%s"\n' "$ALPHA" > "$PRAGMA"
printf '\tdescriptor->api_version = "%s";\n\tdescriptor->api_version = "v1.2.0";\n' "$ALPHA" > "$LOADER"
echo 'duckdb_version <- "2.0.0-dev7"' > R/version.R
commit "vendor: Update vendored sources to duckdb/duckdb@${ALPHA}000000000000000000000000000000"
AV=$(git rev-parse HEAD)
passed "$AV"
read -r KWT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
git -C "$KWT" checkout -q --detach "$AV"

stamp
is "an engine upstream built no alpha of is refused" "$st" 1
has "  and says the batch must end on one" "$out" "upstream built no alpha of duckdb/duckdb@$ALPHA"
echo v2.0.0-alpha77 > "$NET/pointer-$ALPHA"
echo v2.0.0-alpha77/osx_arm64/icu.duckdb_extension.gz > "$NET/missing"
stamp
is "an alpha with a gap in its extensions is refused" "$st" 1
has "  and names the gap" "$out" "v2.0.0-alpha77 has no icu for osx_arm64"
is "  and the kept worktree is untouched" "$(git -C "$KWT" status --porcelain)" ""
: > "$NET/missing"
# Run from the kept worktree, as step 3 runs it.
out=$(cd "$KWT" && PATH="$SCRATCH/bin:$PATH" "$WORK/scripts/series-land.sh" v2.0-x --stamp-alpha 2>&1) && st=0 || st=$?
is "the alpha is stamped into the kept worktree" "$st" 0
has "  with a warning that it is not the engine of the source" "$out" "vendors $ALPHA, not dddd444"
is "  in the three files it rewrites" "$(git -C "$KWT" diff --cached --name-only | tr '\n' ' ')" "R/version.R $LOADER $PRAGMA "
has "  DUCKDB_VERSION is the alpha" "$(cat "$KWT/$PRAGMA")" '#define DUCKDB_VERSION "v2.0.0-alpha77"'
has "  DUCKDB_SOURCE_ID stays the commit" "$(cat "$KWT/$PRAGMA")" "#define DUCKDB_SOURCE_ID \"$ALPHA\""
stamp
is "stamped again before the commit, it succeeds" "$st" 0
is "  and the stamp stays staged" "$(git -C "$KWT" diff --cached --name-only | tr '\n' ' ')" "R/version.R $LOADER $PRAGMA "
echo '// beside the stamp' >> "$KWT/$LOADER"
stamp
is "an edit to a stamped file beside the stamp is refused" "$st" 1
has "  and says so" "$out" "has changes to the stamped files other than the stamp"
git -C "$KWT" checkout -q -- "$LOADER"
echo v2.0.0-alpha78 > "$NET/pointer-$ALPHA"
stamp
is "a stamp of an alpha upstream's pointer has since moved past is refused" "$st" 1
has "  and named" "$out" "holds a different stamp, v2.0.0-alpha77, where upstream's alpha of $ALPHA is v2.0.0-alpha78 now"
has "  with the checkout that drops it" "$out" "checkout HEAD -- R/version.R $LOADER $PRAGMA"
echo v2.0.0-alpha77 > "$NET/pointer-$ALPHA"
(cd "$KWT" && write_bump 1.99.99.9001 "${ALPHA}000000000000000000000000000000" &&
  git -c user.name=Test -c user.email=t@example.invalid commit -qam "$bump_msg")
SB=$(git -C "$KWT" rev-parse HEAD)
stamp
has "a rerun on the stamped bump has nothing to do" "$out" "is stamped as v2.0.0-alpha77 already"
status_of "$SB"
has "the bump that carries the stamp is ready" "$out" "READY: every commit has passed"
hasnt "  with no note" "$out" "carries no alpha stamp"
echo v2.0.0-alpha78 > "$NET/pointer-$ALPHA"
status_of "$SB"
is "a stamp upstream's pointer has moved past is not ready" "$st" 1
has "  and names the newer alpha" "$out" "NOT READY: the bump stamps v2.0.0-alpha77, but upstream's newest alpha of $ALPHA is v2.0.0-alpha78"
rm "$NET/pointer-$ALPHA"
status_of "$SB"
is "a stamp upstream names no alpha for is not ready" "$st" 1
has "  and says so" "$out" "upstream names no alpha of $ALPHA now"
echo v2.0.0-alpha77 > "$NET/pointer-$ALPHA"
: > "$NET/down"
status_of "$SB"
is "a stamp whose pointer cannot be read is not ready" "$st" 1
has "  and says why" "$out" "NOT READY: the bump's stamp v2.0.0-alpha77 is unconfirmed: could not read the alpha of $ALPHA"
rm "$NET/down"
landed "$SB"
echo v2.0.0-alpha78 > "$NET/pointer-$ALPHA"
status_of "$SB"
has "once main is the stamped bump, a pointer moved past it leaves it ready" "$out" "READY: every commit has passed"
: > "$NET/down"
status_of "$SB"
has "  and so does a pointer that cannot be read" "$out" "READY: every commit has passed"
is "  and run as printed, the tag block tags it" "$(PATH="$STUB:$PATH" tag_as_printed v1.99.99.9001)" \
  "$SB"$'\n''duckdb 1.99.99.9001'
rm "$NET/down"
echo v2.0.0-alpha77 > "$NET/pointer-$ALPHA"
git tag -d v1.99.99.9001 >/dev/null
git push -q upstream :refs/tags/v1.99.99.9001
unlanded
git -C "$KWT" checkout -q --detach "$TIP"

stamped() { git checkout -q -f -B probe "$AV"; git checkout -q "$SB" -- .; }
stamped; sed -i "s/^#define DUCKDB_SOURCE_ID .*/#define DUCKDB_SOURCE_ID \"1234567890\"/" "$PRAGMA"
refused "a stamp that changes the engine's commit is refused" "it differs from the stamp of $ALPHA as v2.0.0-alpha77 in $PRAGMA"
stamped; sed -i "s/v2.0.0-alpha77/v2.0.0-alpha78/" "$LOADER"
refused "a stamp naming another alpha in one file is refused" "differs from the stamp of $ALPHA as v2.0.0-alpha77 in $LOADER"
stamped; git checkout -q "$AV" -- R/version.R
refused "a stamp that leaves a file unstamped is refused" "in R/version.R"
stamped; echo 'engine changed' > src/duckdb/engine.cpp
refused "a stamp with an edit beside it is refused" "outside an alpha stamp: src/duckdb/engine.cpp"
stamped; sed -i 's/v2.0.0-alpha77/v2.0.0-rc1/' "$PRAGMA" "$LOADER" R/version.R
refused "a version that is no alpha is refused" "a malformed alpha stamp: DUCKDB_VERSION is 'v2.0.0-rc1'"
stamped; sed -i 's/v2.0.0-alpha77/v2.1.0-alpha77/' "$PRAGMA" "$LOADER" R/version.R
refused "an alpha of another release is refused" "which is no v2.1.0-dev version"
probe; write_bump 1.99.99.9001; printf '#define DUCKDB_VERSION "v2.0.0-alpha77"\n#define DUCKDB_SOURCE_ID "dddd444"\n' > "$PRAGMA"
refused "a stamp on an engine with no ten-digit commit is refused" "not ten hex digits"

echo "== a release engine needs no alpha stamp"
RELENG=fedcba9876
probe
printf '#define DUCKDB_PATCH_VERSION "1"\n#define DUCKDB_VERSION "v2.0.1"\n#define DUCKDB_SOURCE_ID "%s"\n' "$RELENG" > "$PRAGMA"
echo 'duckdb_version <- "2.0.1"' > R/version.R
commit "vendor: Update vendored sources to duckdb/duckdb@${RELENG}000000000000000000000000000000"
RV=$(git rev-parse HEAD)
passed "$RV"
git -C "$KWT" checkout -q --detach "$RV"
stamp
is "--stamp-alpha on a release engine succeeds" "$st" 0
has "  and says a release needs no stamp" "$out" "is stamped as 2.0.1, a release, which needs no alpha stamp"
is "  and leaves the kept worktree alone" "$(git -C "$KWT" status --porcelain)" ""
git -C "$KWT" checkout -q --detach "$TIP"
git checkout -q -f -B probe "$RV"
write_bump 1.99.99.9001 "${RELENG}000000000000000000000000000000"
commit "$bump_msg"
status_of "$(git rev-parse HEAD)"
has "a bump over a release engine is ready" "$out" "READY: every commit has passed"
hasnt "  with no note about an alpha stamp" "$out" "carries no alpha stamp"
git checkout -q -f main

echo "== and it never stands alone"
GA=$(git ls-remote origin refs/heads/v2.0-x-land-green | cut -f1)
git push -q -f origin "$M:refs/heads/v2.0-x-land-green"
git checkout -q -f -B probe "$M"
write_bump 1.99.99.9001
commit "$bump_msg"
status_of "$(git rev-parse HEAD)"
is "a bump with no vendor commit under it is refused" "$st" 1
has "  and says so" "$out" "a bump with no vendor commit under it"
hasnt "  and is not ready" "$out" "READY: every"
git checkout -q -f main
git push -q -f origin "$GA:refs/heads/v2.0-x-land-green"

echo "== and nothing sits above it"
git checkout -q -f -B probe "$BUMP"
echo 'bar <- 1' > R/bar.R
commit 'fix: A commit on top of the bump'
status_of "$(git rev-parse HEAD)"
is "a commit above the bump is refused" "$st" 1
hasnt "and is not ready" "$out" "READY: every"
git checkout -q -f main

echo "== and a rebuild drops it, and only it"
dev_at "$TIP"
read -r KWT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
git -C "$KWT" -c user.name=Test -c user.email=t@example.invalid commit -q --allow-empty -m "$bump_msg"
out=$(scripts/series-land.sh v2.0-x --no-check-glue 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "a rerun with the bump in the kept worktree still builds" "$st" 0
has "and says which bump is dropped" "$out" "the version bump"
has "and that it is dropped" "$out" "above the vendor commits is dropped"
is "the kept build ends on the vendor commits again" "$(git -C "$KWT" rev-parse HEAD)" "$TIP"
git -C "$KWT" -c user.name=Test -c user.email=t@example.invalid commit -q --allow-empty -m "$bump_msg"
echo 'staged' > "$KWT/R/staged.R"
git -C "$KWT" add R/staged.R
out=$(scripts/series-land.sh v2.0-x --no-check-glue 2>&1) || true
hasnt "work staged in the tree is not discarded" "$out" "is dropped"
git -C "$KWT" reset -q --hard "$TIP"
scripts/series-land.sh v2.0-x --abort >/dev/null

# A bump `main` made itself sits at the base of a build that stopped before it
# replayed anything, and is never dropped, even with a vendor commit under it,
# so that the base check stands on its own.
git checkout -q -f -B mainbump "$M"
git commit -q --allow-empty -m 'vendor: Update vendored sources to duckdb/duckdb@ffff000'
git commit -q --allow-empty -m 'chore: Bump version to 2.0.0.9000'
MB=$(git rev-parse HEAD)
git push -q upstream "$MB:refs/heads/mainbump"
git checkout -q -f main
scripts/series-land.sh v2.0-x --no-check-glue --base mainbump >/dev/null 2>&1 || true
read -r KWT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
git -C "$KWT" reset -q --hard "$MB"
out=$(scripts/series-land.sh v2.0-x --no-check-glue --base mainbump 2>&1) || true
hasnt "main's own bump at the base is kept" "$out" "is dropped"
has "and the build resumes on it" "$out" "resuming the build in"
is "the base is in the kept history" "$(git -C "$KWT" merge-base --is-ancestor "$MB" HEAD && echo yes)" yes
scripts/series-land.sh v2.0-x --abort >/dev/null
git branch -q -D mainbump

# The real case: `main` edits a test file the rewind touches, so the first pick
# conflicts and the build stops on `main`'s bump with a resolution staged.
git checkout -q -f -B mainbump2 "$M"
echo 'test main' > tests/testthat/test-foo.R
commit 'chore: Bump version to 2.0.0.9000'
MB2=$(git rev-parse HEAD)
git push -q upstream "$MB2:refs/heads/mainbump2"
git checkout -q -f main
out=$(scripts/series-land.sh v2.0-x --no-check-glue --base mainbump2 2>&1) && st=0 || st=$?
is "a first pick that conflicts stops the build" "$st" 1
has "on the conflict" "$out" "Conflict at"
read -r KWT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
is "at main's bump, which is the base" "$(git -C "$KWT" rev-parse HEAD)" "$MB2"
echo 'test resolved' > "$KWT/tests/testthat/test-foo.R"
git -C "$KWT" add tests/testthat/test-foo.R
out=$(scripts/series-land.sh v2.0-x --no-check-glue --base mainbump2 2>&1) || true
hasnt "the rerun keeps main's bump" "$out" "is dropped"
is "and the base" "$(git -C "$KWT" merge-base --is-ancestor "$MB2" HEAD && echo yes)" yes
is "and the resolution that was staged" \
  "$(git -C "$KWT" show "$(git -C "$KWT" rev-list --reverse "$MB2..HEAD" | head -n 1):tests/testthat/test-foo.R")" "test resolved"
scripts/series-land.sh v2.0-x --abort >/dev/null
git branch -q -D mainbump2 probe

# A refused run leaves the kept worktree as it was: the bump is dropped only
# once the run is past its refusals.
scripts/series-land.sh v2.0-x --no-check-glue >/dev/null 2>&1 || true
read -r KWT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
git -C "$KWT" -c user.name=Test -c user.email=t@example.invalid commit -q --allow-empty -m "$bump_msg"
before=$(git -C "$KWT" rev-parse HEAD)
out=$(scripts/series-land.sh v2.0-x --no-check-glue --base mainbump2 2>&1) && st=0 || st=$?
is "a run with another base is refused" "$st" 1
has "saying where the kept build stands" "$out" "the kept build stands on"
is "and the bump is still there" "$(git -C "$KWT" rev-parse HEAD)" "$before"
scripts/series-land.sh v2.0-x --abort >/dev/null

# --- 10: a wrong resolution, replayed --------------------------------------

echo
echo "== a resolution rerere replays wrongly is named, and can be redone"
scripts/series-land.sh v2.0-x --abort >/dev/null
rm -rf "$(git rev-parse --git-common-dir)/rr-cache"
scripts/series-land.sh v2.0-x --no-check-glue >/dev/null 2>&1 || true
read -r WT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
printf 'a\nb wrong\nc\n' > "$WT/tests/testthat/test-bar.R"
git -C "$WT" add tests/testthat/test-bar.R
scripts/series-land.sh v2.0-x --no-check-glue >/dev/null 2>&1 || true
scripts/series-land.sh v2.0-x --abort >/dev/null
out=$(scripts/series-land.sh v2.0-x --no-check-glue 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "the replayed rebuild is refused" "$st" 1
has "the check names the path" "$out" "tests/testthat/test-bar.R"
has "and says rerere answered it" "$out" "rerere replayed a resolution for: tests/testthat/test-bar.R"

scripts/series-land.sh v2.0-x --abort >/dev/null
out=$(scripts/series-land.sh v2.0-x --no-check-glue --attended 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "an attended rebuild stops at the conflict" "$st" 1
has "with rerere's answer filled in" "$out" "Resolved 'tests/testthat/test-bar.R' using previous resolution"
read -r WT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
git -C "$WT" rerere forget tests/testthat/test-bar.R >/dev/null 2>&1
printf 'a\nb v2 main\nc\n' > "$WT/tests/testthat/test-bar.R"
git -C "$WT" add tests/testthat/test-bar.R
out=$(scripts/series-land.sh v2.0-x --no-check-glue --attended 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "redone, the landing is the series' again" "$out" "v2.0-x-land-dev: already on origin"

# The series vendors one more commit while the build waits.
git checkout -q s
engine eeee555 1.99.99-dev4
desc duckdb.2.0.dev 1.99.99.9000.4
commit 'vendor: Update vendored sources to duckdb/duckdb@eeee555'
git push -q origin s:refs/heads/v2.0-x-dev
git checkout -q main
scripts/series-rc.sh v2.0-x --push >/dev/null 2>&1
out=$(scripts/series-land.sh v2.0-x --no-check-glue 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "the kept build follows the moved strand" "$out" "following it"
has "and lands the new commit too" "$out" "4 vendor commits on $(git rev-parse --short "$M")"
hasnt "and is the series' package" "$out" "DIVERGED"

# --- 11: a base above main ---------------------------------------------------

echo
echo "== a landing stands on a base above main"
scripts/series-land.sh v2.0-x --abort >/dev/null
git checkout -q -b pin "$M"
echo 'test_that("a pinned expectation", expect_true(TRUE))' > tests/testthat/test-pin.R
commit 'test: Pin what the line must keep (#10)'
PIN=$(git rev-parse HEAD)
git push -q upstream pin
git checkout -q main
out=$(scripts/series-land.sh v2.0-x --no-check-glue --base pin --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "it builds on the base" "$out" "4 vendor commits on $(git rev-parse --short "$PIN")"
has "and names the base's own commits" "$out" "1 commit(s) of its own"
hasnt "the base's own change is expected by the check" "$out" "UNEXPLAINED"
git fetch -q origin
LTIP=$(git rev-parse origin/v2.0-x-land-dev)
is "the base's commit lands with it" "$(git rev-parse "$LTIP~4")" "$PIN"
is "green starts at main, so CI judges that commit too" "$(git rev-parse origin/v2.0-x-land-green)" "$M"

git checkout -q rcc2
for c in $(git rev-list "$M..$LTIP"); do rec "$c" success; done
commit 'chore: store stub, the landing on a base'
git push -q origin rcc2
git checkout -q main
out=$(scripts/series-land.sh v2.0-x --status --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "the base's commit counts among those CI passed" "$out" "5 of 5 commits above v2.0-x-land-green passed"
has "and without the bump it is not ready" "$out" "does not end on the version bump"

out=$(scripts/series-land.sh v2.0-x --review --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
git fetch -q upstream v2.0-x-land-review
is "the review shows the base's commit as it lands" \
  "$(git log --format=%s "$M..upstream/v2.0-x-land-review" | grep -c '^test: Pin what the line must keep')" 1

# An iteration reviewed before the series carries it: the fix folded into the
# commit that introduced the defect, and everything above it replayed.
git checkout -q -b land-v2 "$LTIP"
git checkout -q --detach "$LTIP~3"
echo 'glue 2, adapted to bbbb222, and fixed' > src/glue.cpp
git add src/glue.cpp
git commit -q --amend --no-edit
git cherry-pick "$LTIP~3..$LTIP" >/dev/null
git branch -f land-v2 HEAD
git push -q origin "land-v2:refs/heads/v2.0-x-land-v2"
git checkout -q main
out=$(scripts/series-land.sh v2.0-x --review --landing v2.0-x-land-v2 --suffix -v2 --push 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "an iteration gets a review branch of its own" "$out" "v2.0-x-land-review-v2 ->"
has "and a title that names it" "$out" "the R side of the v2.0-x landing, v2"
git fetch -q upstream v2.0-x-land-review-v2
R1=$(git log --format=%H -F --grep='The R side of duckdb/duckdb bbbb222' upstream/v2.0-x-land-review-v2)
is "with the folded fix in the commit that introduced it" \
  "$(git show "$R1:src/glue.cpp")" 'glue 2, adapted to bbbb222, and fixed'

# A fix stacked on top of the vendor commits is not a landing.
git checkout -q -b land-v3 land-v2
echo 'one more' > src/more.cpp
commit 'fix: A commit on top'
git push -q origin "land-v3:refs/heads/v2.0-x-land-v3"
git checkout -q main
out=$(scripts/series-land.sh v2.0-x --review --landing v2.0-x-land-v3 --suffix -v3 2>&1) && st=0 || st=$?
is "a commit on top of the vendor commits is refused" "$st" 1
LAND_BEFORE=$LTIP

# --- 12: a test the base runs, which the series stopped ----------------------

echo
echo "== a landing that stops a test its base runs is not pushed"
git checkout -q s
engine ffff666 1.99.99-dev5
git rm -q tests/testthat/test-bar.R
desc duckdb.2.0.dev 1.99.99.9000.5
commit 'vendor: Update vendored sources to duckdb/duckdb@ffff666'
git push -q origin s:refs/heads/v2.0-x-dev
git checkout -q main
scripts/series-rc.sh v2.0-x --push >/dev/null 2>&1
out=$(scripts/series-land.sh v2.0-x --no-check-glue --push 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "the build is refused" "$st" 1
has "the report names the test" "$out" "deleted   tests/testthat/test-bar.R"
has "and the commit that stopped it" "$out" "duckdb/duckdb@ffff666"
hasnt "though the series lacks it too" "$out" "DIVERGED"
has "and nothing is pushed" "$out" "Nothing was pushed"
git fetch -q origin
is "land-dev is where it was" "$(git rev-parse origin/v2.0-x-land-dev)" "$LAND_BEFORE"

# --- 13: main moves ---------------------------------------------------------

echo
echo "== a main that moved is not landed on blindly"
git checkout -q main
echo 'foo <- function() 3' > R/foo.R
printf 'Imports: DBI\n' >> DESCRIPTION
commit 'fix: A fix the series never ported (#8)'
git push -q upstream main
out=$(scripts/series-land.sh v2.0-x --status 2>&1) && st=0 || st=$?
is "the pushed landing is not ready on it" "$st" 1
has "and says main moved" "$out" "NOT READY"
out=$(scripts/series-land.sh v2.0-x --no-check-glue 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "the kept build refuses" "$st" 1
has "and says main moved" "$out" "Error: main moved from below $(git rev-parse --short "$PIN")"

scripts/series-land.sh v2.0-x --abort >/dev/null
out=$(scripts/series-land.sh v2.0-x --no-check-glue --push 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "a rebuild the series does not match fails" "$st" 1
has "it names the path" "$out" "R/foo.R"
has "and DESCRIPTION, whose difference is not its version" "$out" "    DESCRIPTION"
has "and refuses to push" "$out" "DIVERGED"
git fetch -q origin
is "land-dev is where it was" "$(git rev-parse origin/v2.0-x-land-dev)" "$LAND_BEFORE"

scripts/series-land.sh v2.0-x --abort >/dev/null

# --- 14: a named source -------------------------------------------------------

echo
echo "== a fresh build up to a named ref takes it as the fork has it now"
git push -q origin "$RC:refs/heads/land-src"
git update-ref refs/remotes/origin/land-src "$RC~1"
out=$(scripts/series-land.sh v2.0-x --no-check-glue --source land-src 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
has "it fetches the ref rather than reading a stale copy" "$out" "built up to land-src $(git rev-parse --short "$RC")"
scripts/series-land.sh v2.0-x --abort >/dev/null

# --- 15: the branch the series releases from -----------------------------------

echo
echo "== a forward is never landed"
out=$(scripts/series-land.sh v2.0-x-fwd --no-check-glue 2>&1) && st=0 || st=$?
is "a -fwd series is refused as a usage error" "$st" 2
has "  saying to cut it over first" "$out" "cut it over first, then land v2.0-x"

echo
echo "== the landing goes onto the branch series.yaml names"
G0=$(git ls-remote origin refs/heads/v2.0-x-land-green | cut -f1)
git checkout -q -f -B hi "$M"
sed -i 's/^Version: .*/Version: 1.99.99.9007/' DESCRIPTION
printf 'Config/duckdb/upstream: %s\n' aaaa112000000000000000000000000000000000 >> DESCRIPTION
commit 'chore: Bump version to 1.99.99.9007'
git push -q -f upstream hi
HI=$(git rev-parse HEAD)
MAIN15=$(git ls-remote upstream refs/heads/main | cut -f1)
git checkout -q -f -B canonmain "$MAIN15"
mkdir -p scripts
printf 'flavors:\n  - flavor: duckdb.x.dev\n    kind: dev\n    series: "v2.0-x"\n    releases_from: '"'"'hi'"'"'\n' > scripts/series.yaml
git add scripts/series.yaml
git commit -qm 'chore: The v2.0-x series releases from hi'
git push -q upstream canonmain:main
git checkout -q -f main
out=$(scripts/series-land.sh v2.0-x --no-check-glue 2>&1) || true
[ -z "${KEEP:-}" ] || echo "$out"
is "--target prints that branch" "$(scripts/series-land.sh v2.0-x --target 2>&1)" hi
has "the build stands on that branch, read through quotes" "$out" "vendor commits on $(git rev-parse --short "$HI")"
has "its engine record is the branch's, and no difference" "$out" "Config/duckdb/upstream:, is the branch's"
hasnt "  so the landing is the series' package" "$out" "DIVERGED"
read -r WT _ < "$(git rev-parse --git-dir)/series-land-v2.0-x"
FIRST=$(git -C "$WT" rev-list --reverse "$HI..HEAD" | head -n 1)
is "its first landing commit's parent is that branch's tip" "$(git -C "$WT" rev-parse "$FIRST~1")" "$HI"
scripts/series-land.sh v2.0-x --abort >/dev/null

# A landing on hi by hand: the vendor commit, then a bump that clears the
# series' version but not hi's, which earlier landings there advanced.
V=$(git commit-tree "$TIP^{tree}" -p "$HI" -m 'vendor: Update vendored sources to duckdb/duckdb@dddd444')
git push -q -f origin "$HI:refs/heads/v2.0-x-land-green"
git checkout -q -f -B probe "$V"
write_bump 1.99.99.9001
commit "$bump_msg"
LOW=$(git rev-parse HEAD)
dev_at "$LOW"; passed "$V"; passed "$LOW"
out=$(scripts/series-land.sh v2.0-x --status 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
is "a bump below the branch's version is refused" "$st" 1
has "  and says why" "$out" "does not raise the version above hi's 1.99.99.9007"
git checkout -q -f probe~1
write_bump 1.99.99.9008
commit 'chore: Bump version to 1.99.99.9008 with hand-written release notes'
HIGH=$(git rev-parse HEAD)
dev_at "$HIGH"; passed "$HIGH"
out=$(scripts/series-land.sh v2.0-x --status 2>&1) && st=0 || st=$?
[ -z "${KEEP:-}" ] || echo "$out"
has "the next version above it is ready" "$out" "READY: every commit has passed, and hi"
has "and the fast-forward is that branch" "$out" "git push upstream $HIGH:refs/heads/hi"
out=$(scripts/series-land.sh v2.0-x --review --suffix -hi --push 2>&1) || true
has "the review pull request targets it" "$out" "--draft --base hi --head v2.0-x-land-review"
git checkout -q -f main
git push -q -f origin "$G0:refs/heads/v2.0-x-land-green"
git branch -q -D probe hi canonmain

echo
echo "== the series must be declared, and the canonical remote named"
out=$(scripts/series-land.sh v9.9-none --no-check-glue 2>&1) && st=0 || st=$?
is "a series series.yaml does not declare is refused" "$st" 1
has "  naming it" "$out" "declares no releases_from for the series v9.9-none"
out=$(scripts/series-land.sh main --status 2>&1) || true
hasnt "main's own series needs no row" "$out" "declares no releases_from"
out=$(SERIES_CANONICAL='' scripts/series-land.sh v2.0-x --status 2>&1) && st=0 || st=$?
is "without a canonical remote it stops" "$st" 1
has "  with its own error" "$out" "Error: no canonical remote"
hasnt "  not the shell's" "$out" "unbound variable"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
