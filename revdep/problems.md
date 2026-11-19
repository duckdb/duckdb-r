# duckh3 (0.2.0)

* GitHub: <https://github.com/Cidree/duckh3>
* Email: <mailto:adrian.cidre@gmail.com>
* GitHub mirror: <https://github.com/cran/duckh3>

Run `revdepcheck::revdep_details(, "duckh3")` for more info

## Newly broken

*   checking examples ... ERROR
     ```
     ...
     Error in `duckspatial::ddbs_install()`:
     ! Failed to install the h3 extension.
     ✖ core: HTTP Error: Failed to download extension "h3" at URL
       "http://extensions.duckdb.org/v2.0.1-alpha56598/linux_amd64/h3.duckdb_extension.gz"
       (HTTP 404) Candidate extensions: "s3", "http", "https", "httpfs",
       "motherduck" For more info, visit
       https://duckdb.org/docs/current/extensions/troubleshooting?version=v2.0.1-alpha56598&platform=linux_amd64&extension=h3
       ℹ Context: rapi_execute ℹ Error type: HTTP
     ✖ community: HTTP Error: Failed to download extension "h3" at URL
       "http://community-extensions.duckdb.org/v2.0.1-alpha56598/linux_amd64/h3.duckdb_extension.gz"
       (HTTP 404) Candidate extensions: "s3", "http", "https", "httpfs",
       "motherduck" For more info, visit
       https://duckdb.org/docs/current/extensions/troubleshooting?version=v2.0.1-alpha56598&platform=linux_amd64&extension=h3
       ℹ Context: rapi_execute ℹ Error type: HTTP
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
         ℹ Context: rapi_execute ℹ Error type: HTTP
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

