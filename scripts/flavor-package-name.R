# Guard for the flavor rename.
#
# Every flavor but the mainline one ships this package under a different name:
# `scripts/flavor.sh` applies `scripts/flavor.patch`, which renames `duckdb` to
# `duckdb.1.4`, `duckdb.1.4.dev`, `duckdb.dev`, and so on. See BRANCHES.md.
#
# Every hard-coded `duckdb::`, `duckdb:::`, or `"duckdb"` that the patch does not
# rewrite keeps pointing at the mainline package in those builds -- silently, and
# usually only noticed by a user. `flavor_package_name_offenders()` returns every
# such occurrence, so a new one has to be dealt with deliberately:
#
# * in code, ask for the name at run time with `get_package_name()`;
# * in docs, do not qualify our own objects with `duckdb::`;
# * if the literal names something else that happens to be spelled the same --
#   the DuckDB CLI executable, say -- write it in two pieces, as
#   `paste0("duck", "db")`, so it reads as what it is;
# * otherwise teach `scripts/flavor.patch` to rewrite it.
#
# The scan covers the R-level surface -- `R/`, `man/`, `tests/`, `vignettes/`, and
# the Markdown files at the top level -- plus the C++ glue in `src/` and
# `inst/include/`. In the glue only the quoted form is checked: `duckdb::` there is
# the engine's C++ namespace, which has nothing to do with the R package name.
# Vendored sources under `src/duckdb/` and testthat snapshots are left alone.
#
# Base R only, and no reliance on the package being loaded, so that CI can run
# this against a plain checkout (see .github/workflows/custom/after-install).
# `tests/testthat/test-flavor-package-name.R` wraps it for `testthat::test_local()`;
# that test cannot carry the check on its own, because `R CMD check` runs the
# tests from a built tarball, where neither the sources nor this directory
# (`.Rbuildignore`d) exist.

# The lines `scripts/flavor.patch` rewrites, as a list of trimmed source lines keyed
# by the path they are rewritten in. These are exactly the occurrences the flavor
# rename already accounts for.
flavor_patched_lines <- function(patch_file) {
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
flavor_dir <- function(root, subdir, pattern) {
  file.path(subdir, dir(file.path(root, subdir), pattern = pattern, recursive = TRUE))
}

# The files to scan, as paths relative to `root`, each named by the pattern that
# applies to it.
flavor_scanned_files <- function(root) {
  r_level <- c(
    flavor_dir(root, "R", "[.]R$"),
    flavor_dir(root, "man", "[.]Rd$"),
    flavor_dir(root, "tests", "[.]R$"),
    flavor_dir(root, "vignettes", "[.](R|Rmd|qmd)$"),
    dir(root, pattern = "[.]md$")
  )

  glue <- c(
    flavor_dir(root, "src", "[.](c|h|cpp|hpp)$"),
    flavor_dir(root, file.path("inst", "include"), "[.](h|hpp)$")
  )
  glue <- glue[!startsWith(glue, paste0(file.path("src", "duckdb"), "/"))]

  patterns <- c(
    rep('duckdb:::?|"duckdb"', length(r_level)),
    rep('"duckdb"', length(glue))
  )
  names(patterns) <- c(r_level, glue)
  patterns
}

# Every hard-coded occurrence of the package name that `scripts/flavor.patch` does
# not rewrite, as `path:line: content` strings. Empty when all is well.
flavor_package_name_offenders <- function(root = ".") {
  patched <- flavor_patched_lines(file.path(root, "scripts", "flavor.patch"))
  scanned <- flavor_scanned_files(root)

  offenders <- character()

  for (i in seq_along(scanned)) {
    path <- names(scanned)[[i]]
    lines <- readLines(file.path(root, path), warn = FALSE)

    for (hit in grep(scanned[[i]], lines)) {
      line <- trimws(lines[[hit]])
      if (line %in% patched[[path]]) next
      offenders <- c(offenders, paste0(path, ":", hit, ": ", line))
    }
  }

  offenders
}
