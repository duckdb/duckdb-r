.Call(duckdb:::duckdb_load_library, system.file(c("inst", "libduckdb"), package="duckdb"))
print(.Call(duckdb:::duckdb_library_version))
database <- .Call(duckdb:::duckdb_database_new)
.Call(duckdb:::duckdb_open,":memory:", database)
connection <- .Call(duckdb:::duckdb_connection_new)
.Call(duckdb:::duckdb_connect, database, connection)

prepared_statement <- .Call(duckdb:::duckdb_prepared_statement_new)
.Call(duckdb:::duckdb_prepare, connection, "SELECT ?::INTEGER", prepared_statement)

.Call(duckdb:::duckdb_bind_int32, prepared_statement, as.numeric(1), as.integer(42))

.Call(duckdb:::duckdb_destroy_prepare, prepared_statement)
.Call(duckdb:::duckdb_disconnect, connection)
.Call(duckdb:::duckdb_close, database)