# A classed matrix column, and an `ARRAY` column through `rel_to_altrep()`

*What it measures:* what a matrix column that also carries a class (`Date`, `POSIXct`, `difftime`, `hms` or `factor`) becomes
when `dbWriteTable()`, `duckdb_register()`, `dbAppendTable()` or a parameter writes it, against a plain matrix.
Also what `rel_to_altrep()` makes of an `ARRAY` column under `array = "matrix"`, by row count, array size and element type,
against `dbGetQuery()` of the same query.

*When and on what:* 2026-09-28, Linux x86_64 with 4 cores, R 4.5.3, DBI 1.3.0, hms 1.1.4.
duckdb 1.5.5.9029 is the code of `main` after [#2849](https://github.com/duckdb/duckdb-r/pull/2849),
built from the branch of [#2850](https://github.com/duckdb/duckdb-r/pull/2850), which changes only documentation on top of it.
It is a fast-path build linking the release `libduckdb` of DuckDB 1.5.5 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
What is measured is the glue's code, which the release does not change.
[`matrix-limits.R`](matrix-limits.R) is rendered to [`matrix-limits.md`](matrix-limits.md)
by [`scripts/render-reprex.R`](/scripts/render-reprex.R),
and the session info names the scratch library that held the build as `<fast-path build library>`.

*What it supports:* the classed matrix limitation in [`usage/types/`](/handbook/usage/types/README.md),
and the `ARRAY` limitation in [`usage/relational/`](/handbook/usage/relational/README.md).

## Findings

From [`matrix-limits.md`](matrix-limits.md):

* **A classed matrix column writes as its class's scalar type, and the scan counts its rows wrong.**
  A 2x2 `Date` matrix, as the second column of a data frame of two rows, writes a `DATE` column of two rows,
  2024-01-01 and 2024-01-02, through `dbWriteTable()`, `duckdb_register()` and `dbAppendTable()`.
  The second matrix column is dropped, and nothing warns.
  Appending it to a `DATE[2]` column fails instead, because `DATE` has no cast to `DATE[2]`.
  As the only column it writes all four values as four rows.
  As the first of two columns it also writes four rows, and the other column's last two are read past the end of its two values,
  so they hold whatever memory follows it, different on every run.
  Beside a character column, reading that memory crashes R, three times in three runs of [`crash.R`](crash.R),
  which runs on its own because the renderer cannot record a crash.
  A `POSIXct` matrix writes `TIMESTAMP`, and a `difftime` or an `hms` matrix writes `INTERVAL`.
  A `factor` with `dim` set writes `ENUM`, and each of them keeps two rows.
  A plain `integer` matrix writes `INTEGER[2]`, both matrix columns intact.
  As a parameter, a plain matrix is refused with "Unsupported RTypeId", and the `Date` matrix binds as its four values.
  `RApiTypes::DetectRType()` in [`src/types.cpp`](/src/types.cpp) tests these classes before it tests `Rf_isMatrix()`,
  so the column is typed by its class, as a vector.
  The scan takes a data frame's row count from its first column (`RApiTypes::GetVecSize()` in [`src/utils.cpp`](/src/utils.cpp)),
  which for a vector is its length, and reads that many values from every column.
* **`rel_to_altrep()` reads an `ARRAY` column with the wrong shape, or fails.**
  `SELECT [range, range + 10]::INTEGER[2] AS a FROM range(4)` reads through `dbGetQuery()` as the 4x2 matrix with rows `0 10` to `3 13`,
  and through `rel_to_altrep()` as a 2x2 matrix with rows `0 2` and `1 3`:
  the first array element of each row, folded into as many columns as the array has elements.
  An `INTEGER[3]` over six rows and a `VARCHAR[2]` over four read the same way.
  Where the array size does not divide the row count, `rel_to_altrep()` itself fails:
  "dims [product 0] do not match the length of object [1]" for one row of an `INTEGER[2]`,
  and "dims [product 2] do not match the length of object [3]" for three rows of an `INTEGER[2]` or a `VARCHAR[2]`.
  Under the default `array = "none"`, three rows fail the same way, where `dbGetQuery()` gives the hint to `array = "matrix"`.
  Zero rows read as a correct 0x2 matrix.
  An `ARRAY` column also makes `rel_to_altrep()` run the relation as it builds the data frame:
  an error in the query is raised there, where without an array it waits until a value is touched.
  So does a row budget: with `n_rows = 2` over ten rows, the `ARRAY` column fails when the data frame is built,
  and a plain column only once its values are touched.
  `rapi_rel_to_altrep_impl()` in [`src/reltoaltrep.cpp`](/src/reltoaltrep.cpp) calls `duckdb_r_decorate()` on each lazy vector it builds.
  For an array, `duckdb_r_decorate()` in [`src/transform.cpp`](/src/transform.cpp) sets `dim` to the length over the size, by the size.
  A lazy vector's length is the relation's row count (`RelToAltrep::VectorLength()`), which runs the relation to find,
  so the matrix gets the row count over the size as its rows, where `dbGetQuery()` gives it the row count.
  Touching a value allocates the row count times the size through `duckdb_r_allocate()`,
  and `TransformArrayVector()` fills that in the right layout,
  but R reads only as many values as the vector's length.

## Replicating

From this directory, with the build under test first in the library path,
`Rscript ../../scripts/render-reprex.R matrix-limits.R matrix-limits`.
It needs no network and does not wait.
The values read past the end of a column differ from run to run.
[`crash.R`](crash.R) runs on its own, as `Rscript crash.R`, and ends in a segmentation fault.
