``` r
## duckdb-r#1604 -- inserting 12.88M x 5 integers under a memory limit,
## and the question the title asks: is the temporary directory used?
library(duckdb)
#> Loading required package: DBI
packageVersion("duckdb")
#> [1] '1.5.5'

n <- 12880502L
data <- data.frame(
  a = seq_len(n),
  b = rev(seq_len(n)),
  c = seq_len(n) %% 1000L,
  d = seq_len(n) %% 7L,
  e = seq_len(n) %% 13L
)
format(object.size(data), units = "MB")
#> [1] "245.7 Mb"

# The reporter's setup: the database file is named on dbConnect()
db <- tempfile(fileext = ".duckdb")
db_conn <- dbConnect(duckdb::duckdb(), dbdir = db)
dbExecute(db_conn, "SET memory_limit = '3GB';")
#> [1] 0
dbExecute(db_conn, "SET max_temp_directory_size = '20GB';")
#> [1] 0
dbExecute(db_conn, "SET threads TO 1;")
#> [1] 0
dbExecute(db_conn, "SET preserve_insertion_order=false;")
#> [1] 0

# The insert itself is fine at their limit, and stays fine well below it
dbWriteTable(db_conn, "tbl", data)
dbGetQuery(db_conn, "SELECT count(*) AS n FROM tbl")
#>          n
#> 1 12880502
dbExecute(db_conn, "SET memory_limit = '500MB';")
#> [1] 0
dbWriteTable(db_conn, "tbl", data, append = TRUE)
dbGetQuery(db_conn, "SELECT count(*) AS n FROM tbl")
#>          n
#> 1 25761004

# But this is where their temp directory should have appeared, and where the
# 1.5.5 R package points it:
dbGetQuery(
  db_conn,
  "SELECT current_setting('temp_directory') AS temp_directory"
)
#>                temp_directory
#> 1 /tmp/RtmpxrG9ck/duckdb/temp
dbExecute(db_conn, "SET memory_limit = '200MB';")
#> [1] 0
try(dbExecute(db_conn, "CREATE TABLE sorted AS SELECT * FROM tbl ORDER BY b"))
#> Error in duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow) : 
#>   Invalid Error: IO Error: Failed to create directory "/tmp/RtmpxrG9ck/duckdb/temp": No such file or directory
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID
dir.exists(paste0(db, ".tmp"))
#> [1] FALSE
dbDisconnect(db_conn, shutdown = TRUE)

# Naming the file on the driver instead leaves DuckDB's own <db>.tmp in place,
# and the same spilling work goes through
db2 <- tempfile(fileext = ".duckdb")
con <- dbConnect(duckdb(dbdir = db2))
dbExecute(con, "SET memory_limit = '200MB';")
#> [1] 0
dbExecute(con, "SET threads TO 1;")
#> [1] 0
dbExecute(con, "SET preserve_insertion_order=false;")
#> [1] 0
dbGetQuery(con, "SELECT current_setting('temp_directory') AS temp_directory")
#>                               temp_directory
#> 1 /tmp/RtmpxrG9ck/file8b1399bb5e3.duckdb.tmp
dbWriteTable(con, "tbl", data)
dbExecute(con, "CREATE TABLE sorted AS SELECT * FROM tbl ORDER BY b")
#> [1] 12880502
dbGetQuery(con, "SELECT count(*) AS n FROM sorted")
#>          n
#> 1 12880502
dir.exists(paste0(db2, ".tmp"))
#> [1] TRUE
dbDisconnect(con, shutdown = TRUE)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
