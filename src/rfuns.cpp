#include "rfuns_extension.hpp"

#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"

#include <math.h>
#include <climits>

namespace duckdb {
namespace rfuns {

namespace {
void BaseRAddFunctionInteger(DataChunk &args, ExpressionState &state, Vector &result) {
	auto parts = BinaryTypeAssert<LogicalType::INTEGER, LogicalType::INTEGER>(args);

	BinaryExecutor::ExecuteWithNulls<int32_t, int32_t, int32_t>(
	    parts.lefts, parts.rights, result, args.size(), [&](int32_t left, int32_t right, ValidityMask &mask, idx_t idx) {
		    int64_t result = (int64_t)left + right;
		    if (result > INT_MAX || result < (INT_MIN + 1)) {
			    // FIXME: Need warning: NAs produced by integer overflow
			    mask.SetInvalid(idx);
			    return 0;
		    }
		    return (int32_t)result;
	    });
}

void BaseRAddFunctionDouble(DataChunk &args, ExpressionState &state, Vector &result) {
	auto parts = BinaryTypeAssert<LogicalType::DOUBLE, LogicalType::DOUBLE>(args);

	BinaryExecutor::ExecuteWithNulls<double, double, double>(
	    parts.lefts, parts.rights, result, args.size(), [&](double left, double right, ValidityMask &mask, idx_t idx) {
		    if (isnan(left) || isnan(right)) {
			    mask.SetInvalid(idx);
			    return 0.0;
		    }
		    return left + right;
	    });
}

double ExecuteBaseRPlusFunctionIntDouble(int32_t left, double right, ValidityMask &mask, idx_t idx) {
	if (isnan(right)) {
		mask.SetInvalid(idx);
		return 0.0;
	}
	return left + right;
}

void BaseRAddFunctionIntDouble(DataChunk &args, ExpressionState &state, Vector &result) {
	auto parts = BinaryTypeAssert<LogicalType::INTEGER, LogicalType::DOUBLE>(args);

	BinaryExecutor::ExecuteWithNulls<int32_t, double, double>(
	    parts.lefts, parts.rights, result, args.size(), ExecuteBaseRPlusFunctionIntDouble);
}

void BaseRAddFunctionDoubleInt(DataChunk &args, ExpressionState &state, Vector &result) {
	auto parts = BinaryTypeAssert<LogicalType::DOUBLE, LogicalType::INTEGER>(args);

	BinaryExecutor::ExecuteWithNulls<int32_t, double, double>(
	    parts.rights, parts.lefts, result, args.size(), ExecuteBaseRPlusFunctionIntDouble);
}

} // namespace

ScalarFunctionSet base_r_add() {
	ScalarFunctionSet set("r_base::+");
	set.AddFunction(
	    ScalarFunction({LogicalType::INTEGER, LogicalType::INTEGER}, LogicalType::INTEGER, BaseRAddFunctionInteger));
	set.AddFunction(
	    ScalarFunction({LogicalType::DOUBLE, LogicalType::DOUBLE}, LogicalType::DOUBLE, BaseRAddFunctionDouble));

	// <int> + <double>
	set.AddFunction(
	    ScalarFunction({LogicalType::INTEGER, LogicalType::DOUBLE}, LogicalType::DOUBLE, BaseRAddFunctionIntDouble));
	set.AddFunction(
	    ScalarFunction({LogicalType::DOUBLE, LogicalType::INTEGER}, LogicalType::DOUBLE, BaseRAddFunctionDoubleInt));

	return set;
}

} // namespace rfuns
} // namespace duckdb
#include "rfuns_extension.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"
#include "duckdb/common/operator/double_cast_operator.hpp"

#include <math.h>
#include <climits>
#include <limits>

