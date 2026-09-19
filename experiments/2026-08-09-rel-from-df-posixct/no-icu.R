# The branch the fast path cannot reach: a build with no icu in it.
#
# Answers what neither grid could, because a fast-path build links icu
# statically and its absence cannot be produced there:
#   1. which ways of asking about the session zone are safe without icu
#   2. what the zone reads when the setting does not exist
#   3. whether the default write/read round trip still follows the machine
#   4. what `SET TimeZone` costs when it has to reach for the extension
#
# Needs the vendored engine compiled from source -- it links `parquet` and
# `core_functions` and nothing else -- installed in its own library:
#
#   git worktree add --detach ../duckdb-r-noicu HEAD
#   (cd ../duckdb-r-noicu && MAKEFLAGS=-j4 NOT_CRAN=true \
#      R CMD INSTALL . --library=$HOME/R-noicu --no-byte-compile)
#   R_LIBS=$HOME/R-noicu TZ=UTC Rscript experiments/.../no-icu.R
suppressMessages(library(duckdb))

INSTANT <- as.POSIXct(1745781814.84963, origin = "1970-01-01", tz = "UTC")

say <- function(...) cat(sprintf(...), "\n", sep = "")

# `try_sql()` reports what a statement did rather than letting it stop the
# script: on this build some of them raise an autoloading error, which is
# itself one of the answers.
try_sql <- function(con, sql, exec = FALSE) {
  t <- system.time(
    out <- tryCatch(
      if (exec) dbExecute(con, sql) else dbGetQuery(con, sql),
      error = function(e) e
    )
  )[["elapsed"]]
  if (inherits(out, "error")) {
    sprintf("%s (%.2fs)", sub("\n.*", "", conditionMessage(out)), t)
  } else if (exec) {
    sprintf("ok (%.2fs)", t)
  } else {
    sprintf("%s (%.2fs)", as.character(out[[1]]), t)
  }
}

report <- function(label, con) {
  say("-- %s --", label)

  # 1. duckdb_extensions() is a catalog function, not a setting lookup.
  ext <- dbGetQuery(
    con,
    "SELECT loaded, installed, install_mode
       FROM duckdb_extensions() WHERE extension_name = 'icu'"
  )
  say(
    "duckdb_extensions(): loaded=%s installed=%s install_mode=%s",
    ext$loaded,
    ext$installed,
    ext$install_mode
  )

  # 2. The label on a TIMESTAMPTZ column is the session zone as the glue sees
  # it, through GetClientProperties(); asking in SQL is the other way, and the
  # two do not agree, because asking in SQL can load the extension that
  # supplies the setting.
  label <- function() {
    attr(
      dbGetQuery(con, "SELECT TIMESTAMPTZ '2024-01-10 13:03:12-08:00' AS a")$a,
      "tzone"
    )
  }
  say("tzone label before anything asks for the setting: %s", label())
  say(
    "current_setting('TimeZone'): %s",
    try_sql(con, "SELECT current_setting('TimeZone')")
  )
  say("tzone label after: %s", label())

  # 3. Does the default round trip still follow the machine?
  df <- data.frame(a = INSTANT)
  dbWriteTable(con, "t", df, overwrite = TRUE)
  back <- dbReadTable(con, "t")$a
  say("dbWriteTable type: %s", dbGetQuery(con, "DESCRIBE t")$column_type)
  say(
    "round trip: label %s, instant %s",
    attr(back, "tzone"),
    if (isTRUE(all.equal(as.numeric(back), as.numeric(INSTANT)))) {
      "preserved"
    } else {
      "MOVED"
    }
  )

  # 4. What a connect-time pin would be issuing.
  say(
    "SET TimeZone = 'UTC': %s",
    try_sql(con, "SET TimeZone = 'UTC'", exec = TRUE)
  )
  say(
    "icu loaded after: %s",
    dbGetQuery(
      con,
      "SELECT loaded FROM duckdb_extensions() WHERE extension_name = 'icu'"
    )$loaded
  )
}

say(
  "== TZ=%s, duckdb %s, DuckDB %s, source build ==",
  Sys.getenv("TZ"),
  packageVersion("duckdb"),
  duckdb:::get_duckdb_version()
)

# A machine that has never downloaded icu, whatever this one's store holds.
empty_store <- tempfile("ext-store-")
dir.create(empty_store)
con <- suppressMessages(dbConnect(
  duckdb(config = list(extension_directory = empty_store))
))
report("empty extension store", con)
dbDisconnect(con, shutdown = TRUE)

# And a machine that has: the default store, where icu may be cached. If
# asking loads it, a connect-time pin would load an extension for everyone
# who has one, which is what a guard would exist to avoid.
con2 <- suppressMessages(dbConnect(duckdb()))
report("default extension store", con2)
dbDisconnect(con2, shutdown = TRUE)
