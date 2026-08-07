# duplicate map keys are rejected by DuckDB

    Code
      dbGetQuery(con, "SELECT MAP {'a': 1, 'a': 2} AS m")
    Condition
      Error in `dbFetch()`:
      ! Invalid Error: Invalid Input Error: Map keys must be unique.
      i Context: rapi_execute
      i Error type: INVALID

# casting STRUCT(key, value)[] to MAP is unsupported (issue #200)

    Code
      dbGetQuery(con,
        "SELECT [{'key': 'a', 'value': 'b'}]::MAP(VARCHAR, VARCHAR) AS m")
    Condition
      Error in `dbFetch()`:
      ! Invalid Error: Conversion Error: Unimplemented type for cast (STRUCT("key" VARCHAR, "value" VARCHAR)[] -> MAP(VARCHAR, VARCHAR))
      
      LINE 1: SELECT [{'key': 'a', 'value': 'b'}]::MAP(VARCHAR, VARCHAR) AS m
                                                 ^
      i Context: rapi_execute
      i Error type: INVALID

