``` r
## duckdb-r#2503 -- "INSTALL postgres" fails on Windows, works elsewhere
library(duckdb)
#> Loading required package: DBI
packageVersion("duckdb")
#> [1] '1.5.5'

# Same code, same version, on Linux:
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL postgres;")
#> [1] 0
dbExecute(con, "LOAD postgres;")
#> [1] 0
dbGetQuery(
  con,
  "SELECT extension_name, loaded, installed FROM duckdb_extensions()
   WHERE extension_name = 'postgres_scanner'"
)
#>     extension_name loaded installed
#> 1 postgres_scanner   TRUE      TRUE
dbDisconnect(con)

# So the difference is which artifact the repository serves. R on Windows asks
# for windows_amd64_mingw; the MSVC build (windows_amd64) is a different file
# that a MinGW build cannot load.
ext_status <- function(extension, platform, version = "v1.5.5") {
  url <- sprintf(
    "http://extensions.duckdb.org/%s/%s/%s.duckdb_extension.gz",
    version,
    platform,
    extension
  )
  curl::curl_fetch_memory(url, curl::new_handle(nobody = TRUE))$status_code
}

platforms <- c("linux_amd64", "windows_amd64", "windows_amd64_mingw")
data.frame(
  platform = platforms,
  postgres_scanner = vapply(
    platforms,
    function(p) ext_status("postgres_scanner", p),
    integer(1)
  ),
  # extensions that *are* published for the mingw flavour, for contrast
  spatial = vapply(platforms, function(p) ext_status("spatial", p), integer(1)),
  httpfs = vapply(platforms, function(p) ext_status("httpfs", p), integer(1)),
  row.names = NULL
)
#>              platform postgres_scanner spatial httpfs
#> 1         linux_amd64              200     200    200
#> 2       windows_amd64              200     200    200
#> 3 windows_amd64_mingw              404     200    200
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
