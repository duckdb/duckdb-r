test_that("an operator binds correctly while its argument autoloads icu (#2883)", {
  dir <- local_icu_installed_dir()
  con <- local_con(drv = icu_autoload_drv(dir))

  sql <- "SELECT epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00') + 2.5 AS x"

  expect_false(icu_loaded(con))
  # The first execution is the one that autoloads icu while binding `+`;
  # it returned 999999997.5 when the operator was bound against the freed entry.
  expect_equal(dbGetQuery(con, sql)$x, 1000000002.5, tolerance = 0)
  expect_true(icu_loaded(con))
  expect_equal(dbGetQuery(con, sql)$x, 1000000002.5, tolerance = 0)
})

test_that("subtraction binds correctly while its argument autoloads icu (#2883)", {
  dir <- local_icu_installed_dir()
  con <- local_con(drv = icu_autoload_drv(dir))

  expect_false(icu_loaded(con))
  # Failed with a binder error naming `age` when bound against the freed entry.
  expect_equal(
    dbGetQuery(
      con,
      "SELECT epoch(TIMESTAMPTZ '2001-09-09 01:46:40+00') - 2.5 AS x"
    )$x,
    999999997.5,
    tolerance = 0
  )
  expect_true(icu_loaded(con))
})

test_that("an operator over an aggregate binds correctly while icu autoloads (#2883)", {
  dir <- local_icu_installed_dir()
  con <- local_con(drv = icu_autoload_drv(dir))

  expect_false(icu_loaded(con))
  expect_equal(
    dbGetQuery(
      con,
      "
      SELECT sum(epoch(tz)) + 1 AS x
      FROM (VALUES (TIMESTAMPTZ '2001-09-09 01:46:40+00')) t(tz)
      "
    )$x,
    1000000001,
    tolerance = 0
  )
  expect_true(icu_loaded(con))
})
