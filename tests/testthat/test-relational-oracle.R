# Run this file with testthat::test_local(filter = "^relational-oracle$")

con <- local_con()

normalize_rel_text <- function(x) {
  x <- gsub("0x[0-9a-f]+", "0x...", x)
  x <- gsub("dataframe_[0-9]+_[0-9]+", "dataframe_<id>", x)
  x <- gsub(
    "(JOIN_RELATION|CROSS_PRODUCT_RELATION|EXTENSION_RELATION)_[0-9a-f]+",
    "\\1_<id>",
    x
  )
  transform_package_name(x)
}

show_rel <- function(rel) {
  writeLines(rel_tostring(rel, "tree"))
  writeLines(rel_tostring(rel))
  writeLines(rel_to_sql(rel))
}

gt <- function(name, value) {
  expr_comparison(">", list(expr_reference(name), expr_constant(value)))
}

eq <- function(lhs, rhs) {
  expr_comparison("=", list(expr_reference(lhs), expr_reference(rhs)))
}

ge <- function(lhs, rhs) {
  expr_comparison(">=", list(expr_reference(lhs), expr_reference(rhs)))
}

oracle_lhs <- function() {
  rel_set_alias(
    rel_from_df(con, data.frame(a = 1:2, b = c("x", "y"))),
    "lhs"
  )
}

oracle_rhs <- function() {
  rel_set_alias(rel_from_df(con, data.frame(c = 1:2, d = c(2.5, 3.5))), "rhs")
}

dropped_table_rel <- function(con, name) {
  dbExecute(con, paste0("CREATE TABLE ", name, " (a INTEGER)"))
  rel <- rel_from_table(con, name)
  dbExecute(con, paste0("DROP TABLE ", name))
  rel
}

# Build-time errors

test_that("build error: filter on a column that does not exist", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  rel <- rel_from_df(con, data.frame(a = 1:3))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_filter(rel, list(expr_reference("zz")))
  })
})

test_that("build error: projection with an unknown function", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  rel <- rel_from_df(con, data.frame(a = 1:3))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_project(rel, list(expr_function("nofunc", list(expr_reference("a")))))
  })
})

test_that("build error: aggregate", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  rel <- rel_from_df(con, data.frame(a = 1:3))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_aggregate(
      rel,
      list(expr_reference("zz")),
      list(n = expr_function("count", list()))
    )
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_aggregate(rel, list(), list(n = expr_function("nofunc", list())))
  })
})

test_that("build error: order", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  rel <- rel_from_df(con, data.frame(a = 1:3))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_order(rel, list(expr_reference("zz")))
  })
})

test_that("build error: join with a bad condition", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  x <- rel_from_df(con, data.frame(a = 1:3))
  y <- rel_from_df(con, data.frame(c = 1:3))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_join(x, y, list(eq("zz", "c")))
  })
})

test_that("build error: cross join with a bad condition", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  x <- rel_from_df(con, data.frame(a = 1:3))
  y <- rel_from_df(con, data.frame(c = 1:3))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_join(x, y, list(eq("zz", "c")), "cross")
  })
})

test_that("build error: a regular join without conditions is an internal error", {
  x <- rel_from_df(con, data.frame(a = 1:3))
  y <- rel_from_df(con, data.frame(c = 1:3))

  expect_error(
    rel_join(x, y, list(), "inner"),
    "Attempted to access index 0 within vector of size 0",
    fixed = TRUE
  )
  expect_equal(dbGetQuery(con, "SELECT 1 AS ok")$ok, 1)
})

test_that("union all of unequal widths fails at build time", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  x <- rel_from_df(con, data.frame(a = 1:3, b = 1:3))
  y <- rel_from_df(con, data.frame(c = 1:3))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_union_all(x, y)
  })
})

test_that("build error: intersect, except and symmetric difference of unequal widths", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  x <- rel_from_df(con, data.frame(a = 1:3, b = 1:3))
  y <- rel_from_df(con, data.frame(c = 1:3))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_set_intersect(x, y)
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_set_diff(x, y)
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_set_symdiff(x, y)
  })
})

test_that("build error: table function", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  withr::local_dir(withr::local_tempdir())

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_table_function(con, "nofunc", list())
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_table_function(con, "read_csv", list("does-not-exist.csv"))
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_table_function(con, "repeat_row", list(1L), list(bogus = 3L))
  })
})

test_that("build error: distinct over a dropped table", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  rel <- dropped_table_rel(con, "oracle_dropped_distinct")

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_distinct(rel)
  })
})

test_that("build error: alias over a dropped table", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  rel <- dropped_table_rel(con, "oracle_dropped_alias")

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_set_alias(rel, "foo")
  })
})

