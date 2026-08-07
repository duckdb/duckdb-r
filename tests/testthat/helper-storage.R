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
