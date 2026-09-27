/* Two queries at once: what the engine allows on one context and on two, timed
 * from the client threads that call it, for a query that runs on one thread and
 * for one that uses every thread. Compiles against the vendored headers and
 * links the fast-path libduckdb, which carry the same commit. Driven by run.sh;
 * see README.md.
 *
 * ROWS sizes the single-threaded query (default 400000000) and TABLE_ROWS the
 * table the parallel one scans (default 150000000).
 */
#include "duckdb.hpp"

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <thread>

using namespace duckdb;
using steady = std::chrono::steady_clock;

static double Seconds(steady::time_point t0) {
	return std::chrono::duration<double>(steady::now() - t0).count();
}

static double TimeQuery(Connection &con, const std::string &query) {
	auto t0 = steady::now();
	auto result = con.Query(query);
	if (result->HasError()) {
		printf("  query failed: %s\n", result->GetError().c_str());
	}
	return Seconds(t0);
}

static double Sequential(Connection &a, Connection &b, const std::string &query) {
	auto t0 = steady::now();
	TimeQuery(a, query);
	TimeQuery(b, query);
	return Seconds(t0);
}

static double Concurrent(Connection &a, Connection &b, const std::string &query) {
	auto t0 = steady::now();
	std::thread ta([&]() { TimeQuery(a, query); });
	std::thread tb([&]() { TimeQuery(b, query); });
	ta.join();
	tb.join();
	return Seconds(t0);
}

static void Compare(Connection &a, Connection &b, const std::string &query) {
	for (int threads : {4, 1}) {
		a.Query("SET threads = " + std::to_string(threads));
		double one = TimeQuery(a, query);
		double sequential = Sequential(a, b, query);
		double two_contexts = Concurrent(a, b, query);
		double one_context = Concurrent(a, a, query);
		printf("  threads=%d: one query %.2fs | two, sequential %.2fs | two at once on two contexts %.2fs | "
		       "two at once on one context %.2fs\n",
		       threads, one, sequential, two_contexts, one_context);
	}
}

static std::string Env(const char *name, const char *fallback) {
	const char *value = getenv(name);
	return value ? value : fallback;
}

int main() {
	std::string rows = Env("ROWS", "400000000");
	std::string table_rows = Env("TABLE_ROWS", "150000000");
	std::string single = "SELECT sum(i * i) FROM range(" + rows + ") r(i)";
	std::string parallel = "SELECT sum(i * i) FROM big";

	DuckDB db(nullptr);
	Connection a(db), b(db);
	a.Query("CREATE TABLE big AS SELECT i FROM range(" + table_rows + ") r(i)");

	printf("== A query that runs on one thread: %s\n", single.c_str());
	Compare(a, b, single);
	printf("== A query that uses every thread: %s, %s rows\n", parallel.c_str(), table_rows.c_str());
	Compare(a, b, parallel);

	printf("== A stream parked on context a\n");
	a.Query("SET threads = 4");
	auto stream = a.SendQuery("SELECT i FROM big");
	auto first = stream->Fetch();
	printf("  first batch: %llu rows, stream type %s\n", (unsigned long long)first->size(),
	       stream->type == QueryResultType::STREAM_RESULT ? "streaming" : "materialized");
	auto t0 = steady::now();
	TimeQuery(b, parallel);
	printf("  the parallel query on context b meanwhile: %.2fs\n", Seconds(t0));
	auto next = stream->Fetch();
	printf("  a's stream afterwards: %s\n", next ? "yields" : "drained");
	auto other = a.Query("SELECT 1");
	if (other->HasError()) {
		printf("  a query on context a: %s\n", other->GetError().c_str());
	}
	try {
		next = stream->Fetch();
		if (stream->HasError()) {
			printf("  a's stream after a query on context a: %s\n", stream->GetError().c_str());
		} else {
			printf("  a's stream after a query on context a: %s\n", next ? "yields" : "drained");
		}
	} catch (std::exception &e) {
		printf("  a's stream after a query on context a: %s\n", e.what());
	}
	return 0;
}
