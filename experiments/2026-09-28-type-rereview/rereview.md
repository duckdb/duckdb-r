``` r
## Facts a re-review of the type pages found wrong or unscoped:
## the integer minimums through Arrow, an IPv6 INET address,
## the string view setting, BIGNUM through Arrow, when nanoarrow warns,
## the casts of the spatial box types, and which CRS needs spatial.
library(DBI)
library(nanoarrow)
options(width = 200)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

first_line <- function(e) sub("\n.*", "", conditionMessage(e))
con <- dbConnect(duckdb::duckdb())
nano <- function(sql) as.data.frame(dbGetQueryArrow(con, sql))
arrow_df <- function(sql) {
  as.data.frame(arrow::as_arrow_table(dbGetQueryArrow(con, sql)))
}
formats <- function(sql) {
  s <- dbGetQueryArrow(con, sql)
  on.exit(s$release())
  vapply(s$get_schema()$children, `[[`, character(1), "format")
}

## The INTEGER and BIGINT minimums through Arrow ---------------------------------
sql <- "SELECT (-2147483648)::INTEGER AS i, (-9223372036854775808)::BIGINT AS b"
str(suppressWarnings(nano(sql)))
#> 'data.frame':    1 obs. of  2 variables:
#>  $ i: int NA
#>  $ b: num -9.22e+18
str(arrow_df(sql))
#> 'data.frame':    1 obs. of  2 variables:
#>  $ i: int NA
#>  $ b:integer64 NA

## An IPv6 INET address --------------------------------------------------------
sql <- "SELECT '::1'::INET AS v6, '1.2.3.4'::INET AS v4"
x <- dbGetQuery(con, sql)
format(c(v6 = x$v6$address, v4 = x$v4$address), digits = 22)
#>                             v6                             v4 
#> "-1.701411834604692317317e+38" " 1.690906000000000000000e+07"
format(1 - 2^127, digits = 22)
#> [1] "-1.701411834604692317317e+38"
format(nano(sql)$v6$address, digits = 22)
#> [1] "-1.701411834604692317317e+38"
format(arrow_df(sql)$v6$address, digits = 22)
#> [1] "-1.701411834604692317317e+38"
dbGetQuery(con, "SELECT '::1'::INET::VARCHAR AS text")
#>   text
#> 1  ::1

## produce_arrow_string_view takes an output version from 1.4 ------------------
invisible(dbExecute(con, "SET produce_arrow_string_view = true"))
formats("SELECT 'duck' AS s")
#>   s 
#> "u"
invisible(dbExecute(con, "SET arrow_output_version = '1.4'"))
formats("SELECT 'duck' AS s")
#>    s 
#> "vu"
invisible(dbExecute(con, "RESET produce_arrow_string_view"))
invisible(dbExecute(con, "RESET arrow_output_version"))

## BIGNUM: its text both ways, and Arrow ----------------------------------------
big <- "123456789012345678901234567890"
dbGetQuery(con, sprintf("SELECT %s::BIGNUM::VARCHAR AS text", big))
#>                             text
#> 1 123456789012345678901234567890
dbWriteTable(con, "bn", data.frame(b = big), field.types = c(b = "BIGNUM"))
dbGetQuery(con, "SELECT typeof(b) AS type, b::VARCHAR AS text FROM bn")
#>     type                           text
#> 1 BIGNUM 123456789012345678901234567890
formats("SELECT b FROM bn")
#>   b 
#> "z"
str(suppressWarnings(nano("SELECT b FROM bn")))
#> 'data.frame':    1 obs. of  1 variable:
#>  $ b: blob [1:1] 
#>   ..$ : raw  80 00 0d 01 ...
#>   ..@ ptype: raw
tryCatch(arrow_df("SELECT b FROM bn"), error = first_line)
#> [1] "Converter_Extension can't be used with a non-R extension type"
duckdb::duckdb_register_arrow(
  con,
  "bn_arrow",
  arrow::as_arrow_table(dbGetQueryArrow(con, "SELECT b FROM bn"))
)
dbGetQuery(con, "SELECT typeof(b) AS type, b::VARCHAR AS text FROM bn_arrow")
#>     type                           text
#> 1 BIGNUM 123456789012345678901234567890

## When nanoarrow warns on a BIGINT past 2^53 -----------------------------------
values <- c(
  "9007199254740993",
  "9007199254740994",
  "9007199254740995",
  "-9007199254740993",
  "9223372036854775807"
)
warns <- vapply(
  values,
  function(v) {
    w <- FALSE
    x <- withCallingHandlers(
      nano(sprintf("SELECT %s::BIGINT AS b", v)),
      warning = function(e) {
        w <<- TRUE
        invokeRestart("muffleWarning")
      }
    )
    sprintf("%s, warned: %s", format(x$b, digits = 22), w)
  },
  character(1)
)
data.frame(value = values, read = unname(warns))
#>                 value                              read
#> 1    9007199254740993   9007199254740992, warned: FALSE
#> 2    9007199254740994    9007199254740994, warned: TRUE
#> 3    9007199254740995    9007199254740996, warned: TRUE
#> 4   -9007199254740993  -9007199254740992, warned: FALSE
#> 5 9223372036854775807 9223372036854775808, warned: TRUE

## The spatial extension's box types cast to GEOMETRY, not from it ------------
invisible(dbExecute(con, "INSTALL spatial"))
invisible(dbExecute(con, "LOAD spatial"))
geom <- "'POLYGON ((0 0, 1 0, 1 1, 0 0))'::GEOMETRY"
for (type in c("BOX_2D", "BOX_2DF", "POLYGON_2D")) {
  print(tryCatch(
    dbGetQuery(con, sprintf("SELECT %s::%s AS x", geom, type)),
    error = first_line
  ))
}
#> [1] "Conversion Error: Unimplemented type for cast (GEOMETRY -> BOX_2D)"
#> [1] "Conversion Error: Unimplemented type for cast (GEOMETRY -> BOX_2DF)"
#>                        x
#> 1 0, 1, 1, 0, 0, 0, 1, 0
dbGetQuery(
  con,
  sprintf("SELECT typeof(ST_Extent(%s)) AS type", geom)
)
#>     type
#> 1 BOX_2D
dbGetQuery(
  con,
  sprintf("SELECT ST_AsText(ST_Extent(%s)::GEOMETRY) AS b", geom)
)
#>                                     b
#> 1 POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))
dbGetQuery(
  con,
  sprintf("SELECT ST_AsText(ST_Extent(%s)::BOX_2DF::GEOMETRY) AS b", geom)
)
#>                                     b
#> 1 POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0))

## A CRS in a type, with spatial and without it -------------------------------
# The CRS in the Arrow export's field metadata, or the error that stops it.
crs_metadata <- function(con, expr) {
  s <- tryCatch(
    dbGetQueryArrow(con, paste("SELECT", expr, "AS g")),
    error = first_line
  )
  if (is.character(s)) {
    return(substr(s, 1, 75))
  }
  on.exit(s$release())
  m <- s$get_schema()$children[[1]]$metadata[["ARROW:extension:metadata"]]
  substr(m, 1, 45)
}
bare <- dbConnect(duckdb::duckdb(shared_home = FALSE))
dbGetQuery(
  bare,
  "SELECT loaded, installed FROM duckdb_extensions() WHERE extension_name = 'spatial'"
)
#>   loaded installed
#> 1  FALSE     FALSE
geometries <- c(
  "'POINT (1 2)'::GEOMETRY('OGC:CRS84')",
  "'POINT (1 2)'::GEOMETRY('EPSG:4267')",
  "ST_SetCRS('POINT (1 2)'::GEOMETRY, 'EPSG:4267')"
)
data.frame(
  geometry = geometries,
  without_spatial = vapply(geometries, crs_metadata, character(1), con = bare),
  with_spatial = vapply(geometries, crs_metadata, character(1), con = con),
  row.names = NULL
)
#>                                          geometry                                                             without_spatial                                  with_spatial
#> 1            'POINT (1 2)'::GEOMETRY('OGC:CRS84')                               {"crs_type":"projjson","crs":{"$schema":"http {"crs_type":"projjson","crs":{"$schema":"http
#> 2            'POINT (1 2)'::GEOMETRY('EPSG:4267') Binder Error: Encountered unrecognized coordinate system 'EPSG:4267' when t {"crs_type":"projjson","crs":{"$schema":"http
#> 3 ST_SetCRS('POINT (1 2)'::GEOMETRY, 'EPSG:4267')                               {"crs_type":"authority_code","crs":"EPSG:4267 {"crs_type":"projjson","crs":{"$schema":"http
```

<sup>Created on 2026-09-28 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-09-28
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  arrow         25.0.1     2026-08-23 [2] RSPM (R 4.5.0)
#>  assertthat    0.2.1      2019-03-21 [2] RSPM (R 4.5.0)
#>  bit           4.6.0      2025-03-06 [2] RSPM
#>  bit64         4.8.6      2026-09-01 [2] RSPM
#>  blob          1.3.0      2026-01-14 [2] RSPM
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb        1.5.5.9029 2026-09-28 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  magrittr      2.0.5      2026-04-04 [2] RSPM
#>  nanoarrow   * 0.9.0      2026-08-04 [2] RSPM (R 4.5.0)
#>  otel          0.2.0      2025-08-29 [2] RSPM
#>  pillar        1.11.1     2025-09-17 [2] RSPM
#>  purrr         1.2.2      2026-04-10 [2] RSPM
#>  R6            2.6.1      2025-02-15 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  tidyselect    1.2.1      2024-03-11 [2] RSPM
#>  vctrs         0.7.3      2026-04-11 [2] RSPM
#>  withr         3.0.3      2026-06-19 [2] RSPM
#>  xfun          0.61       2026-09-16 [2] RSPM
#>  yaml          2.3.12     2025-12-10 [2] RSPM
#> 
#>  [1] <fast-path build library>
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

</details>
