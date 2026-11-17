# Reproducer for #2883

A query whose argument autoloads icu, such as `epoch(TIMESTAMPTZ ...) + 2.5`, binds its operator against a catalog entry the load has just freed.
These files show it red on an unpatched engine and green with `patch/0129-Keep-a-function-entry-an-autoload-replaces-alive-while-it-is-bound.patch`.
They are a record for proving the patch on another engine, not part of the package.

## Prerequisites

- The package built from source into a library, without icu linked in (`R CMD INSTALL --no-byte-compile <checkout> -l <lib>`).
  A `DUCKDB_R_USE_SYSTEM_LIB` build links upstream's `libduckdb`, which carries icu, and never takes the autoload path.
- An extension directory with icu installed but not loaded: `Rscript make-template.R <lib> <template>`.
  `INSTALL icu` needs extensions published for the engine's exact version string, so a `-dev` engine needs the alpha stamp (see `.claude/skills/series-alpha/`) or an icu built for it.

## Runs

- `./run-all.sh <lib> <template> [n]` runs the main query `n` times (default 120) and the 11 variants 20 times each.
  Each run is a fresh R process on a fresh copy of the template (`run-many.sh`, `one.R`).
  Each line of the tally gives the exit code, the first result, and icu's `loaded` state before and after; `before=FALSE after=TRUE` shows the autoload ran.
- `capi/valgrind.sh <lib> <template> [query]` builds `capi/repro.c` against the package's `duckdb.so` and runs it under `valgrind` with default options.
  The program prints icu's `loaded` state and then runs the query twice.
  No R code is on that path.

## Expected results

Measured on engine v2.0.0 on Linux (glibc).
"Red" is the unpatched engine and "green" the patched one.

- q1 `epoch(tz) + 2.5`: red 999999997.5, green 1000000002.5.
- q2 `2.5 + epoch(tz)`: red -999999997.5, green 1000000002.5.
- q3 `epoch(tz) - 2.5`: red is a binder error on `age(DOUBLE, DECIMAL(2,1))`, green 999999997.5.
- q4 `year(tz) + 2.5`: red 1998.5, green 2003.5.
- q5 `sum(epoch(tz)) + 1`: red 999999999, green 1000000001.
- q6 `max(epoch(tz))`: 1e+09 on both, a control.
- q7 `range(epoch(...))`: red 3 rows, green 2.
- q8 lambda: red -1999999997, green 2000000003.
- q9 window `sum(...) OVER () + 1`: red 999999999, green 1000000001.
- q10 `date_trunc('day', tz) + INTERVAL 1 DAY`: red is a binder error on `time_bucket`, green 2001-09-10.
- q11 `range(date_trunc(...), ..., INTERVAL 1 HOUR)`: red 25 rows, green 24.
- q12 recursive CTE `USING KEY` with `max(epoch(tz))`: 1e+09 on both.
  icu adds no aggregate overloads, so this only checks that the path still binds.
- valgrind, default query: red reports 862 errors (invalid reads of an entry freed in `CatalogSet::AlterEntry`), green 0.
  Under valgrind the red result itself can come out right, because valgrind's allocator does not reuse the freed slot at once; the error count is the verdict there.

Which wrong value or error red shows depends on the allocator reusing the freed entry, so other platforms can give other wrong results, an internal error or a crash.
Anything but the green value is red.

`autoloading_operator_overloads.test` is a sqllogictest sketch of the same checks for the engine's own test suite.
It has not been run there.
