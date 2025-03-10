#include "rapi.hpp"
#include "signal.hpp"
#include "typesr.hpp"
#include "reltoaltrep.hpp"
#include "altrepdataframe_relation.hpp"

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

using namespace duckdb;
using namespace cpp11;

// DuckDB Relations: names

[[cpp11::register]] SEXP rapi_reldf_names(data_frame df, duckdb::conn_eptr_t con) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	auto ret = writable::strings();
	for (auto &col : rel->rel->Columns()) {
		ret.push_back(col.Name());
	}
	return (ret);
}

[[cpp11::register]] std::string rapi_reldf_alias(data_frame df, duckdb::conn_eptr_t con) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));
	return rel->rel->GetAlias();
}

[[cpp11::register]] SEXP rapi_reldf_set_alias(data_frame df, duckdb::conn_eptr_t con, std::string alias) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));
	cpp11::writable::list prot = {rel};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, rel->rel->Alias(alias)), con, df);
}

// DuckDB Relations: operators

[[cpp11::register]] SEXP rapi_reldf_filter(data_frame df, duckdb::conn_eptr_t con, list exprs) {
	duckdb::unique_ptr<ParsedExpression> filter_expr;
	if (exprs.size() == 0) { // nop
		warning("rel_filter without filter expressions has no effect");
		return df;
	} else if (exprs.size() == 1) {
		filter_expr = ((expr_extptr_t)exprs[0])->Copy();
	} else {
		vector<duckdb::unique_ptr<ParsedExpression>> filters;
		for (expr_extptr_t expr : exprs) {
			filters.push_back(expr->Copy());
		}
		filter_expr = make_uniq<ConjunctionExpression>(ExpressionType::CONJUNCTION_AND, std::move(filters));
	}
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	auto filter = make_shared_ptr<FilterRelation>(rel->rel, std::move(filter_expr));

	cpp11::writable::list prot = {rel};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(filter)), con, df);
}

[[cpp11::register]] SEXP rapi_reldf_project(data_frame df, duckdb::conn_eptr_t con, list exprs) {
	if (exprs.size() == 0) {
		stop("expected projection expressions");
	}
	vector<duckdb::unique_ptr<ParsedExpression>> projections;
	vector<string> aliases;

	for (expr_extptr_t expr : exprs) {
		auto dexpr = expr->Copy();
		aliases.push_back(dexpr->GetName());
		projections.push_back(std::move(dexpr));
	}


	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	auto projection = make_shared_ptr<ProjectionRelation>(rel->rel, std::move(projections), std::move(aliases));

	cpp11::writable::list prot = {rel};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(projection)), con, df);
}

[[cpp11::register]] SEXP rapi_reldf_aggregate(data_frame df, duckdb::conn_eptr_t con, list groups, list aggregates) {
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
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	auto aggregate = make_shared_ptr<AggregateRelation>(rel->rel, std::move(res_aggregates), std::move(res_groups));

	cpp11::writable::list prot = {rel};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(aggregate)), con, df);
}

[[cpp11::register]] SEXP rapi_reldf_order(data_frame df, duckdb::conn_eptr_t con, list orders, r_vector<r_bool> ascending) {
	vector<OrderByNode> res_orders;

	OrderType order_type;
	size_t i = 0;

	for (expr_extptr_t expr : orders) {
		order_type = ascending[i] ? OrderType::ASCENDING : OrderType::DESCENDING;
		i++;
		res_orders.emplace_back(order_type, OrderByNullType::NULLS_LAST, expr->Copy());
	}

	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	auto order = make_shared_ptr<OrderRelation>(rel->rel, std::move(res_orders));

	cpp11::writable::list prot = {rel};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(order)), con, df);
}

[[cpp11::register]] SEXP rapi_reldf_join(data_frame left, data_frame right, duckdb::conn_eptr_t con, list conds,
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

	auto rel_left = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, left, true));
	auto rel_right = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, right, true));

	cpp11::writable::list prot = {rel_left, rel_right};

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
		auto res = make_shared_ptr<CrossProductRelation>(rel_left->rel, rel_right->rel, ref_type);
		auto df = rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(res)), con, left);
		// if the user described filters, apply them on top of the cross product relation
		if (conds.size() > 0) {
			return rapi_reldf_filter(df, con, conds);
		}
		return df;
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

	auto res = make_shared_ptr<JoinRelation>(rel_left->rel, rel_right->rel, std::move(cond), join_type, ref_type);
	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(res)), con, left);
}

[[cpp11::register]] SEXP rapi_reldf_union_all(data_frame left, data_frame right, duckdb::conn_eptr_t con) {
	auto rel_left = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, left, true));
	auto rel_right = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, right, true));

	cpp11::writable::list prot = {rel_left, rel_right};

	auto setop = make_shared_ptr<SetOpRelation>(rel_left->rel, rel_right->rel, SetOperationType::UNION);
	setop->setop_all = true;

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(setop)), con, left);
}

