# Install what the scripts need beside the image's own duckdb, into the cache library.
lib <- "/cache/rlib"; dir.create(lib, showWarnings = FALSE, recursive = TRUE); .libPaths(c(lib, .libPaths()))
options(repos = c(P3M = "https://packagemanager.posit.co/cran/__linux__/noble/latest",
                  apache = "https://apache.r-universe.dev"),
        HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))
need <- setdiff(c("DBI", "nanoarrow", "adbcdrivermanager", "arrow"), rownames(installed.packages()))
if (length(need)) install.packages(need, lib = lib, quiet = TRUE)
cat("ready:", paste(c("DBI", "nanoarrow", "adbcdrivermanager", "arrow") %in% rownames(installed.packages()), collapse = " "), "\n")
