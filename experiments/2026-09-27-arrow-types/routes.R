# Which R functions carry Arrow types across, in each direction: every write
# route, given columns of Arrow types that no R class writes, and every read
# route, under the default export and with arrow_lossless_conversion.
# Then what dbplyr, which the arrow package's functions build on, makes of a
# table holding a type R cannot hold.
# The recorded run is routes.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
library(nanoarrow)
options(width = 250)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

con <- dbConnect(duckdb())
# The interval column is DuckDB's own export, from a connection of its own:
# nanoarrow cannot build interval_month_day_nano from an R value.
src <- dbConnect(duckdb())

cell <- function(expr, width = 45) {
  out <- tryCatch(
    expr,
    error = function(e) paste("ERROR:", gsub("\n.*", "", conditionMessage(e)))
  )
  out <- paste(out, collapse = " | ")
  if (nchar(out) > width) paste0(substr(out, 1, width - 3), "...") else out
}

# --- Writing ------------------------------------------------------------

# One column each, of an Arrow type no R class writes.
columns <- list(
  "uint32" = function() as_nanoarrow_array(42, schema = na_uint32()),
  "decimal128(38, 10)" = function() {
    as_nanoarrow_array(3.1415926535, schema = na_decimal128(38, 10))
  },
  "time64('us')" = function() {
    as_nanoarrow_array(hms::as_hms("13:03:12.123456"), schema = na_time64("us"))
  },
  "timestamp('ns')" = function() {
    as_nanoarrow_array(
      as.POSIXct("2024-01-10 13:03:12.123456", tz = "UTC"),
      schema = na_timestamp("ns")
    )
  },
  "dictionary(int8)<string>" = function() {
    as_nanoarrow_array(
      factor("ok"),
      schema = na_dictionary(na_string(), na_int8())
    )
  },
  "interval_month_day_nano" = function() {
    s <- dbGetQueryArrow(src, "SELECT INTERVAL '1 month 2 days 3 seconds' AS x")
    collect_array_stream(s)[[1]]$children$x
  }
)
# A fresh stream of one column, named x unless told otherwise, as nanoarrow
# and as an arrow reader.
stream_of <- function(make, name = "x") {
  arr <- make()
  batch <- nanoarrow_array_init(na_struct(
    setNames(list(infer_nanoarrow_schema(arr)), name)
  ))
  batch <- nanoarrow_array_modify(
    batch,
    list(
      length = arr$length,
      null_count = 0,
      children = setNames(list(arr), name)
    )
  )
  basic_array_stream(list(batch))
}
reader_of <- function(make) arrow::as_record_batch_reader(stream_of(make))

landed <- function(table) {
  r <- dbGetQuery(
    con,
    paste0("SELECT typeof(x) AS t, x::VARCHAR AS v FROM ", table)
  )
  paste(r$t, r$v)
}
fresh <- function(table) {
  invisible(dbExecute(con, paste("DROP TABLE IF EXISTS", table)))
  invisible(dbExecute(con, paste("DROP VIEW IF EXISTS", table)))
}

# Every call registers a view of its own name: a name reused across calls can
# meet a registration an earlier call left behind.
n_views <- 0
view_name <- function() {
  n_views <<- n_views + 1
  paste0("v", n_views)
}

write_routes <- list(
  "duckdb_register_arrow(), reader" = function(make) {
    v <- view_name()
    duckdb_register_arrow(con, v, reader_of(make))
    on.exit(duckdb_unregister_arrow(con, v))
    fresh("w")
    dbExecute(con, paste("CREATE TABLE w AS SELECT * FROM", v))
    landed("w")
  },
  "duckdb_register_arrow(), nanoarrow" = function(make) {
    v <- view_name()
    duckdb_register_arrow(con, v, stream_of(make))
    on.exit(duckdb_unregister_arrow(con, v))
    landed(v)
  },
  "arrow::to_duckdb()" = function(make) {
    v <- view_name()
    arrow::to_duckdb(
      arrow::as_arrow_table(reader_of(make)),
      con = con,
      table_name = v,
      auto_disconnect = FALSE
    )
    on.exit(duckdb_unregister_arrow(con, v))
    landed(v)
  },
  "dbCreateTableArrow()" = function(make) {
    fresh("w")
    dbCreateTableArrow(con, "w", stream_of(make)$get_schema())
    dbGetQuery(con, "SELECT column_type FROM (DESCRIBE w)")$column_type
  },
  "dbWriteTableArrow()" = function(make) {
    fresh("w")
    dbWriteTableArrow(con, "w", stream_of(make))
    landed("w")
  },
  # The type and the value are bound in queries of their own: one parameter
  # used both inside typeof() and in a cast invalidates the database
  # (an engine error, reproduced with PREPARE and EXECUTE alone).
  "dbBindArrow()" = function(make) {
    bind <- function(sql) {
      res <- dbSendQueryArrow(con, sql)
      on.exit(dbClearResult(res))
      dbBindArrow(res, stream_of(make, name = ""))
      as.data.frame(dbFetchArrow(res))[[1]]
    }
    paste(bind("SELECT typeof(?)"), bind("SELECT ?::VARCHAR"))
  }
)
out <- data.frame(arrow = names(columns))
for (route in names(write_routes)) {
  out[[route]] <- vapply(
    columns,
    function(make) cell(write_routes[[route]](make)),
    character(1)
  )
}
print(out, right = FALSE, row.names = FALSE)

