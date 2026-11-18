# shellcheck shell=bash
# The helpers every series script shares, reading scripts/series-config.sh:
# which commit vendors, what it vendors, where a walk starts. Sourced by the
# scripts/series-*.sh and scripts/each-plan.sh; nothing here writes a ref.
# shellcheck source=series-config.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/series-config.sh"

# How deep a scan looks past commits that touch the scan directory without
# vendoring: the patch stack is applied to the vendored tree in place, so every
# CRAN and compiler-warning fix lands there carrying no upstream SHA, and a
# series stacks a few of them above its buffer. 20 is far more than that, and
# bounded so git ends the walk itself. The variable is shared by every reader,
# so raising it raises every answer at once.
base_scan_depth="${BASE_SCAN_DEPTH:-20}"

# Does a subject say its commit vendored? The `vendor:` prefix vendor-one.sh
# writes, or the `<owner>/<repo>@<sha>` marker that carries the upstream commit
# as machine-readable state. The subject decides, never the path.
series_is_vendor() { # <subject>
  # shellcheck disable=SC2254
  case "$1" in vendor:* | $series_vendor_glob) return 0 ;; esac
  return 1
}

# The upstream SHA a subject names, empty when it names none.
series_sha_of() { # <subject>
  sed -rn "$series_sha_sed" <<<"$1"
}

# The upstream SHA a ref has vendored. The pathspec narrows the walk, the
# subject decides: commits that touch the scan directory without vendoring are
# ordinary, so look past them, `base_scan_depth` deep. Empty is the answer
# being absent, not a wrong answer: callers refuse on it, and the reason is on
# stderr for a human to act on.
series_vendored_sha() { # <ref> -> sha, empty when none
  local subjects sha n
  subjects=$(git log -n "$base_scan_depth" --format=%s "$1" -- "$series_scan_dir" || true)
  sha=$(sed -rn "$series_sha_sed" <<<"$subjects" | head -n 1)
  if [ -z "$sha" ]; then
    n=$(grep -c . <<<"$subjects" || true)
    if [ "$n" -ge "$base_scan_depth" ]; then
      echo "vendored_sha: $base_scan_depth $series_scan_dir commits on $1, none of them vendoring;" >&2
      echo "  if that is genuine, raise BASE_SCAN_DEPTH" >&2
    else
      echo "vendored_sha: no vendor commit among $n $series_scan_dir commits on $1" >&2
    fi
  fi
  echo "$sha"
}

# The -build commit equivalent to <ref>'s newest vendor commit for <sha>: the
# same upstream SHA and the same `(tag ...)` marker. One SHA can have two vendor
# commits, because a tag upstream pushes after its commit was vendored is
# re-stamped by a second one on top (scripts/VENDORING.md). Matched by SHA
# alone, the newer of the two answers for a ref that carries only the older, and
# stage 5 never consumes the re-stamp. A ref re-stamped by hand, whose buffer has
# no such twin, falls back to the SHA alone, which is what it always matched.
series_build_equivalent() { # <build> <ref> <sha> -> commit, empty if none
  local subjects newest lines match
  subjects=$(git log -n "$base_scan_depth" --format=%s "$2" -- "$series_scan_dir" || true)
  newest=$(grep -m 1 -F "@$3" <<<"$subjects" || true)
  lines=$(git log --format='%H %s' "$1" | grep -F "@$3" || true)
  case "$newest" in
    *"(tag "*) match=$(grep -m 1 -F '(tag ' <<<"$lines" || true) ;;
    *) match=$(grep -m 1 -v -F '(tag ' <<<"$lines" || true) ;;
  esac
  [ -n "$match" ] || match=$(head -n 1 <<<"$lines")
  echo "${match%% *}"
}

