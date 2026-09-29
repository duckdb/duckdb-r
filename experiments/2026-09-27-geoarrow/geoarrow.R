# Geometry between DuckDB and sf through GeoArrow: each way to read a
# GEOMETRY column into sf, each GeoArrow encoding on the way in, what the
# CRS becomes at every step, and the routes that lose the geometry.
# The recorded run is geoarrow.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
library(sf)
library(nanoarrow)
options(width = 200)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

# One database, so that a second connection with other options sees its tables.
drv <- duckdb()
con <- dbConnect(drv)
invisible(dbExecute(con, "INSTALL spatial"))
invisible(dbExecute(con, "LOAD spatial"))

# The first three counties of nc.shp, MULTIPOLYGON in EPSG:4267, as sf
# reads them and as DuckDB's ST_Read() does.
shp <- system.file("shape/nc.shp", package = "sf")
nc <- read_sf(shp)[1:3, "NAME"]
invisible(dbExecute(
  con,
  paste0(
    "CREATE TABLE nc AS SELECT NAME, geom FROM ST_Read('",
    shp,
    "') LIMIT 3"
  )
))
# The same geometries without a CRS, and a NULL.
invisible(dbExecute(
  con,
  "CREATE TABLE bare AS SELECT NAME, ST_GeomFromWKB(ST_AsWKB(geom)) AS geom FROM nc"
))
invisible(dbExecute(con, "INSERT INTO bare VALUES ('none', NULL)"))

cell <- function(expr, width = 70) {
  out <- tryCatch(
    expr,
    error = function(e) paste("ERROR:", gsub("\n.*", "", conditionMessage(e)))
  )
  out <- paste(out, collapse = " | ")
  if (nchar(out) > width) paste0(substr(out, 1, width - 3), "...") else out
}

# An sf, or its geometry column, against the counties: the class, whether
# every geometry equals its original, and the CRS.
same_as_nc <- function(x) {
  g <- if (inherits(x, "sf")) st_geometry(x) else x
  g <- g[!st_is_empty(g)][seq_len(3)]
  equal <- all(st_equals(
    st_set_crs(g, NA),
    st_set_crs(st_geometry(nc), NA),
    sparse = FALSE
  )[cbind(1:3, 1:3)])
  crs <- if (is.na(st_crs(g))) {
    "no CRS"
  } else if (st_crs(g) == st_crs(nc)) {
    "CRS EPSG:4267"
  } else {
    "another CRS"
  }
  paste(class(x)[1], if (equal) "equal" else "differs", crs, sep = ", ")
}

# --- Reading, before geoarrow is loaded -------------------------------------

# sf's methods for Arrow objects come from geoarrow, registered when its
# namespace loads.
c(
  loaded = "geoarrow" %in% loadedNamespaces(),
  st_as_sf = cell(same_as_nc(st_as_sf(dbGetQueryArrow(
    con,
    "SELECT * FROM nc"
  ))))
)
library(geoarrow)

# --- Reading ------------------------------------------------------------------

q <- "SELECT * FROM nc"
read_routes <- list(
  "st_as_sf(dbGetQueryArrow())" = function(q) st_as_sf(dbGetQueryArrow(con, q)),
  "st_as_sf(as_arrow_table(dbGetQueryArrow()))" = function(q) {
    st_as_sf(arrow::as_arrow_table(dbGetQueryArrow(con, q)))
  },
  "st_as_sfc() of the geoarrow_vctr column" = function(q) {
    st_as_sfc(as.data.frame(dbGetQueryArrow(con, q))$geom)
  },
  "st_as_sfc() of dbGetQuery(), geometry = \"wk\"" = function(q) {
    wk_con <- dbConnect(drv, geometry = "wk")
    on.exit(dbDisconnect(wk_con))
    st_as_sfc(dbGetQuery(wk_con, q)$geom)
  },
  "st_as_sf(to_arrow(tbl()))" = function(q) {
    st_as_sf(arrow::to_arrow(dplyr::tbl(con, dplyr::sql(q))))
  },
  "duckdb_fetch_arrow()" = function(q) {
    res <- dbSendQuery(con, q, arrow = TRUE)
    on.exit(dbClearResult(res))
    st_as_sf(duckdb_fetch_arrow(res))
  },
  "duckdb_fetch_record_batch()" = function(q) {
    res <- dbSendQuery(con, q, arrow = TRUE)
    on.exit(dbClearResult(res))
    st_as_sf(arrow::as_arrow_table(duckdb_fetch_record_batch(res)))
  },
  # Cast to the bare type in the query, which drops the CRS.
  "duckdb_fetch_record_batch(), geom::GEOMETRY" = function(q) {
    res <- dbSendQuery(
      con,
      sub("SELECT \\*", "SELECT NAME, geom::GEOMETRY AS geom", q),
      arrow = TRUE
    )
    on.exit(dbClearResult(res))
    st_as_sf(arrow::as_arrow_table(duckdb_fetch_record_batch(res)))
  }
)
print(
  data.frame(
    route = names(read_routes),
    with_crs = vapply(
      read_routes,
      function(f) cell(same_as_nc(f("SELECT * FROM nc"))),
      ""
    ),
    without_crs = vapply(
      read_routes,
      function(f) cell(same_as_nc(f("SELECT * FROM bare"))),
      ""
    )
  ),
  right = FALSE,
  row.names = FALSE
)

