#!/usr/bin/env Rscript
# Generate the type reference pages, `?duckdb_types`, `?duckdb_types_arrow`
# and `?duckdb_types_spatial`, from the handbook leaves that own them.
#
# Each page is one leaf. The leaf's opening paragraphs are the page's
# description and its sections are the page's sections; its title is the
# page's own, below. Left out: the leaf's heading, its deepen line, and a
# paragraph that names this script, which is about the pages rather than in
# them. Links are rewritten so that a page stands without handbook/, which
# the built package does not carry: a link to a leaf that has a page becomes
# a link to that page, and any other path in the repository a link to it on
# GitHub. The output is roxygen under R/, which roxygen renders into man/.
# Base R only, so that CI can run it on a bare checkout.
# Handbook: handbook/usage/types/README.md names this script.
#
# Usage (from anywhere in the repository):
#   Rscript scripts/types-rd.R          # rewrite
#   Rscript scripts/types-rd.R --check  # stale?

pages <- list(
  list(
    leaf = "handbook/usage/types",
    topic = "duckdb_types",
    title = "DuckDB data types in R"
  ),
  list(
    leaf = "handbook/usage/arrow-types",
    topic = "duckdb_types_arrow",
    title = "DuckDB data types through Arrow"
  ),
  list(
    leaf = "handbook/usage/spatial",
    topic = "duckdb_types_spatial",
    title = "Spatial data types in R"
  )
)
github <- "https://github.com/duckdb/duckdb-r"
self <- "scripts/types-rd.R"

# --- locate the repository ---------------------------------------------

root <- system2("git", c("rev-parse", "--show-toplevel"), stdout = TRUE)
if (!length(root) || !nzchar(root)) {
  stop("not inside a git repository")
}
setwd(root)

# --- links ---------------------------------------------------------------

# A repository path, from a link written from the repository root or
# relative to the leaf's directory.
repo_path <- function(target, dir) {
  path <- if (startsWith(target, "/")) {
    sub("^/", "", target)
  } else {
    file.path(dir, target)
  }
  parts <- character()
  for (p in strsplit(path, "/", fixed = TRUE)[[1]]) {
    if (p == "..") {
      parts <- head(parts, -1)
    } else if (p != "." && p != "") {
      parts <- c(parts, p)
    }
  }
  out <- paste(parts, collapse = "/")
  if (endsWith(path, "/")) paste0(out, "/") else out
}

leaf_topics <- setNames(
  vapply(pages, `[[`, character(1), "topic"),
  vapply(pages, `[[`, character(1), "leaf")
)

rewrite_link <- function(text, target, dir) {
  if (grepl("^[a-z]+:", target) || startsWith(target, "#")) {
    return(sprintf("[%s](%s)", text, target))
  }
  anchor <- if (grepl("#", target, fixed = TRUE)) {
    sub("^[^#]*", "", target)
  } else {
    ""
  }
  path <- repo_path(sub("#.*$", "", target), dir)
  leaf <- sub("/(README\\.md)?$", "", path)
  if (leaf %in% names(leaf_topics)) {
    topic <- leaf_topics[[leaf]]
    return(sprintf("[`?%s`][%s]", topic, topic))
  }
  kind <- if (endsWith(path, "/") || dir.exists(path)) "tree" else "blob"
  sprintf(
    "[%s](%s/%s/main/%s%s)",
    text,
    github,
    kind,
    sub("/$", "", path),
    anchor
  )
}

rewrite_links <- function(line, dir) {
  pattern <- "\\[([^]]*)\\]\\(([^)]*)\\)"
  out <- ""
  repeat {
    m <- regexpr(pattern, line, perl = TRUE)
    if (m < 0) {
      break
    }
    starts <- attr(m, "capture.start")
    lengths <- attr(m, "capture.length")
    text <- substr(line, starts[1], starts[1] + lengths[1] - 1)
    target <- substr(line, starts[2], starts[2] + lengths[2] - 1)
    out <- paste0(out, substr(line, 1, m - 1), rewrite_link(text, target, dir))
    line <- substr(line, m + attr(m, "match.length"), nchar(line))
  }
  paste0(out, line)
}

# --- one page ------------------------------------------------------------

# Paragraphs and list items are kept whole, as runs of lines between blank
# lines, so that one naming this script can be left out whole.
paragraphs <- function(lines) {
  groups <- cumsum(!nzchar(lines))
  keep <- nzchar(lines)
  unname(split(lines[keep], groups[keep]))
}

render <- function(page) {
  source_file <- file.path(page$leaf, "README.md")
  lines <- readLines(source_file, warn = FALSE)
  lines <- lines[-grep("^# ", lines)[[1]]]

  blocks <- paragraphs(lines)
  blocks <- Filter(function(b) !startsWith(b[[1]], "*To deepen:"), blocks)
  blocks <- Filter(function(b) !any(grepl(self, b, fixed = TRUE)), blocks)

  body <- unlist(lapply(blocks, function(b) {
    b <- vapply(
      b,
      rewrite_links,
      character(1),
      dir = page$leaf,
      USE.NAMES = FALSE
    )
    # A leaf's sections are the page's sections, one level up.
    b <- sub("^### ", "## ", sub("^## ", "# ", b))
    c(b, "")
  }))
  body <- head(body, -1)
  # Rd reads % as a comment, and roxygen reads @ as a tag.
  body <- gsub("%", "\\%", body, fixed = TRUE)
  body <- gsub("@", "@@", body, fixed = TRUE)

  first_section <- grep("^# ", body)
  if (length(first_section)) {
    description <- body[seq_len(first_section[[1]] - 2)]
    details <- body[first_section[[1]]:length(body)]
  } else {
    first_list <- grep("^\\* ", body)[[1]]
    description <- body[seq_len(first_list - 2)]
    details <- body[first_list:length(body)]
  }

  roxygen <- function(x) ifelse(nzchar(x), paste("#'", x), "#'")
  c(
    sprintf("# Generated by %s from %s:", self, source_file),
    "# edit the leaf and re-run the script, never this file.",
    "",
    roxygen(c(
      page$title,
      "",
      "@description",
      description,
      "",
      "@details",
      details,
      "",
      paste("@name", page$topic)
    )),
    "NULL"
  )
}

# --- write or check --------------------------------------------------------

check <- identical(commandArgs(trailingOnly = TRUE), "--check")
stale <- character()
for (page in pages) {
  target <- file.path("R", paste0(page$topic, ".R"))
  new <- render(page)
  old <- if (file.exists(target)) {
    readLines(target, warn = FALSE)
  } else {
    character()
  }
  if (identical(old, new)) {
    next
  }
  if (check) {
    stale <- c(stale, target)
  } else {
    writeLines(new, target)
    message("wrote ", target, "; run roxygen to render man/", page$topic, ".Rd")
  }
}
if (length(stale)) {
  writeLines(sprintf("%s is stale; regenerate with: Rscript %s", stale, self))
  quit(status = 1)
}
if (check) {
  writeLines("the type reference pages are current")
}
