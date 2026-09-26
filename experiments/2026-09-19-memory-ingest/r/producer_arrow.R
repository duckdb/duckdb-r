# Producer for the Arrow-over-a-pipe route: fifty batches of a million rows as an IPC stream on stdout,
# generated as they are written, so the producer never holds the data whole either.
# The sink is an R connection wrapped for arrow: arrow's own FileOutputStream on /dev/stdout fails
# with "lseek failed", because the stream writer aligns its messages by asking the sink where it is.
suppressMessages(library(arrow))
sch <- schema(a = float64(), b = float64())
sink <- arrow:::make_output_stream(file("/dev/stdout", "wb", raw = TRUE))
w <- RecordBatchStreamWriter$create(sink, sch)
n_batches <- as.numeric(Sys.getenv("ROWS", "50e6")) / 1e6
set.seed(1)
for (i in seq_len(n_batches)) {
  w$write_batch(record_batch(a = runif(1e6), b = runif(1e6)))
}
w$close()
sink$close()
