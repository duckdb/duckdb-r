#!/usr/bin/env bash
# Git merge driver for NEWS.md: merge it section by section, and leave the
# sections in version order, newest first.
#
# A forward merge of an older release branch into a newer line
# (handbook/branches/model/) meets two NEWS.md files that both grew at the top:
# `# duckdb 2.0.0.9001` and `# duckdb 2.0.1` on the release branch,
# `# duckdb 2.0.99.9001` on `main`. A line-based merge conflicts there every
# time, and resolving it by hand puts the sections in whatever order the hand
# chose. This driver merges by section instead:
#
#   * a section is a `# duckdb <version>` heading and its body, up to the next
#     such heading; the version is the first token after `# duckdb `, and a date
#     or a note after it is part of the heading. Anything before the first
#     heading is merged as one more section that always stays first;
#   * a section on one side only is taken;
#   * a section changed on one side only takes that side;
#   * a section changed on both sides differently is merged three-way with
#     `git merge-file`, and a conflict there is a conflict of the whole merge;
#   * the sections are written newest version first, compared component by
#     component as numbers, whatever side each came from;
#   * the development section, headed exactly `# duckdb (development version)`,
#     sorts above every version. Changed on both sides, it is merged three-way
#     like any other, and where the conflict lies in its `Commits since ...`
#     link line alone, one such line on every side, it takes our link, as the
#     `DESCRIPTION` driver keeps our `Version:`: the link is the branch's own.
#     A conflict anywhere else in it, or a link deleted on one side, is a
#     conflict. Any other heading whose first token is no version sorts
#     below every version, with a warning.
#
#   * a section of the base gone from one side, renamed there or deleted, and
#     left alone on the other is gone, and a renamed one is taken under its new
#     heading: a release renaming `2.0.0.9000` to `2.0.1` merges cleanly.
#
# Where a section of the base is gone from one side and edited on the other,
# matching by heading would set the edit against nothing, so the whole file is
# merged line by line with `git merge-file` instead, and the sections of a clean
# result are put in order the same way. Without python3 the driver falls back to
# that line merge alone, and says so; a renamed heading next to a new section
# then conflicts.
#
# Registered by scripts/setup-git.sh as the `news` driver, which .gitattributes
# names for NEWS.md (handbook/operations/releases/versioning/README.md).
#
# git invokes this with:  %O = ancestor   %A = ours (= output)   %B = theirs
set -euo pipefail

