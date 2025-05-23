#include "duckdb/common/types/timestamp.hpp"
#include "rapi.hpp"
#include "typesr.hpp"
#include "duckdb/common/adbc/adbc-init.hpp"
#include "include/rfuns_extension.hpp"

using namespace duckdb;

[[cpp11::register]] SEXP rapi_adbc_init_func() {
	return R_MakeExternalPtrFn((DL_FUNC)duckdb_adbc_init, R_NilValue, R_NilValue);
}

SEXP duckdb::ToUtf8(SEXP string_sexp) {
	cpp11::function enc2utf8 = RStrings::get().enc2utf8_sym;
	return enc2utf8(string_sexp);
}

[[cpp11::register]] cpp11::r_string rapi_ptr_to_str(SEXP extptr) {
	if (TYPEOF(extptr) != EXTPTRSXP) {
		cpp11::stop("rapi_ptr_to_str: Need external pointer parameter");
	}

	void *ptr = R_ExternalPtrAddr(extptr);
	if (ptr != NULL) {
		char buf[100];
		snprintf(buf, 100, "%p", ptr);
		return cpp11::r_string(buf);
	} else {
		return cpp11::r_string(NA_STRING);
	}
}

static SEXP cstr_to_charsexp(const char *s) {
	return Rf_mkCharCE(s, CE_UTF8);
}

static SEXP cpp_str_to_charsexp(string s) {
	return cstr_to_charsexp(s.c_str());
}

cpp11::strings duckdb::StringsToSexp(vector<string> s) {
	cpp11::writable::strings retsexp(s.size());
	for (idx_t i = 0; i < s.size(); i++) {
		SET_STRING_ELT(retsexp, i, cpp_str_to_charsexp(s[i]));
	}
	return retsexp;
}

RStrings::RStrings() {
	// allocate strings once
	cpp11::sexp strings = Rf_allocVector(STRSXP, 5);
	SET_STRING_ELT(strings, 0, secs = Rf_mkChar("secs"));
	SET_STRING_ELT(strings, 1, mins = Rf_mkChar("mins"));
	SET_STRING_ELT(strings, 2, hours = Rf_mkChar("hours"));
	SET_STRING_ELT(strings, 3, days = Rf_mkChar("days"));
	SET_STRING_ELT(strings, 4, weeks = Rf_mkChar("weeks"));
	R_PreserveObject(strings);
	MARK_NOT_MUTABLE(strings);

	cpp11::sexp chars = Rf_allocVector(VECSXP, 11);
	SET_VECTOR_ELT(chars, 0, UTC_str = Rf_mkString("UTC"));
	SET_VECTOR_ELT(chars, 1, Date_str = Rf_mkString("Date"));
	SET_VECTOR_ELT(chars, 2, difftime_str = Rf_mkString("difftime"));
	SET_VECTOR_ELT(chars, 3, secs_str = Rf_mkString("secs"));
	SET_VECTOR_ELT(chars, 4, arrow_str = Rf_mkString("arrow"));
	SET_VECTOR_ELT(chars, 5, duckdb_str = Rf_mkString("duckdb"));
	SET_VECTOR_ELT(chars, 6, POSIXct_POSIXt_str = StringsToSexp({"POSIXct", "POSIXt"}));
	SET_VECTOR_ELT(chars, 7, factor_str = Rf_mkString("factor"));
	SET_VECTOR_ELT(chars, 8, dataframe_str = Rf_mkString("data.frame"));
	SET_VECTOR_ELT(chars, 9, integer64_str = Rf_mkString("integer64"));
	SET_VECTOR_ELT(chars, 10, tbl_df_tbl_dataframe_str = StringsToSexp({"tbl_df", "tbl", "data.frame"}));

	R_PreserveObject(chars);
	MARK_NOT_MUTABLE(chars);

	// Symbols don't need to be protected
	enc2utf8_sym = Rf_install("enc2utf8");
	tzone_sym = Rf_install("tzone");
	units_sym = Rf_install("units");
	dim_sym = Rf_install("dim");
	getNamespace_sym = Rf_install("getNamespace");
	ImportSchema_sym = Rf_install("ImportSchema");
	ImportRecordBatch_sym = Rf_install("ImportRecordBatch");
	ImportRecordBatchReader_sym = Rf_install("ImportRecordBatchReader");
	Table__from_record_batches_sym = Rf_install("Table__from_record_batches");
	materialize_message_sym = Rf_install("duckdb.materialize_message");
	materialize_callback_sym = Rf_install("duckdb.materialize_callback");
	get_progress_display_sym = Rf_install("get_progress_display");
	duckdb_row_names_sym = Rf_install("duckdb_row_names");
	duckdb_vector_sym = Rf_install("duckdb_vector");
}

