## What each route out of a relation makes of the connection's conversion options,
## with every option set away from its default.
library(DBI)

con <- dbConnect(
  duckdb::duckdb(shared_home = FALSE),
  bigint = "integer64",
  array = "matrix",
  map = "list_of",
  geometry = "wk",
  time = "hms",
  blob = "blob"
)

sql <- "SELECT
  42::BIGINT AS big,
  MAP {'a': 1} AS map,
  'POINT (1 2)'::GEOMETRY AS geom,
  TIME '01:02:03' AS time,
  '\\xAA'::BLOB AS blob"
classes <- function(df) vapply(df, function(x) class(x)[[1]], character(1))

## One column of each type, through each route ---------------------------------
rel <- duckdb:::rel_from_sql(con, sql)
rbind(
  dbGetQuery = classes(dbGetQuery(con, sql)),
  rel_to_altrep = classes(duckdb:::rel_to_altrep(rel)),
  as.data.frame = classes(as.data.frame(rel)),
  rel_sql = classes(duckdb:::rel_sql(rel, "SELECT * FROM _"))
)

## An ARRAY column, which the default `array = "none"` refuses ------------------
arr_sql <- "SELECT [1, 2]::INTEGER[2] AS arr"
dim(dbGetQuery(con, arr_sql)$arr)
arr <- duckdb:::rel_from_sql(con, arr_sql)
tryCatch(as.data.frame(arr), error = function(e) conditionMessage(e))

dbDisconnect(con)
