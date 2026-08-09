test_that("test_all_types() output", {
  skip_on_os("windows")
  skip_if_not(getRversion() >= "4.3")

  con <- local_con(array = "matrix")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    bad <- c(
      # Need to omit timestamp columns, likely due to https://bugs.r-project.org/show_bug.cgi?id=16856
      "timestamp_tz",
      "timestamp_ns",
      "timestamp_array",
      "timestamptz_array",

      "bit",
      '"union"',
      "fixed_nested_int_array",
      "fixed_nested_varchar_array",
      "fixed_struct_array",
      "fixed_array_of_int_list",
      "bignum",
      "time_ns",
      "geometry",
      NULL
    )

    as.list(dbGetQuery(
      con,
      paste0("SELECT * EXCLUDE (", paste(bad, collapse = ", "), ") REPLACE(replace(varchar, chr(0), '') AS varchar) FROM test_all_types(use_large_enum=true)")
    ))
  })
})

# A column carrying a class attribute -- `units`, and anything else built the
# same way -- crosses as the numeric underneath it, so the value is what a
# caller gets back and can re-apply the class to:
# handbook/usage/types/README.md, reported as #590.
test_that("the value of a classed numeric column survives every route in", {
  con <- local_con()

  df <- data.frame(id = 1:3)
  df$area <- structure(c(1.5, 2.5, 3.5), class = "area_unit")

  dbWriteTable(con, "written", df)
  expect_equal(dbGetQuery(con, "SELECT area FROM written")$area, c(1.5, 2.5, 3.5))

  duckdb_register(con, "registered", df)
  expect_equal(dbGetQuery(con, "SELECT area FROM registered")$area, c(1.5, 2.5, 3.5))

  bound <- dbGetQuery(con, "SELECT ? AS area", params = list(structure(2.5, class = "area_unit")))
  expect_equal(bound$area, 2.5)
})
