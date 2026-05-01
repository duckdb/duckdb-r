Scheduled job: scan all `*-dev` branches (including `broken-*-dev`) in
`krlmlr/duckdb-r` for the earliest commit whose `rcc`
commit-status (set by the "Smoke test: stock R" job in the `rcc` workflow) is
`failure` since 2026-04-11. For each such branch, if no `broken-<sha>-dev`
branch exists yet (full 40-char SHA), create it, fix `testthat::test_local()` and
`rcmdcheck::rcmdcheck()`, update snapshots, then cherry-pick all later commits from the
`*-dev` branch and push. Never edit vendored sources (`src/duckdb/`,
`inst/include/cpp11/`, `inst/include/cpp11.hpp`) by hand; editing `patch/`
will produce expected, committable changes under `src/duckdb/`.

---

<!--
## Operation essence (read this first)

Why this skill exists.
  The DuckDB C++ core is vendored hourly into `src/duckdb/` from
  `duckdb/duckdb` (one upstream branch per `*-dev` line — `main` for
  `main-dev`, `v1.5-variegata` for `v1.5-variegata-dev`, `v1.4-andium` for
  `v1.4-andium-dev`). A vendor commit can break R-side glue (`src/*.cpp`,
  `src/include/`), R code (`R/`), or test snapshots
  (`tests/testthat/_snaps/`). We do not rewrite the upstream vendor commit;
  instead we author a parallel `broken-<sha>-dev` branch whose first commit
  is an **amended replacement** of the failing `<sha>` (same parent;
  original vendor message kept verbatim and a short R-side fix note
  appended; vendor diff plus R-side fix folded in). All later commits from
  the original `*-dev` branch are then cherry-picked on top. The result is
  a continuous "vendor + repair" history with no extra fix commit, which
  preserves continuity and keeps cherry-picks clean. Promoting the green
  tip back into the parent `*-dev` branch is a manual step performed
  outside this skill (today there is no CI/CD that does it automatically;
  this may be automated in the future).

End-to-end workflow.
  1. Refresh `krlmlr/*` remote-tracking refs from scratch — the dev
     branches are force-pushed and any cached state is suspect.
  2. Enumerate `*-dev` branches and existing `broken-*-dev` branches in
     one pass.
  3. For each `*-dev` branch, walk first-parent history oldest-first since
     SINCE and look up each commit's `rcc` commit-status until the earliest
     `failure` is found. Skip the branch if no failure exists or if the
     corresponding `broken-<sha>-dev` is already published.
  4. For every (branch, sha) pair that needs work:
     a. Check out `<sha>` on a new local branch `broken-<sha>-dev`.
     b. Reproduce the breakage locally — install the package
        (`_R_SHLIB_STRIP_=true R CMD INSTALL .`, with `MAKEFLAGS=-j$(nproc)`
        for parallel build), run `testthat::test_local()`, then
        `rcmdcheck::rcmdcheck()` (which builds the package tarball and
        checks it). The first build of `src/duckdb/` is heavy (10-15 min on cold
        cache); set generous timeouts. Read the error output carefully
        to classify the failure (compile, link, runtime, snapshot,
        NOTE/WARNING).
     c. Apply the smallest fix in priority order: `patch/` → glue
        (`src/*.cpp`, `src/include/`) → R code (`R/`) → snapshots
        (`tests/testthat/_snaps/`) → tests (`tests/testthat/test-*.R`).
        Stop at the first level that resolves the failure. Never edit
        vendored paths by hand — but expect `src/duckdb/` to change as a
        downstream effect when a `patch/` file is added or modified (the
        patch is applied to the vendored tree); commit those derived
        changes alongside the patch.
     d. `rcmdcheck::rcmdcheck()` until clean (`Status: OK` or only
        pre-existing NOTE).
     e. Cherry-pick every remaining commit from the upstream `*-dev`
        branch on top of the fix. Vendor commits apply cleanly by
        construction; non-vendor commits (forward-ports from `main`,
        glue-code repairs already pushed to `*-dev`) must be carried
        forward and may legitimately conflict with our own fix —
        resolve, do not skip.
     f. Push `broken-<sha>-dev` to `krlmlr` with `--force-with-lease`
        and move on to the next pair.