namespace duckdb {
namespace rfuns {

namespace {

template <typename T>
int32_t check_range(T value, ValidityMask &mask, idx_t idx) {
	if (value > std::numeric_limits<int32_t>::max() || value < std::numeric_limits<int32_t>::min() ) {
		mask.SetInvalid(idx);
	}

	return static_cast<int32_t>(value);
}

template <typename T>
int32_t cast(T input, ValidityMask &mask, idx_t idx) {
	return static_cast<int32_t>(input);
}

template <>
int32_t cast<double>(double input, ValidityMask &mask, idx_t idx) {
	if (isnan(input)) {
		mask.SetInvalid(idx);
	}
	return check_range(input, mask, idx);
}

template <>
int32_t cast<string_t>(string_t input, ValidityMask &mask, idx_t idx) {
	double result;
	if (!TryDoubleCast<double>(input.GetData(), input.GetSize(), result, false)) {
		mask.SetInvalid(idx);
	}

	return cast<double>(result, mask, idx);
}

template <>
int32_t cast<date_t>(date_t input, ValidityMask &mask, idx_t idx) {
	return input.days;
}

template <>
int32_t cast<timestamp_t>(timestamp_t input, ValidityMask &mask, idx_t idx) {
	return check_range(Timestamp::GetEpochSeconds(input), mask, idx);
}

template <LogicalTypeId TYPE>
ScalarFunction AsIntegerFunction() {
	using physical_type = typename physical<TYPE>::type;

	auto fun = [](DataChunk &args, ExpressionState &state, Vector &result) {
		UnaryExecutor::ExecuteWithNulls<physical_type, int32_t>(
			args.data[0], result, args.size(), cast<physical_type>
		);
	};
	return ScalarFunction({TYPE}, LogicalType::INTEGER, fun);
}

}

ScalarFunctionSet base_r_as_integer() {
	ScalarFunctionSet set("r_base::as.integer");

	set.AddFunction(AsIntegerFunction<LogicalType::BOOLEAN>());
	set.AddFunction(AsIntegerFunction<LogicalType::INTEGER>());
	set.AddFunction(AsIntegerFunction<LogicalType::DOUBLE>());

	set.AddFunction(AsIntegerFunction<LogicalType::VARCHAR>());

	set.AddFunction(AsIntegerFunction<LogicalType::DATE>());
	set.AddFunction(AsIntegerFunction<LogicalType::TIMESTAMP>());

	return set;
}

}
}
#include "rfuns_extension.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"

#include <math.h>
#include <climits>

namespace duckdb {
namespace rfuns {

ScalarFunctionSet binary_dispatch(ScalarFunctionSet fn) {
	ScalarFunctionSet set(StringUtil::Format("dispatch(%s)", fn.name));

	set.AddFunction(ScalarFunction(
		{LogicalType::ANY, LogicalType::ANY},
		LogicalType::VARCHAR,
		[fn](DataChunk &args, ExpressionState &state, Vector &result) {
			vector<LogicalType> types(args.data.size());
			types[0] = args.data[0].GetType();
			types[1] = args.data[1].GetType();
			auto variant = const_cast<ScalarFunctionSet&>(fn).GetFunctionByArguments(state.GetContext(), types);

			auto info = StringUtil::Format(
				"lhs = %s, rhs = %s, signature = %s",
				EnumUtil::ToChars(types[0].id()),
				EnumUtil::ToChars(types[1].id()),
				variant.ToString().c_str()
			);
			result.SetValue(0, info);
		}
	));
	return set;
}

} // namespace rfuns
} // namespace duckdb
#include "rfuns_extension.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"

#include <math.h>
#include <climits>
#include <iostream>

