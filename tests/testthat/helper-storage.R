# Helpers for the storage-location tests: the paths the package resolves to
# under a mocked session temp dir, and a path comparison that survives Windows.

# The storage paths the package resolves to when `session_temp_dir()` is mocked
# to "/tmp/sess".
#
# `session_home()` names the per-session home after the running package, so the
# expected path is `/tmp/sess/duckdb` on mainline and `/tmp/sess/duckdb.dev` on
# a flavor. Asking for the name at run time keeps the expectations true for
# every flavor; see `scripts/flavor-package-name.R` for the rule.
session_home_path <- function(...) {
  file.path("/tmp/sess", get_package_name(), ...)
}

# Compare two paths that name the same directory, ignoring which separator each
# happens to be spelled with.
#
# On Windows one directory reaches these tests under two spellings. `dirname()`
# always returns "/" separators (documented in `?basename`), while `file.path()`
# and `tempdir()` keep the "\" they were handed -- and on Windows `tempdir()`
# hands back "\". So `dirname(x)` and `file.path(tempdir(), ...)` differ as
# strings while naming one directory, and `expect_equal()` reports a difference
# that is not there. Comparing on a single spelling keeps the assertion about
# the path. A no-op on Unix, where neither side contains a backslash.
expect_same_path <- function(object, expected) {
  expect_equal(chartr("\\", "/", object), chartr("\\", "/", expected))
}
