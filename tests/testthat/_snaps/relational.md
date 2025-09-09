# we can create comparison expressions with appropriate operators

    Code
      expr_comparison("=", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 = 42)

---

    Code
      expr_comparison("!=", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 != 42)

---

    Code
      expr_comparison(">", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 > 42)

---

    Code
      expr_comparison("<", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 < 42)

---

    Code
      expr_comparison(">=", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 >= 42)

---

    Code
      expr_comparison("<=", list(expr_constant(-42), expr_constant(42L)))
    Message
      DuckDB Expression: (-42.0 <= 42)

# we cannot create comparison expressions with inappropriate operators

    Code
      expr_comparison("z", list(expr_constant(-42), expr_constant(42L)))
    Condition
      Error:
      ! expr_comparison: Invalid comparison operator

---

    Code
      expr_comparison("2", list(expr_constant(-42), expr_constant(42L)))
    Condition
      Error:
      ! expr_comparison: Invalid comparison operator

---

    Code
      expr_comparison("-", list(expr_constant(-42), expr_constant(42L)))
    Condition
      Error:
      ! expr_comparison: Invalid comparison operator

# the altrep-conversion for relations works

    Code
      last_rel
    Message
      DuckDB Relation: 
      ---------------------
      --- Relation Tree ---
      ---------------------
      r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - Sepal.Length (DOUBLE)
      - Sepal.Width (DOUBLE)
      - Petal.Length (DOUBLE)
      - Petal.Width (DOUBLE)
      - Species (VARCHAR)
      

# rel_tostring()

    Code
      writeLines(rel_tostring(proj))
    Output
      ---------------------
      --- Relation Tree ---
      ---------------------
      Projection [x as x]
        r_dataframe_scan(0x...)
      
      ---------------------
      -- Result Columns  --
      ---------------------
      - x (DOUBLE)
      

---

    Code
      writeLines(rel_tostring(proj, "tree"))
    Output
      Projection [x as x]
        r_dataframe_scan(0x...)

# Handle zero-length lists (#186)

    Code
      expr_constant(list(integer()))
    Message
      DuckDB Expression: []

# prudence

    Code
      nrow(forbid)
    Condition
      Error:
      ! Materialization is disabled, use `collect()` or `as_tibble()` to materialize.
      i Context: GetQueryResult

---

    Code
      nrow(forbid)
    Condition
      Error:
      ! Materialization is disabled, use `collect()` or `as_tibble()` to materialize.
      i Context: GetQueryResult

---

    Code
      nrow(four_rows)
    Condition
      Error:
      ! Materialization would result in more than 4 rows. Use `collect()` or `as_tibble()` to materialize.
      i Context: GetQueryResult

---

    Code
      nrow(nine_cells)
    Condition
      Error:
      ! Materialization would result in more than 4 rows. Use `collect()` or `as_tibble()` to materialize.
      i Context: GetQueryResult

---

    Code
      nrow(bad_rows)
    Condition
      Error:
      ! Materialization would result in more than 4 rows. Use `collect()` or `as_tibble()` to materialize.
      i Context: GetQueryResult

---

    Code
      nrow(bad_cells)
    Condition
      Error:
      ! Materialization would result in more than 4 rows. Use `collect()` or `as_tibble()` to materialize.
      i Context: GetQueryResult

