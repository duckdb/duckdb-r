#!/bin/bash
# The compiler-warning gate: what each scope is held to, and the check itself.
# Handbook: handbook/build/warnings/README.md
#
# Usage:
#   scripts/warnings.sh glue          # compile src/ and judge it, about a minute
#   scripts/warnings.sh vendored      # compile src/duckdb/ and judge it, a full build
#   scripts/warnings.sh all           # both, glue first
#   scripts/warnings.sh <scope> --all # ... and list what other scopes own, too
#
#   scripts/warnings.sh flags <scope>       # print the scope's ride-along flags
#   scripts/warnings.sh scan <scope> <log>  # judge a build log compiled with them
#
# `flags` and `scan` are the halves of the same check for a build that is
# happening anyway: put the flags on it, keep its output, judge that. The
# vendored scope is checked that way in CI, because compiling the engine twice
# to read it a second time costs an hour and proves nothing new.
#
# A ride-along build is R's, so R takes the flags from the user Makevars -- and
# `R CMD check --as-cran` reads that file too, reporting every -Wno-* in it as a
# non-portable flag suppressing warnings and failing the check over it. So
# `flags` enables and never suppresses, and `scan` drops the categories the
# -Wno-* name instead. Both routes reach the same verdict from the same list.
#
# A warning is attributed to the file it points at, not to the translation unit
# that raised it: a glue file including an engine header is not answerable for
# what that header says. So each scope is judged on the files it owns, and what
# another scope owns is counted rather than listed.
#
# Parallelism comes from nproc; MAKEFLAGS is not consulted, because the compile
# here is not make's.

set -euo pipefail

cd "$(dirname "$0")/.."

# Every flag below is a decision with a reason, and the reasons are
# handbook/build/warnings/README.md's. None of this reaches src/Makevars: CRAN
# rejects -Wno-* in a package's own build flags, and these are the gate's flags,
# not the package's.
COMMON="-Wall -Wextra -Wno-redundant-move -Wno-unused-parameter"
GLUE_WARNINGS="$COMMON -Wno-cast-function-type
  -Wshadow -Wcast-qual -Wnon-virtual-dtor -Woverloaded-virtual -Wsuggest-override
  -Wextra-semi -Wduplicated-cond -Wduplicated-branches -Wlogical-op
  -Wnull-dereference -Wmisleading-indentation -Wdouble-promotion"
VENDORED_WARNINGS="$COMMON"

warnings_of() {
  local w
  case "$1" in
    glue) w=$GLUE_WARNINGS ;;
    vendored) w=$VENDORED_WARNINGS ;;
    *)
      echo "Error: unknown scope '$1'" >&2
      return 2
      ;;
  esac
  # The sets are written over several lines to stay readable; every consumer
  # wants one line, so fold them back.
  # shellcheck disable=SC2086
  echo $w
}

# The same set, minus what suppresses, for a build this script does not drive
# (the header says why). Everything that stays is a flag R CMD check accepts.
ride_along_flags_of() {
  local w
  w=$(warnings_of "$1") || return
  # shellcheck disable=SC2086
  echo $(printf '%s\n' $w | grep -v '^-Wno-')
}

# What the dropped flags would have silenced, spelled the way GCC closes a
# warning line with it: `… [-Wunused-parameter]`.
suppressed_categories_of() {
  local w
  w=$(warnings_of "$1") || return
  # shellcheck disable=SC2086
  printf '%s\n' $w | sed -n 's/^-Wno-\(.*\)$/[-W\1]/p'
}

