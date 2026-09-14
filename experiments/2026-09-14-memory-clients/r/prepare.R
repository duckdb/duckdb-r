# Install what the scripts need beside the image's own duckdb, into the cache library,
# from the repositories the image itself is configured with (rig points them at the
# Posit binaries for the image's own distribution), plus r-universe for what they lack.
lib <- "/cache/rlib"; dir.create(lib, showWarnings = FALSE, recursive = TRUE); .libPaths(c(lib, .libPaths()))
repos <- getOption("repos"); repos <- repos[repos != "@CRAN@"]
options(repos = c(repos, apache = "https://apache.r-universe.dev"))
need <- setdiff(c("DBI", "nanoarrow", "adbcdrivermanager", "arrow"), rownames(installed.packages()))
if (length(need)) install.packages(need, lib = lib, quiet = TRUE)
ok <- vapply(c("DBI", "nanoarrow", "adbcdrivermanager", "arrow"), requireNamespace, logical(1), quietly = TRUE)
cat("ready:", paste(names(ok), ok, collapse = " "), "\n")