LogicalType RStringsType::Get() {
	LogicalType r_string_type(LogicalTypeId::POINTER);
	r_string_type.SetAlias(R_STRING_TYPE_NAME);
	return r_string_type;
}

template <class SRC, class DST, class RTYPE>
static void AppendColumnSegment(SRC *source_data, Vector &result, idx_t count) {
	auto result_data = FlatVector::GetData<DST>(result);
	auto &result_mask = FlatVector::Validity(result);
	for (idx_t i = 0; i < count; i++) {
		auto val = source_data[i];
		if (RTYPE::IsNull(val)) {
			result_mask.SetInvalid(i);
		} else {
			result_data[i] = RTYPE::Convert(val);
		}
	}
}

R_len_t RApiTypes::GetVecSize(RType rtype, SEXP coldata) {
	while (rtype.id() == RTypeId::STRUCT) {
		rtype = rtype.GetStructChildTypes()[0].second;
		D_ASSERT(TYPEOF(coldata) == VECSXP);
		coldata = VECTOR_ELT(coldata, 0);
	}
	if (rtype.id() == RTypeId::MATRIX) {
		return Rf_nrows(coldata);
	}
	// This still isn't quite accurate, but good enough for the types we support.
	return Rf_length(coldata);
}

R_len_t RApiTypes::GetVecSize(SEXP coldata, bool integer64) {
	auto rtype = DetectRType(coldata, integer64);
	return GetVecSize(rtype, coldata);
}

