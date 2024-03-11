# PatientProfiles

<details>

* Version: 0.6.2
* GitHub: NA
* Source code: https://github.com/cran/PatientProfiles
* Date/Publication: 2024-03-05 18:50:03 UTC
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
      > # * https://testthat.r-lib.org/reference/test_package.html#special-files
      > 
      > library(testthat)
      > library(PatientProfiles)
      > 
      > test_check("PatientProfiles")
      Starting 2 test processes
      [ FAIL 8 | WARN 38 | SKIP 1 | PASS 644 ]
      
      ══ Skipped tests (1) ═══════════════════════════════════════════════════════════
      • empty test (1): 'test-summariseResult.R:209:1'
      
      ══ Failed tests ════════════════════════════════════════════════════════════════
      ── Error ('test-addFutureObservation.R:126:3'): check working example with condition_occurrence ──
      Error in `dplyr::collect(removeClass(x, "cdm_table"))`: Failed to collect lazy table.
      Caused by error:
      ! rapi_prepare: Failed to prepare query SELECT cohort1.*
      FROM main.cohort1
      WHERE NOT EXISTS (
        SELECT 1 FROM (
        SELECT cohort1.*, observation_period_start_date, observation_period_end_date
        FROM main.cohort1
        LEFT JOIN main.observation_period
          ON (cohort1.subject_id = observation_period.person_id)
      ) RHS
        WHERE
          (cohort1.cohort_definition_id = RHS.cohort_definition_id) AND
          (cohort1.subject_id = RHS.subject_id) AND
          (cohort1.cohort_start_date = RHS.cohort_start_date) AND
          (cohort1.cohort_end_date = RHS.cohort_end_date) AND
          (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )
      Error: Binder Error: Cannot compare values of type VARCHAR and type DATE - an explicit cast is required
      LINE 15:     (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )...
                                          ^
      Backtrace:
           ▆
        1. └─PatientProfiles::mockPatientProfiles(...) at test-addFutureObservation.R:126:3
        2.   └─omopgenerics::newCohortTable(cdm[[cohort]])
        3.     └─omopgenerics:::validateGeneratedCohortSet(cohort, soft = .softValidation)
        4.       └─omopgenerics::checkCohortRequirements(...)
        5.         └─omopgenerics:::checkObservationPeriod(...)
        6.           ├─dplyr::collect(...)
        7.           └─omopgenerics:::collect.cohort_table(...)
        8.             ├─dplyr::collect(x)
        9.             └─omopgenerics:::collect.cdm_table(x)
       10.               ├─dplyr::collect(removeClass(x, "cdm_table"))
       11.               └─dbplyr:::collect.tbl_sql(removeClass(x, "cdm_table"))
       12.                 └─base::tryCatch(...)
       13.                   └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       14.                     └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       15.                       └─value[[3L]](cond)
       16.                         └─cli::cli_abort("Failed to collect lazy table.", parent = cnd)
       17.                           └─rlang::abort(...)
      ── Error ('test-addFutureObservation.R:198:3'): different name ─────────────────
      Error in `dplyr::collect(removeClass(x, "cdm_table"))`: Failed to collect lazy table.
      Caused by error:
      ! rapi_prepare: Failed to prepare query SELECT cohort1.*
      FROM main.cohort1
      WHERE NOT EXISTS (
        SELECT 1 FROM (
        SELECT cohort1.*, observation_period_start_date, observation_period_end_date
        FROM main.cohort1
        LEFT JOIN main.observation_period
          ON (cohort1.subject_id = observation_period.person_id)
      ) RHS
        WHERE
          (cohort1.cohort_definition_id = RHS.cohort_definition_id) AND
          (cohort1.subject_id = RHS.subject_id) AND
          (cohort1.cohort_start_date = RHS.cohort_start_date) AND
          (cohort1.cohort_end_date = RHS.cohort_end_date) AND
          (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )
      Error: Binder Error: Cannot compare values of type VARCHAR and type DATE - an explicit cast is required
      LINE 15:     (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )...
                                          ^
      Backtrace:
           ▆
        1. └─PatientProfiles::mockPatientProfiles(...) at test-addFutureObservation.R:198:3
        2.   └─omopgenerics::newCohortTable(cdm[[cohort]])
        3.     └─omopgenerics:::validateGeneratedCohortSet(cohort, soft = .softValidation)
        4.       └─omopgenerics::checkCohortRequirements(...)
        5.         └─omopgenerics:::checkObservationPeriod(...)
        6.           ├─dplyr::collect(...)
        7.           └─omopgenerics:::collect.cohort_table(...)
        8.             ├─dplyr::collect(x)
        9.             └─omopgenerics:::collect.cdm_table(x)
       10.               ├─dplyr::collect(removeClass(x, "cdm_table"))
       11.               └─dbplyr:::collect.tbl_sql(removeClass(x, "cdm_table"))
       12.                 └─base::tryCatch(...)
       13.                   └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       14.                     └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       15.                       └─value[[3L]](cond)
       16.                         └─cli::cli_abort("Failed to collect lazy table.", parent = cnd)
       17.                           └─rlang::abort(...)
      ── Error ('test-addFutureObservation.R:251:3'): priorHistory and future_observation - outside of observation period ──
      Error in `dplyr::collect(removeClass(x, "cdm_table"))`: Failed to collect lazy table.
      Caused by error:
      ! rapi_prepare: Failed to prepare query SELECT cohort1.*
      FROM main.cohort1
      WHERE NOT EXISTS (
        SELECT 1 FROM (
        SELECT cohort1.*, observation_period_start_date, observation_period_end_date
        FROM main.cohort1
        LEFT JOIN main.observation_period
          ON (cohort1.subject_id = observation_period.person_id)
      ) RHS
        WHERE
          (cohort1.cohort_definition_id = RHS.cohort_definition_id) AND
          (cohort1.subject_id = RHS.subject_id) AND
          (cohort1.cohort_start_date = RHS.cohort_start_date) AND
          (cohort1.cohort_end_date = RHS.cohort_end_date) AND
          (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )
      Error: Binder Error: Cannot compare values of type VARCHAR and type DATE - an explicit cast is required
      LINE 15:     (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )...
                                          ^
      Backtrace:
           ▆
        1. └─PatientProfiles::mockPatientProfiles(...) at test-addFutureObservation.R:251:3
        2.   └─omopgenerics::newCohortTable(cdm[[cohort]])
        3.     └─omopgenerics:::validateGeneratedCohortSet(cohort, soft = .softValidation)
        4.       └─omopgenerics::checkCohortRequirements(...)
        5.         └─omopgenerics:::checkObservationPeriod(...)
        6.           ├─dplyr::collect(...)
        7.           └─omopgenerics:::collect.cohort_table(...)
        8.             ├─dplyr::collect(x)
        9.             └─omopgenerics:::collect.cdm_table(x)
       10.               ├─dplyr::collect(removeClass(x, "cdm_table"))
       11.               └─dbplyr:::collect.tbl_sql(removeClass(x, "cdm_table"))
       12.                 └─base::tryCatch(...)
       13.                   └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       14.                     └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       15.                       └─value[[3L]](cond)
       16.                         └─cli::cli_abort("Failed to collect lazy table.", parent = cnd)
       17.                           └─rlang::abort(...)
      ── Error ('test-addFutureObservation.R:301:3'): multiple observation periods ───
      Error in `dplyr::collect(removeClass(x, "cdm_table"))`: Failed to collect lazy table.
      Caused by error:
      ! rapi_prepare: Failed to prepare query SELECT cohort2.*
      FROM main.cohort2
      WHERE NOT EXISTS (
        SELECT 1 FROM (
        SELECT cohort2.*, observation_period_start_date, observation_period_end_date
        FROM main.cohort2
        LEFT JOIN main.observation_period
          ON (cohort2.subject_id = observation_period.person_id)
      ) RHS
        WHERE
          (cohort2.cohort_definition_id = RHS.cohort_definition_id) AND
          (cohort2.subject_id = RHS.subject_id) AND
          (cohort2.cohort_start_date = RHS.cohort_start_date) AND
          (cohort2.cohort_end_date = RHS.cohort_end_date) AND
          (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )
      Error: Binder Error: Cannot compare values of type VARCHAR and type DATE - an explicit cast is required
      LINE 15:     (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )...
                                          ^
      Backtrace:
           ▆
        1. └─PatientProfiles::mockPatientProfiles(...) at test-addFutureObservation.R:301:3
        2.   └─omopgenerics::newCohortTable(cdm[[cohort]])
        3.     └─omopgenerics:::validateGeneratedCohortSet(cohort, soft = .softValidation)
        4.       └─omopgenerics::checkCohortRequirements(...)
        5.         └─omopgenerics:::checkObservationPeriod(...)
        6.           ├─dplyr::collect(...)
        7.           └─omopgenerics:::collect.cohort_table(...)
        8.             ├─dplyr::collect(x)
        9.             └─omopgenerics:::collect.cdm_table(x)
       10.               ├─dplyr::collect(removeClass(x, "cdm_table"))
       11.               └─dbplyr:::collect.tbl_sql(removeClass(x, "cdm_table"))
       12.                 └─base::tryCatch(...)
       13.                   └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       14.                     └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       15.                       └─value[[3L]](cond)
       16.                         └─cli::cli_abort("Failed to collect lazy table.", parent = cnd)
       17.                           └─rlang::abort(...)
      ── Error ('test-addPriorObservation.R:106:3'): check working example with condition_occurrence ──
      Error in `dplyr::collect(removeClass(x, "cdm_table"))`: Failed to collect lazy table.
      Caused by error:
      ! rapi_prepare: Failed to prepare query SELECT cohort1.*
      FROM main.cohort1
      WHERE NOT EXISTS (
        SELECT 1 FROM (
        SELECT cohort1.*, observation_period_start_date, observation_period_end_date
        FROM main.cohort1
        LEFT JOIN main.observation_period
          ON (cohort1.subject_id = observation_period.person_id)
      ) RHS
        WHERE
          (cohort1.cohort_definition_id = RHS.cohort_definition_id) AND
          (cohort1.subject_id = RHS.subject_id) AND
          (cohort1.cohort_start_date = RHS.cohort_start_date) AND
          (cohort1.cohort_end_date = RHS.cohort_end_date) AND
          (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )
      Error: Binder Error: Cannot compare values of type VARCHAR and type DATE - an explicit cast is required
      LINE 15:     (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )...
                                          ^
      Backtrace:
           ▆
        1. └─PatientProfiles::mockPatientProfiles(...) at test-addPriorObservation.R:106:3
        2.   └─omopgenerics::newCohortTable(cdm[[cohort]])
        3.     └─omopgenerics:::validateGeneratedCohortSet(cohort, soft = .softValidation)
        4.       └─omopgenerics::checkCohortRequirements(...)
        5.         └─omopgenerics:::checkObservationPeriod(...)
        6.           ├─dplyr::collect(...)
        7.           └─omopgenerics:::collect.cohort_table(...)
        8.             ├─dplyr::collect(x)
        9.             └─omopgenerics:::collect.cdm_table(x)
       10.               ├─dplyr::collect(removeClass(x, "cdm_table"))
       11.               └─dbplyr:::collect.tbl_sql(removeClass(x, "cdm_table"))
       12.                 └─base::tryCatch(...)
       13.                   └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       14.                     └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       15.                       └─value[[3L]](cond)
       16.                         └─cli::cli_abort("Failed to collect lazy table.", parent = cnd)
       17.                           └─rlang::abort(...)
      ── Error ('test-addPriorObservation.R:158:3'): different name ──────────────────
      Error in `dplyr::collect(removeClass(x, "cdm_table"))`: Failed to collect lazy table.
      Caused by error:
      ! rapi_prepare: Failed to prepare query SELECT cohort1.*
      FROM main.cohort1
      WHERE NOT EXISTS (
        SELECT 1 FROM (
        SELECT cohort1.*, observation_period_start_date, observation_period_end_date
        FROM main.cohort1
        LEFT JOIN main.observation_period
          ON (cohort1.subject_id = observation_period.person_id)
      ) RHS
        WHERE
          (cohort1.cohort_definition_id = RHS.cohort_definition_id) AND
          (cohort1.subject_id = RHS.subject_id) AND
          (cohort1.cohort_start_date = RHS.cohort_start_date) AND
          (cohort1.cohort_end_date = RHS.cohort_end_date) AND
          (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )
      Error: Binder Error: Cannot compare values of type VARCHAR and type DATE - an explicit cast is required
      LINE 15:     (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )...
                                          ^
      Backtrace:
           ▆
        1. └─PatientProfiles::mockPatientProfiles(...) at test-addPriorObservation.R:158:3
        2.   └─omopgenerics::newCohortTable(cdm[[cohort]])
        3.     └─omopgenerics:::validateGeneratedCohortSet(cohort, soft = .softValidation)
        4.       └─omopgenerics::checkCohortRequirements(...)
        5.         └─omopgenerics:::checkObservationPeriod(...)
        6.           ├─dplyr::collect(...)
        7.           └─omopgenerics:::collect.cohort_table(...)
        8.             ├─dplyr::collect(x)
        9.             └─omopgenerics:::collect.cdm_table(x)
       10.               ├─dplyr::collect(removeClass(x, "cdm_table"))
       11.               └─dbplyr:::collect.tbl_sql(removeClass(x, "cdm_table"))
       12.                 └─base::tryCatch(...)
       13.                   └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       14.                     └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       15.                       └─value[[3L]](cond)
       16.                         └─cli::cli_abort("Failed to collect lazy table.", parent = cnd)
       17.                           └─rlang::abort(...)
      ── Error ('test-addPriorObservation.R:209:3'): multiple observation periods ────
      Error in `dplyr::collect(removeClass(x, "cdm_table"))`: Failed to collect lazy table.
      Caused by error:
      ! rapi_prepare: Failed to prepare query SELECT cohort2.*
      FROM main.cohort2
      WHERE NOT EXISTS (
        SELECT 1 FROM (
        SELECT cohort2.*, observation_period_start_date, observation_period_end_date
        FROM main.cohort2
        LEFT JOIN main.observation_period
          ON (cohort2.subject_id = observation_period.person_id)
      ) RHS
        WHERE
          (cohort2.cohort_definition_id = RHS.cohort_definition_id) AND
          (cohort2.subject_id = RHS.subject_id) AND
          (cohort2.cohort_start_date = RHS.cohort_start_date) AND
          (cohort2.cohort_end_date = RHS.cohort_end_date) AND
          (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )
      Error: Binder Error: Cannot compare values of type VARCHAR and type DATE - an explicit cast is required
      LINE 15:     (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )...
                                          ^
      Backtrace:
           ▆
        1. └─PatientProfiles::mockPatientProfiles(...) at test-addPriorObservation.R:209:3
        2.   └─omopgenerics::newCohortTable(cdm[[cohort]])
        3.     └─omopgenerics:::validateGeneratedCohortSet(cohort, soft = .softValidation)
        4.       └─omopgenerics::checkCohortRequirements(...)
        5.         └─omopgenerics:::checkObservationPeriod(...)
        6.           ├─dplyr::collect(...)
        7.           └─omopgenerics:::collect.cohort_table(...)
        8.             ├─dplyr::collect(x)
        9.             └─omopgenerics:::collect.cdm_table(x)
       10.               ├─dplyr::collect(removeClass(x, "cdm_table"))
       11.               └─dbplyr:::collect.tbl_sql(removeClass(x, "cdm_table"))
       12.                 └─base::tryCatch(...)
       13.                   └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       14.                     └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       15.                       └─value[[3L]](cond)
       16.                         └─cli::cli_abort("Failed to collect lazy table.", parent = cnd)
       17.                           └─rlang::abort(...)
      ── Error ('test-summariseCharacteristics.R:51:3'): test summariseCharacteristics ──
      Error in `dplyr::collect(removeClass(x, "cdm_table"))`: Failed to collect lazy table.
      Caused by error:
      ! rapi_prepare: Failed to prepare query SELECT cohort1.*
      FROM main.cohort1
      WHERE NOT EXISTS (
        SELECT 1 FROM (
        SELECT cohort1.*, observation_period_start_date, observation_period_end_date
        FROM main.cohort1
        LEFT JOIN main.observation_period
          ON (cohort1.subject_id = observation_period.person_id)
      ) RHS
        WHERE
          (cohort1.cohort_definition_id = RHS.cohort_definition_id) AND
          (cohort1.subject_id = RHS.subject_id) AND
          (cohort1.cohort_start_date = RHS.cohort_start_date) AND
          (cohort1.cohort_end_date = RHS.cohort_end_date) AND
          (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )
      Error: Binder Error: Cannot compare values of type VARCHAR and type DATE - an explicit cast is required
      LINE 15:     (RHS.cohort_start_date >= RHS.observation_period_start_date AND RHS.cohort_start_date <= RHS.observation_period_end_date AND RHS.cohort_end_date >= RHS.observation_period_start_date AND RHS.cohort_end_date <= RHS.observation_period_end_date)
      )...
                                          ^
      Backtrace:
           ▆
        1. └─PatientProfiles::mockPatientProfiles(...) at test-summariseCharacteristics.R:51:3
        2.   └─omopgenerics::newCohortTable(cdm[[cohort]])
        3.     └─omopgenerics:::validateGeneratedCohortSet(cohort, soft = .softValidation)
        4.       └─omopgenerics::checkCohortRequirements(...)
        5.         └─omopgenerics:::checkObservationPeriod(...)
        6.           ├─dplyr::collect(...)
        7.           └─omopgenerics:::collect.cohort_table(...)
        8.             ├─dplyr::collect(x)
        9.             └─omopgenerics:::collect.cdm_table(x)
       10.               ├─dplyr::collect(removeClass(x, "cdm_table"))
       11.               └─dbplyr:::collect.tbl_sql(removeClass(x, "cdm_table"))
       12.                 └─base::tryCatch(...)
       13.                   └─base (local) tryCatchList(expr, classes, parentenv, handlers)
       14.                     └─base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
       15.                       └─value[[3L]](cond)
       16.                         └─cli::cli_abort("Failed to collect lazy table.", parent = cnd)
       17.                           └─rlang::abort(...)
      
      [ FAIL 8 | WARN 38 | SKIP 1 | PASS 644 ]
      Error: Test failures
      Execution halted
    ```

