test_that("test_all_types() output", {
  skip_on_os("windows")

  con <- local_con(array = "matrix")

  local_edition(3)
  withr::local_options(digits.secs = 6)

  expect_snapshot({
    bad <- c(
      # Need to omit timestamp columns, likely due to https://bugs.r-project.org/show_bug.cgi?id=16856
      "timestamp_tz",
      "time_tz",
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
      NULL
    )

    as.list(dbGetQuery(
      con,
      paste0("SELECT * EXCLUDE (", paste(bad, collapse = ", "), ") REPLACE(replace(varchar, chr(0), '') AS varchar) FROM test_all_types(use_large_enum=true)")
    ))
  })
})
