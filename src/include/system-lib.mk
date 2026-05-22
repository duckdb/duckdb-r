# Used when DUCKDB_R_USE_SYSTEM_LIB=1.
#
# In this mode the R glue still compiles against the vendored *headers*
# under src/duckdb/src/include/ (the amalgamated duckdb.hpp shipped by
# libduckdb does not contain the ~37 internal C++ headers the glue
# needs), but the vendored .cpp files are not compiled. The actual
# DuckDB implementation comes from the system-installed libduckdb at
# link time and at runtime. PKG_LIBS is appended by configure.
all:
SOURCES=
