``` r
## duckdb-r#590 -- a `units` column (sf's st_area()) through Arrow into DuckDB
library(arrow, warn.conflicts = FALSE)
library(duckdb)
#> Loading required package: DBI
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
library(dplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
#> [1] '1.5.5'

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
#> [1] "units"

temparrow <- tempfile(fileext = ".parquet")
write_dataset(cell_areas, path = temparrow)

arrow_dataset <- open_dataset(temparrow)
arrow_dataset$schema
#> Schema
#> id: int32
#> area:  [m^2]
#> 
#> See $metadata for additional Schema metadata

# This is the call that raised
# "rapi_prepare: Unknown column type for prepare: INVALID" on 1.1.2
to_duckdb(arrow_dataset)
#> # A query:  ?? x 2
#> # Database: DuckDB 1.5.5 [unknown@Linux 6.18.5-fc-v18:R 4.5.3/:memory:]
#>      id         area
#>   <int>        <dbl>
#> 1     1 12364036567.
#> 2     2 12360269788.
#> 3     3 12352737380.

# The units column arrives as DOUBLE: the value survives, the unit label does not
con <- dbConnect(duckdb())
dbGetQuery(
  con,
  sprintf("DESCRIBE SELECT * FROM read_parquet('%s/*.parquet')", temparrow)
)
#>   column_name column_type null  key default extra
#> 1          id     INTEGER  YES <NA>    <NA>  <NA>
#> 2        area      DOUBLE  YES <NA>    <NA>  <NA>
dbGetQuery(
  con,
  sprintf("SELECT * FROM read_parquet('%s/*.parquet')", temparrow)
)
#>   id        area
#> 1  1 12364036567
#> 2  2 12360269788
#> 3  3 12352737380
dbDisconnect(con)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
