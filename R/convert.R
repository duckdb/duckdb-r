duckdb_convert_opts <- function(
  ...,
  timezone_out = "UTC",
  tz_out_convert = c("with", "force"),
  bigint = "numeric",
  array = "none",
  geometry = "blob"
) {
  tz_out_convert <- match.arg(tz_out_convert)
  timezone_out <- check_tz(timezone_out)

  if (bigint == "integer64") {
    if (!is_installed("bit64")) {
      stop("bit64 package is required for integer64 support")
    }
  } else if (bigint != "numeric") {
    stop(paste0("Unsupported bigint configuration: ", bigint))
  }

  if (geometry == "wk") {
    if (!is_installed("wk")) {
      stop("wk package is required for geometry = \"wk\" support")
    }
  } else if (geometry != "blob") {
    stop(paste0("Unsupported geometry configuration: ", geometry))
  }

  duckdb_convert_opts_impl(
    timezone_out = timezone_out,
    tz_out_convert = tz_out_convert,
    bigint = bigint,
    array = array,
    geometry = geometry,
    arrow = FALSE,
    experimental = FALSE,
    strict_relational = TRUE
  )
}

duckdb_convert_opts_impl <- function(
  x = list(),
  ...,
  timezone_out = NULL,
  tz_out_convert = NULL,
  bigint = NULL,
  array = NULL,
  geometry = NULL,
  arrow = NULL,
  experimental = NULL,
  strict_relational = NULL
) {
  if (!is.null(timezone_out)) {
    x$timezone_out <- timezone_out
  }
  if (!is.null(tz_out_convert)) {
    x$tz_out_convert <- tz_out_convert
  }
  if (!is.null(bigint)) {
    x$bigint <- bigint
  }
  if (!is.null(array)) {
    x$array <- array
  }
  if (!is.null(geometry)) {
    x$geometry <- geometry
  }
  if (!is.null(arrow)) {
    x$arrow <- arrow
  }
  if (!is.null(experimental)) {
    x$experimental <- experimental
  }
  if (!is.null(strict_relational)) {
    x$strict_relational <- strict_relational
  }

  x
}
