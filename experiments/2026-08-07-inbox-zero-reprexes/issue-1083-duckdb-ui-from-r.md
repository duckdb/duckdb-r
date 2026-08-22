``` r
## duckdb-r#1083 -- can an R user start the DuckDB UI, and is the Windows
## build of the `ui` extension there?
library(duckdb)
#> Loading required package: DBI
packageVersion("duckdb")
#> [1] '1.5.5'

# The extension the reporter could not download in March 2025, per version,
# for the platform R on Windows asks for:
ext_status <- function(version, platform, extension = "ui") {
  url <- sprintf(
    "http://extensions.duckdb.org/%s/%s/%s.duckdb_extension.gz",
    version,
    platform,
    extension
  )
  curl::curl_fetch_memory(url, curl::new_handle(nobody = TRUE))$status_code
}

versions <- c("v1.2.0", "v1.2.1", "v1.2.2", "v1.3.2", "v1.4.1", "v1.5.5")
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
#> 1  v1.2.0                 404         200
#> 2  v1.2.1                 200         200
#> 3  v1.2.2                 200         200
#> 4  v1.3.2                 200         200
#> 5  v1.4.1                 200         200
#> 6  v1.5.5                 200         200

# And the R-side answer to "is there a way to run duckdb-ui with R functions?":
con <- dbConnect(duckdb())
dbGetQuery(con, "SELECT version() AS engine")
#>   engine
#> 1 v1.5.5
dbExecute(con, "INSTALL ui")
#> [1] 0
dbExecute(con, "LOAD ui")
#> [1] 0
dbGetQuery(
  con,
  "SELECT extension_name, loaded, installed, extension_version
   FROM duckdb_extensions() WHERE extension_name = 'ui'"
)
#>   extension_name loaded installed extension_version
#> 1             ui   TRUE      TRUE           26084e6

dbGetQuery(con, "CALL start_ui_server()")
#>                                        result
#> 1 UI server started at http://localhost:4213/
dbGetQuery(con, "CALL stop_ui_server()")
#>              result
#> 1 UI server stopped
dbDisconnect(con)

# start_ui() is the same call plus a browser launch; what the browser then
# renders is served by the extension, not by R.
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
