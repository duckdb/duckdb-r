#pragma once
#include "value_conversion.hpp"
#include <dlfcn.h>
#include <mutex>

namespace duckdb_r {


template<typename T> void GetFunctionPointer(const char* name, T* out_ptr) {
	if (!*out_ptr) {
		*out_ptr = (T) dlsym(duckdb_r_dlopen_handle, name);
		if (!*out_ptr) {
			Rf_error("Unable to find symbol");
		}
	}
}


class FunctionWrappers {
public:
	template <class ARG1, StringLiteral NAME>
	static SEXP FunctionWrapper1Void(SEXP arg1_sexp) {
		static void (*fun)(ARG1) = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		auto arg1 = ValueConversion::FromR<ARG1>(arg1_sexp);
		fun(arg1);
		return R_NilValue;
	}

	template <class RET, StringLiteral NAME>
	static SEXP FunctionWrapper0() {
		static RET (*fun)() = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		RET ret = fun();
		return ValueConversion::ToR(ret);
	}

	template <class RET, class ARG1, StringLiteral NAME>
	static SEXP FunctionWrapper1(SEXP arg1_sexp) {
		static RET (*fun)(ARG1) = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		auto arg1 = ValueConversion::FromR<ARG1>(arg1_sexp);
		auto ret = fun(arg1);
		return ValueConversion::ToR(ret);
	}

	template <class RET, class ARG1, class ARG2, StringLiteral NAME>
	static SEXP FunctionWrapper2(SEXP arg1_sexp, SEXP arg2_sexp) {
		static RET (*fun)(ARG1, ARG2) = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		auto arg1 = ValueConversion::FromR<ARG1>(arg1_sexp);
		auto arg2 = ValueConversion::FromR<ARG2>(arg2_sexp);
		auto ret = fun(arg1, arg2);
		return ValueConversion::ToR(ret);
	}

	template <class ARG1, class ARG2, StringLiteral NAME>
	static SEXP FunctionWrapper2Void(SEXP arg1_sexp, SEXP arg2_sexp) {
		static void (*fun)(ARG1, ARG2) = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		auto arg1 = ValueConversion::FromR<ARG1>(arg1_sexp);
		auto arg2 = ValueConversion::FromR<ARG2>(arg2_sexp);
		fun(arg1, arg2);
		return R_NilValue;
	}

	template <class RET, class ARG1, class ARG2, class ARG3, StringLiteral NAME>
	static SEXP FunctionWrapper3(SEXP arg1_sexp, SEXP arg2_sexp, SEXP arg3_sexp) {
		static RET (*fun)(ARG1, ARG2, ARG3) = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		auto arg1 = ValueConversion::FromR<ARG1>(arg1_sexp);
		auto arg2 = ValueConversion::FromR<ARG2>(arg2_sexp);
		auto arg3 = ValueConversion::FromR<ARG3>(arg3_sexp);
		auto ret = fun(arg1, arg2, arg3);
		return ValueConversion::ToR(ret);
	}

	template <class ARG1, class ARG2, class ARG3, StringLiteral NAME>
	static SEXP FunctionWrapper3Void(SEXP arg1_sexp, SEXP arg2_sexp, SEXP arg3_sexp) {
		static void (*fun)(ARG1, ARG2, ARG3) = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		auto arg1 = ValueConversion::FromR<ARG1>(arg1_sexp);
		auto arg2 = ValueConversion::FromR<ARG2>(arg2_sexp);
		auto arg3 = ValueConversion::FromR<ARG3>(arg3_sexp);
		fun(arg1, arg2, arg3);
		return R_NilValue;
	}

	template <class RET, class ARG1, class ARG2, class ARG3, class ARG4, StringLiteral NAME>
	static SEXP FunctionWrapper4(SEXP arg1_sexp, SEXP arg2_sexp, SEXP arg3_sexp, SEXP arg4_sexp) {
		static RET (*fun)(ARG1, ARG2, ARG3, ARG4) = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		auto arg1 = ValueConversion::FromR<ARG1>(arg1_sexp);
		auto arg2 = ValueConversion::FromR<ARG2>(arg2_sexp);
		auto arg3 = ValueConversion::FromR<ARG3>(arg3_sexp);
		auto arg4 = ValueConversion::FromR<ARG4>(arg4_sexp);

		auto ret = fun(arg1, arg2, arg3, arg4);
		return ValueConversion::ToR(ret);
	}

	template <class ARG1, class ARG2, class ARG3, class ARG4, StringLiteral NAME>
	static SEXP FunctionWrapper4Void(SEXP arg1_sexp, SEXP arg2_sexp, SEXP arg3_sexp, SEXP arg4_sexp) {
		static void (*fun)(ARG1, ARG2, ARG3, ARG4) = nullptr;
		GetFunctionPointer(NAME.value, &fun);
		auto arg1 = ValueConversion::FromR<ARG1>(arg1_sexp);
		auto arg2 = ValueConversion::FromR<ARG2>(arg2_sexp);
		auto arg3 = ValueConversion::FromR<ARG3>(arg3_sexp);
		auto arg4 = ValueConversion::FromR<ARG4>(arg4_sexp);

		fun(arg1, arg2, arg3, arg4);
		return R_NilValue;
	}
};
} // namespace duckdb_node