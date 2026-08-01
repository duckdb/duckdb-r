#!/usr/bin/env Rscript
# Generate scripts/README.md: the routing index GitHub renders in place
# when the directory is browsed.
#
# One row per file in scripts/, grouped by the document that owns the
# topic; the purpose column is extracted from each file's own header
# comment (or Python docstring, or Markdown H1), so the index cannot
# drift from the files -- the roxygen model, applied to scripts.
# Ownership follows the draft manifest in plan/PLAN-docs-tree.md ss.6
# (PR #2443), corrected where projecting it onto this directory showed
# it to be wrong; the mapping below moves into .github/docs-owners.yml
# when that manifest lands.  Design: plan/PLAN-docs-tree-filesystem.md.
#
# Usage:
#   Rscript scripts/docs-readme.R          # rewrite scripts/README.md
#   Rscript scripts/docs-readme.R --check  # exit 1 if README.md is stale

# --- locate the repository ---------------------------------------------

root <- system2("git", c("rev-parse", "--show-toplevel"), stdout = TRUE)
if (!length(root) || !nzchar(root)) {
  stop("not inside a git repository")
}
setwd(root)

files <- system2(
  "git",
  c("ls-files", "--cached", "--others", "--exclude-standard", "--", "scripts/"),
  stdout = TRUE
)
# The target file lists itself, whether or not it exists yet.
files <- sort(unique(c(basename(files), "README.md")), method = "radix")

# --- purpose extraction ------------------------------------------------

# First sentence of the first header-comment paragraph.  Skips shebangs
# and lint directives; a bare `#` ends the paragraph.  Returns NA for a
# file whose format carries no extractable header (for example a patch).
extract_purpose <- function(path) {
  lines <- readLines(path, n = 30, warn = FALSE)
  ext <- tolower(tools::file_ext(path))

  if (ext == "md") {
    h1 <- grep("^# ", lines, value = TRUE)
    if (length(h1)) {
      return(first_sentence(sub("^# ", "", h1[[1]])))
    }
    return(NA_character_)
  }

  if (ext == "py") {
    open <- grep("^\\s*[rb]*\"\"\"", lines)
    if (length(open)) {
      text <- sub("^\\s*[rb]*\"\"\"", "", lines[open[[1]]])
      i <- open[[1]] + 1
      while (!grepl("\"\"\"", text) && !grepl("^\\s*$", text) && i <= length(lines)) {
        nxt <- lines[[i]]
        if (grepl("^\\s*$", nxt) || grepl("\"\"\"", nxt)) break
        text <- paste(text, trimws(nxt))
        i <- i + 1
      }
      return(first_sentence(sub("\"\"\".*$", "", text)))
    }
    # fall through: a py file may use `#` headers instead
  }

  collected <- character()
  for (line in lines) {
    if (grepl("^#!", line)) next
    if (grepl("^#+\\s*(shellcheck|-\\*-)", line)) next
    if (!length(collected) && grepl("^\\s*$", line)) next
    if (grepl("^#\\s*$", line)) {
      if (length(collected)) break
      next
    }
    if (grepl("^#", line)) {
      collected <- c(collected, sub("^#+\\s?", "", line))
    } else {
      break
    }
  }
  if (!length(collected)) {
    return(NA_character_)
  }
  first_sentence(paste(collected, collapse = " "))
}

# Cut at the first period that ends the text or is followed by
# whitespace and a capital letter or backtick -- so `e.g.` and file
# names like `version.R` inside the sentence survive.
first_sentence <- function(text) {
  text <- trimws(text)
  m <- regexpr("\\.(?=\\s+[A-Z`(]|\\s*$)", text, perl = TRUE)
  if (m > 0) {
    text <- substr(text, 1L, m)
  }
  if (nchar(text) > 160) {
    text <- paste0(substr(text, 1L, 157), "...")
  }
  gsub("|", "\\|", text, fixed = TRUE)
}

# --- ownership ---------------------------------------------------------

