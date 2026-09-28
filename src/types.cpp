#include "duckdb/common/types/date.hpp"
#include "duckdb/common/types/hugeint.hpp"
#include "duckdb/common/types/interval.hpp"
#include "duckdb/common/types/timestamp.hpp"
#include "duckdb/common/types/uhugeint.hpp"

#include <cmath>
#include <sstream>

#include "rapi.hpp"
#include "typesr.hpp"

// Avoid clash with TRUE and FALSE macros in older rtools
#undef TRUE
#undef FALSE

using namespace duckdb;

RType::RType() : id_(RTypeId::UNKNOWN), size_(0) {
}

RType::RType(RTypeId id) : id_(id), size_(0) {
}

RType::RType(RTypeId id, R_len_t size) : id_(id), size_(size) {
}

RType::RType(const RType &other) : id_(other.id_), size_(other.size_), aux_(other.aux_), period_(other.period_) {
}

RType::RType(RType &&other) noexcept
    : id_(other.id_), size_(other.size_), aux_(std::move(other.aux_)), period_(std::move(other.period_)) {
}

RTypeId RType::id() const {
	return id_;
}

bool RType::operator==(const RType &rhs) const {
	return id_ == rhs.id_ && size_ == rhs.size_ && aux_ == rhs.aux_;
}

// Reads the levels in place, as DetectRType() does a data frame's names
RType RType::FACTOR(SEXP levels) {
	D_ASSERT(TYPEOF(levels) == STRSXP);
	RType out = RType(RTypeId::FACTOR);
	for (R_xlen_t level_idx = 0; level_idx < Rf_xlength(levels); level_idx++) {
		out.aux_.push_back(std::make_pair(Rf_translateCharUTF8(STRING_ELT(levels, level_idx)), RType()));
	}
	return out;
}

Vector RType::GetFactorLevels() const {
	D_ASSERT(id_ == RTypeId::FACTOR);
	Vector duckdb_levels(LogicalType::VARCHAR, aux_.size());
	auto levels_ptr = FlatVector::GetData<string_t>(duckdb_levels);
	for (size_t level_idx = 0; level_idx < aux_.size(); level_idx++) {
		levels_ptr[level_idx] = StringVector::AddString(duckdb_levels, aux_[level_idx].first);
	}
	return duckdb_levels;
}

size_t RType::GetFactorLevelsCount() const {
	D_ASSERT(id_ == RTypeId::FACTOR);
	return aux_.size();
}

Value RType::GetFactorValue(int r_value) const {
	D_ASSERT(id_ == RTypeId::FACTOR);
	bool is_null = RIntegerType::IsNull(r_value);
	if (!is_null) {
		auto str_val = aux_[r_value - 1].first;
		return Value(str_val);
	} else {
		return Value(LogicalType::VARCHAR);
	}
}

RType RType::LIST(const RType &child) {
	RType out = RType(RTypeId::LIST);
	out.aux_.push_back(std::make_pair("", child));
	return out;
}

RType RType::GetListChildType() const {
	D_ASSERT(id_ == RTypeId::LIST);
	return aux_.front().second;
}

RType RType::PERIOD(SEXP period) {
	RType out = RType(RTypeId::INTERVAL_PERIOD);
	out.period_ = make_shared_ptr<RPeriodType>(period);
	return out;
}

const RPeriodType &RType::GetPeriod() const {
	D_ASSERT(id_ == RTypeId::INTERVAL_PERIOD && period_);
	return *period_;
}

RType RType::MATRIX(const RType &child, R_len_t ncols) {
	RType out = RType(RTypeId::MATRIX, ncols);
	out.aux_.push_back(std::make_pair("", child));
	return out;
}

RType RType::GetMatrixElementType() const {
	D_ASSERT(id_ == RTypeId::MATRIX);
	return aux_.front().second;
}

R_len_t RType::GetMatrixNcols() const {
	D_ASSERT(id_ == RTypeId::MATRIX);
	return size_;
}

