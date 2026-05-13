test_that("structs can be read", {
  skip_if_not_installed("vctrs")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT {'x': 100, 'y': 'hello', 'z': 3.14} AS s")
  expect_equal(res, vctrs::data_frame(
    s = vctrs::data_frame(x = 100L, y = "hello", z = 3.14)
  ))

  res <- dbGetQuery(con, "SELECT 1 AS n, {'x': 100, 'y': 'hello', 'z': 3.14} AS s")
  expect_equal(res, vctrs::data_frame(
    n = 1L,
    s = vctrs::data_frame(x = 100L, y = "hello", z = 3.14)
  ))

  res <- dbGetQuery(con, "values (100, {'x': 100}), (200, {'x': 200}), (300, NULL)")
  expect_equal(res, vctrs::data_frame(
    col0 = c(100L, 200L, 300L),
    col1 = vctrs::data_frame(x = c(100L, 200L, NA))
  ))

  res <- dbGetQuery(con, "values ('a', {'x': 100, 'y': {'a': 1, 'b': 2}}), ('b', {'x': 200, y: NULL}), ('c', NULL)")
  expect_equal(res, vctrs::data_frame(
    col0 = c("a", "b", "c"),
    col1 = vctrs::data_frame(
      x = c(100L, 200L, NA),
      y = vctrs::data_frame(a = c(1L, NA, NA), b = c(2L, NA, NA))
    )
  ))

  res <- dbGetQuery(con, "select 100 AS other, [{'x': 1, 'y': 'a'}, {'x': 2, 'y': 'b'}] AS s")
  expect_equal(res, vctrs::data_frame(
    other = 100L,
    s = list(
      vctrs::data_frame(x = c(1L, 2L), y = c("a", "b"))
    )
  ))

  res <- dbGetQuery(con, "values ([{'x': 1, 'y': 'a'}, {'x': 2, 'y': 'b'}]), ([]), ([{'x': 1, 'y': 'a'}])")
  expect_equal(res, vctrs::data_frame(
    col0 = list(
      vctrs::data_frame(x = c(1L, 2L), y = c("a", "b")),
      vctrs::data_frame(x = integer(0), y = character(0)),
      vctrs::data_frame(x = 1L, y = "a")
    )
  ))
})

test_that("structs give the same results via Arrow", {
  skip_on_cran()
  skip_if_not_installed("vctrs")
  skip_if_not_installed("tibble")
  skip_if_not_installed("arrow", "13.0.0")

  con <- local_con()

  res <- dbGetQuery(con, "SELECT {'x': 100, 'y': 'hello', 'z': 3.14::double} AS s", arrow = TRUE)
  expect_equal(res, vctrs::data_frame(
    s = tibble::tibble(x = 100L, y = "hello", z = 3.14)
  ))

  res <- dbGetQuery(con, "SELECT 1 AS n, {'x': 100, 'y': 'hello', 'z': 3.14::double} AS s", arrow = TRUE)
  expect_equal(res, vctrs::data_frame(
    n = 1L,
    s = tibble::tibble(x = 100L, y = "hello", z = 3.14)
  ))

  res <- dbGetQuery(con, "values (100, {'x': 100}), (200, {'x': 200}), (300, NULL)", arrow = TRUE)
  expect_equal(res, vctrs::data_frame(
    col0 = c(100L, 200L, 300L),
    col1 = tibble::tibble(x = c(100L, 200L, NA))
  ))

  res <- dbGetQuery(con, "values ('a', {'x': 100, 'y': {'a': 1, 'b': 2}}), ('b', {'x': 200, y: NULL}), ('c', NULL)", arrow = TRUE)
  expect_equal(res, vctrs::data_frame(
    col0 = c("a", "b", "c"),
    col1 = tibble::tibble(
      x = c(100L, 200L, NA),
      y = tibble::tibble(a = c(1L, NA, NA), b = c(2L, NA, NA))
    )
  ))

  res <- dbGetQuery(con, "select 100 AS other, [{'x': 1, 'y': 'a'}, {'x': 2, 'y': 'b'}] AS s", arrow = TRUE)
  expect_equal(res, data.frame(
    other = 100L,
    s = vctrs::new_list_of(
      list(
        tibble::tibble(x = c(1L, 2L), y = c("a", "b"))
      ),
      ptype = tibble::tibble(x = integer(), y = character()),
      class = "arrow_list"
    )
  ))

  res <- dbGetQuery(con, "values ([{'x': 1, 'y': 'a'}, {'x': 2, 'y': 'b'}]), ([]), ([{'x': 1, 'y': 'a'}])", arrow = TRUE)
  expect_equal(res, data.frame(
    col0 = vctrs::new_list_of(
      list(
        tibble::tibble(x = c(1L, 2L), y = c("a", "b")),
        tibble::tibble(x = integer(0), y = character(0)),
        tibble::tibble(x = 1L, y = "a")
      ),
      ptype = tibble::tibble(x = integer(), y = character()),
      class = "arrow_list"
    )
  ))
})

test_that("nested lists of atomic values can be written", {
  skip_if_not(TEST_RE2)

  skip_if_not_installed("vctrs")

  con <- local_con()

  df <- vctrs::data_frame(a = 1:3, b = list(4:6, 2:3, 1L))
  dbWriteTable(con, "df", df)
  expect_equal(dbReadTable(con, "df"), df)

  duckdb_register(con, "df_reg", df)
  expect_equal(dbReadTable(con, "df_reg"), df)

  df2 <- vctrs::data_frame(a = 1:2, b = list(4:6, letters[2:3]))
  expect_error(dbWriteTable(con, "df2", df2), "register")
  expect_error(duckdb_register(con, "df2_reg", df2), "register")
})

