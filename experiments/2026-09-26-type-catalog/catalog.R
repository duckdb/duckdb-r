# Every DuckDB type, both directions: what a value of each type becomes in
# R, and which routes put that R value back as the same type.
# One row per type, one column per route; the recorded run is catalog.md,
# rendered with reprex::reprex(si = TRUE).
library(duckdb)
library(geoarrow) # registers geoarrow.wkb, so an Arrow GEOMETRY converts
options(width = 250)
options(nanoarrow.warn_unregistered_extension = FALSE)
# Name the extension store explicitly, so the location reminder stays out
# of the record.
options(duckdb.home = "~/.duckdb")

# The types, with a value of each: types.R, shared with arrow.R.
source("types.R")

# Two connections: every default, and every option that changes a type's R
# shape. Writes run on the second, where the value written back is the one
# the option produced.
con <- dbConnect(duckdb())
con_opt <- dbConnect(
  duckdb(),
  bigint = "integer64",
  array = "matrix",
  map = "list_of",
  geometry = "wk"
)
for (e in unique(types$ext[types$ext != ""])) {
  invisible(dbExecute(con, paste("INSTALL", e)))
  for (cn in list(con, con_opt)) {
    invisible(dbExecute(cn, paste("LOAD", e)))
  }
}

# --- The list is complete ---------------------------------------------

# Every type id the engine knows is covered, and so is every type name an
# extension adds; TYPE is the catalog's own and holds no data.
known <- dbGetQuery(con, "SELECT type_name, logical_type FROM duckdb_types()")
setdiff(unique(known$logical_type), c(types$logical, "TYPE"))
added <- dbGetQuery(
  con,
  "SELECT type_name FROM duckdb_types() WHERE type_name = upper(type_name)
     AND type_name NOT IN (SELECT upper(type_name) FROM duckdb_types()
                           WHERE type_name = lower(type_name))"
)$type_name
setdiff(added, sub("\\(.*", "", types$type))

# --- Helpers ----------------------------------------------------------

# One cell per route: the result, or the first line of the error, with a
# warning noted rather than printed.
cell <- function(expr, width = 58) {
  warned <- NULL
  out <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warned <<- conditionMessage(w)
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      msg <- sub(
        "^(Invalid Error|Invalid Input Error): ",
        "",
        conditionMessage(e)
      )
      paste("ERROR:", gsub("\n.*", "", msg))
    }
  )
  out <- if (is.na(out[1])) "NA" else as.character(out[1])
  if (!is.null(warned)) {
    out <- paste0(out, " (warns)")
  }
  if (nchar(out) > width) paste0(substr(out, 1, width - 3), "...") else out
}

# What R received: the class, the attribute that carries meaning, and the
# value as R prints it.
describe <- function(x) {
  cls <- paste(class(x), collapse = "/")
  extra <- if (inherits(x, "POSIXct")) {
    paste0("[", attr(x, "tzone") %||% "", "]")
  } else if (inherits(x, "difftime")) {
    paste0("[", units(x), "]")
  } else if (is.factor(x)) {
    paste0("[", paste(levels(x), collapse = ","), "]")
  } else if (is.matrix(x)) {
    paste0("[", paste(dim(x), collapse = "x"), "]")
  } else if (is.data.frame(x)) {
    paste0("[", paste(names(x), collapse = ","), "]")
  } else if (identical(class(x), "list") && length(x) && !is.null(x[[1]])) {
    paste0("<", paste(class(x[[1]]), collapse = "/"), ">")
  } else {
    ""
  }
  val <- if (is.list(x) && !is.data.frame(x) && !inherits(x, "wk_vctr")) {
    ""
  } else {
    format(x)[1]
  }
  paste0(cls, extra, if (nzchar(val)) paste0(" ", val))
}

fetch <- function(cn, lit) dbGetQuery(cn, paste("SELECT", lit, "AS x"))$x