# What two vendor commits are paired by: the upstream SHA, `+tag` appended for a
# re-stamp, so that a re-stamp pairs with a re-stamp and the plain commit with
# the plain one (scripts/series-advance.sh, scripts/series-forward-build.sh).
series_twin_key() { # <subject> -> key, empty when the subject vendors nothing
  local sha
  sha=$(series_sha_of "$1")
  [ -n "$sha" ] || return 0
  case "$1" in
    *"(tag "*) echo "$sha+tag" ;;
    *) echo "$sha" ;;
  esac
}

# The seed a ref stands on: the newest first-parent commit with the seed's
# subject, empty where the ref has none (a series cut from a parent rather than
# seeded on `main`).
series_seed_of() { # <ref> -> commit, empty when none
  local re
  re=$(printf '%s' "$series_seed_subject" | sed 's/[][\.*^$]/\\&/g')
  git log --first-parent --format=%H --grep="^$re\$" -1 "$1"
}

# Does a forward's green stand above its own seed?
# At birth it sits on the commit the seed sits on, below the flavor commits (.claude/skills/series-forward/SKILL.md),
# which the green of the series it forwards may have too without any swap,
# so only a green above its seed tells cutover litter by ancestry (`series_fwd_swapped`).
# A `-dev` with no seed answers yes, as these read before seeds were.
series_green_seeded() { # <green> <-dev>: status 0 when <green> carries the seed of <-dev>, or <-dev> has none
  local seed
  seed=$(series_seed_of "$2")
  [ -z "$seed" ] || git merge-base --is-ancestor "$seed" "$1"
}

# Was a forward swapped into the series it forwards, its refs left behind as cutover litter?
# Its tips are then reached by the series' refs, so deleting them loses nothing;
# reached, not equal, since the series moves on after the swap.
# The forward's green answers against the series' green where it stands above its seed (`series_green_seeded`);
# where it sits below, as at the forward's birth, or does not exist, the forward's `-dev` answers against the series' `-dev`;
# and where no `-dev` exists, whatever is named for the forward derives from nothing, and is litter.
# Prints the ref that answered, `green`, `dev` or `none`, for the caller to say so
# (scripts/series-check.sh, scripts/series-prune.sh).
series_fwd_swapped() { # <forward green> <forward -dev> <green> <-dev>, a missing forward ref empty: status 0 when swapped in
  if [ -n "$1" ] && { [ -z "$2" ] || series_green_seeded "$1" "$2"; }; then
    echo green
    git merge-base --is-ancestor "$1" "$3"
  elif [ -n "$2" ]; then
    echo dev
    git merge-base --is-ancestor "$2" "$4"
  else
    echo none
  fi
}

# Is a path on the vendored strand, including the Makevars generated from it?
# A configured entry is a path or a glob, and matches itself or anything under it.
series_in_strand() { # <path>
  local p
  for p in "${series_strand[@]}" "${series_makevars[@]}"; do
    # shellcheck disable=SC2254
    case "$1" in $p | $p/*) return 0 ;; esac
  done
  return 1
}

# An ERE matching a configured path or glob: dots escaped, `*` and `?` as in a
# pathspec, where `*` crosses directories.
series_re_of() { # <path or glob>
  printf '%s' "$1" | sed 's/[.]/\\./g; s/\*/.*/g; s/?/./g'
}

# Is a path one of the files vendoring regenerates?
series_is_regenerated() { # <path>
  local p
  for p in "${series_regenerated[@]}"; do
    # shellcheck disable=SC2254
    case "$1" in $p) return 0 ;; esac
  done
  return 1
}

# The vendor paths (scripts/series-config.sh) as an ERE, each matched as itself
# or as a directory; a tree's entries under them; and the key two commits are
# twins by, the same vendor paths blob for blob (scripts/series-vendor.sh).
series_vendor_re() {
  local re='' p
  for p in "${series_vendor_paths[@]}"; do re="${re:+$re|}$(series_re_of "$p")"; done
  printf '^(%s)(/|$)' "$re"
}
series_vendor_entries() { # <tree-ish> -> `ls-tree -r` lines under the vendor paths
  git ls-tree -r --full-tree "$1" | awk -F'\t' -v re="$(series_vendor_re)" '$2 ~ re'
}
series_vendor_key() { # <tree-ish> -> one hash
  series_vendor_entries "$1" | git hash-object --stdin
}

