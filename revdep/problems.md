# CodelistGenerator

<details>

* Version: 1.7.0
* GitHub: NA
* Source code: https://github.com/cran/CodelistGenerator
* Date/Publication: 2023-08-16 08:42:32 UTC
* Number of recursive dependencies: 117

Run `revdepcheck::cloud_details(, "CodelistGenerator")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      • Sys.getenv("CDM5_REDSHIFT_DBNAME") == "" is TRUE (2):
        'test-codesFrom.R:95:3', 'test-summariseCodeUse.R:3:3'
      • Sys.getenv("darwinDbDatabaseServer") == "" is TRUE (1):
        'test-synthea_sql_server.R:2:3'
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test-vocabUtilities.R:34:5'): tests with mock db ──────────────────
      all(descendants1$concept_id == c(1, 2, 3, 4, 5)) is not TRUE
      
      `actual`:   FALSE
      `expected`: TRUE 
      
      [ FAIL 1 | WARN 4 | SKIP 3 | PASS 144 ]
      Error: Test failures
      Execution halted
    ```

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
    Last 13 lines of output:
      • draw-dm/nycflight-dm.svg
      • draw-dm/single-empty-table-dm.svg
      • draw-dm/table-desc-1-dm.svg
      • draw-dm/table-desc-2-dm.svg
      • draw-dm/table-desc-3-dm.svg
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
    Last 13 lines of output:
      result$n_records (`actual`) not equal to c(4, 2, 1, 3, 1, 1) (`expected`).
      
        `actual`: 4 1 1 2 1 3
      `expected`: 4 2 1 3 1 1
      ── Failure ('test-IngredientOverview.R:75:3'): getIngredientsPresence ──────────
      result$n_people (`actual`) not equal to c(2, 1, 1, 2, 1, 1) (`expected`).
      
        `actual`: 2 1 1 1 1 2
      `expected`: 2 1 1 2 1 1
      
      [ FAIL 8 | WARN 22 | SKIP 1 | PASS 285 ]
      Error: Test failures
      In addition: There were 32 warnings (use warnings() to see them)
      Execution halted
      There were 20 warnings (use warnings() to see them)
    ```

# DrugUtilisation

<details>

* Version: 0.3.3
* GitHub: NA
* Source code: https://github.com/cran/DrugUtilisation
* Date/Publication: 2023-09-25 21:40:02 UTC
* Number of recursive dependencies: 136

Run `revdepcheck::cloud_details(, "DrugUtilisation")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
        'test-indication.R:314:3', 'test-indication.R:422:3'
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test-indication.R:153:3'): test case single indication ────────────
      identical(...) is not TRUE
      
      `actual`:   FALSE
      `expected`: TRUE 
      
      [ FAIL 1 | WARN 1 | SKIP 14 | PASS 202 ]
      Error: Test failures
      Execution halted
      Warning messages:
      1: Connection is garbage-collected, use dbDisconnect() to avoid this. 
      2: Database is garbage-collected, use dbDisconnect(con, shutdown=TRUE) or duckdb::duckdb_shutdown(drv) to avoid this. 
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
    Last 13 lines of output:
      In addition: Warning messages:
      1: In normalizePath(tools::R_user_dir("R.cache", which = "cache")) :
        path[1]="/root/.cache/R/R.cache": No such file or directory
      2: In normalizePath(tools::R_user_dir("R.cache", which = "cache")) :
        path[1]="/root/.cache/R/R.cache": No such file or directory
      3: In normalizePath(tools::R_user_dir("R.cache", which = "cache")) :
        path[1]="/root/.cache/R/R.cache": No such file or directory
      
      🛠: 883
      🔨: 544
      🦆: 339
      add_count, anti_join, arrange, compute, count, cross_join, distinct, do, eval, filter, full_join, inner_join, intersect, left_join, mutate, mutate.data.frame, nest_join, pull, reframe, relocate, rename, rename_with, right_join, rows_append, rows_delete, rows_insert, rows_patch, rows_update, rows_upsert, select, semi_join, setdiff, setequal, slice, slice_head, slice_tail, summarise, symdiff, transmute, ungroup, union_all
      
      00:00:54.157797
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
    Last 13 lines of output:
                              - 3.2                  [15]          
                              - 3.1                  [16]          
                              - 2.9                  [17]          
                              - 3.7                  [18]          
                              - 4.0                  [19]          
                              - 2.3                  [20]          
       ... ...                  ...                  and 3 more ...
      
        `actual$..row_id`: 1 3 6 10 11 12 15 16 17 18 and 140 more...
      `expected$..row_id`: 2 4 5  7  8  9 13 14 20 21             ...
      
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
    Last 13 lines of output:
      ══ Skipped tests (2) ═══════════════════════════════════════════════════════════
      • On CRAN (1): 'test-db-tools.R:138:3'
      • On Linux (1): 'test-db-tools.R:79:3'
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Failure ('test-status-tools.R:16:3'): restez_status() works ─────────────────
      as.character(status_obj$Database$`Total size`) not equal to "1.01M".
      1/1 mismatches
      x[1]: "780K"
      y[1]: "1.01M"
      
      [ FAIL 1 | WARN 0 | SKIP 2 | PASS 138 ]
      Error: Test failures
      In addition: There were 50 or more warnings (use warnings() to see the first 50)
      Execution halted
    ```

