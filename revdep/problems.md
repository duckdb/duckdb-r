# GeoTox (1.0.0)

* GitHub: <https://github.com/NIEHS/GeoTox>
* Email: <mailto:skylar.marvel@nih.gov>
* GitHub mirror: <https://github.com/cran/GeoTox>

Run `revdepcheck::cloud_details(, "GeoTox")` for more info

## Newly broken

*   checking tests ... ERROR
     ```
     ...
       i Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
       i Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
       i See ?duckdb_storage for details and alternatives.
       Saving _problems/test-calc_sensitivity-84.R
       The duckplyr package is configured to fall back to dplyr when it encounters an incompatibility. Fallback events can be collected and uploaded for analysis to guide future development. By default, data will be collected but no data will be uploaded.
       i Automatic fallback uploading is not controlled and therefore disabled, see `?duckplyr::fallback()`.
       v Number of reports ready for upload: 3.
       > Review with `duckplyr::fallback_review()`, upload with `duckplyr::fallback_upload()`.
       i Configure automatic uploading with `duckplyr::fallback_config()`.
       [ FAIL 1 | WARN 0 | SKIP 6 | PASS 224 ]
       
       ══ Skipped tests (6) ═══════════════════════════════════════════════════════════
       • On CRAN (6): 'test-calc_response.R:1:1', 'test-calc_response.R:61:1',
         'test-calc_risk.R:125:1', 'test-calc_sensitivity.R:26:1',
         'test-calc_sensitivity.R:102:1', 'test-sensitivity_analysis.R:1:1'
       
       ══ Failed tests ════════════════════════════════════════════════════════════════
       ── Failure ('test-calc_sensitivity.R:82:3'): calc sensitivity ──────────────────
       Expected `calc_sensitivity(GT)` to run silently.
       Actual noise: messages.
       
       [ FAIL 1 | WARN 0 | SKIP 6 | PASS 224 ]
       Error:
       ! Test failures.
       Execution halted
     ```

