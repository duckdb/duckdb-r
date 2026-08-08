#!/usr/bin/env python3
"""Run a command on a real pty, type into it, then press Ctrl+C.

The child gets a controlling terminal and its own session, so the ^C byte
goes through the tty line discipline exactly as it would for a human at a
prompt -- SIGINT is delivered to the foreground process group, not injected
with kill(2).

Usage:
  ctrlc.py --prewait 2 --type $'code\n' --wait 5 --hits 1 \
           --then $'marker\n' --after 5 -- cmd args...
"""

import argparse
import os
import pty
import select
import signal
import sys
import time

p = argparse.ArgumentParser()
p.add_argument("--prewait", type=float, default=2.0, help="settle before typing")
p.add_argument("--type", dest="typed", action="append", default=[],
               help="text to type; repeat for several chunks")
p.add_argument("--chardelay", type=float, default=0.01)
p.add_argument("--chunkgap", type=float, default=0.8)
p.add_argument("--wait", type=float, default=5.0, help="run time before ^C")
p.add_argument("--hits", type=int, default=1)
p.add_argument("--gap", type=float, default=3.0)
p.add_argument("--then", default="", help="typed after the last ^C")
p.add_argument("--after", type=float, default=5.0)
p.add_argument("cmd", nargs=argparse.REMAINDER)
a = p.parse_args()

cmd = a.cmd[1:] if a.cmd and a.cmd[0] == "--" else a.cmd

pid, fd = pty.fork()
if pid == 0:
    os.execvp(cmd[0], cmd)

out = []
dead = False


def pump(seconds):
    global dead
    end = time.time() + seconds
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if fd in r:
            try:
                data = os.read(fd, 65536)
            except OSError:
                dead = True
                return
            if not data:
                dead = True
                return
            out.append(data)


def slow_write(text):
    for ch in text.encode():
        if dead:
            return
        try:
            os.write(fd, bytes([ch]))
        except OSError:
            return
        pump(a.chardelay)


def reap():
    """Return (exited, status) without blocking."""
    try:
        wpid, status = os.waitpid(pid, os.WNOHANG)
    except ChildProcessError:
        return True, None
    return wpid != 0, status


# Drain startup banner, then type the payload.
pump(a.prewait)
for chunk in a.typed:
    slow_write(chunk)
    pump(a.chunkgap)

pump(a.wait)

for i in range(a.hits):
    sys.stderr.write(f"[ctrlc] ^C #{i + 1}\n")
    sys.stderr.flush()
    try:
        os.write(fd, b"\x03")
    except OSError:
        pass
    pump(a.gap)

if a.then:
    slow_write(a.then)

pump(a.after)

exited, status = reap()
if exited:
    if status is not None and os.WIFSIGNALED(status):
        verdict = f"KILLED by signal {os.WTERMSIG(status)}"
    else:
        verdict = f"EXITED status {status}"
else:
    verdict = "STILL RUNNING"
sys.stderr.write(f"[ctrlc] verdict: {verdict}\n")

if not exited:
    os.kill(pid, signal.SIGKILL)
    os.waitpid(pid, 0)

sys.stdout.write(b"".join(out).decode("utf-8", "replace")
                 if out else "")
