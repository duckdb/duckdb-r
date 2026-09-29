# Crashes R: run it on its own, as `Rscript crash.R`, not through the reprex renderer.
# A classed matrix as the first column makes the scan read the character column past its end.
library(DBI)
con <- dbConnect(duckdb::duckdb(shared_home = FALSE))
d <- structure(as.Date("2024-01-01") + 0:3, dim = c(2L, 2L))
df <- data.frame(m = 1:2)
df$m <- d
df$s <- c("a", "b")
duckdb::duckdb_register(con, "r", df)
print(dbGetQuery(con, "SELECT m, s FROM r"))
