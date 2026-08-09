# Which R API reports the version of the *loaded* package, and which re-reads
# the library copy that may have changed underneath it?
#
# Builds a throwaway package, loads it, reinstalls a newer one over the top --
# the shape of `install.packages()` in a running session -- and asks each API.

lib <- file.path(tempdir(), "lib")
src <- file.path(tempdir(), "fakedep")
dir.create(lib, showWarnings = FALSE)

make_pkg <- function(version) {
  unlink(src, recursive = TRUE)
  dir.create(file.path(src, "R"), recursive = TRUE)
  writeLines(
    c(
      "Package: fakedep", paste0("Version: ", version), "Title: Fake",
      "Description: Fake.", "Author: N", "Maintainer: N <n@e.com>",
      "License: MIT + file LICENSE", "Encoding: UTF-8"
    ),
    file.path(src, "DESCRIPTION")
  )
  writeLines("MIT", file.path(src, "LICENSE"))
  writeLines("fakedep_marker <- function() 'x'", file.path(src, "R", "f.R"))
  writeLines("export(fakedep_marker)", file.path(src, "NAMESPACE"))
  res <- callr::rcmd("INSTALL", c(src, paste0("--library=", lib)), show = FALSE)
  stopifnot(res$status == 0)
}

report <- function(when) {
  cat(sprintf(
    "%-26s packageVersion()=%-7s packageDescription()=%-7s getNamespaceVersion()=%s\n",
    when,
    as.character(utils::packageVersion("fakedep")),
    utils::packageDescription("fakedep")$Version,
    unname(getNamespaceVersion("fakedep"))
  ))
}

make_pkg("1.0.0")
invisible(loadNamespace("fakedep", lib.loc = lib))
report("loaded 1.0.0")

make_pkg("2.0.0")  # reinstalled over the top, session still running
report("library now 2.0.0")

cat("\nnamespace still loaded:", isNamespaceLoaded("fakedep"), "\n")
cat("still running the 1.0.0 code:", fakedep::fakedep_marker() == "x", "\n")

# The other direction: a source tree loaded with pkgload, never installed. Here
# the two agree -- `packageVersion()` follows the namespace's path, which is the
# source tree, so `load_all()` is not where they diverge.
src2 <- file.path(tempdir(), "fakedep2")
unlink(src2, recursive = TRUE)
dir.create(file.path(src2, "R"), recursive = TRUE)
writeLines(
  c(
    "Package: fakedep2", "Version: 9.9.9", "Title: Fake", "Description: Fake.",
    "Author: N", "Maintainer: N <n@e.com>", "License: MIT + file LICENSE",
    "Encoding: UTF-8"
  ),
  file.path(src2, "DESCRIPTION")
)
writeLines("MIT", file.path(src2, "LICENSE"))
writeLines("fakedep2_marker <- function() 'x'", file.path(src2, "R", "f.R"))
writeLines("export(fakedep2_marker)", file.path(src2, "NAMESPACE"))
suppressMessages(pkgload::load_all(src2, quiet = TRUE))
cat(sprintf(
  "\nunder load_all(): packageVersion()=%s getNamespaceVersion()=%s\n",
  as.character(utils::packageVersion("fakedep2")),
  unname(getNamespaceVersion("fakedep2"))
))
