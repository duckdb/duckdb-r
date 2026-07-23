# Extensions are disabled on a Linux build not compiled with libstdc++, where
# loading a prebuilt (libstdc++) extension crashes R (duckdb/duckdb-r#1107). The
# per-driver decision is made in R by resolve_allow_extensions() and plumbed to
# the engine; the detection seams (is_linux(), compiled_cxx_stdlib()) are mocked
# here, like is_windows().

test_that("extensions_supported() is FALSE on Linux unless the stdlib is libstdc++", {
  local_mocked_bindings(
    is_linux = function() TRUE,
    compiled_cxx_stdlib = function() "libc++"
  )
  expect_false(extensions_supported())

  # An unidentified stdlib is treated conservatively (also disabled).
  local_mocked_bindings(
    is_linux = function() TRUE,
    compiled_cxx_stdlib = function() "<an unknown C++ library>"
  )
  expect_false(extensions_supported())
})

test_that("extensions_supported() is TRUE for libstdc++ and for non-Linux", {
  # libstdc++ is the matching, safe standard library.
  local_mocked_bindings(
    is_linux = function() TRUE,
    compiled_cxx_stdlib = function() "libstdc++"
  )
  expect_true(extensions_supported())

  # Non-Linux is unaffected regardless of stdlib (macOS is libc++, but its
  # prebuilt extensions match).
  local_mocked_bindings(
    is_linux = function() FALSE,
    compiled_cxx_stdlib = function() "libc++"
  )
  expect_true(extensions_supported())

  local_mocked_bindings(
    is_linux = function() FALSE,
    compiled_cxx_stdlib = function() "libstdc++"
  )
  expect_true(extensions_supported())
})

test_that("compiled_cxx_stdlib() reports a known standard library", {
  # The real compile-time value on the CI/test toolchain; just assert it is one
  # of the recognized tokens (guards against the macro logic silently breaking).
  expect_true(
    compiled_cxx_stdlib() %in% c("libc++", "libstdc++", "<an unknown C++ library>")
  )
})

# --- resolve_allow_extensions() ----------------------------------------------

test_that("resolve_allow_extensions(NULL) on an affected build disables + announces", {
  withr::local_options(duckdb.allow_extensions = NULL)
  withr::local_envvar(DUCKDB_R_ALLOW_EXTENSIONS = NA)
  local_mocked_bindings(extensions_supported = function() FALSE)

  res <- resolve_allow_extensions(NULL)
  expect_false(res$allow)
  expect_true(res$announce)
  expect_identical(res$source, "auto")
})

test_that("resolve_allow_extensions(NULL) on a healthy build enables + stays quiet", {
  withr::local_options(duckdb.allow_extensions = NULL)
  withr::local_envvar(DUCKDB_R_ALLOW_EXTENSIONS = NA)
  local_mocked_bindings(extensions_supported = function() TRUE)

  res <- resolve_allow_extensions(NULL)
  expect_true(res$allow)
  expect_false(res$announce)
  expect_identical(res$source, "auto")
})

test_that("an explicit allow_extensions argument wins and is silent", {
  withr::local_options(duckdb.allow_extensions = NULL)
  withr::local_envvar(DUCKDB_R_ALLOW_EXTENSIONS = NA)
  # Even on an affected build, the explicit argument decides and never announces.
  local_mocked_bindings(extensions_supported = function() FALSE)

  res_true <- resolve_allow_extensions(TRUE)
  expect_true(res_true$allow)
  expect_false(res_true$announce)
  expect_identical(res_true$source, "argument")

  res_false <- resolve_allow_extensions(FALSE)
  expect_false(res_false$allow)
  expect_false(res_false$announce)
  expect_identical(res_false$source, "argument")
})

test_that("the duckdb.allow_extensions option is honored (and silent)", {
  withr::local_envvar(DUCKDB_R_ALLOW_EXTENSIONS = NA)
  local_mocked_bindings(extensions_supported = function() FALSE)

  withr::local_options(duckdb.allow_extensions = TRUE)
  res_true <- resolve_allow_extensions(NULL)
  expect_true(res_true$allow)
  expect_false(res_true$announce)
  expect_identical(res_true$source, "option")

  withr::local_options(duckdb.allow_extensions = FALSE)
  res_false <- resolve_allow_extensions(NULL)
  expect_false(res_false$allow)
  expect_false(res_false$announce)
  expect_identical(res_false$source, "option")
})