RType RType::STRUCT(child_list_t<RType> &&children) {
	RType out = RType(RTypeId::STRUCT);
	std::swap(out.aux_, children);
	return out;
}

child_list_t<RType> RType::GetStructChildTypes() const {
	D_ASSERT(id_ == RTypeId::STRUCT);
	return aux_;
}

// A data frame's names, read in place, or R_NilValue unless they are one string per column
static SEXP DataFrameNames(SEXP df) {
	SEXP names = GET_NAMES(df);
	return TYPEOF(names) == STRSXP && Rf_xlength(names) == Rf_xlength(df) ? names : R_NilValue;
}

RType RApiTypes::DetectRType(SEXP v, bool integer64, bool hms_time, bool period_interval) {
	if (period_interval && (TYPEOF(v) == REALSXP || TYPEOF(v) == INTSXP) && Rf_isS4(v) && Rf_inherits(v, "Period")) {
		return RType::PERIOD(v);
	}
	if (TYPEOF(v) == REALSXP && Rf_inherits(v, "POSIXct")) {
		return RType::TIMESTAMP;
	} else if (TYPEOF(v) == REALSXP && Rf_inherits(v, "Date")) {
		return RType::DATE;
	} else if (TYPEOF(v) == INTSXP && Rf_inherits(v, "Date")) {
		return RType::DATE_INTEGER;
	} else if (TYPEOF(v) == REALSXP && Rf_inherits(v, "difftime")) {
		SEXP units = Rf_getAttrib(v, RStrings::get().units_sym);
		if (TYPEOF(units) != STRSXP) {
			return RType::UNKNOWN;
		}
		SEXP units0 = STRING_ELT(units, 0);
		if (units0 == RStrings::get().secs) {
			if (hms_time && Rf_inherits(v, "hms")) {
				return RType::TIME;
			}
			return RType::INTERVAL_SECONDS;
		} else if (units0 == RStrings::get().mins) {
			return RType::INTERVAL_MINUTES;
		} else if (units0 == RStrings::get().hours) {
			return RType::INTERVAL_HOURS;
		} else if (units0 == RStrings::get().days) {
			return RType::INTERVAL_DAYS;
		} else if (units0 == RStrings::get().weeks) {
			return RType::INTERVAL_WEEKS;
		} else {
			return RType::UNKNOWN;
		}
	} else if (TYPEOF(v) == INTSXP && Rf_inherits(v, "difftime")) {
		SEXP units = Rf_getAttrib(v, RStrings::get().units_sym);
		if (TYPEOF(units) != STRSXP) {
			return RType::UNKNOWN;
		}
		SEXP units0 = STRING_ELT(units, 0);
		if (units0 == RStrings::get().secs) {
			return RType::INTERVAL_SECONDS_INTEGER;
		} else if (units0 == RStrings::get().mins) {
			return RType::INTERVAL_MINUTES_INTEGER;
		} else if (units0 == RStrings::get().hours) {
			return RType::INTERVAL_HOURS_INTEGER;
		} else if (units0 == RStrings::get().days) {
			return RType::INTERVAL_DAYS_INTEGER;
		} else if (units0 == RStrings::get().weeks) {
			return RType::INTERVAL_WEEKS_INTEGER;
		} else {
			return RType::UNKNOWN;
		}
	} else if (Rf_isFactor(v) && TYPEOF(v) == INTSXP) {
		SEXP levels = GET_LEVELS(v);
		if (TYPEOF(levels) != STRSXP) {
			return RType::UNKNOWN;
		}
		return RType::FACTOR(levels);
	} else if (Rf_isMatrix(v)) {
		if (TYPEOF(v) == LGLSXP) {
			return RType::MATRIX(RType::LOGICAL, Rf_ncols(v));
		} else if (TYPEOF(v) == INTSXP) {
			return RType::MATRIX(RType::INTEGER, Rf_ncols(v));
		} else if (TYPEOF(v) == REALSXP) {
			if (integer64 && Rf_inherits(v, "integer64")) {
				return RType::MATRIX(RType::INTEGER64, Rf_ncols(v));
			}
			return RType::MATRIX(RType::NUMERIC, Rf_ncols(v));
		} else if (TYPEOF(v) == STRSXP) {
			return RType::MATRIX(RType::STRING, Rf_ncols(v));
		} else {
			return RType::UNKNOWN;
		}
	} else if (TYPEOF(v) == LGLSXP) {
		return RType::LOGICAL;
	} else if (TYPEOF(v) == INTSXP) {
		return RType::INTEGER;
	} else if (TYPEOF(v) == RAWSXP) {
		return RTypeId::BYTE;
	} else if (TYPEOF(v) == REALSXP) {
		if (integer64 && Rf_inherits(v, "integer64")) {
			return RType::INTEGER64;
		}
		return RType::NUMERIC;
	} else if (TYPEOF(v) == STRSXP) {
		return RType::STRING;
	} else if (TYPEOF(v) == VECSXP) {
		if (Rf_inherits(v, "blob")) {
			return RType::BLOB;
		}

		if (Rf_inherits(v, "data.frame")) {
			child_list_t<RType> child_types;
			R_xlen_t ncol = Rf_length(v);

			// Read in place: the scan detects a list cell's type on a task thread,
			// where no cpp11 vector may be built (handbook/architecture/glue/threading/)
			SEXP names = DataFrameNames(v);
			if (names == R_NilValue) {
				return RType::UNKNOWN;
			}
			for (R_xlen_t i = 0; i < ncol; ++i) {
				RType child = DetectRType(VECTOR_ELT(v, i), integer64, hms_time, period_interval);
				if (child == RType::UNKNOWN) {
					return (RType::UNKNOWN);
				}

				child_types.push_back(std::make_pair(CHAR(STRING_ELT(names, i)), child));
			}

			return RType::STRUCT(std::move(child_types));
		} else {
			// A list cell leaves `hms_time` behind: the scan converts it with SexpToValue(), which does not see it,
			// so an hms in a list writes INTERVAL (handbook/usage/types/README.md).
			R_xlen_t len = Rf_xlength(v);
			R_xlen_t i = 0;
			auto type = RType();
			for (; i < len; ++i) {
				auto elt = VECTOR_ELT(v, i);
				if (elt != R_NilValue) {
					type = DetectRType(elt, integer64);
					break;
				}
			}

			if (i == len) {
				return RType::LIST_OF_NULLS;
			}

			for (; i < len; ++i) {
				auto elt = VECTOR_ELT(v, i);
				if (elt != R_NilValue) {
					auto new_type = DetectRType(elt, integer64);
					if (new_type != type) {
						return RType::UNKNOWN;
					}
				}
			}

			if (type == RTypeId::BYTE) {
				return RType::BLOB;
			}

			return RType::LIST(type);
		}
	}
	return RType::UNKNOWN;
}

