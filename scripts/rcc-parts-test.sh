#!/bin/bash
# Check the invariants the per-commit record layout rests on, offline, against a
# local bare repository -- optionally seeded from the real `rcc` branch.
#
# The claims in scripts/EACH.md section 3 are measurements, so they should be
# reproducible: this is what produced them. Six things are checked.
#
#   1. scripts/rcc-merge.sh extends the existing layout rather than migrating it:
#      the records already in `runs2.ndjson` are left byte for byte where they
#      are, new ones are appended, and running it twice appends nothing.
#   2. N concurrent writers publishing at once lose nothing. Records land at
#      disjoint paths, so the only contention is on the ref, and the loser
#      re-reads the tip and re-commits rather than re-deriving.
#   3. A blobless, shallow, checkout-less clone stays small even against a branch
#      of a few hundred megabytes -- the property that makes publishing from a leg
#      affordable at all. This is the one that regresses silently: a stray
#      `git write-tree` without `--missing-ok` backfills every blob on the branch.
#   4. scripts/rcc-push.sh recovers from a lost race by resetting onto the winner,
#      re-deriving its own records and appending what the aggregate still lacks,
#      with both writers' records surviving.
#   5. A newer verdict for a commit that already has one overwrites it, in the
#      part and in the aggregate's line -- which is what a retry needs
#      (.claude/skills/series-loop.md), and what a re-publish of the *same*
#      verdict must not cost anything -- and a verdict that stops being a failure
#      takes its log with it, on both the leg's path and the fan-in's.
#   5b. A fan-in whose run is *older* than what the branch already records leaves
#      it alone. Legs publish within seconds while a run takes hours, so an
#      earlier run's fan-in can outlive a retry that corrected it; replaying its
#      artifact must not put the overturned verdict back.
#   6. scripts/rcc-consolidate.sh is a no-op as a dry run, makes the two layouts
#      agree, drops logs past their retention, squashes to two commits, inherits
#      its empty root on a second pass, and refuses to push over a writer that
#      landed in between.
#
# Usage:
#   scripts/rcc-parts-test.sh              # synthetic branch, fast
#   SEED_FROM=origin/rcc scripts/rcc-parts-test.sh
#                                          # seed from a real rcc branch, so the
#                                          # clone-size check is meaningful
#
# Environment variables:
#   WRITERS    - concurrent writers in the race check (default: 20)
#   PER_WRITER - records each publishes (default: 5)
#   SEED_FROM  - a ref holding an `rcc`-shaped tree to seed the remote with
#   KEEP       - if non-empty, do not delete the scratch directory

set -uo pipefail

WRITERS="${WRITERS:-20}"
PER_WRITER="${PER_WRITER:-5}"
SEED_FROM="${SEED_FROM:-}"

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "${here}/.." && pwd)"
work="$(mktemp -d)"
[ -n "${KEEP:-}" ] || trap 'rm -rf "${work}"' EXIT

failures=0
pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; failures=$(( failures + 1 )); }

sha_for() { # <n> -> a 40-hex pseudo-sha
  printf '%040x' "$(( $1 * 2654435761 & 0xffffffffffff ))"
}
record_for() { # <sha> <state>
  printf '{"commit":"%s","status":{"context":"rcc","state":"%s"},"run":{"id":1}}\n' "$1" "$2"
}

git init -q --bare "${work}/remote.git"
git -C "${work}/remote.git" config uploadpack.allowFilter true

echo "== 1. the aggregate is extended, not migrated =="
# Seeded from a real branch, the whole tree is taken -- the harvested logs are
# most of its bytes, and check 3 is only meaningful against them.
if [ -n "${SEED_FROM}" ]; then
  git -C "${repo}" push -q "${work}/remote.git" "${SEED_FROM}:refs/heads/rcc"
  git clone -q --single-branch --branch rcc "${work}/remote.git" "${work}/agg"
else
  mkdir -p "${work}/agg"
  for i in $(seq 1 200); do record_for "$(sha_for "${i}")" success; done \
    > "${work}/agg/runs2.ndjson"
