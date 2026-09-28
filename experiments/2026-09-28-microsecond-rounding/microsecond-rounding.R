## How a POSIXct and a difftime round to the microsecond:
## on the write routes, in dbQuoteLiteral(), and in the engine's own conversions.
library(DBI)

con <- dbConnect(duckdb::duckdb(shared_home = FALSE))

## Ties, one microsecond apart ----------------------------------------------------
## 2.5 us and 3.5 us are ties once scaled; half to even takes both to an even
## number, half away from zero takes them outward.
s <- c(2.5e-6, 3.5e-6, -2.5e-6, -3.5e-6)
s * 1e6 - trunc(s * 1e6)
x <- .POSIXct(s, tz = "UTC")
d <- as.difftime(s, units = "secs")

# dbWriteTable(), duckdb_register() and dbAppendTable() all convert in the glue
df <- data.frame(i = seq_along(s), x = x, d = d)
dbWriteTable(con, "written", df)
duckdb::duckdb_register(con, "registered", df)
dbCreateTable(con, "appended", c(i = "INTEGER", x = "TIMESTAMP", d = "INTERVAL"))
dbAppendTable(con, "appended", df)
us <- "SELECT epoch_us(x) AS x_us, to_microseconds(0) + d AS d FROM %s ORDER BY i"
dbGetQuery(con, sprintf(us, "written"))
dbGetQuery(con, sprintf(us, "registered"))
dbGetQuery(con, sprintf(us, "appended"))

# A parameter binds through the same conversion
dbGetQuery(con, "SELECT epoch_us(?) AS x_us", params = list(x))

# dbQuoteLiteral() rounds in R, with round()
dbQuoteLiteral(con, x)
dbQuoteLiteral(con, d)
round(s * 1e6)

# The engine's own conversions from a double
dbGetQuery(con, "
  SELECT v,
    CAST(v AS BIGINT) AS cast_bigint,
    epoch_us(to_timestamp(v / 1e6)) AS to_timestamp_us,
    round(v) AS round_fn
  FROM (VALUES (2.5::DOUBLE), (3.5), (-2.5), (-3.5)) t(v)
")

## How often, for present-day instants -----------------------------------------
## Near 1.7e9 seconds, the product with 1e6 is a double whose spacing is 0.25,
## so a quarter of all values land exactly on a half microsecond.
set.seed(20260928)
secs <- 1.7e9 + runif(1e5, 0, 1e7)
p <- secs * 1e6
mean(p - trunc(p) == 0.5)

now <- data.frame(i = seq_along(secs), x = .POSIXct(secs, tz = "UTC"), s = secs)
dbWriteTable(con, "now", now)
res <- dbGetQuery(con, "
  SELECT epoch_us(x) AS written, epoch_us(to_timestamp(s)) AS engine
  FROM now ORDER BY i
")
quoted <- round(p)

# Share that differs, and by how much
mean(res$written != quoted)
mean(res$written != res$engine)
mean(quoted != res$engine)
max(abs(res$written - quoted))

## What it costs -----------------------------------------------------------------
## A literal quoted from the value that was written does not find its row.
k <- which(res$written != quoted)[1]
lit <- dbQuoteLiteral(con, now$x[k])
lit
dbGetQuery(con, paste0("SELECT count(*) AS n FROM now WHERE x = ", lit))
dbGetQuery(con, "SELECT count(*) AS n FROM now WHERE x = ?", params = list(now$x[k]))

dbDisconnect(con)
