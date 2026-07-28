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
  if (file.exists(file.path(root, "scripts", "flavor-package-name.R"))) root else NA_character_
}

test_that("the package name is hard-coded only where scripts/flavor.patch rewrites it", {
  root <- lts_source_root()
  skip_if(is.na(root), "Not running from the package source tree.")

  source(file.path(root, "scripts", "flavor-package-name.R"), local = TRUE)

  expect_equal(flavor_package_name_offenders(root), character())
})
