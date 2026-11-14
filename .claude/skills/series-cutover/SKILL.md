---
name: series-cutover
description: Run a cutover the maintainer has decided, without a terminal, by swapping a forward series `<S>-fwd-*` in for its base series with `scripts/series-cutover.sh <S> --confirm <S>@<sha>`, then quoting the archive pull requests, verifying both repositories, and handing back what the run left behind. Use when the maintainer has decided a cutover where the series is coordinated and asks a session to run it, or when asked to cut over, swap in or retire a series. Never from the scheduled loop, which only reports a ready cutover.
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
  The session never ticks or edits that question itself:
  it writes as the maintainer's account, so a tick it made could not be told from theirs.
  Anyone else's comment is information, not a decision.
* **The decision covers the state it was taken on**,
  the tip of `<S>-fwd-green` that `--prepare` printed, which the question names.
  A forward that has moved since, or a gate, a convergence finding or a version warning the decision did not see,
  goes back to the maintainer as a new question.
* **Never from the scheduled loop.**
  A firing reports a ready cutover in stage 6 and stops ([`series-loop`](../series-loop/SKILL.md)).
  It never passes `--confirm`, whatever was decided, because the run belongs to the session the maintainer sent.
  The script cannot tell the two apart; this rule and the loop's own, among its [invariants](../series-loop/SKILL.md#invariants),
  are what keep a firing out.

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

   It moves nothing, and its output is what the decision is taken on:
   the [script's header](/scripts/series-cutover.sh) says what each part of it is,
   and its last lines name the tip of `<S>-fwd-green` to decide on.
2. **Stop on anything `--confirm` would refuse on, or a tip the decision does not name.**
   Under `--confirm` every warning a terminal run leaves to the operator refuses, as the script's header lists,
   so a cutover that needs one weighed, a version going back on a preview line among them, is the maintainer's to run on a terminal.
   So is one whose archive plan names a remote not on GitHub: `--no-archive` beside `--confirm` is a usage error.
   Stopping means reporting the reading on the pull request and waiting for a new decision.
3. **Swap.**

   ```sh
   scripts/series-cutover.sh <S> --remote <fork> --canonical <canonical> --upstream <clone> --confirm <S>@<sha>
   ```

   `<sha>` is the tip the decision names, as `--prepare` printed it.
   The script's header says what the run checks under `--confirm` before it opens or moves anything,
   and what each exit status means;
   whatever the status, it goes into the record with the run's last lines.
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
   Then re-cut the derived strands where the series has them, as the run's last lines say,
   and check the mirror rules with `scripts/pull-config.sh --check`, the last line of the block the loop's stage 6 reports.
6. **Hand the lines under `left behind` to the maintainer**, as printed.
   A litter ref's deletion loses nothing, but a moved ref may hold commits no other ref has, so what moved is read first,
   and nothing refused is routed around.
7. **Record the outcome** on the pull request that carried the decision:
   the command and its exit status, the archive pull requests, the verification, the undo, and the delete lines,
   each block fenced so that it can be run as it stands.

## How to undo

The archive pull requests' heads hold the old lineage,
and the run prints the undo under them, filled in, one leased push per repository (step 4).
That printed copy, quoted in the record, is the one to use.
The leases refuse once the loop has moved a ref since the swap;
read what moved before leasing on it, since that work is lost by the undo.
Undoing is the maintainer's decision as much as the cutover was,
and afterwards the derived strands of both series are re-cut as after the swap.
