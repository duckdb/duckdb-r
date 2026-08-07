## duckdb-r#384 -- DISTINCT ON for the dbplyr backend: where would it go?
library(duckdb)
library(dplyr, warn.conflicts = FALSE)
library(dbplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
packageVersion("dbplyr")

con <- dbConnect(duckdb())
duckdb_register(con, "iris", iris)

# Today's translation, as reported: a ROW_NUMBER() subquery
tbl(con, "iris") |>
  distinct(Petal.Width, Species, .keep_all = TRUE) |>
  show_query()

# The same shape on other backends -- this SQL is written by dbplyr's
# distinct.tbl_lazy(), not by anything in the duckdb dialect
lazy_frame(a = 1, b = 2, con = simulate_postgres()) |>
  distinct(a, .keep_all = TRUE) |>
  show_query()
lazy_frame(a = 1, b = 2, con = simulate_mssql()) |>
  distinct(a, .keep_all = TRUE) |>
  show_query()

# ... and duckdb-r defines no distinct method of its own to intercept it
grep(
  "distinct",
  as.character(methods(class = "duckdb_connection")),
  value = TRUE
)
grep("^distinct", as.character(methods(class = "tbl_lazy")), value = TRUE)

# The engine has supported DISTINCT ON all along; the two queries agree
by_hand <- dbGetQuery(
  con,
  'SELECT DISTINCT ON ("Petal.Width", "Species") * FROM iris ORDER BY "Petal.Width", "Species", "Sepal.Length"'
)
by_dbplyr <- tbl(con, "iris") |>
  distinct(Petal.Width, Species, .keep_all = TRUE) |>
  collect()

nrow(by_hand)
nrow(by_dbplyr)
identical(
  dplyr::arrange(by_hand, Petal.Width, Species),
  as.data.frame(dplyr::arrange(by_dbplyr, Petal.Width, Species))
)

dbDisconnect(con)
