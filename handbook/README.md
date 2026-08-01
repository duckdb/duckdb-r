# The duckdb-r handbook

One place for every documentable aspect of this package;
internal pages like this one only navigate — leaves explain
([the rules](meta/handbook/)).

* [`usage/`](usage/) — using the package from R
  * [`installation/`](usage/installation/) — CRAN, r-universe, and the flavors
  * [`connections/`](usage/connections/) — `dbConnect()`, instances, shutdown
  * [`types/`](usage/types/) — the R ↔ DuckDB type mapping
  * [`extensions/`](usage/extensions/) — what ships, what installs
  * [`memory/`](usage/memory/) — limits, spill, streaming
  * [`data-import/`](usage/data-import/) — CSV and Parquet ingestion
  * [`storage/`](usage/storage/) — where extensions and secrets live
  * [`integrations/`](usage/integrations/) — dbplyr and Arrow
* [`architecture/`](architecture/) — what the shipped code is
  * [`r-layer/`](architecture/r-layer/) — R conventions and the flavor seam
  * [`glue/`](architecture/glue/) — the R ↔ DuckDB bridge in `src/`
  * [`engine/`](architecture/engine/) — `src/duckdb/` and the patch policy
* [`build/`](build/) — from tree to installed package
  * [`source-build/`](build/source-build/) — `configure`, Makevars, the tarball
  * [`fast-paths/`](build/fast-paths/) — prebuilt libduckdb in seconds
  * [`configuration/`](build/configuration/) — the build knobs
  * [`hygiene/`](build/hygiene/) — formatting and warnings
* [`testing/`](testing/) — proving the package works
  * [`suite/`](testing/suite/) — layout, helpers, the fast loop
  * [`snapshots/`](testing/snapshots/) — snapshot discipline
  * [`guards/`](testing/guards/) — CRAN guard, flavor guard
  * [`revdep/`](testing/revdep/) — `revdep/` before release
* [`vendoring/`](vendoring/) — how upstream becomes `src/duckdb/`
  * [`model/`](vendoring/model/) — why vendor, and the invariant
  * [`pipeline/`](vendoring/pipeline/) — the scripts that do it
  * [`series-loop/`](vendoring/series-loop/) — the routine that advances series
  * [`troubleshooting/`](vendoring/troubleshooting/) — when a vendor run fails
* [`branches/`](branches/) — series, flavors, invariants
  * [`model/`](branches/model/) — series and their refs
  * [`flavors/`](branches/flavors/) — one source, many package names
  * [`invariants/`](branches/invariants/) — what every series guarantees
* [`ci/`](ci/) — what runs, and what it gates
  * [`workflows/`](ci/workflows/) — the workflow inventory
  * [`per-commit/`](ci/per-commit/) — `each`, `rcc`, the verdict store
  * [`matrix/`](ci/matrix/) — platforms and R versions
* [`releases/`](releases/) — from a green branch to CRAN
  * [`process/`](releases/process/) — the release state machine
  * [`cran/`](releases/cran/) — submission and policy
  * [`versioning/`](releases/versioning/) — counters, fledge, NEWS
* [`operations/`](operations/) — running the automation
  * [`playbooks/`](operations/playbooks/) — the executable procedures
  * [`schedules/`](operations/schedules/) — which routine fires when
  * [`runbooks/`](operations/runbooks/) — when something is red
* [`meta/`](meta/) — the documentation system itself
  * [`handbook/`](meta/handbook/) — the rules of this tree
  * [`documentation-map/`](meta/documentation-map/) — what lives outside, and why
  * [`plans/`](meta/plans/) — active designs, superseded records
