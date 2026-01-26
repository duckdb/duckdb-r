# duckspatial

<details>

* Version: 0.2.0
* GitHub: https://github.com/Cidree/duckspatial
* Source code: https://github.com/cran/duckspatial
* Date/Publication: 2025-04-29 18:40:02 UTC
* Number of recursive dependencies: 16

Run `revdepcheck::cloud_details(, "duckspatial")` for more info

</details>

## Newly broken

*   checking examples ... ERROR
    ```
    Running examples in ‘duckspatial-Ex.R’ failed
    The error most likely occurred in:
    
    > ### Name: ddbs_install
    > ### Title: Checks and installs the Spatial extension
    > ### Aliases: ddbs_install
    > 
    > ### ** Examples
    > 
    > ## load packages
    > library(duckdb)
    Loading required package: DBI
    > library(duckspatial)
    > 
    > ## connect to in memory database
    > conn <- dbConnect(duckdb::duckdb())
    > 
    > ## install the spatial exntesion
    > ddbs_install(conn)
    Error: rapi_execute: Invalid Error: HTTP Error: Failed to download extension "spatial" at URL "http://extensions.duckdb.org/a86af889de/linux_amd64/spatial.duckdb_extension.gz" (HTTP 404)
    Extension "spatial" is an existing extension.
    
    For more info, visit https://duckdb.org/docs/stable/extensions/troubleshooting?version=a86af889de&platform=linux_amd64&extension=spatial (error_type: INVALID; : )
    Execution halted
    ```

# motherduck

<details>

* Version: 0.2.0
* GitHub: NA
* Source code: https://github.com/cran/motherduck
* Date/Publication: 2025-12-02 14:40:02 UTC
* Number of recursive dependencies: 76

Run `revdepcheck::cloud_details(, "motherduck")` for more info

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
      > # * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
      > # * https://testthat.r-lib.org/articles/special-files.html
      > 
      > library(testthat)
      > library(motherduck)
      > library(DBI)
      > library(openxlsx)
      > 
      > test_check("motherduck")
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 0
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 0
      * # Tables in this catalog & schema you have access to: 0
      
      -- Action Report: --
      
      v Inserted into existing database "memory"
      v Created new schema "test_schema"
      > Current role: `duckdb`
      
      -- Status: ---------------------------------------------------------------------
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "test_schema"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 0
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 0
      * # Tables in this catalog & schema you have access to: 0
      > Current role: `duckdb`
      > Current role: `duckdb`
      > Current role: `duckdb`
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 1
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 1
      * # Tables in this catalog & schema you have access to: 1
      
      -- Action Report: --
      
      v Inserted into existing database "memory"
      v Using existing schema "main"
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 1
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 1
      * # Tables in this catalog & schema you have access to: 1
      
      -- Action Report: --
      
      v Inserted into existing database "memory"
      v Using existing schema "main"
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 1
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 1
      * # Tables in this catalog & schema you have access to: 1
      
      -- Action Report: --
      
      v Inserted into existing database "memory"
      v Using existing schema "main"
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 3
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 3
      * # Tables in this catalog & schema you have access to: 3
      
      -- Action Report: --
      
      v Inserted into existing database "memory"
      v Using existing schema "main"
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 3
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 3
      * # Tables in this catalog & schema you have access to: 3
      
      -- Action Report: --
      
      v Inserted into existing database "memory"
      v Using existing schema "main"
      Note: method with signature 'DBIConnection#Id' chosen for function 'dbExistsTable',
       target signature 'duckdb_connection#Id'.
       "duckdb_connection#ANY" would also be valid
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 0
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 0
      * # Tables in this catalog & schema you have access to: 0
      
      -- Action Report: 
      * Deleted "delete_table" from "[database_name]" in "main"
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 0
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 0
      * # Tables in this catalog & schema you have access to: 0
      
      -- Action Report: --
      
      v Inserted into existing database "memory"
      v Created new schema "test_schema"
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 1
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 1
      * # Tables in this catalog & schema you have access to: 0
      
      -- Action Report: --
      
      * Deleted "test_schema" schema and 1 tables
      
      -- Status: ---------------------------------------------------------------------
      
      -- Connection Status Report: --
      
      ! You are not connected to MotherDuck
      
      -- User Report: --
      
      * User Name: "duckdb"
      * Role: "duckdb"
      
      -- Catalog Report: --
      
      * Current Database: "memory"
      * Current Schema: "main"
      * # Total Catalogs you have access to: 3
      * # Total Tables you have access to: 0
      * # Total Shares you have access to: 0
      * # Tables in this catalog you have access to: 0
      * # Tables in this catalog & schema you have access to: 0
      
      -- Action Report: --
      
      * Deleted "test_schema" schema and 1 tables
      
      -- Action Report: --
      
      v Inserted into existing database "memory"
      v Using existing schema "main"
      v Overwrite existing table "mtcars_csv"
      Saving _problems/test-motherduck-405.R
      [ FAIL 1 | WARN 0 | SKIP 1 | PASS 22 ]
      
      ══ Skipped tests (1) ═══════════════════════════════════════════════════════════
      • empty test (1): 'test-motherduck.R:259:3'
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Error ('test-motherduck.R:405:7'): read_excel / successfully reads a excel and copies table to database ──
      <purrr_error_indexed/rlang_error/error/condition>
      Error in `purrr::map(ext_lst$valid_ext, function(x) DBI::dbExecute(.con, glue::glue("INSTALL {x};")))`: i In index: 1.
      Caused by error in `duckdb_result()`:
      ! Invalid Error: HTTP Error: Failed to download extension "excel" at URL "http://extensions.duckdb.org/a86af889de/linux_amd64/excel.duckdb_extension.gz" (HTTP 404)
      Extension "excel" is an existing extension.
      
      For more info, visit https://duckdb.org/docs/stable/extensions/troubleshooting?version=a86af889de&platform=linux_amd64&extension=excel
      i Context: rapi_execute
      i Error type: INVALID
      
      [ FAIL 1 | WARN 0 | SKIP 1 | PASS 22 ]
      Error:
      ! Test failures.
      Execution halted
    ```

## In both

*   checking data for non-ASCII characters ... NOTE
    ```
      Note: found 2 marked UTF-8 strings
    ```

