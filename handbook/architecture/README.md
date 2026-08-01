# `architecture/`

What the shipped code is:
the R layer, the C++ glue, and the vendored engine.

* [`r-layer/`](r-layer/) — R conventions and the flavor seam
* [`glue/`](glue/) — the R ↔ DuckDB bridge in `src/`
* [`engine/`](engine/) — the embedded DuckDB engine
