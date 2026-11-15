---
name: series-cutover
description: Run a cutover the maintainer has asked for, every mechanical step of it, by opening a cutover pull request, building and opening a review stack of pull requests per strand with `scripts/series-cutover-stack.sh`, folding what the review finds into the forward, asking the maintainer to sign off on the `<S>-fwd-green` SHA, swapping with `scripts/series-cutover.sh <S> --confirm <S>@<sha>` once he has, verifying, and closing and deleting what the cutover opened. Use when the maintainer asks a session to cut over, swap in or retire a series, or to prepare one for his sign-off. Never from the scheduled loop, which only reports a ready cutover.
---

# Running a cutover

*Handbook: [`branches/model/`](/handbook/branches/model/README.md),
what a cutover replaces and what keeps the replaced history reachable.*

A cutover swaps a forward series in for its base series,
and what the swap does, and why, is [`series-forward`](../series-forward/SKILL.md)'s "Cut over" section.
This skill is the whole run, from the request to the cleanup.
The session runs every mechanical step of it:
it builds the stacks, opens and closes the pull requests, folds the fixes, swaps and cleans up.
The maintainer reviews the stacks and signs off, in a pull request rather than in a script.

## Who decides, and who runs it

* **The maintainer starts a cutover**, by asking a session to run one for a series.
  Anyone else's request or comment is information, not a start.
* **He signs it off by ticking the decision question on the cutover pull request**,
  which names the tip of `<S>-fwd-green` the swap is to put in place (step 7).
  That tick is the sign-off, and the only one.
  The session never gives it or simulates it, by a tick, an approving review or anything else:
  it writes through the maintainer's account, so its own tick or approval could not be told from his and would not be his.
  GitHub also refuses an approving review from a pull request's own author, so a review could not carry it anyway.
  A sign-off given only in chat is posted as that question first, and nothing swaps until he ticks it.
* **The sign-off covers the state it names.**
  A `<S>-fwd-green` that moved since, or a stack that changed in a way the review did not read, goes back to him as a new question.
* **Never from the scheduled loop.**
  A firing reports a ready cutover in stage 6 and stops ([`series-loop`](../series-loop/SKILL.md)).
  It never builds a stack, opens a cutover pull request or passes `--confirm`, whatever was decided,
  because the run belongs to the session the maintainer sent.
  The scripts cannot tell the two apart; this rule and the loop's own, among its [invariants](../series-loop/SKILL.md#invariants),
  are what keep a firing out.

## Before the first step

Run from current `main`, with refs fetched from both repositories, as stage 6's block does
([`references/6-forwarding.md`](../series-loop/references/6-forwarding.md)).
`<fork>` is the remote of `krlmlr/duckdb-r`, which carries `<S>-green`, `<canonical>` the remote of `duckdb/duckdb-r`,
and `<clone>` a `duckdb/duckdb` checkout; the scripts read its commits alone, so a `--filter=blob:none` clone serves.
`<dir>` is a scratch directory for the stacks' summaries.
`scripts/setup-git.sh` registers the `DESCRIPTION` merge driver and rerere, which the stack script also runs.
The cutover pull request and the stacks live in the fork, beside the series refs, and keep the canonical repository's list clean.

Pull requests are opened, edited and closed with the session's own GitHub tools:
the GitHub MCP server's pull request tools, or `gh` where it works.
No script calls `gh`, so none of this waits on one being installed or allowed.
A pull request body takes reflowed paragraphs, not semantic line breaks.

## The steps

1. **Open the cutover pull request**, one per cutover, as a draft in the fork:
   an empty commit on the fork's `main`, pushed as `cutover/<S>/pr`, into `main`.

   ```sh
   git fetch <fork> main
   git push <fork> "$(git commit-tree '<fork>/main^{tree}' -p <fork>/main -m 'Cutover <S>')":refs/heads/cutover/<S>/pr
   ```

   Title it `Cutover <S>`, and give its body a section for each of the report, the stacks, the review, the decision and the outcome,
   each filled in as its step comes.
   It coordinates and is never merged.
   The branch is `cutover/<S>/pr` and not `cutover/<S>`, which git could not hold beside the stack branches under it.
