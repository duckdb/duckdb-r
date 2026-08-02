# Glossary

The tree's recurring terms of art, one line each,
every entry linking the leaf that owns the concept.

* **backreference** — the link a secondary document carries back to the handbook node it serves ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **buffer** — a series' `-build` ref: vendored ahead of CI, deliberately untested ([`branches/model/`](/handbook/branches/model/README.md)).
* **commit-match guard** — the fast path's check that library and vendored headers share one upstream commit ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
* **CRAN guard** — the gate that keeps the bundled engine off CRAN's check farm ([`testing/guards/`](/handbook/testing/guards/README.md)).
* **cutover** — the human-run swap that puts a verified `-fwd` counterpart in a series' place ([`branches/model/`](/handbook/branches/model/README.md)).
* **deepen line** — the italic last line naming what a not-yet-comprehensive leaf still owes ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **depths** (reference, core, comprehensive) — a leaf's three legitimate published states ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **engine** — the DuckDB database engine embedded in `src/duckdb/` ([`architecture/engine/`](/handbook/architecture/engine/README.md)).
* **fast path** — linking a prebuilt engine library instead of compiling the vendored sources ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
* **flavor** — a mechanical rename publishing the one source tree under another package name ([`branches/flavors/`](/handbook/branches/flavors/README.md)).
* **flavor-name guard** — the scan for the package name hard-coded where the rename cannot reach ([`testing/guards/`](/handbook/testing/guards/README.md)).
* **forward counterpart** (`-fwd`) — the rebased series verified beside the one it will replace ([`branches/model/`](/handbook/branches/model/README.md)).
* **forward-port** — bringing `main`'s R-side work onto a series as cherry-picks ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).
* **glue** — the C++ translation units in `src/` that bridge R and the engine ([`architecture/glue/`](/handbook/architecture/glue/README.md)).
* **glue gate** — the syntax check of the glue against freshly vendored headers ([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
* **leaf** / **internal node** — leaves explain, once; internal nodes navigate and may govern ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **patch stack** — the patches under `patch/` re-applied to each freshly vendored tree ([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).
* **pointer leaf** — a leaf that states and links its topic's canonical home elsewhere ([`meta/handbook/`](/handbook/meta/handbook/README.md)).
* **series** — one upstream DuckDB branch with the package branches that carry it ([`branches/model/`](/handbook/branches/model/README.md)).
* **series loop** — the scheduled agent routine that vendors every series ([`operations/vendoring/series-loop/`](/handbook/operations/vendoring/series-loop/README.md)).
* **series refs** — `-build`, `-dev`, `-green`, `-build-base`: each with one meaning and one allowed motion ([`branches/model/`](/handbook/branches/model/README.md)).
* **shard** — a contiguous, cost-balanced slice of commits one CI job builds and judges ([`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)).
* **snapshot** — recorded test output; accepting a change asserts the new output is correct ([`testing/snapshots/`](/handbook/testing/snapshots/README.md)).
* **triage verdicts** — the dispositions issue intake assigns, exactly one per open item ([`operations/triage/`](/handbook/operations/triage/README.md)).
* **vendor commit** — one commit advancing `src/duckdb/` by exactly one upstream commit ([`operations/vendoring/model/`](/handbook/operations/vendoring/model/README.md)).
* **vendoring** — keeping a dependency's sources inside the depending repository ([`operations/vendoring/model/`](/handbook/operations/vendoring/model/README.md)).
* **verdict store** / **`rcc` branch** — the orphan branch holding each commit's build verdict and log ([`operations/ci/per-commit/`](/handbook/operations/ci/per-commit/README.md)).

*To deepen: add terms as leaves coin them; a term used in two leaves belongs here.*
