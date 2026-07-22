# dbSpatial (0.1.2)

* GitHub: <https://github.com/dbverse-org/dbspatial-r>
* Email: <mailto:ecr7407@gmail.com>
* GitHub mirror: <https://github.com/cran/dbSpatial>

Run `revdepcheck::cloud_details(, "dbSpatial")` for more info

## Newly broken

*   checking re-building of vignette outputs ... ERROR
     ```
     ...
       4.   └─dbSpatial::loadSpatial(conn = conn)
       5.     ├─DBI::dbExecute(conn, "INSTALL spatial")
       6.     └─DBI::dbExecute(conn, "INSTALL spatial")
       7.       ├─DBI::dbSendStatement(conn, statement, ...)
       8.       └─DBI::dbSendStatement(conn, statement, ...)
       9.         ├─DBI::dbSendQuery(conn, statement, ...)
      10.         └─duckdb::dbSendQuery(conn, statement, ...)
      11.           └─duckdb (local) .local(conn, statement, ...)
      12.             └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     
     Error: processing vignette 'spatial_operations.Rmd' failed with diagnostics:
     Invalid Error: HTTP Error: Failed to download extension "spatial" at URL "http://extensions.duckdb.org/0b9ca13565/linux_amd64/spatial.duckdb_extension.gz" (HTTP 404)
     Extension "spatial" is an existing extension.
     
     For more info, visit https://duckdb.org/docs/stable/extensions/troubleshooting?version=0b9ca13565&platform=linux_amd64&extension=spatial
     ℹ Context: rapi_execute
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
       URL
       "http://extensions.duckdb.org/0b9ca13565/linux_amd64/spatial.duckdb_extension.gz"
       (HTTP 404) Extension "spatial" is an existing extension.  For more info,
       visit
       https://duckdb.org/docs/stable/extensions/troubleshooting?version=0b9ca13565&platform=linux_amd64&extension=spatial
       ℹ Context: rapi_execute ℹ Error type: INVALID
     ✖ community: Invalid Error: HTTP Error: Failed to download extension "spatial"
       at URL
       "http://community-extensions.duckdb.org/0b9ca13565/linux_amd64/spatial.duckdb_extension.gz"
       (HTTP 404) Extension "spatial" is an existing extension.  For more info,
       visit
       https://duckdb.org/docs/stable/extensions/troubleshooting?version=0b9ca13565&platform=linux_amd64&extension=spatial
       ℹ Context: rapi_execute ℹ Error type: INVALID
     ℹ It might not be available for this version of DuckDB, or the install location
       may not be writable.
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
       ℹ It might not be available for this version of DuckDB, or the install location
         may not be writable.
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

# duckspatial (1.2.1)

* GitHub: <https://github.com/Cidree/duckspatial>
* Email: <mailto:adrian.cidre@gmail.com>
* GitHub mirror: <https://github.com/cran/duckspatial>

Run `revdepcheck::cloud_details(, "duckspatial")` for more info

## Newly broken

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

# GeoTox (1.0.0)

* GitHub: <https://github.com/NIEHS/GeoTox>
* Email: <mailto:skylar.marvel@nih.gov>
* GitHub mirror: <https://github.com/cran/GeoTox>

Run `revdepcheck::cloud_details(, "GeoTox")` for more info

## Newly broken

*   checking tests ... ERROR
     ```
     ...
       i Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
       i Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
       i See ?duckdb_storage for details and alternatives.
       Saving _problems/test-calc_sensitivity-84.R
       The duckplyr package is configured to fall back to dplyr when it encounters an incompatibility. Fallback events can be collected and uploaded for analysis to guide future development. By default, data will be collected but no data will be uploaded.
       i Automatic fallback uploading is not controlled and therefore disabled, see `?duckplyr::fallback()`.
       v Number of reports ready for upload: 3.
       > Review with `duckplyr::fallback_review()`, upload with `duckplyr::fallback_upload()`.
       i Configure automatic uploading with `duckplyr::fallback_config()`.
       [ FAIL 1 | WARN 0 | SKIP 6 | PASS 224 ]
       
       ══ Skipped tests (6) ═══════════════════════════════════════════════════════════
       • On CRAN (6): 'test-calc_response.R:1:1', 'test-calc_response.R:61:1',
         'test-calc_risk.R:125:1', 'test-calc_sensitivity.R:26:1',
         'test-calc_sensitivity.R:102:1', 'test-sensitivity_analysis.R:1:1'
       
       ══ Failed tests ════════════════════════════════════════════════════════════════
       ── Failure ('test-calc_sensitivity.R:82:3'): calc sensitivity ──────────────────
       Expected `calc_sensitivity(GT)` to run silently.
       Actual noise: messages.
       
       [ FAIL 1 | WARN 0 | SKIP 6 | PASS 224 ]
       Error:
       ! Test failures.
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
       i Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
       i Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
       i See ?duckdb_storage for details and alternatives.
       Saving _problems/test-motherduck-405.R
       [ FAIL 1 | WARN 0 | SKIP 1 | PASS 22 ]
       
       ══ Skipped tests (1) ═══════════════════════════════════════════════════════════
       • empty test (1): 'test-motherduck.R:259:3'
       
       ══ Failed tests ════════════════════════════════════════════════════════════════
       ── Error ('test-motherduck.R:405:7'): read_excel / successfully reads a excel and copies table to database ──
       <purrr_error_indexed/rlang_error/error/condition>
       Error in `purrr::map(ext_lst$valid_ext, function(x) DBI::dbExecute(.con, glue::glue("INSTALL {x};")))`: i In index: 1.
       Caused by error in `duckdb_result()`:
       ! Invalid Error: HTTP Error: Failed to download extension "excel" at URL "http://extensions.duckdb.org/0b9ca13565/linux_amd64/excel.duckdb_extension.gz" (HTTP 404)
       Extension "excel" is an existing extension.
       
       For more info, visit https://duckdb.org/docs/stable/extensions/troubleshooting?version=0b9ca13565&platform=linux_amd64&extension=excel
       i Context: rapi_execute
       i Error type: INVALID
       
       [ FAIL 1 | WARN 0 | SKIP 1 | PASS 22 ]
       Error:
       ! Test failures.
       Execution halted
     ```

# quak (0.1.0)

* GitHub: <https://github.com/pedrobtz/quak>
* Email: <mailto:pedrobtz@gmail.com>
* GitHub mirror: <https://github.com/cran/quak>

Run `revdepcheck::cloud_details(, "quak")` for more info

## Newly broken

*   checking tests ... ERROR
     ```
     ...
       * Secrets are lost.
       i Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
       i Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
       i See ?duckdb_storage for details and alternatives.
       [ FAIL 1 | WARN 0 | SKIP 19 | PASS 260 ]
       
       ══ Skipped tests (19) ══════════════════════════════════════════════════════════
       • On CRAN (18): 'test-azure.R:2:3', 'test-azure.R:22:3', 'test-azure.R:39:3',
         'test-azure.R:56:3', 'test-azure.R:67:3', 'test-azure.R:91:3',
         'test-azure.R:109:3', 'test-azure.R:128:3', 'test-azure.R:139:3',
         'test-extensions.R:2:3', 'test-extensions.R:12:3', 'test-extensions.R:22:3',
         'test-extensions.R:39:3', 'test-extensions.R:51:3',
         'test-extensions.R:302:3', 'test-extensions.R:338:3',
         'test-extensions.R:352:3', 'test-extensions.R:367:3'
       • azure extension not installed (1): 'test-tables.R:46:3'
       
       ══ Failed tests ════════════════════════════════════════════════════════════════
       ── Failure ('test-conditions.R:60:3'): extension unavailable errors include extension metadata and parent ──
       Expected `err$parent` to be an S3 object.
       Actual OO type: none.
       
       [ FAIL 1 | WARN 0 | SKIP 19 | PASS 260 ]
       Error:
       ! Test failures.
       Execution halted
     ```