fi
cp "${work}/agg/runs2.ndjson" "${work}/agg-before.ndjson"
lines="$(wc -l < "${work}/agg-before.ndjson" | tr -d ' ')"
count_parts() { find "${work}/agg/runs2.d" -type f -name '*.ndjson' 2>/dev/null | wc -l | tr -d ' '; }
parts_before="$(count_parts)"

# A merge with no new parts must be a no-op, down to the byte -- and must not
# split anything out. Counted as a delta rather than absolutely, because a branch
# seeded from the real one already carries parts of its own.
OUT_DIR="${work}/agg" "${here}/rcc-merge.sh"
cmp -s "${work}/agg-before.ndjson" "${work}/agg/runs2.ndjson" \
  && pass "existing records untouched (${lines}, byte for byte)" \
  || fail "the merge rewrote records that were already there"
[ "$(count_parts)" = "${parts_before}" ] \
  && pass "nothing was migrated into runs2.d/ (still ${parts_before})" \
  || fail "the merge split existing records out, which is what it must not do"

# New parts are appended, and only the new ones.
for i in $(seq 1 5); do
  sha="$(sha_for $(( 800000 + i )))"
  mkdir -p "${work}/agg/runs2.d/${sha:0:2}"
  record_for "${sha}" success > "${work}/agg/runs2.d/${sha:0:2}/${sha}.ndjson"
done
OUT_DIR="${work}/agg" "${here}/rcc-merge.sh"
[ "$(wc -l < "${work}/agg/runs2.ndjson" | tr -d ' ')" = "$(( lines + 5 ))" ] \
  && pass "5 new records appended, nothing else" \
  || fail "expected $(( lines + 5 )) records, got $(wc -l < "${work}/agg/runs2.ndjson")"
head -n "${lines}" "${work}/agg/runs2.ndjson" | cmp -s - "${work}/agg-before.ndjson" \
  && pass "the append left the existing records in place and in order" \
  || fail "appending disturbed the records already in the file"

first="$(cksum < "${work}/agg/runs2.ndjson")"
OUT_DIR="${work}/agg" "${here}/rcc-merge.sh" > /dev/null
[ "${first}" = "$(cksum < "${work}/agg/runs2.ndjson")" ] \
  && pass "a second merge is a no-op" \
  || fail "the merge is not idempotent"

# The migration is available on request, just not on the critical path. Checked
# on a copy, so the rest of this run exercises the un-migrated layout that
# production will actually have.
cp -r "${work}/agg" "${work}/agg-backfilled"
rm -rf "${work}/agg-backfilled/.git"
OUT_DIR="${work}/agg-backfilled" BACKFILL=1 "${here}/rcc-merge.sh" > /dev/null
[ "$(find "${work}/agg-backfilled/runs2.d" -type f -name '*.ndjson' | wc -l | tr -d ' ')" \
    = "$(wc -l < "${work}/agg-backfilled/runs2.ndjson" | tr -d ' ')" ] \
  && pass "BACKFILL=1 splits every record out on request" \
  || fail "BACKFILL=1 did not produce one part per record"
cmp -s "${work}/agg-backfilled/runs2.ndjson" "${work}/agg/runs2.ndjson" \
  && pass "even BACKFILL=1 leaves the aggregate alone" \
  || fail "BACKFILL=1 rewrote the aggregate"

# Publish this state as the remote's starting point.
if [ ! -d "${work}/agg/.git" ]; then
  git clone -q "${work}/remote.git" "${work}/agg-repo" 2>/dev/null
  git -C "${work}/agg-repo" checkout -q --orphan rcc
  cp -r "${work}/agg/." "${work}/agg-repo/"
  mv "${work}/agg-repo" "${work}/agg-tmp"
  rm -rf "${work}/agg"
  mv "${work}/agg-tmp" "${work}/agg"
fi
git -C "${work}/agg" add -A
git -C "${work}/agg" -c user.name=t -c user.email=t@e commit -qm "seed"
git -C "${work}/agg" push -q origin HEAD:refs/heads/rcc
seed_size="$(du -sm "${work}/remote.git" | cut -f1)"
echo "  (remote seeded: ${lines} records, ${seed_size} MB)"

echo
echo "== 2. ${WRITERS} concurrent writers, back to back =="
export RCC_REMOTE="file://${work}/remote.git"
export GITHUB_ACTOR="rcc-parts-test"
export GITHUB_RUN_ID=0

