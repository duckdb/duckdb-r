#pragma once

#include "cpp11.hpp"

#include <Rdefines.h>
#include <R_ext/Altrep.h>
#include <Rversion.h>

#include "duckdb.hpp"
#include "duckdb/function/table_function.hpp"
#include "duckdb/common/unordered_map.hpp"
#include "duckdb/parser/tableref/table_function_ref.hpp"
#include "duckdb/common/mutex.hpp"
#include "duckdb/common/error_data.hpp"

#include "convert.hpp"

#if defined(R_VERSION) && R_VERSION >= R_Version(4, 3, 0)
#define R_HAS_ALTLIST
#endif

// Helper functions to communicate errors via R's stop() function with context information
[[noreturn]] void rapi_error_with_context(const std::string &context, const std::string &message);
[[noreturn]] void rapi_error_with_context(const std::string &context, const std::exception &e);
[[noreturn]] void rapi_error_with_context(const std::string &context, const duckdb::ErrorData &error_data);

namespace duckdb {

typedef unordered_map<std::string, cpp11::list> arrow_scans_t;

struct DBWrapper {
	duckdb::unique_ptr<DuckDB> db;
	arrow_scans_t arrow_scans;
	mutex lock;
	cpp11::sexp env;
	cpp11::sexp registered_dfs;
};

template <class T>
class DualWrapper {
public:
	DualWrapper(T *db) : precious_(db) {
	}
	DualWrapper(std::shared_ptr<T> db) : precious_(db) {
	}
	DualWrapper(DualWrapper *dual) : precious_(dual->get()) {
		if (!precious_) {
			rapi_error_with_context("DualWrapper", "dual is already released");
		}
	}
	~DualWrapper() {
		if (has()) {
			cpp11::warning("Database is garbage-collected, use dbConnect(duckdb()) with dbDisconnect(), or "
			               "duckdb::duckdb_shutdown(drv) to avoid this.");
		}
	}

	std::shared_ptr<T> get() const {
		if (precious_) {
			return precious_;
		} else {
			return disposable_.lock();
		}
	}

	std::shared_ptr<T> operator->() const {
		return get();
	}

	bool has() const {
		return !!get();
	}

	bool is_locked() const {
		return !!precious_;
	}

	void lock() {
		precious_ = get();
		disposable_.reset();
	}

	void unlock() {
		disposable_ = get();
		precious_.reset();
	}

	void reset() {
		precious_.reset();
		disposable_.reset();
	}

private:
	std::shared_ptr<T> precious_;
	std::weak_ptr<T> disposable_;
};

typedef DualWrapper<DBWrapper> DBWrapperDual;

typedef cpp11::external_pointer<DBWrapperDual> db_eptr_t;

struct ConnWrapper {
	ConnWrapper() = delete;
	ConnWrapper(std::shared_ptr<DBWrapper> db_p, ConvertOpts convert_opts_p)
	    : db(std::move(db_p)), convert_opts(std::move(convert_opts_p)) {
		conn = make_uniq<Connection>(*db->db);
	}
	std::shared_ptr<DBWrapper> db;
	duckdb::unique_ptr<Connection> conn;
	const ConvertOpts convert_opts;
};

void ConnDeleter(ConnWrapper *);
typedef cpp11::external_pointer<ConnWrapper, ConnDeleter> conn_eptr_t;

struct RStatement {
	RStatement() = delete;
	RStatement(duckdb::unique_ptr<PreparedStatement> stmt_p) : stmt(std::move(stmt_p)) {
	}
	duckdb::unique_ptr<PreparedStatement> stmt;
	vector<Value> parameters;
};

typedef cpp11::external_pointer<RStatement> stmt_eptr_t;

struct RelationWrapper {
	RelationWrapper() = delete;
	RelationWrapper(duckdb::shared_ptr<Relation> rel_p, ConvertOpts convert_opts)
	    : rel(std::move(rel_p)), convert_opts(std::move(convert_opts)) {
	}
	duckdb::shared_ptr<Relation> rel;
	const ConvertOpts convert_opts;
};

typedef cpp11::external_pointer<RelationWrapper> rel_extptr_t;

typedef cpp11::external_pointer<ParsedExpression> expr_extptr_t;

struct RQueryResult {
	duckdb::unique_ptr<QueryResult> result;
};

typedef cpp11::external_pointer<RQueryResult> rqry_eptr_t;

// internal
unique_ptr<TableRef> ArrowScanReplacement(ClientContext &context, ReplacementScanInput &input,
                                          optional_ptr<ReplacementScanData> data);

unique_ptr<TableRef> EnvironmentScanReplacement(ClientContext &context, ReplacementScanInput &input,
                                                optional_ptr<ReplacementScanData> data);

struct ReplacementDataDBWrapper : public ReplacementScanData {
	DBWrapper *wrapper;
};

cpp11::strings StringsToSexp(vector<std::string> s);

SEXP ToUtf8(SEXP string_sexp);

static constexpr char R_STRING_TYPE_NAME[] = "r_string";

struct RStringsType {
	static LogicalType Get();
};

struct DataFrameScanFunction : public TableFunction {
	DataFrameScanFunction();
};

struct RStrings {
	SEXP secs; // Rf_mkChar
	SEXP mins;
	SEXP hours;
	SEXP days;
	SEXP weeks;
	SEXP POSIXct;
	SEXP POSIXt;
	SEXP UTC_str; // Rf_mkString
	SEXP Date_str;
	SEXP factor_str;
	SEXP dataframe_str;
	SEXP difftime_str;
	SEXP secs_str;
	SEXP arrow_str; // StringsToSexp
	SEXP duckdb_str;
	SEXP POSIXct_POSIXt_str;
	SEXP integer64_str;
	SEXP tbl_df_tbl_dataframe_str;
	SEXP enc2utf8_sym; // Rf_install
	SEXP tzone_sym;
	SEXP units_sym;
	SEXP dim_sym;
	SEXP getNamespace_sym;
	SEXP Table__from_record_batches_sym;
	SEXP ImportSchema_sym;
	SEXP ImportRecordBatch_sym;
	SEXP ImportRecordBatchReader_sym;
	SEXP materialize_callback_sym;
	SEXP materialize_message_sym;
	SEXP get_progress_display_sym;
	SEXP duckdb_row_names_sym;
	SEXP duckdb_vector_sym;

