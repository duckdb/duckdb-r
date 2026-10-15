# shellcheck shell=bash
# The glue gate: whether the glue compiles against the headers the tree vendors.
# Shared by scripts/vendor-one.sh, scripts/series-forward-build.sh and
# scripts/series-advance.sh, and run from the repository root of the tree to
# check.
# shellcheck source=series-config.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/series-config.sh"

# The flags one glue file is compiled with, read off `R CMD SHLIB -n`'s compile
# line for `series_glue_probe`, plus `series_glue_extra_flags`. `src/Makevars`
# includes the `Makevars.rstrtmgr` only `./configure` writes and `.gitignore`
# keeps out of the tree; without it `make -n` stops before it ever prints a
# compile line, so `./configure` runs first where it has not. Empty when no
# compile line was printed, which is the check not being able to run.
glue_compile_flags() {
  local probe flags
  [ -f src/Makevars.rstrtmgr ] || ./configure >/dev/null 2>&1 || true
  probe=$(printf '%s' "$series_glue_probe" | sed 's/[.]/\\./g')
  flags=$( (cd src && R CMD SHLIB -n "$series_glue_probe" 2>/dev/null) |
    grep -m 1 -E -- "-c $probe" |
    sed -E "s/^ *(ccache )?g\+\+ //; s/ -c $probe -o [^ ]+\.o *$//")
  [ -n "$flags" ] || return 0
  printf '%s%s\n' "$flags" "${series_glue_extra_flags:+ $series_glue_extra_flags}"
}

# 0 the glue compiles, 1 some file does not, 2 the check could not run. The
# three are distinct because the caller acts differently on each: only 1 says
# anything about the commit at HEAD. The files that failed go to <failures>,
# one per line, written only by a run that got as far as compiling.
#
# `eval`, because R quotes its include path (`-I"/usr/share/R/include"`); plain
# expansion word-splits without removing the quotes, so g++ never finds R.h and
# every glue file looks broken.
glue_compiles() { # [failures]
  local flags out=${1:-/dev/null}
  flags=$(glue_compile_flags)
  [ -n "$flags" ] || return 2
  # shellcheck disable=SC2016  # the sh child expands $FLAGS and $1, not this shell
  (cd src && printf '%s\n' *.cpp | FLAGS="$flags" xargs -P "$(nproc 2>/dev/null || echo 4)" -I{} \
    sh -c 'eval "g++ $FLAGS -fsyntax-only \"\$1\"" 2>/dev/null || echo "$1"' sh {}) | sort |
    tee "$out" |
    { ! grep -q .; }
}
