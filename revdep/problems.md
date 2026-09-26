# datacaged (0.2.1)

* GitHub: <https://github.com/gecomt/datacaged>
* Email: <mailto:alexsandro.prado@ufersa.edu.br>
* GitHub mirror: <https://github.com/cran/datacaged>

Run `revdepcheck::revdep_details(, "datacaged")` for more info

## Newly broken

*   checking tests ... ERROR
     ```
     ...
        3. └─datacaged::caged_load(...)
        4.   └─datacaged::caged_info(db_path)
        5.     └─datacaged::caged_connect(db_path, read_only = TRUE, quiet = TRUE)
        6.       └─duckdb::duckdb(dbdir = db_path, read_only = read_only)
        7.         └─duckdb:::warn_instance_settings_ignored(...)
        8.           └─rlang::abort(...)
       ── Error ('test-pipelines.R:216:3'): caged_adjustments_load() cria banco com tabela caged_ajustes ──
       Error in `duckdb::duckdb(dbdir = db_path, read_only = read_only)`: `read_only` can't be applied to the database instance for `/tmp/RtmpLS2fZM/working_dir/RtmpyHcdxR/caged_adj_mock_31119a606bc.duckdb`, which already exists.
       * These settings take effect only when the instance is created.
       * Release it with `duckdb_shutdown()` first, or pass them to the `duckdb()` call that creates it.
       Backtrace:
           ▆
        1. ├─base::suppressMessages(...) at test-pipelines.R:216:3
        2. │ └─base::withCallingHandlers(...)
        3. └─datacaged::caged_adjustments_load(...)
        4.   └─datacaged::caged_info(db_path)
        5.     └─datacaged::caged_connect(db_path, read_only = TRUE, quiet = TRUE)
        6.       └─duckdb::duckdb(dbdir = db_path, read_only = read_only)
        7.         └─duckdb:::warn_instance_settings_ignored(...)
        8.           └─rlang::abort(...)
       
       [ FAIL 2 | WARN 0 | SKIP 5 | PASS 187 ]
       Error:
       ! Test failures.
       Execution halted
     ```

# Rduckhts (1.5.1-0.1.3)

* GitHub: <https://github.com/RGenomicsETL/duckhts>
* Email: <mailto:sounkoutoure@gmail.com>
* GitHub mirror: <https://github.com/cran/Rduckhts>

Run `revdepcheck::revdep_details(, "Rduckhts")` for more info

## Newly broken

*   checking tests ... ERROR
     ```
     ...
       MATCH: MAP -> data.frame
       MATCH: MAP -> data.frame
       MATCH: MAP -> data.frame
       
       test_type_mappings.R..........    0 tests    Testing type mapping function assertions...
       Type mapping function assertions passed!
       
       test_type_mappings.R..........   13 tests OK Type mapping test completed! Check output above for effective type mappings.
       
       test_type_mappings.R..........   13 tests OK 79ms
       
       test_variantkey_regionkey.R...    0 tests    
       test_variantkey_regionkey.R...    0 tests    
       test_variantkey_regionkey.R...    0 tests    
       test_variantkey_regionkey.R...   48 tests OK 0.1s
       ----- FAILED[xcpt]: test_connection.R<143--143>
        call| test_reused_file_driver_rejected()
        call| -->expect_error(rduckhts_connect(dbdir = dbdir), "already has a live instance")
        diff| The error message:
        diff| '`shared_home`, `allow_extensions`, `config$allow_unsigned_extensions`, `config$autoinstall_known_extensions`, `config$autoload_known_extensions` can't be applied to the database instance for `/tmp/RtmpxbiFmy/working_dir/Rtmpw2lEhh/rduckhts_reused_c3631f8b8f6.duckdb`, which already exists.
        diff| These settings take effect only when the instance is created.
        diff| Release it with `duckdb_shutdown()` first, or pass them to the `duckdb()` call that creates it.'
        diff| does not match pattern 'already has a live instance'
       Error: 1 out of 2078 tests failed
       Execution halted
     ```

