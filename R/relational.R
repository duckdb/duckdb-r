# expressions

#' Create a column reference expression
#' @param names the column name to be referenced, could be a list to refer to schema.table.column etc.
#' @param table the optional table name or a relation object to be referenced
#' @return a column reference expression
#' @noRd
#' @examples
#' col_ref_expr <- expr_reference("some_column_name")
#' col_ref_expr2 <- expr_reference("some_column_name", "some_table_name")
expr_reference <- function(
  names,
  table = NULL,
  ...,
  alias = NULL
) {
  if (...length() > 0) {
    stop("... must be empty")
  }

  if (inherits(table, "duckdb_relation")) {
    names <- c(rel_alias(table), names)
  } else if (is.character(table) && !identical(table, "")) {
    names <- c(table, names)
  }

  if (is.null(alias)) {
    alias <- ""
  }

  rethrow_rapi_expr_reference(names, alias)
}

#' Create a constant expression
#' @param val the constant value
#' @return a constant expression
#' @noRd
#' @examples
#' const_int_expr <- expr_constant(42)
#' const_str_expr <- expr_constant("Hello, World")
expr_constant <- function(
  val,
  ...,
  alias = NULL,
  con = NULL,
  convert_opts = NULL
) {
  if (...length() > 0) {
    stop("... must be empty")
  }

  if (is.null(alias)) {
    alias <- ""
  }

  if (is.null(convert_opts)) {
    if (is.null(con)) {
      convert_opts <- duckdb_convert_opts()
    } else {
      convert_opts <- con@convert_opts
    }
  }

  rethrow_rapi_expr_constant(val, alias, convert_opts)
}

#' Create an operator expression
#' @param op the operator
#' @param exprs a list of expressions
#' @return an operator expression
#' @noRd
#' @examples
#' op_expr <- expr_operator("IN", list(expr_reference("some_column_name"), expr_constant(-42), expr_constant(42)))
expr_operator <- function(
  op,
  exprs,
  ...,
  alias = NULL
) {
  if (...length() > 0) {
    stop("... must be empty")
  }

  if (is.null(alias)) {
    alias <- ""
  }

  rethrow_rapi_expr_operator(op, exprs, alias)
}

#' Create a comparison expression
#' @param exprs a vector of size two, the expressions to compare
#' @param cmp_op the comparison operators
#' @return a comparison expression
#' @noRd
#' @examples
#' comp_expr <- expr_comparison(">", list(expr_constant(-42), expr_constant(42)))
expr_comparison <- function(
  cmp_op,
  exprs,
  ...,
  alias = NULL
) {
  if (...length() > 0) {
    stop("... must be empty")
  }

  if (is.null(alias)) {
    alias <- ""
  }

  rethrow_rapi_expr_comparison(cmp_op, exprs, alias)
}

#' Create a function call expression
#' @param name the function name
#' @param args the a list of expressions for the function arguments
#' @return a function call expression
#' @noRd
#' @examples
#' call_expr <- expr_function("ABS", list(expr_constant(-42)))
expr_function <- function(
  name,
  args,
  ...,
  order_bys = list(),
  filter_bys = list(),
  alias = NULL
) {
  if (...length() > 0) {
    stop("... must be empty")
  }

  if (is.null(alias)) {
    alias <- ""
  }

  rethrow_rapi_expr_function(name, args, order_bys, filter_bys, alias)
}

#' Convert an expression to a string for debugging purposes
#' @param expr the expression
#' @return a string representation of the expression
#' @noRd
#' @examples
#' expr_str <- expr_tostring(expr_constant(42))
expr_tostring <- function(expr) {
  rethrow_rapi_expr_tostring(expr)
}

#' Set the alias for an expression
#' @param expr the expression
#' @param alias the alias
#' @noRd
#' @examples
#' expr_set_alias(expr_constant(42), "my_alias")
expr_set_alias <- function(expr, alias) {
  rethrow_rapi_expr_set_alias(expr, alias)
}

