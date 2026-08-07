# Make snapshot output independent of the package name.
#
# Every flavor but the mainline one ships under a different name -- `duckdb.dev`,
# `duckdb.1.4`, ... -- and anything the package derives from `get_package_name()`
# carries that name into the output it produces. Storage paths are the obvious
# case: the session home is `<tempdir>/<package name>`, so the same code prints
# `/tmp/sess/duckdb` on mainline and `/tmp/sess/duckdb.dev` on a flavor.
#
# `scripts/lts.patch` deliberately does not rewrite `tests/testthat/_snaps/`
# (see `scripts/lts-package-name.R`), so a snapshot recorded on one flavor can
# never match another. Rather than teach the patch about snapshots -- which
# would mean rewriting recorded output, and would still leave the file wrong for
# whichever flavor recorded it -- normalise at capture time: replace the running
# package's name with the mainline one, so every flavor records the same text.
#
# The mainline name is assembled from two pieces on purpose. Spelled out, it
# would be an offender under `lts_package_name_offenders()` -- and rewriting it
# is exactly what must not happen here, because this literal is the
# normalisation target rather than a reference to the package.
transform_package_name <- function(x) {
  mainline <- paste0("duck", "db")
  name <- get_package_name()
  if (identical(name, mainline)) {
    return(x)
  }
  gsub(name, mainline, x, fixed = TRUE)
}
