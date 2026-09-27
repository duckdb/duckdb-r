# The cross-client scenarios, Julia side (DuckDB.jl over DuckDB_jll): one scenario per process, one CSV line out.
using DuckDB, DataFrames, Tables
image, scenario = ARGS[1], ARGS[2]
function peak_mb()
    for l in eachline("/proc/self/status")
        startswith(l, "VmHWM") && return parse(Int, split(l)[2]) / 1024
    end
    0.0
end
Q = "SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(50000000) t(i)"
QS = "SELECT i::DOUBLE AS a, ((i * 7919) % 1000003)::DOUBLE AS b FROM range(50000000) t(i) ORDER BY b"
con = DBInterface.connect(DuckDB.DB, ":memory:")
t0 = time(); rows = 0
if scenario == "probe"
    res = DBInterface.execute(con, "SELECT 1 AS x")
    println("result type: ", typeof(res)); println("execute methods: ", methods(DuckDB.execute))
    println("partitions: ", typeof(Tables.partitions(res)))
elseif scenario == "materialize_df"
    df = DataFrame(DBInterface.execute(con, Q)); rows = nrow(df)
elseif scenario == "stream_rows"
    for row in DBInterface.execute(con, Q); rows += 1; end
elseif scenario in ("stream_partitions", "stream_sorted_limited")
    scenario == "stream_sorted_limited" && DBInterface.execute(con, "SET memory_limit = '200MB'")
    res = DBInterface.execute(con, scenario == "stream_sorted_limited" ? QS : Q)
    for chunk in Tables.partitions(res); rows += length(Tables.getcolumn(Tables.columns(chunk), 1)); end
else
    error("unknown scenario " * scenario)
end
println("julia,", image, ",", scenario, ",", rows, ",", round(Int, peak_mb()), ",", round(time() - t0, digits = 1))
