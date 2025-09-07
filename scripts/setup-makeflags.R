#!/usr/bin/env Rscript

# Setup MAKEFLAGS for parallel compilation
# Based on the approach used by Apache Arrow R package
# Only sets MAKEFLAGS if not already set (respects user preferences)

# Check if MAKEFLAGS is already set
makeflags <- Sys.getenv("MAKEFLAGS", unset = "")

if (makeflags == "") {
  # Detect number of cores
  ncores <- parallel::detectCores()

  # CRAN policy: don't use more than 2 cores during checks
  # Use NOT_CRAN environment variable to allow more cores locally
  not_cran <- tolower(Sys.getenv("NOT_CRAN", "false")) %in% c("true", "1", "yes")

  if (!not_cran) {
    ncores <- min(ncores, 2)
  }

  # Output the MAKEFLAGS value for the shell to export
  makeflags_value <- sprintf("-j%s", ncores)
  cat(makeflags_value)
} else {
  # Don't output anything if MAKEFLAGS is already set
  cat("")
}
