# Every DuckDB type out through Arrow: the Arrow type the engine exports it
# as, under each setting that changes that, and what nanoarrow and arrow make
# of it in R. Then values chosen to show where precision is lost.
# The recorded run is out.md, rendered with reprex::reprex(si = TRUE).
library(duckdb)
options(width = 250, digits = 17, digits.secs = 6)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

# The types, with a value of each: types.R.
source("types.R")

con <- dbConnect(duckdb())
for (e in c(unique(types$ext[types$ext != ""]), "icu")) {
  invisible(dbExecute(con, paste("INSTALL", e)))
  invisible(dbExecute(con, paste("LOAD", e)))
}

# The result, or the first line of the error, cut to fit a column.
cell <- function(expr, width = 60) {
  out <- tryCatch(
    expr,
    error = function(e) paste("ERROR:", gsub("\n.*", "", conditionMessage(e)))
  )
  if (nchar(out) > width) paste0(substr(out, 1, width - 3), "...") else out
}

# One column, one row, as a stream.
one <- function(lit) dbGetQueryArrow(con, paste("SELECT", lit, "AS x"))

# The Arrow type of a field as nanoarrow spells it, with the extension it
# carries, and for arrow.opaque the DuckDB type it stands for.
arrow_type <- function(sch) {
  out <- sub("^<nanoarrow_schema (.*)>$", "\\1", format(sch))
  ext <- sch$metadata[["ARROW:extension:name"]]
  if (!is.null(ext)) {
    if (ext == "arrow.opaque") {
      meta <- jsonlite::fromJSON(sch$metadata[["ARROW:extension:metadata"]])
      ext <- paste0(ext, "<", meta$type_name, ">")
    }
    out <- paste0(ext, "<", out, ">")
  }
  out
}

# An R value in one line: its class, then its first element.
r_value <- function(x) {
  first <- function(v) {
    if (is.data.frame(v)) {
      inner <- vapply(v, first, character(1))
      return(paste0(
        "{",
        paste(names(v), inner, sep = "=", collapse = ", "),
        "}"
      ))
    }
    if (is.list(v) && !inherits(v, "blob")) {
      e <- v[[1]]
      return(paste0("[", paste(format(e), collapse = " "), "]"))
    }
    format(v[1])
  }
  cls <- class(x)[1]
  if (is.list(x) && !is.data.frame(x) && !inherits(x, "blob")) {
    cls <- paste0(cls, "<", class(x[[1]])[1], ">")
  }
  paste0(cls, " ", first(x))
}

# The field's Arrow type, then R through each reader.
exported <- function(lit) {
  s <- one(lit)
  on.exit(s$release())
  arrow_type(s$get_schema()$children$x)
}
via_nanoarrow <- function(lit) r_value(as.data.frame(one(lit))$x)
via_arrow <- function(lit) {
  r_value(as.data.frame(arrow::as_arrow_table(one(lit)))$x)
}

each <- function(f, lits = types$lit) {
  vapply(lits, function(lit) cell(f(lit)), character(1), USE.NAMES = FALSE)
}

# --- Before geoarrow is loaded -----------------------------------------

# geoarrow registers geoarrow.wkb with both readers when its namespace loads;
# until then, both read the storage.
geometry <- "'POINT (1 2)'::GEOMETRY"
c(
  nanoarrow = cell(via_nanoarrow(geometry)),
  arrow = cell(via_arrow(geometry)),
  geoarrow_loaded = "geoarrow" %in% loadedNamespaces()
)
library(geoarrow)

# arrow converts an int64 column to integer when every value fits, and to
# integer64 otherwise; the option makes it integer64 always.
local({
  withr::local_options(arrow.int64_downcast = FALSE)
  c(
    small = cell(via_arrow("42::BIGINT")),
    large = cell(via_arrow("9007199254740993::BIGINT"))
  )
})

# --- The Arrow type of each DuckDB type ------------------------------

default <- each(exported)
invisible(dbExecute(con, "SET arrow_lossless_conversion = true"))
lossless <- each(exported)
invisible(dbExecute(con, "RESET arrow_lossless_conversion"))

print(
  data.frame(type = types$type, default = default, lossless = lossless),
  right = FALSE,
  row.names = FALSE
)

# --- What R receives, with the default export ------------------------

print(
  data.frame(
    type = types$type,
    nanoarrow = each(via_nanoarrow),
    arrow = each(via_arrow)
  ),
  right = FALSE,
  row.names = FALSE
)

# --- What R receives where arrow_lossless_conversion changes the type -

changed <- default != lossless
invisible(dbExecute(con, "SET arrow_lossless_conversion = true"))
print(
  data.frame(
    type = types$type[changed],
    nanoarrow = each(via_nanoarrow, types$lit[changed]),
    arrow = each(via_arrow, types$lit[changed])
  ),
  right = FALSE,
  row.names = FALSE
)
invisible(dbExecute(con, "RESET arrow_lossless_conversion"))

