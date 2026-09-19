/* Three ways to reach DBInstanceCache::GetInstanceInternal() with a cache entry
 * whose DuckDB handle is gone, through the C API only -- no DuckDB internals,
 * no container. Driven by run.sh; see README.md.
 *
 *   in-use-connection  a connection outlives the handle
 *   in-use-result      an unfinished result outlives both
 *   shutdown-race      200 rounds of releasing the handle on another thread
 */
#include "duckdb.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *PATH = "/tmp/duckdb-instance-cache-probe.db";

static void reopen(duckdb_instance_cache cache, const char *label) {
	duckdb_database db = NULL;
	char *err = NULL;
	printf("  %s: reopening ...\n", label);
	fflush(stdout);
	if (duckdb_get_or_create_from_cache(cache, PATH, &db, NULL, &err) == DuckDBError) {
		printf("  %s: refused: %s\n", label, err ? err : "(no message)");
		duckdb_free(err);
		return;
	}
	printf("  %s: reopened\n", label);
	duckdb_close(&db);
}

static void *release_handle(void *arg) {
	duckdb_close((duckdb_database *)arg);
	return NULL;
}

int main(int argc, char **argv) {
	const char *scenario = argc > 1 ? argv[1] : "in-use-connection";
	duckdb_instance_cache cache = duckdb_create_instance_cache();
	duckdb_database db = NULL;
	duckdb_connection con = NULL;
	char *err = NULL;

	printf("libduckdb %s, scenario %s\n", duckdb_library_version(), scenario);
	remove(PATH);

	if (strcmp(scenario, "shutdown-race") == 0) {
		const char *rounds_env = getenv("ROUNDS");
		int rounds = rounds_env ? atoi(rounds_env) : 200;
		int reopened = 0, refused = 0, i;
		for (i = 0; i < rounds; i++) {
			duckdb_instance_cache round = duckdb_create_instance_cache();
			duckdb_database first = NULL, second = NULL;
			pthread_t thread;
			duckdb_get_or_create_from_cache(round, PATH, &first, NULL, NULL);
			pthread_create(&thread, NULL, release_handle, &first);
			if (duckdb_get_or_create_from_cache(round, PATH, &second, NULL, NULL) == DuckDBError) {
				refused++;
			} else {
				reopened++;
				duckdb_close(&second);
			}
			pthread_join(thread, NULL);
			duckdb_destroy_instance_cache(&round);
		}
		printf("  reopened %d, refused %d (refused is a spurious error: nothing was in use)\n", reopened,
		       refused);
		duckdb_destroy_instance_cache(&cache);
		remove(PATH);
		return 0;
	}

	if (duckdb_get_or_create_from_cache(cache, PATH, &db, NULL, &err) == DuckDBError) {
		printf("  open failed: %s\n", err ? err : "(no message)");
		return 1;
	}
	duckdb_connect(db, &con);

	if (strcmp(scenario, "in-use-result") == 0) {
		/* A pending result holds the ClientContext, so the instance outlives both
		 * the connection and the handle, and no connection is registered. */
		duckdb_prepared_statement stmt = NULL;
		duckdb_pending_result pending = NULL;
		duckdb_prepare(con, "SELECT 42", &stmt);
		duckdb_pending_prepared(stmt, &pending);
		duckdb_disconnect(&con);
		duckdb_close(&db);
		reopen(cache, scenario);
		duckdb_destroy_pending(&pending);
		duckdb_destroy_prepare(&stmt);
	} else {
		/* The connection stays open across the release of the handle. */
		duckdb_close(&db);
		reopen(cache, scenario);
		duckdb_disconnect(&con);
	}

	duckdb_destroy_instance_cache(&cache);
	remove(PATH);
	return 0;
}
