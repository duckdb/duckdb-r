#!/usr/bin/env python3
# Apply finding 1 (Arrow results stream) at landing position 1620, in the current worktree.
import re

def edit(p, pairs):
    s = open(p).read()
    for old, new in pairs:
        assert s.count(old) == 1, (p, old[:80])
        s = s.replace(old, new)
    open(p, 'w').write(s)

decl = open('/workspace/decl1856.txt').read()
decl = decl[:decl.index("// The engine's Arrow stream over")]
decl = decl.replace('QueryResultStream<>', 'QueryResultStream')
impl = open('/workspace/impl1856.txt').read().replace('QueryResultStream<>', 'QueryResultStream')
impl = impl.replace('void RResultArrowStream::Release(ArrowArrayStream *stream) {',
                    '// Owned by the wrapper around it, which never releases it through the callback\n'
                    'void RResultArrowStream::Release(ArrowArrayStream *stream) {')

# --- rapi.hpp ---
p = 'src/include/rapi.hpp'
s = open(p).read()
s = s.replace('#include "duckdb/common/arrow/result_arrow_wrapper.hpp"\n',
              '#include "duckdb/common/arrow/result_arrow_wrapper.hpp"\n#include "duckdb/main/query_result_stream.hpp"\n')
edit_pairs = [
    ('''	//! Whether a duckdb call is running R code right now
	static bool Active();
	//! Park a statement that cannot be destroyed where we are
	static void Defer(duckdb::unique_ptr<PreparedStatement> stmt);
	//! Destroy everything parked so far; a no-op while Active()
	static void Drain();
};''',
     '''	//! Whether a duckdb call is running R code right now
	static bool Active();
	//! Park an object that cannot be destroyed where we are:
	//! a statement, or a query result, which ends its query under the same lock
	template <class T>
	static void Defer(T object) {
		Park(duckdb::make_uniq<Parked<T>>(std::move(object)));
	}
	//! Destroy everything parked so far, in the order it was parked; a no-op while Active()
	static void Drain();

	struct ParkedBase {
		virtual ~ParkedBase() = default;
	};

private:
	template <class T>
	struct Parked : public ParkedBase {
		explicit Parked(T object_p) : object(std::move(object_p)) {
		}
		T object;
	};
	static void Park(duckdb::unique_ptr<ParkedBase> object);
};'''),
    ('''// The engine's Arrow stream over a query result, behind one that reports a streaming result''',
     decl + '''// The engine's Arrow stream over a query result, behind one that reports a streaming result'''),
    ('''	ResultArrowArrayStreamWrapper engine;''', '''	RResultArrowStream engine;'''),
    ('''client_properties(result->client_properties) {
	}

	// Declared first, so the context outlives everything that reads it.''',
     '''client_properties(result->client_properties) {
	}
	~RQueryResult();

	// Declared first, so the context outlives everything that reads it.'''),
]
for old, new in edit_pairs:
    assert s.count(old) == 1, (p, old[:80])
    s = s.replace(old, new)
open(p, 'w').write(s)

# --- arrow_export.cpp ---
p = 'src/arrow_export.cpp'
s = open(p).read()
s = s.replace('#include "duckdb/common/arrow/result_arrow_wrapper.hpp"\n',
              '#include "duckdb/common/arrow/arrow_appender.hpp"\n#include "duckdb/main/buffered_data/buffered_data.hpp"\n')
pairs = [
    ('''RArrowArrayStreamWrapper::RArrowArrayStreamWrapper(duckdb::shared_ptr<ClientContext> context_p,''',
     impl + '\n' + '''RArrowArrayStreamWrapper::RArrowArrayStreamWrapper(duckdb::shared_ptr<ClientContext> context_p,'''),
    ('''// This engine's Arrow stream reads a result it holds whole, with nothing another statement can end
// (vendored src/duckdb/src/common/arrow/arrow_wrapper.cpp), until duckdb/duckdb#25989 streams again.
bool RArrowArrayStreamWrapper::Invalidated() {
	return false;
}''',
     '''// This engine has one query result type and a separate stream drained from it, and the stream records
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
}'''),
]
for old, new in pairs:
    assert s.count(old) == 1, (p, old[:80])
    s = s.replace(old, new)
# The release callback parks a stream a finalizer frees inside a callback
old = re.search(r'void RArrowArrayStreamWrapper::Release\(ArrowArrayStream \*stream\) \{.*?\n\}\n', s, re.S).group(0)
new = old.replace('''	delete reinterpret_cast<RArrowArrayStreamWrapper *>(stream->private_data);
}''', '''	duckdb::unique_ptr<RArrowArrayStreamWrapper> wrapper(
	    reinterpret_cast<RArrowArrayStreamWrapper *>(stream->private_data));
	// A stream not read to its end ends its query under the client context lock,
	// which a finalizer run inside a callback must not take.
	if (RCallbackScope::Active()) {
		RCallbackScope::Defer(std::move(wrapper));
	}
}''')
assert new != old
s = s.replace(old, new)
open(p, 'w').write(s)

