# TPC-H fetch benchmark for duckdb-r: materialized vs streaming result transfer.
#
# Measures the *R boundary*: how long it takes to move a query result from the
# engine into R, and how much memory the move needs, per fetch strategy.
# It does not compare query engines; for cross-solution group-by/join numbers
# see duckdblabs/db-benchmark (Tom Ebergen's continuation of the h2oai
# benchmark), which this script deliberately does not depend on.
#
# Usage:
#   Rscript bench.R [--sf=0.1] [--reps=3] [--chunk=10000] [--out=results.csv]
#                   [--buffer=<streaming_buffer_size, e.g. 64MB>]
#                   [--memlimit=<engine memory_limit, e.g. 500MB>]
#                   [--db=<path to .duckdb file to create/reuse>]
#                   [--scenarios=a,b,...] [--queries=a,b,...]
#
# Environment:
#   DUCKDB_LIB  optional R library path to load duckdb from
#               (e.g. a library holding a dev build; workers inherit it).
#
# The orchestrator creates the TPC-H database once (tpch extension if it can
# be installed, otherwise a deterministic synthetic lineitem with the same
# schema), then runs every scenario x query cell in a fresh R subprocess:
# peak RSS (VmHWM) and gc() deltas are per-cell, uncontaminated.
#
# Scenarios (cells not supported by the installed duckdb build are skipped
# and marked in the output):
#   materialize          dbGetQuery(): execute + convert everything at once
#   materialize_chunked  dbSendQuery() + dbFetch(n = chunk) loop (API-chunked,
#                        but the build may still buffer the whole result)
#   stream_all           dbSendQuery(stream = TRUE) + dbFetch(-1)
#   stream_chunked       dbSendQuery(stream = TRUE) + dbFetch(n = chunk) loop,
#                        discarding each batch: the bounded-memory consumer
#   arrow_drain          dbSendQueryArrow() + dbFetchArrowChunk() loop without
#                        converting to R vectors: approximates engine-side
#                        production cost as seen from R (needs nanoarrow)
#   engine_only          CREATE TEMP TABLE AS <query>: production cost with no
#                        R conversion at all (includes the table write)
#   spill_then_stream    CREATE TEMP TABLE AS <query>, then stream-fetch the
#                        table in chunks: the two-phase spill-friendly idiom
#
# Queries:
#   q1        TPC-H Q1 pricing summary: heavy scan+aggregate, 4-row result;
#             fetch cost ~ 0, so this is the engine-time control
#   all       SELECT * FROM lineitem: wide result, mixed types, engine work
#             is a bare scan, so conversion dominates
#   sorted    the same wide result behind an ORDER BY: engine work and
#             conversion in the same ballpark, the balanced case
#   strings   the VARCHAR columns of lineitem: string-allocation bound

args <- commandArgs(trailingOnly = TRUE)

arg <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) {
    return(default)
  }
  sub(paste0("^--", name, "="), "", hit[[1]])
}

lib <- Sys.getenv("DUCKDB_LIB", "")
if (nzchar(lib)) {
  .libPaths(c(lib, .libPaths()))
}

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
})

# ---------------------------------------------------------------------------
# Shared definitions

lineitem_rows <- function(sf) round(6001215 * sf)