# Whether what landed equals the original: compared as the type where the
# engine can, and as text where it cannot.
verdict <- function(cn, from, lit, params = NULL) {
  q <- "SELECT x IS NOT DISTINCT FROM (%s) AS s, x::VARCHAR AS t FROM (%s)"
  r <- tryCatch(
    dbGetQuery(cn, sprintf(q, lit, from), params = params),
    error = function(e) NULL
  )
  suffix <- ""
  if (is.null(r)) {
    q <- paste(
      "SELECT x::VARCHAR IS NOT DISTINCT FROM (%s)::VARCHAR AS s,",
      "x::VARCHAR AS t FROM (%s)"
    )
    r <- dbGetQuery(cn, sprintf(q, lit, from), params = params)
    suffix <- " (as text)"
  }
  if (isTRUE(r$s[1])) paste0("same", suffix) else paste("differs:", r$t[1])
}

# A one-row data frame whose column is the value, whatever its shape.
frame <- function(x) {
  d <- data.frame(id = 1L)
  d$x <- x
  d
}

# --- Reading ------------------------------------------------------------

arrow_shape <- function(lit) {
  s <- nanoarrow::as_nanoarrow_array_stream(dbGetQueryArrow(
    con,
    paste("SELECT", lit, "AS x")
  ))
  sch <- s$get_schema()$children$x
  ext <- sch$metadata[["ARROW:extension:name"]]
  paste0(
    sch$format,
    if (!is.null(sch$dictionary)) {
      paste0(" dictionary<", sch$dictionary$format, ">")
    },
    if (!is.null(ext)) paste0(" ", ext),
    " -> ",
    paste(class(as.data.frame(s)$x), collapse = "/")
  )
}

read <- do.call(
  rbind,
  lapply(seq_len(nrow(types)), function(i) {
    t <- types[i, ]
    data.frame(
      type = t$type,
      default = cell(describe(fetch(con, t$lit))),
      option = if (nzchar(t$opt)) {
        cell(paste0(t$opt, ": ", describe(fetch(con_opt, t$lit))))
      } else {
        ""
      },
      arrow = cell(arrow_shape(t$lit)),
      text = cell(fetch(con, paste0("(", t$lit, ")::VARCHAR")))
    )
  })
)
print(read, right = FALSE)

# --- Writing --------------------------------------------------------------

# The value to write back is what the best read returned: the option's, if
# the type has one, else the default's.
value_of <- function(t) {
  tryCatch(
    fetch(if (nzchar(t$opt)) con_opt else con, t$lit),
    error = function(e) NULL
  )
}

# An untyped NULL has no column type to write back to.
writable <- types[types$logical != "NULL", ]
write <- do.call(
  rbind,
  lapply(seq_len(nrow(writable)), function(i) {
    t <- writable[i, ]
    x <- value_of(t)
    txt <- fetch(con, paste0("(", t$lit, ")::VARCHAR"))
    none <- "(no R value)"
    data.frame(
      type = t$type,
      natural = if (is.null(x)) {
        none
      } else {
        cell({
          dbWriteTable(con_opt, "w", frame(x), overwrite = TRUE)
          paste0(
            dbGetQuery(con_opt, "SELECT typeof(x) AS t FROM w")$t,
            "; ",
            verdict(con_opt, "SELECT x FROM w", t$lit)
          )
        })
      },
      field.types = if (is.null(x)) {
        none
      } else {
        cell({
          dbWriteTable(
            con_opt,
            "w",
            frame(x),
            overwrite = TRUE,
            field.types = c(x = t$type)
          )
          verdict(con_opt, "SELECT x FROM w", t$lit)
        })
      },
      append = if (is.null(x)) {
        none
      } else {
        cell({
          dbExecute(
            con_opt,
            paste("CREATE OR REPLACE TABLE a (id INTEGER, x", t$type, ")")
          )
          dbAppendTable(con_opt, "a", frame(x))
          verdict(con_opt, "SELECT x FROM a", t$lit)
        })
      },
      bind = if (is.null(x)) {
        none
      } else {
        cell(verdict(
          con_opt,
          paste0("SELECT ?::", t$type, " AS x"),
          t$lit,
          params = list(x)
        ))
      },
      from_text = cell({
        dbWriteTable(
          con_opt,
          "w",
          frame(txt),
          overwrite = TRUE,
          field.types = c(x = t$type)
        )
        verdict(con_opt, "SELECT x FROM w", t$lit)
      })
    )
  })
)
print(write, right = FALSE)

dbDisconnect(con, shutdown = TRUE)
dbDisconnect(con_opt, shutdown = TRUE)
