## duckdb-r#72 -- a grouped aggregation over Parquet under a memory limit
## The reporter's dataset was 150 GB of eBird observations on 0.3.4; this is
## the same query shape over 20M rows, with the limit set well below what the
## hash aggregate needs, so the engine has to spill.
library(duckdb)
library(dplyr, warn.conflicts = FALSE)
packageVersion("duckdb")

parquet <- tempfile(fileext = ".parquet")
db <- tempfile(fileext = ".duckdb")

con <- dbConnect(duckdb(dbdir = db))
dbExecute(con, "SET memory_limit = '256MB'")
dbExecute(con, "SET threads = 2")
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
round(file.size(parquet) / 1024^2, 1) # MB on disk

dbExecute(
  con,
  sprintf(
    "CREATE VIEW observations AS SELECT * FROM parquet_scan('%s')",
    parquet
  )
)
obs <- tbl(con, "observations")

t0 <- Sys.time()
tmp <- obs |>
  group_by(sampling_event_identifier, scientific_name) |>
  summarize(count = sum(observation_count, na.rm = TRUE), .groups = "drop") |>
  compute() # this is the call that crashed / OOMed on 0.3.4
round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1) # seconds

tmp |> count() |> collect()
tmp |> head(3) |> collect()

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
dir.exists(paste0(db, ".tmp"))

dbDisconnect(con, shutdown = TRUE)
