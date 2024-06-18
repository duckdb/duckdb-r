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

static SEXP duckdb_copy_buffer(SEXP x, SEXP len_sexp) {
	const char* name = "duckdb_void_ptr";
	void* ptr;
	if (IS_NUMERIC((x))) {
		auto ptr_dbl = NUMERIC_POINTER(x)[0];
		ptr = (void*) *((uintptr_t*) &ptr_dbl);
	} else {
		const char* tag = CHAR(STRING_ELT(R_ExternalPtrTag(x), 0));
		if (strcmp(tag, name) != 0) {
			Rf_error("Passed a %s, expected %s", tag,name);
		}
		ptr = R_ExternalPtrAddr(x);
	}
	if (!ptr) {
		Rf_error("Pointer cannot be 0");
	}
	auto len = INTEGER_DATA(len_sexp)[0]; // TODO check
	auto res = NEW_RAW(len);
	memcpy(RAW_POINTER((res)), ptr,len );
	return res;
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