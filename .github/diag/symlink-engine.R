# Throwaway diagnostic for the draft pull request #2854, not meant to merge:
# how the vendored engine, built into this package, handles a symlink whose
# target does not exist yet.
# Handbook: handbook/usage/connections/README.md

lib <- commandArgs(trailingOnly = TRUE)[[1]]
library(DBI)
library(duckdb, lib.loc = lib)
cat(
  "duckdb",
  format(packageVersion("duckdb", lib.loc = lib)),
  "from",
  lib,
  "\n"
)

win <- function(path) chartr("/", "\\", path)
section <- function(title) cat("\n=====", title, "=====\n")

fresh <- function(how = c("R", "dir")) {
  how <- match.arg(how)
  dir <- tempfile("symlink-")
  dir.create(dir)
  target <- file.path(dir, "target.duckdb")
  link <- file.path(dir, "link.duckdb")
  if (how == "R") {
    cat("  file.symlink(target, link):", file.symlink(target, link), "\n")
  } else {
    out <- system2(
      "cmd",
      c("/c", "mklink", "/D", win(link), win(target)),
      stdout = TRUE,
      stderr = TRUE
    )
    cat(paste0("    | ", out), sep = "\n")
  }
  list(dir = dir, target = target, link = link)
}

state <- function(s) {
  fi <- file.info(s$link, extra_cols = FALSE)
  cat(
    "    Sys.readlink(link): ",
    encodeString(Sys.readlink(s$link), quote = '"'),
    "; file.info(link): size ",
    fi$size,
    ", isdir ",
    fi$isdir,
    "; file.exists(link) ",
    file.exists(s$link),
    ", file.exists(target) ",
    file.exists(s$target),
    "\n",
    sep = ""
  )
}

engine_view <- function(s) {
  con <- dbConnect(duckdb())
  on.exit(dbDisconnect(con))
  for (what in c("link", "target")) {
    files <- dbGetQuery(
      con,
      sprintf("SELECT file FROM glob('%s')", s[[what]])
    )$file
    cat(
      "    glob(",
      what,
      "), which is FileExists() || IsPipe(): ",
      if (length(files)) "found" else "not found",
      "\n",
      sep = ""
    )
  }
  cat("    path_normalize(link):", duckdb:::path_normalize(s$link), "\n")
}

open_through <- function(s) {
  cat("  before duckdb(link):\n")
  state(s)
  engine_view(s)
  drv <- tryCatch(duckdb(s$link), error = identity)
  if (inherits(drv, "error")) {
    cat("  duckdb(link) failed:", conditionMessage(drv), "\n")
    cat("  after the failed duckdb(link):\n")
    state(s)
    return(invisible())
  }
  cat("  duckdb(link) opened; dbdir:", drv@dbdir, "\n")
  con <- dbConnect(drv)
  dbExecute(con, "CREATE TABLE t AS SELECT 42 AS x")
  dbDisconnect(con)
  duckdb_shutdown(drv)
  cat("  after duckdb(link) and a write:\n")
  state(s)
  cat("    target size:", file.size(s$target), "\n")
  drv <- duckdb(s$link)
  con <- dbConnect(drv)
  cat(
    "    reopened through the link, t holds:",
    dbGetQuery(con, "FROM t")$x,
    "\n"
  )
  dbDisconnect(con)
  duckdb_shutdown(drv)
}

report <- function(e) cat("  ERROR:", conditionMessage(e), "\n")

section("1. duckdb() through the link file.symlink() makes")
s <- fresh("R")
tryCatch(open_through(s), error = report)
if (!file.exists(s$target)) {
  cat("  file.create(link) afterwards:", file.create(s$link), "\n")
  state(s)
}

section("2. duckdb() through a directory symlink (mklink /D)")
s <- fresh("dir")
tryCatch(open_through(s), error = report)
