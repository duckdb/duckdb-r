# `architecture/`

What the shipped code is:
the R layer, the C++ glue, and the vendored engine.
The area divides by who wrote the code rather than by what language it is in:
two of the three are written here,
and the third is upstream's, described only as far as
this package's build of it differs from a stock one.

**Little of what ships was typed where it is read.**
A source here is as likely to be generated from an annotation,
derived from a sibling file, or copied wholesale from upstream
as it is to be hand-written,
so the first thing a leaf says about a file is which of those it is.
The consequence is a habit rather than a rule:
a correction goes to the producer, never to the file in front of you,
and a page in this area earns its keep by naming the producer
rather than by describing the product.
The hand-written surface is smaller than the directory listing suggests,
and knowing which part of it is hand-written is most of what this area is for.

* [`r-layer/`](r-layer/) — R conventions and the flavor seam
* [`glue/`](glue/) — the R ↔ DuckDB bridge in `src/`
* [`engine/`](engine/) — the embedded DuckDB engine
