# What a nanoarrow-only data frame scan does today, measured against the
# built-in r_dataframe_scan. Uses no C++ changes: the closures that
# duckdb_register_arrow() passes to rapi_register_arrow() are ordinary R
# functions, so nanoarrow can be substituted for arrow at that seam.

# The recorded run is scan.md, rendered with reprex::reprex(si = TRUE).

library(duckdb)
library(nanoarrow)
options(width = 200)

# Keep the run hermetic: no shared extension/secret home.
new_con <- function() dbConnect(duckdb(shared_home = FALSE))

packageVersion("duckdb")
packageVersion("nanoarrow")

# --- The nanoarrow-only registration shim ------------------------------

# rapi_register_arrow() takes five closures: an exporter, three Arrow
# expression factories used for filter pushdown, and a schema exporter.
# Only the exporter and the schema exporter need Arrow semantics; the
# expression factories are reached only when DuckDB pushes a filter down.
register_nanoarrow <- function(con, name, x, on_filter = c("ignore", "error")) {
  on_filter <- match.arg(on_filter)

  export_fun <- function(x, stream_ptr, projection = NULL, filter = TRUE) {
    if (!is.null(projection)) {
      x <- x[projection]
    }
    stream <- nanoarrow::as_nanoarrow_array_stream(x)
    nanoarrow::nanoarrow_pointer_export(stream, stream_ptr)
  }

  get_schema_fun <- function(x, schema_ptr) {
    schema <- nanoarrow::infer_nanoarrow_schema(x)
    nanoarrow::nanoarrow_pointer_export(schema, schema_ptr)
  }

  expr_factory <- switch(on_filter,
    ignore = function(...) structure(list(...), class = "unused_expression"),
    error = function(...) stop("nanoarrow source cannot apply filters")
  )

  duckdb:::rapi_register_arrow(
    con@conn_ref,
    name,
    list(export_fun, expr_factory, expr_factory, expr_factory, get_schema_fun),
    x
  )
  invisible(TRUE)
}

con <- new_con()

# --- 1. Does it scan at all? -------------------------------------------

df <- data.frame(a = 1:5, b = letters[1:5])
register_nanoarrow(con, "na_tbl", df)

dbGetQuery(con, "SELECT * FROM na_tbl")

# Projection pushdown: DuckDB asks for the columns it needs, by name.
dbGetQuery(con, "SELECT b FROM na_tbl")

# count(*) still projects one column, so the exporter is never called
# with a NULL projection in practice.
dbGetQuery(con, "SELECT count(*) FROM na_tbl")

# The source is scanned afresh every time, so repeated scans and
# self-joins both work.
dbGetQuery(con, "SELECT sum(a) FROM na_tbl")
dbGetQuery(con, "SELECT count(*) FROM na_tbl x JOIN na_tbl y USING (a)")

# --- 2. Filter pushdown is not optional --------------------------------

# arrow_scan sets filter_pushdown = true, and PhysicalTableScan does not
# re-apply what it hands to the producer: a producer that ignores the
# filter returns the wrong rows, silently.
dbGetQuery(con, "SELECT * FROM na_tbl WHERE a > 3")

cat(dbGetQuery(con, "EXPLAIN SELECT * FROM na_tbl WHERE a > 3")[[2]])

# Failing loudly instead is a one-line change in the shim, and it fails
# for every filtered query rather than only the unrepresentable ones.
register_nanoarrow(con, "na_strict", df, on_filter = "error")
try(dbGetQuery(con, "SELECT * FROM na_strict WHERE a > 3"))

# A materialized CTE gets the right answer back -- but not by
# suppressing the pushdown. The filter is still pushed into the scan and
# still ignored there; what fixes the answer is that DuckDB applies it a
# second time above the materialization barrier.
dbGetQuery(
  con,
  "WITH t AS MATERIALIZED (SELECT * FROM na_tbl) SELECT * FROM t WHERE a > 3"
)

cat(dbGetQuery(
  con,
  "EXPLAIN WITH t AS MATERIALIZED (SELECT * FROM na_tbl) SELECT * FROM t WHERE a > 3"
)[[2]])

# --- 3. A one-shot stream is not a table -------------------------------

# Anything that is consumed on read cannot back a view: it has no
# columns to project and nothing to replay.
register_nanoarrow(con, "one_shot", nanoarrow::as_nanoarrow_array_stream(df))
try(dbGetQuery(con, "SELECT count(*) FROM one_shot"))