LogicalType RApiTypes::LogicalTypeFromRType(const RType &rtype, bool experimental) {
	switch (rtype.id()) {
	case RType::LOGICAL:
		return LogicalType::BOOLEAN;
	case RType::INTEGER:
		return LogicalType::INTEGER;
	case RType::NUMERIC:
		return LogicalType::DOUBLE;
	case RType::INTEGER64:
		return LogicalType::BIGINT;
	case RTypeId::FACTOR: {
		auto duckdb_levels = rtype.GetFactorLevels();
		return LogicalType::ENUM(duckdb_levels, rtype.GetFactorLevelsCount());
	}
	case RType::STRING:
		if (experimental) {
			return RStringsType::Get();
		} else {
			return LogicalType::VARCHAR;
		}
		break;
	case RType::TIMESTAMP:
		return LogicalType::TIMESTAMP;
	case RType::TIME:
		return LogicalType::TIME;
	case RType::INTERVAL_SECONDS:
	case RType::INTERVAL_MINUTES:
	case RType::INTERVAL_HOURS:
	case RType::INTERVAL_DAYS:
	case RType::INTERVAL_WEEKS:
	case RType::INTERVAL_SECONDS_INTEGER:
	case RType::INTERVAL_MINUTES_INTEGER:
	case RType::INTERVAL_HOURS_INTEGER:
	case RType::INTERVAL_DAYS_INTEGER:
	case RType::INTERVAL_WEEKS_INTEGER:
	case RType::INTERVAL_PERIOD:
		return LogicalType::INTERVAL;
	case RType::DATE:
		return LogicalType::DATE;
	case RType::DATE_INTEGER:
		return LogicalType::DATE;
	case RType::LIST_OF_NULLS:
	case RType::BLOB:
		return LogicalType::BLOB;
	case RTypeId::LIST:
		return LogicalType::LIST(RApiTypes::LogicalTypeFromRType(rtype.GetListChildType(), experimental));
	case RTypeId::MATRIX:
		return LogicalType::ARRAY(RApiTypes::LogicalTypeFromRType(rtype.GetMatrixElementType(), experimental),
		                          rtype.GetMatrixNcols());
	case RTypeId::STRUCT: {
		child_list_t<LogicalType> children;
		for (const auto &child : rtype.GetStructChildTypes()) {
			children.push_back(
			    std::make_pair(child.first, RApiTypes::LogicalTypeFromRType(child.second, experimental)));
		}
		if (children.size() == 0) {
			rapi_error_with_context("SexpToLogicalType", "Packed column must have at least one column");
		}
		return LogicalType::STRUCT(std::move(children));
	}

	default:
		rapi_error_with_context("SexpToLogicalType", "Can't convert R type to logical type");
	}
}

