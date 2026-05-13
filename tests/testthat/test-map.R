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
