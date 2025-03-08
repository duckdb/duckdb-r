#' Lazily retrieve the top-n rows of a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param n the amount of rows to retrieve
#' @return the now limited `duckdb_relation` object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel2 <- rel_limit(rel, 10)
reldf_limit <- function(df, con, n) {
  rethrow_rapi_reldf_limit(df, con@conn_ref, n)
}

#' Lazily project a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param exprs a list of DuckDB expressions to project
#' @return the now projected `duckdb_relation` object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel2 <- rel_project(rel, list(expr_reference("cyl"), expr_reference("disp")))
reldf_project <- function(df, con, exprs) {
  rethrow_rapi_reldf_project(df, con@conn_ref, exprs)
}

#' Lazily filter a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param exprs a list of DuckDB expressions to filter by
#' @return the now filtered `duckdb_relation` object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' DBI::dbExecute(con, "CREATE OR REPLACE MACRO gt(a, b) AS a > b")
#' rel <- rel_from_df(con, mtcars)
#' rel2 <- rel_filter(rel, list(expr_function("gt", list(expr_reference("cyl"), expr_constant("6")))))
reldf_filter <- function(df, con, exprs) {
  rethrow_rapi_reldf_filter(df, con@conn_ref, exprs)
}

#' Lazily aggregate a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param groups a list of DuckDB expressions to group by
#' @param aggregates a (optionally named) list of DuckDB expressions with aggregates to compute
#' @return the now aggregated `duckdb_relation` object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' aggrs <- list(avg_hp = expr_function("avg", list(expr_reference("hp"))))
#' rel2 <- rel_aggregate(rel, list(expr_reference("cyl")), aggrs)
reldf_aggregate <- function(df, con, groups, aggregates) {
  rethrow_rapi_reldf_aggregate(df, con@conn_ref, groups, aggregates)
}

#' Lazily reorder a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param orders a list of DuckDB expressions to order by
#' @param ascending a vector of boolean values describing sort order of expressions. True for ascending.
#' @return the now aggregated `duckdb_relation` object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel2 <- rel_order(rel, list(expr_reference("hp")))
reldf_order <- function(df, con, orders, ascending = NULL) {
  if (is.null(ascending)) {
    ascending <- rep(TRUE, length(orders))
  }

  if (length(orders) != length(ascending)) {
    stop("length of ascending must equal length of orders")
  }

  return(rethrow_rapi_reldf_order(df, con@conn_ref, orders, ascending))
}

#' Lazily INNER join two DuckDB relation objects
#' @param left the left-hand-side DuckDB relation object
#' @param right the right-hand-side DuckDB relation object
#' @param conds a list of DuckDB expressions to use for the join
#' @param join a string describing the join type (either "inner", "left", "right", or "outer")
#' @return a new `duckdb_relation` object resulting from the join
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' DBI::dbExecute(con, "CREATE OR REPLACE MACRO eq(a, b) AS a = b")
#' left <- rel_from_df(con, mtcars)
#' right <- rel_from_df(con, mtcars)
#' cond <- list(expr_function("eq", list(expr_reference("cyl", left), expr_reference("cyl", right))))
#' rel2 <- rel_join(left, right, cond, "inner")
#' rel2 <- rel_join(left, right, cond, "right")
#' rel2 <- rel_join(left, right, cond, "left")
#' rel2 <- rel_join(left, right, cond, "outer")
reldf_join <- function(
  left,
  right,
  con,
  conds,
  join = c("inner", "left", "right", "outer", "cross", "semi", "anti"),
  join_ref_type = c("regular", "natural", "cross", "positional", "asof")
) {
  join <- match.arg(join)
  join_ref_type <- match.arg(join_ref_type)
  # the ref type is naturally regular. Users won't write rel_join(left, right, conds, "cross", "cross")
  # so we update it here.
  if (join == "cross" && join_ref_type == "regular") {
    join_ref_type <- "cross"
  }
  rethrow_rapi_reldf_join(left, right, con@conn_ref, conds, join, join_ref_type)
}

#' UNION ALL on two DuckDB relation objects
#' @param rel_a a DuckDB relation object
#' @param rel_b a DuckDB relation object
#' @return a new `duckdb_relation` object resulting from the union
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel_a <- rel_from_df(con, mtcars)
#' rel_b <- rel_from_df(con, mtcars)
#' rel_union_all(rel_a, rel_b)
reldf_union_all <- function(df_a, df_b, con) {
  rethrow_rapi_reldf_union_all(df_a, df_b, con@conn_ref)
}

#' Lazily compute a distinct result on a DuckDB relation object
#' @param rel the input DuckDB relation object
#' @return a new `duckdb_relation` object with distinct rows
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel2 <- rel_distinct(rel)
reldf_distinct <- function(df, con) {
  rethrow_rapi_reldf_distinct(df, con@conn_ref)
}

