``` r
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
#> [1] 3e+06
nums <- tbl(con, "nums")

## A statement on the same connection ----------------------------------------
# The old route has read everything before it returns, so nothing can touch it.
old <- arrow::to_arrow(nums)
dbGetQuery(con, "SELECT 42 AS answer")
#>   answer
#> 1     42
as_arrow_table(old)$num_rows
#> [1] 3000000

# The new one is invalidated, before the first batch or after it, and says so.
new <- to_arrow_stream(nums)
dbGetQuery(con, "SELECT 42 AS answer")
#>   answer
#> 1     42
try(as_arrow_table(new))
#> Error : Invalid: Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection.

new <- to_arrow_stream(nums)
new$read_next_batch()$num_rows
#> [1] 1000000
dbGetQuery(con, "SELECT 42 AS answer")
#>   answer
#> 1     42
try(new$read_next_batch())
#> Error : Invalid: Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection.

# Read to the end first, and the next statement is harmless.
new <- to_arrow_stream(nums)
as_arrow_table(new)$num_rows
#> [1] 3000000
dbGetQuery(con, "SELECT 42 AS answer")
#>   answer
#> 1     42

# A second reader on the same connection is such a statement, so a join of two
# readers from one connection fails where the old route's succeeds.
join_two <- function(f, con_left, con_right) {
  left <- f(tbl(con_left, "nums") |> filter(g == 1))
  right <- f(tbl(con_right, "nums") |> filter(g == 1) |> select(i))
  inner_join(left, right, by = "i") |> summarise(n = n()) |> collect()
}
join_two(arrow::to_arrow, con, con)
#> # A tibble: 1 × 1
#>        n
#>    <int>
#> 1 428572
try(join_two(to_arrow_stream, con, con))
#> Error in compute.arrow_dplyr_query(x) : 
#>   Invalid: Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection.

## A second connection --------------------------------------------------------
# Statements there leave the stream alone, including a reader of its own and a
# write to the table being read; the stream reads the snapshot it started on.
con2 <- dbConnect(drv)
join_two(to_arrow_stream, con, con2)
#> # A tibble: 1 × 1
#>        n
#>    <int>
#> 1 428572

new <- to_arrow_stream(nums)
new$read_next_batch()$num_rows
#> [1] 1000000
dbExecute(con2, "INSERT INTO nums SELECT range, 0 FROM range(10)")
#> [1] 10
dbGetQuery(con2, "SELECT count(*) AS n FROM nums")
#>         n
#> 1 3000010
as_arrow_table(new)$num_rows
#> [1] 2000000
dbExecute(con, "DELETE FROM nums WHERE rowid >= 3000000")
#> [1] 10

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
#> Error in duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow) : 
#>   Invalid Input Error: boom
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID_INPUT
# The candidate, and the reader pulled on R's thread, fail at the read.
try(as_arrow_table(to_arrow_stream(fails_late)))
#> Error : IOError: Invalid Input Error: boom
try(to_arrow_stream(fails_late) |> summarise(n = n()) |> collect())
#> Error in compute.arrow_dplyr_query(x) : 
#>   IOError: Invalid Input Error: boom
try(to_arrow_pulled(fails_late) |> summarise(n = n()) |> collect())
#> Error in compute.arrow_dplyr_query(x) : 
#>   array_stream->get_next(): [-1] Invalid Input Error: boom
# The literal swap keeps arrow's MakeSafeRecordBatchReader(), which drops the
# error its wrapped reader returns: two of three batches, and no error at all.
as_arrow_table(to_arrow_literal(fails_late))$num_rows
#> [1] 2000000
to_arrow_literal(fails_late) |> summarise(n = n()) |> collect()
#> # A tibble: 1 × 1
#>         n
#>     <int>
#> 1 2000000

## The DBI result and the connection ------------------------------------------
# dbGetQueryArrow() has cleared the DBI result before it returns; the stream
# holds the engine's query result, and with it the connection's context.
con3 <- dbConnect(duckdb(shared_home = FALSE))
new <- to_arrow_stream(tbl(con3, sql("SELECT * FROM range(3000000)")))
dbDisconnect(con3, shutdown = TRUE)
dbIsValid(con3)
#> [1] FALSE
as_arrow_table(new)$num_rows
#> [1] 3000000

## Handing the reader back to duckdb ------------------------------------------
# to_duckdb() registers the reader on arrow's own connection by default, and
# duckdb then pulls it from a thread of Arrow's pool. The readers that insist
# on R's thread are refused there; the candidate is not.
back <- function(f, ...) {
  f(nums) |> to_duckdb(...) |> summarise(n = n()) |> collect()
}
try(back(arrow::to_arrow))
#> Error in collect(summarise(to_duckdb(f(nums), ...), n = n())) : 
#>   Failed to collect lazy table.
#> Caused by error in `duckdb_result()`:
#> ! Invalid Input Error: arrow_scan: get_next failed(): NotImplemented: Call to R (SafeRecordBatchReader::ReadNext()) from a non-R thread from an unsupported context
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID_INPUT
try(back(to_arrow_literal))
#> Error in collect(summarise(to_duckdb(f(nums), ...), n = n())) : 
#>   Failed to collect lazy table.
#> Caused by error in `duckdb_result()`:
#> ! Invalid Input Error: arrow_scan: get_next failed(): NotImplemented: Call to R (SafeRecordBatchReader::ReadNext()) from a non-R thread from an unsupported context
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID_INPUT
try(back(to_arrow_pulled))
#> Error in collect(summarise(to_duckdb(f(nums), ...), n = n())) : 
#>   Failed to collect lazy table.
#> Caused by error in `duckdb_result()`:
#> ! Invalid Input Error: arrow_scan: get_next failed(): NotImplemented: Call to R (unspecified) from a non-R thread from an unsupported context
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID_INPUT
back(to_arrow_stream)
#> # A tibble: 1 × 1
#>         n
#>     <dbl>
#> 1 3000000

# On the reader's own connection, the old route, the literal swap and the
# pulled reader are refused the same way. The candidate's stream waits for the
# connection that the scanning query itself holds, and never gets it: run in a
# subprocess and killed after 20 seconds.
try(back(arrow::to_arrow, con = con))
#> Error in collect(summarise(to_duckdb(f(nums), ...), n = n())) : 
#>   Failed to collect lazy table.
#> Caused by error in `duckdb_result()`:
#> ! Invalid Input Error: arrow_scan: get_next failed(): NotImplemented: Call to R (SafeRecordBatchReader::ReadNext()) from a non-R thread from an unsupported context
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID_INPUT
try(back(to_arrow_literal, con = con))
#> Error in collect(summarise(to_duckdb(f(nums), ...), n = n())) : 
#>   Failed to collect lazy table.
#> Caused by error in `duckdb_result()`:
#> ! Invalid Input Error: arrow_scan: get_next failed(): NotImplemented: Call to R (SafeRecordBatchReader::ReadNext()) from a non-R thread from an unsupported context
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID_INPUT
try(back(to_arrow_pulled, con = con))
#> Error in collect(summarise(to_duckdb(f(nums), ...), n = n())) : 
#>   Failed to collect lazy table.
#> Caused by error in `duckdb_result()`:
#> ! Invalid Input Error: arrow_scan: get_next failed(): NotImplemented: Call to R (unspecified) from a non-R thread from an unsupported context
#> ℹ Context: rapi_execute
#> ℹ Error type: INVALID_INPUT
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
#>    user  system elapsed 
#>   1.569   0.510  20.120
class(attr(hang, "condition"))[[1]]
#> [1] "callr_timeout_error"

dbDisconnect(con2)
dbDisconnect(con, shutdown = TRUE)
```

