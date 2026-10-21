## What the ROW_NUMBER() plan dbplyr emits costs, against DISTINCT ON,
## for the same question -- and whether any regime turns that around.
library(duckdb)
library(dplyr, warn.conflicts = FALSE)
library(dbplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
packageVersion("dbplyr")

con <- dbConnect(duckdb(dbdir = tempfile(fileext = ".duckdb")))
dbExecute(con, "SET threads = 1")

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

## 2. Three regimes where DISTINCT ON might have the edge -------------------

# the table is now 2M-ish groups, narrow; keep it and add a sorted copy
dbExecute(
  con,
  "CREATE OR REPLACE TABLE t_sorted AS SELECT * FROM t ORDER BY k, k2, ord"
)

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

## 3. The comparison that decides it ----------------------------------------
## dbplyr, with no arrange() in the pipeline, orders by the first column --
## which is one of the partition keys, so the pick is arbitrary either way.
## That is the same question DISTINCT ON answers with no ORDER BY at all.

dbplyr_plan <- as.character(
  sql_render(tbl(con, "t") |> distinct(k, k2, .keep_all = TRUE))
)
dbplyr_plan

cat(sprintf(
  "same question, both plans   | dbplyr's ROW_NUMBER %5.2f | DISTINCT ON %5.2f\n",
  timing(dbplyr_plan, reps = 3),
  timing(distinct_on_bare, reps = 3)
))
dbGetQuery(con, sprintf("SELECT count(*) AS n FROM (%s)", dbplyr_plan))$n ==
  dbGetQuery(con, sprintf("SELECT count(*) AS n FROM (%s)", distinct_on_bare))$n

## 4. And with the cores the machine has ------------------------------------

dbExecute(con, "SET threads = 4")
cat(sprintf(
  "threads = 4                 | ROW_NUMBER %5.2f | DISTINCT ON %5.2f | unordered %5.2f\n",
  timing(row_number),
  timing(distinct_on),
  timing(distinct_on_bare)
))

dbDisconnect(con, shutdown = TRUE)
