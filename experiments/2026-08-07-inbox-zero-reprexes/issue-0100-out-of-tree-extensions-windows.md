``` r
## duckdb-r#100 -- "Out-of-tree extensions missing for Windows", re-measured
## The 2024 table in the issue was built from duckdb_extensions(); this asks
## the repository the same question for the platform R's Windows toolchain
## uses today (windows_amd64_mingw), at the current version.
ext_status <- function(extension, platform, version = "v1.5.5") {
  url <- sprintf(
    "http://extensions.duckdb.org/%s/%s/%s.duckdb_extension.gz",
    version,
    platform,
    extension
  )
  curl::curl_fetch_memory(url, curl::new_handle(nobody = TRUE))$status_code
}

extensions <- c(
  "aws",
  "azure",
  "excel",
  "fts",
  "httpfs",
  "iceberg",
  "icu",
  "inet",
  "json",
  "motherduck",
  "mysql_scanner",
  "postgres_scanner",
  "spatial",
  "sqlite_scanner",
  "tpcds",
  "tpch"
)

data.frame(
  extension = extensions,
  linux_amd64 = vapply(
    extensions,
    ext_status,
    integer(1),
    platform = "linux_amd64"
  ),
  windows_amd64 = vapply(
    extensions,
    ext_status,
    integer(1),
    platform = "windows_amd64"
  ),
  windows_amd64_mingw = vapply(
    extensions,
    ext_status,
    integer(1),
    platform = "windows_amd64_mingw"
  ),
  row.names = NULL
)
#>           extension linux_amd64 windows_amd64 windows_amd64_mingw
#> 1               aws         200           200                 404
#> 2             azure         200           200                 404
#> 3             excel         200           200                 200
#> 4               fts         200           200                 200
#> 5            httpfs         200           200                 200
#> 6           iceberg         200           200                 404
#> 7               icu         200           200                 200
#> 8              inet         200           200                 200
#> 9              json         200           200                 200
#> 10       motherduck         200           200                 404
#> 11    mysql_scanner         200           200                 404
#> 12 postgres_scanner         200           200                 404
#> 13          spatial         200           200                 200
#> 14   sqlite_scanner         200           200                 200
#> 15            tpcds         200           200                 200
#> 16             tpch         200           200                 200

# When the mingw directory started carrying out-of-tree builds, using spatial
# (❌ for amd64_rtools in the issue's 0.10.0 table) as the probe:
versions <- c("v1.3.2", "v1.4.0", "v1.4.1", "v1.4.3", "v1.5.5")
data.frame(
  version = versions,
  spatial_windows_amd64_mingw = vapply(
    versions,
    function(v) ext_status("spatial", "windows_amd64_mingw", v),
    integer(1)
  ),
  row.names = NULL
)
#>   version spatial_windows_amd64_mingw
#> 1  v1.3.2                         200
#> 2  v1.4.0                         404
#> 3  v1.4.1                         200
#> 4  v1.4.3                         200
#> 5  v1.5.5                         200
```

<sup>Created on 2026-08-07 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>
