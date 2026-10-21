``` r
# Arrow into DuckDB: every Arrow type, built in R and registered through
# duckdb_register_arrow(), with the DuckDB type and value it lands as; then
# every R class, through each package's Arrow inference, beside the type
# dbWriteTable() gives the same column.
# The recorded run is in.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
#> Loading required package: DBI
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
#>  arrow                                 duckdb                                                                
#>  na                                    "NULL" NA                                                             
#>  bool                                  BOOLEAN true                                                          
#>  int8                                  TINYINT 42                                                            
#>  int16                                 SMALLINT 42                                                           
#>  int32                                 INTEGER 42                                                            
#>  int64                                 BIGINT 42                                                             
#>  uint8                                 UTINYINT 42                                                           
#>  uint16                                USMALLINT 42                                                          
#>  uint32                                UINTEGER 42                                                           
#>  uint64                                UBIGINT 42                                                            
#>  half_float                            ERROR duckdb: Not implemented Error: Unsupported Internal Arrow Type e
#>  float                                 FLOAT 1.5                                                             
#>  double                                DOUBLE 1.5                                                            
#>  decimal32(9, 2)                       DECIMAL(9,2) 3.14                                                     
#>  decimal64(18, 3)                      DECIMAL(18,3) 3.142                                                   
#>  decimal128(38, 10)                    DECIMAL(38,10) 3.1415926535                                           
#>  decimal256(76, 10)                    ERROR duckdb: Not implemented Error: Unsupported Internal Arrow Typ...
#>  string                                VARCHAR duck                                                          
#>  large_string                          VARCHAR duck                                                          
#>  string_view                           VARCHAR duck                                                          
#>  binary                                BLOB \\xAA\\xBB                                                       
#>  large_binary                          BLOB \\xAA\\xBB                                                       
#>  binary_view                           BLOB \\xAA\\xBB                                                       
#>  fixed_size_binary(2)                  BLOB \\xAA\\xBB                                                       
#>  date32                                DATE 2024-01-10                                                       
#>  date64                                DATE 2024-01-10                                                       
#>  time32('s')                           TIME 13:03:12                                                         
#>  time32('ms')                          TIME 13:03:12.123                                                     
#>  time64('us')                          TIME 13:03:12.123456                                                  
#>  time64('ns')                          TIME_NS 13:03:12.123456                                               
#>  timestamp('s')                        TIMESTAMP_S 2024-01-10 13:03:12                                       
#>  timestamp('ms')                       TIMESTAMP_MS 2024-01-10 13:03:12.123                                  
#>  timestamp('us')                       TIMESTAMP 2024-01-10 13:03:12.123456                                  
#>  timestamp('ns')                       TIMESTAMP_NS 2024-01-10 13:03:12.123456                               
#>  timestamp('us', 'UTC')                TIMESTAMP WITH TIME ZONE 2024-01-10 13:03:12.123456+00                
#>  timestamp('us', 'America/New_York')   TIMESTAMP WITH TIME ZONE 2024-01-10 13:03:12.123456+00                
#>  duration('s')                         INTERVAL 01:30:00                                                     
#>  duration('ms')                        INTERVAL 01:30:00                                                     
#>  duration('us')                        INTERVAL 01:30:00                                                     
#>  duration('ns')                        INTERVAL 01:30:00                                                     
#>  interval_months                       INTERVAL 3 months                                                     
#>  interval_day_time                     INTERVAL 3579139:24:48.002                                            
#>  interval_month_day_nano               INTERVAL 1 month 2 days 00:00:03                                      
#>  list<int32>                           INTEGER[] [1, 2, 3]                                                   
#>  large_list<int32>                     INTEGER[] [1, 2, 3]                                                   
#>  list_view<int32>                      INTEGER[] [1, 2, 3]                                                   
#>  fixed_size_list(3)<int32>             INTEGER[3] [1, 2, 3]                                                  
#>  struct<i: int32, j: string>           STRUCT(i INTEGER, j VARCHAR) {'i': 42, 'j': duck}                     
#>  map<string, int32>                    MAP(VARCHAR, INTEGER) {a=1, b=2}                                      
#>  sparse_union<num: int32, str: string> UNION(num INTEGER, str VARCHAR) 2                                     
#>  dense_union<num: int32, str: string>  ERROR duckdb: Not implemented Error: Unsupported Internal Arrow Typ...
#>  dictionary(int8)<string>              VARCHAR ok                                                            
#>  arrow.uuid                            UUID 01020304-0506-0708-090a-0b0c0d0e0f10                             
#>  arrow.json                            JSON {"a": 1}                                                         
#>  arrow.bool8                           BOOLEAN true                                                          
#>  arrow.opaque<hugeint>                 HUGEINT 42                                                            
#>  geoarrow.wkb                          GEOMETRY POINT (1 2)                                                  
#>  geoarrow.point                        STRUCT(x DOUBLE, y DOUBLE) {'x': 1.0, 'y': 2.0}

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
#>  r                          dbWriteTable                         nanoarrow                                                                       
#>  logical                    BOOLEAN true                         bool -> BOOLEAN true                                                            
#>  integer                    INTEGER 42                           int32 -> INTEGER 42                                                             
#>  numeric                    DOUBLE 1.5                           double -> DOUBLE 1.5                                                            
#>  character                  VARCHAR duck                         string -> VARCHAR duck                                                          
#>  factor                     ENUM('ok') ok                        dictionary(int32)<string> -> VARCHAR ok                                         
#>  ordered                    ENUM('ok') ok                        ERROR arrow: ArrowSchemaViewInit(): ARROW_FLAG_DICTIONARY_ORDERED is only rel...
#>  Date (double)              DATE 2024-01-10                      date32 -> DATE 2024-01-10                                                       
#>  Date (integer)             DATE 2024-01-10                      date32 -> DATE 2024-01-10                                                       
#>  POSIXct (UTC)              TIMESTAMP 2024-01-10 13:03:...       timestamp('us', 'UTC') -> TIMESTAMP WITH TIME ZONE 2024-01-10 13:03:12.123456+00
#>  POSIXct (America/New_York) TIMESTAMP 2024-01-10 18:03:12        timestamp('us', 'America/New_York') -> TIMESTAMP WITH TIME ZONE 2024-01-10 18...
#>  POSIXct (no tzone)         TIMESTAMP 2024-01-10 13:03:...       timestamp('us', 'Etc/UTC') -> TIMESTAMP WITH TIME ZONE 2024-01-10 13:03:12.12...
#>  difftime (secs)            INTERVAL 00:01:30                    duration('us') -> INTERVAL 00:01:30                                             
#>  difftime (days)            INTERVAL 2 days                      duration('us') -> INTERVAL 48:00:00                                             
#>  hms                        INTERVAL 13:03:12.123456             time32('ms') -> TIME 13:03:12.123                                               
#>  integer64                  BIGINT 9007199254740993              int64 -> BIGINT 9007199254740993                                                
#>  blob                       BLOB \\xAA\\xBB                      binary -> BLOB \\xAA\\xBB                                                       
#>  list of raw                BLOB \\xAA\\xBB                      binary -> BLOB \\xAA\\xBB                                                       
#>  list of integer            INTEGER[] [1, 2, 3]                  ERROR nanoarrow: Can't infer Arrow type for object of class list                
#>  data.frame                 STRUCT(i INTEGER, j VARCHAR...       struct<i: int32, j: string> -> STRUCT(i INTEGER, j VARCHAR) {'i': 42, 'j': duck}
#>  matrix                     INTEGER[3] [1, 2, 3]                 fixed_size_list(3)<item: int32> -> INTEGER[3] [1, 2, 3]                         
#>  wk_wkb                     BLOB \\x01\\x01\\x00\\x00\\x00\\x... geoarrow.wkb<geoarrow.wkb{binary}> -> GEOMETRY POINT (1 2)                      
#>  arrow                                                                                                            
#>  bool -> BOOLEAN true                                                                                             
#>  int32 -> INTEGER 42                                                                                              
#>  double -> DOUBLE 1.5                                                                                             
#>  string -> VARCHAR duck                                                                                           
#>  dictionary<values=string, indices=int8> -> VARCHAR ok                                                            
#>  dictionary<values=string, indices=int8, ordered> -> VARCHAR ok                                                   
#>  date32[day] -> DATE 2024-01-10                                                                                   
#>  date32[day] -> DATE 2024-01-10                                                                                   
#>  timestamp[us, tz=UTC] -> TIMESTAMP WITH TIME ZONE 2024-01-10 13:03:12.123456+00                                  
#>  timestamp[us, tz=America/New_York] -> TIMESTAMP WITH TIME ZONE 2024-01-10 18:03:12+00                            
#>  timestamp[us, tz=Etc/UTC] -> TIMESTAMP WITH TIME ZONE 2024-01-10 13:03:12.123456+00                              
#>  duration[s] -> INTERVAL 00:01:30                                                                                 
#>  duration[s] -> INTERVAL 48:00:00                                                                                 
#>  time32[s] -> TIME 13:03:12                                                                                       
#>  int64 -> BIGINT 9007199254740993                                                                                 
#>  binary -> BLOB \\xAA\\xBB                                                                                        
#>  binary -> BLOB \\xAA\\xBB                                                                                        
#>  list<item: int32> -> INTEGER[] [1, 2, 3]                                                                         
#>  struct<i: int32, j: string> -> STRUCT(i INTEGER, j VARCHAR) {'i': 42, 'j': duck}                                 
#>  int32 -> INTEGER 1 | int32 -> INTEGER 2 | int32 -> INTEGER 3                                                     
#>  <wk_wkb[0]> -> BLOB \\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xF0?\\x00\\x00\\x00\\x00\\x00\\x0...

for (p in producers) {
  dbDisconnect(p, shutdown = TRUE)
}
dbDisconnect(con, shutdown = TRUE)
```

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-09-27
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  arrow         25.0.1     2026-08-23 [1] RSPM
#>  assertthat    0.2.1      2019-03-21 [1] RSPM
#>  bit           4.6.0      2025-03-06 [1] RSPM
#>  bit64         4.8.6      2026-09-01 [1] RSPM
#>  blob          1.3.0      2026-01-14 [1] RSPM
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9028 2026-09-27 [1] local
#>  evaluate      1.0.5      2025-08-27 [1] RSPM
#>  fastmap       1.2.0      2024-05-15 [1] RSPM
#>  fs            2.1.0      2026-04-18 [1] RSPM
#>  geoarrow    * 0.4.4      2026-09-16 [1] RSPM
#>  glue          1.8.1      2026-04-17 [1] RSPM
#>  hms           1.1.4      2025-10-17 [1] RSPM
#>  htmltools     0.5.9      2025-12-04 [1] RSPM
#>  knitr         1.52       2026-09-06 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  magrittr      2.0.5      2026-04-04 [1] RSPM
#>  nanoarrow   * 0.9.0      2026-08-04 [1] RSPM
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  pillar        1.11.1     2025-09-17 [1] RSPM
#>  pkgconfig     2.0.3      2019-09-22 [1] RSPM
#>  purrr         1.2.2      2026-04-10 [1] RSPM
#>  R6            2.6.1      2025-02-15 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.32       2026-09-01 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  tidyselect    1.2.1      2024-03-11 [1] RSPM
#>  vctrs         0.7.3      2026-04-11 [1] RSPM
#>  withr         3.0.3      2026-06-19 [1] RSPM
#>  wk            0.9.5      2025-12-18 [1] RSPM
#>  xfun          0.60       2026-07-09 [1] RSPM
#>  yaml          2.3.12     2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

</details>
