#include "rapi.hpp"
#include "typesr.hpp"
#include "duckdb/common/types/uuid.hpp"
#include "duckdb/common/types/uhugeint.hpp"

using namespace duckdb;

// converter for primitive types
template <class SRC, class DEST>
static void VectorToR(const Vector &src_vec, size_t count, void *dest, uint64_t dest_offset, DEST na_val) {
	auto src_ptr = FlatVector::GetData<SRC>(src_vec);
	auto &mask = FlatVector::Validity(src_vec);
	auto dest_ptr = ((DEST *)dest) + dest_offset;
	for (size_t row_idx = 0; row_idx < count; row_idx++) {
		dest_ptr[row_idx] = !mask.RowIsValid(row_idx) ? na_val : src_ptr[row_idx];
	}
}

int duckdb_r_typeof(const LogicalType &type, const string &name, const char *caller) {
	if (type.GetAlias() == R_STRING_TYPE_NAME) {
		return STRSXP;
	}

	switch (type.id()) {
	case LogicalTypeId::BOOLEAN:
		return LGLSXP;
	case LogicalTypeId::UTINYINT:
	case LogicalTypeId::TINYINT:
	case LogicalTypeId::SMALLINT:
	case LogicalTypeId::USMALLINT:
	case LogicalTypeId::INTEGER:
		return INTSXP;
	case LogicalTypeId::UINTEGER:
		return REALSXP;
	case LogicalTypeId::BIGINT:
	case LogicalTypeId::UBIGINT:
		// Both for numeric and integer64 options
		return REALSXP;
	case LogicalTypeId::HUGEINT:
	case LogicalTypeId::UHUGEINT:
	case LogicalTypeId::FLOAT:
	case LogicalTypeId::DOUBLE:
	case LogicalTypeId::DECIMAL:
	case LogicalTypeId::TIMESTAMP_SEC:
	case LogicalTypeId::TIMESTAMP_MS:
	case LogicalTypeId::TIMESTAMP:
	case LogicalTypeId::TIMESTAMP_TZ:
	case LogicalTypeId::TIMESTAMP_NS:
	case LogicalTypeId::DATE:
	case LogicalTypeId::TIME:
	case LogicalTypeId::INTERVAL:
		return REALSXP;
	case LogicalTypeId::LIST:
	case LogicalTypeId::MAP:
		return VECSXP;
	case LogicalTypeId::ARRAY: {
		auto &child_type = ArrayType::GetChildType(type);
		return duckdb_r_typeof(child_type, name, caller);
	}
	case LogicalTypeId::STRUCT:
		return VECSXP;
	case LogicalTypeId::VARCHAR:
	case LogicalTypeId::UUID:
		return STRSXP;
	case LogicalTypeId::BLOB:
		return VECSXP;
	case LogicalTypeId::ENUM:
		return INTSXP;
	default: {
		std::string error_msg = "Unknown type for column `" + name + "`: " + type.ToString();
		rapi_error_with_context(caller, error_msg);
	}
	}
}

SEXP duckdb_r_allocate(const LogicalType &type, idx_t nrows, const string &name,
                       const duckdb::ConvertOpts &convert_opts, const char *caller) {
	int rtype = duckdb_r_typeof(type, name, caller);

	switch (type.id()) {
	case LogicalTypeId::ARRAY: {
		if (convert_opts.array != ConvertOpts::ArrayConversion::MATRIX)
			rapi_error_with_context("duckdb_r_allocate",
			                        "Use `dbConnect(array = \"matrix\")` to enable arrays to be returned to R.");
		auto array_size = ArrayType::GetSize(type);
		auto &child_type = ArrayType::GetChildType(type);
		if (child_type.IsNested())
			rapi_error_with_context("duckdb_r_allocate", "Nested arrays cannot be returned to R as column data.");
		cpp11::sexp varvalue =
		    duckdb_r_allocate(child_type, (nrows * array_size), name, convert_opts, "LogicalTypeId::ARRAY");
		return varvalue;
	}
	case LogicalTypeId::STRUCT: {
		cpp11::writable::list dest_list;
		dest_list.reserve(StructType::GetChildTypes(type).size());

		for (const auto &child : StructType::GetChildTypes(type)) {
			const auto &child_name = child.first;
			const auto &child_type = child.second;

			cpp11::sexp dest_child =
			    duckdb_r_allocate(child_type, nrows, name + "$" + child_name, convert_opts, "LogicalTypeId::STRUCT");
			dest_list.push_back(std::move(dest_child));
		}

		// convert to SEXP, with potential side effect of truncation
		(void)(SEXP)dest_list;

		// This is overstretching the concern of this function.
		// This logic belongs in duckdb_r_decorate(), but that function
		// does not know the number of rows.
		duckdb_r_df_decorate(dest_list, nrows);

		return dest_list;
	}
	default:
		return Rf_allocVector(rtype, nrows);
	}
}

