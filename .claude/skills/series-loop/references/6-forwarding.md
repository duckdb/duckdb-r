# Stage 6: read the forwarding, and suggest a cutover, never perform one

*Reference for stage 6 of [`series-loop`](../SKILL.md), read when the stage has work;
the handbook leaf is [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md).*

**Every series with a forward counterpart is read here, caught up or not.**
The two lineages carry the same package or they do not,
and the answer is worth having while there is still time to act on it:

```sh
scripts/series-converge.sh <S>
```

It diffs `<S>-dev` against `<S>-fwd-dev`
and sorts every differing path into
what the forwarding explains and what it does not —
the version counter the replay renumbers,
the release paperwork stage 4 never ports,
the flavored READMEs, which are per-branch by design,
the Windows export list while the engines differ,
and the vendored strand,
only while the two still vendor different upstream commits.
Everything else is a finding, and the stage carries it into the report.

**The invariant is the reason the stage exists.**
At the end of a forwarding,
`<S>-dev` and `<S>-fwd-dev` are identical,
or every difference between them is explicable —
a statement about trees, never about ancestry,
since the histories differ by construction.
Both branches advancing is what makes it readable at the frontier
rather than only at the commit a frozen base stopped on (stage 5).

A finding here is not repaired by the swap; it is inherited by it.
Fix it where it belongs —
a missing carry is stage 5's, a missing port stage 4's,
a fix folded on one branch and not the other is stage 2's —
and say so in the commit message that answers it,
which is where a later forward reads it.
An explained difference still gets read, not skipped:
an explanation can go stale,
and a stale one reads exactly like a clean result.
So the class list is deliberately short,
and it grows only where a firing has shown a new class benign —
never on the strength of another script excluding the same path,
which it may well do for an unrelated reason.

**A caught-up forward is reported, not swapped.**
When `<S>-fwd-green` vendors the upstream commit `<S>-green` vendors,
`series-check.sh` says so beside that series' verdict,
and the firing carries it into its summary
as a block somebody can paste into a terminal whole:

```sh
# Tooling from `main`, refs and tags from everywhere.
git fetch --prune --tags --all
git switch main && git merge --ff-only @{u}
git -C ../../../duckdb fetch --prune --tags origin

# Both halves of the question, before anything moves.
scripts/series-check.sh <S> <S>-fwd --upstream ../../../duckdb
scripts/series-converge.sh <S>

# The refs to swap, coverage, convergence, package and versions, and the
# tip of <S>-fwd-green to decide on, with nothing moved. The canonical
# repository is the remote named with --canonical where it is not `upstream`.
scripts/series-cutover.sh <S> --remote origin --upstream ../../../duckdb --prepare

# The rest is a session's, on the maintainer's request: the cutover pull
# request, a review stack per strand, his sign-off on the SHA above, the swap.
# See .claude/skills/series-cutover/SKILL.md.

# A retired lineage moves the badge table, and the mirror rules with it.
scripts/pull-config.sh --check
```

`--remote` names whichever remote of that checkout carries `<S>-green`,
and `--upstream` the `duckdb/duckdb` checkout on disk:
`../../../duckdb` is where `vendor-one.sh` looks for one when nobody names it,
so it is the path the project already assumes.
Substitute either where it is not the reader's;
the names are the same in every `scripts/series-*.sh`
(`handbook/operations/vendoring/series-loop/README.md`),
and naming them is what makes the remote-for-path swap unsayable
rather than merely diagnosable.
Check that the `main` the block lands on is the canonical one:
a fork's mirror lags by however long the mirroring takes,
and a report run off a stale mirror runs a stale `series-cutover.sh`.

**Emit the block whole, on every firing the condition holds**,
with `<S>` and the paths substituted rather than left as placeholders.
`series-check.sh` prints the report's command alone,
and a report run on a clone that last fetched hours ago
reads coverage and convergence off refs that have since moved,
so a firing that abbreviates the block to the line it already saw
hands the reader exactly that.
Repeating the block costs a firing nothing;
it is not summarised into a sentence, and not dropped
because an earlier firing already printed it.

That is the whole stage.
The routine does not build a review stack, open a cutover pull request or run the swap,
and does not swap the four refs by hand instead.

Cutover is the one move that retires a lineage consumers are reading.
Everything else the loop does is bounded and recoverable:
a bad repair is repaired again,
a wrong extension is replayed,
and `-green` only ever moves forward over commits CI called green.
The swap moves a serving green *sideways*,
the single sanctioned non-fast-forward of one (`series-forward/SKILL.md`),
and the one place the canonical repository's copy of green is forced rather than
fast-forwarded, which is why `--canonical` belongs on that run and nowhere else
the routine types by hand;
and it deletes the counterpart that would let it be undone.
What it replaces stays readable only because a review stack's pull request pins each old tip first
(`series-forward/SKILL.md`).
Coverage is only half the question:
it asks how much upstream the forward reaches
and nothing about what it carries.
What it carries is read in the stacks, a strand at a time and a layer at a time,
because whether a difference is explicable is exactly the judgement no script can make.
Verification is mechanical, so the loop owns it;
deciding that r-universe should build a different lineage today
is not, so a human owns that, and signs it off on the cutover pull request.

The swap runs only with `--confirm <S>@<sha>`,
and it cannot tell a firing from a session the maintainer sent: either can type that option.
What keeps a firing from cutting over is what it is told:
stage 6 and the [invariants](../SKILL.md#invariants) of the loop's skill say a firing never runs the swap and never passes `--confirm`,
and [`series-cutover/SKILL.md`](../../series-cutover/SKILL.md) swaps only on the maintainer's sign-off,
which a firing never carries.
The SHA, the tip of `<S>-fwd-green` the sign-off names, ties a run to the state it was given on:
the script refuses once the forward has moved.
