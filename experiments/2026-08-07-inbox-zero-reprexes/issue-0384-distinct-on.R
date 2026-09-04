## duckdb-r#384 -- DISTINCT ON for the dbplyr backend: is it faster, and
## can a user have it today?
library(duckdb)
library(dplyr, warn.conflicts = FALSE)
library(dbplyr, warn.conflicts = FALSE)
packageVersion("duckdb")
packageVersion("dbplyr")

con <- dbConnect(duckdb(dbdir = tempfile(fileext = ".duckdb")))

# Today's translation, as reported: a ROW_NUMBER() subquery
duckdb_register(con, "iris", iris)
tbl(con, "iris") |>
  distinct(Petal.Width, Species, .keep_all = TRUE) |>
  show_query()

# The same shape on other backends -- this SQL is written by dbplyr's
# distinct.tbl_lazy(), not by anything in the duckdb dialect
lazy_frame(a = 1, b = 2, con = simulate_postgres()) |>
  distinct(a, .keep_all = TRUE) |>
  show_query()
grep(
  "distinct",
  as.character(methods(class = "duckdb_connection")),
  value = TRUE
)

## Is DISTINCT ON faster? 20M rows, 8.6M groups, one thread ------------------

dbExecute(
  con,
  "CREATE TABLE obs AS
     SELECT (hash(i) % 500000)::DOUBLE      AS petal_width,
            ('sp_' || (hash(i + 3) % 20))   AS species,
            (i % 977)::DOUBLE               AS sepal_length,
            (i % 13)::DOUBLE                AS sepal_width,
            (i % 7)::DOUBLE                 AS petal_length
     FROM range(20000000) t(i)"
)
dbGetQuery(
  con,
  "SELECT count(DISTINCT (petal_width, species)) AS groups FROM obs"
)

timing <- function(sql, reps = 3) {
  median(replicate(reps, {
    t0 <- Sys.time()
    dbGetQuery(con, sprintf("SELECT count(*) AS n FROM (%s)", sql))
    as.numeric(difftime(Sys.time(), t0, units = "secs"))
  }))
}

# dbplyr's plan, with the tie-break made explicit so the three mean the same
row_number <- "SELECT * FROM (
   SELECT *, ROW_NUMBER() OVER (
     PARTITION BY petal_width, species ORDER BY sepal_length) AS col01
   FROM obs) q
 WHERE col01 = 1"
# the same result, asked for as DISTINCT ON
distinct_on <- "SELECT DISTINCT ON (petal_width, species) *
 FROM obs ORDER BY petal_width, species, sepal_length"
# and DISTINCT ON when any row per group will do
distinct_on_bare <- "SELECT DISTINCT ON (petal_width, species) * FROM obs"

for (threads in c(1, 4)) {
  dbExecute(con, sprintf("SET threads = %d", threads))
  cat(sprintf(
    "threads=%d | ROW_NUMBER %5.2fs | DISTINCT ON %5.2fs | DISTINCT ON, unordered %5.2fs\n",
    threads,
    timing(row_number),
    timing(distinct_on),
    timing(distinct_on_bare)
  ))
}

## Can a user have DISTINCT ON today, and how deep does it reach? ------------

# Only exported functions: remote_con(), sql_render(), ident(), escape(),
# sql(), dplyr::tbl(), tidyselect::eval_select(). No dbplyr internals.
distinct_on_tbl <- function(.data, ..., .order_by = NULL) {
  con <- dbplyr::remote_con(.data)
  on <- names(tidyselect::eval_select(rlang::expr(c(...)), .data))
  order <- names(tidyselect::eval_select(rlang::enquo(.order_by), .data))
  quote_cols <- function(x) {
    paste(dbplyr::escape(dbplyr::ident(x), con = con), collapse = ", ")
  }
  dplyr::tbl(
    con,
    dbplyr::sql(paste0(
      "SELECT DISTINCT ON (",
      quote_cols(on),
      ") * FROM (",
      dbplyr::sql_render(.data),
      ") AS q ",
      "ORDER BY ",
      quote_cols(c(on, order))
    ))
  )
}

by_hatch <- tbl(con, "iris") |>
  distinct_on_tbl(Petal.Width, Species, .order_by = Sepal.Length)
by_hatch |> show_query()

# It agrees with the verb, and the result stays lazy and composable
by_dbplyr <- tbl(con, "iris") |>
  arrange(Sepal.Length) |>
  distinct(Petal.Width, Species, .keep_all = TRUE)
identical(
  as.data.frame(arrange(collect(by_hatch), Petal.Width, Species)),
  as.data.frame(arrange(collect(by_dbplyr), Petal.Width, Species))
)
by_hatch |> filter(Species == "setosa") |> count() |> collect()

# ... and it can be the verb, for the user's own session
registerS3method(
  "distinct",
  "tbl_duckdb_connection",
  function(.data, ..., .keep_all = FALSE) {
    if (!.keep_all) {
      return(NextMethod())
    }
    distinct_on_tbl(.data, ...)
  }
)
tbl(con, "iris") |>
  distinct(Petal.Width, Species, .keep_all = TRUE) |>
  show_query()
tbl(con, "iris") |>
  distinct(Petal.Width, Species) |>
  show_query()

dbDisconnect(con, shutdown = TRUE)
