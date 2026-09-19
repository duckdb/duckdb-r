#include "duckdb/common/arrow/arrow_wrapper.hpp"
#include "duckdb/common/enum_util.hpp"
#include "duckdb/function/table/arrow.hpp"
#include "duckdb/main/external_dependencies.hpp"
#include "duckdb/parser/expression/constant_expression.hpp"
#include "duckdb/parser/expression/function_expression.hpp"
#include "duckdb/planner/expression/bound_comparison_expression.hpp"
#include "duckdb/planner/expression/bound_conjunction_expression.hpp"
#include "duckdb/planner/expression/bound_constant_expression.hpp"
#include "duckdb/planner/expression/bound_function_expression.hpp"
#include "duckdb/planner/expression/bound_operator_expression.hpp"
#include "duckdb/planner/expression/bound_reference_expression.hpp"
#include "duckdb/planner/filter/conjunction_filter.hpp"
#include "duckdb/planner/filter/constant_filter.hpp"
#include "duckdb/planner/filter/expression_filter.hpp"
#include "duckdb/planner/filter/in_filter.hpp"
#include "duckdb/planner/filter/optional_filter.hpp"
#include "duckdb/planner/filter/table_filter_functions.hpp"
#include "duckdb/planner/table_filter.hpp"
#include "duckdb/planner/table_filter_set.hpp"
#include "rapi.hpp"
#include "signal.hpp"
#include "typesr.hpp"

// Avoid clash with TRUE and FALSE macros in older rtools
#undef TRUE
#undef FALSE

using namespace duckdb;

[[cpp11::register]] void rapi_register_df(duckdb::conn_eptr_t conn, std::string name, cpp11::data_frame value,
                                          duckdb::ConvertOpts convert_opts, bool overwrite) {
	if (!conn || !conn.get() || !conn->conn) {
		rapi_error_with_context("rapi_register_df", "Invalid connection");
	}
	if (name.empty()) {
		rapi_error_with_context("rapi_register_df", "Name cannot be empty");
	}
	if (value.ncol() < 1) {
		rapi_error_with_context("rapi_register_df", "Data frame with at least one column required");
	}

	ScopedInterruptHandler signal_handler(conn->conn->context);

	try {
		named_parameter_map_t parameter_map;
		parameter_map["integer64"] = convert_opts.bigint == ConvertOpts::BigIntType::INTEGER64;
		parameter_map["experimental"] = convert_opts.experimental == ConvertOpts::ExperimentalFeatures::ENABLED;
		parameter_map["map_list_of"] = convert_opts.map == ConvertOpts::MapShape::LIST_OF;

		conn->conn->TableFunction("r_dataframe_scan", {Value::POINTER((uintptr_t)value.data())}, parameter_map)
		    ->CreateView(Identifier(name), overwrite, true);

		signal_handler.HandleInterrupt();

		static_cast<cpp11::sexp>(conn).attr("_registered_df_" + name) = value;
	} catch (std::exception &e) {
		rapi_error_with_context("rapi_register_df", e);
	}
}

[[cpp11::register]] void rapi_unregister_df(duckdb::conn_eptr_t conn, std::string name) {
	if (!conn || !conn.get() || !conn->conn) {
		return;
	}

	ScopedInterruptHandler signal_handler(conn->conn->context);

	static_cast<cpp11::sexp>(conn).attr("_registered_df_" + name) = R_NilValue;
	auto res = conn->conn->Query("DROP VIEW IF EXISTS \"" + name + "\"");

	signal_handler.HandleInterrupt();

	if (res->HasError()) {
		rapi_error_with_context("rapi_unregister_df", res->GetErrorObject());
	}
}

