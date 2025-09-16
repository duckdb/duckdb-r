#include "rapi.hpp"
#include "signal.hpp"
#include "typesr.hpp"
#include "reltoaltrep.hpp"

#include "R_ext/Random.h"

#include "duckdb/parser/expression/columnref_expression.hpp"
#include "duckdb/parser/expression/constant_expression.hpp"
#include "duckdb/parser/expression/comparison_expression.hpp"
#include "duckdb/parser/expression/function_expression.hpp"
#include "duckdb/parser/expression/comparison_expression.hpp"
#include "duckdb/parser/expression/conjunction_expression.hpp"
#include "duckdb/parser/expression/window_expression.hpp"

#include "duckdb/main/relation/filter_relation.hpp"
#include "duckdb/main/relation/projection_relation.hpp"
#include "duckdb/main/relation/aggregate_relation.hpp"
#include "duckdb/main/relation/order_relation.hpp"
#include "duckdb/main/relation/join_relation.hpp"
#include "duckdb/main/relation/cross_product_relation.hpp"
#include "duckdb/main/relation/setop_relation.hpp"
#include "duckdb/main/relation/limit_relation.hpp"
#include "duckdb/main/relation/distinct_relation.hpp"

#include "duckdb/common/enum_util.hpp"
#include "duckdb/common/enums/joinref_type.hpp"

using namespace duckdb;
using namespace cpp11;

SEXP result_to_df(duckdb::unique_ptr<duckdb::QueryResult> res) {
	if (res->HasError()) {
		stop("%s", res->GetError().c_str());
	}
	if (res->type == QueryResultType::STREAM_RESULT) {
		res = ((StreamQueryResult &)*res).Materialize();
	}
	D_ASSERT(res->type == QueryResultType::MATERIALIZED_RESULT);
	auto mat_res = (MaterializedQueryResult *)res.get();

	return duckdb_execute_R_impl(mat_res, duckdb::ConvertOpts(), RStrings::get().tbl_df_tbl_dataframe_str);
}

// Check if column has names
bool check_has_names(SEXP col, const std::string &col_name) {
	if (Rf_getAttrib(col, R_NamesSymbol) != R_NilValue && !Rf_inherits(col, "data.frame")) {
		std::string error_msg = "Can't convert named vectors to relational. Affected column: `" + col_name + "`.";
		stop(error_msg.c_str());
		return true;
	}
	return false;
}

// Check if column is an array or matrix
bool check_is_array_or_matrix(SEXP col, const std::string &col_name) {
	if (Rf_getAttrib(col, R_DimSymbol) != R_NilValue) {
		std::string error_msg = "Can't convert arrays or matrices to relational. Affected column: `" + col_name + "`.";
		stop(error_msg.c_str());
		return true;
	}
	return false;
}

// Check if column is an S4 object
bool check_is_s4_object(SEXP col, const std::string &col_name) {
	if (Rf_isS4(col)) {
		std::string error_msg = "Can't convert S4 columns to relational. Affected column: `" + col_name + "`.";
		stop(error_msg.c_str());
		return true;
	}
	return false;
}

// Check if column class is valid for relational conversion
bool check_has_valid_class(SEXP col, const std::string &col_name, const std::string &tzone) {
	SEXP col_class_sexp = Rf_getAttrib(col, R_ClassSymbol);
	bool valid = false;

	if (col_class_sexp == R_NilValue) {
		auto col_type = TYPEOF(col);
		return (col_type == LGLSXP || col_type == INTSXP || col_type == REALSXP || col_type == STRSXP ||
		        col_type == VECSXP);
	}

	writable::strings col_class = col_class_sexp;
	if (col_class.size() == 1) {
		const auto &class_name = col_class[0];
		valid =
		    (class_name == "Date" || class_name == "difftime" || class_name == "factor" || class_name == "data.frame");
	} else if (col_class.size() == 2) {
		const auto &class1 = col_class[0];
		const auto &class2 = col_class[1];

		if (class1 == "hms" && class2 == "difftime") {
			valid = true;
		} else if (class1 == "POSIXct" && class2 == "POSIXt") {
			SEXP tzone_attr = Rf_getAttrib(col, RStrings::get().tzone_sym);
			if (tzone_attr == R_NilValue) {
				if (tzone == "") {
					valid = true;
				}
			} else if (Rf_isString(tzone_attr) && LENGTH(tzone_attr) == 1 &&
			           cpp11::as_cpp<string>(tzone_attr) == tzone) {
				valid = true;
			}
		}
	}

	if (!valid) {
		std::string error_msg = "Can't convert column `" + col_name + "` to relational.";
		stop(error_msg.c_str());
		return false;
	}

	return true;
}