string RApiTypes::DetectLogicalType(const LogicalType &stype, const char *caller) {

	if (stype.GetAlias() == R_STRING_TYPE_NAME) {
		return "character";
	}

	switch (stype.id()) {
	case LogicalTypeId::BOOLEAN:
		return "logical";
	case LogicalTypeId::UTINYINT:
	case LogicalTypeId::TINYINT:
	case LogicalTypeId::USMALLINT:
	case LogicalTypeId::SMALLINT:
	case LogicalTypeId::INTEGER:
		return "integer";
	case LogicalTypeId::TIMESTAMP_SEC:
	case LogicalTypeId::TIMESTAMP_MS:
	case LogicalTypeId::TIMESTAMP:
	case LogicalTypeId::TIMESTAMP_TZ:
	case LogicalTypeId::TIMESTAMP_NS:
		return "POSIXct";
	case LogicalTypeId::DATE:
		return "Date";
	case LogicalTypeId::TIME:
	case LogicalTypeId::TIME_NS:
	case LogicalTypeId::TIME_TZ:
	case LogicalTypeId::INTERVAL:
		return "difftime";
	case LogicalTypeId::UINTEGER:
	case LogicalTypeId::BIGINT:
	case LogicalTypeId::UBIGINT:
	case LogicalTypeId::HUGEINT:
	case LogicalTypeId::UHUGEINT:
	case LogicalTypeId::FLOAT:
	case LogicalTypeId::DOUBLE:
	case LogicalTypeId::DECIMAL:
		return "numeric";
	case LogicalTypeId::VARCHAR:
	case LogicalTypeId::UUID:
		return "character";
	case LogicalTypeId::BLOB:
	case LogicalTypeId::GEOMETRY:
		return "raw";
	case LogicalTypeId::LIST:
	case LogicalTypeId::VARIANT:
		return "list";
	case LogicalTypeId::ARRAY:
		return "matrix";
	case LogicalTypeId::STRUCT:
	case LogicalTypeId::MAP:
		return "data.frame";
	case LogicalTypeId::ENUM:
		return "factor";
	case LogicalTypeId::UNKNOWN:
	case LogicalTypeId::SQLNULL:
	// No R vector holds these: the route to R vectors refuses them by column before
	// the statement runs, in rapi_execute_impl(), while an Arrow result carries them
	// unconverted (handbook/usage/types/README.md).
	case LogicalTypeId::BIT:
	case LogicalTypeId::BIGNUM:
	case LogicalTypeId::UNION:
		return "unknown";

	default: {
		std::string error_msg = "Unknown column type for prepare: " + stype.ToString();
		rapi_error_with_context(caller, error_msg);
		break;
	}
	}
}