# Warm each writer's clone first, so the race is on the pushes rather than on N
# simultaneous first fetches.
for w in $(seq 1 "${WRITERS}"); do
  sha="$(sha_for $(( 900000 + w )))"
  record_for "${sha}" success > "${work}/warm-${w}"
  RCC_DIR="${work}/w${w}" "${here}/rcc-part-push.sh" "${sha}" "${work}/warm-${w}" \
    > /dev/null 2>&1
done

writer() {
  local w="$1" i sha
  for i in $(seq 1 "${PER_WRITER}"); do
    sha="$(sha_for $(( w * 10000 + i )))"
    record_for "${sha}" success > "${work}/rec-${sha}"
    printf 'log for %s\n' "${sha}" > "${work}/log-${sha}"
    RCC_DIR="${work}/w${w}" "${here}/rcc-part-push.sh" \
      "${sha}" "${work}/rec-${sha}" "${work}/log-${sha}" >> "${work}/out-${w}" 2>&1
    printf '%s\n' "${sha}" >> "${work}/expected"
  done
}

: > "${work}/expected"
for w in $(seq 1 "${WRITERS}"); do writer "${w}" & done
wait

LC_ALL=C sort -u "${work}/expected" -o "${work}/expected"
git -C "${work}/remote.git" ls-tree -r --name-only rcc \
  | sed -n 's#^runs2\.d/../\(.*\)\.ndjson$#\1#p' | LC_ALL=C sort -u > "${work}/actual"
expected_n="$(wc -l < "${work}/expected" | tr -d ' ')"
landed="$(comm -12 "${work}/expected" "${work}/actual" | wc -l | tr -d ' ')"
[ "${landed}" = "${expected_n}" ] \
  && pass "all ${expected_n} records landed, none lost to the race" \
  || fail "only ${landed} of ${expected_n} records landed"

gaveup="$(grep -hc 'could not publish' "${work}"/out-* 2>/dev/null | paste -sd+ | bc)"
[ "${gaveup:-0}" = "0" ] \
  && pass "no writer exhausted its attempts" \
  || fail "${gaveup} writer(s) gave up"

echo "  attempt distribution:"
grep -ho 'on attempt [0-9]*' "${work}"/out-* | sort -V | uniq -c | sed 's/^/    /'

echo
echo "== 3. a writer's clone stays small =="
clone_kb="$(du -sk "${work}/w1/.git" | cut -f1)"
remote_kb="$(du -sk "${work}/remote.git" | cut -f1)"
echo "  writer clone ${clone_kb} KB against a ${remote_kb} KB branch"
if [ "${remote_kb}" -lt 20000 ]; then
  echo "  (branch too small for this to mean much; use SEED_FROM=origin/rcc)"
elif [ "${clone_kb}" -lt $(( remote_kb / 4 )) ]; then
  pass "the blobless clone did not backfill the branch"
else
  fail "the writer clone is $(( clone_kb * 100 / remote_kb ))% of the branch --" \
    "something is fetching blobs (a write-tree without --missing-ok?)"
fi

echo
echo "== 4. rcc-push.sh recovers from a lost race =="
mk_writer() { # <dir> <sha>
  rm -rf "$1"
  git clone -q --single-branch --branch rcc "${work}/remote.git" "$1"
  git -C "$1" config user.name t
  git -C "$1" config user.email t@e
  mkdir -p "$1/runs2.d/${2:0:2}"
  record_for "$2" success > "$1/runs2.d/${2:0:2}/$2.ndjson"
}
sha_a="$(sha_for 111111)"
sha_b="$(sha_for 222222)"
mk_writer "${work}/pa" "${sha_a}"
mk_writer "${work}/pb" "${sha_b}"
# B's producer is idempotent, the way both real producers are: on a re-derive it
# re-creates exactly the records the winner did not already publish.
cat > "${work}/producer-b.sh" <<EOF
#!/bin/bash
mkdir -p "${work}/pb/runs2.d/${sha_b:0:2}"
printf '{"commit":"%s","status":{"context":"rcc","state":"success"},"run":{"id":1}}\n' \\
  "${sha_b}" > "${work}/pb/runs2.d/${sha_b:0:2}/${sha_b}.ndjson"
