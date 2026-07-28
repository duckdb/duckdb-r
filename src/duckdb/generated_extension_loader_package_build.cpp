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

namespace duckdb {

//! Looks through the package_build.py-generated list of extensions that are linked into DuckDB currently to try load <extension>
ExtensionLoadResult ExtensionHelper::LoadExtension(DuckDB &db, const std::string &extension) {
#if DUCKDB_EXTENSION_PARQUET_LINKED
    if (extension=="parquet") {
        db.LoadStaticExtension<ParquetExtension>();
        return ExtensionLoadResult::LOADED_EXTENSION;
    }
#endif
#if DUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED
    if (extension=="core_functions") {
        db.LoadStaticExtension<CoreFunctionsExtension>();
        return ExtensionLoadResult::LOADED_EXTENSION;
    }
#endif

    return ExtensionLoadResult::NOT_LOADED;
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

void ExtensionHelper::LoadAllExtensions(DuckDB &db) {
    for (auto& ext_name : LinkedExtensions()) {
        LoadExtension(db, ext_name);
    }
}

vector<string> ExtensionHelper::LoadedExtensionTestPaths(){
    vector<string> VEC = {
    };
    return VEC;
}
}