test_that("a malformed duckdb.allow_extensions option warns and is reset", {
  withr::local_envvar(DUCKDB_R_ALLOW_EXTENSIONS = NA)
  withr::local_options(duckdb.allow_extensions = "yes")
  local_mocked_bindings(extensions_supported = function() TRUE)

  expect_warning(res <- resolve_allow_extensions(NULL), "must be TRUE, FALSE, or NULL")
  # Falls through to the auto path once the bad option is cleared.
  expect_identical(res$source, "auto")
  expect_true(res$allow)
  expect_null(getOption("duckdb.allow_extensions"))
})

test_that("DUCKDB_R_ALLOW_EXTENSIONS enables or disables per as.logical()", {
  withr::local_options(duckdb.allow_extensions = NULL)
  # Supported build, so the auto path would enable; this isolates the env var.
  local_mocked_bindings(extensions_supported = function() TRUE)

  # A value R reads as TRUE enables via the env var.
  withr::with_envvar(list(DUCKDB_R_ALLOW_EXTENSIONS = "TRUE"), {
    res <- resolve_allow_extensions(NULL)
    expect_true(res$allow)
    expect_false(res$announce)
    expect_identical(res$source, "env")
  })

  # A value R reads as FALSE disables, even though the auto path would enable.
  withr::with_envvar(list(DUCKDB_R_ALLOW_EXTENSIONS = "false"), {
    res <- resolve_allow_extensions(NULL)
    expect_false(res$allow)
    expect_identical(res$source, "env")
  })

  # An unparseable or empty value is NA -- undecided -- and falls through to auto.
  for (v in c("", "1", "maybe")) {
    withr::with_envvar(list(DUCKDB_R_ALLOW_EXTENSIONS = v), {
      res <- resolve_allow_extensions(NULL)
      expect_identical(res$source, "auto")
    })
  }
})

test_that("an unparseable DUCKDB_R_ALLOW_EXTENSIONS is treated as completely unset", {
  withr::local_options(duckdb.allow_extensions = NULL)
  # Affected build: the auto path disables extensions and announces.
  local_mocked_bindings(extensions_supported = function() FALSE)

  # Baseline: with the variable unset, the advisory fires (the library mismatch
  # is genuinely the cause).
  withr::with_envvar(list(DUCKDB_R_ALLOW_EXTENSIONS = NA), {
    res <- resolve_allow_extensions(NULL)
    expect_identical(res$source, "auto")
    expect_false(res$allow)
    expect_true(res$announce)
  })

  # A value as.logical() reads as neither TRUE nor FALSE is ignored entirely --
  # same source, decision, and advisory as if the variable were unset.
  for (v in c("", "1", "yes", "maybe")) {
    withr::with_envvar(list(DUCKDB_R_ALLOW_EXTENSIONS = v), {
      res <- resolve_allow_extensions(NULL)
      expect_identical(res$source, "auto")
      expect_false(res$allow)
      expect_true(res$announce)
    })
  }
})

# --- duckdb() advisory message ------------------------------------------------

# Clear the "extensions" throttle key so message tests are order-independent.
reset_extensions_throttle <- function(env = parent.frame()) {
  storage_message_state[["extensions"]] <- NULL
  withr::defer(storage_message_state[["extensions"]] <- NULL, envir = env)
}

test_that("duckdb() announces on the auto path when extensions are disabled", {
  skip_on_cran()
  withr::local_options(
    duckdb.allow_extensions = NULL,
    duckdb.home = withr::local_tempdir(),
    rlang_interactive = FALSE
  )
  withr::local_envvar(DUCKDB_R_ALLOW_EXTENSIONS = NA)
  local_mocked_bindings(extensions_supported = function() FALSE)
  reset_extensions_throttle()

  drv <- NULL
  expect_message(drv <- duckdb(), "extensions are disabled")
  duckdb_shutdown(drv)
})

test_that("duckdb(allow_extensions = FALSE) is silent", {
  skip_on_cran()
  withr::local_options(
    duckdb.allow_extensions = NULL,
    duckdb.home = withr::local_tempdir(),
    rlang_interactive = FALSE
  )
  withr::local_envvar(DUCKDB_R_ALLOW_EXTENSIONS = NA)
  local_mocked_bindings(extensions_supported = function() FALSE)
  reset_extensions_throttle()

  drv <- NULL
  expect_no_message(drv <- duckdb(allow_extensions = FALSE))
  duckdb_shutdown(drv)
})