EOF
chmod +x "${work}/producer-b.sh"

OUT_DIR="${work}/pa" "${here}/rcc-push.sh" "writer A" > /dev/null 2>&1
OUT_DIR="${work}/pb" ATTEMPTS=4 "${here}/rcc-push.sh" "writer B" \
  -- "${work}/producer-b.sh" > "${work}/push-b.log" 2>&1
rc=$?

git -C "${work}/remote.git" cat-file -p rcc:runs2.ndjson > "${work}/final.ndjson"
if [ "${rc}" -eq 0 ] \
   && grep -q "${sha_a}" "${work}/final.ndjson" \
   && grep -q "${sha_b}" "${work}/final.ndjson"; then
  pass "both writers' records are in the aggregate"
else
  fail "a lost race dropped a record (see ${work}/push-b.log)"
fi
grep -q 'resetting onto origin/rcc' "${work}/push-b.log" \
  && pass "the loser reset onto the winner rather than merging" \
  || fail "the loser did not take the recovery path -- was there a race at all?"

echo
echo "== 5. a newer verdict overwrites an older one =="
retry_sha="$(sha_for 555001)"
record_for "${retry_sha}" failure > "${work}/retry-1"
printf 'the first failure\n' > "${work}/retry-log-1"
RCC_DIR="${work}/w1" "${here}/rcc-part-push.sh" \
  "${retry_sha}" "${work}/retry-1" "${work}/retry-log-1" > /dev/null

# Re-publishing the identical verdict must cost nothing.
before_tip="$(git -C "${work}/remote.git" rev-parse rcc)"
RCC_DIR="${work}/w1" "${here}/rcc-part-push.sh" \
  "${retry_sha}" "${work}/retry-1" "${work}/retry-log-1" > /dev/null
[ "${before_tip}" = "$(git -C "${work}/remote.git" rev-parse rcc)" ] \
  && pass "re-publishing the same verdict adds no commit" \
  || fail "an unchanged record was pushed again"

# The retry's verdict is different, so it must land.
record_for "${retry_sha}" success > "${work}/retry-2"
RCC_DIR="${work}/w1" "${here}/rcc-part-push.sh" \
  "${retry_sha}" "${work}/retry-2" > /dev/null
landed="$(git -C "${work}/remote.git" cat-file -p \
  "rcc:runs2.d/${retry_sha:0:2}/${retry_sha}.ndjson" | jq -r '.status.state')"
[ "${landed}" = "success" ] \
  && pass "the newer verdict replaced the part" \
  || fail "the part still says ${landed}"

# And the aggregate's stale line is replaced, not duplicated -- readers take the
# first line for a SHA, so an appended second one would be invisible.
rm -rf "${work}/agg2"
git clone -q --single-branch --branch rcc "${work}/remote.git" "${work}/agg2"
OUT_DIR="${work}/agg2" "${here}/rcc-merge.sh" > /dev/null
OUT_DIR="${work}/agg2" "${here}/rcc-merge.sh" > /dev/null   # the record is stale only now
lines="$(grep -c "\"${retry_sha}\"" "${work}/agg2/runs2.ndjson" || true)"
first="$(grep -m 1 "\"${retry_sha}\"" "${work}/agg2/runs2.ndjson" | jq -r '.status.state')"
[ "${lines}" = "1" ] && [ "${first}" = "success" ] \
  && pass "the aggregate holds one line for the commit, with the newer verdict" \
  || fail "the aggregate has ${lines} line(s), first says ${first}"

# The stale log must go when the verdict stops being a failure, on the leg path.
git -C "${work}/remote.git" cat-file -e "rcc:logs2/${retry_sha}.log" 2>/dev/null \
  && fail "the failure log survived a retry to success" \
  || pass "the leg dropped the log its own new verdict overturned"

echo
echo "== 5b. an older run's fan-in does not overwrite a newer record =="
stale_sha="$(sha_for 556001)"
mkdir -p "${work}/sf/runs/runs2.d/${stale_sha:0:2}" "${work}/sf/runs/logs2" \
  "${work}/sf/art/each-logs-1/parts"