Environment assumptions (current).
  * R 4.x and standard development tooling (gcc/g++, make, git, `curl`,
    `jq`) are pre-installed.
  * GitHub Actions build logs and run results are available on the
    **orphan branch `rcc`** in `krlmlr/duckdb-r` — no token required.
    Fetch them before starting a local rebuild (see Step 4b).
  * When the orphan branch index does not cover a SHA, fall back to `gh`
    (run `gh auth status` first; skip the fallback if it fails). Do not
    use `curl` or read environment variables to check authentication.
  * A GitHub MCP tool may also be used for commit-status lookups when the
    agent provides one.

Fetching CI build logs from the `rcc` orphan branch.
  The harness (`scripts/rcc-logs.sh`) stores GitHub Actions results and
  logs on the `rcc` orphan branch of `krlmlr/duckdb-r`. Layout:
  `runs2.ndjson` holds one `{commit, status, run}` record per line keyed
  by commit SHA (only `completed` runs are recorded; pending commits are
  skipped and retried next harness run); `logs2/<sha>.log` holds the
  last 10 000 lines of the combined run log for each failed run. Before
  running a slow local `R CMD INSTALL`, read `logs2/<sha>.log` directly
  (see Step 4b). Most diagnostics point straight at the file and line,
  allowing the agent to draft a targeted fix and potentially skip the
  10–15 min cold-cache C++ rebuild. The local install +
  `testthat::test_local()` + `rcmdcheck::rcmdcheck()` cycle remains the
  authoritative final gate — logs only short-circuit triage, they do
  not replace verification.
-->

---

## Step 1 — Refresh local mirror of krlmlr/duckdb-r (always, force-reset)

```bash
if ! git remote get-url krlmlr &>/dev/null 2>&1; then
  git remote add krlmlr https://github.com/krlmlr/duckdb-r.git
fi
# Hard-reset: throw away any cached remote-tracking state
git fetch krlmlr --force --prune --tags
```

## Step 2 — Collect all branches and existing `broken-*` branches in one pass

```bash
# All krlmlr remote-tracking branches that end in -dev
DEV_BRANCHES=$(git branch -r \
  | grep -oP 'krlmlr/\K\S+' \
  | grep -E '\-dev$' \
  | sort)

# All broken-*-dev branches already on krlmlr (to skip re-doing work)
BROKEN_BRANCHES=$(git branch -r \
  | grep -oP 'krlmlr/\K\S+' \
  | grep -E '^broken-.*-dev$')

echo "=== Dev branches ===" && echo "$DEV_BRANCHES"
echo "=== Broken branches (existing) ===" && echo "$BROKEN_BRANCHES"
```

## Step 3 — For each `*-dev` branch, find the earliest failing commit

Iterate over every entry in `$DEV_BRANCHES`. For each `$BRANCH`:

```bash
SINCE="2026-04-11"
REPO="krlmlr/duckdb-r"

# Commits on this branch since SINCE, oldest-first (first-parent only)
COMMITS_OLDEST_FIRST=$(git log "krlmlr/$BRANCH" \
  --first-parent --since="$SINCE" --format="%H" --reverse)
```

Cache the orphan-branch run index once (no token required):

```bash
RCC_NDJSON=$(git show krlmlr/rcc:runs2.ndjson 2>/dev/null || true)
```

Define helpers. `lookup_rcc_status` reads from the cached `$RCC_NDJSON`
first; falls back to `gh` only when the SHA is absent and `gh auth status`
succeeds. Do not use `curl` or check environment variables.