[ $# -eq 3 ] || { echo "usage: merge-news.sh <ancestor> <ours> <theirs>" >&2; exit 2; }

if ! command -v python3 >/dev/null 2>&1; then
  echo "merge-news.sh: no python3, so NEWS.md is merged line by line and not put in version order" >&2
  exec git merge-file -L ours -L base -L theirs "$2" "$1" "$3"
fi

exec python3 -I - "$@" <<'PY'
import re
import subprocess
import sys
import tempfile

o_path, a_path, b_path = sys.argv[1:4]
HEAD = re.compile(r"^# duckdb (\S+)(\s.*)?$")
DEV = "(development version)"
LINK = re.compile(r"^(- )?Commits since \S+: <[^>]*>\.?$")
warned = set()


def read(path):
    with open(path, encoding="utf-8", newline="") as f:
        return f.read()


def write(text):
    with open(a_path, "w", encoding="utf-8", newline="") as f:
        f.write(text)


def sections(text):
    """The preamble and the sections, as {key: text}, key None for the preamble."""
    out = {}
    key, buf = None, []
    seen = {}
    for line in text.splitlines(keepends=True):
        m = HEAD.match(line.rstrip("\r\n"))
        if m:
            out[key] = "".join(buf)
            v = DEV if line.rstrip("\r\n") == "# duckdb " + DEV else m.group(1)
            if v != DEV and not v[:1].isdigit() and line.strip() not in warned:
                warned.add(line.strip())
                print(f"merge-news.sh: heading {line.strip()!r} names no version, so it sorts below every version",
                      file=sys.stderr)
            seen[v] = seen.get(v, 0) + 1
            key = v if seen[v] == 1 else (v, seen[v])
            buf = [line]
        else:
            buf.append(line)
    out[key] = "".join(buf)
    if out.get(None) == "":
        del out[None]
    return out


def is_dev(key):
    v = key if isinstance(key, str) else key[0]
    return v == DEV


def version_key(key):
    v, n = (key, 1) if isinstance(key, str) else key
    if is_dev(key):
        return ([(1, 0, v)], -n)
    parts = []
    for p in re.split(r"[.-]", v):
        parts.append((0, int(p), "") if p.isdigit() else (-1, 0, p))
    return (parts, -n)


def merge3(a, o, b):
    """git merge-file on three texts; returns (text, conflicted)."""
    with tempfile.TemporaryDirectory() as d:
        paths = []
        for name, t in (("ours", a), ("base", o), ("theirs", b)):
            p = f"{d}/{name}"
            with open(p, "w", encoding="utf-8", newline="") as f:
                f.write(t or "")
            paths.append(p)
        r = subprocess.run(["git", "merge-file", "-p", "-L", "ours", "-L", "base", "-L", "theirs", *paths],
                           capture_output=True)
        if r.returncode < 0 or r.returncode > 127:
            sys.exit(r.returncode)
        # Bytes, not text=True, so a CRLF file keeps its line endings.
        return r.stdout.decode("utf-8"), r.returncode != 0


def merge_dev(a, o, b):
    """The development section changed on both sides: merge three-way, and where
    the conflict lies in the link line alone, take our link line. Only when
    each side, and the base where there is one, has exactly one link line: a
    link deleted on theirs would otherwise delete ours."""
    res, c = merge3(a, o, b)

    def links(t):
        return [l for l in (t or "").splitlines(keepends=True) if LINK.match(l.rstrip("\r\n"))]

    ours = links(a)
    if not c or len(ours) != 1 or len(links(b)) != 1 or (o is not None and len(links(o)) != 1):
        return res, c

    def ours_link(t):
        return "".join(ours[0] if LINK.match(l.rstrip("\r\n")) else l for l in (t or "").splitlines(keepends=True))

    res2, c2 = merge3(a, ours_link(o), ours_link(b))
    return (res2, c2) if not c2 else (res, c)


def ordered(merged):
    keys = sorted((k for k in merged if k is not None), key=version_key, reverse=True)
    order = ([None] if None in merged else []) + keys
    # The line ending the file uses, so a CRLF file stays CRLF, for a last
    # line that has none.
    nl = "\r\n" if any("\r\n" in t for t in merged.values()) else "\n"
    out = []
    for i, key in enumerate(order):
        t = merged[key]
        if not t.endswith("\n"):
            t += nl
        # A section that moved off the end still needs the blank lines before
        # the next heading that the file uses between sections, in the line
        # ending of the section's own last line: a file with CRLF lines in
        # some sections only gets no CR padding after its LF ones.
        if i < len(order) - 1 and key is not None and not t.endswith(("\n\n", "\r\n\r\n")):
            own = "\r\n" if t.endswith("\r\n") else "\n"
            t += own + own
        out.append(t)
    return "".join(out)


O, A, B = (sections(read(p)) for p in (o_path, a_path, b_path))

# A base section gone from one side, renamed there or deleted, and edited on
# the other: matching by heading would drop the edit, so merge the file line by
# line, and order a clean result. Gone and left alone, the loop below drops it.
if any(k is not None and ((k not in A and B.get(k, O[k]) != O[k]) or (k not in B and A.get(k, O[k]) != O[k]))
       for k in O):
    text, conflict = merge3(read(a_path), read(o_path), read(b_path))
    write(text if conflict else ordered(sections(text)))
    sys.exit(1 if conflict else 0)

merged, conflict = {}, False
for key in list(dict.fromkeys([*A, *B, *O])):
    o, a, b = O.get(key), A.get(key), B.get(key)
    if a == b:
        res = a
    elif a == o:
        res = b
    elif b == o:
        res = a
    elif key is not None and is_dev(key) and a is not None and b is not None:
        res, c = merge_dev(a, o, b)
        conflict = conflict or c
    else:
        res, c = merge3(a, o, b)
        conflict = conflict or c
    if res is not None and res != "":
        merged[key] = res

write(ordered(merged))
sys.exit(1 if conflict else 0)
PY
