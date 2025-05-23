#include "duckdb/common/case_insensitive_map.hpp"
#include "rapi.hpp"
#include "typesr.hpp"

#include "duckdb/main/client_context.hpp"

using namespace duckdb;
using namespace cpp11;

static
data_ptr_t GetColDataPtr(const RType &rtype, SEXP coldata) {
	switch (rtype.id()) {
	case RType::LOGICAL:
		return (data_ptr_t)LOGICAL_POINTER(coldata);
	case RType::INTEGER:
		return (data_ptr_t)INTEGER_POINTER(coldata);
	case RType::NUMERIC:
		return (data_ptr_t)NUMERIC_POINTER(coldata);
	case RType::INTEGER64:
		return (data_ptr_t)NUMERIC_POINTER(coldata);
	case RTypeId::FACTOR:
		// TODO What about factors that use numeric?
		return (data_ptr_t)INTEGER_POINTER(coldata);
	case RType::STRING:
		return (data_ptr_t)DATAPTR_RO(coldata);
	case RType::TIMESTAMP:
		return (data_ptr_t)NUMERIC_POINTER(coldata);
	case RType::INTERVAL_SECONDS:
	case RType::INTERVAL_MINUTES:
	case RType::INTERVAL_HOURS:
	case RType::INTERVAL_DAYS:
	case RType::INTERVAL_WEEKS:
		return (data_ptr_t)NUMERIC_POINTER(coldata);
	case RType::INTERVAL_SECONDS_INTEGER:
	case RType::INTERVAL_MINUTES_INTEGER:
	case RType::INTERVAL_HOURS_INTEGER:
	case RType::INTERVAL_DAYS_INTEGER:
	case RType::INTERVAL_WEEKS_INTEGER:
		return (data_ptr_t)INTEGER_POINTER(coldata);
	case RType::DATE:
		if (!IS_NUMERIC(coldata)) {
			cpp11::stop("DATE should be of numeric type");
		}
		return (data_ptr_t)NUMERIC_POINTER(coldata);
	case RType::DATE_INTEGER:
		if (!IS_INTEGER(coldata)) {
			cpp11::stop("DATE_INTEGER should be of integer type");
		}
		return (data_ptr_t)INTEGER_POINTER(coldata);
	case RType::LIST_OF_NULLS:
	case RType::BLOB:
		return (data_ptr_t)DATAPTR_RO(coldata);
	case RTypeId::LIST:
		return (data_ptr_t)DATAPTR_RO(coldata);
	case RTypeId::MATRIX:
	case RTypeId::STRUCT:
		// Will bind child columns dynamically. Could also optimize by descending early and recording.
		return (data_ptr_t)coldata;
	default:
		cpp11::stop("GetColDataPtr: Unsupported column type for bind");
	}
}

struct DedupPointerEnumType {
	static bool IsNull(SEXP val) {
		return val == NA_STRING;
	}
	static uintptr_t Convert(SEXP val) {
		return (uintptr_t)DATAPTR_RO(val);
	}
};

template <class SRC, class DST, class RTYPE>
static void AppendColumnSegment(SRC *source_data, idx_t sexp_offset, Vector &result, idx_t count) {
	source_data += sexp_offset;
	auto &result_mask = FlatVector::Validity(result);
	for (idx_t i = 0; i < count; i++) {
		auto val = source_data[i];
		if (RTYPE::IsNull(val)) {
			result_mask.SetInvalid(i);
		} else {
			auto result_data = FlatVector::GetData<DST>(result);
			result_data[i] = RTYPE::Convert(val);
		}
	}
}

static
void AppendListColumnSegment(const RType &rtype, SEXP *source_data, idx_t sexp_offset, Vector &result, idx_t count) {
	source_data += sexp_offset;
	auto &result_mask = FlatVector::Validity(result);
	auto child_rtype = rtype.GetListChildType();
	auto result_data = FlatVector::GetData<list_entry_t>(result);
	for (idx_t i = 0; i < count; i++) {
		auto val = source_data[i];
		if (RSexpType::IsNull(val)) {
			result_mask.SetInvalid(i);
		} else {
			auto len = RApiTypes::GetVecSize(child_rtype, val);
			result_data[i].offset = ListVector::GetListSize(result);
			for (R_len_t child_idx = 0; child_idx < len; ++child_idx) {
				auto child_item = RApiTypes::SexpToValue(val, child_idx);
				ListVector::PushBack(result, child_item);
			}
			result_data[i].length = len;
		}
	}
}

