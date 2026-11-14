---
name: series-cutover
description: Run a cutover the maintainer has decided, without a terminal, by swapping a forward series `<S>-fwd-*` in for its base series with `scripts/series-cutover.sh <S> --confirm <S>`, then quoting the archive pull requests, verifying both repositories, and handing back what the remotes refused. Use when the maintainer has decided a cutover where the series is coordinated and asks a session to run it, or when asked to cut over, swap in or retire a series. Never from the scheduled loop, which only reports a ready cutover.
---

# Running a decided cutover

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md),
what this routine is, and when it runs.*

A cutover swaps a forward series in for its base series, and what the swap does, and why, is
[`series-forward`](../series-forward/SKILL.md)'s "Cut over" section: the gates, the review, the archive pull requests,
the one atomic leased push, and the cleanup.
This skill is how a session runs one that the maintainer has decided.
The decision stays a human's, and the run may be a session's.

## When a session may cut over

* **Only on the maintainer's explicit decision for that series**,
  recorded where the series is coordinated, such as a ticked question on the pull request that carries the forward.
  Quote the link to that decision before the first command, and record the outcome beside it.
  A decision given only in chat is posted there first, as a question the maintainer ticks, and nothing runs until it is.
  Anyone else's comment is information, not a decision.
* **The decision covers the state it was taken on.**
  A gate, a convergence finding or a version warning it did not see goes back to the maintainer as a new question.
* **Never from the scheduled loop.**
  A firing reports a ready cutover in stage 6 and stops ([`series-loop`](../series-loop/SKILL.md)).
  It never passes `--confirm`, whatever was decided, because the run belongs to the session the maintainer sent.

## The steps

Run them from current `main` with refs fetched from both repositories,
as stage 6's block does ([`references/6-forwarding.md`](../series-loop/references/6-forwarding.md)).
`<fork>` is the remote carrying `<S>-green`, `<canonical>` the remote of `duckdb/duckdb-r`,
and `<clone>` a `duckdb/duckdb` checkout; the coverage gate reads its commits alone, so a `--filter=blob:none` clone serves.
Where a remote's URL is not a `github.com` one, such as a local proxy's address,
name its repository with `git config remote.<name>.github <owner>/<repo>`, or the archive refuses.

1. **Prepare, and read the gates.**

   ```sh
   scripts/series-cutover.sh <S> --remote <fork> --canonical <canonical> --upstream <clone> --prepare --out <dir>
   ```

   It prints the coverage gate, the convergence read, the package and the version of each ref before and after,
   the review stat, the archive plan and the cleanup plan, and moves nothing.
2. **Stop on any failed gate other than a known, explained one.**
   A known one is named in the decision, or called normal by the script itself, as a version going back on a preview line is.
   Coverage that is not verified is a failed gate, and so is an archive plan that names a remote not on GitHub;
   `--no-archive` has no place in a run nobody watches.
   Stopping means reporting the reading on the pull request and waiting for a new decision.
3. **Swap.**

   ```sh
   scripts/series-cutover.sh <S> --remote <fork> --canonical <canonical> --upstream <clone> --confirm <S>
   ```

   `--confirm <S>` is the confirmation a terminal would ask for, so the command line records it.
   The gates run again, and the coverage gate holds rather than warns: without `--upstream` the run refuses.
   The archive pull requests are opened and closed before the swap, and a run that cannot archive stops there.
   The exit status says what happened, as the script's header documents:
   0 swapped and cleaned up; 1 nothing swapped; 2 a wrong command, nothing read;
   9 swapped, with refs the remotes refused to delete or move listed under `left behind`.
   After 9 the swap stands and a rerun finishes nothing.
4. **Quote the archive pull requests**, the block the run prints after the swap, number and URL for each,
   and the undo it prints beneath them.
5. **Verify** both repositories against the run's `refs to swap` lines, and read the verdict:

   ```sh
   git ls-remote <fork> 'refs/heads/<S>-*' 'refs/heads/retry-<S>-*'
   git ls-remote <canonical> 'refs/heads/<S>-green' 'refs/heads/<S>-fwd-green'
   scripts/series-check.sh <S> --remote <fork> --upstream <clone>
   ```

   Each `<S>-*` ref sits at the tip its `-fwd` twin had, the canonical `<S>-green` equals the fork's,
   and no `-fwd` ref is left but those listed under `left behind`.
   Then re-cut the derived strands and check the mirror rules, as the run's last lines say:
   `scripts/series-rc.sh <S> --push`, `scripts/series-alpha.sh <S> --push` where the series has them,
   and `scripts/pull-config.sh --check`.
6. **Hand any litter's delete lines to the maintainer**, one `gh api -X DELETE` line per ref, as printed.
   They lose nothing, and a refused deletion is not routed around.
7. **Record the outcome** on the pull request that carried the decision:
   the command and its exit status, the archive pull requests, the verification, the undo, and the delete lines,
   each block fenced so that it can be run as it stands.

## How to undo

The archive pull requests' heads hold the old lineage,
and one leased push per repository puts it back, with the forward's refs at the tips they gave.
The run prints both filled in, and that is the copy to use:

```sh
git fetch <fork> refs/pull/<dev>/head refs/pull/<build>/head refs/pull/<vendor>/head
git push --atomic \
  --force-with-lease=refs/heads/<S>-build:<new-build> --force-with-lease=refs/heads/<S>-dev:<new-dev> \
  --force-with-lease=refs/heads/<S>-green:<new-green> --force-with-lease=refs/heads/<S>-build-base:<new-build-base> \
  --force-with-lease=refs/heads/<S>-vendor:<new-vendor> \
  <fork> \
  <old-build>:refs/heads/<S>-build <new-build>:refs/heads/<S>-fwd-build \
  <old-dev>:refs/heads/<S>-dev <new-dev>:refs/heads/<S>-fwd-dev \
  <old-green>:refs/heads/<S>-green <new-green>:refs/heads/<S>-fwd-green \
  <old-build-base>:refs/heads/<S>-build-base <new-build-base>:refs/heads/<S>-fwd-build-base \
  <old-vendor>:refs/heads/<S>-vendor <new-vendor>:refs/heads/<S>-fwd-vendor
git fetch <canonical> refs/pull/<green>/head
git push --force-with-lease=refs/heads/<S>-green:<new-green> <canonical> \
  <old-canonical-green>:refs/heads/<S>-green <new-green>:refs/heads/<S>-fwd-green
```

The old `-dev`, `-build` and `-vendor` tips are the heads of their archive pull requests, and so is the old canonical green;
the old `-green` and `-build-base` are on the `-dev` and `-build` lineages, at the tips the run's `refs to swap` lines name.
The leases refuse once the loop has moved a ref since the swap;
read what moved before leasing on it, since that work is lost by the undo.
Undoing is the maintainer's decision as much as the cutover was,
and afterwards the derived strands of both series are re-cut as after the swap.
