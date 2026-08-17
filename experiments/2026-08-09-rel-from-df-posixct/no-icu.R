# The branch the fast path cannot reach: a build with no icu in it.
#
# Answers what neither grid could, because a fast-path build links icu
# statically and its absence cannot be produced there:
#   1. what the session zone reads when the setting does not exist
#   2. whether `duckdb_extensions()` is safe to ask (the pin's guard)
#   3. whether `SET TimeZone` reaches for icu, and what that costs
#   4. whether the default write/read round trip still follows the machine
#
# Run against a source build installed in its own library; run.sh in the
# no-icu worktree supplies TZ.
suppressMessages(library(duckdb))

TZ <- Sys.getenv("TZ")
INSTANT <- as.POSIXct(1745781814.84963, origin = "1970-01-01", tz = "UTC")

say <- function(...) cat(sprintf(...), "\n", sep = "")

# An empty extension directory is a machine that has never downloaded icu,
# whatever this one's ~/.duckdb holds.
empty_store <- tempfile("ext-store-")
dir.create(empty_store)

fresh <- function(...) {
  suppressMessages(dbConnect(
    duckdb(config = list(extension_directory = empty_store)),
    ...
  ))
}

say(
  "== TZ=%s, duckdb %s, DuckDB %s ==",
  TZ,
  packageVersion("duckdb"),
  duckdb:::get_duckdb_version()
)

con <- fresh()

# 2. Is duckdb_extensions() safe to ask? Nothing should be loaded by asking.
ext <- dbGetQuery(
  con,
  "SELECT extension_name, loaded, installed, install_mode
     FROM duckdb_extensions() WHERE extension_name = 'icu'"
)
say(
  "icu row: loaded=%s installed=%s install_mode=%s",
  ext$loaded,
  ext$installed,
  ext$install_mode
)

# 1. What does the session zone read with no icu?
say(
  "session zone: %s",
  dbGetQuery(con, "SELECT current_setting('TimeZone') AS tz")$tz
)

# 4. Does the default round trip still follow the machine?
df <- data.frame(a = INSTANT)
dbWriteTable(con, "t", df)
back <- dbReadTable(con, "t")$a
say(
  "dbWriteTable type: %s",
  dbGetQuery(con, "DESCRIBE t")$column_type
)
say(
  "round trip: label %s, instant %s",
  attr(back, "tzone"),
  if (isTRUE(all.equal(as.numeric(back), as.numeric(INSTANT)))) {
    "preserved"
  } else {
    "MOVED"
  }
)

# 3. What does asking for the setting cost? Time it: a network reach shows up.
elapsed <- system.time(
  err <- tryCatch(dbExecute(con, "SET TimeZone = 'UTC'"), error = function(e) e)
)[["elapsed"]]
say(
  "SET TimeZone = 'UTC': %s (%.2fs)",
  if (inherits(err, "error")) {
    paste0("error: ", sub("\n.*", "", conditionMessage(err)))
  } else {
    "ok"
  },
  elapsed
)
say(
  "session zone after: %s",
  dbGetQuery(con, "SELECT current_setting('TimeZone') AS tz")$tz
)

dbDisconnect(con, shutdown = TRUE)

# The same question on a machine that has downloaded icu before: the default
# store. If `SET TimeZone` autoloads from there, a connect-time pin would
# silently load an extension for everyone who has one cached, which is what
# the guard exists to avoid.
say("-- default extension store (icu may be cached) --")
con2 <- suppressMessages(dbConnect(duckdb()))
say(
  "icu before: loaded=%s",
  dbGetQuery(
    con2,
    "SELECT loaded FROM duckdb_extensions() WHERE extension_name = 'icu'"
  )$loaded
)
elapsed2 <- system.time(
  err2 <- tryCatch(
    dbExecute(con2, "SET TimeZone = 'UTC'"),
    error = function(e) e
  )
)[["elapsed"]]
say(
  "SET TimeZone = 'UTC': %s (%.2fs)",
  if (inherits(err2, "error")) {
    paste0("error: ", sub("\n.*", "", conditionMessage(err2)))
  } else {
    "ok"
  },
  elapsed2
)
say(
  "icu after: loaded=%s",
  dbGetQuery(
    con2,
    "SELECT loaded FROM duckdb_extensions() WHERE extension_name = 'icu'"
  )$loaded
)
dbDisconnect(con2, shutdown = TRUE)