namespace duckdb {
namespace rfuns {

void isna_double(DataChunk &args, ExpressionState &state, Vector &result) {
	auto count = args.size();
	auto input = args.data[0];
	auto mask = FlatVector::Validity(input);
	auto* data = FlatVector::GetData<double>(input);

	result.SetVectorType(VectorType::FLAT_VECTOR);
	auto result_data = FlatVector::GetData<bool>(result);

	idx_t base_idx = 0;
	auto entry_count = ValidityMask::EntryCount(count);
	for (idx_t entry_idx = 0; entry_idx < entry_count; entry_idx++) {
		auto validity_entry = mask.GetValidityEntry(entry_idx);
		idx_t next = MinValue<idx_t>(base_idx + ValidityMask::BITS_PER_VALUE, count);

		if (ValidityMask::AllValid(validity_entry)) {
			// all valid: check with isnan()
			for (; base_idx < next; base_idx++) {
				result_data[base_idx] = isnan(data[base_idx]);
			}
		} else if (ValidityMask::NoneValid(validity_entry)) {
			// None valid:
			for (; base_idx < next; base_idx++) {
				result_data[base_idx] = true;
			}
		} else {
			// partially valid: need to check individual elements for validity
			idx_t start = base_idx;
			for (; base_idx < next; base_idx++) {
				if (ValidityMask::RowIsValid(validity_entry, base_idx - start)) {
					D_ASSERT(mask.RowIsValid(base_idx));
					result_data[base_idx] = isnan(data[base_idx]);
				} else {
					result_data[base_idx] = true;
				}
			}
		}
	}
}

void isna_any(DataChunk &args, ExpressionState &state, Vector &result) {
	auto count = args.size();
	auto input = args.data[0];
	auto mask = FlatVector::Validity(input);

	result.SetVectorType(VectorType::FLAT_VECTOR);
	auto result_data = FlatVector::GetData<bool>(result);

	if (mask.AllValid()) {
		for (idx_t i = 0; i < count; i++) {
			result_data[i] = false;
		}
		return;
	}

	idx_t base_idx = 0;
	auto entry_count = ValidityMask::EntryCount(count);
	for (idx_t entry_idx = 0; entry_idx < entry_count; entry_idx++) {
		auto validity_entry = mask.GetValidityEntry(entry_idx);
		idx_t next = MinValue<idx_t>(base_idx + ValidityMask::BITS_PER_VALUE, count);

		if (ValidityMask::AllValid(validity_entry)) {
			// all valid: check with isnan()
			for (; base_idx < next; base_idx++) {
				result_data[base_idx] = false;
			}
		} else if (ValidityMask::NoneValid(validity_entry)) {
			// None valid:
			for (; base_idx < next; base_idx++) {
				result_data[base_idx] = true;
			}
		} else {
			// partially valid: need to check individual elements for validity
			idx_t start = base_idx;
			for (; base_idx < next; base_idx++) {
				result_data[base_idx] = !ValidityMask::RowIsValid(validity_entry, base_idx - start);
			}
		}
	}
}


ScalarFunctionSet base_r_is_na() {
	ScalarFunctionSet set("r_base::is.na");

	set.AddFunction(ScalarFunction({LogicalType::DOUBLE}, LogicalType::BOOLEAN, isna_double));
	set.AddFunction(ScalarFunction({LogicalType::ANY}   , LogicalType::BOOLEAN, isna_any));

	return set;
}

}
}
#include "rfuns_extension.hpp"

#include "duckdb/parser/parsed_data/create_aggregate_function_info.hpp"

#include <math.h>
#include <climits>
#include "duckdb/core_functions/aggregate/distributive_functions.hpp"

namespace duckdb {
namespace rfuns {

template <class T>
struct RMinMaxState {
	T value;
	bool is_set;
	bool is_null;
};

template <class MinMaxOP, bool NA_RM>
struct RMinMaxOperation {

	template <class STATE>
	static void Initialize(STATE &state) {
		state.is_set = false;
		state.is_null = false;
	}

	static bool IgnoreNull() {
		return NA_RM;
	}

	template <class INPUT_TYPE, class STATE, class OP>
	static void Operation(STATE &state, const INPUT_TYPE &input, AggregateUnaryInput &unary_input) {
		if (state.is_null) return;

		if (!NA_RM && !unary_input.RowIsValid()) {
			state.is_null = true;
		} else if (!state.is_set ){
			state.value = input;
			state.is_set = true;
		} else {
			MinMaxOP::template Execute<STATE, INPUT_TYPE>(state, input);
		}
	}

	template <class INPUT_TYPE, class STATE, class OP>
	static void ConstantOperation(STATE &state, const INPUT_TYPE &input, AggregateUnaryInput &unary_input, idx_t count) {
		if (state.is_null) return;

		if (!NA_RM && !unary_input.RowIsValid()) {
			state.is_null = true;
		} else if (!state.is_set ){
			state.value = input;
			state.is_set = true;
		} else {
			MinMaxOP::template Execute<STATE, INPUT_TYPE>(state, input);
		}
	}

	template <class STATE, class OP>
	static void Combine(const STATE &source, STATE &target, AggregateInputData &) {
		if (!source.is_set) {
			return;
		}

		if (!target.is_set) {
			target = source;
		}
	}

