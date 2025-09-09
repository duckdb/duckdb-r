#include "rapi.hpp"
#include "typesr.hpp"
#include "signal.hpp"

#include "duckdb/common/arrow/arrow_wrapper.hpp"
#include "duckdb/planner/table_filter.hpp"
#include "duckdb/planner/filter/constant_filter.hpp"
#include "duckdb/planner/filter/conjunction_filter.hpp"
#include "duckdb/parser/expression/constant_expression.hpp"
#include "duckdb/parser/expression/function_expression.hpp"
#include "duckdb/function/table/arrow.hpp"

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

		conn->conn->TableFunction("r_dataframe_scan", {Value::POINTER((uintptr_t)value.data())}, parameter_map)
		    ->CreateView(name, overwrite, true);

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
		rapi_error_with_context("rapi_unregister_df", res->GetError());
	}
}

unique_ptr<TableRef> duckdb::EnvironmentScanReplacement(ClientContext &context, ReplacementScanInput &input,
                                                        optional_ptr<ReplacementScanData> data_p) {
	auto &data = (ReplacementDataDBWrapper &)*data_p;
	auto db_wrapper = data.wrapper;

	auto table_name_symbol = cpp11::safe[Rf_install](input.table_name.c_str());
	SEXP df = R_NilValue;
	SEXP rho = db_wrapper->env;
	if (TYPEOF(rho) != ENVSXP) {
		return nullptr;
	}

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
	if (!Rf_inherits(df, "data.frame")) {
		return nullptr;
	}

	// Avoid garbage collection of data frame
	SEXP node = Rf_cons(df, CDR(db_wrapper->registered_dfs));
	SETCDR(db_wrapper->registered_dfs, node);

	// TODO: do utf conversion
	auto table_function = make_uniq<TableFunctionRef>();
	vector<duckdb::unique_ptr<ParsedExpression>> children;
	children.push_back(make_uniq<ConstantExpression>(Value::POINTER((uintptr_t)df)));
	table_function->function = make_uniq<FunctionExpression>("r_dataframe_scan", std::move(children));
	return std::move(table_function);
}

class RArrowTabularStreamFactory {
public:
	RArrowTabularStreamFactory(SEXP export_fun_p, SEXP arrow_scannable_p, ClientProperties config)
	    : arrow_scannable(arrow_scannable_p), export_fun(export_fun_p), config(config) {};

	static unique_ptr<ArrowArrayStreamWrapper> Produce(uintptr_t factory_p, ArrowStreamParameters &parameters) {
		auto res = make_uniq<ArrowArrayStreamWrapper>();
		auto factory = (RArrowTabularStreamFactory *)factory_p;
		cpp11::sexp stream_ptr_sexp =
		    Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&res->arrow_array_stream)));

		cpp11::function export_fun = VECTOR_ELT(factory->export_fun, 0);

		auto &column_list = parameters.projected_columns.columns;
		auto filters = parameters.filters;
		auto &projection_map = parameters.projected_columns.projection_map;
		if (column_list.empty()) {
			export_fun(factory->arrow_scannable, stream_ptr_sexp);
		} else {
			cpp11::sexp projection_sexp = StringsToSexp(column_list);
			cpp11::sexp filters_sexp = Rf_ScalarLogical(true);
			if (filters && !filters->filters.empty()) {
				auto timezone_config = factory->config.time_zone;
				filters_sexp = TransformFilter(*filters, projection_map, factory->export_fun, timezone_config);
			}
			export_fun(factory->arrow_scannable, stream_ptr_sexp, projection_sexp, filters_sexp);
		}
		return res;
	}

	static void GetSchema(uintptr_t factory_p, ArrowSchemaWrapper &schema) {

		auto res = make_uniq<ArrowArrayStreamWrapper>();
		auto factory = (RArrowTabularStreamFactory *)factory_p;
		cpp11::sexp schema_ptr_sexp =
		    Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&schema.arrow_schema)));

		cpp11::function export_fun = VECTOR_ELT(factory->export_fun, 4);

		export_fun(factory->arrow_scannable, schema_ptr_sexp);
	}

	SEXP arrow_scannable;
	SEXP export_fun;
	ClientProperties config;

