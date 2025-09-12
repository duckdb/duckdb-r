#include "rfuns_extension.hpp"

#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"
#include "duckdb/main/extension/extension_loader.hpp"

#include <math.h>
#include <climits>
#include <cmath>

namespace duckdb {
namespace rfuns {

namespace {
void BaseRAddFunctionInteger(DataChunk &args, ExpressionState &state, Vector &result) {
	auto parts = BinaryTypeAssert<LogicalType::INTEGER, LogicalType::INTEGER>(args);

	BinaryExecutor::ExecuteWithNulls<int32_t, int32_t, int32_t>(
	    parts.lefts, parts.rights, result, args.size(),
	    [&](int32_t left, int32_t right, ValidityMask &mask, idx_t idx) {
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
		    if (std::isnan(left) || std::isnan(right)) {
			    mask.SetInvalid(idx);
			    return 0.0;
		    }
		    return left + right;
	    });
}

double ExecuteBaseRPlusFunctionIntDouble(int32_t left, double right, ValidityMask &mask, idx_t idx) {
	if (std::isnan(right)) {
		mask.SetInvalid(idx);
		return 0.0;
	}
	return left + right;
}

void BaseRAddFunctionIntDouble(DataChunk &args, ExpressionState &state, Vector &result) {
	auto parts = BinaryTypeAssert<LogicalType::INTEGER, LogicalType::DOUBLE>(args);

	BinaryExecutor::ExecuteWithNulls<int32_t, double, double>(parts.lefts, parts.rights, result, args.size(),
	                                                          ExecuteBaseRPlusFunctionIntDouble);
}

void BaseRAddFunctionDoubleInt(DataChunk &args, ExpressionState &state, Vector &result) {
	auto parts = BinaryTypeAssert<LogicalType::DOUBLE, LogicalType::INTEGER>(args);

	BinaryExecutor::ExecuteWithNulls<int32_t, double, double>(parts.rights, parts.lefts, result, args.size(),
	                                                          ExecuteBaseRPlusFunctionIntDouble);
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
#include <cmath>

namespace duckdb {
namespace rfuns {

namespace {

template <typename T>
int32_t check_int_range(T value, ValidityMask &mask, idx_t idx) {
	if (value > std::numeric_limits<int32_t>::max() || value < std::numeric_limits<int32_t>::min()) {
		mask.SetInvalid(idx);
	}

	return static_cast<int32_t>(value);
}

template <typename FROM, typename TO>
TO cast(FROM input, ValidityMask &mask, idx_t idx) {
	return static_cast<TO>(input);
}

template <>
int32_t cast<double, int32_t>(double input, ValidityMask &mask, idx_t idx) {
	if (std::isnan(input)) {
		mask.SetInvalid(idx);
	}
	return check_int_range(input, mask, idx);
}

template <>
double cast<string_t, double>(string_t input, ValidityMask &mask, idx_t idx) {
	double result;
	if (!TryDoubleCast<double>(input.GetData(), input.GetSize(), result, false)) {
		mask.SetInvalid(idx);
	}

	return result;
}

template <>
int32_t cast<string_t, int32_t>(string_t input, ValidityMask &mask, idx_t idx) {
	auto dbl = cast<string_t, double>(input, mask, idx);
	return cast<double, int32_t>(dbl, mask, idx);
}

template <>
int32_t cast<date_t, int32_t>(date_t input, ValidityMask &mask, idx_t idx) {
	return input.days;
}

template <>
double cast<date_t, double>(date_t input, ValidityMask &mask, idx_t idx) {
	return input.days;
}

template <>
int32_t cast<timestamp_t, int32_t>(timestamp_t input, ValidityMask &mask, idx_t idx) {
	return check_int_range(Timestamp::GetEpochSeconds(input), mask, idx);
}

template <>
double cast<timestamp_t, double>(timestamp_t input, ValidityMask &mask, idx_t idx) {
	return check_int_range(Timestamp::GetEpochSeconds(input), mask, idx);
}

template <LogicalTypeId TYPE, LogicalTypeId RESULT_TYPE>
ScalarFunction AsNumberFunction() {
	using physical_type = typename physical<TYPE>::type;
	using result_type = typename physical<RESULT_TYPE>::type;

	auto fun = [](DataChunk &args, ExpressionState &state, Vector &result) {
		UnaryExecutor::ExecuteWithNulls<physical_type, result_type>(args.data[0], result, args.size(),
		                                                            cast<physical_type, result_type>);
	};
	return ScalarFunction({TYPE}, RESULT_TYPE, fun);
}

template <LogicalTypeId RESULT_TYPE>
ScalarFunctionSet as_number(std::string name) {
	ScalarFunctionSet set(name);

	set.AddFunction(AsNumberFunction<LogicalType::BOOLEAN, RESULT_TYPE>());
	set.AddFunction(AsNumberFunction<LogicalType::INTEGER, RESULT_TYPE>());
	set.AddFunction(AsNumberFunction<LogicalType::DOUBLE, RESULT_TYPE>());
	set.AddFunction(AsNumberFunction<LogicalType::VARCHAR, RESULT_TYPE>());
	set.AddFunction(AsNumberFunction<LogicalType::DATE, RESULT_TYPE>());
	set.AddFunction(AsNumberFunction<LogicalType::TIMESTAMP, RESULT_TYPE>());

	return set;
}

} // namespace

ScalarFunctionSet base_r_as_integer() {
	return as_number<LogicalTypeId::INTEGER>("r_base::as.integer");
}

ScalarFunctionSet base_r_as_numeric() {
	return as_number<LogicalTypeId::DOUBLE>("r_base::as.numeric");
}

} // namespace rfuns
} // namespace duckdb
#include "rfuns_extension.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"

#include <math.h>
#include <climits>

namespace duckdb {
namespace rfuns {

ScalarFunctionSet binary_dispatch(ScalarFunctionSet fn) {
	ScalarFunctionSet set(StringUtil::Format("dispatch(%s)", fn.name));

	set.AddFunction(ScalarFunction(
	    {LogicalType::ANY, LogicalType::ANY}, LogicalType::VARCHAR,
	    [fn](DataChunk &args, ExpressionState &state, Vector &result) {
		    vector<LogicalType> types(args.data.size());
		    types[0] = args.data[0].GetType();
		    types[1] = args.data[1].GetType();
		    auto variant = const_cast<ScalarFunctionSet &>(fn).GetFunctionByArguments(state.GetContext(), types);

		    auto info = StringUtil::Format("lhs = %s, rhs = %s, signature = %s", EnumUtil::ToChars(types[0].id()),
		                                   EnumUtil::ToChars(types[1].id()), variant.ToString().c_str());
		    result.SetValue(0, info);
	    }));
	return set;
}

} // namespace rfuns
} // namespace duckdb
#include "rfuns_extension.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"

#include <math.h>
#include <climits>
#include <iostream>
#include <cmath>

namespace duckdb {
namespace rfuns {

void isna_double_loop(idx_t count, const double *data, bool *result_data, ValidityMask mask) {
	idx_t base_idx = 0;
	auto entry_count = ValidityMask::EntryCount(count);
	for (idx_t entry_idx = 0; entry_idx < entry_count; entry_idx++) {
		auto validity_entry = mask.GetValidityEntry(entry_idx);
		idx_t next = MinValue<idx_t>(base_idx + ValidityMask::BITS_PER_VALUE, count);

		if (ValidityMask::AllValid(validity_entry)) {
			// all valid: check with std::isnan()
			for (; base_idx < next; base_idx++) {
				result_data[base_idx] = std::isnan(data[base_idx]);
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
					result_data[base_idx] = std::isnan(data[base_idx]);
				} else {
					result_data[base_idx] = true;
				}
			}
		}
	}
}

void isna_double(DataChunk &args, ExpressionState &state, Vector &result) {
	auto count = args.size();
	auto input = args.data[0];

	switch (input.GetVectorType()) {
	case VectorType::FLAT_VECTOR: {
		result.SetVectorType(VectorType::FLAT_VECTOR);

		isna_double_loop(count, FlatVector::GetData<double>(input), FlatVector::GetData<bool>(result),
		                 FlatVector::Validity(input));

		break;
	}

	case VectorType::CONSTANT_VECTOR: {
		result.SetVectorType(VectorType::CONSTANT_VECTOR);
		auto result_data = ConstantVector::GetData<bool>(result);
		auto ldata = ConstantVector::GetData<double>(input);

		*result_data = ConstantVector::IsNull(input) || std::isnan(*ldata);

		break;
	}

	default: {
		UnifiedVectorFormat vdata;
		input.ToUnifiedFormat(count, vdata);
		result.SetVectorType(VectorType::FLAT_VECTOR);

		isna_double_loop(count, UnifiedVectorFormat::GetData<double>(vdata), FlatVector::GetData<bool>(result),
		                 vdata.validity);

		break;
	}
	}
}

void isna_any_loop(idx_t count, bool *result_data, ValidityMask mask) {
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
			// all valid
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

void isna_any(DataChunk &args, ExpressionState &state, Vector &result) {
	auto count = args.size();
	auto input = args.data[0];

	switch (input.GetVectorType()) {
	case VectorType::FLAT_VECTOR: {
		result.SetVectorType(VectorType::FLAT_VECTOR);
		isna_any_loop(count, FlatVector::GetData<bool>(result), FlatVector::Validity(input));

		break;
	}

	case VectorType::CONSTANT_VECTOR: {
		result.SetVectorType(VectorType::CONSTANT_VECTOR);
		auto result_data = ConstantVector::GetData<bool>(result);
		*result_data = ConstantVector::IsNull(input);

		break;
	}

	default: {
		UnifiedVectorFormat vdata;
		input.ToUnifiedFormat(count, vdata);
		result.SetVectorType(VectorType::FLAT_VECTOR);
		isna_any_loop(count, FlatVector::GetData<bool>(result), vdata.validity);

		break;
	}
	}
}

ScalarFunctionSet base_r_is_na() {
	ScalarFunctionSet set("r_base::is.na");

	set.AddFunction(ScalarFunction({LogicalType::DOUBLE}, LogicalType::BOOLEAN, isna_double));
	set.AddFunction(ScalarFunction({LogicalType::ANY}, LogicalType::BOOLEAN, isna_any));

	return set;
}

} // namespace rfuns
} // namespace duckdb
#include "rfuns_extension.hpp"

#include "duckdb/parser/parsed_data/create_aggregate_function_info.hpp"

#include <math.h>
#include <climits>
#include "duckdb/extension/core_functions/include/core_functions/aggregate/distributive_functions.hpp"

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
		if (state.is_null)
			return;

		if (!NA_RM && !unary_input.RowIsValid()) {
			state.is_null = true;
		} else if (!state.is_set) {
			state.value = input;
			state.is_set = true;
		} else {
			MinMaxOP::template Execute<STATE, INPUT_TYPE>(state, input);
		}
	}

