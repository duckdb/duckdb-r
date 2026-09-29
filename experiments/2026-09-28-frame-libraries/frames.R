## A query result into Polars, data.table and collapse: each library's recipe,
## and whether the memory of the columns is the memory the result arrived in.
library(DBI)

con <- dbConnect(duckdb::duckdb(shared_home = FALSE))
# 2.5 million rows, three Arrow batches of up to a million.
sql <- paste(
  "SELECT i, i % 3 AS g, i::DOUBLE AS d,",
  "'a string longer than twelve bytes ' || i AS s",
  "FROM range(2500000) t(i)"
)

## Polars: the recipe ----------------------------------------------------------
pl_df <- polars::as_polars_df(dbGetQueryArrow(con, sql))
pl_df$shape
pl_df$schema
pl_df$n_chunks("all")

## Polars: which buffers it keeps ----------------------------------------------
# The data address of buffer `k` of column `col`, in every batch.
addrs <- function(batches, col, k) {
  vapply(
    batches,
    function(b) {
      buffer <- b$children[[col]]$buffers[[k]]
      info <- nanoarrow:::nanoarrow_buffer_info(buffer)
      nanoarrow::nanoarrow_pointer_addr_chr(info$data)
    },
    ""
  )
}
# The batches are collected first, so that their addresses can be read, and
# handed to Polars as a stream of the same arrays. Polars' own export then
# hands back what it holds.
through_polars <- function() {
  batches <- nanoarrow::collect_array_stream(dbGetQueryArrow(con, sql))
  schema <- nanoarrow::infer_nanoarrow_schema(batches[[1]])
  df <- polars::as_polars_df(nanoarrow::basic_array_stream(batches, schema))
  out <- nanoarrow::collect_array_stream(
    nanoarrow::as_nanoarrow_array_stream(df)
  )
  views <- out[[1]]$children$s$buffers[[2]]
  list(
    batches = length(batches),
    s_format = c(
      stream = schema$children$s$format,
      polars = nanoarrow::infer_nanoarrow_schema(out[[1]])$children$s$format
    ),
    # The second buffer of `s` holds a `string`'s offsets, a `string_view`'s
    # views.
    same_address = c(
      i = identical(addrs(batches, "i", 2), addrs(out, "i", 2)),
      d = identical(addrs(batches, "d", 2), addrs(out, "d", 2)),
      s_characters = identical(addrs(batches, "s", 3), addrs(out, "s", 3)),
      s_second_buffer = identical(addrs(batches, "s", 2), addrs(out, "s", 2))
    ),
    view_bytes_per_row = nanoarrow:::nanoarrow_buffer_info(views)$size_bytes /
      out[[1]]$length
  )
}
through_polars()
# The export settings that send strings as views.
dbExecute(con, "SET arrow_output_version = '1.4'")
dbExecute(con, "SET produce_arrow_string_view = true")
through_polars()

## data.table ------------------------------------------------------------------
dt <- data.table::setDT(dbGetQuery(con, sql))
class(dt)
df <- dbGetQuery(con, sql)
cols <- lobstr::obj_addrs(df)
data.table::setDT(df)
identical(lobstr::obj_addrs(df), cols)
# as.data.table() copies every column.
df <- dbGetQuery(con, sql)
cols <- lobstr::obj_addrs(df)
lobstr::obj_addrs(data.table::as.data.table(df)) %in% cols

## collapse --------------------------------------------------------------------
df <- dbGetQuery(con, sql)
cols <- lobstr::obj_addrs(df)
collapse::fsummarise(collapse::fgroup_by(df, g), d = collapse::fmean(d))
q <- collapse::qDT(df)
class(q)
identical(lobstr::obj_addrs(q), cols)

dbDisconnect(con)
