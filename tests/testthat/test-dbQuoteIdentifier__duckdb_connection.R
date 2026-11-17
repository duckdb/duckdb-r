test_that("only quotes where needed", {
  con <- local_con()

  expect_equal(
    dbQuoteIdentifier(con, c("x y", "select", "SELECT", "x", "2nd")),
    SQL(c('"x y"', '"select"', '"SELECT"', "x", '"2nd"'))
  )
})

test_that("preserves expected DBI behaviour", {
  con <- local_con()

  expect_equal(dbQuoteIdentifier(con, SQL("SELECT")), SQL("SELECT"))
  expect_equal(dbQuoteIdentifier(con, character()), SQL(character()))
  expect_equal(dbQuoteIdentifier(con, c(a = "a")), SQL("a", names = "a"))

  expect_equal(
    dbQuoteIdentifier(con, Id(schema = "a", table = "b")),
    SQL("a.b")
  )
  expect_equal(
    dbQuoteIdentifier(con, Id(schema = "SELECT", table = "b")),
    SQL('"SELECT".b')
  )
})

test_that("passes a name wrapped in I() through unquoted, as dbplyr does (#2973)", {
  con <- local_con()

  expect_equal(dbQuoteIdentifier(con, I("s.t")), SQL("s.t"))
  expect_equal(dbQuoteIdentifier(con, I(c(a = "s.t"))), SQL("s.t", names = "a"))
})
