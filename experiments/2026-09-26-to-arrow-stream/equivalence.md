``` r
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
#> [1] '1.5.5.9026'
packageVersion("arrow")
#> [1] '25.0.1'
packageVersion("nanoarrow")
#> [1] '0.9.0'
packageVersion("dbplyr")
#> [1] '2.6.0'

con <- dbConnect(duckdb(shared_home = FALSE))
dbExecute(
  con,
  "CREATE TABLE nums AS
   SELECT range::INTEGER AS i, range % 7 AS g, range * 0.5 AS x
   FROM range(3000000)"
)
#> [1] 3e+06
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
#> [1] 3

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
#> [1] "RecordBatchReader" "ArrowObject"       "R6"
class(to_arrow_stream(tbl(con, "nums")))
#> [1] "RecordBatchReader" "ArrowObject"       "R6"
class(arrow::to_arrow(group_by(tbl(con, "nums"), g)))
#> [1] "arrow_dplyr_query"
class(to_arrow_stream(group_by(tbl(con, "nums"), g)))
#> [1] "arrow_dplyr_query"
dplyr::group_vars(to_arrow_stream(group_by(tbl(con, "nums"), g)))
#> [1] "g"

## Schema and data ------------------------------------------------------------
# Three million rows: three batches of the default million.
compare(tbl(con, "nums"))
#>      rows same_schema same_data
#> 1 3000000        TRUE      TRUE

compare(
  tbl(con, "nums") |>
    filter(g != 3) |>
    mutate(y = x * 2) |>
    group_by(g) |>
    summarise(n = n(), s = sum(y, na.rm = TRUE)) |>
    arrange(g)
)
#>   rows same_schema same_data
#> 1    6        TRUE      TRUE

compare(tbl(con, "types"))
#>   rows same_schema same_data
#> 1    3        TRUE      TRUE
to_arrow_stream(tbl(con, "types"))$schema
#> Schema
#> int: int32
#> bigint: int64
#> dbl: double
#> vchar: string
#> bool: bool
#> date: date32[day]
#> ts: timestamp[us]
#> tstz: timestamp[us, tz=Etc/UTC]
#> dec18: decimal128(18, 3)
#> dec38: decimal128(38, 10)
#> list: list<l: int32>
#> struct: struct<a: int32, b: string>
#> blob: binary
#> ivl: month_day_nano_interval
#> enum: dictionary<values=string, indices=uint8>
#> huge: decimal128(38, 0)
#> map: map<string, int32>

# Empty, for plain and nested types
compare(filter(tbl(con, "nums"), i < 0))
#>   rows same_schema same_data
#> 1    0        TRUE      TRUE
compare(filter(tbl(con, "types"), int > 100))
#>   rows same_schema same_data
#> 1    0        TRUE      TRUE

## Downstream -----------------------------------------------------------------
# collect() to a data frame; arrow converts no month_day_nano_interval to R,
# on either route
try(collect(arrow::to_arrow(tbl(con, "types"))))
#> Error : cannot handle Array of type <month_day_nano_interval>
try(collect(to_arrow_stream(tbl(con, "types"))))
#> Error : cannot handle Array of type <month_day_nano_interval>
identical(
  collect(arrow::to_arrow(select(tbl(con, "types"), -ivl))),
  collect(to_arrow_stream(select(tbl(con, "types"), -ivl)))
)
#> [1] TRUE

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
#> [1] TRUE
new
#> # A tibble: 7 × 3
#>       g      n            z
#>   <int>  <int>        <dbl>
#> 1     0 214286 160713964285
#> 2     1 214286 160715035715
#> 3     2 214286 160714607143
#> 4     3 214285 160714178570
#> 5     4 214286 160715250001
#> 6     5 214285 160714821425
#> 7     6 214286 160715892859

# Groups carried through, then summarised by arrow
to_arrow_stream(group_by(tbl(con, "nums"), g)) |>
  summarise(n = n()) |>
  arrange(g) |>
  collect()
#> # A tibble: 7 × 2
#>       g      n
#>   <int>  <int>
#> 1     0 428572
#> 2     1 428572
#> 3     2 428572
#> 4     3 428571
#> 5     4 428571
#> 6     5 428571
#> 7     6 428571

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
#> [1] TRUE
by_factor(to_arrow_stream(from_df))
#> # A tibble: 3 × 4
#>   f           n             s      nl
#>   <chr>   <int>       <int64>   <int>
#> 1 a     1000000 1499999500000 2000000
#> 2 b     1000000 1500000500000       0
#> 3 c     1000000 1500001500000 1000000

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
#> [1] TRUE

## Passthrough and refusal ----------------------------------------------------
at <- arrow_table(a = 1:3)
identical(to_arrow_stream(at), at)
#> [1] TRUE
q <- filter(at, a > 1)
identical(to_arrow_stream(q), q)
#> [1] TRUE
try(arrow::to_arrow(dbplyr::lazy_frame(a = 1)))
#> Error : to_arrow() currently only supports Arrow tables, Arrow datasets, Arrow queries, or dbplyr tbls from duckdb connections
try(to_arrow_stream(dbplyr::lazy_frame(a = 1)))
#> Error : to_arrow() currently only supports Arrow tables, Arrow datasets, Arrow queries, or dbplyr tbls from duckdb connections

dbDisconnect(con)
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
#>  purrr         1.2.2      2026-04-10 [2] RSPM
#>  R6            2.6.1      2025-02-15 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  tibble        3.3.1      2026-01-11 [2] RSPM
#>  tidyselect    1.2.1      2024-03-11 [2] RSPM
#>  utf8          1.2.6      2025-06-08 [2] RSPM
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
