## duckdb-r#2230 -- does the dbplyr translation use TRY_CAST?
library(duckdb)
library(dplyr, warn.conflicts = FALSE)
packageVersion("duckdb")

con <- dbConnect(duckdb())
duckdb_register(con, "iris", iris)

# The request: as.numeric() and friends should translate to TRY_CAST
tbl(con, "iris") |>
  mutate(Petal.Width = as.numeric(Petal.Width)) |>
  dbplyr::sql_render()

tbl(con, "iris") |>
  transmute(
    n = as.numeric(Species),
    i = as.integer(Species),
    d = as.Date(Species),
    ts = as.POSIXct(Species),
    chr = as.character(Species)
  ) |>
  dbplyr::sql_render()

# What TRY_CAST buys: unparseable values become NA instead of aborting the query
dbExecute(
  con,
  "CREATE TABLE t AS SELECT * FROM (VALUES ('1.5'), ('nope')) v(s)"
)

tbl(con, "t") |>
  mutate(n = as.numeric(s)) |>
  collect()

# The same cast written by hand still errors, as it should
try(dbGetQuery(con, "SELECT CAST(s AS DOUBLE) FROM t"))

dbDisconnect(con)
