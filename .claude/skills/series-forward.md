# Forwarding a series to a newer base

`main` moves under a series:
R-side fixes, workflow changes, version bumps.
The series' branches are built on yesterday's `main`,
and rebasing them in place would rewrite `<S>-green` —
the one ref consumers depend on.
So the rebase happens **beside** the series, not in it:
a forward counterpart is built as a sibling series,
verified from scratch by the ordinary loop,
and swapped in atomically once it has caught up.

## Create the forward series

Bootstrap first, populate second —
like any series,
the four `-fwd` refs start **equal** at the regenerated seed tip;
the replay then populates `<S>-fwd-build`.

1. **`<S>-fwd-build`**: rebuild `<S>-build` on current `main`.
   Regenerate the seed —
   `scripts/flavor.sh`,
   plus the separate fifth-component commit on a dev branch
   (`series-open.md`) —
   then replay each vendor commit onto it.

   **The forward series takes the whole of the new base.**
   The replay is a cherry-pick, not a tree reconstruction:
   a vendor commit's diff is already exactly what vendoring changed —
   `src/duckdb/`, the version bookkeeping,
   and the glue that commit had to adapt —
   so replaying the diffs keeps `main`'s state for everything else
   by construction.
   Files `main` deleted stay deleted,
   tooling `main` gained comes along,
   tests and snapshots are `main`'s,
   and glue born on a `-dev` branch
   rides in the commit that needed it,
   so the preview line needs no exception.
   Nothing is reconstructed from a path list,
   which is what used to go wrong:
   every failure was the list failing to see
   something `main` had removed.

   Only `vendor:` subjects are replayed —
   a `-dev` branch's non-vendor commits belong to `main`
   and are already in the seed.
   That includes the commits stage 4 of the loop
   ported onto `-dev`, and its tooling sync commits
   (`series-loop.md`):
   the seed carries their content,
   the replay leaves them behind,
   and that is where a port's life ends.
   The fifth version component is renumbered as a true counter,
   one per replayed commit,
   so it counts this chain rather than carrying the old one's numbering.
   Keep every commit message;
   the original author survives the replay, only the committer changes.
   `scripts/series-forward-build.sh <old-build> <old-base>`
   does exactly this, run on the fresh seed —
   `<old-base>` only delimits the range.
   `DESCRIPTION` merges on every commit,
   so register the merge driver first (`scripts/setup-git.sh`);
   on a conflict the script stops with the tree in place,
   and rerunning it after `git add` continues where it stopped.

2. **`<S>-fwd-dev` = `<S>-fwd-green` = `<S>-fwd-build-base`** =
   the seed tip:
   green contains the flavor change from day one,
   so whatever consumes it builds the flavored package;
   the loop's stage 5 extends `-fwd-dev` from the populated buffer.

3. Nothing else is special:
   a forward series is a series,
   and the loop discovers and drives it like any other.
   The base series stops consuming
   (its stage 5 is skipped while a live `<S>-fwd-build` exists)
   but keeps verifying and promoting what is already in flight —
   `<S>-green` still serves consumers, unchanged, on the old lineage.

## A WIP forward series is not pinned to its base

Until cutover, a forward series is work in progress:
nothing consumes its refs —
the base `<S>-green` is still the serving ref —
so the fast-forward-only discipline that protects a serving green
does not yet bind the `-fwd` refs.
A WIP forward series can therefore **always be moved
onto the current mainline**,
and this is the normal way to pick up `main`-side fine-tuning —
CI changes, script fixes, R-side work —
that landed while the forward series was being built or verified.

That move is a rebase of the series onto itself, `series-rebase.md`,
and it is not this skill.
Forwarding is `<S>` → `<S>-fwd`, across lineages:
`-fwd-build` is replayed out of the base series' buffer
and `-fwd-dev` starts empty, for the loop to rederive.
A rebase is `<S>-fwd` → `<S>-fwd`, one lineage,
all four refs replayed as they stand, nothing rederived.

A series that has cut over is no longer WIP:
its green serves consumers,
and moving it means a new forward series, not a rebase.

## Cut over

When `<S>-fwd-green` vendors at least the upstream commit
`<S>-green` vendors —
coverage may never regress — run

```sh
scripts/series-cutover.sh <S> origin <upstream-clone>
```

It swaps all four refs in a single `git push --atomic`
with a per-ref lease,
so consumers never observe a half-replaced series,
then deletes the `-fwd` refs.
A base ref that does not exist yet is **created** rather than swapped,
leased as "must not exist" —
a series opened directly as `-fwd`
has no counterpart to replace,
and its first cutover is what brings `<S>-*` into being.
The swap is the **one sanctioned non-fast-forward move
of a serving green ref**;
a WIP `-fwd-green` may be reset by a rebase (above),
but a green that consumers read
moves fast-forward only, before and after the swap.

If the remote refuses ref deletion (some git proxies do),
remove the `-fwd` refs via the forge UI.
Until they are gone,
the loop ignores a forward series
whose green is an ancestor of its base series' green —
that is cutover litter, not work.
