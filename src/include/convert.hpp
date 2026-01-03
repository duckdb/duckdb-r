#pragma once

#include "cpp4r/list.hpp"
#include "duckdb/common/string.hpp"

namespace duckdb {

struct ConvertOpts {
	// Enums for the options
	enum class TzOutConvert { WITH, FORCE };

	enum class BigIntType { NUMERIC, INTEGER64 };

	enum class ArrayConversion { NONE, MATRIX };

	enum class ArrowConversion { DISABLED, ENABLED };

	enum class ExperimentalFeatures { DISABLED, ENABLED };

	enum class StrictRelational { DISABLED, ENABLED };

	// Default options
	string timezone_out = "UTC";
	TzOutConvert tz_out_convert = TzOutConvert::WITH;
	BigIntType bigint = BigIntType::NUMERIC;
	ArrayConversion array = ArrayConversion::NONE;
	ArrowConversion arrow = ArrowConversion::DISABLED;
	ExperimentalFeatures experimental = ExperimentalFeatures::DISABLED;
	StrictRelational strict_relational = StrictRelational::ENABLED;

	// Constructor with defaults
	ConvertOpts() = default;

	explicit ConvertOpts(cpp4r::sexp options_nullable);

	// Constructor with parameters
	ConvertOpts(std::string timezone_out_p, TzOutConvert tz_out_convert_p, BigIntType bigint_p, ArrayConversion array_p,
	            ArrowConversion arrow_p, ExperimentalFeatures experimental_p, StrictRelational strict_relational_p)
	    : timezone_out(std::move(timezone_out_p)), tz_out_convert(tz_out_convert_p), bigint(bigint_p), array(array_p),
	      arrow(arrow_p), experimental(experimental_p), strict_relational(strict_relational_p) {
	}
};

} // namespace duckdb
