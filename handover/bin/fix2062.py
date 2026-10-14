#!/usr/bin/env python3
# Apply finding 1's second stage at landing position 2062, where the engine starts refusing a statement while a
# result is open on the connection: the glue ends the connection's open Arrow results first.
import re

FIX = '/workspace/fix/'

def edit(p, pairs):
    s = open(p).read()
    for old, new in pairs:
        assert s.count(old) == 1, (p, old[:90])
        s = s.replace(old, new)
    open(p, 'w').write(s)

def between(text, start, end):
    i = text.index(start)
    j = text.index(end, i)
    return text[i:j]

fix_hpp = open(FIX + 'src/include/rapi.hpp').read()
fix_cpp = open(FIX + 'src/arrow_export.cpp').read()

# --- rapi.hpp ---
open_result = between(fix_hpp, '// A streamed result of the Arrow route holds', '// Pulls chunks from a query result')
edit('src/include/rapi.hpp', [
    ('// Pulls chunks from a query result', open_result + '// Pulls chunks from a query result'),
    ('class RArrowChunkSource {', 'class RArrowChunkSource : public ROpenResult {'),
    ('''	explicit RArrowChunkSource(duckdb::unique_ptr<QueryResult> result);
	explicit RArrowChunkSource(QueryResult &result);
''', '''	explicit RArrowChunkSource(duckdb::unique_ptr<QueryResult> result, bool invalidated = false);
	explicit RArrowChunkSource(QueryResult &result);
	~RArrowChunkSource() override;

	void EndForAnotherStatement() override;
'''),
    ('RResultArrowStream(duckdb::unique_ptr<QueryResult> result, idx_t batch_size);',
     'RResultArrowStream(duckdb::unique_ptr<QueryResult> result, idx_t batch_size, bool invalidated = false);'),
    ('''	                         idx_t batch_size);''', '''	                         idx_t batch_size, bool invalidated = false);'''),
    ('''struct RQueryResult {
	RQueryResult(duckdb::shared_ptr<ClientContext> context_p, duckdb::unique_ptr<QueryResult> result_p)''',
     '''struct RQueryResult : public ROpenResult {
	// A streamed result holds its connection's query open from here on, so it is tracked until it is handed on
	RQueryResult(duckdb::shared_ptr<ClientContext> context_p, duckdb::unique_ptr<QueryResult> result_p, bool streamed)'''),
    ('''client_properties(result->client_properties) {
	}
	~RQueryResult();
''', '''client_properties(result->client_properties) {
		if (streamed && context) {
			Track(context.get());
		}
	}

	~RQueryResult() override;

	void EndForAnotherStatement() override;
	//! Hands the result on, to a stream that tracks it from then on
	duckdb::unique_ptr<QueryResult> TakeResult() {
		Untrack();
		return std::move(result);
	}
'''),
])

# --- arrow_export.cpp ---
registry = between(fix_cpp, 'static constexpr const char *INVALIDATED_MESSAGE', 'RArrowChunkSource::RArrowChunkSource(duckdb::unique_ptr<QueryResult> result_p, bool invalidated_p)')
p = 'src/arrow_export.cpp'
s = open(p).read()
old_ctor = re.search(r'RArrowChunkSource::RArrowChunkSource\(duckdb::unique_ptr<QueryResult> result_p\) : owned_result\(std::move\(result_p\)\) \{\n.*?\n\}\n', s, re.S).group(0)
new_ctor = old_ctor.replace('RArrowChunkSource::RArrowChunkSource(duckdb::unique_ptr<QueryResult> result_p) : owned_result(std::move(result_p)) {',
                            'RArrowChunkSource::RArrowChunkSource(duckdb::unique_ptr<QueryResult> result_p, bool invalidated_p)\n    : owned_result(std::move(result_p)) {')
new_ctor = new_ctor.replace('''	client_properties = owned_result->client_properties;''', '''	invalidated = invalidated_p;
	client_properties = owned_result->client_properties;''')
assert '	if (CanDrain(*owned_result)) {' in new_ctor
new_ctor = new_ctor.replace('''	if (CanDrain(*owned_result)) {
		stream_result = make_uniq<QueryResultStream<>>(std::move(owned_result));''', '''	if (!invalidated && CanDrain(*owned_result)) {
		stream_result = make_uniq<QueryResultStream<>>(std::move(owned_result));
		if (client_properties.client_context) {
			Track(client_properties.client_context.get());
		}''')
