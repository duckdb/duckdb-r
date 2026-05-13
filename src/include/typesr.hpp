#pragma once

namespace duckdb {

struct DuckDBAltrepStringWrapper {
	duckdb::unsafe_unique_array<string_t> string_data;
	duckdb::unsafe_unique_array<bool> mask_data;
	StringHeap heap;
	idx_t length;
};

struct DuckDBAltrepListEntryWrapper {
	DuckDBAltrepListEntryWrapper(idx_t max_length);
	void Reset(idx_t offset_p, idx_t length_p);
	idx_t length;
	duckdb::unsafe_unique_array<data_t> data;
};

enum class RTypeId {
	UNKNOWN,
	LOGICAL,
	INTEGER,
	NUMERIC,
	STRING,
	FACTOR,
	DATE,
	DATE_INTEGER,
	TIMESTAMP,
	INTERVAL_SECONDS,
	INTERVAL_MINUTES,
	INTERVAL_HOURS,
	INTERVAL_DAYS,
	INTERVAL_WEEKS,
	INTERVAL_SECONDS_INTEGER,
	INTERVAL_MINUTES_INTEGER,
	INTERVAL_HOURS_INTEGER,
	INTERVAL_DAYS_INTEGER,
	INTERVAL_WEEKS_INTEGER,
	INTEGER64,
	LIST_OF_NULLS,
	BLOB,

	// No RType equivalent
	BYTE,
	LIST,
	MATRIX,
	STRUCT,
};

struct RType {
	RType();
	RType(RTypeId id);               // NOLINT: Allow implicit conversion from `RTypeId`
	RType(RTypeId id, R_len_t size); // NOLINT: Allow implicit conversion from `RTypeId`
	RType(const RType &other);
	RType(RType &&other) noexcept;

	RTypeId id() const;

	// copy assignment
	inline RType &operator=(const RType &other) {
		id_ = other.id_;
		size_ = other.size_;
		aux_ = other.aux_;
		return *this;
	}
	// move assignment
	inline RType &operator=(RType &&other) noexcept {
		id_ = other.id_;
		size_ = other.size_;
		std::swap(aux_, other.aux_);
		return *this;
	}

	bool operator==(const RType &rhs) const;
	inline bool operator!=(const RType &rhs) const {
		return !(*this == rhs);
	}

	static constexpr const RTypeId UNKNOWN = RTypeId::UNKNOWN;
	static constexpr const RTypeId LOGICAL = RTypeId::LOGICAL;
	static constexpr const RTypeId INTEGER = RTypeId::INTEGER;
	static constexpr const RTypeId NUMERIC = RTypeId::NUMERIC;
	static constexpr const RTypeId STRING = RTypeId::STRING;
	static constexpr const RTypeId DATE = RTypeId::DATE;
	static constexpr const RTypeId DATE_INTEGER = RTypeId::DATE_INTEGER;
	static constexpr const RTypeId TIMESTAMP = RTypeId::TIMESTAMP;
	static constexpr const RTypeId INTERVAL_SECONDS = RTypeId::INTERVAL_SECONDS;
	static constexpr const RTypeId INTERVAL_MINUTES = RTypeId::INTERVAL_MINUTES;
	static constexpr const RTypeId INTERVAL_HOURS = RTypeId::INTERVAL_HOURS;
	static constexpr const RTypeId INTERVAL_DAYS = RTypeId::INTERVAL_DAYS;
	static constexpr const RTypeId INTERVAL_WEEKS = RTypeId::INTERVAL_WEEKS;
	static constexpr const RTypeId INTERVAL_SECONDS_INTEGER = RTypeId::INTERVAL_SECONDS_INTEGER;
	static constexpr const RTypeId INTERVAL_MINUTES_INTEGER = RTypeId::INTERVAL_MINUTES_INTEGER;
	static constexpr const RTypeId INTERVAL_HOURS_INTEGER = RTypeId::INTERVAL_HOURS_INTEGER;
	static constexpr const RTypeId INTERVAL_DAYS_INTEGER = RTypeId::INTERVAL_DAYS_INTEGER;
	static constexpr const RTypeId INTERVAL_WEEKS_INTEGER = RTypeId::INTERVAL_WEEKS_INTEGER;
	static constexpr const RTypeId INTEGER64 = RTypeId::INTEGER64;
	static constexpr const RTypeId LIST_OF_NULLS = RTypeId::LIST_OF_NULLS;
	static constexpr const RTypeId BLOB = RTypeId::BLOB;