test_that("limit builds unbound over a dropped table, and reading it fails", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  rel <- dropped_table_rel(con, "oracle_dropped_limit")

  limited <- rel_limit(rel, 1)
  expect_s3_class(limited, "duckdb_relation")
  expect_identical(names(limited), "a")
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    as.data.frame(limited)
  })
})

# Depth

test_that("depth: 600 filters build and materialize lazily, but not through as.data.frame()", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  expect_equal(
    dbGetQuery(con, "SELECT current_setting('max_expression_depth') AS d")$d,
    1000
  )

  rel <- rel_from_df(con, data.frame(a = 1:3))
  for (i in 1:600) {
    rel <- rel_filter(rel, list(gt("a", 0L)))
  }

  expect_equal(nrow(rel_to_altrep(rel)), 3)
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    as.data.frame(rel)
  })
})

test_that("depth: 998 projections build and the 999th fails", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")

  rel <- rel_from_df(con, data.frame(a = 1L))
  for (i in 1:998) {
    rel <- rel_project(rel, list(expr_reference("a")))
  }

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_project(rel, list(expr_reference("a")))
  })
})

# Result mismatch

test_that("result mismatch: a column added after rel_from_table()", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  dbExecute(con, "CREATE TABLE oracle_mismatch_df AS SELECT 1 AS a")
  rel <- rel_from_table(con, "oracle_mismatch_df")
  dbExecute(con, "ALTER TABLE oracle_mismatch_df ADD COLUMN y INTEGER")

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    as.data.frame(rel)
  })
})

test_that("result mismatch: a lazy data frame fails on every access with the same message", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  dbExecute(con, "CREATE TABLE oracle_mismatch_altrep AS SELECT 1 AS a")
  rel <- rel_from_table(con, "oracle_mismatch_altrep")
  dbExecute(con, "ALTER TABLE oracle_mismatch_altrep ADD COLUMN y INTEGER")
  df <- rel_to_altrep(rel)

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    nrow(df)
  })
  first <- tryCatch(nrow(df), error = conditionMessage)
  second <- tryCatch(df$a[1], error = conditionMessage)
  expect_identical(second, first)
})

# rel_from_sql()

test_that("from sql: more than one statement, or not a SELECT", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  dbExecute(con, "CREATE TABLE oracle_from_sql_insert (a INTEGER)")

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_sql(con, "SELECT 1; SELECT 2")
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_sql(con, "INSERT INTO oracle_from_sql_insert VALUES (1)")
  })
  expect_equal(
    dbGetQuery(con, "SELECT count(*) AS n FROM oracle_from_sql_insert")$n,
    0
  )
})

test_that("from sql: two data frames stay usable after the function has returned", {
  local_edition(3)
  scan_con <- local_con(drv = duckdb(environment_scan = TRUE))
  make_rel <- function() {
    d1 <- data.frame(a = 1:2)
    d2 <- data.frame(b = c("x", "y"))
    rel_from_sql(scan_con, "SELECT * FROM d1 CROSS JOIN d2 ORDER BY a, b")
  }

  rel <- make_rel()
  gc()
  gc()

  expect_equal(
    as.data.frame(rel),
    data.frame(a = c(1L, 1L, 2L, 2L), b = c("x", "y", "x", "y")),
    ignore_attr = TRUE
  )
  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
})

test_that("from sql: name used twice is pinned once", {
  local_edition(3)
  scan_con <- local_con(drv = duckdb(environment_scan = TRUE))
  make_rel <- function() {
    dd <- data.frame(a = 1:3)
    rel_from_sql(
      scan_con,
      "SELECT x.a, y.a AS b FROM dd x JOIN dd y ON x.a = y.a ORDER BY x.a"
    )
  }

  rel <- make_rel()
  gc()

  expect_equal(
    as.data.frame(rel),
    data.frame(a = 1:3, b = 1:3),
    ignore_attr = TRUE
  )
  expect_snapshot(transform = normalize_rel_text, {
    writeLines(rel_to_sql(rel))
  })
})

test_that("from sql: the name lookup in the environment is case sensitive", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  scan_con <- local_con(drv = duckdb(environment_scan = TRUE))

  upper_text <- new.env(parent = emptyenv())
  upper_text$dd <- data.frame(a = 1:3)
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_sql(scan_con, "SELECT * FROM DD", env = upper_text)
  })

  mixed_name <- new.env(parent = emptyenv())
  mixed_name$Dd <- data.frame(a = 1:3)
  expect_error(
    rel_from_sql(scan_con, "SELECT * FROM dd", env = mixed_name),
    "Table with name dd does not exist!",
    fixed = TRUE
  )

  both <- new.env(parent = emptyenv())
  both$dd <- data.frame(a = 1:3)
  expect_error(
    rel_from_sql(
      scan_con,
      "SELECT * FROM dd x JOIN DD y USING (a)",
      env = both
    ),
    "Table with name DD does not exist!",
    fixed = TRUE
  )
})

