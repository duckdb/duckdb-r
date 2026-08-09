# The warning as shipped, against a real old dbplyr, in every order that puts
# the two packages in a session -- plus the mid-session upgrade, which is the
# case that separates the loaded version from the library one.
#
# dbplyr 2.5.0 comes from a Posit Package Manager snapshot; the current dbplyr
# comes from the ordinary library. Both are read-only here: every scenario runs
# in its own subprocess against a copy.

pkg <- "duckdb"
snapshot <- "https://packagemanager.posit.co/cran/2025-06-02"

old_lib <- file.path(tempdir(), "old")
dir.create(old_lib, showWarnings = FALSE)
install.packages("dbplyr", lib = old_lib, repos = snapshot, type = "source",
                 dependencies = FALSE, quiet = TRUE)
cat("old dbplyr:", as.character(packageVersion("dbplyr", lib.loc = old_lib)),
    "| exports sql_glue():",
    "sql_glue" %in% names(readRDS(file.path(old_lib, "dbplyr", "Meta", "nsInfo.rds"))$exports),
    "\n")
cur_lib <- dirname(find.package("dbplyr"))
cat("current dbplyr:", as.character(packageVersion("dbplyr")), "\n\n")

run <- function(label, lines, libs = character()) {
  f <- tempfile(fileext = ".R")
  writeLines(lines, f)
  env <- if (length(libs)) paste0("R_LIBS=", paste(c(libs, .libPaths()), collapse = ":")) else character()
  out <- suppressWarnings(system2("env", c(env, "Rscript", f), stdout = TRUE, stderr = TRUE))
  out <- out[nzchar(out) & !grepl("^(i|ℹ) |This persists|storing downloaded|^<environment", out)]
  cat("--", label, "\n")
  cat(paste0("   ", out), sep = "\n")
  cat("\n")
}

banner <- 'cat("[dbplyr", unname(getNamespaceVersion("dbplyr")), "loaded]\n")'
attach_pkg <- sprintf('suppressMessages(library(%s))', pkg)

run("old dbplyr loaded first, then the package attached",
    c('suppressMessages(library(dbplyr))', banner, attach_pkg, 'cat("<< end >>\n")'),
    libs = old_lib)

run("the package attached first, then old dbplyr loaded",
    c(attach_pkg, 'suppressMessages(library(dbplyr))', banner, 'cat("<< end >>\n")'),
    libs = old_lib)

run("the package loaded but never attached, then old dbplyr",
    c(sprintf('invisible(%s::%s())', pkg, pkg), 'suppressMessages(library(dbplyr))',
      banner, 'cat("<< end >>\n")'),
    libs = old_lib)

run("current dbplyr loaded first, then the package attached",
    c('suppressMessages(library(dbplyr))', banner, attach_pkg, 'cat("<< end >>\n")'))

run("the package attached, dbplyr never loaded",
    c(attach_pkg, 'cat("<< dbplyr loaded:", isNamespaceLoaded("dbplyr"), ">>\n")'))

run("dbplyr upgraded mid-session: library moves, the session does not",
    sprintf('
      scratch <- file.path(tempdir(), "lib"); dir.create(scratch)
      stopifnot(file.copy(file.path("%s", "dbplyr"), scratch, recursive = TRUE))
      .libPaths(c(scratch, .libPaths()))
      invisible(loadNamespace("dbplyr"))
      cat("   after loading  : packageVersion()", as.character(packageVersion("dbplyr")),
          "| getNamespaceVersion()", unname(getNamespaceVersion("dbplyr")), "\n")
      stopifnot(file.copy(file.path("%s", "dbplyr"), scratch, recursive = TRUE, overwrite = TRUE))
      cat("   after upgrading: packageVersion()", as.character(packageVersion("dbplyr")),
          "| getNamespaceVersion()", unname(getNamespaceVersion("dbplyr")), "\n")
      cat("   sql_glue() reachable in this session:",
          "sql_glue" %%in%% getNamespaceExports("dbplyr"), "\n")
      suppressMessages(library(%s))
      cat("<< end >>\n")
    ', old_lib, cur_lib, pkg))
