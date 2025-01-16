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

// DuckDB Expressions

[[cpp11::register]] SEXP rapi_rel_project2(data_frame df, duckdb::conn_eptr_t con, list exprs) {
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


	duckdb::rel_extptr_t rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	auto projection = make_shared_ptr<ProjectionRelation>(rel->rel, std::move(projections), std::move(aliases));

	cpp11::writable::list prot = {rel};

	return rapi_rel_to_altrep2(make_external_prot<RelationWrapper>("duckdb_relation", prot, projection), con, true);
}

[[cpp11::register]] SEXP rapi_rel_filter2(data_frame df, duckdb::conn_eptr_t con, list exprs) {
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
	duckdb::rel_extptr_t rel = cpp11::as_cpp<cpp11::decay_t<duckdb::rel_extptr_t>>(rapi_rel_from_any_df(con, df, true));

	auto filter = make_shared_ptr<FilterRelation>(rel->rel, std::move(filter_expr));

	cpp11::writable::list prot = {rel};

	return rapi_rel_to_altrep2(make_external_prot<RelationWrapper>("duckdb_relation", prot, filter), con, true);
}