# Deterministic synthetic lineitem, used when the tpch extension cannot be
# installed (e.g. offline). Same schema and column widths as dbgen output;
# value distributions are approximate, which is fine for a transfer benchmark.
synthetic_lineitem_sql <- function(n) {
  sprintf(
    "CREATE TABLE lineitem AS
     SELECT
       (r %% 1500000)::BIGINT + 1 AS l_orderkey,
       (hash(r) %% 200000)::BIGINT + 1 AS l_partkey,
       (hash(r + 1) %% 10000)::BIGINT + 1 AS l_suppkey,
       (r %% 7)::INTEGER + 1 AS l_linenumber,
       ((hash(r + 2) %% 50) + 1)::DECIMAL(15,2) AS l_quantity,
       ((hash(r + 3) %% 10000000) / 100.0)::DECIMAL(15,2) AS l_extendedprice,
       ((hash(r + 4) %% 11) / 100.0)::DECIMAL(15,2) AS l_discount,
       ((hash(r + 5) %% 9) / 100.0)::DECIMAL(15,2) AS l_tax,
       CASE hash(r + 6) %% 3 WHEN 0 THEN 'A' WHEN 1 THEN 'N' ELSE 'R' END
         AS l_returnflag,
       CASE hash(r + 7) %% 2 WHEN 0 THEN 'O' ELSE 'F' END AS l_linestatus,
       DATE '1992-01-01' + (hash(r + 8) %% 2526)::INTEGER AS l_shipdate,
       DATE '1992-01-01' + (hash(r + 9) %% 2526)::INTEGER AS l_commitdate,
       DATE '1992-01-01' + (hash(r + 10) %% 2526)::INTEGER AS l_receiptdate,
       CASE hash(r + 11) %% 4
         WHEN 0 THEN 'DELIVER IN PERSON' WHEN 1 THEN 'COLLECT COD'
         WHEN 2 THEN 'NONE' ELSE 'TAKE BACK RETURN' END AS l_shipinstruct,
       CASE hash(r + 12) %% 7
         WHEN 0 THEN 'REG AIR' WHEN 1 THEN 'AIR' WHEN 2 THEN 'RAIL'
         WHEN 3 THEN 'SHIP' WHEN 4 THEN 'TRUCK' WHEN 5 THEN 'MAIL'
         ELSE 'FOB' END AS l_shipmode,
       substr(repeat(md5(r::VARCHAR), 2), 1, 10 + (hash(r + 13) %% 34)::INTEGER)
         AS l_comment
     FROM range(%d) t(r)",
    n
  )
}

queries <- list(
  q1 = "
    SELECT
      l_returnflag, l_linestatus,
      sum(l_quantity) AS sum_qty,
      sum(l_extendedprice) AS sum_base_price,
      sum(l_extendedprice * (1 - l_discount)) AS sum_disc_price,
      sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
      avg(l_quantity) AS avg_qty,
      avg(l_extendedprice) AS avg_price,
      avg(l_discount) AS avg_disc,
      count(*) AS count_order
    FROM lineitem
    WHERE l_shipdate <= DATE '1998-12-01' - INTERVAL 90 DAY
    GROUP BY l_returnflag, l_linestatus
    ORDER BY l_returnflag, l_linestatus",
  all = "SELECT * FROM lineitem",
  sorted = "SELECT * FROM lineitem ORDER BY l_extendedprice DESC, l_orderkey",
  strings = "
    SELECT l_orderkey, l_returnflag, l_linestatus, l_shipinstruct,
           l_shipmode, l_comment
    FROM lineitem"
)

all_scenarios <- c(
  "materialize", "materialize_chunked", "stream_all", "stream_chunked",
  "arrow_drain", "engine_only", "spill_then_stream"
)

has_stream_arg <- function() {
  fml <- tryCatch(
    formals(getFromNamespace("dbSendQuery__duckdb_connection_character", "duckdb")),
    error = function(e) NULL
  )
  !is.null(fml) && "stream" %in% names(fml)
}

peak_rss_mb <- function() {
  status <- tryCatch(readLines("/proc/self/status"), error = function(e) NULL)
  if (is.null(status)) {
    return(NA_real_)
  }
  line <- grep("^VmHWM:", status, value = TRUE)
  if (length(line) == 0) {
    return(NA_real_)
  }
  as.numeric(gsub("[^0-9]", "", line)) / 1024
}

reset_peak_rss <- function() {
  # Linux: writing 5 to clear_refs resets the VmHWM high-water mark.
  tryCatch(writeLines("5", "/proc/self/clear_refs"), error = function(e) NULL)
  invisible()
}

# ---------------------------------------------------------------------------
# Worker: measure one scenario x query cell, print one CSV row on stdout

