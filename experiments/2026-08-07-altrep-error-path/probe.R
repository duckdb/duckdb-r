#!/usr/bin/env Rscript
# What happens when an ALTREP method raises an error.
#
# Usage: Rscript probe.R <library-path> [variant]
#
#   variant "as-built"        the duckdb in <library-path>, unchanged (default)
#   variant "base-rapi-error" swap duckdb:::rapi_error for the plain stop()
#                             version before the first error, so the static
#                             cpp11::function caches it -- isolates how much of
#                             the error path's cost is rlang rather than the
#                             call into R itself
#
# Five probes:
#   1. which R closures run while the ALTREP method is on the C stack
#   2. what the resulting condition looks like to a caller
#   3. whether a long-jmp out of an ALTREP method leaves the guard stuck on
#   4. how much C stack the error path needs to report at all  <- #1796
#   5. how far re-entrant access recurses before R's C stack limit
#
# Reads nothing, writes nothing, needs no network.

args <- commandArgs(TRUE)
lib <- args[[1]]
variant <- if (length(args) >= 2) args[[2]] else "as-built"
.libPaths(c(lib, .libPaths()))
suppressMessages(library(duckdb))

invisible(compiler::enableJIT(0)) # keep recursion off the byte-code node stack
options(expressions = 500000L) # let the C stack, not the eval depth, bind

if (variant == "base-rapi-error") {
  ns <- asNamespace("duckdb")
  unlockBinding("rapi_error", ns)
  assign("rapi_error", function(context, message, error_type = NULL,
                                raw_message = NULL, extra_info = NULL) {
    stop(paste0(context, ": ", message), call. = FALSE)
  }, envir = ns)
}

con <- dbConnect(duckdb())
rel <- duckdb:::rel_from_df(con, data.frame(a = 1:10, b = 1:10))
forbid <- duckdb:::rel_to_altrep(rel, allow_materialization = FALSE)
ok <- duckdb:::rel_to_altrep(rel)

cat("duckdb ", as.character(packageVersion("duckdb")),
    ", R ", as.character(getRversion()),
    ", rlang ", as.character(packageVersion("rlang")),
    ", variant ", variant, "\n\n", sep = "")

invisible(tryCatch(nrow(forbid), error = function(e) NULL)) # warm every path


## 1. What runs inside the ALTREP method ------------------------------------
#
# nrow() reaches RownamesLength() through .row_names_info(), so every frame
# after .row_names_info() is R code evaluated with the ALTREP method live on
# the C stack.

seen <- NULL
probe <- function() {
  withCallingHandlers(
    nrow(forbid),
    condition = function(cnd) {
      if (is.null(seen)) {
        seen <<- vapply(sys.calls(), function(x) paste(deparse(x[[1]])[[1]], collapse = ""), "")
      }
    }
  )
}
invisible(tryCatch(probe(), error = function(e) NULL))

cut <- match(".row_names_info", seen)
cat("== 1. R frames below the ALTREP method\n")
cat(paste0("   ", format(seq_along(seen)), ". ", seen,
           ifelse(seq_along(seen) > cut, "   <- inside RownamesLength()", "")),
    sep = "\n")
cat("\n")


## 2. What the caller sees ---------------------------------------------------

e <- tryCatch(nrow(forbid), error = identity)
cat("== 2. The condition\n")
cat("   class  :", paste(class(e), collapse = "/"), "\n")
cat("   message:", gsub("\n", "\n            ", conditionMessage(e)), "\n\n")


## 3. Does a long-jmp leave the guard stuck on? ------------------------------
#
# rapi_error_with_context() raised from a plain entry point -- no ALTREP method
# anywhere on the stack. Under rlang the context is a bullet; a stuck guard
# collapses it to a flat "<context>: <message>".

marker <- function() {
  msg <- conditionMessage(tryCatch(
    duckdb:::rel_from_altrep_df(data.frame(a = 1)),
    error = identity
  ))
  if (grepl("Context:", msg)) "bullet form (guard off)" else "FLAT FORM (guard stuck on)"
}

# Only meaningful as built: the marker reads the rlang bullet, which the plain
# stop() version of rapi_error() never emits.
cat("== 3. Guard state across a long-jmp out of an ALTREP method\n")
if (variant != "as-built") {
  cat("   skipped for variant", variant, "\n\n")
} else {
  cat("   before the long-jmp:", marker(), "\n")

  # GetQueryResult() evaluates the materialize callback from inside the ALTREP
  # method; an error there unwinds all the way out to this tryCatch().
  options(duckdb.materialize_callback = function(rel) stop("callback failed"))
  cat("   the long-jmp       :",
      tryCatch({ nrow(ok); "no error" }, error = conditionMessage), "\n")
  options(duckdb.materialize_callback = NULL)

  cat("   after the long-jmp :", marker(), "\n\n")
}


## 4. How much C stack does reporting the error take? ------------------------
#
# Recurse until the error path itself no longer fits, and report the free stack
# at the ALTREP entry on either side of the crossover. Below that threshold the
# caller is told "C stack usage is too close to the limit" rather than what
# actually went wrong -- the stack overflow of #1796.

at <- NA_real_
deep <- function(n) {
  if (n <= 0) {
    at <<- Cstack_info()[["current"]]
    nrow(forbid)
  } else {
    deep(n - 1)
  }
}

size <- Cstack_info()[["size"]]
through <- NA_real_
overflow <- NA_real_
d <- 0L
step <- 512L
while (step >= 1L) {
  repeat {
    at <- NA_real_
    res <- tryCatch(deep(d + step), error = conditionMessage)
    if (grepl("C stack usage|too deeply", res)) {
      overflow <- size - at
      break
    }
    through <- size - at
    d <- d + step
  }
  step <- step %/% 2L
}

cat("== 4. C stack the error path needs\n")
cat(sprintf("   stack size                  : %8.0f bytes\n", size))
cat(sprintf("   real error still reported at: %8.0f bytes free (depth %d)\n", through, d))
cat(sprintf("   C-stack error from          : %8.0f bytes free\n\n", overflow))


## 5. Re-entrant access ------------------------------------------------------
#
# A handler that touches the same object again. Each round installs a fresh
# handler, so nothing truncates the cycle; it ends at R's C stack limit.

n <- 0
f <- function() {
  n <<- n + 1
  withCallingHandlers(nrow(forbid), error = function(e) f())
}
res <- tryCatch(f(), error = function(e) sub("\n.*", "", conditionMessage(e)))

cat("== 5. Re-entrant access\n")
cat("   rounds before the limit:", n, "\n")
cat("   outcome                :", format(res), "\n")
