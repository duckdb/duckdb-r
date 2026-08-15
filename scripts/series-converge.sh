#!/bin/bash
# Does a forward series still carry the same package as the series it replaces?
#
# A forward series is the same series rebuilt on a newer `main`
# (.claude/skills/series-forward.md). Its *history* differs by construction -- a
# regenerated seed, version counters renumbered as a true counter, the ported
# commits the replay leaves behind -- and its *content* must not. So the
# statement a cutover rests on is about trees, not ancestry:
#
#   at the end of a forwarding, `<S>-dev` and `<S>-fwd-dev` are identical, or
#   every difference between them is explicable.
#
# This prints the difference and sorts it into those two, so "explicable" is
# something a reader checks rather than something a cutover assumes. Nothing is
# hidden: an explained difference is still printed, with its line counts, so one
# that changed by more than its explanation accounts for stays visible rather
# than being filed away.
#
# It is also why the loop keeps consuming a base series that has a live forward
# counterpart (scripts/series-advance.sh, stage 5). A base frozen where the
# forward went live can only be compared at the commit it stopped on, which is
# the one point the two are known to agree; every commit the forward vendored
# afterwards is unverifiable against anything. Both series advancing is what
# turns this from a claim into a reading.
#
# **Read-only.** It writes no ref, makes no commit, and touches no worktree.
#
# What counts as explicable, and why each one:
#
#   * `DESCRIPTION` -- but only its `Version:` line. The replay renumbers the
#     fifth component as a counter of its own chain, so the versions differ by
#     construction. Anything else in that file is a real difference, and the
#     file is diffed line-wise to tell the two apart.
#   * `NEWS.md` -- the release paperwork a `fledge:` commit carries, and stage 4
#     never ports a VERSION commit: `main`'s R-client counter is not a series'
#     (.claude/skills/series-loop.md). So the two branches hold whatever their
#     seeds' release lines held, and the file is fledge-maintained, never edited
#     by hand.
#   * The **vendored strand** -- `src/duckdb/`, `patch/`, `R/version.R`,
#     `src/include/sources.mk` and the Makevars -- but **only while the two
#     branches vendor different upstream commits**, where it is the gap itself
#     rather than a finding. Everything in it is a function of the upstream tree:
#     `R/version.R` carries the engine's own version (`1.6.0-dev12322` against
#     `1.6.0-dev12739` on `main` today), the source list and the Makevars are
#     generated from that tree, and `patch/` retires entries as upstream absorbs
#     them. Once both sit on the same upstream SHA every one of them must agree:
#     the forward regenerates the vendored tree from its own patch stack, and
#     series-forward-build.sh verifies exactly that at replay time.
#   * The **flavored docs** -- `README.md` and `.github/README.md`. These are
#     per-branch by design: `.github/README.md` is the front page GitHub renders
#     and scripts/series-port.sh excludes it from the tooling sync by name, for
#     the reason #2517 and #2518 were filed, and `README.md` is in no ported
#     path at all. So each branch carries the wording its seed was made with,
#     and a forward -- whose seed is regenerated on today's `main` -- carries
#     `main`'s current wording while the base carries its own seed's. Observed
#     on all three live series, 2026-08-15, and the same difference on each:
#     the base still described itself as "the LTS version 1.3 of DuckDB" where
#     the forward names its flavor.
#   * The **Windows export list**, `src/*-win.def` -- but only when the two
#     differ by the flavor rename alone. Both the file name and the single
#     symbol in it carry the package name, and scripts/flavor.patch rewrites
#     both, so a base seeded before that flavoring holds `src/duckdb-win.def`
#     exporting `R_init_duckdb` where its forward holds
#     `src/duckdb.1.5.dev-win.def` exporting `R_init_duckdb_1_5_dev`
#     (`v1.5-variegata`, 2026-08-15). The comment prose is compared verbatim and
#     only the `R_init_` line is allowed to differ, so a real edit to the list
#     is still a finding.
#
# Note what is *not* here. Stage 5's carry excludes the same generated files
# (scripts/series-advance.sh), but for an unrelated reason -- so the twin's copy
# does not overwrite the one the buffer's own vendor run just produced -- and
# that exclusion is no evidence they may differ. On the three live series they
# do not: at a matching upstream SHA `R/version.R`, `src/include/sources.mk` and
# the Makevars are identical, and the logos under `man/figures/` are not derived
# from upstream at all, so a difference there is a finding like any other.
#
# Everything else is unexplained and printed as a finding -- glue under `src/`,
# tests, R code, and the tooling directories, which stage 4 brings to `main`'s
# state on both branches every firing and which therefore have no reason to
# differ at all. The READMEs used to be listed here too, which was wrong twice
# over: the port never carries them, so "no reason to differ" was never true of
# them.
#
# The list is deliberately short. A class is added here only once something has
# shown the difference to be benign, because a check that explains away what it
# has not accounted for is worse than no check: it reads as a clean bill. When a
# firing proves a new class benign, it adds it with the evidence.
#
# Usage: series-converge.sh <series> [remote] [--no-fetch]
#   series-converge.sh main            # the base name
#   series-converge.sh main-fwd        # or the forward's; the same comparison
#
# Exit status: 0 when nothing is unexplained, 1 when something is, 2 on a usage
# or lookup error -- so a caller can gate on it. `--no-fetch` is for a caller
# that has just fetched (scripts/series-cutover.sh).

