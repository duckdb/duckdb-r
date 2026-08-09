# The R layer

Everything under `R/` and the tests that exercise it:
the R this package writes, where it lives and how it is written.
The C++ half of the interface is
[`glue/`](/handbook/architecture/glue/README.md).

**Almost nothing about this layer is this package's own invention.**
The generics it implements belong to a standard,
the shape its arguments and its messages take belongs to guides
written outside this repository,
and the names it may spell belong to the rename it has to survive.
So a rule on these pages is a citation and a deviation:
what the outside standard says,
and where this package cannot follow it — with the reason.
A deviation nobody wrote down is one the next contributor
reports as a bug, and the one after that copies.

* [`conventions/`](conventions/) — where a method lives, what is generated, and the flavor seam
* [`style/`](style/) — the tidyverse rules this code follows, and where it does not