# --- 4. Type fidelity, nanoarrow against r_dataframe_scan --------------

types <- list(
  logical = c(TRUE, FALSE, NA),
  integer = c(1L, 2L, NA),
  double = c(1.5, 2.5, NA),
  character = c("a", "äöü", NA),
  factor = factor(c("x", "y", NA)),
  Date = as.Date(c("2024-01-01", "2024-06-15", NA)),
  POSIXct_utc = as.POSIXct(c("2024-01-01 10:00:00", "2024-06-15 10:00:00", NA), tz = "UTC"),
  POSIXct_tz = as.POSIXct(c("2024-01-01 10:00:00", "2024-06-15 10:00:00", NA), tz = "Europe/Zurich"),
  difftime_secs = as.difftime(c(1, 2, NA), units = "secs"),
  difftime_days = as.difftime(c(1, 2, NA), units = "days"),
  integer64 = bit64::as.integer64(c(1, 2, NA)),
  hms = hms::as_hms(c(1, 2, NA)),
  blob = blob::blob(as.raw(1:3), as.raw(4:6), NULL),
  list_int = list(1:2, integer(), NULL),
  struct = NULL # filled in below, a data frame column
)
types$struct <- data.frame(x = 1:3, y = c("a", "b", NA))

probe_one <- function(value, how) {
  df <- data.frame(row.names = seq_len(3))
  df[["x"]] <- value
  con <- new_con()
  on.exit(dbDisconnect(con), add = TRUE)
  tryCatch(
    {
      if (how == "r_dataframe_scan") {
        duckdb_register(con, "t", df)
      } else {
        register_nanoarrow(con, "t", df)
      }
      type <- dbGetQuery(con, "SELECT typeof(x) AS t FROM t LIMIT 1")$t[[1]]
      list(type = type, value = dbGetQuery(con, "SELECT * FROM t")$x)
    },
    error = function(e) {
      list(type = paste("ERROR:", conditionMessage(e)), value = NULL)
    }
  )
}

grid <- do.call(rbind, lapply(names(types), function(name) {
  native <- probe_one(types[[name]], "r_dataframe_scan")
  nano <- probe_one(types[[name]], "nanoarrow")
  data.frame(
    column = name,
    native_type = native$type,
    nanoarrow_type = nano$type,
    native_roundtrips = identical(native$value, types[[name]]),
    nanoarrow_roundtrips = identical(nano$value, types[[name]]),
    agree = identical(native$value, nano$value),
    stringsAsFactors = FALSE
  )
}))
grid$native_type <- substr(grid$native_type, 1, 32)
grid$nanoarrow_type <- substr(grid$nanoarrow_type, 1, 32)
grid

# The one column nanoarrow cannot take at all is the bare list, and the
# reason is lost on the way through the seam: an R error raised inside
# the schema exporter reaches the caller as `std::exception`.
try(nanoarrow::infer_nanoarrow_schema(types$list_int))

# --- 5. What the export costs ------------------------------------------

n <- 1e6
big <- data.frame(
  i = seq_len(n),
  d = as.numeric(seq_len(n)),
  s = rep(letters, length.out = n),
  stringsAsFactors = FALSE
)

con2 <- new_con()
duckdb_register(con2, "native", big)
register_nanoarrow(con2, "na", big)

timing <- function(label, expr) {
  expr <- substitute(expr)
  t <- system.time(for (i in 1:3) eval(expr, parent.frame()))
  data.frame(what = label, elapsed_per_run = round(unname(t[["elapsed"]]) / 3, 3))
}

do.call(rbind, list(
  timing("native  count(*)", dbGetQuery(con2, "SELECT count(*) FROM native")),
  timing("nanoarrow count(*)", dbGetQuery(con2, "SELECT count(*) FROM na")),
  timing("native  sum(i)", dbGetQuery(con2, "SELECT sum(i) FROM native")),
  timing("nanoarrow sum(i)", dbGetQuery(con2, "SELECT sum(i) FROM na")),
  timing("native  one string column", dbGetQuery(con2, "SELECT count(DISTINCT s) FROM native")),
  timing("nanoarrow one string column", dbGetQuery(con2, "SELECT count(DISTINCT s) FROM na")),
  timing("native  full fetch", dbGetQuery(con2, "SELECT * FROM native")),
  timing("nanoarrow full fetch", dbGetQuery(con2, "SELECT * FROM na"))
))

dbDisconnect(con2)
dbDisconnect(con)