```bash
is_rcc_failure() {
  case "$1" in
    failure|timed_out|startup_failure|action_required) return 0 ;;
    *) return 1 ;;
  esac
}

# Check once whether `gh` is usable; cache the result.
GH_OK=0
gh auth status &>/dev/null && GH_OK=1

lookup_rcc_status() {
  local sha="$1"
  # Primary: orphan branch index (instant, no auth needed).
  # runs2.ndjson is keyed by commit SHA and only contains completed runs;
  # use the run conclusion so it lines up with is_rcc_failure().
  local conclusion
  conclusion=$(jq -r --arg sha "$sha" \
    'select(.commit == $sha) | .run.conclusion // empty' \
    <<< "$RCC_NDJSON" | head -1)
  [[ -n "$conclusion" ]] && { echo "$conclusion"; return; }

  # Fallback: gh CLI (only when authenticated). Returns the commit-status
  # state, which uses a smaller vocabulary (success|failure|pending|error)
  # but still triggers is_rcc_failure() on "failure".
  if [[ "$GH_OK" == "1" ]]; then
    gh api "repos/$REPO/commits/$sha/statuses" \
      | jq -r '[.[] | select(.context == "rcc")] | first | .state // "none"'
  else
    echo "none"
  fi
}
```

Walk the commits oldest-first, stop at the first failure. Use `pipefail`
so a failed status lookup is not silently swallowed:

```bash
set -o pipefail

FIRST_FAIL=""
while IFS= read -r SHA; do
  STATUS=$(lookup_rcc_status "$SHA")
  echo "$BRANCH  ${SHA}  $STATUS"
  if is_rcc_failure "$STATUS"; then
    FIRST_FAIL="$SHA"
    break
  fi
done <<< "$COMMITS_OLDEST_FIRST"

# Existence check comes AFTER finding the earliest failure.
# Checking inside the loop would short-circuit on a later already-fixed commit
# before reaching an earlier failure that still has no fix branch.
if [[ -z "$FIRST_FAIL" ]]; then
  echo "$BRANCH: no rcc failure — skip"
elif echo "$BROKEN_BRANCHES" | grep -qxF "broken-${FIRST_FAIL}-dev"; then
  echo "$BRANCH: broken-${FIRST_FAIL}-dev already exists — skip"
else
  echo "NEEDS_FIX  $BRANCH  $FIRST_FAIL"
fi
```

Collect all `NEEDS_FIX  <branch>  <sha>` lines. Process them in order.

## Step 4 — Create, fix, and push a `broken-*` branch

Repeat for each `NEEDS_FIX` pair `($BRANCH, $SHA)`:

### 4a. Check out the failing commit on the new fix branch

```bash
FIX_BRANCH="broken-${SHA}-dev"
git checkout -B "$FIX_BRANCH" "$SHA"
```

IMPORTANT: Keep the `-dev` suffix in the fix branch name. It ensures that each
intermediate commit is checked on CI/CD via `each.yaml`.

### 4b. Fetch CI log, then install and run tests; collect failures

**First**, fetch the build log from the `rcc` orphan branch. This is fast
and usually pinpoints the failure before any local compilation.

The orphan branch layout (produced by `scripts/rcc-logs.sh`) is:

```
runs2.ndjson     – one {commit, status, run} record per line, keyed by
                   commit SHA (only completed runs; pending commits are
                   absent and retried on the next harness invocation)
logs2/<sha>.log  – last 10 000 lines of the combined run log,
                   only for runs with a failure conclusion
```

```bash
# Fetch the rcc orphan branch (do this once; re-use across multiple SHAs)
git fetch krlmlr rcc

# Show the tail of the failure log (logs are keyed by full commit SHA;
# no run-id intermediate)
git show "krlmlr/rcc:logs2/${SHA}.log" 2>/dev/null | tail -60
```

If you also want the run metadata (run id, html_url, conclusion, etc.):

```bash
git show krlmlr/rcc:runs2.ndjson \
  | jq -c --arg sha "$SHA" 'select(.commit == $sha) | .run' \
  | head -1
```

If the log identifies the root cause clearly (compiler error, link error,
failing test + message), draft the targeted fix and proceed to Step 4c
directly, skipping the slow `R CMD INSTALL` of `src/duckdb/`. If the log
is absent or inconclusive, fall back to a full local build:

```bash
set -o pipefail
export MAKEFLAGS="-j$(nproc)"
_R_SHLIB_STRIP_=true R CMD INSTALL . 2>&1 | tail -20
Rscript -e 'testthat::test_local(stop_on_failure = FALSE)' 2>&1
```