test_that("an option or env override silences the duckdb() advisory", {
  skip_on_cran()
  withr::local_options(
    duckdb.home = withr::local_tempdir(),
    rlang_interactive = FALSE
  )
  local_mocked_bindings(extensions_supported = function() FALSE)

  # Option set: no advisory.
  withr::with_options(
    list(duckdb.allow_extensions = FALSE),
    {
      reset_extensions_throttle()
      drv <- NULL
      expect_no_message(drv <- duckdb())
      duckdb_shutdown(drv)
    }
  )

  # Env set (a value as.logical() parses): no advisory.
  withr::with_options(
    list(duckdb.allow_extensions = NULL),
    withr::with_envvar(
      list(DUCKDB_R_ALLOW_EXTENSIONS = "false"),
      {
        reset_extensions_throttle()
        drv <- NULL
        expect_no_message(drv <- duckdb())
        duckdb_shutdown(drv)
      }
    )
  )
})

test_that("duckdb() still announces when DUCKDB_R_ALLOW_EXTENSIONS is unparseable", {
  skip_on_cran()
  # A value as.logical() cannot read as TRUE/FALSE is treated as completely
  # unset, so the auto advisory fires exactly as it would with no variable set.
  withr::local_options(
    duckdb.allow_extensions = NULL,
    duckdb.home = withr::local_tempdir(),
    rlang_interactive = FALSE
  )
  local_mocked_bindings(extensions_supported = function() FALSE)
  reset_extensions_throttle()

  drv <- NULL
  withr::with_envvar(
    list(DUCKDB_R_ALLOW_EXTENSIONS = "1"),
    expect_message(drv <- duckdb(), "extensions are disabled")
  )
  duckdb_shutdown(drv)
})

# --- message wording (snapshot) ----------------------------------------------

test_that("extensions message wording is stable", {
  # The advisory names the detected C++ standard library as the cause and is only
  # shown on the auto path, so snapshot both stdlib variants that reach it.
  local_mocked_bindings(compiled_cxx_stdlib = function() "libc++")
  expect_snapshot(rlang::inform(extensions_disabled_message()))

  local_mocked_bindings(compiled_cxx_stdlib = function() "<an unknown C++ library>")
  expect_snapshot(rlang::inform(extensions_disabled_message()))

  # The INSTALL / LOAD refusal error is cause-neutral: it fires both on the
  # auto-disable path and for an explicit duckdb(allow_extensions = FALSE), so it
  # never names the library. Snapshot it through the centralized rapi_error()
  # bridge the C++ guard calls with context "load_extension" and an empty message.
  expect_snapshot(rapi_error("load_extension", ""), error = TRUE)
})

# --- driver slots -------------------------------------------------------------

test_that("duckdb() exposes the experimental allow_extensions slot", {
  skip_on_cran()
  drv <- duckdb()
  on.exit(duckdb_shutdown(drv))
  expect_type(drv@allow_extensions, "logical")
})

# --- plumbing integration (works on any platform) -----------------------------

test_that("allow_extensions is plumbed to the engine's INSTALL/LOAD guard", {
  # rapi_startup has a CRAN poison guard, so this exercises the C++ path only in
  # our own CI, not on CRAN.
  skip_on_cran()

  # A driver created with extensions disabled refuses LOAD before the engine
  # dlopen()s anything, regardless of the build's stdlib.
  con <- dbConnect(duckdb(allow_extensions = FALSE))
  on.exit(dbDisconnect(con, shutdown = TRUE))
  expect_error(dbExecute(con, "LOAD spatial"), "disabled")

  # Positive control: with extensions enabled the disabled-guard must NOT fire.
  # A LOAD may still fail for another reason (e.g. the extension is unavailable
  # or cannot be downloaded); only the guard's "disabled" error is forbidden.
  con2 <- dbConnect(duckdb(allow_extensions = TRUE))
  on.exit(dbDisconnect(con2, shutdown = TRUE), add = TRUE)
  expect_error(
    tryCatch(
      dbExecute(con2, "LOAD spatial"),
      error = function(e) {
        if (grepl("disabled", conditionMessage(e), fixed = TRUE)) {
          stop(e)
        }
        invisible(NULL)
      }
    ),
    NA
  )
})
