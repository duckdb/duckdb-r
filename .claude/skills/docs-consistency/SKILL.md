# Documentation consistency

The enforcement arm of the handbook rules
([`handbook/meta/handbook/`](/handbook/meta/handbook/README.md)):
the checks that keep the documentation system whole.
Run it when a change touches documentation —
handbook pages, free-floating `.md` files, script headers,
generated indexes — and periodically as a scheduled sweep.

Judgment lives here; mechanics live in helpers.
Two helpers live in this directory:
[`docs-readme.R`](docs-readme.R) renders and diffs the generated
`scripts/` index, and [`docs-links.py`](docs-links.py) walks the
tracked Markdown for the link checks below.
Helpers are not entry points of their own.

## Checks

1. **Tree shape** (mechanical).
   Every directory under `handbook/` has a `README.md`.
   Every subdirectory is listed exactly once
   in its parent's navigation list, with a scope phrase.
   The root's per-area sketch names each area's actual
   next level; a renamed, added, or removed child
   updates the sketch in the same change —
   hold `ls -d handbook/*/*/` beside the sketch to see a child
   the prose skipped, since the sketch reads fluently either way.
   Internal nodes navigate and may govern:
   a scope sentence, optionally the area's principles,
   and the list — nothing else,
   and a principle passes the three tests in the rules' forms.
   A leaf is written content at some depth;
   a leaf below comprehensive depth ends with one italic
   deepen line naming what remains.

2. **Link integrity** (mechanical).
   Every internal link under `handbook/` resolves,
   no handbook link traverses upward with `../`
   (the rules, "The forms": a link that leaves its own directory
   is written from the repository root),
   every `/handbook/…` link in a tracked `.md` outside the tree —
   the backreferences — resolves too,
   and every fragment on an internal Markdown link
   matches a heading of the file it points into.

   ```sh
   python3 .claude/skills/docs-consistency/docs-links.py
   ```

   External links are outside the helper's reach.
   Check this repository's own issue and pull-request links
   with whatever GitHub access the session has,
   and treat an unreachable foreign domain as unverified, not broken:
   in a sandboxed session the proxy answers 000 or 403
   for anything off the allow-list,
   which says nothing about the link.

3. **Generated indexes are fresh** (mechanical).

   ```sh
   Rscript .claude/skills/docs-consistency/docs-readme.R --check
   ```

   Stale → regenerate and include the result in the same change.
   Never edit a generated file by hand.

4. **Directory maps are complete** (mechanical, then judgment).
   A leaf that presents itself as the map of a directory
   is compared against that directory, both ways.
   The one such map today is the workflow inventory
   ([`handbook/operations/ci/workflows/`](/handbook/operations/ci/workflows/README.md)):

   ```sh
   diff <(basename -a .github/workflows/*.yaml | sort) \
        <(grep -o '[A-Za-z0-9._-]*\.yaml' \
            handbook/operations/ci/workflows/README.md | sort -u)
   ```

   A missing or extra row is repaired in the same change.
   Whether each row's *fires on* still matches the file's `on:` block
   is judged by reading the blocks — triggers drift silently,
   and the prose keeps rendering either way.

5. **Deepen lines are live** (mechanical, then judgment).
   A deepen line's promises must still be redeemable.
   List them with `grep -rn -A3 -- '\*To deepen:' handbook/`,
   then check each issue a *drain* clause names
   against the tracker with whatever GitHub access the session has —
   a closed issue is drained or dropped, never left promised —
   and each `§`-named section against the headings
   of the file it would absorb.

6. **Source-to-leaf coverage** (judgment).
   Every tracked source path is claimed by exactly one handbook
   leaf. `scripts/` is machine-mapped in `docs-readme.R`'s `groups`;
   for the rest, walk the top-level directories
   (`R/`, `src/`, `tests/`, `.github/`, `patch/`, `inst/`, …)
   against the leaves' scope and deepen lines.
   Unclaimed surface is a finding:
   report it with a proposed leaf address —
   an unaddressable path is a defect of the tree,
   per the address rule in
   [`handbook/operations/triage/`](/handbook/operations/triage/README.md).

7. **Backreferences** (judgment).
   The tree is the single source of truth;
   every secondary document — the root `README.md`'s sections,
   reference pages, per-directory indexes,
   and the free-floating files still awaiting absorption —
   names the handbook node it serves.
   Any secondary document touched by the change under review
   must carry its backreference; add it or flag it.

8. **Headers describe their files** (judgment).
   `docs-readme.R` only extracts a first sentence;
   whether that sentence says what the file does is judged here.
   A weak or missing header is fixed at the source file,
   never patched over in the index.

9. **Report and repair.**
   Apply the small fixes in the same change:
   regenerated indexes, navigation lists, links, backreferences,
   map rows, stale drain pointers, header punctuation.
   Report the structural findings instead of acting on them:
   unclaimed surface, a grouping that looks wrong,
   an internal node accreting prose, a leaf outgrowing its scope,
   an entry restating what the experiment, issue, or plan it links
   already holds
   ([`handbook/meta/authoring/`](/handbook/meta/authoring/README.md),
   "How long an entry is").
   One summary at the end; no per-file chatter.

The rules define, this skill enforces:
when the two disagree,
[`handbook/meta/handbook/`](/handbook/meta/handbook/README.md)
is the authority, and the fix lands there first.
