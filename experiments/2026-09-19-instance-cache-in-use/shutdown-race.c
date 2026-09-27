/* A shutdown that is genuinely in flight: one thread releases the last handle
 * while another asks the cache for the same path. Nothing is in use, so every
 * round must reopen -- a refusal here would be a false positive.
 *
 * Each round is a fresh cache and a fresh instance, so the cost is DuckDB
 * startup and teardown, about 20 ms a round on the machine this was written on.
 * The round counter is printed as it goes: a run that stops at a round is
 * wedged, a run still counting when its budget expires is only slow.
 *
 * ROUNDS sets the length (default 200). Built and run by run.sh; stands on its
 * own otherwise:
 *   cc shutdown-race.c -I<include> -L<lib> -lduckdb -lpthread -o shutdown-race
 */
#include "duckdb.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

static const char *PATH = "/tmp/duckdb-shutdown-race.db";

static void *release_handle(void *handle) {
	duckdb_close((duckdb_database *)handle);
	return NULL;
}

int main(void) {
	const char *rounds_env = getenv("ROUNDS");
	int rounds = rounds_env ? atoi(rounds_env) : 200;
	int reopened = 0, refused = 0, i;

	printf("libduckdb %s, %d rounds\n", duckdb_library_version(), rounds);
	remove(PATH);

	for (i = 0; i < rounds; i++) {
		duckdb_instance_cache cache = duckdb_create_instance_cache();
		duckdb_database first = NULL, second = NULL;
		pthread_t releaser;

		duckdb_get_or_create_from_cache(cache, PATH, &first, NULL, NULL);
		pthread_create(&releaser, NULL, release_handle, &first);
		if (duckdb_get_or_create_from_cache(cache, PATH, &second, NULL, NULL) == DuckDBError) {
			refused++;
		} else {
			reopened++;
			duckdb_close(&second);
		}
		pthread_join(releaser, NULL);
		duckdb_destroy_instance_cache(&cache);

		if ((i + 1) % 25 == 0) {
			printf("  round %d of %d\n", i + 1, rounds);
			fflush(stdout);
		}
	}

	printf("  reopened %d, refused %d (a refusal is a false positive: nothing was in use)\n", reopened, refused);
	remove(PATH);
	return refused ? 1 : 0;
}
