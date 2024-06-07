.Call(duckdb:::duckdb_load_library, system.file(c("inst", "libduckdb"), package="duckdb"))
print(.Call(duckdb:::duckdb_library_version))
database <- .Call(duckdb:::duckdb_database_new)
.Call(duckdb:::duckdb_open,":memory:", database)
connection <- .Call(duckdb:::duckdb_connection_new)
.Call(duckdb:::duckdb_connect, database, connection)

prepared_statement <- .Call(duckdb:::duckdb_prepared_statement_new)
.Call(duckdb:::duckdb_prepare, connection, "SELECT range::INTEGER my_range FROM range(?)", prepared_statement)

.Call(duckdb:::duckdb_bind_int32, prepared_statement, as.numeric(1), as.integer(100))

result <- .Call(duckdb:::duckdb_result_new)
.Call(duckdb:::duckdb_execute_prepared, prepared_statement, result)

for (col_idx in as.numeric(seq(0, .Call(duckdb:::duckdb_column_count, result)-1)) ){
    print(.Call(duckdb:::duckdb_column_name, result, col_idx))
}
while (TRUE) {
    chunk =  .Call(duckdb:::duckdb_fetch_chunk, result);
        n = .Call(duckdb:::duckdb_data_chunk_get_size, chunk)
        if (n == 0) { # empty chunk means end of stream
            break;
        }

        # chunk column count needs to be equivalent to result set column count
        stopifnot(identical(.Call(duckdb:::duckdb_data_chunk_get_column_count, chunk), .Call(duckdb:::duckdb_column_count, result)))

        for (col_idx in as.numeric(seq(0, .Call(duckdb:::duckdb_column_count, result)-1)) ){
            vector <- .Call(duckdb:::duckdb_data_chunk_get_vector, chunk, col_idx)

            type <- .Call(duckdb:::duckdb_vector_get_column_type, vector)
            type_id <- .Call(duckdb:::duckdb_get_type_id, type)

            if(type_id == duckdb:::duckdb_type_enum$DUCKDB_TYPE_INTEGER) {
                validity <- .Call(duckdb:::duckdb_vector_get_validity, vector)
                # TODO: maybe we do a native validity conversion here
                # could possibly re-use a buffer (pass in logical(n)) to avoid allocation

                vector_data <-  .Call(duckdb:::duckdb_vector_get_data, vector)
                vector_data_raw <- .Call(duckdb:::duckdb_copy_buffer, vector_data, as.integer(n*4))
               res <- readBin(vector_data_raw, what='integer', n)
               print(res)
            }
        }
       .Call(duckdb:::duckdb_destroy_data_chunk, chunk);
    }

.Call(duckdb:::duckdb_destroy_result, result)
.Call(duckdb:::duckdb_destroy_prepare, prepared_statement)
.Call(duckdb:::duckdb_disconnect, connection)
.Call(duckdb:::duckdb_close, database)
