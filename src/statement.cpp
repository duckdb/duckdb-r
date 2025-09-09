#include "duckdb/common/arrow/arrow.hpp"
#include "duckdb/common/arrow/arrow_converter.hpp"
#include "duckdb/common/arrow/arrow_util.hpp"
#include "duckdb/common/arrow/arrow_wrapper.hpp"
#include "duckdb/common/arrow/result_arrow_wrapper.hpp"
#include "duckdb/common/types/timestamp.hpp"
#include "duckdb/main/chunk_scan_state/query_result.hpp"
#include "duckdb/parser/statement/relation_statement.hpp"
#include "rapi.hpp"
#include "signal.hpp"
#include "typesr.hpp"

#include <R_ext/Utils.h>
#include "httplib.hpp"

using namespace duckdb;
using namespace cpp11::literals;

[[cpp11::register]] void rapi_release(duckdb::stmt_eptr_t stmt) {
	auto stmt_ptr = stmt.release();
	if (stmt_ptr) {
		delete stmt_ptr;
	}
}

static cpp11::list construct_retlist(duckdb::unique_ptr<PreparedStatement> stmt, const string &query, idx_t n_param,
                                     SEXP registered_dfs = R_NilValue) {
	cpp11::writable::list retlist;
	retlist.reserve(8);
	retlist.push_back({"str"_nm = query});

	auto stmtholder = make_uniq<RStatement>(std::move(stmt));

	retlist.push_back({"type"_nm = StatementTypeToString(stmtholder->stmt->GetStatementType())});
	retlist.push_back({"names"_nm = cpp11::as_sexp(stmtholder->stmt->GetNames())});

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
		statements = conn->conn->ExtractStatements(query.c_str());
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
	// if there are multiple statements, we directly execute the statements besides the last one
	// we only return the result of the last statement to the user, unless one of the previous statements fails
	for (idx_t i = 0; i + 1 < statements.size(); i++) {
		auto res = conn->conn->Query(std::move(statements[i]));

		signal_handler.HandleInterrupt();

		if (res->HasError()) {
			ErrorData error(res->GetError());
			rapi_error_with_context("rapi_prepare", error);
		}
	}
	auto stmt = conn->conn->Prepare(std::move(statements.back()));

	signal_handler.HandleInterrupt();

	signal_handler.Disable();

	if (stmt->HasError()) {
		ErrorData error(stmt->error);
		rapi_error_with_context("rapi_prepare", error);
	}
	auto n_param = stmt->named_param_map.size();
	return construct_retlist(std::move(stmt), query, n_param, conn->db->registered_dfs);
}

[[cpp11::register]] cpp11::list rapi_bind(duckdb::stmt_eptr_t stmt, cpp11::list params,
                                          duckdb::ConvertOpts convert_opts) {
	if (!stmt || !stmt.get() || !stmt->stmt) {
		rapi_error_with_context("rapi_bind", "Invalid statement");
	}

	auto n_param = stmt->stmt->named_param_map.size();

	if (n_param == 0) {
		rapi_error_with_context("rapi_bind", "`dbBind()` called but query takes no parameters");
	}

	if (params.size() != R_xlen_t(n_param)) {
		std::string error_msg = "Bind parameters need to be a list of length " + std::to_string(n_param);
		rapi_error_with_context("rapi_bind", error_msg);
	}

	stmt->parameters.clear();
	stmt->parameters.resize(n_param);

	R_len_t n_rows = Rf_length(params[0]);

	for (auto param = std::next(params.begin()); param != params.end(); ++param) {
		if (Rf_length(*param) != n_rows) {
			rapi_error_with_context("rapi_bind", "Bind parameter values need to have the same length");
		}
	}

	if (n_rows != 1 && convert_opts.arrow == ConvertOpts::ArrowConversion::ENABLED) {
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
		cpp11::sexp res = rapi_execute(stmt, convert_opts);
		out.push_back(res);
	}

	return out;
}

