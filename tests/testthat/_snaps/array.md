# array errors with more than one dimention

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `duckdb_result()`:
      ! Nested arrays cannot be returned to R as column data.
      i Context: duckdb_r_allocate

# array errors with convert option array = 'none'

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `duckdb_result()`:
      ! Use `dbConnect(array = "matrix")` to enable arrays to be returned to R.
      i Context: duckdb_r_allocate

# array errors with default convert option array

    Code
      dbGetQuery(con, "FROM tbl")
    Condition
      Error in `duckdb_result()`:
      ! Use `dbConnect(array = "matrix")` to enable arrays to be returned to R.
      i Context: duckdb_r_allocate

# array errors when writing matrix of complex numbers

    Code
      dbWriteTable(con, "tbl", df)
    Condition
      Error in `.local()`:
      ! Can't convert R type to logical type
      i Context: SexpToLogicalType
      Error in `.local()`:
      ! std::exception
      i Context: rapi_register_df

