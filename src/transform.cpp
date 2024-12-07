#include "rapi.hpp"
#include "typesr.hpp"
#include "duckdb/common/types/uuid.hpp"
#include "duckdb/common/types/uhugeint.hpp"

using namespace duckdb;

// converter for primitive types
template <class SRC, class DEST>
static void VectorToR(Vector &src_vec, size_t count, void *dest, uint64_t dest_offset, DEST na_val) {
	auto src_ptr = FlatVector::GetData<SRC>(src_vec);
	auto &mask = FlatVector::Validity(src_vec);
	auto dest_ptr = ((DEST *)dest) + dest_offset;
	for (size_t row_idx = 0; row_idx < count; row_idx++) {
		dest_ptr[row_idx] = !mask.RowIsValid(row_idx) ? na_val : src_ptr[row_idx];
	}
}

SEXP duckdb_r_allocate(const LogicalType &type, idx_t nrows) {
	if (type.GetAlias() == R_STRING_TYPE_NAME) {
		return NEW_STRING(nrows);
	}

	switch (type.id()) {
	case LogicalTypeId::BOOLEAN:
		return NEW_LOGICAL(nrows);
	case LogicalTypeId::UTINYINT:
	case LogicalTypeId::TINYINT:
	case LogicalTypeId::SMALLINT:
	case LogicalTypeId::USMALLINT:
	case LogicalTypeId::INTEGER:
		return NEW_INTEGER(nrows);
	case LogicalTypeId::UINTEGER:
	case LogicalTypeId::BIGINT:
	case LogicalTypeId::UBIGINT:
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
		return NEW_NUMERIC(nrows);
	case LogicalTypeId::LIST:
	case LogicalTypeId::MAP:
		return NEW_LIST(nrows);
	case LogicalTypeId::STRUCT: {
		cpp11::writable::list dest_list;
		dest_list.reserve(StructType::GetChildTypes(type).size());

		for (const auto &child : StructType::GetChildTypes(type)) {
			const auto &name = child.first;
			const auto &child_type = child.second;

			cpp11::sexp dest_child = duckdb_r_allocate(child_type, nrows);
			dest_list.push_back(cpp11::named_arg(name.c_str()) = std::move(dest_child));
		}

		// convert to SEXP, with potential side effect of truncation
		(void)(SEXP)dest_list;

		// Note we cannot use cpp11's data frame here as it tries to calculate the number of rows itself,
		// but gives the wrong answer if the first column is another data frame or the struct is empty.
		dest_list.attr(R_ClassSymbol) = RStrings::get().dataframe_str;
		dest_list.attr(R_RowNamesSymbol) = {NA_INTEGER, -static_cast<int>(nrows)};

		return dest_list;
	}
	case LogicalTypeId::VARCHAR:
	case LogicalTypeId::UUID:
		return NEW_STRING(nrows);
	case LogicalTypeId::BLOB:
		return NEW_LIST(nrows);
	case LogicalTypeId::ENUM:
		return NEW_INTEGER(nrows);
	default:
		cpp11::stop("rapi_execute: Unknown column type for execute: %s", type.ToString().c_str());
	}
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
void ConvertTimestampVector(Vector &src_vec, size_t count, const SEXP dest, uint64_t dest_offset) {
	auto src_data = FlatVector::GetData<int64_t>(src_vec);
	auto &mask = FlatVector::Validity(src_vec);
	double *dest_ptr = ((double *)NUMERIC_POINTER(dest)) + dest_offset;
	for (size_t row_idx = 0; row_idx < count; row_idx++) {
		dest_ptr[row_idx] = !mask.RowIsValid(row_idx) ? NA_REAL : ConvertTimestampValue<LT>(src_data[row_idx]);
	}
}

std::once_flag nanosecond_coercion_warning;

void duckdb_r_decorate(const LogicalType &type, const SEXP dest, bool integer64) {
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
	case LogicalTypeId::TIMESTAMP_SEC:
	case LogicalTypeId::TIMESTAMP_MS:
	case LogicalTypeId::TIMESTAMP:
	case LogicalTypeId::TIMESTAMP_TZ:
	case LogicalTypeId::TIMESTAMP_NS:
		SET_CLASS(dest, RStrings::get().POSIXct_POSIXt_str);
		Rf_setAttrib(dest, RStrings::get().tzone_sym, RStrings::get().UTC_str);
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
		if (integer64) {
			Rf_setAttrib(dest, R_ClassSymbol, RStrings::get().integer64_str);
		}
		break;
	case LogicalTypeId::STRUCT: {
		const auto &child_types = StructType::GetChildTypes(type);
		for (size_t i = 0; i < child_types.size(); i++) {
			const auto &child_type = child_types[i].second;
			SEXP child_dest = VECTOR_ELT(dest, i);
			duckdb_r_decorate(child_type, child_dest, integer64);
		}

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

	default:
		cpp11::stop("rapi_execute: Unknown column type for convert: %s", type.ToString().c_str());
		break;
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
		cpp11::stop("String contains null byte");
	}
	return Rf_mkCharLenCE(data, len, CE_UTF8);
}

void duckdb_r_transform(Vector &src_vec, const SEXP dest, idx_t dest_offset, idx_t n, bool integer64) {
	if (src_vec.GetType().GetAlias() == R_STRING_TYPE_NAME) {
		ptrdiff_t sexp_header_size = (data_ptr_t)DATAPTR(R_BlankString) - (data_ptr_t)R_BlankString;

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
			dest_ptr[row_idx] = !mask.RowIsValid(row_idx) ? NA_REAL : (double)int32_t(src_data[row_idx]);
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
				dest_ptr[row_idx] = src_data[row_idx].micros / Interval::MICROS_PER_SEC;
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
				dest_ptr[row_idx] = Interval::GetMicro(src_data[row_idx]) / Interval::MICROS_PER_SEC;
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
		if (integer64) {
			// this silently loses the high bit
			VectorToR<uint64_t, int64_t>(src_vec, n, NUMERIC_POINTER(dest), dest_offset,
			                             NumericLimits<int64_t>::Minimum());
			Rf_setAttrib(dest, R_ClassSymbol, RStrings::get().integer64_str);
		} else {
			VectorToR<uint64_t, double>(src_vec, n, NUMERIC_POINTER(dest), dest_offset, NA_REAL);
		}
		break;
	case LogicalTypeId::BIGINT:
		if (integer64) {
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
		auto src_data = ListVector::GetData(src_vec);
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
				cpp11::sexp list_element = duckdb_r_allocate(child_type, src_data[row_idx].length);
				duckdb_r_decorate(child_type, list_element, integer64);
				duckdb_r_transform(child_vector, list_element, 0, src_data[row_idx].length, integer64);

				// call R's own extract subset method
				SET_ELEMENT(dest, dest_offset + row_idx, list_element);
			}
		}
		break;
	}
	case LogicalTypeId::STRUCT: {
		const auto &children = StructVector::GetEntries(src_vec);

		for (size_t i = 0; i < children.size(); i++) {
			const auto &struct_child = children[i];
			SEXP child_dest = VECTOR_ELT(dest, i);
			duckdb_r_transform(*struct_child, child_dest, dest_offset, n, integer64);
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

				cpp11::sexp key_sexp = duckdb_r_allocate(key_type, length);
				cpp11::sexp value_sexp = duckdb_r_allocate(value_type, length);

				duckdb_r_decorate(key_type, key_sexp, integer64);
				duckdb_r_decorate(value_type, value_sexp, integer64);

				duckdb_r_transform(key_child, key_sexp, 0, length, integer64);
				duckdb_r_transform(value_child, value_sexp, 0, length, integer64);

				cpp11::writable::list dest_list;
				dest_list.reserve(2);

				dest_list.push_back(cpp11::named_arg("key") = std::move(key_sexp));
				dest_list.push_back(cpp11::named_arg("value") = std::move(value_sexp));

				// convert to SEXP, with potential side effect of truncation
				(void)(SEXP)dest_list;

				// Note we cannot use cpp11's data frame here as it tries to calculate the number of rows itself,
				// but gives the wrong answer if the first column is another data frame or the struct is empty.
				dest_list.attr(R_ClassSymbol) = RStrings::get().dataframe_str;
				dest_list.attr(R_RowNamesSymbol) = {NA_INTEGER, -static_cast<int>(length)};
				// call R's own extract subset method
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
			VectorToR<uint8_t, uint32_t>(src_vec, n, INTEGER_POINTER(dest), dest_offset, NA_INTEGER);
			break;

		default:
			cpp11::stop("rapi_execute: Unknown enum type for convert: %s", TypeIdToString(physical_type).c_str());
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
	default:
		cpp11::stop("rapi_execute: Unknown column type for convert: %s", src_vec.GetType().ToString().c_str());
	}
}