#' @export
print.duckdb_expr <- function(x, ...) {
  message("DuckDB Expression: ", expr_tostring(x))
  invisible(NULL)
}

# relations

#' Convert a R data.frame to a DuckDB relation object
#' @param con a DuckDB DBI connection object
#' @param df the data.frame
#' @param experimental enable experimental string handling
#' @return the `duckdb_relation` object wrapping the data.frame
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
rel_from_df <- function(
  con,
  df,
  ...,
  experimental = NULL,
  convert_opts = NULL,
  strict = NULL
) {
  if (...length() > 0) {
    stop("... must be empty")
  }

  # FIXME: Enable warning
  if (is.null(convert_opts)) {
    convert_opts <- con@convert_opts
  }
  if (!is.null(experimental)) {
    convert_opts$experimental <- experimental
  }
  if (!is.null(strict)) {
    convert_opts$strict_relational <- strict
  }

  rethrow_rapi_rel_from_df(con@conn_ref, as.data.frame(df), convert_opts)
}

#' @export
print.duckdb_relation <- function(x, ...) {
  message("DuckDB Relation: \n", rel_tostring(x))
}

#' @export

as.data.frame.duckdb_relation <- function(x, row.names = NULL, optional = NULL, ...) { # nolint: object_name_linter
  if (!missing(row.names) || !missing(optional)) {
    stop("row.names and optional parameters not supported")
  }
  rethrow_rapi_rel_to_df(x)
}

#' @export
names.duckdb_relation <- function(x) {
  rethrow_rapi_rel_names(x)
}

#' @export
head.duckdb_relation <- function(x, n = 6L, ...) {
  rethrow_rapi_rel_limit(x, n)
}

