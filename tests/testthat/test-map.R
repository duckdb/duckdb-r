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

test_that("empty maps can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT MAP([]::INTEGER[], []::VARCHAR[]) AS x")
  expect_equal(res, vctrs::data_frame(
    x = list(
      vctrs::data_frame(key = integer(), value = character())
    )
  ))

  res <- dbGetQuery(
    con,
    "SELECT 1 as a, MAP([]::INTEGER[], []::VARCHAR[]) AS x UNION ALL SELECT 2, MAP {1: 'a'} ORDER BY a"
  )
  expect_equal(res, vctrs::data_frame(
    a = 1:2,
    x = list(
      vctrs::data_frame(key = integer(), value = character()),
      vctrs::data_frame(key = 1L, value = "a")
    )
  ))
})

test_that("NULL maps can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT NULL::MAP(VARCHAR, INTEGER) AS x")
  expect_equal(res, vctrs::data_frame(x = list(NULL)))

  res <- dbGetQuery(
    con,
    "SELECT 1 AS a, MAP {'x': 1, 'y': 2} AS m UNION ALL SELECT 2, NULL ORDER BY a"
  )
  expect_equal(res, vctrs::data_frame(
    a = 1:2,
    m = list(
      vctrs::data_frame(key = c("x", "y"), value = 1:2),
      NULL
    )
  ))
})

test_that("maps with NULL values can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT MAP([1,2], [NULL, 'b']) AS m")
  expect_equal(res, vctrs::data_frame(
    m = list(
      vctrs::data_frame(key = 1:2, value = c(NA, "b"))
    )
  ))
})

test_that("maps preserve key insertion order", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT MAP {'z': 1, 'a': 2, 'm': 3} AS m")
  expect_equal(
    res$m[[1]],
    vctrs::data_frame(key = c("z", "a", "m"), value = 1:3)
  )
})

test_that("maps with various key and value types can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT MAP {'a': 1, 'b': 2} AS m")
  expect_equal(res$m[[1]], vctrs::data_frame(key = c("a", "b"), value = 1:2))

  res <- dbGetQuery(
    con,
    "SELECT MAP([DATE '2024-01-01', DATE '2024-01-02'], ['a', 'b']) AS m"
  )
  expect_equal(res$m[[1]], vctrs::data_frame(
    key = as.Date(c("2024-01-01", "2024-01-02")),
    value = c("a", "b")
  ))

  res <- dbGetQuery(con, "SELECT MAP {1.5: 1, 2.5: 2} AS m")
  expect_equal(res$m[[1]], vctrs::data_frame(key = c(1.5, 2.5), value = 1:2))

  res <- dbGetQuery(
    con,
    "SELECT MAP {'a': TIMESTAMP '2024-01-01 12:00:00', 'b': TIMESTAMP '2024-02-02 00:00:00'} AS m"
  )
  expect_equal(res$m[[1]]$key, c("a", "b"))
  expect_s3_class(res$m[[1]]$value, "POSIXct")
  expect_length(res$m[[1]]$value, 2)
})

test_that("BIGINT values in maps respect the bigint connection option", {
  skip_if_not_installed("vctrs")

  con <- local_con()
  res <- dbGetQuery(con, "SELECT MAP {'a': 1::BIGINT, 'b': 2::BIGINT} AS m")
  expect_equal(res$m[[1]], vctrs::data_frame(
    key = c("a", "b"),
    value = c(1, 2)
  ))

  skip_if_not_installed("bit64")
  con2 <- local_con(bigint = "integer64")
  res <- dbGetQuery(con2, "SELECT MAP {'a': 1::BIGINT, 'b': 2::BIGINT} AS m")
  expect_equal(res$m[[1]], vctrs::data_frame(
    key = c("a", "b"),
    value = bit64::as.integer64(c(1, 2))
  ))
})

test_that("maps with nested value types can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(
    con,
    "SELECT MAP([1, 2], [[1, 2], [3, 4, 5]]) AS m"
  )
  expect_equal(res$m[[1]], vctrs::data_frame(
    key = 1:2,
    value = list(1:2, 3:5)
  ))

  res <- dbGetQuery(
    con,
    "SELECT MAP([1, 2], [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}]) AS m"
  )
  expect_equal(res$m[[1]], vctrs::data_frame(
    key = 1:2,
    value = vctrs::data_frame(a = c(1L, 3L), b = c(2L, 4L))
  ))

  res <- dbGetQuery(
    con,
    "SELECT MAP([1, 2], [MAP {'a': 10}, MAP {'b': 20, 'c': 30}]) AS m"
  )
  expect_equal(res$m[[1]], vctrs::data_frame(
    key = 1:2,
    value = list(
      vctrs::data_frame(key = "a", value = 10L),
      vctrs::data_frame(key = c("b", "c"), value = c(20L, 30L))
    )
  ))
})

test_that("maps nested inside structs can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT {'m': MAP {'a': 1}, 'n': 42} AS s")
  expect_equal(res, vctrs::data_frame(
    s = vctrs::data_frame(
      m = list(vctrs::data_frame(key = "a", value = 1L)),
      n = 42L
    )
  ))
})