set -euo pipefail

usage='usage: series-converge.sh <series> [remote] [--no-fetch]'
S=${1:?$usage}
shift
remote=origin
fetch=1
for a in "$@"; do
  case "$a" in
    --no-fetch) fetch= ;;
    -*) echo "$usage" >&2; exit 2 ;;
    *) remote=$a ;;
  esac
done

# Either name asks the same question, so neither is wrong to type.
S=${S%-fwd}
dev="$remote/$S-dev"
fwd="$remote/$S-fwd-dev"

[ -z "$fetch" ] || git fetch -q "$remote"

for r in "$dev" "$fwd"; do
  git rev-parse -q --verify "$r" >/dev/null || {
    echo "Error: ${r#"$remote"/} does not exist on $remote" >&2
    echo "  There is no forwarding to check unless both branches are there." >&2
    exit 2
  }
done

# The same helper, the same bound and the same reasons as scripts/series-advance.sh
# and scripts/series-cutover.sh: the pathspec narrows the walk, the subject
# decides, and an empty answer explains itself on stderr rather than lying.
base_scan_depth="${BASE_SCAN_DEPTH:-20}"
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

# True when the two branches' Windows export lists differ by the flavor rename
# and nothing else. The rename means the file is present on one side under one
# name and on the other under another, so the pair cannot be found by path --
# it is found by suffix, one per branch, and their contents are then compared
# with the flavored `R_init_` symbol taken out.
def_renamed_only() {
  local dev_def fwd_def
  dev_def=$(git ls-tree -r --name-only "$dev" src/ | grep -- '-win\.def$' || true)
  fwd_def=$(git ls-tree -r --name-only "$fwd" src/ | grep -- '-win\.def$' || true)
  # One on each side, or there is no pair and the difference is not a rename.
  [ "$(grep -c . <<<"$dev_def")" = 1 ] || return 1
  [ "$(grep -c . <<<"$fwd_def")" = 1 ] || return 1
  cmp -s <(git show "$dev:$dev_def" | grep -v '^R_init_') \
         <(git show "$fwd:$fwd_def" | grep -v '^R_init_')
}

dev_up=$(vendored_sha "$dev")
fwd_up=$(vendored_sha "$fwd")
# An `if`, not an `&&` chain: as a bare statement the chain's own failure is
# what `set -e` would have to be trusted to overlook, and a reader should not
# have to know that rule to see that this line is safe.
same=
if [ -n "$dev_up" ] && [ "$dev_up" = "$fwd_up" ]; then
  same=1
fi

