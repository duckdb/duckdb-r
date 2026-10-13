# Data frame scan reports a scan-time error with its message

    Code
      dbGetQuery(con, "SELECT count(*) AS n FROM with_list WHERE len(l) > 0")
    Condition
      Error in `duckdb_result()`:
      ! Invalid Input Error: SexpToValue: Only UTF-8 encoded strings are supported for the data frame scan.
      i Context: rapi_execute
      i Error type: INVALID_INPUT

# A scan task on R's thread keeps its message

    Code
      dbGetQuery(con, "SELECT count(*) AS n FROM mats WHERE len(l) > 0")
    Condition
      Error in `duckdb_result()`:
      ! Invalid Input Error: duckdb_sexp_to_value: Unsupported RTypeId
      i Context: rapi_execute
      i Error type: INVALID_INPUT

# Errors raised on R's thread keep their context

    Code
      duckdb_register(con, "empty", data.frame())
    Condition
      Error:
      ! Data frame with at least one column required
      i Context: rapi_register_df

# An entry point reports the scan's encoding check through R

    Code
      expr_constant(latin1)
    Condition
      Error:
      ! Only UTF-8 encoded strings are supported for the data frame scan.
      i Context: SexpToValue

---

    Code
      rel_from_table_function(con, "repeat", list(latin1, 3L))
    Condition
      Error:
      ! Only UTF-8 encoded strings are supported for the data frame scan.
      i Context: SexpToValue

# An entry point reports the engine's UTF-8 check through R

    Code
      expr_constant(bad)
    Condition
      Error:
      ! Invalid Input Error: Invalid unicode (byte sequence mismatch) detected in value construction
      i Context: SexpToValue
      i Error type: INVALID_INPUT

---

    Code
      dbGetQuery(con, "SELECT ?", params = list(bad))
    Condition
      Error in `.local()`:
      ! Invalid Input Error: Invalid unicode (byte sequence mismatch) detected in value construction
      i Context: SexpToValue
      i Error type: INVALID_INPUT

# An error raised while the engine binds a data frame keeps its message

    Code
      duckdb_register(con, "cplx", data.frame(z = 0+1i))
    Condition
      Error:
      ! Invalid Input Error: SexpToLogicalType: Can't convert R type to logical type
      i Context: rapi_register_df
      i Error type: INVALID_INPUT

