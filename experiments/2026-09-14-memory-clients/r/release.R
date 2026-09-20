# What frees an Arrow batch's memory, R side: dropping the nanoarrow object and collecting,
# releasing it explicitly, a second reference, a converted double column, a converted string
# column. One process, resident size (VmRSS) in MB at each step, the dev build.
# Usage: Rscript release.R
suppressMessages({library(DBI); library(duckdb)})
rss <- function() as.numeric(strsplit(grep("VmRSS", readLines("/proc/self/status"), value = TRUE), "\\s+")[[1]][2]) / 1024
step <- function(...) cat(sprintf("%s\n", paste(..., collapse = "")))
mb <- function(x) sprintf("%.0f", x)
con <- dbConnect(duckdb())
q <- "SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(20000000) t(i)"   # one 320 MB batch of doubles
qs <- "SELECT ('value-' || i)::VARCHAR AS s FROM range(10000000) t(i)"          # one batch of ten million strings

# A. Drop the object and collect: the finalizer runs the release callback in the first collection.
local({
  rs <- dbSendQueryArrow(con, q); on.exit(dbClearResult(rs))
  r0 <- rss(); ch <- dbFetchArrowChunk(rs, chunk_size = 2e7); r1 <- rss()
  rm(ch); r2 <- rss(); invisible(gc()); r3 <- rss(); invisible(gc()); r4 <- rss()
  step("A drop and collect: idle ", mb(r0), ", batch held ", mb(r1), ", after rm() ", mb(r2), ", after one gc() ", mb(r3), ", after a second ", mb(r4))
})
# B. Release explicitly: the memory returns at once, and the object is an invalid pointer.
local({
  rs <- dbSendQueryArrow(con, q); on.exit(dbClearResult(rs))
  r0 <- rss(); ch <- dbFetchArrowChunk(rs, chunk_size = 1e7); r1 <- rss()   # half the result, 160 MB
  nanoarrow::nanoarrow_pointer_release(ch); r2 <- rss()
  step("B release(): idle ", mb(r0), ", half-size batch held ", mb(r1), ", after release ", mb(r2), "; the object prints as ", format(ch))
  ch2 <- dbFetchArrowChunk(rs, chunk_size = 1e6)
  step("   the stream is unaffected: the next chunk has ", ch2$length, " rows")
  nanoarrow::nanoarrow_pointer_release(ch2)
})
# C. A second reference defeats collection, not release.
local({
  rs <- dbSendQueryArrow(con, q); on.exit(dbClearResult(rs))
  ch <- dbFetchArrowChunk(rs, chunk_size = 2e7); keep <- list(ch); r1 <- rss()
  rm(ch); invisible(gc()); r2 <- rss(); rm(keep); invisible(gc()); r3 <- rss()
  step("C second reference: batch held ", mb(r1), ", after rm() and gc() with the reference alive ", mb(r2), ", after dropping it and gc() ", mb(r3))
})
# D. Doubles are copied by as.data.frame(): the batch can go while the frame stays.
local({
  rs <- dbSendQueryArrow(con, q); on.exit(dbClearResult(rs))
  ch <- dbFetchArrowChunk(rs, chunk_size = 2e7); r1 <- rss(); df <- as.data.frame(ch); r2 <- rss()
  nanoarrow::nanoarrow_pointer_release(ch); r3 <- rss()
  step("D doubles: batch held ", mb(r1), ", frame converted ", mb(r2), " (column is ALTREP: ", nanoarrow:::is_nanoarrow_altrep(df$a), "), batch released with the frame kept ", mb(r3))
})
invisible(gc())
# E. Strings are converted lazily: the column keeps its buffers until it is materialized.
local({
  rs <- dbSendQueryArrow(con, qs); on.exit(dbClearResult(rs))
  r0 <- rss(); ch <- dbFetchArrowChunk(rs, chunk_size = 1e7); r1 <- rss(); df <- as.data.frame(ch); r2 <- rss()
  alt <- nanoarrow:::is_nanoarrow_altrep(df$s)
  nanoarrow::nanoarrow_pointer_release(ch); r3 <- rss(); invisible(gc()); r4 <- rss()
  ok <- identical(df$s[c(1, 1e7)], c("value-0", "value-9999999")); r5 <- rss()
  nanoarrow:::nanoarrow_altrep_force_materialize(df$s); r6 <- rss(); invisible(gc()); r7 <- rss()
  step("E strings: idle ", mb(r0), ", batch held ", mb(r1), ", frame converted ", mb(r2), " (column is ALTREP: ", alt, "), batch released ", mb(r3), ", gc() ", mb(r4),
       ", two values read correctly: ", ok, " ", mb(r5), ", column materialized ", mb(r6), ", gc() ", mb(r7))
})
dbDisconnect(con, shutdown = TRUE)
