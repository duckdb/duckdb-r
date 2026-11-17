``` r
# Seconds per call of a summary on a converted lazy column of rel_to_altrep(),
# against the same values in a plain vector, mean of five calls.
# Handbook: experiments/2026-11-17-lazy-vector-summaries/README.md
con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE))
seconds <- function(expr) {
  unname(
    system.time(
      for (k in 1:5) {
        force(expr)
      }
    )[["elapsed"]] /
      5
  )
}
once <- function(expr) unname(system.time(expr)[["elapsed"]])
sql <- paste(
  "SELECT random() AS x, (random() * 100)::INTEGER AS i,",
  "random() < 0.5 AS l, 'a' || (range % 10)::VARCHAR AS s",
  "FROM range(10000000)"
)
lazy <- function() duckdb:::rel_to_altrep(duckdb:::rel_from_sql(con, sql))

# First touch of an unconverted column, conversion included
data.frame(
  op = c("sum(l)", "anyNA(l)", "anyNA(s)", "unique(s)"),
  first_call = c(
    once(sum(lazy()$l)),
    once(anyNA(lazy()$l)),
    once(anyNA(lazy()$s)),
    once(unique(lazy()$s))
  )
)
#>          op first_call
#> 1    sum(l)      0.862
#> 2  anyNA(l)      1.503
#> 3  anyNA(s)      1.736
#> 4 unique(s)      5.523

df <- lazy()
x <- df$x
i <- df$i
l <- df$l
s <- df$s
# Converts each column
invisible(list(x[[1]], i[[1]], l[[1]], s[[1]]))
x_plain <- x + 0
i_plain <- i + 0L
l_plain <- !!l
s_plain <- s[seq_along(s)]

ops <- c("sum()", "max()", "range()", "anyNA()", "mean()", "c()", "* 2")
data.frame(
  op = ops,
  double_altrep = c(
    seconds(sum(x)),
    seconds(max(x)),
    seconds(range(x)),
    seconds(anyNA(x)),
    seconds(mean(x)),
    seconds(c(x)),
    seconds(x * 2)
  ),
  double_plain = c(
    seconds(sum(x_plain)),
    seconds(max(x_plain)),
    seconds(range(x_plain)),
    seconds(anyNA(x_plain)),
    seconds(mean(x_plain)),
    seconds(c(x_plain)),
    seconds(x_plain * 2)
  ),
  integer_altrep = c(
    seconds(sum(i)),
    seconds(max(i)),
    seconds(range(i)),
    seconds(anyNA(i)),
    seconds(mean(i)),
    seconds(c(i)),
    seconds(i * 2L)
  ),
  integer_plain = c(
    seconds(sum(i_plain)),
    seconds(max(i_plain)),
    seconds(range(i_plain)),
    seconds(anyNA(i_plain)),
    seconds(mean(i_plain)),
    seconds(c(i_plain)),
    seconds(i_plain * 2L)
  )
)
#>        op double_altrep double_plain integer_altrep integer_plain
#> 1   sum()        0.0040       0.0038         0.0024        0.0022
#> 2   max()        0.0084       0.0076         0.0036        0.0036
#> 3 range()        0.3236       0.0262         0.2954        0.0146
#> 4 anyNA()        0.0034       0.0032         0.0018        0.0018
#> 5  mean()        0.0086       0.0092         0.1570        0.0038
#> 6     c()        0.2666       0.0102         0.2766        0.0056
#> 7     * 2        0.0084       0.0082         0.0094        0.0092

data.frame(
  op = c("sum(l)", "anyNA(l)", "c(l)", "anyNA(s)", "unique(s)", "c(s)"),
  altrep = c(
    seconds(sum(l)),
    seconds(anyNA(l)),
    seconds(c(l)),
    seconds(anyNA(s)),
    seconds(unique(s)),
    seconds(c(s))
  ),
  plain = c(
    seconds(sum(l_plain)),
    seconds(anyNA(l_plain)),
    seconds(c(l_plain)),
    seconds(anyNA(s_plain)),
    seconds(unique(s_plain)),
    seconds(c(s_plain))
  )
)
#>          op altrep  plain
#> 1    sum(l) 0.0020 0.0022
#> 2  anyNA(l) 0.1590 0.0028
#> 3      c(l) 0.2816 0.0062
#> 4  anyNA(s) 0.1334 0.0028
#> 5 unique(s) 0.8786 0.0452
#> 6      c(s) 0.3338 0.0164
```

<sup>Created on 2026-11-17 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.5 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-11-17
#>  pandoc   3.10.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.10.19 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI           1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb        2.0.0.9000 2026-11-17 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  otel          0.3.0      2026-11-07 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
#>  withr         3.0.3      2026-06-19 [2] RSPM
#>  xfun          0.62       2026-10-16 [2] RSPM
#>  yaml          2.3.12     2025-12-10 [2] RSPM
#> 
#>  [1] <base build library>
#>  [2] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [3] /opt/R/4.5.3/lib/R/library
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

</details>
