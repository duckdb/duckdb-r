library(DBI)
packageVersion("duckdb")

# The default connection is an in-memory database. The package points its
# temporary storage below tempdir(), away from the current working directory:
drv <- duckdb::duckdb()
con <- dbConnect(drv)
spill <- dbGetQuery(
  con,
  "SELECT current_setting('temp_directory') AS temp_directory"
)[[1]]
spill

# Any operation that outgrows memory_limit must offload to that directory:
# a ~460 MB sort under a 300 MB limit.
dbExecute(con, "SET memory_limit = '300MB'")
dbExecute(
  con,
  "CREATE TABLE big_sort AS SELECT hash(i) AS h, i FROM range(30000000) t(i) ORDER BY h"
)
dbGetQuery(con, "SELECT count(*) AS n FROM big_sort")

# The spill directory exists while the instance is live ...
dir.exists(spill)

dbDisconnect(con)
duckdb::duckdb_shutdown(drv)

# ... and the engine removes it again at instance shutdown.
dir.exists(spill)
