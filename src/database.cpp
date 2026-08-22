#include "duckdb/catalog/catalog_entry/table_function_catalog_entry.hpp"
#include "duckdb/common/vector_operations/generic_executor.hpp"
#include "duckdb/function/cast/cast_function_set.hpp"
#include "duckdb/main/client_context.hpp"
#include "duckdb/main/db_instance_cache.hpp"
#include "duckdb/parser/parsed_data/create_table_function_info.hpp"
#include "duckdb/parser/parsed_data/create_type_info.hpp"
#include "rapi.hpp"

// Avoid clash with TRUE and FALSE macros in older rtools
#undef TRUE
#undef FALSE

using namespace duckdb;

static bool CastRstringToVarchar(Vector &source, Vector &result, idx_t count, CastParameters &parameters) {
	GenericExecutor::ExecuteUnary<PrimitiveType<uintptr_t>, PrimitiveType<string_t>>(
	    source, result, count,
	    [&](PrimitiveType<uintptr_t> input) { return StringVector::AddString(result, (const char *)input.val); });
	return true;
}

namespace {

// One instance cache for the process, and the `DBWrapper` each instance
// carries. Explained in handbook/usage/connections/README.md.
//
// The wrapper is per instance, not per call. `config.replacement_scans` holds a
// raw pointer to it, and `DBConfig::operator==` compares only `options`, so a
// cache hit hands back an instance whose scans still point at the *first*
// caller's wrapper -- a second wrapper would be one nothing routes to. The map
// is what lets a later call find the instance's own.
struct RInstanceCache {
	DBInstanceCache cache;
	mutex lock;
	unordered_map<DatabaseInstance *, std::weak_ptr<DBWrapper>> wrappers;
};

RInstanceCache &GetRInstanceCache() {
	static RInstanceCache instance_cache;
	return instance_cache;
}

} // namespace

[[cpp11::register]] duckdb::db_eptr_t rapi_startup(std::string dbdir, bool readonly, cpp11::list configsexp,
                                                   bool environment_scan, bool allow_extensions) {
	// Hard stop when poisoned: every DuckDB session starts here, so this single
	// guard ensures no test or example can reach the C++ engine on CRAN.
	DUCKDB_R_POISON_GUARD();

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
	config.SetOptionByName("duckdb_api", "r-dbi");

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

	// Built before the cache call because `config.replacement_scans` has to
	// carry its address, and kept only if this call is the one that creates the
	// instance -- otherwise the instance's own wrapper is the live one.
	// `std::shared_ptr`, not duckdb's: `DualWrapper` holds the standard one.
	auto wrapper = std::make_shared<DBWrapper>();
	wrapper->allow_extensions = allow_extensions;

	auto &r_cache = GetRInstanceCache();
	shared_ptr<DuckDB> db;

	try {
		auto data1 = make_uniq<ReplacementDataDBWrapper>();
		data1->wrapper = wrapper.get();
		config.replacement_scans.emplace_back(ArrowScanReplacement, std::move(data1));

		if (environment_scan) {
			auto data2 = make_uniq<ReplacementDataDBWrapper>();
			data2->wrapper = wrapper.get();
			config.replacement_scans.emplace_back(EnvironmentScanReplacement, std::move(data2));
		}

		// An in-memory database has no file to share and is never cached: every
		// duckdb() call gets a fresh, isolated instance.
		auto behavior = dbdirchar ? CacheBehavior::ALWAYS_CACHE : CacheBehavior::NEVER_CACHE;
		bool created = false;

		db = r_cache.cache.GetOrCreateInstance(
		    dbdirchar ? dbdir : string(IN_MEMORY_PATH), config, behavior, [&](DuckDB &instance_db) {
			    created = true;

			    auto &instance = *instance_db.instance;
			    auto &catalog = Catalog::GetSystemCatalog(instance);
			    auto transaction = CatalogTransaction::GetSystemTransaction(instance);
			    auto &schema = catalog.GetSchema(transaction, DEFAULT_SCHEMA);
			    auto scan_entry = schema.GetEntry(transaction, CatalogType::TABLE_FUNCTION_ENTRY, "arrow_scan");
			    auto &arrow_scan = scan_entry->Cast<TableFunctionCatalogEntry>();
			    for (auto &function : arrow_scan.functions.functions) {
				    function.global_initialization = TableFunctionInitialization::INITIALIZE_ON_SCHEDULE;
			    }

			    // Registering these a second time is an error, so they belong here,
			    // where the callback runs once per instance rather than per call.
			    DataFrameScanFunction scan_fun;
			    CreateTableFunctionInfo info(scan_fun);
			    Connection conn(instance_db);
			    auto &context = *conn.context;
			    auto &conn_catalog = Catalog::GetSystemCatalog(context);
			    context.transaction.BeginTransaction();
			    conn_catalog.CreateTableFunction(context, &info);
			    auto &runtime_config = DBConfig::GetConfig(context);
			    auto &casts = runtime_config.GetCastFunctions();
			    casts.RegisterCastFunction(RStringsType::Get(), LogicalType::VARCHAR, CastRstringToVarchar);
			    context.transaction.Commit();
		    });

		lock_guard<mutex> guard(r_cache.lock);
		if (created) {
			wrapper->db = db;
			r_cache.wrappers[db->instance.get()] = wrapper;
		} else {
			// Reused: the scans built above are discarded with the wrapper they
			// point at, and the instance's own wrapper takes over.
			auto entry = r_cache.wrappers.find(db->instance.get());
			std::shared_ptr<DBWrapper> existing;
			if (entry != r_cache.wrappers.end()) {
				existing = entry->second.lock();
			}
			if (!existing) {
				rapi_error_with_context("rapi_startup", "Reused a database instance this package did not create");
			}
			wrapper = std::move(existing);
		}
	} catch (std::exception &e) {
		rapi_error_with_context("rapi_startup", e);
	}
	D_ASSERT(wrapper->db);

	auto dual = new DBWrapperDual(wrapper);

	return db_eptr_t(dual);
}

// The path the engine settled on, which is the instance's identity: canonical,
// and an extension-prefixed `dbdir` left as it stands. The R layer stores it on
// the driver so `dbGetInfo()` reports what the engine opened, not what the
// caller spelled.
[[cpp11::register]] std::string rapi_database_path(duckdb::db_eptr_t dual) {
	if (!dual || !dual.get()) {
		rapi_error_with_context("rapi_database_path", "Invalid database reference");
	}
	auto wrapper = dual->get();
	if (!wrapper || !wrapper->db) {
		rapi_error_with_context("rapi_database_path", "Database is already shut down");
	}
	return DBConfig::GetConfig(*wrapper->db->instance).options.database_path;
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
