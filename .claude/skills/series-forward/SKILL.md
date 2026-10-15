---
name: series-forward
description: Forward a line onto a newer `main` by building its next generation, `<L>-v<NNN>-*`, beside the newest one from that generation's own `-dev`, so its commits keep what the series proved, and pointing r-universe at it by pull request once it has caught up, so no ref anyone reads is ever rewritten. Covers the generation scheme, the cutover and pruning. Use when `main` has moved under a series and its branches need the newer base, when asked to forward a series, to cut over to a generation, or to prune old ones.
---

# Forwarding a series to a newer base

*Handbook: [`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md) —
what this routine is, and when it runs.*

`main` moves under a series:
R-side fixes, workflow changes, version bumps.
The series' branches are built on yesterday's `main`,
and rebasing them in place would rewrite `<S>-green` —
the one ref consumers depend on.
So the rebase happens **beside** the series, not in it:
the next **generation** of the line is built as a sibling series,
out of the commits the newest generation has already had judged,
verified again by the ordinary loop on the new base,
and published in its turn, by a pull request that points r-universe at its green once it has caught up.
Nothing is swapped and nothing is rewritten; the generations below stay where they are
([Generations](#generations), below).

`<L>` is the line, `v2.0-cyanoptera`; `<S>` is its newest generation, the one the forward is built from,
and `<G>` the generation it creates, `scripts/series-lib.sh`'s `series_next`:
`v2.0-cyanoptera-v001` for a line whose newest is `v2.0-cyanoptera-fwd`, which is its `v000` under the older spelling.

**A release is the largest instance of `main` moving, and not a rule of its own.**
Nothing schedules a forward; what makes one due is drift worth resolving.
For a series whose own line has just released, the version is one reading of that drift:
its seed sits below the release it produced, `1.5.5.9020.36` being under `1.5.6`,
and re-seeding is what restores the correspondence.
A preview line is the exception, its prefix being deliberately not `main`'s
([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)),
so a bump on `main` moves nothing under it and only the R-side drift counts.

## Create the next generation

Bootstrap first, populate second —
like any series,
the four `<G>-*` refs start **equal** at the regenerated seed tip;
the replay then populates `<G>-build`.

1. **`<G>-build`**: rebuild `<S>-dev`, and the buffer above it, on current `main`.
   Regenerate the seed — `scripts/flavor.sh <F>`, plus a separate
   `chore: Add fifth version component` commit appending the counter's `.0` to
   `Version:` — then replay each vendor commit onto it.
   `flavor.sh` needs `krlmlr/cpp11` installed and refuses the whole run without
   it ([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)).
   A series seeded from a release branch rather than from `main`
   regenerates on **that** branch,
   whose `scripts/` may be older than `main`'s —
   replay the recorded seed commits instead when it is.

   **A preview line's seed takes its version prefix again here.**
   A regenerated seed carries `main`'s prefix, which is the released line's,
   and the replay cannot put the preview prefix back:
   the `DESCRIPTION` gate keeps our side verbatim across differing prefixes,
   so every picked commit inherits whatever the seed was stamped with
   ([`operations/releases/versioning/`](/handbook/operations/releases/versioning/README.md)).
   Stamp it in the fifth-component commit, before the four `<G>-*` refs are created equal.
   The prefix is the previewed line's, not the seed's: previewing 2.1 is `2.0.99.9000`,
   previewing 2.0 is `1.99.99.9000`.

   **A seed on a released `main` takes fledge's first dev version as its fourth component.**
   On the day of a release `main` carries the bare `1.5.6`,
   and appending the counter's `.0` would leave four components where the replay reads five.
   The seed takes `1.5.6.9000.0`, the version `main`'s own next bump writes,
   which also rises past every version the old chain published, `1.5.5.9020.57` among them.

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

   **Read the whole glue set before the first pick.**

   ```sh
   scripts/series-glue.sh <old-base>..<old-build>
   ```

   Every R-side adaptation the buffer carries, oldest first,
   with the upstream SHA each answered,
   the `R-side fix` prose each left behind,
   and the files ranked by how often they were adapted.
   That ranking is the conflict forecast:
   a file adapted five times in the range
   is a file upstream keeps moving,
   and the pick that stops will be one of those five.
   Read them together and the shape is visible —
   the same call site migrated to an accessor,
   then to a different type, then renamed —
   so a conflict is resolved toward
   where the range is going, in one move.
   Read one at a time and each is resolved on its own evidence,
   toward a state a later commit in the same range overwrites:
   the work is done twice, and the intermediate resolution
   is the one that has to be undone.
   Findings recorded by stage 3 of the loop
   — what r-universe made of the base series' green,
   on the platforms the gate never covered —
   travel in those same messages, and are read in the same pass.

   **Read what the base learned, and judge it, in the same pass.**

   ```sh
   scripts/series-learned.sh <S>          # per commit, what -dev carries beyond its -build twin
   scripts/series-learned.sh <S> --diff   # the changes themselves
   ```

   `-build` is what pure vendoring produces plus the glue each engine needed to compile;
   `-dev` is the same commits with what CI demanded afterwards folded in,
   and the replay below takes `-dev`, so every one of those fixes travels, the sound ones and the expedient ones alike.
   The report is the difference, one commit at a time: the paths the fix touched, the `R-side fix` prose that explains it,
   and the files ranked by how often a fix landed in them,
   35 commits of 2160 on `v2.0-cyanoptera`.
   Read each by its merits.
   A fix that should not travel as it is gets a correction *after* the replay,
   written as a commit on the forward commit that carries it and folded there with
   [`scripts/series-fold.sh`](/scripts/series-fold.sh), which replays everything above and surfaces where later commits leaned on it;
   a snapshot or a skip taken at a rewind gets the engine gate stage 2 would have written.
   Nothing is edited on the replay by hand, and nothing is dropped from it:
   a `-dev` commit dropped in favour of its buffer twin leaves every later commit's diff standing on a fix that is no longer there.

   **The forward keeps `<S>-dev`'s commits as they are, wherever it can.**
   The replay's source is `<S>-dev`, not `<S>-build`:
   a `-dev` vendor commit carries the R-side fix CI demanded for it, folded in by stage 2 of the loop,
   while its `-build` twin carries only what the glue gate demanded.
   Replaying `-build` rebuilt the compile side and left everything the series had learned afterwards
   to be rediscovered on the forward, one red commit at a time, or to be lost where the loop's carry did not reach:
   `v2.0-cyanoptera-fwd` took 2160 commits that way, 63 of them with a carry,
   and ended with `tests/testthat/test-variant.R` deleted and seven more tests changed or skipped against its base
   ([#2900](https://github.com/duckdb/duckdb-r/pull/2900)),
   and with glue conflicts resolved differently from how the base had resolved the same ones.
   Replaying `-dev` makes every forward commit's tree the old, verified tree plus `main`'s delta since the old seed,
   so the work the base did survives by construction,
   and the only new work is where that delta meets the series.
   That is what a landing already does with the rc strand ([`series-land`](/.claude/skills/series-land/SKILL.md)),
   and the two share one replay.

   Only `vendor:` subjects are replayed —
   a `-dev` branch's non-vendor commits belong to `main`
   and are already in the seed.
   That includes the commits stage 4 of the loop
   ported onto `-dev`, and its tooling sync commits
   (`series-loop/SKILL.md`):
   the seed carries their content,
   the replay leaves them behind,
   and that is where a port's life ends.
   The script places a port by the `main` commit its `-x` trailer names, and a sync by its subject;
   what is neither is named, below.
   The fifth version component is renumbered as a true counter,
   one per replayed commit,
   so it counts this chain rather than carrying the old one's numbering.
   Keep every commit message;
   the original author survives the replay, only the committer changes.

   ```sh
   scripts/series-forward-build.sh <S>-dev <old-base> --buffer <S>-build
   ```

   does exactly this, run on the fresh seed —
   `<old-base>` only delimits the range, and the old seed's base is always right.
   `--buffer` names the base's buffer, whose vendor commits above the newest upstream commit `<S>-dev` vendors
   are replayed after `-dev`'s:
   `-dev` covers only what the base has consumed, and the buffer beyond its tip still comes from `-build`,
   compile side only, for the loop's stage 5 to carry into as the base consumes it.
   The script refuses a `-dev` whose newest vendor commit has no twin on the buffer,
   which is a fold made in a repair and not mirrored (`series-loop/SKILL.md`, stage 2).

   **A pick never stops a test the seed runs.**
   The seed carries `main`'s tests, and a `-dev` commit folded at a rewind may have deleted one or skipped it for good,
   where its engine could not pass it;
   the base's later restore is a commit of its own, which no replay of vendor commits takes
   ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).
   So the script keeps the seed's copy of such a path, names it on stdout and in the commit's message,
   and lets an engine gate through, since that re-arms its test by itself.
   CI then judges the commit, and a red there is gated in stage 2 as any red at a rewind is.

   **Where the replay starts is read from the trees, not chosen.**
   A range starting above the old base is legitimate
   where the new base already vendors the commit the range starts at,
   and nowhere else:
   a range that starts higher lands its first commit on whatever the base
   happens to vendor, walking the engine backwards where that is older.
   So the script reads the engine the seed vendors
   (`DUCKDB_SOURCE_ID` in the vendored `pragma_version.cpp`)
   and starts above the vendor commit naming it, if the range has one.
   That is a release line once `main` has vendored its release:
   `v1.5-variegata` vendored `069cc9f9b5` before `main` shipped it as 1.5.6,
   and its forward onto that `main` replays nothing below it.
   For a line tracking upstream `main`,
   what establishes such a base is upstream's back-merge of a release branch,
   and until one lands the whole buffer replays
   ([`plan/PLAN-v2-series-open.md`](/plan/PLAN-v2-series-open.md)).

   **A preview line's buffer opens on a rewind, and the script rebuilds it.**
   A preview line seeds on `main`, which vendors a released engine,
   so its first vendor commit walks back to where the lines fork:
   `v2.0-cyanoptera` from 1.5.5 to `duckdb/duckdb@ee0b06f6f0`, January's fork point.
   That commit's diff is taken against the engine the *old* seed vendored,
   and a new seed on a newer release has another one:
   picked, it lays 1.5.5's delta over 1.5.6's tree.
   Where the old parent of the first pick vendors another engine than the seed,
   the script takes that commit's vendored strand whole
   (`src/duckdb/`, `patch/`, `R/version.R`, `src/include/sources.mk`)
   and replays only the rest of its diff, the glue the rewind adapted.
   The Makevars stay a diff, because they are generated from `src/Makevars.in`, which is `main`'s.
   The seed's patches go with the seed's strand:
   they were written for the release, and the base series never had them at this commit,
   so the strand stays equal to the base buffer's at every commit, which is what the tree check reads.
   It also means the seed is no evidence about the buffer's own `patch/` commits in such a range,
   and the script lists every one of them rather than judging one carried
   because `main` holds the same entry for its release.

   **`main`'s glue meets the fork point's engine there, and some of it is newer.**
   R-side work written against the release calls what the release has,
   and the fork point is months older:
   forwarding onto 1.5.6, `PreprocessStatements()`, `GetAutoRollback()` and `CanonicalizePath()`
   were all missing at `ee0b06f6f0`.
   Nothing conflicts, so the script gates the glue as `vendor-one.sh` does
   (after the rewind, after every pick whose old commit adapted glue, and at the end)
   and stops with HEAD on the commit to amend.
   Step each call back to what the fork point offers,
   and restore it in the vendor commit that brings the API back,
   usually upstream's merge of the release branch into its `main`:

   ```sh
   git log --reverse --format='%h %s' -S<api> <rewind>..<S>-build -- src/duckdb/src/include | head -1
   ```

   Replay to that commit (the script's `<old-build>` may be any commit of the range), amend the restore,
   and carry on, naming both ends in `R-side fix` sections.
   The pair then travels:
   the next forward replays the rewind's glue diff and the restore's like any others,
   and only glue `main` gained since needs a new pair.
   A gate that fails between two gated commits names the last commit that passed;
   the break is in that range, often an upstream change the old glue never touched,
   as `CheckResultTypeForR()` met upstream's `Identifier`.

   **`main`'s tests meet that engine too, and are gated rather than rewound.**
   A test asking for behaviour the fork point lacks gets `skip_if_engine_before()` in the stage 2 repair on `-dev`,
   never a deletion or a rewritten expectation ([`series-loop/SKILL.md`](series-loop), stage 2).
   That engine gate names the engine that brings the behaviour back,
   so the test runs again there whether or not the gate's removal travels with the forward.

   **A forward that re-roots is a graft, and grafts nothing but a tree.**
   Where the point is to drop history below a fork point — an opening leaves the
   parent carrying it ([`series-open/SKILL.md`](series-open)) — the new root is
   one commit whose tree *is* the fork-point commit's, verbatim, parented on
   current `main`:

   ```bash
   git commit-tree <fork-point commit>^{tree} -p <main> -F <message>
   ```

   No pick, because a pick would land one line's delta on another's tree. No
   regenerated seed either: the graft keeps the fork point's R side, and the
   forward that aligns it with `main` is a separate move. Replay everything the
   branch has taken since — every subject, not only `vendor:`, since the base is
   that range's own base — stamping the counter on each. `Version:` is the graft's
   only edit, taking the prefix of the line the series now previews.

   **That separate move is the next ordinary forward, and it takes the graft from the child.**
   A graft carries the glue of every commit below the fork point,
   and none of those commits is in its range any more,
   so a rewind that takes only the first pick's strand leaves all of it behind:
   108 compile errors against a 2.0 engine.
   The series the opening cut owns that history,
   so forward it first and name its buffer:

   ```sh
   scripts/series-forward-build.sh --graft-from v2.0-cyanoptera-v001-build main-dev <old-base> --buffer main-build
   ```

   The script rebuilds the graft as one vendor commit naming the fork point:
   the strand is the graft's,
   and the rest is what the child's forward changed between its seed and the commit vendoring the fork point,
   so every conflict with the new `main` was resolved there, once.
   It refuses a range that stands on a graft without `--graft-from`, and the option without a graft.
   After that forward the parent's buffer opens on an ordinary rewind,
   and the forward after it needs nothing from the child.

   **It refuses to start while the buffer carries a change
   the new base does not have.**
   `-build` takes no ports, so a non-vendor commit above its first
   vendor commit is the buffer's own —
   the `patch/` entries stage 3 commits onto it —
   and the replay has nowhere to put it.
   The script names each one and stops before writing anything.
   Work through them in this order:

   1. **Read it.** The refusal rests on two cheap tests,
      so a change the new base carries in a shape neither recognises
      is listed too; confirm by reading the base for its effect.
      If it is there, the commit is done.
   2. **Find the commit it belongs to** —
      the first whose tree carries the code it answers, never the commit
      it was written at
      ([`vendoring/troubleshooting/`](/handbook/operations/vendoring/troubleshooting/README.md)).
      Name it by its upstream SHA:
      the replayed commit does not exist yet.
   3. **Rerun with `--placed <sha>` for each** — the script prints the
      whole command — and let the replay finish.
      The acknowledgement is remembered, so a conflict stop resumes
      without it.
   4. **Fold each change into its commit, then replay the tail.**
      Detach at the commit, apply the change, `git commit --amend`,
      and `git rebase --onto HEAD <that commit> <G>-build`.
      Amending rather than inserting is what keeps the counter equal to
      the number of commits the script wrote,
      which is how it finds its place on a later resume.
   5. **Verify by tree.**
      `git diff --name-only <S>-build <G>-build -- src/duckdb patch/`
      must be empty.
      This is the check that catches everything above going wrong,
      including a fold that landed in the wrong place.
   `DESCRIPTION` merges on every commit,
   so register the merge driver first (`scripts/setup-git.sh`);
   on a conflict the script stops with the tree in place,
   and rerunning it after `git add` continues where it stopped.
   Expect one on `src/Makevars` and `src/Makevars.win` wherever a pick moved the include list,
   for as long as the base buffer still keeps cpp11 under `inst/include`:
   take the pick's line with `-I../inst/include` spelled `-Ivendor`, as the seed's template writes it.
   A pick resumed after a conflict is gated whatever it touched, because its resolution is new glue;
   a glue conflict usually resolves to what the base `<S>-dev` carries in that place,
   since it met the same code through a port.

   **Adapt where the new base asks, and minimally.**
   The glue gate stops where `main`'s glue and the series' engine disagree, and that fix is folded into the commit it stopped on, as above.
   Everything else the forward learns, it learns from per-commit CI once `<G>-dev` is extended:
   a red there gets the smallest fix that answers it, folded into the commit that introduced the defect with
   [`scripts/series-fold.sh`](/scripts/series-fold.sh), the rule a landing follows too ([`series-land`](/.claude/skills/series-land/SKILL.md), step 4),
   and mirrored onto `<G>-build` where it is glue (`series-loop/SKILL.md`, stage 2).
   Do not put a snapshot or a test fix onto `<G>-build` by hand ahead of a verdict.

2. **`<G>-dev` = `<G>-green` = `<G>-build-base`** =
   the seed tip:
   green contains the flavor change from day one,
   so whatever consumes it builds the flavored package;
   the loop's stage 5 extends `<G>-dev` from the populated buffer.
   Up to the commit the base `-dev` had reached when the forward was built, there is nothing left to carry,
   and the stage recognises a fix the buffer commit already holds;
   above it, where the buffer came from `-build`, it folds the base's fixes in as it always has.

3. Push the four refs together, `git push --atomic`, plain pushes creating new names,
   and register `<G>-green` in the fork's universe, `krlmlr.r-universe.dev`,
   in place of the generation it was built from
   ([`branches/flavors/`](/handbook/branches/flavors/README.md)):
   that universe builds the newest generation across the platforms the gate never sees,
   so the cutover below can be judged on fifteen targets rather than one.
   Nothing else is special:
   a generation is a series,
   and the loop discovers and drives it like any other.
   **The generation it was built from keeps consuming too**, at full speed,
   vendoring, repairing, porting and extending as if nothing had been built on it,
   for as long as the loop serves it ([Generations](#generations));
   the published green still serves consumers, unchanged, on its own lineage.
   The two run level until the new one is published,
   which is what the invariant below needs
   and what the loop's stage 5 used to prevent.

## An unpublished generation is not pinned to its base

Until it is published, a generation is work in progress:
nothing installs from its refs —
the published green is still the serving ref —
so the fast-forward-only discipline that protects a serving green
does not yet bind it beyond the loop's own rules.
Such a generation can therefore **always be moved
onto the current mainline**,
and this is the normal way to pick up `main`-side fine-tuning —
CI changes, script fixes, R-side work —
that landed while the generation was being built or verified.

That move is this skill again, from the unpublished generation:
its `-dev` keeps every commit and every repair folded in,
so the next generation is the rebase a `-fwd` series used to get in place,
and it leaves the generation it was built from where it stands rather than rewriting it
([`series-rebase`](/.claude/skills/series-rebase/SKILL.md) says what an in-place rebase paid for once).
Whether it is worth a generation is the same question as for any forward:
`main`'s motion has to matter to the series, since each one costs a CI pass over the chain.

A generation that has been published is no longer work in progress:
its green serves consumers, and it moves the same way, by the next generation.

## What the forward guarantees

> Every commit of `<G>-build` replayed from `<S>-dev` has the tree of its `-dev` twin plus `main`'s delta since the old seed,
> except where the glue gate or the test guard adapted it, and each adaptation is named in the commit.

Work the base series did survives by construction, and the only new work is where `main`'s delta meets the series.
Three limits bound that claim, and each is somebody's work rather than a gap in the claim:

* **The glue gate is a compile check.**
  It does not see behaviour `main`'s delta changes, so per-commit CI still judges every commit of `<G>-dev`,
  and a red there gets a minimal fix folded into the commit that introduced it (above).
  "Adapt minimally" covers a test failure as much as a build failure.
* **Keeping `-dev` keeps its defects along with its fixes.**
  The forward is no better than its base where `main` did not move;
  improvement over the incumbent comes from `main`'s side alone, and a defect the base carries is fixed on the base, where stage 2 fixes one.
* **`-dev` covers only what the base has consumed.**
  The buffer beyond its tip is replayed from `-build`, compile side only, and the loop's carry serves it as before.

## What a forwarding has to end up with

A forward is the same series rebuilt on a newer `main`,
so its history differs by construction
and its content must not.
That is the invariant:

> At the end of a forwarding,
> `<S>-dev` and `<G>-dev` are **identical**,
> or every difference between them is **explicable**.

Read it as a claim about trees, never about ancestry —
the two share a seed generation and nothing below it,
the version counters are renumbered,
and the ported commits the replay leaves behind
are content the new seed already carries.
Ancestry says nothing here; the working trees say everything.

```sh
scripts/series-converge.sh <G>
```

prints the difference against the generation `<G>` was built from and sorts it into the two.
What is explicable is a short, evidenced list —
`DESCRIPTION`'s `Version:` line, which the replay renumbers;
`NEWS.md`, the release paperwork stage 4 never ports;
and the **vendored strand** —
`src/duckdb/`, `patch/`, `R/version.R`, `src/include/sources.mk`
and the Makevars —
*only while the two vendor different upstream commits*,
where it is the gap and not a finding.
Every file in that strand is a function of the upstream tree:
`R/version.R` carries the engine's own version,
the source list and the Makevars are generated from it,
and `patch/` retires entries as upstream absorbs them.
Once both sit on the same upstream SHA the whole strand must agree:
a forward regenerates the vendored tree from its own patch stack,
which is what step 1's tree check verifies at replay time.

Everything else is a finding —
glue, tests, R code, the READMEs, the tooling directories —
and it belongs to whichever stage should have moved it:
a carry stage 5 could not make,
a port that reached one branch and not the other,
a fix folded on one and not the other.
A forward replayed from `-dev` starts with none of these up to the commit the base had reached,
so what the read shows afterwards is what the two lineages did since, and a test the replay kept.
The swap does not resolve a finding; it inherits it,
onto the lineage r-universe builds from.

**An explanation can go stale, and then it reads like a clean result.**
So the class list stays short,
and an explained difference is still printed with its line counts
rather than filed away.
A class is earned by evidence that the difference is benign —
not by another script excluding the same path,
which it may do for a reason that has nothing to do with this one.
Stage 5's carry excludes the generated files
so the twin's copy cannot overwrite what the buffer just regenerated;
that says nothing about whether the two branches may differ there,
and on the live series they do not.

## Cut over: a pull request, never a ref move

Cutting over is **pointing r-universe at `<G>-green`**.
The flavor's entry in the universe's `packages.json` names the green it builds,
and `publishes_from` in [`scripts/series.yaml`](/scripts/series.yaml) says the same here,
so a cutover is two pull requests, one in each repository, and nothing else:
no ref is swapped, deleted or renamed, in either repository,
and the generation that was published stays exactly where it is
([`branches/flavors/`](/handbook/branches/flavors/README.md)).
A human starts one, by asking for it; the loop reports that a generation is ready and stops there
(`series-loop/SKILL.md`, stage 6).

When `<G>-green` vendors at least the upstream commit the published green vendors —
coverage may never regress — run

```sh
scripts/series-cutover.sh <G> --remote origin --upstream ../../../duckdb --out <dir>
```

Pass the upstream clone:
without it the coverage gate degrades to a warning,
and a warning is not what should authorize pointing consumers at another lineage.
The script gathers what the decision rests on and writes what the pull requests change; it moves no ref:

* **coverage**: the new green covers the published one, by ancestry in the upstream clone;
* **convergence**: [`scripts/series-converge.sh`](/scripts/series-converge.sh) against the generation `<G>` was built from,
  whose findings a cutover inherits rather than resolves;
* **the package on both sides**: `Package:` and `Version:` of the two greens.
  A version that would go **backwards** is warned about, not refused:
  the replay renumbers the fifth component as a counter of its own chain,
  which starts well below the one the older generation accumulated,
  and the fourth component usually covers it because the generation is seeded on a newer `main`.
  Where it does not, r-universe has no upgrade to offer until the new chain climbs past the old one's counter —
  a cost rather than a corruption, and whether it is worth paying is the judgement the pull request asks for.
  On a preview line it never does, and a version going back is normal there:
  the prefix is pinned to the line being previewed rather than taken from `main`
  ([`scripts/preview-prefix.sh`](/scripts/preview-prefix.sh)),
  so only the restarted counter differs;
* **the canonical copy**: whether `duckdb/duckdb-r` carries `<G>-green` yet.
  The loop mirrors every generation's green there on each firing
  ([`branches/mirrors/`](/handbook/branches/mirrors/README.md)),
  and r-universe builds from that copy, so the pull request has to find it there;
* **the review**: everything `<G>-green` changes against current `main` outside the engine,
  as a stat on screen and as `review.diff` in `--out`;
* **the two changes**: the `packages.json` entry and the `publishes_from` line,
  written to `--out`, and `--apply` writes the latter into this checkout and regenerates the tables.

**The review is the cutover's substance, and it is read in full before either pull request is opened.**
The generation's seed is a recent `main`, so the diff is the series' own work:
the R side, `src/` outside `src/duckdb/`, the tests, and the patch stack.
Read it as a reviewer of `main` would read a landing's review branch
([`series-land`](/.claude/skills/series-land/SKILL.md), step 4), and hold it to the same rules:

* **glue**: every adaptation answers an upstream change named in an `R-side fix` section,
  and nothing is suppressed that [`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md) says is not;