	static const RStrings &get() {
		// On demand
		static RStrings strings;
		return strings;
	}

private:
	RStrings();
};

SEXP duckdb_execute_R_impl(MaterializedQueryResult *result, const duckdb::ConvertOpts &convert_opts, SEXP class_);

} // namespace duckdb

// moved out of duckdb namespace for the time being (r-lib/cpp11#262)

duckdb::db_eptr_t rapi_startup(std::string, bool, cpp11::list);

void rapi_shutdown(duckdb::db_eptr_t);

duckdb::conn_eptr_t rapi_connect(duckdb::db_eptr_t);

void rapi_disconnect(duckdb::conn_eptr_t);

bool rapi_connection_valid(duckdb::conn_eptr_t);

cpp11::list rapi_prepare(duckdb::conn_eptr_t, std::string);

cpp11::list rapi_bind(duckdb::stmt_eptr_t, SEXP paramsexp, duckdb::ConvertOpts);

SEXP rapi_execute(duckdb::stmt_eptr_t, duckdb::ConvertOpts);

void rapi_release(duckdb::stmt_eptr_t);

void rapi_register_df(duckdb::conn_eptr_t, std::string, cpp11::data_frame, duckdb::ConvertOpts);

void rapi_unregister_df(duckdb::conn_eptr_t, std::string);

void rapi_register_arrow(duckdb::conn_eptr_t, SEXP namesexp, SEXP export_funsexp, SEXP valuesexp);

void rapi_unregister_arrow(duckdb::conn_eptr_t, SEXP namesexp);

SEXP rapi_execute_arrow(duckdb::rqry_eptr_t, int);

SEXP rapi_record_batch(duckdb::rqry_eptr_t, int);

cpp11::r_string rapi_ptr_to_str(SEXP extptr);

int duckdb_r_typeof(const duckdb::LogicalType &type, const duckdb::string &name, const char *caller);
SEXP duckdb_r_allocate(const duckdb::LogicalType &type, duckdb::idx_t nrows, const duckdb::string &name,
                       const duckdb::ConvertOpts &convert_opts, const char *caller);
void duckdb_r_df_decorate_impl(SEXP dest, SEXP rownames, SEXP class_);
void duckdb_r_df_decorate(SEXP dest, duckdb::idx_t nrows, SEXP class_ = R_NilValue);
void duckdb_r_decorate(const duckdb::LogicalType &type, SEXP dest, const duckdb::ConvertOpts &convert_opts);
void duckdb_r_transform(const duckdb::Vector &src_vec, SEXP dest, duckdb::idx_t dest_offset, duckdb::idx_t n,
                        const duckdb::ConvertOpts &convert_opts, const duckdb::string &name);

SEXP get_attrib(SEXP vec, SEXP name);

template <typename T, typename... ARGS>
cpp11::external_pointer<T> make_external(const std::string &rclass, ARGS &&... args) {
	auto extptr = cpp11::external_pointer<T>(new T(std::forward<ARGS>(args)...));
	((cpp11::sexp)extptr).attr("class") = rclass;
	return extptr;
}

template <typename T, typename... ARGS>
cpp11::external_pointer<T> make_external_prot(const std::string &rclass, SEXP prot, ARGS &&... args) {
	auto extptr = cpp11::external_pointer<T>(new T(std::forward<ARGS>(args)...), true, true, prot);
	((cpp11::sexp)extptr).attr("class") = rclass;
	return extptr;
}