	template <class T, class STATE>
	static void Finalize(STATE &state, T &target, AggregateFinalizeData &finalize_data) {
		if (state.is_null || !state.is_set) {
			finalize_data.ReturnNull();
		} else {
			target = state.value;
		}
	}
};

struct RMinOperation {
	template <class STATE, class INPUT_TYPE>
	static void Execute(STATE &state, INPUT_TYPE input) {
		if (LessThan::Operation<INPUT_TYPE>(input, state.value)) {
			state.value = input;
		}
	}

};

struct RMaxOperation {
	template <class STATE, class INPUT_TYPE>
	static void Execute(STATE &state, INPUT_TYPE input) {
		if (GreaterThan::Operation<INPUT_TYPE>(input, state.value)) {
			state.value = input;
		}
	}
};

template <typename OP, typename T, bool NA_RM>
unique_ptr<FunctionData> BindRMinMax_dispatch(ClientContext &context, AggregateFunction &function, vector<unique_ptr<Expression>> &arguments) {
	auto type = arguments[0]->return_type;
	function = AggregateFunction::UnaryAggregate<RMinMaxState<T>, T, T, RMinMaxOperation<OP, NA_RM>>(type, type) ;
	return nullptr;
}

template <typename OP, typename T>
unique_ptr<FunctionData> BindRMinMax(ClientContext &context, AggregateFunction &function, vector<unique_ptr<Expression>> &arguments) {
	auto na_rm = arguments[1]->ToString() == "true";
	if (na_rm) {
		return BindRMinMax_dispatch<OP, T, true>(context, function, arguments);
	} else {
		return BindRMinMax_dispatch<OP, T, false>(context, function, arguments);
	}
}

template <typename OP, LogicalTypeId TYPE>
void add_RMinMax(AggregateFunctionSet& set) {
	set.AddFunction(AggregateFunction(
		{TYPE, LogicalType::BOOLEAN}, TYPE,
		nullptr, nullptr, nullptr, nullptr, nullptr, FunctionNullHandling::DEFAULT_NULL_HANDLING, nullptr,
		BindRMinMax<OP, typename physical<TYPE>::type>
	));

	set.AddFunction(AggregateFunction(
		{TYPE}, TYPE,
		nullptr, nullptr, nullptr, nullptr, nullptr, FunctionNullHandling::DEFAULT_NULL_HANDLING, nullptr,
		BindRMinMax_dispatch<OP, typename physical<TYPE>::type, false>
	));
}

template <typename OP>
AggregateFunctionSet base_r_minmax(std::string name) {
	AggregateFunctionSet set(name);

	add_RMinMax<OP, LogicalType::BOOLEAN>(set);
	add_RMinMax<OP, LogicalType::INTEGER>(set);
	add_RMinMax<OP, LogicalType::DOUBLE>(set);
	add_RMinMax<OP, LogicalType::TIMESTAMP>(set);
	add_RMinMax<OP, LogicalType::DATE>(set);

	return set;
}

AggregateFunctionSet base_r_min() {
	return base_r_minmax<RMinOperation>("r_base::min");
}

AggregateFunctionSet base_r_max() {
	return base_r_minmax<RMaxOperation>("r_base::max");
}


}
}
#include "rfuns_extension.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"

#include <math.h>
#include <climits>
#include <iostream>

namespace duckdb {
namespace rfuns {

namespace {

enum Relop {
	EQ,
	NEQ,
	LT,
	LTE,
	GT,
	GTE
};

template <typename LHS, typename RHS, Relop OP>
struct SimpleDispatch {
	inline bool operator()(LHS lhs, RHS rhs);
};


template <typename LHS, typename RHS>
struct SimpleDispatch<LHS, RHS, EQ> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs == rhs;
	}
};

template <typename LHS, typename RHS>
struct SimpleDispatch<LHS, RHS, NEQ> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return !(lhs == rhs);
	}
};

template <typename LHS, typename RHS>
struct SimpleDispatch<LHS, RHS, LT> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs < rhs;
	}
};

template <typename LHS, typename RHS>
struct SimpleDispatch<LHS, RHS, LTE> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs < rhs || lhs == rhs;
	}
};

template <typename LHS, typename RHS>
struct SimpleDispatch<LHS, RHS, GT> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs > rhs;
	}
};

