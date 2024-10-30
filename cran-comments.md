duckdb 1.1.2

## R CMD check results

- [x] Checked locally, R 4.3.3
- [x] Checked on CI system, R 4.4.1
- [x] Checked on win-builder, R devel

## Current CRAN check results

- [x] Checked on 2024-10-30, problems found: https://cran.r-project.org/web/checks/check_results_duckdb.html
- [ ] WARN: r-devel-linux-x86_64-debian-gcc
     Found the following significant warnings:
     /usr/include/c++/14/bits/move.h:222:11: warning: ‘((void (**)(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >))this)[2]’ is used uninitialized [-Wuninitialized]
     See ‘/home/hornik/tmp/R.check/r-devel-gcc/Work/PKGS/duckdb.Rcheck/00install.out’ for details.
     * used C++ compiler: ‘g++-14 (Debian 14.2.0-6) 14.2.0’

Check results at: https://cran.r-project.org/web/checks/check_results_duckdb.html