unique_ptr<TableRef> duckdb::EnvironmentScanReplacement(ClientContext &context, ReplacementScanInput &input,
                                                        optional_ptr<ReplacementScanData> data_p) {
	auto &data = (ReplacementDataDBWrapper &)*data_p;
	auto db_wrapper = data.wrapper;

	// The binder holds the client context lock across this, and looking the name
	// up forces a promise -- arbitrary R code, and with it a garbage collection.
	RCallbackScope callback_scope;

	auto table_name_symbol = cpp11::safe[Rf_install](input.table_name.c_str());
	SEXP rho = db_wrapper->env;
	if (TYPEOF(rho) != ENVSXP) {
		return nullptr;
	}

	SEXP df = R_NilValue;

#if defined(R_VERSION) && R_VERSION >= R_Version(4, 5, 0)
	df = cpp11::safe[R_getVarEx](table_name_symbol, rho, Rboolean::TRUE, R_NilValue);
#else
	while (rho != R_EmptyEnv) {
		df = cpp11::safe[Rf_findVarInFrame3](rho, table_name_symbol, TRUE);
		if (df != R_UnboundValue) {
			break;
		}
		rho = ENCLOS(rho);
	}
	if (TYPEOF(df) == PROMSXP) {
		df = cpp11::safe[Rf_eval](df, rho);
	}
#endif

	PROTECT(df);
	if (!Rf_inherits(df, "data.frame")) {
		UNPROTECT(1);
		return nullptr;
	}

	// Avoid garbage collection of data frame
	SEXP node = Rf_cons(df, CDR(db_wrapper->registered_dfs));
	SETCDR(db_wrapper->registered_dfs, node);

	UNPROTECT(1);

	// TODO: do utf conversion
	auto table_function = make_uniq<TableFunctionRef>();
	vector<duckdb::unique_ptr<ParsedExpression>> children;
	children.push_back(ConstantExpression::FromValue(Value::POINTER((uintptr_t)df)));
	table_function->function = make_uniq<FunctionExpression>("r_dataframe_scan", std::move(children));

	// Signal that this table reference depends on external state (the R data
	// frame found via environment scan). For relations created via
	// rel_from_sql(), this causes QueryRelation::Bind() to wrap the original
	// query in a CTE that materializes the data frame pointer, so subsequent
	// binds (e.g. during rel_to_altrep()) do not need to look up the data
	// frame from the environment again.
	table_function->external_dependency = make_shared_ptr<ExternalDependency>();
	return std::move(table_function);
}

class RArrowTabularStreamFactory : public ArrowScanFactory {
public:
	RArrowTabularStreamFactory(SEXP export_fun_p, SEXP arrow_scannable_p, ClientProperties config_)
	    : arrow_scannable(arrow_scannable_p), export_fun(export_fun_p), config(std::move(config_)) {
	}

	unique_ptr<ArrowArrayStreamWrapper> ProduceStream(ArrowStreamParameters &parameters) override {
		// Called from ArrowScanInitGlobal, under the client context lock.
		RCallbackScope callback_scope;

		auto res = make_uniq<ArrowArrayStreamWrapper>();
		cpp11::sexp stream_ptr_sexp =
		    Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&res->arrow_array_stream)));

		cpp11::function produce_fun = VECTOR_ELT(export_fun, 0);

		auto &column_list = parameters.projected_columns.columns;
		auto filters = parameters.filters;
		auto &projection_map = parameters.projected_columns.projection_map;
		if (column_list.empty()) {
			produce_fun(arrow_scannable, stream_ptr_sexp);
		} else {
			cpp11::sexp projection_sexp = StringsToSexp(column_list);
			cpp11::sexp filters_sexp = Rf_ScalarLogical(true);
			if (filters && filters->HasFilters()) {
				filters_sexp = TransformFilter(*filters, projection_map, export_fun);
			}
			produce_fun(arrow_scannable, stream_ptr_sexp, projection_sexp, filters_sexp);
		}
		return res;
	}

	void GetSchema(ArrowSchema &schema) override {
		RCallbackScope callback_scope;

		cpp11::sexp schema_ptr_sexp = Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&schema)));

		cpp11::function schema_fun = VECTOR_ELT(export_fun, 4);

		schema_fun(arrow_scannable, schema_ptr_sexp);
	}

	SEXP arrow_scannable;
	SEXP export_fun;
	ClientProperties config;