template <typename LHS, typename RHS>
struct SimpleDispatch<LHS, RHS, GTE> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs > rhs || lhs == rhs;
	}
};

template <typename LHS, typename RHS, Relop OP>
struct RelopDispatch {
	inline bool operator()(LHS lhs, RHS rhs) {
		return SimpleDispatch<LHS, RHS, OP>()(lhs, rhs);
	}
};

template <typename LHS, typename RHS, Relop OP>
inline bool relop(LHS lhs, RHS rhs);

// borrowed from EncodeInteger
string_t to_string(int x) {
	char s[100];
	snprintf(s, sizeof(s), "%d", x);
	return string_t(s);
}

string_t to_string(bool x) {
	return string_t(x ? "TRUE" : "FALSE");
}

string_t to_string(double x) {
	char s[100];
	snprintf(s, sizeof(s), "%.17g", x);
	return string_t(s);
}

template <Relop OP>
struct RelopDispatch<string_t, date_t, OP> {
	inline bool operator()(string_t lhs, date_t rhs) {
		return SimpleDispatch<date_t, date_t, OP>()(Date::FromString(lhs.GetData(), false), rhs);
	}
};

template <Relop OP>
struct RelopDispatch<date_t, string_t, OP> {
	inline bool operator()(date_t lhs, string_t rhs) {
		return SimpleDispatch<date_t, date_t, OP>()(lhs, Date::FromString(rhs.GetData(), false));
	}
};

template <Relop OP>
struct RelopDispatch<string_t, timestamp_t, OP> {
	inline bool operator()(string_t lhs, timestamp_t rhs) {
		return SimpleDispatch<timestamp_t, timestamp_t, OP>()(Timestamp::FromString(lhs.GetData()), rhs);
	}
};

template <Relop OP>
struct RelopDispatch<timestamp_t, string_t, OP> {
	inline bool operator()(timestamp_t lhs, string_t rhs) {
		return SimpleDispatch<timestamp_t, timestamp_t, OP>()(lhs, Timestamp::FromString(rhs.GetData()));
	}
};

template <typename LHS, Relop OP>
struct RelopDispatch<LHS, string_t, OP> {
	inline bool operator()(LHS lhs, string_t rhs) {
		return SimpleDispatch<string_t, string_t, OP>()(to_string(lhs), rhs);
	}
};

template <typename RHS, Relop OP>
struct RelopDispatch<string_t, RHS, OP> {
	inline bool operator()(string_t lhs, RHS rhs) {
		return SimpleDispatch<string_t, string_t, OP>()(lhs, to_string(rhs));
	}
};

template <Relop OP>
struct RelopDispatch<string_t, string_t, OP> {
	inline bool operator()(string_t lhs, string_t rhs) {
		return SimpleDispatch<string_t, string_t, OP>()(lhs, rhs);
	}
};

template <typename LHS, typename RHS, Relop OP>
inline bool relop(LHS lhs, RHS rhs) {
	return RelopDispatch<LHS, RHS, OP>()(lhs, rhs);
}

template <typename LHS, typename RHS>
struct relop_adds_null : public std::integral_constant<bool, false>{};

template <typename LHS>
struct relop_adds_null<LHS, double> : public std::integral_constant<bool, true>{};

template <typename RHS>
struct relop_adds_null<double, RHS> : public std::integral_constant<bool, true>{};

template <>
struct relop_adds_null<double, double> : public std::integral_constant<bool, true>{};

template <typename T>
bool set_null(T value, ValidityMask &mask, idx_t idx) {
	return false;
}

template <>
bool set_null<double>(double value, ValidityMask &mask, idx_t idx) {
	if (isnan(value)) {
		mask.SetInvalid(idx);
		return true;
	}
	return false;
}

template <LogicalTypeId LHS_LOGICAL, typename LHS_TYPE, LogicalTypeId RHS_LOGICAL, typename RHS_TYPE, Relop OP>
void RelopExecuteDispatch(DataChunk &args, ExpressionState &state, Vector &result, std::false_type) {
	auto parts = BinaryTypeAssert<LHS_LOGICAL, RHS_LOGICAL>(args);
	BinaryExecutor::Execute<LHS_TYPE, RHS_TYPE, bool>(parts.lefts, parts.rights, result, args.size(), relop<LHS_TYPE, RHS_TYPE, OP>);
}