#' Lazily retrieve the top-n rows of a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param n the amount of rows to retrieve
#' @return the now limited `duckdb_relation` object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel2 <- rel_limit(rel, 10)
rel_limit <- function(rel, n) {
  rethrow_rapi_rel_limit(rel, n)
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
rel_project <- function(rel, exprs) {
  rethrow_rapi_rel_project(rel, exprs)
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
rel_filter <- function(rel, exprs) {
  rethrow_rapi_rel_filter(rel, exprs)
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
rel_aggregate <- function(rel, groups, aggregates) {
  rethrow_rapi_rel_aggregate(rel, groups, aggregates)
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
rel_order <- function(rel, orders, ascending = NULL) {
  if (is.null(ascending)) {
    ascending <- rep(TRUE, length(orders))
  }

  if (length(orders) != length(ascending)) {
    stop("length of ascending must equal length of orders")
  }

  return(rethrow_rapi_rel_order(rel, orders, ascending))
}

#' Get an external pointer pointing to NULL
#' @return an external pointer pointing to null_ptr.
#' @noRd
#' @examples
#' null_ptr <- sexp_null_ptr()
# Not rethrowing, internal utility
sexp_null_ptr <- rapi_get_null_SEXP_ptr

expr_window <- function(
  window_function,
  partitions = list(),
  order_bys = list(),
  window_boundary_start = "unbounded_preceding",
  window_boundary_end = "current_row_range",
  start_expr = NULL,
  end_expr = NULL,
  offset_expr = NULL,
  default_expr = NULL,
  alias = NULL
) {
  null_ptr <- sexp_null_ptr()
  if (is.null(start_expr)) {
    start_expr <- null_ptr
  }
  if (is.null(end_expr)) {
    end_expr <- null_ptr
  }
  if (is.null(offset_expr)) {
    offset_expr <- null_ptr
  }
  if (is.null(default_expr)) {
    default_expr <- null_ptr
  }
  if (is.null(alias)) {
    alias <- ""
  }

  expr_window_(
    window_function,
    partitions,
    order_bys,
    tolower(window_boundary_start),
    tolower(window_boundary_end),
    start_expr,
    end_expr,
    offset_expr,
    default_expr,
    alias
  )
}

window_boundaries <- c("unbounded_preceding",
                       "unbounded_following",
                       "current_row_range",
                       "current_row_rows",
                       "expr_preceding_rows",
                       "expr_following_rows",
                       "expr_preceding_range")

expr_window_ <- function(
  window_function,
  partitions = list(),
  order_bys = list(),
  window_boundary_start = window_boundaries,
  window_boundary_end = window_boundaries,
  start_expr = list(),
  end_expr = list(),
  offset_expr = list(),
  default_expr = list(),
  alias = ""
) {
  window_boundary_start <- match.arg(window_boundary_start)
  window_boundary_end <- match.arg(window_boundary_end)
  rethrow_rapi_expr_window(
    window_function,
    partitions,
    order_bys,
    window_boundary_start,
    window_boundary_end,
    start_expr,
    end_expr,
    offset_expr,
    default_expr,
    alias
  )
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

rel_inner_join <- function(left, right, conds) {
  rel_join(left, right, conds, "inner", "regular")
}

rel_join <- function(left, right, conds,
                     join = c("inner", "left", "right", "outer", "cross", "semi", "anti"),
                     join_ref_type = c("regular", "natural", "cross", "positional", "asof")) {
  join <- match.arg(join)
  join_ref_type <- match.arg(join_ref_type)
  # the ref type is naturally regular. Users won't write rel_join(left, right, conds, "cross", "cross")
  # so we update it here.
  if (join == "cross" && join_ref_type == "regular") {
    join_ref_type <- "cross"
  }
  rethrow_rapi_rel_join(left, right, conds, join, join_ref_type)
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
rel_union_all <- function(rel_a, rel_b) {
  rethrow_rapi_rel_union_all(rel_a, rel_b)
}

#' Lazily compute a distinct result on a DuckDB relation object
#' @param rel the input DuckDB relation object
#' @return a new `duckdb_relation` object with distinct rows
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel2 <- rel_distinct(rel)
rel_distinct <- function(rel) {
  rethrow_rapi_rel_distinct(rel)
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
rel_set_intersect <- function(rel_a, rel_b) {
  rethrow_rapi_rel_set_intersect(rel_a, rel_b)
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
rel_set_diff <- function(rel_a, rel_b) {
  rethrow_rapi_rel_set_diff(rel_a, rel_b)
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
rel_set_symdiff <- function(rel_a, rel_b) {
  rethrow_rapi_rel_set_symdiff(rel_a, rel_b)
}

#' Run a SQL query on a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param sql a SQL query to run, use `_` to refer back to the relation
#' @return the now aggregated `duckdb_relation` object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel2 <- rel_sql(rel, "SELECT hp, cyl FROM _ WHERE hp > 100")
rel_sql <- function(rel, sql) {
  rethrow_rapi_rel_sql(rel, sql)
}

#' Print the EXPLAIN output for a DuckDB relation object
#' @param rel the DuckDB relation object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel_explain(rel)
rel_explain <- function(rel) {
  # Legacy
  cat(rethrow_rapi_rel_explain(rel, "EXPLAIN_STANDARD", "DEFAULT")[[2]][[1]])
  invisible(NULL)
}

#' Return the EXPLAIN output for a DuckDB relation object as a data frame
#' @param rel the DuckDB relation object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel_explain(rel)
rel_explain_df <- function(
  rel,
  type = c("standard", "analyze"),
  format = c("default", "text", "json", "html", "graphviz")
) {
  type <- match.arg(type)
  format <- match.arg(format)
  rethrow_rapi_rel_explain(rel, paste0("EXPLAIN_", toupper(type)), toupper(format))
}

#' Format a DuckDB relation object as a string
#' @param rel the DuckDB relation object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel_tostring(rel)
rel_tostring <- function(rel, format = c("full", "tree")) {
  format <- match.arg(format)
  rethrow_rapi_rel_tostring(rel, format)
}

#' Get the internal alias for a DuckDB relation object
#' @param rel the DuckDB relation object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel_alias(rel)
rel_alias <- function(rel) {
  rethrow_rapi_rel_alias(rel)
}

#' Set the internal alias for a DuckDB relation object
#' @param rel the DuckDB relation object
#' @param alias the new alias
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' rel_set_alias(rel, "my_new_alias")
rel_set_alias <- function(rel, alias) {
  rethrow_rapi_rel_set_alias(rel, alias)
}

#' Transforms a relation object to a lazy data frame using altrep
#' @param rel the DuckDB relation object
#' @return a data frame
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' print(rel_to_altrep(rel))
rel_to_altrep <- function(
  rel,
  allow_materialization = TRUE,
  n_rows = Inf,
  n_cells = Inf,
  ...
) {
  # FIXME: Move dots after `rel` for duckplyr >= 1.1.0
  if (...length() > 0) {
    stop("... must be empty")
  }
  if (!isTRUE(allow_materialization)) {
    n_cells <- 0
  }
  rethrow_rapi_rel_to_altrep(rel, n_rows = n_rows, n_cells = n_cells)
}


#' Retrieves the data frame back from a altrep df
#' @param df the data frame created by rel_to_altrep
#' @param strict whether to throw an error if the data frame is not an altrep
#'   or if other criteria are not met
#' @param allow_materialized whether to succeed if the data frame is already materialized
#' @return the relation object
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' df = rel_to_altrep(rel)
#' print(rel_from_altrep_df(df))
rel_from_altrep_df <- function(df, strict = TRUE, allow_materialized = TRUE, wrap = FALSE) {
  rethrow_rapi_rel_from_altrep_df(
    df,
    strict,
    allow_materialized,
    wrap
  )
}



df_is_materialized <- function(df) {
  is.null(rel_from_altrep_df(df, allow_materialized = FALSE))
}



#' Convert a relation to a SQL string
#' @param rel the DuckDB relation object
#' @return a SQL string
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' rel <- rel_from_df(con, mtcars)
#' print(rel_to_sql(rel))
rel_to_sql <- function(rel) {
  rethrow_rapi_rel_to_sql(rel)
}



#' Create a duckdb table relation from a table name
#' @param sql An SQL query
#' @return a duckdb relation
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' DBI::dbWriteTable(con, "mtcars", mtcars)
#' rel <- rel_from_sql(con, "SELECT * FROM mtcars")
rel_from_sql <- function(con, sql) {
  rethrow_rapi_rel_from_sql(con@conn_ref, sql)
}

#' Create a duckdb table relation from a table name
#' @param table the table name
#' @return a duckdb relation
#' @noRd
#' @examples
#' con <- DBI::dbConnect(duckdb())
#' DBI::dbWriteTable(con, "mtcars", mtcars)
#' rel <- rel_from_table(con, "mtcars")
rel_from_table <- function(con, table_name, schema_name = "MAIN") {
  rethrow_rapi_rel_from_table(con@conn_ref, schema_name, table_name)
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
rel_from_table_function <- function(con, function_name, positional_parameters = list(), named_parameters = list()) {
  rethrow_rapi_rel_from_table_function(con@conn_ref, function_name, positional_parameters, named_parameters)
}

rel_to_parquet <- function(rel, file_name, options = list()) {
  rethrow_rapi_rel_to_parquet(rel, file_name, options)
}

rel_to_csv <- function(rel, file_name, options = list()) {
  rethrow_rapi_rel_to_csv(rel, file_name, options)
}

rel_to_table <- function(rel, schema_name, table_name, temporary) {
  rethrow_rapi_rel_to_table(rel, schema_name, table_name, temporary)
}

rel_to_view <- function(rel, schema_name, view_name, temporary) {
  rethrow_rapi_rel_to_view(rel, schema_name, view_name, temporary)
}

rel_insert <- function(rel, schema_name, table_name) {
  rethrow_rapi_rel_insert(rel, schema_name, table_name)
}

rel_names <- function(rel) {
  rethrow_rapi_rel_names(rel)
}

load_rfuns <- function() {
  rethrow_rapi_load_rfuns()
}
