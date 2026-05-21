#pragma once

#include "duckdb.hpp"

namespace duckdb {
namespace rfuns {

template <LogicalTypeId LOGICAL_TYPE>
struct physical;

template <>
struct physical<LogicalType::BOOLEAN> {
	using type = bool;
};
template <>
struct physical<LogicalType::INTEGER> {
	using type = int32_t;
};
template <>
struct physical<LogicalType::DOUBLE> {
	using type = double;
};
template <>
struct physical<LogicalType::VARCHAR> {
	using type = string_t;
};
template <>
struct physical<LogicalType::TIMESTAMP> {
	using type = timestamp_t;
};
template <>
struct physical<LogicalType::DATE> {
	using type = date_t;
};

struct BinaryChunk {
	duckdb::Vector &lefts;
	duckdb::Vector &rights;
};

template <LogicalTypeId LHS_LOGICAL_TYPE, LogicalTypeId RHS_LOGICAL_TYPE>
BinaryChunk BinaryTypeAssert(DataChunk &args) {
	auto &lefts = args.data[0];
	D_ASSERT(lefts.GetType() == LHS_LOGICAL_TYPE);

	auto &rights = args.data[1];
	D_ASSERT(rights.GetType() == LHS_LOGICAL_TYPE);

	return {lefts, rights};
}

ScalarFunctionSet base_r_add();

// relop
ScalarFunctionSet base_r_eq();
ScalarFunctionSet base_r_neq();
ScalarFunctionSet base_r_lt();
ScalarFunctionSet base_r_lte();
ScalarFunctionSet base_r_gt();
ScalarFunctionSet base_r_gte();

ScalarFunctionSet base_r_is_na();
ScalarFunctionSet base_r_as_integer();
ScalarFunctionSet base_r_as_numeric();

ScalarFunctionSet base_r_in();

// aggregates
AggregateFunctionSet base_r_sum();
AggregateFunctionSet base_r_min();
AggregateFunctionSet base_r_max();

ScalarFunctionSet binary_dispatch(ScalarFunctionSet fn);

} // namespace rfuns

class RfunsExtension : public Extension {
public:
	void Load(ExtensionLoader &db) override;
	std::string Name() override;
};

} // namespace duckdb
