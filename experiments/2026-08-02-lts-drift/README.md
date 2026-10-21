# LTS flavor drift, v1.4

*What it measures:* how far the LTS flavor branch has drifted
from the baseline it renames —
whole tree, and the shipped surface separately.

*When and on what:* 2026-08-02,
`v1.4-andium` at 2b5afce (2026-07-30)
and `v1.4-andium-lts` at 0eeb58c (2026-06-20),
both as fetched from `duckdb/duckdb-r`.

*What it supports:* the structural invariant at
[`branches/invariants/`](/handbook/branches/invariants/README.md) —
the LTS flavor is the released tree plus the rename,
and then mostly frozen.

Run [`run.sh`](run.sh); it reads two refs and writes nothing.

```
$ sh run.sh v1.4-andium v1.4-andium-lts

== whole tree
 60 files changed, 577 insertions(+), 9801 deletions(-)

== shipped surface (what survives .Rbuildignore)
DESCRIPTION
NAMESPACE
R/cpp11.R
R/duckdb-package.R
inst/include/duckdb_1_4_types.hpp
man/duckdb.1.4-package.Rd
src/cpp11.cpp
src/include/rapi.hpp
tests/testthat.R
tests/testthat/test-DBItest.R

== versions
v1.4-andium: Package: duckdb Version: 1.4.5
v1.4-andium-lts: Package: duckdb.1.4 Version: 1.4.5
```

**What it shows.**
On the shipped surface the drift is the rename surface exactly,
plus one straggler:
`tests/testthat/test-DBItest.R`,
where the baseline gained a conditional `PST8PDT` skip
after the LTS branch was last rebuilt.
The other fifty files are tooling and documentation —
the vendoring scripts, the series-loop skills, the workflows —
which the baseline gained and the frozen branch did not.

So the invariant holds where it ships,
and the whole-tree difference measures how long ago
the LTS branch was last rebuilt, not a violation.
Re-running after a rebuild is how that is confirmed.
