## duckdb-r#98 -- one generic duckdb_register()? What the API looks like today
library(duckdb)
library(arrow, warn.conflicts = FALSE)
packageVersion("duckdb")

# Still exactly the two entry points the issue names, and no others
ls("package:duckdb", pattern = "register")

con <- dbConnect(duckdb())

duckdb_register(con, "df", data.frame(a = 1:3))
dbGetQuery(con, "SELECT * FROM df")

# The data frame entry point already accepts an Arrow table -- by calling
# as.data.frame() on it first, which is exactly what the Arrow one avoids
duckdb_register(con, "materialised", arrow_table(data.frame(a = 1:3)))
dbGetQuery(con, "SELECT * FROM materialised")
body(duckdb_register)[[3]]

duckdb_register_arrow(con, "streamed", arrow_table(data.frame(a = 1:3)))
dbGetQuery(con, "SELECT * FROM streamed")

# So the pair is two data paths under two names, not one operation under two
# names; and the standard-API answer that arrived meanwhile is the DBI Arrow
# generics, which dispatch on the object rather than on the function name
dbWriteTableArrow(con, "written", arrow_table(data.frame(a = 1:3)))
dbGetQuery(con, "SELECT * FROM written")
class(dbReadTableArrow(con, "written"))

dbDisconnect(con)