// Run all column checks in one function
void check_column_validity(SEXP col, const std::string &col_name, ConvertOpts::StrictRelational strict_relational,
                           const std::string &tzone) {
	check_has_names(col, col_name);
	check_is_s4_object(col, col_name);
	if (strict_relational == ConvertOpts::StrictRelational::ENABLED) {
		check_is_array_or_matrix(col, col_name);
		check_has_valid_class(col, col_name, tzone);
	}
}

// DuckDB Expressions

[[cpp11::register]] SEXP rapi_expr_reference(r_vector<r_string> rnames, std::string alias = "") {
	if (rnames.size() == 0) {
		stop("expr_reference: Zero length name vector");
	}
	duckdb::vector<std::string> names;
	for (auto name : rnames) {
		if (name.size() == 0) {
			stop("expr_reference: Zero length name");
		}
		names.push_back(name);
	}
	auto out = make_external<ColumnRefExpression>("duckdb_expr", names);
	if (alias != "") {
		out->SetAlias(std::move(alias));
	}
	return out;
}

[[cpp11::register]] SEXP rapi_expr_constant(sexp val, std::string alias, duckdb::ConvertOpts convert_opts) {
	if (LENGTH(val) != 1) {
		stop("expr_constant: Need value of length one");
	}
	check_column_validity(val, "val", convert_opts.strict_relational, convert_opts.timezone_out);
	auto const_value = RApiTypes::SexpToValue(val, 0, false);
	auto out = make_external<ConstantExpression>("duckdb_expr", const_value);
	if (alias != "") {
		out->SetAlias(std::move(alias));
	}
	return out;
}

[[cpp11::register]] SEXP rapi_expr_comparison(std::string cmp_op, list exprs, std::string alias = "") {

	ExpressionType expr_type = OperatorToExpressionType(cmp_op);
	if (expr_type == ExpressionType::INVALID) {
		stop("expr_comparison: Invalid comparison operator");
	}

	auto out = make_external<ComparisonExpression>("duckdb_expr", expr_type, expr_extptr_t(exprs[0])->Copy(),
	                                               expr_extptr_t(exprs[1])->Copy());
	if (alias != "") {
		out->SetAlias(std::move(alias));
	}
	return out;
}

[[cpp11::register]] SEXP rapi_expr_function(std::string name, list args, list order_bys, list filter_bys,
                                            std::string alias = "") {
	if (name.size() == 0) {
		stop("expr_function: Zero length name");
	}
	vector<duckdb::unique_ptr<ParsedExpression>> children;
	for (auto arg : args) {
		children.push_back(expr_extptr_t(arg)->Copy());
		// Keep aliases, rely on the caller to cautiously place them
	}

	// For aggregates you can add orders
	auto order_modifier = make_uniq<OrderModifier>();
	for (expr_extptr_t expr : order_bys) {
		order_modifier->orders.emplace_back(OrderType::ASCENDING, OrderByNullType::NULLS_LAST, expr->Copy());
	}

	// For Aggregates you can add filters
	unique_ptr<ParsedExpression> filter_expr;
	if (filter_bys.size() == 1) {
		filter_expr = ((expr_extptr_t)filter_bys[0])->Copy();
	} else {
		vector<unique_ptr<ParsedExpression>> filters;
		for (expr_extptr_t expr : filter_bys) {
			filters.push_back(expr->Copy());
		}
		filter_expr = make_uniq<ConjunctionExpression>(ExpressionType::CONJUNCTION_AND, std::move(filters));
	}

	auto func_expr = make_external<FunctionExpression>("duckdb_expr", name, std::move(children));
	if (!order_bys.empty()) {
		func_expr->order_bys = std::move(order_modifier);
	}
	if (!filter_bys.empty()) {
		func_expr->filter = std::move(filter_expr);
	}
	if (alias != "") {
		func_expr->SetAlias(std::move(alias));
	}
	return func_expr;
}

