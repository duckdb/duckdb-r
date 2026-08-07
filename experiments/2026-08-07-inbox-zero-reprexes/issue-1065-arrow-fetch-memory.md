``` r
## duckdb-r#1065 -- fetching a large result as Arrow: what costs what
## The reporter's left join produced a 20M-row result and died in
## duckdb_fetch_arrow(). Each strategy below runs in its own subprocess, so
## the peak resident set is attributable to it alone.
library(duckdb)
#> Loading required package: DBI
packageVersion("duckdb")
#> [1] '1.5.5'

query <- "SELECT i, i * 2 AS a, i * 3 AS b, i::VARCHAR AS s FROM range(20000000) t(i)"

peak_rss_mb <- function() {
  round(
    as.numeric(gsub(
      "\\D",
      "",
      grep("VmHWM", readLines("/proc/self/status"), value = TRUE)
    )) /
      1024
  )
}

measure <- function(fun) {
  callr::r(fun, args = list(query = query, peak_rss_mb = peak_rss_mb))
}

# 1. the whole result as one Arrow table
measure(function(query, peak_rss_mb) {
  library(duckdb)
  con <- dbConnect(duckdb())
  tbl <- arrow::as_arrow_table(dbGetQueryArrow(con, query))
  c(rows = nrow(tbl), peak_rss_mb = peak_rss_mb())
})
#>        rows peak_rss_mb 
#>    20000000         879

# 2. the DBI Arrow stream, one chunk at a time, nothing accumulated
measure(function(query, peak_rss_mb) {
  library(duckdb)
  con <- dbConnect(duckdb())
  res <- dbSendQueryArrow(con, query)
  rows <- 0
  while (!dbHasCompleted(res)) {
    rows <- rows + dbFetchArrowChunk(res)$length
  }
  dbClearResult(res)
  c(rows = rows, peak_rss_mb = peak_rss_mb())
})
#>        rows peak_rss_mb 
#>    20000000         814

# 3. the record batch reader the issue uses
measure(function(query, peak_rss_mb) {
  library(duckdb)
  con <- dbConnect(duckdb())
  res <- dbSendQuery(con, query, arrow = TRUE)
  reader <- duckdb_fetch_record_batch(res)
  rows <- 0
  while (!is.null(batch <- reader$read_next_batch())) {
    rows <- rows + batch$num_rows
  }
  dbClearResult(res)
  c(rows = rows, peak_rss_mb = peak_rss_mb())
})
#>        rows peak_rss_mb 
#>    20000000        1354

# 4. ten bounded results instead of one unbounded one
measure(function(query, peak_rss_mb) {
  library(duckdb)
  con <- dbConnect(duckdb())
  rows <- 0
  for (k in 0:9) {
    part <- arrow::as_arrow_table(dbGetQueryArrow(
      con,
      sprintf("SELECT * FROM (%s) WHERE i %% 10 = %d", query, k)
    ))
    rows <- rows + nrow(part)
    rm(part)
    gc()
  }
  c(rows = rows, peak_rss_mb = peak_rss_mb())
})
#>        rows peak_rss_mb 
#>    20000000         291

# 5. the same question answered inside the engine, nothing fetched
measure(function(query, peak_rss_mb) {
  library(duckdb)
  con <- dbConnect(duckdb())
  out <- dbGetQuery(con, sprintf("SELECT count(*) AS n FROM (%s)", query))
  c(rows = out$n, peak_rss_mb = peak_rss_mb())
})
#>        rows peak_rss_mb 
#>    20000000         101
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