template <class SRC, class DST, class RTYPE>
static inline
void AppendMatrixSegmentAtomic(SRC *src_ptr, int nrows, int ncols, idx_t sexp_offset,
                               Vector &child_vector, idx_t count) {
	auto child_data = FlatVector::GetData<DST>(child_vector);
	auto &child_mask = FlatVector::Validity(child_vector);
	idx_t vector_idx = 0;
	for (idx_t i = 0; i < count; i++) {
		auto matrix_elt_idx = sexp_offset + i;
		for (idx_t k = 0; k < ncols; k++) {
			auto val = src_ptr[matrix_elt_idx];
			if (RTYPE::IsNull(val)) {
				child_mask.SetInvalid(vector_idx++);
			} else {
				child_data[vector_idx++] = RTYPE::Convert(val);
			}
			matrix_elt_idx += nrows;
		}
	}
}

static
void AppendMatrixColumnSegment(const RType &rtype, bool experimental, SEXP source_data, idx_t sexp_offset, Vector &result, idx_t count) {
	auto element_rtype = rtype.GetMatrixElementType();
	auto nrows = Rf_nrows(source_data);
	auto ncols = Rf_ncols(source_data);
	auto &child_vector = ArrayVector::GetEntry(result);

	switch (element_rtype.id()) {
	case RType::LOGICAL: //LGLSXP
		AppendMatrixSegmentAtomic<int, bool, RBooleanType>(LOGICAL_POINTER(source_data),
		                                                   nrows, ncols, sexp_offset, child_vector, count);
		break;

	case RType::INTEGER: //INTSXP
		AppendMatrixSegmentAtomic<int, int, RIntegerType>(INTEGER_POINTER(source_data),
		                                                  nrows, ncols, sexp_offset, child_vector, count);
		break;

	case RType::INTEGER64: //REALSXP
		AppendMatrixSegmentAtomic<int64_t, int64_t, RInteger64Type>((int64_t *)NUMERIC_POINTER(source_data),
		                                                            nrows, ncols, sexp_offset, child_vector, count);
		break;

	case RType::NUMERIC: //REALSXP
		AppendMatrixSegmentAtomic<double, double, RDoubleType>(NUMERIC_POINTER(source_data),
		                                                       nrows, ncols, sexp_offset, child_vector, count);
		break;

	case RTypeId::BYTE: // RAWSXP
		cpp11::stop("Matrix of type raw is not supported.");
		break;

	case RType::STRING: //STRSXP
		if (experimental) {
			D_ASSERT(result.GetType().id() == LogicalTypeId::POINTER);
			AppendMatrixSegmentAtomic<SEXP, uintptr_t, DedupPointerEnumType>((SEXP *)DATAPTR_RO(source_data),
		                                                                     nrows, ncols, sexp_offset, child_vector, count);
		} else {
			AppendMatrixSegmentAtomic<SEXP, string_t, RStringSexpType>((SEXP *)DATAPTR_RO(source_data),
		                                                               nrows, ncols, sexp_offset, child_vector, count);
		}
		break;

	default:
		cpp11::stop("AppendMatrixColumnSegment: Unsupported matrix type for scan");
	}
}

static
void AppendAnyColumnSegment(const RType &rtype, bool experimental, data_ptr_t coldata_ptr, idx_t sexp_offset, Vector &v,
                            idx_t this_count);

static
void AppendStructColumnSegment(const RType &rtype, bool experimental, SEXP source_data, idx_t sexp_offset,
                               Vector &result, idx_t count) {
	// No NULL values for STRUCTs.
	auto &child_entries = StructVector::GetEntries(result);
	auto child_rtypes = rtype.GetStructChildTypes();
	for (size_t i = 0; i < child_entries.size(); ++i) {
		auto coldata = VECTOR_ELT(source_data, i);
		auto const &child_rtype = child_rtypes[i].second;
		auto coldata_ptr = GetColDataPtr(child_rtype, coldata);
		AppendAnyColumnSegment(child_rtype, experimental, coldata_ptr, sexp_offset, *child_entries[i], count);
	}
}

