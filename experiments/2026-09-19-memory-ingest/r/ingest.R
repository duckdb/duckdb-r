# The ingest scenarios, R side: one scenario per process, one CSV line out.
# Usage: Rscript ingest.R <image-label> <file|memory> <scenario>
args <- commandArgs(TRUE); image <- args[1]; target <- args[2]; scenario <- args[3]
stat <- function(key) { x <- readLines("/proc/self/status"); as.numeric(strsplit(x[grep(key, x)], "\\s+")[[1]][2]) / 1024 }
hwm <- function() stat("VmHWM")
# Writing 5 to clear_refs resets the kernel's peak-RSS counter to the current RSS, so the peak
# measured afterwards is the measured step's own, not the source frame's construction.
reset_peak <- function() writeLines("5", "/proc/self/clear_refs")
suppressMessages(library(DBI))
# ROWS scales the data: 50 million rows of two doubles are 800 MB; the chunked routes append a million rows at a time.
N <- as.numeric(Sys.getenv("ROWS", "50e6"))
dbdir <- if (target == "file") tempfile(fileext = ".duckdb") else ":memory:"
con <- dbConnect(duckdb::duckdb(), dbdir = dbdir); dbExecute(con, "SET memory_limit = '300MB'")
make_frame <- function(n = N) { set.seed(1); data.frame(a = runif(n), b = runif(n)) }
create <- function() dbExecute(con, "CREATE TABLE t (a DOUBLE, b DOUBLE)")
ctas <- function(from) dbExecute(con, paste0("CREATE TABLE t AS SELECT a, b FROM ", from))
base <- NA; t0 <- NA; rows <- NA
start <- function() { invisible(gc()); reset_peak(); base <<- stat("VmRSS"); t0 <<- Sys.time() }
count <- function() dbGetQuery(con, "SELECT count(*) AS n FROM t")$n
if (scenario == "frame_dbWriteTable") {
  df <- make_frame(); start(); dbWriteTable(con, "t", df); rows <- count()
} else if (scenario == "frame_dbAppendTable") {
  df <- make_frame(); create(); start(); dbAppendTable(con, "t", df); rows <- count()
} else if (scenario == "frame_register_only") {
  df <- make_frame(); start(); duckdb::duckdb_register(con, "src", df)
  rows <- dbGetQuery(con, "SELECT count(*) AS n, sum(a) AS s FROM src")$n
} else if (scenario == "frame_arrow_register") {
  df <- make_frame(); start(); tb <- arrow::as_arrow_table(df); duckdb::duckdb_register_arrow(con, "src", tb); ctas("src"); rows <- count()
} else if (scenario == "frame_nanoarrow_register") {
  df <- make_frame(); start()
  rdr <- arrow::as_record_batch_reader(nanoarrow::as_nanoarrow_array_stream(df))
  duckdb::duckdb_register_arrow(con, "src", rdr); ctas("src"); rows <- count()
} else if (scenario == "frame_nanoparquet_roundtrip") {
  df <- make_frame(); start(); f <- tempfile(fileext = ".parquet"); nanoparquet::write_parquet(df, f)
  ctas(sprintf("read_parquet('%s')", f)); rows <- count()
} else if (scenario == "chunks_dbAppendTable") {
  create(); start(); for (i in seq_len(N / 1e6)) dbAppendTable(con, "t", make_frame(1e6)); rows <- count()
} else if (scenario == "stream_stdin_csv") {
  create(); start(); dbExecute(con, "COPY t FROM '/dev/stdin' (FORMAT CSV, HEADER false)"); rows <- count()
} else if (scenario %in% c("stream_stdin_arrow", "stream_stdin_arrow_1thread")) {
  if (scenario == "stream_stdin_arrow_1thread") dbExecute(con, "SET threads = 1")
  start(); rdr <- arrow::as_record_batch_reader(nanoarrow::read_nanoarrow(file("stdin", "rb")))
  duckdb::duckdb_register_arrow(con, "src", rdr); ctas("src"); rows <- count()
} else if (scenario == "stream_stdin_arrow_dbAppendTableArrow") {
  # DBI's default: pulls one batch at a time on R's thread and appends each as a data frame.
  create(); start(); DBI::dbAppendTableArrow(con, "t", nanoarrow::read_nanoarrow(file("stdin", "rb"))); rows <- count()
} else if (startsWith(scenario, "dataset_arrow_to_duckdb")) {
  # What arrow::to_duckdb() does: the arrow package's dataset scanner reads the file, the engine ingests the stream.
  if (endsWith(scenario, "_1thread")) invisible(dbExecute(con, "SET threads = 1"))
  start(); duckdb::duckdb_register_arrow(con, "src", arrow::open_dataset("/data/src.parquet"))
  if (endsWith(scenario, "_count")) rows <- dbGetQuery(con, "SELECT count(*) AS n FROM src")$n else { ctas("src"); rows <- count() }
} else if (scenario == "file_read_parquet") {
  start(); ctas("read_parquet('/data/src.parquet')"); rows <- count()
} else if (scenario == "file_read_csv") {
  start(); ctas("read_csv('/data/src.csv')"); rows <- count()
} else if (scenario == "file_duckdb_read_csv") {
  start(); duckdb::duckdb_read_csv(con, "t", "/data/src.csv"); rows <- count()
} else if (scenario == "engine_generate") {
  start(); ctas(sprintf("(SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(%d) t(i))", as.integer(N))); rows <- count()
} else stop("unknown scenario ", scenario)
peak <- hwm()
cat(sprintf("r,%s,%s,%s,%d,%d,%d,%d,%.1f\n", image, scenario, target, as.integer(rows), round(base), round(peak), round(peak - base), as.numeric(Sys.time() - t0, units = "secs")))
dbDisconnect(con, shutdown = TRUE)
