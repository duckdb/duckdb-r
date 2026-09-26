# Peak resident memory of one process per route and consumer, for a result of
# `rows` rows of a BIGINT and a DOUBLE column (16 bytes a row).
#
#   Rscript memory.R                             # every case, to memory.csv
#   Rscript memory.R <route> <consumer> <rows>   # one case, one CSV line
#
# Run from this directory, which holds to-arrow-stream.R.
#
# A case runs in a process of its own, because VmHWM only ever grows: the
# baseline is the high-water mark after the packages are loaded and the
# connection is open, the peak is the mark at the end.

routes <- c("legacy", "stream", "literal", "pulled")
consumers <- c("acero", "table", "collect")
sizes <- c(20e6, 50e6)

hwm_mb <- function() {
  status <- readLines("/proc/self/status")
  kb <- as.numeric(gsub("\\D", "", grep("^VmHWM:", status, value = TRUE)))
  kb / 1024
}

args <- commandArgs(TRUE)
if (length(args) == 0) {
  lines <- character()
  for (rows in sizes) {
    for (consumer in consumers) {
      for (route in routes) {
        out <- system2(
          file.path(R.home("bin"), "Rscript"),
          c("memory.R", route, consumer, format(rows, scientific = FALSE)),
          stdout = TRUE
        )
        line <- grep("^(legacy|stream|literal|pulled),", out, value = TRUE)
        cat(line, "\n")
        lines <- c(lines, line)
      }
    }
  }
  writeLines(
    c("route,consumer,rows,baseline_mb,peak_mb,over_mb,call_s,total_s", lines),
    "memory.csv"
  )
  quit(save = "no")
}

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(dplyr, warn.conflicts = FALSE)
  library(arrow, warn.conflicts = FALSE)
})
source("to-arrow-stream.R")

route <- args[[1]]
consumer <- args[[2]]
rows <- as.numeric(args[[3]])
f <- switch(
  route,
  legacy = arrow::to_arrow,
  stream = to_arrow_stream,
  literal = to_arrow_literal,
  pulled = to_arrow_pulled
)

con <- dbConnect(duckdb(shared_home = FALSE))
lazy <- tbl(
  con,
  sql(sprintf(
    "SELECT range AS i, range * 0.5 AS x FROM range(%.0f)",
    rows
  ))
)
invisible(gc())
baseline <- hwm_mb()

start <- proc.time()[["elapsed"]]
reader <- f(lazy)
call_s <- proc.time()[["elapsed"]] - start
result <- switch(
  consumer,
  acero = reader |> summarise(n = n(), s = sum(x)) |> collect(),
  table = as_arrow_table(reader),
  collect = collect(reader)
)
total_s <- proc.time()[["elapsed"]] - start
stopifnot(NROW(result) %in% c(1, rows))
peak <- hwm_mb()

cat(sprintf(
  "%s,%s,%.0f,%.0f,%.0f,%.0f,%.2f,%.2f\n",
  route,
  consumer,
  rows,
  baseline,
  peak,
  peak - baseline,
  call_s,
  total_s
))
