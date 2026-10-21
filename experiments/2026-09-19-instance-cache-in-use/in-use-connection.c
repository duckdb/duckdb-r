/* A connection outlives the last database handle.
 *
 * The cache entry is then alive with an expired handle, which
 * GetInstanceInternal() reads as a shutdown in flight -- but nothing is
 * shutting down, because the ClientContext behind the connection still holds
 * the DatabaseInstance. Unpatched, the reopen below never returns.
 *
 * Built and run by run.sh; stands on its own otherwise:
 *   cc in-use-connection.c -I<include> -L<lib> -lduckdb -o in-use-connection
 */
#include "duckdb.h"
#include <stdio.h>

static const char *PATH = "/tmp/duckdb-in-use-connection.db";

int main(void) {
	duckdb_instance_cache cache = duckdb_create_instance_cache();
	duckdb_database db = NULL, reopened = NULL;
	duckdb_connection con = NULL;
	char *err = NULL;

	printf("libduckdb %s\n", duckdb_library_version());
	remove(PATH);

	if (duckdb_get_or_create_from_cache(cache, PATH, &db, NULL, &err) == DuckDBError) {
		printf("  open failed: %s\n", err ? err : "(no message)");
		duckdb_free(err);
		return 1;
	}
	duckdb_connect(db, &con);
	printf("  opened and connected\n");

	duckdb_close(&db);
	printf("  released the handle, connection still open\n");

	printf("  reopening ...\n");
	fflush(stdout);
	if (duckdb_get_or_create_from_cache(cache, PATH, &reopened, NULL, &err) == DuckDBError) {
		printf("  refused: %s\n", err ? err : "(no message)");
		duckdb_free(err);
	} else {
		printf("  reopened\n");
		duckdb_close(&reopened);
	}

	duckdb_disconnect(&con);
	duckdb_destroy_instance_cache(&cache);
	remove(PATH);
	return 0;
}
