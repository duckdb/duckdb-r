# Data frame scan reports a scan-time error with its message

    Code
      dbGetQuery(con, "SELECT count(*) AS n FROM with_list WHERE len(l) > 0")
    Condition
      Error in `duckdb_result()`:
      ! Invalid Input Error: SexpToValue: Only UTF-8 encoded strings are supported for the data frame scan.
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
      ! Invalid Input Error: SexpToValue: Only UTF-8 encoded strings are supported for the data frame scan.
      i Context: rapi_expr_constant
      i Error type: INVALID_INPUT

---

    Code
      rel_from_table_function(con, "repeat", list(latin1, 3L))
    Condition
      Error:
      ! Invalid Input Error: SexpToValue: Only UTF-8 encoded strings are supported for the data frame scan.
      i Context: rapi_rel_from_table_function
      i Error type: INVALID_INPUT