static
void AppendAnyColumnSegment(const RType &rtype, bool experimental, data_ptr_t coldata_ptr, idx_t sexp_offset, Vector &v,
                            idx_t this_count) {
	switch (rtype.id()) {
	case RType::LOGICAL: {
		auto data_ptr = (int *)coldata_ptr;
		AppendColumnSegment<int, bool, RBooleanType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTEGER: {
		auto data_ptr = (int *)coldata_ptr;
		AppendColumnSegment<int, int, RIntegerType>(data_ptr, sexp_offset, v, this_count);

		break;
	}
	case RType::NUMERIC: {
		auto data_ptr = (double *)coldata_ptr;
		AppendColumnSegment<double, double, RDoubleType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTEGER64: {
		auto data_ptr = (int64_t *)coldata_ptr;
		AppendColumnSegment<int64_t, int64_t, RInteger64Type>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::STRING: {
		auto data_ptr = (SEXP *)coldata_ptr;

		if (experimental) {
			D_ASSERT(v.GetType().id() == LogicalTypeId::POINTER);
			AppendColumnSegment<SEXP, uintptr_t, DedupPointerEnumType>(data_ptr, sexp_offset, v, this_count);
		} else {
			AppendColumnSegment<SEXP, string_t, RStringSexpType>(data_ptr, sexp_offset, v, this_count);
		}

		break;
	}
	case RTypeId::FACTOR: {
		auto data_ptr = (int *)coldata_ptr;
		switch (v.GetType().InternalType()) {
		case PhysicalType::UINT8:
			AppendColumnSegment<int, uint8_t, RFactorType>(data_ptr, sexp_offset, v, this_count);
			break;

		case PhysicalType::UINT16:
			AppendColumnSegment<int, uint16_t, RFactorType>(data_ptr, sexp_offset, v, this_count);
			break;

		case PhysicalType::UINT32:
			AppendColumnSegment<int, uint32_t, RFactorType>(data_ptr, sexp_offset, v, this_count);
			break;

		default:
			cpp11::stop("AppendAnyColumnSegment: Unknown enum type for scan: %s",
			            TypeIdToString(v.GetType().InternalType()).c_str());
		}
		break;
	}
	case RType::TIMESTAMP: {
		auto data_ptr = (double *)coldata_ptr;
		AppendColumnSegment<double, timestamp_t, RTimestampType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_SECONDS: {
		auto data_ptr = (double *)coldata_ptr;
		AppendColumnSegment<double, interval_t, RIntervalSecondsType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_MINUTES: {
		auto data_ptr = (double *)coldata_ptr;
		AppendColumnSegment<double, interval_t, RIntervalMinutesType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_HOURS: {
		auto data_ptr = (double *)coldata_ptr;
		AppendColumnSegment<double, interval_t, RIntervalHoursType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_DAYS: {
		auto data_ptr = (double *)coldata_ptr;
		AppendColumnSegment<double, interval_t, RIntervalDaysType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_WEEKS: {
		auto data_ptr = (double *)coldata_ptr;
		AppendColumnSegment<double, interval_t, RIntervalWeeksType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_SECONDS_INTEGER: {
		auto data_ptr = (int *)coldata_ptr;
		AppendColumnSegment<int, interval_t, RIntervalSecondsType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_MINUTES_INTEGER: {
		auto data_ptr = (int *)coldata_ptr;
		AppendColumnSegment<int, interval_t, RIntervalMinutesType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_HOURS_INTEGER: {
		auto data_ptr = (int *)coldata_ptr;
		AppendColumnSegment<int, interval_t, RIntervalHoursType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_DAYS_INTEGER: {
		auto data_ptr = (int *)coldata_ptr;
		AppendColumnSegment<int, interval_t, RIntervalDaysType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::INTERVAL_WEEKS_INTEGER: {
		auto data_ptr = (int *)coldata_ptr;
		AppendColumnSegment<int, interval_t, RIntervalWeeksType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::DATE: {
		auto data_ptr = (double *)coldata_ptr;
		AppendColumnSegment<double, date_t, RDateType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::DATE_INTEGER: {
		auto data_ptr = (int *)coldata_ptr;
		AppendColumnSegment<int, date_t, RDateType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RType::LIST_OF_NULLS:
	case RType::BLOB: {
		auto data_ptr = (SEXP *)coldata_ptr;
		AppendColumnSegment<SEXP, string_t, RRawSexpType>(data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RTypeId::LIST: {
		auto data_ptr = (SEXP *)coldata_ptr;
		AppendListColumnSegment(rtype, data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RTypeId::MATRIX: {
		auto data_ptr = (SEXP)coldata_ptr;
		AppendMatrixColumnSegment(rtype, experimental, data_ptr, sexp_offset, v, this_count);
		break;
	}
	case RTypeId::STRUCT: {
		auto data_ptr = (SEXP)coldata_ptr;
		AppendStructColumnSegment(rtype, experimental, data_ptr, sexp_offset, v, this_count);
		break;
	}
	default:
		cpp11::stop("AppendAnyColumnSegment: Unsupported column type for scan");
	}
}

case_insensitive_map_t<vector<Value>> ListToVectorOfValue(list input_sexps) {
	const bool integer64 = false, experimental = false;
	case_insensitive_map_t<vector<Value>> output;

	auto names = input_sexps.names();
	if (names.size() != input_sexps.size()) {
		stop("rel_from_table_function: Named parameters need names");
	}
	R_xlen_t input_idx = 0;
	for (sexp parameter_sexp : input_sexps) {
		auto rtype = RApiTypes::DetectRType(parameter_sexp, integer64);
		auto coldata = GetColDataPtr(rtype, parameter_sexp);
		auto size = RApiTypes::GetVecSize(parameter_sexp, integer64);
		Vector v(RApiTypes::LogicalTypeFromRType(rtype, experimental));
		AppendAnyColumnSegment(rtype, experimental, coldata, 0, v, size);

		vector<Value> vv;
		vv.reserve(size);
		for (idx_t i = 0; i < size; ++i) {
			vv.push_back(v.GetValue(i));
		}

		output[names[input_idx]] = vv;
		input_idx++;
	}

	return output;
}

static bool get_integer64_param(named_parameter_map_t &named_parameters) {
	auto entry = named_parameters.find("integer64");
	if (entry != named_parameters.end()) {
		return BooleanValue::Get(entry->second);
	}
	return false;
}

static bool get_experimental_param(named_parameter_map_t &named_parameters) {
	auto entry = named_parameters.find("experimental");
	if (entry != named_parameters.end()) {
		return BooleanValue::Get(entry->second);
	}
	return false;
}

struct DataFrameScanBindData : public TableFunctionData {
	DataFrameScanBindData(SEXP df_p, idx_t row_count_p, vector<RType> &rtypes_p, vector<data_ptr_t> &dataptrs_p,
	                      named_parameter_map_t &named_parameters)
	    : df(df_p), row_count(row_count_p), rtypes(rtypes_p), data_ptrs(dataptrs_p) {
		integer64 = get_integer64_param(named_parameters);
		experimental = get_experimental_param(named_parameters);
	}
	data_frame df;
	idx_t row_count;
	vector<RType> rtypes;
	vector<data_ptr_t> data_ptrs;
	idx_t rows_per_task = 1000000;
	bool integer64 = false;
	bool experimental = false;
};

struct DataFrameGlobalState : public GlobalTableFunctionState {
	DataFrameGlobalState(idx_t max_threads) : max_threads(max_threads) {
	}

	mutex lock;
	idx_t position = 0;
	idx_t max_threads;

	idx_t MaxThreads() const override {
		return max_threads;
	}
};

struct DataFrameLocalState : public LocalTableFunctionState {
	vector<column_t> column_ids;
	idx_t position;
	idx_t offset;
	idx_t count;
};

static duckdb::unique_ptr<FunctionData> DataFrameScanBind(ClientContext &context, TableFunctionBindInput &input,
                                                          vector<LogicalType> &return_types, vector<string> &names) {
	data_frame df((SEXP)input.inputs[0].GetPointer());

	auto integer64 = get_integer64_param(input.named_parameters);
	auto experimental = get_experimental_param(input.named_parameters);

	auto df_names = df.names();
	vector<RType> rtypes;
	vector<data_ptr_t> data_ptrs;

	for (R_xlen_t col_idx = 0; col_idx < df.size(); col_idx++) {
		names.push_back(df_names[col_idx]);

		auto coldata = df[col_idx];
		auto rtype = RApiTypes::DetectRType(coldata, integer64);
		rtypes.push_back(rtype);
		return_types.push_back(RApiTypes::LogicalTypeFromRType(rtype, experimental));

		data_ptrs.push_back(GetColDataPtr(rtype, coldata));
	}
	auto row_count = RApiTypes::GetVecSize(rtypes[0], VECTOR_ELT(df, 0));
	return make_uniq<DataFrameScanBindData>(df, row_count, rtypes, data_ptrs, input.named_parameters);
}

static idx_t DataFrameScanMaxThreads(ClientContext &context, const FunctionData *bind_data_p) {
	D_ASSERT(bind_data_p);
	auto bind_data = (const DataFrameScanBindData *)bind_data_p;
	return ceil((double)bind_data->row_count / bind_data->rows_per_task);
}

static duckdb::unique_ptr<GlobalTableFunctionState> DataFrameScanInitGlobal(ClientContext &context,
                                                                            TableFunctionInitInput &input) {
	auto result = make_uniq<DataFrameGlobalState>(DataFrameScanMaxThreads(context, input.bind_data.get()));
	result->position = 0;
	return std::move(result);
}

static bool DataFrameScanParallelStateNext(ClientContext &context, const FunctionData *bind_data_p,
                                           DataFrameLocalState &local_state, DataFrameGlobalState &global_state) {
	auto &bind_data = bind_data_p->Cast<DataFrameScanBindData>();

	lock_guard<mutex> parallel_lock(global_state.lock);
	if (global_state.position >= bind_data.row_count) {
		local_state.position = 0;
		local_state.offset = 0;
		local_state.count = 0;
		return false;
	}
	auto offset = global_state.position;
	auto count = MinValue<idx_t>(bind_data.rows_per_task, bind_data.row_count - offset);
	local_state.position = 0;
	local_state.offset = offset;
	local_state.count = count;

	global_state.position += bind_data.rows_per_task;
	return true;
}

static unique_ptr<LocalTableFunctionState> DataFrameScanInitLocal(ExecutionContext &context,
                                                                  TableFunctionInitInput &input,
                                                                  GlobalTableFunctionState *global_state) {
	auto &gstate = global_state->Cast<DataFrameGlobalState>();
	auto result = make_uniq<DataFrameLocalState>();

	result->column_ids = input.column_ids;
	DataFrameScanParallelStateNext(context.client, input.bind_data.get(), *result, gstate);
	return std::move(result);
}

static void DataFrameScanFunc(ClientContext &context, TableFunctionInput &data, DataChunk &output) {
	auto &bind_data = data.bind_data->Cast<DataFrameScanBindData>();
	auto &operator_data = data.local_state->Cast<DataFrameLocalState>();
	auto &gstate = data.global_state->Cast<DataFrameGlobalState>();
	if (operator_data.position >= operator_data.count) {
		if (!DataFrameScanParallelStateNext(context, data.bind_data.get(), operator_data, gstate)) {
			return;
		}
	}
	idx_t this_count = MinValue<idx_t>(STANDARD_VECTOR_SIZE, operator_data.count - operator_data.position);
	output.SetCardinality(this_count);

	auto sexp_offset = operator_data.offset + operator_data.position;
	D_ASSERT(sexp_offset + this_count <= bind_data.row_count);

	for (R_xlen_t out_col_idx = 0; out_col_idx < R_xlen_t(output.ColumnCount()); out_col_idx++) {
		auto &v = output.data[out_col_idx];
		auto src_df_col_idx = operator_data.column_ids[out_col_idx];

		// Hannes: I love the reference, but would you mind adding a bit of context why this is necessary?
		if (src_df_col_idx == COLUMN_IDENTIFIER_ROW_ID) {
			Value constant_42 = Value::BIGINT(42);
			output.data[out_col_idx].Reference(constant_42);
			continue;
		}

		auto coldata_ptr = bind_data.data_ptrs[src_df_col_idx];
		auto rtype = bind_data.rtypes[src_df_col_idx];
		AppendAnyColumnSegment(rtype, bind_data.experimental, coldata_ptr, sexp_offset, v, this_count);
	}
	operator_data.position += this_count;
}

static unique_ptr<NodeStatistics> DataFrameScanCardinality(ClientContext &context, const FunctionData *bind_data_p) {
	auto &bind_data = bind_data_p->Cast<DataFrameScanBindData>();
	return make_uniq<NodeStatistics>(bind_data.row_count, bind_data.row_count);
}

static InsertionOrderPreservingMap<string> DataFrameScanToString(TableFunctionToStringInput &input) {
	InsertionOrderPreservingMap<string> result;
	result["Text"] = "data.frame";
	return result;
}

DataFrameScanFunction::DataFrameScanFunction()
    : TableFunction("r_dataframe_scan", {LogicalType::POINTER}, DataFrameScanFunc, DataFrameScanBind,
                    DataFrameScanInitGlobal, DataFrameScanInitLocal) {
	cardinality = DataFrameScanCardinality;
	to_string = DataFrameScanToString;
	named_parameters["integer64"] = LogicalType::BOOLEAN;
	named_parameters["experimental"] = LogicalType::BOOLEAN;
	projection_pushdown = true;
	global_initialization = TableFunctionInitialization::INITIALIZE_ON_SCHEDULE;
}
