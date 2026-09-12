# Link integrity for the documentation system.
# Run through the docs-consistency skill (SKILL.md in this directory);
# helpers are not entry points of their own.
#
# Three claims, checked in one pass over the tracked Markdown:
#
#   1. every internal link in handbook/ resolves,
#      and none climbs out of its directory with ../
#      (the rules: a link that leaves its directory is root-relative);
#   2. every /handbook/... link in a tracked .md outside the tree --
#      the backreferences -- resolves too,
#      which is what keeps a moved leaf from silently orphaning them;
#   3. every fragment on an internal Markdown link matches a heading
#      of the file it points into (GitHub's slug rules, approximated).
#
# External links are skipped entirely: http(s) targets cannot be
# judged from here, and in a sandboxed session most domains are
# unreachable anyway -- SKILL.md says what to do about them.
#
# Prints one line per finding (UPWARD / DANGLING / ANCHOR) and exits
# non-zero when there are any; a clean run prints a one-line count.

import os
import re
import subprocess
import sys

ROOT = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"],
    capture_output=True, text=True, check=True,
).stdout.strip()

# Directories whose Markdown is written by foreign generators;
# their links are the generator's, not this repository's to fix.
FOREIGN = ("revdep/",)

LINK = re.compile(r"\]\(([^)\s]+)\)")
HEADING = re.compile(r"#{1,6}\s+(.*)")


def tracked_md():
    # Tracked plus untracked-but-not-ignored, so a page that is being
    # written is checked before it is ever staged.
    out = subprocess.run(
        ["git", "ls-files", "--cached", "--others",
         "--exclude-standard", "*.md"],
        capture_output=True, text=True, check=True, cwd=ROOT,
    ).stdout.splitlines()
    return sorted(p for p in set(out) if not p.startswith(FOREIGN))


def lines_outside_fences(path):
    in_fence = False
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.lstrip().startswith("```"):
                in_fence = not in_fence
                continue
            if not in_fence:
                yield line


def slug(text):
    # GitHub's ASCII slug: strip inline markup, lowercase,
    # drop punctuation except - and _, spaces become hyphens.
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"[`*_]", "", text.strip())
    text = re.sub(r"[^\w\- ]", "", text.lower())
    return text.replace(" ", "-")


def heading_slugs(path):
    seen = {}
    for line in lines_outside_fences(path):
        m = HEADING.match(line)
        if not m:
            continue
        s = slug(m.group(1))
        n = seen.get(s, 0)
        seen[s] = n + 1
        if n:
            seen[f"{s}-{n}"] = 1
    return set(seen)


def main():
    bad = 0
    links = 0
    slug_cache = {}
    files = tracked_md()

    for rel in files:
        path = os.path.join(ROOT, rel)
        inside = rel.startswith("handbook/")
        for line in lines_outside_fences(path):
            for m in LINK.finditer(line):
                raw = m.group(1)
                if raw.startswith(("http://", "https://", "mailto:")):
                    continue
                target, _, frag = raw.partition("#")

                if target == "":
                    resolved = rel                      # same-page fragment
                else:
                    if inside and target.startswith(".."):
                        print("UPWARD", rel, raw)
                        bad += 1
                        continue
                    base = "" if target.startswith("/") else os.path.dirname(rel)
                    resolved = os.path.normpath(
                        os.path.join(base, target.lstrip("/"))
                    )
                    if not inside and not resolved.startswith("handbook/"):
                        continue                        # outside: handbook links only
                    links += 1
                    if not os.path.exists(os.path.join(ROOT, resolved)):
                        print("DANGLING", rel, raw)
                        bad += 1
                        continue

                if frag and resolved.endswith(".md"):
                    if resolved not in slug_cache:
                        slug_cache[resolved] = heading_slugs(
                            os.path.join(ROOT, resolved)
                        )
                    if frag not in slug_cache[resolved]:
                        print("ANCHOR", rel, raw)
                        bad += 1

    print(f"{len(files)} files, {links} internal links, {bad} bad")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
