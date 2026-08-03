# Troubleshooting

When a vendoring run is red:
telling the failure modes apart and reaching the right repair.
The repair procedures are the series loop's playbooks
([`series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).

Start read-only:
[`scripts/series-check.sh`](/scripts/series-check.sh) prints one
verdict per series — the script's own list, and a `CUTOVER` line
where a forward counterpart has caught up —
from the harvest on the orphan `rcc2` branch,
which stores one record per commit and failing commits'
logs ([`ci/per-commit/store/`](/handbook/operations/ci/per-commit/store/README.md)).
What is vendored where:

```sh
grep duckdb_version R/version.R            # the DuckDB version
git log --oneline --grep="^vendor:" -5     # the last vendor commits
```

The failure classes, and what each needs:

* **The script refuses to start** — dirty tree; commit or stash.
* **The base scan comes up empty** — no `duckdb/duckdb@` subject
  within `BASE_SCAN_DEPTH` (20, in both vendor scripts);
  they refuse rather than guess a range.
  Usually a reworded vendor subject.
* **The glue gate stops `vendor-one.sh`** —
  the fresh headers broke the glue;
  fix the glue and fold it into that vendor commit.
* **A patch stopped applying** — if it reverses cleanly the run
  retires it and continues; if it neither applies nor reverses the run
  stops, and the patch needs a hand rebase against the regenerated tree
  ([`pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
* **A red `-dev` commit** — repair-vs-retry is the loop's
  classification; a stuck shard or lost leg is
  [`ci/per-commit/legs/`](/handbook/operations/ci/per-commit/legs/README.md)'s.
  When the tree upstream shipped is itself the defect, see below.
* **Stale snapshots** — engine output drifted;
  [`testing/snapshots/`](/handbook/testing/snapshots/README.md).

## A commit upstream broke

A vendor commit can be red for a reason the R side cannot adapt to:
upstream did not build or pass at that commit,
and the vendored tree carries the defect.
Two repairs, and choosing between them is the decision.

**Fold it forward — the default.**
When the next upstream commit repairs the tree,
squash the failing vendor commit into it.
The surviving commit carries the newer tree
and the newer `vendor: … duckdb/duckdb@<sha>` subject —
the subject is machine-readable state,
so it must name the tree the commit carries —
with the folded commit's SHA and subject in the body,
marked as not passing on its own,
and the `R-side fix` sections of both kept.
Mirror the fold in `<S>-build`, which carries no CI.
Only the adjacent pair may be folded:
squashing a longer span buries commits
that never stood on the chain as their own tree.

**Forward-port upstream's fix — the escalation.**
When the next commit is red too, there is no green tree to fold into.
Re-root the fixing commit's diff under `src/duckdb/`,
add it to the patch stack ([patch stack](/BRANCHES.md#patch-stack)),
and fold the patch and its effect into the vendor commit that needs it,
with an `R-side fix` section naming the upstream fix —
the same move as a glue fix, one directory over.
The re-rooted files must be byte-identical to the fixing commit's;
if they are not, the patch is not a forward-port of it.
The patch retires itself:
the vendor run that reaches upstream's own fix drops it,
because a patch that no longer applies is dropped.
With the patch applied, that fixing commit may change nothing
and be skipped by the more-than-one-file rule,
named in the next vendor commit's body like any other no-op commit.

Folding costs the one-to-one correspondence with upstream history
at that point, so a bisect can no longer land on the commit that broke;
a patch costs a file to review, carry, and trust to retire.
Pay the second only when the first is unavailable.
The version counter gains a gap where the folded bump went,
which is what a counter that orders rather than counts allows
([`versioning/`](/handbook/operations/releases/versioning/README.md)).
The loop's own statement of the rule is in its repair stage
([`series-loop.md`](/.claude/skills/series-loop.md)).

*To deepen: absorb `scripts/VENDORING.md` § Troubleshooting —
rebuilding the upstream clone, and the spurious `src/*.dd` churn.*