template <LogicalTypeId LHS_LOGICAL, typename LHS_TYPE, LogicalTypeId RHS_LOGICAL, typename RHS_TYPE, Relop OP>
void RelopExecuteDispatch(DataChunk &args, ExpressionState &state, Vector &result, std::true_type) {
	auto parts = BinaryTypeAssert<LHS_LOGICAL, RHS_LOGICAL>(args);
	auto fun = [&](LHS_TYPE left, RHS_TYPE right, ValidityMask &mask, idx_t idx) {
		if (set_null<LHS_TYPE>(left, mask, idx)) return false;
		if (set_null<RHS_TYPE>(right, mask, idx)) return false;
		return relop<LHS_TYPE, RHS_TYPE, OP>(left, right);
	};
	BinaryExecutor::ExecuteWithNulls<LHS_TYPE, RHS_TYPE, bool>(parts.lefts, parts.rights, result, args.size(), fun);
}

template <LogicalTypeId LHS_LOGICAL, typename LHS_TYPE, LogicalTypeId RHS_LOGICAL, typename RHS_TYPE, Relop OP>
void RelopExecute(DataChunk &args, ExpressionState &state, Vector &result) {
	RelopExecuteDispatch<LHS_LOGICAL, LHS_TYPE, RHS_LOGICAL, RHS_TYPE, OP>(args, state, result, typename relop_adds_null<LHS_TYPE, RHS_TYPE>::type());
}

#define RELOP_VARIANT(__LHS__, __RHS__) ScalarFunction(                      \
	/* arguments   = */ {LogicalType::__LHS__, LogicalType::__RHS__},        \
	/* return_type = */ LogicalType::BOOLEAN,                                \
	/* function    = */ RelopExecute<                                        \
		LogicalType::__LHS__, typename physical<LogicalType::__LHS__>::type, \
	    LogicalType::__RHS__, typename physical<LogicalType::__RHS__>::type, \
	    OP                                                                   \
	>)

#define RELOP_VARIANT_BIND_FAIL(__LHS__, __RHS__, __WHY__) ScalarFunction(                \
	  /* arguments   = */ {LogicalType::__LHS__, LogicalType::__RHS__},                   \
	  /* return_type = */ LogicalType::BOOLEAN,                                           \
	  /* function    = */ [](DataChunk &args, ExpressionState &state, Vector &result) {}, \
	  /* bind        = */ [](ClientContext &context, ScalarFunction &bound_function, vector<duckdb::unique_ptr<Expression>> &arguments) -> unique_ptr<FunctionData> { \
		throw InvalidInputException("%s : %s <=> %s", __WHY__, EnumUtil::ToChars(LogicalType::__LHS__), EnumUtil::ToChars(LogicalType::__RHS__)); \
		})

template <Relop OP>
ScalarFunctionSet base_r_relop(string name) {
	ScalarFunctionSet set(name);

	set.AddFunction(RELOP_VARIANT(BOOLEAN, BOOLEAN));
	set.AddFunction(RELOP_VARIANT(BOOLEAN, INTEGER));
	set.AddFunction(RELOP_VARIANT(INTEGER, BOOLEAN));
	set.AddFunction(RELOP_VARIANT(INTEGER, INTEGER));

	set.AddFunction(RELOP_VARIANT(DOUBLE, INTEGER));
	set.AddFunction(RELOP_VARIANT(INTEGER, DOUBLE));
	set.AddFunction(RELOP_VARIANT(DOUBLE, BOOLEAN));
	set.AddFunction(RELOP_VARIANT(BOOLEAN, DOUBLE));

	set.AddFunction(RELOP_VARIANT(VARCHAR, INTEGER));
	set.AddFunction(RELOP_VARIANT(INTEGER, VARCHAR));
	set.AddFunction(RELOP_VARIANT(VARCHAR, BOOLEAN));
	set.AddFunction(RELOP_VARIANT(BOOLEAN, VARCHAR));

	set.AddFunction(RELOP_VARIANT(DOUBLE, DOUBLE));
	set.AddFunction(RELOP_VARIANT(VARCHAR, VARCHAR));
	set.AddFunction(RELOP_VARIANT(VARCHAR, DOUBLE));
	set.AddFunction(RELOP_VARIANT(DOUBLE, VARCHAR));

	set.AddFunction(RELOP_VARIANT(TIMESTAMP, TIMESTAMP));
	set.AddFunction(RELOP_VARIANT(DATE, DATE));

	set.AddFunction(RELOP_VARIANT(DATE, VARCHAR));
	set.AddFunction(RELOP_VARIANT(VARCHAR, DATE));

	set.AddFunction(RELOP_VARIANT(TIMESTAMP, VARCHAR));
	set.AddFunction(RELOP_VARIANT(VARCHAR, TIMESTAMP));

	set.AddFunction(RELOP_VARIANT_BIND_FAIL(TIMESTAMP, DATE, "Comparing times and dates is not supported"));
	set.AddFunction(RELOP_VARIANT_BIND_FAIL(DATE, TIMESTAMP, "Comparing dates and times is not supported"));

	return set;
}

} // namespace

