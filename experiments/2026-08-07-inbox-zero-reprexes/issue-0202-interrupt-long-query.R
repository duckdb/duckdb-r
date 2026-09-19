## duckdb-r#202 -- can Ctrl+C get out of a running DuckDB call in R?
## Ctrl+C is a signal to an interactive session, so the reprex runs one in a
## subprocess and sends it SIGINT after 8 seconds.
library(processx)
packageVersion("duckdb")

script <- tempfile(fileext = ".R")
writeLines(
  c(
    "library(duckdb)",
    "con <- dbConnect(duckdb())",
    "t0 <- Sys.time()",
    'dbGetQuery(con, "SELECT count(*) FROM range(1000000000000) t(i) WHERE i % 7 = 0")',
    'cat("gave up after", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "s\\n")',
    "dbGetQuery(con, \"SELECT 'connection still usable' AS state\")"
  ),
  script
)

p <- process$new(
  file.path(R.home("bin"), "R"),
  c("--interactive", "--quiet", "--no-save"),
  stdin = script,
  stdout = "|",
  stderr = "2>&1"
)
Sys.sleep(8)
p$signal(tools::SIGINT)
p$wait()
p$get_exit_status()
cat(p$read_all_output())
