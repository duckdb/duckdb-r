``` r
## duckdb-r#1581 -- "INSTALL spatial fails on Windows"
library(duckdb)
#> Loading required package: DBI
packageVersion("duckdb")
#> [1] '1.5.5'

# The failure was an HTTP status from the extension repository, so ask the
# repository directly: is there a spatial build for the platform R's Windows
# toolchain asks for (windows_amd64_mingw)?
ext_status <- function(version, platform, extension = "spatial") {
  url <- sprintf(
    "http://extensions.duckdb.org/%s/%s/%s.duckdb_extension.gz",
    version,
    platform,
    extension
  )
  curl::curl_fetch_memory(url, curl::new_handle(nobody = TRUE))$status_code
}

versions <- c("v1.3.2", "v1.4.0", "v1.4.1", "v1.4.3", "v1.5.5")
data.frame(
  version = versions,
  windows_amd64_mingw = vapply(
    versions,
    ext_status,
    integer(1),
    platform = "windows_amd64_mingw"
  ),
  linux_amd64 = vapply(
    versions,
    ext_status,
    integer(1),
    platform = "linux_amd64"
  ),
  row.names = NULL
)
#>   version windows_amd64_mingw linux_amd64
#> 1  v1.3.2                 200         200
#> 2  v1.4.0                 404         200
#> 3  v1.4.1                 200         200
#> 4  v1.4.3                 200         200
#> 5  v1.5.5                 200         200

# The R side was never the problem -- same call, same version, on Linux:
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial")
#> [1] 0
dbExecute(con, "LOAD spatial")
#> [1] 0
dbGetQuery(
  con,
  "SELECT extension_name, loaded, installed FROM duckdb_extensions()
   WHERE extension_name = 'spatial'"
)
#>   extension_name loaded installed
#> 1        spatial   TRUE      TRUE
dbGetQuery(con, "SELECT ST_AsText(ST_Point(1, 2)) AS pt")
#>            pt
#> 1 POINT (1 2)
dbDisconnect(con)
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
