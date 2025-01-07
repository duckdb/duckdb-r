drv <- duckdb::duckdb()
con <- DBI::dbConnect(drv)
df1 <- tibble::tibble(a = 1)

"mutate"
#> [1] "mutate"
rel1 <- duckdb:::rel_from_df(con, df1)
"mutate"
#> [1] "mutate"
rel2 <- duckdb:::rel_project(
  rel1,
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
"filter"
#> [1] "filter"
rel3 <- duckdb:::rel_filter(
  rel2,
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