	template <class INPUT_TYPE, class STATE, class OP>
	static void ConstantOperation(STATE &state, const INPUT_TYPE &input, AggregateUnaryInput &unary_input,
	                              idx_t count) {
		if (state.is_null)
			return;

		if (!NA_RM && !unary_input.RowIsValid()) {
			state.is_null = true;
		} else if (!state.is_set) {
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
unique_ptr<FunctionData> BindRMinMax_dispatch(ClientContext &context, AggregateFunction &function,
                                              vector<unique_ptr<Expression>> &arguments) {
	auto type = arguments[0]->return_type;
	function = AggregateFunction::UnaryAggregate<RMinMaxState<T>, T, T, RMinMaxOperation<OP, NA_RM>>(type, type);
	return nullptr;
}

template <typename OP, typename T>
unique_ptr<FunctionData> BindRMinMax(ClientContext &context, AggregateFunction &function,
                                     vector<unique_ptr<Expression>> &arguments) {
	auto na_rm = arguments[1]->ToString() == "true";
	if (na_rm) {
		return BindRMinMax_dispatch<OP, T, true>(context, function, arguments);
	} else {
		return BindRMinMax_dispatch<OP, T, false>(context, function, arguments);
	}
}

template <typename OP, LogicalTypeId TYPE>
void add_RMinMax(AggregateFunctionSet &set) {
	set.AddFunction(AggregateFunction({TYPE, LogicalType::BOOLEAN}, TYPE, nullptr, nullptr, nullptr, nullptr, nullptr,
	                                  FunctionNullHandling::DEFAULT_NULL_HANDLING, nullptr,
	                                  BindRMinMax<OP, typename physical<TYPE>::type>));

	set.AddFunction(AggregateFunction({TYPE}, TYPE, nullptr, nullptr, nullptr, nullptr, nullptr,
	                                  FunctionNullHandling::DEFAULT_NULL_HANDLING, nullptr,
	                                  BindRMinMax_dispatch<OP, typename physical<TYPE>::type, false>));
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

} // namespace rfuns
} // namespace duckdb
#include "rfuns_extension.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"
#include "duckdb/common/operator/string_cast.hpp"
#include "duckdb/common/operator/double_cast_operator.hpp"

#include <math.h>
#include <climits>
#include <iostream>
#include <cmath>

namespace duckdb {
namespace rfuns {

namespace {

enum Relop { EQ, NEQ, LT, LTE, GT, GTE };

template <typename LHS, typename RHS, Relop OP>
struct RelopDispatch {
	inline bool operator()(LHS lhs, RHS rhs);
};

template <typename LHS, typename RHS>
struct RelopDispatch<LHS, RHS, EQ> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs == rhs;
	}
};

template <typename LHS, typename RHS>
struct RelopDispatch<LHS, RHS, NEQ> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return !(lhs == rhs);
	}
};

template <typename LHS, typename RHS>
struct RelopDispatch<LHS, RHS, LT> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs < rhs;
	}
};

template <typename LHS, typename RHS>
struct RelopDispatch<LHS, RHS, LTE> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs < rhs || lhs == rhs;
	}
};

