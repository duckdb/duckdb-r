## Whether to_arrow_stream() returns what arrow::to_arrow() returns: the same
## class, schema and data for a plain table, a dplyr pipeline, a grouped
## table, the types that stress the Arrow export, a result of several batches
## and an empty one; and whether the result works downstream.
library(DBI)
library(duckdb)
library(dplyr, warn.conflicts = FALSE)
library(arrow, warn.conflicts = FALSE)
source("to-arrow-stream.R")
packageVersion("duckdb")
packageVersion("arrow")
packageVersion("nanoarrow")
packageVersion("dbplyr")

con <- dbConnect(duckdb(shared_home = FALSE))
dbExecute(
  con,
  "CREATE TABLE nums AS
   SELECT range::INTEGER AS i, range % 7 AS g, range * 0.5 AS x
   FROM range(3000000)"
)
dbExecute(
  con,
  "CREATE TABLE types AS SELECT * FROM (VALUES
     (1, 10::BIGINT, 1.5::DOUBLE, 'a', true, DATE '2026-09-26',
      TIMESTAMP '2026-09-26 12:34:56.789', TIMESTAMPTZ '2026-09-26 12:34:56+02',
      12.345::DECIMAL(18, 3), 1234567890.0123456789::DECIMAL(38, 10),
      [1, 2, 3], {'a': 1, 'b': 'x'}, '\\xAA'::BLOB, INTERVAL 3 DAY,
      'b'::ENUM('a', 'b'), 123::HUGEINT, MAP {'k': 1}),
     (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
      NULL, NULL, NULL, NULL, NULL, NULL, NULL),
     (3, -3::BIGINT, -0.25::DOUBLE, 'ü', false, DATE '1970-01-01',
      TIMESTAMP '1970-01-01 00:00:00', TIMESTAMPTZ '1970-01-01 00:00:00+00',
      -0.001::DECIMAL(18, 3), -1::DECIMAL(38, 10),
      [], {'a': NULL, 'b': NULL}, ''::BLOB, INTERVAL 1 MONTH,
      'a'::ENUM('a', 'b'), -1::HUGEINT, MAP {})
   ) v(int, bigint, dbl, vchar, bool, date, ts, tstz, dec18, dec38,
       list, struct, blob, ivl, enum, huge, map)"
)

# Read the old route to the end before starting the new one: a statement on
# the connection invalidates a stream that is not read to the end.
compare <- function(lazy) {
  old <- as_arrow_table(arrow::to_arrow(lazy))
  new <- as_arrow_table(to_arrow_stream(lazy))
  data.frame(
    rows = new$num_rows,
    same_schema = old$schema$Equals(new$schema, check_metadata = TRUE),
    same_data = old$Equals(new, check_metadata = TRUE)
  )
}

## Class ----------------------------------------------------------------------
class(arrow::to_arrow(tbl(con, "nums")))
class(to_arrow_stream(tbl(con, "nums")))
class(arrow::to_arrow(group_by(tbl(con, "nums"), g)))
class(to_arrow_stream(group_by(tbl(con, "nums"), g)))
dplyr::group_vars(to_arrow_stream(group_by(tbl(con, "nums"), g)))

## Schema and data ------------------------------------------------------------
# Three million rows: three batches of the default million.
compare(tbl(con, "nums"))

compare(
  tbl(con, "nums") |>
    filter(g != 3) |>
    mutate(y = x * 2) |>
    group_by(g) |>
    summarise(n = n(), s = sum(y, na.rm = TRUE)) |>
    arrange(g)
)

compare(tbl(con, "types"))
to_arrow_stream(tbl(con, "types"))$schema

# Empty, for plain and nested types
compare(filter(tbl(con, "nums"), i < 0))
compare(filter(tbl(con, "types"), int > 100))

## Downstream -----------------------------------------------------------------
# collect() to a data frame; arrow converts no month_day_nano_interval to R,
# on either route
try(collect(arrow::to_arrow(tbl(con, "types"))))
try(collect(to_arrow_stream(tbl(con, "types"))))
identical(
  collect(arrow::to_arrow(select(tbl(con, "types"), -ivl))),
  collect(to_arrow_stream(select(tbl(con, "types"), -ivl)))
)

# Further arrow dplyr verbs, evaluated by arrow's engine
pipeline <- function(reader) {
  reader |>
    filter(i %% 2 == 0) |>
    mutate(z = x + g) |>
    group_by(g) |>
    summarise(n = n(), z = sum(z)) |>
    arrange(g) |>
    collect()
}
old <- pipeline(arrow::to_arrow(tbl(con, "nums")))
new <- pipeline(to_arrow_stream(tbl(con, "nums")))
identical(old, new)
new

# Groups carried through, then summarised by arrow
to_arrow_stream(group_by(tbl(con, "nums"), g)) |>
  summarise(n = n()) |>
  arrange(g) |>
  collect()

## Sources that call R, read from arrow's threads -----------------------------
# arrow's engine pulls the candidate's stream from its own threads. The query
# scans a registered R data frame (factor and list columns included), or an
# arrow dataset handed to duckdb with to_duckdb(): arrow to duckdb to arrow.
n <- 3000000
df <- data.frame(i = seq_len(n), f = factor(rep_len(c("a", "b", "c"), n)))
df$l <- rep_len(list(1:2, NULL, 3L), n)
duckdb_register(con, "df", df)
from_df <- tbl(con, sql("SELECT i, f::VARCHAR AS f, len(l) AS nl FROM df"))
by_factor <- function(reader) {
  reader |>
    group_by(f) |>
    summarise(n = n(), s = sum(i), nl = sum(nl, na.rm = TRUE)) |>
    arrange(f) |>
    collect()
}
identical(
  by_factor(arrow::to_arrow(from_df)),
  by_factor(to_arrow_stream(from_df))
)
by_factor(to_arrow_stream(from_df))

dir <- tempfile()
write_dataset(arrow_table(i = seq_len(n), g = rep_len(1:7, n)), dir)
round_trip <- function(f) {
  open_dataset(dir) |>
    filter(i %% 3 == 0) |>
    to_duckdb() |>
    mutate(j = i * 2) |>
    f() |>
    group_by(g) |>
    summarise(n = n(), s = sum(j)) |>
    arrange(g) |>
    collect()
}
identical(round_trip(arrow::to_arrow), round_trip(to_arrow_stream))

## Passthrough and refusal ----------------------------------------------------
at <- arrow_table(a = 1:3)
identical(to_arrow_stream(at), at)
q <- filter(at, a > 1)
identical(to_arrow_stream(q), q)
try(arrow::to_arrow(dbplyr::lazy_frame(a = 1)))
try(to_arrow_stream(dbplyr::lazy_frame(a = 1)))

dbDisconnect(con)
