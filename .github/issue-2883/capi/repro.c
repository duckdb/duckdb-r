#include <stdio.h>
#include <stdint.h>
typedef struct _duckdb_database { void *internal_ptr; } *duckdb_database;
typedef struct _duckdb_connection { void *internal_ptr; } *duckdb_connection;
typedef struct _duckdb_config { void *internal_ptr; } *duckdb_config;
typedef struct { void *deprecated_columns; uint64_t a, b, c; char *deprecated_error_message; void *internal_data; } duckdb_result;
int duckdb_create_config(duckdb_config *); int duckdb_set_config(duckdb_config, const char *, const char *);
int duckdb_open_ext(const char *, duckdb_database *, duckdb_config, char **);
int duckdb_connect(duckdb_database, duckdb_connection *);
int duckdb_query(duckdb_connection, const char *, duckdb_result *);
char *duckdb_value_varchar(duckdb_result *, uint64_t, uint64_t);
const char *duckdb_result_error(duckdb_result *); void duckdb_destroy_result(duckdb_result *);
static void run(duckdb_connection c, const char *q) {
  duckdb_result r; if (duckdb_query(c, q, &r)) printf("%-60s ERROR %s\n", q, duckdb_result_error(&r));
  else printf("%-60s %s\n", q, duckdb_value_varchar(&r, 0, 0));
  duckdb_destroy_result(&r);
}
int main(int argc, char **argv) {
  duckdb_config cfg; duckdb_database db; duckdb_connection con; char *err = NULL;
  duckdb_create_config(&cfg);
  duckdb_set_config(cfg, "extension_directory", argv[1]);
  duckdb_set_config(cfg, "autoload_known_extensions", "true");
  duckdb_set_config(cfg, "autoinstall_known_extensions", "false");
  if (duckdb_open_ext(NULL, &db, cfg, &err)) { printf("open failed: %s\n", err); return 1; }
  duckdb_connect(db, &con);
  const char *q = argc > 2 ? argv[2] : "SELECT (epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00') + 2.5)::VARCHAR";
  run(con, "SELECT loaded::VARCHAR FROM duckdb_extensions() WHERE extension_name='icu'");
  run(con, q); run(con, q);
  return 0;
}
