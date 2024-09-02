test_that("test_all_types() output", {
  skip_on_os("windows")

  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE))

  local_edition(3)
  withr::local_options(digits.secs = 6)

  # Need to omit timestamp columns, likely due to https://bugs.r-project.org/show_bug.cgi?id=16856
  expect_snapshot({
    as.list(dbGetQuery(con, "SELECT * EXCLUDE (timestamp_tz, time_tz, timestamp_ns, timestamp_array, timestamptz_array, bit, \"union\", fixed_int_array, fixed_varchar_array, fixed_nested_int_array, fixed_nested_varchar_array, fixed_struct_array, struct_of_fixed_array, fixed_array_of_int_list, list_of_fixed_int_array, varint) REPLACE(replace(varchar, chr(0), '') AS varchar) FROM test_all_types(use_large_enum=true)"))
  })
})
