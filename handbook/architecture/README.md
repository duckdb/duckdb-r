# `architecture/`

What the shipped code is:
the R layer, the C++ glue, and the vendored engine.
The area divides by who wrote the code, not by language:
the R layer and the glue are written here,
the engine is upstream's,
described only as far as this package's build of it
differs from a stock one.

**Little of what ships was typed where it is read.**
A source file here is as likely generated from an annotation,
derived from a sibling, or copied from upstream
as it is hand-written,
so the first thing a leaf says about a file is which of those it is —
and a correction goes to the producer,
never to the file in front of you.

* [`r-layer/`](r-layer/) — R conventions and the flavor seam
* [`glue/`](glue/) — the R ↔ DuckDB bridge in `src/`
* [`engine/`](engine/) — the embedded DuckDB engine
