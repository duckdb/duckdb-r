#include "R_ext/Rdynload.h"
#include "Rdefines.h"
#include <dlfcn.h>

static SEXP duckdb_load_library(SEXP path_sexp) {
	auto path = CHAR(STRING_ELT(path_sexp, 0));
	auto res = dlopen(path, RTLD_GLOBAL | RTLD_NOW);
	if (!res) {
		Rf_error("Unable to load shared object");
	}
	return Rf_ScalarLogical(true);
}

#include "duckdb_r_generated.cpp"


extern "C" {
void R_init_duckdb(DllInfo *dll) {
	R_registerRoutines(dll, nullptr, generated_methods, nullptr, nullptr);
}
}