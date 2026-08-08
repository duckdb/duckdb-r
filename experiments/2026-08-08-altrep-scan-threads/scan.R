# One attempt: register an ALTREP data frame that still has an untouched
# nested column, and let DuckDB scan it back. Prints one result line and
# exits 0 -- run.sh is what turns a killed process into a tally.
# Parameters come from the environment: N_ROWS, THREADS, FIELD (int or str).

suppressMessages(library(duckdb))

n_rows <- as.numeric(Sys.getenv("N_ROWS", "5000000"))
threads <- Sys.getenv("THREADS", "4")
field <- Sys.getenv("FIELD", "int")

sql <- switch(field,
  int = sprintf(
    "SELECT i, {'a': i, 'b': i * 2} AS s FROM range(%.0f) t(i)", n_rows
  ),
  str = sprintf(
    "SELECT i, {'a': i, 't': 'row-' || i} AS s FROM range(%.0f) t(i)", n_rows
  ),
  stop("FIELD must be int or str")
)
agg <- switch(field,
  int = "sum(s.a)",
  str = "sum(length(s.t))"
)

con_src <- DBI::dbConnect(duckdb(shared_home = FALSE))
rel <- duckdb:::rel_from_sql(con_src, sql)

# The truth, straight out of the engine, before R holds any of it
expected <- DBI::dbGetQuery(
  con_src, sprintf("SELECT %s AS v FROM (%s)", agg, sql)
)$v

df <- duckdb:::rel_to_altrep(rel)

# nrow() runs the relation and caches its result, and leaves the per-column
# transforms undone. `s` is a data frame of ALTREP vectors, so whether
# anything reads it before the scan reaches it is what this asks: bind takes
# the pointer of every flat column, and a nested one is the open question.
stopifnot(nrow(df) == n_rows)

con_scan <- DBI::dbConnect(duckdb(shared_home = FALSE))
invisible(DBI::dbExecute(con_scan, paste0("SET threads=", threads)))
duckdb_register(con_scan, "packed", df)

# Scanning `packed` reaches into `s` from DataFrameScanFunc(), on whichever
# thread DuckDB runs the scan task on
actual <- DBI::dbGetQuery(con_scan, sprintf("SELECT %s AS v FROM packed", agg))$v

cat(sprintf(
  "n=%.0f threads=%s field=%s expected=%.0f actual=%.0f %s\n",
  n_rows, threads, field, expected, actual,
  if (isTRUE(all.equal(expected, actual))) "MATCH" else "MISMATCH"
))
