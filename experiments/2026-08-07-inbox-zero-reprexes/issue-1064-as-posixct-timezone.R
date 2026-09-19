## duckdb-r#1064 -- as.POSIXct() in a dbplyr translation ignores the time zone
library(duckdb)
library(dbplyr, warn.conflicts = FALSE)
library(dplyr, warn.conflicts = FALSE)
packageVersion("dbplyr")

# The reporter's session was in Indiana; the R value 18:00 local is 23:00 UTC
Sys.setenv(TZ = "America/Indiana/Indianapolis")
as.POSIXct("2025-03-01 18:00:00")

# Translated: the string is cast as-is, the session zone is not applied
translate_sql(as.POSIXct("2025-03-01 18:00:00"), con = simulate_duckdb())

# Escaped instead of translated: dbplyr converts the R value to UTC
translate_sql(!!as.POSIXct("2025-03-01 18:00:00"), con = simulate_duckdb())

# The tz argument is not part of the translation at all
try(translate_sql(
  as.POSIXct("2025-03-01 18:00:00", tz = "UTC"),
  con = simulate_duckdb()
))

# Every other backend translates it the same way, so this is dbplyr's base
# translation rather than the duckdb dialect
translate_sql(as.POSIXct("2025-03-01 18:00:00"), con = simulate_postgres())
translate_sql(as.POSIXct("2025-03-01 18:00:00"), con = simulate_mssql())
translate_sql(as.POSIXct("2025-03-01 18:00:00"), con = simulate_mysql())

# ... and the escape/translate split is the same everywhere too
translate_sql(!!as.POSIXct("2025-03-01 18:00:00"), con = simulate_postgres())

# Live, the two comparisons disagree by the UTC offset, as reported
con <- dbConnect(duckdb())
tbl(con, sql("SELECT TIMESTAMP '2025-03-01 20:00:00' AS t")) |>
  mutate(
    translated = t > as.POSIXct("2025-03-01 18:00:00"),
    escaped = t > !!as.POSIXct("2025-03-01 18:00:00")
  ) |>
  collect()
dbDisconnect(con)
