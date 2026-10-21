# Where a value does not survive the crossing: what changes, what collides
# with NA, and what fails, one case per row.
# The recorded run is edges.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
options(width = 250)
options(duckdb.home = "~/.duckdb")

con <- dbConnect(duckdb())
con64 <- dbConnect(duckdb(), bigint = "integer64", array = "matrix")

# The result, or the first line of the error, with a warning noted.
cell <- function(expr) {
  warned <- NULL
  out <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warned <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) paste("ERROR:", gsub("\n.*", "", conditionMessage(e)))
  )
  if (!is.null(warned)) {
    out <- paste0(out, " (warns: ", warned, ")")
  }
  out
}

# Values as R holds them, at full precision.
show <- function(x) {
  if (is.data.frame(x)) {
    return(paste(vapply(x, show, ""), collapse = " | "))
  }
  if (is.list(x)) {
    return(paste(vapply(x, function(e) deparse(e)[1], ""), collapse = ", "))
  }
  v <- if (inherits(x, "integer64")) {
    as.character(x)
  } else if (is.double(x) && !inherits(x, c("Date", "POSIXct", "difftime"))) {
    format(unclass(x), digits = 17)
  } else {
    format(x)
  }
  paste(v, collapse = ", ")
}
fetch <- function(cn, sql, ...) show(dbGetQuery(cn, sql, ...)[[1]])
text <- function(cn, table) {
  paste(
    dbGetQuery(
      cn,
      paste("SELECT typeof(x) || ' ' || x::VARCHAR AS v FROM", table)
    )$v,
    collapse = ", "
  )
}
frame <- function(x) {
  d <- data.frame(id = seq_len(NROW(x)))
  d$x <- x
  d
}

# --- Out: DuckDB to R ---------------------------------------------------

out <- list(
  "INTEGER minimum" = fetch(con, "SELECT (-2147483648)::INTEGER"),
  "BIGINT 2^53 + 1, default" = fetch(con, "SELECT 9007199254740993::BIGINT"),
  "BIGINT 2^53 + 1, integer64" = fetch(
    con64,
    "SELECT 9007199254740993::BIGINT"
  ),
  "BIGINT minimum, integer64" = fetch(
    con64,
    "SELECT (-9223372036854775808)::BIGINT"
  ),
  "UBIGINT maximum, default" = fetch(
    con,
    "SELECT 18446744073709551615::UBIGINT"
  ),
  "UBIGINT maximum, integer64" = fetch(
    con64,
    "SELECT 18446744073709551615::UBIGINT"
  ),
  "HUGEINT maximum" = fetch(
    con,
    "SELECT 170141183460469231731687303715884105727::HUGEINT"
  ),
  "HUGEINT as text" = fetch(
    con,
    "SELECT 170141183460469231731687303715884105727::HUGEINT::VARCHAR"
  ),
  "DECIMAL(38,10), 38 digits" = fetch(
    con,
    "SELECT 1234567890123456789012345678.0123456789::DECIMAL(38,10)"
  ),
  "DOUBLE NaN and NULL" = fetch(con, "SELECT unnest(['NaN'::DOUBLE, NULL])"),
  "DATE infinity" = fetch(con, "SELECT 'infinity'::DATE"),
  "TIMESTAMP infinity" = fetch(con, "SELECT 'infinity'::TIMESTAMP"),
  "TIMESTAMP_NS, first query" = cell(fetch(
    con,
    "SELECT TIMESTAMP_NS '2024-01-10 13:03:12.123456789'"
  )),
  "TIMESTAMP_NS, second query" = cell(fetch(
    con,
    "SELECT TIMESTAMP_NS '2024-01-10 13:03:12.123456789'"
  )),
  "TIMETZ with an offset" = fetch(con, "SELECT TIMETZ '13:03:12+05:30'"),
  "INTERVAL one month" = fetch(con, "SELECT INTERVAL '1 month'"),
  "INTERVAL one day" = fetch(con, "SELECT INTERVAL '1 day'"),
  "STRUCT NULL vs. NULL fields" = fetch(
    con,
    "SELECT unnest([NULL, {'i': NULL}]::STRUCT(i INTEGER)[])"
  ),
  "ARRAY NULL vs. NULL elements" = fetch(
    con64,
    "SELECT unnest([NULL, [NULL, NULL]]::INTEGER[2][])"
  ),
  "LIST NULL vs. NULL element" = fetch(
    con,
    "SELECT unnest([NULL, [NULL]]::INTEGER[][])"
  ),
  "ENUM levels" = paste(
    levels(dbGetQuery(con, "SELECT 'ok'::ENUM('sad', 'ok', 'happy')")[[1]]),
    collapse = ","
  ),
  "VARIANT holding a BIT" = cell(fetch(con, "SELECT '101'::BIT::VARIANT")),
  "BIT as text" = fetch(con, "SELECT '101'::BIT::VARCHAR"),
  "BIGNUM as text" = fetch(con, "SELECT (2::BIGNUM ^ 200)::BIGNUM::VARCHAR"),
  "TIME_NS as TIME" = fetch(con, "SELECT '13:03:12.123456789'::TIME_NS::TIME"),
  "UNION tag and member" = fetch(
    con,
    "SELECT union_tag(u) || ': ' || union_extract(u, 'num')
       FROM (SELECT union_value(num := 2)::UNION(num INTEGER, str VARCHAR) AS u)"
  )
)
print(
  data.frame(case = names(out), result = unlist(out)),
  right = FALSE,
  row.names = FALSE
)

