# Streams the even numbers below 1,000,000 in batches of 10,000 rows on a new
# connection whose streaming buffer is `buffer`, reads `before` batches,
# collects garbage, and reads the rest.
# Returns the rows read and the progress callback's calls during each read
# after the collection, the read that returns NULL last.
# Handbook: handbook/usage/interactive/README.md
progress_stream_calls <- function(buffer, before) {
  calls <- 0L
  rlang::local_options(
    duckdb.progress_display = function(x) calls <<- calls + 1L
  )
  con <- local_con()
  dbExecute(con, "CREATE TABLE t AS SELECT i FROM range(1000000) t(i)")
  # One thread, so that only the reads run the engine: since
  # duckdb/duckdb@18e49b34a9 (#28761) a prepared execution, as
  # dbGetQueryArrow() submits it, streams from its submission on, and with
  # more threads the engine can finish the query before the first read.
  # The setting dies with the database local_con() creates for this call.
  dbExecute(con, "SET threads = 1")
  dbExecute(con, sprintf("SET max_streaming_buffer_size = '%s'", buffer))

  # getOption() hands the display a copy of the callback that nothing else
  # refers to, and the display is built here, where the query is submitted.
  stream <- dbGetQueryArrow(
    con,
    "SELECT i FROM t WHERE i % 2 = 0",
    chunk_size = 10000
  )
  rows <- 0
  for (k in seq_len(before)) {
    rows <- rows + stream$get_next()$length
  }

  # Collect, and reuse the cells a collected callback would have left behind.
  for (pass in 1:3) {
    invisible(gc())
    garbage <- lapply(1:50000, function(i) list(i))
  }

  per_read <- integer()
  repeat {
    calls <- 0L
    batch <- stream$get_next()
    per_read <- c(per_read, calls)
    if (is.null(batch)) {
      break
    }
    rows <- rows + batch$length
  }
  list(rows = rows, calls = per_read)
}