# Seed of .github/docs-owners.yml (plan/PLAN-docs-tree.md ss.6),
# restricted to scripts/.  `owner` is repo-relative; `proposed` marks a
# document that exists only in PR #2443 so far.  First match wins.
PR2443 <- "https://github.com/duckdb/duckdb-r/pull/2443"
groups <- list(
  list(
    title = "Vendoring and series",
    owner = "scripts/VENDORING.md",
    globs = c("VENDORING.md", "vendor*.sh", "rconfigure.py", "series-*.sh",
      "merge-version.sh")
  ),
  list(
    title = "Per-commit CI",
    owner = "scripts/EACH.md",
    globs = c("EACH.md", "each-*", "rcc-*")
  ),
  list(
    title = "Flavors and branch plumbing",
    owner = "BRANCHES.md",
    globs = c("flavor*", "setup-git.sh")
  ),
  list(
    title = "Build and development environment",
    owner = "BUILD.md",
    proposed = PR2443,
    globs = c("install-*.sh", "setup-makeflags.R", "format.py", "python_helpers.py")
  ),
  list(
    title = "Testing",
    owner = "TESTING.md",
    proposed = PR2443,
    globs = c("snapshot-accept.sh", "rethrow.R")
  ),
  list(
    title = "This index",
    owner = "plan/PLAN-docs-tree-filesystem.md",
    globs = c("README.md", "docs-readme.R")
  )
)

find_group <- function(file) {
  hits <- which(vapply(
    groups,
    function(g) any(vapply(
      g$globs,
      function(glob) grepl(utils::glob2rx(glob), file),
      logical(1)
    )),
    logical(1)
  ))
  if (length(hits) > 1) {
    warning("double-owned: ", file, " matches groups ",
      paste(hits, collapse = ", "), call. = FALSE)
  }
  if (length(hits)) hits[[1]] else NA_integer_
}

owner_heading <- function(g) {
  if (!is.null(g$label)) {
    return(paste0("## ", g$title, " — ", g$label))
  }
  name <- basename(g$owner)
  rel <- if (dirname(g$owner) == "scripts") name else file.path("..", g$owner)
  if (file.exists(g$owner)) {
    paste0("## ", g$title, " — [`", name, "`](", rel, ")")
  } else if (!is.null(g$proposed)) {
    paste0("## ", g$title, " — `", name, "` *(proposed: [#2443](", g$proposed, "))*")
  } else {
    stop("dangling owner: ", g$owner)
  }
}

# --- assemble ----------------------------------------------------------

idx <- vapply(files, find_group, integer(1))
unowned <- files[is.na(idx)]

out <- c(
  "# `scripts/` — what lives here, and who explains it",
  "",
  "<!-- Generated by scripts/docs-readme.R; do not edit by hand.",
  "     Regenerate: Rscript scripts/docs-readme.R -->",
  "",
  "This index routes; the owning documents explain.",
  "One row per file,",
  "with the purpose taken from the file's own header line",
  "and the grouping from the document that owns the topic —",
  "ownership by purpose, navigation by place",
  "([`plan/PLAN-docs-tree-filesystem.md`](../plan/PLAN-docs-tree-filesystem.md)).",
  "Root of the documentation tree:",
  "[`AGENTS.md` § Where to look](../AGENTS.md#where-to-look).",
  ""
)

for (gi in seq_along(groups)) {
  members <- files[!is.na(idx) & idx == gi]
  if (!length(members)) next
  out <- c(out, owner_heading(groups[[gi]]), "", "| File | Purpose |", "|---|---|")
  for (file in members) {
    purpose <- if (file == "README.md") {
      "(this index)"
    } else {
      p <- extract_purpose(file.path("scripts", file))
      if (is.na(p)) "—" else p
    }
    out <- c(out, paste0("| [`", file, "`](", file, ") | ", purpose, " |"))
  }
  out <- c(out, "")
}

if (length(unowned)) {
  out <- c(
    out, "## Unowned", "",
    "These files match no ownership glob — fix the mapping:", "",
    paste0("* `", unowned, "`"), ""
  )
}

# --- write or check ----------------------------------------------------

target <- "scripts/README.md"
check <- any(commandArgs(trailingOnly = TRUE) == "--check")

if (check) {
  current <- if (file.exists(target)) readLines(target, warn = FALSE) else character()
  if (!identical(current, out) || length(unowned)) {
    if (length(unowned)) {
      message("unowned files: ", paste(unowned, collapse = ", "))
    }
    message(target, " is stale; regenerate with: Rscript scripts/docs-readme.R")
    quit(status = 1)
  }
  message(target, " is current")
} else {
  writeLines(out, target)
  message("wrote ", target, " (", length(files), " files",
    if (length(unowned)) paste0(", ", length(unowned), " UNOWNED"), ")")
}
