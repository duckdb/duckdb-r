## duckdb-r#1604 -- inserting 12.88M x 5 integers under a memory limit,
## and the question the title asks: is the temporary directory used?
library(duckdb)
packageVersion("duckdb")

n <- 12880502L
data <- data.frame(
  a = seq_len(n),
  b = rev(seq_len(n)),
  c = seq_len(n) %% 1000L,
  d = seq_len(n) %% 7L,
  e = seq_len(n) %% 13L
)
format(object.size(data), units = "MB")

# The reporter's setup: the database file is named on dbConnect()
db <- tempfile(fileext = ".duckdb")
db_conn <- dbConnect(duckdb::duckdb(), dbdir = db)
dbExecute(db_conn, "SET memory_limit = '3GB';")
dbExecute(db_conn, "SET max_temp_directory_size = '20GB';")
dbExecute(db_conn, "SET threads TO 1;")
dbExecute(db_conn, "SET preserve_insertion_order=false;")

# The insert itself is fine at their limit, and stays fine well below it
dbWriteTable(db_conn, "tbl", data)
dbGetQuery(db_conn, "SELECT count(*) AS n FROM tbl")
dbExecute(db_conn, "SET memory_limit = '500MB';")
dbWriteTable(db_conn, "tbl", data, append = TRUE)
dbGetQuery(db_conn, "SELECT count(*) AS n FROM tbl")

# But this is where their temp directory should have appeared, and where the
# 1.5.5 R package points it:
dbGetQuery(
  db_conn,
  "SELECT current_setting('temp_directory') AS temp_directory"
)
dbExecute(db_conn, "SET memory_limit = '200MB';")
try(dbExecute(db_conn, "CREATE TABLE sorted AS SELECT * FROM tbl ORDER BY b"))
dir.exists(paste0(db, ".tmp"))
dbDisconnect(db_conn, shutdown = TRUE)

# Naming the file on the driver instead leaves DuckDB's own <db>.tmp in place,
# and the same spilling work goes through
db2 <- tempfile(fileext = ".duckdb")
con <- dbConnect(duckdb(dbdir = db2))
dbExecute(con, "SET memory_limit = '200MB';")
dbExecute(con, "SET threads TO 1;")
dbExecute(con, "SET preserve_insertion_order=false;")
dbGetQuery(con, "SELECT current_setting('temp_directory') AS temp_directory")
dbWriteTable(con, "tbl", data)
dbExecute(con, "CREATE TABLE sorted AS SELECT * FROM tbl ORDER BY b")
dbGetQuery(con, "SELECT count(*) AS n FROM sorted")
dir.exists(paste0(db2, ".tmp"))
dbDisconnect(con, shutdown = TRUE)