bool RDoubleType::IsNull(double val) {
	return ISNA(val);
}

double RDoubleType::Convert(double val) {
	return val;
}

date_t RDateType::Convert(double val) {
	return date_t((int32_t)std::floor(val));
}

timestamp_t RTimestampType::Convert(double val) {
	return Timestamp::FromEpochMicroSeconds(round(val * Interval::MICROS_PER_SEC));
}

// TIME holds 00:00:00 to 24:00:00, to the microsecond, and an hms is rounded to that.
// NaN and the infinities compare false, so they are not valid either.
bool RTimeType::IsValid(double val) {
	auto micros = round(val * Interval::MICROS_PER_SEC);
	return micros >= 0 && micros <= double(Interval::MICROS_PER_DAY);
}

// Checked before the scan or the bind, where the error can name the column (FindInvalidValue());
// what gets here anyway is refused without calling R, since the scan runs on a task thread.
dtime_t RTimeType::Convert(double val) {
	if (!IsValid(val)) {
		throw InvalidInputException("An hms of %s seconds is not a time of day `TIME` can hold", std::to_string(val));
	}
	return dtime_t(int64_t(round(val * Interval::MICROS_PER_SEC)));
}

// A number for an error message, spelled as R prints it
static string FormatRNumber(double val) {
	if (std::isnan(val)) {
		return ISNA(val) ? "NA" : "NaN";
	}
	if (std::isinf(val)) {
		return val > 0 ? "Inf" : "-Inf";
	}
	std::ostringstream out;
	out.precision(15);
	out << val;
	return out.str();
}

RPeriodType::Part RPeriodType::ReadPart(SEXP part, R_xlen_t length) {
	Part result;
	if (Rf_xlength(part) != length) {
		return result;
	}
	if (TYPEOF(part) == REALSXP) {
		result.real = REAL_RO(part);
	} else if (TYPEOF(part) == INTSXP) {
		result.integer = INTEGER_RO(part);
	}
	return result;
}

bool RPeriodType::Part::IsRead() const {
	return real || integer;
}

double RPeriodType::Part::Get(R_xlen_t idx) const {
	if (real) {
		return real[idx];
	}
	return integer[idx] == NA_INTEGER ? NA_REAL : double(integer[idx]);
}

RPeriodType::RPeriodType(SEXP period) : length(Rf_xlength(period)), seconds(ReadPart(period, length)) {
	const auto &slot_syms = RStrings::get().period_slot_syms;
	for (idx_t slot_idx = 0; slot_idx < 5; slot_idx++) {
		slots[slot_idx] = ReadPart(Rf_getAttrib(period, slot_syms[slot_idx]), length);
	}
}

double RPeriodType::Seconds(R_xlen_t idx) const {
	return seconds.Get(idx);
}

double RPeriodType::Slot(idx_t slot_idx, R_xlen_t idx) const {
	return slots[slot_idx].Get(idx);
}

bool RPeriodType::IsMalformed() const {
	if (!seconds.IsRead()) {
		return true;
	}
	for (auto &slot : slots) {
		if (!slot.IsRead()) {
			return true;
		}
	}
	return false;
}

