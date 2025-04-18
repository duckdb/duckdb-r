#include "include/rapi.hpp"
#include <cpp11.hpp>

using namespace cpp11;

namespace duckdb {

// Helper functions to convert string to enum values
ConvertOpts::TzOutConvert string_to_tz_out_convert(const std::string &str) {
	if (str == "with")
		return ConvertOpts::TzOutConvert::WITH;
	if (str == "force")
		return ConvertOpts::TzOutConvert::FORCE;
	cpp11::stop("Invalid tz_out_convert value: %s", str.c_str());
}

ConvertOpts::BigIntType string_to_bigint_type(const std::string &str) {
	if (str == "numeric")
		return ConvertOpts::BigIntType::NUMERIC;
	if (str == "integer64")
		return ConvertOpts::BigIntType::INTEGER64;
	cpp11::stop("Invalid bigint value: %s", str.c_str());
}

ConvertOpts::ArrowConversion bool_to_arrow_conversion(bool use_arrow) {
	return use_arrow ? ConvertOpts::ArrowConversion::ENABLED : ConvertOpts::ArrowConversion::DISABLED;
}

ConvertOpts::ExperimentalFeatures bool_to_experimental_features(bool use_experimental) {
	return use_experimental ? ConvertOpts::ExperimentalFeatures::ENABLED : ConvertOpts::ExperimentalFeatures::DISABLED;
}

ConvertOpts::ConvertOpts(cpp11::list options) {
	// Extract timezone_out
	timezone_out = as_cpp<std::string>(options["timezone_out"]);

	// Extract tz_out_convert
	tz_out_convert = string_to_tz_out_convert(as_cpp<std::string>(options["tz_out_convert"]));

	// Extract bigint
	bigint = string_to_bigint_type(as_cpp<std::string>(options["bigint"]));

	// Extract arrow
	arrow = bool_to_arrow_conversion(as_cpp<bool>(options["arrow"]));

	// Extract experimental
	experimental = bool_to_experimental_features(as_cpp<bool>(options["experimental"]));
}

} // namespace duckdb
