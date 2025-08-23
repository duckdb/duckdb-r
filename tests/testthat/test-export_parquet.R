test_that("export_parquet write a valid Parquet file", {
  withr::with_tempfile("parquet_file", fileext = ".parquet", {
    con <- dbConnect(duckdb::duckdb())
    on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

    df <- data.frame(x = 1:3, y = letters[1:3])
    copy_to(con, df, "test_table", temporary = TRUE)

    data <- tbl(con, "test_table")
    export_parquet(data, parquet_file)

    expect_true(file.exists(parquet_file))
  })
})

test_that("export_parquet allows options", {
  withr::with_tempfile("parquet_file", fileext = ".parquet", {
    con <- dbConnect(duckdb::duckdb())
    on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

    df <- data.frame(a = 1:5, b = 1:5)
    copy_to(con, df, "table_opt", temporary = TRUE)
    data <- tbl(con, "table_opt")

    expect_silent(export_parquet(data, parquet_file, list(compression = "zstd", row_group_size = 1000)))
    expect_true(file.exists(parquet_file))

  })
})

test_that("export_parquet échoue proprement si le fichier est invalide", {
  con <- dbConnect(duckdb::duckdb())
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

  df <- data.frame(z = 1:2)
  copy_to(con, df, "bad_path_table", temporary = TRUE)
  data <- tbl(con, "bad_path_table")

  expect_error(
    export_parquet(data, "/chemin/inexistant/fichier.parquet"),
    "IO Error|Failed to open"
  )
})