# The branch carries run 2's success (a retry, which corrected run 1).
printf '{"commit":"%s","status":{"context":"rcc","state":"success","created_at":"2026-07-29T12:00:00Z"},"run":{"id":2}}\n' \
  "${stale_sha}" > "${work}/sf/runs/runs2.d/${stale_sha:0:2}/${stale_sha}.ndjson"
# Run 1's artifact, decided hours earlier, is what its slow fan-in replays.
printf '{"commit":"%s","status":{"context":"rcc","state":"failure","created_at":"2026-07-29T08:00:00Z"},"run":{"id":1}}\n' \
  "${stale_sha}" > "${work}/sf/art/each-logs-1/parts/${stale_sha}.ndjson"
printf 'the overturned failure\n' > "${work}/sf/art/each-logs-1/${stale_sha}.log"
printf '{"commit":"%s","state":"failure","shard":1,"duration_seconds":1,"exit_code":1}\n' \
  "${stale_sha}" > "${work}/sf/art/each-logs-1/index.ndjson"
ARTIFACTS="${work}/sf/art" OUT_DIR="${work}/sf/runs" RUN_ID=1 GH_TOKEN=x \
  "${here}/each-harvest.sh" > "${work}/sf.log" 2>&1
after="$(jq -r '.status.state' "${work}/sf/runs/runs2.d/${stale_sha:0:2}/${stale_sha}.ndjson")"
[ "${after}" = "success" ] \
  && pass "the newer run's verdict survived the older fan-in" \
  || fail "an older fan-in overwrote a newer verdict with ${after}"
[ ! -f "${work}/sf/runs/logs2/${stale_sha}.log" ] \
  && pass "and it did not resurrect the overturned log" \
  || fail "the overturned failure log was restored"
grep -q 'newer than this run' "${work}/sf.log" \
  && pass "the fan-in said why it kept the record" \
  || fail "the fan-in was silent about superseding"

# The reverse direction must still work: a *newer* run does replace.
printf '{"commit":"%s","status":{"context":"rcc","state":"success","created_at":"2026-07-29T20:00:00Z"},"run":{"id":9}}\n' \
  "${stale_sha}" > "${work}/sf/art/each-logs-1/parts/${stale_sha}.ndjson"
printf '{"commit":"%s","state":"success","shard":1,"duration_seconds":1,"exit_code":0}\n' \
  "${stale_sha}" > "${work}/sf/art/each-logs-1/index.ndjson"
# Give the branch a failure for run 2 to be corrected.
printf '{"commit":"%s","status":{"context":"rcc","state":"failure","created_at":"2026-07-29T12:00:00Z"},"run":{"id":2}}\n' \
  "${stale_sha}" > "${work}/sf/runs/runs2.d/${stale_sha:0:2}/${stale_sha}.ndjson"
printf 'stale\n' > "${work}/sf/runs/logs2/${stale_sha}.log"
ARTIFACTS="${work}/sf/art" OUT_DIR="${work}/sf/runs" RUN_ID=9 GH_TOKEN=x \
  "${here}/each-harvest.sh" > "${work}/sf2.log" 2>&1
after="$(jq -r '.status.state' "${work}/sf/runs/runs2.d/${stale_sha:0:2}/${stale_sha}.ndjson")"
[ "${after}" = "success" ] && [ ! -f "${work}/sf/runs/logs2/${stale_sha}.log" ] \
  && pass "a newer run still replaces the record and drops the stale log" \
  || fail "a newer run failed to replace (state=${after})"

# A malformed record on the branch must not take the whole run down with it.
mkdir -p "${work}/mf/runs/runs2.d/ff" "${work}/mf/runs/logs2" "${work}/mf/art/each-logs-1/parts"
bad="ff$(sha_for 557001 | cut -c3-)"; ok_sha="$(sha_for 557002)"
printf 'not json\n' > "${work}/mf/runs/runs2.d/${bad:0:2}/${bad}.ndjson"
for c in "${bad}" "${ok_sha}"; do
  record_for "${c}" success > "${work}/mf/art/each-logs-1/parts/${c}.ndjson"
  printf '{"commit":"%s","state":"success","shard":1,"duration_seconds":1,"exit_code":0}\n' \
    "${c}" >> "${work}/mf/art/each-logs-1/index.ndjson"
