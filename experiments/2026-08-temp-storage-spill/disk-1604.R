library(DBI)
packageVersion("duckdb")

# The scenario of duckdb/duckdb-r#1604: append a data.frame to a table of an
# on-disk database under a memory_limit, with the settings reported there.
dbdir <- file.path(tempdir(), "db.duckdb")
con <- dbConnect(duckdb::duckdb(), dbdir = dbdir)

dbExecute(con, "SET memory_limit = '3GB'")
dbExecute(con, "SET max_temp_directory_size = '20GB'")
dbExecute(con, "SET threads TO 1")
dbExecute(con, "SET preserve_insertion_order = false")

# Temporary storage is on, beside the database file (the engine's own default):
dbGetQuery(con, "SELECT current_setting('temp_directory') AS temp_directory")

# The reported data: 12,880,502 rows x 5 integer columns, ~257 MB.
n <- 12880502L
dat <- data.frame(
  a = seq_len(n),
  b = rev(seq_len(n)),
  c = seq_len(n) %% 1000L,
  d = seq_len(n) %/% 7L,
  e = seq_len(n) %% 33333L
)
format(object.size(dat), units = "MB")

# "insert a data.frame into existing database": create the table, then append.
dbWriteTable(con, "tbl", dat[0, ], overwrite = TRUE)
dbWriteTable(con, "tbl", dat, append = TRUE) # <- failed in #1604 under 3 GB
dbGetQuery(con, "SELECT count(*) AS n FROM tbl")

# Harder than reported: repeat the append with a memory_limit *below* the data
# size, so it can only succeed by offloading to temporary storage.
dbExecute(con, "SET memory_limit = '200MB'")
dbWriteTable(con, "tbl", dat, append = TRUE)
dbGetQuery(con, "SELECT count(*) AS n FROM tbl")

# Was the temporary directory used at any point?
dir.exists(paste0(dbdir, ".tmp"))

# Harder still: a full ~460 MB sort under the 200 MB limit.
dbExecute(con, "SET preserve_insertion_order = true")
dbExecute(
  con,
  "CREATE TABLE big_sort AS SELECT hash(i) AS h, i FROM range(30000000) t(i) ORDER BY h"
)
dbGetQuery(con, "SELECT count(*) AS n FROM big_sort")
dir.exists(paste0(dbdir, ".tmp"))

dbDisconnect(con)
