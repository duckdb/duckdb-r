# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

skip_on_cran()
skip_on_os("windows")
skip_if_not(get_package_name() == "duckdb")
skip_if_not_installed("dbplyr")
skip_if_not_installed("dplyr")
skip_if_not_installed("arrow", "5.0.0")
# Skip if parquet is not a capability as an indicator that Arrow is fully installed.
skip_if_not(arrow::arrow_with_parquet(), message = "The installed Arrow is not fully featured, skipping Arrow integration tests")

example_data <- dplyr::tibble(
  int = c(1:3, NA_integer_, 5:10),
  dbl = c(1:8, NA, 10) + .1,
  dbl2 = rep(5, 10),
  lgl = sample(c(TRUE, FALSE, NA), 10, replace = TRUE),
  false = logical(10),
  chr = letters[c(1:5, NA, 7:10)],
  fct = factor(letters[c(1:4, NA, NA, 7:10)])
)

test_that("to_duckdb", {
  ds <- arrow::InMemoryDataset$create(example_data)
  con <- local_con()

  dbExecute(con, "PRAGMA threads=1")
  expect_equal(
    ds %>%
      arrow::to_duckdb(con = con) %>%
      dplyr::collect() %>%
      # factors don't roundtrip https://github.com/duckdb/duckdb/issues/1879
      dplyr::select(!fct) %>%
      dplyr::arrange(int),
    example_data %>%
      dplyr::select(!fct) %>%
      dplyr::arrange(int)
  )

  df1 <- ds %>%
      dplyr::select(int, lgl, dbl) %>%
      arrow::to_duckdb(con = con) %>%
      dplyr::group_by(lgl) %>%
      dplyr::summarise(sum_int = sum(int, na.rm = TRUE)) %>%
      dplyr::collect() %>%
      dplyr::arrange(lgl, sum_int)
  df2 <- example_data %>%
      dplyr::select(int, lgl, dbl) %>%
      dplyr::group_by(lgl) %>%
      dplyr::summarise(sum_int = sum(int, na.rm = TRUE)) %>%
      dplyr::arrange(lgl, sum_int)

  # can group_by before the to_duckdb
  df1 <- ds %>%
      dplyr::select(int, lgl, dbl) %>%
      dplyr::group_by(lgl) %>%
      arrow::to_duckdb(con = con) %>%
      dplyr::summarise(sum_int = sum(int, na.rm = TRUE)) %>%
      dplyr::collect() %>%
      dplyr::arrange(lgl, sum_int)
  df2 <- example_data %>%
      dplyr::select(int, lgl, dbl) %>%
      dplyr::group_by(lgl) %>%
      dplyr::summarise(sum_int = sum(int, na.rm = TRUE)) %>%
      dplyr::arrange(lgl, sum_int)
})

test_that("to_duckdb then to_arrow", {
  ds <- arrow::InMemoryDataset$create(example_data)

  ds_rt <- ds %>%
    arrow::to_duckdb() %>%
    # factors don't roundtrip https://github.com/duckdb/duckdb/issues/1879
    dplyr::select(-fct) %>%
    arrow::to_arrow()

  expect_identical(
    dplyr::collect(ds_rt),
    ds %>%
      dplyr::select(-fct) %>%
      dplyr::collect()
  )

  # And we can continue the pipeline
  ds_rt <- ds %>%
    arrow::to_duckdb() %>%
    # factors don't roundtrip https://github.com/duckdb/duckdb/issues/1879
    dplyr::select(-fct) %>%
    dplyr::filter(int > 5)

  expect_identical(
    ds_rt %>%
      dplyr::collect() %>%
      dplyr::arrange(int),
    ds %>%
      dplyr::select(-fct) %>%
      dplyr::filter(int > 5) %>%
      dplyr::collect() %>%
      dplyr::arrange(int)
  )

  # Now check errors
  ds_rt <- ds %>%
    arrow::to_duckdb() %>%
    # factors don't roundtrip https://github.com/duckdb/duckdb/issues/1879
    dplyr::select(-fct)

  # alter the class of ds_rt's connection to simulate some other database
  class(ds_rt$src$con) <- "some_other_connection"

  skip_if_not_installed("dbplyr", "2.5.2.9000")

  ds_rt_arrow <- ds_rt %>%
    arrow::to_arrow()

  expect_identical(
    ds_rt_arrow %>%
      dplyr::collect() %>%
      dplyr::arrange(int),
    ds_rt %>%
      dplyr::collect() %>%
      dplyr::arrange(int)
  )
})

test_that("to_arrow roundtrip, with dataset", {
  # With a multi-part dataset
  tf <- tempfile()
  new_ds <- rbind(
    cbind(example_data, part = 1),
    cbind(example_data, part = 2),
    cbind(dplyr::mutate(example_data, dbl = dbl * 3, dbl2 = dbl2 * 3), part = 3),
    cbind(dplyr::mutate(example_data, dbl = dbl * 4, dbl2 = dbl2 * 4), part = 4)
  )
  arrow::write_dataset(new_ds, tf, partitioning = "part")

  ds <- arrow::open_dataset(tf)

  expect_identical(
    ds %>%
      arrow::to_duckdb() %>%
      dplyr::select(-fct) %>%
      dplyr::mutate(dbl_plus = dbl + 1) %>%
      arrow::to_arrow() %>%
      dplyr::filter(int > 5 & part > 1) %>%
      dplyr::collect() %>%
      dplyr::arrange(part, int) %>%
      as.data.frame(),
    ds %>%
      dplyr::select(-fct) %>%
      dplyr::filter(int > 5 & part > 1) %>%
      dplyr::mutate(dbl_plus = dbl + 1) %>%
      dplyr::collect() %>%
      dplyr::arrange(part, int) %>%
      as.data.frame()
  )
})

