#!/usr/bin/env Rscript
# Renders every issue-<n>-<slug>.R in this directory to a GitHub-flavoured
# markdown transcript of the same name, ready to paste into a closing comment.
#
# Run from this directory. `DUCKDB_R_HOME` is set so that duckdb 1.5.5's
# one-time storage-location note (a non-interactive-session message about
# ~/.duckdb, see ?duckdb_storage) does not open every transcript; it changes
# where downloaded extensions are cached and nothing else.
if (Sys.getenv("DUCKDB_R_HOME") == "") {
  home <- file.path(tempdir(), "duckdb-home")
  dir.create(home, showWarnings = FALSE)
  Sys.setenv(DUCKDB_R_HOME = home)
}

files <- commandArgs(trailingOnly = TRUE)
if (length(files) == 0) {
  files <- sort(list.files(".", pattern = "^issue-.*[.]R$"))
}

for (file in files) {
  message("rendering ", file)
  out <- reprex::reprex(
    input = file,
    venue = "gh",
    advertise = TRUE,
    html_preview = FALSE,
    wd = "."
  )
  writeLines(out, sub("[.]R$", ".md", file))
  # reprex leaves its own <name>_reprex.{R,md} beside the input
  unlink(paste0(sub("[.]R$", "", file), "_reprex", c(".R", ".md")))
}
