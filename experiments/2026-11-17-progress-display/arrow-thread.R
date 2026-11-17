# Reads one stream through one route, named as the first argument (get_next,
# as_arrow_table, write_parquet, write_dataset or collect), and prints how
# many calls the progress callback got and the last value it saw.
#
# arrow-thread.sh runs it once per mode under gdb, with DLIB naming the
# library that holds the duckdb under test, and writes arrow-thread.txt.
# Needs nanoarrow, arrow and dplyr (the collect mode uses dplyr).
#
# Handbook: handbook/usage/interactive/README.md

.libPaths(c(Sys.getenv("DLIB"), .libPaths()))
suppressMessages({
  library(duckdb)
  library(arrow)
})
mode <- commandArgs(TRUE)[1]
calls <- numeric()
options(duckdb.progress_display = function(x) calls <<- c(calls, x))
con <- dbConnect(duckdb())
invisible(dbExecute(con, "SET max_streaming_buffer_size = '16KiB'"))
q <- "SELECT i, i * 2 AS j FROM range(30000000) t(i) WHERE i % 3 = 0"
calls <- numeric()
stream <- dbGetQueryArrow(con, q)
cat("calls after dbGetQueryArrow:", length(calls), "\n")
n <- switch(
  mode,
  get_next = {
    n <- 0
    while (!is.null(b <- stream$get_next())) {
      n <- n + b$length
    }
    n
  },
  as_arrow_table = nrow(as_arrow_table(as_record_batch_reader(stream))),
  write_dataset = {
    d <- tempfile()
    write_dataset(as_record_batch_reader(stream), d)
    nrow(open_dataset(d))
  },
  write_parquet = {
    f <- tempfile()
    write_parquet(as_record_batch_reader(stream), f)
    nrow(read_parquet(f, as_data_frame = FALSE))
  },
  collect = nrow(dplyr::collect(dplyr::filter(
    as_record_batch_reader(stream),
    j >= 0
  )))
)
cat(
  "MODE",
  mode,
  "rows",
  n,
  "R callback calls",
  length(calls),
  "last",
  tail(calls, 1),
  "\n"
)
