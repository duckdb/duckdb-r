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


	template <class T>
	static T FromR(SEXP x) {
		//static_assert(false, "Unimplemented value conversion from R");
	}

};
} // namespace duckdb_node