#include "duckdb/common/arrow/arrow.hpp"
#include "duckdb/common/arrow/arrow_converter.hpp"
#include "duckdb/common/arrow/arrow_appender.hpp"
#include "duckdb/common/arrow/arrow_wrapper.hpp"
#include "duckdb/main/buffered_data/buffered_data.hpp"
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

static bool CanDrain(QueryResult &result) {
	if (result.HasError()) {
		return false;
	}
	if (result.GetStatementProperties().result_eagerness == ResultEagerness::FORCED) {
		return false;
	}
	if (!result.HasBufferedData()) {
		return false;
	}
	return result.GetBufferedData().Lifetime() != ResultLifetime::RETAINED;
}

RArrowChunkSource::RArrowChunkSource(duckdb::unique_ptr<QueryResult> result_p) : owned_result(std::move(result_p)) {
	if (!owned_result) {
		throw InvalidInputException("Attempting to export a query result that does not exist as an Arrow stream");
	}
	client_properties = owned_result->client_properties;
	types = owned_result->GetTypes();
	names = IdentifiersToStrings(owned_result->GetNames());
	if (CanDrain(*owned_result)) {
		stream_result = make_uniq<QueryResultStream<>>(std::move(owned_result));
	} else {
		result = owned_result.get();
	}
	Initialize();
}

RArrowChunkSource::RArrowChunkSource(QueryResult &result_p) : result(&result_p) {
	client_properties = result_p.client_properties;
	types = result_p.GetTypes();
	names = IdentifiersToStrings(result_p.GetNames());
	Initialize();
}

void RArrowChunkSource::Initialize() {
	if (client_properties.client_context) {
		extension_types = ArrowTypeExtensionData::GetExtensionTypes(*client_properties.client_context, types);
	}
}

bool RArrowChunkSource::LoadNextChunk() {
	offset = 0;
	current_chunk = nullptr;
	if (finished) {
		return false;
	}
	if (stream_result) {
		// A stream ended by another statement records that as its error when polled
		if (stream_result->Poll() == QueryResultState::EXECUTION_ERROR) {
			finished = true;
			stream_result->GetErrorObject().Throw();
		}
		if (!stream_result->IsOpen()) {
			finished = true;
			return false;
		}
		current_chunk = stream_result->Fetch();
		if (!current_chunk && stream_result->HasError()) {
			finished = true;
			stream_result->GetErrorObject().Throw();
		}
	} else {
		current_chunk = result->Fetch();
		if (result->HasError()) {
			finished = true;
			result->GetErrorObject().Throw();
		}
	}
	if (!current_chunk || current_chunk->size() == 0) {
		finished = true;
		current_chunk = nullptr;
		return false;
	}
	return true;
}

idx_t RArrowChunkSource::FetchArray(idx_t batch_size, ArrowArray &out) {
	ArrowAppender appender(types, batch_size, client_properties, extension_types);
	idx_t count = 0;
	while (count < batch_size) {
		if (!current_chunk || offset >= current_chunk->size()) {
			if (!LoadNextChunk()) {
				break;
			}
		}
		auto to_append = MinValue(batch_size - count, current_chunk->size() - offset);
		appender.Append(*current_chunk, offset, offset + to_append, current_chunk->size());
		offset += to_append;
		count += to_append;
	}
	if (count > 0) {
		out = appender.Finalize();
	} else {
		out.release = nullptr;
	}
	return count;
}

void RArrowChunkSource::FetchSchema(ArrowSchema &out) {
	ArrowConverter::ToArrowSchema(&out, types, names, client_properties);
}

RResultArrowStream::RResultArrowStream(duckdb::unique_ptr<QueryResult> result, idx_t batch_size_p)
    : source(std::move(result)), batch_size(batch_size_p) {
	if (batch_size == 0) {
		throw InvalidInputException("Approximate Batch Size of Record Batch MUST be higher than 0");
	}
	stream.get_schema = GetSchema;
	stream.get_next = GetNext;
	stream.get_last_error = GetLastError;
	stream.release = Release;
	stream.private_data = this;
}

