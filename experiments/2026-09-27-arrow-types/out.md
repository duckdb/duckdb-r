``` r
# Every DuckDB type out through Arrow: the Arrow type the engine exports it
# as, under each setting that changes that, and what nanoarrow and arrow make
# of it in R. Then values chosen to show where precision is lost.
# The recorded run is out.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
#> Loading required package: DBI
options(width = 250, digits = 17, digits.secs = 6)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

# The types, with a value of each: types.R.
source("types.R")

con <- dbConnect(duckdb())
for (e in c(unique(types$ext[types$ext != ""]), "icu")) {
  invisible(dbExecute(con, paste("INSTALL", e)))
  invisible(dbExecute(con, paste("LOAD", e)))
}

# The result, or the first line of the error, cut to fit a column.
cell <- function(expr, width = 60) {
  out <- tryCatch(
    expr,
    error = function(e) paste("ERROR:", gsub("\n.*", "", conditionMessage(e)))
  )
  if (nchar(out) > width) paste0(substr(out, 1, width - 3), "...") else out
}

# One column, one row, as a stream.
one <- function(lit) dbGetQueryArrow(con, paste("SELECT", lit, "AS x"))

# The Arrow type of a field as nanoarrow spells it, with the extension it
# carries, and for arrow.opaque the DuckDB type it stands for.
arrow_type <- function(sch) {
  out <- sub("^<nanoarrow_schema (.*)>$", "\\1", format(sch))
  ext <- sch$metadata[["ARROW:extension:name"]]
  if (!is.null(ext)) {
    if (ext == "arrow.opaque") {
      meta <- jsonlite::fromJSON(sch$metadata[["ARROW:extension:metadata"]])
      ext <- paste0(ext, "<", meta$type_name, ">")
    }
    out <- paste0(ext, "<", out, ">")
  }
  out
}

# An R value in one line: its class, then its first element.
r_value <- function(x) {
  first <- function(v) {
    if (is.data.frame(v)) {
      inner <- vapply(v, first, character(1))
      return(paste0(
        "{",
        paste(names(v), inner, sep = "=", collapse = ", "),
        "}"
      ))
    }
    if (is.list(v) && !inherits(v, "blob")) {
      e <- v[[1]]
      return(paste0("[", paste(format(e), collapse = " "), "]"))
    }
    format(v[1])
  }
  cls <- class(x)[1]
  if (is.list(x) && !is.data.frame(x) && !inherits(x, "blob")) {
    cls <- paste0(cls, "<", class(x[[1]])[1], ">")
  }
  paste0(cls, " ", first(x))
}

# The field's Arrow type, then R through each reader.
exported <- function(lit) {
  s <- one(lit)
  on.exit(s$release())
  arrow_type(s$get_schema()$children$x)
}
via_nanoarrow <- function(lit) r_value(as.data.frame(one(lit))$x)
via_arrow <- function(lit) {
  r_value(as.data.frame(arrow::as_arrow_table(one(lit)))$x)
}

each <- function(f, lits = types$lit) {
  vapply(lits, function(lit) cell(f(lit)), character(1), USE.NAMES = FALSE)
}

# --- Before geoarrow is loaded -----------------------------------------

# geoarrow registers geoarrow.wkb with both readers when its namespace loads;
# until then, both read the storage.
geometry <- "'POINT (1 2)'::GEOMETRY"
c(
  nanoarrow = cell(via_nanoarrow(geometry)),
  arrow = cell(via_arrow(geometry)),
  geoarrow_loaded = "geoarrow" %in% loadedNamespaces()
)
#>                 nanoarrow                     arrow           geoarrow_loaded 
#>         "blob blob[21 B]" "arrow_binary blob[21 B]"                   "FALSE"
library(geoarrow)

# arrow converts an int64 column to integer when every value fits, and to
# integer64 otherwise; the option makes it integer64 always.
local({
  withr::local_options(arrow.int64_downcast = FALSE)
  c(
    small = cell(via_arrow("42::BIGINT")),
    large = cell(via_arrow("9007199254740993::BIGINT"))
  )
})
#>                        small                        large 
#>               "integer64 42" "integer64 9007199254740993"

# --- The Arrow type of each DuckDB type ------------------------------

default <- each(exported)
invisible(dbExecute(con, "SET arrow_lossless_conversion = true"))
lossless <- each(exported)
invisible(dbExecute(con, "RESET arrow_lossless_conversion"))

print(
  data.frame(type = types$type, default = default, lossless = lossless),
  right = FALSE,
  row.names = FALSE
)
#>  type                            default                                                      lossless                                                    
#>  BOOLEAN                         bool                                                         arrow.bool8<arrow.bool8{int8}>                              
#>  TINYINT                         int8                                                         int8                                                        
#>  SMALLINT                        int16                                                        int16                                                       
#>  INTEGER                         int32                                                        int32                                                       
#>  BIGINT                          int64                                                        int64                                                       
#>  HUGEINT                         decimal128(38, 0)                                            arrow.opaque<hugeint><arrow.opaque{fixed_size_binary(16)}>  
#>  UTINYINT                        uint8                                                        uint8                                                       
#>  USMALLINT                       uint16                                                       uint16                                                      
#>  UINTEGER                        uint32                                                       uint32                                                      
#>  UBIGINT                         uint64                                                       uint64                                                      
#>  UHUGEINT                        decimal128(38, 0)                                            arrow.opaque<uhugeint><arrow.opaque{fixed_size_binary(16)}> 
#>  BIGNUM                          arrow.opaque<bignum><arrow.opaque{binary}>                   arrow.opaque<bignum><arrow.opaque{binary}>                  
#>  DECIMAL(4,1)                    decimal128(4, 1)                                             decimal128(4, 1)                                            
#>  DECIMAL(18,3)                   decimal128(18, 3)                                            decimal128(18, 3)                                           
#>  DECIMAL(38,10)                  decimal128(38, 10)                                           decimal128(38, 10)                                          
#>  FLOAT                           float                                                        float                                                       
#>  DOUBLE                          double                                                       double                                                      
#>  VARCHAR                         string                                                       string                                                      
#>  BLOB                            binary                                                       binary                                                      
#>  BIT                             binary                                                       arrow.opaque<bit><arrow.opaque{binary}>                     
#>  UUID                            string                                                       arrow.uuid<arrow.uuid{fixed_size_binary(16)}>               
#>  DATE                            date32                                                       date32                                                      
#>  TIME                            time64('us')                                                 time64('us')                                                
#>  TIME_NS                         time64('ns')                                                 time64('ns')                                                
#>  TIMETZ                          time64('us')                                                 arrow.opaque<time_tz><arrow.opaque{fixed_size_binary(8)}>   
#>  TIMESTAMP_S                     timestamp('s', '')                                           timestamp('s', '')                                          
#>  TIMESTAMP_MS                    timestamp('ms', '')                                          timestamp('ms', '')                                         
#>  TIMESTAMP                       timestamp('us', '')                                          timestamp('us', '')                                         
#>  TIMESTAMP_NS                    timestamp('ns', '')                                          timestamp('ns', '')                                         
#>  TIMESTAMPTZ                     timestamp('us', 'Etc/UTC')                                   timestamp('us', 'Etc/UTC')                                  
#>  INTERVAL                        interval_month_day_nano                                      interval_month_day_nano                                     
#>  ENUM('sad', 'ok', 'happy')      dictionary(uint8)<string>                                    dictionary(uint8)<string>                                   
#>  GEOMETRY                        geoarrow.wkb<geoarrow.wkb{binary}>                           geoarrow.wkb<geoarrow.wkb{binary}>                          
#>  NULL                            int32                                                        int32                                                       
#>  INTEGER[3]                      fixed_size_list(3)<: int32>                                  fixed_size_list(3)<: int32>                                 
#>  INTEGER[]                       list<l: int32>                                               list<l: int32>                                              
#>  MAP(VARCHAR, INTEGER)           map<entries: struct<key: string, value: int32>>              map<entries: struct<key: string, value: int32>>             
#>  STRUCT(i INTEGER, j VARCHAR)    struct<i: int32, j: string>                                  struct<i: int32, j: string>                                 
#>  UNION(num INTEGER, str VARCHAR) sparse_union([0,1])<num: int32, str: string>                 sparse_union([0,1])<num: int32, str: string>                
#>  VARIANT                         ERROR: array_stream->get_schema(): [-1] Not implemented E... ERROR: array_stream->get_schema(): [-1] Not implemented E...
#>  JSON                            string                                                       arrow.json<arrow.json{string}>                              
#>  INET                            struct<ip_type: uint8, address: decimal128(38, 0), mask: ... struct<ip_type: uint8, address: arrow.opaque{fixed_size_b...
#>  POINT_2D                        struct<x: double, y: double>                                 struct<x: double, y: double>                                
#>  POINT_3D                        struct<x: double, y: double, z: double>                      struct<x: double, y: double, z: double>                     
#>  POINT_4D                        struct<x: double, y: double, z: double, m: double>           struct<x: double, y: double, z: double, m: double>          
#>  LINESTRING_2D                   list<l: struct<x: double, y: double>>                        list<l: struct<x: double, y: double>>                       
#>  LINESTRING_3D                   list<l: struct<x: double, y: double, z: double>>             list<l: struct<x: double, y: double, z: double>>            
#>  POLYGON_2D                      list<l: list<l: struct<x: double, y: double>>>               list<l: list<l: struct<x: double, y: double>>>              
#>  POLYGON_3D                      list<l: list<l: struct<x: double, y: double, z: double>>>    list<l: list<l: struct<x: double, y: double, z: double>>>   
#>  BOX_2D                          struct<min_x: double, min_y: double, max_x: double, max_y... struct<min_x: double, min_y: double, max_x: double, max_y...
#>  BOX_2DF                         struct<min_x: float, min_y: float, max_x: float, max_y: f... struct<min_x: float, min_y: float, max_x: float, max_y: f...
#>  WKB_BLOB                        binary                                                       binary

# --- What R receives, with the default export ------------------------

print(
  data.frame(
    type = types$type,
    nanoarrow = each(via_nanoarrow),
    arrow = each(via_arrow)
  ),
  right = FALSE,
  row.names = FALSE
)
#> Warning in convert_array_stream(x, to): 1 value(s) may have incurred loss of precision in conversion to double()
#>  type                            nanoarrow                                                    arrow                                                       
#>  BOOLEAN                         logical TRUE                                                 logical TRUE                                                
#>  TINYINT                         integer 42                                                   integer 42                                                  
#>  SMALLINT                        integer 42                                                   integer 42                                                  
#>  INTEGER                         integer 42                                                   integer 42                                                  
#>  BIGINT                          numeric 42                                                   integer 42                                                  
#>  HUGEINT                         numeric 42                                                   numeric 42                                                  
#>  UTINYINT                        integer 42                                                   integer 42                                                  
#>  USMALLINT                       integer 42                                                   integer 42                                                  
#>  UINTEGER                        numeric 42                                                   integer 42                                                  
#>  UBIGINT                         numeric 42                                                   numeric 42                                                  
#>  UHUGEINT                        numeric 42                                                   numeric 42                                                  
#>  BIGNUM                          blob blob[4 B]                                               ERROR: Converter_Extension can't be used with a non-R ext...
#>  DECIMAL(4,1)                    numeric 3.1000000000000001                                   numeric 3.1000000000000001                                  
#>  DECIMAL(18,3)                   numeric 3.1419999999999999                                   numeric 3.1419999999999999                                  
#>  DECIMAL(38,10)                  numeric 3.1415926535000001                                   numeric 3.1415926535000001                                  
#>  FLOAT                           numeric 1.5                                                  numeric 1.5                                                 
#>  DOUBLE                          numeric 1.5                                                  numeric 1.5                                                 
#>  VARCHAR                         character duck                                               character duck                                              
#>  BLOB                            blob blob[2 B]                                               arrow_binary blob[2 B]                                      
#>  BIT                             blob blob[2 B]                                               arrow_binary blob[2 B]                                      
#>  UUID                            character 4ac7a9e9-607c-4c8a-84f3-843f0191e3fd               character 4ac7a9e9-607c-4c8a-84f3-843f0191e3fd              
#>  DATE                            Date 2024-01-10                                              Date 2024-01-10                                             
#>  TIME                            hms 13:03:12.123456                                          hms 13:03:12.123456                                         
#>  TIME_NS                         hms 13:03:12.123456                                          hms 13:03:12.123456                                         
#>  TIMETZ                          hms 13:03:12.123456                                          hms 13:03:12.123456                                         
#>  TIMESTAMP_S                     POSIXct 2024-01-10 13:03:12                                  POSIXct 2024-01-10 13:03:12                                 
#>  TIMESTAMP_MS                    POSIXct 2024-01-10 13:03:12.123                              POSIXct 2024-01-10 13:03:12.122999                          
#>  TIMESTAMP                       POSIXct 2024-01-10 13:03:12.123456                           POSIXct 2024-01-10 13:03:12.123456                          
#>  TIMESTAMP_NS                    POSIXct 2024-01-10 13:03:12.123456                           POSIXct 2024-01-10 13:03:12.123456                          
#>  TIMESTAMPTZ                     POSIXct 2024-01-10 13:03:12.123456                           POSIXct 2024-01-10 13:03:12.123456                          
#>  INTERVAL                        ERROR: Can't infer R vector type for `x` <interval_month_... ERROR: cannot handle Array of type <month_day_nano_interval>
#>  ENUM('sad', 'ok', 'happy')      character ok                                                 factor ok                                                   
#>  GEOMETRY                        geoarrow_vctr <POINT (1 2)>                                  geoarrow_vctr <POINT (1 2)>                                 
#>  NULL                            integer NA                                                   integer NA                                                  
#>  INTEGER[3]                      vctrs_list_of<integer> [1 2 3]                               arrow_fixed_size_list<integer> [1 2 3]                      
#>  INTEGER[]                       vctrs_list_of<integer> [1 2 3]                               arrow_list<integer> [1 2 3]                                 
#>  MAP(VARCHAR, INTEGER)           vctrs_list_of<data.frame> [c("a", "b") c("1", "2")]          arrow_list<tbl_df> [c("a", "b") c("1", "2")]                
#>  STRUCT(i INTEGER, j VARCHAR)    data.frame {i=42, j=duck}                                    tbl_df {i=42, j=duck}                                       
#>  UNION(num INTEGER, str VARCHAR) data.frame {num=2, str=NA}                                   ERROR: cannot handle Array of type <sparse_union>           
#>  VARIANT                         ERROR: array_stream->get_schema(): [-1] Not implemented E... ERROR: IOError: Not implemented Error: Unsupported Arrow ...
#>  JSON                            character {"a": 1}                                           character {"a": 1}                                          
#>  INET                            data.frame {ip_type=1, address=2130706433, mask=32}          tbl_df {ip_type=1, address=2130706433, mask=32}             
#>  POINT_2D                        data.frame {x=1, y=2}                                        tbl_df {x=1, y=2}                                           
#>  POINT_3D                        data.frame {x=1, y=2, z=3}                                   tbl_df {x=1, y=2, z=3}                                      
#>  POINT_4D                        data.frame {x=1, y=2, z=3, m=4}                              tbl_df {x=1, y=2, z=3, m=4}                                 
#>  LINESTRING_2D                   vctrs_list_of<data.frame> [c("0", "1") c("0", "1")]          arrow_list<tbl_df> [c("0", "1") c("0", "1")]                
#>  LINESTRING_3D                   vctrs_list_of<data.frame> [c("0", "1") c("0", "1") c("0",... arrow_list<tbl_df> [c("0", "1") c("0", "1") c("0", "1")]    
#>  POLYGON_2D                      vctrs_list_of<vctrs_list_of> [0, 1, 0, 0, 0, 0]              arrow_list<arrow_list> [0, 1, 0, 0, 0, 0]                   
#>  POLYGON_3D                      vctrs_list_of<vctrs_list_of> [0, 1, 0, 0, 0, 0, 0, 0, 0]     arrow_list<arrow_list> [0, 1, 0, 0, 0, 0, 0, 0, 0]          
#>  BOX_2D                          data.frame {min_x=0, min_y=0, max_x=1, max_y=1}              tbl_df {min_x=0, min_y=0, max_x=1, max_y=1}                 
#>  BOX_2DF                         data.frame {min_x=0, min_y=0, max_x=1, max_y=1}              tbl_df {min_x=0, min_y=0, max_x=1, max_y=1}                 
#>  WKB_BLOB                        blob blob[21 B]                                              arrow_binary blob[21 B]

# --- What R receives where arrow_lossless_conversion changes the type -

changed <- default != lossless
invisible(dbExecute(con, "SET arrow_lossless_conversion = true"))
print(
  data.frame(
    type = types$type[changed],
    nanoarrow = each(via_nanoarrow, types$lit[changed]),
    arrow = each(via_arrow, types$lit[changed])
  ),
  right = FALSE,
  row.names = FALSE
)
#>  type     nanoarrow                                                    arrow                                                       
#>  BOOLEAN  integer 1                                                    ERROR: Converter_Extension can't be used with a non-R ext...
#>  HUGEINT  ERROR: Can't infer R vector type for `x` <fixed_size_bina... ERROR: Converter_Extension can't be used with a non-R ext...
#>  UHUGEINT ERROR: Can't infer R vector type for `x` <fixed_size_bina... ERROR: Converter_Extension can't be used with a non-R ext...
#>  BIT      blob blob[2 B]                                               ERROR: Converter_Extension can't be used with a non-R ext...
#>  UUID     ERROR: Can't infer R vector type for `x` <fixed_size_bina... ERROR: Converter_Extension can't be used with a non-R ext...
#>  TIMETZ   ERROR: Can't infer R vector type for `x` <fixed_size_bina... ERROR: Converter_Extension can't be used with a non-R ext...
#>  JSON     character {"a": 1}                                           ERROR: Converter_Extension can't be used with a non-R ext...
#>  INET     ERROR: Can't infer R vector type for `address` <fixed_siz... ERROR: Converter_Extension can't be used with a non-R ext...
invisible(dbExecute(con, "RESET arrow_lossless_conversion"))

# --- The other settings: which types they change, and to what --------

# The view layouts need arrow_output_version 1.4 or later: set alone, the two
# switches for them change nothing.
settings <- list(
  "arrow_large_buffer_size" = "SET arrow_large_buffer_size = true",
  "produce_arrow_string_view alone" = "SET produce_arrow_string_view = true",
  "arrow_output_list_view alone" = "SET arrow_output_list_view = true",
  "arrow_output_version 1.4" = "SET arrow_output_version = '1.4'",
  "1.4, produce_arrow_string_view" = c(
    "SET arrow_output_version = '1.4'",
    "SET produce_arrow_string_view = true"
  ),
  "1.4, arrow_output_list_view" = c(
    "SET arrow_output_version = '1.4'",
    "SET arrow_output_list_view = true"
  ),
  "arrow_output_version 1.5" = "SET arrow_output_version = '1.5'"
)
reset <- function() {
  for (name in c(
    "arrow_large_buffer_size",
    "produce_arrow_string_view",
    "arrow_output_list_view",
    "arrow_output_version"
  )) {
    invisible(dbExecute(con, paste("RESET", name)))
  }
}
rows <- lapply(names(settings), function(label) {
  for (sql in settings[[label]]) {
    invisible(dbExecute(con, sql))
  }
  on.exit(reset())
  now <- each(exported)
  moved <- now != default
  if (!any(moved)) {
    return(data.frame(
      setting = label,
      type = "(none)",
      arrow = "",
      nanoarrow = "",
      arrow_pkg = ""
    ))
  }
  data.frame(
    setting = label,
    type = types$type[moved],
    arrow = now[moved],
    nanoarrow = each(via_nanoarrow, types$lit[moved]),
    arrow_pkg = each(via_arrow, types$lit[moved])
  )
})
print(do.call(rbind, rows), right = FALSE, row.names = FALSE)
#>  setting                         type                            arrow                                                        nanoarrow                                                    arrow_pkg                                                   
#>  arrow_large_buffer_size         BIGNUM                          arrow.opaque<bignum><arrow.opaque{large_binary}>             blob blob[4 B]                                               ERROR: Converter_Extension can't be used with a non-R ext...
#>  arrow_large_buffer_size         VARCHAR                         large_string                                                 character duck                                               character duck                                              
#>  arrow_large_buffer_size         BLOB                            large_binary                                                 blob blob[2 B]                                               arrow_large_binary blob[2 B]                                
#>  arrow_large_buffer_size         BIT                             large_binary                                                 blob blob[2 B]                                               arrow_large_binary blob[2 B]                                
#>  arrow_large_buffer_size         UUID                            large_string                                                 character 4ac7a9e9-607c-4c8a-84f3-843f0191e3fd               character 4ac7a9e9-607c-4c8a-84f3-843f0191e3fd              
#>  arrow_large_buffer_size         GEOMETRY                        geoarrow.wkb<geoarrow.wkb{large_binary}>                     geoarrow_vctr <POINT (1 2)>                                  geoarrow_vctr <POINT (1 2)>                                 
#>  arrow_large_buffer_size         INTEGER[]                       large_list<l: int32>                                         vctrs_list_of<integer> [1 2 3]                               arrow_large_list<integer> [1 2 3]                           
#>  arrow_large_buffer_size         MAP(VARCHAR, INTEGER)           map<entries: struct<key: large_string, value: int32>>        vctrs_list_of<data.frame> [c("a", "b") c("1", "2")]          arrow_list<tbl_df> [c("a", "b") c("1", "2")]                
#>  arrow_large_buffer_size         STRUCT(i INTEGER, j VARCHAR)    struct<i: int32, j: large_string>                            data.frame {i=42, j=duck}                                    tbl_df {i=42, j=duck}                                       
#>  arrow_large_buffer_size         UNION(num INTEGER, str VARCHAR) sparse_union([0,1])<num: int32, str: large_string>           data.frame {num=2, str=NA}                                   ERROR: cannot handle Array of type <sparse_union>           
#>  arrow_large_buffer_size         JSON                            large_string                                                 character {"a": 1}                                           character {"a": 1}                                          
#>  arrow_large_buffer_size         LINESTRING_2D                   large_list<l: struct<x: double, y: double>>                  vctrs_list_of<data.frame> [c("0", "1") c("0", "1")]          arrow_large_list<tbl_df> [c("0", "1") c("0", "1")]          
#>  arrow_large_buffer_size         LINESTRING_3D                   large_list<l: struct<x: double, y: double, z: double>>       vctrs_list_of<data.frame> [c("0", "1") c("0", "1") c("0",... arrow_large_list<tbl_df> [c("0", "1") c("0", "1") c("0", ...
#>  arrow_large_buffer_size         POLYGON_2D                      large_list<l: large_list<l: struct<x: double, y: double>>>   vctrs_list_of<vctrs_list_of> [0, 1, 0, 0, 0, 0]              arrow_large_list<arrow_large_list> [0, 1, 0, 0, 0, 0]       
#>  arrow_large_buffer_size         POLYGON_3D                      large_list<l: large_list<l: struct<x: double, y: double, ... vctrs_list_of<vctrs_list_of> [0, 1, 0, 0, 0, 0, 0, 0, 0]     arrow_large_list<arrow_large_list> [0, 1, 0, 0, 0, 0, 0, ...
#>  arrow_large_buffer_size         WKB_BLOB                        large_binary                                                 blob blob[21 B]                                              arrow_large_binary blob[21 B]                               
#>  produce_arrow_string_view alone (none)                                                                                                                                                                                                                
#>  arrow_output_list_view alone    (none)                                                                                                                                                                                                                
#>  arrow_output_version 1.4        BIGNUM                          arrow.opaque<bignum><arrow.opaque{binary_view}>              blob blob[4 B]                                               ERROR: Converter_Extension can't be used with a non-R ext...
#>  arrow_output_version 1.4        BLOB                            binary_view                                                  blob blob[2 B]                                               ERROR: cannot handle Array of type <binary_view>            
#>  arrow_output_version 1.4        BIT                             binary_view                                                  blob blob[2 B]                                               ERROR: cannot handle Array of type <binary_view>            
#>  arrow_output_version 1.4        GEOMETRY                        geoarrow.wkb<geoarrow.wkb{binary_view}>                      geoarrow_vctr <POINT (1 2)>                                  geoarrow_vctr <POINT (1 2)>                                 
#>  arrow_output_version 1.4        WKB_BLOB                        binary_view                                                  blob blob[21 B]                                              ERROR: cannot handle Array of type <binary_view>            
#>  1.4, produce_arrow_string_view  BIGNUM                          arrow.opaque<bignum><arrow.opaque{binary_view}>              blob blob[4 B]                                               ERROR: Converter_Extension can't be used with a non-R ext...
#>  1.4, produce_arrow_string_view  VARCHAR                         string_view                                                  character duck                                               ERROR: cannot handle Array of type <utf8_view>              
#>  1.4, produce_arrow_string_view  BLOB                            binary_view                                                  blob blob[2 B]                                               ERROR: cannot handle Array of type <binary_view>            
#>  1.4, produce_arrow_string_view  BIT                             binary_view                                                  blob blob[2 B]                                               ERROR: cannot handle Array of type <binary_view>            
#>  1.4, produce_arrow_string_view  GEOMETRY                        geoarrow.wkb<geoarrow.wkb{binary_view}>                      geoarrow_vctr <POINT (1 2)>                                  geoarrow_vctr <POINT (1 2)>                                 
#>  1.4, produce_arrow_string_view  MAP(VARCHAR, INTEGER)           map<entries: struct<key: string_view, value: int32>>         vctrs_list_of<data.frame> [c("a", "b") c("1", "2")]          ERROR: cannot handle Array of type <utf8_view>              
#>  1.4, produce_arrow_string_view  STRUCT(i INTEGER, j VARCHAR)    struct<i: int32, j: string_view>                             data.frame {i=42, j=duck}                                    ERROR: cannot handle Array of type <utf8_view>              
#>  1.4, produce_arrow_string_view  UNION(num INTEGER, str VARCHAR) sparse_union([0,1])<num: int32, str: string_view>            data.frame {num=2, str=NA}                                   ERROR: cannot handle Array of type <sparse_union>           
#>  1.4, produce_arrow_string_view  JSON                            string_view                                                  character {"a": 1}                                           ERROR: cannot handle Array of type <utf8_view>              
#>  1.4, produce_arrow_string_view  WKB_BLOB                        binary_view                                                  blob blob[21 B]                                              ERROR: cannot handle Array of type <binary_view>            
#>  1.4, arrow_output_list_view     BIGNUM                          arrow.opaque<bignum><arrow.opaque{binary_view}>              blob blob[4 B]                                               ERROR: Converter_Extension can't be used with a non-R ext...
#>  1.4, arrow_output_list_view     BLOB                            binary_view                                                  blob blob[2 B]                                               ERROR: cannot handle Array of type <binary_view>            
#>  1.4, arrow_output_list_view     BIT                             binary_view                                                  blob blob[2 B]                                               ERROR: cannot handle Array of type <binary_view>            
#>  1.4, arrow_output_list_view     GEOMETRY                        geoarrow.wkb<geoarrow.wkb{binary_view}>                      geoarrow_vctr <POINT (1 2)>                                  geoarrow_vctr <POINT (1 2)>                                 
#>  1.4, arrow_output_list_view     INTEGER[]                       list_view<l: int32>                                          ERROR: Can't infer R vector type for `x` <list_view<l: in... ERROR: cannot handle Array of type <list_view>              
#>  1.4, arrow_output_list_view     LINESTRING_2D                   list_view<l: struct<x: double, y: double>>                   ERROR: Can't infer R vector type for `x` <list_view<l: st... ERROR: cannot handle Array of type <list_view>              
#>  1.4, arrow_output_list_view     LINESTRING_3D                   list_view<l: struct<x: double, y: double, z: double>>        ERROR: Can't infer R vector type for `x` <list_view<l: st... ERROR: cannot handle Array of type <list_view>              
#>  1.4, arrow_output_list_view     POLYGON_2D                      list_view<l: list_view<l: struct<x: double, y: double>>>     ERROR: Can't infer R vector type for `x` <list_view<l: li... ERROR: cannot handle Array of type <list_view>              
#>  1.4, arrow_output_list_view     POLYGON_3D                      list_view<l: list_view<l: struct<x: double, y: double, z:... ERROR: Can't infer R vector type for `x` <list_view<l: li... ERROR: cannot handle Array of type <list_view>              
#>  1.4, arrow_output_list_view     WKB_BLOB                        binary_view                                                  blob blob[21 B]                                              ERROR: cannot handle Array of type <binary_view>            
#>  arrow_output_version 1.5        BIGNUM                          arrow.opaque<bignum><arrow.opaque{binary_view}>              blob blob[4 B]                                               ERROR: Converter_Extension can't be used with a non-R ext...
#>  arrow_output_version 1.5        DECIMAL(4,1)                    decimal32(4, 1)                                              numeric 3.1000000000000001                                   numeric 3.1000000000000001                                  
#>  arrow_output_version 1.5        DECIMAL(18,3)                   decimal64(18, 3)                                             numeric 3.1419999999999999                                   numeric 3.1419999999999999                                  
#>  arrow_output_version 1.5        BLOB                            binary_view                                                  blob blob[2 B]                                               ERROR: cannot handle Array of type <binary_view>            
#>  arrow_output_version 1.5        BIT                             binary_view                                                  blob blob[2 B]                                               ERROR: cannot handle Array of type <binary_view>            
#>  arrow_output_version 1.5        GEOMETRY                        geoarrow.wkb<geoarrow.wkb{binary_view}>                      geoarrow_vctr <POINT (1 2)>                                  geoarrow_vctr <POINT (1 2)>                                 
#>  arrow_output_version 1.5        WKB_BLOB                        binary_view                                                  blob blob[21 B]                                              ERROR: cannot handle Array of type <binary_view>

# --- Precision: values where the reader decides what survives --------

# The text is the engine's own rendering, and the reference.
stress <- c(
  "UINTEGER" = "4294967295::UINTEGER",
  "BIGINT" = "9007199254740993::BIGINT",
  "UBIGINT" = "18446744073709551615::UBIGINT",
  "HUGEINT" = "170141183460469231731687303715884105727::HUGEINT",
  "UHUGEINT" = "340282366920938463463374607431768211455::UHUGEINT",
  "DECIMAL(38,10)" = "1234567890123456789012345678.1234567891::DECIMAL(38,10)",
  "TIME_NS" = "'13:03:12.123456789'::TIME_NS",
  "TIMESTAMP_NS" = "TIMESTAMP_NS '2024-01-10 13:03:12.123456789'",
  "TIMESTAMP" = "TIMESTAMP '1677-01-01 00:00:00.000001'",
  "TIMESTAMP (infinity)" = "'infinity'::TIMESTAMP",
  "DATE (infinity)" = "'infinity'::DATE",
  "INTERVAL" = "INTERVAL '1 month 2 days 3.000004 seconds'"
)
print(
  data.frame(
    value = names(stress),
    text = vapply(
      stress,
      function(lit) {
        cell(dbGetQuery(con, paste0("SELECT (", lit, ")::VARCHAR"))[[1]])
      },
      character(1)
    ),
    nanoarrow = each(via_nanoarrow, stress),
    arrow = each(via_arrow, stress)
  ),
  right = FALSE,
  row.names = FALSE
)
#> Warning in convert_array_stream(x, to): 1 value(s) may have incurred loss of precision in conversion to double()
#> Warning in convert_array_stream(x, to): 1 value(s) may have incurred loss of precision in conversion to double()
#> Warning in convert_array_stream(x, to): 1 value(s) may have incurred loss of precision in conversion to double()
#> Warning in convert_array_stream(x, to): 1 value(s) may have incurred loss of precision in conversion to double()
#>  value                text                                    nanoarrow                                                    arrow                                                       
#>  UINTEGER             4294967295                              numeric 4294967295                                           numeric 4294967295                                          
#>  BIGINT               9007199254740993                        numeric 9007199254740992                                     integer64 9007199254740993                                  
#>  UBIGINT              18446744073709551615                    numeric 18446744073709551616                                 numeric 18446744073709551616                                
#>  HUGEINT              170141183460469231731687303715884105727 numeric 1.7014118346046923e+38                               numeric 1.7014118346046923e+38                              
#>  UHUGEINT             340282366920938463463374607431768211455 numeric -1                                                   numeric -1                                                  
#>  DECIMAL(38,10)       1234567890123456789012345678.1234567891 numeric 1.2345678901234569e+27                               numeric 1.2345678901234569e+27                              
#>  TIME_NS              13:03:12.123456789                      hms 13:03:12.123457                                          hms 13:03:12.123457                                         
#>  TIMESTAMP_NS         2024-01-10 13:03:12.123456789           POSIXct 2024-01-10 13:03:12.123456                           POSIXct 2024-01-10 13:03:12.123456                          
#>  TIMESTAMP            1677-01-01 00:00:00.000001              POSIXct 1677-01-01                                           POSIXct 1677-01-01                                          
#>  TIMESTAMP (infinity) infinity                                POSIXct 294247-01-10 04:00:54.77539                          POSIXct 294247-01-10 04:00:54.77539                         
#>  DATE (infinity)      infinity                                Date 5881580-07-11                                           Date 5881580-07-11                                          
#>  INTERVAL             1 month 2 days 00:00:03.000004          ERROR: Can't infer R vector type for `x` <interval_month_... ERROR: cannot handle Array of type <month_day_nano_interval>

# --- Time zones: the label each reader gives a timestamp -----------------

# R's zone and DuckDB's TimeZone differ on purpose, so that each label shows
# which of the two it came from; the instant is 13:03:12 UTC in every row.
local({
  withr::local_timezone("America/New_York")
  invisible(dbExecute(con, "SET TimeZone = 'America/Los_Angeles'"))
  on.exit(invisible(dbExecute(con, "RESET TimeZone")))
  label <- function(x) {
    tz <- attr(x, "tzone")
    paste0(
      if (is.null(tz)) "tzone unset" else paste0("tzone '", tz, "'"),
      ", ",
      format(x, usetz = TRUE)
    )
  }
  lits <- c(
    "TIMESTAMP" = "TIMESTAMP '2024-01-10 13:03:12'",
    "TIMESTAMPTZ" = "TIMESTAMPTZ '2024-01-10 13:03:12+00'"
  )
  print(
    data.frame(
      type = names(lits),
      arrow_type = each(exported, lits),
      nanoarrow = each(function(l) label(as.data.frame(one(l))$x), lits),
      arrow = each(
        function(l) label(as.data.frame(arrow::as_arrow_table(one(l)))$x),
        lits
      )
    ),
    right = FALSE,
    row.names = FALSE
  )
})
#>  type        arrow_type                             nanoarrow                                            arrow                                               
#>  TIMESTAMP   timestamp('us', '')                    tzone 'UTC', 2024-01-10 13:03:12 UTC                 tzone unset, 2024-01-10 08:03:12 EST                
#>  TIMESTAMPTZ timestamp('us', 'America/Los_Angeles') tzone 'America/Los_Angeles', 2024-01-10 05:03:12 PST tzone 'America/Los_Angeles', 2024-01-10 05:03:12 PST

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
#>  tz       America/New_York
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
#>  jsonlite      2.0.0      2025-03-27 [1] RSPM
#>  knitr         1.52       2026-09-06 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  magrittr      2.0.5      2026-04-04 [1] RSPM
#>  nanoarrow     0.9.0      2026-08-04 [1] RSPM
#>  otel          0.2.0      2025-08-29 [1] RSPM
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
