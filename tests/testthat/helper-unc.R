# Fixtures for the Windows network (UNC) path tests
# in `test-unc-path.R` (#2882):
# a temporary directory reached through the administrative share
# `\\localhost\C$`, which stands in for a network drive,
# and the spellings of a path below it that R hands out.

# A temporary directory and its UNC spelling, `\\localhost\<drive>$\...`.
#
# Returns a list with the local `dir` and the `unc` path to the same directory,
# both with backslashes;
# the directory is removed when `.local_envir` exits.
# Skips off Windows, and where the share is not reachable,
# except on GitHub Actions:
# the share is known reachable on its Windows runners,
# so there a skip would only hide the tests,
# and an unreachable share is an error instead.
local_unc_tempdir <- function(.local_envir = parent.frame()) {
  skip_if_not(.Platform$OS.type == "windows", "UNC paths are Windows-only")
  dir <- normalizePath(
    withr::local_tempdir(.local_envir = .local_envir),
    winslash = "\\"
  )
  unc <- paste0("\\\\localhost\\", substr(dir, 1, 1), "$", substring(dir, 3))
  if (!dir.exists(unc)) {
    if (identical(Sys.getenv("GITHUB_ACTIONS"), "true")) {
      stop(
        "The administrative share is not reachable on GitHub Actions: ",
        unc,
        call. = FALSE
      )
    }
    skip(paste0("The administrative share is not reachable: ", unc))
  }
  list(dir = dir, unc = unc)
}

# A path below a UNC directory under each spelling DuckDB must accept:
# `\\server\share\x`, `//server/share/x`, the mixed `\\server/share/x`,
# and `file.path()`'s backslash root with a forward-slash tail.
unc_spellings <- function(unc, ...) {
  tail <- c(...)
  slashed <- chartr("\\", "/", substring(unc, 3))
  list(
    backslash = paste(c(unc, tail), collapse = "\\"),
    slash = paste(c(paste0("//", slashed), tail), collapse = "/"),
    mixed = paste(c(paste0("\\\\", slashed), tail), collapse = "/"),
    filepath = do.call(file.path, as.list(c(unc, tail)))
  )
}
