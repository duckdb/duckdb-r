# Stage 1: vendor onto `<S>-vendor`, and derive `<S>-build`

*Reference for stage 1 of [`series-loop`](../SKILL.md), read when the stage has work;
the handbook leaf is [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md).*

Run **`main`'s copy of the scripts**, against the strand worktree and then the buffer worktree:

```sh
git -C <upstream-clone> checkout --detach origin/<upstream branch of S>
VENDOR_REPO=<S>-vendor-worktree \
  <main-checkout>/scripts/vendor-one.sh --strand --commits 100 <upstream-clone>
git -C <S>-vendor-worktree push origin HEAD:<S>-vendor
(cd <S>-build-worktree && <main-checkout>/scripts/series-vendor.sh <S> --push)
```

The strand takes the vendoring and nothing else: one commit per upstream commit,
the regenerated tree with the patch stack applied and the files generated from it, no counter, no glue gate
([`branches/model/`](/handbook/branches/model/README.md)).
`--strand` stages the configured vendor paths alone and restores whatever else the generator wrote,
and tells the generator which of the two it is writing
(`series_generate_tree()` and `series_generate_derived()` in [`scripts/series-config.sh`](/scripts/series-config.sh),
the patch stack applied between the two).
The buffer is derived from it by [`scripts/series-vendor.sh`](/scripts/series-vendor.sh):
each strand commit cherry-picked, the fifth component stamped, the glue gate run,
so a glue fix is the buffer's own and the two share the vendored tree at every twin.
A `GLUE BROKEN` stop is the buffer's: fix the glue, `git commit --amend --no-edit` the pick at HEAD, rerun.
A `PATCH BROKEN` stop is the strand's: fix the patch in the strand commit, amend it there, and pick again.
A series opened before the strand existed derives one from its buffer first, once, with nothing re-vendored:
`scripts/series-vendor.sh <S> --init --push`, which `series-check.sh` asks for as `VENDOR`.

**The fetch takes tags because the script reads them from the clone.**
Before it walks on, it asks whether the commit it last vendored has been tagged since,
and re-stamps that commit when it has;
a clone that has not fetched the tag answers no,
and the release keeps its `-dev` stamp.

**The clone's HEAD is what picks the line to vendor**, so check it out first.
The script reads it as the walk's right-hand side and nothing else names one;
a clone left wherever the last session parked it
vendors that branch onto this series' strand.
Every line tracks the `duckdb/duckdb` branch of its own name,
and its forward tracks the same branch
([`branches/model/`](/handbook/branches/model/README.md)).
The script refuses when the strand's last vendored commit
is off the clone HEAD's first-parent line,
which is the shape a wrong ref takes;
treat that refusal as the answer and check out the right branch.

This stage is the one place the port stage cannot reach.
Stage 4 brings `.github/`, `scripts/` and `.claude/` on `<S>-dev`
level with `main` every firing,
but `-build` carries no ports by design —
its tooling refreshes only at a forward,
so a buffer opened last month vendors with last month's script.
Invoking `main`'s copy closes that
without teaching CI to read another branch's tree:
it is a script the routine runs, not a cross-branch reference.

Only the script comes from `main`.
Everything it invokes by relative path —
`scripts/rconfigure.py`, `patch/*.patch`, `./configure` —
stays the buffer's,
because those are coupled to the vendored tree
they generate and patch.

The script gates itself:
after each vendored commit it syntax-checks the glue
against the freshly vendored headers
(~20 s, flags derived from `R CMD SHLIB -n`, no link, no R session)
and **stops at the first failure**
with the breaking vendor commit at HEAD and the upstream clone kept.
Then:

1. fix the glue — `src/*.cpp`, `src/include/`, not `src/duckdb/`;
2. `clang-format -i src/*.{c,cc,cpp,h,hpp}` — CI fails any diff;
3. amend into HEAD, appending an `R-side fix` section
   naming the upstream change and what was adapted;
4. rerun the script to finish the budget.

If no glue fix can help
because the vendored tree itself is broken at that commit,
vendor on and fold the broken commit
into the next one, when that repairs it —
the fold rule in stage 2;
the broken tree never stands alone on the chain.

Push `<S>-build` unconditionally —
red never blocks the buffer, that is the point of it.
Tests, R code and patches are `-dev`'s concern;
do not edit `src/duckdb/` by hand in this stage.