run_worker <- function() {
  scenario <- arg("scenario")
  query_name <- arg("query")
  db <- arg("db")
  chunk <- as.integer(arg("chunk", "10000"))
  buffer <- arg("buffer", "")
  memlimit <- arg("memlimit", "")

  q <- queries[[query_name]]
  stopifnot(!is.null(q), scenario %in% all_scenarios)

  config <- list()
  if (nzchar(memlimit)) {
    config$memory_limit <- memlimit
  }
  con <- suppressMessages(
    dbConnect(duckdb(), dbdir = db, read_only = FALSE, config = config)
  )
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
  if (nzchar(buffer)) {
    dbExecute(con, sprintf("SET streaming_buffer_size = '%s'", buffer))
  }

  send_stream <- function() dbSendQuery(con, q, stream = TRUE)

  rows <- NA_real_
  note <- "ok"

  gc(reset = TRUE)
  reset_peak_rss()
  rss_before <- peak_rss_mb()

  elapsed <- system.time(tryCatch(
    switch(scenario,
      materialize = {
        df <- dbGetQuery(con, q)
        rows <- nrow(df)
      },
      materialize_chunked = {
        rs <- dbSendQuery(con, q)
        rows <- 0
        while (!dbHasCompleted(rs)) {
          batch <- dbFetch(rs, n = chunk)
          rows <- rows + nrow(batch)
          if (nrow(batch) == 0) break
        }
        dbClearResult(rs)
      },
      stream_all = {
        rs <- send_stream()
        df <- dbFetch(rs, n = -1)
        rows <- nrow(df)
        dbClearResult(rs)
      },
      stream_chunked = {
        rs <- send_stream()
        rows <- 0
        while (!dbHasCompleted(rs)) {
          batch <- dbFetch(rs, n = chunk)
          rows <- rows + nrow(batch)
          if (nrow(batch) == 0) break
        }
        dbClearResult(rs)
      },
      arrow_drain = {
        rs <- dbSendQueryArrow(con, q)
        rows <- 0
        while (!is.null(chunk_arr <- dbFetchArrowChunk(rs))) {
          n <- tryCatch(as.numeric(chunk_arr$length), error = function(e) NA_real_)
          if (is.na(n) || n == 0) {
            if (is.na(n)) rows <- NA_real_
            break
          }
          rows <- rows + n
        }
        dbClearResult(rs)
      },
      engine_only = {
        dbExecute(con, paste("CREATE OR REPLACE TEMP TABLE bench_sink AS", q))
        rows <- dbGetQuery(con, "SELECT count(*) AS n FROM bench_sink")$n
      },
      spill_then_stream = {
        dbExecute(con, paste("CREATE OR REPLACE TEMP TABLE bench_sink AS", q))
        rs <- dbSendQuery(con, "SELECT * FROM bench_sink", stream = TRUE)
        rows <- 0
        while (!dbHasCompleted(rs)) {
          batch <- dbFetch(rs, n = chunk)
          rows <- rows + nrow(batch)
          if (nrow(batch) == 0) break
        }
        dbClearResult(rs)
      }
    ),
    error = function(e) {
      note <<- paste("failed:", gsub("[,\n]", " ", conditionMessage(e)))
    }
  ))[["elapsed"]]

  rss_after <- peak_rss_mb()
  gc_stats <- gc()
  r_alloc_mb <- sum(gc_stats[, "max used"] * c(56, 8)) / 2^20
  engine_mem_mb <- tryCatch(
    dbGetQuery(
      con,
      "SELECT coalesce(sum(memory_usage_bytes), 0) / 1048576.0 AS mb
       FROM duckdb_memory()"
    )$mb,
    error = function(e) NA_real_
  )

  cat(sprintf(
    "%s,%s,%.0f,%.3f,%.1f,%.1f,%.1f,%s\n",
    scenario, query_name, rows, elapsed,
    rss_after - rss_before, r_alloc_mb, engine_mem_mb, note
  ))
}

# ---------------------------------------------------------------------------
# Orchestrator: build the database, fan out workers, collect and print

