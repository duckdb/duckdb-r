# The LTS builds ship this package under a different name: `scripts/lts.sh`
# applies `scripts/lts.patch`, which renames `duckdb` to `duckdb.1.3`,
# `duckdb.1.5`, and so on.
#
# Every hard-coded `duckdb::`, `duckdb:::`, or `"duckdb"` that the patch does not
# rewrite keeps pointing at the mainline package in those builds -- silently, and
# usually only noticed by a user. This test fails as soon as such an occurrence
# appears outside the patch, so that a new one has to be dealt with deliberately:
#
# * in code, ask for the name at run time with `get_package_name()`;
# * in docs, do not qualify our own objects with `duckdb::`;
# * if the literal really has to be there, teach `scripts/lts.patch` to rewrite it.
#
# The scan covers the R-level surface -- `R/`, `man/`, `tests/`, `vignettes/`, and
# the Markdown files at the top level -- plus the C++ glue in `src/` and
# `inst/include/`. In the glue only the quoted form is checked: `duckdb::` there is
# the engine's C++ namespace, which has nothing to do with the R package name.
# Vendored sources under `src/duckdb/` and testthat snapshots are left alone.

# The package source root, or NA when the tests run from an installed package
# (`R CMD check` copies `tests/` alone, without the sources this test reads).
lts_source_root <- function() {
  root <- normalizePath(test_path("..", ".."), mustWork = FALSE)
  if (file.exists(file.path(root, "scripts", "lts.patch"))) root else NA_character_
}

# Occurrences that name something other than this R package, and must therefore
# stay literal in the LTS builds as well. Values are the trimmed source lines.
lts_allowed_outside_patch <- list(
  # The name of the DuckDB CLI executable on the PATH, not of the R package.
  "tests/testthat/test-storage-cli-e2e.R" = 'unname(Sys.which("duckdb"))'
)

# The lines `scripts/lts.patch` rewrites, as a list of trimmed source lines keyed
# by the path they are rewritten in. These are exactly the occurrences the LTS
# rename already accounts for.
lts_patched_lines <- function(patch_file) {
  lines <- readLines(patch_file, warn = FALSE)
  patched <- list()
  path <- NA_character_

  for (line in lines) {
    if (grepl("^diff --git a/", line)) {
      path <- sub("^diff --git a/(.*) b/.*$", "\\1", line)
    } else if (!is.na(path) && grepl("^-", line) && !grepl("^---", line)) {
      patched[[path]] <- c(patched[[path]], trimws(substring(line, 2)))
    }
  }

  patched
}

# Paths under `subdir` matching `pattern`, relative to the package root.
lts_dir <- function(root, subdir, pattern) {
  file.path(subdir, dir(file.path(root, subdir), pattern = pattern, recursive = TRUE))
}

# The files to scan, as paths relative to `root`, each named by the pattern that
# applies to it.
lts_scanned_files <- function(root) {
  r_level <- c(
    lts_dir(root, "R", "[.]R$"),
    lts_dir(root, "man", "[.]Rd$"),
    lts_dir(root, "tests", "[.]R$"),
    lts_dir(root, "vignettes", "[.](R|Rmd|qmd)$"),
    dir(root, pattern = "[.]md$")
  )
  # This file spells out the very patterns it looks for.
  r_level <- setdiff(r_level, file.path("tests", "testthat", "test-lts-package-name.R"))

  glue <- c(
    lts_dir(root, "src", "[.](c|h|cpp|hpp)$"),
    lts_dir(root, file.path("inst", "include"), "[.](h|hpp)$")
  )
  glue <- glue[!startsWith(glue, paste0(file.path("src", "duckdb"), "/"))]

  patterns <- c(
    rep('duckdb:::?|"duckdb"', length(r_level)),
    rep('"duckdb"', length(glue))
  )
  names(patterns) <- c(r_level, glue)
  patterns
}

test_that("the hard-coded package name occurs only where scripts/lts.patch rewrites it", {
  root <- lts_source_root()
  skip_if(is.na(root), "Not running from the package source tree.")

  patched <- lts_patched_lines(file.path(root, "scripts", "lts.patch"))
  scanned <- lts_scanned_files(root)

  offenders <- character()

  for (i in seq_along(scanned)) {
    path <- names(scanned)[[i]]
    lines <- readLines(file.path(root, path), warn = FALSE)
    hits <- grep(scanned[[i]], lines)

    for (hit in hits) {
      line <- trimws(lines[[hit]])
      if (line %in% patched[[path]]) next
      if (line %in% lts_allowed_outside_patch[[path]]) next
      offenders <- c(offenders, paste0(path, ":", hit, ": ", line))
    }
  }

  expect_equal(offenders, character())
})