int RResultArrowStream::GetSchema(ArrowArrayStream *stream, ArrowSchema *out) {
	if (!stream->release) {
		return -1;
	}
	out->release = nullptr;
	auto my_stream = reinterpret_cast<RResultArrowStream *>(stream->private_data);
	try {
		my_stream->source.FetchSchema(*out);
	} catch (std::exception &e) {
		my_stream->last_error = ErrorData(e);
		return -1;
	}
	return 0;
}

int RResultArrowStream::GetNext(ArrowArrayStream *stream, ArrowArray *out) {
	if (!stream->release) {
		return -1;
	}
	auto my_stream = reinterpret_cast<RResultArrowStream *>(stream->private_data);
	try {
		my_stream->source.FetchArray(my_stream->batch_size, *out);
	} catch (std::exception &e) {
		my_stream->last_error = ErrorData(e);
		return -1;
	}
	return 0;
}

const char *RResultArrowStream::GetLastError(ArrowArrayStream *stream) {
	if (!stream->release) {
		return "stream was released";
	}
	auto my_stream = reinterpret_cast<RResultArrowStream *>(stream->private_data);
	return my_stream->last_error.Message().c_str();
}

// Owned by the wrapper around it, which never releases it through the callback
void RResultArrowStream::Release(ArrowArrayStream *stream) {
	if (stream) {
		stream->release = nullptr;
	}
}

static bool FetchArrowChunk(RArrowChunkSource &source, AppendableRList &batches_list, ArrowArray &arrow_data,
                            ArrowSchema &arrow_schema, SEXP batch_import_from_c, SEXP arrow_namespace,
                            idx_t chunk_size) {
	auto count = source.FetchArray(chunk_size, arrow_data);
	if (count == 0) {
		return false;
	}
	source.FetchSchema(arrow_schema);
	batches_list.PrepAppend();
	batches_list.Append(cpp11::safe[Rf_eval](batch_import_from_c, arrow_namespace));
	return true;
}

// Every entry point that takes a query result asks this first: the pointer may have been released.
static void CheckQueryResult(const duckdb::rqry_eptr_t &qry_res, const char *context) {
	if (!qry_res || !qry_res.get()) {
		rapi_error_with_context(context, "Invalid query result");
	}
}

// Turn a DuckDB result set into an Arrow Table
[[cpp11::register]] SEXP rapi_execute_arrow(duckdb::rqry_eptr_t qry_res, int chunk_size) {
	CheckQueryResult(qry_res, "rapi_execute_arrow");
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

	RArrowChunkSource source(*result);
	while (FetchArrowChunk(source, batches_list, arrow_data, arrow_schema, batch_import_from_c, arrow_namespace,
	                       chunk_size)) {
	}

	SET_LENGTH(batches_list.the_list, batches_list.size);
	ArrowConverter::ToArrowSchema(&arrow_schema, result->GetTypes(), IdentifiersToStrings(result->GetNames()),
	                              result->client_properties);
	cpp11::sexp schema_arrow_obj(cpp11::safe[Rf_eval](schema_import_from_c, arrow_namespace));

	// create arrow::Table
	cpp11::sexp from_record_batches(
	    Rf_lang3(RStrings::get().Table__from_record_batches_sym, batches_list.the_list, schema_arrow_obj));
	return cpp11::safe[Rf_eval](from_record_batches, arrow_namespace);
}

static duckdb::shared_ptr<ClientContext> KeepContext(QueryResult &result) {
	auto context = result.client_properties.client_context;
	return context ? context->shared_from_this() : nullptr;
}

RArrowArrayStreamWrapper::RArrowArrayStreamWrapper(duckdb::unique_ptr<QueryResult> result, idx_t batch_size)
    : context(KeepContext(*result)), engine(std::move(result), batch_size) {
	stream.get_schema = GetSchema;
	stream.get_next = GetNext;
	stream.get_last_error = GetLastError;
	stream.release = Release;
	stream.private_data = this;
}