// this allows us to set row names on a data frame with an int argument without calling INTPTR on it
void install_new_attrib(SEXP vec, SEXP name, SEXP val) {
	Rf_setAttrib(vec, name, R_NilValue);
	SEXP attrib_vec = ATTRIB(vec);
	SEXP attrib_cell = Rf_cons(val, CDR(attrib_vec));
	SET_TAG(attrib_cell, name);
	SETCDR(attrib_vec, attrib_cell);
}

void duckdb_r_df_decorate_impl(SEXP dest, SEXP rownames, SEXP class_) {
	Rf_setAttrib(dest, R_ClassSymbol, class_);
	install_new_attrib(dest, R_RowNamesSymbol, rownames);
}

void duckdb_r_df_decorate(SEXP dest, idx_t nrows, SEXP class_) {
	if (class_ == R_NilValue) {
		class_ = RStrings::get().dataframe_str;
	}
	duckdb_r_df_decorate_impl(dest, cpp11::writable::integers({NA_INTEGER, -static_cast<int>(nrows)}), class_);
}

// Convert DuckDB's timestamp to R's timestamp (POSIXct). This is a represented as the number of seconds since the
// epoch, stored as a double.
template <LogicalTypeId>
double ConvertTimestampValue(int64_t timestamp);

template <>
double ConvertTimestampValue<LogicalTypeId::TIMESTAMP_SEC>(int64_t timestamp) {
	return static_cast<double>(timestamp);
}

template <>
double ConvertTimestampValue<LogicalTypeId::TIMESTAMP_MS>(int64_t timestamp) {
	return static_cast<double>(timestamp) / Interval::MSECS_PER_SEC;
}

template <>
double ConvertTimestampValue<LogicalTypeId::TIMESTAMP>(int64_t timestamp) {
	return static_cast<double>(timestamp) / Interval::MICROS_PER_SEC;
}

template <>
double ConvertTimestampValue<LogicalTypeId::TIMESTAMP_TZ>(int64_t timestamp) {
	return ConvertTimestampValue<LogicalTypeId::TIMESTAMP>(timestamp);
}

template <>
double ConvertTimestampValue<LogicalTypeId::TIMESTAMP_NS>(int64_t timestamp) {
	return static_cast<double>(timestamp) / Interval::NANOS_PER_SEC;
}

template <LogicalTypeId LT>
void ConvertTimestampVector(const Vector &src_vec, size_t count, const SEXP dest, uint64_t dest_offset) {
	auto src_data = FlatVector::GetData<int64_t>(src_vec);
	auto &mask = FlatVector::Validity(src_vec);
	double *dest_ptr = ((double *)NUMERIC_POINTER(dest)) + dest_offset;
	for (size_t row_idx = 0; row_idx < count; row_idx++) {
		dest_ptr[row_idx] = !mask.RowIsValid(row_idx) ? NA_REAL : ConvertTimestampValue<LT>(src_data[row_idx]);
	}
}

std::once_flag nanosecond_coercion_warning;

