# array errors with more than one dimention

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `dbFetch()`:
      ! Nested arrays cannot be returned to R as column data.
      i Context: duckdb_r_allocate

# array errors with convert option array = 'none'

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `dbFetch()`:
      ! Use `dbConnect(array = "matrix")` to enable arrays to be returned to R.
      i Context: duckdb_r_allocate

# array errors with default convert option array

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `dbFetch()`:
      ! Use `dbConnect(array = "matrix")` to enable arrays to be returned to R.
      i Context: duckdb_r_allocate

