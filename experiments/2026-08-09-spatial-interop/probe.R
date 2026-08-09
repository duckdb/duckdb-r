# DuckDB <-> R-spatial interop: which route carries a geometry, and what
# arrives. One row per route, both directions, plus the CRS detail the
# summary rows cannot hold.
# The recorded run is probe.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
library(sf)
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

# The route that drops it: SET DATA TYPE GEOMETRY names the bare type,
# so a CRS applied in the USING clause has nowhere to live.
invisible(dbExecute(
  con,
  "ALTER TABLE w_alter ALTER COLUMN geom SET DATA TYPE GEOMETRY
     USING ST_SetCRS(geom, 'EPSG:4267')"
))
attr(dbGetQuery(con, "SELECT geom FROM w_alter")$geom, "crs")

# The route that keeps it without naming the CRS in DDL: a projection.
invisible(dbExecute(
  con,
  "CREATE TABLE w_setcrs AS
     SELECT NAME, ST_SetCRS(geom, 'EPSG:4267') AS geom FROM w_alter"
))
attr(dbGetQuery(con, "SELECT geom FROM w_setcrs")$geom, "crs")

dbDisconnect(con, shutdown = TRUE)
