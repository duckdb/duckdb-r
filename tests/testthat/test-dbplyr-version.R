test_that("the declared minimum matches the DESCRIPTION floor", {
  # The declared floor, so reading DESCRIPTION is the point here -- unlike the
  # runtime check below, which must not.
  suggests <- packageDescription(get_package_name())[["Suggests"]]
  entries <- trimws(strsplit(suggests, ",")[[1]])
  entry <- grep("^dbplyr\\b", entries, value = TRUE)

  expect_length(entry, 1L)
  expect_equal(entry, paste0("dbplyr (>= ", dbplyr_min_version(), ")"))
})

test_that("the loaded version is read from the namespace, not the library", {
  skip_if_not_installed("dbplyr")

  # `getNamespaceInfo(, "spec")` is recorded when the namespace loads, so a
  # library copy replaced underneath a running session cannot change it --
  # `packageVersion()` would re-read the DESCRIPTION at that path and report a
  # version this session never loaded.
  expect_equal(
    as.character(loaded_dbplyr_version()),
    unname(getNamespaceVersion("dbplyr"))
  )
})

test_that("an old dbplyr warns, a current one is silent", {
  # Every version here is mocked, and the package is still needed: the check
  # returns early unless dbplyr's namespace is *loaded*, which is the one thing
  # `local_mocked_bindings()` cannot arrange. `skip_if_not_installed()` loads it
  # as a side effect of asking, so this is also what puts it there.
  skip_if_not_installed("dbplyr")

  local_mocked_bindings(loaded_dbplyr_version = function() {
    package_version("2.5.0")
  })
  expect_warning(
    expect_true(warn_if_dbplyr_too_old()),
    "needs dbplyr 2.6.0 or later, but dbplyr 2.5.0 is loaded"
  )

  local_mocked_bindings(loaded_dbplyr_version = function() {
    package_version("2.6.0")
  })
  expect_silent(expect_false(warn_if_dbplyr_too_old()))

  local_mocked_bindings(loaded_dbplyr_version = function() {
    package_version("2.7.1")
  })
  expect_silent(expect_false(warn_if_dbplyr_too_old()))
})

# --- message wording (snapshot) ----------------------------------------------

test_that("the warning wording is stable", {
  skip_if_not_installed("dbplyr")

  # The wording carries the package name, so it goes through the flavor
  # normalisation every snapshot that can name the package uses.
  local_mocked_bindings(loaded_dbplyr_version = function() {
    package_version("2.5.0")
  })

  expect_snapshot(
    warn_if_dbplyr_too_old(),
    transform = transform_package_name
  )
})

test_that("the warning names this package through the flavor seam", {
  skip_if_not_installed("dbplyr")

  local_mocked_bindings(
    loaded_dbplyr_version = function() package_version("2.5.0"),
    get_package_name = function() "someflavor"
  )

  expect_warning(warn_if_dbplyr_too_old(), "^someflavor's dbplyr backend")
})

test_that("a dbplyr loading later is caught by a hook", {
  # The other hooks registered there resolve `dbplyr::` when called, so calling
  # them below is an error rather than a skip when dbplyr is absent.
  skip_if_not_installed("dbplyr")

  hooks <- getHook(packageEvent("dbplyr", "onLoad"))
  expect_gt(length(hooks), 0L)

  # `.onLoad()` armed one of these to run the check. Give it a version that must
  # warn, and confirm the arrangement as a whole reacts -- the other hooks
  # registered there only register S3 methods.
  local_mocked_bindings(loaded_dbplyr_version = function() {
    package_version("2.5.0")
  })
  warned <- vapply(
    hooks,
    function(hook) {
      tryCatch(
        {
          hook("dbplyr", "")
          FALSE
        },
        warning = function(w) {
          grepl("needs dbplyr", conditionMessage(w), fixed = TRUE)
        }
      )
    },
    logical(1)
  )

  expect_true(any(warned))
})

test_that("attaching does not load dbplyr just to check its version", {
  # An absent dbplyr passes this for the wrong reason: nothing could have loaded
  # it either way.
  skip_if_not_installed("dbplyr")

  loaded <- callr::r(
    function(pkg) {
      library(pkg, character.only = TRUE)
      isNamespaceLoaded("dbplyr")
    },
    args = list(pkg = get_package_name())
  )

  expect_false(loaded)
})
