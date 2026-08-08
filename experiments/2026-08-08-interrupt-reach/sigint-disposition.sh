#!/bin/sh
# Which SIGINT handler a running process has installed, and with which
# flags. Point it at a host that is sitting in a wait you just failed to
# cancel; `info symbol` names the library the handler belongs to, which is
# the question -- the package's, the shell's, or an extension's.
#
# Usage: ./sigint-disposition.sh PID
#
# Reads it the only way that is reliable, by calling sigaction(2) in the
# process itself: glibc x86_64 lays struct sigaction out as handler at 0,
# sa_mask at 8, sa_flags at 136. SA_RESTART is 0x10000000.

set -eu

pid=${1:?usage: sigint-disposition.sh PID}

gdb -p "$pid" -batch \
  -ex 'set $buf = (char *) malloc(256)' \
  -ex 'set $rc = (int) sigaction(2, 0, $buf)' \
  -ex 'set $handler = *(void **) $buf' \
  -ex 'set $flags = *(int *) ($buf + 136)' \
  -ex 'printf "handler    = %p\n", $handler' \
  -ex 'printf "sa_flags   = 0x%x\n", $flags' \
  -ex 'printf "SA_RESTART = %d\n", ($flags & 0x10000000) != 0' \
  -ex 'info symbol $handler' \
  -ex 'call (void) free($buf)' 2>/dev/null |
  grep -E "handler|sa_flags|SA_RESTART|in section|No symbol matches"
