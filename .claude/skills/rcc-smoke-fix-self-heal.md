Sub-skill of `rcc-smoke-fix`. Invoke only when, while walking
`*-dev` commits oldest-first, you observe a `success` for `rcc` on a
commit **later** than the earliest `failure` without anyone having
fixed it in between. The break is transient — upstream "self-healed" —
and the default single-commit workflow would double-record the fix.

Most often this is a "hidden merge conflict": two adjacent upstream
commits form one logically consistent change but were vendored as
separate steps, so the first one fails to compile on its own.

Two strategies, gated on window width:

| Width    | Strategy        | Audit trail                                                                                       |
|----------|-----------------|---------------------------------------------------------------------------------------------------|
| 1 commit | Squash          | One amended commit replaces `FIRST_FAIL` + `HEAL_AT`; commit message is exactly what `scripts/vendor.sh` would have produced for the combined range. |
| ≥ 2      | Transient patch | `patch/NNNN-transient-*.patch` added at `FIRST_FAIL`, removed at `HEAL_AT`.                       |

## Detect

Continue the Step 3 walk forward from `$FIRST_FAIL`:

```bash
HEAL_AT=""; LAST_FAIL="$FIRST_FAIL"; seen=0
while IFS= read -r SHA; do
  if [[ "$seen" == 0 ]]; then
    [[ "$SHA" == "$FIRST_FAIL" ]] && seen=1
    continue
  fi
  STATUS=$(lookup_rcc_status "$SHA")
  if is_rcc_failure "$STATUS"; then LAST_FAIL="$SHA"; continue; fi
  if [[ "$STATUS" == "success" ]]; then HEAL_AT="$SHA"; break; fi
  # pending/none/error → cannot prove self-heal
  HEAL_AT=""; break
done <<< "$COMMITS_OLDEST_FIRST"

[[ -z "$HEAL_AT" ]] && exit 0   # fall back to default workflow
WINDOW=$(git rev-list --count --first-parent "${FIRST_FAIL}^..${LAST_FAIL}")
```

Any intermediate commit with status `pending`/`none`/`error` ⇒
`HEAL_AT` stays empty; do not invent CI data.

## Classify (informs strategy choice)

- **Vendored library broken** — `src/duckdb/...` errors in the log,
  upstream-internal symbols. Usually heals via a follow-up vendor
  commit ⇒ window 1 ⇒ squash.
- **Call sites incompatible** — `src/*.cpp`, `src/include/`, `R/`,
  `tests/` references a renamed/removed API. Heals via a forward-port
  on `*-dev` ⇒ either width.

Quick separator on the log fetched in Step 4b:
`grep -E '(^|/)src/duckdb/' <log>` vs `grep -E '(^|/)src/[^d]' <log>`.

## Strategy A — Squash (`$WINDOW == 1`)

Apply `HEAL_AT`'s tree, collapse onto `FIRST_FAIL`'s parent, then
commit with **the exact message `scripts/vendor.sh` would have written
had it vendored both upstream commits in a single step**.

Concretely:

- Title from `HEAL_AT` — its upstream SHA is what `$base..$commit`
  would have resolved to in a single-step vendoring.
- `Date:` line from `HEAL_AT`.
- Body: per-PR subject lines from `FIRST_FAIL`'s body followed by
  those from `HEAL_AT`'s body, in that order, blank lines stripped.

Do **not** append any audit-style "Combined upstream commit" /
"R-side fix" suffix. The squashed commit must be indistinguishable
from a natural single-step vendor commit, because:

- `scripts/vendor.sh` derives the next `$base` by scanning the most
  recent vendor commit's title for the `duckdb/duckdb@<sha>` suffix
  (`sed -nr '/^.*duckdb.duckdb@([0-9a-f]+).*$/{s//\1/;p;}'`). A
  non-standard title would break the next vendoring run.
- An anomaly here propagates forward through every subsequent
  cherry-pick of vendor commits.

