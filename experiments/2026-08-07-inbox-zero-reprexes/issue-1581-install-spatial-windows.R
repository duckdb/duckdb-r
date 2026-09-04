## duckdb-r#1581 -- "INSTALL spatial fails on Windows"
library(duckdb)
packageVersion("duckdb")

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

# The R side was never the problem -- same call, same version, on Linux:
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial")
dbExecute(con, "LOAD spatial")
dbGetQuery(
  con,
  "SELECT extension_name, loaded, installed FROM duckdb_extensions()
   WHERE extension_name = 'spatial'"
)
dbGetQuery(con, "SELECT ST_AsText(ST_Point(1, 2)) AS pt")
dbDisconnect(con)
