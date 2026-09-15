``` r
## duckdb-r#162 -- does the DBI Arrow API hand back Arrow, or a data frame?
library(duckdb)
#> Loading required package: DBI
packageVersion("duckdb")
#> [1] '1.5.5'

con <- dbConnect(duckdb())

# Every DBI Arrow generic has a method (shipped in 1.5.4, #2347 and #2355)
grep("Arrow", as.character(methods(class = "duckdb_connection")), value = TRUE)
#> [1] "dbAppendTableArrow,DBIConnection-method"            
#> [2] "dbCreateTableArrow,DBIConnection-method"            
#> [3] "dbGetQueryArrow,DBIConnection-method"               
#> [4] "dbReadTableArrow,DBIConnection-method"              
#> [5] "dbSendQueryArrow,DBIConnection,ANY-method"          
#> [6] "dbSendQueryArrow,duckdb_connection,character-method"
#> [7] "dbWriteTableArrow,DBIConnection-method"

# A result is an Arrow stream, not a materialised data frame
stream <- dbGetQueryArrow(con, "SELECT i, i * 2 AS twice FROM range(3) t(i)")
class(stream)
#> [1] "nanoarrow_array_stream"
as.data.frame(stream)
#>   i twice
#> 1 0     0
#> 2 1     2
#> 3 2     4

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
#> chunks   rows 
#>  2e+00  1e+06

# The reporter's path: Parquet -> Arrow -> to_duckdb(), no data frame in between
library(arrow, warn.conflicts = FALSE)
tmpfile <- tempfile(fileext = ".parquet")
write_parquet(beaver1, tmpfile)
read_parquet(tmpfile, as_data_frame = FALSE) |>
  to_duckdb()
#> # A query:  ?? x 4
#> # Database: DuckDB 1.5.5 [unknown@Linux 6.18.5-fc-v18:R 4.5.3/:memory:]
#>      day  time  temp activ
#>    <dbl> <dbl> <dbl> <dbl>
#>  1   346   840  36.3     0
#>  2   346   850  36.3     0
#>  3   346   900  36.4     0
#>  4   346   910  36.4     0
#>  5   346   920  36.6     0
#>  6   346   930  36.7     0
#>  7   346   940  36.7     0
#>  8   346   950  36.8     0
#>  9   346  1000  36.8     0
#> 10   346  1010  36.9     0
#> # ℹ more rows

# The other direction, also without a data frame: Arrow table -> DuckDB table
dbWriteTableArrow(con, "beavers", arrow_table(beaver1))
dbReadTableArrow(con, "beavers") |>
  as_arrow_table()
#> Table
#> 114 rows x 4 columns
#> $day <double>
#> $time <double>
#> $temp <double>
#> $activ <double>

dbDisconnect(con)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
