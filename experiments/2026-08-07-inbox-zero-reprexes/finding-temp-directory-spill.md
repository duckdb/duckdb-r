``` r
## Not an issue reprex: a defect this run walked into.
## On 1.5.5, any query that has to spill to disk fails unless the database
## file was named on the driver -- the temp directory the package points at
## has no parent directory, and DuckDB does not create one recursively.
library(duckdb)
#> Loading required package: DBI
packageVersion("duckdb")
#> [1] '1.5.5'

spill <- "SELECT i % 4000000 AS g, count(*) AS n FROM range(20000000) t(i) GROUP BY 1"

report <- function(con) {
  on.exit(dbDisconnect(con, shutdown = TRUE))
  dbExecute(con, "SET memory_limit = '300MB'")
  print(dbGetQuery(
    con,
    "SELECT current_setting('temp_directory') AS temp_directory"
  ))
  out <- try(dbGetQuery(con, spill), silent = TRUE)
  if (inherits(out, "try-error")) {
    cat(as.character(out))
  } else {
    cat(nrow(out), "rows\n")
  }
}

# 1. in-memory: the temp directory is <tempdir()>/duckdb/temp ...
report(dbConnect(duckdb()))
#>                temp_directory
#> 1 /tmp/RtmpbHZJi5/duckdb/temp
#> Error in duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow) : 
#>   Invalid Error: IO Error: Failed to create directory "/tmp/RtmpbHZJi5/duckdb/temp": No such file or directory
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID

# 2. ... and nothing ever creates its parent, so making it by hand is enough
dir.create(file.path(tempdir(), "duckdb"), showWarnings = FALSE)
report(dbConnect(duckdb()))
#>                temp_directory
#> 1 /tmp/RtmpbHZJi5/duckdb/temp
#> 4000000 rows

# 3. a file-backed database named on dbConnect() keeps the in-memory setting,
#    because duckdb() resolved the driver config before it saw the path
unlink(file.path(tempdir(), "duckdb"), recursive = TRUE)
db <- tempfile(fileext = ".duckdb")
report(dbConnect(duckdb(), dbdir = db))
#>                temp_directory
#> 1 /tmp/RtmpbHZJi5/duckdb/temp
#> Error in duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow) : 
#>   Invalid Error: IO Error: Failed to create directory "/tmp/RtmpbHZJi5/duckdb/temp": No such file or directory
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID

# 4. named on the driver instead, it gets DuckDB's own <db>.tmp and works
db2 <- tempfile(fileext = ".duckdb")
report(dbConnect(duckdb(dbdir = db2)))
#>                                temp_directory
#> 1 /tmp/RtmpbHZJi5/file15135396c26d.duckdb.tmp
#> 4000000 rows
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
