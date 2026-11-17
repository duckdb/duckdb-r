# Where an `I("schema.table")` name breaks on duckdb 2.0, why, and what each option changes.
# Handbook: experiments/2026-11-17-asis-table-names/README.md
# Loads the package from the checkout named by `DUCKDB_R_SRC`.

pkgload::load_all(Sys.getenv("DUCKDB_R_SRC"), quiet = TRUE)
library(DBI)
options(width = 120)

con <- dbConnect(duckdb())
dbExecute(con, "CREATE SCHEMA s")
dbExecute(con, "CREATE TABLE s.t AS SELECT 1 AS a")
parquet <- tempfile(fileext = ".parquet")
dbExecute(con, paste0("COPY s.t TO '", parquet, "'"))

# ---- 1. The stack from dplyr::tbl() ------------------------------------------
cnd <- rlang::catch_cnd(withCallingHandlers(
  dplyr::tbl(con, I("s.t")),
  error = rlang::entrace
))
conditionMessage(cnd)
print(cnd$trace, simplify = "none")

# The same failure, one call down, without dplyr or dbplyr.
try(dbExistsTable(con, I("s.t")))
try(dbQuoteIdentifier(con, I("s.t")))

# duckdb's method takes any `x`; `I()` keeps its class through the
# subassignment, and `SQL()` refuses a vector whose class is "AsIs".
x <- I("s.t")
x[TRUE] <- '"s.t"'
class(x)
try(SQL(x))

# ---- 2. What dbplyr itself hands to DBI ---------------------------------------
# Log the class of every name that reaches duckdb's DBI methods,
# and the innermost dplyr or dbplyr function that the call came through.
log_name <- function(generic) {
  bquote({
    fns <- lapply(seq_len(sys.nframe() - 1), sys.function)
    pkg <- vapply(fns, function(f) environmentName(topenv(environment(f))), "")
    calls <- sys.calls()[seq_along(fns)]
    via <- which(pkg %in% c("dbplyr", "dplyr"))
    via <- if (length(via)) deparse(calls[[max(via)]][[1]]) else "-"
    message(
      .(generic),
      "(): ",
      paste(class(name), collapse = "/"),
      ", via ",
      via
    )
  })
}
traced <- list(
  dbExistsTable = c("duckdb_connection", "ANY"),
  dbWriteTable = c("duckdb_connection", "character", "data.frame"),
  dbRemoveTable = c("duckdb_connection", "character"),
  dbListFields = c("duckdb_connection", "character")
)
for (g in names(traced)) {
  suppressMessages(trace(
    g,
    signature = traced[[g]],
    tracer = log_name(g),
    print = FALSE,
    where = asNamespace("DBI")
  ))
}

# dbplyr turns `I()` into a table path, and passes `SQL()` of it to DBI.
dbplyr::as_table_path(I("s.t"), con)
message("copy_to():")
copied <- dplyr::copy_to(con, data.frame(b = 2), I("s.c"), temporary = FALSE)
message("compute():")
computed <- dplyr::compute(copied, I("s.d"), temporary = FALSE)
# copy_to() builds its lazy table itself; compute() comes back through
# duckdb's tbl(), whose probe quotes the table path as one identifier, misses,
# and falls back to `FROM s.d` rather than the path dbplyr built.
dbplyr::remote_table(copied)
dbplyr::remote_table(computed)
# The only frame that hands the AsIs on is duckdb's own tbl() method.
try(dplyr::tbl(con, I("s.d")))

for (g in names(traced)) {
  suppressMessages(untrace(
    g,
    signature = traced[[g]],
    where = asNamespace("DBI")
  ))
}

