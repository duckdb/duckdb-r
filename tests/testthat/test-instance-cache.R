# The engine patch these guard --
# `patch/0042-Tell-a-database-still-in-use-from-a-shutdown-in-flight.patch` --
# is not reachable from R here: `rapi_startup()` builds a `DuckDB` directly, so
# no R call enters `DBInstanceCache`. It becomes reachable with
# duckdb/duckdb-r#2644, where these two sequences wedged the session at 100% CPU.
# The subprocess is what makes the test safe to run either way: a spin inside
# `.Call()` reaches no interrupt check, so only a killed process ends it.

test_that("reopening a database that something still holds open returns", {
  skip_if_not_installed("callr")

  dir <- withr::local_tempdir()

  answers <- callr::r(
    function(dir) {
      library(duckdb)

      reopen <- function(path) {
        tryCatch(
          {
            con <- dbConnect(duckdb(path))
            dbDisconnect(con)
            "reopened"
          },
          error = function(e) conditionMessage(e)
        )
      }

      # An unfinished result holds the connection's context, which holds the
      # instance, past the release of the last driver reference.
      held_by_result <- file.path(dir, "result.duckdb")
      con <- dbConnect(duckdb(held_by_result))
      res <- dbSendQuery(con, "SELECT 42")
      dbDisconnect(con)

      # A connection that is simply still open holds it too.
      held_by_connection <- file.path(dir, "connection.duckdb")
      drv <- duckdb(held_by_connection)
      open_con <- dbConnect(drv)

      out <- c(
        result = reopen(held_by_result),
        connection = reopen(held_by_connection)
      )

      dbClearResult(res)
      dbDisconnect(open_con)
      out
    },
    args = list(dir = dir),
    timeout = 60
  )

  # Reopening and refusing are both answers. Hanging is not, and is what the
  # timeout above turns into a failure rather than a stuck test run.
  expect_type(answers, "character")
  expect_named(answers, c("result", "connection"))
})
