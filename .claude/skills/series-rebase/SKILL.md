---
name: series-rebase
description: Rebasing a generation in place is no longer a move, because a generation is never rewritten; moving an unpublished generation onto a newer `main` is a forward that builds the next generation from it. Use when asked to rebase a series or a generation, to redirect to `series-forward`, and for what the in-place rebases of 2026 paid for once.
---

# Rebasing a generation: superseded by the next generation

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) —
what this routine is, and when it runs.*

Two different moves used to put a series on a newer base.
**Forwarding** replayed a series onto a regenerated seed as a `-fwd` counterpart, across lineages,
and **rebasing** replayed a `-fwd` counterpart onto a newer `main` within its own lineage,
all four refs force-pushed as they stood, green reset to the new seed.

Only the first remains, and it is [`series-forward`](/.claude/skills/series-forward/SKILL.md).
A generation is never rewritten ([`branches/model/`](/handbook/branches/model/README.md)):
its refs move by the loop's own rules, and nothing in the scheme force-pushes one.
Moving an unpublished generation onto a newer `main` is therefore the ordinary forward,
built from that generation's `-dev`, which keeps every commit and every repair folded into it
and costs what a rebase cost, a CI pass over the chain on the new base.
The generation it was built from stays, frozen once two newer ones exist, and is pruned later.

What the rebase bought is still bought:
`-green` of the new generation starts at its seed, so the whole chain is back in flight
and nothing verified on the old base is claimed on the new one;
ported commits whose content `main` has meanwhile absorbed are left behind by the replay,
because only `vendor:` commits travel and the seed carries the rest;
and the two strands share one seed by construction.

## Paid for once, and still true of a forward

- **A `-dev` fix that `main` had meanwhile landed itself.**
  `scripts/rcc-one.sh` conflicted on both series rebased in 2026:
  a CRAN-incoming fix folded into the first `-dev` vendor commit,
  and `fix(rcc-one): Restore the check action's CRAN-incoming default`
  on `main` — the same code, a different comment.
  Resolve toward the base: the new generation takes the whole of the new base,
  so the series' copy goes,
  and its commit message says the fix now comes from `main`.
  Keeping it means conflicting on it at every future forward.

- **Green moves nothing by itself.**
  `each.yaml` triggers on pushes to `*-dev`, and green is not one,
  so a new generation's four refs are pushed together, in one `git push --atomic`,
  and the `-dev` push event finds a full `green..HEAD` to build.
  A `-dev` pushed while green still sits ahead of it
  spends the event on an empty range,
  and the next one has to be manufactured with an amend.