test_that("from sql: R error in lookup reaches the user as that R error", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  scan_con <- local_con(drv = duckdb(environment_scan = TRUE))

  promise_env <- new.env(parent = emptyenv())
  delayedAssign("bad", stop("boom from promise"), assign.env = promise_env)
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_sql(scan_con, "FROM bad", env = promise_env)
  })

  active_env <- new.env(parent = emptyenv())
  makeActiveBinding("act", function() stop("boom from binding"), active_env)
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_sql(scan_con, "FROM act", env = active_env)
  })

  interrupt_env <- new.env(parent = emptyenv())
  makeActiveBinding("stop_me", function() rlang::interrupt(), interrupt_env)
  expect_identical(
    tryCatch(
      rel_from_sql(scan_con, "FROM stop_me", env = interrupt_env),
      interrupt = function(cnd) "interrupt",
      error = function(cnd) "error"
    ),
    "interrupt"
  )

  good_env <- new.env(parent = emptyenv())
  good_env$ok <- data.frame(a = 1L)
  expect_equal(
    as.data.frame(rel_from_sql(scan_con, "FROM ok", env = good_env)),
    data.frame(a = 1L),
    ignore_attr = TRUE
  )
  expect_error(
    rel_from_sql(scan_con, "FROM act", env = good_env),
    "Table with name act does not exist!",
    fixed = TRUE
  )
})

test_that("from sql: a query on another connection during the lookup pins nothing in the outer query", {
  drv <- duckdb(environment_scan = TRUE)
  c1 <- dbConnect(drv)
  c2 <- dbConnect(drv)
  withr::defer({
    dbDisconnect(c2)
    dbDisconnect(c1, shutdown = TRUE)
  })
  dbExecute(c1, "CREATE TEMP TABLE source AS SELECT 1::INTEGER AS a")
  seed <- rel_from_sql(c2, "SELECT 0 AS z")

  env <- new.env(parent = emptyenv())
  env$source <- data.frame(a = 99L)
  makeActiveBinding(
    "gate",
    function() {
      rel_sql(seed, "SELECT * FROM source")
      data.frame(k = 1L)
    },
    env
  )

  rel <- rel_from_sql(
    c1,
    "SELECT source.a FROM source CROSS JOIN gate",
    env = env
  )

  expect_identical(as.data.frame(rel)$a, 1L)
  expect_match(rel_to_sql(rel), "^WITH gate AS ")
})

# rel_from_table()

test_that("from table: a table that does not exist, a view, a missing schema", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  dbExecute(con, "CREATE VIEW oracle_from_table_view AS SELECT 1 AS a")

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_table(con, "oracle_no_such_table")
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_table(con, "oracle_from_table_view")
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_table(con, "oracle_from_table_view", "oracle_no_such_schema")
  })
})

# Printed tree and SQL text

test_that("printed tree and sql text: data frame source", {
  local_edition(3)
  rel <- rel_from_df(con, data.frame(a = 1:2, b = c("x", "y")))

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
})

test_that("printed tree and sql text: table", {
  local_edition(3)
  dbExecute(con, "CREATE TABLE oracle_print_tbl AS SELECT 1 AS a, 'x' AS b")
  rel <- rel_from_table(con, "oracle_print_tbl")

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
})

test_that("printed tree and sql text: table function with a named parameter", {
  local_edition(3)
  rel <- rel_from_table_function(
    con,
    "repeat_row",
    list("v", 2L),
    list(num_rows = 3L)
  )

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
})

test_that("printed tree and sql text: from sql", {
  local_edition(3)
  rel <- rel_from_sql(con, "SELECT 1 AS a")

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
})

test_that("printed tree and sql text: alias", {
  local_edition(3)
  rel <- oracle_lhs()

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
})

test_that("printed tree and sql text: projection", {
  local_edition(3)
  rel <- rel_project(
    rel_from_df(con, data.frame(a = 1:2, b = c("x", "y"))),
    list(
      expr_reference("a"),
      expr_function(
        "+",
        list(expr_reference("a"), expr_constant(1L)),
        alias = "a1"
      )
    )
  )

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
})

test_that("printed tree and sql text: filter", {
  local_edition(3)
  base <- rel_from_df(con, data.frame(a = 1:2, b = c("x", "y")))
  one <- rel_filter(base, list(gt("a", 1L)))
  two <- rel_filter(
    base,
    list(
      gt("a", 1L),
      expr_comparison("=", list(expr_reference("b"), expr_constant("y")))
    )
  )

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(one)
    show_rel(two)
  })
})