# ---- 3. Every way to name s.t, and each option -------------------------------
specs <- list(
  `I("s.t")` = I("s.t"),
  `SQL("s.t")` = SQL("s.t"),
  `in_schema("s", "t")` = dbplyr::in_schema("s", "t"),
  `Id("s", "t")` = Id("s", "t"),
  `ident_q("s.t")` = suppressWarnings(dbplyr::ident_q("s.t")),
  `"s.t"` = "s.t",
  `sql("SELECT * FROM s.t")` = dbplyr::sql("SELECT * FROM s.t"),
  `parquet path` = parquet,
  `I(quoted parquet path)` = I(paste0("'", parquet, "'"))
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

grid <- function() {
  vapply(specs, function(x) outcome(dplyr::tbl(con, x)), character(1))
}

exists <- vapply(
  specs,
  function(x) outcome(dbExistsTable(con, x)),
  character(1)
)
as_is <- grid()

# (a) duckdb's tbl() probes only a bare string, the one form whose meaning it
# extends to replacement scans, and leaves every table identifier dbplyr knows,
# I(), in_schema(), Id(), ident_q() and sql() among them, to dbplyr unprobed.
tbl_option_a <- function(src, from, ..., cache = FALSE) {
  if (rlang::is_bare_character(from) && !DBI::dbExistsTable(src, from)) {
    from <- dbplyr::sql(paste0("FROM ", from))
  }
  if (cache) {
    DBI::dbExecute(src, "PRAGMA enable_object_cache")
  }
  NextMethod("tbl")
}
# (b) duckdb's tbl() probes what dbplyr would emit, as dbplyr's own
# db_table_drop_if_exists() does: SQL() of dbplyr::as_table_path().
tbl_option_b <- function(src, from, ..., cache = FALSE) {
  if (!inherits(from, "sql")) {
    probe <- if (rlang::is_bare_character(from)) {
      from
    } else {
      SQL(dbplyr::as_table_path(from, src))
    }
    if (!DBI::dbExistsTable(src, probe)) {
      from <- dbplyr::sql(paste0("FROM ", probe))
    }
  }
  if (cache) {
    DBI::dbExecute(src, "PRAGMA enable_object_cache")
  }
  NextMethod("tbl")
}

registerS3method(
  "tbl",
  "duckdb_connection",
  tbl_option_a,
  envir = asNamespace("dplyr")
)
option_a <- grid()
registerS3method(
  "tbl",
  "duckdb_connection",
  tbl_option_b,
  envir = asNamespace("dplyr")
)
option_b <- grid()
registerS3method(
  "tbl",
  "duckdb_connection",
  tbl.duckdb_connection,
  envir = asNamespace("dplyr")
)

# (c) #3003: duckdb's dbQuoteIdentifier() takes a character I() as SQL().
setMethod(
  "dbQuoteIdentifier",
  c("duckdb_connection", "AsIs"),
  function(conn, x, ...) SQL(unclass(x))
)
exists_c <- vapply(
  specs,
  function(x) outcome(dbExistsTable(con, x)),
  character(1)
)
option_c <- grid()
removeMethod("dbQuoteIdentifier", c("duckdb_connection", "AsIs"))

knitr::kable(
  row.names = FALSE,
  data.frame(
    name = paste0("`", names(specs), "`"),
    dbExistsTable = exists,
    tbl = as_is,
    check.names = FALSE
  )
)
knitr::kable(
  row.names = FALSE,
  data.frame(
    name = paste0("`", names(specs), "`"),
    `(a) tbl` = option_a,
    `(b) tbl` = option_b,
    `(c) dbExistsTable` = exists_c,
    `(c) tbl` = option_c,
    check.names = FALSE
  )
)

# ---- 4. What DBI and other backends do with I() -------------------------------
# DBI registers "AsIs" as an S4 class, for dbDataType(); it does not extend "character".
is(I("s.t"), "character")
is.character(I("s.t"))
# DBI's default quotes a character I() as one identifier, the opposite of SQL().
dbQuoteIdentifier(ANSI(), I("s.t"))

sqlite <- dbConnect(RSQLite::SQLite())
dbWriteTable(sqlite, "t", data.frame(a = 1))
dbQuoteIdentifier(sqlite, I("main.t"))
try(dbExistsTable(sqlite, I("main.t")))
dbExistsTable(sqlite, SQL("main.t"))
dbDisconnect(sqlite)

# Which method a character I() reaches, without a server.
suppressMessages({
  loadNamespace("RPostgres")
  loadNamespace("odbc")
})
backends <- c(
  duckdb = "duckdb_connection",
  RSQLite = "SQLiteConnection",
  RPostgres = "PqConnection",
  odbc = "OdbcConnection"
)
t(vapply(
  backends,
  function(cl) {
    vapply(
      c("dbQuoteIdentifier", "dbExistsTable"),
      function(g) {
        m <- selectMethod(g, c(cl, "AsIs"), optional = TRUE)
        if (is.null(m)) "no method" else paste(m@defined, collapse = ", ")
      },
      character(1)
    )
  },
  character(2)
))

dbDisconnect(con)