private:
	// Upper bound on the number of IN values expanded into equality
	// comparisons; larger lists are not pushed down.
	static constexpr idx_t MAX_PUSHDOWN_IN_VALUES = 100;

	// Combine expressions over [lo, hi) with a binary op as a balanced tree,
	// so that long chains (e.g. from IN lists) do not produce deeply nested
	// expressions.
	static SEXP FoldBalanced(SEXP functions, const string &op, const vector<cpp11::sexp> &exprs, idx_t lo, idx_t hi) {
		D_ASSERT(lo < hi);
		if (hi - lo == 1) {
			return exprs[lo];
		}
		auto mid = lo + (hi - lo) / 2;
		cpp11::sexp lhs = FoldBalanced(functions, op, exprs, lo, mid);
		cpp11::sexp rhs = FoldBalanced(functions, op, exprs, mid, hi);
		return CreateExpression(functions, op, lhs, rhs);
	}

	// Translate the bound expression of an EXPRESSION_FILTER. Such a filter always
	// applies to a single column, which is bound as reference index 0.
	static string FilterDescription(const TableFilter &filter, const string &column_name) {
		return EnumUtil::ToString(filter.filter_type) + " on " + column_name;
	}

	// The predicate an optional filter wrapper prunes with, if it carries one.
	// Optional filters are internal table filter functions that evaluate to TRUE
	// and keep the real predicate in their bind data.
	static optional_ptr<const Expression> OptionalFilterChild(const BoundFunctionExpression &func) {
		if (!func.BindInfo()) {
			return nullptr;
		}
		if (func.Function().GetName() == OptionalFilterScalarFun::NAME) {
			return func.BindInfo()->Cast<OptionalFilterFunctionData>().child_filter_expr.get();
		}
		if (func.Function().GetName() == SelectivityOptionalFilterScalarFun::NAME) {
			return func.BindInfo()->Cast<SelectivityOptionalFilterFunctionData>().child_filter_expr.get();
		}
		return nullptr;
	}

	// col IN (v1, v2, ...) as a balanced tree of equality comparisons.
	static SEXP TransformInExpression(const BoundOperatorExpression &op_expr, SEXP column_name_expr, SEXP functions) {
		auto &op_children = op_expr.GetChildren();
		if (op_children.empty() || op_children[0]->GetExpressionClass() != ExpressionClass::BOUND_REF) {
			throw NotImplementedException("Arrow table filter pushdown %s not supported yet", op_expr.ToString());
		}
		const idx_t num_values = op_children.size() - 1;
		if (num_values == 0) {
			// col IN () matches no rows
			return CreateScalar(functions, cpp11::sexp(Rf_ScalarLogical(false)));
		}
		if (num_values > MAX_PUSHDOWN_IN_VALUES) {
			// Give up rather than building a huge expression tree. Inside an
			// optional filter this degrades to pushing TRUE.
			static_assert(MAX_PUSHDOWN_IN_VALUES == 100, "update the message below");
			throw NotImplementedException("IN filter with more than 100 values is not pushed down (%s)",
			                              op_expr.ToString());
		}
		vector<cpp11::sexp> equal_exprs;
		equal_exprs.reserve(num_values);
		for (idx_t i = 1; i < op_children.size(); i++) {
			auto &value_expr = *op_children[i];
			if (value_expr.GetExpressionType() != ExpressionType::VALUE_CONSTANT) {
				throw NotImplementedException("Arrow table filter pushdown %s not supported yet", op_expr.ToString());
			}
			auto &value = value_expr.Cast<BoundConstantExpression>().GetValue();
			equal_exprs.push_back(cpp11::sexp(
			    CreateExpression(functions, "equal", column_name_expr, CreateConstantExpression(functions, value))));
		}
		return FoldBalanced(functions, "or_kleene", equal_exprs, 0, equal_exprs.size());
	}

	static SEXP TransformExpression(const Expression &expr, SEXP column_name_expr, SEXP functions) {
		if (BoundComparisonExpression::IsComparison(expr)) {
			auto &comp = expr.Cast<BoundFunctionExpression>();
			auto comparison_type = comp.GetExpressionType();
			auto &lhs = BoundComparisonExpression::Left(comp);
			auto &rhs = BoundComparisonExpression::Right(comp);
			optional_ptr<const Expression> const_side;
			if (lhs.GetExpressionClass() == ExpressionClass::BOUND_REF &&
			    rhs.GetExpressionType() == ExpressionType::VALUE_CONSTANT) {
				const_side = &rhs;
			} else if (rhs.GetExpressionClass() == ExpressionClass::BOUND_REF &&
			           lhs.GetExpressionType() == ExpressionType::VALUE_CONSTANT) {
				const_side = &lhs;
				comparison_type = FlipComparisonExpression(comparison_type);
			}
			if (!const_side) {
				throw NotImplementedException("Arrow table filter pushdown %s not supported yet", expr.ToString());
			}
			cpp11::sexp constant_expr =
			    CreateConstantExpression(functions, const_side->Cast<BoundConstantExpression>().GetValue());
			switch (comparison_type) {
			case ExpressionType::COMPARE_EQUAL:
				return CreateExpression(functions, "equal", column_name_expr, constant_expr);
			case ExpressionType::COMPARE_GREATERTHAN:
				return CreateExpression(functions, "greater", column_name_expr, constant_expr);
			case ExpressionType::COMPARE_GREATERTHANOREQUALTO:
				return CreateExpression(functions, "greater_equal", column_name_expr, constant_expr);
			case ExpressionType::COMPARE_LESSTHAN:
				return CreateExpression(functions, "less", column_name_expr, constant_expr);
			case ExpressionType::COMPARE_LESSTHANOREQUALTO:
				return CreateExpression(functions, "less_equal", column_name_expr, constant_expr);
			case ExpressionType::COMPARE_NOTEQUAL:
				return CreateExpression(functions, "not_equal", column_name_expr, constant_expr);
			default:
				throw NotImplementedException("%s can't be transformed to Arrow Scan Pushdown Filter", expr.ToString());
			}
		}
		if (expr.GetExpressionClass() == ExpressionClass::BOUND_CONJUNCTION) {
			auto &conj = expr.Cast<BoundConjunctionExpression>();
			const string op = expr.GetExpressionType() == ExpressionType::CONJUNCTION_AND ? "and_kleene" : "or_kleene";
			vector<cpp11::sexp> child_exprs;
			child_exprs.reserve(conj.GetChildren().size());
			for (auto &child : conj.GetChildren()) {
				child_exprs.push_back(cpp11::sexp(TransformExpression(*child, column_name_expr, functions)));
			}
			return FoldBalanced(functions, op, child_exprs, 0, child_exprs.size());
		}
		if (ExpressionFilter::IsRootOptionalExpression(expr)) {
			// Optional filters only prune; DuckDB still applies the actual
			// predicate. Push the child expression if it is expressible, and a
			// TRUE literal otherwise, instead of failing the whole query.
			auto child = OptionalFilterChild(expr.Cast<BoundFunctionExpression>());
			if (child) {
				try {
					return TransformExpression(*child, column_name_expr, functions);
				} catch (NotImplementedException &) {
				}
			}
			return CreateScalar(functions, cpp11::sexp(Rf_ScalarLogical(true)));
		}
		if (expr.GetExpressionClass() == ExpressionClass::BOUND_OPERATOR) {
			auto &op_expr = expr.Cast<BoundOperatorExpression>();
			switch (expr.GetExpressionType()) {
			case ExpressionType::OPERATOR_IS_NULL:
				return CreateExpression(functions, "is_null", column_name_expr);
			case ExpressionType::OPERATOR_IS_NOT_NULL: {
				cpp11::sexp is_null_expr = CreateExpression(functions, "is_null", column_name_expr);
				return CreateExpression(functions, "invert", is_null_expr);
			}
			case ExpressionType::COMPARE_IN:
				return TransformInExpression(op_expr, column_name_expr, functions);
			default:
				break;
			}
		}
		throw NotImplementedException("Arrow table filter pushdown %s not supported yet", expr.ToString());
	}

	static SEXP TransformFilterExpression(TableFilter &filter, const string &column_name, SEXP functions) {
		cpp11::sexp column_name_sexp = Rf_mkString(column_name.c_str());
		cpp11::sexp column_name_expr = CreateFieldRef(functions, column_name_sexp);

		switch (filter.filter_type) {
		case TableFilterType::EXPRESSION_FILTER: {
			auto &expr_filter = filter.Cast<ExpressionFilter>();
			return TransformExpression(*expr_filter.expr, column_name_expr, functions);
		}
		case TableFilterType::LEGACY_CONSTANT_COMPARISON: {
			auto &constant_filter = (LegacyConstantFilter &)filter;
			cpp11::sexp constant_expr = CreateConstantExpression(functions, constant_filter.constant);
			switch (constant_filter.comparison_type) {
			case ExpressionType::COMPARE_EQUAL: {
				return CreateExpression(functions, "equal", column_name_expr, constant_expr);
			}
			case ExpressionType::COMPARE_GREATERTHAN: {
				return CreateExpression(functions, "greater", column_name_expr, constant_expr);
			}
			case ExpressionType::COMPARE_GREATERTHANOREQUALTO: {
				return CreateExpression(functions, "greater_equal", column_name_expr, constant_expr);
			}
			case ExpressionType::COMPARE_LESSTHAN: {
				return CreateExpression(functions, "less", column_name_expr, constant_expr);
			}
			case ExpressionType::COMPARE_LESSTHANOREQUALTO: {
				return CreateExpression(functions, "less_equal", column_name_expr, constant_expr);
			}
			case ExpressionType::COMPARE_NOTEQUAL: {
				return CreateExpression(functions, "not_equal", column_name_expr, constant_expr);
			}
			default:
				throw NotImplementedException("%s can't be transformed to Arrow Scan Pushdown Filter",
				                              FilterDescription(filter, column_name));
			}
		}
		case TableFilterType::LEGACY_IS_NULL: {
			return CreateExpression(functions, "is_null", column_name_expr);
		}
		case TableFilterType::LEGACY_IS_NOT_NULL: {
			cpp11::sexp is_null_expr = CreateExpression(functions, "is_null", column_name_expr);
			return CreateExpression(functions, "invert", is_null_expr);
		}
		case TableFilterType::LEGACY_CONJUNCTION_AND: {
			auto &and_filter = (LegacyConjunctionAndFilter &)filter;
			return TransformChildFilters(functions, column_name, "and_kleene", and_filter.child_filters);
		}
		case TableFilterType::LEGACY_CONJUNCTION_OR: {
			auto &or_filter = (LegacyConjunctionOrFilter &)filter;
			return TransformChildFilters(functions, column_name, "or_kleene", or_filter.child_filters);
		}
		case TableFilterType::LEGACY_IN_FILTER: {
			auto &in_filter = (LegacyInFilter &)filter;
			if (in_filter.values.empty()) {
				// col IN () matches no rows
				return CreateScalar(functions, cpp11::sexp(Rf_ScalarLogical(false)));
			}
			if (in_filter.values.size() > MAX_PUSHDOWN_IN_VALUES) {
				// Give up rather than building a huge expression tree. Inside an
				// optional filter this degrades to pushing TRUE.
				static_assert(MAX_PUSHDOWN_IN_VALUES == 100, "update the message below");
				throw NotImplementedException("IN filter with more than 100 values is not pushed down (%s)",
				                              FilterDescription(filter, column_name));
			}
			// col IN (v1, v2, ...) as a balanced tree of equality comparisons.
			vector<cpp11::sexp> equal_exprs;
			equal_exprs.reserve(in_filter.values.size());
			for (auto &value : in_filter.values) {
				// Bind the constant before building the comparison: `CreateExpression()`
				// allocates before it stores its operands, so passing the fresh
				// expression straight through would leave it unprotected.
				cpp11::sexp constant_expr = CreateConstantExpression(functions, value);
				equal_exprs.push_back(
				    cpp11::sexp(CreateExpression(functions, "equal", column_name_expr, constant_expr)));
			}
			return FoldBalanced(functions, "or_kleene", equal_exprs, 0, equal_exprs.size());
		}
		case TableFilterType::LEGACY_OPTIONAL_FILTER: {
			// Optional filters only prune; DuckDB still applies the actual
			// predicate. Push the child filter if it is expressible, and a
			// TRUE literal otherwise, instead of failing the whole query.
			auto &optional_filter = (LegacyOptionalFilter &)filter;
			if (optional_filter.child_filter) {
				try {
					return TransformFilterExpression(*optional_filter.child_filter, column_name, functions);
				} catch (NotImplementedException &) {
				}
			}
			return CreateScalar(functions, cpp11::sexp(Rf_ScalarLogical(true)));
		}

		default:
			throw NotImplementedException("Arrow table filter pushdown %s not supported yet",
			                              FilterDescription(filter, column_name));
		}
	}

	static SEXP TransformChildFilters(SEXP functions, const string &column_name, const string op,
	                                  vector<duckdb::unique_ptr<TableFilter>> &filters) {
		vector<cpp11::sexp> child_exprs;
		child_exprs.reserve(filters.size());
		for (auto &child_filter : filters) {
			child_exprs.push_back(cpp11::sexp(TransformFilterExpression(*child_filter, column_name, functions)));
		}
		return FoldBalanced(functions, op, child_exprs, 0, child_exprs.size());
	}

	static SEXP TransformFilter(TableFilterSet &filter_collection, unordered_map<idx_t, string> &columns,
	                            SEXP functions) {
		auto fit = filter_collection.begin();
		cpp11::sexp res = TransformFilterExpression((*fit).Filter(), columns[(*fit).GetIndex()], functions);
		++fit;
		for (; fit != filter_collection.end(); ++fit) {
			cpp11::sexp rhs = TransformFilterExpression((*fit).Filter(), columns[(*fit).GetIndex()], functions);
			res = CreateExpression(functions, "and_kleene", res, rhs);
		}
		return res;
	}

	static SEXP CallArrowFactory(SEXP functions, idx_t idx, SEXP op1, SEXP op2 = R_NilValue, SEXP op3 = R_NilValue) {
		cpp11::function create_fun = VECTOR_ELT(functions, idx);
		if (Rf_isNull(op2)) {
			return create_fun(op1);
		} else if (Rf_isNull(op3)) {
			return create_fun(op1, op2);
		} else {
			return create_fun(op1, op2, op3);
		}
	}

	static SEXP CreateExpression(SEXP functions, const string name, SEXP op1, SEXP op2 = R_NilValue) {
		cpp11::sexp name_sexp = Rf_mkString(name.c_str());
		return CallArrowFactory(functions, 1, name_sexp, op1, op2);
	}

	static SEXP CreateFieldRef(SEXP functions, SEXP op) {
		return CallArrowFactory(functions, 2, op);
	}

	static SEXP CreateScalar(SEXP functions, SEXP op) {
		return CallArrowFactory(functions, 3, op);
	}

	static SEXP CreateConstantExpression(SEXP functions, const Value &constant) {
		ConvertOpts filter_opts;
		cpp11::sexp constant_sexp = RApiTypes::ValueToSexp(constant, filter_opts);

		// Scalar TIMESTAMP (no TZ) must have tzone="" for Arrow pushdown compatibility
		if (constant.type().id() == LogicalTypeId::TIMESTAMP && TYPEOF(constant_sexp) == REALSXP) {
			Rf_setAttrib(constant_sexp, RStrings::get().tzone_sym, StringsToSexp({""}));
		}

		return CreateScalar(functions, constant_sexp);
	}
};

