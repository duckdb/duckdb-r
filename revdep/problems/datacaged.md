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