# Stage a strand commit: the vendor paths and nothing else, each only where
# the index or the worktree has it, so `patch/` once its last entry retired is
# skipped rather than refused as an unmatched pathspec (scripts/vendor-one.sh
# --strand, scripts/series-patch-sync.sh). What the generator wrote beyond
# them is the caller's to restore.
series_stage_vendor_paths() {
  local p
  for p in "${series_vendor_paths[@]}"; do
    git ls-files --error-unmatch -- "$p" >/dev/null 2>&1 || compgen -G "$p" >/dev/null || continue
    git add -A -- "$p"
  done
}

# The marker a subject carries, `<owner>/<repo>@<sha>` as the subject spells it,
# for a message that names the commit: a history may carry more than one owner.
series_marker_of() { # <subject> -> marker, empty when none
  { grep -oE "$series_marker_ere" <<<"$1" || true; } | head -n 1
}

# An ERE matching exactly one of those files, for `grep -vxE`.
series_regenerated_re() {
  local re='' p
  for p in "${series_regenerated[@]}"; do re="${re:+$re|}$(series_re_of "$p")"; done
  printf '%s' "$re"
}

# The paths a fix may be carried on, read from stdin: what the twin's diff
# touched, less the buffer's own strand, the tooling stage 4 ports, and what
# vendoring regenerates (scripts/series-advance.sh, scripts/series-learned.sh).
# A strand entry counts as a directory and as a file, whichever it is.
series_carry_filter() {
  local dirs='' files p
  for p in "${series_strand[@]}" "${series_tooling[@]}" "${series_regenerated_dirs[@]}"; do
    dirs="${dirs:+$dirs|}$(series_re_of "$p")/"
  done
  files="DESCRIPTION|$(series_regenerated_re)"
  for p in "${series_strand[@]}"; do files="$files|$(series_re_of "$p")"; done
  { grep -vE "^($dirs)" | grep -vxE "$files"; } || true
}

# An ERE matching the tooling paths, `^(\.github/|scripts/|\.claude/)` here.
series_tooling_re() {
  local re='' p
  for p in "${series_tooling[@]}"; do re="${re:+$re|}$(series_re_of "$p")/"; done
  printf '^(%s)' "$re"
}

# The active release branches, oldest first by version, from a declaration,
# scripts/series.yaml, read on stdin: the CRAN flavor's `upstream`, the line it
# ships, and every `releases_from` other than `main` on a row not declared
# `stale: true`, each named as upstream names its line, and never `main`.
# Whether the canonical repository has cut each one yet is not asked here:
# scripts/series-check.sh asks it, and scripts/pull-request-base.sh takes the
# oldest without asking, since a line declared before it is cut is the newest.
series_release_branches() { # < series.yaml -> one branch per line
  awk '
  function val(v) { gsub(/["'"'"']/, "", v); return v }
  function flush() {
    if (k == "CRAN" && up != "") print up
    if (rf != "" && rf != "main" && st != "true") print rf
    k = ""; up = ""; rf = ""; st = ""
  }
  /^  - / { flush() }
  /^    kind:/ { k = val($2) }
  /^    upstream:/ { up = val($2) }
  /^    releases_from:/ { rf = val($2) }
  /^    stale:/ { st = val($2) }
  END { flush() }' | { grep -v '^main$' || true; } | sort -u -V
}

