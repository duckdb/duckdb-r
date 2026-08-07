test_that("geometry columns can be read as blob (default)", {
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

  # WKB: byte order (01=LE) + type (01000000=Point) + x + y
  wkb <- res$geom[[1]]
  expect_equal(wkb[1], as.raw(0x01)) # little-endian
  expect_equal(wkb[2:5], as.raw(c(0x01, 0x00, 0x00, 0x00))) # Point type
})

test_that("geometry columns can be read inline", {
  con <- local_con()

  res <- dbGetQuery(con, "SELECT 'POINT (1 2)'::GEOMETRY AS geom")

  expect_true(is.list(res$geom))
  expect_true(is.raw(res$geom[[1]]))
})

test_that("geometry = 'blob' returns raw vectors", {
  con <- local_con(geometry = "blob")

  dbExecute(con, "CREATE TABLE test_geom (id INTEGER, geom GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (1, 'POINT (1 2)'::GEOMETRY)")

  res <- dbGetQuery(con, "SELECT * FROM test_geom")
  expect_true(is.list(res$geom))
  expect_true(is.raw(res$geom[[1]]))
})

test_that("geometry = 'wk' returns wk_wkb objects", {
  skip_if_not_installed("wk")

  con <- local_con(geometry = "wk")

  dbExecute(con, "CREATE TABLE test_geom (id INTEGER, geom GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (1, 'POINT (1 2)'::GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (2, 'POINT (3 4)'::GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (3, NULL)")

  res <- dbGetQuery(con, "SELECT * FROM test_geom ORDER BY id")

  expect_equal(nrow(res), 3)
  expect_s3_class(res$geom, "wk_wkb")
  expect_equal(length(res$geom), 3)

  # Validate coordinates via wk
  coords <- wk::wk_coords(res$geom)
  expect_equal(coords$x[1], 1)
  expect_equal(coords$y[1], 2)
  expect_equal(coords$x[2], 3)
  expect_equal(coords$y[2], 4)

  # NULL becomes NA in wk
  expect_true(is.na(res$geom[3]))
})

test_that("geometry = 'wk' works end-to-end with sf", {
  skip_if_not_installed("wk")
  skip_if_not_installed("sf")

  con <- local_con(geometry = "wk")

  dbExecute(con, "CREATE TABLE test_geom (id INTEGER, geom GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (1, 'POINT (1 2)'::GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (2, 'POINT (3 4)'::GEOMETRY)")
  dbExecute(con, "INSERT INTO test_geom VALUES (3, NULL)")

  res <- dbGetQuery(con, "SELECT * FROM test_geom ORDER BY id")

  # Convert wk_wkb to sfc
  sfc <- sf::st_as_sfc(res$geom)

  expect_s3_class(sfc, "sfc")
  expect_equal(length(sfc), 3)

  # Validate coordinates via sf
  coords <- sf::st_coordinates(sfc[1:2])
  expect_equal(unname(coords[1, "X"]), 1)
  expect_equal(unname(coords[1, "Y"]), 2)
  expect_equal(unname(coords[2, "X"]), 3)
  expect_equal(unname(coords[2, "Y"]), 4)

  # NULL becomes empty geometry in sf
  expect_true(sf::st_is_empty(sfc[3]))
})

test_that("invalid geometry option is rejected", {
  expect_error(local_con(geometry = "invalid"), "geometry")
})
