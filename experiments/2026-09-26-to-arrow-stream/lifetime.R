## How long a reader from to_arrow_stream() stays valid, and what ends it:
## statements on the same connection and on a second one, a query error after
## the first batch, the DBI result and the connection going away, and a
## reader handed back to duckdb. arrow::to_arrow() alongside, and the other
## two constructions where they differ.
library(DBI)
library(duckdb)
library(dplyr, warn.conflicts = FALSE)
library(arrow, warn.conflicts = FALSE)
source("to-arrow-stream.R")

drv <- duckdb(shared_home = FALSE)
con <- dbConnect(drv)
dbExecute(
  con,
  "CREATE TABLE nums AS SELECT range AS i, range % 7 AS g FROM range(3000000)"
)
nums <- tbl(con, "nums")

## A statement on the same connection ----------------------------------------
# The old route has read everything before it returns, so nothing can touch it.
old <- arrow::to_arrow(nums)
dbGetQuery(con, "SELECT 42 AS answer")
as_arrow_table(old)$num_rows

# The new one is invalidated, before the first batch or after it, and says so.
new <- to_arrow_stream(nums)
dbGetQuery(con, "SELECT 42 AS answer")
try(as_arrow_table(new))

new <- to_arrow_stream(nums)
new$read_next_batch()$num_rows
dbGetQuery(con, "SELECT 42 AS answer")
try(new$read_next_batch())

# Read to the end first, and the next statement is harmless.
new <- to_arrow_stream(nums)
as_arrow_table(new)$num_rows
dbGetQuery(con, "SELECT 42 AS answer")

# A second reader on the same connection is such a statement, so a join of two
# readers from one connection fails where the old route's succeeds.
join_two <- function(f, con_left, con_right) {
  left <- f(tbl(con_left, "nums") |> filter(g == 1))
  right <- f(tbl(con_right, "nums") |> filter(g == 1) |> select(i))
  inner_join(left, right, by = "i") |> summarise(n = n()) |> collect()
}
join_two(arrow::to_arrow, con, con)
try(join_two(to_arrow_stream, con, con))

## A second connection --------------------------------------------------------
# Statements there leave the stream alone, including a reader of its own and a
# write to the table being read; the stream reads the snapshot it started on.
con2 <- dbConnect(drv)
join_two(to_arrow_stream, con, con2)

new <- to_arrow_stream(nums)
new$read_next_batch()$num_rows
dbExecute(con2, "INSERT INTO nums SELECT range, 0 FROM range(10)")
dbGetQuery(con2, "SELECT count(*) AS n FROM nums")
as_arrow_table(new)$num_rows
dbExecute(con, "DELETE FROM nums WHERE rowid >= 3000000")

## A query that fails after its first batch -----------------------------------
fails_late <- tbl(
  con,
  sql(
    "SELECT CASE WHEN range < 2500000 THEN range ELSE error('boom') END AS i
     FROM range(3000000)"
  )
)
# The old route fails while it materializes, inside to_arrow() itself.
try(arrow::to_arrow(fails_late))
# The candidate, and the reader pulled on R's thread, fail at the read.
try(as_arrow_table(to_arrow_stream(fails_late)))
try(to_arrow_stream(fails_late) |> summarise(n = n()) |> collect())
try(to_arrow_pulled(fails_late) |> summarise(n = n()) |> collect())
# The literal swap keeps arrow's MakeSafeRecordBatchReader(), which drops the
# error its wrapped reader returns: two of three batches, and no error at all.
as_arrow_table(to_arrow_literal(fails_late))$num_rows
to_arrow_literal(fails_late) |> summarise(n = n()) |> collect()

## The DBI result and the connection ------------------------------------------
# dbGetQueryArrow() has cleared the DBI result before it returns; the stream
# holds the engine's query result, and with it the connection's context.
con3 <- dbConnect(duckdb(shared_home = FALSE))
new <- to_arrow_stream(tbl(con3, sql("SELECT * FROM range(3000000)")))
dbDisconnect(con3, shutdown = TRUE)
dbIsValid(con3)
as_arrow_table(new)$num_rows

## Handing the reader back to duckdb ------------------------------------------
# to_duckdb() registers the reader on arrow's own connection by default, and
# duckdb then pulls it from a thread of Arrow's pool. The readers that insist
# on R's thread are refused there; the candidate is not.
back <- function(f, ...) {
  f(nums) |> to_duckdb(...) |> summarise(n = n()) |> collect()
}
try(back(arrow::to_arrow))
try(back(to_arrow_literal))
try(back(to_arrow_pulled))
back(to_arrow_stream)

# On the reader's own connection, the old route, the literal swap and the
# pulled reader are refused the same way. The candidate's stream waits for the
# connection that the scanning query itself holds, and never gets it: run in a
# subprocess and killed after 20 seconds.
try(back(arrow::to_arrow, con = con))
try(back(to_arrow_literal, con = con))
try(back(to_arrow_pulled, con = con))
system.time(
  hang <- try(
    callr::r(
      function() {
        library(DBI)
        library(duckdb)
        library(dplyr, warn.conflicts = FALSE)
        library(arrow, warn.conflicts = FALSE)
        source("to-arrow-stream.R")
        con <- dbConnect(duckdb(shared_home = FALSE))
        dbExecute(con, "CREATE TABLE nums AS SELECT range AS i FROM range(10)")
        to_arrow_stream(tbl(con, "nums")) |>
          to_duckdb(con = con) |>
          collect()
      },
      timeout = 20
    ),
    silent = TRUE
  )
)
class(attr(hang, "condition"))[[1]]

dbDisconnect(con2)
dbDisconnect(con, shutdown = TRUE)
