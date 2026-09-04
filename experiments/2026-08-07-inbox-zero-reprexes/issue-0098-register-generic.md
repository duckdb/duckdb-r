``` r
## duckdb-r#98 -- one generic duckdb_register()? What the API looks like today
library(duckdb)
#> Loading required package: DBI
library(arrow, warn.conflicts = FALSE)
packageVersion("duckdb")
#> [1] '1.5.5'

# Still exactly the two entry points the issue names, and no others
ls("package:duckdb", pattern = "register")
#> [1] "duckdb_register"         "duckdb_register_arrow"  
#> [3] "duckdb_unregister"       "duckdb_unregister_arrow"

con <- dbConnect(duckdb())

duckdb_register(con, "df", data.frame(a = 1:3))
dbGetQuery(con, "SELECT * FROM df")
#>   a
#> 1 1
#> 2 2
#> 3 3

# The data frame entry point already accepts an Arrow table -- by calling
# as.data.frame() on it first, which is exactly what the Arrow one avoids
duckdb_register(con, "materialised", arrow_table(data.frame(a = 1:3)))
dbGetQuery(con, "SELECT * FROM materialised")
#>   a
#> 1 1
#> 2 2
#> 3 3
body(duckdb_register)[[3]]
#> df <- encode_values(as.data.frame(df))

duckdb_register_arrow(con, "streamed", arrow_table(data.frame(a = 1:3)))
dbGetQuery(con, "SELECT * FROM streamed")
#>   a
#> 1 1
#> 2 2
#> 3 3

# So the pair is two data paths under two names, not one operation under two
# names; and the standard-API answer that arrived meanwhile is the DBI Arrow
# generics, which dispatch on the object rather than on the function name
dbWriteTableArrow(con, "written", arrow_table(data.frame(a = 1:3)))
dbGetQuery(con, "SELECT * FROM written")
#>   a
#> 1 1
#> 2 2
#> 3 3
class(dbReadTableArrow(con, "written"))
#> [1] "nanoarrow_array_stream"

dbDisconnect(con)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
