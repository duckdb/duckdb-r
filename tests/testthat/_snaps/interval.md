# a Period with more than seconds is refused under the default `interval`, on every route

    Code
      dbWriteTable(con, "tbl", data.frame(a = c(lubridate::seconds(1), p)))
    Condition
      Error in `.local()`:
      ! Column `a` must hold periods of seconds alone to write a `DOUBLE`, not 0y 1m 0d 0H 5M 6.5S (row 2). Use `dbConnect(interval = "Period")` to write an exact `INTERVAL`, or `lubridate::period_to_seconds()` for a `DOUBLE` of the total.
      i Context: rapi_register_df
    Code
      duckdb_register(con, "field", field)
    Condition
      Error:
      ! Column `s$p` must hold periods of seconds alone to write a `DOUBLE`, not 0y 1m 0d 0H 5M 6.5S (row 1). Use `dbConnect(interval = "Period")` to write an exact `INTERVAL`, or `lubridate::period_to_seconds()` for a `DOUBLE` of the total.
      i Context: rapi_register_df
    Code
      dbWriteTable(con, "cell", cell)
    Condition
      Error in `.local()`:
      ! Column `l[[1]]` must hold periods of seconds alone to write a `DOUBLE`, not 0y 1m 0d 0H 5M 6.5S (element 2). In a list, a `Period` writes a `DOUBLE` whatever `interval` says, so use `lubridate::period_to_seconds()` for a `DOUBLE` of the total.
      i Context: rapi_register_df
    Code
      dbGetQuery(con, "SELECT ? AS a", params = list(p))
    Condition
      Error in `.local()`:
      ! `params[[1]]` must hold periods of seconds alone to write a `DOUBLE`, not 0y 1m 0d 0H 5M 6.5S (row 1). Use `dbConnect(interval = "Period")` to write an exact `INTERVAL`, or `lubridate::period_to_seconds()` for a `DOUBLE` of the total.
      i Context: rapi_bind

# a Period in a list writes its seconds alone under `interval = "Period"` too

    Code
      dbAppendTable(con, "tbl", more)
    Condition
      Error in `dbAppendTable()`:
      ! Column `l[[1]]` must hold periods of seconds alone to write a `DOUBLE`, not 0y 0m 1d 0H 0M 0S (element 1). In a list, a `Period` writes a `DOUBLE` whatever `interval` says, so use `lubridate::period_to_seconds()` for a `DOUBLE` of the total.
      i Context: rapi_register_df
    Code
      dbWriteTable(con, "map", map, field.types = c(m = "MAP(VARCHAR, INTERVAL)"))
    Condition
      Error in `.local()`:
      ! Column `m[[1]]$value` must hold periods of seconds alone to write a `DOUBLE`, not 0y 2m 0d 0H 0M 0S (element 1). In a list, a `Period` writes a `DOUBLE` whatever `interval` says, so use `lubridate::period_to_seconds()` for a `DOUBLE` of the total.
      i Context: rapi_register_df

# `interval = "Period"` refuses a Period that INTERVAL can't hold, naming its column or parameter

    Code
      dbWriteTable(con, "tbl", data.frame(a = lubridate::period(seconds = c(1, Inf))))
    Condition
      Error in `.local()`:
      ! Column `a` must hold periods that fit an `INTERVAL`, not 0y 0m 0d 0H 0M InfS (row 2).
      i Context: rapi_register_df
    Code
      dbGetQuery(con, "SELECT ? AS a", params = list(lubridate::period(months = 3e+09)))
    Condition
      Error in `.local()`:
      ! `params[[1]]` must hold periods that fit an `INTERVAL`, not 0y 3000000000m 0d 0H 0M 0S (row 1).
      i Context: rapi_bind

