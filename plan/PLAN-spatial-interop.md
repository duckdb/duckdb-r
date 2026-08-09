# Plan: geometry on the write side, and the sf seam

*This is a plan — work proposed, not a description of the system.
[`usage/types/`](/handbook/usage/types/README.md) owns what geometry
does today, and where the two disagree, the leaf is right.
The measurements it argues from are
[`experiments/2026-08-09-spatial-interop/`](/experiments/2026-08-09-spatial-interop/README.md),
run on 2026-08-09 against duckdb 1.5.5.9013.
It closes out [#117](https://github.com/duckdb/duckdb-r/issues/117),
open since 2024 and stated against an engine that has since changed
underneath it.*

## What is already done

The issue was filed when spatial's geometry was an extension type that
could not customize its Arrow output.
Both halves of that have gone away.
`GEOMETRY` is a core DuckDB type as of 1.5, and this package converts it:
`geometry = "blob"` returns raw WKB, `geometry = "wk"` returns `wk_wkb`
carrying the column's CRS
([#2278](https://github.com/duckdb/duckdb-r/issues/2278),
[#2279](https://github.com/duckdb/duckdb-r/pull/2279)).
The engine registers a `geoarrow.wkb` Arrow extension type in both
directions, so `dbGetQueryArrow()` hands out a field the geoarrow
package decodes, CRS included —
which is what
[duckdb_spatial#153](https://github.com/duckdb/duckdb_spatial/issues/153)
blocked on.

So the read side is finished, and #117's remaining scope is the write
side and the sf seam.

## What is not, and what it costs today

The experiment's write matrix has nineteen rows and three successes,
none of them reachable from an `sf` object.
Three problems, in the order a user meets them.

**An `sfc` column is not refused.**
A `POINT` column writes silently as `DOUBLE[]`:
`DetectRType()` walks into the `sfg` list, finds numbers, and types the
column as a list of doubles.
The geometry is gone and nothing says so — the worst outcome in the
matrix, because it is the only one that does not fail.
`LINESTRING` and `MULTIPOLYGON` fail instead, with
`Invalid Error: std::exception`, naming neither the column nor the
type.
`duckdb_register()` behaves the same way.
Compare `rel_from_df()`, which says
"Can't convert column `geom` to relational."

**A whole `sf` object fails in sf's code, not ours.**
sf registers a `dbDataType()` method that declares the column
`geometry` and writes EWKB hex text into it;
DuckDB 1.5 has a `VARCHAR` → `GEOMETRY` cast that parses *WKT*, so the
hex arrives as "Failed to parse geometry: Unknown geometry type at
offset 0".
`sf::st_write(dsn = con)` fails identically.

**The route that does work is not the one anyone guesses.**
WKT text plus `field.types = c(geom = "GEOMETRY")` lands a `GEOMETRY`
column in one statement, and `field.types = c(geom =
"GEOMETRY('EPSG:4267')")` lands the CRS with it.
WKB does not: `BLOB` → `GEOMETRY` has no cast, so the same call over
`st_as_binary()` output fails, and so does `dbAppendTable()` of WKB
into an existing `GEOMETRY` column.
The Arrow route carries geometry *and* CRS —
a `geoarrow.wkb` field is read as `GEOMETRY('<PROJJSON>')` and the
round trip back to `sf` is geometry-equal and CRS-equal —
but only through `arrow::as_record_batch_reader()` wrapped around a
`nanoarrow` stream, with geoarrow loaded;
`duckdb_register_arrow()` rejects a bare `nanoarrow` stream with
`std::exception`, and `arrow`'s own conversions lose the extension
type.

## What to do

Four steps, in dependency order.
The first two are worth doing whatever happens to the rest.

### 1. Stop the silent loss, and say what failed

A geometry column that cannot be written should say so, in R, naming
the column and the class — never become `DOUBLE[]`, and never surface
as `std::exception`.

Two changes in the glue, both small:

* `DetectRType()` ([`src/types.cpp`](/src/types.cpp)) should recognize
  `sfc` before it descends into the list, the way it already recognizes
  `blob` and `data.frame`, and yield a refusal carrying the class name.
* The `std::exception` path is the more general defect: a non-DuckDB
  exception escaping the register/write path is rendered with no
  content at all.
  Whatever the geometry decision is, that message should name the
  column.

This is a bug fix, not a feature, and it is what makes the rest
diagnosable.

### 2. Give the leaf the shorter route

[`usage/types/`](/handbook/usage/types/README.md) currently documents
the `ALTER TABLE … ALTER COLUMN … SET DATA TYPE GEOMETRY USING
ST_GeomFromWKB()` route.
It works, but it takes two statements and drops the CRS —
`SET DATA TYPE GEOMETRY` names the bare type, so a CRS applied in the
`USING` clause has nowhere to live.
The one-statement WKT route belongs there instead, with the CRS form
beside it and the note that naming a CRS in DDL needs `spatial`
loaded while `ST_SetCRS()` does not.

### 3. Write `wk_wkb` as `GEOMETRY`, not `BLOB`

The narrow, honest version of native support:
teach the write path that a `wk_wkb` column is a geometry.

`wk` is already a `Suggests` and already the read side's non-default
representation, so this closes the loop without a new dependency and
without sf.
The column's `crs` attribute is the CRS to declare.
`dbDataType()` gains a `wk_wkb` method returning `"GEOMETRY"`, or
`"GEOMETRY('<crs>')"` where the attribute is set and resolvable;
the register path types the column the same way.

The open question is how the bytes get there, and the experiment
answers it in the negative for the obvious candidate:
there is no `BLOB` → `GEOMETRY` cast to lean on, so the write cannot
simply hand WKB to a declared `GEOMETRY` column.
Either the glue converts through `ST_GeomFromWKB()` in the projection
it already builds over the registered view — which needs no engine
change and works today — or the cast is asked for upstream, which is
the cleaner shape and makes `dbAppendTable()` of WKB work as a
side effect.
Ask upstream; use the projection meanwhile.

### 4. Decide what `sf` support means, then ask for it where it belongs

With step 3 in place, an `sf` object is one `wk::as_wkb()` away from
writing, and the remaining question is whether this package should
take that step for the user.

Two costs argue for *not* adding an `sf` method here.
sf is a heavy dependency, even suggested, and this package already
declines to carry attribute classes across the boundary in general
([#590](https://github.com/duckdb/duckdb-r/issues/590)) —
`units` columns lose their class in exactly the same way, and geometry
being special would be a rule with one member.
The seam that already exists is `wk`, which is what sf itself uses to
talk to other formats.

So the proposal is: support `wk_wkb` here, and let sf be sf's:

* `sf::st_read(con, <table>)` should recognize a `GEOMETRY` column, or
  the `wk_wkb` vector this package hands it.
  Today it warns and returns a `data.frame`, which is the single most
  visible thing in the issue thread and is fixable only in sf.
* `sf::dbDataType()` declaring `geometry` and writing EWKB hex is what
  makes `dbWriteTable(con, tbl, <sf>)` fail against DuckDB.
  Once a `GEOMETRY` column accepts WKB, that method has a working
  target; until then, the R-side error should at least say what to do
  (`wk::as_wkb()`, or `st_as_text()` with `field.types`).

Both belong in an issue against r-spatial/sf, with this experiment as
the evidence, rather than in a workaround here.

### Not proposed

* **A `geometry = "sf"` connection option.**
  The read side already reaches `sf` in one call
  (`sf::st_as_sfc()` over `wk_wkb`), CRS included,
  so the option would buy a dependency and save nothing.
* **Fixing `arrow`'s conversions.**
  That `arrow::as_arrow_table()` drops `geoarrow.wkb` is worth
  reporting, but the Arrow route is not the one most users take, and
  the nanoarrow stream it needs is one `duckdb_register_arrow()`
  argument away — see below.
* **Anything that requires the `spatial` extension to be present.**
  Everything above works with core `GEOMETRY`; extensions stay
  opt-in
  ([`usage/extensions/`](/handbook/usage/extensions/README.md)).

### Adjacent, and cheap

`duckdb_register_arrow()` accepting a `nanoarrow` array stream
directly would remove the `arrow` round trip from the one write route
that carries a CRS, and would fix an `std::exception` on the way.
It is independent of everything above and not gated on any of it.