# Which scope owns the file a diagnostic points at. Paths arrive three ways --
# relative to src/ (our own compile), absolute (an R CMD INSTALL log), and
# relative to the *engine's* own root, where a `#line` in a generated file
# points back at its source (`third_party/libpg_query/grammar/…/select.y`). So
# the marks have to survive a prefix and stand on their own: `duckdb/` is the
# engine wherever it sits -- and the package directory is `duckdb-r`, which that
# pattern does not match -- while `third_party/` and `extension/` are the
# engine's other two roots. `cpp11` names the vendored cpp11 under
# inst/include/, which has an upstream of its own and is nobody's here.
#
# `generated` is checked first, and is dropped outright rather than counted:
# an editable fix does not exist for a file its generator rewrites, this
# repository vendors none of the generators, and there is no upstream to send
# the warning to either -- the generator's input is not what warned. The list is
# a list because there is no marker to match on -- extend it when a generated
# file starts warning:
#   src_backend_parser_gram.cpp, src_backend_parser_scan.cpp  bison and flex
#   yyjson.cpp                                                the amalgamation
#   cpp11.cpp                                                 cpp11::cpp_register()
# The bison output carries `#line` directives, so its diagnostics point at
# `libpg_query/grammar/…`, a path this repository does not even contain; that
# prefix names the same generated code and belongs here too.
classify='
  function scope_of(p) {
    if (p ~ /(^|\/)(src_backend_parser_(gram|scan)|yyjson|cpp11)\.cpp$/) return "generated"
    if (p ~ /libpg_query\/grammar\//) return "generated"
    if (p ~ /(^|\/)(duckdb|third_party|extension)\//) return "vendored"
    if (p ~ /inst\/include\/cpp11\//) return "cpp11"
    return "glue"
  }'

# Judge a log: fail on any warning the scope owns, count the rest.
scan() {
  local scope=$1 log=$2 all mine theirs
  all=$(grep -E '^[^ ].*:[0-9]+:[0-9]+: warning:' "$log" | sed 's/^ *//' | sort -u |
    awk -F: "$classify"'scope_of($1) != "generated"' || true)
  # A compile this script drives never raises the suppressed categories; a
  # ride-along build does, because its flags may not suppress. Drop them here so
  # the two agree.
  all=$(echo "$all" | grep -F -v -f <(suppressed_categories_of "$scope") || true)
  mine=$(echo "$all" | grep . | awk -F: -v want="$scope" "$classify"'
    scope_of($1) == want' || true)
  theirs=$(echo "$all" | grep . | awk -F: -v want="$scope" "$classify"'
    scope_of($1) != want' || true)

  # What another scope owns is counted, not listed: a glue run raises hundreds
  # from engine headers, and a wall of text nobody here can act on is how a
  # gate's output stops being read. `--all` prints them when someone is going
  # after that scope instead.
  if [ -n "$theirs" ]; then
    echo "-- $(echo "$theirs" | grep -c .) warnings in files another scope owns:"
    echo "$theirs" | awk -F: "$classify"'
      { n[scope_of($1)]++ }
      END { for (s in n) printf "   %6d  %s\n", n[s], s }' | sort -k2
    if [ "${show_all:-no}" = "yes" ]; then
      echo "$theirs" | sed 's/^/   /'
    fi
  fi
  if [ -n "$mine" ]; then
    echo "-- $scope warnings ($(echo "$mine" | grep -c .)):"
    echo "$mine" | sed 's/^/   /'
    echo "-- $scope: not clean. Fix the cause; handbook/build/warnings/ says where."
    return 1
  fi
  echo "-- $scope: clean"
}

# --- compiling a scope ourselves --------------------------------------------

prepare_compile() {
  # src/Makevars includes Makevars.rstrtmgr, which only ./configure writes and
  # .gitignore keeps out of the tree; without it the include below has nothing
  # to read for DUCKDB_RSTRTMGR.
  [ -f src/Makevars.rstrtmgr ] || ./configure >/dev/null 2>&1

  # The compile line, composed from what R reports and what src/Makevars adds.
  #
  # `R CMD SHLIB -n` looks like the better source -- it is what vendor-one.sh's
  # glue gate uses -- and it is a trap here. src/Makevars sets OBJECTS, so SHLIB
  # plans the package's own objects whatever file it is handed, and make prints
  # nothing at all once those objects are up to date. That is exactly the state
  # this gate runs in under CI, one step after `R CMD INSTALL`.
  # CI's compiler is usually newer than a development box's, and a newer GCC
  # finds more -- `-Wextra-semi` on a stray `;` after a namespace, say, is
  # GCC 15's, and the runners have it while Ubuntu 24.04 stops at 14. Point
  # this at another compiler to reproduce what CI saw:
  #   DUCKDB_R_WARNINGS_CXX=g++-14 scripts/warnings.sh glue
  cxx=${DUCKDB_R_WARNINGS_CXX:-$(R CMD config CXX17)}
  base_flags="$(R CMD config CXX17STD) $(R CMD config --cppflags) -DNDEBUG"
  base_flags="$base_flags $(R CMD config CPPFLAGS)"
  base_flags="$base_flags $(sed -n 's/^PKG_CPPFLAGS *= *//p' src/Makevars |
    sed 's/\$(DUCKDB_RSTRTMGR)/1/')"
  base_flags="$base_flags $(R CMD config CXX17PICFLAGS) $(R CMD config CXX17FLAGS)"

  if [ -z "$cxx" ] || ! printf '%s' "$base_flags" | grep -q -- '-Iduckdb/src/include'; then
    echo "Error: could not compose the compile flags." >&2
    echo "       R CMD config CXX17 said: ${cxx:-(nothing)}" >&2
    echo "       src/Makevars' PKG_CPPFLAGS is what carries the engine includes." >&2
    exit 2
  fi
  jobs=$(nproc 2>/dev/null || echo 2)
}

# The roster src/Makevars links, spelled as sources. A vendored `.o` resolves to
# whichever of .cpp/.cc/.c is on disk, the way R's implicit rules do.
sources_of() {
  case "$1" in
    glue)
      sed 's/^GLUE=//' src/include/glue.mk | tr ' ' '\n' | sed 's/\.o$/.cpp/' | grep .
      ;;
    vendored)
      sed 's/^SOURCES=//' src/include/sources.mk | tr ' ' '\n' | grep . |
        while read -r o; do
          for ext in cpp cc c; do
            if [ -f "src/${o%.o}.$ext" ]; then
              echo "${o%.o}.$ext"
              break
            fi
          done
        done
      ;;
  esac
}

run_scope() {
  local scope=$1 sources log runner count
  log=$work/$scope.log
  runner=$work/$scope.sh
  # The flags are baked into a runner rather than exported, so one quoting rule
  # holds for the whole command line. `eval` because R quotes its include path
  # (-I"/usr/share/R/include"): plain expansion word-splits without removing the
  # quotes, and the compiler then never finds R.h.
  {
    echo 'cd src || exit 2'
    echo 'obj=$(echo "$1" | tr / _)'
    printf 'eval %s\n' \
      "\"$cxx $base_flags $(warnings_of "$scope") -fdiagnostics-plain-output -c '\$1' -o '$work/\$obj.o'\""
  } >"$runner"

  sources=$(sources_of "$scope")
  count=$(echo "$sources" | grep -c . || true)
  echo "== $scope: $count translation units"
  : >"$log"
  if ! echo "$sources" | xargs -r -P "$jobs" -n 1 sh "$runner" 2>>"$log"; then
    echo "-- $scope does not compile:"
    grep -E ': (error|fatal error):' "$log" | sed 's/^/   /' | head -n 40
    return 1
  fi
  scan "$scope" "$log"
}

# --- the command line -------------------------------------------------------

case "${1:-all}" in
  flags)
    ride_along_flags_of "${2:?usage: scripts/warnings.sh flags <scope>}"
    exit
    ;;
  scan)
    scan "${2:?usage: scripts/warnings.sh scan <scope> <log>}" \
      "${3:?usage: scripts/warnings.sh scan <scope> <log>}"
    exit
    ;;
  glue | vendored | all) scope=${1:-all} ;;
  *)
    echo "usage: scripts/warnings.sh [glue|vendored|all] [--all]" >&2
    echo "       scripts/warnings.sh flags <scope>" >&2
    echo "       scripts/warnings.sh scan <scope> <log>" >&2
    exit 2
    ;;
esac

show_all=no
[ "${2:-}" = "--all" ] && show_all=yes

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
prepare_compile

status=0
case "$scope" in
  all)
    run_scope glue || status=1
    run_scope vendored || status=1
    ;;
  *) run_scope "$scope" || status=1 ;;
esac
exit $status