test_that("maps nested inside lists can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(
    con,
    "SELECT [MAP {'a': 1}, MAP {'b': 2, 'c': 3}] AS x"
  )
  expect_equal(res$x, list(list(
    vctrs::data_frame(key = "a", value = 1L),
    vctrs::data_frame(key = c("b", "c"), value = c(2L, 3L))
  )))
})

test_that("map column type is reported by DESCRIBE", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE t (m MAP(VARCHAR, INTEGER))")
  desc <- dbGetQuery(con, "DESCRIBE t")
  expect_equal(desc$column_name, "m")
  expect_equal(desc$column_type, "MAP(VARCHAR, INTEGER)")
})

test_that("duplicate map keys are rejected by DuckDB", {
  con <- local_con()
  expect_snapshot(
    error = TRUE,
    dbGetQuery(con, "SELECT MAP {'a': 1, 'a': 2} AS m")
  )
})

# Reading with map = "list_of" ---------------------------------------------

test_that("dbConnect(map = \"list_of\") returns vctrs::list_of for MAP columns", {
  skip_if_not_installed("vctrs")

  con <- local_con(map = "list_of")

  res <- dbGetQuery(con, "SELECT MAP {'a': 1, 'b': 2} AS m")
  expect_s3_class(res$m, "vctrs_list_of")
  expect_equal(
    vctrs::vec_ptype(attr(res$m, "ptype")),
    vctrs::vec_ptype(data.frame(key = character(), value = integer()))
  )
  expect_equal(
    as.data.frame(res$m[[1]]),
    data.frame(key = c("a", "b"), value = 1:2, stringsAsFactors = FALSE)
  )
})

test_that("dbConnect(map = \"list_of\") preserves NULL and empty MAP cells", {
  skip_if_not_installed("vctrs")

  con <- local_con(map = "list_of")

  res <- dbGetQuery(
    con,
    "SELECT 1 AS i, MAP {'a': 1} AS m UNION ALL
     SELECT 2, NULL UNION ALL
     SELECT 3, MAP([]::VARCHAR[], []::INTEGER[]) ORDER BY i"
  )
  expect_s3_class(res$m, "vctrs_list_of")
  expect_equal(
    as.data.frame(res$m[[1]]),
    data.frame(key = "a", value = 1L, stringsAsFactors = FALSE)
  )
  expect_null(res$m[[2]])
  expect_equal(nrow(as.data.frame(res$m[[3]])), 0L)
})

test_that("dbConnect default `map` keeps MAP columns as plain data.frame lists", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT MAP {'a': 1} AS m")
  expect_false(inherits(res$m, "vctrs_list_of"))
  expect_type(res$m, "list")
})

test_that("dbConnect(map = \"list_of\") works with nested key/value types", {
  skip_if_not_installed("vctrs")

  con <- local_con(map = "list_of")

  res <- dbGetQuery(
    con,
    "SELECT MAP([DATE '2024-01-01'], ['x']) AS m"
  )
  expect_s3_class(res$m, "vctrs_list_of")
  ptype <- attr(res$m, "ptype")
  expect_s3_class(ptype$key, "Date")
  expect_type(ptype$value, "character")
})

test_that("dbConnect(map = ...) rejects unknown values", {
  expect_error(local_con(map = "wat"), "Unsupported map configuration")
})

# Auto-detection in dbDataType --------------------------------------------

test_that("dbDataType reports MAP for vctrs::list_of with key/value ptype", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  col <- vctrs::new_list_of(
    list(data.frame(key = c("a", "b"), value = 1:2, stringsAsFactors = FALSE)),
    ptype = data.frame(key = character(), value = integer(), stringsAsFactors = FALSE)
  )
  expect_equal(dbDataType(con, col), "MAP(STRING, INTEGER)")

  col2 <- vctrs::new_list_of(
    list(data.frame(key = as.Date("2024-01-01"), value = "v", stringsAsFactors = FALSE)),
    ptype = data.frame(key = as.Date(character()), value = character(), stringsAsFactors = FALSE)
  )
  expect_equal(dbDataType(con, col2), "MAP(DATE, STRING)")
})

test_that("dbDataType ignores vctrs::list_of without key/value ptype", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  col <- vctrs::list_of(1L, 2L)
  expect_equal(dbDataType(con, col), "STRING")

  col2 <- vctrs::new_list_of(
    list(data.frame(a = 1L, b = 2L)),
    ptype = data.frame(a = integer(), b = integer())
  )
  expect_equal(dbDataType(con, col2), "STRING")
})

test_that("dbCreateTable on a list_of column creates a MAP column", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  m <- vctrs::new_list_of(
    list(data.frame(key = "k", value = 1L, stringsAsFactors = FALSE)),
    ptype = data.frame(key = character(), value = integer(), stringsAsFactors = FALSE)
  )
  df <- data.frame(id = 1L)
  df$m <- m
  dbCreateTable(con, "t", df)
  expect_equal(
    dbGetQuery(con, "DESCRIBE t")$column_type,
    c("INTEGER", "MAP(VARCHAR, INTEGER)")
  )
})

