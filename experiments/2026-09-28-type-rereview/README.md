# Type facts a re-review corrected

*What it measures:* the facts a re-review of the type reference pages after [#2850](https://github.com/duckdb/duckdb-r/pull/2850)
found wrong or stated too broadly:
the `INTEGER` and `BIGINT` minimums through the two Arrow readers, what an IPv6 `INET` address reads as,
which settings make the Arrow export send string views, what `BIGNUM` becomes through Arrow,
when nanoarrow warns on a `BIGINT` past 2^53,
which way the `spatial` extension's box types cast, and which CRS can be named in a type without `spatial`.

*When and on what:* 2026-09-28, Linux x86_64, R 4.5.3, DBI 1.3.0, nanoarrow 0.9.0, arrow 25.0.1,
with `spatial` from the extension store.
duckdb 1.5.5.9029 is the state of `main` after #2850,
a fast-path build linking the release `libduckdb` of DuckDB 1.5.5 ([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
What is measured is the glue's code and engine code the release shares with the vendored engine.
[`rereview.R`](rereview.R) is rendered to [`rereview.md`](rereview.md) by [`scripts/render-reprex.R`](/scripts/render-reprex.R),
and the session info names the scratch library that held the build as `<fast-path build library>`.

*What it supports:* the entries and limitations these facts correct
in [`usage/types/`](/handbook/usage/types/README.md), [`usage/arrow-types/`](/handbook/usage/arrow-types/README.md)
and [`usage/integrations/`](/handbook/usage/integrations/README.md).

## Findings

From [`rereview.md`](rereview.md):

* **The `INTEGER` minimum reads as `NA` in both Arrow readers, and the `BIGINT` minimum as `integer64`'s `NA` in arrow's.**
  nanoarrow reads the `BIGINT` minimum as a `numeric`.
* **An IPv6 `INET` address reads as the address minus 2^127.**
  The engine stores it as a `HUGEINT` with the top bit flipped, and that is what `dbGetQuery()` and both Arrow readers give as a double:
  `'::1'::INET` reads as 1 - 2^127, `-1.7e38`.
  An IPv4 address reads as itself, and the text of either reads the address.
* **`produce_arrow_string_view` alone changes nothing.**
  A string exports as `u` with it, and as the view `vu` once `arrow_output_version` is `'1.4'` too.
* **`BIGNUM` crosses Arrow as `arrow.opaque`, which no R reader converts.**
  nanoarrow reads its storage bytes as a `blob`, and arrow fails with "Converter_Extension can't be used with a non-R extension type".
  Registered back with `duckdb_register_arrow()`, the export lands as `BIGNUM`, and its text reads and writes it.
* **nanoarrow warns where the double it gives is past 2^53, not wherever it rounds.**
  2^53 + 1 rounds to 2^53 without a warning, and 2^53 + 2, which a double holds exactly, warns.
* **`BOX_2D` and `BOX_2DF` cast to `GEOMETRY`, and not from it.**
  The cast from `GEOMETRY` fails with "Unimplemented type for cast" where `POLYGON_2D`'s succeeds,
  and `ST_Extent()` gives a geometry's `BOX_2D`.
  A `typeof()` of the cast does not show this, because it is folded before the cast runs.
* **A CRS the core knows is named in a type without `spatial`.**
  `GEOMETRY('OGC:CRS84')` binds without `spatial` and exports its CRS as PROJJSON;
  `GEOMETRY('EPSG:4267')` fails to bind without it, "Encountered unrecognized coordinate system",
  and exports as PROJJSON with it.
  `ST_SetCRS()` sets that CRS without `spatial`, and the export then carries it as its identifier, an `authority_code`.
  The core's own systems are those [`default_coordinate_systems.cpp`](/src/duckdb/src/catalog/default/default_coordinate_systems.cpp) lists.
