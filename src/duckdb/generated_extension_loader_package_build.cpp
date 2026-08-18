#ifndef DUCKDB_EXTENSION_PARQUET_LINKED
#define DUCKDB_EXTENSION_PARQUET_LINKED 1
#endif

#ifndef DUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED
#define DUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED 1
#endif

#if DUCKDB_EXTENSION_PARQUET_LINKED
#include "parquet_extension.hpp"
#endif
#if DUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED
#include "core_functions_extension.hpp"
#endif
#include "duckdb/main/extension/generated_extension_loader.hpp"
#include "duckdb/main/extension_helper.hpp"
#include "duckdb/main/config.hpp"
#include "duckdb/main/database.hpp"


namespace duckdb {

//! Publishes the package_build.py-generated list of extensions linked into this binary onto the config, so that
//! ExtensionHelper::LoadExtension can find them - including when it is called from code carrying its
//! own copy of DuckDB, which links no generated loader of its own.
void ExtensionHelper::RegisterLinkedExtensions(DBConfig &config) {
#if DUCKDB_EXTENSION_PARQUET_LINKED
    config.linked_extensions.push_back({"parquet", [](DuckDB &db) {
        db.LoadStaticExtension<ParquetExtension>();
    }});
#endif
#if DUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED
    config.linked_extensions.push_back({"core_functions", [](DuckDB &db) {
        db.LoadStaticExtension<CoreFunctionsExtension>();
    }});
#endif

}

vector<string> LinkedExtensions(){
    vector<string> VEC = {
#if DUCKDB_EXTENSION_PARQUET_LINKED
        "parquet",
#endif
#if DUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED
        "core_functions",
#endif
    };
    return VEC;
}

vector<string> ExtensionHelper::LoadedExtensionTestPaths(){
    vector<string> VEC = {
    };
    return VEC;
}
}