# --- In: R to DuckDB ----------------------------------------------------

i64 <- bit64::as.integer64(c("42", NA))
into <- list(
  "integer64, bigint = numeric" = cell({
    dbWriteTable(con, "i", frame(i64), overwrite = TRUE)
    text(con, "i")
  }),
  "integer64, bigint = integer64" = cell({
    dbWriteTable(con64, "i", frame(i64), overwrite = TRUE)
    text(con64, "i")
  }),
  "integer64 bound, bigint = integer64" = cell(fetch(
    con64,
    "SELECT ?::BIGINT",
    params = list(i64[1])
  )),
  "Date stored as integer, with NA" = cell({
    dbWriteTable(
      con,
      "d",
      frame(structure(c(19732L, NA), class = "Date")),
      overwrite = TRUE
    )
    text(con, "d")
  }),
  "difftime stored as integer, with NA" = cell({
    dbWriteTable(
      con,
      "d",
      frame(structure(c(5L, NA), class = "difftime", units = "mins")),
      overwrite = TRUE
    )
    text(con, "d")
  }),
  "difftime in minutes" = cell({
    dbWriteTable(
      con,
      "d",
      frame(as.difftime(90, units = "mins")),
      overwrite = TRUE
    )
    paste(text(con, "d"), "->", show(dbReadTable(con, "d")$x))
  }),
  "hms" = cell({
    dbWriteTable(con, "d", frame(hms::as_hms("13:03:12")), overwrite = TRUE)
    text(con, "d")
  }),
  "dbDataType() of difftime" = dbDataType(con, as.difftime(1, units = "secs")),
  "difftime into dbCreateTable()'s table" = cell({
    d <- frame(as.difftime(1, units = "secs"))
    dbCreateTable(con, "c", d)
    dbAppendTable(con, "c", d)
  }),
  "POSIXct in New York" = cell({
    x <- as.POSIXct("2024-01-10 13:03:12", tz = "America/New_York")
    dbWriteTable(con, "p", frame(x), overwrite = TRUE)
    text(con, "p")
  }),
  "POSIXct, field.types TIMESTAMPTZ" = cell({
    x <- as.POSIXct("2024-01-10 13:03:12", tz = "America/New_York")
    dbWriteTable(
      con,
      "p",
      frame(x),
      overwrite = TRUE,
      field.types = c(x = "TIMESTAMPTZ")
    )
    text(con, "p")
  }),
  "factor" = cell({
    dbWriteTable(
      con,
      "f",
      frame(factor("ok", levels = c("sad", "ok"))),
      overwrite = TRUE
    )
    text(con, "f")
  }),
  "ordered factor, read back" = cell({
    dbWriteTable(
      con,
      "f",
      frame(factor("ok", levels = c("sad", "ok"), ordered = TRUE)),
      overwrite = TRUE
    )
    paste(class(dbReadTable(con, "f")$x), collapse = "/")
  }),
  "factor bound" = cell(fetch(
    con,
    "SELECT typeof(?)",
    params = list(factor("ok"))
  )),
  "character UUID" = cell({
    dbWriteTable(
      con,
      "u",
      frame("4ac7a9e9-607c-4c8a-84f3-843f0191e3fd"),
      overwrite = TRUE
    )
    text(con, "u")
  }),
  "blob::blob" = cell({
    dbWriteTable(
      con,
      "b",
      frame(blob::as_blob(as.raw(c(0xAA, 0xBB)))),
      overwrite = TRUE
    )
    text(con, "b")
  }),
  "raw vector" = cell({
    dbWriteTable(con, "b", frame(as.raw(c(0xAA, 0xBB))), overwrite = TRUE)
    text(con, "b")
  }),
  "complex" = cell({
    dbWriteTable(con, "z", frame(1i), overwrite = TRUE)
    text(con, "z")
  }),
  "double NaN" = cell({
    dbWriteTable(con, "n", frame(c(NaN, NA)), overwrite = TRUE)
    text(con, "n")
  }),
  "matrix bound" = cell(fetch(
    con,
    "SELECT ?::INTEGER[2]",
    params = list(matrix(1:2, nrow = 1))
  )),
  "data frame column, two fields" = cell({
    dbWriteTable(con, "s", frame(data.frame(i = 1L, j = "a")), overwrite = TRUE)
    text(con, "s")
  }),
  # In a subprocess, because a build that reads past the data frame crashes.
  "data frame bound as STRUCT" = cell({
    r <- callr::r(
      function() {
        con <- DBI::dbConnect(duckdb::duckdb())
        DBI::dbGetQuery(
          con,
          "SELECT (?::STRUCT(i INTEGER, j VARCHAR))::VARCHAR AS v",
          params = list(data.frame(i = 1L, j = "a"))
        )$v
      },
      error = "error"
    )
    r
  }),
  "VARIANT from a scalar column" = cell({
    dbWriteTable(
      con,
      "v",
      frame(42L),
      overwrite = TRUE,
      field.types = c(x = "VARIANT")
    )
    fetch(con, "SELECT variant_typeof(x) || ' ' || x::VARCHAR FROM v")
  }),
  "UNION from its member's type" = cell({
    dbWriteTable(
      con,
      "u",
      frame(2L),
      overwrite = TRUE,
      field.types = c(x = "UNION(num INTEGER, str VARCHAR)")
    )
    fetch(con, "SELECT union_tag(x) || ': ' || x::VARCHAR FROM u")
  }),
  "UNION from text" = cell({
    dbWriteTable(
      con,
      "u",
      frame("2"),
      overwrite = TRUE,
      field.types = c(x = "UNION(num INTEGER, str VARCHAR)")
    )
    fetch(con, "SELECT union_tag(x) || ': ' || x::VARCHAR FROM u")
  })
)
print(
  data.frame(case = names(into), result = unlist(into)),
  right = FALSE,
  row.names = FALSE
)

# --- Tables and results holding a type R cannot hold -----------------

invisible(dbExecute(con, "CREATE TABLE b (x BIT, y INTEGER)"))
held <- list(
  "dbExistsTable()" = cell(dbExistsTable(con, "b")),
  "dbListFields()" = cell(paste(dbListFields(con, "b"), collapse = ", ")),
  "dbGetQuery()" = cell(fetch(con, "SELECT x FROM b")),
  "dbGetQueryArrow()" = cell({
    s <- nanoarrow::as_nanoarrow_array_stream(dbGetQueryArrow(
      con,
      "SELECT x FROM b"
    ))
    s$get_schema()$children$x$format
  })
)
print(
  data.frame(case = names(held), result = unlist(held)),
  right = FALSE,
  row.names = FALSE
)

dbDisconnect(con, shutdown = TRUE)
dbDisconnect(con64, shutdown = TRUE)
