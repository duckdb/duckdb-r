# Reads a CSV file into DuckDB

Directly reads a CSV file into DuckDB, tries to detect and create the
correct schema for it. This usually is much faster than reading the data
into R and writing it to DuckDB.

## Usage

``` r
duckdb_read_csv(
  conn,
  name,
  files,
  ...,
  header = TRUE,
  na.strings = "",
  nrow.check = 500,
  delim = ",",
  quote = "\"",
  col.names = NULL,
  col.types = NULL,
  lower.case.names = FALSE,
  sep = delim,
  transaction = TRUE,
  temporary = FALSE
)
```

## Arguments

- conn:

  A DuckDB connection, created by
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

- name:

  The name for the virtual table that is registered or unregistered

- files:

  One or more CSV file names, should all have the same structure though

- ...:

  Reserved for future extensions, must be empty.

- header:

  Whether or not the CSV files have a separate header in the first line

- na.strings:

  Which strings in the CSV files should be considered to be NULL

- nrow.check:

  How many rows should be read from the CSV file to figure out data
  types

- delim:

  Which field separator should be used

- quote:

  Which quote character is used for columns in the CSV file

- col.names:

  Override the detected or generated column names

- col.types:

  Character vector of column types in the same order as col.names, or a
  named character vector where names are column names and types pairs.
  Valid types are [DuckDB data
  types](https://duckdb.org/docs/sql/data_types/overview.html), e.g.
  VARCHAR, DOUBLE, DATE, BIGINT, BOOLEAN, etc.

- lower.case.names:

  Transform column names to lower case

- sep:

  Alias for delim for compatibility

- transaction:

  Should a transaction be used for the entire operation

- temporary:

  Set to `TRUE` to create a temporary table

## Value

The number of rows in the resulted table, invisibly.

## Details

If the table already exists in the database, the csv is appended to it.
Otherwise the table is created.

## Examples

``` r
con <- dbConnect(duckdb())
#> Error in (function (cond) .Internal(C_tryCatchHelper(addr, 1L, cond)))(structure(list(message = "{\"exception_type\":\"IO\",\"exception_message\":\"Input is not a GZIP stream: /proc/self/cgroup\"}\n\033[34mℹ\033[39m Context: rapi_startup",     trace = structure(list(call = list(pkgdown::deploy_to_branch(new_process = FALSE),         build_site_github_pages(pkg, ..., clean = clean), build_site(pkg,             preview = FALSE, install = install, new_process = new_process,             ...), build_site_local(pkg = pkg, examples = examples,             run_dont_run = run_dont_run, seed = seed, lazy = lazy,             override = override, preview = preview, devel = devel,             quiet = quiet), build_reference(pkg, lazy = lazy,             examples = examples, run_dont_run = run_dont_run,             seed = seed, override = override, preview = FALSE,             devel = devel), unwrap_purrr_error(purrr::map(topics,             build_reference_topic, pkg = pkg, lazy = lazy, examples_env = examples_env,             run_dont_run = run_dont_run)), withCallingHandlers(code,             purrr_error_indexed = function(err) {                cnd_signal(err$parent)            }), purrr::map(topics, build_reference_topic, pkg = pkg,             lazy = lazy, examples_env = examples_env, run_dont_run = run_dont_run),         map_("list", .x, .f, ..., .progress = .progress), with_indexed_errors(i = i,             names = names, error_call = .purrr_error_call, call_with_cleanup(map_impl,                 environment(), .type, .progress, n, names, i)),         withCallingHandlers(expr, error = function(cnd) {            if (i == 0L) {            }            else {                message <- c(i = "In index: {i}.")                if (!is.null(names) && !is.na(names[[i]]) &&                   names[[i]] != "") {                  name <- names[[i]]                  message <- c(message, i = "With name: {name}.")                }                else {                  name <- NULL                }                cli::cli_abort(message, location = i, name = name,                   parent = cnd, call = error_call, class = "purrr_error_indexed")            }        }), call_with_cleanup(map_impl, environment(), .type,             .progress, n, names, i), .f(.x[[i]], ...), withCallingHandlers(data_reference_topic(topic,             pkg, examples_env = examples_env, run_dont_run = run_dont_run),             error = function(err) {                cli::cli_abort("Failed to parse Rd in {.file {topic$file_in}}",                   parent = err, call = quote(build_reference()))            }), data_reference_topic(topic, pkg, examples_env = examples_env,             run_dont_run = run_dont_run), run_examples(tags$tag_examples[[1]],             env = if (is.null(examples_env)) NULL else new.env(parent = examples_env),             topic = tools::file_path_sans_ext(topic$file_in),             run_dont_run = run_dont_run), highlight_examples(code,             topic, env = env), downlit::evaluate_and_highlight(code,             fig_save = fig_save_topic, env = eval_env, output_handler = handler),         evaluate::evaluate(code, child_env(env), new_device = TRUE,             output_handler = output_handler), withRestarts(with_handlers({            for (expr in tle$exprs) {                ev <- withVisible(eval(expr, envir))                watcher$capture_plot_and_output()                watcher$print_value(ev$value, ev$visible, envir)            }            TRUE        }, handlers), eval_continue = function() TRUE, eval_stop = function() FALSE),         withRestartList(expr, restarts), withOneRestart(withRestartList(expr,             restarts[-nr]), restarts[[nr]]), doWithOneRestart(return(expr),             restart), withRestartList(expr, restarts[-nr]), withOneRestart(expr,             restarts[[1L]]), doWithOneRestart(return(expr), restart),         with_handlers({            for (expr in tle$exprs) {                ev <- withVisible(eval(expr, envir))                watcher$capture_plot_and_output()                watcher$print_value(ev$value, ev$visible, envir)            }            TRUE        }, handlers), eval(call), eval(call), withCallingHandlers(code,             message = `<fn>`, warning = `<fn>`, error = `<fn>`),         withVisible(eval(expr, envir)), eval(expr, envir), eval(expr,             envir), dbConnect(duckdb()), duckdb(), new("duckdb_driver",             config = config, database_ref = rethrow_rapi_startup(dbdir,                 read_only, config, environment_scan), dbdir = dbdir,             read_only = read_only, convert_opts = convert_opts,             bigint = convert_opts$bigint), initialize(value,             ...), initialize(value, ...), rethrow_rapi_startup(dbdir,             read_only, config, environment_scan), rlang::try_fetch(rapi_startup(dbdir,             readonly, configsexp, environment_scan), error = function(e) {            rethrow_error_from_rapi(e, call)        }), tryCatch(withCallingHandlers(expr, condition = function(cnd) {            {                .__handler_frame__. <- TRUE                .__setup_frame__. <- frame                if (inherits(cnd, "message")) {                  except <- c("warning", "error")                }                else if (inherits(cnd, "warning")) {                  except <- "error"                }                else {                  except <- ""                }            }            while (!is_null(cnd)) {                if (inherits(cnd, "error")) {                  out <- handlers[[1L]](cnd)                  if (!inherits(out, "rlang_zap"))                     throw(out)                }                inherit <- .subset2(.subset2(cnd, "rlang"), "inherit")                if (is_false(inherit)) {                  return()                }                cnd <- .subset2(cnd, "parent")            }        }), stackOverflowError = handlers[[1L]]), tryCatchList(expr,             classes, parentenv, handlers), tryCatchOne(expr,             names, parentenv, handlers[[1L]]), doTryCatch(return(expr),             name, parentenv, handler), withCallingHandlers(expr,             condition = function(cnd) {                {                  .__handler_frame__. <- TRUE                  .__setup_frame__. <- frame                  if (inherits(cnd, "message")) {                    except <- c("warning", "error")                  }                  else if (inherits(cnd, "warning")) {                    except <- "error"                  }                  else {                    except <- ""                  }                }                while (!is_null(cnd)) {                  if (inherits(cnd, "error")) {                    out <- handlers[[1L]](cnd)                    if (!inherits(out, "rlang_zap"))                       throw(out)                  }                  inherit <- .subset2(.subset2(cnd, "rlang"),                     "inherit")                  if (is_false(inherit)) {                    return()                  }                  cnd <- .subset2(cnd, "parent")                }            }), rapi_startup(dbdir, readonly, configsexp, environment_scan),         `<fn>`("rapi_startup", "{\"exception_type\":\"IO\",\"exception_message\":\"Input is not a GZIP stream: /proc/self/cgroup\"}"),         rlang::abort(error_parts, class = "duckdb_error", !!!fields),         signal_abort(cnd, .file), signalCondition(cnd), `<fn>`(`<dckdb_rr>`),         handlers[[1L]](cnd), rethrow_error_from_rapi(e, call),         rlang::abort(msg, call = call)), parent = c(0L, 1L, 2L,     3L, 4L, 5L, 6L, 5L, 8L, 9L, 10L, 9L, 9L, 13L, 13L, 15L, 16L,     17L, 18L, 19L, 20L, 21L, 22L, 21L, 24L, 25L, 19L, 27L, 28L,     27L, 19L, 19L, 32L, 33L, 33L, 35L, 36L, 36L, 35L, 39L, 40L,     41L, 42L, 43L, 40L, 39L, 0L, 47L, 48L, 49L, 0L, 51L, 52L,     53L), visible = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,     TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,     TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,     TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE    ), namespace = c("pkgdown", "pkgdown", "pkgdown", "pkgdown",     "pkgdown", "pkgdown", "base", "purrr", "purrr", "purrr",     "base", "purrr", "pkgdown", "base", "pkgdown", "pkgdown",     "pkgdown", "downlit", "evaluate", "base", "base", "base",     "base", "base", "base", "base", "evaluate", "base", "base",     "base", "base", "base", "base", "DBI", "duckdb.1.4", "methods",     "methods", "methods", "duckdb.1.4", "rlang", "base", "base",     "base", "base", "base", "duckdb.1.4", "duckdb.1.4", "rlang",     "rlang", "base", "rlang", NA, "duckdb.1.4", "rlang"), scope = c("::",     "::", "::", ":::", "::", ":::", "::", "::", ":::", ":::",     "::", ":::", "local", "::", ":::", ":::", ":::", "::", "::",     "::", "local", "local", "local", "local", "local", "local",     ":::", "::", "::", "::", "::", "::", "::", "::", "::", "::",     "::", "::", ":::", "::", "::", "local", "local", "local",     "::", ":::", "local", "::", ":::", "::", "local", NA, ":::",     "::"), error_frame = c(FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE)), row.names = c(NA, -54L), version = 2L, class = c("rlang_trace",     "rlib_trace", "tbl", "data.frame")), parent = NULL, rlang = list(        inherit = TRUE), call = eval(expr, envir)), class = c("rlang_error", "error", "condition"))): error in evaluating the argument 'drv' in selecting a method for function 'dbConnect': {"exception_type":"IO","exception_message":"Input is not a GZIP stream: /proc/self/cgroup"}
#> ℹ Context: rapi_startup

data <- data.frame(a = 1:3, b = letters[1:3])
path <- tempfile(fileext = ".csv")

write.csv(data, path, row.names = FALSE)

duckdb_read_csv(con, "data", path)
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'conn' in selecting a method for function 'dbBegin': object 'con' not found
dbReadTable(con, "data")
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'conn' in selecting a method for function 'dbReadTable': object 'con' not found

dbDisconnect(con)
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'conn' in selecting a method for function 'dbDisconnect': object 'con' not found


# Providing data types for columns
path <- tempfile(fileext = ".csv")
write.csv(iris, path, row.names = FALSE)

con <- dbConnect(duckdb())
#> Error in (function (cond) .Internal(C_tryCatchHelper(addr, 1L, cond)))(structure(list(message = "{\"exception_type\":\"IO\",\"exception_message\":\"Input is not a GZIP stream: /proc/self/cgroup\"}\n\033[34mℹ\033[39m Context: rapi_startup",     trace = structure(list(call = list(pkgdown::deploy_to_branch(new_process = FALSE),         build_site_github_pages(pkg, ..., clean = clean), build_site(pkg,             preview = FALSE, install = install, new_process = new_process,             ...), build_site_local(pkg = pkg, examples = examples,             run_dont_run = run_dont_run, seed = seed, lazy = lazy,             override = override, preview = preview, devel = devel,             quiet = quiet), build_reference(pkg, lazy = lazy,             examples = examples, run_dont_run = run_dont_run,             seed = seed, override = override, preview = FALSE,             devel = devel), unwrap_purrr_error(purrr::map(topics,             build_reference_topic, pkg = pkg, lazy = lazy, examples_env = examples_env,             run_dont_run = run_dont_run)), withCallingHandlers(code,             purrr_error_indexed = function(err) {                cnd_signal(err$parent)            }), purrr::map(topics, build_reference_topic, pkg = pkg,             lazy = lazy, examples_env = examples_env, run_dont_run = run_dont_run),         map_("list", .x, .f, ..., .progress = .progress), with_indexed_errors(i = i,             names = names, error_call = .purrr_error_call, call_with_cleanup(map_impl,                 environment(), .type, .progress, n, names, i)),         withCallingHandlers(expr, error = function(cnd) {            if (i == 0L) {            }            else {                message <- c(i = "In index: {i}.")                if (!is.null(names) && !is.na(names[[i]]) &&                   names[[i]] != "") {                  name <- names[[i]]                  message <- c(message, i = "With name: {name}.")                }                else {                  name <- NULL                }                cli::cli_abort(message, location = i, name = name,                   parent = cnd, call = error_call, class = "purrr_error_indexed")            }        }), call_with_cleanup(map_impl, environment(), .type,             .progress, n, names, i), .f(.x[[i]], ...), withCallingHandlers(data_reference_topic(topic,             pkg, examples_env = examples_env, run_dont_run = run_dont_run),             error = function(err) {                cli::cli_abort("Failed to parse Rd in {.file {topic$file_in}}",                   parent = err, call = quote(build_reference()))            }), data_reference_topic(topic, pkg, examples_env = examples_env,             run_dont_run = run_dont_run), run_examples(tags$tag_examples[[1]],             env = if (is.null(examples_env)) NULL else new.env(parent = examples_env),             topic = tools::file_path_sans_ext(topic$file_in),             run_dont_run = run_dont_run), highlight_examples(code,             topic, env = env), downlit::evaluate_and_highlight(code,             fig_save = fig_save_topic, env = eval_env, output_handler = handler),         evaluate::evaluate(code, child_env(env), new_device = TRUE,             output_handler = output_handler), withRestarts(with_handlers({            for (expr in tle$exprs) {                ev <- withVisible(eval(expr, envir))                watcher$capture_plot_and_output()                watcher$print_value(ev$value, ev$visible, envir)            }            TRUE        }, handlers), eval_continue = function() TRUE, eval_stop = function() FALSE),         withRestartList(expr, restarts), withOneRestart(withRestartList(expr,             restarts[-nr]), restarts[[nr]]), doWithOneRestart(return(expr),             restart), withRestartList(expr, restarts[-nr]), withOneRestart(expr,             restarts[[1L]]), doWithOneRestart(return(expr), restart),         with_handlers({            for (expr in tle$exprs) {                ev <- withVisible(eval(expr, envir))                watcher$capture_plot_and_output()                watcher$print_value(ev$value, ev$visible, envir)            }            TRUE        }, handlers), eval(call), eval(call), withCallingHandlers(code,             message = `<fn>`, warning = `<fn>`, error = `<fn>`),         withVisible(eval(expr, envir)), eval(expr, envir), eval(expr,             envir), dbConnect(duckdb()), duckdb(), new("duckdb_driver",             config = config, database_ref = rethrow_rapi_startup(dbdir,                 read_only, config, environment_scan), dbdir = dbdir,             read_only = read_only, convert_opts = convert_opts,             bigint = convert_opts$bigint), initialize(value,             ...), initialize(value, ...), rethrow_rapi_startup(dbdir,             read_only, config, environment_scan), rlang::try_fetch(rapi_startup(dbdir,             readonly, configsexp, environment_scan), error = function(e) {            rethrow_error_from_rapi(e, call)        }), tryCatch(withCallingHandlers(expr, condition = function(cnd) {            {                .__handler_frame__. <- TRUE                .__setup_frame__. <- frame                if (inherits(cnd, "message")) {                  except <- c("warning", "error")                }                else if (inherits(cnd, "warning")) {                  except <- "error"                }                else {                  except <- ""                }            }            while (!is_null(cnd)) {                if (inherits(cnd, "error")) {                  out <- handlers[[1L]](cnd)                  if (!inherits(out, "rlang_zap"))                     throw(out)                }                inherit <- .subset2(.subset2(cnd, "rlang"), "inherit")                if (is_false(inherit)) {                  return()                }                cnd <- .subset2(cnd, "parent")            }        }), stackOverflowError = handlers[[1L]]), tryCatchList(expr,             classes, parentenv, handlers), tryCatchOne(expr,             names, parentenv, handlers[[1L]]), doTryCatch(return(expr),             name, parentenv, handler), withCallingHandlers(expr,             condition = function(cnd) {                {                  .__handler_frame__. <- TRUE                  .__setup_frame__. <- frame                  if (inherits(cnd, "message")) {                    except <- c("warning", "error")                  }                  else if (inherits(cnd, "warning")) {                    except <- "error"                  }                  else {                    except <- ""                  }                }                while (!is_null(cnd)) {                  if (inherits(cnd, "error")) {                    out <- handlers[[1L]](cnd)                    if (!inherits(out, "rlang_zap"))                       throw(out)                  }                  inherit <- .subset2(.subset2(cnd, "rlang"),                     "inherit")                  if (is_false(inherit)) {                    return()                  }                  cnd <- .subset2(cnd, "parent")                }            }), rapi_startup(dbdir, readonly, configsexp, environment_scan),         `<fn>`("rapi_startup", "{\"exception_type\":\"IO\",\"exception_message\":\"Input is not a GZIP stream: /proc/self/cgroup\"}"),         rlang::abort(error_parts, class = "duckdb_error", !!!fields),         signal_abort(cnd, .file), signalCondition(cnd), `<fn>`(`<dckdb_rr>`),         handlers[[1L]](cnd), rethrow_error_from_rapi(e, call),         rlang::abort(msg, call = call)), parent = c(0L, 1L, 2L,     3L, 4L, 5L, 6L, 5L, 8L, 9L, 10L, 9L, 9L, 13L, 13L, 15L, 16L,     17L, 18L, 19L, 20L, 21L, 22L, 21L, 24L, 25L, 19L, 27L, 28L,     27L, 19L, 19L, 32L, 33L, 33L, 35L, 36L, 36L, 35L, 39L, 40L,     41L, 42L, 43L, 40L, 39L, 0L, 47L, 48L, 49L, 0L, 51L, 52L,     53L), visible = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,     TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,     TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,     TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE    ), namespace = c("pkgdown", "pkgdown", "pkgdown", "pkgdown",     "pkgdown", "pkgdown", "base", "purrr", "purrr", "purrr",     "base", "purrr", "pkgdown", "base", "pkgdown", "pkgdown",     "pkgdown", "downlit", "evaluate", "base", "base", "base",     "base", "base", "base", "base", "evaluate", "base", "base",     "base", "base", "base", "base", "DBI", "duckdb.1.4", "methods",     "methods", "methods", "duckdb.1.4", "rlang", "base", "base",     "base", "base", "base", "duckdb.1.4", "duckdb.1.4", "rlang",     "rlang", "base", "rlang", NA, "duckdb.1.4", "rlang"), scope = c("::",     "::", "::", ":::", "::", ":::", "::", "::", ":::", ":::",     "::", ":::", "local", "::", ":::", ":::", ":::", "::", "::",     "::", "local", "local", "local", "local", "local", "local",     ":::", "::", "::", "::", "::", "::", "::", "::", "::", "::",     "::", "::", ":::", "::", "::", "local", "local", "local",     "::", ":::", "local", "::", ":::", "::", "local", NA, ":::",     "::"), error_frame = c(FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,     FALSE, FALSE, FALSE, FALSE)), row.names = c(NA, -54L), version = 2L, class = c("rlang_trace",     "rlib_trace", "tbl", "data.frame")), parent = NULL, rlang = list(        inherit = TRUE), call = eval(expr, envir)), class = c("rlang_error", "error", "condition"))): error in evaluating the argument 'drv' in selecting a method for function 'dbConnect': {"exception_type":"IO","exception_message":"Input is not a GZIP stream: /proc/self/cgroup"}
#> ℹ Context: rapi_startup
duckdb_read_csv(con, "iris", path,
  col.types = c(
    Sepal.Length = "DOUBLE",
    Sepal.Width = "DOUBLE",
    Petal.Length = "DOUBLE",
    Petal.Width = "DOUBLE",
    Species = "VARCHAR"
  )
)
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'conn' in selecting a method for function 'dbBegin': object 'con' not found
dbReadTable(con, "iris")
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'conn' in selecting a method for function 'dbReadTable': object 'con' not found
dbDisconnect(con)
#> Error in h(simpleError(msg, call)): error in evaluating the argument 'conn' in selecting a method for function 'dbDisconnect': object 'con' not found
```