test_that("printed tree and sql text: aggregate with and without groups", {
  local_edition(3)
  base <- rel_from_df(con, data.frame(a = 1:2, b = c("x", "y")))
  grouped <- rel_aggregate(
    base,
    list(expr_reference("b")),
    list(n = expr_function("count", list()))
  )
  ungrouped <- rel_aggregate(
    base,
    list(),
    list(s = expr_function("sum", list(expr_reference("a"))))
  )

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(grouped)
    show_rel(ungrouped)
  })
})

test_that("printed tree and sql text: order", {
  local_edition(3)
  rel <- rel_order(
    rel_from_df(con, data.frame(a = 1:2, b = c("x", "y"))),
    list(expr_reference("a"), expr_reference("b")),
    ascending = c(FALSE, TRUE),
    nulls_first = c(TRUE, FALSE)
  )

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
})

test_that("printed tree and sql text: limit and distinct", {
  local_edition(3)
  base <- rel_from_df(con, data.frame(a = 1:2, b = c("x", "y")))
  limited <- rel_limit(base, 1)
  distinct <- rel_distinct(base)

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(limited)
    show_rel(distinct)
  })
})

test_that("printed tree and sql text: regular join of each join type", {
  local_edition(3)
  x <- oracle_lhs()
  y <- oracle_rhs()
  cond <- list(eq("a", "c"))
  joins <- lapply(
    c("inner", "left", "right", "outer", "semi", "anti"),
    function(type) rel_join(x, y, cond, type)
  )

  expect_snapshot(transform = normalize_rel_text, {
    for (rel in joins) show_rel(rel)
  })
})

test_that("printed tree and sql text: asof join", {
  local_edition(3)
  x <- oracle_lhs()
  y <- oracle_rhs()
  cond <- list(ge("a", "c"))
  inner <- rel_join(x, y, cond, "inner", "asof")
  left <- rel_join(x, y, cond, "left", "asof")

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(inner)
    show_rel(left)
  })
})

test_that("printed tree and sql text: cross join, with and without a condition", {
  local_edition(3)
  x <- oracle_lhs()
  y <- oracle_rhs()
  plain <- rel_join(x, y, list(), "cross")
  filtered <- rel_join(x, y, list(eq("a", "c")), "cross")

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(plain)
    show_rel(filtered)
  })
})

test_that("printed tree and sql text: a cross join with another ref type warns and is a cross product", {
  local_edition(3)
  x <- oracle_lhs()
  y <- oracle_rhs()

  expect_snapshot(transform = normalize_rel_text, {
    rel <- rel_join(x, y, list(), "cross", "natural")
    writeLines(rel_tostring(rel, "tree"))
  })
})

test_that("printed tree and sql text: positional join", {
  local_edition(3)
  x <- oracle_lhs()
  y <- oracle_rhs()
  cross <- rel_join(x, y, list(), "cross", "positional")
  inner <- rel_join(x, y, list(), "inner", "positional")
  left <- rel_join(x, y, list(eq("a", "c")), "left", "positional")

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(cross)
    show_rel(inner)
    show_rel(left)
  })
  expect_equal(
    as.data.frame(left),
    data.frame(a = 1:2, b = c("x", "y"), c = 1:2, d = c(2.5, 3.5)),
    ignore_attr = TRUE
  )
})

test_that("printed tree and sql text: natural is a regular join", {
  local_edition(3)
  x <- oracle_lhs()
  y <- oracle_rhs()
  rel <- rel_join(x, y, list(eq("a", "c")), "inner", "natural")

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(rel)
  })
  expect_equal(
    as.data.frame(rel),
    data.frame(a = 1:2, b = c("x", "y"), c = 1:2, d = c(2.5, 3.5)),
    ignore_attr = TRUE
  )
})

test_that("printed tree and sql text: set operations", {
  local_edition(3)
  x <- rel_from_df(con, data.frame(a = 1:2, b = c("x", "y")))
  y <- rel_from_df(con, data.frame(a = 2:3, b = c("y", "z")))
  union_all <- rel_union_all(x, y)
  intersect <- rel_set_intersect(x, y)
  except <- rel_set_diff(x, y)
  symdiff <- rel_set_symdiff(x, y)

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(union_all)
    show_rel(intersect)
    show_rel(except)
    show_rel(symdiff)
  })
})

test_that("sql text: over a join, a filter, a projection and an aggregate are written into the join's SELECT", {
  local_edition(3)
  join <- rel_join(oracle_lhs(), oracle_rhs(), list(eq("a", "c")))
  filtered <- rel_filter(join, list(gt("d", 3)))
  projected <- rel_project(join, list(expr_reference("a"), expr_reference("d")))
  aggregated <- rel_aggregate(
    join,
    list(expr_reference("b")),
    list(n = expr_function("count", list()))
  )

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(filtered)
    show_rel(projected)
    show_rel(aggregated)
  })
})

