/* Stages the shutdown that is genuinely in flight, as tightly as the C++ API
 * allows: one thread releases the last handle while another asks the cache for
 * the same path. Nothing is in use, so every round must reopen.
 *
 * The C API cannot stage this -- duckdb_open_internal() builds a DBConfig and
 * sets duckdb_api before it reaches the cache, and the shutdown has finished by
 * then -- so this one reaches for the internal header, which the vendored tree
 * carries. Driven by run.sh; see README.md.
 */
#include "duckdb.hpp"
#include "duckdb/main/db_instance_cache.hpp"
#include <cstdio>
#include <cstdlib>
#include <thread>

using namespace duckdb;

int main() {
	const char *path = "/tmp/duckdb-shutdown-race-tight.db";
	const char *rounds_env = getenv("ROUNDS");
	int rounds = rounds_env ? atoi(rounds_env) : 200;
	int reopened = 0, refused = 0;

	for (int i = 0; i < rounds; i++) {
		remove(path);
		DBInstanceCache cache;
		DBConfig config;
		auto db = cache.GetOrCreateInstance(path, config, true);
		std::thread releaser([&db]() { db.reset(); });
		DBConfig config2;
		try {
			auto reopened_db = cache.GetOrCreateInstance(path, config2, true);
			reopened++;
		} catch (std::exception &) {
			refused++;
		}
		releaser.join();
		if ((i + 1) % 25 == 0) {
			printf("  round %d of %d\n", i + 1, rounds);
			fflush(stdout);
		}
	}
	remove(path);
	printf("  reopened %d, refused %d (a refusal is a false positive: nothing was in use)\n", reopened, refused);
	return 0;
}
