# duckh3 (0.1.0)

* GitHub: <https://github.com/Cidree/duckh3>
* Email: <mailto:adrian.cidre@gmail.com>
* GitHub mirror: <https://github.com/cran/duckh3>

Run `revdepcheck::cloud_details(, "duckh3")` for more info

## Newly broken

*   checking examples ... ERROR
     ```
     ...
     ! Failed to install the h3 extension.
     ✖ core: Invalid Error: HTTP Error: Failed to download extension "h3" at URL
       "http://extensions.duckdb.org/e14c3db187/linux_amd64/h3.duckdb_extension.gz"
       (HTTP 404) Candidate extensions: "s3", "http", "https", "httpfs",
       "motherduck" For more info, visit
       https://duckdb.org/docs/stable/extensions/troubleshooting?version=e14c3db187&platform=linux_amd64&extension=h3
       ℹ Context: rapi_execute ℹ Error type: INVALID
     ✖ community: Invalid Error: HTTP Error: Failed to download extension "h3" at
       URL
       "http://community-extensions.duckdb.org/e14c3db187/linux_amd64/h3.duckdb_extension.gz"
       (HTTP 404) Candidate extensions: "s3", "http", "https", "httpfs",
       "motherduck" For more info, visit
       https://duckdb.org/docs/stable/extensions/troubleshooting?version=e14c3db187&platform=linux_amd64&extension=h3
       ℹ Context: rapi_execute ℹ Error type: INVALID
     ℹ It might not be available for this version of DuckDB, or the install location
       may not be writable.
     ℹ Check that the extension name is correct:
       <https://duckdb.org/docs/extensions/overview>
     Backtrace:
         ▆
      1. └─duckh3::ddbh3_default_conn(threads = 1)
      2.   └─duckspatial::ddbs_install(conn, upgrade = upgrade_h3, quiet = TRUE, extension = "h3")
      3.     └─cli::cli_abort(...)
      4.       └─rlang::abort(...)
     Execution halted
     ```

*   checking tests ... ERROR
     ```
     ...
         ℹ Context: rapi_execute ℹ Error type: INVALID
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
        15.                           └─duckspatial::ddbs_install(conn, upgrade = upgrade_h3, quiet = TRUE, extension = "h3")
        16.                             └─cli::cli_abort(...)
        17.                               └─rlang::abort(...)
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
       v Set `custom_extension_repository` = "https://core.example"
       v Set `custom_extension_repository` = "https://c.example"
       v Set `custom_extension_repository` = "https://fake.example"
       i Collecting data from Azure...
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