test_that("sql text: over a join, a projection over a filter or an order", {
  local_edition(3)
  join <- rel_join(oracle_lhs(), oracle_rhs(), list(eq("a", "c")))
  over_filter <- rel_project(
    rel_filter(join, list(gt("d", 3))),
    list(expr_reference("a"), expr_reference("d"))
  )
  over_order <- rel_project(
    rel_order(join, list(expr_reference("a"))),
    list(expr_reference("a"))
  )

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(over_filter)
    show_rel(over_order)
  })
  expect_equal(
    as.data.frame(over_filter),
    data.frame(a = 2L, d = 3.5),
    ignore_attr = TRUE
  )
})

test_that("printed tree and sql text: wrapped lazy data frame before and after materialization", {
  local_edition(3)
  df <- rel_to_altrep(rel_from_df(con, data.frame(a = 1:3)))
  wrapped <- rel_from_altrep_df(df, wrap = TRUE)
  pointers <- function(rel) {
    tree <- rel_tostring(rel, "tree")
    regmatches(tree, gregexpr("0x[0-9a-f]+", tree))[[1]]
  }

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(wrapped)
  })
  before <- pointers(wrapped)
  expect_length(before, 2)
  expect_false(before[[1]] == before[[2]])

  expect_equal(nrow(df), 3)
  wrapped_after <- rel_from_altrep_df(df, wrap = TRUE)

  expect_snapshot(transform = normalize_rel_text, {
    show_rel(wrapped_after)
  })
  after <- pointers(wrapped_after)
  expect_identical(after[[1]], after[[2]])
  expect_identical(after[[1]], before[[1]])
  expect_identical(pointers(wrapped), after)
  expect_equal(as.data.frame(wrapped), data.frame(a = 1:3), ignore_attr = TRUE)
})

# Aliases

test_that("alias: every node kind", {
  dbExecute(con, "CREATE TABLE oracle_alias_tbl AS SELECT 1 AS a")
  base <- rel_from_df(con, data.frame(a = 1:2, b = c("x", "y")))
  other <- rel_from_df(con, data.frame(a = 2:3, b = c("y", "z")))
  base_alias <- rel_alias(base)
  x <- oracle_lhs()
  y <- oracle_rhs()
  cond <- list(eq("a", "c"))
  count <- list(n = expr_function("count", list()))

  expect_match(base_alias, "^dataframe_[0-9]+_[0-9]+$")
  expect_identical(
    rel_alias(rel_from_table(con, "oracle_alias_tbl")),
    "oracle_alias_tbl"
  )
  expect_identical(
    rel_alias(rel_from_table_function(con, "generate_series", list(1L, 3L))),
    "generate_series"
  )
  expect_identical(
    rel_alias(rel_from_sql(con, "SELECT 1 AS a")),
    "queryrelation"
  )
  expect_identical(rel_alias(rel_set_alias(base, "foo")), "foo")
  expect_identical(
    rel_alias(rel_project(base, list(expr_reference("a")))),
    base_alias
  )
  expect_identical(rel_alias(rel_filter(base, list(gt("a", 1L)))), base_alias)
  expect_identical(rel_alias(rel_aggregate(base, list(), count)), base_alias)
  expect_identical(
    rel_alias(rel_order(base, list(expr_reference("a")))),
    base_alias
  )
  expect_identical(rel_alias(rel_limit(base, 1)), base_alias)
  expect_identical(rel_alias(rel_distinct(base)), base_alias)
  expect_identical(rel_alias(rel_union_all(base, other)), base_alias)
  expect_identical(rel_alias(rel_set_intersect(base, other)), base_alias)
  expect_identical(rel_alias(rel_set_diff(base, other)), base_alias)
  expect_identical(rel_alias(rel_set_symdiff(base, other)), base_alias)
  expect_match(rel_alias(rel_join(x, y, cond)), "^JOIN_RELATION_[0-9a-f]+$")
  expect_match(
    rel_alias(rel_join(x, y, list(ge("a", "c")), "inner", "asof")),
    "^JOIN_RELATION_[0-9a-f]+$"
  )
  expect_match(
    rel_alias(rel_join(x, y, list(), "cross")),
    "^CROSS_PRODUCT_RELATION_[0-9a-f]+$"
  )
  expect_match(
    rel_alias(rel_join(x, y, cond, "cross")),
    "^CROSS_PRODUCT_RELATION_[0-9a-f]+$"
  )
  expect_match(
    rel_alias(rel_join(x, y, list(), "cross", "positional")),
    "^CROSS_PRODUCT_RELATION_[0-9a-f]+$"
  )
  expect_match(
    rel_alias(rel_from_altrep_df(rel_to_altrep(base), wrap = TRUE)),
    "^EXTENSION_RELATION_[0-9a-f]+$"
  )
  expect_false(identical(
    rel_alias(rel_join(x, y, cond)),
    rel_alias(rel_join(x, y, cond))
  ))
})

