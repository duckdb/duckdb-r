# Install what the R scripts need beside the image's own duckdb, into the cache library,
# from the repositories the image is configured with, plus r-universe for what they lack.
lib <- "/cache/rlib"; dir.create(lib, showWarnings = FALSE, recursive = TRUE); .libPaths(c(lib, .libPaths()))
repos <- getOption("repos"); repos <- repos[repos != "@CRAN@"]
options(repos = c(repos, apache = "https://apache.r-universe.dev"))
pkgs <- c("DBI", "nanoarrow", "adbcdrivermanager", "arrow", "nanoparquet")
need <- setdiff(pkgs, rownames(installed.packages()))
if (length(need)) install.packages(need, lib = lib, quiet = TRUE)
ok <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
cat("ready:", paste(names(ok), ok, collapse = " "), "\n")
