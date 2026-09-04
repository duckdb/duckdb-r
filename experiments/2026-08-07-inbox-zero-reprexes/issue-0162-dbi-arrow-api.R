## duckdb-r#162 -- does the DBI Arrow API hand back Arrow, or a data frame?
library(duckdb)
packageVersion("duckdb")

con <- dbConnect(duckdb())

# Every DBI Arrow generic has a method (shipped in 1.5.4, #2347 and #2355)
grep("Arrow", as.character(methods(class = "duckdb_connection")), value = TRUE)

# A result is an Arrow stream, not a materialised data frame
stream <- dbGetQueryArrow(con, "SELECT i, i * 2 AS twice FROM range(3) t(i)")
class(stream)
as.data.frame(stream)

# ... and it is consumed chunk by chunk, so the whole result is never held
res <- dbSendQueryArrow(con, "SELECT i FROM range(1000000) t(i)")
chunks <- 0L
rows <- 0
while (!dbHasCompleted(res)) {
  chunk <- dbFetchArrowChunk(res)
  chunks <- chunks + 1L
  rows <- rows + chunk$length
}
dbClearResult(res)
c(chunks = chunks, rows = rows)

# The reporter's path: Parquet -> Arrow -> to_duckdb(), no data frame in between
library(arrow, warn.conflicts = FALSE)
tmpfile <- tempfile(fileext = ".parquet")
write_parquet(beaver1, tmpfile)
read_parquet(tmpfile, as_data_frame = FALSE) |>
  to_duckdb()

# The other direction, also without a data frame: Arrow table -> DuckDB table
dbWriteTableArrow(con, "beavers", arrow_table(beaver1))
dbReadTableArrow(con, "beavers") |>
  as_arrow_table()

dbDisconnect(con)
