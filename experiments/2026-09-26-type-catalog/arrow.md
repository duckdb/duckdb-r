``` r
# Every DuckDB type through Arrow: the field an Arrow result carries, and
# whether registering that stream back lands the same type and value, with
# the engine's default Arrow export and with arrow_lossless_conversion.
# Then the Arrow types an R user can build for the types R has no class for.
# The recorded run is arrow.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
#> Loading required package: DBI
library(geoarrow) # registers geoarrow.wkb for nanoarrow
options(width = 250)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

# The types, with a value of each: types.R, shared with catalog.R.
source("types.R")

con <- dbConnect(duckdb())
for (e in unique(types$ext[types$ext != ""])) {
  invisible(dbExecute(con, paste("INSTALL", e)))
  invisible(dbExecute(con, paste("LOAD", e)))
}

# The result, or the first line of the error.
cell <- function(expr, width = 70) {
  out <- tryCatch(
    expr,
    error = function(e) paste("ERROR:", gsub("\n.*", "", conditionMessage(e)))
  )
  if (nchar(out) > width) paste0(substr(out, 1, width - 3), "...") else out
}

# An Arrow field's format, and the extension it carries, if any.
field <- function(sch) {
  ext <- sch$metadata[["ARROW:extension:name"]]
  if (!is.null(ext) && ext == "arrow.opaque") {
    meta <- jsonlite::fromJSON(sch$metadata[["ARROW:extension:metadata"]])
    ext <- paste0(ext, "<", meta$type_name, ">")
  }
  paste0(sch$format, if (!is.null(ext)) paste0(" ", ext))
}

# Out through Arrow, then back in through duckdb_register_arrow(), which
# takes an arrow object. The stream is read to the end first: registered
# while still open, it waits on the connection that is scanning it.
round_trip <- function(lit) {
  s <- dbGetQueryArrow(con, paste("SELECT", lit, "AS x"))
  s <- nanoarrow::as_nanoarrow_array_stream(s)
  shape <- field(s$get_schema()$children$x)
  tbl <- arrow::as_arrow_table(arrow::as_record_batch_reader(s))
  back <- cell({
    duckdb_register_arrow(con, "back", tbl)
    on.exit(duckdb_unregister_arrow(con, "back"))
    r <- dbGetQuery(
      con,
      sprintf(
        "SELECT typeof(x) AS t, x::VARCHAR = (%s)::VARCHAR AS s FROM back",
        lit
      )
    )
    paste0(r$t, if (isTRUE(r$s)) "; same" else "; differs")
  })
  paste(shape, "->", back)
}

each <- function() {
  vapply(
    types$lit[types$logical != "NULL"],
    function(lit) cell(round_trip(lit)),
    character(1)
  )
}

default <- each()
invisible(dbExecute(con, "SET arrow_lossless_conversion = true"))
lossless <- each()
invisible(dbExecute(con, "RESET arrow_lossless_conversion"))

print(
  data.frame(
    type = types$type[types$logical != "NULL"],
    default = default,
    lossless = lossless
  ),
  right = FALSE,
  row.names = FALSE
)
#>  type                            default                                                                lossless                                                              
#>  BOOLEAN                         b -> BOOLEAN; same                                                     c arrow.bool8 -> BOOLEAN; same                                        
#>  TINYINT                         c -> TINYINT; same                                                     c -> TINYINT; same                                                    
#>  SMALLINT                        s -> SMALLINT; same                                                    s -> SMALLINT; same                                                   
#>  INTEGER                         i -> INTEGER; same                                                     i -> INTEGER; same                                                    
#>  BIGINT                          l -> BIGINT; same                                                      l -> BIGINT; same                                                     
#>  HUGEINT                         d:38,0 -> DECIMAL(38,0); same                                          w:16 arrow.opaque<hugeint> -> HUGEINT; same                           
#>  UTINYINT                        C -> UTINYINT; same                                                    C -> UTINYINT; same                                                   
#>  USMALLINT                       S -> USMALLINT; same                                                   S -> USMALLINT; same                                                  
#>  UINTEGER                        I -> UINTEGER; same                                                    I -> UINTEGER; same                                                   
#>  UBIGINT                         L -> UBIGINT; same                                                     L -> UBIGINT; same                                                    
#>  UHUGEINT                        d:38,0 -> DECIMAL(38,0); same                                          w:16 arrow.opaque<uhugeint> -> UHUGEINT; same                         
#>  BIGNUM                          z arrow.opaque<bignum> -> BIGNUM; same                                 z arrow.opaque<bignum> -> BIGNUM; same                                
#>  DECIMAL(4,1)                    d:4,1,128 -> DECIMAL(4,1); same                                        d:4,1,128 -> DECIMAL(4,1); same                                       
#>  DECIMAL(18,3)                   d:18,3,128 -> DECIMAL(18,3); same                                      d:18,3,128 -> DECIMAL(18,3); same                                     
#>  DECIMAL(38,10)                  d:38,10,128 -> DECIMAL(38,10); same                                    d:38,10,128 -> DECIMAL(38,10); same                                   
#>  FLOAT                           f -> FLOAT; same                                                       f -> FLOAT; same                                                      
#>  DOUBLE                          g -> DOUBLE; same                                                      g -> DOUBLE; same                                                     
#>  VARCHAR                         u -> VARCHAR; same                                                     u -> VARCHAR; same                                                    
#>  BLOB                            z -> BLOB; same                                                        z -> BLOB; same                                                       
#>  BIT                             z -> BLOB; differs                                                     z arrow.opaque<bit> -> BIT; same                                      
#>  UUID                            u -> VARCHAR; same                                                     w:16 arrow.uuid -> UUID; same                                         
#>  DATE                            tdD -> DATE; same                                                      tdD -> DATE; same                                                     
#>  TIME                            ttu -> TIME; same                                                      ttu -> TIME; same                                                     
#>  TIME_NS                         ttn -> TIME_NS; same                                                   ttn -> TIME_NS; same                                                  
#>  TIMETZ                          ttu -> TIME; differs                                                   w:8 arrow.opaque<time_tz> -> TIME WITH TIME ZONE; same                
#>  TIMESTAMP_S                     tss: -> TIMESTAMP_S; same                                              tss: -> TIMESTAMP_S; same                                             
#>  TIMESTAMP_MS                    tsm: -> TIMESTAMP_MS; same                                             tsm: -> TIMESTAMP_MS; same                                            
#>  TIMESTAMP                       tsu: -> TIMESTAMP; same                                                tsu: -> TIMESTAMP; same                                               
#>  TIMESTAMP_NS                    tsn: -> TIMESTAMP_NS; same                                             tsn: -> TIMESTAMP_NS; same                                            
#>  TIMESTAMPTZ                     tsu:Etc/UTC -> TIMESTAMP WITH TIME ZONE; same                          tsu:Etc/UTC -> TIMESTAMP WITH TIME ZONE; same                         
#>  INTERVAL                        tin -> INTERVAL; same                                                  tin -> INTERVAL; same                                                 
#>  ENUM('sad', 'ok', 'happy')      C -> VARCHAR; same                                                     C -> VARCHAR; same                                                    
#>  GEOMETRY                        z geoarrow.wkb -> GEOMETRY; same                                       z geoarrow.wkb -> GEOMETRY; same                                      
#>  INTEGER[3]                      +w:3 -> INTEGER[3]; same                                               +w:3 -> INTEGER[3]; same                                              
#>  INTEGER[]                       +l -> INTEGER[]; same                                                  +l -> INTEGER[]; same                                                 
#>  MAP(VARCHAR, INTEGER)           +m -> MAP(VARCHAR, INTEGER); same                                      +m -> MAP(VARCHAR, INTEGER); same                                     
#>  STRUCT(i INTEGER, j VARCHAR)    +s -> STRUCT(i INTEGER, j VARCHAR); same                               +s -> STRUCT(i INTEGER, j VARCHAR); same                              
#>  UNION(num INTEGER, str VARCHAR) +us:0,1 -> UNION(num INTEGER, str VARCHAR); same                       +us:0,1 -> UNION(num INTEGER, str VARCHAR); same                      
#>  VARIANT                         ERROR: array_stream->get_schema(): [-1] Not implemented Error: Unsu... ERROR: array_stream->get_schema(): [-1] Not implemented Error: Unsu...
#>  JSON                            u -> VARCHAR; same                                                     u arrow.json -> JSON; same                                            
#>  INET                            +s -> STRUCT(ip_type UTINYINT, address DECIMAL(38,0), mask USMALLIN... +s -> STRUCT(ip_type UTINYINT, address HUGEINT, mask USMALLINT); di...
#>  POINT_2D                        +s -> STRUCT(x DOUBLE, y DOUBLE); differs                              +s -> STRUCT(x DOUBLE, y DOUBLE); differs                             
#>  POINT_3D                        +s -> STRUCT(x DOUBLE, y DOUBLE, z DOUBLE); differs                    +s -> STRUCT(x DOUBLE, y DOUBLE, z DOUBLE); differs                   
#>  POINT_4D                        +s -> STRUCT(x DOUBLE, y DOUBLE, z DOUBLE, m DOUBLE); differs          +s -> STRUCT(x DOUBLE, y DOUBLE, z DOUBLE, m DOUBLE); differs         
#>  LINESTRING_2D                   +l -> STRUCT(x DOUBLE, y DOUBLE)[]; differs                            +l -> STRUCT(x DOUBLE, y DOUBLE)[]; differs                           
#>  LINESTRING_3D                   +l -> STRUCT(x DOUBLE, y DOUBLE, z DOUBLE)[]; differs                  +l -> STRUCT(x DOUBLE, y DOUBLE, z DOUBLE)[]; differs                 
#>  POLYGON_2D                      +l -> STRUCT(x DOUBLE, y DOUBLE)[][]; differs                          +l -> STRUCT(x DOUBLE, y DOUBLE)[][]; differs                         
#>  POLYGON_3D                      +l -> STRUCT(x DOUBLE, y DOUBLE, z DOUBLE)[][]; differs                +l -> STRUCT(x DOUBLE, y DOUBLE, z DOUBLE)[][]; differs               
#>  BOX_2D                          +s -> STRUCT(min_x DOUBLE, min_y DOUBLE, max_x DOUBLE, max_y DOUBLE... +s -> STRUCT(min_x DOUBLE, min_y DOUBLE, max_x DOUBLE, max_y DOUBLE...
#>  BOX_2DF                         +s -> STRUCT(min_x FLOAT, min_y FLOAT, max_x FLOAT, max_y FLOAT); same +s -> STRUCT(min_x FLOAT, min_y FLOAT, max_x FLOAT, max_y FLOAT); same
#>  WKB_BLOB                        z -> BLOB; same                                                        z -> BLOB; same

# --- Arrow built in R -------------------------------------------------

# For the types no R class writes, an Arrow array of the matching type does.
built <- list(
  "int8" = arrow::Array$create(42L, type = arrow::int8()),
  "uint32" = arrow::Array$create(42, type = arrow::uint32()),
  "uint64" = arrow::Array$create(
    bit64::as.integer64("9007199254740993"),
    type = arrow::uint64()
  ),
  "float32" = arrow::Array$create(1.5, type = arrow::float32()),
  "decimal128(38, 10)" = arrow::Array$create(
    "3.1415926535",
    type = arrow::string()
  )$cast(arrow::decimal128(38, 10)),
  "time64[us]" = arrow::Array$create(
    hms::as_hms("13:03:12.123456"),
    type = arrow::time64("us")
  ),
  "time64[ns]" = arrow::Array$create(
    hms::as_hms("13:03:12.123456"),
    type = arrow::time64("ns")
  ),
  "timestamp[ns]" = arrow::Array$create(
    as.POSIXct("2024-01-10 13:03:12", tz = "UTC"),
    type = arrow::timestamp("ns")
  ),
  "timestamp[us, America/New_York]" = arrow::Array$create(
    as.POSIXct("2024-01-10 13:03:12", tz = "America/New_York"),
    type = arrow::timestamp("us", "America/New_York")
  ),
  "duration[us]" = arrow::Array$create(
    as.difftime(90, units = "mins"),
    type = arrow::duration("us")
  ),
  "dictionary<int8, utf8>" = arrow::Array$create(factor("ok")),
  "fixed_size_list<int32>[3]" = arrow::Array$create(
    list(1:3),
    type = arrow::fixed_size_list_of(arrow::int32(), 3)
  ),
  "map<utf8, int32>" = arrow::Array$create(
    list(data.frame(key = c("a", "b"), value = 1:2)),
    type = arrow::map_of(arrow::utf8(), arrow::int32())
  )
)
print(
  data.frame(
    arrow = names(built),
    duckdb = vapply(
      built,
      function(a) {
        cell({
          duckdb_register_arrow(con, "built", arrow::arrow_table(x = a))
          on.exit(duckdb_unregister_arrow(con, "built"))
          r <- dbGetQuery(
            con,
            "SELECT typeof(x) AS t, x::VARCHAR AS v FROM built"
          )
          paste(r$t, r$v)
        })
      },
      character(1)
    )
  ),
  right = FALSE,
  row.names = FALSE
)
#>  arrow                           duckdb                                         
#>  int8                            TINYINT 42                                     
#>  uint32                          UINTEGER 42                                    
#>  uint64                          UBIGINT 9007199254740993                       
#>  float32                         FLOAT 1.5                                      
#>  decimal128(38, 10)              DECIMAL(38,10) 3.1415926535                    
#>  time64[us]                      TIME 13:03:12.123456                           
#>  time64[ns]                      TIME_NS 13:03:12.123456                        
#>  timestamp[ns]                   TIMESTAMP_NS 2024-01-10 13:03:12               
#>  timestamp[us, America/New_York] TIMESTAMP WITH TIME ZONE 2024-01-10 18:03:12+00
#>  duration[us]                    INTERVAL 01:30:00                              
#>  dictionary<int8, utf8>          VARCHAR ok                                     
#>  fixed_size_list<int32>[3]       INTEGER[3] [1, 2, 3]                           
#>  map<utf8, int32>                MAP(VARCHAR, INTEGER) {a=1, b=2}

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
#>  date     2026-09-26
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  arrow         25.0.1     2026-08-23 [1] RSPM
#>  assertthat    0.2.1      2019-03-21 [1] RSPM
#>  bit           4.6.0      2025-03-06 [1] RSPM
#>  bit64         4.8.6      2026-09-01 [1] RSPM
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9026 2026-09-26 [1] local
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
