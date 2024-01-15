#pragma once

#include "duckdb.h"
#include "Rdefines.h"

namespace duckdb_r {
//
//typedef uint8_t data_t;
//
//static Napi::Value GetValue(const Napi::CallbackInfo &info, size_t offset) {
//	Napi::Env env = info.Env();
//
//	if (info.Length() < offset) {
//		throw Napi::TypeError::New(env, "Value expected at offset " + std::to_string(offset));
//	}
//	return info[offset].As<Napi::Value>();
//}

class ValueConversion {
public:
	template <class T>
	static SEXP ToR(T val) {
		//static_assert(false, "Unimplemented value conversion to R");
		return nullptr;

	}


	template <>
	SEXP ToR(const char* val) {
		return Rf_ScalarString(mkChar(val));
	}

	template <>
	SEXP ToR(duckdb_state val) {
		switch (val) {
		case DuckDBSuccess:
			// TODO do we dont want to allocate a string here, maybe cache them?
			return Rf_ScalarString(mkChar("DuckDBSuccess"));
		case DuckDBError:
			return Rf_ScalarString(mkChar("DuckDBError"));
		}
	}


	template <class T>
	static T FromR(SEXP x) {
		//static_assert(false, "Unimplemented value conversion from R");
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
		return (duckdb_database*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_database FromR(SEXP x) {
		return *FromR<duckdb_database*>(x);
	}

	template <>
	duckdb_connection* FromR(SEXP x) {
		return (duckdb_connection*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_connection FromR(SEXP x) {
		return *FromR<duckdb_connection*>(x);
	}

	template <>
	duckdb_prepared_statement * FromR(SEXP x) {
		return (duckdb_prepared_statement*) R_ExternalPtrAddr(x);
	}

	template <>
	duckdb_prepared_statement FromR(SEXP x) {
		return *FromR<duckdb_prepared_statement*>(x);
	}

};
} // namespace duckdb_node