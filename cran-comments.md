Resubmission.

duckdb 0.10.2

## R CMD check results

- [x] Checked locally, R 4.3.2
- [x] Checked on CI system, R 4.4.0
- [x] Checked on win-builder, R devel

## Current CRAN check results

- [x] Checked on 2024-04-29, problems found: https://cran.r-project.org/web/checks/check_results_duckdb.html
- [x] NOTE: r-devel-linux-x86_64-debian-clang, r-devel-linux-x86_64-debian-gcc, r-devel-linux-x86_64-fedora-clang, r-devel-linux-x86_64-fedora-gcc, r-devel-windows-x86_64
     File ‘duckdb/libs/duckdb.so’:
     Found non-API calls to R: ‘SETLENGTH’, ‘SET_TRUELENGTH’
     
     Compiled code should not call non-API entry points in R.
     
     See ‘Writing portable packages’ in the ‘Writing R Extensions’ manual.
     
     Fixed.
