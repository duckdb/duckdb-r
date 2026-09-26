/* An unfinished result outlives the connection and the last database handle.
 *
 * ~Connection deregisters from the ConnectionManager, so no connection is open
 * here -- but the pending result holds the ClientContext, which holds the
 * DatabaseInstance, so the cache entry stays alive with an expired handle.
 * This is the state that reaches R through an uncleared dbSendQuery() result.
 *
 * Built and run by run.sh; stands on its own otherwise:
 *   cc in-use-result.c -I<include> -L<lib> -lduckdb -o in-use-result
 */
#include "duckdb.h"
#include <stdio.h>

static const char *PATH = "/tmp/duckdb-in-use-result.db";

int main(void) {
	duckdb_instance_cache cache = duckdb_create_instance_cache();
	duckdb_database db = NULL, reopened = NULL;
	duckdb_connection con = NULL;
	duckdb_prepared_statement stmt = NULL;
	duckdb_pending_result pending = NULL;
	char *err = NULL;

	printf("libduckdb %s\n", duckdb_library_version());
	remove(PATH);

	if (duckdb_get_or_create_from_cache(cache, PATH, &db, NULL, &err) == DuckDBError) {
		printf("  open failed: %s\n", err ? err : "(no message)");
		duckdb_free(err);
		return 1;
	}
	duckdb_connect(db, &con);
	duckdb_prepare(con, "SELECT 42", &stmt);
	duckdb_pending_prepared(stmt, &pending);
	printf("  opened, with a result left unfinished\n");

	duckdb_disconnect(&con);
	duckdb_close(&db);
	printf("  released the connection and the handle, result still open\n");

	printf("  reopening ...\n");
	fflush(stdout);
	if (duckdb_get_or_create_from_cache(cache, PATH, &reopened, NULL, &err) == DuckDBError) {
		printf("  refused: %s\n", err ? err : "(no message)");
		duckdb_free(err);
	} else {
		printf("  reopened\n");
		duckdb_close(&reopened);
	}

	duckdb_destroy_pending(&pending);
	duckdb_destroy_prepare(&stmt);
	duckdb_destroy_instance_cache(&cache);
	remove(PATH);
	return 0;
}