void duckdb_r_decorate(const LogicalType &type, const SEXP dest, const duckdb::ConvertOpts &convert_opts) {
	if (type.GetAlias() == R_STRING_TYPE_NAME) {
		return;
	}

	switch (type.id()) {
	case LogicalTypeId::BOOLEAN:
	case LogicalTypeId::UTINYINT:
	case LogicalTypeId::TINYINT:
	case LogicalTypeId::USMALLINT:
	case LogicalTypeId::SMALLINT:
	case LogicalTypeId::INTEGER:
	case LogicalTypeId::UINTEGER:
	case LogicalTypeId::HUGEINT:
	case LogicalTypeId::UHUGEINT:
	case LogicalTypeId::DECIMAL:
	case LogicalTypeId::FLOAT:
	case LogicalTypeId::DOUBLE:
	case LogicalTypeId::VARCHAR:
	case LogicalTypeId::BLOB:
	case LogicalTypeId::UUID:
	case LogicalTypeId::LIST:
	case LogicalTypeId::MAP:
		break; // no extra decoration required, do nothing
	case LogicalTypeId::ARRAY: {
		auto array_size = ArrayType::GetSize(type);
		auto &child_type = ArrayType::GetChildType(type);
		duckdb_r_decorate(child_type, dest, convert_opts);
		// The class of a matrix and an array is implicit from
		// the dim attribute so we don't set the class attribute.
		// See: https://svn.r-project.org/R/trunk/src/main/attrib.c:656
		// SET_CLASS(dest, RStrings::get().matrix_array_str);
		cpp11::sexp dims = NEW_INTEGER(2);
		INTEGER(dims)[0] = (Rf_xlength(dest) / array_size);
		INTEGER(dims)[1] = array_size;
		Rf_setAttrib(dest, RStrings::get().dim_sym, dims);
		break;
	}
	case LogicalTypeId::TIMESTAMP_SEC:
	case LogicalTypeId::TIMESTAMP_MS:
	case LogicalTypeId::TIMESTAMP:
	case LogicalTypeId::TIMESTAMP_TZ:
	case LogicalTypeId::TIMESTAMP_NS:
		SET_CLASS(dest, RStrings::get().POSIXct_POSIXt_str);
		if (convert_opts.tz_out_convert == ConvertOpts::TzOutConvert::WITH) {
			// Attribute added here here, also useful for ALTREP
			if (convert_opts.timezone_out != "") {
				Rf_setAttrib(dest, RStrings::get().tzone_sym, StringsToSexp({convert_opts.timezone_out}));
			}
		} else {
			// Conversion happens in the R layer
			Rf_setAttrib(dest, RStrings::get().tzone_sym, RStrings::get().UTC_str);
		}
		break;
	case LogicalTypeId::DATE:
		SET_CLASS(dest, RStrings::get().Date_str);
		break;
	case LogicalTypeId::TIME:
	case LogicalTypeId::INTERVAL:
		SET_CLASS(dest, RStrings::get().difftime_str);
		Rf_setAttrib(dest, RStrings::get().units_sym, RStrings::get().secs_str);
		break;
	case LogicalTypeId::BIGINT:
	case LogicalTypeId::UBIGINT:
		if (convert_opts.bigint == ConvertOpts::BigIntType::INTEGER64) {
			Rf_setAttrib(dest, R_ClassSymbol, RStrings::get().integer64_str);
		}
		break;
	case LogicalTypeId::STRUCT: {
		const auto &child_types = StructType::GetChildTypes(type);
		cpp11::writable::strings names;
		names.reserve(child_types.size());

		for (size_t i = 0; i < child_types.size(); i++) {
			const auto &child_name = child_types[i].first;
			names.push_back(child_name);

			const auto &child_type = child_types[i].second;
			SEXP child_dest = VECTOR_ELT(dest, i);
			duckdb_r_decorate(child_type, child_dest, convert_opts);
		}

		SET_NAMES(dest, names);
		break;
	}

	case LogicalTypeId::ENUM: {
		auto &str_vec = EnumType::GetValuesInsertOrder(type);
		auto size = EnumType::GetSize(type);
		vector<string> str_c_vec(size);
		for (idx_t i = 0; i < size; i++) {
			str_c_vec[i] = str_vec.GetValue(i).ToString();
		}
		SET_LEVELS(dest, StringsToSexp(str_c_vec));
		SET_CLASS(dest, RStrings::get().factor_str);
		break;
	}

	default: {
		std::string error_msg = "Unknown column type: " + type.ToString();
		rapi_error_with_context("duckdb_r_decorate", error_msg);
		break;
	}
	}
}

SEXP ToRString(const string_t &input) {
	auto data = input.GetData();
	auto len = input.GetSize();
	idx_t has_null_byte = 0;
	for (idx_t c = 0; c < len; c++) {
		has_null_byte += data[c] == 0;
	}
	if (has_null_byte) {
		rapi_error_with_context("string_to_charsexp", "String contains null byte");
	}
	return Rf_mkCharLenCE(data, len, CE_UTF8);
}

