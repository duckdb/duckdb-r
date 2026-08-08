# `architecture/`

What the shipped code is, and who wrote it.
The area divides by authorship rather than by language:
some of what ships is written here, and some is vendored from
elsewhere and described only as far as this package's build of it
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
* [`rfuns/`](rfuns/) — the extension that gives the engine R's semantics