```bash
git cherry-pick --no-commit "$HEAL_AT"
git reset --soft "${FIRST_FAIL}^"

vendor_body() {
  # Subjects below the "vendor: ..." / blank / "Date: ..." / blank
  # prologue, blank lines stripped.
  git log -1 --format='%B' "$1" | tail -n +5 | sed '/^$/d'
}

HEAL_TITLE=$(git log -1 --format='%s' "$HEAL_AT")
HEAL_DATE=$(git log -1 --format='%B' "$HEAL_AT" | sed -n '/^Date:/{p;q;}')

git commit -m "${HEAL_TITLE}

${HEAL_DATE}

$(vendor_body "$FIRST_FAIL")
$(vendor_body "$HEAL_AT")"
```

In the main skill's Step 4g cherry-pick loop, **skip** `HEAL_AT`
(its tree is already in the squashed commit).

### Worked example

Given:

```
FIRST_FAIL=37917586a018e7875e446e1ad8a51050619c0c70
  vendor: Update vendored sources to duckdb/duckdb@a61e6e000bdf16f19e3b375467144269cae9fb84

  Date: 2026-04-30 09:31:08 +0000

  Fix duckdb_param_type returning INVALID for nested casts (https://redirect.github.com/duckdb/duckdb/pull/22281)

HEAL_AT=c0cb67f58c0b04a3e09bb4fa5369a145fa904c59
  vendor: Update vendored sources to duckdb/duckdb@cd2ef3919f0ec8aeee7fe8eae2819f95565ba299

  Date: 2026-04-30 09:40:47 +0000

  Fix hidden merge conflict (https://redirect.github.com/duckdb/duckdb/pull/22388)
```

The squashed commit's message must be exactly:

```
vendor: Update vendored sources to duckdb/duckdb@cd2ef3919f0ec8aeee7fe8eae2819f95565ba299

Date: 2026-04-30 09:40:47 +0000

Fix duckdb_param_type returning INVALID for nested casts (https://redirect.github.com/duckdb/duckdb/pull/22281)
Fix hidden merge conflict (https://redirect.github.com/duckdb/duckdb/pull/22388)
```

Byte-for-byte what `scripts/vendor.sh` would have produced had upstream
HEAD been at `@cd2ef39` (with `$base` at the previous vendor SHA) when
vendoring ran.

## Strategy B — Transient patch (`$WINDOW >= 2`)

Add `patch/NNNN-transient-<short>.patch` with this header:

```
# Transient: <short symptom>
# Introduced  : <FIRST_FAIL>
# Removed at  : <HEAL_AT>
# Upstream    : <PR URL or "none">
```

Apply with `patch -p1 -i patch/NNNN-...`, fold into the `FIRST_FAIL`
amend (Step 4f of the main skill).

In Step 4g, when cherry-picking `HEAL_AT`, remove the transient patch
and re-sync `src/duckdb/`:

```bash
git cherry-pick --no-commit "$HEAL_AT"
git rm patch/*-transient-*.patch
git checkout "$HEAL_AT" -- src/duckdb/
HEAL_MSG=$(git log -1 --format=%B "$HEAL_AT")
git commit -m "${HEAL_MSG}"   # unchanged from upstream; patch removal is part of the same tree
```

For a **call-site** self-heal (no `src/duckdb/` change), store the
audit-only reverse glue/R diff in `patch/transient-glue/<short>.patch`
(not applied by the build).

## Hard rules

- Squash only when `$WINDOW == 1`. Wider windows ⇒ transient patch.
- Squashed commit message MUST be byte-identical to what
  `scripts/vendor.sh` would have produced for the combined range —
  no appended audit notes, no extra body sections.
- Transient patches MUST name `FIRST_FAIL`, `HEAL_AT`, upstream link
  in their header, and MUST be deleted at `HEAL_AT`. Never carry one
  past its documented `HEAL_AT`.
- Missing CI data (`pending`/`none`) ⇒ no self-heal claim; fall back
  to the default single-commit workflow.
