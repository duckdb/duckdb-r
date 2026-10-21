#!/bin/sh
# Build sigprobe.c into a shared library R can dyn.load() and the CLI can
# be preloaded with. Linux needs dl and pthread named explicitly; macOS
# has both in libSystem and has no -ldl to link.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

case "$(uname -s)" in
Darwin) libs="" ;;
*) libs="-ldl -lpthread" ;;
esac

PKG_LIBS="$libs" R CMD SHLIB "$here/sigprobe.c"

echo
echo "built: $here/sigprobe$(R -s -e 'cat(.Platform$dynlib.ext)')"
echo
echo "In R:   see md-probe.R"
echo "In the CLI, if its signing allows a preload:"
case "$(uname -s)" in
Darwin)
  echo "  DUCKDB_SIGPROBE=1:180 DYLD_INSERT_LIBRARIES=$here/sigprobe.so duckdb"
  echo "  (a hardened-runtime binary ignores this; a locally built one does not)"
  ;;
*)
  echo "  DUCKDB_SIGPROBE=1:180 LD_PRELOAD=$here/sigprobe.so duckdb"
  ;;
esac
