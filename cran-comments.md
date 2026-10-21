duckdb 1.5.6

## Cran Repository Policy

- [x] Reviewed CRP last edited 2026-05-31.

## Current CRAN check results

- [x] Checked on 2026-09-28, problems found: https://cran.r-project.org/web/checks/check_results_duckdb.html
- [x] ERROR on r-devel-linux-x86_64-fedora-clang: installation failed because glibc's `<langinfo.h>` defines `GROUPING` as a macro, which replaced a parser token code in the vendored libpg_query.
  Fixed.
