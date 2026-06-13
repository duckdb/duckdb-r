# dbSpatial (0.1.1)

* GitHub: <https://github.com/dbverse-org/dbspatial-r>
* Email: <mailto:ecr7407@gmail.com>
* GitHub mirror: <https://github.com/cran/dbSpatial>

Run `revdepcheck::cloud_details(, "dbSpatial")` for more info

## Newly broken

*   checking tests ... ERROR
     ```
     ...
         8. │     └─DBI::dbSendStatement(conn, statement, ...)
         9. │       ├─DBI::dbSendQuery(conn, statement, ...)
        10. │       └─duckdb::dbSendQuery(conn, statement, ...)
        11. │         └─duckdb (local) .local(conn, statement, ...)
        12. │           └─duckdb:::rethrow_rapi_prepare(conn@conn_ref, statement, env)
        13. │             ├─rlang::try_fetch(...)
        14. │             │ ├─base::tryCatch(...)
        15. │             │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
        16. │             │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
        17. │             │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
        18. │             │ └─base::withCallingHandlers(...)
        19. │             └─duckdb:::rapi_prepare(conn, query, env)
        20. ├─duckdb (local) `<fn>`(...)
        21. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
        22. │   └─rlang:::signal_abort(cnd, .file)
        23. │     └─base::signalCondition(cnd)
        24. └─rlang (local) `<fn>`(`<dckdb_rr>`)
        25.   └─handlers[[1L]](cnd)
        26.     └─duckdb:::rethrow_error_from_rapi(e, call)
        27.       └─rlang::abort(msg, call = call)
       
       [ FAIL 6 | WARN 0 | SKIP 0 | PASS 0 ]
       Error:
       ! Test failures.
       Execution halted
     ```

*   checking re-building of vignette outputs ... ERROR
     ```
     ...
       2.   ├─base::suppressMessages(loadSpatial(conn = conn))
       3.   │ └─base::withCallingHandlers(...)
       4.   └─dbSpatial::loadSpatial(conn = conn)
       5.     ├─DBI::dbExecute(conn, query)
       6.     └─DBI::dbExecute(conn, query)
       7.       ├─DBI::dbSendStatement(conn, statement, ...)
       8.       └─DBI::dbSendStatement(conn, statement, ...)
       9.         ├─DBI::dbSendQuery(conn, statement, ...)
      10.         └─duckdb::dbSendQuery(conn, statement, ...)
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     
     Error: processing vignette 'spatial_operations.Rmd' failed with diagnostics:
     Invalid Error: HTTP Error: Failed to download extension "spatial" at URL "http://extensions.duckdb.org/894e3727d19/linux_amd64/spatial.duckdb_extension.gz" (HTTP 404)
     Extension "spatial" is an existing extension.
     
     For more info, visit https://duckdb.org/docs/stable/extensions/troubleshooting?version=894e3727d19&platform=linux_amd64&extension=spatial
     ℹ Context: rapi_prepare
     ℹ Error type: INVALID
     --- failed re-building ‘spatial_operations.Rmd’
     
     SUMMARY: processing the following files failed:
       ‘class_structure.Rmd’ ‘getting_started.Rmd’ ‘spatial_operations.Rmd’
     
     Error: Vignette re-building failed.
     Execution halted
     ```

# duckh3 (0.1.0)

* GitHub: <https://github.com/Cidree/duckh3>
* Email: <mailto:adrian.cidre@gmail.com>
* GitHub mirror: <https://github.com/cran/duckh3>

Run `revdepcheck::cloud_details(, "duckh3")` for more info

## Newly broken

*   checking examples ... ERROR
     ```
     ...
     The following objects are masked from ‘package:stats’:
     
         filter, lag
     
     The following objects are masked from ‘package:base’:
     
         intersect, setdiff, setequal, union
     
     > 
     > ## Setup the default connection with h3 and spatial extensions
     > ## This is a mandatory step to use duckh3 functions
     > ddbh3_default_conn(threads = 1)
     Error in `ddbs_install()`:
     ! Failed to install the spatial extension.
     ℹ It could not be found in the core or community repositories.
     ℹ Check that the extension name is correct:
       <https://duckdb.org/docs/extensions/overview>
     Backtrace:
         ▆
      1. └─duckh3::ddbh3_default_conn(threads = 1)
      2.   └─duckspatial::ddbs_create_conn(...)
      3.     └─duckspatial::ddbs_install(conn, upgrade = upgrade, quiet = TRUE)
      4.       └─cli::cli_abort(...)
      5.         └─rlang::abort(...)
     Execution halted
     ```

