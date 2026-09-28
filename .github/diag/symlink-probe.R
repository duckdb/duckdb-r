# Throwaway diagnostic for the draft pull request #2854, not meant to merge:
# how Windows, the C runtime and the DuckDB CLI see a symlink whose target does
# not exist yet, before any of the package is built.
# Handbook: handbook/usage/connections/README.md

stopifnot(.Platform$OS.type == "windows")
cat(R.version.string, "on", utils::sessionInfo()$running, R.version$arch, "\n")

build <- file.path(tempdir(), "probe")
dir.create(build)
file.copy(".github/diag/symlink-probe.c", build)
owd <- setwd(build)
out <- system2(
  file.path(R.home("bin"), "R"),
  c("CMD", "SHLIB", "symlink-probe.c"),
  stdout = TRUE,
  stderr = TRUE
)
cat(out, sep = "\n")
setwd(owd)
dyn.load(file.path(build, paste0("symlink-probe", .Platform$dynlib.ext)))

codes <- c(
  CREATE_NEW = 1L,
  CREATE_ALWAYS = 2L,
  OPEN_EXISTING = 3L,
  OPEN_ALWAYS = 4L
)
view <- function(path) invisible(.C("probe_view", path))
reparse <- function(path) invisible(.C("probe_reparse", path))
open_as <- function(path, disposition, style) {
  invisible(.C("probe_open", path, codes[[disposition]], as.integer(style)))
}

win <- function(path) chartr("/", "\\", path)
section <- function(title) cat("\n=====", title, "=====\n")
shell_out <- function(...) {
  out <- suppressWarnings(system2(
    "cmd",
    c("/c", ...),
    stdout = TRUE,
    stderr = TRUE
  ))
  cat(paste0("    | ", out), sep = "\n")
}

fresh <- function(how = c("R", "file", "dir")) {
  how <- match.arg(how)
  dir <- tempfile("symlink-")
  dir.create(dir)
  target <- file.path(dir, "target.duckdb")
  link <- file.path(dir, "link.duckdb")
  if (how == "R") {
    ok <- file.symlink(target, link)
    cat("  file.symlink(target, link):", ok, "\n")
  } else {
    shell_out("mklink", if (how == "dir") "/D", win(link), win(target))
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

reset <- function(s) {
  if (file.exists(s$target)) {
    unlink(s$target)
    cat("    (target removed again)\n")
  }
}

section("1. The link file.symlink() makes, before anything opens it")
s <- fresh("R")
state(s)
shell_out("dir", "/AL", win(s$dir))
shell_out("fsutil", "reparsepoint", "query", win(s$link))
reparse(s$link)
cat("  the engine's calls on the link:\n")
view(s$link)
cat(
  "  the missing target, which file.symlink() stats to choose the link type:\n"
)
view(s$target)

section("2. CreateFileW() through that link, one disposition at a time")
for (d in c("OPEN_EXISTING", "OPEN_ALWAYS", "CREATE_ALWAYS", "CREATE_NEW")) {
  for (style in 0:1) {
    open_as(s$link, d, style)
    state(s)
    reset(s)
  }
}

section("3. R's file.create() through the link")
cat("    file.create(link):", file.create(s$link), "\n")
state(s)
reset(s)
cat("  the engine's calls on the link, once more:\n")
view(s$link)

cli <- Sys.getenv("DUCKDB_CLI_WIN")
cli_run <- function(db, sql) {
  out <- suppressWarnings(system2(
    cli,
    c(shQuote(db, type = "cmd"), "-c", shQuote(sql, type = "cmd")),
    stdout = TRUE,
    stderr = TRUE
  ))
  cat(paste0("    | ", out), sep = "\n")
  cat(
    "    exit status:",
    if (is.null(attr(out, "status"))) 0 else attr(out, "status"),
    "\n"
  )
}
if (nzchar(cli)) {
  section(
    "4. The DuckDB CLI (MSVC build of the same release) through a fresh R link"
  )
  cli_run(":memory:", "SELECT version()")
  s <- fresh("R")
  cat("  glob() on the link, which is FileExists() || IsPipe():\n")
  cli_run(":memory:", sprintf("SELECT file FROM glob('%s')", win(s$link)))
  cat("  opening the link as a database:\n")
  cli_run(win(s$link), "CREATE TABLE t AS SELECT 42 AS x")
  state(s)
  if (file.exists(s$target)) {
    cli_run(win(s$link), "FROM t")
  }
}

for (how in c("file", "dir")) {
  section(sprintf("5. An explicit %s symlink (mklink), for comparison", how))
  s <- fresh(how)
  state(s)
  reparse(s$link)
  view(s$link)
  for (d in c("OPEN_ALWAYS", "CREATE_ALWAYS")) {
    open_as(s$link, d, 0L)
    state(s)
    reset(s)
  }
  if (nzchar(cli)) {
    cli_run(win(s$link), "CREATE TABLE t AS SELECT 42 AS x")
    state(s)
  }
}
