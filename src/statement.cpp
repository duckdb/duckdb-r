#include "duckdb/common/types/timestamp.hpp"
#include "duckdb/main/query_profiler.hpp"
#include "duckdb/parser/parser.hpp"
#include "duckdb/parser/statement/explain_statement.hpp"
#include "duckdb/parser/statement/relation_statement.hpp"
#include "httplib.hpp"
#include "rapi.hpp"
#include "signal.hpp"
#include "typesr.hpp"

#include <R_ext/Utils.h>

// Handbook: handbook/usage/memory/reading/README.md
// (where a result's copies live per fetch path, and when each is freed)

// Avoid clash with TRUE and FALSE macros in older rtools
#undef TRUE
#undef FALSE

using namespace duckdb;
using namespace cpp11::literals;

namespace {

// Depth rather than a flag: a callback may run R code that starts another query
// over another registered table, and only the outermost return is safe.
idx_t callback_depth = 0;
vector<duckdb::unique_ptr<PreparedStatement>> deferred_statements;

} // namespace

namespace duckdb {

RCallbackScope::RCallbackScope() {
	callback_depth++;
}

RCallbackScope::~RCallbackScope() {
	callback_depth--;
}

bool RCallbackScope::Active() {
	return callback_depth > 0;
}

void RCallbackScope::Defer(duckdb::unique_ptr<PreparedStatement> stmt) {
	deferred_statements.push_back(std::move(stmt));
}

// Deliberately not called from the scope's own destructor: that returns into the
// duckdb call that made the callback, which still holds the lock. Draining has
// to wait for an entry point, where R is the caller and nothing is held.
void RCallbackScope::Drain() {
	if (Active()) {
		return;
	}
	// Swap first: destroying a statement runs duckdb code, which may register
	// another callback, and appending to a vector we are iterating would be UB.
	vector<duckdb::unique_ptr<PreparedStatement>> to_destroy;
	to_destroy.swap(deferred_statements);
	to_destroy.clear();
}

RStatement::~RStatement() {
	if (stmt && RCallbackScope::Active()) {
		RCallbackScope::Defer(std::move(stmt));
	}
}

} // namespace duckdb

[[cpp11::register]] void rapi_release(duckdb::stmt_eptr_t stmt) {
	auto stmt_ptr = stmt.release();
	if (stmt_ptr) {
		delete stmt_ptr;
	}
}

// Every entry point that takes a statement asks this first: the pointer may have been released by dbClearResult().
static void CheckStatement(const duckdb::stmt_eptr_t &stmt, const char *context) {
	if (!stmt || !stmt.get() || !stmt->stmt) {
		rapi_error_with_context(context, "Invalid statement");
	}
}

static bool IsExplainAnalyze(const SQLStatement &statement) {
	if (statement.type != StatementType::EXPLAIN_STATEMENT) {
		return false;
	}
	return statement.Cast<ExplainStatement>().explain_type == ExplainType::EXPLAIN_ANALYZE;
}

static cpp11::list construct_retlist(duckdb::unique_ptr<PreparedStatement> stmt, const string &query, idx_t n_param,
                                     SEXP registered_dfs = R_NilValue, bool explain_analyze = false) {
	cpp11::writable::list retlist;
	retlist.reserve(8);
	retlist.push_back({"str"_nm = query});

	auto stmtholder = make_uniq<RStatement>(std::move(stmt), explain_analyze);

	retlist.push_back({"type"_nm = StatementTypeToString(stmtholder->stmt->GetStatementType())});
	retlist.push_back({"names"_nm = cpp11::as_sexp(IdentifiersToStrings(stmtholder->stmt->GetNames()))});

	cpp11::writable::strings rtypes;
	rtypes.reserve(stmtholder->stmt->GetTypes().size());

	for (auto &stype : stmtholder->stmt->GetTypes()) {
		string rtype = RApiTypes::DetectLogicalType(stype, "rapi_prepare");
		rtypes.push_back(rtype);
	}

	retlist.push_back({"rtypes"_nm = rtypes});
	retlist.push_back({"n_param"_nm = n_param});
	retlist.push_back(
	    {"return_type"_nm = StatementReturnTypeToString(stmtholder->stmt->GetStatementProperties().return_type)});
	retlist.push_back({"registered_dfs"_nm = registered_dfs});
	retlist.push_back({"ref"_nm = stmt_eptr_t(stmtholder.release())});

	return retlist;
}

