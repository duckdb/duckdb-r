# Explained in handbook/usage/integrations/README.md.

# The dbplyr release the backend needs. `test-dbplyr-version.R` pins this to the
# `Suggests` floor in DESCRIPTION, so the two cannot drift apart.
dbplyr_min_version <- function() {
  "2.6.0"
}

# The version of the dbplyr that is *loaded*, which is not always the one on
# disk: a library copy can be replaced under a running session, and
# `packageVersion()` re-reads DESCRIPTION from that path, so it would report a
# version this session will never call. The `"spec"` namespace info is recorded
# when the namespace loads, so it names what the backend will actually reach --
# the same way `get_package_version()` reads this package's own version.
loaded_dbplyr_version <- function() {
  package_version(getNamespaceInfo(asNamespace("dbplyr"), "spec")[["version"]])
}

# Warn when the loaded dbplyr is older than the backend needs. Silent -- and
# careful not to load dbplyr itself -- when dbplyr is absent: the backend is
# only reachable once something else has loaded it.
warn_if_dbplyr_too_old <- function() {
  if (!isNamespaceLoaded("dbplyr")) {
    return(invisible(FALSE))
  }

  min_version <- dbplyr_min_version()
  version <- loaded_dbplyr_version()
  if (version >= min_version) {
    return(invisible(FALSE))
  }

  warning(
    sprintf(
      paste0(
        "%s's dbplyr backend needs dbplyr %s or later, but dbplyr %s is loaded.\n",
        "Translations such as `n_distinct()` will fail.\n",
        "Install a newer dbplyr and restart R."
      ),
      get_package_name(),
      min_version,
      version
    ),
    call. = FALSE
  )

  invisible(TRUE)
}
