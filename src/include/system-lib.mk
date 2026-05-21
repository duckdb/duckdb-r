# Used when DUCKDB_R_USE_SYSTEM_LIB=1.
# Overrides SOURCES so the vendored .cpp files under src/duckdb/ are not
# compiled; the R package links against the system-installed libduckdb
# at link time and at runtime. PKG_LIBS is appended by configure.
all:
SOURCES=