`pipefail` is required so that a failing `R CMD INSTALL` propagates its
non-zero exit status through the `tail` pipe. The last 20 lines are
typically enough to diagnose a build failure; if they aren't, drop the pipe
and re-run for the full log.

The first build of `src/duckdb/` from a cold cache takes **10–15 minutes**
— set generous timeouts. Subsequent rebuilds are incremental and much
faster. If only `R/`, `tests/`, `man/`, or `tests/testthat/_snaps/`
change, the C++ rebuild is skipped entirely.

Note: spurious changes to `src/*.dd` (dependency-tracking files) caused by a
Makefile bug should be discarded with `git checkout -- src/*.dd` rather than
fixed; see `AGENTS.md` for the root cause.

When a failure is in a test gated by `requireNamespace()` (e.g. `arrow`,
`DBItest`, `dbplyr`) and that Suggests dependency is missing from the local
library, install it with `install.packages("foo")` — leave `repos=` unset
first, so the env-configured default (Posit P3M binary builds for the
current Linux release) is used; that's much faster than a CRAN source
compile. If the default repo can't serve the package (404, mirror down,
unsupported R version), fall back to an explicit `repos=` (e.g.
`"https://cloud.r-project.org"`) and retry — but only after the default
has actually failed.

### 4c. Fix issues — allowed modifications and priority order

**Never edit by hand** any of the following vendored / auto-generated paths:

- `src/duckdb/` (vendored DuckDB C++ core) — note: `src/duckdb/` WILL change
  as a downstream effect of editing `patch/` (the patch is applied to the
  vendored tree); those derived changes are expected and must be committed
  with the patch (see priority 1 below). It is only direct edits that are
  forbidden.
- `inst/include/cpp11/`, `inst/include/cpp11.hpp` (vendored cpp11 from
  `krlmlr/cpp11`)
- `scripts/vendor.sh`, `scripts/vendor-one.sh`, `scripts/lts.sh`,
  `scripts/lts.patch` (vendoring + flavor automation)

The flavor files (`DESCRIPTION`'s `Package:` field, `R/duckdb-package.R`,
`src/include/rapi.hpp` for `DUCKDB_PACKAGE_NAME`,
`inst/include/duckdb_types.hpp`, `tests/testthat.R`) are managed by
`scripts/lts.sh` and should not be hand-edited; if they look wrong, re-run
`scripts/lts.sh <flavor>` rather than patching by hand.

Everything else — including `patch/` — may be changed.

Apply fixes in this priority order (stop at the first level that resolves
the failure):

1. **`patch/`** — R-specific patches to the DuckDB C++ core. Prefer adjusting
   or adding a patch here when the C++ API changed in a way that breaks
   compilation, linking, or warning policy. Assign the next available
   number; do not renumber existing patches. Send the same change as a PR
   to `duckdb/duckdb` so it can eventually be retired.

   Apply a new or edited patch with `patch -p1 -i patch/<file>.patch` so
   that `src/duckdb/` reflects the patched state the build expects. The
   resulting modifications under `src/duckdb/` are the expected downstream
   effect of the patch and must be committed together with the patch
   file.

2. **Glue code** (`src/*.cpp`, `src/include/`, `src/*.dd`) — adapt the R↔C++
   bridge to a changed DuckDB API before touching any R-level code. New
   string constants and `Rf_install()` symbols belong in
   `RStrings::RStrings()` in `src/utils.cpp` and `struct RStrings` in
   `src/include/rapi.hpp` (see `AGENTS.md`).

3. **R code** (`R/`) — update high-level R functions, fix argument handling,
   etc. After changes, regenerate documentation:
   `Rscript -e 'roxygen2::roxygenize()'`.

4. **Snapshots** (`tests/testthat/_snaps/`) — accept updated snapshots only
   after the underlying behaviour is confirmed correct:

   ```bash
   Rscript -e 'testthat::snapshot_accept()'
   ```

   Or for a single test file: `testthat::snapshot_accept("test-name")`.

5. **Tests** (`tests/testthat/test-*.R`) — change test code **only as a last
   resort**, e.g. when the test itself was testing a now-removed
   C++-level detail. Do not weaken assertions; adapt them to the new
   correct behaviour.

