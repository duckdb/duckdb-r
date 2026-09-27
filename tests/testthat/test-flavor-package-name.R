# The flavored builds ship this package under a different name, and scripts/flavor.patch
# is what renames it. This test fails when the name is hard-coded somewhere the
# patch does not rewrite; scripts/flavor-package-name.R explains the rules and holds
# the scan itself.
#
# The scan needs the sources and scripts/flavor.patch, so it only runs from a
# checkout. `R CMD check` works from a built tarball, which has neither, and
# skips -- CI therefore runs the same scan directly against the checkout, see
# .github/workflows/custom/after-install.

# The package source root, or NA when the sources are not around.
lts_source_root <- function() {
  root <- normalizePath(test_path("..", ".."), mustWork = FALSE)
  if (file.exists(file.path(root, "scripts", "flavor-package-name.R"))) {
    root
  } else {
    NA_character_
  }
}

test_that("the package name is hard-coded only where scripts/flavor.patch rewrites it", {
  root <- lts_source_root()
  skip_if(is.na(root), "Not running from the package source tree.")

  source(file.path(root, "scripts", "flavor-package-name.R"), local = TRUE)

  expect_equal(flavor_package_name_offenders(root), character())
})

test_that("no file still carries the mainline name that scripts/flavor.patch renames", {
  root <- lts_source_root()
  skip_if(is.na(root), "Not running from the package source tree.")

  source(file.path(root, "scripts", "flavor-package-name.R"), local = TRUE)

  expect_equal(flavor_unflavored_paths(root), character())
})

test_that("no generated README tells a reader to install the mainline package", {
  root <- lts_source_root()
  skip_if(is.na(root), "Not running from the package source tree.")

  source(file.path(root, "scripts", "flavor-package-name.R"), local = TRUE)

  expect_equal(flavor_mainline_readme_offenders(root), character())
})

test_that("scripts/flavor.patch applies to the unflavored tree", {
  root <- lts_source_root()
  skip_if(is.na(root), "Not running from the package source tree.")

  source(file.path(root, "scripts", "flavor-package-name.R"), local = TRUE)

  expect_equal(flavor_patch_failures(root), character())
})

test_that("both halves of the cpp11 binding carry this flavor's prefix", {
  root <- lts_source_root()
  skip_if(is.na(root), "Not running from the package source tree.")

  source(file.path(root, "scripts", "flavor-package-name.R"), local = TRUE)

  expect_equal(flavor_binding_prefix_offenders(root), character())
})

test_that("the cpp11 binding prefix follows the flavor's package name", {
  root <- withr::local_tempdir()
  dir.create(file.path(root, "R"))
  writeLines("Package: duckdb.2.0.dev", file.path(root, "DESCRIPTION"))
  writeLines(
    c(
      "rapi_flavored <- function() {",
      "  .Call(`_duckdb_2_0_dev_rapi_flavored`)",
      "}",
      "rapi_unflavored <- function() {",
      "  .Call(`_duckdb_rapi_unflavored`)",
      "}"
    ),
    file.path(root, "R", "cpp11.R")
  )

  source(
    file.path(lts_source_root(), "scripts", "flavor-package-name.R"),
    local = TRUE
  )

  expect_equal(flavor_binding_prefix(root), "_duckdb_2_0_dev_")
  expect_equal(
    flavor_binding_prefix_offenders(root),
    "R/cpp11.R:5: .Call(`_duckdb_rapi_unflavored`)"
  )
})
