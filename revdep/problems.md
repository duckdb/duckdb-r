# rcdf

<details>

* Version: 0.1.1
* GitHub: https://github.com/yng-me/rcdf
* Source code: https://github.com/cran/rcdf
* Date/Publication: 2025-10-12 13:50:02 UTC
* Number of recursive dependencies: 0

Run `revdepcheck::cloud_details(, "rcdf")` for more info

</details>

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘rcdf-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: write_parquet
    > ### Title: Write Parquet file with optional encryption
    > ### Aliases: write_parquet
    > 
    > ### ** Examples
    > 
    > 
    > data <- mtcars
    > key <- "5bddd0ea4ab48ed5e33b1406180d68158aa255cf3f368bdd4744abc1a7909ead"
    > iv <- "7D3EF463F4CCD81B11B6EC3230327B2D"
    > 
    > temp_dir <- tempdir()
    > 
    > rcdf::write_parquet(
    +   data = data,
    +   path = file.path(temp_dir, "mtcars.parquet"),
    +   encryption_key = list(aes_key = key, aes_iv = iv)
    + )
    Error in `duckdb_result()`:
    ! Invalid Error: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
    ℹ Context: rapi_execute
    ℹ Error type: INVALID
    ℹ Raw message: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
    Backtrace:
         ▆
      1. ├─rcdf::write_parquet(...)
      2. │ ├─DBI::dbExecute(conn = pq_conn, statement = pq_query)
      3. │ └─DBI::dbExecute(conn = pq_conn, statement = pq_query)
      4. │   ├─DBI::dbSendStatement(conn, statement, ...)
      5. │   └─DBI::dbSendStatement(conn, statement, ...)
      6. │     ├─DBI::dbSendQuery(conn, statement, ...)
      7. │     └─duckdb::dbSendQuery(conn, statement, ...)
      8. │       └─duckdb (local) .local(conn, statement, ...)
      9. │         └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
     10. │           └─duckdb:::duckdb_execute(res)
     11. │             └─duckdb:::rethrow_rapi_execute(...)
     12. │               ├─rlang::try_fetch(...)
     13. │               │ ├─base::tryCatch(...)
     14. │               │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
     15. │               │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
     16. │               │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
     17. │               │ └─base::withCallingHandlers(...)
     18. │               └─duckdb:::rapi_execute(stmt, convert_opts)
     19. ├─duckdb (local) `<fn>`(...)
     20. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
     21. │   └─rlang:::signal_abort(cnd, .file)
     22. │     └─base::signalCondition(cnd)
     23. └─rlang (local) `<fn>`(`<dckdb_rr>`)
     24.   └─handlers[[1L]](cnd)
     25.     └─duckdb:::rethrow_error_from_rapi(e, call)
     26.       └─rlang::abort(msg, call = call)
    Execution halted
    ```

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > # This file is part of the standard setup for testthat.
      > # It is recommended that you do not modify it.
      > #
      > # Where should you do additional test configuration?
      > # Learn more about the roles of various files in:
      > # * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
      > # * https://testthat.r-lib.org/articles/special-files.html
      > 
      > library(testthat)
      > library(rcdf)
      > 
      > test_check("rcdf")
      Saving _problems/test-read_parquet-35.R
      Saving _problems/test-read_parquet-59.R
      Saving _problems/test-read_rcdf-29.R
      Saving _problems/test-read_rcdf-53.R
      Saving _problems/test-write_parquet-13.R
      Saving _problems/test-write_rcdf-29.R
      Saving _problems/test-write_rcdf-62.R
      [ FAIL 7 | WARN 0 | SKIP 0 | PASS 46 ]
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Error ('test-read_parquet.R:35:3'): read_parquet reads encrypted Parquet file with decryption ──
      Error in `duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)`: Invalid Error: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      i Context: rapi_execute
      i Error type: INVALID
      i Raw message: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      Backtrace:
           ▆
        1. ├─rcdf::write_parquet(data, temp_file, encryption_key = mock_aes_key) at test-read_parquet.R:35:3
        2. │ ├─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        3. │ └─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        4. │   ├─DBI::dbSendStatement(conn, statement, ...)
        5. │   └─DBI::dbSendStatement(conn, statement, ...)
        6. │     ├─DBI::dbSendQuery(conn, statement, ...)
        7. │     └─duckdb::dbSendQuery(conn, statement, ...)
        8. │       └─duckdb (local) .local(conn, statement, ...)
        9. │         └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
       10. │           └─duckdb:::duckdb_execute(res)
       11. │             └─duckdb:::rethrow_rapi_execute(...)
       12. │               ├─rlang::try_fetch(...)
       13. │               │ ├─base::tryCatch(...)
       14. │               │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       15. │               │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       16. │               │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
       17. │               │ └─base::withCallingHandlers(...)
       18. │               └─duckdb:::rapi_execute(stmt, convert_opts)
       19. ├─duckdb (local) `<fn>`(...)
       20. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
       21. │   └─rlang:::signal_abort(cnd, .file)
       22. │     └─base::signalCondition(cnd)
       23. └─rlang (local) `<fn>`(`<dckdb_rr>`)
       24.   └─handlers[[1L]](cnd)
       25.     └─duckdb:::rethrow_error_from_rapi(e, call)
       26.       └─rlang::abort(msg, call = call)
      ── Error ('test-read_parquet.R:59:3'): read_parquet throws error with invalid decryption key ──
      Error in `duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)`: Invalid Error: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      i Context: rapi_execute
      i Error type: INVALID
      i Raw message: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      Backtrace:
           ▆
        1. ├─rcdf::write_parquet(data, temp_file, encryption_key = mock_aes_key) at test-read_parquet.R:59:3
        2. │ ├─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        3. │ └─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        4. │   ├─DBI::dbSendStatement(conn, statement, ...)
        5. │   └─DBI::dbSendStatement(conn, statement, ...)
        6. │     ├─DBI::dbSendQuery(conn, statement, ...)
        7. │     └─duckdb::dbSendQuery(conn, statement, ...)
        8. │       └─duckdb (local) .local(conn, statement, ...)
        9. │         └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
       10. │           └─duckdb:::duckdb_execute(res)
       11. │             └─duckdb:::rethrow_rapi_execute(...)
       12. │               ├─rlang::try_fetch(...)
       13. │               │ ├─base::tryCatch(...)
       14. │               │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       15. │               │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       16. │               │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
       17. │               │ └─base::withCallingHandlers(...)
       18. │               └─duckdb:::rapi_execute(stmt, convert_opts)
       19. ├─duckdb (local) `<fn>`(...)
       20. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
       21. │   └─rlang:::signal_abort(cnd, .file)
       22. │     └─base::signalCondition(cnd)
       23. └─rlang (local) `<fn>`(`<dckdb_rr>`)
       24.   └─handlers[[1L]](cnd)
       25.     └─duckdb:::rethrow_error_from_rapi(e, call)
       26.       └─rlang::abort(msg, call = call)
      ── Error ('test-read_rcdf.R:29:3'): read_rcdf can read and decrypt RCDF files ──
      Error in `duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)`: Invalid Error: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      i Context: rapi_execute
      i Error type: INVALID
      i Raw message: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      Backtrace:
           ▆
        1. ├─rcdf (local) create_mock_rcdf(temp_dir) at test-read_rcdf.R:29:3
        2. │ └─rcdf::write_rcdf(...) at test-read_rcdf.R:14:3
        3. │   └─rcdf::write_rcdf_parquet(...)
        4. │     └─rcdf::write_parquet(...)
        5. │       ├─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        6. │       └─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        7. │         ├─DBI::dbSendStatement(conn, statement, ...)
        8. │         └─DBI::dbSendStatement(conn, statement, ...)
        9. │           ├─DBI::dbSendQuery(conn, statement, ...)
       10. │           └─duckdb::dbSendQuery(conn, statement, ...)
       11. │             └─duckdb (local) .local(conn, statement, ...)
       12. │               └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
       13. │                 └─duckdb:::duckdb_execute(res)
       14. │                   └─duckdb:::rethrow_rapi_execute(...)
       15. │                     ├─rlang::try_fetch(...)
       16. │                     │ ├─base::tryCatch(...)
       17. │                     │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       18. │                     │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       19. │                     │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
       20. │                     │ └─base::withCallingHandlers(...)
       21. │                     └─duckdb:::rapi_execute(stmt, convert_opts)
       22. ├─duckdb (local) `<fn>`(...)
       23. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
       24. │   └─rlang:::signal_abort(cnd, .file)
       25. │     └─base::signalCondition(cnd)
       26. └─rlang (local) `<fn>`(`<dckdb_rr>`)
       27.   └─handlers[[1L]](cnd)
       28.     └─duckdb:::rethrow_error_from_rapi(e, call)
       29.       └─rlang::abort(msg, call = call)
      ── Error ('test-read_rcdf.R:53:3'): read_rcdf can read and decrypt RCDF files with RSA password protected key ──
      Error in `duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)`: Invalid Error: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      i Context: rapi_execute
      i Error type: INVALID
      i Raw message: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      Backtrace:
           ▆
        1. ├─rcdf (local) create_mock_rcdf(temp_dir, pw = "xxx") at test-read_rcdf.R:53:3
        2. │ └─rcdf::write_rcdf(...) at test-read_rcdf.R:14:3
        3. │   └─rcdf::write_rcdf_parquet(...)
        4. │     └─rcdf::write_parquet(...)
        5. │       ├─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        6. │       └─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        7. │         ├─DBI::dbSendStatement(conn, statement, ...)
        8. │         └─DBI::dbSendStatement(conn, statement, ...)
        9. │           ├─DBI::dbSendQuery(conn, statement, ...)
       10. │           └─duckdb::dbSendQuery(conn, statement, ...)
       11. │             └─duckdb (local) .local(conn, statement, ...)
       12. │               └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
       13. │                 └─duckdb:::duckdb_execute(res)
       14. │                   └─duckdb:::rethrow_rapi_execute(...)
       15. │                     ├─rlang::try_fetch(...)
       16. │                     │ ├─base::tryCatch(...)
       17. │                     │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       18. │                     │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       19. │                     │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
       20. │                     │ └─base::withCallingHandlers(...)
       21. │                     └─duckdb:::rapi_execute(stmt, convert_opts)
       22. ├─duckdb (local) `<fn>`(...)
       23. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
       24. │   └─rlang:::signal_abort(cnd, .file)
       25. │     └─base::signalCondition(cnd)
       26. └─rlang (local) `<fn>`(`<dckdb_rr>`)
       27.   └─handlers[[1L]](cnd)
       28.     └─duckdb:::rethrow_error_from_rapi(e, call)
       29.       └─rlang::abort(msg, call = call)
      ── Error ('test-write_parquet.R:13:3'): write_parquet writes encrypted Parquet files ──
      Error in `duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)`: Invalid Error: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      i Context: rapi_execute
      i Error type: INVALID
      i Raw message: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      Backtrace:
           ▆
        1. ├─rcdf::write_parquet(data, temp_file, encryption_key = mock_aes_key) at test-write_parquet.R:13:3
        2. │ ├─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        3. │ └─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        4. │   ├─DBI::dbSendStatement(conn, statement, ...)
        5. │   └─DBI::dbSendStatement(conn, statement, ...)
        6. │     ├─DBI::dbSendQuery(conn, statement, ...)
        7. │     └─duckdb::dbSendQuery(conn, statement, ...)
        8. │       └─duckdb (local) .local(conn, statement, ...)
        9. │         └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
       10. │           └─duckdb:::duckdb_execute(res)
       11. │             └─duckdb:::rethrow_rapi_execute(...)
       12. │               ├─rlang::try_fetch(...)
       13. │               │ ├─base::tryCatch(...)
       14. │               │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       15. │               │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       16. │               │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
       17. │               │ └─base::withCallingHandlers(...)
       18. │               └─duckdb:::rapi_execute(stmt, convert_opts)
       19. ├─duckdb (local) `<fn>`(...)
       20. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
       21. │   └─rlang:::signal_abort(cnd, .file)
       22. │     └─base::signalCondition(cnd)
       23. └─rlang (local) `<fn>`(`<dckdb_rr>`)
       24.   └─handlers[[1L]](cnd)
       25.     └─duckdb:::rethrow_error_from_rapi(e, call)
       26.       └─rlang::abort(msg, call = call)
      ── Error ('test-write_rcdf.R:29:3'): write_rcdf creates a valid RCDF file ──────
      Error in `duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)`: Invalid Error: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      i Context: rapi_execute
      i Error type: INVALID
      i Raw message: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      Backtrace:
           ▆
        1. ├─rcdf::write_rcdf(data = mock_data, path = rcdf_path, pub_key = pub_key) at test-write_rcdf.R:29:3
        2. │ └─rcdf::write_rcdf_parquet(...)
        3. │   └─rcdf::write_parquet(...)
        4. │     ├─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        5. │     └─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        6. │       ├─DBI::dbSendStatement(conn, statement, ...)
        7. │       └─DBI::dbSendStatement(conn, statement, ...)
        8. │         ├─DBI::dbSendQuery(conn, statement, ...)
        9. │         └─duckdb::dbSendQuery(conn, statement, ...)
       10. │           └─duckdb (local) .local(conn, statement, ...)
       11. │             └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
       12. │               └─duckdb:::duckdb_execute(res)
       13. │                 └─duckdb:::rethrow_rapi_execute(...)
       14. │                   ├─rlang::try_fetch(...)
       15. │                   │ ├─base::tryCatch(...)
       16. │                   │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       17. │                   │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       18. │                   │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
       19. │                   │ └─base::withCallingHandlers(...)
       20. │                   └─duckdb:::rapi_execute(stmt, convert_opts)
       21. ├─duckdb (local) `<fn>`(...)
       22. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
       23. │   └─rlang:::signal_abort(cnd, .file)
       24. │     └─base::signalCondition(cnd)
       25. └─rlang (local) `<fn>`(`<dckdb_rr>`)
       26.   └─handlers[[1L]](cnd)
       27.     └─duckdb:::rethrow_error_from_rapi(e, call)
       28.       └─rlang::abort(msg, call = call)
      ── Error ('test-write_rcdf.R:62:3'): write_rcdf creates RCDF file with correct encryption ──
      Error in `duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)`: Invalid Error: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      i Context: rapi_execute
      i Error type: INVALID
      i Raw message: Invalid Configuration Error: DuckDB requires a secure random engine to be loaded to enable secure crypto. Normally, this will be handled automatically by DuckDB by autoloading the `httpfs` Extension, but that seems to have failed. Please ensure the httpfs extension is loaded manually using `LOAD httpfs`.
      Backtrace:
           ▆
        1. ├─rcdf::write_rcdf(data = mock_data, path = rcdf_path, pub_key = pub_key) at test-write_rcdf.R:62:3
        2. │ └─rcdf::write_rcdf_parquet(...)
        3. │   └─rcdf::write_parquet(...)
        4. │     ├─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        5. │     └─DBI::dbExecute(conn = pq_conn, statement = pq_query)
        6. │       ├─DBI::dbSendStatement(conn, statement, ...)
        7. │       └─DBI::dbSendStatement(conn, statement, ...)
        8. │         ├─DBI::dbSendQuery(conn, statement, ...)
        9. │         └─duckdb::dbSendQuery(conn, statement, ...)
       10. │           └─duckdb (local) .local(conn, statement, ...)
       11. │             └─duckdb:::duckdb_result(connection = conn, stmt_lst = stmt_lst, arrow = arrow)
       12. │               └─duckdb:::duckdb_execute(res)
       13. │                 └─duckdb:::rethrow_rapi_execute(...)
       14. │                   ├─rlang::try_fetch(...)
       15. │                   │ ├─base::tryCatch(...)
       16. │                   │ │ └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       17. │                   │ │   └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       18. │                   │ │     └─base (local) doTryCatch(return(expr), name, parentenv, handler)
       19. │                   │ └─base::withCallingHandlers(...)
       20. │                   └─duckdb:::rapi_execute(stmt, convert_opts)
       21. ├─duckdb (local) `<fn>`(...)
       22. │ └─rlang::abort(error_parts, class = "duckdb_error", !!!fields)
       23. │   └─rlang:::signal_abort(cnd, .file)
       24. │     └─base::signalCondition(cnd)
       25. └─rlang (local) `<fn>`(`<dckdb_rr>`)
       26.   └─handlers[[1L]](cnd)
       27.     └─duckdb:::rethrow_error_from_rapi(e, call)
       28.       └─rlang::abort(msg, call = call)
      
      [ FAIL 7 | WARN 0 | SKIP 0 | PASS 46 ]
      Error:
      ! Test failures.
      Execution halted
    ```

