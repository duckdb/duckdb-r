# What does `R CMD check` say about each way of speaking from `.onAttach()`?
#
# Two separate mechanisms bear on the choice, and they are easy to conflate:
# the R-code check (which flags message-generating calls) and the install
# check (which greps `R CMD INSTALL` output for warnings).

pkg <- file.path(tempdir(), "startuptest")

write_pkg <- function(body) {
  unlink(pkg, recursive = TRUE)
  dir.create(file.path(pkg, "R"), recursive = TRUE)
  writeLines(
    c(
      "Package: startuptest", "Version: 1.0.0", "Title: Startup Test",
      "Description: Checks what R CMD check says about startup functions.",
      "Author: N <n@e.com>", "Maintainer: N <n@e.com>",
      "License: MIT + file LICENSE", "Encoding: UTF-8"
    ),
    file.path(pkg, "DESCRIPTION")
  )
  writeLines("MIT", file.path(pkg, "LICENSE"))
  writeLines("export(f)", file.path(pkg, "NAMESPACE"))
  writeLines(
    c("f <- function() 1", "", ".onAttach <- function(libname, pkgname) {",
      paste0("  ", body), "  invisible()", "}"),
    file.path(pkg, "R", "f.R")
  )
}

check <- function(label, body) {
  write_pkg(body)
  out <- suppressWarnings(system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "check", "--no-manual", "--no-build-vignettes", pkg),
    stdout = TRUE, stderr = TRUE
  ))
  keep <- grep("can be installed|R code for possible problems", out)
  keep <- sort(unique(c(keep, keep + 1, keep + 2, keep + 3, keep + 4, keep + 5, keep + 6)))
  cat("--", label, "\n")
  cat(paste0("   ", out[keep[keep <= length(out)]]), sep = "\n")
  cat("\n")
  unlink(paste0(basename(pkg), ".Rcheck"), recursive = TRUE)
}

owd <- setwd(tempdir())
on.exit(setwd(owd))

check("warning(..., call. = FALSE)", 'warning("too old", call. = FALSE)')
check("packageStartupMessage()", 'packageStartupMessage("too old")')
check("message()", 'message("too old")')

# And the check the package itself has to pass: the R-code check reads the
# sources, so it can be run directly against a package directory.
cat("-- tools:::.check_package_code_startup_functions() on this package\n")
found <- tools:::.check_package_code_startup_functions(owd)
cat("   offending startup calls:", length(unlist(found)), "\n")
