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
   then replay each vendor commit:
   chain-owned paths from the old commit
   (`src/` — vendored sources and glue alike —
   `patch/`, `DESCRIPTION`, `R/version.R`, `R/cpp11.R`),
   everything `main` changed since the old base from `main`,
   deleted-on-`main` files dropped,
   `.github` restored wholesale.
   Tests and snapshots are `main`-owned:
   a `-build` branch carries glue fixes only,
   and test amendments live on `-dev`.
   Renumber the fifth version component onto `main`'s prefix.
   Keep every commit message.
   `scripts/series-forward-build.sh <old-build> <old-base>`
   does exactly this, run on the fresh seed.

2. **`<S>-fwd-dev` = `<S>-fwd-green` = `<S>-fwd-build-base`** =
   the seed tip:
   green contains the flavor change from day one,
   so whatever consumes it builds the flavored package;
   the loop's stage 4 extends `-fwd-dev` from the populated buffer.

3. Nothing else is special:
   a forward series is a series,
   and the loop discovers and drives it like any other.
   The base series stops consuming
   (its stage 4 is skipped while a live `<S>-fwd-build` exists)
   but keeps verifying and promoting what is already in flight —
   `<S>-green` still serves consumers, unchanged, on the old lineage.

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
The swap is the **one sanctioned non-fast-forward move of a green ref**;
everything before and after it is fast-forward only.

If the remote refuses ref deletion (some git proxies do),
remove the `-fwd` refs via the forge UI.
Until they are gone,
the loop ignores a forward series
whose green is an ancestor of its base series' green —
that is cutover litter, not work.
