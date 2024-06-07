#include "R_ext/Rdynload.h"
#include "Rdefines.h"
#include <dlfcn.h>

static void* duckdb_r_dlopen_handle;

// small helper to actually call dlopen, we don't know the package location on library load
static SEXP duckdb_load_library(SEXP path_sexp) {
	auto path = CHAR(STRING_ELT(path_sexp, 0));
	duckdb_r_dlopen_handle = dlopen(path, RTLD_GLOBAL | RTLD_NOW);
	if (!duckdb_r_dlopen_handle) {
		Rf_error("Unable to load shared object");
	}
	return Rf_ScalarLogical(true);
}
#define DUCKDB_NO_EXTENSION_FUNCTIONS
#define DUCKDB_API_NO_DEPRECATED
#include "duckdb_r_generated.cpp"

extern "C" {
void R_init_duckdb(DllInfo *dll) {
	R_registerRoutines(dll, nullptr, generated_methods, nullptr, nullptr);
	R_useDynamicSymbols(dll, FALSE);
	R_forceSymbols(dll, TRUE);
}
}