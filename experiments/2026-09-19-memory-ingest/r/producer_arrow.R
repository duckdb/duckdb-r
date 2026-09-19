# Producer for the Arrow-over-a-pipe route: fifty batches of a million rows as an IPC stream on stdout,
# generated as they are written, so the producer never holds the data whole either.
suppressMessages(library(arrow))
sch <- schema(a = float64(), b = float64())
w <- RecordBatchStreamWriter$create(FileOutputStream$create("/dev/stdout"), sch)
set.seed(1); for (i in 1:50) w$write_batch(record_batch(a = runif(1e6), b = runif(1e6)))
w$close()