test_that("alias: a reference qualified by a relation resolves through projection, filter and order", {
  local_edition(3)
  aliased <- rel_set_alias(
    rel_from_df(con, data.frame(a = 1:3, b = c("x", "y", "z"))),
    "foo"
  )
  projected <- rel_project(
    aliased,
    list(expr_reference("a"), expr_reference("b"))
  )
  filtered <- rel_filter(
    projected,
    list(expr_comparison(
      ">",
      list(expr_reference("a", projected), expr_constant(1L))
    ))
  )
  ordered <- rel_order(
    filtered,
    list(expr_reference("a", filtered)),
    ascending = FALSE
  )
  final <- rel_project(ordered, list(expr_reference("b", ordered)))

  expect_identical(rel_alias(final), "foo")
  expect_identical(expr_tostring(expr_reference("a", ordered)), "foo.a")
  expect_equal(
    as.data.frame(final),
    data.frame(b = c("z", "y")),
    ignore_attr = TRUE
  )
  expect_snapshot(transform = normalize_rel_text, {
    writeLines(rel_to_sql(final))
  })
})

# Writes

test_that("write: insert into an existing table and into a missing one", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  dbExecute(con, "CREATE TABLE oracle_insert (a INTEGER, b VARCHAR)")
  rel <- rel_from_df(con, data.frame(a = 1:2, b = c("x", "y")))

  rel_insert(rel, "main", "oracle_insert")
  rel_insert(rel, "", "oracle_insert")
  expect_equal(
    dbGetQuery(con, "FROM oracle_insert"),
    data.frame(a = c(1:2, 1:2), b = c("x", "y", "x", "y"))
  )

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_insert(rel, "main", "oracle_insert_missing")
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_insert(rel_from_df(con, data.frame(a = 1L)), "main", "oracle_insert")
  })
})

test_that("write: to table, temporary and not, and onto an existing table", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  rel <- rel_from_df(con, data.frame(a = 1:2, b = c("x", "y")))

  rel_to_table(rel, "", "oracle_to_table", FALSE)
  rel_to_table(rel, "", "oracle_to_table_temp", TRUE)
  expect_equal(
    dbGetQuery(con, "FROM oracle_to_table"),
    data.frame(a = 1:2, b = c("x", "y"))
  )
  expect_equal(
    dbGetQuery(con, "FROM oracle_to_table_temp"),
    data.frame(a = 1:2, b = c("x", "y"))
  )
  expect_equal(
    dbGetQuery(
      con,
      paste(
        "SELECT table_name, temporary FROM duckdb_tables()",
        "WHERE table_name LIKE 'oracle_to_table%' ORDER BY 1"
      )
    ),
    data.frame(
      table_name = c("oracle_to_table", "oracle_to_table_temp"),
      temporary = c(FALSE, TRUE)
    )
  )

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_to_table(rel, "", "oracle_to_table", FALSE)
  })
})

test_that("write: to view over a data frame, queried repeatedly", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  df <- data.frame(a = 1:2, b = c("x", "y"))
  rel <- rel_from_df(con, df)

  rel_to_view(rel, "", "oracle_to_view", FALSE)
  expect_equal(dbGetQuery(con, "FROM oracle_to_view"), df)
  expect_equal(dbGetQuery(con, "FROM oracle_to_view"), df)
  expect_equal(
    as.data.frame(rel_from_sql(con, "FROM oracle_to_view")),
    df,
    ignore_attr = TRUE
  )

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_to_view(rel, "", "oracle_to_view", FALSE)
  })
})

test_that("write: to csv and to parquet, and an unknown option", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  dir <- withr::local_tempdir()
  df <- data.frame(a = 1:2, b = c("x", "y"))
  rel <- rel_from_df(con, df)
  csv <- file.path(dir, "out.csv")
  parquet <- file.path(dir, "out.parquet")

  rel_to_csv(rel, csv)
  expect_identical(readLines(csv), c("a,b", "1,x", "2,y"))
  rel_to_parquet(rel, parquet)
  expect_equal(
    dbGetQuery(con, paste0("FROM ", dbQuoteString(con, parquet))),
    df
  )

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_to_csv(rel, file.path(dir, "bogus.csv"), list(bogus = 1L))
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_to_parquet(rel, file.path(dir, "bogus.parquet"), list(bogus = 1L))
  })
  expect_false(file.exists(file.path(dir, "bogus.csv")))
  expect_false(file.exists(file.path(dir, "bogus.parquet")))
})

