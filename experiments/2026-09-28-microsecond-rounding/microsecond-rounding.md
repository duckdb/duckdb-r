``` r
## How a POSIXct and a difftime round to the microsecond:
## on the write routes, in dbQuoteLiteral(), and in the engine's own conversions.
library(DBI)

con <- dbConnect(duckdb::duckdb(shared_home = FALSE))

## Ties, one microsecond apart ----------------------------------------------------
## 2.5 us and 3.5 us are ties once scaled; half to even takes both to an even
## number, half away from zero takes them outward.
s <- c(2.5e-6, 3.5e-6, -2.5e-6, -3.5e-6)
s * 1e6 - trunc(s * 1e6)
#> [1]  0.5  0.5 -0.5 -0.5
x <- .POSIXct(s, tz = "UTC")
d <- as.difftime(s, units = "secs")

# dbWriteTable(), duckdb_register() and dbAppendTable() all convert in the glue
df <- data.frame(i = seq_along(s), x = x, d = d)
dbWriteTable(con, "written", df)
duckdb::duckdb_register(con, "registered", df)
dbCreateTable(con, "appended", c(i = "INTEGER", x = "TIMESTAMP", d = "INTERVAL"))
dbAppendTable(con, "appended", df)
us <- "SELECT epoch_us(x) AS x_us, to_microseconds(0) + d AS d FROM %s ORDER BY i"
dbGetQuery(con, sprintf(us, "written"))
#>   x_us           d
#> 1    3  3e-06 secs
#> 2    4  4e-06 secs
#> 3   -3 -3e-06 secs
#> 4   -4 -4e-06 secs
dbGetQuery(con, sprintf(us, "registered"))
#>   x_us           d
#> 1    3  3e-06 secs
#> 2    4  4e-06 secs
#> 3   -3 -3e-06 secs
#> 4   -4 -4e-06 secs
dbGetQuery(con, sprintf(us, "appended"))
#>   x_us           d
#> 1    3  3e-06 secs
#> 2    4  4e-06 secs
#> 3   -3 -3e-06 secs
#> 4   -4 -4e-06 secs

# A parameter binds through the same conversion
dbGetQuery(con, "SELECT epoch_us(?) AS x_us", params = list(x))
#>   x_us
#> 1    3
#> 2    4
#> 3   -3
#> 4   -4

# dbQuoteLiteral() rounds in R, with round()
dbQuoteLiteral(con, x)
#> <SQL> '1970-01-01 00:00:00.000002'::timestamp
#> <SQL> '1970-01-01 00:00:00.000004'::timestamp
#> <SQL> '1969-12-31 23:59:59.999998'::timestamp
#> <SQL> '1969-12-31 23:59:59.999996'::timestamp
dbQuoteLiteral(con, d)
#> <SQL> to_microseconds(2)
#> <SQL> to_microseconds(4)
#> <SQL> to_microseconds(-2)
#> <SQL> to_microseconds(-4)
round(s * 1e6)
#> [1]  2  4 -2 -4

# The engine's own conversions from a double
dbGetQuery(con, "
  SELECT v,
    CAST(v AS BIGINT) AS cast_bigint,
    epoch_us(to_timestamp(v / 1e6)) AS to_timestamp_us,
    round(v) AS round_fn
  FROM (VALUES (2.5::DOUBLE), (3.5), (-2.5), (-3.5)) t(v)
")
#>      v cast_bigint to_timestamp_us round_fn
#> 1  2.5           2               2        3
#> 2  3.5           4               4        4
#> 3 -2.5          -2              -2       -3
#> 4 -3.5          -4              -4       -4

## How often, for present-day instants -----------------------------------------
## Near 1.7e9 seconds, the product with 1e6 is a double whose spacing is 0.25,
## so a quarter of all values land exactly on a half microsecond.
set.seed(20260928)
secs <- 1.7e9 + runif(1e5, 0, 1e7)
p <- secs * 1e6
mean(p - trunc(p) == 0.5)
#> [1] 0.25153

now <- data.frame(i = seq_along(secs), x = .POSIXct(secs, tz = "UTC"), s = secs)
dbWriteTable(con, "now", now)
res <- dbGetQuery(con, "
  SELECT epoch_us(x) AS written, epoch_us(to_timestamp(s)) AS engine
  FROM now ORDER BY i
")
quoted <- round(p)

# Share that differs, and by how much
mean(res$written != quoted)
#> [1] 0.1269
mean(res$written != res$engine)
#> [1] 0.1269
mean(quoted != res$engine)
#> [1] 0
max(abs(res$written - quoted))
#> [1] 1

## What it costs -----------------------------------------------------------------
## A literal quoted from the value that was written does not find its row.
k <- which(res$written != quoted)[1]
lit <- dbQuoteLiteral(con, now$x[k])
lit
#> <SQL> '2023-11-18 22:22:24.032664'::timestamp
dbGetQuery(con, paste0("SELECT count(*) AS n FROM now WHERE x = ", lit))
#>   n
#> 1 0
dbGetQuery(con, "SELECT count(*) AS n FROM now WHERE x = ?", params = list(now$x[k]))
#>   n
#> 1 1

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
#>  package     * version    date (UTC) lib source
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb        1.5.5.9900 2026-09-28 [1] local
#>  evaluate      1.0.5      2025-08-27 [1] RSPM
#>  fastmap       1.2.0      2024-05-15 [1] RSPM
#>  fs            2.1.0      2026-04-18 [1] RSPM
#>  glue          1.8.1      2026-04-17 [1] RSPM
#>  htmltools     0.5.9      2025-12-04 [1] RSPM
#>  knitr         1.52       2026-09-06 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  pillar        1.11.1     2025-09-17 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.32       2026-09-01 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  vctrs         0.7.3      2026-04-11 [1] RSPM
#>  withr         3.0.3      2026-06-19 [1] RSPM
#>  xfun          0.61       2026-09-16 [1] RSPM
#>  yaml          2.3.12     2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