*   checking tests ... ERROR
     ```
     ...
       ! Failed to install the spatial extension.
       ℹ It could not be found in the core or community repositories.
       ℹ Check that the extension name is correct:
         <https://duckdb.org/docs/extensions/overview>
       Backtrace:
            ▆
         1. └─testthat::test_check("duckh3")
         2.   └─testthat::test_dir(...)
         3.     └─testthat:::test_files(...)
         4.       └─testthat:::test_files_serial(...)
         5.         └─testthat:::test_files_setup_state(...)
         6.           └─testthat::source_test_setup(".", env)
         7.             └─testthat::source_dir(path, "^setup.*\\.[rR]$", env = env, wrap = FALSE)
         8.               └─base::lapply(...)
         9.                 └─testthat (local) FUN(X[[i]], ...)
        10.                   └─testthat::source_file(...)
        11.                     ├─base::withCallingHandlers(...)
        12.                     └─base::eval(exprs, env)
        13.                       └─base::eval(exprs, env)
        14.                         └─duckh3::ddbh3_default_conn() at ./setup.R:12:1
        15.                           └─duckspatial::ddbs_create_conn(...)
        16.                             └─duckspatial::ddbs_install(conn, upgrade = upgrade, quiet = TRUE)
        17.                               └─cli::cli_abort(...)
        18.                                 └─rlang::abort(...)
       Execution halted
     ```

# duckspatial (1.1.1)

* GitHub: <https://github.com/Cidree/duckspatial>
* Email: <mailto:adrian.cidre@gmail.com>
* GitHub mirror: <https://github.com/cran/duckspatial>

Run `revdepcheck::cloud_details(, "duckspatial")` for more info

## Newly broken

*   checking examples ... ERROR
     ```
     ...
     > ### Aliases: ddbs_install
     > 
     > ### ** Examples
     > 
     > ## load packages
     > library(duckspatial)
     > library(duckdb)
     Loading required package: DBI
     > 
     > # connect to in memory database
     > conn <- duckdb::dbConnect(duckdb::duckdb())
     > 
     > # install the spatial extension
     > ddbs_install(conn)
     Error in `ddbs_install()`:
     ! Failed to install the spatial extension.
     ℹ It could not be found in the core or community repositories.
     ℹ Check that the extension name is correct:
       <https://duckdb.org/docs/extensions/overview>
     Backtrace:
         ▆
      1. └─duckspatial::ddbs_install(conn)
      2.   └─cli::cli_abort(...)
      3.     └─rlang::abort(...)
     Execution halted
     ```

*   checking tests ... ERROR
     ```
     ...
       ℹ Check that the extension name is correct:
         <https://duckdb.org/docs/extensions/overview>
       Backtrace:
            ▆
         1. └─testthat::test_check("duckspatial")
         2.   └─testthat::test_dir(...)
         3.     └─testthat:::test_files(...)
         4.       └─testthat:::test_files_serial(...)
         5.         └─testthat:::test_files_setup_state(...)
         6.           └─testthat::source_test_setup(".", env)
         7.             └─testthat::source_dir(path, "^setup.*\\.[rR]$", env = env, wrap = FALSE)
         8.               └─base::lapply(...)
         9.                 └─testthat (local) FUN(X[[i]], ...)
        10.                   └─testthat::source_file(...)
        11.                     ├─base::withCallingHandlers(...)
        12.                     └─base::eval(exprs, env)
        13.                       └─base::eval(exprs, env)
        14.                         ├─duckspatial::as_duckspatial_df(argentina_sf) at ./setup.R:15:1
        15.                         └─duckspatial:::as_duckspatial_df.sf(argentina_sf)
        16.                           └─duckspatial:::ddbs_default_conn()
        17.                             └─duckspatial::ddbs_create_conn(dbdir = "memory", ...)
        18.                               └─duckspatial::ddbs_install(conn, upgrade = upgrade, quiet = TRUE)
        19.                                 └─cli::cli_abort(...)
        20.                                   └─rlang::abort(...)
       Execution halted
     ```

# motherduck (0.2.1)

* Email: <mailto:alejandro.hagan@outlook.com>
* GitHub mirror: <https://github.com/cran/motherduck>

Run `revdepcheck::cloud_details(, "motherduck")` for more info

## Newly broken

*   checking tests ... ERROR
     ```
     ...
       v Inserted into existing database "memory"
       v Using existing schema "main"
       v Overwrite existing table "mtcars_csv"
       Saving _problems/test-motherduck-405.R
       [ FAIL 1 | WARN 0 | SKIP 1 | PASS 22 ]
       
       ══ Skipped tests (1) ═══════════════════════════════════════════════════════════
       • empty test (1): 'test-motherduck.R:259:3'
       
       ══ Failed tests ════════════════════════════════════════════════════════════════
       ── Error ('test-motherduck.R:405:7'): read_excel / successfully reads a excel and copies table to database ──
       <purrr_error_indexed/rlang_error/error/condition>
       Error in `purrr::map(ext_lst$valid_ext, function(x) DBI::dbExecute(.con, glue::glue("INSTALL {x};")))`: i In index: 1.
       Caused by error in `duckdb_result()`:
       ! Invalid Error: HTTP Error: Failed to download extension "excel" at URL "http://extensions.duckdb.org/894e3727d19/linux_amd64/excel.duckdb_extension.gz" (HTTP 404)
       Extension "excel" is an existing extension.
       
       For more info, visit https://duckdb.org/docs/stable/extensions/troubleshooting?version=894e3727d19&platform=linux_amd64&extension=excel
       i Context: rapi_execute
       i Error type: INVALID
       
       [ FAIL 1 | WARN 0 | SKIP 1 | PASS 22 ]
       Error:
       ! Test failures.
       Execution halted
     ```