[[cpp11::register]] cpp11::list rapi_prepare(duckdb::conn_eptr_t conn, std::string query, cpp11::environment env) {
	RCallbackScope::Drain();

	if (!conn || !conn.get() || !conn->conn) {
		rapi_error_with_context("rapi_prepare", "Invalid connection");
	}

	// Create ScopedInterruptHandler to prevent deadlock when called re-entrantly
	// during progress bar callbacks. This will throw "ScopedInterruptHandler already active"
	// if another query is already executing, providing fast failure instead of deadlock.
	ScopedInterruptHandler signal_handler(conn->conn->context);

	D_ASSERT(conn->db->env == R_NilValue);
	conn->db->env = (SEXP)env;
	conn->db->registered_dfs = Rf_cons(R_NilValue, R_NilValue);
	duckdb_httplib::detail::scope_exit reset_db_env([&]() {
		conn->db->env = R_NilValue;
		conn->db->registered_dfs = R_NilValue;
	});

	vector<unique_ptr<SQLStatement>> statements;
	try {
		Parser parser(*conn->conn->context);
		parser.ParseQuery(query);
		statements = std::move(parser.statements);
	} catch (std::exception &ex) {
		ErrorData error(ex);
		error.AddErrorLocation(query);
		// Pass ErrorData directly to preserve rich error information
		rapi_error_with_context("rapi_prepare", error);
	}
	if (statements.empty()) {
		// no statements to execute
		rapi_error_with_context("rapi_prepare", "No statements to execute");
	}

	// When extensions are disallowed for this driver (an affected non-libstdc++
	// Linux build, or duckdb(allow_extensions = FALSE)), refuse the whole
	// extension workflow. DuckDB parses INSTALL, FORCE INSTALL and LOAD all as
	// StatementType::LOAD_STATEMENT, so this one check forbids installing as well
	// as loading: LOAD would dlopen() a prebuilt (libstdc++) extension and crash R
	// (duckdb/duckdb-r#1107), and there is no point installing an extension that
	// can never be loaded. The decision is made in R (resolve_allow_extensions())
	// and plumbed here via the DBWrapper external pointer. Every parsed statement
	// is checked -- not just the last one returned to the caller -- so a LOAD
	// anywhere in a multi-statement query is caught. The user-facing message is
	// centralized in R: throw with context "load_extension" and an empty message,
	// and rapi_error() fills in the text from extensions_disabled_error().
	if (!conn->db->allow_extensions) {
		for (auto &statement : statements) {
			if (statement->type == StatementType::LOAD_STATEMENT) {
				rapi_error_with_context("load_extension", "");
			}
		}
	}

	unique_ptr<SQLStatement> last_statement;
	for (idx_t i = 0; i < statements.size(); i++) {
		vector<unique_ptr<SQLStatement>> fragments;
		fragments.push_back(std::move(statements[i]));
		try {
			conn->conn->context->PreprocessStatements(fragments);
		} catch (std::exception &ex) {
			ErrorData error(ex);
			error.AddErrorLocation(query);
			rapi_error_with_context("rapi_prepare", error);
		}
		// A PRAGMA can expand to a LOAD (import_database runs the SQL it reads from disk), so its expansion is
		// checked as a whole before any of it runs: refusing it part-way would leave the implicit BEGIN the
		// engine wraps the expansion in open, and every later statement on the connection inside it.
		if (!conn->db->allow_extensions) {
			for (auto &fragment : fragments) {
				if (fragment->type == StatementType::LOAD_STATEMENT) {
					rapi_error_with_context("load_extension", "");
				}
			}
		}
		for (idx_t j = 0; j < fragments.size(); j++) {
			auto &fragment = fragments[j];
			if (i + 1 == statements.size() && j + 1 == fragments.size()) {
				last_statement = std::move(fragment);
				break;
			}
			auto res = conn->conn->Query(std::move(fragment));
			if (res->HasError()) {
				// Mirrors ClientContext::Query(const string &), which rolls back the implicit transaction a PRAGMA's
				// expansion runs in when one of its statements fails. Query(unique_ptr<SQLStatement>) does so only
				// for an error raised before execution, and leaves the transaction open and aborted otherwise.
				// Ahead of HandleInterrupt(), so that an interrupted fragment is rolled back too.
				auto &transaction = conn->conn->context->transaction;
				if (transaction.HasActiveTransaction() && transaction.GetAutoRollback()) {
					transaction.Rollback(res->GetErrorObject());
				}
			}
			signal_handler.HandleInterrupt();
			if (res->HasError()) {
				// `GetErrorObject()`, not `GetError()`: the latter is the formatted
				// message, and rebuilding an `ErrorData` from it would report every
				// failure as INVALID with no extra info.
				rapi_error_with_context("rapi_prepare", res->GetErrorObject());
			}
		}
	}
	// The last statement is the call's result. With no fragment left, it was a PRAGMA that expanded to nothing, the
	// only statement that can, and it returns what any other PRAGMA returns: no rows of one `Success` column.
	bool explain_analyze = last_statement && IsExplainAnalyze(*last_statement);
	auto stmt = last_statement ? conn->conn->Prepare(std::move(last_statement))
	                           : conn->conn->Prepare("SELECT CAST(NULL AS BOOLEAN) AS Success LIMIT 0");

	signal_handler.HandleInterrupt();

	signal_handler.Disable();

	if (stmt->HasError()) {
		ErrorData error(stmt->GetErrorObject());
		rapi_error_with_context("rapi_prepare", error);
	}
	auto n_param = stmt->GetParameterCount();
	return construct_retlist(std::move(stmt), query, n_param, conn->db->registered_dfs, explain_analyze);
}

