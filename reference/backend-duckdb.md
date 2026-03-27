# DuckDB SQL backend for dbplyr

This is a SQL backend for dbplyr tailored to take into account DuckDB's
possibilities. This mainly follows the backend for PostgreSQL, but
contains more mapped functions.

`tbl_file()` is an experimental variant of
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) to
directly access files on disk. It is safer than
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) because
there is no risk of misinterpreting the request, and paths with special
characters are supported.

`tbl_function()` is an experimental variant of
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) to
create a lazy table from a table-generating function, useful for reading
nonstandard CSV files or other data sources. It is safer than
[`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) because
there is no risk of misinterpreting the query. See
<https://duckdb.org/docs/data/overview> for details on data importing
functions.

As an alternative, use
`dplyr::tbl(src, dplyr::sql("SELECT ... FROM ..."))` for custom SQL
queries.

`tbl_query()` is deprecated in favor of `tbl_function()`.

Use `simulate_duckdb()` with `lazy_frame()` to see simulated SQL without
opening a DuckDB connection.

## Usage

``` r
tbl_file(src = NULL, path, ..., cache = FALSE)

tbl_function(src, query, ..., cache = FALSE)

tbl_query(src, query, ...)

simulate_duckdb(...)
```

## Arguments

- src:

  A duckdb connection object,
  [`default_conn()`](https://r.duckdb.org/reference/default_conn.md) if
  omitted.

- path:

  Path to existing Parquet, CSV or JSON file

- ...:

  Any parameters to be forwarded

- cache:

  Enable object cache for Parquet files

- query:

  SQL code, omitting the `FROM` clause

## Examples

``` r
library(dplyr, warn.conflicts = FALSE)
con <- DBI::dbConnect(duckdb(), path = ":memory:")
#> Error in (function (cond) .Internal(C_tryCatchHelper(addr, 1L, cond)))(structure(list(message = "{\"exception_type\":\"IO\",\"exception_message\":\"Input is not a GZIP stream: /proc/self/cgroup\"}\n\033[34mℹ\033[39m Context: rapi_startup",     trace = structure(list(call = list(DBI::dbConnect(duckdb(),         path = ":memory:"), duckdb(), new("duckdb_driver", config = config,         database_ref = rethrow_rapi_startup(dbdir, read_only,             config, environment_scan), dbdir = dbdir, read_only = read_only,         convert_opts = convert_opts, bigint = convert_opts$bigint),         initialize(value, ...), initialize(value, ...), rethrow_rapi_startup(dbdir,             read_only, config, environment_scan), rlang::try_fetch(rapi_startup(dbdir,             readonly, configsexp, environment_scan), error = function(e) {            rethrow_error_from_rapi(e, call)        }), tryCatch(withCallingHandlers(expr, condition = function(cnd) {            {                .__handler_frame__. <- TRUE                .__setup_frame__. <- frame                if (inherits(cnd, "message")) {                  except <- c("warning", "error")                }                else if (inherits(cnd, "warning")) {                  except <- "error"                }                else {                  except <- ""                }            }            while (!is_null(cnd)) {                if (inherits(cnd, "error")) {                  out <- handlers[[1L]](cnd)                  if (!inherits(out, "rlang_zap"))                     throw(out)                }                inherit <- .subset2(.subset2(cnd, "rlang"), "inherit")                if (is_false(inherit)) {                  return()                }                cnd <- .subset2(cnd, "parent")            }        }), stackOverflowError = handlers[[1L]]), tryCatchList(expr,             classes, parentenv, handlers), tryCatchOne(expr,             names, parentenv, handlers[[1L]]), doTryCatch(return(expr),             name, parentenv, handler), withCallingHandlers(expr,             condition = function(cnd) {                {                  .__handler_frame__. <- TRUE                  .__setup_frame__. <- frame                  if (inherits(cnd, "message")) {                    except <- c("warning", "error")                  }                  else if (inherits(cnd, "warning")) {                    except <- "error"                  }                  else {                    except <- ""                  }                }                while (!is_null(cnd)) {                  if (inherits(cnd, "error")) {                    out <- handlers[[1L]](cnd)                    if (!inherits(out, "rlang_zap"))                       throw(out)                  }                  inherit <- .subset2(.subset2(cnd, "rlang"),                     "inherit")                  if (is_false(inherit)) {                    return()                  }                  cnd <- .subset2(cnd, "parent")                }            }), rapi_startup(dbdir, readonly, configsexp, environment_scan),         `<fn>`("rapi_startup", "{\"exception_type\":\"IO\",\"exception_message\":\"Input is not a GZIP stream: /proc/self/cgroup\"}"),         rlang::abort(error_parts, class = "duckdb_error", !!!fields),         signal_abort(cnd, .file), signalCondition(cnd), `<fn>`(`<dckdb_rr>`),         handlers[[1L]](cnd), rethrow_error_from_rapi(e, call),         rlang::abort(msg, call = call)), parent = c(0L, 0L, 2L,     3L, 3L, 2L, 6L, 7L, 8L, 9L, 10L, 7L, 6L, 0L, 14L, 15L, 16L,     0L, 18L, 19L, 20L), visible = c(FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),         namespace = c("DBI", "duckdb.1.4", "methods", "methods",         "methods", "duckdb.1.4", "rlang", "base", "base", "base",         "base", "base", "duckdb.1.4", "duckdb.1.4", "rlang",         "rlang", "base", "rlang", NA, "duckdb.1.4", "rlang"),         scope = c("::", "::", "::", "::", "::", ":::", "::",         "::", "local", "local", "local", "::", ":::", "local",         "::", ":::", "::", "local", NA, ":::", "::"), error_frame = c(FALSE,         FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,         FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,         FALSE, FALSE, FALSE, FALSE)), row.names = c(NA, -21L), version = 2L, class = c("rlang_trace",     "rlib_trace", "tbl", "data.frame")), parent = NULL, rlang = list(        inherit = TRUE), call = eval(expr, envir)), class = c("rlang_error", "error", "condition"))): error in evaluating the argument 'drv' in selecting a method for function 'dbConnect': {"exception_type":"IO","exception_message":"Input is not a GZIP stream: /proc/self/cgroup"}
#> ℹ Context: rapi_startup

db <- copy_to(con, data.frame(a = 1:3, b = letters[2:4]))
#> Error: object 'con' not found

db %>%
  filter(a > 1) %>%
  select(b)
#> Error: object 'db' not found

path <- tempfile(fileext = ".csv")
write.csv(data.frame(a = 1:3, b = letters[2:4]))
#> "","a","b"
#> "1",1,"b"
#> "2",2,"c"
#> "3",3,"d"

db_csv <- tbl_file(con, path)
#> Error: object 'con' not found
db_csv %>%
  summarize(sum_a = sum(a))
#> Error: object 'db_csv' not found

db_csv_fun <- tbl_function(con, paste0("read_csv_auto('", path, "')"))
#> Error: object 'con' not found
db_csv %>%
  count()
#> Error: object 'db_csv' not found

DBI::dbDisconnect(con, shutdown = TRUE)
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'conn' in selecting a method for function 'dbDisconnect': object 'con' not found
```
