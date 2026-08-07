# Documentation consistency

The enforcement arm of the handbook rules
([`handbook/meta/handbook/`](/handbook/meta/handbook/README.md)):
the checks that keep the documentation system whole.
Run it when a change touches documentation —
handbook pages, free-floating `.md` files, script headers,
generated indexes — and periodically as a scheduled sweep.

Judgment lives here; mechanics live in helpers.
The one helper today is [`docs-readme.R`](docs-readme.R) in this
directory, which renders and diffs the generated `scripts/` index.
Helpers are not entry points of their own.

## Checks

1. **Tree shape** (mechanical).
   Every directory under `handbook/` has a `README.md`.
   Every subdirectory is listed exactly once
   in its parent's navigation list, with a scope phrase.
   The root's per-area sketch names each area's actual
   next level; a renamed, added, or removed child
   updates the sketch in the same change.
   Internal nodes navigate and may govern:
   a scope sentence, optionally the area's principles,
   and the list — nothing else,
   and a principle passes the three tests in the rules' forms.
   A leaf is written content at some depth;
   a leaf below comprehensive depth ends with one italic
   deepen line naming what remains.

2. **Link integrity** (mechanical).
   Every link under `handbook/` resolves,
   and no link traverses upward with `../`
   (the rules, "The forms": a link that leaves its own directory
   is written from the repository root).

   ```sh
   python3 - <<'EOF'
   import os, re, sys
   bad = 0
   for dirpath, _, files in os.walk("handbook"):
       for f in files:
           p = os.path.join(dirpath, f)
           for m in re.finditer(r"\]\(([^)#]+?)\)", open(p).read()):
               t = m.group(1)
               if t.startswith("http"):
                   continue
               if t.startswith(".."):
                   print("UPWARD", p, t); bad += 1
                   continue
               base = "." if t.startswith("/") else dirpath
               if not os.path.exists(os.path.normpath(base + "/" + t)):
                   print("DANGLING", p, t); bad += 1
   sys.exit(1 if bad else 0)
   EOF
   ```

3. **Generated indexes are fresh** (mechanical).

   ```sh
   Rscript .claude/skills/docs-consistency/docs-readme.R --check
   ```

   Stale → regenerate and include the result in the same change.
   Never edit a generated file by hand.

4. **Source-to-leaf coverage** (judgment).
   Every tracked source path is claimed by exactly one handbook
   leaf. `scripts/` is machine-mapped in the helper's `groups`;
   for the rest, walk the top-level directories
   (`R/`, `src/`, `tests/`, `.github/`, `patch/`, `inst/`, …)
   against the leaves' scope and deepen lines.
   Unclaimed surface is a finding:
   report it with a proposed leaf address —
   an unaddressable path is a defect of the tree,
   per the address rule in
   [`handbook/operations/triage/`](/handbook/operations/triage/README.md).

5. **Backreferences** (judgment).
   The tree is the single source of truth;
   every secondary document — the root `README.md`'s sections,
   reference pages, per-directory indexes,
   and the free-floating files still awaiting absorption —
   names the handbook node it serves.
   Any secondary document touched by the change under review
   must carry its backreference; add it or flag it.

6. **Headers describe their files** (judgment).
   The helper only extracts a first sentence;
   whether that sentence says what the file does is judged here.
   A weak or missing header is fixed at the source file,
   never patched over in the index.

7. **Report and repair.**
   Apply the small fixes in the same change:
   regenerated indexes, navigation lists, links, backreferences,
   header punctuation.
   Report the structural findings instead of acting on them:
   unclaimed surface, a grouping that looks wrong,
   an internal node accreting prose, a leaf outgrowing its scope.
   One summary at the end; no per-file chatter.

The rules define, this skill enforces:
when the two disagree,
[`handbook/meta/handbook/`](/handbook/meta/handbook/README.md)
is the authority, and the fix lands there first.