static void TransformArrayVector(const Vector &src_vec, const SEXP dest, idx_t dest_offset, idx_t n,
                                 const duckdb::ConvertOpts &convert_opts, const string &name) {
	auto array_size = ArrayType::GetSize(src_vec.GetType());
	auto &child_type = ArrayType::GetChildType(src_vec.GetType());
	Vector child_vector(child_type, nullptr);

	cpp11::sexp buffer = duckdb_r_allocate(child_type, array_size, name, convert_opts, "TransformArrayVector");

	// Calculate total number of rows in the final matrix from the length of dest
	// The dest length should be total_rows * array_size
	idx_t total_rows = Rf_xlength(dest) / array_size;

	// actual loop over rows
	for (size_t row_idx = 0; row_idx < n; row_idx++) {
		size_t offset = (row_idx * array_size);
		size_t end = offset + array_size;
		child_vector.Slice(ArrayVector::GetEntry(src_vec), offset, end);
		duckdb_r_transform(child_vector, buffer, 0, array_size, convert_opts, name);

		// Calculate destination index for R column-major matrix layout
		size_t actual_row_idx = dest_offset + row_idx;

		switch (TYPEOF(buffer)) {
		case LGLSXP:
			for (size_t i = 0; i < array_size; i++) {
				size_t dest_idx = actual_row_idx + i * total_rows;
				LOGICAL(dest)[dest_idx] = LOGICAL(buffer)[i];
			}
			break;
		case INTSXP:
			for (size_t i = 0; i < array_size; i++) {
				size_t dest_idx = actual_row_idx + i * total_rows;
				INTEGER(dest)[dest_idx] = INTEGER(buffer)[i];
			}
			break;
		case REALSXP:
			for (size_t i = 0; i < array_size; i++) {
				size_t dest_idx = actual_row_idx + i * total_rows;
				REAL(dest)[dest_idx] = REAL(buffer)[i];
			}
			break;
		case STRSXP:
			for (size_t i = 0; i < array_size; i++) {
				size_t dest_idx = actual_row_idx + i * total_rows;
				SET_STRING_ELT(dest, dest_idx, STRING_ELT(buffer, i));
			}
			break;
		case VECSXP:
			for (size_t i = 0; i < array_size; i++) {
				size_t dest_idx = actual_row_idx + i * total_rows;
				SET_VECTOR_ELT(dest, dest_idx, VECTOR_ELT(buffer, i));
			}
			break;
		default:
			throw NotImplementedException("Unimplemented internal type for ARRAY");
		}
	}
}