// This engine has one query result type and a separate stream drained from it, and the stream records
// an invalidation as an interrupt of its own: `Poll()` reports a stream that another statement ended as
// EXECUTION_ERROR, where a stream read to the end reports its terminal state
// (vendored src/duckdb/src/main/query_result_stream.cpp).
bool RArrowArrayStreamWrapper::Invalidated() {
	auto stream_result = engine.source.StreamResult();
	if (!stream_result) {
		return false;
	}
	if (stream_result->Poll() != QueryResultState::EXECUTION_ERROR) {
		return false;
	}
	return stream_result->GetErrorType() == ExceptionType::INTERRUPT;
}

int RArrowArrayStreamWrapper::ReportInvalidated() {
	last_error = ErrorData(ExceptionType::INVALID_INPUT,
	                       "The query result was invalidated by another statement on its connection "
	                       "before it was read to the end. "
	                       "Read it to the end first, or run the other statement on a separate connection.");
	// A failing callback of the Arrow C stream interface returns an errno-compatible code, not the engine's -1
	// (https://arrow.apache.org/docs/format/CStreamInterface.html).
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
	// The Arrow C data interface requires a release callback to mark the struct released by nulling `release`,
	// as the engine's own callbacks do.
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
	CheckQueryResult(qry_res, "rapi_fetch_arrow_stream_into");
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
		wrapper->engine.batch_size = chunk_size;
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

// Write the Arrow schema of a query result into the nanoarrow-owned struct behind `schema_xptr`,
// from the columns the result keeps: available before the first fetch,
// and after the result has been read to the end or handed over.
[[cpp11::register]] void rapi_arrow_schema(duckdb::rqry_eptr_t qry_res, cpp11::sexp schema_xptr) {
	CheckQueryResult(qry_res, "rapi_arrow_schema");
	if (TYPEOF(schema_xptr.data()) != EXTPTRSXP) {
		rapi_error_with_context("rapi_arrow_schema", "Expected an external pointer for schema");
	}
	auto out = reinterpret_cast<ArrowSchema *>(R_ExternalPtrAddr(schema_xptr.data()));
	if (out == nullptr || out->release != nullptr) {
		rapi_error_with_context("rapi_arrow_schema", "Schema pointer is NULL or already initialized");
	}

	try {
		ArrowConverter::ToArrowSchema(out, qry_res->types, qry_res->names, qry_res->client_properties);
	} catch (std::exception &e) {
		rapi_error_with_context("rapi_arrow_schema", ErrorData(e));
	}
}

// Fetch one Arrow chunk from the streaming query result into the nanoarrow-owned struct behind `array_xptr`,
// typically from `nanoarrow::nanoarrow_allocate_array()`.
// Returns TRUE when a chunk was fetched, FALSE when the stream is exhausted.
[[cpp11::register]] bool rapi_fetch_arrow_array(duckdb::rqry_eptr_t qry_res, cpp11::sexp array_xptr, int chunk_size) {
	CheckQueryResult(qry_res, "rapi_fetch_arrow_array");
	if (chunk_size <= 0) {
		rapi_error_with_context("rapi_fetch_arrow_array", "Chunk Size must be higher than 0");
	}
	if (TYPEOF(array_xptr.data()) != EXTPTRSXP) {
		rapi_error_with_context("rapi_fetch_arrow_array", "Expected an external pointer for array");
	}

	auto out_array = reinterpret_cast<ArrowArray *>(R_ExternalPtrAddr(array_xptr.data()));
	if (out_array == nullptr) {
		rapi_error_with_context("rapi_fetch_arrow_array", "Array pointer is NULL");
	}

	if (!qry_res->stream_wrapper) {
		if (!qry_res->result) {
			rapi_error_with_context("rapi_fetch_arrow_array", "Result has already been consumed");
		}
		qry_res->stream_wrapper = make_uniq<RArrowArrayStreamWrapper>(std::move(qry_res->result), chunk_size);
	}
	// The wrapper outlives the call that created it, and each call asks for its own batch size.
	qry_res->stream_wrapper->engine.batch_size = chunk_size;

	auto &stream = qry_res->stream_wrapper->stream;
	if (stream.get_next(&stream, out_array) != 0) {
		rapi_error_with_context("rapi_fetch_arrow_array", stream.get_last_error(&stream));
	}
	if (out_array->release == nullptr) {
		// Read to the end: let go of the result, which for a materialized one still holds all its rows.
		// The columns that the schema and the empty batch need stay in the query result.
		qry_res->stream_wrapper.reset();
		return false;
	}
	return true;
}

// Write a zero-length Arrow array for the columns of a query result into the nanoarrow-owned struct behind
// `array_xptr`: the batch a drained result answers with (handbook/usage/integrations/README.md).
// The engine's converter builds it from an empty chunk, so it has the layout of every batch before it.
[[cpp11::register]] void rapi_arrow_empty_array(duckdb::rqry_eptr_t qry_res, cpp11::sexp array_xptr) {
	CheckQueryResult(qry_res, "rapi_arrow_empty_array");
	if (TYPEOF(array_xptr.data()) != EXTPTRSXP) {
		rapi_error_with_context("rapi_arrow_empty_array", "Expected an external pointer for array");
	}
	auto out = reinterpret_cast<ArrowArray *>(R_ExternalPtrAddr(array_xptr.data()));
	if (out == nullptr || out->release != nullptr) {
		rapi_error_with_context("rapi_arrow_empty_array", "Array pointer is NULL or already initialized");
	}

	try {
		auto &context = *qry_res->client_properties.client_context;
		DataChunk empty;
		empty.Initialize(Allocator::DefaultAllocator(), qry_res->types);
		ArrowConverter::ToArrowArray(empty, out, qry_res->client_properties,
		                             ArrowTypeExtensionData::GetExtensionTypes(context, qry_res->types));
	} catch (std::exception &e) {
		rapi_error_with_context("rapi_arrow_empty_array", ErrorData(e));
	}
}

// Let go of a query result when its R result is cleared.
// A streaming result not read to the end keeps its query, with the pipeline and the rows it has buffered,
// active on the connection until the next statement there cleans it up,
// so this ends the query the same way (handbook/usage/memory/reading/README.md).
// This engine ends it on destruction, so dropping the handles is all it takes
// (vendored src/duckdb/src/main/query_result.cpp, src/main/query_result_stream.cpp).
// A stream that dbFetchArrow() has handed over is no longer here, and keeps its query.
[[cpp11::register]] void rapi_release_arrow_result(duckdb::rqry_eptr_t qry_res) {
	if (!qry_res || !qry_res.get()) {
		return;
	}
	qry_res->stream_wrapper.reset();
	qry_res->result.reset();
}

// Turn a DuckDB result set into an RecordBatchReader
[[cpp11::register]] SEXP rapi_record_batch(duckdb::rqry_eptr_t qry_res, int chunk_size) {
	CheckQueryResult(qry_res, "rapi_record_batch");
	if (!qry_res->result) {
		rapi_error_with_context("rapi_record_batch", "Result has already been consumed");
	}
	// somewhat dark magic below
	cpp11::function getNamespace = RStrings::get().getNamespace_sym;
	cpp11::sexp arrow_namespace(getNamespace(RStrings::get().arrow_str));

	// The wrapper owns the result from here on. arrow's ImportRecordBatchReader
	// takes the stream and frees both through stream.release when the reader is
	// collected; only a failing import below leaks it (handbook/usage/memory/reading/README.md).
	// Unlike the engine's own wrapper, it keeps the client context alive for a reader that outlives the connection.
	auto result_stream = new RArrowArrayStreamWrapper(std::move(qry_res->result), chunk_size);

	cpp11::sexp stream_ptr_sexp(
	    Rf_ScalarReal(static_cast<double>(reinterpret_cast<uintptr_t>(&result_stream->stream))));
	cpp11::sexp record_batch_reader(Rf_lang2(RStrings::get().ImportRecordBatchReader_sym, stream_ptr_sexp));
	return cpp11::safe[Rf_eval](record_batch_reader, arrow_namespace);
}