ScalarFunctionSet base_r_eq() {
	return base_r_relop<EQ>("r_base::==");
}
ScalarFunctionSet base_r_neq() {
	return base_r_relop<NEQ>("r_base::!=");
}
ScalarFunctionSet base_r_lt() {
	return base_r_relop<LT>("r_base::<");
}
ScalarFunctionSet base_r_lte() {
	return base_r_relop<LTE>("r_base::<=");
}
ScalarFunctionSet base_r_gt() {
	return base_r_relop<GT>("r_base::>");
}
ScalarFunctionSet base_r_gte() {
	return base_r_relop<GTE>("r_base::>=");
}

} // namespace rfuns
} // namespace duckdb
#define DUCKDB_EXTENSION_MAIN

#include "rfuns_extension.hpp"
#include "duckdb.hpp"
#include "duckdb/common/exception.hpp"
#include "duckdb/function/scalar_function.hpp"
#include "duckdb/main/extension_util.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"

#include <math.h>
#include <climits>

namespace duckdb {
namespace rfuns {

static void register_binary(DatabaseInstance &instance, ScalarFunctionSet fun) {
	// fun()
	ExtensionUtil::RegisterFunction(instance, fun);

	// dispatch(fun())
	ExtensionUtil::RegisterFunction(instance, binary_dispatch(fun));
}

static void register_rfuns(DatabaseInstance &instance) {
	// +
	register_binary(instance, base_r_add());

	// relop
	register_binary(instance, base_r_eq());
	register_binary(instance, base_r_neq());
	register_binary(instance, base_r_lt());
	register_binary(instance, base_r_lte());
	register_binary(instance, base_r_gt());
	register_binary(instance, base_r_gte());

	ExtensionUtil::RegisterFunction(instance, base_r_is_na());
	ExtensionUtil::RegisterFunction(instance, base_r_as_integer());

	ExtensionUtil::RegisterFunction(instance, base_r_sum());
	ExtensionUtil::RegisterFunction(instance, base_r_min());
	ExtensionUtil::RegisterFunction(instance, base_r_max());
}
}  // namespace rfuns

static void LoadInternal(DatabaseInstance &instance) {
	rfuns::register_rfuns(instance);
}

void RfunsExtension::Load(DuckDB &db) {
	LoadInternal(*db.instance);
}
std::string RfunsExtension::Name() {
	return "rfuns";
}

} // namespace duckdb

extern "C" {

DUCKDB_EXTENSION_API void rfuns_init(duckdb::DatabaseInstance &db) {
	duckdb::DuckDB db_wrapper(db);
	db_wrapper.LoadExtension<duckdb::RfunsExtension>();
}

DUCKDB_EXTENSION_API const char *rfuns_version() {
	return duckdb::DuckDB::LibraryVersion();
}
}

#ifndef DUCKDB_EXTENSION_MAIN
#error DUCKDB_EXTENSION_MAIN not defined
#endif
#include "rfuns_extension.hpp"

#include "duckdb/parser/parsed_data/create_aggregate_function_info.hpp"

#include <math.h>
#include <climits>
#include "duckdb/core_functions/aggregate/sum_helpers.hpp"
#include "duckdb/core_functions/aggregate/distributive_functions.hpp"