SEXP duckdb::duckdb_execute_R_impl(MaterializedQueryResult *result, const duckdb::ConvertOpts &convert_opts,
                                   SEXP class_) {
	// step 2: create result data frame and allocate columns
	auto ncols = result->types.size();
	if (ncols == 0) {
		return Rf_ScalarReal(0); // no need for protection because no allocation can happen afterwards
	}

	auto nrows = result->RowCount();

	// Note we cannot use cpp11's data frame here as it tries to calculate the number of rows itself,
	// but gives the wrong answer if the first column is another data frame. So we set the necessary
	// attributes manually.
	cpp11::writable::list data_frame;
	data_frame.reserve(ncols);

	for (size_t col_idx = 0; col_idx < ncols; col_idx++) {
		cpp11::sexp varvalue = duckdb_r_allocate(result->types[col_idx], nrows, result->names[col_idx], convert_opts,
		                                         "duckdb_execute_R_impl");
		duckdb_r_decorate(result->types[col_idx], varvalue, convert_opts);
		data_frame.push_back(varvalue);
	}

	// step 3: set values from chunks
	idx_t dest_offset = 0;
	for (auto &chunk : result->Collection().Chunks()) {
		D_ASSERT(chunk.ColumnCount() == ncols);
		D_ASSERT(chunk.ColumnCount() == (idx_t)Rf_length(data_frame));
		for (size_t col_idx = 0; col_idx < chunk.ColumnCount(); col_idx++) {
			duckdb_r_transform(chunk.data[col_idx], data_frame[col_idx], dest_offset, chunk.size(), convert_opts,
			                   result->names[col_idx]);
		}
		dest_offset += chunk.size();
	}

	D_ASSERT(dest_offset == nrows);

	// Convert to SEXP, finalize length
	(void)(SEXP)data_frame;

	SET_NAMES(data_frame, StringsToSexp(result->names));
	duckdb_r_df_decorate(data_frame, nrows, class_);

	// at this point data_frame is fully allocated and the only protected SEXP

	return data_frame;
}

struct AppendableRList {
	AppendableRList() {
		the_list = NEW_LIST(capacity);
	}
	void PrepAppend() {
		if (size >= capacity) {
			capacity = capacity * 2;
			cpp11::sexp new_list = NEW_LIST(capacity);
			D_ASSERT(new_list);
			for (idx_t i = 0; i < size; i++) {
				SET_VECTOR_ELT(new_list, i, VECTOR_ELT(the_list, i));
			}
			the_list = new_list;
		}
	}

	void Append(SEXP val) {
		D_ASSERT(size < capacity);
		D_ASSERT(the_list != R_NilValue);
		SET_VECTOR_ELT(the_list, size++, val);
	}
	cpp11::sexp the_list;
	idx_t capacity = 1000;
	idx_t size = 0;
};

bool FetchArrowChunk(ChunkScanState &scan_state, ClientProperties options, AppendableRList &batches_list,
                     ArrowArray &arrow_data, ArrowSchema &arrow_schema, SEXP batch_import_from_c, SEXP arrow_namespace,
                     idx_t chunk_size) {
	auto count =
	    ArrowUtil::FetchChunk(scan_state, options, chunk_size, &arrow_data,
	                          ArrowTypeExtensionData::GetExtensionTypes(*options.client_context, scan_state.Types()));
	if (count == 0) {
		return false;
	}
	ArrowConverter::ToArrowSchema(&arrow_schema, scan_state.Types(), scan_state.Names(), options);
	batches_list.PrepAppend();
	batches_list.Append(cpp11::safe[Rf_eval](batch_import_from_c, arrow_namespace));
	return true;
}