Other common fixes:

| Symptom                            | Fix                                              |
|------------------------------------|--------------------------------------------------|
| Missing export / namespace error   | `Rscript -e 'roxygen2::roxygenize()'`            |
| `cpp11::cpp_register()` out of date| `Rscript -e 'cpp11::cpp_register()'`             |
| NOTE / WARNING in `rcmdcheck` output| Fix in `R/`, `man/`, or `patch/`                 |
| Compiler warning in vendored code  | New file under `patch/` (do **not** suppress)    |

After any change, re-run:

```bash
Rscript -e 'testthat::test_local(stop_on_failure = FALSE)' 2>&1
```

Iterate until all tests pass.

### 4d. Final check

Use `rcmdcheck::rcmdcheck()` to build the package tarball and check it:

```bash
set -o pipefail
Rscript -e 'rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"), error_on = "warning")' 2>&1 | tail -20
```

Must show `Status: OK` or at most `1 NOTE` (pre-existing CRAN notes are
fine). Fix any new ERRORs or new WARNINGs.

### 4e. Fold the fix into the failing commit (amend, do not add)

The fix must be **amended into the failing commit itself**, so the tip of
`broken-<sha>-dev` is a single-commit-deep replacement of `<sha>` (same
parent, vendor diff + R-side fix) rather than a two-commit chain.
Cherry-picks then layer cleanly on top, and the branch keeps a
continuous "vendor + repair" history without an explicit "fix" commit.

The amended commit message **keeps the original vendor message intact**
and **appends** a short note documenting the R-side finding (what broke,
why, what was changed). Append-only: do not rewrite or shorten the
upstream-authored portion.

```bash
git add -- R/ tests/ man/ NAMESPACE src/*.cpp src/include/ src/*.dd patch/
# Also stage `src/duckdb/` if (and only if) you modified `patch/` and the
# patch was applied to the vendored tree:
git diff --cached --name-only -- patch/ | grep -q . && \
  git add -- src/duckdb/
# Only if there are staged changes: amend, preserving the original
# vendor message and appending a short fix note. Replace <DETAILS>
# with 1-5 lines describing the upstream API change and the R-side
# adaptation (e.g. "Handle new EXPRESSION_FILTER kind in
# TransformFilterExpression — upstream PR #22005 unified
# ConstantFilter into ExpressionFilter.").
ORIG_MSG=$(git log -1 --format=%B)
git diff --cached --quiet || \
  git commit --amend -m "${ORIG_MSG}

R-side fix
----------
<DETAILS>"
```

This rewrites the local `broken-<sha>-dev` HEAD only — the original
`<sha>` on `krlmlr/main-dev` (or whichever upstream) is untouched, so the
"never amend pushed commits" rule still holds: the amend produces a new
commit on a new, never-before-pushed branch.

Never `git add` paths under `inst/include/cpp11/` or any flavor file
managed by `scripts/lts.sh`. `src/duckdb/` should only appear in the
amended commit when it carries the downstream effect of a `patch/`
change.

### 4f. Cherry-pick all remaining commits from `*-dev`

```bash
# Commits on the *-dev branch that come *after* the failing commit
REMAINING=$(git log "${SHA}..krlmlr/${BRANCH}" \
  --first-parent --format="%H" --reverse)

for C in $REMAINING; do
  git cherry-pick "$C" --allow-empty
done
```

Most of these commits are vendor-only and apply cleanly. However, the range
**may include non-vendor commits**: forward-ports from `duckdb/duckdb-r@main`
(glue, R code, CI/CD, cpp11), or later glue-code repairs that were pushed
directly to the `*-dev` branch. That is expected and correct — those
fixes address *subsequent* breakages that were introduced after our fix
point and must be carried forward.

Conflict handling:

- Conflict on `inst/include/cpp11/` or `inst/include/cpp11.hpp`: should
  never happen; stop and report.
- Conflict on `src/duckdb/`: rare; usually means our `patch/` change
  overlaps with a later vendor commit. Take the cherry-picked version
  (`git checkout --theirs src/duckdb/`), re-apply our patch
  (`patch -p1 -i patch/<file>.patch`), then `git add src/duckdb/` and
  `git cherry-pick --continue`.
