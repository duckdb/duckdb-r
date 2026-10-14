#!/bin/bash
# gate.sh [dir]: the glue gate of scripts/series-forward-build.sh (glue_compiles()), in a worktree.
# Prints the files that fail to compile; exit 0 when all compile, 1 when some do not, 2 when it cannot run.
cd "${1:-.}" || exit 2
[ -f src/Makevars.rstrtmgr ] || ./configure >/dev/null 2>&1
flags=$(cd src && R CMD SHLIB -n cpp11.cpp 2>/dev/null | grep -m 1 -E -- '-c cpp11\.cpp' |
  sed -E 's/^ *(ccache )?g\+\+ //; s/ -c cpp11\.cpp -o cpp11\.o *$//')
[ -n "$flags" ] || exit 2
fails=$(cd src && printf '%s\n' *.cpp | FLAGS="$flags" xargs -P "$(nproc)" -I{} \
  sh -c 'eval "g++ $FLAGS -fsyntax-only \"\$1\"" 2>/tmp/gate-err-$$-$(basename $1) || { echo "$1"; cat /tmp/gate-err-$$-$(basename $1) | grep -m3 error >&2; }; rm -f /tmp/gate-err-$$-$(basename $1)' sh {} | sort)
[ -z "$fails" ] && exit 0
echo "$fails"; exit 1