assert 'Track(' in new_ctor
new_ctor += '''
RArrowChunkSource::~RArrowChunkSource() {
	Untrack();
}

void RArrowChunkSource::EndForAnotherStatement() {
	// A stream read to its end no longer holds the connection, and keeps reading as ended
	if (stream_result && stream_result->IsOpen()) {
		invalidated = true;
		stream_result->Close();
	}
}
'''
s = s.replace(old_ctor, registry + new_ctor)
pairs = [
    ('''RResultArrowStream::RResultArrowStream(duckdb::unique_ptr<QueryResult> result, idx_t batch_size_p)
    : source(std::move(result)), batch_size(batch_size_p) {''',
     '''RResultArrowStream::RResultArrowStream(duckdb::unique_ptr<QueryResult> result, idx_t batch_size_p, bool invalidated)
    : source(std::move(result), invalidated), batch_size(batch_size_p) {'''),
    ('''	if (!qry_res->result) {
		rapi_error_with_context("rapi_execute_arrow", "Result has already been consumed");
	}''', '''	if (!qry_res->result) {
		rapi_error_with_context("rapi_execute_arrow", "Result has already been consumed");
	}
	if (qry_res->Invalidated()) {
		rapi_error_with_context("rapi_execute_arrow", INVALIDATED_MESSAGE);
	}'''),
    ('''                                                   duckdb::unique_ptr<QueryResult> result, idx_t batch_size)
    : context(std::move(context_p)), engine(std::move(result), batch_size) {''',
     '''                                                   duckdb::unique_ptr<QueryResult> result, idx_t batch_size,
                                                   bool invalidated)
    : context(std::move(context_p)), engine(std::move(result), batch_size, invalidated) {'''),
    ('''bool RArrowArrayStreamWrapper::Invalidated() {
''', '''bool RArrowArrayStreamWrapper::Invalidated() {
	if (engine.source.Invalidated()) {
		return true;
	}
'''),
    ('''	last_error = ErrorData(ExceptionType::INVALID_INPUT,
	                       "The query result was invalidated by another statement on its connection "
	                       "before it was read to the end. "
	                       "Read it to the end first, or run the other statement on a separate connection.");''',
     '''	last_error = ErrorData(ExceptionType::INVALID_INPUT, INVALIDATED_MESSAGE);'''),
    ('''	qry_res->result.reset();''', '''	qry_res->TakeResult().reset();'''),
]
for old, new in pairs:
    assert s.count(old) == 1, (p, old[:90])
    s = s.replace(old, new)
n = s.count('std::move(qry_res->result), chunk_size)')
assert n == 3, n
s = s.replace('std::move(qry_res->result), chunk_size)', 'qry_res->TakeResult(), chunk_size, qry_res->Invalidated())')
open(p, 'w').write(s)

# --- statement.cpp ---
edit('src/statement.cpp', [
    ('''RQueryResult::~RQueryResult() {
	if (RCallbackScope::Active()) {''', '''RQueryResult::~RQueryResult() {
	Untrack();
	if (RCallbackScope::Active()) {'''),
    ('''} // namespace duckdb

[[cpp11::register]] void rapi_release(duckdb::stmt_eptr_t stmt) {''', '''void RQueryResult::EndForAnotherStatement() {
	if (result) {
		invalidated = true;
		result->Close();
	}
}

} // namespace duckdb

[[cpp11::register]] void rapi_release(duckdb::stmt_eptr_t stmt) {'''),
    ('''	if (!conn || !conn.get() || !conn->conn) {
		rapi_error_with_context("rapi_prepare", "Invalid connection");
	}
''', '''	if (!conn || !conn.get() || !conn->conn) {
		rapi_error_with_context("rapi_prepare", "Invalid connection");
	}
	EndOpenResults(*conn->conn->context);
'''),
    ('''	auto context = stmt->stmt->TryGetContext();
	ScopedInterruptHandler signal_handler(context);
''', '''	auto context = stmt->stmt->TryGetContext();
	if (context) {
		EndOpenResults(*context);
	}
	ScopedInterruptHandler signal_handler(context);
'''),
    ('''	duckdb::unique_ptr<QueryResult> generic_result;
	if (allow_stream_result) {''', '''	duckdb::unique_ptr<QueryResult> generic_result;
	bool streamed = false;
	if (allow_stream_result) {'''),
    ('''		if (!generic_result->HasError() && !streams) {
			generic_result->Complete();
		}''', '''		if (!generic_result->HasError()) {
			streamed = streams;
			if (!streamed) {
				generic_result->Complete();
			}
		}'''),
    ('make_uniq<RQueryResult>(context, std::move(generic_result));',
     'make_uniq<RQueryResult>(std::move(context), std::move(generic_result), streamed);'),
])

# --- the glue's other statements ---
p = 'src/relational.cpp'
s = open(p).read()
n = s.count('ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());')
s = re.sub(r'(\n(\t+))ScopedInterruptHandler signal_handler\(rel->rel->context->GetContext\(\)\);',
           r'\1EndOpenResults(*rel->rel->context->GetContext());\1ScopedInterruptHandler signal_handler(rel->rel->context->GetContext());', s)
old = re.search(r'\n(\t)return result_to_df\(rel->rel->Explain\(', s)
assert old
s = s[:old.start()] + '\n\tEndOpenResults(*rel->rel->context->GetContext());' + s[old.start():]
open(p, 'w').write(s)
print('relational sites', n)
edit('src/reltoaltrep.cpp', [
    ('''		ScopedInterruptHandler signal_handler(rel->context->GetContext());''',
     '''		EndOpenResults(*rel->context->GetContext());
		ScopedInterruptHandler signal_handler(rel->context->GetContext());'''),
])
p = 'src/register.cpp'
s = open(p).read()
n = s.count('	ScopedInterruptHandler signal_handler(conn->conn->context);')
assert n == 2, n
s = s.replace('	ScopedInterruptHandler signal_handler(conn->conn->context);',
              '	EndOpenResults(*conn->conn->context);\n	ScopedInterruptHandler signal_handler(conn->conn->context);')
open(p, 'w').write(s)
print('applied')
