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
# The scan covers the R-level surface -- `R/`, `man/`, `tests/`, `vignettes/`, the
# Markdown files at the top level, and `README.Rmd` in place of the `README.md`
# generated from it -- plus the C++ glue in `src/` and
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
  # `README.md` is generated from `README.Rmd`, and so is `.github/README.md`
  # (which is not top-level, so it never reached this scan). The patch renames
  # the source, keying its removed lines under `README.Rmd`; a hit found in a
  # generated file would be looked up under a path the patch no longer names
  # and would read as an offender however well the rename is handled. Scanning
  # the source instead is also where a fix would have to be made.
  top_level_md <- setdiff(dir(root, pattern = "[.]md$"), "README.md")

  # `README.Rmd` is the one entry named literally rather than found by `dir()`,
  # so it is the only one that can be absent -- and on a frozen series it is:
  # the commit that adds it is not ported there
  # (.claude/skills/series-loop.md stage 4), while the tooling sync brings this
  # scan and the `scripts/flavor.patch` that keys it. Reading it unconditionally
  # turned that combination into an error rather than a verdict. Every other
  # entry is discovered, so a missing one there would be a real problem and is
  # left to fail.
  readme_rmd <- if (file.exists(file.path(root, "README.Rmd"))) "README.Rmd"

  r_level <- c(
    flavor_dir(root, "R", "[.]R$"),
    flavor_dir(root, "man", "[.]Rd$"),
    flavor_dir(root, "tests", "[.]R$"),
    flavor_dir(root, "vignettes", "[.](R|Rmd|qmd)$"),
    top_level_md,
    readme_rmd
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

# The paths `scripts/flavor.patch` renames, as mainline names relative to the
# package root. A file the patch renames carries the package name in its *name*
# rather than in its contents, so the scan above cannot see it.
flavor_renamed_paths <- function(patch_file) {
  lines <- readLines(patch_file, warn = FALSE)
  sub("^rename from ", "", lines[grepl("^rename from ", lines)])
}

# Every file that still carries the mainline name on a flavored checkout.
#
# `scripts/flavor.patch` renames these, and it runs once, when a series is
# seeded. A commit that adds such a file on `main` and is then ported onto a
# flavored series (.claude/skills/series-loop.md stage 4) brings the mainline
# name with it, and nothing rewrites it afterwards. The file is then simply not
# read: `src/duckdb-win.def` on a `duckdb.dev` build is not the export list R's
# `share/make/winshlib.mk` looks for, so the Windows link falls back to
# generating one from every object and overruns the PE export table.
#
# Empty on the mainline flavor, where the mainline name is the right one.
flavor_unflavored_paths <- function(root = ".") {
  package <- sub("^Package: +", "", grep(
    "^Package: ", readLines(file.path(root, "DESCRIPTION"), warn = FALSE),
    value = TRUE
  )[[1]])
  if (package == "duckdb") {
    return(character())
  }

  renamed <- flavor_renamed_paths(file.path(root, "scripts", "flavor.patch"))
  renamed[file.exists(file.path(root, renamed))]
}