// NA or NaN in any part makes the whole Period NULL,
// where lubridate's is.na() looks at the seconds alone and its constructors put NA in every part at once
bool RPeriodType::IsNull(R_xlen_t idx) const {
	if (seconds.IsRead() && ISNAN(seconds.Get(idx))) {
		return true;
	}
	for (auto &slot : slots) {
		if (slot.IsRead() && ISNAN(slot.Get(idx))) {
			return true;
		}
	}
	return false;
}

static bool IsWholeWithin(double val, double min, double max) {
	return std::isfinite(val) && val == std::floor(val) && val >= min && val <= max;
}

static bool AddWithin(int64_t left, int64_t right, int64_t &result) {
	if ((right > 0 && left > NumericLimits<int64_t>::Maximum() - right) ||
	    (right < 0 && left < NumericLimits<int64_t>::Minimum() - right)) {
		return false;
	}
	result = left + right;
	return true;
}

// The largest int64 is not a double, and the double just past it is 2^63
static const double INT64_BELOW = -9223372036854775808.0;
static const double INT64_ABOVE = std::nextafter(9223372036854775808.0, 0.0);

// The microseconds of a Period, combined in 64-bit integers from its hours, minutes, whole seconds
// and the fraction of a second left over, which alone is rounded to the microsecond.
// The parts a read split off come back exactly,
// and a double of seconds below 2^33, some 272 years, holds each microsecond, which rounding it whole would not.
bool RPeriodType::Micros(R_xlen_t idx, int64_t &micros) const {
	auto hours = Slot(3, idx);
	auto minutes = Slot(4, idx);
	auto whole_seconds = std::trunc(Seconds(idx));
	if (!IsWholeWithin(hours, INT64_BELOW / Interval::MICROS_PER_HOUR, INT64_ABOVE / Interval::MICROS_PER_HOUR) ||
	    !IsWholeWithin(minutes, INT64_BELOW / Interval::MICROS_PER_MINUTE, INT64_ABOVE / Interval::MICROS_PER_MINUTE) ||
	    !IsWholeWithin(whole_seconds, INT64_BELOW / Interval::MICROS_PER_SEC, INT64_ABOVE / Interval::MICROS_PER_SEC)) {
		return false;
	}
	// Taking off the whole part is exact (Sterbenz), so only this product rounds
	auto fraction_micros = int64_t(std::round((Seconds(idx) - whole_seconds) * Interval::MICROS_PER_SEC));
	int64_t partial;
	return AddWithin(int64_t(hours) * Interval::MICROS_PER_HOUR, int64_t(minutes) * Interval::MICROS_PER_MINUTE,
	                 partial) &&
	       AddWithin(partial, int64_t(whole_seconds) * Interval::MICROS_PER_SEC, partial) &&
	       AddWithin(partial, fraction_micros, micros);
}

bool RPeriodType::IsValid(R_xlen_t idx) const {
	if (IsMalformed()) {
		return false;
	}
	for (idx_t slot_idx = 0; slot_idx < 5; slot_idx++) {
		if (!std::isfinite(Slot(slot_idx, idx))) {
			return false;
		}
	}
	int64_t micros;
	auto months = Slot(0, idx) * 12 + Slot(1, idx);
	return IsWholeWithin(months, NumericLimits<int32_t>::Minimum(), NumericLimits<int32_t>::Maximum()) &&
	       IsWholeWithin(Slot(2, idx), NumericLimits<int32_t>::Minimum(), NumericLimits<int32_t>::Maximum()) &&
	       Micros(idx, micros);
}

interval_t RPeriodType::Convert(R_xlen_t idx) const {
	interval_t result;
	if (!IsValid(idx) || !Micros(idx, result.micros)) {
		throw InvalidInputException("A Period of %s does not fit an `INTERVAL`", Format(idx));
	}
	result.months = int32_t(Slot(0, idx) * 12 + Slot(1, idx));
	result.days = int32_t(Slot(2, idx));
	return result;
}

