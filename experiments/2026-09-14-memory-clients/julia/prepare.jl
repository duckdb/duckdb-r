# Install DuckDB.jl (prebuilt engine via DuckDB_jll) and DataFrames into the depot.
using Pkg
Pkg.add(["DuckDB", "DataFrames", "Tables"])
using DuckDB, DataFrames
println("ready: DuckDB.jl ", pkgversion(DuckDB), " DataFrames ", pkgversion(DataFrames))
