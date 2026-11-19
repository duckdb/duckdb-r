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
      ! {"exception_type":"Invalid","exception_message":"std::exception"}
      i Context: rapi_register_df

# a classed matrix as the first column is refused before its neighbour is read

    Code
      duckdb_register(con, "r", df)
    Condition
      Error:
      ! Can't pass a matrix or array that carries a class to DuckDB. Affected column: `m` (class `Date`).
      i Context: rapi_register_df

# the environment scan refuses a matrix that carries a class

    Code
      dbGetQuery(con, "FROM df_classed")
    Condition
      Error in `dbSendQuery()`:
      ! Invalid Input Error: Can't pass a matrix or array that carries a class to DuckDB. Affected column: `m` (class `Date`).
      i Context: rapi_prepare
      i Error type: INVALID_INPUT