- Conflict on any other file (glue, `patch/`, `R/`, tests, snapshots): the
  cherry-picked commit is a fix commit whose change overlaps with our own
  fix. Resolve by accepting the cherry-picked version
  (`git checkout --theirs`) or by merging manually, then
  `git cherry-pick --continue`. Do **not** use `--skip` unless the commit
  is genuinely a no-op after our fix.

After all cherry-picks, re-run the final check (same form as Step 4d):

```bash
set -o pipefail
Rscript -e 'rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"), error_on = "warning")' 2>&1 | tail -20
```

to confirm the fully-assembled branch is clean.

### 4g. Push the fix branch

```bash
git push krlmlr "$FIX_BRANCH" --force-with-lease
```

## Step 5 — Continue

Return to Step 3 / Step 4 for the next `NEEDS_FIX` entry.
When all are processed, report a summary:

```text
Fixed: broken-<sha40>-dev (from main-dev,           cherry-picked N commits)
Fixed: broken-<sha40>-dev (from v1.5-variegata-dev, cherry-picked M commits)
Skipped (already fixed): broken-<sha40>-dev exists
No failure found: v1.4-andium-dev
```

---

## Constraints (hard rules)

- **Never edit by hand** `inst/include/cpp11/`, `inst/include/cpp11.hpp`,
  or any `scripts/vendor*.sh` / `scripts/lts.{sh,patch}` file.
  `src/duckdb/` may not be edited directly either, but it WILL change as
  a downstream effect of editing `patch/` (the patch is applied to the
  vendored tree); those derived changes are expected and must be
  committed alongside the patch. `patch/` itself **may** be edited.
- **Never** hand-edit flavor files (`DESCRIPTION` `Package:` field,
  `R/duckdb-package.R`, `src/include/rapi.hpp`'s `DUCKDB_PACKAGE_NAME`,
  `inst/include/duckdb_types.hpp`, `tests/testthat.R`); they are produced
  by `scripts/lts.sh` and should match per-branch.
- **Never** suppress C++ warnings via `#pragma clang diagnostic ignored` or
  similar. Add a `patch/` file that fixes the underlying issue (see
  `AGENTS.md`). CRAN rejects packages that silence warnings.
- **Never** amend commits that have already been pushed. Step 4e amends
  the failing `<sha>` only on the freshly-created local `broken-<sha>-dev`
  branch (which has not been pushed); the original `<sha>` on the upstream
  `*-dev` branch is left alone.
- **Commit status to check**: context `rcc` (not the full check-run name).
- **Branch target**: all pushes go to the `krlmlr` remote
  (`krlmlr/duckdb-r`) to a branch named `broken-<sha>-dev` (full 40-char
  SHA). The `-dev` suffix is required so `each.yaml` triggers per-commit
  CI on the new branch.
- **Branch scope**: only branches matching `\-dev$`.
- Branches being force-pushed to: always use the freshly-fetched
  `krlmlr/*` ref; never rely on any previously-checked-out state.
- **Triage with CI logs, confirm locally.** GitHub Actions results and
  logs are available on the `rcc` orphan branch of `krlmlr/duckdb-r`
  (see Step 4b for fetch commands). Use these to triage failures before
  starting a slow local build. Every fix must still be validated by a
  local `R CMD INSTALL` + `testthat::test_local()` +
  `rcmdcheck::rcmdcheck()` cycle — logs short-circuit triage but do not
  replace verification. The first cold-cache `R CMD INSTALL` is slow
  (10–15 min); do not abort it.
- **Tooling**: prefer the `rcc` orphan branch (`runs2.ndjson` for status
  metadata, `logs2/<sha>.log` for failure log tails) — no auth needed.
  Fall back to `gh` only when a SHA is absent from `runs2.ndjson`;
  always gate that fallback on `gh auth status` succeeding. Do not use
  `curl` for API calls and do not inspect environment variables to
  decide whether to authenticate. A GitHub MCP tool may be used when
  the agent provides one.
