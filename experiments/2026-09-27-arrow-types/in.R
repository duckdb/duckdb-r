# Arrow into DuckDB: every Arrow type, built in R and registered through
# duckdb_register_arrow(), with the DuckDB type and value it lands as; then
# every R class, through each package's Arrow inference, beside the type
# dbWriteTable() gives the same column.
# The recorded run is in.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
library(nanoarrow)
library(geoarrow) # registers the geoarrow extension types
options(width = 250)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

con <- dbConnect(duckdb())

# Each step names itself when it fails: the package that built the array,
# arrow importing it (duckdb_register_arrow() takes arrow objects only),
# or DuckDB scanning it.
step <- function(name, expr) {
  tryCatch(
    expr,
    error = function(e) {
      stop(
        paste0(name, ": ", gsub("\n.*", "", conditionMessage(e))),
        call. = FALSE
      )
    }
  )
}
cell <- function(expr, width = 70) {
  out <- tryCatch(expr, error = function(e) paste("ERROR", conditionMessage(e)))
  out <- paste(out, collapse = " | ")
  if (nchar(out) > width) paste0(substr(out, 1, width - 3), "...") else out
}

# One array as the column x of a one-column batch, as an arrow reader.
as_reader <- function(arr) {
  batch <- nanoarrow_array_init(na_struct(list(
    x = infer_nanoarrow_schema(arr)
  )))
  batch <- nanoarrow_array_modify(
    batch,
    list(length = arr$length, null_count = 0, children = list(x = arr))
  )
  step("arrow", arrow::as_record_batch_reader(basic_array_stream(list(batch))))
}

# Register a reader, and read back the type and the value as text. Every
# call registers a view of its own name: a name reused across calls can meet
# a registration an earlier call left behind.
n_views <- 0
lands_as <- function(reader) {
  n_views <<- n_views + 1
  v <- paste0("v", n_views)
  step("duckdb", {
    duckdb_register_arrow(con, v, reader)
    on.exit(duckdb_unregister_arrow(con, v))
    r <- dbGetQuery(
      con,
      paste("SELECT typeof(x) AS t, x::VARCHAR AS v FROM", v)
    )
    paste(r$t, r$v)
  })
}

# Built from an R value by nanoarrow, into the schema given.
from_r <- function(value, schema) {
  function() {
    as_reader(step("nanoarrow", as_nanoarrow_array(value, schema = schema)))
  }
}
# Built from raw bytes, for the types nanoarrow cannot convert R values to.
from_bytes <- function(schema, bytes) {
  function() {
    arr <- nanoarrow_array_modify(
      nanoarrow_array_init(schema),
      list(
        length = 1,
        null_count = 0,
        buffers = list(NULL, as_nanoarrow_buffer(bytes))
      )
    )
    as_reader(arr)
  }
}
# DuckDB's own export of a query, after the SET statements given, from a
# connection of its own: any later statement on the connection that produced
# a stream invalidates it, and a stream registered on that connection hangs.
producers <- list()
from_duckdb <- function(sql, set = character()) {
  function() {
    src <- dbConnect(duckdb())
    producers[[length(producers) + 1]] <<- src
    for (s in set) {
      invisible(dbExecute(src, s))
    }
    step("arrow", arrow::as_record_batch_reader(dbGetQueryArrow(src, sql)))
  }
}
int32_le <- function(...) writeBin(c(...), raw(), size = 4, endian = "little")

hms <- hms::as_hms("13:03:12.123456")
utc <- as.POSIXct("2024-01-10 13:03:12.123456", tz = "UTC")
bytes <- blob::blob(as.raw(c(0xaa, 0xbb)))

# --- Every Arrow type -----------------------------------------------------