done
if ARTIFACTS="${work}/mf/art" OUT_DIR="${work}/mf/runs" RUN_ID=1 GH_TOKEN=x \
     "${here}/each-harvest.sh" > "${work}/mf.log" 2>&1 \
   && [ -f "${work}/mf/runs/runs2.d/${ok_sha:0:2}/${ok_sha}.ndjson" ]; then
  pass "one unreadable record does not abort the fan-in"
else
  fail "a malformed record aborted the whole fan-in (see ${work}/mf.log)"
fi

echo
echo "== 6. consolidation =="
rm -rf "${work}/cons"
git clone -q --single-branch --branch rcc "${work}/remote.git" "${work}/cons"
git -C "${work}/cons" config user.name t
git -C "${work}/cons" config user.email t@e

# An aggregate-only record, so the reconciliation has something to do; and a log
# old enough to age out.
legacy_sha="$(sha_for 666001)"
printf '{"commit":"%s","status":{"context":"rcc","state":"failure","created_at":"2020-01-01T00:00:00Z"},"run":{"id":1}}\n' \
  "${legacy_sha}" >> "${work}/cons/runs2.ndjson"
printf 'an ancient log\n' > "${work}/cons/logs2/${legacy_sha}.log"
git -C "${work}/cons" add -A
git -C "${work}/cons" commit -qm "an aggregate-only record with an old log"
git -C "${work}/cons" push -q origin HEAD:rcc

before_state="$(git -C "${work}/cons" rev-parse HEAD:)"
OUT_DIR="${work}/cons" "${here}/rcc-consolidate.sh" > "${work}/cons-dry.log" 2>&1
[ "${before_state}" = "$(git -C "${work}/cons" rev-parse HEAD:)" ] \
  && [ -z "$(git -C "${work}/cons" status --porcelain)" ] \
  && pass "a dry run changes nothing" \
  || fail "the dry run modified the worktree"
stragglers="$(sed -n 's/^ *\([0-9]*\) record(s) live only in runs2.ndjson.*/\1/p' \
  "${work}/cons-dry.log" | head -1)"
[ -n "${stragglers}" ] && [ "${stragglers}" -ge 1 ] \
  && pass "the dry run reported ${stragglers} aggregate-only record(s)" \
  || fail "the dry run did not report the aggregate-only record"

OUT_DIR="${work}/cons" APPLY=1 "${here}/rcc-consolidate.sh" > "${work}/cons.log" 2>&1 \
  && pass "the consolidation applied and pushed" \
  || fail "the consolidation failed (see ${work}/cons.log)"

[ "$(git -C "${work}/remote.git" rev-list --count rcc)" = "2" ] \
  && pass "the branch is two commits" \
  || fail "the branch has $(git -C "${work}/remote.git" rev-list --count rcc) commits"
root="$(git -C "${work}/remote.git" rev-list --max-parents=0 rcc)"
[ -z "$(git -C "${work}/remote.git" ls-tree "${root}")" ] \
  && [ "$(git -C "${work}/remote.git" log -1 --format=%s "${root}")" = "Initial" ] \
  && pass "the root is an empty commit called Initial" \
  || fail "the root is not an empty Initial commit"

git -C "${work}/remote.git" ls-tree -r --name-only rcc \
  | sed -n 's#^runs2\.d/../\(.*\)\.ndjson$#\1#p' | LC_ALL=C sort > "${work}/cons-parts"
git -C "${work}/remote.git" cat-file -p rcc:runs2.ndjson > "${work}/cons-agg"
jq -r .commit "${work}/cons-agg" | LC_ALL=C sort > "${work}/cons-agg-shas"
cmp -s "${work}/cons-parts" "${work}/cons-agg-shas" \
  && pass "the two layouts hold exactly the same records ($(wc -l < "${work}/cons-parts" | tr -d ' '))" \
  || fail "the layouts still disagree after consolidating"
[ "$(jq -c . "${work}/cons-agg" | wc -l)" = "$(wc -l < "${work}/cons-agg")" ] \
  && pass "every aggregate line is still valid JSON" \
  || fail "the rebuilt aggregate has malformed lines"
