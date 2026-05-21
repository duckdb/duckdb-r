rlang::local_options(arrow_duck_con = default_conn())

# Clean up extension cache on CRAN
withr::defer(envir = testthat::teardown_env(), tryCatch(
  {
    skip_on_cran()
  },
  skip = function(e) {
    cleanup_user_directory()
  }
))