// Spelled as lubridate prints a Period
string RPeriodType::Format(R_xlen_t idx) const {
	if (IsMalformed()) {
		return "a malformed Period";
	}
	return FormatRNumber(Slot(0, idx)) + "y " + FormatRNumber(Slot(1, idx)) + "m " + FormatRNumber(Slot(2, idx)) +
	       "d " + FormatRNumber(Slot(3, idx)) + "H " + FormatRNumber(Slot(4, idx)) + "M " +
	       FormatRNumber(Seconds(idx)) + "S";
}

// Whether a Period has parts other than its seconds, which a DOUBLE of its seconds would drop;
// a part that could not be read counts, so that the write is refused rather than lossy
bool RPeriodType::HasOtherParts(R_xlen_t idx) const {
	for (auto &slot : slots) {
		if (!slot.IsRead() || slot.Get(idx) != 0) {
			return true;
		}
	}
	return false;
}

namespace {

// Where FindInvalidValue() is looking: a column or parameter, or a field or element under one,
// spelled out only for an error, so that a search finding nothing builds no string
struct ValuePath {
	const string &root;
	const ValuePath *parent;
	// The names of the data frame this is a field of, or R_NilValue for an element of a list
	SEXP names;
	R_xlen_t index;

	string ToString() const {
		if (!parent) {
			return root;
		}
		if (names != R_NilValue) {
			return parent->ToString() + "$" + CHAR(STRING_ELT(names, index));
		}
		return parent->ToString() + "[[" + std::to_string(index + 1) + "]]";
	}
};

} // namespace

// Whether a value is one FindInvalidValue() looks into or at: a list, a Period, or under `time = "hms"` a double
static bool MayHoldInvalidValue(SEXP v, bool hms_time) {
	switch (TYPEOF(v)) {
	case VECSXP:
		return true;
	case REALSXP:
		return hms_time || Rf_isS4(v);
	case INTSXP:
		return Rf_isS4(v);
	default:
		return false;
	}
}

static string FindInvalidValueAt(SEXP v, const ValuePath &path, bool hms_time, bool period_interval, bool in_list) {
	if (TYPEOF(v) == VECSXP) {
		auto is_df = Rf_inherits(v, "data.frame");
		SEXP names = is_df ? DataFrameNames(v) : R_NilValue;
		if (is_df && names == R_NilValue) {
			// Not a data frame DetectRType() takes, which refuses it
			return "";
		}
		// A field keeps the options, where an element of a list leaves them behind
		auto child_hms_time = is_df && hms_time;
		auto child_period_interval = is_df && period_interval;
		auto child_in_list = !is_df || in_list;
		for (R_xlen_t i = 0; i < Rf_xlength(v); i++) {
			SEXP child = VECTOR_ELT(v, i);
			if (!MayHoldInvalidValue(child, child_hms_time)) {
				continue;
			}
			auto invalid = FindInvalidValueAt(child, ValuePath {path.root, &path, names, i}, child_hms_time,
			                                  child_period_interval, child_in_list);
			if (!invalid.empty()) {
				return invalid;
			}
		}
		return "";
	}
	if (!MayHoldInvalidValue(v, hms_time)) {
		return "";
	}
	auto position = [&](R_xlen_t i) {
		return (in_list ? " (element " : " (row ") + std::to_string(i + 1) + ").";
	};
	if (Rf_isS4(v) && Rf_inherits(v, "Period")) {
		RPeriodType period(v);
		for (R_xlen_t i = 0; i < period.length; i++) {
			// Written as an INTERVAL, NA in any part is NULL; written as a DOUBLE, only NA seconds are,
			// and a missing other part is one the DOUBLE would drop
			if (period_interval ? period.IsNull(i) : ISNAN(period.Seconds(i))) {
				continue;
			}
			if (period_interval && !period.IsValid(i)) {
				return "`" + path.ToString() + "` must hold periods that fit an `INTERVAL`, not " + period.Format(i) +
				       position(i);
			}
			if (!period_interval && period.HasOtherParts(i)) {
				return "`" + path.ToString() + "` must hold periods of seconds alone to write a `DOUBLE`, not " +
				       period.Format(i) + position(i) +
				       (in_list ? " In a list, a `Period` writes a `DOUBLE` whatever `interval` says, "
				                  "so use `lubridate::period_to_seconds()` for a `DOUBLE` of the total."
				                : " Use `dbConnect(interval = \"Period\")` to write an exact `INTERVAL`, "
				                  "or `lubridate::period_to_seconds()` for a `DOUBLE` of the total.");
			}
		}
		return "";
	}
	if (!hms_time || RApiTypes::DetectRType(v, true, true).id() != RTypeId::TIME) {
		return "";
	}
	auto data = NUMERIC_POINTER(v);
	for (R_xlen_t i = 0; i < Rf_xlength(v); i++) {
		if (!RTimeType::IsNull(data[i]) && !RTimeType::IsValid(data[i])) {
			return "`" + path.ToString() + "` must hold times of day from 00:00:00 to 24:00:00 to write `TIME`, not " +
			       FormatRNumber(data[i]) + " seconds" + position(i);
		}
	}
	return "";
}

