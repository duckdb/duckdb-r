# starwarsdb

<details>

* Version: 0.1.2
* GitHub: https://github.com/gadenbuie/starwarsdb
* Source code: https://github.com/cran/starwarsdb
* Date/Publication: 2020-11-02 23:50:02 UTC
* Number of recursive dependencies: 51

Run `revdepcheck::cloud_details(, "starwarsdb")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(starwarsdb)
      > 
      > test_check("starwarsdb")
      [ FAIL 1 | WARN 1 | SKIP 0 | PASS 32 ]
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test-connect.R:3:3'): connects and disconnects to duckdb in memory ──
      con@driver@dbdir not equal to ":memory:".
      1/1 mismatches
      x[1]: ""
      y[1]: ":memory:"
      
      [ FAIL 1 | WARN 1 | SKIP 0 | PASS 32 ]
      Error: Test failures
      In addition: Warning messages:
      1: Database is garbage-collected, use dbConnect(duckdb()) with dbDisconnect(), or duckdb::duckdb_shutdown(drv) to avoid this. 
      2: Database is garbage-collected, use dbConnect(duckdb()) with dbDisconnect(), or duckdb::duckdb_shutdown(drv) to avoid this. 
      3: Database is garbage-collected, use dbConnect(duckdb()) with dbDisconnect(), or duckdb::duckdb_shutdown(drv) to avoid this. 
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 14 marked UTF-8 strings
    ```

