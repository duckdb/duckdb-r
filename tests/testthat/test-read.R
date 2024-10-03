test_that("duckdb_read_csv() works as expected", {
  skip_if_not(TEST_RE2)

  con <- dbConnect(duckdb())

  tf <- tempfile()

  # default case
  write.csv(iris, tf, row.names = FALSE)
  duckdb_read_csv(con, "iris", tf)
  res <- dbReadTable(con, "iris")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))

  # table exists
  duckdb_read_csv(con, "iris", tf)
  count <- dbGetQuery(con, "SELECT COUNT(*) FROM iris")[1][1]
  expect_true(identical(as.integer(count), as.integer(nrow(iris) * 2)))
  dbRemoveTable(con, "iris")


  # different separator
  write.table(iris, tf, row.names = FALSE, sep = " ")
  duckdb_read_csv(con, "iris", tf, delim = " ")
  res <- dbReadTable(con, "iris")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))
  dbRemoveTable(con, "iris")

  write.table(iris, tf, row.names = FALSE, sep = " ")
  duckdb_read_csv(con, "iris", tf, sep = " ")
  res <- dbReadTable(con, "iris")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))
  dbRemoveTable(con, "iris")

  # no header
  write.table(iris, tf, row.names = FALSE, sep = ",", col.names = FALSE)
  duckdb_read_csv(con, "iris", tf, header = FALSE)
  res <- dbReadTable(con, "iris")
  names(res) <- names(iris)
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))
  dbRemoveTable(con, "iris")

  # lowercase header
  write.csv(iris, tf, row.names = FALSE)
  duckdb_read_csv(con, "iris", tf, lower.case.names = T)
  res <- dbReadTable(con, "iris")
  res$species <- as.factor(res$species)
  iris_lc <- iris
  names(iris_lc) <- tolower(names(iris))
  expect_true(identical(res, iris_lc))
  dbRemoveTable(con, "iris")

  # nulls
  iris_na <- iris
  iris_na[[2]][42] <- NA

  write.csv(iris_na, tf, row.names = FALSE, na = "")
  duckdb_read_csv(con, "iris", tf)
  res <- dbReadTable(con, "iris")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris_na))
  dbRemoveTable(con, "iris")


  write.csv(iris_na, tf, row.names = FALSE, na = "NULL")
  duckdb_read_csv(con, "iris", tf, na.strings = "NULL")
  res <- dbReadTable(con, "iris")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris_na))
  dbRemoveTable(con, "iris")


  # strange table name
  write.csv(iris, tf, row.names = FALSE)
  duckdb_read_csv(con, "ir Is", tf)
  res <- dbReadTable(con, "ir Is")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))
  dbRemoveTable(con, "ir Is")


  # specified column names
  colnames <- paste0("c", 1:5)
  write.csv(iris, tf, row.names = FALSE)
  duckdb_read_csv(con, "iris", tf, col.names = colnames)
  res <- dbReadTable(con, "iris")
  res$c5 <- as.factor(res$c5)
  iris_c <- iris
  names(iris_c) <- colnames
  expect_true(identical(res, iris_c))
  dbRemoveTable(con, "iris")


  # multiple files
  tf2 <- tempfile()
  write.csv(iris, tf2, row.names = FALSE)
  duckdb_read_csv(con, "iris", c(tf, tf2))
  count <- dbGetQuery(con, "SELECT COUNT(*) FROM iris")[1][1]
  expect_true(identical(as.integer(count), as.integer(nrow(iris) * 2)))
  dbRemoveTable(con, "iris")


  # deprecated API
  write.csv(iris, tf, row.names = FALSE)
  expect_warning(read_csv_duckdb(con, tf, "iris"), "duckdb_read_csv")
  res <- dbReadTable(con, "iris")
  res$Species <- as.factor(res$Species)
  expect_true(identical(res, iris))

  # test better na.strings handling
  # see https://github.com/duckdb/duckdb/issues/8590
  tf3 <- tempfile()
  csv <- c(
    '"num","char","logi","lisst.1","lisst.2","lisst.3","lisst.NA"',
    '0.5,"yes",TRUE,1,2,3,NA',
    '2,"no",FALSE,1,2,3,NA',
    'NA,NA,NA,1,2,3,NA'
  )
  writeLines(csv, tf3)
  duckdb_read_csv(con, "na_table", tf3, na.strings = "-")
  expect_identical(
    dbReadTable(con, "na_table"),
    read.csv(tf3, na.strings = "-")
  )

  # temporary table
  # see https://github.com/duckdb/duckdb-r/issues/142
  db <- tempfile()
  con2 <- dbConnect(duckdb(), dbdir = db)
  duckdb_read_csv(con2, "iris", tf, temporary = TRUE)
  expect_true(length(dbListTables(con2)) == 1)
  dbDisconnect(con2)

  con2 <- dbConnect(duckdb(), dbdir = db)
  expect_true(length(dbListTables(con2)) == 0)
  dbDisconnect(con2)

  dbDisconnect(con, shutdown = TRUE)
})