test_that("write: explain of the standard type contains the scan", {
  rel <- rel_from_df(con, data.frame(a = 1:3))

  out <- capture.output(rel_explain(rel))
  expect_match(paste(out, collapse = "\n"), "R Dataframe Scan", fixed = TRUE)
})

# Expression arguments

test_that("an aggregate function with order_bys", {
  local_edition(3)
  rel <- rel_from_df(
    con,
    data.frame(g = c(1L, 1L, 2L), a = c(2L, 1L, 3L), b = c("x", "y", "z"))
  )
  agg <- rel_aggregate(
    rel,
    list(expr_reference("g")),
    list(
      s = expr_function(
        "string_agg",
        list(expr_reference("b"), expr_constant(",")),
        order_bys = list(expr_reference("a"))
      )
    )
  )

  expect_equal(
    as.data.frame(rel_order(agg, list(expr_reference("g")))),
    data.frame(g = 1:2, s = c("y,x", "z")),
    ignore_attr = TRUE
  )
  expect_snapshot(transform = normalize_rel_text, {
    show_rel(agg)
  })
})

test_that("a table function with named parameters", {
  rel <- rel_from_table_function(
    con,
    "repeat_row",
    list("v", 2L),
    list(num_rows = 3L)
  )

  expect_equal(
    as.data.frame(rel),
    data.frame(column0 = rep("v", 3), column1 = rep(2L, 3)),
    ignore_attr = TRUE
  )
})

# Lifetime

test_that("identity: rel_from_altrep_df() of rel_to_altrep() returns the same R object", {
  rel <- rel_from_df(con, data.frame(a = 1:3))
  df <- rel_to_altrep(rel)

  expect_identical(rel_from_altrep_df(df), rel)
})

test_that("identity: a child works after its parent and the data frame are collected", {
  make_child <- function() {
    df <- data.frame(a = 1:5, b = 5:1)
    parent <- rel_from_df(con, df)
    rel_filter(parent, list(gt("a", 2L)))
  }

  child <- make_child()
  gc()
  gc()

  expect_equal(
    as.data.frame(child),
    data.frame(a = 3:5, b = 3:1),
    ignore_attr = TRUE
  )
})

test_that("after disconnect: reading, building and lazy data frames", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  closed <- dbConnect(duckdb())
  rel <- rel_from_df(closed, data.frame(a = 1:3))
  lazy <- rel_to_altrep(rel)
  materialized <- rel_to_altrep(rel)
  expect_equal(nrow(materialized), 3)
  dbDisconnect(closed, shutdown = TRUE)

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    as.data.frame(rel)
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_filter(rel, list(gt("a", 1L)))
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_to_altrep(rel)
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    nrow(lazy)
  })
  expect_error(nrow(lazy), "Connection has already been closed", fixed = TRUE)

  expect_s3_class(rel_limit(rel, 1), "duckdb_relation")
  expect_identical(names(rel), "a")
  expect_match(rel_alias(rel), "^dataframe_[0-9]+_[0-9]+$")
  expect_match(
    rel_to_sql(rel),
    "^SELECT \\* FROM r_dataframe_scan\\(0x[0-9a-f]+\\)$"
  )
  expect_equal(materialized$a, 1:3)
})

test_that("after disconnect: a wrapped lazy data frame not rendered before refuses to render", {
  closed <- dbConnect(duckdb())
  df <- rel_to_altrep(rel_from_df(closed, data.frame(a = 1:3)))
  wrapped <- rel_from_altrep_df(df, wrap = TRUE)
  expect_equal(nrow(df), 3)
  dbDisconnect(closed, shutdown = TRUE)

  expect_error(
    rel_to_sql(wrapped),
    "Connection has already been closed",
    fixed = TRUE
  )
  expect_error(
    rel_tostring(wrapped, "tree"),
    "Connection has already been closed",
    fixed = TRUE
  )
})

# Query label

test_that("query label: reading a relation is logged as its tree rendered as SQL", {
  log_con <- local_con()
  rel <- rel_filter(
    rel_from_df(log_con, data.frame(a = 1:3)),
    list(gt("a", 1L))
  )
  from_sql <- rel_from_sql(log_con, "SELECT 42 AS answer")

  dbExecute(log_con, "CALL enable_logging('QueryLog')")
  as.data.frame(rel)
  nrow(rel_to_altrep(rel))
  as.data.frame(from_sql)
  dbExecute(log_con, "CALL disable_logging()")

  logged <- dbGetQuery(
    log_con,
    paste(
      "SELECT message FROM duckdb_logs()",
      "WHERE type = 'QueryLog' AND NOT starts_with(message, 'CALL')"
    )
  )$message
  expect_identical(
    logged,
    c(rel_to_sql(rel), rel_to_sql(rel), "SELECT 42 AS answer")
  )
})