2. **Report.**

   ```sh
   scripts/series-cutover.sh <S> --remote <fork> --canonical <canonical> --upstream <clone> --prepare
   ```

   It moves nothing and decides nothing.
   The [script's header](/scripts/series-cutover.sh) says what each part of the report is,
   and its last lines name the tip of `<S>-fwd-green` the decision would be taken on.
   Quote the output, fenced, in the cutover pull request.
   A coverage that regresses exits 1 here and refuses the swap later; report it and stop.
3. **Build the stacks**, one per strand, `vendor`, `build`, `dev` and `green` in turn:

   ```sh
   scripts/series-cutover-stack.sh <S> <X> --remote <fork> --upstream <clone> --summary <dir>/<X>.md
   ```

   The [script's header](/scripts/series-cutover-stack.sh) says what each layer is, how the replay is made, and what each exit status means.
   `main`'s changes there are those of the branch the series releases from, which is `main` for most series,
   and the first layer is called `1-main` whichever branch it replays.
   A conflict stops it with the worktree kept (exit 3): resolve it to what the forward made of the same change,
   `git add` the paths, and rerun with `--continue`.
   A conflict is also a reading for the review: where the forward made something else of it, that is a surprise (step 6).
   A `2-engine` an earlier build left and this one no longer needs stays where it is, and the run exits 9 with the steps that retire it:
   take them in their order, which retargets the `3-fwd` pull request before the branch goes,
   with the strand's GitHub stack taken apart first and linked again after (step 4).
4. **Open each stack's pull requests**, as the script's closing block lists them:
   as drafts in the fork, from the bottom up, each layer into the one below it,
   with its title, its section of the summary as body, and a link to the cutover pull request.
   Add the expectation for that strand and layer (below) to the body, so that the review reads against it.
   Link every stack's pull requests from the cutover pull request.

   Then link each strand's pull requests into one GitHub stack, bottom to top, in the order the closing block lists them,
   and record each stack's number beside its pull requests in the cutover pull request.
   No GitHub tool does it, so it is the REST API, the pull request numbers unquoted:
   the stack is created once the first two are open, and each later one is added on top, under the number the first call answers.
   `<owner>/<repo>` is the repository the closing block names.

   ```sh
   gh api -X POST repos/<owner>/<repo>/stacks --input - <<<'{"pull_requests":[<1-main>,<next>]}' --jq .number
   gh api -X POST -H "X-GitHub-Api-Version: 2026-03-10" repos/<owner>/<repo>/stacks/<number>/add --input - <<<'{"pull_requests":[<next>]}'
   ```

   Where `gh` cannot reach the API, hand the maintainer each stack's calls filled in, with no placeholder left,
   as one fenced block that runs as it stands and prints the stack's number,
   here for pull requests 72 to 75 of `krlmlr/duckdb-r`, the `vendor` stack of the `v2.0-cyanoptera` cutover:

   ```sh
   n=$(gh api -X POST repos/krlmlr/duckdb-r/stacks --input - <<<'{"pull_requests":[72,73]}' --jq .number) && echo "stack $n" &&
     gh api -X POST -H "X-GitHub-Api-Version: 2026-03-10" "repos/krlmlr/duckdb-r/stacks/$n/add" --input - <<<'{"pull_requests":[74]}' &&
     gh api -X POST -H "X-GitHub-Api-Version: 2026-03-10" "repos/krlmlr/duckdb-r/stacks/$n/add" --input - <<<'{"pull_requests":[75]}'
   ```

   A stack can be linked after the fact too, as that cutover's were, stacks 88 to 91 in the fork.
   A stack also retargets each pull request as the one below it merges; these are closed, never merged, so it only groups them.
   Where a rebuild changes which layers a strand has, take its stack apart before any base changes or pull request closes,
   with `gh api -X POST -H "X-GitHub-Api-Version: 2026-03-10" repos/<owner>/<repo>/stacks/<number>/unstack`,
   handed over the same way where `gh` cannot reach the API,
   and link the pull requests again once they stand as the closing block lists them, recording the new number.
   The first pull request of each stack stays open until after the swap:
   its head is the pin that keeps the old tip reachable as `refs/pull/<n>/head`
   ([`branches/model/`](/handbook/branches/model/README.md)), and a closed pull request's head no longer follows its branch.
   A rebuild moves the branches under open pull requests; update a body whose section changed,
   and close the pull request of a head the closing block no longer lists.
5. **Review the stacks cleanly**, every layer against its expectation, and explain each difference on the pull request that shows it.
   The maintainer reads them too, where they are unclear.
6. **Fix a surprise in the forward, at the exact commit.**
   A difference no explanation covers, or a conflict the forward resolved otherwise, is fixed on the `-fwd` strand that carries it,
   in the commit where the problem lies, with [`scripts/series-fold.sh`](/scripts/series-fold.sh):
   on `<S>-fwd-dev`, on `<S>-fwd-build` where the fix is glue, and on `<S>-fwd-vendor` where it is a patch,
   as [`series-forward`](../series-forward/SKILL.md) answers a fix found wanting on the new base.
   Push the folded refs leased; where the fold lands at or below `<S>-fwd-green`, set it back below the folded commit,
   which a forward in progress allows and which the commits above it have to earn again.
   CI judges them again, the loop's stage 3 carries green over them, and then the stacks are rebuilt (step 3) and read again.
   Different upstream commits on the two sides are exceptional, and they ask for more judgment, not a refusal:
   the forward vendored and judged every commit of the range `2-engine` names.
7. **Ask for the sign-off.**
   Once every stack is read and explained, run `--prepare` again (step 2), and post on the cutover pull request a question,
   with a box to tick, that names the tip of `<S>-fwd-green` it printed and links the stacks and their review.
   Then wait for the maintainer's tick (above).
8. **Swap.**
   The base series keeps vendoring while the stacks are read, so rebuild every stack first (step 3),
   and read what a moved old tip added.

   ```sh
   scripts/series-cutover.sh <S> --remote <fork> --canonical <canonical> --upstream <clone> --confirm <S>@<sha>
   ```

   `<sha>` is the tip the ticked question names.
   The [script's header](/scripts/series-cutover.sh) says what the run enforces, the pins among them, and what each exit status means.
   A ref no pin holds refuses the swap before anything moves
   ([`troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md));
   whatever the status, the command and its last lines go into the record.

   Once the swap has run, with exit 0 or 9, close every stack pull request right away, with a comment naming the outcome.
   A closed pull request's head no longer follows its branch, so each pin stays at the old tip whatever moves the branch later,
   and stays readable for as long as the pull request exists.
9. **Verify** both repositories against the run's `refs to swap` lines, and read the verdict:

   ```sh
   git ls-remote <fork> 'refs/heads/<S>-*' 'refs/heads/retry-<S>-*'
   git ls-remote <canonical> 'refs/heads/<S>-green' 'refs/heads/<S>-fwd-green'
   scripts/series-check.sh <S> --remote <fork> --upstream <clone>
   ```

   Each `<S>-*` ref sits at the tip its `-fwd` twin had, the canonical `<S>-green` equals the fork's,
   and no `-fwd` ref is left but those the run lists as left behind.
   Then re-cut the derived strands where the series has them, as the run's last lines say,
   and check the mirror rules with `scripts/pull-config.sh --check`, the last line of the block the loop's stage 6 reports.
   Last, start the verdict mirror in the canonical repository
   ([`per-commit/upstream/`](/handbook/operations/ci/per-commit/upstream/README.md)).
   The new `<S>-green`'s commits were covered as `<S>-fwd-green` already,
   so it posts only what landed since the last hourly run, and the rest stays as it is shown:

   ```sh
   gh api -X POST repos/duckdb/duckdb-r/actions/workflows/each-mirror.yaml/dispatches -f ref=main
   ```
10. **Clean up.**
    With the stack pull requests closed since the swap, delete the stack branches, each leased on the tip read,
    as `scripts/series-prune.sh` prints its deletions, and `cutover/<S>/pr` left for last:

    ```sh
    heads=$(git ls-remote --heads <fork> 'refs/heads/cutover/<S>/*' | awk '$2 != "refs/heads/cutover/<S>/pr"')
    git push $(awk '{ print "--force-with-lease=" $2 ":" $1 }' <<<"$heads") <fork> $(awk '{ print ":" $2 }' <<<"$heads")
    ```

    Where the remote refuses a deletion, as a cloud session's git proxy does,
    dispatch [`delete-branch.yaml`](/.github/workflows/delete-branch.yaml) yourself, one call per branch,
    naming each stack branch's own closed pull request:

    ```sh
    gh api -X POST repos/krlmlr/duckdb-r/actions/workflows/delete-branch.yaml/dispatches \
      -f ref=main -f 'inputs[branch]=<branch>' -f 'inputs[pr]=<number>'
    ```

    It deletes a branch only where the pull request is closed and its head is the branch's tip, and refuses anything else.
    Dispatch the litter the swap left yourself too, the lines it printed, as it printed them:
    a `-fwd-` ref whose twin, the same name without the `fwd-`, is at its tip needs no pull request
    ([`branches/model/`](/handbook/branches/model/README.md)).
    A ref neither proof covers gets a tip-checked `gh api -X DELETE` line instead,
    which is the maintainer's to run, never the session's.
    A dispatch answers 204 and nothing more, so confirm each deletion afterwards with `git ls-remote --heads <fork> <branch>`,
    or by the run's conclusion.
    The workflow runs from the copy on the repository's `main`, so in the fork it works only once the fork's `main` carries the file;
    until then, hand the exact dispatch lines to whoever can reach the fork, beside what the swap left behind, as it printed it.
    A litter ref's deletion loses nothing, but a moved ref may hold commits no other ref has, so what moved is read first,
    and nothing refused is routed around.
    Then close the cutover pull request with the outcome:
    the command and its exit status, the verification, the undo, and the delete lines, each fenced so that it can be run as it stands;
    `cutover/<S>/pr` goes last, once that pull request is closed:
    by `git push --force-with-lease=refs/heads/cutover/<S>/pr:<tip> <fork> :refs/heads/cutover/<S>/pr`,
    or by a dispatch in the fork that names the cutover pull request.

## What each layer is expected to show

| Layer | `vendor` | `build` | `dev` and `green` |
|---|---|---|---|
| `1-main` | every commit of `main` applies without its engine paths, or is recorded; any that touches a file the flavor renames conflicts, as the old tip carries the rename and `main` does not, and is resolved in the old flavor's names, so that where the flavors differ the rename shows in `3-fwd` alone | the same | the same; a commit the series ported is recorded as present |
| `2-engine` | the forward's engine, where it differs: the upstream range it names, and the engine side of the commits `1-main` replays without it, which its summary lists | the same | the same |
| `3-fwd` | empty, but for the files the seed's `chore: Update version to` and flavor commits touch, where the version prefix or the flavor differ ([`scripts/flavor.sh`](/scripts/flavor.sh)): `DESCRIPTION` alone for `1.5.5` against `2.0.0`, the whole rename for `duckdb.dev` against `duckdb.2.0.dev`; and for the forward's own changes to `patch/` where the engines differ | the seed's files as for `vendor`, the vendor counter in `DESCRIPTION` included, and `patch/` as for `vendor`; the commits that differ, the forward's glue adaptations | the seed's files as for `build`, and `patch/` as for `vendor`; the forward's own repairs and carries, each explained |
| `4-old` | roughly the inverse of the layers below | the same | the same |

What `4-old` shows beyond that inverse is something the old series has and the forward does not, and it is read like a surprise.

## How to undo

The swap prints the undo, filled in: one leased push per repository that puts the old tips back from the pins.
That printed copy, quoted in the record, is the one to use.
The leases refuse once the loop has moved a ref since the swap;
read what moved before leasing on it, since that work is lost by the undo.
Undoing is the maintainer's decision as much as the cutover was,
and afterwards the derived strands of both series are re-cut as after the swap.