#' SET INTERSECT on two DuckDB relation objects
#' @param rel_a a DuckDB relation object
#' @param rel_b a DuckDB relation object
#' @return a new `duckdb_relation` object resulting from the intersection
#' @noRd
#' @examples
#' rel_a <- rel_from_df(con, mtcars)
#' rel_b <- rel_from_df(con, mtcars)
#' rel_set_intersect_all(rel_a, rel_b)
reldf_set_intersect <- function(df_a, df_b, con) {
  rethrow_rapi_reldf_set_intersect(df_a, df_b, con@conn_ref)
}

#' SET DIFF on two DuckDB relation objects
#' @param rel_a a DuckDB relation object
#' @param rel_b a DuckDB relation object
#' @return a new `duckdb_relation` object resulting from the set difference
#' @noRd
#' @examples
#' rel_a <- rel_from_df(con, mtcars)
#' rel_b <- rel_from_df(con, mtcars)
#' rel_set_diff(rel_a, rel_b)
reldf_set_diff <- function(df_a, df_b, con) {
  rethrow_rapi_reldf_set_diff(df_a, df_b, con@conn_ref)
}

#' SET SYMDIFF on two DuckDB relation objects
#' @param rel_a a DuckDB relation object
#' @param rel_b a DuckDB relation object
#' @return a new `duckdb_relation` object resulting from the symmetric difference of rel_a and rel_b
#' @noRd
#' @examples
#' rel_a <- rel_from_df(con, mtcars)
#' rel_b <- rel_from_df(con, mtcars)
#' rel_set_symdiff(rel_a, rel_b)
reldf_set_symdiff <- function(df_a, df_b, con) {
  rethrow_rapi_reldf_set_symdiff(df_a, df_b, con@conn_ref)
}

#' Print the EXPLAIN output for a DuckDB relation object
#' @param rel the DuckDB relation object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel_explain(rel)
reldf_explain <- function(df, con) {
  # Legacy
  cat(rethrow_rapi_reldf_explain(df, con@conn_ref, "EXPLAIN_STANDARD", "DEFAULT")[[2]][[1]])
  invisible(NULL)
}

#' Get the internal alias for a DuckDB relation object
#' @param rel the DuckDB relation object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel_alias(rel)
reldf_alias <- function(df, con) {
  rethrow_rapi_reldf_alias(df, con@conn_ref)
}

#' Set the internal alias for a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param alias the new alias
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel_set_alias(rel, "my_new_alias")
reldf_set_alias <- function(df, con, alias) {
  rethrow_rapi_reldf_set_alias(df, con@conn_ref, alias)
}

#' Create a duckdb table relation from a table name
#' @param sql An SQL query
#' @return a duckdb relation
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' DBI::dbWriteTable(con, "mtcars", mtcars)
#' rel <- rel_from_sql(con, "SELECT * FROM mtcars")
reldf_from_sql <- function(con, sql) {
    rethrow_rapi_reldf_from_sql(con@conn_ref, sql)
}

#' Create a duckdb table relation from a table name
#' @param table the table name
#' @return a duckdb relation
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' DBI::dbWriteTable(con, "mtcars", mtcars)
#' rel <- rel_from_table(con, "mtcars")
reldf_from_table <- function(con, table_name, schema_name = "MAIN") {
  rethrow_rapi_reldf_from_table(con@conn_ref, schema_name, table_name)
}

#' Convert a duckdb relation from a table-producing function
#' @param name the table function name
#' @param positional_parameters the table function positional parameters list
#' @param named_parameters the table function named parameters list
#' @return a duckdb relation
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_table_function(con, 'generate_series', list(10L))
reldf_from_table_function <- function(con, function_name, positional_parameters = list(), named_parameters = list()) {
  rethrow_rapi_reldf_from_table_function(con@conn_ref, function_name, positional_parameters, named_parameters)
}

reldf_to_parquet <- function(df, con, file_name, options = list()) {
  rethrow_rapi_reldf_to_parquet(df, con@conn_ref, file_name, options)
}

reldf_to_csv <- function(df, con, file_name, options = list()) {
  rethrow_rapi_reldf_to_csv(df, con@conn_ref, file_name, options)
}

reldf_to_table <- function(df, con, schema_name, table_name, temporary) {
  rethrow_rapi_reldf_to_table(df, con@conn_ref, schema_name, table_name, temporary)
}

reldf_insert <- function(df, con, schema_name, table_name) {
  rethrow_rapi_reldf_insert(df, con@conn_ref, schema_name, table_name)
}

reldf_names <- function(df, con) {
  rethrow_rapi_reldf_names(df, con@conn_ref)
}