Value RApiTypes::SexpToValue(SEXP valsexp, R_len_t idx, bool typed_logical_null) {
	auto rtype = RApiTypes::DetectRType(valsexp, false); // TODO
	switch (rtype.id()) {
	case RType::LOGICAL: {
		auto lgl_val = INTEGER_POINTER(valsexp)[idx];
		return RBooleanType::IsNull(lgl_val) ? Value(typed_logical_null ? LogicalType::BOOLEAN : LogicalType::SQLNULL)
		                                     : Value::BOOLEAN(lgl_val);
	}
	case RType::INTEGER: {
		auto int_val = INTEGER_POINTER(valsexp)[idx];
		return RIntegerType::IsNull(int_val) ? Value(LogicalType::INTEGER) : Value::INTEGER(int_val);
	}
	case RType::NUMERIC: {
		auto dbl_val = NUMERIC_POINTER(valsexp)[idx];
		bool is_null = RDoubleType::IsNull(dbl_val);
		if (is_null) {
			return Value(LogicalType::DOUBLE);
		} else {
			return Value::DOUBLE(dbl_val);
		}
	}
	case RType::STRING: {
		auto str_val = STRING_ELT(ToUtf8(valsexp), idx);
		return str_val == NA_STRING ? Value(LogicalType::VARCHAR) : Value(CHAR(str_val));
	}
	case RTypeId::FACTOR: {
		auto int_val = INTEGER_POINTER(valsexp)[idx];
		return rtype.GetFactorValue(int_val);
	}
	case RType::TIMESTAMP: {
		auto ts_val = NUMERIC_POINTER(valsexp)[idx];
		bool is_null = RTimestampType::IsNull(ts_val);
		if (!is_null) {
			return Value::TIMESTAMP(RTimestampType::Convert(ts_val));
		} else {
			return Value(LogicalType::TIMESTAMP);
		}
	}
	case RType::DATE: {
		auto d_val = NUMERIC_POINTER(valsexp)[idx];
		return RDateType::IsNull(d_val) ? Value(LogicalType::DATE) : Value::DATE(RDateType::Convert(d_val));
	}
	case RType::DATE_INTEGER: {
		auto d_val = INTEGER_POINTER(valsexp)[idx];
		return RIntegerType::IsNull(d_val) ? Value(LogicalType::DATE) : Value::DATE(RDateType::Convert(d_val));
	}
	case RType::INTERVAL_SECONDS: {
		auto ts_val = NUMERIC_POINTER(valsexp)[idx];
		return RIntervalSecondsType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                            : Value::INTERVAL(RIntervalSecondsType::Convert(ts_val));
	}
	case RType::INTERVAL_MINUTES: {
		auto ts_val = NUMERIC_POINTER(valsexp)[idx];
		return RIntervalMinutesType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                            : Value::INTERVAL(RIntervalMinutesType::Convert(ts_val));
	}
	case RType::INTERVAL_HOURS: {
		auto ts_val = NUMERIC_POINTER(valsexp)[idx];
		return RIntervalHoursType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                          : Value::INTERVAL(RIntervalHoursType::Convert(ts_val));
	}
	case RType::INTERVAL_DAYS: {
		auto ts_val = NUMERIC_POINTER(valsexp)[idx];
		return RIntervalDaysType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                         : Value::INTERVAL(RIntervalDaysType::Convert(ts_val));
	}
	case RType::INTERVAL_WEEKS: {
		auto ts_val = NUMERIC_POINTER(valsexp)[idx];
		return RIntervalWeeksType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                          : Value::INTERVAL(RIntervalWeeksType::Convert(ts_val));
	}
	case RType::INTERVAL_SECONDS_INTEGER: {
		auto ts_val = INTEGER_POINTER(valsexp)[idx];
		return RIntegerType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                    : Value::INTERVAL(RIntervalSecondsType::Convert(ts_val));
	}
	case RType::INTERVAL_MINUTES_INTEGER: {
		auto ts_val = INTEGER_POINTER(valsexp)[idx];
		return RIntegerType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                    : Value::INTERVAL(RIntervalMinutesType::Convert(ts_val));
	}
	case RType::INTERVAL_HOURS_INTEGER: {
		auto ts_val = INTEGER_POINTER(valsexp)[idx];
		return RIntegerType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                    : Value::INTERVAL(RIntervalHoursType::Convert(ts_val));
	}
	case RType::INTERVAL_DAYS_INTEGER: {
		auto ts_val = INTEGER_POINTER(valsexp)[idx];
		return RIntegerType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                    : Value::INTERVAL(RIntervalDaysType::Convert(ts_val));
	}
	case RType::INTERVAL_WEEKS_INTEGER: {
		auto ts_val = INTEGER_POINTER(valsexp)[idx];
		return RIntegerType::IsNull(ts_val) ? Value(LogicalType::INTERVAL)
		                                    : Value::INTERVAL(RIntervalWeeksType::Convert(ts_val));
	}
	case RType::LIST_OF_NULLS:
		// Performance shortcut: this corresponds to the RType::BLOB case,
		// but we already know that all values are NULL
		return Value(LogicalType::BLOB);
	case RType::BLOB: {
		auto ts_val = VECTOR_ELT(valsexp, idx);
		return Rf_isNull(ts_val) ? Value(LogicalType::BLOB) : Value::BLOB(RAW(ts_val), Rf_xlength(ts_val));
	}
	case RTypeId::LIST: {
		auto ts_val = VECTOR_ELT(valsexp, idx);
		auto child_rtype = rtype.GetListChildType();
		vector<Value> child_values;
		R_len_t child_len = GetVecSize(child_rtype, ts_val);
		for (R_len_t child_idx = 0; child_idx < child_len; ++child_idx) {
			auto value = SexpToValue(ts_val, child_idx);
			child_values.push_back(value);
		}
		if (child_values.empty()) {
			return Value::LIST(RApiTypes::LogicalTypeFromRType(child_rtype, true), std::move(child_values));
		}
		return Value::LIST(std::move(child_values));
	}
	case RTypeId::STRUCT: {
		child_list_t<Value> child_values;
		auto ncol = Rf_length(valsexp);
		auto child_rtypes = rtype.GetStructChildTypes();
		for (R_len_t col = 0; col < ncol; ++col) {
			auto value = SexpToValue(VECTOR_ELT(valsexp, col), idx);
			child_values.push_back(std::make_pair(child_rtypes[col].first, value));
		}
		return Value::STRUCT(std::move(child_values));
	}
	default:
		cpp11::stop("duckdb_sexp_to_value: Unsupported type");
		return Value();
	}
}

