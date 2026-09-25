#include "duckdb/common/arrow/arrow.hpp"
#include "duckdb/common/arrow/arrow_converter.hpp"
#include "duckdb/common/arrow/arrow_util.hpp"
#include "duckdb/common/arrow/arrow_wrapper.hpp"
#include "duckdb/common/arrow/result_arrow_wrapper.hpp"
#include "duckdb/main/chunk_scan_state/query_result.hpp"
#include "rapi.hpp"

#include <cerrno>

// Handbook: handbook/usage/integrations/README.md (the Arrow routes out of a query result),
// and handbook/usage/memory/reading/README.md (what each route holds, and when it is freed)

// Avoid clash with TRUE and FALSE macros in older rtools
#undef TRUE
#undef FALSE

using namespace duckdb;

struct AppendableRList {
	AppendableRList() {
		the_list = NEW_LIST(capacity);
	}
	void PrepAppend() {
		if (size >= capacity) {
			capacity = capacity * 2;
			cpp11::sexp new_list = NEW_LIST(capacity);
			D_ASSERT(new_list != R_NilValue);
			for (idx_t i = 0; i < size; i++) {
				SET_VECTOR_ELT(new_list, i, VECTOR_ELT(the_list, i));
			}
			the_list = new_list;
		}
	}

	void Append(SEXP val) {
		D_ASSERT(size < capacity);
		D_ASSERT(the_list != R_NilValue);
		SET_VECTOR_ELT(the_list, size++, val);
	}
	cpp11::sexp the_list;
	idx_t capacity = 1000;
	idx_t size = 0;
};

bool FetchArrowChunk(ChunkScanState &scan_state, ClientProperties options, AppendableRList &batches_list,
                     ArrowArray &arrow_data, ArrowSchema &arrow_schema, SEXP batch_import_from_c, SEXP arrow_namespace,
                     idx_t chunk_size) {
	auto count =
	    ArrowUtil::FetchChunk(scan_state, options, chunk_size, &arrow_data,
	                          ArrowTypeExtensionData::GetExtensionTypes(*options.client_context, scan_state.Types()));
	if (count == 0) {
		return false;
	}
	ArrowConverter::ToArrowSchema(&arrow_schema, scan_state.Types(), scan_state.Names(), options);
	batches_list.PrepAppend();
	batches_list.Append(cpp11::safe[Rf_eval](batch_import_from_c, arrow_namespace));
	return true;
}

// Turn a DuckDB result set into an Arrow Table
[[cpp11::register]] SEXP rapi_execute_arrow(duckdb::rqry_eptr_t qry_res, int chunk_size) {
	if (!qry_res || !qry_res.get()) {
		rapi_error_with_context("rapi_execute_arrow", "Invalid query result");
	}
	if (!qry_res->result) {
		rapi_error_with_context("rapi_execute_arrow", "Result has already been consumed");
	}
	auto result = qry_res->result.get();
	// somewhat dark magic below
	cpp11::function getNamespace = RStrings::get().getNamespace_sym;
	cpp11::sexp arrow_namespace(getNamespace(RStrings::get().arrow_str));

	// export schema setup
	ArrowSchema arrow_schema;
	cpp11::doubles schema_ptr_sexp(Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&arrow_schema))));
	cpp11::sexp schema_import_from_c(Rf_lang2(RStrings::get().ImportSchema_sym, schema_ptr_sexp));

	// export data setup
	ArrowArray arrow_data;
	cpp11::doubles data_ptr_sexp(Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&arrow_data))));
	cpp11::sexp batch_import_from_c(Rf_lang3(RStrings::get().ImportRecordBatch_sym, data_ptr_sexp, schema_ptr_sexp));
	// create data batches
	AppendableRList batches_list;

	QueryResultChunkScanState scan_state(*result);
	while (FetchArrowChunk(scan_state, result->client_properties, batches_list, arrow_data, arrow_schema,
	                       batch_import_from_c, arrow_namespace, chunk_size)) {
	}

	SET_LENGTH(batches_list.the_list, batches_list.size);
	ArrowConverter::ToArrowSchema(&arrow_schema, result->types, result->names, result->client_properties);
	cpp11::sexp schema_arrow_obj(cpp11::safe[Rf_eval](schema_import_from_c, arrow_namespace));

	// create arrow::Table
	cpp11::sexp from_record_batches(
	    Rf_lang3(RStrings::get().Table__from_record_batches_sym, batches_list.the_list, schema_arrow_obj));
	return cpp11::safe[Rf_eval](from_record_batches, arrow_namespace);
}