template <typename LHS, typename RHS>
struct RelopDispatch<LHS, RHS, GT> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs > rhs;
	}
};

template <typename LHS, typename RHS>
struct RelopDispatch<LHS, RHS, GTE> {
	inline bool operator()(LHS lhs, RHS rhs) {
		return lhs > rhs || lhs == rhs;
	}
};

template <typename LHS, typename RHS, Relop OP>
inline bool relop(LHS lhs, RHS rhs) {
	return RelopDispatch<LHS, RHS, OP>()(lhs, rhs);
}

template <typename LHS, typename RHS>
struct relop_adds_null : public std::integral_constant<bool, false> {};

template <typename LHS>
struct relop_adds_null<LHS, double> : public std::integral_constant<bool, true> {};

template <typename RHS>
struct relop_adds_null<double, RHS> : public std::integral_constant<bool, true> {};

template <>
struct relop_adds_null<double, double> : public std::integral_constant<bool, true> {};

template <typename T>
bool set_null(T value, ValidityMask &mask, idx_t idx) {
	return false;
}

template <>
bool set_null<double>(double value, ValidityMask &mask, idx_t idx) {
	if (std::isnan(value)) {
		mask.SetInvalid(idx);
		return true;
	}
	return false;
}

template <LogicalTypeId LHS_LOGICAL, typename LHS_TYPE, LogicalTypeId RHS_LOGICAL, typename RHS_TYPE, Relop OP>
void RelopExecuteDispatch(DataChunk &args, ExpressionState &state, Vector &result, std::false_type) {
	auto parts = BinaryTypeAssert<LHS_LOGICAL, RHS_LOGICAL>(args);
	BinaryExecutor::Execute<LHS_TYPE, RHS_TYPE, bool>(parts.lefts, parts.rights, result, args.size(),
	                                                  relop<LHS_TYPE, RHS_TYPE, OP>);
}

