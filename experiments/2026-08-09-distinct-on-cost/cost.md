``` r
## What the ROW_NUMBER() plan dbplyr emits costs, against DISTINCT ON,
## for the same question -- and whether any regime turns that around.
library(duckdb)
#> Loading required package: DBI
library(dplyr, warn.conflicts = FALSE)
library(dbplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
#> [1] '1.5.5'
packageVersion("dbplyr")
#> [1] '2.6.0'

con <- dbConnect(duckdb(dbdir = tempfile(fileext = ".duckdb")))
dbExecute(con, "SET threads = 1")
#> [1] 0

build <- function(groups, width) {
  extra <- if (width == "wide") {
    paste(sprintf(", (i %% %d)::DOUBLE AS p%d", 3:10, 3:10), collapse = "")
  } else {
    ""
  }
  dbExecute(
    con,
    sprintf(
      "CREATE OR REPLACE TABLE t AS
         SELECT (hash(i) %% %d)::DOUBLE   AS k,
                ('s' || (hash(i + 3) %% 20)) AS k2,
                (i %% 977)::DOUBLE        AS ord,
                (i %% 13)::DOUBLE         AS p1,
                (i %% 7)::DOUBLE          AS p2 %s
         FROM range(20000000) t(i)",
      groups,
      extra
    )
  )
  dbGetQuery(con, "SELECT count(DISTINCT (k, k2)) AS g FROM t")$g
}

timing <- function(sql, reps = 2) {
  median(replicate(reps, {
    t0 <- Sys.time()
    dbGetQuery(con, sprintf("SELECT count(*) AS n FROM (%s)", sql))
    as.numeric(difftime(Sys.time(), t0, units = "secs"))
  }))
}

## 1. The grid: does cardinality, width or a LIMIT change the answer? -------

row_number <- "SELECT * FROM (
   SELECT *, ROW_NUMBER() OVER (PARTITION BY k, k2 ORDER BY ord) AS c FROM t
 ) q WHERE c = 1"
distinct_on <- "SELECT DISTINCT ON (k, k2) * FROM t ORDER BY k, k2, ord"
distinct_on_bare <- "SELECT DISTINCT ON (k, k2) * FROM t"
with_limit <- function(sql) paste(sql, "LIMIT 10")

for (groups in c(200L, 2000000L)) {
  for (width in c("narrow", "wide")) {
    n <- build(groups, width)
    cat(sprintf(
      "%8d groups %-6s | ROW_NUMBER %5.2f | DISTINCT ON %5.2f | unordered %5.2f | +LIMIT %5.2f / %5.2f\n",
      n,
      width,
      timing(row_number),
      timing(distinct_on),
      timing(distinct_on_bare),
      timing(with_limit(row_number)),
      timing(with_limit(distinct_on))
    ))
  }
}
#>     4000 groups narrow | ROW_NUMBER  0.60 | DISTINCT ON  1.14 | unordered  0.40 | +LIMIT  0.58 /  1.15
#>     4000 groups wide   | ROW_NUMBER  0.56 | DISTINCT ON  1.12 | unordered  0.39 | +LIMIT  0.56 /  1.11
#> 15737882 groups narrow | ROW_NUMBER  7.07 | DISTINCT ON  8.97 | unordered  3.08 | +LIMIT  3.87 /  4.82
#> 15737882 groups wide   | ROW_NUMBER  4.46 | DISTINCT ON  8.15 | unordered  3.04 | +LIMIT  3.83 /  5.35

## 2. Three regimes where DISTINCT ON might have the edge -------------------

# the table is now 2M-ish groups, narrow; keep it and add a sorted copy
dbExecute(
  con,
  "CREATE OR REPLACE TABLE t_sorted AS SELECT * FROM t ORDER BY k, k2, ord"
)
#> [1] 2e+07

# (a) nothing to tie-break on: the ordering is the ON list itself
cat(sprintf(
  "ordering = the ON columns   | ROW_NUMBER %5.2f | DISTINCT ON %5.2f\n",
  timing(
    "SELECT * FROM (
     SELECT *, ROW_NUMBER() OVER (PARTITION BY k, k2 ORDER BY k) AS c FROM t
   ) q WHERE c = 1"
  ),
  timing("SELECT DISTINCT ON (k, k2) * FROM t ORDER BY k, k2")
))
#> ordering = the ON columns   | ROW_NUMBER  3.09 | DISTINCT ON  5.06

# (b) the input is already stored in the order the pick needs
cat(sprintf(
  "input physically sorted     | ROW_NUMBER %5.2f | DISTINCT ON %5.2f\n",
  timing(
    "SELECT * FROM (
     SELECT *, ROW_NUMBER() OVER (PARTITION BY k, k2 ORDER BY ord) AS c
     FROM t_sorted
   ) q WHERE c = 1"
  ),
  timing("SELECT DISTINCT ON (k, k2) * FROM t_sorted ORDER BY k, k2, ord")
))
#> input physically sorted     | ROW_NUMBER  2.86 | DISTINCT ON  6.03

# (c) the caller wants the output sorted by the keys anyway, so DISTINCT ON's
#     mandatory sort would not be wasted work
cat(sprintf(
  "output wanted sorted        | ROW_NUMBER %5.2f | DISTINCT ON %5.2f\n",
  timing(
    "SELECT * FROM (
     SELECT * FROM (
       SELECT *, ROW_NUMBER() OVER (PARTITION BY k, k2 ORDER BY ord) AS c FROM t
     ) q WHERE c = 1
   ) r ORDER BY k, k2"
  ),
  timing(distinct_on)
))
#> output wanted sorted        | ROW_NUMBER  5.02 | DISTINCT ON  7.24

## 3. The comparison that decides it ----------------------------------------
## dbplyr, with no arrange() in the pipeline, orders by the first column --
## which is one of the partition keys, so the pick is arbitrary either way.
## That is the same question DISTINCT ON answers with no ORDER BY at all.

dbplyr_plan <- as.character(
  sql_render(tbl(con, "t") |> distinct(k, k2, .keep_all = TRUE))
)
dbplyr_plan
#> [1] "SELECT k, k2, ord, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10\nFROM (\n  SELECT *, ROW_NUMBER() OVER (PARTITION BY k, k2 ORDER BY k) AS col01\n  FROM t\n) AS q01\nWHERE (col01 = 1)"

cat(sprintf(
  "same question, both plans   | dbplyr's ROW_NUMBER %5.2f | DISTINCT ON %5.2f\n",
  timing(dbplyr_plan, reps = 3),
  timing(distinct_on_bare, reps = 3)
))
#> same question, both plans   | dbplyr's ROW_NUMBER  2.81 | DISTINCT ON  2.96
dbGetQuery(con, sprintf("SELECT count(*) AS n FROM (%s)", dbplyr_plan))$n ==
  dbGetQuery(con, sprintf("SELECT count(*) AS n FROM (%s)", distinct_on_bare))$n
#> [1] TRUE

## 4. And with the cores the machine has ------------------------------------

dbExecute(con, "SET threads = 4")
#> [1] 0
cat(sprintf(
  "threads = 4                 | ROW_NUMBER %5.2f | DISTINCT ON %5.2f | unordered %5.2f\n",
  timing(row_number),
  timing(distinct_on),
  timing(distinct_on_bare)
))
#> threads = 4                 | ROW_NUMBER  0.71 | DISTINCT ON  1.94 | unordered  0.46

dbDisconnect(con, shutdown = TRUE)
```

<sup>Created on 2026-08-09 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
