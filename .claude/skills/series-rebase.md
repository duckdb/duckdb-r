# Rebasing a forward series onto a newer mainline

Two different moves put a series on a newer base,
and only one of them is a rebase.

**Forwarding** (`series-forward.md`) is `<S>` → `<S>-fwd`,
across lineages:
`-fwd-build` is replayed out of the base series' buffer
by `scripts/series-forward-build.sh`,
which filters the `vendor:` commits out of a branch that also carries
commits belonging to `main` and renumbers the fifth component;
`-fwd-dev` starts empty at the seed
for the loop to rederive, mining the base `-dev` for what it proved.

**Rebasing** — this skill — is `<S>-fwd` → `<S>-fwd`, one lineage.
A `-fwd` branch has already been through that filter:
a seed, then `vendor:` commits, one counter step each,
sitting on some `main`.
Replaying it onto a newer `main` is the identity,
so all four refs are rebased as they stand.
Nothing is derived and nothing is rederived:
`-fwd-dev` keeps its commits with the repairs folded into them,
and the counter keeps its numbering.

Only while the series is WIP —
after cutover its green serves consumers,
and moving it means a new forward series (`series-forward.md`).

## The rebase

`scripts/setup-git.sh` first:
the `ours-version` driver keeps `DESCRIPTION` off the conflict list
(both strands touch `Version:` on every commit),
`rebase.backend=merge` is what honours the driver,
and `rerere` replays a resolution onto the second series
once it has been made for the first.

```sh
# `<old-seed>` is the branch's `chore: Add fifth version component` commit.
git checkout -B seed <old-dev-seed>
git rebase --onto main "$(git merge-base main <old-dev-seed>)"

git rebase --onto seed <old-dev-seed>   <S>-fwd-dev
git rebase --onto seed <old-build-seed> <S>-fwd-build
```

`-fwd-green` and `-fwd-build-base` carry no commits of their own;
they land as below.
Push all four in one `git push --atomic`
with a per-ref `--force-with-lease`,
so a half-moved series is never observable.

## One seed for all four

The two `git rebase --onto seed` lines take **one** seed,
even when `-build` and `-dev` were seeded on different `main` commits
(they were, both series, when this was first done —
`-build` six commits behind `main`, `-dev` two).

Split bases are the state to get out of, not to preserve.
The loop reads the `-build`↔`-dev` delta
as the R-side fixes folded in during repair,
and stage 4 replays buffer commits onto the `-dev` tip;
with two bases that delta also carries `main`-side drift,
and every replay drags it along.
Measured on `main-fwd`: twelve files before the rebase,
three after — exactly the snapshot and test adaptations
that repair had folded in.

## Where each ref lands

`-fwd-build` and `-fwd-build-base` keep their positions.
The buffer carries no runs (`each.yaml` never matches `*-build`),
so moving it claims nothing.

`-fwd-green` claims a `success` run for every commit below it,
and a rebase re-mints every SHA,
so those runs no longer attach to anything.
Keeping green where it stands has to be earned:
what CI checked must be what is still there.
The delta the series absorbs has to miss the built package entirely —
everything `.Rbuildignore` excludes:

```sh
git diff --name-only <old-green> <new-green> \
  -- . ':!scripts/**' ':!.github/**' ':!.claude/**'
```

Empty, and green rides forward;
`each.yaml` finds nothing to schedule, and nothing needs it to.
Not empty, and green resets to the new seed tip:
`green..tip` then has no runs
and the loop re-verifies the chain from the seed.
That is the whole cost of a rebase, and it is why one rebases
when `main`'s motion matters to the series, not per commit.

## Paid for once

- **A `-dev` fix that `main` had meanwhile landed itself.**
  `scripts/rcc-one.sh` conflicted on both series:
  a CRAN-incoming fix folded into the first `-dev` vendor commit,
  and `fix(rcc-one): Restore the check action's CRAN-incoming default`
  on `main` — the same code, a different comment.
  Resolve toward the base: the forward series takes the whole of
  the new base, so the `-dev` copy goes,
  and its commit message says the fix now comes from `main`.
  Keeping it means conflicting on it at every future rebase.

- **The seed is replayed, never regenerated.**
  Rerunning `scripts/flavor.sh` would re-run `cpp11::cpp_register()`,
  whose output is not stable across cpp11 versions
  (`series-open.md`), so it can quietly differ from the seed
  the series was built and verified on.
  Replaying the recorded seed commits has no such freedom.
  Worth confirming after a rebase, cheaply:
  flavor a scratch branch off current `main`
  and compare its tree to the rebased seed's flavor pair.
  Equal is the expected answer; unequal is a finding, not a verdict —
  read the difference before taking either side.