unique_ptr<TableRef> duckdb::ArrowScanReplacement(ClientContext &context, ReplacementScanInput &input,
                                                  optional_ptr<ReplacementScanData> data_p) {
	auto table_name = input.table_name;
	ReplacementDataDBWrapper &data = static_cast<ReplacementDataDBWrapper &>(*data_p);
	auto db_wrapper = data.wrapper;
	lock_guard<mutex> arrow_scans_lock(db_wrapper->lock);
	const auto &arrow_scans = db_wrapper->arrow_scans;
	for (auto e = arrow_scans.find(table_name); e != arrow_scans.end(); ++e) {
		auto &factory = *reinterpret_cast<shared_ptr<RArrowTabularStreamFactory> *>(R_ExternalPtrAddr(e->second[0]));
		auto table_function = make_uniq<TableFunctionRef>();
		vector<duckdb::unique_ptr<ParsedExpression>> children;
		table_function->function = make_uniq<FunctionExpression>("arrow_scan", std::move(children));
		table_function->bind_info = shared_ptr_cast<RArrowTabularStreamFactory, TableFunctionInfo>(factory);
		return std::move(table_function);
	}
	return nullptr;
}

[[cpp11::register]] void rapi_register_arrow(duckdb::conn_eptr_t conn, std::string name, cpp11::list export_funs,
                                             cpp11::sexp valuesexp) {
	if (!conn || !conn.get() || !conn->conn) {
		rapi_error_with_context("rapi_register_arrow", "Invalid connection");
	}
	if (name.empty()) {
		rapi_error_with_context("rapi_register_arrow", "Name cannot be empty");
	}

	auto stream_factory =
	    make_shared_ptr<RArrowTabularStreamFactory>(export_funs, valuesexp, conn->conn->context->GetClientProperties());
	// make r external ptr object to keep factory around until arrow table is unregistered
	cpp11::external_pointer<shared_ptr<RArrowTabularStreamFactory>> factorysexp(
	    new shared_ptr<RArrowTabularStreamFactory>(stream_factory));

	// factorysexp must occur first here, used in ArrowScanReplacement()
	cpp11::writable::list state_list = {factorysexp, export_funs, valuesexp};
	{
		lock_guard<mutex> arrow_scans_lock(conn->db->lock);
		auto &arrow_scans = conn->db->arrow_scans;

		for (auto e = arrow_scans.find(name); e != arrow_scans.end(); ++e) {
			std::string error_msg = "Arrow table '" + name + "' already registered";
			rapi_error_with_context("rapi_register_arrow", error_msg);
		}

		arrow_scans[name] = state_list;
	}
}

[[cpp11::register]] void rapi_unregister_arrow(duckdb::conn_eptr_t conn, std::string name) {
	if (!conn || !conn.get() || !conn->conn) {
		return; // if the connection is already dead there is probably no point in cleaning this
	}
	{
		lock_guard<mutex> arrow_scans_lock(conn->db->lock);
		auto &arrow_scans = conn->db->arrow_scans;
		arrow_scans.erase(name);
	}
}

[[cpp11::register]] cpp11::strings rapi_list_arrow(duckdb::conn_eptr_t conn) {
	lock_guard<mutex> arrow_scans_lock(conn->db->lock);
	const auto &arrow_scans = conn->db->arrow_scans;

	cpp11::writable::strings names;
	names.reserve(arrow_scans.size());

	for (const auto &e : arrow_scans) {
		names.push_back(e.first);
	}

	return names;
}