// Turn a DuckDB result set into an Arrow Table
[[cpp11::register]] SEXP rapi_execute_arrow(duckdb::rqry_eptr_t qry_res, int chunk_size) {
	auto result = qry_res->result.get();
	// somewhat dark magic below
	cpp11::function getNamespace = RStrings::get().getNamespace_sym;
	cpp11::sexp arrow_namespace(getNamespace(RStrings::get().arrow_str));

	// export schema setup
	ArrowSchema arrow_schema;
	cpp11::doubles schema_ptr_sexp(Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&arrow_schema))));
	cpp11::sexp schema_import_from_c(Rf_lang2(RStrings::get().ImportSchema_sym, schema_ptr_sexp));

	// export data setup
	ArrowArray arrow_data;
	cpp11::doubles data_ptr_sexp(Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&arrow_data))));
	cpp11::sexp batch_import_from_c(Rf_lang3(RStrings::get().ImportRecordBatch_sym, data_ptr_sexp, schema_ptr_sexp));
	// create data batches
	AppendableRList batches_list;

	QueryResultChunkScanState scan_state(*result);
	while (FetchArrowChunk(scan_state, result->client_properties, batches_list, arrow_data, arrow_schema,
	                       batch_import_from_c, arrow_namespace, chunk_size)) {
	}

	SET_LENGTH(batches_list.the_list, batches_list.size);
	ArrowConverter::ToArrowSchema(&arrow_schema, result->types, result->names, result->client_properties);
	cpp11::sexp schema_arrow_obj(cpp11::safe[Rf_eval](schema_import_from_c, arrow_namespace));

	// create arrow::Table
	cpp11::sexp from_record_batches(
	    Rf_lang3(RStrings::get().Table__from_record_batches_sym, batches_list.the_list, schema_arrow_obj));
	return cpp11::safe[Rf_eval](from_record_batches, arrow_namespace);
}

// Turn a DuckDB result set into an RecordBatchReader
[[cpp11::register]] SEXP rapi_record_batch(duckdb::rqry_eptr_t qry_res, int chunk_size) {
	// somewhat dark magic below
	cpp11::function getNamespace = RStrings::get().getNamespace_sym;
	cpp11::sexp arrow_namespace(getNamespace(RStrings::get().arrow_str));

	// FIXME: This is a memory leak, need better lifecycle management
	auto result_stream = new ResultArrowArrayStreamWrapper(std::move(qry_res->result), chunk_size);

	cpp11::sexp stream_ptr_sexp(
	    Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&result_stream->stream))));
	cpp11::sexp record_batch_reader(Rf_lang2(RStrings::get().ImportRecordBatchReader_sym, stream_ptr_sexp));
	return cpp11::safe[Rf_eval](record_batch_reader, arrow_namespace);
}

[[cpp11::register]] SEXP rapi_execute(duckdb::stmt_eptr_t stmt, duckdb::ConvertOpts convert_opts) {
	if (!stmt || !stmt.get() || !stmt->stmt) {
		rapi_error_with_context("rapi_execute", "Invalid statement");
	}

	ScopedInterruptHandler signal_handler(stmt->stmt->context);

	auto generic_result = stmt->stmt->Execute(stmt->parameters, false);

	signal_handler.HandleInterrupt();

	signal_handler.Disable();

	if (generic_result->HasError()) {
		ErrorData error(generic_result->GetError());
		rapi_error_with_context("rapi_execute", error);
	}

	if (convert_opts.arrow == ConvertOpts::ArrowConversion::ENABLED) {
		auto query_result = make_uniq<RQueryResult>();
		query_result->result = std::move(generic_result);
		rqry_eptr_t query_resultsexp(query_result.release());
		return query_resultsexp;
	} else {
		D_ASSERT(generic_result->type == QueryResultType::MATERIALIZED_RESULT);
		auto result = (MaterializedQueryResult *)generic_result.get();

		// Avoid rchk warning, it sees QueryResult::~QueryResult() as an allocating function
		cpp11::sexp out = duckdb_execute_R_impl(result, convert_opts, RStrings::get().dataframe_str);
		return out;
	}
}
