# A parallel scan of list cells, for the tests of what a task thread may do:
# handbook/architecture/glue/threading/README.md

# Runs `sql` at four threads against a registered data frame of `n` rows,
# whose list columns, named as `cells` is, repeat one cell in every row.
# The scan starts a task per million rows, so `n` decides how many tasks share a column.
# The subprocess and its timeout are so that a scan that crashes or hangs
# is a failure of the calling test rather than a suite that stops.
# An error comes back as its class and fields.
scan_repeated_cells <- function(cells, sql, n = 2000000L) {
  callr::r(
    function(pkg, cells, sql, n) {
      ns <- asNamespace(pkg)

      con <- DBI::dbConnect(ns$duckdb())
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      DBI::dbExecute(con, "SET threads=4")

      df <- data.frame(id = seq_len(n))
      for (name in names(cells)) {
        df[[name]] <- rep(list(cells[[name]]), n)
      }
      ns$duckdb_register(con, "cells", df)

      tryCatch(
        DBI::dbGetQuery(con, sql),
        error = function(e) {
          list(class = class(e), context = e$context, error_type = e$error_type)
        }
      )
    },
    list(pkg = get_package_name(), cells = cells, sql = sql, n = n),
    timeout = 120
  )
}