<sup>Created on 2026-09-26 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-09-26
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  arrow       * 25.0.1     2026-08-23 [2] RSPM
#>  assertthat    0.2.1      2019-03-21 [2] RSPM
#>  bit           4.6.0      2025-03-06 [2] RSPM
#>  bit64         4.8.6      2026-09-01 [2] RSPM
#>  blob          1.3.0      2026-01-14 [2] RSPM
#>  callr         3.8.0      2026-06-05 [2] RSPM
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  dbplyr        2.6.0      2026-06-17 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  dplyr       * 1.2.1      2026-04-03 [2] RSPM
#>  duckdb      * 1.5.5.9026 2026-09-26 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  generics      0.1.4      2025-05-09 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  magrittr      2.0.5      2026-04-04 [2] RSPM
#>  nanoarrow     0.9.0      2026-08-04 [2] RSPM
#>  otel          0.2.0      2025-08-29 [2] RSPM
#>  pillar        1.11.1     2025-09-17 [2] RSPM
#>  pkgconfig     2.0.3      2019-09-22 [2] RSPM
#>  processx      3.9.0      2026-04-22 [2] RSPM
#>  ps            1.9.3      2026-04-20 [2] RSPM
#>  purrr         1.2.2      2026-04-10 [2] RSPM
#>  R6            2.6.1      2025-02-15 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  tibble        3.3.1      2026-01-11 [2] RSPM
#>  tidyselect    1.2.1      2024-03-11 [2] RSPM
#>  vctrs         0.7.3      2026-04-11 [2] RSPM
#>  withr         3.0.3      2026-06-19 [2] RSPM
#>  xfun          0.61       2026-09-16 [2] RSPM
#>  yaml          2.3.12     2025-12-10 [2] RSPM
#> 
#>  [1] <fast-path build library>
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
