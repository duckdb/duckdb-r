``` r
# DuckDB <-> R-spatial interop: which route carries a geometry, and what
# arrives. One row per route, both directions, plus the CRS detail the
# summary rows cannot hold.
# The recorded run is probe.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
#> Loading required package: DBI
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
library(geoarrow) # registers the geoarrow.wkb nanoarrow extension
options(width = 200)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

# One line of outcome, so a route fits on a row. DuckDB wraps every R-side
# failure in one "Invalid Error:", which says nothing; the rest is verbatim.
outcome <- function(expr) {
  tryCatch(
    expr,
    error = function(e) {
      msg <- gsub("\n.*", "", conditionMessage(e))
      paste("ERROR:", sub("^Invalid Error: ", "", msg))
    }
  )
}
routes <- function(...) {
  rows <- list(...)
  data.frame(
    route = vapply(rows, `[[`, character(1), 1L),
    outcome = vapply(rows, `[[`, character(1), 2L)
  )
}

con <- dbConnect(duckdb(), geometry = "wk")
invisible(dbExecute(con, "INSTALL spatial"))
invisible(dbExecute(con, "LOAD spatial"))

nc <- read_sf(system.file("shape/nc.shp", package = "sf"))[
  1:3,
  c("NAME", "geometry")
]
nc_wkb <- st_as_binary(st_geometry(nc)) # list of raw
nc_wk <- wk::as_wkb(st_geometry(nc)) # wk_wkb, carries the CRS
nc_wkt <- st_as_text(st_geometry(nc)) # character

# Which ST_ functions are core in 1.5, and which still need the extension.
core <- dbConnect(duckdb(allow_extensions = FALSE))
is_core <- function(sql) {
  tryCatch(
    {
      dbGetQuery(core, sql)
      "core"
    },
    error = function(e) {
      msg <- conditionMessage(e)
      absent <- grepl("not in the catalog|does not exist", msg) ||
        grepl("unrecognized coordinate system", msg)
      if (absent) "spatial extension" else "core"
    }
  )
}
print(
  routes(
    c(
      "GEOMETRY type, 'POINT (1 2)'::GEOMETRY",
      is_core("SELECT 'POINT (1 2)'::GEOMETRY")
    ),
    c(
      "ST_AsWKB / ST_GeomFromWKB",
      is_core("SELECT ST_GeomFromWKB(ST_AsWKB('POINT (1 2)'::GEOMETRY))")
    ),
    c("ST_AsText", is_core("SELECT ST_AsText('POINT (1 2)'::GEOMETRY)")),
    c(
      "ST_SetCRS",
      is_core("SELECT ST_SetCRS('POINT (1 2)'::GEOMETRY, 'EPSG:4326')")
    ),
    c(
      "GEOMETRY('EPSG:4326') in DDL",
      is_core("CREATE TABLE ddl (g GEOMETRY('EPSG:4326'))")
    ),
    c("ST_GeomFromText", is_core("SELECT ST_GeomFromText('POINT (1 2)')")),
    c("ST_Point", is_core("SELECT ST_Point(1, 2)")),
    c(
      "ST_Area",
      is_core("SELECT ST_Area('POLYGON ((0 0, 1 0, 1 1, 0 0))'::GEOMETRY)")
    ),
    c("ST_Read", is_core("SELECT 1 FROM ST_Read('nonexistent.shp')")),
    c(
      "ST_Transform",
      is_core(
        "SELECT ST_Transform('POINT (1 2)'::GEOMETRY, 'EPSG:4326', 'EPSG:3857')"
      )
    )
  ),
  right = FALSE
)
#>    route                                  outcome          
#> 1  GEOMETRY type, 'POINT (1 2)'::GEOMETRY core             
#> 2  ST_AsWKB / ST_GeomFromWKB              core             
#> 3  ST_AsText                              core             
#> 4  ST_SetCRS                              core             
#> 5  GEOMETRY('EPSG:4326') in DDL           spatial extension
#> 6  ST_GeomFromText                        spatial extension
#> 7  ST_Point                               spatial extension
#> 8  ST_Area                                spatial extension
#> 9  ST_Read                                spatial extension
#> 10 ST_Transform                           spatial extension
dbDisconnect(core, shutdown = TRUE)

# --- Reading: a GEOMETRY column on its way to R -----------------------

shp <- system.file("shape/nc.shp", package = "sf")
read_query <- paste0("SELECT NAME, geom FROM ST_Read('", shp, "') LIMIT 3")

# wk_crs() reads the CRS wherever the representation keeps it: an
# attribute on wk_wkb, the Arrow schema on geoarrow_vctr.
describe <- function(x) {
  crs <- tryCatch(wk::wk_crs(x), error = function(e) NULL)
  paste0(
    paste(class(x), collapse = "/"),
    if (is.list(x) && length(x) && is.raw(x[[1]])) " of raw" else "",
    ", crs ",
    if (is.null(crs) || is.na(crs)[1]) {
      "absent"
    } else if (startsWith(crs, "{")) {
      "PROJJSON"
    } else {
      crs
    }
  )
}

print(
  routes(
    c(
      "dbGetQuery(), geometry = \"blob\" (default)",
      outcome({
        con_b <- dbConnect(duckdb())
        on.exit(dbDisconnect(con_b, shutdown = TRUE))
        invisible(dbExecute(con_b, "LOAD spatial"))
        describe(dbGetQuery(con_b, read_query)$geom)
      })
    ),
    c(
      "dbGetQuery(), geometry = \"wk\"",
      outcome(describe(dbGetQuery(con, read_query)$geom))
    ),
    c(
      "dbGetQuery() + ST_AsWKB()",
      outcome({
        q <- paste0(
          "SELECT ST_AsWKB(geom) AS geom FROM ST_Read('",
          shp,
          "') LIMIT 3"
        )
        describe(dbGetQuery(con, q)$geom)
      })
    ),
    c(
      "dbGetQueryArrow() schema",
      outcome({
        s <- nanoarrow::as_nanoarrow_array_stream(dbGetQueryArrow(
          con,
          read_query
        ))
        m <- s$get_schema()$children$geom$metadata
        paste0(
          m[["ARROW:extension:name"]],
          ", crs ",
          if (is.null(m[["ARROW:extension:metadata"]])) "absent" else "present"
        )
      })
    ),
    c(
      "dbGetQueryArrow() -> data.frame (geoarrow loaded)",
      outcome({
        s <- nanoarrow::as_nanoarrow_array_stream(dbGetQueryArrow(
          con,
          read_query
        ))
        describe(as.data.frame(s)$geom)
      })
    ),
    c(
      "sf::st_read(con, <table>)",
      outcome({
        invisible(dbExecute(con, paste0("CREATE TABLE nc AS ", read_query)))
        x <- withCallingHandlers(
          st_read(con, "nc", quiet = TRUE),
          warning = function(w) {
            message("warning: ", conditionMessage(w))
            invokeRestart("muffleWarning")
          }
        )
        paste(class(x), collapse = "/")
      })
    ),
    c(
      "sf::st_read(con, query = ST_AsWKB(...))",
      outcome({
        q <- "SELECT NAME, ST_AsWKB(geom) AS geometry FROM nc"
        x <- st_read(con, query = q, geometry_column = "geometry", quiet = TRUE)
        paste0(paste(class(x), collapse = "/"), ", crs ", st_crs(x)$input)
      })
    ),
    c(
      "duckplyr's rel_from_df(), wk_wkb column",
      outcome({
        d <- data.frame(NAME = nc$NAME)
        d$geom <- nc_wk
        class(duckdb:::rel_from_df(con, d))
      })
    )
  ),
  right = FALSE
)
#> warning: Could not find a simple features geometry column. Will return a `data.frame`.
#>   route                                             outcome                                          
#> 1 dbGetQuery(), geometry = "blob" (default)         list of raw, crs absent                          
#> 2 dbGetQuery(), geometry = "wk"                     wk_wkb/wk_vctr, crs EPSG:4267                    
#> 3 dbGetQuery() + ST_AsWKB()                         list of raw, crs absent                          
#> 4 dbGetQueryArrow() schema                          geoarrow.wkb, crs present                        
#> 5 dbGetQueryArrow() -> data.frame (geoarrow loaded) geoarrow_vctr/nanoarrow_vctr, crs PROJJSON       
#> 6 sf::st_read(con, <table>)                         data.frame                                       
#> 7 sf::st_read(con, query = ST_AsWKB(...))           sf/data.frame, crs NA                            
#> 8 duckplyr's rel_from_df(), wk_wkb column           ERROR: Can't convert column `geom` to relational.

# --- Writing: an R geometry on its way into a GEOMETRY column ---------

typeof_col <- function(table, col = "geom") {
  dbGetQuery(
    con,
    paste0("SELECT typeof(", col, ") AS t FROM ", table, " LIMIT 1")
  )$t
}
with_col <- function(x) {
  d <- data.frame(NAME = nc$NAME)
  d$geom <- x
  d
}

print(
  routes(
    c(
      "dbWriteTable(), sf object",
      outcome({
        dbWriteTable(con, "w_sf", nc, overwrite = TRUE)
        typeof_col("w_sf", "geometry")
      })
    ),
    c(
      "dbWriteTable(), data.frame with sfc (MULTIPOLYGON)",
      outcome({
        dbWriteTable(con, "w_sfc", as.data.frame(nc), overwrite = TRUE)
        typeof_col("w_sfc", "geometry")
      })
    ),
    c(
      "dbWriteTable(), data.frame with sfc (POINT)",
      outcome({
        dbWriteTable(
          con,
          "w_pt",
          with_col(st_sfc(st_point(c(1, 2)))[c(1, 1, 1)]),
          overwrite = TRUE
        )
        typeof_col("w_pt")
      })
    ),
    c(
      "duckdb_register(), sf object, typed",
      outcome({
        duckdb_register(con, "w_reg", nc)
        typeof_col("w_reg", "geometry")
      })
    ),
    c(
      "duckdb_register(), sf object, fetched",
      outcome({
        class(dbGetQuery(con, "SELECT geometry FROM w_reg")$geometry)
      })
    ),
    c(
      "dbWriteTable(), wk_wkb column",
      outcome({
        dbWriteTable(con, "w_wk", with_col(nc_wk), overwrite = TRUE)
        typeof_col("w_wk")
      })
    ),
    c(
      "dbWriteTable(), list of raw (WKB)",
      outcome({
        dbWriteTable(con, "w_raw", with_col(nc_wkb), overwrite = TRUE)
        typeof_col("w_raw")
      })
    ),
    c(
      "dbWriteTable(), WKB + field.types = GEOMETRY",
      outcome({
        dbWriteTable(
          con,
          "w_ft",
          with_col(nc_wkb),
          field.types = c(geom = "GEOMETRY"),
          overwrite = TRUE
        )
        typeof_col("w_ft")
      })
    ),
    c(
      "dbWriteTable(), WKT + field.types = GEOMETRY",
      outcome({
        dbWriteTable(
          con,
          "w_wkt",
          with_col(nc_wkt),
          field.types = c(geom = "GEOMETRY"),
          overwrite = TRUE
        )
        typeof_col("w_wkt")
      })
    ),
    c(
      "dbWriteTable(), WKT + field.types = GEOMETRY('EPSG:4267')",
      outcome({
        dbWriteTable(
          con,
          "w_crs",
          with_col(nc_wkt),
          field.types = c(geom = "GEOMETRY('EPSG:4267')"),
          overwrite = TRUE
        )
        typeof_col("w_crs")
      })
    ),
    c(
      "dbWriteTable() + ALTER ... USING ST_GeomFromWKB()",
      outcome({
        dbWriteTable(con, "w_alter", with_col(nc_wkb), overwrite = TRUE)
        dbExecute(
          con,
          "ALTER TABLE w_alter ALTER COLUMN geom SET DATA TYPE GEOMETRY USING ST_GeomFromWKB(geom)"
        )
        typeof_col("w_alter")
      })
    ),
    c(
      "dbAppendTable(), WKB into a GEOMETRY column",
      outcome({
        dbAppendTable(con, "w_alter", with_col(nc_wkb))
        "appended"
      })
    ),
    c(
      "dbAppendTable(), WKT into a GEOMETRY column",
      outcome({
        dbAppendTable(con, "w_alter", with_col(nc_wkt))
        "appended"
      })
    ),
    c(
      "dbBind(), WKB into ST_GeomFromWKB(?)",
      outcome({
        r <- dbGetQuery(
          con,
          "SELECT typeof(ST_GeomFromWKB(?)) AS t",
          params = list(nc_wkb[1])
        )
        r$t
      })
    ),
    c(
      "sf::st_write(nc, dsn = con)",
      outcome({
        st_write(nc, dsn = con, layer = "w_stw")
        typeof_col("w_stw", "geometry")
      })
    ),
    c(
      "duckdb_register_arrow(), arrow table from sf",
      outcome({
        duckdb_register_arrow(con, "w_at_sf", arrow::as_arrow_table(nc))
        typeof_col("w_at_sf", "geometry")
      })
    ),
    c(
      "duckdb_register_arrow(), arrow table from wk_wkb",
      outcome({
        duckdb_register_arrow(
          con,
          "w_at_wk",
          arrow::as_arrow_table(with_col(nc_wk))
        )
        typeof_col("w_at_wk")
      })
    ),
    c(
      "duckdb_register_arrow(), nanoarrow stream",
      outcome({
        duckdb_register_arrow(
          con,
          "w_na",
          nanoarrow::as_nanoarrow_array_stream(with_col(nc_wk))
        )
        typeof_col("w_na")
      })
    ),
    c(
      "duckdb_register_arrow(), reader over a nanoarrow stream",
      outcome({
        rbr <- arrow::as_record_batch_reader(
          nanoarrow::as_nanoarrow_array_stream(with_col(nc_wk))
        )
        duckdb_register_arrow(con, "w_rbr", rbr)
        substr(typeof_col("w_rbr"), 1, 40)
      })
    )
  ),
  right = FALSE
)
#> Note: method with signature 'DBIObject#sf' chosen for function 'dbDataType',
#>  target signature 'duckdb_connection#sf'.
#>  "duckdb_connection#ANY" would also be valid
#>    route                                                     outcome                                                                                                     
#> 1  dbWriteTable(), sf object                                 ERROR: Invalid Input Error: Failed to parse geometry: Unknown geometry type at offset 0                     
#> 2  dbWriteTable(), data.frame with sfc (MULTIPOLYGON)        ERROR: Invalid Error: std::exception                                                                        
#> 3  dbWriteTable(), data.frame with sfc (POINT)               DOUBLE[]                                                                                                    
#> 4  duckdb_register(), sf object, typed                       DOUBLE[2][][][]                                                                                             
#> 5  duckdb_register(), sf object, fetched                     ERROR: Invalid Error: std::exception                                                                        
#> 6  dbWriteTable(), wk_wkb column                             BLOB                                                                                                        
#> 7  dbWriteTable(), list of raw (WKB)                         BLOB                                                                                                        
#> 8  dbWriteTable(), WKB + field.types = GEOMETRY              ERROR: Conversion Error: Unimplemented type for cast (BLOB -> GEOMETRY) when casting from source column geom
#> 9  dbWriteTable(), WKT + field.types = GEOMETRY              GEOMETRY                                                                                                    
#> 10 dbWriteTable(), WKT + field.types = GEOMETRY('EPSG:4267') GEOMETRY('EPSG:4267')                                                                                       
#> 11 dbWriteTable() + ALTER ... USING ST_GeomFromWKB()         GEOMETRY                                                                                                    
#> 12 dbAppendTable(), WKB into a GEOMETRY column               ERROR: Conversion Error: Unimplemented type for cast (BLOB -> GEOMETRY) when casting from source column geom
#> 13 dbAppendTable(), WKT into a GEOMETRY column               appended                                                                                                    
#> 14 dbBind(), WKB into ST_GeomFromWKB(?)                      GEOMETRY                                                                                                    
#> 15 sf::st_write(nc, dsn = con)                               ERROR: Invalid Input Error: Failed to parse geometry: Unknown geometry type at offset 0                     
#> 16 duckdb_register_arrow(), arrow table from sf              STRUCT(x DOUBLE, y DOUBLE)[][][]                                                                            
#> 17 duckdb_register_arrow(), arrow table from wk_wkb          BLOB                                                                                                        
#> 18 duckdb_register_arrow(), nanoarrow stream                 ERROR: std::exception                                                                                       
#> 19 duckdb_register_arrow(), reader over a nanoarrow stream   GEOMETRY('EPSG:4267')

# --- The CRS, end to end ---------------------------------------------

# Reading: both representations reach sf with the source's CRS, though
# only wk keeps the identifier the column was declared with.
c(
  wk = isTRUE(
    st_crs(st_as_sfc(dbGetQuery(con, read_query)$geom)) == st_crs(nc)
  ),
  geoarrow = isTRUE(
    st_crs(st_as_sfc(
      as.data.frame(
        nanoarrow::as_nanoarrow_array_stream(dbGetQueryArrow(con, read_query))
      )$geom
    )) ==
      st_crs(nc)
  )
)
#>       wk geoarrow 
#>     TRUE     TRUE

# The route that keeps it: geoarrow.wkb in, GEOMETRY(<PROJJSON>) out.
# A reader is consumed once, so this needs a fresh one.
duckdb_register_arrow(
  con,
  "w_rbr2",
  arrow::as_record_batch_reader(nanoarrow::as_nanoarrow_array_stream(with_col(
    nc_wk
  )))
)
invisible(dbExecute(con, "CREATE TABLE roundtrip AS SELECT * FROM w_rbr2"))
back <- dbGetQuery(con, "SELECT geom FROM roundtrip")$geom
sfc <- st_as_sfc(back)
c(
  rows = length(sfc),
  crs_equal = isTRUE(st_crs(sfc) == st_crs(nc)),
  geometry_equal = all(st_equals(sfc, st_geometry(nc), sparse = FALSE)[cbind(
    1:3,
    1:3
  )])
)
#>           rows      crs_equal geometry_equal 
#>              3              1              1

# The route that drops it: SET DATA TYPE GEOMETRY names the bare type,
# so a CRS applied in the USING clause has nowhere to live.
invisible(dbExecute(
  con,
  "ALTER TABLE w_alter ALTER COLUMN geom SET DATA TYPE GEOMETRY
     USING ST_SetCRS(geom, 'EPSG:4267')"
))
attr(dbGetQuery(con, "SELECT geom FROM w_alter")$geom, "crs")
#> NULL

# The route that keeps it without naming the CRS in DDL: a projection.
invisible(dbExecute(
  con,
  "CREATE TABLE w_setcrs AS
     SELECT NAME, ST_SetCRS(geom, 'EPSG:4267') AS geom FROM w_alter"
))
attr(dbGetQuery(con, "SELECT geom FROM w_setcrs")$geom, "crs")
#> [1] "EPSG:4267"

dbDisconnect(con, shutdown = TRUE)
```

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
#>  date     2026-08-09
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  arrow         25.0.0     2026-07-16 [1] RSPM
#>  assertthat    0.2.1      2019-03-21 [1] RSPM
#>  bit           4.6.0      2025-03-06 [1] RSPM
#>  bit64         4.8.2      2026-05-19 [1] RSPM
#>  class         7.3-23     2025-01-01 [2] CRAN (R 4.5.3)
#>  classInt      0.4-11     2025-01-08 [1] RSPM
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9013 2026-08-09 [1] local
#>  e1071         1.7-17     2025-12-18 [1] RSPM
#>  evaluate      1.0.5      2025-08-27 [1] RSPM
#>  fastmap       1.2.0      2024-05-15 [1] RSPM
#>  fs            2.1.0      2026-04-18 [1] RSPM
#>  geoarrow    * 0.4.3      2026-06-04 [1] RSPM
#>  glue          1.8.1      2026-04-17 [1] RSPM
#>  htmltools     0.5.9      2025-12-04 [1] RSPM
#>  KernSmooth    2.23-26    2025-01-01 [2] CRAN (R 4.5.3)
#>  knitr         1.51       2025-12-20 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  magrittr      2.0.5      2026-04-04 [1] RSPM
#>  nanoarrow     0.9.0      2026-08-04 [1] RSPM
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  pillar        1.11.1     2025-09-17 [1] RSPM
#>  pkgconfig     2.0.3      2019-09-22 [1] RSPM
#>  proxy         0.4-29     2025-12-29 [1] RSPM
#>  purrr         1.2.2      2026-04-10 [1] RSPM
#>  R6            2.6.1      2025-02-15 [1] RSPM
#>  Rcpp          1.1.2      2026-07-05 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.31       2026-03-26 [1] RSPM
#>  s2            1.1.11     2026-06-01 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  sf          * 1.1-2      2026-07-23 [1] RSPM
#>  tibble        3.3.1      2026-01-11 [1] RSPM
#>  tidyselect    1.2.1      2024-03-11 [1] RSPM
#>  units         1.0-1      2026-03-11 [1] RSPM
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
#> ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

</details>