RArrowArrayStreamWrapper::RArrowArrayStreamWrapper(duckdb::unique_ptr<QueryResult> result, idx_t batch_size)
    : engine(std::move(result), batch_size) {
	stream.get_schema = GetSchema;
	stream.get_next = GetNext;
	stream.get_last_error = GetLastError;
	stream.release = Release;
	stream.private_data = this;
}

// A streaming result that ran to the end has let go of its client context,
// one that another statement on its connection invalidated still holds it
// (vendored src/duckdb/src/main/stream_query_result.cpp).
bool RArrowArrayStreamWrapper::Invalidated() {
	auto &result = *engine.result;
	if (result.type != QueryResultType::STREAM_RESULT || result.HasError()) {
		return false;
	}
	auto &stream_result = result.Cast<StreamQueryResult>();
	return stream_result.context && !stream_result.IsOpen();
}

int RArrowArrayStreamWrapper::ReportInvalidated() {
	last_error = ErrorData(ExceptionType::INVALID_INPUT,
	                       "The Arrow stream was invalidated by another statement on its connection "
	                       "before it was read to the end. "
	                       "Read the stream to the end first, or run the other statement on a separate connection.");
	return EINVAL;
}

int RArrowArrayStreamWrapper::GetSchema(ArrowArrayStream *stream, ArrowSchema *out) {
	auto wrapper = reinterpret_cast<RArrowArrayStreamWrapper *>(stream->private_data);
	auto status = wrapper->engine.stream.get_schema(&wrapper->engine.stream, out);
	// The engine's own message for an invalidated result says only that it is closed.
	if (status != 0 && wrapper->Invalidated()) {
		return wrapper->ReportInvalidated();
	}
	return status;
}

int RArrowArrayStreamWrapper::GetNext(ArrowArrayStream *stream, ArrowArray *out) {
	auto wrapper = reinterpret_cast<RArrowArrayStreamWrapper *>(stream->private_data);
	// The engine reports an invalidated result as the end of the stream,
	// which reads as a complete result (#2772).
	if (wrapper->Invalidated()) {
		return wrapper->ReportInvalidated();
	}
	return wrapper->engine.stream.get_next(&wrapper->engine.stream, out);
}

const char *RArrowArrayStreamWrapper::GetLastError(ArrowArrayStream *stream) {
	auto wrapper = reinterpret_cast<RArrowArrayStreamWrapper *>(stream->private_data);
	if (wrapper->last_error.HasError()) {
		return wrapper->last_error.Message().c_str();
	}
	return wrapper->engine.stream.get_last_error(&wrapper->engine.stream);
}

void RArrowArrayStreamWrapper::Release(ArrowArrayStream *stream) {
	if (!stream || !stream->release) {
		return;
	}
	stream->release = nullptr;
	delete reinterpret_cast<RArrowArrayStreamWrapper *>(stream->private_data);
}

// Move the streaming query result into a nanoarrow-owned ArrowArrayStream.
// `stream_xptr` is a nanoarrow_array_stream external pointer whose target
// `ArrowArrayStream` struct has been zero-initialized by
// `nanoarrow::nanoarrow_allocate_array_stream()`. After this call, the
// stream owns the underlying QueryResult; the wrapper deletes itself when
// nanoarrow's finalizer invokes `stream->release()`.
[[cpp11::register]] void rapi_fetch_arrow_stream_into(duckdb::rqry_eptr_t qry_res, cpp11::sexp stream_xptr,
                                                      int chunk_size) {
	if (!qry_res || !qry_res.get()) {
		rapi_error_with_context("rapi_fetch_arrow_stream_into", "Invalid query result");
	}
	if (chunk_size <= 0) {
		rapi_error_with_context("rapi_fetch_arrow_stream_into", "Chunk Size must be higher than 0");
	}
	if (TYPEOF(stream_xptr.data()) != EXTPTRSXP) {
		rapi_error_with_context("rapi_fetch_arrow_stream_into", "Expected an external pointer for stream");
	}
	auto out = reinterpret_cast<ArrowArrayStream *>(R_ExternalPtrAddr(stream_xptr.data()));
	if (out == nullptr) {
		rapi_error_with_context("rapi_fetch_arrow_stream_into", "Stream pointer is NULL");
	}
	if (out->release != nullptr) {
		rapi_error_with_context("rapi_fetch_arrow_stream_into", "Stream pointer is already initialized");
	}

	RArrowArrayStreamWrapper *wrapper;
	if (qry_res->stream_wrapper) {
		wrapper = qry_res->stream_wrapper.release();
	} else if (qry_res->result) {
		wrapper = new RArrowArrayStreamWrapper(std::move(qry_res->result), chunk_size);
	} else {
		rapi_error_with_context("rapi_fetch_arrow_stream_into", "Result has already been consumed");
	}

	// POD-copy the wired-up stream; the wrapper deletes itself via the release
	// callback when nanoarrow's finalizer runs on `out`.
	*out = wrapper->stream;
	// Defensive: prevent any other path from re-releasing via the wrapper.
	wrapper->stream.release = nullptr;
}

