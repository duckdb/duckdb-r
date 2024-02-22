# PatientProfiles

<details>

* Version: 0.6.1
* GitHub: NA
* Source code: https://github.com/cran/PatientProfiles
* Date/Publication: 2024-02-21 23:30:07 UTC
* Number of recursive dependencies: 174

Run `revdepcheck::cloud_details(, "PatientProfiles")` for more info

</details>

## Newly broken

*   checking tests ... ERROR
    ```
      Running ‘spelling.R’
      Running ‘testthat.R’
    Running the tests in ‘tests/testthat.R’ failed.
    Complete output:
      > # This file is part of the standard setup for testthat.
      > # It is recommended that you do not modify it.
      > #
      > # Where should you do additional test configuration?
      > # Learn more about the roles of various files in:
      > # * https://r-pkgs.org/tests.html
    ...
      `expected`: TRUE 
      ── Failure ('test-addCategories.R:25:3'): addCategories, functionality ─────────
      all(...) is not TRUE
      
      `actual`:   FALSE
      `expected`: TRUE 
      
      [ FAIL 2 | WARN 1 | SKIP 1 | PASS 666 ]
      Error: Test failures
      Execution halted
    ```