static SEXP rapi_execute_impl(RStatement *stmt, const duckdb::ConvertOpts &convert_opts);

[[cpp11::register]] cpp11::list rapi_bind(duckdb::stmt_eptr_t stmt, cpp11::list params,
                                          duckdb::ConvertOpts convert_opts) {
	RCallbackScope::Drain();

	CheckStatement(stmt, "rapi_bind");

	auto n_param = stmt->stmt->GetParameterCount();

	if (n_param == 0) {
		rapi_error_with_context("rapi_bind", "`dbBind()` called but query takes no parameters");
	}

	if (params.size() != R_xlen_t(n_param)) {
		std::string error_msg = "Bind parameters need to be a list of length " + std::to_string(n_param);
		rapi_error_with_context("rapi_bind", error_msg);
	}

	stmt->parameters.clear();
	stmt->parameters.resize(n_param);

	// A data frame binds as STRUCT, one value per row, so the rows are counted by type, not by length.
	R_len_t n_rows = RApiTypes::GetVecSize(params[0]);

	for (auto param = std::next(params.begin()); param != params.end(); ++param) {
		if (RApiTypes::GetVecSize(*param) != n_rows) {
			rapi_error_with_context("rapi_bind", "Bind parameter values need to have the same length");
		}
	}

	bool arrow = convert_opts.arrow == ConvertOpts::ArrowConversion::ENABLED;
	bool allow_stream = convert_opts.allow_stream_result == ConvertOpts::AllowStreamResult::ENABLED;

	// The legacy arrow path (`dbSendQuery(arrow = TRUE)`) materializes results and
	// has never supported binding multiple rows; preserve that error.
	if (arrow && !allow_stream && n_rows != 1) {
		rapi_error_with_context("rapi_bind", "Bind parameter values need to have length one for arrow queries");
	}

	cpp11::writable::list out;
	out.reserve(n_rows);

	for (idx_t row_idx = 0; row_idx < (size_t)n_rows; ++row_idx) {
		for (idx_t param_idx = 0; param_idx < (idx_t)params.size(); param_idx++) {
			SEXP valsexp = params[(size_t)param_idx];
			auto val = RApiTypes::SexpToValue(valsexp, row_idx);
			stmt->parameters[param_idx] = val;
		}

		// Protection error is flagged by rchk
		cpp11::sexp res = rapi_execute_impl(stmt.get(), convert_opts);
		out.push_back(res);
	}

	return out;
}

// Create the result data frame and allocate columns, without any values yet.
// Note we cannot use cpp11's data frame here as it tries to calculate the number of rows itself,
// but gives the wrong answer if the first column is another data frame. So we set the necessary
// attributes manually.
static cpp11::writable::list duckdb_r_allocate_df(const vector<LogicalType> &types, const vector<Identifier> &names,
                                                  idx_t nrows, const duckdb::ConvertOpts &convert_opts,
                                                  const char *caller) {
	cpp11::writable::list data_frame;
	data_frame.reserve(types.size());

	for (size_t col_idx = 0; col_idx < types.size(); col_idx++) {
		cpp11::sexp varvalue =
		    duckdb_r_allocate(types[col_idx], nrows, names[col_idx].GetIdentifierName(), convert_opts, caller);
		duckdb_r_decorate(types[col_idx], varvalue, convert_opts);
		data_frame.push_back(varvalue);
	}

	return data_frame;
}