# Where a step binds through ClientContext::BindStatement and runs as a statement, not as the unmodified
# package does: these tests fail on duckdb 2.0.0 as released

test_that("build error: from sql text that does not bind", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_from_sql(con, "SELECT zz FROM range(3)")
  })
})

test_that("from sql: a parameter binds to a column of unknown type and fails when read", {
  rel <- rel_from_sql(con, "SELECT $1")

  expect_identical(names(rel), "unknown")
  expect_error(as.data.frame(rel), "Not all parameters were bound", fixed = TRUE)
  expect_error(
    rel_to_altrep(rel),
    "Unknown type for column `unknown`",
    fixed = TRUE
  )
  expect_identical(
    names(rel_project(rel, list(expr_reference("zz")))),
    "unknown"
  )
  expect_identical(
    names(rel_from_table_function(con, "query", list("SELECT $1"))),
    "unknown"
  )
})

test_that("write: into a database attached read-only", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  path <- withr::local_tempfile(fileext = ".duckdb")
  setup <- dbConnect(duckdb(path))
  dbExecute(setup, "CREATE TABLE ro (a INTEGER)")
  dbDisconnect(setup, shutdown = TRUE)

  ro_con <- local_con()
  dbExecute(
    ro_con,
    paste0("ATTACH ", dbQuoteString(ro_con, path), " AS rodb (READ_ONLY)")
  )
  dbExecute(ro_con, "USE rodb")
  rel <- rel_from_df(ro_con, data.frame(a = 1L))

  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_insert(rel, "main", "ro")
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_to_table(rel, "main", "ro2", FALSE)
  })
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    rel_to_view(rel, "main", "rov", FALSE)
  })
})

test_that("explicit transaction: a step that fails to bind leaves it usable", {
  txn_con <- local_con()
  rel <- rel_from_df(txn_con, data.frame(a = 1:3))

  dbBegin(txn_con)
  expect_error(rel_filter(rel, list(expr_reference("zz"))), "zz")
  expect_equal(dbGetQuery(txn_con, "SELECT 1 AS x")$x, 1)
  dbRollback(txn_con)
})

test_that("explicit transaction: a commit after a failed step keeps what was done", {
  txn_con <- local_con()
  rel <- rel_from_df(txn_con, data.frame(a = 1:3))

  dbBegin(txn_con)
  dbExecute(txn_con, "CREATE TABLE created_in_txn (a INTEGER)")
  expect_error(rel_filter(rel, list(expr_reference("zz"))), "zz")
  expect_true(dbCommit(txn_con))
  expect_true(dbExistsTable(txn_con, "created_in_txn"))
})

test_that("aborted transaction: a step builds, and reading it fails until the rollback", {
  local_edition(3)
  withr::local_envvar(NO_COLOR = "true")
  txn_con <- local_con()
  rel <- rel_from_df(txn_con, data.frame(a = 1:3))

  dbBegin(txn_con)
  expect_error(dbGetQuery(txn_con, "SELECT * FROM oracle_no_such_table"))
  filtered <- rel_filter(rel, list(gt("a", 1L)))
  expect_s3_class(filtered, "duckdb_relation")
  expect_s3_class(rel_from_df(txn_con, data.frame(b = 1)), "duckdb_relation")
  expect_snapshot(error = TRUE, cnd_class = TRUE, {
    as.data.frame(filtered)
  })
  dbRollback(txn_con)
  expect_equal(as.data.frame(filtered), data.frame(a = 2:3), ignore_attr = TRUE)
})

test_that("aborted transaction: a write fails when it runs, with the prefix of the write", {
  txn_con <- local_con()
  dbExecute(txn_con, "CREATE TABLE oracle_txn_write (a INTEGER)")
  rel <- rel_from_df(txn_con, data.frame(a = 1L))

  dbBegin(txn_con)
  expect_error(dbGetQuery(txn_con, "SELECT * FROM oracle_no_such_table"))
  expect_error(
    rel_insert(rel, "main", "oracle_txn_write"),
    "Failed to insert into table 'oracle_txn_write': .*Current transaction is aborted"
  )
  dbRollback(txn_con)
})

test_that("a result mismatch leaves an explicit transaction usable", {
  txn_con <- local_con()
  dbExecute(txn_con, "CREATE TABLE oracle_mismatch_txn AS SELECT 1 AS a")
  rel <- rel_from_table(txn_con, "oracle_mismatch_txn")

  dbBegin(txn_con)
  dbExecute(txn_con, "ALTER TABLE oracle_mismatch_txn ADD COLUMN y INTEGER")
  expect_error(as.data.frame(rel), "Result mismatch in query!", fixed = TRUE)
  expect_equal(dbGetQuery(txn_con, "SELECT 1 AS x")$x, 1)
  dbRollback(txn_con)
})