printf '=== %s\n' "$S"
printf '  %-26s %s  vendors %s\n' "$S-dev" "$(git rev-parse --short "$dev")" "${dev_up:0:10}"
printf '  %-26s %s  vendors %s\n' "$S-fwd-dev" "$(git rev-parse --short "$fwd")" "${fwd_up:0:10}"
if [ -z "$same" ]; then
  echo "  The two are not on the same upstream commit, so this is an interim read:"
  echo "  the vendored strand (src/duckdb/, patch/, and the files generated from"
  echo "  that tree) is the gap between them, counted rather than listed."
  echo "  Everything else still has to agree."
fi
echo

explained=()
unexplained=()
gap=0

while IFS=$'\t' read -r add del f; do
  case "$f" in
    DESCRIPTION)
      # Line-wise, because only one line of this file is allowed to differ.
      # `^[+-][^+-]` takes the changed lines and leaves the `+++`/`---` headers.
      other=$(git diff "$dev" "$fwd" -- DESCRIPTION |
                sed -n '/^[+-][^+-]/p' | grep -vE '^[+-]Version:' || true)
      if [ -n "$other" ]; then
        unexplained+=("$f|$add/$del|differs beyond its Version: line")
      else
        explained+=("$f|$add/$del|version counter, renumbered by the replay")
      fi
      ;;
    NEWS.md)
      explained+=("$f|$add/$del|release paperwork; stage 4 never ports a VERSION commit")
      ;;
    README.md | .github/README.md)
      explained+=("$f|$add/$del|flavored doc, never ported; each branch carries its seed's wording")
      ;;
    src/*-win.def)
      # Only the flavor rename is explained. The file's own comment says the
      # name and the symbol both carry the package name; everything above
      # `EXPORTS` is prose that is the same on every flavor, so compare that
      # verbatim and allow only the `R_init_` line to differ. A path that is
      # present on one side alone diffs against the empty tree, and its prose
      # then differs too -- which is exactly the rename, so pair the two by
      # their suffix before comparing.
      if def_renamed_only; then
        explained+=("$f|$add/$del|Windows export list, flavor-renamed")
      else
        unexplained+=("$f|$add/$del|export list differs beyond its R_init_ symbol")
      fi
      ;;
    src/duckdb/* | patch/* | R/version.R | src/include/sources.mk | \
    src/Makevars | src/Makevars.win | src/Makevars.in)
      if [ -n "$same" ]; then
        unexplained+=("$f|$add/$del|vendored strand, at one and the same upstream commit")
      else
        gap=$((gap + 1))
      fi
      ;;
    *)
      unexplained+=("$f|$add/$del|")
      ;;
  esac
# --no-renames, so every path is classified as itself. Rename detection prints
# the pair as one `src/{a => b}` entry, which matches no case below and is not a
# path anything else here could act on.
done < <(git diff --numstat --no-renames "$dev" "$fwd")

show() { # <heading> <entries...>
  local heading=$1 e f n w
  shift
  [ $# -gt 0 ] || return 0
  printf '  %s (%d):\n' "$heading" "$#"
  for e in "$@"; do
    IFS='|' read -r f n w <<<"$e"
    printf '    %-44s %-9s %s\n' "$f" "$n" "$w"
  done
  echo
}

show "explained by the forwarding" ${explained[@]+"${explained[@]}"}
if [ "$gap" -gt 0 ]; then
  printf '  upstream gap: %d path(s) in the vendored strand\n\n' "$gap"
fi
show "UNEXPLAINED" ${unexplained[@]+"${unexplained[@]}"}

if [ ${#unexplained[@]} -eq 0 ]; then
  echo "CONVERGED: the two branches differ only where the forwarding explains it."
  exit 0
fi
echo "DIVERGED: ${#unexplained[@]} path(s) the forwarding does not explain."
echo "  Each is a difference somebody has to account for before the swap:"
echo "  a fix folded on one branch and not the other, a port that reached one"
echo "  of them, or a carry that stage 5 could not make. See"
echo "  .claude/skills/series-forward.md."
exit 1
