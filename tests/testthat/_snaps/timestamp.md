# `time = "hms"` refuses an hms that TIME can't hold, naming its column or parameter

    Code
      dbWriteTable(con, "tbl", data.frame(a = hms::hms(c(1, -1))))
    Condition
      Error in `.local()`:
      ! Column `a` must hold times of day from 00:00:00 to 24:00:00 to write `TIME`, not -1 seconds (row 2).
      i Context: rapi_register_df
    Code
      dbWriteTable(con, "tbl", data.frame(a = hms::hms(90000)))
    Condition
      Error in `.local()`:
      ! Column `a` must hold times of day from 00:00:00 to 24:00:00 to write `TIME`, not 90000 seconds (row 1).
      i Context: rapi_register_df
    Code
      dbWriteTable(con, "tbl", data.frame(a = hms::hms(Inf)))
    Condition
      Error in `.local()`:
      ! Column `a` must hold times of day from 00:00:00 to 24:00:00 to write `TIME`, not Inf seconds (row 1).
      i Context: rapi_register_df
    Code
      dbGetQuery(con, "SELECT ? AS a", params = list(hms::hms(NaN)))
    Condition
      Error in `.local()`:
      ! `params[[1]]` must hold times of day from 00:00:00 to 24:00:00 to write `TIME`, not NaN seconds (row 1).
      i Context: rapi_bind

