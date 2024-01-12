library(duckdb)
.Call("duckdb_load_library", system.file(c("inst","libduckdb"), package="duckdb"), PACKAGE ="duckdb")
print(.Call("duckdb_library_version", PACKAGE="duckdb"))