git -C "${work}/remote.git" cat-file -e "rcc:logs2/${legacy_sha}.log" 2>/dev/null \
  && fail "the aged-out log is still on the branch" \
  || pass "the aged-out log was dropped"
git -C "${work}/remote.git" cat-file -e "rcc:runs2.d/${legacy_sha:0:2}/${legacy_sha}.ndjson" \
  && pass "its record was kept -- the verdict outlives the evidence" \
  || fail "the record was dropped along with the log"

# A second pass must reuse the root rather than mint another.
rm -rf "${work}/cons2"
# --no-hardlinks: the consolidation just repacked the bare repo, and
# git's local clone optimisation trips on that. Local paths only.
git clone -q --no-hardlinks --single-branch --branch rcc "${work}/remote.git" "${work}/cons2"
git -C "${work}/cons2" config user.name t
git -C "${work}/cons2" config user.email t@e
OUT_DIR="${work}/cons2" APPLY=1 "${here}/rcc-consolidate.sh" > "${work}/cons2.log" 2>&1
grep -q "Inheriting the existing empty root" "${work}/cons2.log" \
  && [ "${root}" = "$(git -C "${work}/remote.git" rev-list --max-parents=0 rcc)" ] \
  && pass "a second consolidation inherits the same root" \
  || fail "the root was re-minted"

# And the lease must refuse a writer that landed in between.
rm -rf "${work}/cons3" "${work}/other"
# --no-hardlinks: the consolidation just repacked the bare repo, and
# git's local clone optimisation trips on that. Local paths only.
git clone -q --no-hardlinks --single-branch --branch rcc "${work}/remote.git" "${work}/cons3"
git -C "${work}/cons3" config user.name t
git -C "${work}/cons3" config user.email t@e
other_sha="$(sha_for 777001)"
record_for "${other_sha}" success > "${work}/other-rec"
RCC_DIR="${work}/wother" "${here}/rcc-part-push.sh" \
  "${other_sha}" "${work}/other-rec" > /dev/null
if OUT_DIR="${work}/cons3" APPLY=1 "${here}/rcc-consolidate.sh" > "${work}/cons3.log" 2>&1; then
  fail "the consolidation pushed over a concurrent writer"
else
  git -C "${work}/remote.git" cat-file -e "rcc:runs2.d/${other_sha:0:2}/${other_sha}.ndjson" \
    && pass "the lease refused the push and the other writer's record survived" \
    || fail "the push was refused but the record is gone anyway"
fi

# Every shape the branch can legitimately have must still produce a report.
echo
echo "== 6b. consolidation survives every branch shape =="
for shape in no-aggregate no-logs no-parts empty; do
  d="${work}/shape-${shape}"
  rm -rf "${d}"
  git init -q "${d}"
  git -C "${d}" config user.name t
  git -C "${d}" config user.email t@e
  case "${shape}" in
    no-aggregate) mkdir -p "${d}/runs2.d/aa" "${d}/logs2"
                  record_for "$(sha_for 1)" success > "${d}/runs2.d/aa/$(sha_for 1).ndjson" ;;
    no-logs)      mkdir -p "${d}/runs2.d/aa"
                  record_for "$(sha_for 1)" success > "${d}/runs2.d/aa/$(sha_for 1).ndjson"
                  record_for "$(sha_for 1)" success > "${d}/runs2.ndjson" ;;
    no-parts)     mkdir -p "${d}/logs2"
                  record_for "$(sha_for 1)" success > "${d}/runs2.ndjson" ;;
    empty)        : ;;
  esac
  git -C "${d}" add -A > /dev/null 2>&1 || true
  git -C "${d}" commit -qm "${shape}" --allow-empty
  if OUT_DIR="${d}" "${here}/rcc-consolidate.sh" > "${work}/shape-${shape}.log" 2>&1 \
     && grep -q 'dry run' "${work}/shape-${shape}.log"; then
    pass "${shape}: the dry run reported instead of dying"
  else
    fail "${shape}: the dry run failed (see ${work}/shape-${shape}.log)"
  fi
done

echo
if [ "${failures}" -eq 0 ]; then
  echo "All checks passed."
else
  echo "${failures} check(s) failed."
fi
exit "${failures}"
