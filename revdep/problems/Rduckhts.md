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

