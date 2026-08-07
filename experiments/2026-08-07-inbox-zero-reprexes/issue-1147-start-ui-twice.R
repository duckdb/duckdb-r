## duckdb-r#1147 -- R crashes calling start_ui() with an overwritten
## connection object. The failure is an abort, not an R error, so each
## variant runs in its own process and we look at the exit status.
library(duckdb)
packageVersion("duckdb")

variant <- function(...) {
  script <- tempfile(fileext = ".R")
  writeLines(c("library(duckdb)", ...), script)
  out <- processx::run(
    file.path(R.home("bin"), "Rscript"),
    script,
    error_on_status = FALSE,
    stderr_to_stdout = TRUE
  )
  cat(out$stdout)
  cat("exit status:", out$status, "\n")
}

# 1. The reporter's sequence: the second connection lands on the same name,
#    so the first database is finalised while its UI server is still up
variant(
  'con <- DBI::dbConnect(duckdb::duckdb())',
  'DBI::dbExecute(con, "INSTALL ui")',
  'DBI::dbExecute(con, "CALL start_ui_server()")',
  'con <- DBI::dbConnect(duckdb::duckdb())',
  'gc()',
  'DBI::dbExecute(con, "CALL start_ui_server()")',
  'cat("survived\\n")'
)

# 2. Same shape, but the first database stays alive: no crash
variant(
  'con <- DBI::dbConnect(duckdb::duckdb())',
  'DBI::dbExecute(con, "INSTALL ui")',
  'DBI::dbExecute(con, "CALL start_ui_server()")',
  'con2 <- DBI::dbConnect(duckdb::duckdb())',
  'DBI::dbExecute(con2, "CALL start_ui_server()")',
  'cat("survived\\n")'
)

# 3. Same shape, but the server is stopped before its database goes away
variant(
  'con <- DBI::dbConnect(duckdb::duckdb())',
  'DBI::dbExecute(con, "INSTALL ui")',
  'DBI::dbExecute(con, "CALL start_ui_server()")',
  'DBI::dbExecute(con, "CALL stop_ui_server()")',
  'con <- DBI::dbConnect(duckdb::duckdb())',
  'gc()',
  'DBI::dbExecute(con, "CALL start_ui_server()")',
  'cat("survived\\n")'
)

# 4. And the timing: give the finalised database a moment before the new
#    server starts, and the same sequence survives
variant(
  'con <- DBI::dbConnect(duckdb::duckdb())',
  'DBI::dbExecute(con, "INSTALL ui")',
  'DBI::dbExecute(con, "CALL start_ui_server()")',
  'con <- DBI::dbConnect(duckdb::duckdb())',
  'gc()',
  'Sys.sleep(2)',
  'DBI::dbExecute(con, "CALL start_ui_server()")',
  'cat("survived\\n")'
)

# which extension build this was
con <- dbConnect(duckdb())
dbExecute(con, "LOAD ui")
dbGetQuery(
  con,
  "SELECT extension_name, extension_version, install_mode
   FROM duckdb_extensions() WHERE extension_name = 'ui'"
)
dbDisconnect(con, shutdown = TRUE)