# dbBindArrow() binds by position only when the stream's field names are
# empty; a named field is passed on as a named parameter, which dbBind()
# refuses, even for a named placeholder.
cell(
  {
    res <- dbSendQueryArrow(con, "SELECT $x::VARCHAR AS v")
    on.exit(dbClearResult(res))
    dbBindArrow(res, stream_of(columns[["uint32"]], name = "x"))
    as.data.frame(dbFetchArrow(res))$v
  },
  width = 80
)

# --- Reading ------------------------------------------------------------

invisible(dbExecute(
  con,
  "CREATE TABLE r AS SELECT
     42::HUGEINT AS h,
     '4ac7a9e9-607c-4c8a-84f3-843f0191e3fd'::UUID AS u,
     'ok'::ENUM('sad', 'ok') AS e,
     TIMESTAMPTZ '2024-01-10 13:03:12+00' AS tz,
     INTERVAL '1 month' AS iv"
))
sql <- "SELECT * FROM r"

# The Arrow types of a stream's fields, in one line.
types_of <- function(schema) {
  vapply(
    schema$children,
    function(f) {
      out <- sub("^<nanoarrow_schema (.*)>$", "\\1", format(f))
      ext <- f$metadata[["ARROW:extension:name"]]
      if (is.null(ext)) out else ext
    },
    character(1)
  )
}
read_routes <- list(
  "dbGetQueryArrow()" = function() {
    types_of(nanoarrow::infer_nanoarrow_schema(dbGetQueryArrow(con, sql)))
  },
  "dbSendQueryArrow(), dbFetchArrow()" = function() {
    res <- dbSendQueryArrow(con, sql)
    on.exit(dbClearResult(res))
    types_of(nanoarrow::infer_nanoarrow_schema(dbFetchArrow(res)))
  },
  "dbSendQueryArrow(), dbFetchArrowChunk()" = function() {
    res <- dbSendQueryArrow(con, sql)
    on.exit(dbClearResult(res))
    types_of(nanoarrow::infer_nanoarrow_schema(dbFetchArrowChunk(res)))
  },
  "dbReadTableArrow()" = function() {
    types_of(nanoarrow::infer_nanoarrow_schema(dbReadTableArrow(con, "r")))
  },
  "duckdb_fetch_arrow()" = function() {
    res <- dbSendQuery(con, sql, arrow = TRUE)
    on.exit(dbClearResult(res))
    types_of(nanoarrow::infer_nanoarrow_schema(duckdb_fetch_arrow(res)))
  },
  "duckdb_fetch_record_batch()" = function() {
    res <- dbSendQuery(con, sql, arrow = TRUE)
    on.exit(dbClearResult(res))
    types_of(nanoarrow::infer_nanoarrow_schema(duckdb_fetch_record_batch(res)))
  },
  "arrow::to_arrow()" = function() {
    types_of(nanoarrow::infer_nanoarrow_schema(arrow::to_arrow(dplyr::tbl(
      con,
      "r"
    ))))
  }
)
for (lossless in c(FALSE, TRUE)) {
  invisible(dbExecute(
    con,
    sprintf("SET arrow_lossless_conversion = %s", lossless)
  ))
  cat("arrow_lossless_conversion =", lossless, "\n")
  print(
    do.call(
      rbind,
      lapply(read_routes, function(f) {
        tryCatch(as.data.frame(t(f())), error = function(e) {
          cols <- c("h", "u", "e", "tz", "iv")
          msg <- paste("ERROR:", gsub("\n.*", "", conditionMessage(e)))
          as.data.frame(t(setNames(c(msg, rep("", 4)), cols)))
        })
      })
    ),
    right = FALSE
  )
}

# dbplyr reads a table's fields through a query R has to convert, so a
# table holding a type R cannot hold has no tbl(), and neither of the arrow
# functions built on it works for that table.
invisible(dbExecute(
  con,
  "CREATE TABLE n AS SELECT '13:03:12.123456789'::TIME_NS AS tn"
))
cell(dplyr::tbl(con, "n"), width = 120)
# arrow::to_duckdb() registers the data, then returns a tbl() of it, so it
# fails the same way for Arrow data that lands as such a type.
cell(
  {
    arrow::to_duckdb(
      arrow::as_arrow_table(reader_of(function() {
        as_nanoarrow_array(
          hms::as_hms("13:03:12.123456"),
          schema = na_time64("ns")
        )
      })),
      con = con,
      table_name = view_name(),
      auto_disconnect = FALSE
    )
    "ok"
  },
  width = 120
)

dbDisconnect(src, shutdown = TRUE)
dbDisconnect(con, shutdown = TRUE)
