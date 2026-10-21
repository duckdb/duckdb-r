# Every DuckDB type through Arrow: the field an Arrow result carries, and
# whether registering that stream back lands the same type and value, with
# the engine's default Arrow export and with arrow_lossless_conversion.
# Then the Arrow types an R user can build for the types R has no class for.
# The recorded run is arrow.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
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

dbDisconnect(con, shutdown = TRUE)
