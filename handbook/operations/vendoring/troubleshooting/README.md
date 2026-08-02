# Troubleshooting

When a vendoring run is red:
telling the failure modes apart and reaching the right repair.
The repair procedures are the series loop's playbooks
([`series-loop/`](/handbook/operations/vendoring/series-loop/README.md));
[`scripts/VENDORING.md` § Troubleshooting](/scripts/VENDORING.md#troubleshooting)
keeps the detailed recovery walkthroughs.

Start read-only:
[`scripts/series-check.sh`](/scripts/series-check.sh) prints one
verdict per series — `ADVANCE`, `WAIT`, `RETRY <sha>`,
`REPAIR <sha>`, or `IDLE` — from the harvest on the orphan `rcc`
branch, which stores one record per commit and failing commits'
logs ([`ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)).
What is vendored where:

```sh
grep duckdb_version R/version.R            # the DuckDB version
git log --oneline --grep="^vendor:" -5     # the last vendor commits
```

The failure classes, and what each needs:

* **The script refuses to start** — dirty tree; commit or stash.
* **The base scan comes up empty** — no `duckdb/duckdb@` subject
  within `BASE_SCAN_DEPTH`; the scripts refuse rather than guess a
  range. Usually a reworded vendor subject.
* **The glue gate stops `vendor-one.sh`** — the fresh headers
  broke the glue; fix the glue and fold it into that vendor
  commit.
* **A dropped patch** — the run classifies a patch that stopped
  applying; re-derive or retire it deliberately.
* **A red `-dev` commit** — repair-vs-retry is the loop's
  classification; a stuck shard or lost leg is
  [`ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)'s.
* **Stale snapshots** — engine output drifted;
  [`testing/snapshots/`](/handbook/testing/snapshots/README.md).
