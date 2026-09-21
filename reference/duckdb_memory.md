# Memory-efficient reading and writing

A result that fits comfortably in the database can still be too large
for R, and a data frame that fits in R can still be copied on its way
into the database. This page shows memory-efficient ways for reading and
writing:

- Memory limits

- Streamed reading via Arrow

- Registering a data frame for writing

The routes below keep R's share to one batch, or one data frame, at a
time. Follow these recipes to process datasets larger than memory.

## Set the limit where it takes effect

DuckDB and R allocate from two different budgets. The engine's memory is
bounded by `memory_limit` and can spill to disk; R's vectors are
unbounded and only spilled to the system swap space, if at all.

The engine's limit is set on the driver or on a live connection.

    library(DBI)
    con <- dbConnect(duckdb(config = list(memory_limit = "2GB")))
    # or, on a live connection:
    dbExecute(con, "SET memory_limit = '2GB'")

## Reading: stream, and release each batch

Reading via Arrow stream never holds the result whole. Execution starts
at
[`DBI::dbSendQueryArrow()`](https://dbi.r-dbi.org/reference/dbSendQueryArrow.html)
and pauses at a bounded buffer. Each
[`DBI::dbFetchArrowChunk()`](https://dbi.r-dbi.org/reference/dbFetchArrowChunk.html)
hands over one batch that can be converted using
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html). For best
results, release a batch immediately via
[`nanoarrow::nanoarrow_pointer_release()`](https://arrow.apache.org/nanoarrow/latest/r/reference/nanoarrow_pointer_is_valid.html);
[duckdb_result_arrow](https://r.duckdb.org/reference/duckdb_result_arrow-class.md)
says what the release does and what happens without it.

    rs <- dbSendQueryArrow(con, "SELECT * FROM huge")
    repeat {
      batch <- dbFetchArrowChunk(rs, chunk_size = 1e6)
      if (batch$length == 0) break
      df <- as.data.frame(batch)
      # ... consume df ...
      nanoarrow::nanoarrow_pointer_release(batch)
    }
    dbClearResult(rs)

## Writing: hand the data frame over, and let the engine scan it

[`DBI::dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
copies nothing on the R side: it registers the data frame as a view that
the engine scans in place, creates the table from that scan, and
unregisters.
[`DBI::dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
does the same into an existing table, so data that arrives in pieces is
appended piece by piece with the same cost.

    dbWriteTable(con, "t", df)        # one frame
    dbAppendTable(con, "t", next_df)  # or piece by piece

Where no table is needed at all,
[`duckdb_register()`](https://r.duckdb.org/reference/duckdb_register.md)
alone lets queries scan the frame with negligible overhead.

    duckdb_register(con, "df", df)
    dbGetQuery(con, "SELECT count(*) FROM df WHERE a > 0.5")

### Files: let the engine read them

DuckDB supports readers for various formats, bypassing R memory
entirely.

    dbExecute(con, "CREATE TABLE t AS SELECT * FROM read_parquet('data.parquet')")

### Arrow streams: append a batch at a time

Data that arrives as an Arrow stream, from a pipe, a socket or another
library's reader, goes in through
[`DBI::dbWriteTableArrow()`](https://dbi.r-dbi.org/reference/dbWriteTableArrow.html),
or
[`DBI::dbAppendTableArrow()`](https://dbi.r-dbi.org/reference/dbAppendTableArrow.html)
into an existing table. Both pull one batch on R's thread and append it
as a data frame.

    stream <- nanoarrow::read_nanoarrow(file("data.arrows", "rb"))
    dbWriteTableArrow(con, "t", stream)

## Measurements

The method, every other route, and the same measurements through the
Python, Node, Go and Rust clients are recorded in the repository:
[`experiments/2026-09-14-memory-clients/`](https://github.com/duckdb/duckdb-r/tree/main/experiments/2026-09-14-memory-clients)
for reading,
[`experiments/2026-09-19-memory-ingest/`](https://github.com/duckdb/duckdb-r/tree/main/experiments/2026-09-19-memory-ingest)
for writing.

## See also

[duckdb_result_arrow](https://r.duckdb.org/reference/duckdb_result_arrow-class.md)
for the Arrow result and what releases a batch,
[`duckdb_register()`](https://r.duckdb.org/reference/duckdb_register.md)
and
[`duckdb_register_arrow()`](https://r.duckdb.org/reference/duckdb_register_arrow.md)
for scanning R data in place,
[duckdb_storage](https://r.duckdb.org/reference/duckdb_storage.md) for
where the engine spills.
