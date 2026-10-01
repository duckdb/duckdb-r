test_that("`blob = \"list\"` is the default", {
  con <- local_con(blob = "list")

  data <- dbGetQuery(con, "SELECT '\\xAA\\xBB'::BLOB AS a, NULL::BLOB AS b")
  expect_identical(data$a, list(as.raw(c(0xaa, 0xbb))))
  expect_identical(data$b, list(NULL))
})

test_that("`blob = \"blob\"` reads BLOB as blob, and leaves GEOMETRY alone", {
  skip_if_not_installed("blob")

  con <- local_con(blob = "blob")

  data <- dbGetQuery(
    con,
    "SELECT
       '\\xAA\\xBB'::BLOB AS a,
       NULL::BLOB AS b,
       ''::BLOB AS c,
       'POINT (1 2)'::GEOMETRY AS d"
  )
  expect_identical(data$a, blob::blob(as.raw(c(0xaa, 0xbb))))
  expect_identical(data$b, blob::blob(NULL))
  expect_identical(data$c, blob::blob(raw()))
  expect_false(inherits(data$d, "blob"))
  expect_type(data$d[[1]], "raw")
})

test_that("`blob = \"blob\"` reads zero rows and nested values as blob", {
  skip_if_not_installed("blob")

  con <- local_con(blob = "blob")

  empty <- dbGetQuery(con, "SELECT 'a'::BLOB AS a WHERE false")
  expect_identical(empty$a, blob::blob())

  data <- dbGetQuery(
    con,
    "SELECT ['\\x01'::BLOB, NULL] AS l, {'b': '\\x02'::BLOB} AS s"
  )
  expect_identical(data$l[[1]], blob::blob(as.raw(1), NULL))
  expect_identical(data$s$b, blob::blob(as.raw(2)))
})

test_that("`blob = \"blob\"` holds for every chunk dbFetch() returns", {
  skip_if_not_installed("blob")

  con <- local_con(blob = "blob")

  res <- dbSendQuery(
    con,
    "SELECT i::VARCHAR::BLOB AS a FROM range(5) AS r(i) ORDER BY i"
  )
  on.exit(dbClearResult(res))
  expect_identical(dbFetch(res, n = 2)$a, blob::as_blob(c("0", "1")))
  expect_identical(dbFetch(res, n = 2)$a, blob::as_blob(c("2", "3")))
  expect_identical(dbFetch(res)$a, blob::as_blob("4"))
  expect_identical(dbFetch(res)$a, blob::blob())
})

test_that("`blob = \"blob\"` reaches a relation's columns", {
  skip_if_not_installed("blob")

  con <- local_con(blob = "blob")

  df <- rel_to_altrep(rel_from_sql(con, "SELECT 'a'::BLOB AS a"))
  expect_identical(df$a, blob::as_blob("a"))
})

test_that("a blob read under `blob = \"blob\"` writes back as BLOB", {
  skip_if_not_installed("blob")

  con <- local_con(blob = "blob")

  data <- dbGetQuery(
    con,
    "SELECT '\\xAA\\xBB'::BLOB AS a UNION ALL SELECT NULL ORDER BY a"
  )

  dbWriteTable(con, "tbl", data)
  expect_equal(
    dbGetQuery(con, "SELECT DISTINCT typeof(a) AS t FROM tbl")$t,
    "BLOB"
  )
  expect_identical(dbReadTable(con, "tbl"), data)

  dbAppendTable(con, "tbl", data)
  expect_identical(dbReadTable(con, "tbl")$a, vctrs::vec_rep(data$a, 2))

  bound <- dbGetQuery(con, "SELECT ? AS a", params = list(data$a[1]))
  expect_identical(bound$a, data$a[1])
})

test_that("`blob = \"blob\"` needs the blob package", {
  local_mocked_bindings(is_installed = function(pkg) pkg != "blob")

  expect_error(local_con(blob = "blob"), "blob package must be installed")
  expect_no_error(local_con(blob = "list"))
})

test_that("`blob` rejects unknown values", {
  expect_error(local_con(blob = "wat"), "list")
})
