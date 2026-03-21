test_that("geometry columns can be read", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE test_geom (id INTEGER, geom GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (1, 'POINT (1 2)'::GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (2, 'POINT (3 4)'::GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (3, NULL)")

  res <- dbGetQuery(con, "SELECT * FROM test_geom ORDER BY id")

  expect_equal(nrow(res), 3)
  expect_equal(res$id, 1:3)
  expect_true(is.list(res$geom))
  expect_true(is.raw(res$geom[[1]]))
  expect_true(is.raw(res$geom[[2]]))
  expect_null(res$geom[[3]])
})

test_that("geometry columns can be read inline", {
  con <- local_con()

  res <- dbGetQuery(con, "SELECT 'POINT (1 2)'::GEOMETRY AS geom")

  expect_true(is.list(res$geom))
  expect_true(is.raw(res$geom[[1]]))
})
