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

