# Reads a CSV file into DuckDB

Directly reads a CSV file into DuckDB, tries to detect and create the
correct schema for it. This usually is much faster than reading the data
into R and writing it to DuckDB.

## Usage

``` r
duckdb_read_csv(
  conn,
  name,
  files,
  ...,
  header = TRUE,
  na.strings = "",
  nrow.check = 500,
  delim = ",",
  quote = "\"",
  col.names = NULL,
  col.types = NULL,
  lower.case.names = FALSE,
  sep = delim,
  transaction = TRUE,
  temporary = FALSE
)
```

## Arguments

- conn:

  A DuckDB connection, created by
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

- name:

  The name for the virtual table that is registered or unregistered

- files:

  One or more CSV file names, should all have the same structure though

- ...:

  Reserved for future extensions, must be empty.

- header:

  Whether or not the CSV files have a separate header in the first line

- na.strings:

  Which strings in the CSV files should be considered to be NULL

- nrow.check:

  How many rows should be read from the CSV file to figure out data
  types

- delim:

  Which field separator should be used

- quote:

  Which quote character is used for columns in the CSV file

- col.names:

  Override the detected or generated column names

- col.types:

  Character vector of column types in the same order as col.names, or a
  named character vector where names are column names and types pairs.
  Valid types are [DuckDB data
  types](https://duckdb.org/docs/sql/data_types/overview.html), e.g.
  VARCHAR, DOUBLE, DATE, BIGINT, BOOLEAN, etc.

- lower.case.names:

  Transform column names to lower case

- sep:

  Alias for delim for compatibility

- transaction:

  Should a transaction be used for the entire operation

- temporary:

  Set to `TRUE` to create a temporary table

## Value

The number of rows in the resulted table, invisibly.

## Details

If the table already exists in the database, the csv is appended to it.
Otherwise the table is created.

## Examples

``` r
if (FALSE) { # duckdb:::TEST_RE2
con <- dbConnect(duckdb())

data <- data.frame(a = 1:3, b = letters[1:3])
path <- tempfile(fileext = ".csv")

write.csv(data, path, row.names = FALSE)

duckdb_read_csv(con, "data", path)
dbReadTable(con, "data")

dbDisconnect(con)


# Providing data types for columns
path <- tempfile(fileext = ".csv")
write.csv(iris, path, row.names = FALSE)

con <- dbConnect(duckdb())
duckdb_read_csv(con, "iris", path,
  col.types = c(
    Sepal.Length = "DOUBLE",
    Sepal.Width = "DOUBLE",
    Petal.Length = "DOUBLE",
    Petal.Width = "DOUBLE",
    Species = "VARCHAR"
  )
)
dbReadTable(con, "iris")
dbDisconnect(con)
}
```
