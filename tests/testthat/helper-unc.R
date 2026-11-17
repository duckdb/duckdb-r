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
# Skips off Windows, and where the share cannot be written to quickly:
# a stalled share would otherwise hang or fail the tests
# for reasons that have nothing to do with path handling.
local_unc_tempdir <- function(.local_envir = parent.frame()) {
  skip_if_not(.Platform$OS.type == "windows", "UNC paths are Windows-only")
  dir <- normalizePath(
    withr::local_tempdir(.local_envir = .local_envir),
    winslash = "\\"
  )
  unc <- paste0("\\\\localhost\\", substr(dir, 1, 1), "$", substring(dir, 3))
  skip_if_not(
    unc_share_writable(unc),
    paste0("The administrative share is not writable within 10 s: ", unc)
  )
  list(dir = dir, unc = unc)
}

# Whether a file can be written to and removed from `unc` within `timeout` s.
# A child process does the probe,
# because a stalled share can block a file call in R itself for minutes.
unc_share_writable <- function(unc, timeout = 10) {
  probe <- paste0(unc, "\\unc-probe.txt")
  status <- suppressWarnings(system2(
    "cmd.exe",
    c(
      "/c",
      paste0(
        "echo x>",
        shQuote(probe, type = "cmd"),
        " && del ",
        shQuote(probe, type = "cmd")
      )
    ),
    stdout = FALSE,
    stderr = FALSE,
    timeout = timeout
  ))
  identical(as.integer(status), 0L)
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