# The CRS as each representation carries it.
c(
  arrow = cell(st_crs(st_as_sf(dbGetQueryArrow(con, q)))$input, 40),
  duckdb_type = dbGetQuery(con, "SELECT typeof(geom) FROM nc LIMIT 1")[[1]]
)

# A NULL geometry: an empty one in sf.
cell(st_is_empty(st_geometry(st_as_sf(dbGetQueryArrow(
  con,
  "SELECT * FROM bare"
)))))

# The export settings that change the layout of geoarrow.wkb's storage.
vapply(
  c("SET arrow_large_buffer_size = true", "SET arrow_output_version = '1.4'"),
  function(set) {
    invisible(dbExecute(con, set))
    on.exit(invisible(dbExecute(con, sub("SET (\\w+).*", "RESET \\1", set))))
    cell(same_as_nc(st_as_sf(dbGetQueryArrow(con, q))))
  },
  ""
)

# --- Writing --------------------------------------------------------------------

# The geometry column encoded as each GeoArrow type, beside the names.
encoded <- function(g, schema) {
  d <- data.frame(id = seq_along(g))
  d$geometry <- as_geoarrow_vctr(g, schema = schema)
  d
}
crs <- st_crs(nc)
producers <- list(
  "nanoarrow, as inferred" = function() as_nanoarrow_array_stream(nc),
  "arrow::as_arrow_table(sf)" = function() arrow::as_arrow_table(nc),
  "geoarrow_wkb(crs)" = function() {
    as_nanoarrow_array_stream(encoded(st_geometry(nc), geoarrow_wkb(crs = crs)))
  },
  "geoarrow_wkb(), no CRS" = function() {
    as_nanoarrow_array_stream(encoded(
      st_set_crs(st_geometry(nc), NA),
      geoarrow_wkb()
    ))
  },
  "geoarrow_large_wkb(crs)" = function() {
    as_nanoarrow_array_stream(encoded(
      st_geometry(nc),
      geoarrow_large_wkb(crs = crs)
    ))
  },
  "geoarrow_wkb_view(crs)" = function() {
    as_nanoarrow_array_stream(encoded(
      st_geometry(nc),
      geoarrow_wkb_view(crs = crs)
    ))
  },
  "geoarrow_wkt(crs)" = function() {
    as_nanoarrow_array_stream(encoded(st_geometry(nc), geoarrow_wkt(crs = crs)))
  },
  "geoarrow_native(MULTIPOLYGON)" = function() {
    as_nanoarrow_array_stream(encoded(
      st_geometry(nc),
      geoarrow_native("MULTIPOLYGON", crs = crs)
    ))
  },
  "wk::as_wkb() column" = function() {
    d <- data.frame(id = 1:3)
    d$geometry <- wk::as_wkb(st_geometry(nc))
    as_nanoarrow_array_stream(d)
  }
)

# Registered as an arrow Table, which DuckDB can scan more than once, then
# written into a table and read back into sf through Arrow.
n <- 0
lands <- function(make, connection = con) {
  n <<- n + 1
  v <- paste0("v", n)
  duckdb_register_arrow(connection, v, arrow::as_arrow_table(make()))
  on.exit(duckdb_unregister_arrow(connection, v))
  invisible(dbExecute(
    connection,
    paste0("CREATE TABLE w", n, " AS SELECT * FROM ", v)
  ))
  type <- dbGetQuery(
    connection,
    paste0("SELECT typeof(geometry) FROM w", n, " LIMIT 1")
  )[[1]]
  back <- tryCatch(
    same_as_nc(st_as_sf(dbGetQueryArrow(
      connection,
      paste0("SELECT * FROM w", n)
    ))),
    error = function(e) "not sf"
  )
  paste0(
    if (nchar(type) > 40) paste0(substr(type, 1, 37), "...") else type,
    "; back: ",
    back
  )
}
print(
  data.frame(
    encoding = names(producers),
    lands_as = vapply(producers, function(f) cell(lands(f), 110), "")
  ),
  right = FALSE,
  row.names = FALSE
)