# The GitHub repository a remote names, `owner/repo`, for `gh api`; empty for a
# remote that is not on GitHub. `git config remote.<name>.github <owner>/<repo>`
# comes first, so a remote whose URL names no repository can still name one: a
# test fixture's path, or a local proxy's address. A URL may carry a user, a
# token or a port, `https://<user>:<token>@github.com:443/o/r.git`, and only the
# path is ever returned, so the credential is never printed; a URL with a query
# or a fragment, which may carry one too, names nothing.
series_github_slug() { # <remote> -> owner/repo, empty when none
  local slug url
  slug=$(git config "remote.$1.github" 2>/dev/null || true)
  if [ -z "$slug" ]; then
    url=$(git remote get-url "$1" 2>/dev/null || true)
    slug=$(sed -nE \
      -e 's#^(https?|ssh|git)://([^/@]*@)?github\.com(:[0-9]+)?/([^/?#]+/[^/?#]+)/?$#\4#p' \
      -e 's#^([^/@:]+@)?github\.com:([^/?#]+/[^/?#]+)/?$#\2#p' <<<"$url")
    slug=${slug%.git}
  fi
  echo "$slug"
}

# The listing `series_delete_line` reads, per remote: its branches, twins
# included, and its pull requests' heads, thousands of refs in the fork. A caller that prints several
# lines loads it once with `series_delete_listing <remote>`, outside the command
# substitutions that call `series_delete_line`, which then read it; without it,
# each line runs its own `git ls-remote`. A remote that cannot be read is not
# cached, and each line then says its tip could not be read. The cache is kept
# per remote name and never invalidated, so load it after the last push to
# that remote, or the lines name tips that have moved.
declare -gA series_delete_cache=()
series_delete_listing() { # <remote>
  local refs
  if refs=$(git ls-remote "$1" 'refs/heads/*' 'refs/pull/*/head' 2>/dev/null); then
    series_delete_cache[$1]=$refs
  fi
}