template <LogicalTypeId LHS_LOGICAL, typename LHS_TYPE, LogicalTypeId RHS_LOGICAL, typename RHS_TYPE, Relop OP>
void RelopExecuteDispatch(DataChunk &args, ExpressionState &state, Vector &result, std::true_type) {
	auto parts = BinaryTypeAssert<LHS_LOGICAL, RHS_LOGICAL>(args);
	auto fun = [&](LHS_TYPE left, RHS_TYPE right, ValidityMask &mask, idx_t idx) {
		if (set_null<LHS_TYPE>(left, mask, idx))
			return false;
		if (set_null<RHS_TYPE>(right, mask, idx))
			return false;
		return relop<LHS_TYPE, RHS_TYPE, OP>(left, right);
	};
	BinaryExecutor::ExecuteWithNulls<LHS_TYPE, RHS_TYPE, bool>(parts.lefts, parts.rights, result, args.size(), fun);
}

template <LogicalTypeId LHS_LOGICAL, typename LHS_TYPE, LogicalTypeId RHS_LOGICAL, typename RHS_TYPE, Relop OP>
void RelopExecute(DataChunk &args, ExpressionState &state, Vector &result) {
	RelopExecuteDispatch<LHS_LOGICAL, LHS_TYPE, RHS_LOGICAL, RHS_TYPE, OP>(
	    args, state, result, typename relop_adds_null<LHS_TYPE, RHS_TYPE>::type());
}