// Fetch one Arrow chunk from the streaming query result. Both `schema_xptr`
// and `array_xptr` are nanoarrow-owned external pointers to zeroed structs
// (typically from `nanoarrow::nanoarrow_allocate_schema()` and
// `nanoarrow::nanoarrow_allocate_array()`). The schema is populated on every
// call so the caller can rely on it after the first chunk. Returns TRUE
// when a chunk was fetched, FALSE when the stream is exhausted.
[[cpp11::register]] bool rapi_fetch_arrow_array(duckdb::rqry_eptr_t qry_res, cpp11::sexp array_xptr,
                                                cpp11::sexp schema_xptr, int chunk_size) {
	if (!qry_res || !qry_res.get()) {
		rapi_error_with_context("rapi_fetch_arrow_array", "Invalid query result");
	}
	if (chunk_size <= 0) {
		rapi_error_with_context("rapi_fetch_arrow_array", "Chunk Size must be higher than 0");
	}
	if (TYPEOF(array_xptr.data()) != EXTPTRSXP || TYPEOF(schema_xptr.data()) != EXTPTRSXP) {
		rapi_error_with_context("rapi_fetch_arrow_array", "Expected external pointers for array and schema");
	}

	auto out_array = reinterpret_cast<ArrowArray *>(R_ExternalPtrAddr(array_xptr.data()));
	auto out_schema = reinterpret_cast<ArrowSchema *>(R_ExternalPtrAddr(schema_xptr.data()));
	if (out_array == nullptr || out_schema == nullptr) {
		rapi_error_with_context("rapi_fetch_arrow_array", "Output pointers are NULL");
	}

	if (!qry_res->stream_wrapper) {
		if (!qry_res->result) {
			rapi_error_with_context("rapi_fetch_arrow_array", "Result has already been consumed");
		}
		qry_res->stream_wrapper = make_uniq<RArrowArrayStreamWrapper>(std::move(qry_res->result), chunk_size);
	}

	auto &stream = qry_res->stream_wrapper->stream;
	if (out_schema->release == nullptr) {
		if (stream.get_schema(&stream, out_schema) != 0) {
			rapi_error_with_context("rapi_fetch_arrow_array", stream.get_last_error(&stream));
		}
	}
	if (stream.get_next(&stream, out_array) != 0) {
		rapi_error_with_context("rapi_fetch_arrow_array", stream.get_last_error(&stream));
	}
	return out_array->release != nullptr;
}

// Turn a DuckDB result set into an RecordBatchReader
[[cpp11::register]] SEXP rapi_record_batch(duckdb::rqry_eptr_t qry_res, int chunk_size) {
	if (!qry_res || !qry_res.get()) {
		rapi_error_with_context("rapi_record_batch", "Invalid query result");
	}
	if (!qry_res->result) {
		rapi_error_with_context("rapi_record_batch", "Result has already been consumed");
	}
	// somewhat dark magic below
	cpp11::function getNamespace = RStrings::get().getNamespace_sym;
	cpp11::sexp arrow_namespace(getNamespace(RStrings::get().arrow_str));

	// The wrapper owns the result from here on. arrow's ImportRecordBatchReader
	// takes the stream and frees both through stream.release when the reader is
	// collected; only a failing import below leaks it (handbook/usage/memory/reading/README.md).
	auto result_stream = new ResultArrowArrayStreamWrapper(std::move(qry_res->result), chunk_size);

	cpp11::sexp stream_ptr_sexp(
	    Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&result_stream->stream))));
	cpp11::sexp record_batch_reader(Rf_lang2(RStrings::get().ImportRecordBatchReader_sym, stream_ptr_sexp));
	return cpp11::safe[Rf_eval](record_batch_reader, arrow_namespace);
}
