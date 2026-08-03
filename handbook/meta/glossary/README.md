# Glossary

The tree's recurring terms of art, one line each,
every entry linking the leaf that owns the concept.
A term earns a line once a second leaf uses it,
added by the change that reaches for it —
one line, so the register stays greppable and diffs per term.

* **ALTREP** — R's alternative-representation mechanism: how an unexecuted relation masquerades as a data frame until touched ([`architecture/glue/`](/handbook/architecture/glue/README.md)).
* **autoload / autoinstall** — an *installed* extension loads on first use; nothing downloads without being asked ([`usage/extensions/`](/handbook/usage/extensions/README.md)).
* **backreference** — the link a secondary document carries back to the handbook node it serves ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **buffer** — a series' `-build` ref: vendored ahead of CI, deliberately untested ([`branches/model/`](/handbook/branches/model/README.md)).
* **commit-match guard** — the fast path's check that library and vendored headers share one upstream commit ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
* **CRAN guard** — the gate that keeps the bundled engine off CRAN's check farm ([`testing/guards/`](/handbook/testing/guards/README.md)).
* **cutover** — the human-run swap that puts a verified `-fwd` counterpart in a series' place ([`branches/model/`](/handbook/branches/model/README.md)).
* **DBI** — R's database-interface standard, which the package implements as a driver ([`usage/connections/`](/handbook/usage/connections/README.md)).
* **dbplyr backend** — the methods that translate dplyr expressions into DuckDB SQL ([`usage/integrations/`](/handbook/usage/integrations/README.md)).
* **deepen line** — the italic last line naming what a not-yet-comprehensive leaf still owes ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **depths** (reference, core, comprehensive) — a leaf's three legitimate published states ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **driver / database instance** — `duckdb()` returns a driver owning one database instance; connections share it, and file-backed instances are cached by path ([`usage/connections/`](/handbook/usage/connections/README.md)).
* **duckplyr** — the dplyr-native downstream package, the closest reverse dependency and a gate for behavior changes ([`testing/revdep/`](/handbook/testing/revdep/README.md)).
* **engine** — the DuckDB database engine embedded in `src/duckdb/` ([`architecture/engine/`](/handbook/architecture/engine/README.md)).
* **fast path** — linking a prebuilt engine library instead of compiling the vendored sources ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
* **flavor** — a mechanical rename publishing the one source tree under another package name ([`branches/flavors/`](/handbook/branches/flavors/README.md)).
* **flavor-name guard** — the scan for the package name hard-coded where the rename cannot reach ([`testing/guards/`](/handbook/testing/guards/README.md)).
* **forward counterpart** (`-fwd`) — the rebased series verified beside the one it will replace ([`branches/model/`](/handbook/branches/model/README.md)).
* **forward-port** — bringing `main`'s R-side work onto a series as cherry-picks ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).
* **glue** — the C++ translation units in `src/` that bridge R and the engine ([`architecture/glue/`](/handbook/architecture/glue/README.md)).
* **glue gate** — the syntax check of the glue against freshly vendored headers ([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
* **harvest** — the fan-in that reconciles what the legs could not publish themselves onto the verdict store ([`operations/ci/per-commit/store/`](/handbook/operations/ci/per-commit/store/README.md)).
* **in-memory database** — the default, file-less instance: never cached, fresh per `duckdb()` call ([`usage/connections/`](/handbook/usage/connections/README.md)).
* **leaf** / **internal node** — leaves explain, once; internal nodes navigate and may govern ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **leg** — the one CI job that builds and judges a shard, commit by commit, in a single workspace ([`operations/ci/per-commit/legs/`](/handbook/operations/ci/per-commit/legs/README.md)).
* **libduckdb** — a prebuilt engine library, linked by the fast path instead of compiling ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
* **nanoarrow array stream** — the zero-copy, batch-by-batch result format of the Arrow API ([`usage/integrations/`](/handbook/usage/integrations/README.md)).
* **patch stack** — the patches under `patch/` re-applied to each freshly vendored tree ([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
* **pointer leaf** — a leaf that states and links its topic's canonical home elsewhere ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **register** — expose an R data frame as a scannable table without copying ([`usage/data-import/`](/handbook/usage/data-import/README.md)); Arrow objects register the same way ([`usage/integrations/`](/handbook/usage/integrations/README.md)).
* **relation** — an unexecuted query tree built by the relational API, run only when its values are touched ([`architecture/glue/`](/handbook/architecture/glue/README.md)).
* **secret store** — where `CREATE PERSISTENT SECRET` writes, under the storage home ([`usage/storage/`](/handbook/usage/storage/README.md)).
* **series** — one upstream DuckDB branch with the package branches that carry it ([`branches/model/`](/handbook/branches/model/README.md)).
* **series loop** — the scheduled agent routine that vendors every series ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).
* **series refs** — `-build`, `-dev`, `-green`, `-build-base`: each with one meaning and one allowed motion ([`branches/model/`](/handbook/branches/model/README.md)).
* **shard** — a contiguous, cost-balanced slice of commits one CI job builds and judges ([`operations/ci/per-commit/planning/`](/handbook/operations/ci/per-commit/planning/README.md)).
* **snapshot** — recorded test output; accepting a change asserts the new output is correct ([`testing/snapshots/`](/handbook/testing/snapshots/README.md)).
* **source id** — `DUCKDB_SOURCE_ID`, the upstream commit the vendored engine identifies as ([`architecture/engine/`](/handbook/architecture/engine/README.md)).
* **spill** — the engine's offload of larger-than-memory work to `temp_directory` ([`usage/memory/`](/handbook/usage/memory/README.md)).
* **storage home** — the one root extensions and secrets share, `~/.duckdb` when shared ([`usage/storage/`](/handbook/usage/storage/README.md)).
* **triage verdicts** — the dispositions issue intake assigns, exactly one per open item ([`operations/triage/`](/handbook/operations/triage/README.md)).
* **vendor commit** — one commit advancing `src/duckdb/` by exactly one upstream commit ([`operations/vendoring/model/`](/handbook/operations/vendoring/model/README.md)).
* **vendoring** — keeping a dependency's sources inside the depending repository ([`operations/vendoring/model/`](/handbook/operations/vendoring/model/README.md)).
* **verdict store** / **`rcc` branch** — the orphan branch holding each commit's build verdict and log ([`operations/ci/per-commit/store/`](/handbook/operations/ci/per-commit/store/README.md)).
* **WKB** — well-known binary, the geometry interchange across the R boundary ([`usage/types/`](/handbook/usage/types/README.md)).