arrow_types <- list(
  "na" = from_r(NA, na_na()),
  "bool" = from_r(TRUE, na_bool()),
  "int8" = from_r(42L, na_int8()),
  "int16" = from_r(42L, na_int16()),
  "int32" = from_r(42L, na_int32()),
  "int64" = from_r(42L, na_int64()),
  "uint8" = from_r(42L, na_uint8()),
  "uint16" = from_r(42L, na_uint16()),
  "uint32" = from_r(42L, na_uint32()),
  "uint64" = from_r(42L, na_uint64()),
  "half_float" = from_r(1.5, na_half_float()),
  "float" = from_r(1.5, na_float()),
  "double" = from_r(1.5, na_double()),
  "decimal32(9, 2)" = from_r(3.14, na_decimal32(9, 2)),
  "decimal64(18, 3)" = from_r(3.142, na_decimal64(18, 3)),
  "decimal128(38, 10)" = from_r(3.1415926535, na_decimal128(38, 10)),
  "decimal256(76, 10)" = from_r(3.1415926535, na_decimal256(76, 10)),
  "string" = from_r("duck", na_string()),
  "large_string" = from_r("duck", na_large_string()),
  "string_view" = from_r("duck", na_string_view()),
  "binary" = from_r(bytes, na_binary()),
  "large_binary" = from_r(bytes, na_large_binary()),
  "binary_view" = from_r(bytes, na_binary_view()),
  "fixed_size_binary(2)" = from_r(bytes, na_fixed_size_binary(2)),
  "date32" = from_r(as.Date("2024-01-10"), na_date32()),
  "date64" = from_r(as.Date("2024-01-10"), na_date64()),
  "time32('s')" = from_r(hms, na_time32("s")),
  "time32('ms')" = from_r(hms, na_time32("ms")),
  "time64('us')" = from_r(hms, na_time64("us")),
  "time64('ns')" = from_r(hms, na_time64("ns")),
  "timestamp('s')" = from_r(utc, na_timestamp("s")),
  "timestamp('ms')" = from_r(utc, na_timestamp("ms")),
  "timestamp('us')" = from_r(utc, na_timestamp("us")),
  "timestamp('ns')" = from_r(utc, na_timestamp("ns")),
  "timestamp('us', 'UTC')" = from_r(utc, na_timestamp("us", "UTC")),
  "timestamp('us', 'America/New_York')" = from_r(
    utc,
    na_timestamp("us", "America/New_York")
  ),
  "duration('s')" = from_r(as.difftime(90, units = "mins"), na_duration("s")),
  "duration('ms')" = from_r(as.difftime(90, units = "mins"), na_duration("ms")),
  "duration('us')" = from_r(as.difftime(90, units = "mins"), na_duration("us")),
  "duration('ns')" = from_r(as.difftime(90, units = "mins"), na_duration("ns")),
  # 3 months.
  "interval_months" = from_bytes(na_interval_months(), int32_le(3L)),
  # 2 days and 3000 milliseconds, two 32-bit fields.
  "interval_day_time" = from_bytes(na_interval_day_time(), int32_le(2L, 3000L)),
  "interval_month_day_nano" = from_duckdb(
    "SELECT INTERVAL '1 month 2 days 3 seconds' AS x"
  ),
  "list<int32>" = from_r(list(1:3), na_list(na_int32())),
  "large_list<int32>" = from_r(list(1:3), na_large_list(na_int32())),
  "list_view<int32>" = from_duckdb(
    "SELECT [1, 2, 3] AS x",
    c("SET arrow_output_version = '1.4'", "SET arrow_output_list_view = true")
  ),
  "fixed_size_list(3)<int32>" = from_r(
    list(1:3),
    na_fixed_size_list(na_int32(), 3)
  ),
  "struct<i: int32, j: string>" = from_r(
    data.frame(i = 42L, j = "duck"),
    na_struct(list(i = na_int32(), j = na_string()))
  ),
  # Arrow requires the keys of a map to be non-nullable.
  "map<string, int32>" = from_r(
    list(data.frame(key = c("a", "b"), value = 1:2)),
    na_map(na_string(nullable = FALSE), na_int32())
  ),
  "sparse_union<num: int32, str: string>" = from_r(
    data.frame(num = 2L, str = NA_character_),
    na_sparse_union(list(num = na_int32(), str = na_string()))
  ),
  "dense_union<num: int32, str: string>" = from_r(
    data.frame(num = 2L, str = NA_character_),
    na_dense_union(list(num = na_int32(), str = na_string()))
  ),
  "dictionary(int8)<string>" = from_r(
    factor("ok"),
    na_dictionary(na_string(), na_int8())
  ),
  "arrow.uuid" = function() {
    as_reader(nanoarrow_extension_array(
      as_nanoarrow_array(
        blob::blob(as.raw(1:16)),
        schema = na_fixed_size_binary(16)
      ),
      "arrow.uuid"
    ))
  },
  "arrow.json" = function() {
    as_reader(nanoarrow_extension_array(
      as_nanoarrow_array('{"a": 1}'),
      "arrow.json"
    ))
  },
  "arrow.bool8" = function() {
    as_reader(nanoarrow_extension_array(
      as_nanoarrow_array(1L, schema = na_int8()),
      "arrow.bool8"
    ))
  },
  "arrow.opaque<hugeint>" = from_duckdb(
    "SELECT 42::HUGEINT AS x",
    "SET arrow_lossless_conversion = true"
  ),
  "geoarrow.wkb" = function() {
    as_reader(as_nanoarrow_array(wk::as_wkb("POINT (1 2)")))
  },
  "geoarrow.point" = function() {
    as_reader(as_nanoarrow_array(
      wk::xy(1, 2),
      schema = geoarrow::geoarrow_native("POINT")
    ))
  }
)
print(
  data.frame(
    arrow = names(arrow_types),
    duckdb = vapply(arrow_types, function(f) cell(lands_as(f())), character(1))
  ),
  right = FALSE,
  row.names = FALSE
)

