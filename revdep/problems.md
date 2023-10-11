# dm

<details>

* Version: 1.0.6
* GitHub: https://github.com/cynkra/dm
* Source code: https://github.com/cran/dm
* Date/Publication: 2023-07-21 13:30:02 UTC
* Number of recursive dependencies: 137

Run `revdepcheck::cloud_details(, "dm")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > 
      > # Need to use qualified call, this is checked in helper-print.R
      > testthat::test_check("dm")
      Loading required package: dm
      
      Attaching package: 'dm'
    ...
      • draw-dm/table-desc-4-dm.svg
      • draw-dm/table-uk-1-dm.svg
      • draw-dm/table-uk-2-dm.svg
      • duckdb/meta/columns.csv
      • maria/meta/columns.csv
      • mssql/meta/columns.csv
      • postgres/meta/columns.csv
      • sqlite/meta/columns.csv
      Error: Test failures
      Execution halted
    ```

# DrugExposureDiagnostics

<details>

* Version: 0.4.6
* GitHub: NA
* Source code: https://github.com/cran/DrugExposureDiagnostics
* Date/Publication: 2023-08-16 14:34:35 UTC
* Number of recursive dependencies: 132

Run `revdepcheck::cloud_details(, "DrugExposureDiagnostics")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > library(testthat)
      > library(DrugExposureDiagnostics)
      > 
      > test_check("DrugExposureDiagnostics")
      trying URL 'https://example-data.ohdsi.dev/GiBleed.zip'
      Content type 'application/zip' length 6754786 bytes (6.4 MB)
      ==================================================
    ...
      Warning messages:
      1: Connection is garbage-collected, use dbDisconnect() to avoid this. 
      2: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
      3: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
      4: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
      5: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
      6: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
      7: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
      8: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
      9: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
    ```

# duckplyr

<details>

* Version: 0.2.1
* GitHub: https://github.com/duckdblabs/duckplyr
* Source code: https://github.com/cran/duckplyr
* Date/Publication: 2023-09-17 11:20:03 UTC
* Number of recursive dependencies: 91

Run `revdepcheck::cloud_details(, "duckplyr")` for more info

</details>

## Newly broken

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
      > # * https://r-pkgs.org/tests.html
      > # * https://testthat.r-lib.org/reference/test_package.html#special-files
    ...
      3: In normalizePath(tools::R_user_dir("R.cache", which = "cache")) :
        path[1]="/root/.cache/R/R.cache": No such file or directory
      
      🛠: 883
      🔨: 544
      🦆: 339
      add_count, anti_join, arrange, compute, count, cross_join, distinct, do, eval, filter, full_join, inner_join, intersect, left_join, mutate, mutate.data.frame, nest_join, pull, reframe, relocate, rename, rename_with, right_join, rows_append, rows_delete, rows_insert, rows_patch, rows_update, rows_upsert, select, semi_join, setdiff, setequal, slice, slice_head, slice_tail, summarise, symdiff, transmute, ungroup, union_all
      
      00:00:49.658042
      Execution halted
    ```

# mlr3db

<details>

* Version: 0.5.0
* GitHub: https://github.com/mlr-org/mlr3db
* Source code: https://github.com/cran/mlr3db
* Date/Publication: 2022-08-08 10:10:02 UTC
* Number of recursive dependencies: 71

Run `revdepcheck::cloud_details(, "mlr3db")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > if (requireNamespace("testthat", quietly = TRUE)) {
      +   library("testthat")
      +   library("mlr3db")
      +   test_check("mlr3db")
      + }
      Loading required package: mlr3
      Loading required package: RSQLite
    ...
      [20] 0.3                | 0.3                  [20]          
       ... ...                  ...                  and 1 more ...
      
      `actual$Species`:   "setosa" "virginica"  "versicolor"
      `expected$Species`: "setosa" "versicolor" "virginica" 
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 1416 ]
      Error: Test failures
      In addition: There were 27 warnings (use warnings() to see them)
      Execution halted
    ```

# restez

<details>

* Version: 2.1.3
* GitHub: https://github.com/ropensci/restez
* Source code: https://github.com/cran/restez
* Date/Publication: 2022-11-11 07:20:10 UTC
* Number of recursive dependencies: 71

Run `revdepcheck::cloud_details(, "restez")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘test-all.R’
    Running the tests in ‘tests/test-all.R’ failed.
    Complete output:
      > library(testthat)
      > test_check("restez")
      Loading required package: restez
      ... Creating 'test_db_fldr/restez'
      ... Creating 'test_db_fldr/restez/downloads'
      ... Creating 'test_db_fldr/restez'
      ... Creating 'test_db_fldr/restez/downloads'
    ...
      1/1 mismatches
      x[1]: "780K"
      y[1]: "1.01M"
      
      [ FAIL 1 | WARN 0 | SKIP 2 | PASS 138 ]
      Error: Test failures
      In addition: There were 50 or more warnings (use warnings() to see the first 50)
      Execution halted
      Warning message:
      Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
    ```

