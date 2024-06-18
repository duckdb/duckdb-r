.Call(duckdb:::duckdb_load_library, system.file(c("inst", "libduckdb"), package="duckdb"))
print(.Call(duckdb:::duckdb_library_version))
database <- .Call(duckdb:::duckdb_database_new)
.Call(duckdb:::duckdb_open,":memory:", database)
connection <- .Call(duckdb:::duckdb_connection_new)
.Call(duckdb:::duckdb_connect, database, connection)

prepared_statement <- .Call(duckdb:::duckdb_prepared_statement_new)
.Call(duckdb:::duckdb_prepare, connection, "SELECT range::INTEGER FROM range(?)", prepared_statement)

.Call(duckdb:::duckdb_bind_int32, prepared_statement, as.numeric(1), as.integer(100000000))

result <- .Call(duckdb:::duckdb_result_new)
.Call(duckdb:::duckdb_execute_prepared, prepared_statement, result)
column_count <- .Call(duckdb:::duckdb_column_count, result)

types <- integer(column_count)

for (col_idx in as.numeric(seq(0, column_count-1)) ){
    print(.Call(duckdb:::duckdb_column_name, result, col_idx))
    types[col_idx+1] <- .Call(duckdb:::duckdb_column_type, result, col_idx)
}

# C struct decoding R style, for duckdb_string_t
sizeof_string_t <- 16L
duckdb_vector_size <- .Call(duckdb:::duckdb_vector_size)
start_offsets <- (c(0L : (duckdb_vector_size - 1L)) * sizeof_string_t)
sizes_offsets <- (rep(c(0L : (duckdb_vector_size - 1L)), each=4L) * sizeof_string_t) + rep.int(1L : 4L, duckdb_vector_size)
pointer_offsets <- (rep(c(0L : (duckdb_vector_size - 1L)), each=8L) * sizeof_string_t) + rep.int(9L : sizeof_string_t, duckdb_vector_size)

# always the same
column_count <- .Call(duckdb:::duckdb_column_count, result)
col_idxs <- as.numeric(seq.int(0L, column_count-1L))

system.time({
while (TRUE) {
    chunk =  .Call(duckdb:::duckdb_fetch_chunk, result);
    n = .Call(duckdb:::duckdb_data_chunk_get_size, chunk)
    if (n == 0) { # empty chunk means end of stream
        break;
    }

#     # chunk column count needs to be equivalent to result set column count
  #  stopifnot(identical(.Call(duckdb:::duckdb_data_chunk_get_column_count, chunk), .Call(duckdb:::duckdb_column_count, result)))

    for (col_idx in col_idxs){
        vector <- .Call(duckdb:::duckdb_data_chunk_get_vector, chunk, col_idx)
        vector_data <- .Call(duckdb:::duckdb_vector_get_data, vector)
            # TODO: maybe we do a native validity conversion here
            # could possibly re-use a buffer (pass in logical(n)) to avoid allocation
   # TODO
   #     validity <- .Call(duckdb:::duckdb_vector_get_validity, vector)

        type_id <- types[col_idx+1]

        if(type_id == duckdb:::duckdb_type_enum$DUCKDB_TYPE_INTEGER) {
            res <- readBin(.Call(duckdb:::duckdb_copy_buffer, vector_data, as.integer(n * 4L)), what='integer', n)
        } else if(type_id == duckdb:::duckdb_type_enum$DUCKDB_TYPE_VARCHAR) {
           vector_data_raw <- .Call(duckdb:::duckdb_copy_buffer, vector_data, as.integer(n * 16L))
           res <- character(n)
           string_lengths <- readBin(vector_data_raw[sizes_offsets], what="integer", n=n)
           string_inlined <- string_lengths <= 12L
           row_idxs <- seq.int(n)
           res <- NA

         if (any(string_inlined)) {
           inline_start_offsets <- start_offsets + 5L
           inline_lengths <- string_lengths
           inline_lengths[!string_inlined] <- 0L
           res <- vapply(row_idxs, \(row_idx)
            rawToChar(vector_data_raw[inline_start_offsets[[row_idx]]:(inline_start_offsets[[row_idx]]+inline_lengths[[row_idx]])])
           , character(1L))
            }
        if (any(!string_inlined)) {
           pointers <- readBin(vector_data_raw[pointer_offsets], what="numeric", n=n)
           res[!string_inlined] <- vapply(row_idxs[!string_inlined], \(row_idx)
                rawToChar(.Call(duckdb:::duckdb_copy_buffer, pointers[[row_idx]], string_lengths[[row_idx]]))
           , character(1L))
         }

       # print(res)
       }
    }
    # FIXME why does this break
     #.Call(duckdb:::duckdb_destroy_data_chunk, chunk);
    }
})
.Call(duckdb:::duckdb_destroy_result, result)
.Call(duckdb:::duckdb_destroy_prepare, prepared_statement)
.Call(duckdb:::duckdb_disconnect, connection)
.Call(duckdb:::duckdb_close, database)
warnings()