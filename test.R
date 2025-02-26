drv <- duckdb::duckdb()
con <- DBI::dbConnect(drv)
df1 <- tibble::tibble(a = 1)

df1
"mutate"
rel2 <- duckdb:::rel_project2(
  df1,
  con,
  list(
    {
      tmp_expr <- duckdb:::expr_reference("a")
      duckdb:::expr_set_alias(tmp_expr, "a")
      tmp_expr
    },
    {
      tmp_expr <- duckdb:::expr_constant(2)
      duckdb:::expr_set_alias(tmp_expr, "b")
      tmp_expr
    }
  )
)

df2 <- duckdb:::rel_to_altrep(rel2)
df1
df2
typeof(df1)
typeof(df2)

"filter"
rel3 <- duckdb:::rel_filter2(
  df2,
  con,
  list(
    duckdb:::expr_comparison(
      "==",
      list(
        duckdb:::expr_reference("b"),
        duckdb:::expr_constant(2)
      )
    )
  )
)
rel2
rel3
duckdb:::rel_to_altrep(rel2)
rel2
rel3