run_orchestrator <- function() {
  sf <- as.numeric(arg("sf", "0.1"))
  reps <- as.integer(arg("reps", "3"))
  chunk <- arg("chunk", "10000")
  out <- arg("out", sprintf("results-sf%s.csv", sf))
  buffer <- arg("buffer", "")
  memlimit <- arg("memlimit", "")
  db <- arg("db", file.path(tempdir(), sprintf("tpch-sf%s.duckdb", sf)))

  message("duckdb package version: ", packageVersion("duckdb"))
  stream_ok <- has_stream_arg()
  message("dbSendQuery(stream = ) available: ", stream_ok)
  arrow_ok <- requireNamespace("nanoarrow", quietly = TRUE)
  message("nanoarrow available: ", arrow_ok)

  if (!file.exists(db)) {
    message("creating ", db, " at sf = ", sf)
    con <- suppressMessages(dbConnect(duckdb(), dbdir = db))
    made <- tryCatch(
      {
        dbExecute(con, "INSTALL tpch")
        dbExecute(con, "LOAD tpch")
        dbExecute(con, sprintf("CALL dbgen(sf = %s)", sf))
        "tpch extension (dbgen)"
      },
      error = function(e) {
        message("tpch extension unavailable (", conditionMessage(e),
                "), generating synthetic lineitem")
        dbExecute(con, synthetic_lineitem_sql(lineitem_rows(sf)))
        "synthetic (deterministic, schema-faithful)"
      }
    )
    n <- dbGetQuery(con, "SELECT count(*) AS n FROM lineitem")$n
    message("lineitem rows: ", n, " via ", made)
    dbDisconnect(con, shutdown = TRUE)
  } else {
    message("reusing ", db)
  }

  scenarios <- strsplit(arg("scenarios", paste(all_scenarios, collapse = ",")), ",")[[1]]
  query_names <- strsplit(arg("queries", paste(names(queries), collapse = ",")), ",")[[1]]

  needs_stream <- c("stream_all", "stream_chunked", "spill_then_stream")
  results <- list()

  for (query_name in query_names) {
    for (scenario in scenarios) {
      if (scenario %in% needs_stream && !stream_ok) {
        message(sprintf("%-20s %-8s skipped: no stream support", scenario, query_name))
        next
      }
      if (scenario == "arrow_drain" && !arrow_ok) {
        message(sprintf("%-20s %-8s skipped: nanoarrow not installed", scenario, query_name))
        next
      }
      for (rep in seq_len(reps)) {
        worker_args <- c(
          "--worker",
          paste0("--scenario=", scenario),
          paste0("--query=", query_name),
          paste0("--db=", db),
          paste0("--chunk=", chunk)
        )
        if (nzchar(buffer)) {
          worker_args <- c(worker_args, paste0("--buffer=", buffer))
        }
        if (nzchar(memlimit)) {
          worker_args <- c(worker_args, paste0("--memlimit=", memlimit))
        }
        line <- system2(
          file.path(R.home("bin"), "Rscript"),
          c(shQuote(sub("--file=", "", grep("^--file=", commandArgs(), value = TRUE))), worker_args),
          stdout = TRUE
        )
        line <- tail(line[nzchar(line)], 1)
        fields <- strsplit(line, ",", fixed = TRUE)[[1]]
        if (length(fields) < 8) {
          fields <- c(fields, rep("", 8 - length(fields)))
        }
        results[[length(results) + 1]] <- data.frame(
          duckdb = as.character(packageVersion("duckdb")),
          stream_build = stream_ok,
          sf = sf,
          rep = rep,
          scenario = fields[[1]],
          query = fields[[2]],
          rows = as.numeric(fields[[3]]),
          elapsed_s = as.numeric(fields[[4]]),
          peak_rss_mb = as.numeric(fields[[5]]),
          r_alloc_mb = as.numeric(fields[[6]]),
          engine_mem_mb = as.numeric(fields[[7]]),
          note = fields[[8]] %||% ""
        )
        message(sprintf(
          "%-20s %-8s rep %d: %6.2fs  rss %7.1f MB  ralloc %7.1f MB  rows %s",
          scenario, query_name, rep,
          as.numeric(fields[[4]]), as.numeric(fields[[5]]),
          as.numeric(fields[[6]]), fields[[3]]
        ))
      }
    }
  }

  df <- do.call(rbind, results)
  write.csv(df, out, row.names = FALSE)
  message("\nwrote ", out)

  agg <- aggregate(
    cbind(elapsed_s, peak_rss_mb, r_alloc_mb) ~ scenario + query,
    df,
    median
  )
  agg <- agg[order(agg$query, agg$elapsed_s), ]
  message("\nmedians over ", reps, " reps:")
  print(agg, row.names = FALSE)
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x)) y else x

if ("--worker" %in% args) {
  run_worker()
} else {
  run_orchestrator()
}
