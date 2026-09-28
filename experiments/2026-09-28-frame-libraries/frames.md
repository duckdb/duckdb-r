``` r
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
#> [1] 2500000       4
pl_df$schema
#> $i
#> Int64
#> 
#> $g
#> Int64
#> 
#> $d
#> Float64
#> 
#> $s
#> String
pl_df$n_chunks("all")
#> i g d s 
#> 3 3 3 3

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
#> $batches
#> [1] 3
#> 
#> $s_format
#> stream polars 
#>    "u"   "vu" 
#> 
#> $same_address
#>               i               d    s_characters s_second_buffer 
#>            TRUE            TRUE            TRUE           FALSE 
#> 
#> $view_bytes_per_row
#> [1] 16
# The export settings that send strings as views.
dbExecute(con, "SET arrow_output_version = '1.4'")
#> [1] 0
dbExecute(con, "SET produce_arrow_string_view = true")
#> [1] 0
through_polars()
#> $batches
#> [1] 3
#> 
#> $s_format
#> stream polars 
#>   "vu"   "vu" 
#> 
#> $same_address
#>               i               d    s_characters s_second_buffer 
#>            TRUE            TRUE            TRUE            TRUE 
#> 
#> $view_bytes_per_row
#> [1] 16

## data.table ------------------------------------------------------------------
dt <- data.table::setDT(dbGetQuery(con, sql))
class(dt)
#> [1] "data.table" "data.frame"
df <- dbGetQuery(con, sql)
cols <- lobstr::obj_addrs(df)
data.table::setDT(df)
identical(lobstr::obj_addrs(df), cols)
#> [1] TRUE
# as.data.table() copies every column.
df <- dbGetQuery(con, sql)
cols <- lobstr::obj_addrs(df)
lobstr::obj_addrs(data.table::as.data.table(df)) %in% cols
#> [1] FALSE FALSE FALSE FALSE

## collapse --------------------------------------------------------------------
df <- dbGetQuery(con, sql)
cols <- lobstr::obj_addrs(df)
collapse::fsummarise(collapse::fgroup_by(df, g), d = collapse::fmean(d))
#>   g       d
#> 1 0 1250000
#> 2 1 1249999
#> 3 2 1250000
q <- collapse::qDT(df)
class(q)
#> [1] "data.table" "data.frame"
identical(lobstr::obj_addrs(q), cols)
#> [1] TRUE

dbDisconnect(con)
```

<sup>Created on 2026-09-28 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

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
#>  date     2026-09-28
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version          date (UTC) lib source
#>  cli           3.6.6            2026-04-09 [2] RSPM
#>  collapse      2.1.8            2026-08-30 [1] RSPM (R 4.5.0)
#>  data.table    1.18.6.1         2026-08-24 [2] RSPM
#>  DBI         * 1.3.0            2026-02-25 [2] RSPM
#>  digest        0.6.39           2025-11-19 [2] RSPM
#>  duckdb        1.5.5.9029       2026-09-28 [1] local
#>  evaluate      1.0.5            2025-08-27 [2] RSPM
#>  fastmap       1.2.0            2024-05-15 [2] RSPM
#>  fs            2.1.0            2026-04-18 [2] RSPM
#>  glue          1.8.1            2026-04-17 [2] RSPM
#>  htmltools     0.5.9            2025-12-04 [2] RSPM
#>  knitr         1.52             2026-09-06 [2] RSPM
#>  lifecycle     1.0.5            2026-01-08 [2] RSPM
#>  lobstr        1.2.2            2026-09-01 [1] RSPM (R 4.5.0)
#>  nanoarrow     0.9.0            2026-08-04 [2] RSPM (R 4.5.0)
#>  otel          0.2.0            2025-08-29 [2] RSPM
#>  polars        1.9000.9000.9000 2026-09-23 [1] https://rpolars.r-universe.dev (R 4.5.3)
#>  Rcpp          1.1.2            2026-07-05 [2] RSPM
#>  reprex        2.1.1            2024-07-06 [2] RSPM
#>  rlang         1.3.0            2026-07-05 [2] RSPM
#>  rmarkdown     2.32             2026-09-01 [2] RSPM
#>  S7            0.2.2            2026-04-22 [2] RSPM
#>  sessioninfo   1.2.4            2026-06-04 [2] RSPM
#>  withr         3.0.3            2026-06-19 [2] RSPM
#>  xfun          0.61             2026-09-16 [2] RSPM
#>  yaml          2.3.12           2025-12-10 [2] RSPM
#> 
#>  [1] <scratch library>
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