	static RType FACTOR(cpp11::strings levels);
	Vector GetFactorLevels() const;
	size_t GetFactorLevelsCount() const;
	Value GetFactorValue(int r_value) const;

	static RType LIST(const RType &child);
	RType GetListChildType() const;

	static RType STRUCT(child_list_t<RType> &&children);
	child_list_t<RType> GetStructChildTypes() const;

	static RType MATRIX(const RType &child, R_len_t ncols);
	RType GetMatrixElementType() const;
	R_len_t GetMatrixNcols() const;

private:
	RTypeId id_;
	R_len_t size_;
	child_list_t<RType> aux_;
};

struct RApiTypes {
	static RType DetectRType(SEXP v, bool integer64);
	static LogicalType LogicalTypeFromRType(const RType &rtype, bool experimental);
	static string DetectLogicalType(const LogicalType &stype, const char *caller);
	static R_len_t GetVecSize(RType rtype, SEXP coldata);
	static R_len_t GetVecSize(SEXP coldata, bool integer64 = false);
	static Value SexpToValue(SEXP valsexp, R_len_t idx, bool typed_logical_null = true);
	static SEXP ValueToSexp(Value &val, string &timezone_config);
};

struct RIntegralType {
	template <class T>
	static double DoubleCast(T val) {
		return double(val);
	}
};

template <class T>
static void RDecimalCastLoop(const Vector &src_vec, size_t count, double *dest_ptr, uint8_t scale) {
	auto src_ptr = FlatVector::GetData<T>(src_vec);
	auto &mask = FlatVector::Validity(src_vec);
	double division = std::pow((uint64_t)10, (uint64_t)scale);
	for (size_t row_idx = 0; row_idx < count; row_idx++) {
		dest_ptr[row_idx] =
		    !mask.RowIsValid(row_idx) ? NA_REAL : RIntegralType::DoubleCast<T>(src_ptr[row_idx]) / division;
	}
}

template <>
double RIntegralType::DoubleCast<>(hugeint_t val);

struct RDoubleType {
	static bool IsNull(double val);
	static double Convert(double val);
};

struct RDateType : public RDoubleType {
	static date_t Convert(double val);
};

struct RTimestampType : public RDoubleType {
	static timestamp_t Convert(double val);
};

struct RIntervalSecondsType : public RDoubleType {
	static interval_t Convert(double val);
};

struct RIntervalMinutesType : public RDoubleType {
	static interval_t Convert(double val);
};

struct RIntervalHoursType : public RDoubleType {
	static interval_t Convert(double val);
};

struct RIntervalDaysType : public RDoubleType {
	static interval_t Convert(double val);
};

struct RIntervalWeeksType : public RDoubleType {
	static interval_t Convert(double val);
};

struct RIntegerType {
	static bool IsNull(int val);
	static int Convert(int val);
};

struct RInteger64Type {
	static bool IsNull(int64_t val);
	static int64_t Convert(int64_t val);
};

struct RFactorType : public RIntegerType {
	static int Convert(int val);
};

struct RBooleanType : public RIntegerType {
	static bool Convert(int val);
};

struct RStringSexpType {
	static string_t Convert(SEXP val);
	static bool IsNull(SEXP val);
};

struct RSexpType {
	static bool IsNull(SEXP val);
};

struct RRawSexpType : public RSexpType {
	static string_t Convert(SEXP val);
};

} // namespace duckdb

duckdb::case_insensitive_map_t<duckdb::vector<duckdb::Value>> ListToVectorOfValue(cpp11::list input_sexps);
