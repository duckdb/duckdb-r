# Landing v2 handover

_A transient work branch for the v2.0-cyanoptera landing iteration (`.claude/skills/series-land/SKILL.md`, step 4); never merged._

## Branches in duckdb/duckdb-r

* `claude/land-v2-transfer`: the folded landing so far, pass 7 (`0de9224b00`).
  It is the pinned-tests commit `61edbd384a`, then 2160 vendor commits.
  It still lacks the two remaining folds below.
* `claude/land-v2-base`: the unfolded build of the same 2160 vendor commits (`f3ca08e476`).
  `scripts/series-land.sh v2.0-cyanoptera-fwd --remote origin --canonical upstream --base upstream/claude/glue-expectation-tests --no-check-glue` made it, and its tree check passed.
* `claude/land-v2-fix-pos1`: the staged fold for position 1 (`71b91bad75`), a commit on the transfer branch's first commit.
* `claude/land-v2`: the tooling, `scripts/series-fold.sh` and its offline test.
* `claude/land-v2-workbench`: this branch, with the helper scripts in `bin/` and the logs in `logs/`.

Positions count the vendor commits from 1 at the rewind.
`fix-commits.txt` lists each fix commit as `target=fix`, from before the replay that folded it.

## Folded into the transfer branch

Each folded commit carries a "Landing v2 (finding N): ..." paragraph above its trailers.

* 202: finding 3, `lag()`/`lead()` get the default offset of 1 before a default.
  The pinned test fails here unfixed; see `logs/bisect-202.log`.
  1539 adapts that line to `ConstantExpression::FromValue()`.
* 401: finding 8, `TIMESTAMP_TZ_NS` takes the session TimeZone, with a new test in `test-timezone.R`.
* 405: finding 5, the `rel_to_csv()` guard; the pinned test fails here unfixed.
* 653: finding 9, `RType::operator==()` compares names exactly; the pinned tests fail here unfixed.
* 1033: findings 2 and 6.
  An Arrow result holds its client context, and a statement a finalizer frees is parked rather than destroyed.
  The pinned `test-fetch_arrow.R` test wedges here unfixed.
* 1620: findings 1 and 4.
  Arrow results are submitted and streamed through the glue's `RArrowChunkSource`, results and streams are parked inside callbacks, and the skipped tests are restored.
  1740 gains a note only, because its R side no longer applies.
* 2062: finding 1, `EndOpenResults()` ends a connection's open Arrow results before the glue starts a statement there, since the engine refuses one from here on.
* 2112: finding 1, the streaming decision moves to `StreamsByDefault()` on the statement type as written, and `CanDrain()` no longer asks.
* 2149: findings 1 and 11.
  The new `StreamsByDefault()` signature, and a PRAGMA that expands to nothing returns no rows of one `Success` column.
  `test-multi_statement.R` fails at landing v1's tip without it.
* 2160: finding 7, NEWS and the handbook pages.

## Still to do

* Fold `claude/land-v2-fix-pos1` at position 1: `bin/series-fold.sh`, or `scripts/series-fold.sh` on `claude/land-v2`.
  * Positions 1-147 do not compile on landing v1 or on the transfer branch: `rapi_connection_set_invalidation_policy()` calls an API that arrives at 148 (duckdb/duckdb@3ac07aebe5).
    The fold stubs it to refuse at run time; the R side calls it only from DuckDB 2.0 on.
  * The fold also restores `main`'s `test-variant.R`, adds `skip_if_engine_before()` to `helper-skip.R` as commit 96050786cc does, and gates four tests with the placeholder `@V@`.
* Then fold at 148: revert the stub to `main`'s body.
* Find the gate version V and remove the four gates there.
  The four gated tests fail at positions 1 and 9 (`logs/test-w1.log`, `logs/variant-9.log`) and pass at the tip.
  A build at 148 was running when the work stopped.
  The candidates are the cast changes at 93-95 and the `v1.5-variegata` merges at 111, 128, 148, 180 and 495.
* After the replay, run the glue gate over every commit (`bin/gate-all2.sh`).
  On pass 7 it passed every commit from 148 up to the last it checked (`logs/gate-p7b.log`), and positions 1-147 fail only `connection.cpp`.
* Build and test the tip: `bin/install.sh` and `bin/test.sh`.
  The fixed tip as developed on landing v1 passed the whole suite (`logs/suite-fix.log`), apart from `test-multi_statement.R`, which the 2149 fold fixes.
  That tip passed `lag()`/`lead()` the offset and the default by name rather than through the explicit offset folded at 202.
* Check `scripts/series-tests.sh 61edbd384a <tip> --strict`; on pass 7 it reports only `test-variant.R` lost.
* Then push `v2.0-cyanoptera-land-v2` to krlmlr/duckdb-r, run `--review --landing ... --suffix -v2 --push`, and open the review PR.

## Open, not fixed

* Finding 10 (EXPLAIN ANALYZE): `main` behaves the same (#2901).
* Ending an open streamed SELECT that writes rolls it back, and inside an explicit transaction it invalidates the transaction.
* An interrupt while a streamed result is being read is not caught: `ScopedInterruptHandler` wraps only `Submit()`.
* Finding 6: no hang at exit was reproduced; the fix parks statements a finalizer frees.
