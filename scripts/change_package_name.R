#!/usr/bin/env Rscript

# Change the R package name across all relevant files.
#
# Usage:
#   Rscript scripts/change_package_name.R <new_package_name>
#
# Example:
#   Rscript scripts/change_package_name.R duckdb.1.4
#
# This script updates the R package name in all locations where it appears
# as a package identifier. It does NOT change function names (e.g., duckdb()),
# class names (e.g., duckdb_connection), or C/C++ code.
#
# The DESCRIPTION file's Package field is the single source of truth for
# the package name.

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop("Usage: Rscript scripts/change_package_name.R <new_package_name>")
}

new_name <- args[[1]]

# Validate the new package name per R rules:
# must start with a letter, contain only letters, digits, and dots,
# and be at least two characters long.
if (!grepl("^[a-zA-Z][a-zA-Z0-9.]*$", new_name) || nchar(new_name) < 2) {
  stop("Invalid R package name: '", new_name, "'. ",
       "Must start with a letter, contain only letters, digits, and dots, ",
       "and be at least 2 characters.")
}

# Read current package name from DESCRIPTION
desc <- readLines("DESCRIPTION")
pkg_line <- grep("^Package:", desc, value = TRUE)
if (length(pkg_line) != 1) {
  stop("Could not find unique 'Package:' line in DESCRIPTION")
}
old_name <- trimws(sub("^Package:", "", pkg_line))

if (old_name == new_name) {
  message("Package name is already '", new_name, "'. Nothing to do.")
  quit(status = 0)
}

message("Renaming package: '", old_name, "' -> '", new_name, "'")

# Helper: read a file, apply a replacement function, write back if changed
replace_in_file <- function(path, pattern, replacement) {
  if (!file.exists(path)) {
    message("  SKIP (not found): ", path)
    return(invisible(FALSE))
  }
  content <- readLines(path, warn = FALSE)
  new_content <- gsub(pattern, replacement, content)
  if (!identical(content, new_content)) {
    writeLines(new_content, path)
    changed_lines <- which(content != new_content)
    message("  Updated: ", path, " (", length(changed_lines), " line(s))")
    return(invisible(TRUE))
  } else {
    message("  No change: ", path)
    return(invisible(FALSE))
  }
}

# Escape for use in fixed-string regex patterns
esc <- function(x) gsub("([.\\|(){}^$*+?\\[\\]])", "\\\\\\1", x)
old_esc <- esc(old_name)
new_esc <- new_name

# 1. DESCRIPTION: Package: field
message("\n[1/10] DESCRIPTION")
replace_in_file("DESCRIPTION",
  paste0("^Package: ", old_esc, "$"),
  paste0("Package: ", new_esc))

# 2. NAMESPACE: useDynLib() call
message("\n[2/10] NAMESPACE")
replace_in_file("NAMESPACE",
  paste0("useDynLib\\(", old_esc, ","),
  paste0("useDynLib(", new_esc, ","))

# 3. R/duckdb-package.R: @useDynLib directive
message("\n[3/10] R/duckdb-package.R")
replace_in_file("R/duckdb-package.R",
  paste0("@useDynLib ", old_esc, ","),
  paste0("@useDynLib ", new_esc, ","))

# 4. R/Viewer.R: package = "..." argument
message("\n[4/10] R/Viewer.R")
replace_in_file("R/Viewer.R",
  paste0('package = "', old_esc, '"'),
  paste0('package = "', new_esc, '"'))

# 5. R/Driver.R: R_user_dir("...", ...) calls
message("\n[5/10] R/Driver.R")
replace_in_file("R/Driver.R",
  paste0('R_user_dir\\("', old_esc, '"'),
  paste0('R_user_dir("', new_esc, '"'))

# 6. R/dbSendQuery__duckdb_connection_character.R: namespace name check
message("\n[6/10] R/dbSendQuery__duckdb_connection_character.R")
replace_in_file("R/dbSendQuery__duckdb_connection_character.R",
  paste0('c\\("', old_esc, '",'),
  paste0('c("', new_esc, '",'))

# 7. tests/testthat.R: library() and test_check()
message("\n[7/10] tests/testthat.R")
replace_in_file("tests/testthat.R",
  paste0("library\\(", old_esc, "\\)"),
  paste0("library(", new_esc, ")"))
replace_in_file("tests/testthat.R",
  paste0('test_check\\("', old_esc, '"\\)'),
  paste0('test_check("', new_esc, '")'))

# 8. tests/testthat/helper-DBItest.R: name = "..."
message("\n[8/10] tests/testthat/helper-DBItest.R")
replace_in_file("tests/testthat/helper-DBItest.R",
  paste0('name = "', old_esc, '"'),
  paste0('name = "', new_esc, '"'))

# 9. tests/testthat/test-arrow.R: skip_if_not_installed() and library()
message("\n[9/10] tests/testthat/test-arrow.R")
replace_in_file("tests/testthat/test-arrow.R",
  paste0('skip_if_not_installed\\("', old_esc, '"'),
  paste0('skip_if_not_installed("', new_esc, '"'))
replace_in_file("tests/testthat/test-arrow.R",
  paste0("library\\(", old_esc, "\\)"),
  paste0("library(", new_esc, ")"))

# 10. inst/rstudio/connections/DuckDB.R: library()
message("\n[10/10] inst/rstudio/connections/DuckDB.R")
replace_in_file("inst/rstudio/connections/DuckDB.R",
  paste0("library\\(", old_esc, "\\)"),
  paste0("library(", new_esc, ")"))

message("\nDone! Package name changed from '", old_name, "' to '", new_name, "'.")
message("The DESCRIPTION file is the single source of truth for the package name.")
