# The same names on duckdb 1.4.0, where the probe swallowed the quoting error.
# Handbook: experiments/2026-11-17-asis-table-names/README.md

library(duckdb)
library(DBI)
options(width = 120)

con <- dbConnect(duckdb())
dbExecute(con, "CREATE SCHEMA s")
dbExecute(con, "CREATE TABLE s.t AS SELECT 1 AS a")

try(dbQuoteIdentifier(con, I("s.t")))
dbExistsTable(con, I("s.t"))

# tbl() then took the `FROM` fallback meant for replacement scans.
lazy <- dplyr::tbl(con, I("s.t"))
dbplyr::remote_table(lazy)
dplyr::show_query(lazy)

specs <- list(
  `I("s.t")` = I("s.t"),
  `SQL("s.t")` = SQL("s.t"),
  `in_schema("s", "t")` = dbplyr::in_schema("s", "t"),
  `Id("s", "t")` = Id("s", "t"),
  `ident_q("s.t")` = suppressWarnings(dbplyr::ident_q("s.t")),
  `"s.t"` = "s.t",
  `sql("SELECT * FROM s.t")` = dbplyr::sql("SELECT * FROM s.t")
)
outcome <- function(expr) {
  tryCatch(
    {
      res <- suppressWarnings(suppressMessages(expr))
      if (inherits(res, "tbl_lazy")) {
        paste0("rows: ", nrow(dplyr::collect(res)))
      } else {
        format(res)
      }
    },
    error = function(e) {
      paste0("error: ", substr(gsub("\\s+", " ", conditionMessage(e)), 1, 80))
    }
  )
}
knitr::kable(
  row.names = FALSE,
  data.frame(
    name = paste0("`", names(specs), "`"),
    dbExistsTable = vapply(
      specs,
      function(x) outcome(dbExistsTable(con, x)),
      character(1)
    ),
    tbl = vapply(specs, function(x) outcome(dplyr::tbl(con, x)), character(1))
  )
)

dbDisconnect(con)