# The CRS names the same system with the spatial extension or without it,
# spelled as its identifier or as the PROJJSON it came as.
bare_con <- dbConnect(duckdb(allow_extensions = FALSE))
landed <- c(
  with_spatial = lands(producers[["geoarrow_wkb(crs)"]]),
  without_spatial = lands(producers[["geoarrow_wkb(crs)"]], bare_con)
)
data.frame(
  type = substr(sub("; back: .*", "", landed), 1, 60),
  back = sub(".*; back: ", "", landed)
)
dbDisconnect(bare_con, shutdown = TRUE)

# The large and view layouts that geoarrow cannot build from an sfc,
# produced by DuckDB on a connection of its own, and scanned back.
src <- dbConnect(duckdb())
invisible(dbExecute(src, "LOAD spatial"))
vapply(
  c("SET arrow_large_buffer_size = true", "SET arrow_output_version = '1.4'"),
  function(set) {
    invisible(dbExecute(src, set))
    on.exit(invisible(dbExecute(src, sub("SET (\\w+).*", "RESET \\1", set))))
    s <- dbGetQueryArrow(
      src,
      "SELECT ST_SetCRS('POINT (1 2)'::GEOMETRY, 'EPSG:4326') AS geometry"
    )
    storage <- infer_nanoarrow_schema(s)$children$geometry$format
    duckdb_register_arrow(con, "made", arrow::as_arrow_table(s))
    on.exit(duckdb_unregister_arrow(con, "made"), add = TRUE)
    paste(
      storage,
      "->",
      dbGetQuery(con, "SELECT typeof(geometry) FROM made")[[1]]
    )
  },
  ""
)
dbDisconnect(src, shutdown = TRUE)

# What SQL makes of the encodings that do not land as GEOMETRY.
register <- function(name, d) {
  duckdb_register_arrow(
    con,
    name,
    arrow::as_arrow_table(as_nanoarrow_array_stream(d))
  )
}
points <- st_sfc(st_point(c(1, 2)), st_point(c(3, 4)), crs = 4326)
register("pts", encoded(points, geoarrow_native("POINT", crs = st_crs(points))))
register(
  "polys",
  encoded(
    st_cast(st_geometry(nc), "POLYGON"),
    geoarrow_native("POLYGON", crs = crs)
  )
)
register("wkt", encoded(st_geometry(nc), geoarrow_wkt(crs = crs)))
c(
  point_via_POINT_2D = cell(dbGetQuery(
    con,
    "SELECT ST_AsText(geometry::POINT_2D::GEOMETRY) FROM pts"
  )[[1]]),
  polygon_via_POLYGON_2D = cell(dbGetQuery(
    con,
    "SELECT geometry::POLYGON_2D::GEOMETRY FROM polys"
  )[[1]]),
  polygon_directly = cell(dbGetQuery(
    con,
    "SELECT geometry::GEOMETRY FROM polys"
  )[[1]]),
  wkt_cast_and_crs = cell(dbGetQuery(
    con,
    "SELECT DISTINCT typeof(ST_SetCRS(geometry::GEOMETRY, 'EPSG:4267')) FROM wkt"
  )[[1]])
)

# --- What loses the geometry ----------------------------------------------------

# A registered reader is a stream, scanned once; a Table is scanned again.
duckdb_register_arrow(
  con,
  "once",
  arrow::as_record_batch_reader(producers[["geoarrow_wkb(crs)"]]())
)
duckdb_register_arrow(
  con,
  "again",
  arrow::as_arrow_table(producers[["geoarrow_wkb(crs)"]]())
)
c(
  reader = paste(
    nrow(dbGetQuery(con, "SELECT id FROM once")),
    nrow(dbGetQuery(con, "SELECT id FROM once")),
    sep = " then "
  ),
  table = paste(
    nrow(dbGetQuery(con, "SELECT id FROM again")),
    nrow(dbGetQuery(con, "SELECT id FROM again")),
    sep = " then "
  )
)

# A geoarrow_vctr is an integer vector of indices into the Arrow data it
# holds, and the routes through an R data frame write those integers.
from_r <- function(write) {
  n <<- n + 1
  t <- paste0("r", n)
  write(t)
  r <- dbGetQuery(
    con,
    paste("SELECT typeof(geometry) AS t, geometry::VARCHAR AS v FROM", t)
  )
  paste(r$t[1], paste(r$v, collapse = ", "))
}
c(
  dbWriteTable = cell(from_r(function(t) {
    d <- as.data.frame(dbGetQueryArrow(
      con,
      "SELECT NAME, geom AS geometry FROM nc"
    ))
    dbWriteTable(con, t, d)
  })),
  dbWriteTableArrow = cell(from_r(function(t) {
    dbWriteTableArrow(con, t, producers[["geoarrow_wkb(crs)"]]())
  }))
)

dbDisconnect(con)
duckdb_shutdown(drv)