test_that("nested and packed columns work in full", {
  skip_if_not(TEST_RE2)

  skip_if_not_installed("vctrs")

  con <- local_con()

  df <- vctrs::data_frame(
    a = vctrs::data_frame(
      x = 1:5,
      y = as.numeric(6:10),
      z = vctrs::data_frame(
        k = c(TRUE, FALSE, NA, TRUE, FALSE),
        l = letters[1:5]
      )
    ),
    b = list(
      vctrs::data_frame(
        u = structure(as.numeric(19577:19578), class = "Date"),
        v = structure(19577:19578, class = "Date"),
        w = structure(1691507820, class = c("POSIXct", "POSIXt"), tzone = "UTC") + 0:1
      )
    ),
    c = list(
      vctrs::data_frame(
        # TIME_MINUTES, TIME_MINUTES_INTEGER, TIME_HOURS, ... etc.: Loss ok
        d = structure(as.numeric(13:16), class = "difftime", units = "secs"),
        e = vctrs::data_frame(
          u = structure(17:20, class = "difftime", units = "secs"),
          v = 5:8,
          w = as.list(9:12)
        )
      )
    ),
    f = list(
      vctrs::data_frame(
        g = list(as.raw(13), as.raw(14:15), as.raw(16:18), as.raw(19:22)),
        h = vctrs::data_frame(u = 1:4, v = 5:8, w = list(vctrs::data_frame(s = 9:10)))
      )
    ),
    i = "plain old"
  )
  dbWriteTable(con, "df", df)
  expect_equal(dbReadTable(con, "df"), df)

  duckdb_register(con, "df_reg", df)
  expect_equal(dbReadTable(con, "df_reg"), df)
})

test_that("packed columns work with ALTREP", {
  con <- local_con()
  df1 <- data.frame(g = c(1, 1, 2), a = 1:3, b = 2:4, c = 3:5)

  rel1 <- rel_from_df(con, df1)
  "mutate"
  rel2 <- rel_project(
    rel1,
    list(
      {
        tmp_expr <- expr_reference("g")
        expr_set_alias(tmp_expr, "g")
        tmp_expr
      },
      {
        tmp_expr <- expr_reference("c")
        expr_set_alias(tmp_expr, "c")
        tmp_expr
      },
      {
        tmp_expr <- expr_function("struct_pack", list(expr_reference("a"), expr_reference("b")))
        expr_set_alias(tmp_expr, "d")
        tmp_expr
      }
    )
  )
  "mutate"
  rel3 <- rel_project(
    rel2,
    list(
      {
        tmp_expr <- expr_reference("g")
        expr_set_alias(tmp_expr, "g")
        tmp_expr
      },
      {
        tmp_expr <- expr_function("struct_pack", list(expr_reference("d"), expr_reference("c")))
        expr_set_alias(tmp_expr, "e")
        tmp_expr
      }
    )
  )

  expected <- structure(
    list(
      g = c(1, 1, 2),
      e = structure(
        list(d = data.frame(a = 1:3, b = 2:4), c = 3:5),
        row.names = c(NA, -3L),
        class = "data.frame"
      )
    ),
    row.names = c(NA, -3L),
    class = "data.frame"
  )

  expect_identical(rel_to_altrep(rel3), expected)
})

test_that("nested columns work with ALTREP", {
  skip_if(getRversion() < "4.3.0", "ALTREP for lists not supported")

  con <- local_con()
  df1 <- data.frame(g = c(1, 1, 2), a = 1:3, b = 2:4, c = 3:5)

  rel1 <- rel_from_df(con, df1)
  "mutate"
  rel2 <- rel_project(
    rel1,
    list(
      {
        tmp_expr <- expr_reference("g")
        expr_set_alias(tmp_expr, "g")
        tmp_expr
      },
      {
        tmp_expr <- expr_reference("c")
        expr_set_alias(tmp_expr, "c")
        tmp_expr
      },
      {
        tmp_expr <- expr_function("struct_pack", list(expr_reference("a"), expr_reference("b")))
        expr_set_alias(tmp_expr, "d")
        tmp_expr
      }
    )
  )
  "mutate"
  rel3 <- rel_project(
    rel2,
    list(
      {
        tmp_expr <- expr_reference("g")
        expr_set_alias(tmp_expr, "g")
        tmp_expr
      },
      {
        tmp_expr <- expr_reference("d")
        expr_set_alias(tmp_expr, "d")
        tmp_expr
      },
      {
        tmp_expr <- expr_function("struct_pack", list(expr_reference("d"), expr_reference("c")))
        expr_set_alias(tmp_expr, "e")
        tmp_expr
      }
    )
  )
  "summarise"
  rel4 <- rel_aggregate(
    rel3,
    groups = list(expr_reference("g")),
    aggregates = list(
      {
        tmp_expr <- expr_function("list", list(expr_reference("e")))
        expr_set_alias(tmp_expr, "f")
        tmp_expr
      }
    )
  )
  "arrange"
  rel5 <- rel_order(rel4, list(expr_reference("g")))

  expected <- structure(
    list(
      g = c(1, 2),
      f = list(
        structure(
          list(d = data.frame(a = 1:2, b = 2:3), c = 3:4),
          class = "data.frame",
          row.names = c(NA, -2L)
        ),
        structure(
          list(d = data.frame(a = 3L, b = 4L), c = 5L),
          class = "data.frame",
          row.names = c(NA, -1L)
        )
      )
    ),
    row.names = c(NA, -2L),
    class = "data.frame"
  )

  expect_identical(rel_to_altrep(rel5), expected)
})