# Writing -----------------------------------------------------------------
#
# Tracks the behavior described in
# https://github.com/duckdb/duckdb-r/issues/200.

test_that("dbAppendTable can write to a MAP column (issue #200)", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE tbl (mp MAP(VARCHAR, VARCHAR))")
  dbExecute(con, "INSERT INTO tbl VALUES (MAP {'a': 'b'})")

  df <- data.frame(
    mp = I(list(data.frame(key = "page", value = "1", stringsAsFactors = FALSE)))
  )
  dbAppendTable(con, "tbl", df)

  out <- dbReadTable(con, "tbl")
  expect_equal(nrow(out), 2L)
  expect_equal(
    as.data.frame(out$mp[[2]]),
    data.frame(key = "page", value = "1", stringsAsFactors = FALSE)
  )
})

test_that("dbWriteTable of a MAP-shaped data frame creates STRUCT[], not MAP", {
  con <- local_con()

  dbExecute(con, "CREATE TABLE src (m MAP(VARCHAR, INTEGER))")
  dbExecute(con, "INSERT INTO src VALUES (MAP {'a': 1, 'b': 2}), (MAP {'c': 3}), (NULL)")
  df <- dbReadTable(con, "src")

  dbWriteTable(con, "dst", df)
  expect_equal(
    dbGetQuery(con, "DESCRIBE dst")$column_type,
    "STRUCT(\"key\" VARCHAR, \"value\" INTEGER)[]"
  )
})

test_that("dbCreateTable of a MAP-shaped data frame creates VARCHAR, not MAP", {
  con <- local_con()

  df <- data.frame(
    m = I(list(data.frame(key = "a", value = 1L)))
  )
  dbCreateTable(con, "ct", df)
  expect_equal(dbGetQuery(con, "DESCRIBE ct")$column_type, "VARCHAR")
})

test_that("duckdb_register exposes list-of-data.frame as STRUCT[], not MAP", {
  con <- local_con()

  df <- data.frame(
    mp = I(list(data.frame(key = "page", value = "1")))
  )
  duckdb_register(con, "df_reg", df)
  expect_equal(
    dbGetQuery(con, "DESCRIBE df_reg")$column_type,
    "STRUCT(\"key\" VARCHAR, \"value\" VARCHAR)[]"
  )
})

test_that("duckdb_register exposes list of named atomic vectors as plain list", {
  con <- local_con()

  df <- data.frame(
    mp = I(list(c(what = 1L, where = 2L), c(anything = 8L, anyhow = 9L)))
  )
  duckdb_register(con, "df_reg", df)
  # The names of the atomic vectors are lost; the column ends up as a
  # plain list of integers, not a MAP.
  expect_equal(dbGetQuery(con, "DESCRIBE df_reg")$column_type, "INTEGER[]")
})

test_that("dbDataType reports STRING for MAP-shaped R values", {
  con <- local_con()

  expect_equal(
    dbDataType(con, list(data.frame(key = "a", value = 1L))),
    "STRING"
  )
  expect_equal(
    dbDataType(con, list(c(a = 1L, b = 2L))),
    "STRING"
  )
})

test_that("casting STRUCT(key, value)[] to MAP is unsupported (issue #200)", {
  con <- local_con()
  expect_snapshot(
    error = TRUE,
    dbGetQuery(
      con,
      "SELECT [{'key': 'a', 'value': 'b'}]::MAP(VARCHAR, VARCHAR) AS m"
    )
  )
})

test_that("map_from_entries() is a working SQL-side workaround (issue #200)", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  dbExecute(con, "CREATE TABLE src (m MAP(VARCHAR, INTEGER))")
  dbExecute(con, "INSERT INTO src VALUES (MAP {'a': 1, 'b': 2}), (NULL), (MAP {'c': 3})")
  df <- dbReadTable(con, "src")

  duckdb_register(con, "df_reg", df)

  dbExecute(con, "CREATE TABLE dst (m MAP(VARCHAR, INTEGER))")
  dbExecute(con, "INSERT INTO dst SELECT map_from_entries(m) FROM df_reg")

  expect_equal(
    dbGetQuery(con, "DESCRIBE dst")$column_type,
    "MAP(VARCHAR, INTEGER)"
  )
  expect_equal(dbReadTable(con, "dst"), df)
})

test_that("read-then-write round-trip via duckdb_register preserves values", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  df <- data.frame(
    id = 1:3,
    m = I(list(
      data.frame(key = c("a", "b"), value = c(1L, 2L)),
      NULL,
      data.frame(key = "c", value = 3L)
    ))
  )
  duckdb_register(con, "df_reg", df)
  res <- dbGetQuery(
    con,
    "SELECT id, map_from_entries(m) AS m FROM df_reg ORDER BY id"
  )

  expect_equal(res$id, 1:3)
  expect_equal(res$m[[1]], data.frame(key = c("a", "b"), value = c(1L, 2L)))
  expect_null(res$m[[2]])
  expect_equal(res$m[[3]], data.frame(key = "c", value = 3L))
})
