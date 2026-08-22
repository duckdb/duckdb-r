## duckdb-r#590 -- a `units` column (sf's st_area()) through Arrow into DuckDB
library(arrow, warn.conflicts = FALSE)
library(duckdb)
library(sf)
library(dplyr, warn.conflicts = FALSE)
packageVersion("duckdb")

cell_areas <- st_as_sf(data.frame(
  id = 1:3,
  geometry = st_sfc(
    st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1), c(0, 0)))),
    st_polygon(list(rbind(c(1, 1), c(2, 1), c(2, 2), c(1, 2), c(1, 1)))),
    st_polygon(list(rbind(c(2, 2), c(3, 2), c(3, 3), c(2, 3), c(2, 2))))
  )
)) |>
  st_set_crs(4326) |>
  mutate(area = st_area(geometry)) |> # a units column, the trigger in #590
  st_drop_geometry()

class(cell_areas$area)

temparrow <- tempfile(fileext = ".parquet")
write_dataset(cell_areas, path = temparrow)

arrow_dataset <- open_dataset(temparrow)
arrow_dataset$schema

# This is the call that raised
# "rapi_prepare: Unknown column type for prepare: INVALID" on 1.1.2
to_duckdb(arrow_dataset)

# The units column arrives as DOUBLE: the value survives, the unit label does not
con <- dbConnect(duckdb())
dbGetQuery(
  con,
  sprintf("DESCRIBE SELECT * FROM read_parquet('%s/*.parquet')", temparrow)
)
dbGetQuery(
  con,
  sprintf("SELECT * FROM read_parquet('%s/*.parquet')", temparrow)
)
dbDisconnect(con)