void duckdb_r_transform(const Vector &src_vec, const SEXP dest, idx_t dest_offset, idx_t n,
                        const duckdb::ConvertOpts &convert_opts, const string &name) {
	if (src_vec.GetType().GetAlias() == R_STRING_TYPE_NAME) {
		ptrdiff_t sexp_header_size = (data_ptr_t)DATAPTR_RO(R_BlankString) - (data_ptr_t)R_BlankString;

		auto child_ptr = FlatVector::GetData<uintptr_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		/* we have to use SET_STRING_ELT here because otherwise those SEXPs dont get referenced */
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!mask.RowIsValid(row_idx)) {
				SET_STRING_ELT(dest, dest_offset + row_idx, NA_STRING);
			} else {
				SET_STRING_ELT(dest, dest_offset + row_idx, (SEXP)((data_ptr_t)child_ptr[row_idx] - sexp_header_size));
			}
		}
		return;
	}

	switch (src_vec.GetType().id()) {
	case LogicalTypeId::BOOLEAN:
		VectorToR<int8_t, uint32_t>(src_vec, n, LOGICAL_POINTER(dest), dest_offset, NA_LOGICAL);
		break;
	case LogicalTypeId::UTINYINT:
		VectorToR<uint8_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
		break;
	case LogicalTypeId::TINYINT:
		VectorToR<int8_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
		break;
	case LogicalTypeId::USMALLINT:
		VectorToR<uint16_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
		break;
	case LogicalTypeId::SMALLINT:
		VectorToR<int16_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
		break;
	case LogicalTypeId::INTEGER:
		VectorToR<int32_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
		break;
	case LogicalTypeId::TIMESTAMP_SEC:
		ConvertTimestampVector<LogicalTypeId::TIMESTAMP_SEC>(src_vec, n, dest, dest_offset);
		break;
	case LogicalTypeId::TIMESTAMP_MS:
		ConvertTimestampVector<LogicalTypeId::TIMESTAMP_MS>(src_vec, n, dest, dest_offset);
		break;
	case LogicalTypeId::TIMESTAMP:
		ConvertTimestampVector<LogicalTypeId::TIMESTAMP>(src_vec, n, dest, dest_offset);
		break;
	case LogicalTypeId::TIMESTAMP_TZ:
		ConvertTimestampVector<LogicalTypeId::TIMESTAMP_TZ>(src_vec, n, dest, dest_offset);
		break;
	case LogicalTypeId::TIMESTAMP_NS:
		ConvertTimestampVector<LogicalTypeId::TIMESTAMP_NS>(src_vec, n, dest, dest_offset);
		std::call_once(nanosecond_coercion_warning, Rf_warning,
		               "Coercing nanoseconds to a lower resolution may result in a loss of data.");
		break;
	case LogicalTypeId::DATE: {
		auto src_data = FlatVector::GetData<date_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		double *dest_ptr = ((double *)NUMERIC_POINTER(dest)) + dest_offset;
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			dest_ptr[row_idx] = !mask.RowIsValid(row_idx) ? NA_REAL : static_cast<double>(int32_t(src_data[row_idx]));
		}

		// some dresssup for R
		SET_CLASS(dest, RStrings::get().Date_str);
		break;
	}
	case LogicalTypeId::TIME: {
		auto src_data = FlatVector::GetData<dtime_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		double *dest_ptr = ((double *)NUMERIC_POINTER(dest)) + dest_offset;
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!mask.RowIsValid(row_idx)) {
				dest_ptr[row_idx] = NA_REAL;
			} else {
				dest_ptr[row_idx] = static_cast<double>(src_data[row_idx].micros) / Interval::MICROS_PER_SEC;
			}
		}
		SET_CLASS(dest, RStrings::get().difftime_str);
		Rf_setAttrib(dest, RStrings::get().units_sym, RStrings::get().secs_str);
		break;
	}
	case LogicalTypeId::INTERVAL: {
		auto src_data = FlatVector::GetData<interval_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		double *dest_ptr = ((double *)NUMERIC_POINTER(dest)) + dest_offset;
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!mask.RowIsValid(row_idx)) {
				dest_ptr[row_idx] = NA_REAL;
			} else {
				dest_ptr[row_idx] =
				    static_cast<double>(Interval::GetMicro(src_data[row_idx])) / Interval::MICROS_PER_SEC;
			}
		}
		SET_CLASS(dest, RStrings::get().difftime_str);
		Rf_setAttrib(dest, RStrings::get().units_sym, RStrings::get().secs_str);
		break;
	}
	case LogicalTypeId::UINTEGER:
		VectorToR<uint32_t, double>(src_vec, n, NUMERIC_POINTER(dest), dest_offset, NA_REAL);
		break;
	case LogicalTypeId::UBIGINT:
		if (convert_opts.bigint == ConvertOpts::BigIntType::INTEGER64) {
			// this silently loses the high bit
			VectorToR<uint64_t, int64_t>(src_vec, n, NUMERIC_POINTER(dest), dest_offset,
			                             NumericLimits<int64_t>::Minimum());
			Rf_setAttrib(dest, R_ClassSymbol, RStrings::get().integer64_str);
		} else {
			VectorToR<uint64_t, double>(src_vec, n, NUMERIC_POINTER(dest), dest_offset, NA_REAL);
		}
		break;
	case LogicalTypeId::BIGINT:
		if (convert_opts.bigint == ConvertOpts::BigIntType::INTEGER64) {
			VectorToR<int64_t, int64_t>(src_vec, n, NUMERIC_POINTER(dest), dest_offset,
			                            NumericLimits<int64_t>::Minimum());
			Rf_setAttrib(dest, R_ClassSymbol, RStrings::get().integer64_str);
		} else {
			VectorToR<int64_t, double>(src_vec, n, NUMERIC_POINTER(dest), dest_offset, NA_REAL);
		}
		break;
	case LogicalTypeId::HUGEINT: {
		auto src_data = FlatVector::GetData<hugeint_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		double *dest_ptr = ((double *)NUMERIC_POINTER(dest)) + dest_offset;
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!mask.RowIsValid(row_idx)) {
				dest_ptr[row_idx] = NA_REAL;
			} else {
				Hugeint::TryCast(src_data[row_idx], dest_ptr[row_idx]);
			}
		}
		break;
	}
	case LogicalTypeId::UHUGEINT: {
		auto src_data = FlatVector::GetData<uhugeint_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		double *dest_ptr = ((double *)NUMERIC_POINTER(dest)) + dest_offset;
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!mask.RowIsValid(row_idx)) {
				dest_ptr[row_idx] = NA_REAL;
			} else {
				Uhugeint::TryCast(src_data[row_idx], dest_ptr[row_idx]);
			}
		}
		break;
	}
	case LogicalTypeId::DECIMAL: {
		auto &decimal_type = src_vec.GetType();
		double *dest_ptr = ((double *)NUMERIC_POINTER(dest)) + dest_offset;
		auto dec_scale = DecimalType::GetScale(decimal_type);
		switch (decimal_type.InternalType()) {
		case PhysicalType::INT16:
			RDecimalCastLoop<int16_t>(src_vec, n, dest_ptr, dec_scale);
			break;
		case PhysicalType::INT32:
			RDecimalCastLoop<int32_t>(src_vec, n, dest_ptr, dec_scale);
			break;
		case PhysicalType::INT64:
			RDecimalCastLoop<int64_t>(src_vec, n, dest_ptr, dec_scale);
			break;
		case PhysicalType::INT128:
			RDecimalCastLoop<hugeint_t>(src_vec, n, dest_ptr, dec_scale);
			break;
		default:
			throw NotImplementedException("Unimplemented internal type for DECIMAL");
		}
		break;
	}
	case LogicalTypeId::FLOAT:
		VectorToR<float, double>(src_vec, n, NUMERIC_POINTER(dest), dest_offset, NA_REAL);
		break;

	case LogicalTypeId::DOUBLE:
		VectorToR<double, double>(src_vec, n, NUMERIC_POINTER(dest), dest_offset, NA_REAL);
		break;
	case LogicalTypeId::VARCHAR: {
		auto src_ptr = FlatVector::GetData<string_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!mask.RowIsValid(row_idx)) {
				SET_STRING_ELT(dest, dest_offset + row_idx, NA_STRING);
			} else {
				SET_STRING_ELT(dest, dest_offset + row_idx, ToRString(src_ptr[row_idx]));
			}
		}
		break;
	}
	case LogicalTypeId::LIST: {
		// figure out the total and max element length of the list vector child
		const auto src_data = ListVector::GetData(src_vec);
		auto &child_type = ListType::GetChildType(src_vec.GetType());
		Vector child_vector(child_type, nullptr);

		// actual loop over rows
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!FlatVector::Validity(src_vec).RowIsValid(row_idx)) {
				SET_ELEMENT(dest, dest_offset + row_idx, R_NilValue);
			} else {
				const auto end = src_data[row_idx].offset + src_data[row_idx].length;
				child_vector.Slice(ListVector::GetEntry(src_vec), src_data[row_idx].offset, end);

				// transform the list child vector to a single R SEXP
				cpp11::sexp list_element =
				    duckdb_r_allocate(child_type, src_data[row_idx].length, name, convert_opts, "LogicalTypeId::LIST");
				duckdb_r_decorate(child_type, list_element, convert_opts);
				duckdb_r_transform(child_vector, list_element, 0, src_data[row_idx].length, convert_opts, name);

				// call R's own assign subset method
				SET_ELEMENT(dest, dest_offset + row_idx, list_element);
			}
		}
		break;
	}
	case LogicalTypeId::ARRAY: {
		TransformArrayVector(src_vec, dest, dest_offset, n, convert_opts, name);
		break;
	}
	case LogicalTypeId::STRUCT: {
		const auto &children = StructVector::GetEntries(src_vec);

		for (size_t i = 0; i < children.size(); i++) {
			const auto &struct_child = children[i];
			SEXP child_dest = VECTOR_ELT(dest, i);
			duckdb_r_transform(*struct_child, child_dest, dest_offset, n, convert_opts, name);
		}

		break;
	}

	case LogicalTypeId::MAP: {
		auto src_data = ListVector::GetData(src_vec);

		auto &key_type = MapType::KeyType(src_vec.GetType());
		auto &value_type = MapType::ValueType(src_vec.GetType());

		Vector key_child(key_type, nullptr);
		Vector value_child(value_type, nullptr);

		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!FlatVector::Validity(src_vec).RowIsValid(row_idx)) {
				SET_ELEMENT(dest, dest_offset + row_idx, R_NilValue);
			} else {
				auto offset = src_data[row_idx].offset;
				auto length = src_data[row_idx].length;
				const auto end = offset + length;

				key_child.Slice(MapVector::GetKeys(src_vec), offset, end);
				value_child.Slice(MapVector::GetValues(src_vec), offset, end);

				cpp11::sexp key_sexp = duckdb_r_allocate(key_type, length, name, convert_opts, "LogicalTypeId::MAP");
				cpp11::sexp value_sexp =
				    duckdb_r_allocate(value_type, length, name, convert_opts, "LogicalTypeId::MAP");

				duckdb_r_decorate(key_type, key_sexp, convert_opts);
				duckdb_r_decorate(value_type, value_sexp, convert_opts);

				duckdb_r_transform(key_child, key_sexp, 0, length, convert_opts, name);
				duckdb_r_transform(value_child, value_sexp, 0, length, convert_opts, name);

				cpp11::writable::list dest_list;
				dest_list.reserve(2);

				dest_list.push_back(cpp11::named_arg("key") = std::move(key_sexp));
				dest_list.push_back(cpp11::named_arg("value") = std::move(value_sexp));

				// convert to SEXP, with potential side effect of truncation
				(void)(SEXP)dest_list;

				// Note we cannot use cpp11's data frame here as it tries to calculate the number of rows itself,
				// but gives the wrong answer if the first column is another data frame or the struct is empty.
				duckdb_r_df_decorate(dest_list, length);

				// call R's own assign subset method
				SET_ELEMENT(dest, dest_offset + row_idx, dest_list);
			}
		}
		break;
	}

	case LogicalTypeId::BLOB: {
		auto src_ptr = FlatVector::GetData<string_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!mask.RowIsValid(row_idx)) {
				SET_VECTOR_ELT(dest, dest_offset + row_idx, R_NilValue);
			} else {
				SEXP rawval = NEW_RAW(src_ptr[row_idx].GetSize());
				if (!rawval) {
					throw std::bad_alloc();
				}
				memcpy(RAW_POINTER(rawval), src_ptr[row_idx].GetData(), src_ptr[row_idx].GetSize());
				SET_VECTOR_ELT(dest, dest_offset + row_idx, rawval);
			}
		}
		break;
	}
	case LogicalTypeId::ENUM: {
		auto physical_type = src_vec.GetType().InternalType();

		switch (physical_type) {
		case PhysicalType::UINT8:
			VectorToR<uint8_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
			break;

		case PhysicalType::UINT16:
			VectorToR<uint16_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
			break;

		case PhysicalType::UINT32:
			VectorToR<uint32_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
			break;

		default: {
			std::string error_msg = "Unknown enum type for convert: " + TypeIdToString(physical_type);
			rapi_error_with_context("duckdb_r_transform", error_msg);
		}
		}
		// increment by one cause R factor offsets start at 1
		auto dest_ptr = ((int32_t *)INTEGER_POINTER(dest)) + dest_offset;
		for (idx_t i = 0; i < n; i++) {
			if (dest_ptr[i] == NA_INTEGER) {
				continue;
			}
			dest_ptr[i]++;
		}

		auto &str_vec = EnumType::GetValuesInsertOrder(src_vec.GetType());
		auto size = EnumType::GetSize(src_vec.GetType());
		vector<string> str_c_vec(size);
		for (idx_t i = 0; i < size; i++) {
			str_c_vec[i] = str_vec.GetValue(i).ToString();
		}

		SET_LEVELS(dest, StringsToSexp(str_c_vec));
		SET_CLASS(dest, RStrings::get().factor_str);
		break;
	}
	case LogicalTypeId::UUID: {
		auto src_ptr = FlatVector::GetData<hugeint_t>(src_vec);
		auto &mask = FlatVector::Validity(src_vec);
		for (size_t row_idx = 0; row_idx < n; row_idx++) {
			if (!mask.RowIsValid(row_idx)) {
				SET_STRING_ELT(dest, dest_offset + row_idx, NA_STRING);
			} else {
				char uuid_buf[UUID::STRING_SIZE];
				UUID::ToString(src_ptr[row_idx], uuid_buf);
				SET_STRING_ELT(dest, dest_offset + row_idx, Rf_mkCharLen(uuid_buf, UUID::STRING_SIZE));
			}
		}
		break;
	}
	default: {
		std::string error_msg = "Unknown column type for convert: " + src_vec.GetType().ToString();
		rapi_error_with_context("duckdb_r_transform", error_msg);
	}
	}
}
