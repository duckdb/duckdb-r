``` r
## duckdb-r#1829 -- where the -Wunused-function noise comes from
## Every warning in the report names one file, and that file is vendored
## verbatim from duckdb/duckdb. It documents the effect itself:
url <- paste0(
  "https://raw.githubusercontent.com/duckdb/duckdb/v1.5.5/",
  "src/include/duckdb/common/operator/numeric_cast.hpp"
)
writeLines(readLines(url, n = 11)[9:11])
#> //! NOTE: This file should not be included directly.
#> //! NOTE: When included directly, this file produces 'unused static method' warnings/errors.
#> //! NOTE: The methods in this file should be used through the TryCast:: methods defined in 'cast_operators.hpp'.

# The construct: a `static` function template, so every explicit
# specialization has internal linkage and every one that a translation unit
# does not call is "defined but not used". Reduced to two functions:
d <- tempfile()
dir.create(d)
writeLines(
  c(
    "#pragma once",
    "namespace demo {",
    "template <class SRC, class DST>",
    "static bool TryCastWithOverflowCheck(SRC value, DST &result) {",
    "\tresult = static_cast<DST>(value);",
    "\treturn true;",
    "}",
    "template <>",
    "bool TryCastWithOverflowCheck(double value, int &result) {",
    "\tresult = static_cast<int>(value);",
    "\treturn true;",
    "}",
    "}"
  ),
  file.path(d, "numeric_cast_demo.hpp")
)
writeLines(
  c('#include "numeric_cast_demo.hpp"', "int main() { return 0; }"),
  file.path(d, "tu.cpp")
)

cxx <- system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "config", "CXX"),
  stdout = TRUE
)
cxx
#> [1] "ccache g++"

compile <- function(flags) {
  cmd <- paste(
    cxx,
    flags,
    "-c",
    shQuote(file.path(d, "tu.cpp")),
    "-o",
    shQuote(file.path(d, "tu.o"))
  )
  cat(
    system2("sh", c("-c", shQuote(cmd)), stdout = TRUE, stderr = TRUE),
    sep = "\n"
  )
}

# With -Wall, one warning per unused specialization -- the shape reported
compile("-std=gnu++17 -Wall")
#> In file included from /tmp/RtmpMejUmN/filebd5763d1a85/tu.cpp:1:
#> /tmp/RtmpMejUmN/filebd5763d1a85/numeric_cast_demo.hpp:9:6: warning: ‘bool demo::TryCastWithOverflowCheck(SRC, DST&) [with SRC = double; DST = int]’ defined but not used [-Wunused-function]
#>     9 | bool TryCastWithOverflowCheck(double value, int &result) {
#>       |      ^~~~~~~~~~~~~~~~~~~~~~~~

# Without it, silence: R's default CXXFLAGS do not ask for this warning
compile("-std=gnu++17")
system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "config", "CXXFLAGS"),
  stdout = TRUE
)
#> [1] "-g -O2"
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