namespace duckdb {
namespace rfuns {

template <class T>
struct RSumKeepNaState {
	T value;
	bool is_set;
	bool is_null;
};

template <class ADDOP, bool NA_RM>
struct RSumOperation {

	template <class STATE>
	static void Initialize(STATE &state) {
		state.is_set = false;
		state.is_null = false;
	}

	static bool IgnoreNull() {
		return NA_RM;
	}

	template <class INPUT_TYPE, class STATE, class OP>
	static void Operation(STATE &state, const INPUT_TYPE &input, AggregateUnaryInput &unary_input) {
		if (state.is_null) return;
		if (!NA_RM && !unary_input.RowIsValid()) {
			state.is_null = true;
		} else {
			if (!state.is_set) {
				state.is_set = true;
			}
			ADDOP::template AddNumber<STATE, INPUT_TYPE>(state, input);
		}
	}

	template <class INPUT_TYPE, class STATE, class OP>
	static void ConstantOperation(STATE &state, const INPUT_TYPE &input, AggregateUnaryInput &unary_input, idx_t count) {
		if (!NA_RM && !unary_input.RowIsValid()) {
			state.is_null = true;
		} else {
			if (!state.is_set) {
				state.is_set = true;
			}
			ADDOP::template AddConstant<STATE, INPUT_TYPE>(state, input, count);
		}
	}

	template <class STATE, class OP>
	static void Combine(const STATE &source, STATE &target, AggregateInputData &) {
		if (!target.is_set) {
			target = source;
		}
	}

	template <class T, class STATE>
	static void Finalize(STATE &state, T &target, AggregateFinalizeData &finalize_data) {
		if (state.is_null) {
			finalize_data.ReturnNull();
		} else {
			target = state.value;
		}
	}
};

template <bool NA_RM>
unique_ptr<FunctionData> BindRSum_dispatch(ClientContext &context, AggregateFunction &function, vector<unique_ptr<Expression>> &arguments) {
	auto type = arguments[0]->return_type;

	switch (type.id()) {
	case LogicalTypeId::DOUBLE:
		function = AggregateFunction::UnaryAggregate<RSumKeepNaState<double>, double, double, RSumOperation<RegularAdd, NA_RM>>(type, type);
		break;
	case LogicalTypeId::INTEGER:
		function = AggregateFunction::UnaryAggregate<RSumKeepNaState<hugeint_t>, int32_t, hugeint_t, RSumOperation<HugeintAdd, NA_RM>>(type, type);
		break;
	case LogicalTypeId::BOOLEAN:
		function = AggregateFunction::UnaryAggregate<RSumKeepNaState<int32_t>, bool, int32_t, RSumOperation<RegularAdd, NA_RM>>(LogicalType::BOOLEAN, LogicalType::INTEGER);
		break;
	default:
		break;
	}

	return nullptr;
}

unique_ptr<FunctionData> BindRSum(ClientContext &context, AggregateFunction &function, vector<unique_ptr<Expression>> &arguments) {
	auto na_rm = arguments[1]->ToString() == "true";
	if (na_rm) {
		return BindRSum_dispatch<true>(context, function, arguments);
	} else {
		return BindRSum_dispatch<false>(context, function, arguments);
	}
}

void add_RSum(AggregateFunctionSet& set, const LogicalType& type) {
	auto return_type = type == LogicalType::BOOLEAN ? LogicalType::INTEGER : type;
	set.AddFunction(AggregateFunction(
		{type, LogicalType::BOOLEAN}, return_type,
		nullptr, nullptr, nullptr, nullptr, nullptr, FunctionNullHandling::DEFAULT_NULL_HANDLING, nullptr,
		BindRSum
	));

	set.AddFunction(AggregateFunction(
		{type}, return_type,
		nullptr, nullptr, nullptr, nullptr, nullptr, FunctionNullHandling::DEFAULT_NULL_HANDLING, nullptr,
		BindRSum_dispatch<false>
	));
}

AggregateFunctionSet base_r_sum() {
	AggregateFunctionSet set("r_base::sum");

	add_RSum(set, LogicalType::BOOLEAN);
	add_RSum(set, LogicalType::INTEGER);
	add_RSum(set, LogicalType::DOUBLE);

	return set;
}

}
}