#define RELOP_VARIANT(__LHS__, __RHS__)                                                                                \
	ScalarFunction(/* arguments   = */ {LogicalType::__LHS__, LogicalType::__RHS__},                                   \
	               /* return_type = */ LogicalType::BOOLEAN, /* function    = */                                       \
	               RelopExecute<LogicalType::__LHS__, typename physical<LogicalType::__LHS__>::type,                   \
	                            LogicalType::__RHS__, typename physical<LogicalType::__RHS__>::type, OP>)

#define RELOP_VARIANT_BIND_FAIL(__LHS__, __RHS__, __WHY__)                                                             \
	ScalarFunction(/* arguments   = */                                                                                 \
	               {LogicalType::__LHS__, LogicalType::__RHS__}, /* return_type = */ LogicalType::BOOLEAN,             \
	               /* function    = */ [](DataChunk &args, ExpressionState &state, Vector &result) {}, /* bind = */    \
	               [](ClientContext &context, ScalarFunction &bound_function,                                          \
	                  vector<duckdb::unique_ptr<Expression>> &arguments) -> unique_ptr<FunctionData> {                 \
		               throw InvalidInputException("%s : %s <=> %s", __WHY__, EnumUtil::ToChars(LogicalType::__LHS__), \
		                                           EnumUtil::ToChars(LogicalType::__RHS__));                           \
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

	set.AddFunction(RELOP_VARIANT(DOUBLE, DOUBLE));
	set.AddFunction(RELOP_VARIANT(VARCHAR, VARCHAR));

	set.AddFunction(RELOP_VARIANT(TIMESTAMP, TIMESTAMP));
	set.AddFunction(RELOP_VARIANT(DATE, DATE));

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

namespace {

template <typename LHS_TYPE, typename RHS_TYPE>
bool try_equal(LHS_TYPE lhs, RHS_TYPE rhs) {
	return relop<LHS_TYPE, RHS_TYPE, EQ>(lhs, rhs);
}

template <typename LHS_TYPE, typename RHS_TYPE>
void InExecute(DataChunk &args, ExpressionState &state, Vector &result) {

	auto count = args.size();
	auto x = args.data[0];

	auto y = args.data[1];
	if (y.GetVectorType() != VectorType::CONSTANT_VECTOR) {
		throw InvalidInputException("rhs must be a constant");
	}
	auto y_size = ListVector::GetListSize(y);
	auto y_data = FlatVector::GetData<RHS_TYPE>(ListVector::GetEntry(y));
	auto y_mask = FlatVector::Validity(ListVector::GetEntry(y));

	bool na_in_y = [&]() {
		if (y_mask.AllValid()) {
			return false;
		}

		idx_t y_base_idx = 0;
		auto y_entry_count = ValidityMask::EntryCount(y_size);
		for (idx_t y_entry_idx = 0; y_entry_idx < y_entry_count; y_entry_idx++) {
			auto y_validity_entry = y_mask.GetValidityEntry(y_entry_idx);
			idx_t y_next = MinValue<idx_t>(y_base_idx + ValidityMask::BITS_PER_VALUE, y_size);

			if (ValidityMask::AllValid(y_validity_entry)) {
				continue;
			}

			if (ValidityMask::NoneValid(y_validity_entry)) {
				return true;
			}

			idx_t y_start = y_base_idx;
			for (; y_base_idx < y_next; y_base_idx++) {
				if (!ValidityMask::RowIsValid(y_validity_entry, y_base_idx - y_start)) {
					return true;
				}
			}
		}

		return false;
	}();

	auto is_in_y = [&](LHS_TYPE left) {
		// special case when there are no NAs in y
		if (!na_in_y) {
			for (idx_t i = 0; i < y_size; i++) {
				if (try_equal(left, y_data[i])) {
					return true;
				}
			}
			return false;
		}

		// there are NAs in y, so do entry by entry
		idx_t y_base_idx = 0;
		auto y_entry_count = ValidityMask::EntryCount(y_size);
		for (idx_t y_entry_idx = 0; y_entry_idx < y_entry_count; y_entry_idx++) {
			auto y_validity_entry = y_mask.GetValidityEntry(y_entry_idx);
			idx_t y_next = MinValue<idx_t>(y_base_idx + ValidityMask::BITS_PER_VALUE, y_size);

			if (ValidityMask::AllValid(y_validity_entry)) {
				for (; y_base_idx < y_next; y_base_idx++) {
					if (try_equal(left, y_data[y_base_idx])) {
						return true;
					}
				}
			} else if (ValidityMask::NoneValid(y_validity_entry)) {
				// nothing to do, because inside is_in_y() we know left is valid
				for (; y_base_idx < y_next; y_base_idx++) {
				}
			} else {
				idx_t y_start = y_base_idx;

				for (; y_base_idx < y_next; y_base_idx++) {
					if (ValidityMask::RowIsValid(y_validity_entry, y_base_idx - y_start)) {
						if (try_equal(left, y_data[y_base_idx])) {
							return true;
						}
					}
				}
			}
		}
		return false;
	};

	auto in_loop = [&](idx_t count, const LHS_TYPE *x_data, bool *result_data, const ValidityMask &mask) {
		idx_t base_idx = 0;
		auto entry_count = ValidityMask::EntryCount(count);
		for (idx_t entry_idx = 0; entry_idx < entry_count; entry_idx++) {
			auto validity_entry = mask.GetValidityEntry(entry_idx);
			idx_t next = MinValue<idx_t>(base_idx + ValidityMask::BITS_PER_VALUE, count);

			if (ValidityMask::AllValid(validity_entry)) {
				for (; base_idx < next; base_idx++) {
					result_data[base_idx] = is_in_y(x_data[base_idx]);
				}
			} else if (ValidityMask::NoneValid(validity_entry)) {
				// None valid:
				for (; base_idx < next; base_idx++) {
					result_data[base_idx] = !y_mask.AllValid();
				}
			} else {
				// partially valid: need to check individual elements for validity
				idx_t start = base_idx;

				for (; base_idx < next; base_idx++) {
					if (ValidityMask::RowIsValid(validity_entry, base_idx - start)) {
						result_data[base_idx] = is_in_y(x_data[base_idx]);
					} else {
						result_data[base_idx] = na_in_y;
					}
				}
			}
		}
	};

	switch (x.GetVectorType()) {
	case VectorType::FLAT_VECTOR: {
		result.SetVectorType(VectorType::FLAT_VECTOR);

		in_loop(count, FlatVector::GetData<LHS_TYPE>(x), FlatVector::GetData<bool>(result), FlatVector::Validity(x));

		break;
	}

	case VectorType::CONSTANT_VECTOR: {
		result.SetVectorType(VectorType::CONSTANT_VECTOR);
		auto result_data = ConstantVector::GetData<bool>(result);
		*result_data = is_in_y(*ConstantVector::GetData<LHS_TYPE>(x));

		break;
	}

	default: {
		UnifiedVectorFormat vdata;
		x.ToUnifiedFormat(count, vdata);
		result.SetVectorType(VectorType::FLAT_VECTOR);
		in_loop(count, UnifiedVectorFormat::GetData<LHS_TYPE>(vdata), FlatVector::GetData<bool>(result),
		        vdata.validity);

		break;
	}
	}
}

#define IN_VARIANT(__LHS__, __RHS__)                                                                                   \
	ScalarFunction(                                                                                                    \
	    /* arguments   = */ {LogicalType::__LHS__, LogicalType::LIST(LogicalType::__RHS__)},                           \
	    /* return_type = */ LogicalType::BOOLEAN, /* function    = */                                                  \
	    InExecute<typename physical<LogicalType::__LHS__>::type, typename physical<LogicalType::__RHS__>::type>)

} // namespace

ScalarFunctionSet base_r_in() {
	ScalarFunctionSet set("r_base::%in%");

	set.AddFunction(IN_VARIANT(DOUBLE, DOUBLE));
	set.AddFunction(IN_VARIANT(BOOLEAN, BOOLEAN));
	set.AddFunction(IN_VARIANT(BOOLEAN, INTEGER));
	set.AddFunction(IN_VARIANT(INTEGER, BOOLEAN));
	set.AddFunction(IN_VARIANT(INTEGER, INTEGER));

	set.AddFunction(IN_VARIANT(DOUBLE, INTEGER));
	set.AddFunction(IN_VARIANT(INTEGER, DOUBLE));
	set.AddFunction(IN_VARIANT(DOUBLE, BOOLEAN));
	set.AddFunction(IN_VARIANT(BOOLEAN, DOUBLE));

	set.AddFunction(IN_VARIANT(VARCHAR, VARCHAR));
	set.AddFunction(IN_VARIANT(TIMESTAMP, TIMESTAMP));
	set.AddFunction(IN_VARIANT(DATE, DATE));

	return set;
}

} // namespace rfuns
} // namespace duckdb
#define DUCKDB_EXTENSION_MAIN

