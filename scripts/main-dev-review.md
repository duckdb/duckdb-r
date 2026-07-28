# Non-vendored changes on `main-dev` — review against upstream

**Range:** `main-dev-base..main-dev` (`krlmlr/duckdb-r`), 242 first-parent
commits, of which **16 carry non-vendored (R-side) changes**.
`main-dev` was force-pushed; the R-side fixes are folded **into** the vendor
commits they accompany (the in-place repair model), so they are recovered here
by **path filter** — the diff outside the mechanical paths `src/duckdb/`,
`inst/include/cpp11*`, `R/version.R`, `src/include/sources.mk`, `DESCRIPTION`
(version bump). This is primitive E of `scripts/VENDORING-LOOP.md` applied by
hand.

- base `26c2becd` = `vendor … duckdb/duckdb@d521a441` (2026-04-24)
- tip  `93fe89ac` = `vendor … duckdb/duckdb@7dcfd4b9` (2026-06-02)

Link conventions: R-pkg commit → `krlmlr/duckdb-r@<sha>`; upstream engine →
[`duckdb/duckdb@<sha>`](https://github.com/duckdb/duckdb) and
[`duckdb/duckdb#<pr>`](https://github.com/duckdb/duckdb).

## Summary

| # | R-pkg commit | Upstream | Kind | R-side change |
|---|---|---|---|---|
| 1 | [`3bbfe744`](https://github.com/krlmlr/duckdb-r/commit/3bbfe744b51e3339645350202906d13b2870d296) | [@a1b9a37e](https://github.com/duckdb/duckdb/commit/a1b9a37e49e16263ea7c4e7e1a9fbd595aa9e39c) · [#22268](https://github.com/duckdb/duckdb/pull/22268) | glue/API | `scan.cpp`: `Vector::Reference(value, count)` |
| 2 | [`e8b86c5e`](https://github.com/krlmlr/duckdb-r/commit/e8b86c5e7b4a3ab7a0d89bcee0ee4cb4da724450) | [@81404968](https://github.com/duckdb/duckdb/commit/8140496820f36735571d385bd1f2048f9db2e230) · [#22194](https://github.com/duckdb/duckdb/pull/22194) | snapshot/build | PEG parser: `sql.md` error-position snapshot; drop `libpg_query` includes |
| 3 | [`71ce8f0c`](https://github.com/krlmlr/duckdb-r/commit/71ce8f0ccebae6ec161b1f0bf5c1e21dbe77c541) | [@a41ee381](https://github.com/duckdb/duckdb/commit/a41ee3817550a758764fedaecf8ba59d2c112ca5) · [#22351](https://github.com/duckdb/duckdb/pull/22351) | glue/API | use `SetAlias()` / `GetExpressionType()` / `GetReturnType()` |
| 4 | [`d79cb721`](https://github.com/krlmlr/duckdb-r/commit/d79cb72142f9ad468599ef0c8b9bd0b548f08eda) | — (krlmlr [#22](https://github.com/krlmlr/duckdb-r/pull/22)) | docs/infra | add `.claude/skills/rcc-smoke-fix.md` (not upstream-driven) |
| 5 | [`ead5d8c8`](https://github.com/krlmlr/duckdb-r/commit/ead5d8c8a52cc3538f4c45ddc2feabd0be95500c) | [@ca97226b](https://github.com/duckdb/duckdb/commit/ca97226bd855d0f3e5d1856ad6ae890907954ecd) · [#22377](https://github.com/duckdb/duckdb/pull/22377) | glue/API | `scan.cpp`: `SetChildCardinality()` |
| 6 | [`35888914`](https://github.com/krlmlr/duckdb-r/commit/35888914a3abaacb69d22e308691e3cd363e08b2) | [@b67d8525](https://github.com/duckdb/duckdb/commit/b67d8525f3d97aeea662dc2882f1caaad8809720) · [#22400](https://github.com/duckdb/duckdb/pull/22400) | glue/API (large) | `rfuns.cpp`: `ExecuteWithNulls` → `Execute` with `optional<T>` |
| 7 | [`74081478`](https://github.com/krlmlr/duckdb-r/commit/7408147868c878d5abcd9f32c7eaf813975c2ef2) | [@9ef0d774](https://github.com/duckdb/duckdb/commit/9ef0d7741b719d425682b69cb7dd6b76ca7aaaa7) · [#22412](https://github.com/duckdb/duckdb/pull/22412) | glue+test+snapshot | handle `TIMESTAMP_TZ_NS` |
| 8 | [`cc0b5051`](https://github.com/krlmlr/duckdb-r/commit/cc0b5051425fff905643bdc64e94b8b256f4db58) | [@24c54370](https://github.com/duckdb/duckdb/commit/24c543706576db08a78bd59490d6164b5bef392d) · [#22423](https://github.com/duckdb/duckdb/pull/22423) | R code | validate `file_name` in `rel_to_parquet()` |
| 9 | [`76cb212f`](https://github.com/krlmlr/duckdb-r/commit/76cb212f2af5b4597011d05b176412cc5189e5d9) | [@22e98952](https://github.com/duckdb/duckdb/commit/22e98952f83c80fc20e9ba2af29e57569999ebcd) · [#22428](https://github.com/duckdb/duckdb/pull/22428) | glue/API | `rfuns.cpp`: `ReplaceImplementation()` |
| 10 | [`adceb534`](https://github.com/krlmlr/duckdb-r/commit/adceb5341ae302a57678e416e124a9a5d78d686e) | [@bcb0c9c5](https://github.com/duckdb/duckdb/commit/bcb0c9c5306ccf1cf5c952ea9027740d2587edc0) · [#22463](https://github.com/duckdb/duckdb/pull/22463) | glue/API | `relational.cpp`: `ConstantExpression::GetValue()` |
| 11 | [`15e4ba5f`](https://github.com/krlmlr/duckdb-r/commit/15e4ba5fc6696ba7af9465012dd32e0acb044b74) | [@839b3a77](https://github.com/duckdb/duckdb/commit/839b3a774cce5f1dca62ec016054e19e19674e0b) · [#22493](https://github.com/duckdb/duckdb/pull/22493) | glue/API (warning) | `rfuns.cpp`: non-count `ToUnifiedFormat()` overload |
| 12 | [`722f6084`](https://github.com/krlmlr/duckdb-r/commit/722f6084018e0596ca619f645a2858706ec0747b) | [@8f11e1d4](https://github.com/duckdb/duckdb/commit/8f11e1d409ae81a0617ff751f1eade8f946f0cdf) · [#22489](https://github.com/duckdb/duckdb/pull/22489) | glue/API | `utils.cpp`: explicit `timestamp_t()` conversion |
| 13 | [`6e65fa22`](https://github.com/krlmlr/duckdb-r/commit/6e65fa2254d3a60c82c5e55dde13769f263906e0) | [@ae0aec23](https://github.com/duckdb/duckdb/commit/ae0aec232abb91f18667cc0a6af82a34dfc20bcf) · [#22514](https://github.com/duckdb/duckdb/pull/22514) | glue/API | `register.cpp`: Arrow pushdown via `BoundFunctionExpression` |
| 14 | [`eacff6c3`](https://github.com/krlmlr/duckdb-r/commit/eacff6c3696ec54f54f35d4c47b342ceeba117bc) | [@88b5dbce](https://github.com/duckdb/duckdb/commit/88b5dbcea4b00eebe9743b0b0717878272250c18) · [#22617](https://github.com/duckdb/duckdb/pull/22617) | glue/API | `register.cpp`: `LEGACY_*` filter enums/classes |
| 15 | [`f9e11d1b`](https://github.com/krlmlr/duckdb-r/commit/f9e11d1b2586129c8cb5f0f8898e5275613f0c19) | [@bbf8a746](https://github.com/duckdb/duckdb/commit/bbf8a74671470df87a594666831db7f97746b45a) · [#22799](https://github.com/duckdb/duckdb/pull/22799) | patch drop | remove `patch/0032-uninitialized-metric.patch` ⚠️ |
| 16 | [`90330396`](https://github.com/krlmlr/duckdb-r/commit/903303969f5231a4172ad55768fb2d270c1812b4) | [@2c29839e](https://github.com/duckdb/duckdb/commit/2c29839e715b117cddfb1e860ca058c30351be1b) · [#22811](https://github.com/duckdb/duckdb/pull/22811) | build/config | `rconfigure.py`: exclude bundled `jemalloc` |

15 of 16 are upstream-driven adaptations; one (#4) is a local docs commit.
The common theme: upstream tightened encapsulation and types (accessors over
public members, mandatory vector sizes, `optional<T>` executors, strong
timestamp typing, immutable expressions, unified/legacy filters), and the R glue
follows each new API.

---

## Details

### 1 · `Vector::Reference` now requires a count — [#22268](https://github.com/duckdb/duckdb/pull/22268)
Upstream made methods that build a `ConstantVector` (`ConstantVector::SetNull`,
`Vector::Reference(const Value &)`) take an explicit `count`. The data-frame scan
builds a constant `ROW_ID` vector, so `scan.cpp` now passes `count_t(this_count)`:
`output.data[out_col_idx].Reference(constant_42, count_t(this_count))`.

### 2 · PEG parser replaces libpg_query — [#22194](https://github.com/duckdb/duckdb/pull/22194)
The PostgreSQL parser was replaced by a PEG-based parser. Behaviour is
equivalent (still a `PARSER` error rejecting `INVALID SQL SYNTAX`) but the
reported error position moves one token later (`"SQL"` instead of `"INVALID"`),
so the `tests/testthat/_snaps/sql.md` snapshot is updated. `src/Makevars{,.win}`
drop the now-unused `libpg_query` include paths (generated). *No behavioural R
change* — snapshot + build-config only.

### 3 · `(Base)Expression` members protected — [#22351](https://github.com/duckdb/duckdb/pull/22351)
`BaseExpression::alias`/`type` and `Expression::return_type` became `protected`.
The glue switches to public accessors: `expr->SetAlias(...)`,
`expr->GetExpressionType()`, `…->GetReturnType()` in `relational.cpp` and
`rfuns.cpp`. Mechanical, behaviour-preserving.

### 4 · Add `rcc-smoke-fix` skill (local, not upstream) — krlmlr [#22](https://github.com/krlmlr/duckdb-r/pull/22)
Adds `.claude/skills/rcc-smoke-fix.md` and build-ignores `^\.claude$`. Pure
tooling/docs; unrelated to any upstream change. (Note: this is the *older*
version of the skill — the in-repo `.claude/skills/` has since evolved on
`main`; not a concern for `main-dev` correctness.)

### 5 · Mandatory `Vector` sizes + `DataChunk::Verify` — [#22377](https://github.com/duckdb/duckdb/pull/22377)
Upstream made per-vector sizes mandatory and added a verify pass requiring each
child vector's size to equal the chunk cardinality. `r_dataframe_scan` used
`output.SetCardinality(this_count)`, which set the chunk count but left child
vectors at size 0 → now `output.SetChildCardinality(this_count)`, matching
upstream table functions (`range.cpp`). Correct and minimal.

### 6 · Executors return `optional<X>` — [#22400](https://github.com/duckdb/duckdb/pull/22400)
The largest change. `BinaryExecutor/UnaryExecutor::ExecuteWithNulls` (lambda +
`ValidityMask`/`idx`) was removed in favour of `Execute` with an
`optional<RESULT_TYPE>` return (`nullopt` ⇒ NULL). `rfuns.cpp` is ported
throughout: the integer/double `+` helpers, the `cast<>` template family behind
`as.integer`/`as.numeric`, and the relop dispatch (`set_null` → `is_null`).
Behaviour-preserving; worth a careful read because it touches NA semantics of
base-R arithmetic/coercion (overflow → NA, NaN → NA). The diff maps 1:1 onto the
old mask logic.

### 7 · Nanosecond timestamp with time zone — [#22412](https://github.com/duckdb/duckdb/pull/22412) (internal [#8974](https://github.com/duckdb/duckdb/pull/8974))
New `LogicalTypeId::TIMESTAMP_TZ_NS`. Glue treats it as `POSIXct` in
`DetectLogicalType` (`types.cpp`) and `duckdb_r_typeof`/`duckdb_r_decorate`
(`transform.cpp`), converting via the existing nanosecond path. `test-types.R`
and the `types.md` snapshot add `timestamp_tz_ns` to the excluded-types list,
alongside `timestamp_ns` — both raise the one-shot nanosecond-coercion warning
(`std::call_once`), which otherwise makes the snapshot order-dependent. Reasonable;
the test exclusion is a known-limitation deferral, not a weakened assertion.

### 8 · `rel_to_parquet("")` no longer errors upstream — [#22423](https://github.com/duckdb/duckdb/pull/22423)
Upstream stopped treating an empty filename as an error in `WriteParquet`. To
preserve the R contract, `R/relational.R` now validates `file_name` (non-empty
scalar string) before calling the C++ path. This is the only **R-level
behavioural** change in the set; it keeps the prior user-visible error. Good.

### 9 · Split `(Bound)Function` inheritance — [#22428](https://github.com/duckdb/duckdb/pull/22428)
`BindAggregateFunctionInput::GetBoundFunction()` now returns a
`BoundAggregateFunction&` that is no longer assignable from an
`AggregateFunction`. `rfuns.cpp` (RMinMax, RSum dispatchers) uses the new
`…ReplaceImplementation(AggregateFunction&)`. Mechanical.

### 10 · `ConstantExpr` encapsulated/immutable — [#22463](https://github.com/duckdb/duckdb/pull/22463)
`ConstantExpression::value` is now private; `constant_expression_is_not_null()`
uses the new `GetValue()` accessor. One-liner.

### 11 · Deprecate `count` variants — [#22493](https://github.com/duckdb/duckdb/pull/22493)
`Vector::ToUnifiedFormat(count, data)` is now `[[deprecated]]`; `rfuns.cpp`
switches the three call sites to the `ToUnifiedFormat(data)` overload. Needed
because `rcmdcheck(error_on = "warning")` fails on the deprecation warning —
i.e. caught by the C++ **warning** policy, not a hard break.

### 12 · Strong timestamp typing — [#22489](https://github.com/duckdb/duckdb/pull/22489) (internal [#9096](https://github.com/duckdb/duckdb/pull/9096))
`timebase_t<P,Z>`'s zone-flipping conversion became explicit. `utils.cpp`'s
`TIMESTAMP_TZ` branch wraps with `timestamp_t(val.GetValue<timestamp_tz_t>())`
before `Timestamp::GetEpochSeconds`. Mechanical compile fix.

### 13 · `BoundComparisonExpression` → function expression — [#22514](https://github.com/duckdb/duckdb/pull/22514)
The class became a set of static helpers over `BoundFunctionExpression`. The
Arrow filter-pushdown glue in `register.cpp` switches detection to
`BoundComparisonExpression::IsComparison(expr)` and operand access to
`::Left(comp)`/`::Right(comp)`, casting to `BoundFunctionExpression`. Faithful to
the refactor.

### 14 · Unify `TableFilter`s with `ExpressionFilter` — [#22617](https://github.com/duckdb/duckdb/pull/22617)
Legacy table filters were renamed with a `LEGACY_`/`Legacy` prefix
(`OPTIONAL_FILTER`→`LEGACY_OPTIONAL_FILTER`/`LegacyOptionalFilter`, etc.) and
`TableFilter::ToString(column)` was removed. `register.cpp` updates the
pushdown `switch` to the legacy names and rewrites error messages to reference
the column name directly. ⚠️ The legacy-prefixed names signal these filter types
are on an upstream deprecation path — a future vendor bump may remove them and
require migrating the Arrow pushdown to the new `ExpressionFilter` model. Track
[#22617](https://github.com/duckdb/duckdb/pull/22617).

### 15 · ⚠️ Dropped `patch/0032-uninitialized-metric.patch` — [#22799](https://github.com/duckdb/duckdb/pull/22799)
This commit has **no "R-side fix" note** — the patch was auto-removed by the
vendoring process because it no longer applied after the Metrics Layer refactor.
The patch initialised `MetricType metric = MetricType::EXTRA_INFO;` in
`profiling_utils.hpp`. **Verify** the underlying uninitialized-read is now moot
upstream (the refactor likely reworked/removed that member) rather than silently
reintroduced; if it can still fire, a refreshed patch is needed. This is the one
item that warrants an explicit upstream check before promotion.

### 16 · Exclude bundled `jemalloc` — [#22811](https://github.com/duckdb/duckdb/pull/22811)
Upstream packaging began emitting the `jemalloc` tree into the source list. The
R package never enables jemalloc (`DUCKDB_ENABLE_JEMALLOC` undefined), so the
sources both failed to compile (`jemalloc_cpp.cpp` needs
`DUCKDB_OVERRIDE_NEW_DELETE`) and failed to load (`duckdb_malloc_ncpus`).
`scripts/rconfigure.py` now filters `third_party/jemalloc` out of the generated
source list — a **durable** fix (applied on every vendor run), not a one-off —
restoring the standard allocator. `Makevars`/`sources.mk` regenerate to match.
Good and correctly placed in the generator.

---

## Reviewer takeaways

- **All 15 upstream-driven changes are faithful, minimal adaptations** to public
  API/encapsulation changes; none weakens R behaviour. The single user-visible R
  change (#8) deliberately *preserves* the prior contract.
- **Two items to verify before promotion:**
  - **#15** — confirm the dropped `0032-uninitialized-metric` patch is genuinely
    obsolete upstream, not a silently lost fix.
  - **#14** — the `LEGACY_*` filter names are a deprecation signal; plan the
    migration to `ExpressionFilter` for the Arrow pushdown.
- **One deferral** (#7) excludes `timestamp_tz_ns` from `test_all_types()` for a
  snapshot-stability (one-shot warning) reason, consistent with the existing
  `timestamp_ns` exclusion — fine, but tracks a real coverage gap.
- The two `src/Makevars{,.win}` edits (#2, #16) are generated artifacts; the
  authoritative source is `scripts/rconfigure.py` (#16) and the vendored source
  list (#2).
