``` r
# Every DuckDB type, both directions: what a value of each type becomes in
# R, and which routes put that R value back as the same type.
# One row per type, one column per route; the recorded run is catalog.md,
# rendered with reprex::reprex(si = TRUE).
library(duckdb)
#> Loading required package: DBI
library(geoarrow) # registers geoarrow.wkb, so an Arrow GEOMETRY converts
options(width = 250)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

# The types, with a value of each: types.R, shared with arrow.R.
source("types.R")

# Two connections: every default, and every option that changes a type's R
# shape. Writes run on the second, where the value written back is the one
# the option produced.
con <- dbConnect(duckdb())
con_opt <- dbConnect(
  duckdb(),
  bigint = "integer64",
  array = "matrix",
  map = "list_of",
  geometry = "wk"
)
for (e in unique(types$ext[types$ext != ""])) {
  invisible(dbExecute(con, paste("INSTALL", e)))
  for (cn in list(con, con_opt)) {
    invisible(dbExecute(cn, paste("LOAD", e)))
  }
}

# --- The list is complete ---------------------------------------------

# Every type id the engine knows is covered, and so is every type name an
# extension adds; TYPE is the catalog's own and holds no data.
known <- dbGetQuery(con, "SELECT type_name, logical_type FROM duckdb_types()")
setdiff(unique(known$logical_type), c(types$logical, "TYPE"))
#> character(0)
added <- dbGetQuery(
  con,
  "SELECT type_name FROM duckdb_types() WHERE type_name = upper(type_name)
     AND type_name NOT IN (SELECT upper(type_name) FROM duckdb_types()
                           WHERE type_name = lower(type_name))"
)$type_name
setdiff(added, sub("\\(.*", "", types$type))
#> character(0)

# --- Helpers ----------------------------------------------------------

# One cell per route: the result, or the first line of the error, with a
# warning noted rather than printed.
cell <- function(expr, width = 58) {
  warned <- NULL
  out <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warned <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      msg <- sub(
        "^(Invalid Error|Invalid Input Error): ",
        "",
        conditionMessage(e)
      )
      paste("ERROR:", gsub("\n.*", "", msg))
    }
  )
  out <- if (is.na(out[1])) "NA" else as.character(out[1])
  if (!is.null(warned)) {
    out <- paste0(out, " (warns)")
  }
  if (nchar(out) > width) paste0(substr(out, 1, width - 3), "...") else out
}

# What R received: the class, the attribute that carries meaning, and the
# value as R prints it.
describe <- function(x) {
  cls <- paste(class(x), collapse = "/")
  extra <- if (inherits(x, "POSIXct")) {
    paste0("[", attr(x, "tzone") %||% "", "]")
  } else if (inherits(x, "difftime")) {
    paste0("[", units(x), "]")
  } else if (is.factor(x)) {
    paste0("[", paste(levels(x), collapse = ","), "]")
  } else if (is.matrix(x)) {
    paste0("[", paste(dim(x), collapse = "x"), "]")
  } else if (is.data.frame(x)) {
    paste0("[", paste(names(x), collapse = ","), "]")
  } else if (identical(class(x), "list") && length(x) && !is.null(x[[1]])) {
    paste0("<", paste(class(x[[1]]), collapse = "/"), ">")
  } else {
    ""
  }
  val <- if (is.list(x) && !is.data.frame(x) && !inherits(x, "wk_vctr")) {
    ""
  } else {
    format(x)[1]
  }
  paste0(cls, extra, if (nzchar(val)) paste0(" ", val))
}

fetch <- function(cn, lit) dbGetQuery(cn, paste("SELECT", lit, "AS x"))$x

# Whether what landed equals the original: compared as the type where the
# engine can, and as text where it cannot.
verdict <- function(cn, from, lit, params = NULL) {
  q <- "SELECT x IS NOT DISTINCT FROM (%s) AS s, x::VARCHAR AS t FROM (%s)"
  r <- tryCatch(
    dbGetQuery(cn, sprintf(q, lit, from), params = params),
    error = function(e) NULL
  )
  suffix <- ""
  if (is.null(r)) {
    q <- paste(
      "SELECT x::VARCHAR IS NOT DISTINCT FROM (%s)::VARCHAR AS s,",
      "x::VARCHAR AS t FROM (%s)"
    )
    r <- dbGetQuery(cn, sprintf(q, lit, from), params = params)
    suffix <- " (as text)"
  }
  if (isTRUE(r$s[1])) paste0("same", suffix) else paste("differs:", r$t[1])
}

# A one-row data frame whose column is the value, whatever its shape.
frame <- function(x) {
  d <- data.frame(id = 1L)
  d$x <- x
  d
}

# --- Reading ------------------------------------------------------------

arrow_shape <- function(lit) {
  s <- nanoarrow::as_nanoarrow_array_stream(dbGetQueryArrow(
    con,
    paste("SELECT", lit, "AS x")
  ))
  sch <- s$get_schema()$children$x
  ext <- sch$metadata[["ARROW:extension:name"]]
  paste0(
    sch$format,
    if (!is.null(sch$dictionary)) {
      paste0(" dictionary<", sch$dictionary$format, ">")
    },
    if (!is.null(ext)) paste0(" ", ext),
    " -> ",
    paste(class(as.data.frame(s)$x), collapse = "/")
  )
}

read <- do.call(
  rbind,
  lapply(seq_len(nrow(types)), function(i) {
    t <- types[i, ]
    data.frame(
      type = t$type,
      default = cell(describe(fetch(con, t$lit))),
      option = if (nzchar(t$opt)) {
        cell(paste0(t$opt, ": ", describe(fetch(con_opt, t$lit))))
      } else {
        ""
      },
      arrow = cell(arrow_shape(t$lit)),
      text = cell(fetch(con, paste0("(", t$lit, ")::VARCHAR")))
    )
  })
)
print(read, right = FALSE)
#>    type                            default                                                    option                                 arrow                                                     
#> 1  BOOLEAN                         logical TRUE                                                                                      b -> logical                                              
#> 2  TINYINT                         integer 42                                                                                        c -> integer                                              
#> 3  SMALLINT                        integer 42                                                                                        s -> integer                                              
#> 4  INTEGER                         integer 42                                                                                        i -> integer                                              
#> 5  BIGINT                          numeric 42                                                 bigint: integer64 42                   l -> numeric                                              
#> 6  HUGEINT                         numeric 42                                                 bigint: numeric 42                     d:38,0 -> numeric                                         
#> 7  UTINYINT                        integer 42                                                                                        C -> integer                                              
#> 8  USMALLINT                       integer 42                                                                                        S -> integer                                              
#> 9  UINTEGER                        numeric 42                                                                                        I -> numeric                                              
#> 10 UBIGINT                         numeric 42                                                 bigint: integer64 42                   L -> numeric                                              
#> 11 UHUGEINT                        numeric 42                                                 bigint: numeric 42                     d:38,0 -> numeric                                         
#> 12 BIGNUM                          ERROR: Unknown type for column `x`: BIGNUM                                                        z arrow.opaque -> blob/vctrs_list_of/vctrs_vctr/list      
#> 13 DECIMAL(4,1)                    numeric 3.1                                                                                       d:4,1,128 -> numeric                                      
#> 14 DECIMAL(18,3)                   numeric 3.142                                                                                     d:18,3,128 -> numeric                                     
#> 15 DECIMAL(38,10)                  numeric 3.141593                                                                                  d:38,10,128 -> numeric                                    
#> 16 FLOAT                           numeric 1.5                                                                                       f -> numeric                                              
#> 17 DOUBLE                          numeric 1.5                                                                                       g -> numeric                                              
#> 18 VARCHAR                         character duck                                                                                    u -> character                                            
#> 19 BLOB                            list<raw>                                                                                         z -> blob/vctrs_list_of/vctrs_vctr/list                   
#> 20 BIT                             ERROR: Unknown type for column `x`: BIT                                                           z -> blob/vctrs_list_of/vctrs_vctr/list                   
#> 21 UUID                            character 4ac7a9e9-607c-4c8a-84f3-843f0191e3fd                                                    u -> character                                            
#> 22 DATE                            Date 2024-01-10                                                                                   tdD -> Date                                               
#> 23 TIME                            difftime[secs] 46992.12 secs                                                                      ttu -> hms/difftime                                       
#> 24 TIME_NS                         ERROR: Unknown type for column `x`: TIME_NS                                                       ttn -> hms/difftime                                       
#> 25 TIMETZ                          difftime[secs] 46992.12 secs                                                                      ttu -> hms/difftime                                       
#> 26 TIMESTAMP_S                     POSIXct/POSIXt[UTC] 2024-01-10 13:03:12                                                           tss: -> POSIXct/POSIXt                                    
#> 27 TIMESTAMP_MS                    POSIXct/POSIXt[UTC] 2024-01-10 13:03:12                                                           tsm: -> POSIXct/POSIXt                                    
#> 28 TIMESTAMP                       POSIXct/POSIXt[UTC] 2024-01-10 13:03:12                                                           tsu: -> POSIXct/POSIXt                                    
#> 29 TIMESTAMP_NS                    POSIXct/POSIXt[UTC] 2024-01-10 13:03:12 (warns)                                                   tsn: -> POSIXct/POSIXt (warns)                            
#> 30 TIMESTAMPTZ                     POSIXct/POSIXt[Etc/UTC] 2024-01-10 13:03:12                                                       tsu:Etc/UTC -> POSIXct/POSIXt                             
#> 31 INTERVAL                        difftime[secs] 11045.5 secs                                                                       ERROR: Can't infer R vector type for `x` <interval_mont...
#> 32 ENUM('sad', 'ok', 'happy')      factor[sad,ok,happy] ok                                                                           C dictionary<u> -> character                              
#> 33 GEOMETRY                        list<raw>                                                  geometry: wk_wkb/wk_vctr <POINT (1 2)> z geoarrow.wkb -> geoarrow_vctr/nanoarrow_vctr            
#> 34 NULL                            integer NA                                                                                        i -> integer                                              
#> 35 INTEGER[3]                      ERROR: Use `dbConnect(array = "matrix")` to enable arra... array: matrix/array[1x3] 1             +w:3 -> vctrs_list_of/vctrs_vctr/list                     
#> 36 INTEGER[]                       list<integer>                                                                                     +l -> vctrs_list_of/vctrs_vctr/list                       
#> 37 MAP(VARCHAR, INTEGER)           list<data.frame>                                           map: vctrs_list_of/vctrs_vctr/list     +m -> vctrs_list_of/vctrs_vctr/list                       
#> 38 STRUCT(i INTEGER, j VARCHAR)    data.frame[i,j] 42                                                                                +s -> data.frame                                          
#> 39 UNION(num INTEGER, str VARCHAR) ERROR: Unknown type for column `x`: UNION(num INTEGER, ...                                        +us:0,1 -> data.frame                                     
#> 40 VARIANT                         list<integer>                                                                                     ERROR: array_stream->get_schema(): [-1] Not implemented...
#> 41 JSON                            character {"a": 1}                                                                                u -> character                                            
#> 42 INET                            data.frame[ip_type,address,mask] 1                                                                +s -> data.frame                                          
#> 43 POINT_2D                        data.frame[x,y] 1                                                                                 +s -> data.frame                                          
#> 44 POINT_3D                        data.frame[x,y,z] 1                                                                               +s -> data.frame                                          
#> 45 POINT_4D                        data.frame[x,y,z,m] 1                                                                             +s -> data.frame                                          
#> 46 LINESTRING_2D                   list<data.frame>                                                                                  +l -> vctrs_list_of/vctrs_vctr/list                       
#> 47 LINESTRING_3D                   list<data.frame>                                                                                  +l -> vctrs_list_of/vctrs_vctr/list                       
#> 48 POLYGON_2D                      list<list>                                                                                        +l -> vctrs_list_of/vctrs_vctr/list                       
#> 49 POLYGON_3D                      list<list>                                                                                        +l -> vctrs_list_of/vctrs_vctr/list                       
#> 50 BOX_2D                          data.frame[min_x,min_y,max_x,max_y] 0                                                             +s -> data.frame                                          
#> 51 BOX_2DF                         data.frame[min_x,min_y,max_x,max_y] 0                                                             +s -> data.frame                                          
#> 52 WKB_BLOB                        list<raw>                                                                                         z -> blob/vctrs_list_of/vctrs_vctr/list                   
#>    text                                                                    
#> 1  true                                                                    
#> 2  42                                                                      
#> 3  42                                                                      
#> 4  42                                                                      
#> 5  42                                                                      
#> 6  42                                                                      
#> 7  42                                                                      
#> 8  42                                                                      
#> 9  42                                                                      
#> 10 42                                                                      
#> 11 42                                                                      
#> 12 42                                                                      
#> 13 3.1                                                                     
#> 14 3.142                                                                   
#> 15 3.1415926535                                                            
#> 16 1.5                                                                     
#> 17 1.5                                                                     
#> 18 duck                                                                    
#> 19 \\xAA\\xBB                                                              
#> 20 10101                                                                   
#> 21 4ac7a9e9-607c-4c8a-84f3-843f0191e3fd                                    
#> 22 2024-01-10                                                              
#> 23 13:03:12.123456                                                         
#> 24 13:03:12.123456                                                         
#> 25 13:03:12.123456+00                                                      
#> 26 2024-01-10 13:03:12                                                     
#> 27 2024-01-10 13:03:12.123                                                 
#> 28 2024-01-10 13:03:12.123456                                              
#> 29 2024-01-10 13:03:12.123456                                              
#> 30 2024-01-10 13:03:12.123456+00                                           
#> 31 03:04:05.5                                                              
#> 32 ok                                                                      
#> 33 POINT (1 2)                                                             
#> 34 NA                                                                      
#> 35 [1, 2, 3]                                                               
#> 36 [1, 2, 3]                                                               
#> 37 {a=1, b=2}                                                              
#> 38 {'i': 42, 'j': duck}                                                    
#> 39 2                                                                       
#> 40 42                                                                      
#> 41 {"a": 1}                                                                
#> 42 127.0.0.1                                                               
#> 43 POINT (1 2)                                                             
#> 44 POINT Z (1 2 3)                                                         
#> 45 POINT ZM (1 2 3 4)                                                      
#> 46 LINESTRING (0 0, 1 1)                                                   
#> 47 LINESTRING Z (0 0 0, 1 1 1)                                             
#> 48 POLYGON ((0 0, 1 0, 0 0))                                               
#> 49 POLYGON Z ((0 0 0, 1 0 0, 0 0 0))                                       
#> 50 BOX(0 0, 1 1)                                                           
#> 51 {'min_x': 0.0, 'min_y': 0.0, 'max_x': 1.0, 'max_y': 1.0}                
#> 52 \\x01\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xF0?\\x00\\x...

# --- Writing --------------------------------------------------------------

# The value to write back is what the best read returned: the option's, if
# the type has one, else the default's.
value_of <- function(t) {
  tryCatch(
    fetch(if (nzchar(t$opt)) con_opt else con, t$lit),
    error = function(e) NULL
  )
}

# An untyped NULL has no column type to write back to.
writable <- types[types$logical != "NULL", ]
write <- do.call(
  rbind,
  lapply(seq_len(nrow(writable)), function(i) {
    t <- writable[i, ]
    x <- value_of(t)
    txt <- fetch(con, paste0("(", t$lit, ")::VARCHAR"))
    none <- "(no R value)"
    data.frame(
      type = t$type,
      natural = if (is.null(x)) {
        none
      } else {
        cell({
          dbWriteTable(con_opt, "w", frame(x), overwrite = TRUE)
          paste0(
            dbGetQuery(con_opt, "SELECT typeof(x) AS t FROM w")$t,
            "; ",
            verdict(con_opt, "SELECT x FROM w", t$lit)
          )
        })
      },
      field.types = if (is.null(x)) {
        none
      } else {
        cell({
          dbWriteTable(
            con_opt,
            "w",
            frame(x),
            overwrite = TRUE,
            field.types = c(x = t$type)
          )
          verdict(con_opt, "SELECT x FROM w", t$lit)
        })
      },
      append = if (is.null(x)) {
        none
      } else {
        cell({
          dbExecute(
            con_opt,
            paste("CREATE OR REPLACE TABLE a (id INTEGER, x", t$type, ")")
          )
          dbAppendTable(con_opt, "a", frame(x))
          verdict(con_opt, "SELECT x FROM a", t$lit)
        })
      },
      bind = if (is.null(x)) {
        none
      } else {
        cell(verdict(
          con_opt,
          paste0("SELECT ?::", t$type, " AS x"),
          t$lit,
          params = list(x)
        ))
      },
      from_text = cell({
        dbWriteTable(
          con_opt,
          "w",
          frame(txt),
          overwrite = TRUE,
          field.types = c(x = t$type)
        )
        verdict(con_opt, "SELECT x FROM w", t$lit)
      })
    )
  })
)
print(write, right = FALSE)
#>    type                            natural                                                    field.types                                                append                                                    
#> 1  BOOLEAN                         BOOLEAN; same                                              same                                                       same                                                      
#> 2  TINYINT                         INTEGER; same                                              same                                                       same                                                      
#> 3  SMALLINT                        INTEGER; same                                              same                                                       same                                                      
#> 4  INTEGER                         INTEGER; same                                              same                                                       same                                                      
#> 5  BIGINT                          BIGINT; same                                               same                                                       same                                                      
#> 6  HUGEINT                         DOUBLE; same                                               same                                                       same                                                      
#> 7  UTINYINT                        INTEGER; same                                              same                                                       same                                                      
#> 8  USMALLINT                       INTEGER; same                                              same                                                       same                                                      
#> 9  UINTEGER                        DOUBLE; same                                               same                                                       same                                                      
#> 10 UBIGINT                         BIGINT; same                                               same                                                       same                                                      
#> 11 UHUGEINT                        DOUBLE; same                                               same                                                       same                                                      
#> 12 BIGNUM                          (no R value)                                               (no R value)                                               (no R value)                                              
#> 13 DECIMAL(4,1)                    DOUBLE; same                                               same                                                       same                                                      
#> 14 DECIMAL(18,3)                   DOUBLE; same                                               same                                                       same                                                      
#> 15 DECIMAL(38,10)                  DOUBLE; same                                               same                                                       same                                                      
#> 16 FLOAT                           DOUBLE; same                                               same                                                       same                                                      
#> 17 DOUBLE                          DOUBLE; same                                               same                                                       same                                                      
#> 18 VARCHAR                         VARCHAR; same                                              same                                                       same                                                      
#> 19 BLOB                            BLOB; same                                                 same                                                       same                                                      
#> 20 BIT                             (no R value)                                               (no R value)                                               (no R value)                                              
#> 21 UUID                            VARCHAR; same                                              same                                                       same                                                      
#> 22 DATE                            DATE; same                                                 same                                                       same                                                      
#> 23 TIME                            INTERVAL; same (as text)                                   ERROR: Conversion Error: Unimplemented type for cast (I... ERROR: Conversion Error: Unimplemented type for cast (I...
#> 24 TIME_NS                         (no R value)                                               (no R value)                                               (no R value)                                              
#> 25 TIMETZ                          INTERVAL; differs: 13:03:12.123456                         ERROR: Conversion Error: Unimplemented type for cast (I... ERROR: Conversion Error: Unimplemented type for cast (I...
#> 26 TIMESTAMP_S                     TIMESTAMP; same                                            same                                                       same                                                      
#> 27 TIMESTAMP_MS                    TIMESTAMP; same                                            same                                                       same                                                      
#> 28 TIMESTAMP                       TIMESTAMP; same                                            same                                                       same                                                      
#> 29 TIMESTAMP_NS                    TIMESTAMP; same                                            same                                                       same                                                      
#> 30 TIMESTAMPTZ                     TIMESTAMP; same                                            same                                                       same                                                      
#> 31 INTERVAL                        INTERVAL; same                                             same                                                       same                                                      
#> 32 ENUM('sad', 'ok', 'happy')      ENUM('sad', 'ok', 'happy'); same                           same                                                       same                                                      
#> 33 GEOMETRY                        BLOB; same                                                 ERROR: Conversion Error: Unimplemented type for cast (B... ERROR: Conversion Error: Unimplemented type for cast (B...
#> 34 INTEGER[3]                      INTEGER[3]; same                                           same                                                       same                                                      
#> 35 INTEGER[]                       INTEGER[]; same                                            same                                                       same                                                      
#> 36 MAP(VARCHAR, INTEGER)           MAP(VARCHAR, INTEGER); same                                same                                                       same                                                      
#> 37 STRUCT(i INTEGER, j VARCHAR)    STRUCT(i INTEGER, j VARCHAR); same                         same                                                       same                                                      
#> 38 UNION(num INTEGER, str VARCHAR) (no R value)                                               (no R value)                                               (no R value)                                              
#> 39 VARIANT                         INTEGER[]; differs: [42]                                   differs: [42]                                              differs: [42]                                             
#> 40 JSON                            VARCHAR; same                                              same                                                       same                                                      
#> 41 INET                            STRUCT(ip_type INTEGER, address DOUBLE, mask INTEGER); ... same                                                       same                                                      
#> 42 POINT_2D                        STRUCT(x DOUBLE, y DOUBLE); same                           same                                                       same                                                      
#> 43 POINT_3D                        STRUCT(x DOUBLE, y DOUBLE, z DOUBLE); same                 same                                                       same                                                      
#> 44 POINT_4D                        STRUCT(x DOUBLE, y DOUBLE, z DOUBLE, m DOUBLE); same       same                                                       same                                                      
#> 45 LINESTRING_2D                   STRUCT(x DOUBLE, y DOUBLE)[]; same                         same                                                       same                                                      
#> 46 LINESTRING_3D                   STRUCT(x DOUBLE, y DOUBLE, z DOUBLE)[]; same               same                                                       same                                                      
#> 47 POLYGON_2D                      STRUCT(x DOUBLE, y DOUBLE)[][]; same                       same                                                       same                                                      
#> 48 POLYGON_3D                      STRUCT(x DOUBLE, y DOUBLE, z DOUBLE)[][]; same             same                                                       same                                                      
#> 49 BOX_2D                          STRUCT(min_x DOUBLE, min_y DOUBLE, max_x DOUBLE, max_y ... same                                                       same                                                      
#> 50 BOX_2DF                         STRUCT(min_x DOUBLE, min_y DOUBLE, max_x DOUBLE, max_y ... same                                                       same                                                      
#> 51 WKB_BLOB                        BLOB; same                                                 same                                                       same                                                      
#>    bind                                                       from_text                                                 
#> 1  same                                                       same                                                      
#> 2  same                                                       same                                                      
#> 3  same                                                       same                                                      
#> 4  same                                                       same                                                      
#> 5  same                                                       same                                                      
#> 6  same                                                       same                                                      
#> 7  same                                                       same                                                      
#> 8  same                                                       same                                                      
#> 9  same                                                       same                                                      
#> 10 same                                                       same                                                      
#> 11 same                                                       same                                                      
#> 12 (no R value)                                               same                                                      
#> 13 same                                                       same                                                      
#> 14 same                                                       same                                                      
#> 15 same                                                       same                                                      
#> 16 same                                                       same                                                      
#> 17 same                                                       same                                                      
#> 18 same                                                       same                                                      
#> 19 same                                                       same                                                      
#> 20 (no R value)                                               same                                                      
#> 21 same                                                       same                                                      
#> 22 same                                                       same                                                      
#> 23 ERROR: Conversion Error: Unimplemented type for cast (I... same                                                      
#> 24 (no R value)                                               same                                                      
#> 25 ERROR: Conversion Error: Unimplemented type for cast (I... same                                                      
#> 26 same                                                       same                                                      
#> 27 same                                                       same                                                      
#> 28 same                                                       same                                                      
#> 29 same                                                       same                                                      
#> 30 same                                                       same                                                      
#> 31 same                                                       same                                                      
#> 32 same                                                       same                                                      
#> 33 ERROR: Conversion Error: Unimplemented type for cast (B... same                                                      
#> 34 ERROR: Unsupported RTypeId                                 same                                                      
#> 35 same                                                       same                                                      
#> 36 ERROR: Conversion Error: Unimplemented type for cast (S... ERROR: Binder Error: No function matches the given name...
#> 37 same                                                       same                                                      
#> 38 (no R value)                                               differs: 2                                                
#> 39 differs: [42]                                              same (as text)                                            
#> 40 same                                                       same                                                      
#> 41 same                                                       same                                                      
#> 42 same                                                       ERROR: Conversion Error: Type VARCHAR with value 'POINT...
#> 43 same                                                       ERROR: Conversion Error: Type VARCHAR with value 'POINT...
#> 44 same                                                       ERROR: Conversion Error: Type VARCHAR with value 'POINT...
#> 45 same                                                       ERROR: Conversion Error: Type VARCHAR with value 'LINES...
#> 46 same                                                       ERROR: Conversion Error: Type VARCHAR with value 'LINES...
#> 47 same                                                       ERROR: Conversion Error: Type VARCHAR with value 'POLYG...
#> 48 same                                                       ERROR: Conversion Error: Type VARCHAR with value 'POLYG...
#> 49 same                                                       ERROR: Conversion Error: Type VARCHAR with value 'BOX(0...
#> 50 same                                                       same                                                      
#> 51 same                                                       same

dbDisconnect(con, shutdown = TRUE)
dbDisconnect(con_opt, shutdown = TRUE)
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
#>  bit           4.6.0      2025-03-06 [1] RSPM
#>  bit64         4.8.6      2026-09-01 [1] RSPM
#>  blob          1.3.0      2026-01-14 [1] RSPM
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
#>  knitr         1.52       2026-09-06 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  nanoarrow     0.9.0      2026-08-04 [1] RSPM
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  pillar        1.11.1     2025-09-17 [1] RSPM
#>  pkgconfig     2.0.3      2019-09-22 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.32       2026-09-01 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
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
