# Reading a table of an ATTACHed Quack server.
#
# The Quack server answers a query's PREPARE with its first batches inline
# and keeps the rest for FETCH requests (see `local_quack_server()`).
# Since duckdb/duckdb-r#2972, a result that needs a FETCH fails:
# with an attached remote catalog, the engine's remote pushdown rewrites the
# query into `quack_query_by_name()` while it is prepared,
# and binding that function runs the query on the server.
# R prepares and executes a statement as two calls, each in its own
# auto-commit transaction, so the client's COMMIT reaches the server between
# them and closes the result the execution then FETCHes from.
# The DuckDB CLI fails the same way with `PREPARE` and `EXECUTE`.
#
# The tables are sized from `quack_inline_rows`.
# One below it is read whole from the PREPARE answer,
# because the server has to wait for the end of the result to stop short of it.
# Exactly that many rows is a race, as the server may stop before it sees the end.
# One more needs a second batch, and so a FETCH.

test_that("a Quack result within the inline rows reads whole", {
  server <- local_quack_server()
  n <- quack_inline_rows - 1L
  dbExecute(server$con, paste0("CREATE TABLE t AS FROM range(", n, ")"))
  con <- local_quack_client(server)

  out <- dbGetQuery(con, "SELECT * FROM rem.main.t")
  expect_equal(nrow(out), n)
})

test_that("a Quack result past the inline rows fails (duckdb/duckdb-r#2972)", {
  server <- local_quack_server()
  n <- quack_inline_rows + 1L
  dbExecute(server$con, paste0("CREATE TABLE t AS FROM range(", n, ")"))
  con <- local_quack_client(server)

  # A canary for the upstream bug, not the behavior we want.
  # The day this expectation fails, the engine or the extension has fixed it:
  # assert that `nrow()` equals `n` instead,
  # and drop the two workaround tests below or keep them as plain reads,
  # since they then test nothing the fixed path does not.
  expect_error(
    dbGetQuery(con, "SELECT * FROM rem.main.t"),
    "Result has been closed"
  )
})

test_that("a Quack result past the inline rows reads whole without remote pushdown", {
  server <- local_quack_server()
  n <- quack_inline_rows + 1L
  dbExecute(server$con, paste0("CREATE TABLE t AS FROM range(", n, ")"))
  con <- local_quack_client(server)

  # A workaround for duckdb/duckdb-r#2972:
  # without the rewrite, the scan runs its remote query when it executes.
  dbExecute(con, "SET disabled_optimizers = 'remote_pushdown'")
  out <- dbGetQuery(con, "SELECT * FROM rem.main.t")
  expect_equal(nrow(out), n)
})

test_that("a Quack result past the inline rows reads whole in a transaction", {
  server <- local_quack_server()
  n <- quack_inline_rows + 1L
  dbExecute(server$con, paste0("CREATE TABLE t AS FROM range(", n, ")"))
  con <- local_quack_client(server)

  # A workaround for duckdb/duckdb-r#2972:
  # inside an explicit transaction, nothing commits between prepare and execute.
  out <- dbWithTransaction(con, dbGetQuery(con, "SELECT * FROM rem.main.t"))
  expect_equal(nrow(out), n)
})