SEXP RApiTypes::ValueToSexp(Value &val, string &timezone_config) {
	if (val.IsNull()) {
		return R_NilValue;
	}

	switch (val.type().id()) {
	case LogicalTypeId::BOOLEAN:
		return cpp11::logicals({val.GetValue<bool>()});
	case LogicalTypeId::TINYINT:
	case LogicalTypeId::SMALLINT:
	case LogicalTypeId::INTEGER:
	case LogicalTypeId::UTINYINT:
	case LogicalTypeId::USMALLINT:
	case LogicalTypeId::UINTEGER:
		return cpp11::integers({val.GetValue<int32_t>()});
	case LogicalTypeId::BIGINT:
	case LogicalTypeId::UBIGINT:
	case LogicalTypeId::FLOAT:
	case LogicalTypeId::DOUBLE:
	case LogicalTypeId::DECIMAL:
		return cpp11::doubles({val.GetValue<double>()});
	case LogicalTypeId::VARCHAR:
		return StringsToSexp({val.ToString()});
	case LogicalTypeId::TIMESTAMP: {
		cpp11::doubles res({(double)Timestamp::GetEpochSeconds(val.GetValue<timestamp_t>())});
		// TODO bit of duplication here with statement.cpp, fix this
		// some dresssup for R
		SET_CLASS(res, RStrings::get().POSIXct_POSIXt_str);
		Rf_setAttrib(res, RStrings::get().tzone_sym, StringsToSexp({""}));
		return res;
	}
	case LogicalTypeId::TIMESTAMP_TZ: {
		cpp11::doubles res({(double)Timestamp::GetEpochSeconds(val.GetValue<timestamp_tz_t>())});
		SET_CLASS(res, RStrings::get().POSIXct_POSIXt_str);
		Rf_setAttrib(res, RStrings::get().tzone_sym, StringsToSexp({timezone_config}));
		return res;
	}
	case LogicalTypeId::TIME: {
		cpp11::doubles res({(double)val.GetValue<dtime_t>().micros / Interval::MICROS_PER_SEC});
		// some dresssup for R
		SET_CLASS(res, RStrings::get().difftime_str);
		// we always return difftime as "seconds"
		Rf_setAttrib(res, RStrings::get().units_sym, RStrings::get().secs_str);
		return res;
	}

	case LogicalTypeId::DATE: {
		cpp11::doubles res({(double)int32_t(val.GetValue<date_t>())});
		// some dresssup for R
		SET_CLASS(res, RStrings::get().Date_str);
		return res;
	}

	default:
		throw NotImplementedException("Can't convert %s of type %s", val.ToString(), val.type().ToString());
	}
}

[[cpp11::register]] void rapi_load_rfuns(duckdb::db_eptr_t dual) {
	if (!dual || !dual.get()) {
		cpp11::stop("rapi_load_rfuns: Invalid database reference");
	}
	auto db = dual->get();
	if (!db || !db->db) {
		cpp11::stop("rapi_load_rfuns: Database already closed");
	}
	db->db->LoadExtension<RfunsExtension>();
}
