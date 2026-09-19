``` r
## duckdb-r#200 -- the issue's reprex, run unchanged on 1.5.5
packageVersion("duckdb")
#> [1] '1.5.5'

con <- DBI::dbConnect(duckdb::duckdb())

DBI::dbExecute(con, "CREATE TABLE tbl (mp MAP(VARCHAR, VARCHAR));")
#> [1] 0
DBI::dbExecute(con, "INSERT INTO tbl VALUES (MAP {'a': 'b'})")
#> [1] 1

DBI::dbGetQuery(con, "DESCRIBE tbl")
#>   column_name           column_type null  key default extra
#> 1          mp MAP(VARCHAR, VARCHAR)  YES <NA>    <NA>  <NA>

DBI::dbReadTable(con, "tbl") |> str()
#> 'data.frame':    1 obs. of  1 variable:
#>  $ mp:List of 1
#>   ..$ :'data.frame': 1 obs. of  2 variables:
#>   .. ..$ key  : chr "a"
#>   .. ..$ value: chr "b"

df <- data.frame(
  mp = I(list(data.frame(key = "page", value = "1")))
)
str(df) # same structure as the returned tbl data
#> 'data.frame':    1 obs. of  1 variable:
#>  $ mp:List of 1
#>   ..$ :'data.frame': 1 obs. of  2 variables:
#>   .. ..$ key  : chr "page"
#>   .. ..$ value: chr "1"
#>   ..- attr(*, "class")= chr "AsIs"

DBI::dbAppendTable(con, "tbl", df)

# The appended row reads back as the same structure it was written from --
# no map_from_entries() detour needed
DBI::dbReadTable(con, "tbl") |> str()
#> 'data.frame':    2 obs. of  1 variable:
#>  $ mp:List of 2
#>   ..$ :'data.frame': 1 obs. of  2 variables:
#>   .. ..$ key  : chr "a"
#>   .. ..$ value: chr "b"
#>   ..$ :'data.frame': 1 obs. of  2 variables:
#>   .. ..$ key  : chr "page"
#>   .. ..$ value: chr "1"

# Round trip: read a MAP column, write it straight back
back <- DBI::dbReadTable(con, "tbl")
DBI::dbAppendTable(con, "tbl", back)
DBI::dbGetQuery(con, "SELECT count(*) AS n FROM tbl")
#>   n
#> 1 4

DBI::dbDisconnect(con)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
