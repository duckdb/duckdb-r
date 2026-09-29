``` r
# Where a value does not survive the crossing: what changes, what collides
# with NA, and what fails, one case per row.
# The recorded run is edges.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
#> Loading required package: DBI
options(width = 250)
options(duckdb.home = "~/.duckdb")

con <- dbConnect(duckdb())
con64 <- dbConnect(duckdb(), bigint = "integer64", array = "matrix")

# The result, or the first line of the error, with a warning noted.
cell <- function(expr) {
  warned <- NULL
  out <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warned <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) paste("ERROR:", gsub("\n.*", "", conditionMessage(e)))
  )
  if (!is.null(warned)) {
    out <- paste0(out, " (warns: ", warned, ")")
  }
  out
}

# Values as R holds them, at full precision.
show <- function(x) {
  if (is.data.frame(x)) {
    return(paste(vapply(x, show, ""), collapse = " | "))
  }
  if (is.list(x)) {
    return(paste(vapply(x, function(e) deparse(e)[1], ""), collapse = ", "))
  }
  v <- if (inherits(x, "integer64")) {
    as.character(x)
  } else if (is.double(x) && !inherits(x, c("Date", "POSIXct", "difftime"))) {
    format(unclass(x), digits = 17)
  } else {
    format(x)
  }
  paste(v, collapse = ", ")
}
fetch <- function(cn, sql, ...) show(dbGetQuery(cn, sql, ...)[[1]])
text <- function(cn, table) {
  paste(
    dbGetQuery(
      cn,
      paste("SELECT typeof(x) || ' ' || x::VARCHAR AS v FROM", table)
    )$v,
    collapse = ", "
  )
}
frame <- function(x) {
  d <- data.frame(id = seq_len(NROW(x)))
  d$x <- x
  d
}

# --- Out: DuckDB to R ---------------------------------------------------

out <- list(
  "INTEGER minimum" = fetch(con, "SELECT (-2147483648)::INTEGER"),
  "BIGINT 2^53 + 1, default" = fetch(con, "SELECT 9007199254740993::BIGINT"),
  "BIGINT 2^53 + 1, integer64" = fetch(
    con64,
    "SELECT 9007199254740993::BIGINT"
  ),
  "BIGINT minimum, integer64" = fetch(
    con64,
    "SELECT (-9223372036854775808)::BIGINT"
  ),
  "UBIGINT maximum, default" = fetch(
    con,
    "SELECT 18446744073709551615::UBIGINT"
  ),
  "UBIGINT maximum, integer64" = fetch(
    con64,
    "SELECT 18446744073709551615::UBIGINT"
  ),
  "HUGEINT maximum" = fetch(
    con,
    "SELECT 170141183460469231731687303715884105727::HUGEINT"
  ),
  "HUGEINT as text" = fetch(
    con,
    "SELECT 170141183460469231731687303715884105727::HUGEINT::VARCHAR"
  ),
  "DECIMAL(38,10), 38 digits" = fetch(
    con,
    "SELECT 1234567890123456789012345678.0123456789::DECIMAL(38,10)"
  ),
  "DOUBLE NaN and NULL" = fetch(con, "SELECT unnest(['NaN'::DOUBLE, NULL])"),
  "DATE infinity" = fetch(con, "SELECT 'infinity'::DATE"),
  "TIMESTAMP infinity" = fetch(con, "SELECT 'infinity'::TIMESTAMP"),
  "TIMESTAMP_NS, first query" = cell(fetch(
    con,
    "SELECT TIMESTAMP_NS '2024-01-10 13:03:12.123456789'"
  )),
  "TIMESTAMP_NS, second query" = cell(fetch(
    con,
    "SELECT TIMESTAMP_NS '2024-01-10 13:03:12.123456789'"
  )),
  "TIMETZ with an offset" = fetch(con, "SELECT TIMETZ '13:03:12+05:30'"),
  "INTERVAL one month" = fetch(con, "SELECT INTERVAL '1 month'"),
  "INTERVAL one day" = fetch(con, "SELECT INTERVAL '1 day'"),
  "STRUCT NULL vs. NULL fields" = fetch(
    con,
    "SELECT unnest([NULL, {'i': NULL}]::STRUCT(i INTEGER)[])"
  ),
  "ARRAY NULL vs. NULL elements" = fetch(
    con64,
    "SELECT unnest([NULL, [NULL, NULL]]::INTEGER[2][])"
  ),
  "LIST NULL vs. NULL element" = fetch(
    con,
    "SELECT unnest([NULL, [NULL]]::INTEGER[][])"
  ),
  "ENUM levels" = paste(
    levels(dbGetQuery(con, "SELECT 'ok'::ENUM('sad', 'ok', 'happy')")[[1]]),
    collapse = ","
  ),
  "VARIANT holding a BIT" = cell(fetch(con, "SELECT '101'::BIT::VARIANT")),
  "BIT as text" = fetch(con, "SELECT '101'::BIT::VARCHAR"),
  "BIGNUM as text" = fetch(con, "SELECT (2::BIGNUM ^ 200)::BIGNUM::VARCHAR"),
  "TIME_NS as TIME" = fetch(con, "SELECT '13:03:12.123456789'::TIME_NS::TIME"),
  "UNION tag and member" = fetch(
    con,
    "SELECT union_tag(u) || ': ' || union_extract(u, 'num')
       FROM (SELECT union_value(num := 2)::UNION(num INTEGER, str VARCHAR) AS u)"
  )
)
print(
  data.frame(case = names(out), result = unlist(out)),
  right = FALSE,
  row.names = FALSE
)
#>  case                         result                                                                                               
#>  INTEGER minimum              NA                                                                                                   
#>  BIGINT 2^53 + 1, default     9007199254740992                                                                                     
#>  BIGINT 2^53 + 1, integer64   9007199254740993                                                                                     
#>  BIGINT minimum, integer64    NA                                                                                                   
#>  UBIGINT maximum, default     18446744073709551616                                                                                 
#>  UBIGINT maximum, integer64   -1                                                                                                   
#>  HUGEINT maximum              1.7014118346046923e+38                                                                               
#>  HUGEINT as text              170141183460469231731687303715884105727                                                              
#>  DECIMAL(38,10), 38 digits    1.2345678901234567e+27                                                                               
#>  DOUBLE NaN and NULL          NaN,  NA                                                                                             
#>  DATE infinity                5881580-07-11                                                                                        
#>  TIMESTAMP infinity           294247-01-10 04:00:54                                                                                
#>  TIMESTAMP_NS, first query    2024-01-10 13:03:12 (warns: Coercing nanoseconds to a lower resolution may result in a loss of data.)
#>  TIMESTAMP_NS, second query   2024-01-10 13:03:12                                                                                  
#>  TIMETZ with an offset        46992 secs                                                                                           
#>  INTERVAL one month           2592000 secs                                                                                         
#>  INTERVAL one day             86400 secs                                                                                           
#>  STRUCT NULL vs. NULL fields  NA, NA                                                                                               
#>  ARRAY NULL vs. NULL elements NA, NA, NA, NA                                                                                       
#>  LIST NULL vs. NULL element   NULL, NA_integer_                                                                                    
#>  ENUM levels                  sad,ok,happy                                                                                         
#>  VARIANT holding a BIT        ERROR: Unknown type for column `variant`: BIT                                                        
#>  BIT as text                  101                                                                                                  
#>  BIGNUM as text               1606938044258990275541962092341162602522202993782792835301376                                        
#>  TIME_NS as TIME              46992.12 secs                                                                                        
#>  UNION tag and member         num: 2

# --- In: R to DuckDB ----------------------------------------------------

i64 <- bit64::as.integer64(c("42", NA))
into <- list(
  "integer64, bigint = numeric" = cell({
    dbWriteTable(con, "i", frame(i64), overwrite = TRUE)
    text(con, "i")
  }),
  "integer64, bigint = integer64" = cell({
    dbWriteTable(con64, "i", frame(i64), overwrite = TRUE)
    text(con64, "i")
  }),
  "integer64 bound, bigint = integer64" = cell(fetch(
    con64,
    "SELECT ?::BIGINT",
    params = list(i64[1])
  )),
  "Date stored as integer, with NA" = cell({
    dbWriteTable(
      con,
      "d",
      frame(structure(c(19732L, NA), class = "Date")),
      overwrite = TRUE
    )
    text(con, "d")
  }),
  "difftime stored as integer, with NA" = cell({
    dbWriteTable(
      con,
      "d",
      frame(structure(c(5L, NA), class = "difftime", units = "mins")),
      overwrite = TRUE
    )
    text(con, "d")
  }),
  "difftime in minutes" = cell({
    dbWriteTable(
      con,
      "d",
      frame(as.difftime(90, units = "mins")),
      overwrite = TRUE
    )
    paste(text(con, "d"), "->", show(dbReadTable(con, "d")$x))
  }),
  "hms" = cell({
    dbWriteTable(con, "d", frame(hms::as_hms("13:03:12")), overwrite = TRUE)
    text(con, "d")
  }),
  "dbDataType() of difftime" = dbDataType(con, as.difftime(1, units = "secs")),
  "difftime into dbCreateTable()'s table" = cell({
    d <- frame(as.difftime(1, units = "secs"))
    dbCreateTable(con, "c", d)
    dbAppendTable(con, "c", d)
  }),
  "POSIXct in New York" = cell({
    x <- as.POSIXct("2024-01-10 13:03:12", tz = "America/New_York")
    dbWriteTable(con, "p", frame(x), overwrite = TRUE)
    text(con, "p")
  }),
  "POSIXct, field.types TIMESTAMPTZ" = cell({
    x <- as.POSIXct("2024-01-10 13:03:12", tz = "America/New_York")
    dbWriteTable(
      con,
      "p",
      frame(x),
      overwrite = TRUE,
      field.types = c(x = "TIMESTAMPTZ")
    )
    text(con, "p")
  }),
  "factor" = cell({
    dbWriteTable(
      con,
      "f",
      frame(factor("ok", levels = c("sad", "ok"))),
      overwrite = TRUE
    )
    text(con, "f")
  }),
  "ordered factor, read back" = cell({
    dbWriteTable(
      con,
      "f",
      frame(factor("ok", levels = c("sad", "ok"), ordered = TRUE)),
      overwrite = TRUE
    )
    paste(class(dbReadTable(con, "f")$x), collapse = "/")
  }),
  "factor bound" = cell(fetch(
    con,
    "SELECT typeof(?)",
    params = list(factor("ok"))
  )),
  "character UUID" = cell({
    dbWriteTable(
      con,
      "u",
      frame("4ac7a9e9-607c-4c8a-84f3-843f0191e3fd"),
      overwrite = TRUE
    )
    text(con, "u")
  }),
  "blob::blob" = cell({
    dbWriteTable(
      con,
      "b",
      frame(blob::as_blob(as.raw(c(0xAA, 0xBB)))),
      overwrite = TRUE
    )
    text(con, "b")
  }),
  "raw vector" = cell({
    dbWriteTable(con, "b", frame(as.raw(c(0xAA, 0xBB))), overwrite = TRUE)
    text(con, "b")
  }),
  "complex" = cell({
    dbWriteTable(con, "z", frame(1i), overwrite = TRUE)
    text(con, "z")
  }),
  "double NaN" = cell({
    dbWriteTable(con, "n", frame(c(NaN, NA)), overwrite = TRUE)
    text(con, "n")
  }),
  "matrix bound" = cell(fetch(
    con,
    "SELECT ?::INTEGER[2]",
    params = list(matrix(1:2, nrow = 1))
  )),
  "data frame column, two fields" = cell({
    dbWriteTable(con, "s", frame(data.frame(i = 1L, j = "a")), overwrite = TRUE)
    text(con, "s")
  }),
  # In a subprocess, because a build that reads past the data frame crashes.
  "data frame bound as STRUCT" = cell({
    r <- callr::r(
      function() {
        con <- DBI::dbConnect(duckdb::duckdb())
        DBI::dbGetQuery(
          con,
          "SELECT (?::STRUCT(i INTEGER, j VARCHAR))::VARCHAR AS v",
          params = list(data.frame(i = 1L, j = "a"))
        )$v
      },
      error = "error"
    )
    r
  }),
  "VARIANT from a scalar column" = cell({
    dbWriteTable(
      con,
      "v",
      frame(42L),
      overwrite = TRUE,
      field.types = c(x = "VARIANT")
    )
    fetch(con, "SELECT variant_typeof(x) || ' ' || x::VARCHAR FROM v")
  }),
  "UNION from its member's type" = cell({
    dbWriteTable(
      con,
      "u",
      frame(2L),
      overwrite = TRUE,
      field.types = c(x = "UNION(num INTEGER, str VARCHAR)")
    )
    fetch(con, "SELECT union_tag(x) || ': ' || x::VARCHAR FROM u")
  }),
  "UNION from text" = cell({
    dbWriteTable(
      con,
      "u",
      frame("2"),
      overwrite = TRUE,
      field.types = c(x = "UNION(num INTEGER, str VARCHAR)")
    )
    fetch(con, "SELECT union_tag(x) || ': ' || x::VARCHAR FROM u")
  })
)
print(
  data.frame(case = names(into), result = unlist(into)),
  right = FALSE,
  row.names = FALSE
)
#>  case                                  result                                                                                                     
#>  integer64, bigint = numeric           DOUBLE 2.08e-322, DOUBLE -0.0                                                                              
#>  integer64, bigint = integer64         BIGINT 42, NA                                                                                              
#>  integer64 bound, bigint = integer64   0                                                                                                          
#>  Date stored as integer, with NA       DATE 2024-01-10, DATE 5877642-06-23 (BC)                                                                   
#>  difftime stored as integer, with NA   INTERVAL 00:05:00, INTERVAL -1491308 days -02:08:00                                                        
#>  difftime in minutes                   INTERVAL 01:30:00 -> 5400 secs                                                                             
#>  hms                                   INTERVAL 13:03:12                                                                                          
#>  dbDataType() of difftime              TIME                                                                                                       
#>  difftime into dbCreateTable()'s table ERROR: Conversion Error: Unimplemented type for cast (INTERVAL -> TIME) when casting from source column x  
#>  POSIXct in New York                   TIMESTAMP 2024-01-10 18:03:12                                                                              
#>  POSIXct, field.types TIMESTAMPTZ      TIMESTAMP WITH TIME ZONE 2024-01-10 18:03:12+00                                                            
#>  factor                                ENUM('sad', 'ok') ok                                                                                       
#>  ordered factor, read back             factor                                                                                                     
#>  factor bound                          VARCHAR                                                                                                    
#>  character UUID                        VARCHAR 4ac7a9e9-607c-4c8a-84f3-843f0191e3fd                                                               
#>  blob::blob                            BLOB \\xAA\\xBB                                                                                            
#>  raw vector                            ERROR: {"exception_type":"Invalid","exception_message":"std::exception"}                                   
#>  complex                               ERROR: {"exception_type":"Invalid","exception_message":"std::exception"}                                   
#>  double NaN                            DOUBLE nan, NA                                                                                             
#>  matrix bound                          ERROR: Unsupported RTypeId                                                                                 
#>  data frame column, two fields         ERROR: the condition has length > 1                                                                        
#>  data frame bound as STRUCT            ERROR: ! callr subprocess failed: could not start R, exited with non-zero status, has crashed or was killed
#>  VARIANT from a scalar column          INT32 42                                                                                                   
#>  UNION from its member's type          num: 2                                                                                                     
#>  UNION from text                       ERROR: Catalog Error: Table with name "u" already exists!

# --- Tables and results holding a type R cannot hold -----------------

invisible(dbExecute(con, "CREATE TABLE b (x BIT, y INTEGER)"))
held <- list(
  "dbExistsTable()" = cell(dbExistsTable(con, "b")),
  "dbListFields()" = cell(paste(dbListFields(con, "b"), collapse = ", ")),
  "dbGetQuery()" = cell(fetch(con, "SELECT x FROM b")),
  "dbGetQueryArrow()" = cell({
    s <- nanoarrow::as_nanoarrow_array_stream(dbGetQueryArrow(
      con,
      "SELECT x FROM b"
    ))
    s$get_schema()$children$x$format
  })
)
print(
  data.frame(case = names(held), result = unlist(held)),
  right = FALSE,
  row.names = FALSE
)
#>  case              result                                     
#>  dbExistsTable()   FALSE                                      
#>  dbListFields()    ERROR: Unknown column type for prepare: BIT
#>  dbGetQuery()      ERROR: Unknown column type for prepare: BIT
#>  dbGetQueryArrow() ERROR: Unknown column type for prepare: BIT

dbDisconnect(con, shutdown = TRUE)
dbDisconnect(con64, shutdown = TRUE)
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
#>  bit           4.6.0      2025-03-06 [2] RSPM
#>  bit64         4.8.6      2026-09-01 [2] RSPM
#>  blob          1.3.0      2026-01-14 [2] RSPM
#>  callr         3.8.0      2026-06-05 [2] RSPM
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb      * 1.5.5.9026 2026-09-26 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  hms           1.1.4      2025-10-17 [2] RSPM
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  nanoarrow     0.9.0      2026-08-04 [2] RSPM
#>  otel          0.2.0      2025-08-29 [2] RSPM
#>  pillar        1.11.1     2025-09-17 [2] RSPM
#>  pkgconfig     2.0.3      2019-09-22 [2] RSPM
#>  processx      3.9.0      2026-04-22 [2] RSPM
#>  ps            1.9.3      2026-04-20 [2] RSPM
#>  R6            2.6.1      2025-02-15 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  vctrs         0.7.3      2026-04-11 [2] RSPM
#>  withr         3.0.3      2026-06-19 [2] RSPM
#>  xfun          0.60       2026-07-09 [2] RSPM
#>  yaml          2.3.12     2025-12-10 [2] RSPM
#> 
#>  [1] /tmp/claude-0/-home-user-duckdb-r/ade6d380-e728-5627-af5b-bbc51338befd/scratchpad/base-lib
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

</details>
