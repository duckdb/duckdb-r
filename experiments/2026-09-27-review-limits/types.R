## R values that write, or create a table, as something other than their type,
## and a column R cannot hold that is refused only after its statement ran.
library(DBI)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))

## NaN and Inf in a Date, difftime or POSIXct stored as double -----------------
x <- c(NaN, Inf, -Inf, NA)
dbWriteTable(
  con,
  "nonfinite",
  data.frame(
    d = as.Date(x),
    dt = as.difftime(x, units = "secs"),
    ts = as.POSIXct(x, tz = "UTC")
  )
)
dbGetQuery(
  con,
  "SELECT d::VARCHAR AS d, dt::VARCHAR AS dt, epoch_us(ts) AS ts_us FROM nonfinite"
)
tryCatch(
  dbGetQuery(con, "SELECT ts::VARCHAR FROM nonfinite"),
  error = first_line
)

## A POSIXct stored as integer ---------------------------------------------------
p <- .POSIXct(c(0L, 86400L), tz = "UTC")
typeof(p)
dbWriteTable(con, "posix_int", data.frame(p = p))
dbGetQuery(con, "SELECT column_type FROM (DESCRIBE posix_int)")
str(dbReadTable(con, "posix_int"))
dbDataType(con, p)
dbGetQuery(con, "SELECT typeof($1) AS type", params = list(p[1]))

## A data frame column -----------------------------------------------------------
two <- data.frame(id = 1:2)
two$s <- data.frame(a = 1:2, b = c("x", "y"))
tryCatch(dbDataType(con, two), error = first_line)
tryCatch(sqlCreateTable(con, "two", two, row.names = FALSE), error = first_line)
tryCatch(dbCreateTable(con, "two", two), error = first_line)
dbWriteTable(con, "two", two)
dbGetQuery(con, "SELECT column_type FROM (DESCRIBE two)")

one <- data.frame(id = 1:2)
one$s <- data.frame(a = 1:2)
dbDataType(con, one)
dbCreateTable(con, "one", one)
dbGetQuery(con, "SELECT column_type FROM (DESCRIBE one)")
tryCatch(dbAppendTable(con, "one", one), error = first_line)

## An ARRAY column under array = "none" -----------------------------------------
dbExecute(con, "CREATE TABLE side (i INTEGER)")
tryCatch(
  dbGetQuery(
    con,
    "INSERT INTO side VALUES (1) RETURNING [i, i]::INTEGER[2] AS a"
  ),
  error = first_line
)
dbGetQuery(con, "SELECT count(*) AS n FROM side")
# A type with no R vector is refused before the statement runs.
tryCatch(
  dbGetQuery(con, "INSERT INTO side VALUES (2) RETURNING i::BIT AS b"),
  error = first_line
)
dbGetQuery(con, "SELECT count(*) AS n FROM side")

dbDisconnect(con)