# The command that deletes one branch of a remote, at a tip: the one the caller
# passes, which it read and checked, or else the one the remote holds now. Every
# form refuses a branch that moved after that read, unless what it moved to is
# again proven safe to delete
# (scripts/series-cutover.sh, scripts/series-prune.sh,
# scripts/series-cutover-stack.sh). Off GitHub it is a `git push` leased on the
# tip. On GitHub it is, for where `git push --delete` is refused, as a cloud
# session's git proxy refuses it, a dispatch of
# .github/workflows/delete-branch.yaml for a session to run, wherever the
# workflow's proof holds in the listing (handbook/branches/model/README.md):
# for a forward's branch, `-fwd-` once in its name, whose twin, the name with
# that `-fwd-` replaced by `-`, is at the tip, as all cutover litter is right
# after the swap, a dispatch with no pull request; else, where a pull request's
# head is the tip, a dispatch naming the lowest-numbered one, read with
# `git ls-remote`, and listing them all in a comment where there are several,
# since the lowest may be open. Where neither holds, the workflow cannot prove
# the deletion safe, and the line is a maintainer's: a `gh api -X DELETE` that
# checks the tip first, since the API takes no lease. A tip it cannot read gets
# the `git ls-remote` that reads it, which deletes nothing.
# One line per ref, so each can be run, or quoted, on its own.
series_delete_line() { # <remote> <branch> [<tip>] -> one command
  local slug refs='' tip=${3:-} prs pr note twin=''
  slug=$(series_github_slug "$1")
  # A forward's branch, `-fwd-` once in its name, and its twin, the name without the `fwd-`.
  # Overlapping occurrences count too, as in `a-fwd-fwd-b`: each strip keeps the dash that ends one.
  local rest=$2 count=0
  while [[ "$rest" == *-fwd-* ]]; do rest=${rest#*-fwd} count=$((count + 1)); done
  [ "$count" -ne 1 ] || twin=${2/-fwd-/-}
  if [ -z "$tip" ] || [ -n "$slug" ]; then
    if [ -n "${series_delete_cache[$1]+x}" ]; then
      refs=${series_delete_cache[$1]}
    else
      # The whole listing is read, never stopped at the first match, so the reader cannot end `git ls-remote` by SIGPIPE.
      refs=$(git ls-remote "$1" "refs/heads/$2" ${twin:+"refs/heads/$twin"} ${slug:+'refs/pull/*/head'} 2>/dev/null) || refs=''
    fi
    [ -n "$tip" ] || tip=$(awk -v r="refs/heads/$2" '$2 == r { print $1 }' <<<"$refs")
  fi
  if [ -z "$tip" ]; then
    echo "git ls-remote $1 refs/heads/$2  # $2 is not on $1 or could not be read: once this reads it, rerun for the line that deletes it"
    return
  fi
  if [ -z "$slug" ]; then
    echo "git push --force-with-lease=refs/heads/$2:$tip $1 :refs/heads/$2"
    return
  fi
  if [ -n "$twin" ] && [ "$(awk -v r="refs/heads/$twin" '$2 == r { print $1 }' <<<"$refs")" = "$tip" ]; then
    echo "gh api -X POST repos/$slug/actions/workflows/delete-branch.yaml/dispatches" \
      "-f ref=main -f 'inputs[branch]=$2'"
    return
  fi
  prs=$(awk -v t="$tip" '$1 == t && $2 ~ /^refs\/pull\/[0-9]+\/head$/ { split($2, p, "/"); print p[3] }' <<<"$refs" |
    sort -n | tr '\n' ' ')
  prs=${prs% }
  if [ -z "$prs" ]; then
    # shellcheck disable=SC2016  # a command for a person to run, printed as it stands
    printf 'if [ "$(gh api repos/%s/git/ref/heads/%s --jq .object.sha)" = %s ]; then gh api -X DELETE repos/%s/git/refs/heads/%s; else echo '"'"'%s is not at %s: read what moved before deleting it'"'"'; fi  # for a maintainer'"'"'s shell: no pull request'"'"'s head is at %s, so the workflow cannot pin it\n' \
      "$slug" "$2" "$tip" "$slug" "$2" "$2" "${tip:0:12}" "${tip:0:12}"
    return
  fi
  pr=${prs%% *} note=''
  [ "$pr" = "$prs" ] || note="  # pull requests whose head is this tip: $prs; name a closed one"
  echo "gh api -X POST repos/$slug/actions/workflows/delete-branch.yaml/dispatches" \
    "-f ref=main -f 'inputs[branch]=$2' -f 'inputs[pr]=$pr'$note"
}

# Keep this side's engine through a merge in progress, a forward merge of an
# older release branch (handbook/branches/model/): the vendored strand and the
# Makevars generated from it, as HEAD has them, whatever the merge did to them
# -- conflicted, added or renamed by the other side, modified on one side and deleted on
# the other. Succeeds when those paths match HEAD afterwards, in the index and
# the tree alike. Only the files the other side added are deleted from the
# tree, so an untracked file of the user's under those paths is left alone.
series_keep_engine() {
  local -a paths=("${series_strand[@]}" "${series_makevars[@]}")
  local p added
  added=$(git diff --no-renames --name-only --diff-filter=A HEAD MERGE_HEAD -- "${paths[@]}" 2>/dev/null || true)
  git rm -rq --cached --ignore-unmatch -- "${paths[@]}" >/dev/null
  for p in "${paths[@]}"; do
    if [ -n "$(git ls-tree --name-only HEAD -- "$p")" ]; then
      git checkout HEAD -- "$p"
    fi
  done
  while IFS= read -r p; do
    [ -z "$p" ] || rm -f -- "$p"
  done <<<"$added"
  git diff --quiet HEAD -- "${paths[@]}" && git diff --cached --quiet HEAD -- "${paths[@]}"
}

# --- the alpha stamp ------------------------------------------------------------
#
# Upstream names a build it dispatches by hand `vX.Y.Z-alpha<run number>` and
# publishes extensions under that name, which a `-dev` stamp never finds. These
# read which build an engine has and stamp a tree as that build, for
# scripts/series-alpha.sh and for a landing's version bump (scripts/series-land.sh,
# handbook/operations/releases/versioning/README.md).

# Where upstream writes its alpha pointers and publishes the extensions, and what
# a stamp is probed for: the platforms R packages are built for, and two
# extensions the test suite installs. Read by the scripts that source this file.
# shellcheck disable=SC2034
series_alpha_staging=https://duckdb-staging.duckdb.org
series_alpha_extensions=https://extensions.duckdb.org
series_alpha_platforms='linux_amd64 linux_arm64 osx_amd64 osx_arm64 windows_amd64_mingw'
series_alpha_probes='icu httpfs'
# shellcheck disable=SC2034
series_alpha_version_re='^v[0-9]+\.[0-9]+\.[0-9]+-alpha[0-9]+$'
# The files a stamp rewrites, the extension loader only where the tree has one.
series_alpha_loader=$series_vendor_dir/generated_extension_loader_package_build.cpp
# shellcheck disable=SC2034
series_alpha_stamped=("$series_engine_file" "$series_stamp_file" "$series_alpha_loader")

series_http() { # <url> <file> -> the HTTP status, with the body in <file>
  curl -sS -L -m 60 -o "$2" -w '%{http_code}' "$1"
}

# Does <commit> stamp a development engine, the kind an alpha build replaces?
# A release's stamp is the build upstream published extensions for, and needs
# none; a tree that stamps nothing is asked as a development one, so that the
# step needing an alpha says what is missing.
series_alpha_wanted() { # <commit>
  local v
  v=$(series_stamped_version "$1")
  [ -n "$v" ] || return 0
  if declare -F series_release_of_stamp >/dev/null; then
    [ -n "$(series_release_of_stamp "$v")" ]
  else
    [[ $v == *-dev* ]]
  fi
}

# Does <commit> change nothing in the stamped files but the lines a stamp
# rewrites, each replaced by one line of its kind that names an alpha? What lets
# a bump carry the stamp as paperwork (scripts/series-port.sh,
# scripts/series-check.sh) without hiding an edit to the engine beside it, a
# line deleted or added, or a `-dev` stamped again.
series_alpha_stamp_lines_only() { # <commit>
  local line file='' kind value alpha=${series_alpha_version_re#^v}
  local -A n=()
  alpha=${alpha%$}
  while IFS= read -r line; do
    case "$line" in
      '+++ '*) file=${line#+++ }; continue ;;
      '--- '*) continue ;;
      [-+]*) ;;
      *) continue ;;
    esac
    if [[ ${line:1} =~ ^\#define\ DUCKDB_VERSION\ \"([^\"]*)\"$ ]]; then
      kind=version value=${BASH_REMATCH[1]#v}
    elif [[ ${line:1} =~ ^\#define\ DUCKDB_PATCH_VERSION\ \"([^\"]*)\"$ ]]; then
      kind=patch value=0.0.${BASH_REMATCH[1]}
    elif [[ ${line:1} =~ ^[[:space:]]*descriptor-\>api_version\ =\ \"([^\"]*)\"\;$ ]]; then
      kind=api value=${BASH_REMATCH[1]#v}
    elif [[ ${line:1} =~ ^duckdb_version\ \<-\ \"([^\"]*)\"$ ]]; then
      kind=r value=${BASH_REMATCH[1]}
    else
      return 1
    fi
    if [ "${line:0:1}" = + ]; then
      [[ $value =~ ^$alpha$ ]] || return 1
      n[$file:$kind]=$((${n[$file:$kind]:-0} + 1))
    else
      n[$file:$kind]=$((${n[$file:$kind]:-0} - 1))
    fi
  done < <(git diff -U0 "$1~1" "$1" -- "${series_alpha_stamped[@]}")
  for kind in "${n[@]}"; do
    [ "$kind" = 0 ] || return 1
  done
}

# Upstream writes a pointer only once the build has deployed its extensions, so
# a gap is upstream's, and nothing is stamped until it is understood.
series_alpha_probe() { # <version>: fails naming the first extension missing
  local p e status
  for p in $series_alpha_platforms; do
    for e in $series_alpha_probes; do
      status=$(curl -sS -I -m 60 -o /dev/null -w '%{http_code}' \
        "$series_alpha_extensions/$1/$p/$e.duckdb_extension.gz") || return $?
      [ "$status" = 200 ] ||
        { echo "Error: $1 has no $e for $p (HTTP $status); not stamping it" >&2; return 1; }
    done
  done
}

# Stage <path> of <commit>, edited by <sed script>, in <index>; fails when the
# edit changed nothing.
series_alpha_edit_() { # <index> <commit> <path> <sed script>
  local before after
  before=$(git rev-parse "$2:$3") &&
    after=$(git show "$2:$3" | sed -e "$4" | git hash-object -w --stdin) || return 1
  [ "$before" != "$after" ] ||
    { echo "Error: the stamp changed nothing in $3 of $(git rev-parse --short "$2")" >&2; return 1; }
  GIT_INDEX_FILE=$1 git update-index --cacheinfo "100644,$after,$3"
}

# The tree of <commit> stamped as upstream's alpha build <version> of its engine
# <sha10>: what upstream's build derives from the version, as
# `DUCKDB_VERSION=<version>` would have written it. `DUCKDB_VERSION` and
# `DUCKDB_PATCH_VERSION` in the engine file, the C++ `api_version` of the linked
# extensions, which is the commit under a `-dev` stamp and the version under a
# release one, and the R-side stamp file; `DUCKDB_SOURCE_ID` stays the commit.
# Fails, saying why, where <commit> stamps no `-dev` of <version>'s release or
# an edit changes nothing. Every step checks its own status, because a caller
# that tests the result turns `set -e` off in here.
series_alpha_stamp_tree() { # <commit> <sha10> <version> -> tree
  local c=$1 sha10=$2 version=$3 release suffix dev devn patch short idx t
  local loader=$series_alpha_loader
  release=${version%-*}  # v2.0.0
  suffix=${version##*-}  # alpha46057
  short=$(git rev-parse --short "$c") || return 1
  dev=$(git show "$c:$series_engine_file" | sed -n 's/^#define DUCKDB_VERSION "\(.*\)"$/\1/p') || return 1
  case "$dev" in
    "$release-dev"[0-9]*) ;;
    *) echo "Error: $short stamps $dev, which is no $release-dev version" >&2; return 1 ;;
  esac
  devn=${dev##*-}       # dev87149
  patch=${release##*.}  # 0
  idx=$(mktemp -d) || return 1
  idx=$idx/index
  if GIT_INDEX_FILE=$idx git read-tree "$c" &&
    series_alpha_edit_ "$idx" "$c" "$series_engine_file" \
      "s/^#define DUCKDB_VERSION \"$dev\"\$/#define DUCKDB_VERSION \"$version\"/;
      s/^#define DUCKDB_PATCH_VERSION \"$patch-$devn\"\$/#define DUCKDB_PATCH_VERSION \"$patch-$suffix\"/" &&
    series_alpha_edit_ "$idx" "$c" "$series_stamp_file" \
      "s/^duckdb_version <- \"${dev#v}\"\$/duckdb_version <- \"${version#v}\"/" &&
    { ! git cat-file -e "$c:$loader" 2>/dev/null ||
      series_alpha_edit_ "$idx" "$c" "$loader" "s/api_version = \"$sha10\";/api_version = \"$version\";/"; } &&
    t=$(GIT_INDEX_FILE=$idx git write-tree); then
    rm -rf "${idx%/index}"
  else
    rm -rf "${idx%/index}"
    return 1
  fi
  if git grep -q -F -e "$devn" "$t" -- "$series_vendor_dir" "$series_stamp_file"; then
    echo "Error: the stamp left $devn behind:" >&2
    git grep -n -F -e "$devn" "$t" -- "$series_vendor_dir" "$series_stamp_file" >&2
    return 1
  fi
  echo "$t"
}