#include "rfuns_extension.hpp"
#include "duckdb.hpp"
#include "duckdb/common/exception.hpp"
#include "duckdb/function/scalar_function.hpp"
#include "duckdb/parser/parsed_data/create_scalar_function_info.hpp"

#include <math.h>
#include <climits>

namespace duckdb {
namespace rfuns {

static void register_binary(ExtensionLoader &loader, ScalarFunctionSet fun) {
	// fun()
	loader.RegisterFunction(fun);

	// dispatch(fun())
	loader.RegisterFunction(binary_dispatch(fun));
}

static void register_rfuns(ExtensionLoader &loader) {
	// +
	register_binary(loader, base_r_add());

	// relop
	register_binary(loader, base_r_eq());
	register_binary(loader, base_r_neq());
	register_binary(loader, base_r_lt());
	register_binary(loader, base_r_lte());
	register_binary(loader, base_r_gt());
	register_binary(loader, base_r_gte());

	loader.RegisterFunction(base_r_is_na());
	loader.RegisterFunction(base_r_as_integer());
	loader.RegisterFunction(base_r_as_numeric());

	loader.RegisterFunction(base_r_in());

	loader.RegisterFunction(base_r_sum());
	loader.RegisterFunction(base_r_min());
	loader.RegisterFunction(base_r_max());
}
} // namespace rfuns

static void LoadInternal(ExtensionLoader &loader) {
	rfuns::register_rfuns(loader);
}

void RfunsExtension::Load(ExtensionLoader &loader) {
	LoadInternal(loader);
}
std::string RfunsExtension::Name() {
	return "rfuns";
}

} // namespace duckdb

