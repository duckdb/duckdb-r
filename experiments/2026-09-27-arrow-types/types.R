# The DuckDB types the scripts beside this one probe, with a value of each.
# Copied unchanged, below this header, from the list in
# experiments/2026-09-26-type-catalog/, which proves it complete against the
# engine; sourced by out.R.
# `logical` is the engine's type id, which catalog.R holds against
# duckdb_types(); `opt` names the dbConnect() option that changes what R
# receives, if one does; `ext` names the extension that defines the type.
spec <- function(type, logical, lit, opt = "", ext = "") {
  data.frame(type = type, logical = logical, lit = lit, opt = opt, ext = ext)
}
types <- rbind(
  spec("BOOLEAN", "BOOLEAN", "true"),
  spec("TINYINT", "TINYINT", "42::TINYINT"),
  spec("SMALLINT", "SMALLINT", "42::SMALLINT"),
  spec("INTEGER", "INTEGER", "42::INTEGER"),
  spec("BIGINT", "BIGINT", "42::BIGINT", "bigint"),
  spec("HUGEINT", "HUGEINT", "42::HUGEINT", "bigint"),
  spec("UTINYINT", "UTINYINT", "42::UTINYINT"),
  spec("USMALLINT", "USMALLINT", "42::USMALLINT"),
  spec("UINTEGER", "UINTEGER", "42::UINTEGER"),
  spec("UBIGINT", "UBIGINT", "42::UBIGINT", "bigint"),
  spec("UHUGEINT", "UHUGEINT", "42::UHUGEINT", "bigint"),
  spec("BIGNUM", "BIGNUM", "42::BIGNUM"),
  spec("DECIMAL(4,1)", "DECIMAL", "3.1::DECIMAL(4,1)"),
  spec("DECIMAL(18,3)", "DECIMAL", "3.142::DECIMAL(18,3)"),
  spec("DECIMAL(38,10)", "DECIMAL", "3.1415926535::DECIMAL(38,10)"),
  spec("FLOAT", "FLOAT", "1.5::FLOAT"),
  spec("DOUBLE", "DOUBLE", "1.5::DOUBLE"),
  spec("VARCHAR", "VARCHAR", "'duck'"),
  spec("BLOB", "BLOB", "'\\xAA\\xBB'::BLOB"),
  spec("BIT", "BIT", "'10101'::BIT"),
  spec("UUID", "UUID", "'4ac7a9e9-607c-4c8a-84f3-843f0191e3fd'::UUID"),
  spec("DATE", "DATE", "DATE '2024-01-10'"),
  spec("TIME", "TIME", "TIME '13:03:12.123456'"),
  spec("TIME_NS", "TIME_NS", "'13:03:12.123456'::TIME_NS"),
  spec("TIMETZ", "TIME WITH TIME ZONE", "TIMETZ '13:03:12.123456+00'"),
  spec("TIMESTAMP_S", "TIMESTAMP_S", "TIMESTAMP_S '2024-01-10 13:03:12'"),
  spec(
    "TIMESTAMP_MS",
    "TIMESTAMP_MS",
    "TIMESTAMP_MS '2024-01-10 13:03:12.123'"
  ),
  spec("TIMESTAMP", "TIMESTAMP", "TIMESTAMP '2024-01-10 13:03:12.123456'"),
  spec(
    "TIMESTAMP_NS",
    "TIMESTAMP_NS",
    "TIMESTAMP_NS '2024-01-10 13:03:12.123456'"
  ),
  spec(
    "TIMESTAMPTZ",
    "TIMESTAMP WITH TIME ZONE",
    "TIMESTAMPTZ '2024-01-10 13:03:12.123456+00'"
  ),
  spec("INTERVAL", "INTERVAL", "INTERVAL '3 hours 4 minutes 5.5 seconds'"),
  spec(
    "ENUM('sad', 'ok', 'happy')",
    "ENUM",
    "'ok'::ENUM('sad', 'ok', 'happy')"
  ),
  spec("GEOMETRY", "GEOMETRY", "'POINT (1 2)'::GEOMETRY", "geometry"),
  spec("NULL", "NULL", "NULL"),
  spec("INTEGER[3]", "ARRAY", "[1, 2, 3]::INTEGER[3]", "array"),
  spec("INTEGER[]", "LIST", "[1, 2, 3]::INTEGER[]"),
  spec("MAP(VARCHAR, INTEGER)", "MAP", "MAP {'a': 1, 'b': 2}", "map"),
  spec("STRUCT(i INTEGER, j VARCHAR)", "STRUCT", "{'i': 42, 'j': 'duck'}"),
  spec(
    "UNION(num INTEGER, str VARCHAR)",
    "UNION",
    "union_value(num := 2)::UNION(num INTEGER, str VARCHAR)"
  ),
  spec("VARIANT", "VARIANT", "42::VARIANT"),
  spec("JSON", "VARCHAR", "'{\"a\": 1}'::JSON", ext = "json"),
  spec("INET", "STRUCT", "'127.0.0.1'::INET", ext = "inet"),
  spec("POINT_2D", "STRUCT", "ST_Point2D(1, 2)", ext = "spatial"),
  spec("POINT_3D", "STRUCT", "ST_Point3D(1, 2, 3)", ext = "spatial"),
  spec("POINT_4D", "STRUCT", "ST_Point4D(1, 2, 3, 4)", ext = "spatial"),
  spec(
    "LINESTRING_2D",
    "LIST",
    "[{'x': 0, 'y': 0}, {'x': 1, 'y': 1}]::LINESTRING_2D",
    ext = "spatial"
  ),
  spec(
    "LINESTRING_3D",
    "LIST",
    "[{'x': 0, 'y': 0, 'z': 0}, {'x': 1, 'y': 1, 'z': 1}]::LINESTRING_3D",
    ext = "spatial"
  ),
  spec(
    "POLYGON_2D",
    "LIST",
    "[[{'x': 0, 'y': 0}, {'x': 1, 'y': 0}, {'x': 0, 'y': 0}]]::POLYGON_2D",
    ext = "spatial"
  ),
  spec(
    "POLYGON_3D",
    "LIST",
    paste0(
      "[[{'x': 0, 'y': 0, 'z': 0}, {'x': 1, 'y': 0, 'z': 0}, ",
      "{'x': 0, 'y': 0, 'z': 0}]]::POLYGON_3D"
    ),
    ext = "spatial"
  ),
  spec(
    "BOX_2D",
    "STRUCT",
    "{'min_x': 0, 'min_y': 0, 'max_x': 1, 'max_y': 1}::BOX_2D",
    ext = "spatial"
  ),
  spec(
    "BOX_2DF",
    "STRUCT",
    "{'min_x': 0, 'min_y': 0, 'max_x': 1, 'max_y': 1}::BOX_2DF",
    ext = "spatial"
  ),
  spec(
    "WKB_BLOB",
    "BLOB",
    "ST_AsWKB('POINT (1 2)'::GEOMETRY)::WKB_BLOB",
    ext = "spatial"
  )
)