// The first value the write routes would refuse, described for an error; empty when there is none.
// Under `time = "hms"`, an hms that TIME cannot hold; under `interval = "Period"`, a Period that INTERVAL cannot hold;
// otherwise, a Period with parts other than its seconds, which would write a DOUBLE of its seconds alone.
// It searches the fields of a data frame and the cells of a list, which the options do not reach:
// there an hms writes INTERVAL and a Period a DOUBLE of its seconds, as without them.
// It reads only what it checks, and names where it looks only once it finds something,
// so that a column or a cell of another type costs a type test.
string RApiTypes::FindInvalidValue(SEXP v, const string &path, bool hms_time, bool period_interval, bool in_list) {
	return FindInvalidValueAt(v, ValuePath {path, nullptr, R_NilValue, 0}, hms_time, period_interval, in_list);
}

interval_t RIntervalSecondsType::Convert(double val) {
	return Interval::FromMicro(int64_t(round(val * Interval::MICROS_PER_SEC)));
}

interval_t RIntervalMinutesType::Convert(double val) {
	return Interval::FromMicro(int64_t(round(val * Interval::MICROS_PER_MINUTE)));
}

interval_t RIntervalHoursType::Convert(double val) {
	return Interval::FromMicro(int64_t(round(val * Interval::MICROS_PER_HOUR)));
}

interval_t RIntervalDaysType::Convert(double val) {
	return Interval::FromMicro(int64_t(round(val * Interval::MICROS_PER_DAY)));
}

interval_t RIntervalWeeksType::Convert(double val) {
	return Interval::FromMicro(int64_t(round(val * (Interval::MICROS_PER_DAY * Interval::DAYS_PER_WEEK))));
}

bool RIntegerType::IsNull(int val) {
	return val == NA_INTEGER;
}

int RIntegerType::Convert(int val) {
	return val;
}

bool RInteger64Type::IsNull(int64_t val) {
	return val == NumericLimits<int64_t>::Minimum();
}

int64_t RInteger64Type::Convert(int64_t val) {
	return val;
}

int RFactorType::Convert(int val) {
	return val - 1;
}

bool RBooleanType::Convert(int val) {
	return val;
}

template <>
double RIntegralType::DoubleCast<>(hugeint_t val) {
	return Hugeint::Cast<double>(val);
}

string_t RStringSexpType::Convert(SEXP val) {
	return string_t(CHAR(val));
}

bool RStringSexpType::IsNull(SEXP val) {
	return val == NA_STRING;
}

bool RSexpType::IsNull(SEXP val) {
	return val == R_NilValue;
}

string_t RRawSexpType::Convert(SEXP val) {
	return string_t((char *)RAW(val), Rf_xlength(val));
}