[[cpp11::register]] void rapi_expr_set_alias(duckdb::expr_extptr_t expr, std::string alias) {
	expr->alias = alias;
}

[[cpp11::register]] std::string rapi_expr_tostring(duckdb::expr_extptr_t expr) {
	return expr->ToString();
}

//
// DuckDB Relations: low-level conversion

[[cpp11::register]] SEXP rapi_get_null_SEXP_ptr() {
	auto ret = make_external<ConstantExpression>("duckdb_null_ptr", nullptr);
	return ret;
}

[[cpp11::register]] SEXP rapi_rel_from_df(duckdb::conn_eptr_t con, data_frame df, duckdb::ConvertOpts convert_opts) {
	if (!con || !con.get() || !con->conn) {
		stop("rel_from_df: Invalid connection.");
	}

	// Get row names info directly
	SEXP row_names = get_attrib(df, R_RowNamesSymbol);

	// FIXME: Check if ALTREP here?

	// Check if row names are character
	if (TYPEOF(row_names) == STRSXP) {
		stop("rel_from_df: Need data frame without row names to convert to relational, got character row names.");
	}

	// Check if row names are not empty or automatic
	auto length = Rf_xlength(row_names);
	if (length != 0) {
		if (length != 2) {
			stop("rel_from_df: Need data frame without row names to convert to relational, got numeric row names of "
			     "length %d.",
			     length);
		}
		auto first = INTEGER(row_names)[0];
		if (first != NA_INTEGER) {
			stop("rel_from_df: Need data frame without row names to convert to relational, got numeric row names with "
			     "first element not NA.");
		}
	}

	if (df.size() == 0) {
		stop("rel_from_df: Can't convert empty data frame to relational.");
	}

	// Check each column
	strings df_names = df.names();

	for (int i = 0; i < df.ncol(); i++) {
		SEXP col = df[i];
		std::string col_name = static_cast<std::string>(df_names[i]);

		// Run all column checks at once
		check_column_validity(col, col_name, convert_opts.strict_relational, convert_opts.timezone_out);
	}

	named_parameter_map_t other_params;
	auto alias = StringUtil::Format("dataframe_%d_%d", (uintptr_t)(SEXP)df,
	                                (int32_t)(NumericLimits<int32_t>::Maximum() * unif_rand()));
	auto rel =
	    con->conn->TableFunction("r_dataframe_scan", {Value::POINTER((uintptr_t)(SEXP)df)}, other_params)->Alias(alias);

	cpp11::writable::list prot = {df};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(rel), convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_to_df(duckdb::rel_extptr_t rel) {
	// For rchk
	cpp11::sexp out;

	{
		ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());

		auto res = rel->rel->Execute();

		signal_handler.HandleInterrupt();

		out = result_to_df(std::move(res));
	}

	return out;
}

//
// DuckDB Relations: questioning

[[cpp11::register]] SEXP rapi_rel_sql(duckdb::rel_extptr_t rel, std::string sql) {
	ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());

	auto res = rel->rel->Query("_", sql);

	signal_handler.HandleInterrupt();

	if (res->HasError()) {
		stop("%s", res->GetError().c_str());
	}
	return result_to_df(std::move(res));
}

//
// DuckDB Relations: names

[[cpp11::register]] SEXP rapi_rel_names(duckdb::rel_extptr_t rel) {
	auto ret = writable::strings();
	for (auto &col : rel->rel->Columns()) {
		ret.push_back(col.Name());
	}
	return (ret);
}

