test_that("maps can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(
    con,
    "SELECT map([1,2],['a','b']) AS x"
  )
  expect_equal(res, vctrs::data_frame(
    x = list(
      vctrs::data_frame(key = 1:2, value = letters[1:2])
    )
  ))

  res <- dbGetQuery(
    con,
    "SELECT 1 as a, map([1,2],[1.5,2.5]) AS x UNION SELECT 2, map([3,4,5],[5.5,4.5,3.5]) ORDER BY a"
  )
  expect_equal(res, vctrs::data_frame(
    a = 1:2,
    x = list(
      vctrs::data_frame(key = 1:2, value = 1:2 + 0.5),
      vctrs::data_frame(key = 3:5, value = 5:3 + 0.5)
    )
  ))

  res <- dbGetQuery(
    con,
    "SELECT 1 as a, map([1,2],[TRUE,FALSE]) AS x UNION SELECT 2, NULL ORDER BY a"
  )
  expect_equal(res, vctrs::data_frame(
    a = 1:2,
    x = list(
      vctrs::data_frame(key = 1:2, value = c(TRUE, FALSE)),
      NULL
    )
  ))
})

test_that("maps can be written with dbAppendTable (#200)", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE tbl (mp MAP(VARCHAR, VARCHAR))")

  df <- data.frame(
    mp = I(list(data.frame(key = "page", value = "1", stringsAsFactors = FALSE)))
  )
  dbAppendTable(con, "tbl", df)

  out <- dbReadTable(con, "tbl")
  expect_equal(length(out$mp), 1L)
  expect_equal(
    as.data.frame(out$mp[[1]]),
    data.frame(key = "page", value = "1", stringsAsFactors = FALSE)
  )
})

test_that("maps can be round-tripped via dbAppendTable (#200)", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE tbl (id INTEGER, mp MAP(VARCHAR, VARCHAR))")
  dbExecute(con, "INSERT INTO tbl VALUES (1, MAP {'a': 'b', 'c': 'd'}), (2, MAP {'x': 'y'})")

  original <- dbReadTable(con, "tbl")

  dbExecute(con, "CREATE TABLE tbl2 (id INTEGER, mp MAP(VARCHAR, VARCHAR))")
  dbAppendTable(con, "tbl2", original)

  roundtripped <- dbReadTable(con, "tbl2")
  expect_equal(roundtripped$id, original$id)
  expect_equal(length(roundtripped$mp), length(original$mp))
  for (i in seq_along(original$mp)) {
    expect_equal(
      as.data.frame(roundtripped$mp[[i]]),
      as.data.frame(original$mp[[i]])
    )
  }
})

test_that("maps with NULL values can be written (#200)", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE tbl (id INTEGER, mp MAP(VARCHAR, VARCHAR))")

  df <- data.frame(id = 1:2)
  df$mp <- list(
    data.frame(key = "a", value = "b", stringsAsFactors = FALSE),
    NULL
  )
  dbAppendTable(con, "tbl", df)

  out <- dbReadTable(con, "tbl")
  expect_equal(out$id, 1:2)
  expect_equal(
    as.data.frame(out$mp[[1]]),
    data.frame(key = "a", value = "b", stringsAsFactors = FALSE)
  )
  expect_null(out$mp[[2]])
})

test_that("maps with non-character keys/values can be written (#200)", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE tbl (mp MAP(INTEGER, DOUBLE))")

  df <- data.frame(
    mp = I(list(data.frame(key = 1:2, value = c(1.5, 2.5))))
  )
  dbAppendTable(con, "tbl", df)

  out <- dbReadTable(con, "tbl")
  expect_equal(
    as.data.frame(out$mp[[1]]),
    data.frame(key = 1:2, value = c(1.5, 2.5))
  )
})

test_that("maps can be written with dbWriteTable and field.types (#200)", {
  con <- local_con()

  df <- data.frame(
    mp = I(list(data.frame(key = "a", value = "b", stringsAsFactors = FALSE)))
  )
  dbWriteTable(con, "tbl", df, field.types = c(mp = "MAP(VARCHAR, VARCHAR)"))

  type <- dbGetQuery(con, "DESCRIBE tbl")$column_type
  expect_equal(type, "MAP(VARCHAR, VARCHAR)")

  out <- dbReadTable(con, "tbl")
  expect_equal(
    as.data.frame(out$mp[[1]]),
    data.frame(key = "a", value = "b", stringsAsFactors = FALSE)
  )
})

test_that("non-map columns alongside map columns still work (#200)", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE tbl (id INTEGER, name VARCHAR, mp MAP(VARCHAR, INTEGER))")

  df <- data.frame(
    id = 1:2,
    name = c("foo", "bar"),
    stringsAsFactors = FALSE
  )
  df$mp <- list(
    data.frame(key = c("a", "b"), value = 1:2, stringsAsFactors = FALSE),
    data.frame(key = "c", value = 3L, stringsAsFactors = FALSE)
  )
  dbAppendTable(con, "tbl", df)

  out <- dbReadTable(con, "tbl")
  expect_equal(out$id, 1:2)
  expect_equal(out$name, c("foo", "bar"))
  expect_equal(
    as.data.frame(out$mp[[1]]),
    data.frame(key = c("a", "b"), value = 1:2, stringsAsFactors = FALSE)
  )
  expect_equal(
    as.data.frame(out$mp[[2]]),
    data.frame(key = "c", value = 3L, stringsAsFactors = FALSE)
  )
})

test_that("structs give the same results via Arrow", {
  skip_on_cran()
  skip_if_not_installed("vctrs")
  skip_if_not_installed("tibble")
  skip_if_not_installed("arrow", "13.0.0")

  con <- local_con()

  res <- dbGetQuery(
    con,
    "SELECT map([1,2],['a','b']) AS x",
    arrow = TRUE
  )
  expect_equal(res, vctrs::data_frame(
    x = structure(class = c("arrow_list", class(vctrs::list_of(logical()))), vctrs::list_of(
      tibble::tibble(key = 1:2, value = letters[1:2])
    ))
  ))

  res <- dbGetQuery(
    con,
    "SELECT 1 as a, map([1,2],[1.5,2.5]) AS x UNION SELECT 2, map([3,4,5],[5.5,4.5,3.5]::double[]) ORDER BY a",
    arrow = TRUE
  )
  expect_equal(res, vctrs::data_frame(
    a = 1:2,
    x = structure(class = c("arrow_list", class(vctrs::list_of(logical()))), vctrs::list_of(
      tibble::tibble(key = 1:2, value = 1:2 + 0.5),
      tibble::tibble(key = 3:5, value = 5:3 + 0.5)
    ))
  ))

  res <- dbGetQuery(
    con,
    "SELECT 1 as a, map([1,2],[TRUE,FALSE]) AS x UNION SELECT 2, NULL ORDER BY a",
    arrow = TRUE
  )
  expect_equal(res, vctrs::data_frame(
    a = 1:2,
    x = structure(class = c("arrow_list", class(vctrs::list_of(logical()))), vctrs::list_of(
      tibble::tibble(key = 1:2, value = c(TRUE, FALSE)),
      NULL
    ))
  ))
})