[[cpp11::register]] SEXP rapi_reldf_limit(data_frame df, duckdb::conn_eptr_t con, int64_t n) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	cpp11::writable::list prot = {rel};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, make_shared_ptr<LimitRelation>(rel->rel, n, 0)), con, df);
}

[[cpp11::register]] SEXP rapi_reldf_distinct(data_frame df, duckdb::conn_eptr_t con) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	cpp11::writable::list prot = {rel};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, make_shared_ptr<DistinctRelation>(rel->rel)), con, df);
}

[[cpp11::register]] SEXP rapi_reldf_set_intersect(data_frame left, data_frame right, duckdb::conn_eptr_t con) {
	auto rel_left = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, left, true));
	auto rel_right = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, right, true));

	auto res = make_shared_ptr<SetOpRelation>(rel_left->rel, rel_right->rel, SetOperationType::INTERSECT);

	cpp11::writable::list prot = {rel_left, rel_right};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(res)), con, left);
}

[[cpp11::register]] SEXP rapi_reldf_set_diff(data_frame left, data_frame right, duckdb::conn_eptr_t con) {
	auto rel_left = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, left, true));
	auto rel_right = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, right, true));

	auto res = make_shared_ptr<SetOpRelation>(rel_left->rel, rel_right->rel, SetOperationType::EXCEPT);

	cpp11::writable::list prot = {rel_left, rel_right};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(res)), con, left);
}

[[cpp11::register]] SEXP rapi_reldf_set_symdiff(data_frame left, data_frame right, duckdb::conn_eptr_t con) {
	auto rel_left = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, left, true));
	auto rel_right = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, right, true));

	// symdiff implemented using the equation below
	// A symdiff B = (A except B) UNION (B except A)
	auto a_except_b = make_shared_ptr<SetOpRelation>(rel_left->rel, rel_right->rel, SetOperationType::EXCEPT);
	auto b_except_a = make_shared_ptr<SetOpRelation>(rel_right->rel, rel_left->rel, SetOperationType::EXCEPT);
	auto symdiff = make_shared_ptr<SetOpRelation>(a_except_b, b_except_a, SetOperationType::UNION);

	cpp11::writable::list prot = {rel_left, rel_right};

	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(symdiff)), con, left);
}

// DuckDB Relations: conversion

[[cpp11::register]] SEXP rapi_reldf_from_sql(duckdb::conn_eptr_t con, const std::string sql) {
	if (!con || !con.get() || !con->conn) {
		stop("rel_from_table: Invalid connection");
	}
	auto rel = con->conn->RelationFromQuery(sql);
	cpp11::writable::list prot = {};
	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(rel)), con, R_NilValue);
}

[[cpp11::register]] SEXP rapi_reldf_from_table(duckdb::conn_eptr_t con, const std::string schema_name,
                                             const std::string table_name) {
	if (!con || !con.get() || !con->conn) {
		stop("rel_from_table: Invalid connection");
	}
	auto rel = con->conn->Table(schema_name, table_name);
	cpp11::writable::list prot = {};
	return rapi_reldf_to_altrep(make_external_prot<RelationWrapper>("duckdb_relation", prot, std::move(rel)), con, R_NilValue);
}

[[cpp11::register]] SEXP rapi_reldf_from_table_function(duckdb::conn_eptr_t con, const std::string function_name,
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
	return rapi_reldf_to_altrep(make_external<RelationWrapper>("duckdb_relation", std::move(rel)), con, R_NilValue);
}

[[cpp11::register]] SEXP rapi_reldf_explain(data_frame df, duckdb::conn_eptr_t con, std::string type, std::string format) {
	auto type_enum = EnumUtil::FromString<ExplainType>(type);
	auto format_enum = EnumUtil::FromString<ExplainFormat>(format);

	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	return result_to_df(rel->rel->Explain(type_enum, format_enum));
}

[[cpp11::register]] void rapi_reldf_to_parquet(data_frame df, duckdb::conn_eptr_t con, std::string file_name, list options_sexps) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));
	rel->rel->WriteParquet(file_name, ListToVectorOfValue(options_sexps));
}

[[cpp11::register]] void rapi_reldf_to_csv(data_frame df, duckdb::conn_eptr_t con, std::string file_name, list options_sexps) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));
	rel->rel->WriteCSV(file_name, ListToVectorOfValue(options_sexps));
}

[[cpp11::register]] void rapi_reldf_to_table(data_frame df, duckdb::conn_eptr_t con, std::string schema_name, std::string table_name, bool temporary) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));
	rel->rel->Create(schema_name, table_name, temporary);
}

[[cpp11::register]] void rapi_reldf_insert(data_frame df, duckdb::conn_eptr_t con, std::string schema_name, std::string table_name) {
	auto rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));
	rel->rel->Insert(schema_name, table_name);
}
