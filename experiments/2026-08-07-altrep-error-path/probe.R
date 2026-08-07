#!/usr/bin/env Rscript
# What happens when an ALTREP method raises an error.
#
# Usage: Rscript probe.R <library-path>
#
# Four probes, all against a duckdb installed in <library-path>:
#   1. which R closures run while the ALTREP method is on the C stack
#   2. what the resulting condition looks like to a caller
#   3. whether a long-jmp out of an ALTREP method leaves the guard stuck on
#   4. how far re-entrant access recurses before R's C stack limit
#
# Reads nothing, writes nothing, needs no network.

lib <- commandArgs(TRUE)[[1]]
.libPaths(c(lib, .libPaths()))
suppressMessages(library(duckdb))

con <- dbConnect(duckdb())
rel <- duckdb:::rel_from_df(con, data.frame(a = 1:10, b = 1:10))
forbid <- duckdb:::rel_to_altrep(rel, allow_materialization = FALSE)
ok <- duckdb:::rel_to_altrep(rel)

cat("duckdb ", as.character(packageVersion("duckdb")),
    ", R ", as.character(getRversion()),
    ", rlang ", as.character(packageVersion("rlang")), "\n\n", sep = "")


## 1. What runs inside the ALTREP method ------------------------------------
#
# nrow() reaches RownamesLength() through .row_names_info(), so every frame
# after .row_names_info() is R code evaluated with the ALTREP method live on
# the C stack.

seen <- NULL
base_stack <- NA

probe <- function() {
  base_stack <<- Cstack_info()[["current"]]
  withCallingHandlers(
    nrow(forbid),
    condition = function(cnd) {
      if (is.null(seen)) {
        seen <<- list(
          calls = vapply(sys.calls(), function(x) paste(deparse(x[[1]])[[1]], collapse = ""), ""),
          cstack = Cstack_info()[["current"]] - base_stack
        )
      }
    }
  )
}
invisible(tryCatch(probe(), error = function(e) NULL))

cut <- match(".row_names_info", seen$calls)
cat("== 1. R frames below the ALTREP method\n")
cat(paste0("   ", format(seq_along(seen$calls)), ". ", seen$calls,
           ifelse(seq_along(seen$calls) > cut, "   <- inside RownamesLength()", "")),
    sep = "\n")
cat("   C stack used below the caller:", seen$cstack, "bytes\n\n")


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

cat("== 3. Guard state across a long-jmp out of an ALTREP method\n")
cat("   before the long-jmp:", marker(), "\n")

# GetQueryResult() evaluates the materialize callback from inside the ALTREP
# method; an error there unwinds all the way out to this tryCatch().
options(duckdb.materialize_callback = function(rel) stop("callback failed"))
cat("   the long-jmp       :",
    tryCatch({ nrow(ok); "no error" }, error = conditionMessage), "\n")
options(duckdb.materialize_callback = NULL)

cat("   after the long-jmp :", marker(), "\n\n")


## 4. Re-entrant access ------------------------------------------------------
#
# A handler that touches the same object again. Each round installs a fresh
# handler, so nothing truncates the cycle; it ends at R's C stack limit.

n <- 0
f <- function() {
  n <<- n + 1
  withCallingHandlers(nrow(forbid), error = function(e) f())
}
res <- tryCatch(f(), error = function(e) sub("\n.*", "", conditionMessage(e)))

cat("== 4. Re-entrant access\n")
cat("   rounds before the limit:", n, "\n")
cat("   outcome                :", format(res), "\n")