# test_that("to_arrow roundtrip, with dataset (without wrapping", {
#   # With a multi-part dataset
#   tf <- tempfile()
#   new_ds <- rbind(
#     cbind(example_data, part = 1),
#     cbind(example_data, part = 2),
#     cbind(dplyr::mutate(example_data, dbl = dbl * 3, dbl2 = dbl2 * 3), part = 3),
#     cbind(dplyr::mutate(example_data, dbl = dbl * 4, dbl2 = dbl2 * 4), part = 4)
#   )
#   arrow::write_dataset(new_ds, tf, partitioning = "part")

#   out <- ds %>%
#     arrow::to_duckdb() %>%
#     dplyr::select(-fct) %>%
#     dplyr::mutate(dbl_plus = dbl + 1) %>%
#     arrow::to_arrow(as_arrow_query = FALSE)

#   expect_r6_class(out, "RecordBatchReader")
# })

# The next set of tests use an already-extant connection to test features of
# persistence and querying against the table without using the `tbl` itself, so
# we need to create a connection separate from the ephemeral one that is made
# with arrow_duck_connection()
con <- local_con()
dbExecute(con, "PRAGMA threads=1")

test_that("Joining, auto-cleanup enabled", {
  ds <- arrow::InMemoryDataset$create(example_data)

  table_one_name <- "my_arrow_table_1"
  table_one <- arrow::to_duckdb(ds, con = con, table_name = table_one_name)
  table_two_name <- "my_arrow_table_2"
  table_two <- arrow::to_duckdb(ds, con = con, table_name = table_two_name)

  res <- dbGetQuery(
    con,
    paste0(
      "SELECT * FROM ", table_one_name,
      " INNER JOIN ", table_two_name,
      " ON ", table_one_name, ".int = ", table_two_name, ".int"
    )
  )
  expect_identical(dim(res), c(9L, 14L))

  # clean up cleans up the tables
  expect_true(all(c(table_one_name, table_two_name) %in% duckdb_list_arrow(con)))
  rm(table_one, table_two)
  gc()
  expect_false(any(c(table_one_name, table_two_name) %in% duckdb_list_arrow(con)))
})

test_that("Joining, auto-cleanup disabled", {
  ds <- arrow::InMemoryDataset$create(example_data)

  table_three_name <- "my_arrow_table_3"
  table_three <- arrow::to_duckdb(ds, con = con, table_name = table_three_name, auto_disconnect = FALSE)

  # clean up does *not* clean these tables
  expect_true(table_three_name %in% duckdb_list_arrow(con))
  rm(table_three)
  gc()
  # but because we aren't auto_disconnecting then we still have this table.
  expect_true(table_three_name %in% duckdb_list_arrow(con))
})

test_that("to_duckdb with a table", {
  tab <- arrow::Table$create(example_data)

  expect_identical(
    tab %>%
      arrow::to_duckdb() %>%
      dplyr::group_by(int > 4) %>%
      dplyr::summarise(
        int_mean = mean(int, na.rm = TRUE),
        dbl_mean = mean(dbl, na.rm = TRUE)
      ) %>%
      dplyr::arrange(dbl_mean) %>%
      dplyr::collect(),
    dplyr::tibble(
      "int > 4" = c(FALSE, NA, TRUE),
      int_mean = c(2, NA, 7.5),
      dbl_mean = c(2.1, 4.1, 7.3)
    )
  )
})

test_that("to_duckdb passing a connection", {
  skip_if_not(TEST_RE2)

  ds <- arrow::InMemoryDataset$create(example_data)

  con_separate <- local_con()
  # we always want to test in parallel
  dbExecute(con_separate, "PRAGMA threads=2")

  # create a table to join to that we know is in our con_separate
  new_df <- data.frame(
    int = 1:10,
    char = letters[26:17],
    stringsAsFactors = FALSE
  )
  DBI::dbWriteTable(con_separate, "separate_join_table", new_df)

  table_four <- ds %>%
    dplyr::select(int, lgl, dbl) %>%
    arrow::to_duckdb(con = con_separate, auto_disconnect = FALSE)
  table_four_name <- dbplyr::remote_name(table_four)

  result <- DBI::dbGetQuery(
    con_separate,
    paste0(
      "SELECT * FROM ", table_four_name,
      " INNER JOIN separate_join_table ",
      "ON separate_join_table.int = ", table_four_name, ".int"
    )
  )

  expect_identical(dim(result), c(9L, 5L))
  expect_identical(result$char, new_df[new_df$int != 4, ]$char)
})
