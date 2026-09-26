# What an engine context costs: to open and close, to run its first statement,
# to keep open, and to replay a registered data frame onto.
# Driven by run.sh; see README.md.
suppressMessages(library(duckdb))
suppressMessages(library(bench))

home <- file.path(tempdir(), "duckdb-home")
drv <- duckdb(home = home)
# Keeps the instance alive while bare contexts come and go: the driver hands
# its only strong reference to the first connection.
keeper <- dbConnect(drv)
opts <- duckdb:::duckdb_convert_opts()

bare_open <- function() {
  duckdb:::rapi_lock(drv@database_ref)
  duckdb:::rapi_connect(drv@database_ref, opts)
}
bare_round_trip <- function() {
  duckdb:::rapi_disconnect(bare_open())
}
first_statement <- function(conn) {
  stmt <- duckdb:::rapi_prepare(conn, "SELECT 1", emptyenv())
  duckdb:::rapi_execute(stmt$ref, opts)
  duckdb:::rapi_release(stmt$ref)
}

cat("== Time\n")
timing <- bench::mark(
  "engine context: open and close" = bare_round_trip(),
  "DBI connection: dbConnect() and dbDisconnect()" = dbDisconnect(dbConnect(
    drv
  )),
  "yardstick: SELECT 1 on a warm context" = first_statement(keeper@conn_ref),
  "SELECT 1 as a fresh context's first statement" = {
    p <- bare_open()
    first_statement(p)
    duckdb:::rapi_disconnect(p)
  },
  "duckdb_register(), one ten-row frame" = duckdb_register(
    keeper,
    "df",
    data.frame(x = 1:10),
    overwrite = TRUE
  ),
  check = FALSE,
  min_iterations = 200
)
print(timing[c("expression", "min", "median")], width = 100)
dbDisconnect(keeper)

cat("== Memory\n")
# Each measurement in a process of its own, so that pages one batch freed are
# not what the next batch grows into.
resident_per_context <- function(n, touch) {
  callr::r(
    function(n, touch, home) {
      rss_kb <- function() {
        line <- grep("^VmRSS", readLines("/proc/self/status"), value = TRUE)
        as.numeric(gsub("[^0-9]", "", line))
      }
      drv <- duckdb::duckdb(home = home)
      keeper <- DBI::dbConnect(drv)
      opts <- duckdb:::duckdb_convert_opts()
      ptrs <- vector("list", n)
      gc()
      before <- rss_kb()
      for (i in seq_len(n)) {
        duckdb:::rapi_lock(drv@database_ref)
        ptrs[[i]] <- duckdb:::rapi_connect(drv@database_ref, opts)
        if (touch) {
          stmt <- duckdb:::rapi_prepare(ptrs[[i]], "SELECT 1", emptyenv())
          duckdb:::rapi_execute(stmt$ref, opts)
          duckdb:::rapi_release(stmt$ref)
        }
      }
      grown <- rss_kb() - before
      for (p in ptrs) {
        duckdb:::rapi_disconnect(p)
      }
      DBI::dbDisconnect(keeper)
      grown
    },
    args = list(n = n, touch = touch, home = home)
  )
}
n <- 5000
for (touch in c(FALSE, TRUE)) {
  grown <- resident_per_context(n, touch)
  cat(sprintf(
    "  %d open contexts%s: %.0f KB resident, %.1f KB each\n",
    n,
    if (touch) ", each after one statement" else "",
    grown,
    grown / n
  ))
}
