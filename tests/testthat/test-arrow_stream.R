skip_on_cran()
skip_on_os("windows")
skip_if_not_installed("arrow", "5.0.0")
skip_if_not_installed("dbplyr")

library("dplyr", warn.conflicts = FALSE)

# Skip if parquet is not a capability as an indicator that Arrow is fully installed.
skip_if_not(arrow::arrow_with_parquet(), message = "The installed Arrow is not fully featured, skipping Arrow integration tests")

test_that("round trip arrow stream", {
  ds <- arrow::open_dataset(rep(test_path("data/userdata1.parquet"), 4))

  to_to <- ds %>%
    select(-registration_dttm) %>% # timestamp[ns] has unrelated error
    arrow::to_duckdb() %>%
    arrow::to_arrow() %>%
    collect() %>%
    arrange(id)

  all_arrow <- ds %>%
    select(-registration_dttm) %>% # timestamp[ns] has unrelated error
    collect() %>%
    arrange(id)


  # The full comparison
  expect_true(all.equal(to_to, all_arrow))
})

test_that("round trip arrow stream with query", {
  ds <- arrow::open_dataset(rep(test_path("data/userdata1.parquet"), 4))


  to_to <- ds %>%
    select(-registration_dttm) %>% # timestamp[ns] has unrelated error
    arrow::to_duckdb() %>%
    mutate(new_id = id + 1L) %>%
    arrow::to_arrow() %>%
    collect() %>%
    arrange(id)

  all_arrow <- ds %>%
    select(-registration_dttm) %>% # timestamp[ns] has unrelated error
    mutate(new_id = id + 1) %>%
    collect() %>%
    arrange(id)


  # The full comparison
  expect_true(all.equal(to_to, all_arrow))
})
