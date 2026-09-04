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
