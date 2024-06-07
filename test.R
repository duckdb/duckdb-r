.Call(duckdb:::duckdb_load_library, system.file(c("inst", "libduckdb"), package="duckdb"))
print(.Call(duckdb:::duckdb_library_version))
database <- .Call(duckdb:::duckdb_database_new)
.Call(duckdb:::duckdb_open,":memory:", database)
connection <- .Call(duckdb:::duckdb_connection_new)
.Call(duckdb:::duckdb_connect, database, connection)

prepared_statement <- .Call(duckdb:::duckdb_prepared_statement_new)
.Call(duckdb:::duckdb_prepare, connection, "FROM range(?)", prepared_statement)

.Call(duckdb:::duckdb_bind_int32, prepared_statement, as.numeric(1), as.integer(10000))

result <- .Call(duckdb:::duckdb_result_new)
.Call(duckdb:::duckdb_execute_prepared, prepared_statement, result)

for (col_idx in as.numeric(seq(0, .Call(duckdb:::duckdb_column_count, result)-1)) ){
    print(.Call(duckdb:::duckdb_column_name, result, col_idx))
}
while (TRUE) {
    chunk =  .Call(duckdb:::duckdb_fetch_chunk, result);
        n = .Call(duckdb:::duckdb_data_chunk_get_size, chunk)
        print(n)
        if (n == 0) { # empty chunk means end of stream
            break;
        }
       .Call(duckdb:::duckdb_destroy_data_chunk, chunk);

#         // loop over columns and interpret vector bytes
#         for (let col_idx = 0; col_idx < duckdb_native.duckdb_data_chunk_get_column_count(chunk); col_idx++) {
#             console.log(convert_vector(duckdb_native.duckdb_data_chunk_get_vector(chunk, col_idx), n));
#         }
    }

.Call(duckdb:::duckdb_destroy_result, result)
.Call(duckdb:::duckdb_destroy_prepare, prepared_statement)
.Call(duckdb:::duckdb_disconnect, connection)
.Call(duckdb:::duckdb_close, database)