extern "C" {

DUCKDB_EXTENSION_API void rfuns_init(duckdb::DatabaseInstance &db) {
	duckdb::DuckDB db_wrapper(db);
	db_wrapper.LoadStaticExtension<duckdb::RfunsExtension>();
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
#include "duckdb/extension/core_functions/include/core_functions/aggregate/sum_helpers.hpp"
#include "duckdb/extension/core_functions/include/core_functions/aggregate/distributive_functions.hpp"

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
		state.value = 0;
		state.is_set = false;
		state.is_null = false;
	}

	static bool IgnoreNull() {
		return NA_RM;
	}

	template <class INPUT_TYPE, class STATE, class OP>
	static void Operation(STATE &state, const INPUT_TYPE &input, AggregateUnaryInput &unary_input) {
		if (state.is_null)
			return;
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
	static void ConstantOperation(STATE &state, const INPUT_TYPE &input, AggregateUnaryInput &unary_input,
	                              idx_t count) {
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
unique_ptr<FunctionData> BindRSum_dispatch(ClientContext &context, AggregateFunction &function,
                                           vector<unique_ptr<Expression>> &arguments) {
	auto type = arguments[0]->return_type;

	switch (type.id()) {
	case LogicalTypeId::DOUBLE:
		function = AggregateFunction::UnaryAggregate<RSumKeepNaState<double>, double, double,
		                                             RSumOperation<RegularAdd, NA_RM>>(type, type);
		break;
	case LogicalTypeId::INTEGER:
		function = AggregateFunction::UnaryAggregate<RSumKeepNaState<double>, int32_t, double,
		                                             RSumOperation<RegularAdd, NA_RM>>(type, LogicalTypeId::DOUBLE);
		break;
	case LogicalTypeId::BOOLEAN:
		function = AggregateFunction::UnaryAggregate<RSumKeepNaState<int32_t>, bool, int32_t,
		                                             RSumOperation<RegularAdd, NA_RM>>(type, LogicalType::INTEGER);
		break;
	default:
		break;
	}

	return nullptr;
}

unique_ptr<FunctionData> BindRSum(ClientContext &context, AggregateFunction &function,
                                  vector<unique_ptr<Expression>> &arguments) {
	auto na_rm = arguments[1]->ToString() == "true";
	if (na_rm) {
		return BindRSum_dispatch<true>(context, function, arguments);
	} else {
		return BindRSum_dispatch<false>(context, function, arguments);
	}
}

void add_RSum(AggregateFunctionSet &set, const LogicalType &type, const LogicalType &return_type) {
	set.AddFunction(AggregateFunction({type, LogicalType::BOOLEAN}, return_type, nullptr, nullptr, nullptr, nullptr,
	                                  nullptr, FunctionNullHandling::DEFAULT_NULL_HANDLING, nullptr, BindRSum));

	set.AddFunction(AggregateFunction({type}, return_type, nullptr, nullptr, nullptr, nullptr, nullptr,
	                                  FunctionNullHandling::DEFAULT_NULL_HANDLING, nullptr, BindRSum_dispatch<false>));
}

AggregateFunctionSet base_r_sum() {
	AggregateFunctionSet set("r_base::sum");

	add_RSum(set, LogicalType::BOOLEAN, LogicalType::INTEGER);
	add_RSum(set, LogicalType::INTEGER, LogicalType::DOUBLE);
	add_RSum(set, LogicalType::DOUBLE, LogicalType::DOUBLE);

	return set;
}

} // namespace rfuns
} // namespace duckdb
