## How dbExistsTable() behaves inside a transaction, and how each way of
## asking keeps or loses the cases it must answer.
## The package under test is named by the DUCKDB_PKG environment variable.
library(DBI)
pkg <- Sys.getenv("DUCKDB_PKG", "duckdb")
duckdb <- getExportedValue(pkg, "duckdb")
duckdb_register <- getExportedValue(pkg, "duckdb_register")
duckdb_read_csv <- getExportedValue(pkg, "duckdb_read_csv")
packageVersion(pkg)

con <- dbConnect(duckdb(shared_home = FALSE))
dbGetQuery(con, "SELECT version() AS engine")
dbGetQuery(
  con,
  "SELECT name, value FROM duckdb_settings() WHERE name LIKE '%invalidation%'"
)

first_line <- function(e) sub("\n.*", "", conditionMessage(e))
outcome <- function(code) {
  tryCatch(
    {
      code
      "ok"
    },
    error = first_line
  )
}
alive <- function(con) {
  tryCatch(
    {
      dbGetQuery(con, "SELECT 1")
      "ok"
    },
    error = function(e) "aborted"
  )
}

## The reported failures --------------------------------------------------------
dbBegin(con)
outcome(dbWriteTable(con, "x", data.frame(a = 1)))
alive(con)
dbRollback(con)

csv <- tempfile(fileext = ".csv")
write.csv(data.frame(a = 1:3), csv, row.names = FALSE)
outcome(duckdb_read_csv(con, "from_csv", csv))

outcome(dplyr::copy_to(con, data.frame(a = 1), "copied", temporary = FALSE))

## Ways of asking ------------------------------------------------------------
# The probe the package sends today (R/dbExistsTable__duckdb_connection_ANY.R).
probe <- function(conn, name) {
  tryCatch(
    {
      dbGetQuery(
        conn,
        sqlInterpolate(
          conn,
          "DESCRIBE SELECT * FROM ? WHERE FALSE",
          dbQuoteIdentifier(conn, name)
        )
      )
      TRUE
    },
    error = function(e) FALSE
  )
}

# 1. The probe, unchanged.
current <- probe

# 2. The probe, with the 1.x policy for this transaction only,
#    on an engine that has the policy, which is asked once.
knows_policy <- nrow(dbGetQuery(
  con,
  "SELECT 1 FROM duckdb_settings()
   WHERE name = 'default_transaction_invalidation_policy'"
)) >
  0
knows_policy
policy <- function(conn, name) {
  if (!knows_policy) {
    return(probe(conn, name))
  }
  dbExecute(
    conn,
    "SET current_transaction_invalidation_policy = 'SYNTACTIC_ERRORS_DO_NOT_INVALIDATE'"
  )
  on.exit(dbExecute(
    conn,
    "SET current_transaction_invalidation_policy = 'STANDARD_POLICY'"
  ))
  probe(conn, name)
}

# 3. The probe, on a second connection to the same instance.
second <- function(conn, name) {
  other <- dbConnect(conn@driver)
  on.exit(dbDisconnect(other))
  probe(other, name)
}

# 4. A lookup in the catalog, which raises nothing.
#    The search path is approximated by the temporary catalog,
#    the current schema, and the system catalog.
name_parts <- function(conn, name) {
  if (is(name, "SQL")) {
    name <- dbUnquoteIdentifier(conn, name)[[1]]
  }
  x <- if (is(name, "Id")) name@name else c(table = name)
  if (is.null(names(x)) || all(names(x) == "")) {
    names(x) <- tail(c("catalog", "schema", "table"), length(x))
  }
  part <- function(p) if (p %in% names(x)) x[[p]] else NA_character_
  list(part("table"), part("schema"), part("catalog"))
}
catalog <- function(conn, name) {
  dbGetQuery(
    conn,
    "WITH objects AS (
       SELECT database_name AS db, schema_name AS sch, table_name AS obj
       FROM duckdb_tables()
       UNION ALL
       SELECT database_name, schema_name, view_name FROM duckdb_views()
     )
     SELECT count(*) > 0 AS found FROM objects
     WHERE lower(obj) = lower($1)
       AND ($3 IS NULL OR lower(db) = lower($3))
       AND (
         $2 IS NULL AND (
           db IN ('temp', 'system') OR
           (db = current_database() AND sch = current_schema())
         ) OR
         lower(sch) = lower($2) OR
         ($3 IS NULL AND lower(db) = lower($2) AND sch = 'main')
       )",
    params = name_parts(conn, name)
  )$found
}

# 5. The catalog on this connection, then, for what it lacks,
#    the probe on a second connection, whose failure aborts nothing here.
hybrid <- function(conn, name) {
  catalog(conn, name) || second(conn, name)
}

# 6. Whatever the package under test sends.
package <- function(conn, name) dbExistsTable(conn, name)

candidates <- list(
  package = package,
  current = current,
  policy = policy,
  second = second,
  catalog = catalog,
  hybrid = hybrid
)

## The cases each must answer ------------------------------------------------------
parquet <- tempfile(fileext = ".parquet")
dbExecute(con, sprintf("COPY (SELECT 1 AS a) TO '%s'", parquet))
dbExecute(con, "CREATE TABLE t AS SELECT 1 AS a")
dbExecute(con, "CREATE TEMP TABLE tmp AS SELECT 1 AS a")
dbExecute(con, "CREATE VIEW v AS SELECT 1 AS a")
duckdb_register(con, "reg", data.frame(a = 1))
dbExecute(con, "CREATE SCHEMA s")
dbExecute(con, "CREATE TABLE s.st AS SELECT 1 AS a")
dbExecute(con, "ATTACH ':memory:' AS other")
dbExecute(con, "CREATE TABLE other.main.ot AS SELECT 1 AS a")
dbExecute(con, 'CREATE TABLE "a.b" AS SELECT 1 AS a')
dbExecute(con, "CREATE TABLE odd (x BIT, y INTEGER)")

