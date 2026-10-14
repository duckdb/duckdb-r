#!/bin/bash
# test.sh <worktree> <lib> [filter]: run the worktree's testthat suite against the installed package
set -euo pipefail
wt=$1 lib=$2 filter=${3:-}
cd "$wt/tests/testthat"
R_LIBS="$lib:${R_LIBS:-}" NOT_CRAN=true Rscript -e '
  library(testthat)
  testthat::set_max_fails(Inf)
  filter <- commandArgs(TRUE)[1]
  if (is.na(filter) || filter == "") filter <- NULL
  res <- as.data.frame(test_dir(".", package = "duckdb", load_package = "installed", filter = filter,
    reporter = ProgressReporter$new(show_praise = FALSE), stop_on_failure = FALSE))
  cat(sprintf("\nSUMMARY files=%d tests=%d failed=%d error=%d skipped=%d\n", length(unique(res$file)), sum(res$nb), sum(res$failed), sum(res$error), sum(res$skipped)))
  bad <- res[res$failed > 0 | res$error, c("file", "test")]
  if (nrow(bad)) { cat("FAILING:\n"); print(bad, row.names = FALSE) }
' "$filter"
