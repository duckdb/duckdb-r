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
      [1m[33mError[39m:[22m
      [33m![39m expr_comparison: Invalid comparison operator

---

    Code
      expr_comparison("2", list(expr_constant(-42), expr_constant(42L)))
    Condition
      [1m[33mError[39m:[22m
      [33m![39m expr_comparison: Invalid comparison operator

---

    Code
      expr_comparison("-", list(expr_constant(-42), expr_constant(42L)))
    Condition
      [1m[33mError[39m:[22m
      [33m![39m expr_comparison: Invalid comparison operator

