## duckdb-r#72 -- a grouped aggregation over Parquet under a memory limit,
## in R and in the CLI. The reporter's dataset was 150 GB of eBird
## observations grouped by sampling event and species, and their last word
## on it was that the same work "works fine in the CLI client, crashes in R"
## (comment 1964392402, duckdb 0.10). This is the same query shape over 200M
## rows whose keys are hashed rather than sequential, so the file does not
## compress away and the group state is real: 40M groups, one per five rows.
library(duckdb)
library(dplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
system2("duckdb", "--version", stdout = TRUE) # the same engine, standalone

parquet <- tempfile(fileext = ".parquet")
db <- tempfile(fileext = ".duckdb")

con <- dbConnect(duckdb(dbdir = db))
dbExecute(con, "SET threads = 4")
dbExecute(
  con,
  sprintf(
    "COPY (
       SELECT
         hash(i // 5)::VARCHAR                         AS sampling_event_identifier,
         ('sp_' || (hash(i // 5 + 7) %% 700))::VARCHAR AS scientific_name,
         (hash(i + 11) %% 50)::INTEGER                 AS observation_count
       FROM range(200000000) t(i)
     ) TO '%s' (FORMAT parquet)",
    parquet
  )
)

# How big it really is, on disk and in the pages, and how many groups
round(file.size(parquet) / 1024^2) # MB
dbGetQuery(
  con,
  sprintf(
    "SELECT
       round(sum(total_compressed_size) / 1e6)   AS compressed_mb,
       round(sum(total_uncompressed_size) / 1e6) AS uncompressed_mb
     FROM parquet_metadata('%s')",
    parquet
  )
)
dbExecute(
  con,
  sprintf(
    "CREATE VIEW observations AS SELECT * FROM parquet_scan('%s')",
    parquet
  )
)
dbGetQuery(
  con,
  "SELECT count(DISTINCT sampling_event_identifier) AS events FROM observations"
)
dbDisconnect(con, shutdown = TRUE)

group_by_sql <- sprintf(
  "SELECT sampling_event_identifier, scientific_name,
          SUM(observation_count) AS count
   FROM parquet_scan('%s')
   GROUP BY sampling_event_identifier, scientific_name",
  parquet
)

# The reporter's pipeline from R, at a given memory limit, on a fresh database
from_r <- function(limit) {
  db <- tempfile(fileext = ".duckdb")
  con <- dbConnect(duckdb(dbdir = db))
  on.exit(try(dbDisconnect(con, shutdown = TRUE), silent = TRUE), add = TRUE)
  dbExecute(con, sprintf("SET memory_limit = '%s'", limit))
  dbExecute(con, "SET threads = 4")
  dbExecute(
    con,
    sprintf(
      "CREATE VIEW observations AS SELECT * FROM parquet_scan('%s')",
      parquet
    )
  )
  t0 <- Sys.time()
  out <- try(
    tbl(con, "observations") |>
      group_by(sampling_event_identifier, scientific_name) |>
      summarize(
        count = sum(observation_count, na.rm = TRUE),
        .groups = "drop"
      ) |>
      compute(),
    silent = TRUE
  )
  spilled <- list.files(paste0(db, ".tmp"), full.names = TRUE, recursive = TRUE)
  cat(
    "R   ",
    limit,
    "|",
    round(as.numeric(difftime(Sys.time(), t0, units = "secs"))),
    "s",
    "| spilled",
    round(sum(file.size(spilled), na.rm = TRUE) / 1024^2),
    "MB",
    "|",
    if (inherits(out, "try-error")) {
      sub(".*(Out of Memory Error[^\n]*).*", "\\1", paste(out, collapse = " "))
    } else {
      paste(collect(count(out))$n, "groups")
    },
    "\n"
  )
}

# The same statements handed to the standalone client instead
from_cli <- function(limit) {
  db <- tempfile(fileext = ".duckdb")
  sql <- tempfile(fileext = ".sql")
  writeLines(
    c(
      sprintf("SET memory_limit = '%s';", limit),
      "SET threads = 4;",
      sprintf("CREATE TEMPORARY TABLE agg AS %s;", group_by_sql),
      "SELECT count(*) AS groups FROM agg;"
    ),
    sql
  )
  t0 <- Sys.time()
  out <- suppressWarnings(system2(
    "duckdb",
    db,
    stdin = sql,
    stdout = TRUE,
    stderr = TRUE
  ))
  cat(
    "CLI ",
    limit,
    "|",
    round(as.numeric(difftime(Sys.time(), t0, units = "secs"))),
    "s",
    "|",
    if (any(grepl("Out of Memory", out))) {
      sub(
        ".*(Out of Memory Error[^\"]*)",
        "\\1",
        grep("Out of Memory", out, value = TRUE)[1]
      )
    } else {
      paste(
        trimws(gsub("[^0-9]", "", grep("^│ *[0-9]+", out, value = TRUE)[1])),
        "groups"
      )
    },
    "\n"
  )
}

# Below the group state, neither client spills -- both die, with the error
# the report quotes
from_r("256MB")
from_cli("256MB")

# Given room to spill, both finish, and R's temp directory is used
from_r("1GB")
from_cli("1GB")

# And with room for the whole aggregate, no spilling at all
from_r("4GB")

# What the R process peaked at across its three attempts
round(
  as.numeric(gsub(
    "\\D",
    "",
    grep("VmHWM", readLines("/proc/self/status"), value = TRUE)
  )) /
    1024
)
