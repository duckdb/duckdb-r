CONVERT_BIGINT_NUMERIC    <- 0L
CONVERT_BIGINT_INTEGER64  <- 1L
# CONVERT_BIGINT_CHARACTER  <- 2L
# CONVERT_BIGINT_INTEGER    <- 3L
CONVERT_BIGINT_MASK <- 3L

CONVERT_ARROW <- 0x10000000L

convert_opts_from_args <- function(bigint) {
  out <- 0L

  if (bigint == "numeric") {
    out <- bitwOr(out, CONVERT_BIGINT_NUMERIC)
  } else if (bigint == "integer64") {
    if (!is_installed("bit64")) {
      stop("bit64 package is required for integer64 support")
    }
    out <- bitwOr(out, CONVERT_BIGINT_INTEGER64)
  } else {
    stop(paste0("Unsupported bigint configuration: ", bigint_type))
  }

  out
}

bigint_from_convert_opts <- function(convert_opts) {
  if (bitwAnd(convert_opts, CONVERT_BIGINT_MASK) == CONVERT_BIGINT_NUMERIC) {
    "numeric"
  } else if (bitwAnd(convert_opts, CONVERT_BIGINT_MASK) == CONVERT_BIGINT_INTEGER64) {
    "integer64"
  } else {
    stop("Unsupported bigint configuration")
  }
}

convert_opts_set_arrow <- function(convert_opts, arrow) {
  if (arrow) {
    bitwOr(convert_opts, CONVERT_ARROW)
  } else {
    bitwAnd(convert_opts, bitwNot(CONVERT_ARROW))
  }
}