# --- statement.cpp ---
p = 'src/statement.cpp'
edit(p, [
    ('''vector<duckdb::unique_ptr<PreparedStatement>> &deferred_statements =
    *new vector<duckdb::unique_ptr<PreparedStatement>>();''',
     '''vector<duckdb::unique_ptr<RCallbackScope::ParkedBase>> &deferred_objects =
    *new vector<duckdb::unique_ptr<RCallbackScope::ParkedBase>>();'''),
    ('''void RCallbackScope::Defer(duckdb::unique_ptr<PreparedStatement> stmt) {
	deferred_statements.push_back(std::move(stmt));
}''',
     '''void RCallbackScope::Park(duckdb::unique_ptr<ParkedBase> object) {
	deferred_objects.push_back(std::move(object));
}'''),
    ('''	vector<duckdb::unique_ptr<PreparedStatement>> to_destroy;
	to_destroy.swap(deferred_statements);
	to_destroy.clear();
}''',
     '''	vector<duckdb::unique_ptr<ParkedBase>> to_destroy;
	to_destroy.swap(deferred_objects);
	for (auto &object : to_destroy) {
		object.reset();
	}
}'''),
    ('''} // namespace duckdb

[[cpp11::register]] void rapi_release(duckdb::stmt_eptr_t stmt) {''',
     '''// A query result not run to its end ends its query on destruction, which takes the client context lock.
// Parked in this order, the stream and the result go before the context they read.
RQueryResult::~RQueryResult() {
	if (RCallbackScope::Active()) {
		if (stream_wrapper) {
			RCallbackScope::Defer(std::move(stream_wrapper));
		}
		if (result) {
			RCallbackScope::Defer(std::move(result));
		}
		if (context) {
			RCallbackScope::Defer(std::move(context));
		}
	}
}

} // namespace duckdb

[[cpp11::register]] void rapi_release(duckdb::stmt_eptr_t stmt) {'''),
    ('static SEXP rapi_execute_impl(RStatement *stmt, const duckdb::ConvertOpts &convert_opts);',
     'static SEXP rapi_execute_impl(RStatement *stmt, const duckdb::ConvertOpts &convert_opts, bool allow_stream_result);'),
    ('''	cpp11::writable::list out;
	out.reserve(n_rows);
''',
     '''	// Streaming arrow results from the same prepared statement cannot coexist
	// (each execution ends the previous one's query). Materialize
	// per-row arrow results when binding multiple rows.
	bool allow_stream_result = arrow && allow_stream && n_rows == 1;

	cpp11::writable::list out;
	out.reserve(n_rows);
'''),
    ('cpp11::sexp res = rapi_execute_impl(stmt.get(), convert_opts);',
     'cpp11::sexp res = rapi_execute_impl(stmt.get(), convert_opts, allow_stream_result);'),
    ('static SEXP rapi_execute_impl(RStatement *stmt, const duckdb::ConvertOpts &convert_opts) {',
     'static SEXP rapi_execute_impl(RStatement *stmt, const duckdb::ConvertOpts &convert_opts, bool allow_stream_result) {'),
    ('''	auto generic_result = stmt->stmt->Execute(stmt->parameters);
''',
     '''	// A streamed result is submitted, and runs as it is read. Only a SELECT that returns rows streams,
	// read from the statement as written, because a prepared execution reports the EXECUTE that runs it;
	// any other is run to completion here, as the engine's own ADBC driver does
	// (ExecuteArrow() in the vendored src/common/adbc/adbc.cpp).
	duckdb::unique_ptr<QueryResult> generic_result;
	if (allow_stream_result) {
		generic_result = stmt->stmt->Submit(stmt->parameters);
		auto &properties = stmt->stmt->GetStatementProperties();
		bool streams = stmt->stmt->GetStatementType() == StatementType::SELECT_STATEMENT &&
		               properties.return_type == StatementReturnType::QUERY_RESULT;
		if (!generic_result->HasError() && !streams) {
			generic_result->Complete();
		}
	} else {
		generic_result = stmt->stmt->Execute(stmt->parameters);
	}
'''),
    ('''	return rapi_execute_impl(stmt.get(), convert_opts);
}''',
     '''	bool allow_stream_result = convert_opts.arrow == ConvertOpts::ArrowConversion::ENABLED &&
	                           convert_opts.allow_stream_result == ConvertOpts::AllowStreamResult::ENABLED;
	return rapi_execute_impl(stmt.get(), convert_opts, allow_stream_result);
}'''),
])
print("applied")
