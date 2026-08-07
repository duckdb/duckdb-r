``` r
## duckdb-r#72 -- a grouped aggregation over Parquet under a memory limit
## The reporter's dataset was 150 GB of eBird observations on 0.3.4; this is
## the same query shape over 20M rows, with the limit set well below what the
## hash aggregate needs, so the engine has to spill.
library(duckdb)
#> Loading required package: DBI
library(dplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
#> [1] '1.5.5'

parquet <- tempfile(fileext = ".parquet")
db <- tempfile(fileext = ".duckdb")

con <- dbConnect(duckdb(dbdir = db))
dbExecute(con, "SET memory_limit = '256MB'")
#> [1] 0
dbExecute(con, "SET threads = 2")
#> [1] 0
dbExecute(
  con,
  sprintf(
    "COPY (
       SELECT
         (i // 5)::VARCHAR         AS sampling_event_identifier,
         ((i // 5) %% 700)::VARCHAR AS scientific_name,
         (i %% 5)                  AS observation_count
       FROM range(20000000) t(i)
     ) TO '%s' (FORMAT parquet)",
    parquet
  )
)
#> [1] 2e+07
round(file.size(parquet) / 1024^2, 1) # MB on disk
#> [1] 35.5

dbExecute(
  con,
  sprintf(
    "CREATE VIEW observations AS SELECT * FROM parquet_scan('%s')",
    parquet
  )
)
#> [1] 0
obs <- tbl(con, "observations")

t0 <- Sys.time()
tmp <- obs |>
  group_by(sampling_event_identifier, scientific_name) |>
  summarize(count = sum(observation_count, na.rm = TRUE), .groups = "drop") |>
  compute() # this is the call that crashed / OOMed on 0.3.4
round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1) # seconds
#> [1] 1.3

tmp |> count() |> collect()
#> # A tibble: 1 × 1
#>         n
#>     <dbl>
#> 1 4000000
tmp |> head(3) |> collect()
#> # A tibble: 3 × 3
#>   sampling_event_identifier scientific_name count
#>   <chr>                     <chr>           <dbl>
#> 1 5                         5                  10
#> 2 33                        33                 10
#> 3 35                        35                 10

# The engine spilled rather than growing: what the R process peaked at,
# against the 256 MB limit
peak_rss_mb <- round(
  as.numeric(gsub(
    "\\D",
    "",
    grep("VmHWM", readLines("/proc/self/status"), value = TRUE)
  )) /
    1024
)
peak_rss_mb
#> [1] 427
dir.exists(paste0(db, ".tmp"))
#> [1] TRUE

dbDisconnect(con, shutdown = TRUE)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
