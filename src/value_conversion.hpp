#pragma once

#include "duckdb.h"
#include "Rdefines.h"

#include <algorithm>


namespace duckdb_r {


// C++ 20 magic ^^
template<size_t N>
struct StringLiteral {
	constexpr StringLiteral(const char (&str)[N]) {
		std::copy_n(str, N, value);
	}
	char value[N];
};


template <class T, StringLiteral NAME>

class PointerWrapper {
public:

	static void Finalize(SEXP s) {
		free((T*) R_ExternalPtrAddr(s));
		R_ClearExternalPtr(s);
	}

	static SEXP Allocate() {
		return Wrap(malloc(sizeof(T)));
	}

	static SEXP Wrap( void* ptr) {
		// TODO cache this string?
		auto ptr_sexp = R_MakeExternalPtr(ptr, Rf_ScalarString(mkChar(NAME.value)), R_NilValue);
		R_RegisterCFinalizerEx(ptr_sexp, Finalize, Rboolean::FALSE);
		return ptr_sexp;
	}
};

class ValueConversion {
public:
	template <class DUCKDB_NATIVE_TYPE>
	static SEXP ToR(DUCKDB_NATIVE_TYPE val) {
		//static_assert(false, "Unimplemented value conversion to R");
		return nullptr;
	}


	template <>
	SEXP ToR(const char* val) {
		return Rf_ScalarString(mkChar(val));
	}

	template <>
	SEXP ToR(idx_t val) {
		return Rf_ScalarReal(val);
	}

	template <>
	SEXP ToR(duckdb_data_chunk val) {
		auto res = PointerWrapper<duckdb_data_chunk , "duckdb_data_chunk">::Allocate();
		*(duckdb_data_chunk*)R_ExternalPtrAddr(res) = val;
		return res;
	}

	template <>
	SEXP ToR(duckdb_vector val) {
		// TOOD reduce code replication here
		auto res = PointerWrapper<duckdb_vector , "duckdb_vector">::Allocate();
		*(duckdb_vector*)R_ExternalPtrAddr(res) = val;
		return res;
	}

	template <>
SEXP ToR(duckdb_logical_type val) {
		// TOOD reduce code replication here
		auto res = PointerWrapper<duckdb_vector , "duckdb_logical_type">::Allocate();
		*(duckdb_logical_type*)R_ExternalPtrAddr(res) = val;
		return res;
	}


	template <>
	SEXP ToR(uint64_t *val) {
		auto res = PointerWrapper<void* , "duckdb_void_ptr">::Allocate();
		R_SetExternalPtrAddr(res, val);
		return res;
	}

	template <>
SEXP ToR(void *val) {
		auto res = PointerWrapper<void* , "duckdb_void_ptr">::Allocate();
		R_SetExternalPtrAddr(res, val);
		return res;
	}


	template <>
	SEXP ToR(duckdb_state val) {
		return ScalarInteger(val);
	}

	template <>
	SEXP ToR(duckdb_type val) {
		return ScalarInteger(val);
	}


	template <class DUCKDB_NATIVE_TYPE>
	static DUCKDB_NATIVE_TYPE FromR(SEXP x) {
		//static_assert(false, "Unimplemented value conversion from R");
		Rf_error("Unimplemented value conversion from R");
	}

	template <>
	const char* FromR(SEXP x) {
		return CHAR(STRING_ELT(x, 0));
	}

	template <>
	idx_t FromR(SEXP x) {
		return (idx_t) DOUBLE_DATA(x)[0];
	}

	template <>
	int32_t FromR(SEXP x) {
		return INTEGER_DATA(x)[0];
	}

	template <>
	duckdb_database* FromR(SEXP x) {
		const char* name = "duckdb_database";
		const char* tag = CHAR(STRING_ELT(R_ExternalPtrTag(x), 0));
		if (strcmp(tag, name) != 0) {
			Rf_error("Passed a %s, expected %s", tag,name);
		}
		return (duckdb_database*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_database FromR(SEXP x) {
		return *FromR<duckdb_database*>(x);
	}

	template <>
	duckdb_connection* FromR(SEXP x) {
		const char* name = "duckdb_connection";
		const char* tag = CHAR(STRING_ELT(R_ExternalPtrTag(x), 0));
		if (strcmp(tag, name) != 0) {
			Rf_error("Passed a %s, expected %s", tag,name);
		}
		return (duckdb_connection*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_connection FromR(SEXP x) {
		return *FromR<duckdb_connection*>(x);
	}

	template <>
	duckdb_prepared_statement * FromR(SEXP x) {
		const char* name = "duckdb_prepared_statement";
		const char* tag = CHAR(STRING_ELT(R_ExternalPtrTag(x), 0));
		if (strcmp(tag, name) != 0) {
			Rf_error("Passed a %s, expected %s", tag,name);
		}
		return (duckdb_prepared_statement*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_prepared_statement FromR(SEXP x) {
		return *FromR<duckdb_prepared_statement*>(x);
	}


	template <>
	duckdb_result * FromR(SEXP x) {
		const char* name = "duckdb_result";
		const char* tag = CHAR(STRING_ELT(R_ExternalPtrTag(x), 0));
		if (strcmp(tag, name) != 0) {
			Rf_error("Passed a %s, expected %s", tag,name);
		}
		return (duckdb_result*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_result FromR(SEXP x) {
		return *FromR<duckdb_result*>(x);
	}

	template <>
	duckdb_data_chunk * FromR(SEXP x) {
		const char* name = "duckdb_data_chunk";
		const char* tag = CHAR(STRING_ELT(R_ExternalPtrTag(x), 0));
		if (strcmp(tag, name) != 0) {
			Rf_error("Passed a %s, expected %s", tag,name);
		}
		return (duckdb_data_chunk*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_data_chunk FromR(SEXP x) {
		return *FromR<duckdb_data_chunk*>(x);
	}


	template <>
	duckdb_vector * FromR(SEXP x) {
		const char* name = "duckdb_vector";
		const char* tag = CHAR(STRING_ELT(R_ExternalPtrTag(x), 0));
		if (strcmp(tag, name) != 0) {
			Rf_error("Passed a %s, expected %s", tag,name);
		}
		return (duckdb_vector*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_vector FromR(SEXP x) {
		return *FromR<duckdb_vector*>(x);
	}

	template <>
	duckdb_logical_type * FromR(SEXP x) {
		const char* name = "duckdb_logical_type";
		const char* tag = CHAR(STRING_ELT(R_ExternalPtrTag(x), 0));
		if (strcmp(tag, name) != 0) {
			Rf_error("Passed a %s, expected %s", tag,name);
		}
		return (duckdb_logical_type*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_logical_type FromR(SEXP x) {
		return *FromR<duckdb_logical_type*>(x);
	}


};
} // namespace duckdb_node