# --- The other settings: which types they change, and to what --------

# The view layouts need arrow_output_version 1.4 or later: set alone, the two
# switches for them change nothing.
settings <- list(
  "arrow_large_buffer_size" = "SET arrow_large_buffer_size = true",
  "produce_arrow_string_view alone" = "SET produce_arrow_string_view = true",
  "arrow_output_list_view alone" = "SET arrow_output_list_view = true",
  "arrow_output_version 1.4" = "SET arrow_output_version = '1.4'",
  "1.4, produce_arrow_string_view" = c(
    "SET arrow_output_version = '1.4'",
    "SET produce_arrow_string_view = true"
  ),
  "1.4, arrow_output_list_view" = c(
    "SET arrow_output_version = '1.4'",
    "SET arrow_output_list_view = true"
  ),
  "arrow_output_version 1.5" = "SET arrow_output_version = '1.5'"
)
reset <- function() {
  for (name in c(
    "arrow_large_buffer_size",
    "produce_arrow_string_view",
    "arrow_output_list_view",
    "arrow_output_version"
  )) {
    invisible(dbExecute(con, paste("RESET", name)))
  }
}
rows <- lapply(names(settings), function(label) {
  for (sql in settings[[label]]) {
    invisible(dbExecute(con, sql))
  }
  on.exit(reset())
  now <- each(exported)
  moved <- now != default
  if (!any(moved)) {
    return(data.frame(
      setting = label,
      type = "(none)",
      arrow = "",
      nanoarrow = "",
      arrow_pkg = ""
    ))
  }
  data.frame(
    setting = label,
    type = types$type[moved],
    arrow = now[moved],
    nanoarrow = each(via_nanoarrow, types$lit[moved]),
    arrow_pkg = each(via_arrow, types$lit[moved])
  )
})
print(do.call(rbind, rows), right = FALSE, row.names = FALSE)

# --- Precision: values where the reader decides what survives --------

# The text is the engine's own rendering, and the reference.
stress <- c(
  "UINTEGER" = "4294967295::UINTEGER",
  "BIGINT" = "9007199254740993::BIGINT",
  "UBIGINT" = "18446744073709551615::UBIGINT",
  "HUGEINT" = "170141183460469231731687303715884105727::HUGEINT",
  "UHUGEINT" = "340282366920938463463374607431768211455::UHUGEINT",
  "DECIMAL(38,10)" = "1234567890123456789012345678.1234567891::DECIMAL(38,10)",
  "TIME_NS" = "'13:03:12.123456789'::TIME_NS",
  "TIMESTAMP_NS" = "TIMESTAMP_NS '2024-01-10 13:03:12.123456789'",
  "TIMESTAMP" = "TIMESTAMP '1677-01-01 00:00:00.000001'",
  "TIMESTAMP (infinity)" = "'infinity'::TIMESTAMP",
  "DATE (infinity)" = "'infinity'::DATE",
  "INTERVAL" = "INTERVAL '1 month 2 days 3.000004 seconds'"
)
print(
  data.frame(
    value = names(stress),
    text = vapply(
      stress,
      function(lit) {
        cell(dbGetQuery(con, paste0("SELECT (", lit, ")::VARCHAR"))[[1]])
      },
      character(1)
    ),
    nanoarrow = each(via_nanoarrow, stress),
    arrow = each(via_arrow, stress)
  ),
  right = FALSE,
  row.names = FALSE
)

# --- Time zones: the label each reader gives a timestamp -----------------

# R's zone and DuckDB's TimeZone differ on purpose, so that each label shows
# which of the two it came from; the instant is 13:03:12 UTC in every row.
local({
  withr::local_timezone("America/New_York")
  invisible(dbExecute(con, "SET TimeZone = 'America/Los_Angeles'"))
  on.exit(invisible(dbExecute(con, "RESET TimeZone")))
  label <- function(x) {
    tz <- attr(x, "tzone")
    paste0(
      if (is.null(tz)) "tzone unset" else paste0("tzone '", tz, "'"),
      ", ",
      format(x, usetz = TRUE)
    )
  }
  lits <- c(
    "TIMESTAMP" = "TIMESTAMP '2024-01-10 13:03:12'",
    "TIMESTAMPTZ" = "TIMESTAMPTZ '2024-01-10 13:03:12+00'"
  )
  print(
    data.frame(
      type = names(lits),
      arrow_type = each(exported, lits),
      nanoarrow = each(function(l) label(as.data.frame(one(l))$x), lits),
      arrow = each(
        function(l) label(as.data.frame(arrow::as_arrow_table(one(l)))$x),
        lits
      )
    ),
    right = FALSE,
    row.names = FALSE
  )
})

dbDisconnect(con, shutdown = TRUE)
