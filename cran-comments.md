duckdb 1.0.0

## R CMD check results

- [x] Checked locally, R 4.3.3
- [x] Checked on CI system, R 4.4.0
- [x] Checked on win-builder, R devel

## Current CRAN check results

- [x] Checked on 2024-06-06, problems found: https://cran.r-project.org/web/checks/check_results_duckdb.html
- [ ] WARN: r-devel-linux-x86_64-debian-gcc
     Found the following significant warnings:
     duckdb/third_party/re2/re2/prog.h:153:14: warning: ISO C++ prohibits anonymous structs [-Wpedantic]
     duckdb/third_party/re2/re2/prog.h:431:12: warning: ISO C++ prohibits anonymous structs [-Wpedantic]
     duckdb/third_party/re2/re2/dfa.cc:124:25: warning: ISO C++ forbids flexible array member ‘next_’ [-Wpedantic]
     duckdb/third_party/re2/re2/onepass.cc:146:12: warning: ISO C++ forbids flexible array member ‘action’ [-Wpedantic]
     See ‘/home/hornik/tmp/R.check/r-devel-gcc/Work/PKGS/duckdb.Rcheck/00install.out’ for details.
     * used C++ compiler: ‘g++-13 (Debian 13.2.0-25) 13.2.0’
- [ ] WARN: r-devel-linux-x86_64-fedora-gcc
     Found the following significant warnings:
     /usr/local/gcc14/include/c++/14.1.0/bits/move.h:221:11: warning: '*(__vector(2) long unsigned int*)this' is used uninitialized [-Wuninitialized]
     /usr/local/gcc14/include/c++/14.1.0/bits/move.h:221:11: warning: '((__vector(2) long unsigned int*)this)[1]' is used uninitialized [-Wuninitialized]
     /usr/local/gcc14/include/c++/14.1.0/bits/move.h:221:11: warning: '((void (**)(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >))this)[2]' is used uninitialized [-Wuninitialized]
     /usr/local/gcc14/include/c++/14.1.0/bits/move.h:221:11: warning: '((duckdb::FileBuffer**)this)[2]' is used uninitialized [-Wuninitialized]
     duckdb/third_party/re2/re2/prog.h:153:14: warning: ISO C++ prohibits anonymous structs [-Wpedantic]
     duckdb/third_party/re2/re2/prog.h:431:12: warning: ISO C++ prohibits anonymous structs [-Wpedantic]
     duckdb/third_party/re2/re2/dfa.cc:124:25: warning: ISO C++ forbids flexible array member 'next_' [-Wpedantic]
     duckdb/third_party/re2/re2/onepass.cc:146:12: warning: ISO C++ forbids flexible array member 'action' [-Wpedantic]
     See ‘/data/gannet/ripley/R/packages/tests-devel/duckdb.Rcheck/00install.out’ for details.
     * used C++ compiler: ‘g++-14 (GCC) 14.1.0’
- [ ] WARN: r-patched-linux-x86_64
     Found the following significant warnings:
     duckdb/third_party/re2/re2/prog.h:153:14: warning: ISO C++ prohibits anonymous structs [-Wpedantic]
     duckdb/third_party/re2/re2/prog.h:431:12: warning: ISO C++ prohibits anonymous structs [-Wpedantic]
     duckdb/third_party/re2/re2/dfa.cc:124:25: warning: ISO C++ forbids flexible array member ‘next_’ [-Wpedantic]
     duckdb/third_party/re2/re2/onepass.cc:146:12: warning: ISO C++ forbids flexible array member ‘action’ [-Wpedantic]
     See ‘/home/hornik/tmp/R.check/r-patched-gcc/Work/PKGS/duckdb.Rcheck/00install.out’ for details.
     * used C++ compiler: ‘g++-13 (Debian 13.2.0-25) 13.2.0’
- [ ] WARN: r-release-linux-x86_64
     Found the following significant warnings:
     duckdb/third_party/re2/re2/prog.h:153:14: warning: ISO C++ prohibits anonymous structs [-Wpedantic]
     duckdb/third_party/re2/re2/prog.h:431:12: warning: ISO C++ prohibits anonymous structs [-Wpedantic]
     duckdb/third_party/re2/re2/dfa.cc:124:25: warning: ISO C++ forbids flexible array member ‘next_’ [-Wpedantic]
     duckdb/third_party/re2/re2/onepass.cc:146:12: warning: ISO C++ forbids flexible array member ‘action’ [-Wpedantic]
     See ‘/home/hornik/tmp/R.check/r-release-gcc/Work/PKGS/duckdb.Rcheck/00install.out’ for details.
     * used C++ compiler: ‘g++-13 (Debian 13.2.0-25) 13.2.0’
- [ ] NOTE: r-release-macos-x86_64
     Package suggested but not available for checking: ‘arrow’
- [ ] other_issue: NA
See: <https://www.stats.ox.ac.uk/pub/bdr/gcc12/duckdb.out>

Check results at: https://cran.r-project.org/web/checks/check_results_duckdb.html