SEXP duckdb::duckdb_execute_R_impl(QueryResult *result, const duckdb::ConvertOpts &convert_opts, SEXP class_) {
	// step 2: create result data frame and allocate columns
	auto ncols = result->GetTypes().size();
	if (ncols == 0) {
		return Rf_ScalarReal(0); // no need for protection because no allocation can happen afterwards
	}

	auto nrows = result->RowCount();

	// Propagate the session's TimeZone so TIMESTAMP WITH TIME ZONE columns
	// can be tagged with the timezone DuckDB used to format their value.
	ConvertOpts local_convert_opts = convert_opts;
	local_convert_opts.session_time_zone = result->client_properties.time_zone;

	cpp11::writable::list data_frame = duckdb_r_allocate_df(result->GetTypes(), result->GetNames(), nrows,
	                                                        local_convert_opts, "duckdb_execute_R_impl");

	// step 3: set values from chunks
	idx_t dest_offset = 0;
	for (auto &chunk : result->Collection().Chunks()) {
		D_ASSERT(chunk.ColumnCount() == ncols);
		D_ASSERT(chunk.ColumnCount() == (idx_t)Rf_length(data_frame));
		for (size_t col_idx = 0; col_idx < chunk.ColumnCount(); col_idx++) {
			duckdb_r_transform(chunk.data[col_idx], data_frame[col_idx], dest_offset, chunk.size(), local_convert_opts,
			                   result->GetNames()[col_idx].GetIdentifierName());
		}
		dest_offset += chunk.size();
	}

	D_ASSERT(dest_offset == nrows);

	// Convert to SEXP, finalize length
	(void)(SEXP)data_frame;

	SET_NAMES(data_frame, StringsToSexp(IdentifiersToStrings(result->GetNames())));
	duckdb_r_df_decorate(data_frame, nrows, class_);

	// at this point data_frame is fully allocated and the only protected SEXP

	return data_frame;
}

// Refuse a result column R cannot hold before the statement runs,
// so that a statement with side effects, such as INSERT ... RETURNING, is not run for rows the conversion then refuses.
// duckdb_r_typeof() is the judge, and throws the message the conversion would,
// for a column or for anything nested in it (handbook/usage/types/README.md).
static void CheckResultTypeForR(const LogicalType &type, const string &name) {
	switch (type.id()) {
	case LogicalTypeId::UNKNOWN:
	case LogicalTypeId::SQLNULL:
		// Resolved when the parameters are bound, or holding no value to convert
		return;
	case LogicalTypeId::LIST:
		CheckResultTypeForR(ListType::GetChildType(type), name);
		return;
	case LogicalTypeId::ARRAY:
		CheckResultTypeForR(ArrayType::GetChildType(type), name);
		return;
	case LogicalTypeId::MAP:
		CheckResultTypeForR(MapType::KeyType(type), name);
		CheckResultTypeForR(MapType::ValueType(type), name);
		return;
	case LogicalTypeId::STRUCT:
		for (const auto &child : StructType::GetChildTypes(type)) {
			CheckResultTypeForR(child.second, name + "$" + child.first);
		}
		return;
	default:
		(void)duckdb_r_typeof(type, name, "rapi_execute");
		return;
	}
}

static SEXP rapi_execute_impl(RStatement *stmt, const duckdb::ConvertOpts &convert_opts) {
	// Only the conversion to R vectors needs the check: an Arrow result carries every type.
	if (convert_opts.arrow != ConvertOpts::ArrowConversion::ENABLED) {
		const auto &types = stmt->stmt->GetTypes();
		const auto &names = stmt->stmt->GetNames();
		for (idx_t col_idx = 0; col_idx < types.size(); col_idx++) {
			CheckResultTypeForR(types[col_idx], names[col_idx].GetIdentifierName());
		}
	}

	auto context = stmt->stmt->TryGetContext();
	ScopedInterruptHandler signal_handler(context);

	// EXPLAIN ANALYZE renders the query profiler's output, and the profiler only
	// arms itself when the statement the engine plans is the EXPLAIN itself. The
	// prepared-statement API plans an EXECUTE, so arm it here; the profiler
	// disarms itself at the end of the query.
	if (stmt->explain_analyze && context) {
		QueryProfiler::Get(*context).StartExplainAnalyze();
	}

	auto generic_result = stmt->stmt->Execute(stmt->parameters);

	signal_handler.HandleInterrupt();

	signal_handler.Disable();

	if (generic_result->HasError()) {
		// The error object rather than its message, so that the exception type
		// and extra info survive to the caller -- see rapi_prepare() above.
		rapi_error_with_context("rapi_execute", generic_result->GetErrorObject());
	}

	if (convert_opts.arrow == ConvertOpts::ArrowConversion::ENABLED) {
		auto query_result = make_uniq<RQueryResult>(std::move(generic_result));
		rqry_eptr_t query_resultsexp(query_result.release());
		return query_resultsexp;
	} else {
		D_ASSERT(generic_result->GetResultType() == QueryResultType::MATERIALIZED_RESULT);
		auto result = generic_result.get();

		// Avoid rchk warning, it sees QueryResult::~QueryResult() as an allocating function
		cpp11::sexp out = duckdb_execute_R_impl(result, convert_opts, RStrings::get().dataframe_str);
		return out;
	}
}

[[cpp11::register]] SEXP rapi_execute(duckdb::stmt_eptr_t stmt, duckdb::ConvertOpts convert_opts) {
	RCallbackScope::Drain();

	CheckStatement(stmt, "rapi_execute");

	return rapi_execute_impl(stmt.get(), convert_opts);
}
