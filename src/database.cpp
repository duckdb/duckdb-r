#include "rapi.hpp"

#include "duckdb/main/client_context.hpp"
#include "duckdb/parser/parsed_data/create_table_function_info.hpp"
#include "duckdb/parser/parsed_data/create_type_info.hpp"
#include "duckdb/function/cast/cast_function_set.hpp"
#include "duckdb/common/vector_operations/generic_executor.hpp"
#include "duckdb/catalog/catalog_entry/table_function_catalog_entry.hpp"

using namespace duckdb;

static bool CastRstringToVarchar(Vector &source, Vector &result, idx_t count, CastParameters &parameters) {
	GenericExecutor::ExecuteUnary<PrimitiveType<uintptr_t>, PrimitiveType<string_t>>(
	    source, result, count,
	    [&](PrimitiveType<uintptr_t> input) { return StringVector::AddString(result, (const char *)input.val); });
	return true;
}

[[cpp11::register]] duckdb::db_eptr_t rapi_startup(std::string dbdir, bool readonly, cpp11::list configsexp,
                                                   bool environment_scan) {
	const char *dbdirchar;

	if (dbdir.length() == 0 || dbdir.compare(IN_MEMORY_PATH) == 0) {
		dbdirchar = NULL;
	} else {
		dbdirchar = dbdir.c_str();
	}

	DBConfig config;
	if (readonly) {
		config.options.access_mode = AccessMode::READ_ONLY;
	}
	config.options.duckdb_api = "r-dbi";

	auto confignames = configsexp.names();

	for (auto it = confignames.begin(); it != confignames.end(); ++it) {
		std::string key = *it;
		std::string val = cpp11::as_cpp<std::string>(configsexp[key]);
		try {
			config.SetOptionByName(key, Value(val));
		} catch (std::exception &e) {
			rapi_error_with_context("rapi_startup", e);
		}
	}

	// FIXME: Rewrite properly with shared pointers
	auto wrapper_ = make_uniq<DBWrapper>();
	DBWrapper *wrapper = wrapper_.get();

	try {
		auto data1 = make_uniq<ReplacementDataDBWrapper>();
		data1->wrapper = wrapper;
		config.replacement_scans.emplace_back(ArrowScanReplacement, std::move(data1));

		if (environment_scan) {
			auto data2 = make_uniq<ReplacementDataDBWrapper>();
			data2->wrapper = wrapper;
			config.replacement_scans.emplace_back(EnvironmentScanReplacement, std::move(data2));
		}
		wrapper->db = make_uniq<DuckDB>(dbdirchar, &config);

		auto &instance = *wrapper->db->instance;
		auto &catalog = Catalog::GetSystemCatalog(instance);
		auto transaction = CatalogTransaction::GetSystemTransaction(instance);
		auto &schema = catalog.GetSchema(transaction, DEFAULT_SCHEMA);
		auto scan_entry = schema.GetEntry(transaction, CatalogType::TABLE_FUNCTION_ENTRY, "arrow_scan");
		auto &arrow_scan = scan_entry->Cast<TableFunctionCatalogEntry>();
		for (auto &function : arrow_scan.functions.functions) {
			function.global_initialization = TableFunctionInitialization::INITIALIZE_ON_SCHEDULE;
		}
	} catch (std::exception &e) {
		rapi_error_with_context("rapi_startup", e);
	}
	D_ASSERT(wrapper->db);

	DataFrameScanFunction scan_fun;
	CreateTableFunctionInfo info(scan_fun);
	Connection conn(*wrapper->db);
	auto &context = *conn.context;
	auto &catalog = Catalog::GetSystemCatalog(context);
	context.transaction.BeginTransaction();

	catalog.CreateTableFunction(context, &info);

	auto &runtime_config = DBConfig::GetConfig(context);

	auto &casts = runtime_config.GetCastFunctions();
	casts.RegisterCastFunction(RStringsType::Get(), LogicalType::VARCHAR, CastRstringToVarchar);

	context.transaction.Commit();

	auto dual = new DBWrapperDual(wrapper_.release());
	wrapper = nullptr;

	return db_eptr_t(dual);
}

[[cpp11::register]] bool rapi_lock(duckdb::db_eptr_t dual) {
	if (!dual || !dual.get()) {
		rapi_error_with_context("rapi_lock", "Invalid database reference");
	}
	dual->lock();
	return dual->has();
}

[[cpp11::register]] void rapi_unlock(duckdb::db_eptr_t dual) {
	if (!dual || !dual.get()) {
		rapi_error_with_context("rapi_unlock", "Invalid database reference");
	}
	dual->unlock();
}

[[cpp11::register]] bool rapi_is_locked(duckdb::db_eptr_t dual) {
	if (!dual || !dual.get()) {
		rapi_error_with_context("rapi_is_locked", "Invalid database reference");
	}
	return dual->is_locked();
}

[[cpp11::register]] void rapi_shutdown(duckdb::db_eptr_t dbsexp) {
	auto db_wrapper = dbsexp.release();
	if (db_wrapper) {
		db_wrapper->reset();
		delete db_wrapper;
	}
}
