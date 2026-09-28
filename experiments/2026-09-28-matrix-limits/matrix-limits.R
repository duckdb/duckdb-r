## A matrix column that carries a class, through every write route,
## and an ARRAY column read by rel_to_altrep() under array = "matrix".
library(DBI)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))
con <- dbConnect(duckdb::duckdb(shared_home = FALSE), array = "matrix")

## A Date matrix column ---------------------------------------------------------
d <- structure(as.Date("2024-01-01") + 0:3, dim = c(2L, 2L))
format(d)
df <- data.frame(id = 1:2)
df$m <- d

dbWriteTable(con, "written", df)
dbGetQuery(con, "SELECT typeof(m) AS type, m FROM written")

duckdb::duckdb_register(con, "registered", df)
dbGetQuery(con, "SELECT typeof(m) AS type, m FROM registered")

dbExecute(con, "CREATE TABLE appended (id INTEGER, m DATE)")
dbAppendTable(con, "appended", df)
dbGetQuery(con, "SELECT typeof(m) AS type, m FROM appended")
dbExecute(con, "CREATE TABLE appended_array (id INTEGER, m DATE[2])")
tryCatch(dbAppendTable(con, "appended_array", df), error = first_line)

# As the only column of a data frame of two rows
single <- df["m"]
dim(single)
dbWriteTable(con, "single", single)
dbGetQuery(con, "SELECT typeof(m) AS type, m FROM single")

# As the first of two columns
first <- df[c("m", "id")]
dbWriteTable(con, "first", first)
dbGetQuery(con, "SELECT typeof(m) AS type, m, id FROM first")

## Other classes, and a plain matrix --------------------------------------------
write_matrix <- function(m) {
  x <- data.frame(id = 1:2)
  x$m <- m
  dbWriteTable(con, "classed", x, overwrite = TRUE)
  dbGetQuery(con, "SELECT typeof(m) AS type, m::VARCHAR AS m FROM classed")
}
lapply(
  list(
    POSIXct = structure(
      as.POSIXct("2024-01-01", tz = "UTC") + 0:3,
      dim = c(2L, 2L)
    ),
    difftime = structure(
      as.difftime(c(1, 2, 3, 4), units = "secs"),
      dim = c(2L, 2L)
    ),
    hms = structure(hms::hms(1:4), dim = c(2L, 2L)),
    factor = structure(factor(c("a", "b", "c", "d")), dim = c(2L, 2L)),
    integer = matrix(1:4, 2)
  ),
  write_matrix
)

## As a parameter ---------------------------------------------------------------
tryCatch(
  dbGetQuery(con, "SELECT $1 AS p", params = list(matrix(1:4, 2))),
  error = first_line
)
dbGetQuery(con, "SELECT typeof($1) AS type, $1 AS p", params = list(d))

## An ARRAY column through rel_to_altrep() --------------------------------------
sql <- "SELECT [range, range + 10]::INTEGER[2] AS a FROM range(%d)"
dbGetQuery(con, sprintf(sql, 4))$a
lazy <- duckdb:::rel_to_altrep(duckdb:::rel_from_sql(con, sprintf(sql, 4)))
lazy$a
length(lazy$a)

altrep_array <- function(conn, query) {
  tryCatch(
    duckdb:::rel_to_altrep(duckdb:::rel_from_sql(conn, query))$a,
    error = first_line
  )
}
altrep_array(con, sprintf(sql, 1))
altrep_array(con, sprintf(sql, 3))
altrep_array(con, sprintf(sql, 0))
altrep_array(
  con,
  "SELECT [range, range + 10, range + 20]::INTEGER[3] AS a FROM range(6)"
)
altrep_array(
  con,
  "SELECT [range::VARCHAR, (range + 10)::VARCHAR]::VARCHAR[2] AS a FROM range(4)"
)
altrep_array(
  con,
  "SELECT [range::VARCHAR, (range + 10)::VARCHAR]::VARCHAR[2] AS a FROM range(3)"
)

# The same failure under the default array = "none"
con_none <- dbConnect(duckdb::duckdb(shared_home = FALSE))
altrep_array(con_none, sprintf(sql, 3))
tryCatch(dbGetQuery(con_none, sprintf(sql, 3)), error = first_line)

# An ARRAY column runs the relation when the data frame is built.
tryCatch(
  duckdb:::rel_to_altrep(duckdb:::rel_from_sql(
    con,
    "SELECT [range, range]::INTEGER[2] AS a, error('boom')::INTEGER AS i FROM range(4)"
  )),
  error = first_line
)
# Without one, the same error waits for a value to be touched.
lazy <- duckdb:::rel_to_altrep(duckdb:::rel_from_sql(
  con,
  "SELECT error('boom')::INTEGER AS i FROM range(4)"
))
tryCatch(lazy$i[1], error = first_line)
# So a row budget fails an ARRAY column when the data frame is built,
tryCatch(
  duckdb:::rel_to_altrep(
    duckdb:::rel_from_sql(con, "SELECT [range, range]::INTEGER[2] AS a FROM range(10)"),
    n_rows = 2
  ),
  error = first_line
)
# and a plain column only once its values are touched.
lazy <- duckdb:::rel_to_altrep(
  duckdb:::rel_from_sql(con, "SELECT range AS a FROM range(10)"),
  n_rows = 2
)
tryCatch(length(lazy$a), error = first_line)

dbDisconnect(con)
dbDisconnect(con_none)
