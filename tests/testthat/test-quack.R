# Reading a table of an ATTACHed Quack server.
#
# The Quack server answers a query's PREPARE with the first batches inline
# (60 vectors of 2048 rows here) and keeps the rest for FETCH requests.
# Since duckdb/duckdb-r#2972, a result past those first batches fails:
# with an attached remote catalog, the engine's remote pushdown rewrites the
# query into `quack_query_by_name()` while it is prepared,
# and binding that function runs the query on the server.
# R prepares and executes a statement as two calls, each in its own
# auto-commit transaction, so the client's COMMIT reaches the server between
# them and closes the result the execution then FETCHes from.
# The DuckDB CLI fails the same way with `PREPARE` and `EXECUTE`.

test_that("a Quack result within the inline batches reads whole", {
  server <- local_quack_server()
  dbExecute(server$con, "CREATE TABLE repro AS FROM range(122881)")
  con <- local_quack_client(server)

  out <- dbGetQuery(con, "SELECT * FROM rem.main.repro LIMIT 122880")
  expect_equal(nrow(out), 122880)
})

test_that("a Quack result past the inline batches fails (duckdb/duckdb-r#2972)", {
  server <- local_quack_server()
  dbExecute(server$con, "CREATE TABLE repro AS FROM range(122881)")
  con <- local_quack_client(server)

  # A canary for the upstream bug, not the behavior we want.
  # The day this expectation fails, the engine or the extension has fixed it:
  # assert `nrow()` equals 122881 instead.
  expect_error(
    dbGetQuery(con, "SELECT * FROM rem.main.repro"),
    "Result has been closed"
  )
})

test_that("a Quack result past the inline batches reads whole without remote pushdown", {
  server <- local_quack_server()
  dbExecute(server$con, "CREATE TABLE repro AS FROM range(122881)")
  con <- local_quack_client(server)

  # The workaround for duckdb/duckdb-r#2972:
  # without the rewrite, the scan runs its remote query when it executes.
  dbExecute(con, "SET disabled_optimizers = 'remote_pushdown'")
  out <- dbGetQuery(con, "SELECT * FROM rem.main.repro")
  expect_equal(nrow(out), 122881)
})

test_that("a Quack result past the inline batches reads whole in a transaction", {
  server <- local_quack_server()
  dbExecute(server$con, "CREATE TABLE repro AS FROM range(122881)")
  con <- local_quack_client(server)

  # Inside an explicit transaction, nothing commits between prepare and execute.
  dbBegin(con)
  out <- dbGetQuery(con, "SELECT * FROM rem.main.repro")
  dbCommit(con)
  expect_equal(nrow(out), 122881)
})
