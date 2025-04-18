#pragma once

#include "cpp11/list.hpp"
#include "duckdb/common/string.hpp"

namespace duckdb {

struct ConvertOpts {
	// Enums for the options
	enum class TzOutConvert { WITH, FORCE };

	enum class BigIntType { NUMERIC, INTEGER64 };

	enum class ArrowConversion { DISABLED, ENABLED };

	enum class ExperimentalFeatures { DISABLED, ENABLED };

	// Default options
	string timezone_out = "UTC";
	TzOutConvert tz_out_convert = TzOutConvert::WITH;
	BigIntType bigint = BigIntType::NUMERIC;
	ArrowConversion arrow = ArrowConversion::DISABLED;
	ExperimentalFeatures experimental = ExperimentalFeatures::DISABLED;

	// Constructor with defaults
	ConvertOpts() = default;

	explicit ConvertOpts(cpp11::list opts);

	// Constructor with parameters
	ConvertOpts(std::string timezone_out_p, TzOutConvert tz_out_convert_p, BigIntType bigint_p,
	            ArrowConversion arrow_p, ExperimentalFeatures experimental_p)
	    : timezone_out(std::move(timezone_out_p)), tz_out_convert(tz_out_convert_p), bigint(bigint_p), arrow(arrow_p),
	      experimental(experimental_p) {
	}
};

} // namespace duckdb