[[cpp11::register]] std::string rapi_rel_alias(duckdb::rel_extptr_t rel) {
	return rel->rel->GetAlias();
}

[[cpp11::register]] SEXP rapi_rel_set_alias(duckdb::rel_extptr_t rel, std::string alias) {
	cpp11::writable::list prot = {rel};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, rel->rel->Alias(alias), rel->convert_opts);
}

//
// DuckDB Relations: operators

[[cpp11::register]] SEXP rapi_rel_filter(duckdb::rel_extptr_t rel, list exprs) {
	duckdb::unique_ptr<ParsedExpression> filter_expr;
	if (exprs.size() == 0) { // nop
		warning("rel_filter without filter expressions has no effect");
		return rel;
	} else if (exprs.size() == 1) {
		filter_expr = ((expr_extptr_t)exprs[0])->Copy();
	} else {
		vector<duckdb::unique_ptr<ParsedExpression>> filters;
		for (expr_extptr_t expr : exprs) {
			filters.push_back(expr->Copy());
		}
		filter_expr = make_uniq<ConjunctionExpression>(ExpressionType::CONJUNCTION_AND, std::move(filters));
	}
	auto res = make_shared_ptr<FilterRelation>(rel->rel, std::move(filter_expr));

	cpp11::writable::list prot = {rel};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, res, rel->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_project(duckdb::rel_extptr_t rel, list exprs) {
	if (exprs.size() == 0) {
		warning("rel_project without projection expressions has no effect");
		return rel;
	}
	vector<duckdb::unique_ptr<ParsedExpression>> projections;
	vector<string> aliases;

	for (expr_extptr_t expr : exprs) {
		auto dexpr = expr->Copy();
		aliases.push_back(dexpr->GetName());
		projections.push_back(std::move(dexpr));
	}

	auto res = make_shared_ptr<ProjectionRelation>(rel->rel, std::move(projections), std::move(aliases));

	cpp11::writable::list prot = {rel};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, res, rel->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_aggregate(duckdb::rel_extptr_t rel, list groups, list aggregates) {
	vector<duckdb::unique_ptr<ParsedExpression>> res_groups, res_aggregates;

	// TODO deal with empty groups
	vector<string> aliases;

	for (expr_extptr_t expr : groups) {
		res_groups.push_back(expr->Copy());
		res_aggregates.push_back(expr->Copy());
	}

	int aggr_idx = 0; // has to be int for - reasons
	auto aggr_names = aggregates.names();

	for (expr_extptr_t expr_p : aggregates) {
		auto expr = expr_p->Copy();
		if (aggr_names.size() > aggr_idx) {
			expr->alias = aggr_names[aggr_idx];
		}
		res_aggregates.push_back(std::move(expr));
		aggr_idx++;
	}

	auto res = make_shared_ptr<AggregateRelation>(rel->rel, std::move(res_aggregates), std::move(res_groups));

	cpp11::writable::list prot = {rel};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, res, rel->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_order(duckdb::rel_extptr_t rel, list orders, r_vector<r_bool> ascending) {
	vector<OrderByNode> res_orders;

	OrderType order_type;
	size_t i = 0;

	for (expr_extptr_t expr : orders) {
		order_type = ascending[i] ? OrderType::ASCENDING : OrderType::DESCENDING;
		i++;
		res_orders.emplace_back(order_type, OrderByNullType::NULLS_LAST, expr->Copy());
	}

	auto res = make_shared_ptr<OrderRelation>(rel->rel, std::move(res_orders));

	cpp11::writable::list prot = {rel};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, res, rel->convert_opts);
}

static WindowBoundary StringToWindowBoundary(string &window_boundary) {
	if (window_boundary == "unbounded_preceding") {
		return WindowBoundary::UNBOUNDED_PRECEDING;
	} else if (window_boundary == "unbounded_following") {
		return WindowBoundary::UNBOUNDED_FOLLOWING;
	} else if (window_boundary == "current_row_range") {
		return WindowBoundary::CURRENT_ROW_RANGE;
	} else if (window_boundary == "current_row_rows") {
		return WindowBoundary::CURRENT_ROW_ROWS;
	} else if (window_boundary == "expr_preceding_rows") {
		return WindowBoundary::EXPR_PRECEDING_ROWS;
	} else if (window_boundary == "expr_following_rows") {
		return WindowBoundary::EXPR_FOLLOWING_ROWS;
	} else if (window_boundary == "expr_preceding_range") {
		return WindowBoundary::EXPR_PRECEDING_RANGE;
	} else {
		return WindowBoundary::EXPR_FOLLOWING_RANGE;
	}
}

bool constant_expression_is_not_null(duckdb::expr_extptr_t expr) {
	if (expr->type == ExpressionType::VALUE_CONSTANT) {
		auto const_expr = expr->Cast<ConstantExpression>();
		return !const_expr.value.IsNull();
	}
	return true;
}

[[cpp11::register]] SEXP rapi_expr_window(duckdb::expr_extptr_t window_function, list partitions, list order_bys,
                                          std::string window_boundary_start, std::string window_boundary_end,
                                          duckdb::expr_extptr_t start_expr, duckdb::expr_extptr_t end_expr,
                                          duckdb::expr_extptr_t offset_expr, duckdb::expr_extptr_t default_expr,
                                          std::string alias = "") {

	if (!window_function || window_function->type != ExpressionType::FUNCTION) {
		stop("expected function expression");
	}

	auto &function = (FunctionExpression &)*window_function;
	auto window_type = WindowExpression::WindowToExpressionType(function.function_name);
	auto window_expr = make_external<WindowExpression>("duckdb_expr", window_type, "", "", function.function_name);

	for (expr_extptr_t expr : order_bys) {
		window_expr->orders.emplace_back(OrderType::ASCENDING, OrderByNullType::NULLS_LAST, expr->Copy());
	}

	if (function.filter) {
		window_expr->filter_expr = function.filter->Copy();
	}

	window_expr->start = StringToWindowBoundary(window_boundary_start);
	window_expr->end = StringToWindowBoundary(window_boundary_end);
	for (auto &child : function.children) {
		window_expr->children.push_back(child->Copy());
	}
	for (expr_extptr_t partition : partitions) {
		window_expr->partitions.push_back(partition->Copy());
	}

	if (constant_expression_is_not_null(start_expr)) {
		window_expr->start_expr = start_expr->Copy();
	}
	if (constant_expression_is_not_null(end_expr)) {
		window_expr->end_expr = end_expr->Copy();
	}
	if (constant_expression_is_not_null(offset_expr)) {
		window_expr->offset_expr = offset_expr->Copy();
	}
	if (constant_expression_is_not_null(default_expr)) {
		window_expr->default_expr = default_expr->Copy();
	}

	if (alias != "") {
		window_expr->SetAlias(std::move(alias));
	}

	return window_expr;
}

[[cpp11::register]] SEXP rapi_rel_join(duckdb::rel_extptr_t left, duckdb::rel_extptr_t right, list conds,
                                       std::string join, std::string join_ref_type) {
	auto join_type = JoinType::INNER;
	auto ref_type = JoinRefType::REGULAR;
	unique_ptr<ParsedExpression> cond;

	if (join_ref_type == "regular") {
		ref_type = JoinRefType::REGULAR;
	} else if (join_ref_type == "cross") {
		ref_type = JoinRefType::CROSS;
	} else if (join_ref_type == "positional") {
		ref_type = JoinRefType::POSITIONAL;
	} else if (join_ref_type == "asof") {
		ref_type = JoinRefType::ASOF;
	}

	cpp11::writable::list prot = {left, right};

	if (join == "left") {
		join_type = JoinType::LEFT;
	} else if (join == "right") {
		join_type = JoinType::RIGHT;
	} else if (join == "outer") {
		join_type = JoinType::OUTER;
	} else if (join == "semi") {
		join_type = JoinType::SEMI;
	} else if (join == "anti") {
		join_type = JoinType::ANTI;
	} else if (join == "cross" || ref_type == JoinRefType::POSITIONAL) {
		if (ref_type != JoinRefType::POSITIONAL && ref_type != JoinRefType::CROSS) {
			// users can only supply positional cross join, or cross join.
			warning("Using `rel_join(join_ref_type = \"cross\")`");
			ref_type = JoinRefType::CROSS;
		}
		auto res = make_shared_ptr<CrossProductRelation>(left->rel, right->rel, ref_type);
		auto rel = make_external_prot<RelationWrapper>("duckdb_relation", prot, res, left->convert_opts);
		// if the user described filters, apply them on top of the cross product relation
		if (conds.size() > 0) {
			return rapi_rel_filter(rel, conds);
		}
		return rel;
	}

	if (conds.size() == 1) {
		cond = ((expr_extptr_t)conds[0])->Copy();
	} else {
		vector<duckdb::unique_ptr<ParsedExpression>> cond_args;
		for (expr_extptr_t expr : conds) {
			cond_args.push_back(expr->Copy());
		}
		cond = make_uniq<ConjunctionExpression>(ExpressionType::CONJUNCTION_AND, std::move(cond_args));
	}

	auto res = make_shared_ptr<JoinRelation>(left->rel, right->rel, std::move(cond), join_type, ref_type);
	return make_external_prot<RelationWrapper>("duckdb_relation", prot, res, left->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_union_all(duckdb::rel_extptr_t rel_a, duckdb::rel_extptr_t rel_b) {
	auto res = make_shared_ptr<SetOpRelation>(rel_a->rel, rel_b->rel, SetOperationType::UNION);
	res->setop_all = true;

	cpp11::writable::list prot = {rel_a, rel_b};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, res, rel_a->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_limit(duckdb::rel_extptr_t rel, int64_t n) {

	cpp11::writable::list prot = {rel};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, make_shared_ptr<LimitRelation>(rel->rel, n, 0),
	                                           rel->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_distinct(duckdb::rel_extptr_t rel) {

	cpp11::writable::list prot = {rel};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, make_shared_ptr<DistinctRelation>(rel->rel),
	                                           rel->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_set_intersect(duckdb::rel_extptr_t rel_a, duckdb::rel_extptr_t rel_b) {
	auto res = make_shared_ptr<SetOpRelation>(rel_a->rel, rel_b->rel, SetOperationType::INTERSECT);

	cpp11::writable::list prot = {rel_a, rel_b};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, res, rel_a->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_set_diff(duckdb::rel_extptr_t rel_a, duckdb::rel_extptr_t rel_b) {
	auto res = make_shared_ptr<SetOpRelation>(rel_a->rel, rel_b->rel, SetOperationType::EXCEPT);

	cpp11::writable::list prot = {rel_a, rel_b};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, res, rel_a->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_set_symdiff(duckdb::rel_extptr_t rel_a, duckdb::rel_extptr_t rel_b) {
	// symdiff implemented using the equation below
	// A symdiff B = (A except B) UNION (B except A)
	auto a_except_b = make_shared_ptr<SetOpRelation>(rel_a->rel, rel_b->rel, SetOperationType::EXCEPT);
	auto b_except_a = make_shared_ptr<SetOpRelation>(rel_b->rel, rel_a->rel, SetOperationType::EXCEPT);
	auto symdiff = make_shared_ptr<SetOpRelation>(a_except_b, b_except_a, SetOperationType::UNION);

	cpp11::writable::list prot = {rel_a, rel_b};

	return make_external_prot<RelationWrapper>("duckdb_relation", prot, symdiff, rel_a->convert_opts);
}

//
// DuckDB Relations: conversion

[[cpp11::register]] SEXP rapi_rel_from_sql(duckdb::conn_eptr_t con, const std::string sql) {
	if (!con || !con.get() || !con->conn) {
		stop("rel_from_table: Invalid connection");
	}
	auto rel = con->conn->RelationFromQuery(sql);
	cpp11::writable::list prot = {};
	return make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(rel), con->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_from_table(duckdb::conn_eptr_t con, const std::string schema_name,
                                             const std::string table_name) {
	if (!con || !con.get() || !con->conn) {
		stop("rel_from_table: Invalid connection");
	}
	auto rel = con->conn->Table(schema_name, table_name);
	cpp11::writable::list prot = {};
	return make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(rel), con->convert_opts);
}

[[cpp11::register]] SEXP rapi_rel_from_table_function(duckdb::conn_eptr_t con, const std::string function_name,
                                                      list positional_parameters_sexps, list named_parameters_sexps) {
	if (!con || !con.get() || !con->conn) {
		stop("rel_from_table_function: Invalid connection");
	}
	vector<Value> positional_parameters;

	for (sexp parameter_sexp : positional_parameters_sexps) {
		if (RApiTypes::GetVecSize(parameter_sexp) < 1) {
			stop("rel_from_table_function: Can't have zero-length parameter");
		}
		positional_parameters.push_back(RApiTypes::SexpToValue(parameter_sexp, 0));
	}

	named_parameter_map_t named_parameters;

	auto names = named_parameters_sexps.names();
	if (names.size() != named_parameters_sexps.size()) {
		stop("rel_from_table_function: Named parameters need names");
	}
	R_xlen_t named_parameter_idx = 0;
	for (sexp parameter_sexp : named_parameters_sexps) {
		if (RApiTypes::GetVecSize(parameter_sexp) != 1) {
			stop("rel_from_table_function: Need scalar parameter");
		}
		named_parameters[names[named_parameter_idx]] = RApiTypes::SexpToValue(parameter_sexp, 0);
		named_parameter_idx++;
	}

	auto rel = con->conn->TableFunction(function_name, std::move(positional_parameters), std::move(named_parameters));
	return make_external<RelationWrapper>("duckdb_relation", std::move(rel), con->convert_opts);
}

[[cpp11::register]] std::string rapi_rel_tostring(duckdb::rel_extptr_t rel, std::string format) {
	// FIXME: Support format = "sql" here, forwarding to rapi_rel_to_sql()
	if (format == "tree") {
		return rel->rel->ToString(0);
	} else {
		return rel->rel->ToString();
	}
}

[[cpp11::register]] std::string rapi_rel_to_sql(duckdb::rel_extptr_t rel) {
	return rel->rel->GetQueryNode()->ToString();
}

[[cpp11::register]] SEXP rapi_rel_explain(duckdb::rel_extptr_t rel, std::string type, std::string format) {
	auto type_enum = EnumUtil::FromString<ExplainType>(type);
	auto format_enum = EnumUtil::FromString<ExplainFormat>(format);
	return result_to_df(rel->rel->Explain(type_enum, format_enum));
}

[[cpp11::register]] void rapi_rel_to_parquet(duckdb::rel_extptr_t rel, std::string file_name, list options_sexps) {
	ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());

	rel->rel->WriteParquet(file_name, ListToVectorOfValue(options_sexps));

	signal_handler.HandleInterrupt();
}

[[cpp11::register]] void rapi_rel_to_csv(duckdb::rel_extptr_t rel, std::string file_name, list options_sexps) {
	ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());

	rel->rel->WriteCSV(file_name, ListToVectorOfValue(options_sexps));

	signal_handler.HandleInterrupt();
}

[[cpp11::register]] void rapi_rel_to_table(duckdb::rel_extptr_t rel, std::string schema_name, std::string table_name,
                                           bool temporary) {
	ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());

	rel->rel->Create(schema_name, table_name, temporary);

	signal_handler.HandleInterrupt();
}

[[cpp11::register]] void rapi_rel_to_view(duckdb::rel_extptr_t rel, std::string schema_name, std::string view_name,
                                          bool temporary) {
	ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());

	rel->rel->CreateView(schema_name, view_name, false, temporary);

	signal_handler.HandleInterrupt();
}

[[cpp11::register]] void rapi_rel_insert(duckdb::rel_extptr_t rel, std::string schema_name, std::string table_name) {
	ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());

	rel->rel->Insert(schema_name, table_name);

	signal_handler.HandleInterrupt();
}
