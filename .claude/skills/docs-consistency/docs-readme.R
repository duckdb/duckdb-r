#!/usr/bin/env Rscript
# Generate scripts/README.md: the routing index GitHub renders in place
# when the directory is browsed.
#
# One row per file in scripts/, grouped by the handbook leaf that owns
# the topic; the purpose column is extracted from each file's own header
# comment (or Python docstring, or Markdown H1), so the index cannot
# drift from the files -- the roxygen model, applied to scripts.
# The mapping below is the scripts/ slice of the source-to-leaf
# ownership map; it moves into a repo-wide manifest when that lands.
#
# A helper, not an entry point: the docs-consistency skill (SKILL.md
# in this directory) drives it and owns the judgment calls -- whether
# a grouping is right, whether a header says what its file does.
# This renders and diffs.
# Rules: handbook/meta/handbook/README.md, "Enforcement".
#
# Usage (from anywhere in the repository):
#   Rscript .claude/skills/docs-consistency/docs-readme.R          # rewrite
#   Rscript .claude/skills/docs-consistency/docs-readme.R --check  # stale?

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

# The scripts/ slice of the source-to-leaf ownership map.
# `owner` is a handbook node, repo-relative.  First match wins;
# a file that could fit several paths is mapped to its best fit.
# The index renders grouped by handbook path, in path order.
groups <- list(
  list(
    owner = "handbook/operations/vendoring",
    globs = c("VENDORING.md")
  ),
  list(
    owner = "handbook/operations/vendoring/pipeline",
    globs = c("vendor*.sh", "rconfigure.py", "merge-version.sh", "setup-git.sh")
  ),
  list(
    owner = "handbook/operations/vendoring/series-loop",
    globs = c("series-*.sh")
  ),
  list(
    owner = "handbook/operations/ci/per-commit",
    globs = c("EACH.md", "each-*", "rcc-*")
  ),
  list(
    owner = "handbook/branches/flavors",
    globs = c("flavor*")
  ),
  list(
    owner = "handbook/build/fast-paths",
    globs = c("install-*.sh")
  ),
  list(
    owner = "handbook/build/configuration",
    globs = c("setup-makeflags.R")
  ),
  list(
    owner = "handbook/architecture/glue",
    globs = c("format.py", "python_helpers.py")
  ),
  list(
    owner = "handbook/architecture/r-layer",
    globs = c("rethrow.R")
  ),
  list(
    owner = "handbook/testing/snapshots",
    globs = c("snapshot-accept.sh")
  ),
  list(
    owner = "handbook/meta/handbook",
    globs = c("README.md")
  )
)
groups <- groups[order(vapply(groups, function(g) g$owner, character(1)))]

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
  if (!file.exists(g$owner)) {
    stop("dangling owner: ", g$owner)
  }
  name <- paste0(sub("^handbook/", "", g$owner), "/")
  rel <- paste0("../", g$owner, "/")
  paste0("## [`", name, "`](", rel, ")")
}

# --- assemble ----------------------------------------------------------

idx <- vapply(files, find_group, integer(1))
unowned <- files[is.na(idx)]

out <- c(
  "# `scripts/` — what lives here, and who explains it",
  "",
  "<!-- Generated by .claude/skills/docs-consistency/docs-readme.R;",
  "     do not edit by hand.  Regenerate:",
  "     Rscript .claude/skills/docs-consistency/docs-readme.R -->",
  "",
  "This index routes; the owning handbook leaves explain.",
  "One row per file,",
  "with the purpose taken from the file's own header line",
  "and the grouping from the handbook leaf that owns the topic —",
  "ownership by topic, navigation by place",
  "([the rules](../handbook/meta/handbook/README.md)).",
  "Root of the documentation tree: [`handbook/`](../handbook/).",
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
    message(target, " is stale; regenerate with:",
      " Rscript .claude/skills/docs-consistency/docs-readme.R")
    quit(status = 1)
  }
  message(target, " is current")
} else {
  writeLines(out, target)
  message("wrote ", target, " (", length(files), " files",
    if (length(unowned)) paste0(", ", length(unowned), " UNOWNED"), ")")
}
