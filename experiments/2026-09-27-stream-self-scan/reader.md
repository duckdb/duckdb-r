``` r
## What else the reader from to_arrow_stream() cannot do on its own connection:
## the statements dplyr and dbplyr run without being asked, a second read,
## writing the reader back, and what a second connection to the same
## database changes. None of these cases waits, so they run in one session.
library(DBI)
library(duckdb)

msg <- function(e) conditionMessage(e)

con <- dbConnect(duckdb(shared_home = FALSE))
dbWriteTable(con, "t", data.frame(i = seq_len(3e6)))
dbWriteTable(con, "u", data.frame(j = 1:3))
lazy <- dplyr::tbl(con, "t")

## Statements that dplyr and dbplyr run -----------------------------------------
# dbplyr asks for the columns of a new lazy table.
reader <- to_arrow_stream(lazy)
other <- dplyr::tbl(con, "u")
tryCatch(reader$read_next_batch()$num_rows, error = msg)
#> [1] "Invalid: Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection."

# Printing a lazy table queries its first rows.
reader <- to_arrow_stream(lazy)
print(other)
#> # A query:  ?? x 1
#> # Database: DuckDB 1.5.5 [unknown@Linux 6.18.44-fc-v37:R 4.5.3/:memory:]
#>       j
#>   <int>
#> 1     1
#> 2     2
#> 3     3
tryCatch(reader$read_next_batch()$num_rows, error = msg)
#> [1] "Invalid: Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection."

# So does collect().
reader <- to_arrow_stream(lazy)
invisible(dplyr::collect(other))
tryCatch(reader$read_next_batch()$num_rows, error = msg)
#> [1] "Invalid: Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection."

## A second connection to the same database is independent --------------------
# con@driver holds the database, so a connection from it sees the same tables.
other_con <- dbConnect(con@driver)
reader <- to_arrow_stream(lazy)
dplyr::collect(dplyr::tbl(other_con, "u"))
#> # A tibble: 3 × 1
#>       j
#>   <int>
#> 1     1
#> 2     2
#> 3     3
reader$read_table()$num_rows
#> [1] 3000000

## The reader is read once -----------------------------------------------------
reader <- to_arrow_stream(lazy)
reader$read_table()$num_rows
#> [1] 3000000
reader$read_table()$num_rows
#> [1] 0

## Writing the reader back to its own connection --------------------------------
# The reader knows its schema, so DBI's dbWriteTableArrow() creates the table
# before the first read fails, and leaves it empty.
reader <- to_arrow_stream(lazy)
tryCatch(dbWriteTableArrow(con, "copy", reader), error = msg)
#> [1] "array_stream->get_next(): [22] Invalid: Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection."
dbGetQuery(con, "SELECT count(*) AS n FROM copy")$n
#> [1] 0

# DBI's dbAppendTableArrow() appends batch by batch, and keeps the first.
dbExecute(con, "CREATE TABLE copy2 (i INTEGER)")
#> [1] 0
reader <- to_arrow_stream(lazy)
tryCatch(dbAppendTableArrow(con, "copy2", reader), error = msg)
#> [1] "array_stream->get_next(): [22] Invalid: Invalid Input Error: The query result was invalidated by another statement on its connection before it was read to the end. Read it to the end first, or run the other statement on a separate connection."
dbGetQuery(con, "SELECT count(*) AS n FROM copy2")$n
#> [1] 1e+06

# To a second connection, dbWriteTableArrow() writes every row.
reader <- to_arrow_stream(lazy)
dbWriteTableArrow(other_con, "copy3", reader)
dbGetQuery(other_con, "SELECT count(*) AS n FROM copy3")$n
#> [1] 3e+06

## The reader outlives its connection ------------------------------------------
reader <- to_arrow_stream(lazy)
dbDisconnect(other_con)
dbDisconnect(con)
reader$read_table()$num_rows
#> [1] 3000000
```

<sup>Created on 2026-09-27 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

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
#>  date     2026-09-27
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  arrow         25.0.1     2026-08-23 [2] RSPM
#>  assertthat    0.2.1      2019-03-21 [2] RSPM
#>  bit           4.6.0      2025-03-06 [2] RSPM
#>  bit64         4.8.6      2026-09-01 [2] RSPM
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  dbplyr        2.6.0      2026-06-17 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  dplyr         1.2.1      2026-04-03 [2] RSPM
#>  duckdb      * 1.5.5.9028 2026-09-27 [1] local
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
