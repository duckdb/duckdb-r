# Expectations for the refusal of a matrix or array the scan would count by its values,
# used by `test-array.R` (#2860).

# Typed by its class, a matrix would count its values as rows,
# and so would an array of more than two dimensions,
# so every write route refuses it (handbook/usage/types/README.md)
expect_column_refused <- function(con, m, affected) {
  dbExecute(con, "CREATE OR REPLACE TABLE appended (s VARCHAR, m VARCHAR)")
  for (m_first in c(TRUE, FALSE)) {
    df <- data.frame(s = c("a", "b"))
    df$m <- m
    if (m_first) {
      df <- df[c("m", "s")]
    }
    expect_error(dbWriteTable(con, "written", df), affected, fixed = TRUE)
    expect_error(duckdb_register(con, "registered", df), affected, fixed = TRUE)
    expect_error(dbAppendTable(con, "appended", df), affected, fixed = TRUE)
  }
  expect_false(dbExistsTable(con, "written"))
  expect_false(dbExistsTable(con, "registered"))
  expect_equal(dbGetQuery(con, "SELECT count(*) AS n FROM appended")$n, 0)
}

expect_classed_matrix_refused <- function(con, m, type = class(m)[[1]]) {
  type_note <- paste0(" (class `", type, "`)")
  expect_column_refused(con, m, paste0("Affected column: `m`", type_note))
  expect_error(
    dbGetQuery(con, "SELECT $1 AS p", params = list(m)),
    paste0("Affected parameter: `params[[1]]`", type_note),
    fixed = TRUE
  )
  expect_error(
    dbGetQuery(con, "SELECT $1 AS p, $2 AS q", params = list(1:2, m)),
    paste0("Affected parameter: `params[[2]]`", type_note),
    fixed = TRUE
  )
}
