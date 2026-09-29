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
str(arrow_df(sql))

## An IPv6 INET address --------------------------------------------------------
sql <- "SELECT '::1'::INET AS v6, '1.2.3.4'::INET AS v4"
x <- dbGetQuery(con, sql)
format(c(v6 = x$v6$address, v4 = x$v4$address), digits = 22)
format(1 - 2^127, digits = 22)
format(nano(sql)$v6$address, digits = 22)
format(arrow_df(sql)$v6$address, digits = 22)
dbGetQuery(con, "SELECT '::1'::INET::VARCHAR AS text")

## produce_arrow_string_view takes an output version from 1.4 ------------------
invisible(dbExecute(con, "SET produce_arrow_string_view = true"))
formats("SELECT 'duck' AS s")
invisible(dbExecute(con, "SET arrow_output_version = '1.4'"))
formats("SELECT 'duck' AS s")
invisible(dbExecute(con, "RESET produce_arrow_string_view"))
invisible(dbExecute(con, "RESET arrow_output_version"))

## BIGNUM: its text both ways, and Arrow ----------------------------------------
big <- "123456789012345678901234567890"
dbGetQuery(con, sprintf("SELECT %s::BIGNUM::VARCHAR AS text", big))
dbWriteTable(con, "bn", data.frame(b = big), field.types = c(b = "BIGNUM"))
dbGetQuery(con, "SELECT typeof(b) AS type, b::VARCHAR AS text FROM bn")
formats("SELECT b FROM bn")
str(suppressWarnings(nano("SELECT b FROM bn")))
tryCatch(arrow_df("SELECT b FROM bn"), error = first_line)
duckdb::duckdb_register_arrow(
  con,
  "bn_arrow",
  arrow::as_arrow_table(dbGetQueryArrow(con, "SELECT b FROM bn"))
)
dbGetQuery(con, "SELECT typeof(b) AS type, b::VARCHAR AS text FROM bn_arrow")

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
dbGetQuery(
  con,
  sprintf("SELECT typeof(ST_Extent(%s)) AS type", geom)
)
dbGetQuery(
  con,
  sprintf("SELECT ST_AsText(ST_Extent(%s)::GEOMETRY) AS b", geom)
)
dbGetQuery(
  con,
  sprintf("SELECT ST_AsText(ST_Extent(%s)::BOX_2DF::GEOMETRY) AS b", geom)
)

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