cases <- list(
  "t" = list("t", TRUE),
  "T" = list("T", TRUE),
  "nope" = list("nope", FALSE),
  "temporary table" = list("tmp", TRUE),
  "view" = list("v", TRUE),
  "registered frame" = list("reg", TRUE),
  "created in this transaction" = list("in_tx", TRUE),
  "Id(table)" = list(Id(table = "t"), TRUE),
  "Id(schema, table)" = list(Id(schema = "s", table = "st"), TRUE),
  "Id(catalog, schema, table)" = list(
    Id(catalog = "other", schema = "main", table = "ot"),
    TRUE
  ),
  "Id(\"other\", \"ot\")" = list(Id("other", "ot"), TRUE),
  "SQL('\"s\".\"st\"')" = list(SQL('"s"."st"'), TRUE),
  "\"a.b\", one name" = list("a.b", TRUE),
  "\"s.st\", one name" = list("s.st", FALSE),
  "BIT column" = list("odd", TRUE),
  "information_schema.tables" = list(
    Id(schema = "information_schema", table = "tables"),
    TRUE
  ),
  "Parquet path" = list(parquet, TRUE),
  "missing Parquet path" = list("missing.parquet", FALSE)
)

# Each case in a transaction that has created `in_tx`;
# a case that aborts it is marked, and the next case gets a fresh one.
begin <- function(con) {
  dbBegin(con)
  dbExecute(con, "CREATE TABLE in_tx AS SELECT 1 AS a")
}
run_matrix <- function(con) {
  out <- lapply(candidates, function(f) {
    begin(con)
    on.exit(dbRollback(con))
    vapply(
      cases,
      function(case) {
        got <- tryCatch(f(con, case[[1]]), error = function(e) NA)
        state <- alive(con)
        if (state == "aborted") {
          dbRollback(con)
          begin(con)
        }
        paste0(
          if (identical(got, case[[2]])) "" else "WRONG ",
          got,
          if (state == "aborted") ", aborted"
        )
      },
      character(1)
    )
  })
  as.data.frame(out, check.names = FALSE)
}
run_matrix(con)

## An existing table, asked about in a transaction already aborted -----------------
dbBegin(con)
tryCatch(dbGetQuery(con, "SELECT 'x'::INTEGER"), error = first_line)
vapply(
  candidates,
  function(f) tryCatch(as.character(f(con, "t")), error = first_line),
  character(1)
)
dbRollback(con)

## The policy candidate leaves the transaction's own policy as it found it ---------
dbBegin(con)
policy(con, "nope")
tryCatch(dbGetQuery(con, "SELECT * FROM nope"), error = first_line)
alive(con)
dbRollback(con)

## The policy candidate under lock_configuration -----------------------------------
locked <- dbConnect(duckdb(
  shared_home = FALSE,
  config = list(lock_configuration = "true")
))
dbExecute(locked, "CREATE TABLE t AS SELECT 1 AS a")
dbBegin(locked)
tryCatch(policy(locked, "t"), error = first_line)
alive(locked)
dbRollback(locked)
# The package under test, for a table that exists and one that does not.
dbBegin(locked)
dbExistsTable(locked, "t")
alive(locked)
dbExistsTable(locked, "nope")
alive(locked)
dbRollback(locked)
# The engine's own multi-statement handling sets the same option.
dbBegin(locked)
tryCatch(dbGetQuery(locked, "SELECT 1; SELECT 2"), error = first_line)
alive(locked)
dbRollback(locked)
dbDisconnect(locked)

## The instance created with the 1.x policy ----------------------------------------
lenient <- tryCatch(
  dbConnect(duckdb(
    shared_home = FALSE,
    config = list(
      default_transaction_invalidation_policy = "SYNTACTIC_ERRORS_DO_NOT_INVALIDATE"
    )
  )),
  error = first_line
)
if (is(lenient, "DBIConnection")) {
  dbBegin(lenient)
  dbWriteTable(lenient, "x", data.frame(a = 1))
  print(alive(lenient))
  # The user's own misspelt query no longer aborts the transaction.
  print(tryCatch(
    dbGetQuery(lenient, "SELECT * FROM nope"),
    error = first_line
  ))
  print(alive(lenient))
  dbRollback(lenient)
  dbDisconnect(lenient)
} else {
  lenient
}

## What each costs, in milliseconds per call -------------------------------------
# Inside a transaction, a timing that aborted it is NA:
# every call after the first would have failed fast.
per_call <- function(f, name, in_tx, n = 200) {
  if (in_tx) {
    begin(con)
    on.exit(dbRollback(con))
  }
  ms <- system.time(
    for (i in seq_len(n)) {
      f(con, name)
    }
  )[["elapsed"]] /
    n *
    1000
  if (alive(con) == "ok") ms else NA
}
timings <- function(in_tx) {
  t(vapply(
    candidates,
    function(f) {
      c(found = per_call(f, "t", in_tx), missing = per_call(f, "nope", in_tx))
    },
    numeric(2)
  ))
}
round(timings(in_tx = FALSE), 2)
round(timings(in_tx = TRUE), 2)

dbDisconnect(con)