* **R code**: a change born on the series rather than on `main` is the documented exception
  ([`branches/invariants/`](/handbook/branches/invariants/README.md)), vendor-coupled and named as such, or it is a finding for `main`;
* **tests**: no test `main` runs is deleted, rewritten or skipped without an engine gate,
  and an expired gate is due to go ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md));
  `scripts/series-tests.sh <main> <G>-green` is the same read, sorted;
* **the patch stack**: every entry is a prototype of an upstream change, filed or due to be
  ([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)),
  and `series-check.sh`'s `PATCH DRIFT` line is empty for `<G>`.

A finding is fixed on the generation, folded into the commit that introduced it ([`scripts/series-fold.sh`](/scripts/series-fold.sh)),
and the cutover waits for CI to judge the fix.
Then the two pull requests, in this order:

1. **The universe.** In `<user>/<user>.r-universe.dev`'s `packages.json`, the flavor's `branch` becomes `<G>-green`;
   the `--out` directory holds the exact entry. The universe rebuilds the package from the new green within the hour,
   and [`scripts/r-universe-check.sh`](/scripts/r-universe-check.sh) says what it made of it.
2. **The declaration**, against `main` here: `publishes_from: <G>-green`, the regenerated flavor tables,
   and a rendered README; `--apply` writes the first and runs the generator.
   Merged, it is what tells the loop which generation is published, and so which one it keeps serving ([Generations](#generations)).

Until both have merged, the published generation is the one before, and the loop serves both.

## Generations

A line `<L>` is served by **generations**, each a full set of series refs and each the same series rebuilt on a newer `main`.
`scripts/series-lib.sh` is the one place the names are read, and every `scripts/series-*.sh` reads them from there.

**Names.**
The line's first refs are `<L>-build`, `<L>-dev`, `<L>-green` and `<L>-build-base`.
Every generation after them is `<L>-v<NNN>-*`, three digits, numbered from `v000`:
`v2.0-cyanoptera-v001-dev`, `v2.0-cyanoptera-v001-green`.
A generation's derived strands take the same infix,
`<L>-v<NNN>-rc-dev` ([`series-rc`](/.claude/skills/series-rc/SKILL.md)),
`<L>-v<NNN>-alpha` and `<L>-v<NNN>-rc-alpha` ([`series-alpha`](/.claude/skills/series-alpha/SKILL.md)),
and its retry ledger is `retry-<L>-v<NNN>-dev` (`series-loop/SKILL.md`).
A landing is named for the line, `<L>-land-*`, whichever generation it is built from
([`series-land`](/.claude/skills/series-land/SKILL.md)).
The older spelling `<L>-fwd-*` is generation `v000` wherever it exists and no `<L>-v000-*` does,
so that nothing live is renamed: the next generation of such a line is `v001`.
A series name, as every script takes one, is `<L>` for the first refs and `<L>-v<NNN>` or `<L>-fwd` for a generation.

**Each generation is built from the newest one before it**, by this skill, and the newest is `series_next`'s answer.
A generation's base, the one it is compared and mined against, is the generation below it;
the first refs are generation 0's base.

**A generation is never rewritten.**
Its refs move only by the loop's own rules, the same for every generation:
`-green` fast-forwards over verified commits, `-dev` and `-build` take the loop's repairs above green,
and `-build-base` is set to the match.
Nothing in the scheme points a ref of one generation at another's lineage,
deletes a ref anything reads, or renames one:
a cutover is a pull request, a forward creates names, and pruning deletes only what nothing reads any more.
No step here needs a force-push, and an agent has none to give.

**The loop serves the two newest generations of a line, and the published one.**
Everything else is **frozen**: nothing vendors, repairs, ports or extends it,
and `series-check.sh` says `FROZEN` beside it rather than a verdict.
Two is what keeps the loop's cost from growing with the number of generations,
and the published one is kept however old it is,
because the convergence read needs the published lineage to keep moving
(`series-loop/SKILL.md`, stage 5), and because its green serves consumers until the cutover merges.
The handbook's own reading of "the last two" is therefore the newest two *plus* the published one, where those differ:
a third generation created before the second is published freezes the first refs only once something newer is published.

**Prune what is frozen and older than the published generation.**
A frozen generation newer than the published one is superseded, and may be the next to publish; it stays.
One older than the published generation has given everything it had to the generation above it,
replayed commit for commit, and costs refs in two repositories and an entry in the fork's universe:

```sh
scripts/series-prune.sh <L> --remote origin --canonical upstream --archive archive
```

prints, for each such generation, the push that copies its refs to the archive, `krlmlr/duckdb-r-old`,
and the deletions that follow, in the fork and of the green's copy in the canonical repository, and runs none of them.
A human runs them, after the two checks the script cannot make:
that no landing is being built from the generation, and that the fork's universe no longer names its green.
Pruning is the one time refs of a generation go away, and it is never part of a cutover.

**Where today's series stand, and what moves them onto the scheme.**
Nothing is renamed.
`v2.0-cyanoptera-fwd`, `main-fwd`, `v1.5-variegata-fwd` and `v1.4-andium-fwd` are their lines' generation `v000` under the older spelling,
and every script reads them as such;
the first refs of each line, `v2.0-cyanoptera-*` and the rest, are what r-universe publishes today, and stay so.
From here:

1. the next forward of a line creates `<L>-v001-*` from `<L>-fwd-dev`, as above, and registers `<L>-v001-green` in the fork's universe
   in place of `<L>-fwd-green`;
2. the loop's next firing mirrors every generation's green into the canonical repository, where the cutover will name it;
3. a cutover, when a generation is ready and a human asks for it, is the two pull requests above and moves nothing;
4. `<L>-fwd-*` and the first refs go when they are frozen and older than the published generation, by `series-prune.sh`'s commands, run by a human.

None of this is run by a firing, and nothing here is run by the change that introduces the scheme.
