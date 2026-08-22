duckdb_convert_opts <- function(
  ...,
  timezone_out = "UTC",
  tz_out_convert = c("with", "force"),
  bigint = "numeric",
  array = "none",
  geometry = "blob",
  map = "data.frame",
  posixct = "timestamptz",
  call = parent.frame()
) {
  tz_out_convert <- match.arg(tz_out_convert)
  timezone_out <- check_tz(timezone_out)

  if (bigint == "integer64") {
    if (!is_installed("bit64")) {
      abort("bit64 package is required for integer64 support", call = call)
    }
  } else if (bigint != "numeric") {
    abort(paste0("Unsupported bigint configuration: ", bigint), call = call)
  }

  if (geometry == "wk") {
    if (!is_installed("wk")) {
      abort("wk package is required for geometry = \"wk\" support", call = call)
    }
  } else if (geometry != "blob") {
    abort(paste0("Unsupported geometry configuration: ", geometry), call = call)
  }

  if (map == "list_of") {
    if (!is_installed("vctrs")) {
      abort(
        "vctrs package is required for map = \"list_of\" support",
        call = call
      )
    }
  } else if (map != "data.frame") {
    abort(paste0("Unsupported map configuration: ", map), call = call)
  }

  if (!posixct %in% c("timestamp", "timestamptz")) {
    abort(paste0("Unsupported posixct configuration: ", posixct), call = call)
  }

  duckdb_convert_opts_impl(
    timezone_out = timezone_out,
    tz_out_convert = tz_out_convert,
    bigint = bigint,
    array = array,
    geometry = geometry,
    map = map,
    posixct = posixct,
    arrow = FALSE,
    streaming = FALSE,
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
  map = NULL,
  posixct = NULL,
  arrow = NULL,
  streaming = NULL,
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
  if (!is.null(map)) {
    x$map <- map
  }
  if (!is.null(posixct)) {
    x$posixct <- posixct
  }
  if (!is.null(arrow)) {
    x$arrow <- arrow
  }
  if (!is.null(streaming)) {
    x$streaming <- streaming
  }
  if (!is.null(experimental)) {
    x$experimental <- experimental
  }
  if (!is.null(strict_relational)) {
    x$strict_relational <- strict_relational
  }

  x
}
