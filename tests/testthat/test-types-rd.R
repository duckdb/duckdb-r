# The type reference pages, ?duckdb_types and its siblings, are rendered from
# handbook leaves by scripts/types-rd.R (handbook/usage/types/README.md).
# This test fails when a leaf was edited without re-running the script.
#
# The script needs handbook/ and a git checkout, so it only runs from one.
# `R CMD check` works from a built tarball, which has neither, and skips;
# CI therefore runs the same check against the checkout, see
# .github/workflows/custom/after-install.

test_that("the type reference pages match their handbook leaves", {
  root <- normalizePath(test_path("..", ".."), mustWork = FALSE)
  script <- file.path(root, "scripts", "types-rd.R")
  # `.git` is a directory in a clone and a file in a worktree.
  skip_if_not(
    file.exists(script) &&
      dir.exists(file.path(root, "handbook")) &&
      file.exists(file.path(root, ".git")),
    "Not running from a git checkout of the package source."
  )
  skip_if(Sys.which("git") == "", "git is not available.")

  out <- withr::with_dir(
    root,
    suppressWarnings(system2(
      file.path(R.home("bin"), "Rscript"),
      c(script, "--check"),
      stdout = TRUE,
      stderr = TRUE
    ))
  )
  expect_null(attr(out, "status"), label = paste(out, collapse = "\n"))
})
