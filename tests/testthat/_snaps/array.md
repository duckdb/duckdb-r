# array errors with more than one dimention

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `duckdb_result()`:
      ! Nested arrays cannot be returned to R as column data.

# array errors with convert option array = 'none'

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `duckdb_result()`:
      ! Use connection convert option to enable arrays to be returned to R.

# array errors with default convert option array

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `duckdb_result()`:
      ! Use connection convert option to enable arrays to be returned to R.

