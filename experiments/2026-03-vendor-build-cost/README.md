# Vendor-commit build cost

*What it measures:* how much a vendor commit actually changes,
and what that costs to rebuild —
the churn per commit, the ccache hit rate on adjacent commits,
and the size of a cached object archive.

*When and on what:* a local session, March–May 2026,
against real `v1.5-variegata-dev` history (~2 weeks+ old at the time),
R 4.3.3, ccache 4.9.1, `-j4`, unity build linked with LTO.
Sample for A.1: 163 vendor commits, March–May 2026.

*What it supports:* the cost model in
[`operations/ci/per-commit/planning/`](/handbook/operations/ci/per-commit/planning/README.md) —
its shard weighting, its bimodal timing, and the archive trade-off.

*Provenance:* run as Appendix A of the agentic-loop design,
now [`plan/superseded/vendoring-loop.md`](/plan/superseded/vendoring-loop.md),
and moved here unchanged when that design was superseded
but its measurements were not.
No script survives; the method is described with each measurement.

### A.1 Churn / path-filter validation (163 vendor commits, Mar–May 2026)

- **Path filter holds.** Every vendor commit touches only `src/duckdb/` plus two
  generated files: `R/version.R` (163/163) and occasionally `src/include/sources.mk`.
  The only non-mechanical touches in the whole sample were 3 genuine folded
  fixes (1 test, 2 snapshots) — i.e. exactly what the review surface (§3.4) is
  meant to flag.
- **Churn is tiny and header-light.** Per vendor commit: **median 2 `.cpp`**
  changed (106/163 change exactly 2); **66% (107/163) change zero headers**;
  header changes are a small tail (mostly 1, rarely up to 14).

### A.2 ccache behaviour on adjacent commits (8 consecutive v1.5 commits)

Full in-place rebuild at each commit, shared ccache, `--preclean` so every
object is offered to ccache (measures the cache hit rate, not incremental make).
Build is a **unity build** (~340 objects) linked with **LTO**.

| step | Δ cpp | Δ hdr | wall | hits | misses | hit % |
|---|---|---|---|---|---|---|
| 1 (cold) | — | — | 841 s | 0 | 351 | 0% |
| 2 | 1 | 1 (narrow) | 173 s | 325 | 26 | 92% |
| 3 | 2 | 0 | 91 s | 346 | 5 | 98% |
| 4 | 2 | 0 | 92 s | 346 | 5 | 98% |
| 5 | 5 | 3 (**wide**) | 738 s | 161 | 190 | 45% |
| 6 | 6 | 0 | 89 s | 347 | 5 | 98% |
| 7 | 1 | 1 (narrow) | 89 s | 347 | 5 | 98% |
| 8 | 1 | 1 (narrow) | 163 s | 326 | 26 | 92% |

Takeaways:

- **Typical adjacent commit: ~98% cached, ~90 s** (only ~5/351 objects rebuilt).
- **Mean across all incremental steps ≈ 89% / ~205 s**, dragged down by the one
  wide-header commit; **median ≈ 98% / ~92 s**.
- **Header reach, not count, is the cost driver:** steps 2, 7, 8 are all
  "1 cpp + 1 hdr" yet span 5–26 misses (98%↔92%); step 5's 3 *wide* headers
  invalidated 190/351 (45%, near-cold). ⇒ the sharding cost-estimator must weight
  headers by reverse-include reach (§4.3).
- The ~70–90 s floor on cheap commits is **LTO link + install + smoke test**, not
  compilation ⇒ drop LTO for the smoke build (§4.4).
- A.1 (66% zero-header) + A.2 (zero-header ⇒ 98%) ⇒ **most adjacent rebuilds are
  near-free**. The bulk path realises this with incremental `make` within a shard
  (no shared cache, §4.2); the normal per-commit path with the existing CI caches.
  The `--preclean` here only *forces* a full recompile to measure the hit rate;
  production never cleans between consecutive commits.

### A.3 `duckdb.tar` archive size — debug info dominates

> Scope: this measurement informed an earlier *cached* bulk design. The bulk
> path is now **cache-free** (§4.2), so the archive-size question applies only if
> the **normal per-commit** cached path's `duckdb.tar` is ever shrunk; it is
> retained here as a measured reference (and the `-g`/strip trade-off is real for
> that path).

The cached object archive (`$(SOURCES)` = 341 unity `.o`, one v1.5 tree):

| variant | total `.o` | tar (raw) | gzip -6 | zstd -3 | zstd -19 |
|---|---|---|---|---|---|
| **unstripped (`-g`, current CI)** | 2.5 GB | 2.5 GB | 489 MB | 457 MB | — |
| **stripped (`--strip-debug`)** | 97 MB | 97 MB | 20 MB | 19 MB | 14 MB |

(Context: the shipped `duckdb.so`, stripped via `_R_SHLIB_STRIP_`, is ~46 MB.)

- **Debug info is ~96% of the archive** — stripping is a **26×** reduction.
- At ~457 MB zstd (current `-g`), only ~20 trees fit the 10 GB `actions/cache`
  budget ⇒ per-commit archiving of a bulk replay is infeasible. At ~19 MB zstd
  (stripped), **~500 trees fit** ⇒ per-commit archive caching is cheap (§4.2).

**End-to-end validation of "build `-g`, strip only the archive":**

1. *Live build* (`-g`, archive absent → `to-tar.mk`): rc=0, both the `.o` and the
   installed `.so` carry `.debug_info` ⇒ real traces on a failing test.
2. *Strip* the extracted `.o` with `--strip-debug`, re-tar → 97 MB / 19 MB zstd.
3. *Cache-hit build* (stripped archive present → `from-tar.mk`): rc=0 in **6 s**,
   engine objects extracted from the archive, only the ~15 glue `.cpp`
   recompiled; the `.so` **linked cleanly from the stripped objects** and the
   connect/insert/`SELECT sum` smoke test passed (loaded strictly from the
   cache-hit library).

Caveats confirmed: use `--strip-debug` (a full `strip` removes the symbol table
and breaks linking); on a cache hit the engine frames are debug-less (only glue
has `-g`), which is acceptable since novel failures occur on the `-g` miss path.