private:
	static SEXP TransformFilterExpression(TableFilter &filter, const string &column_name, SEXP functions,
	                                      string &timezone_config) {
		cpp11::sexp column_name_sexp = Rf_mkString(column_name.c_str());
		cpp11::sexp column_name_expr = CreateFieldRef(functions, column_name_sexp);

		switch (filter.filter_type) {
		case TableFilterType::CONSTANT_COMPARISON: {
			auto constant_filter = (ConstantFilter &)filter;
			cpp11::sexp constant_sexp = RApiTypes::ValueToSexp(constant_filter.constant, timezone_config);
			cpp11::sexp constant_expr = CreateScalar(functions, constant_sexp);
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
				throw InternalException("%s can't be transformed to Arrow Scan Pushdown Filter",
				                        filter.ToString(column_name));
			}
		}
		case TableFilterType::IS_NULL: {
			return CreateExpression(functions, "is_null", column_name_expr);
		}
		case TableFilterType::IS_NOT_NULL: {
			cpp11::sexp is_null_expr = CreateExpression(functions, "is_null", column_name_expr);
			return CreateExpression(functions, "invert", is_null_expr);
		}
		case TableFilterType::CONJUNCTION_AND: {
			auto &and_filter = (ConjunctionAndFilter &)filter;
			return TransformChildFilters(functions, column_name, "and_kleene", and_filter.child_filters,
			                             timezone_config);
		}
		case TableFilterType::CONJUNCTION_OR: {
			auto &and_filter = (ConjunctionAndFilter &)filter;
			return TransformChildFilters(functions, column_name, "or_kleene", and_filter.child_filters,
			                             timezone_config);
		}

		default:
			throw NotImplementedException("Arrow table filter pushdown %s not supported yet",
			                              filter.ToString(column_name));
		}
	}

	static SEXP TransformChildFilters(SEXP functions, const string &column_name, const string op,
	                                  vector<duckdb::unique_ptr<TableFilter>> &filters, string &timezone_config) {
		auto fit = filters.begin();
		cpp11::sexp conjunction_sexp = TransformFilterExpression(**fit, column_name, functions, timezone_config);
		fit++;
		for (; fit != filters.end(); ++fit) {
			cpp11::sexp rhs = TransformFilterExpression(**fit, column_name, functions, timezone_config);
			conjunction_sexp = CreateExpression(functions, op, conjunction_sexp, rhs);
		}
		return conjunction_sexp;
	}

	static SEXP TransformFilter(TableFilterSet &filter_collection, unordered_map<idx_t, string> &columns,
	                            SEXP functions, string &timezone_config) {
		auto fit = filter_collection.filters.begin();
		cpp11::sexp res = TransformFilterExpression(*fit->second, columns[fit->first], functions, timezone_config);
		fit++;
		for (; fit != filter_collection.filters.end(); ++fit) {
			cpp11::sexp rhs = TransformFilterExpression(*fit->second, columns[fit->first], functions, timezone_config);
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
};

unique_ptr<TableRef> duckdb::ArrowScanReplacement(ClientContext &context, ReplacementScanInput &input,
                                                  optional_ptr<ReplacementScanData> data_p) {
	auto table_name = input.table_name;
	ReplacementDataDBWrapper &data = static_cast<ReplacementDataDBWrapper &>(*data_p);
	auto db_wrapper = data.wrapper;
	lock_guard<mutex> arrow_scans_lock(db_wrapper->lock);
	const auto &arrow_scans = db_wrapper->arrow_scans;
	for (auto e = arrow_scans.find(table_name); e != arrow_scans.end(); ++e) {
		auto table_function = make_uniq<TableFunctionRef>();
		vector<duckdb::unique_ptr<ParsedExpression>> children;
		children.push_back(make_uniq<ConstantExpression>(Value::POINTER((uintptr_t)R_ExternalPtrAddr(e->second[0]))));
		children.push_back(
		    make_uniq<ConstantExpression>(Value::POINTER((uintptr_t)RArrowTabularStreamFactory::Produce)));
		children.push_back(
		    make_uniq<ConstantExpression>(Value::POINTER((uintptr_t)RArrowTabularStreamFactory::GetSchema)));
		table_function->function = make_uniq<FunctionExpression>("arrow_scan", std::move(children));
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
	    new RArrowTabularStreamFactory(export_funs, valuesexp, conn->conn->context->GetClientProperties());
	// make r external ptr object to keep factory around until arrow table is unregistered
	cpp11::external_pointer<RArrowTabularStreamFactory> factorysexp(stream_factory);

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
