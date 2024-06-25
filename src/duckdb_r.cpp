#include "R_ext/Rdynload.h"
#include "Rdefines.h"
#include <dlfcn.h>


#ifdef _WIN32


#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#define RTLD_NOW   0
#define RTLD_LOCAL 0
inline void *dlopen(const char *file, int mode) {
	D_ASSERT(file);
	auto fpath = WindowsUtil::UTF8ToUnicode(file);
	return (void *)LoadLibraryW(fpath.c_str());
}

inline void *dlsym(void *handle, const char *name) {
	D_ASSERT(handle);
	return (void *)GetProcAddress((HINSTANCE)handle, name);
}

inline std::string GetDLError(void) {
	return LocalFileSystem::GetLastErrorAsString();
}
#endif

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

static SEXP duckdb_adbc() {
	auto init_func_xptr =
		  PROTECT(R_MakeExternalPtrFn((DL_FUNC)dlsym(duckdb_r_dlopen_handle, "duckdb_adbc_init"), R_NilValue, R_NilValue));
	Rf_setAttrib(init_func_xptr, R_ClassSymbol, Rf_mkString("adbc_driver_init_func"));
	UNPROTECT(1);
	return init_func_xptr;
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
void R_init_duckdbneo(DllInfo *dll) {
	R_registerRoutines(dll, nullptr, generated_methods, nullptr, nullptr);
	R_useDynamicSymbols(dll, FALSE);
	R_forceSymbols(dll, TRUE);
}
}