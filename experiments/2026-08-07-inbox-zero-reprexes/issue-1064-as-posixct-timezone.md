``` r
## duckdb-r#1064 -- as.POSIXct() in a dbplyr translation ignores the time zone
library(duckdb)
#> Loading required package: DBI
library(dbplyr, warn.conflicts = FALSE)
library(dplyr, warn.conflicts = FALSE)
packageVersion("dbplyr")
#> [1] '2.6.0'

# The reporter's session was in Indiana; the R value 18:00 local is 23:00 UTC
Sys.setenv(TZ = "America/Indiana/Indianapolis")
as.POSIXct("2025-03-01 18:00:00")
#> [1] "2025-03-01 18:00:00 EST"

# Translated: the string is cast as-is, the session zone is not applied
translate_sql(as.POSIXct("2025-03-01 18:00:00"), con = simulate_duckdb())
#> <SQL> TRY_CAST('2025-03-01 18:00:00' AS TIMESTAMP)

# Escaped instead of translated: dbplyr converts the R value to UTC
translate_sql(!!as.POSIXct("2025-03-01 18:00:00"), con = simulate_duckdb())
#> <SQL> '2025-03-01 23:00:00'::timestamp

# The tz argument is not part of the translation at all
try(translate_sql(
  as.POSIXct("2025-03-01 18:00:00", tz = "UTC"),
  con = simulate_duckdb()
))
#> Error in as.POSIXct("2025-03-01 18:00:00", tz = "UTC") : 
#>   unused argument (tz = "UTC")

# Every other backend translates it the same way, so this is dbplyr's base
# translation rather than the duckdb dialect
translate_sql(as.POSIXct("2025-03-01 18:00:00"), con = simulate_postgres())
#> <SQL> CAST('2025-03-01 18:00:00' AS TIMESTAMP)
translate_sql(as.POSIXct("2025-03-01 18:00:00"), con = simulate_mssql())
#> <SQL> TRY_CAST('2025-03-01 18:00:00' AS DATETIME2)
translate_sql(as.POSIXct("2025-03-01 18:00:00"), con = simulate_mysql())
#> <SQL> CAST('2025-03-01 18:00:00' AS DATETIME)

# ... and the escape/translate split is the same everywhere too
translate_sql(!!as.POSIXct("2025-03-01 18:00:00"), con = simulate_postgres())
#> <SQL> '2025-03-01T23:00:00Z'::timestamp

# Live, the two comparisons disagree by the UTC offset, as reported
con <- dbConnect(duckdb())
tbl(con, sql("SELECT TIMESTAMP '2025-03-01 20:00:00' AS t")) |>
  mutate(
    translated = t > as.POSIXct("2025-03-01 18:00:00"),
    escaped = t > !!as.POSIXct("2025-03-01 18:00:00")
  ) |>
  collect()
#> # A tibble: 1 × 3
#>   t                   translated escaped
#>   <dttm>              <lgl>      <lgl>  
#> 1 2025-03-01 20:00:00 TRUE       FALSE
dbDisconnect(con)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
