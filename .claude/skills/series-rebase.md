# Rebasing a forward series onto a newer mainline

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) —
what this routine is, and when it runs.*

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

Then `scripts/series-glue.sh <S>-fwd`, before starting the replay.
A rebase conflicts where the glue does,
and `rerere` only replays a resolution that has already been made once —
so the pass that decides them is the first one,
and it decides better having seen all of them
(`series-forward.md`, "Read the whole glue set before the first pick").

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

Ported commits (stage 4 of the loop)
whose content `main` has meanwhile absorbed
are dropped by the rebase itself —
the merge backend omits patch-id equivalents,
and a stage-4 sync commit whose delta `main` caught up with
rebases to empty and is dropped too —
which is the intended end of their lives.
One that survives is one `main` does not carry;
it rides on, and the next forward retires it.

## One seed for all four

The two `git rebase --onto seed` lines take **one** seed,
even when `-build` and `-dev` were seeded on different `main` commits
(they were, both series, when this was first done —
`-build` six commits behind `main`, `-dev` two).

Split bases are the state to get out of, not to preserve.
The loop reads the `-build`↔`-dev` delta
as the R-side fixes folded in during repair,
and stage 5 replays buffer commits onto the `-dev` tip;
with two bases that delta also carries `main`-side drift,
and every replay drags it along.
Measured on `main-fwd`: twelve files before the rebase,
three after — exactly the snapshot and test adaptations
that repair had folded in.

## Where each ref lands

`-fwd-build` and `-fwd-build-base` keep their positions.
The buffer carries no runs (`each.yaml` never matches `*-build`),
so moving it claims nothing.

**`-fwd-green` always resets to the new seed tip.**
It is never replayed, and it never rides forward,
however little the series absorbed.

Green claims a `success` run for every commit below it,
and a rebase re-mints every SHA,
so those runs no longer attach to anything —
a green carried forward claims a verification
that no run backs any more.
The failure is not only bookkeeping.
`each.yaml` builds `<S>-green..HEAD` and nothing else,
and builds nothing at all when green is not an ancestor of `HEAD`;
a green replayed to the `-dev` tip leaves that range empty,
so the rebased series emits no builds
and reads IDLE while nothing on the new base has been checked.

Resetting green to the seed puts the whole chain back in flight:
`green..tip` has no runs, and the loop re-verifies it from the seed.
That is the whole cost of a rebase, and it is why one rebases
when `main`'s motion matters to the series, not per commit.

## Green first, then `-dev`

The atomic push already gets the order right —
green lands at the seed in the same push that moves `-dev`,
so the `-dev` push event finds a full `green..HEAD` and starts building.

Moving green on its own starts nothing:
`each.yaml` triggers on pushes to `*-dev`, and green is not one.
So a series pushed with green ahead of the seed —
or one whose green is rewound afterwards — needs the event re-emitted:

```sh
git push --force-with-lease=... origin +<new-seed>:refs/heads/<S>-fwd-green
git commit --amend --no-edit          # same tree, new SHA, on <S>-fwd-dev
git push --force-with-lease=... origin +<new-dev>:refs/heads/<S>-fwd-dev
```

Green first in both cases.
A `-dev` push while green still sits ahead of it
spends the event on an empty range,
and the next one has to be manufactured.

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
