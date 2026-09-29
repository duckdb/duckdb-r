``` r
## Three limits of running statements: an INSTALL or LOAD that stops a whole
## string, a PRAGMA's expansion left half done while a stream is open, and a
## parameter that invalidates the database.
library(DBI)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))

## allow_extensions = FALSE ----------------------------------------------------
con <- dbConnect(duckdb::duckdb(allow_extensions = FALSE, shared_home = FALSE))
tryCatch(
  dbExecute(con, "CREATE TABLE l1 (i INTEGER); LOAD parquet"),
  error = first_line
)
#> [1] "DuckDB extension loading (INSTALL / LOAD) is disabled for this driver."
dbExistsTable(con, "l1")
#> [1] FALSE
# Any other failing statement leaves the ones before it in effect.
tryCatch(
  dbExecute(con, "CREATE TABLE l2 (i INTEGER); SELECT * FROM nope"),
  error = first_line
)
#> [1] "Catalog Error: Table with name nope does not exist!"
dbExistsTable(con, "l2")
#> [1] TRUE
dbDisconnect(con)

## A PRAGMA's expansion while a stream is open ---------------------------------
# An export of two tables, and the second table's CSV made unparseable.
dir <- tempfile("export")
src <- dbConnect(duckdb::duckdb(shared_home = FALSE))
dbExecute(src, "CREATE TABLE a AS SELECT 1 AS i")
#> [1] 1
dbExecute(src, "CREATE TABLE b AS SELECT 2 AS i")
#> [1] 1
dbExecute(src, sprintf("EXPORT DATABASE '%s'", dir))
#> [1] 0
dbDisconnect(src)
writeLines(c("i", "not a number"), file.path(dir, "b.csv"))
import <- sprintf("PRAGMA import_database('%s')", dir)

# Without a stream, the failure rolls the whole expansion back.
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))
tryCatch(dbExecute(con, import), error = first_line)
#> [1] "Conversion Error: CSV Error on Line: 2"
dbGetQuery(con, "SELECT table_name FROM duckdb_tables()")
#> [1] table_name
#> <0 rows> (or 0-length row.names)
dbDisconnect(con)

# With a stream open on the connection, the statements before it stay.
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))
res <- dbSendQueryArrow(con, "SELECT * FROM range(10000000)")
tryCatch(dbExecute(con, import), error = first_line)
#> [1] "Conversion Error: CSV Error on Line: 2"
dbGetQuery(
  con,
  "SELECT (SELECT count(*) FROM a) AS a_rows, (SELECT count(*) FROM b) AS b_rows"
)
#>   a_rows b_rows
#> 1      1      0
tryCatch(dbRollback(con), error = first_line)
#> [1] "TransactionContext Error: cannot rollback - no transaction is active"
dbClearResult(res)
dbDisconnect(con)

## One character parameter inside typeof() and in a cast ------------------------
# Each case runs in a session of its own, because the error invalidates the
# database.
sql <- "SELECT typeof($1) AS type, $1::VARCHAR AS text"
in_session <- function(f) {
  callr::r(f, args = list(sql = sql), libpath = .libPaths())
}

in_session(function(sql) {
  first_line <- function(e) sub("\n.*", "", conditionMessage(e))
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE))
  list(
    query = tryCatch(
      DBI::dbGetQuery(con, sql, params = list("ok")),
      error = first_line
    ),
    next_statement = tryCatch(
      DBI::dbGetQuery(con, "SELECT 42"),
      error = first_line
    ),
    new_connection = tryCatch(DBI::dbConnect(con@driver), error = first_line)
  )
})
#> $query
#> [1] "INTERNAL Error: Invalid PhysicalType for GetTypeIdSize"
#> 
#> $next_statement
#> [1] "FATAL Error: Failed: database has been invalidated because of a previous fatal error. The database must be restarted prior to being used again."
#> 
#> $new_connection
#> [1] "FATAL Error: Failed: database has been invalidated because of a previous fatal error. The database must be restarted prior to being used again."

# Other classes, and a character value bound to two parameters, answer.
in_session(function(sql) {
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE))
  rbind(
    DBI::dbGetQuery(con, sql, params = list(1L)),
    DBI::dbGetQuery(con, sql, params = list(1.5)),
    DBI::dbGetQuery(con, sql, params = list(TRUE)),
    DBI::dbGetQuery(con, sql, params = list(as.Date("2026-09-27"))),
    DBI::dbGetQuery(
      con,
      "SELECT typeof(?) AS type, ?::VARCHAR AS text",
      params = list("ok", "ok")
    )
  )
})
#>      type       text
#> 1 INTEGER          1
#> 2  DOUBLE        1.5
#> 3 BOOLEAN       true
#> 4    DATE 2026-09-27
#> 5 VARCHAR         ok

# On a file, a new driver gets the same instance until duckdb_shutdown().
in_session(function(sql) {
  first_line <- function(e) sub("\n.*", "", conditionMessage(e))
  path <- tempfile(fileext = ".duckdb")
  drv <- duckdb::duckdb(path)
  con <- DBI::dbConnect(drv)
  DBI::dbWriteTable(con, "t", data.frame(x = 1:3))
  count <- function() {
    con <- DBI::dbConnect(duckdb::duckdb(path))
    DBI::dbGetQuery(con, "SELECT count(*) AS n FROM t")$n
  }
  list(
    query = tryCatch(
      DBI::dbGetQuery(con, sql, params = list("ok")),
      error = first_line
    ),
    new_driver = tryCatch(count(), error = first_line),
    after_shutdown = {
      duckdb::duckdb_shutdown(drv)
      count()
    }
  )
})
#> $query
#> [1] "INTERNAL Error: Invalid PhysicalType for GetTypeIdSize"
#> 
#> $new_driver
#> [1] "FATAL Error: Failed: database has been invalidated because of a previous fatal error. The database must be restarted prior to being used again."
#> 
#> $after_shutdown
#> [1] 3
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
#>  callr         3.8.0      2026-06-05 [2] RSPM
#>  cli           3.6.6      2026-04-09 [2] RSPM
#>  DBI         * 1.3.0      2026-02-25 [2] RSPM
#>  digest        0.6.39     2025-11-19 [2] RSPM
#>  duckdb        1.5.5.9028 2026-09-27 [1] local
#>  evaluate      1.0.5      2025-08-27 [2] RSPM
#>  fastmap       1.2.0      2024-05-15 [2] RSPM
#>  fs            2.1.0      2026-04-18 [2] RSPM
#>  glue          1.8.1      2026-04-17 [2] RSPM
#>  htmltools     0.5.9      2025-12-04 [2] RSPM
#>  knitr         1.52       2026-09-06 [2] RSPM
#>  lifecycle     1.0.5      2026-01-08 [2] RSPM
#>  nanoarrow     0.9.0      2026-08-04 [2] RSPM (R 4.5.0)
#>  otel          0.2.0      2025-08-29 [2] RSPM
#>  pillar        1.11.1     2025-09-17 [2] RSPM
#>  processx      3.9.0      2026-04-22 [2] RSPM
#>  ps            1.9.3      2026-04-20 [2] RSPM
#>  R6            2.6.1      2025-02-15 [2] RSPM
#>  reprex        2.1.1      2024-07-06 [2] RSPM
#>  rlang         1.3.0      2026-07-05 [2] RSPM
#>  rmarkdown     2.32       2026-09-01 [2] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [2] RSPM
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