# --- Every R class, through each package's Arrow inference ----------------

values <- list(
  "logical" = TRUE,
  "integer" = 42L,
  "numeric" = 1.5,
  "character" = "duck",
  "factor" = factor("ok"),
  "ordered" = factor("ok", ordered = TRUE),
  "Date (double)" = as.Date("2024-01-10"),
  "Date (integer)" = structure(19732L, class = "Date"),
  "POSIXct (UTC)" = utc,
  "POSIXct (America/New_York)" = as.POSIXct(
    "2024-01-10 13:03:12",
    tz = "America/New_York"
  ),
  "POSIXct (no tzone)" = structure(
    as.numeric(utc),
    class = c("POSIXct", "POSIXt")
  ),
  "difftime (secs)" = as.difftime(90, units = "secs"),
  "difftime (days)" = as.difftime(2, units = "days"),
  "hms" = hms,
  "integer64" = bit64::as.integer64("9007199254740993"),
  "blob" = bytes,
  "list of raw" = list(as.raw(c(0xaa, 0xbb))),
  "list of integer" = list(1:3),
  "data.frame" = data.frame(i = 42L, j = "duck"),
  "matrix" = matrix(1:3, nrow = 1),
  "wk_wkb" = wk::as_wkb("POINT (1 2)")
)

# The column as a data frame of one column, however the value is shaped.
as_df <- function(v) {
  d <- data.frame(id = 1L)
  d$x <- v
  d["x"]
}
type_name <- function(schema) {
  out <- sub("^<nanoarrow_schema (.*)>$", "\\1", format(schema))
  ext <- schema$metadata[["ARROW:extension:name"]]
  if (is.null(ext)) out else paste0(ext, "<", out, ">")
}
by_dbwritetable <- function(v) {
  dbWriteTable(con, "w", as_df(v), overwrite = TRUE)
  r <- dbGetQuery(con, "SELECT typeof(x) AS t, x::VARCHAR AS v FROM w")
  paste(r$t, r$v)
}
by_nanoarrow <- function(v) {
  schema <- step("nanoarrow", infer_nanoarrow_schema(as_df(v)))
  reader <- step(
    "arrow",
    arrow::as_record_batch_reader(as_nanoarrow_array_stream(as_df(v)))
  )
  paste(type_name(schema$children$x), "->", lands_as(reader))
}
by_arrow <- function(v) {
  tbl <- step("arrow", arrow::arrow_table(as_df(v)))
  paste(tbl$schema$x$type$ToString(), "->", lands_as(tbl))
}
print(
  data.frame(
    r = names(values),
    dbWriteTable = vapply(
      values,
      function(v) cell(by_dbwritetable(v), 30),
      character(1)
    ),
    nanoarrow = vapply(
      values,
      function(v) cell(by_nanoarrow(v), 80),
      character(1)
    ),
    arrow = vapply(values, function(v) cell(by_arrow(v), 95), character(1))
  ),
  right = FALSE,
  row.names = FALSE
)

for (p in producers) {
  dbDisconnect(p, shutdown = TRUE)
}
dbDisconnect(con, shutdown = TRUE)
