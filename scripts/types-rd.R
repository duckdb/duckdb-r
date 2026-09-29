#!/usr/bin/env Rscript
# Generate the type reference pages, `?duckdb_types` and `?duckdb_types_arrow`,
# from the handbook leaves that own them.
#
# Each page is one leaf, rendered for someone reading R's help rather than
# the handbook. The leaf's opening sentence is the description, and its
# sections are the page's sections, down to its `## Limitations`, which the
# page does not repeat: the closing section, "Limitations and reference",
# points to the leaf for them, followed by the rest of the leaf's opening
# and any sentence that only points into the repository. Left out: the
# leaf's heading, its deepen line, and a paragraph that names this script,
# which is about the pages rather than in them.
#
# In the sections, a clause citing a file ("pinned by",
# "set in") and a link in parentheses to a path in the repository are
# dropped; a sentence still pointing into the repository moves to the
# closing section, and one that opens its entry is an error, to be
# rephrased in the leaf. A link to a leaf that has a page becomes a link
# to that page, "documented in" it; any other path in the repository, which
# the built package does not carry, becomes a link to it on GitHub,
# "documented in the handbook's" leaf where it is one. A link to the leaf
# itself, or with an anchor into a leaf that has a page, becomes a link to
# the leaf on GitHub, anchor included, and stays where it is, as does the
# breadcrumb "a limitation (below)". The first mention of a function this
# package exports, a DBI function, or `pkg::fun()` from a declared
# dependency links to its help.
#
# The page has no Limitations section, so the script stops on any other
# "(below)" and on a sentence naming "Limitations".
#
# The output is roxygen under R/, which roxygen renders into man/.
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
    title = "DuckDB data types in R",
    see = "See [duckdb_types_arrow] for a description of the conversion via Arrow."
  ),
  list(
    leaf = "handbook/usage/arrow-types",
    topic = "duckdb_types_arrow",
    title = "DuckDB data types through Arrow",
    see = "See [duckdb_types] for a description of the direct conversion to R vectors."
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

# The functions a first mention links to: this package's exports, DBI's
# functions by their prefix, and the packages DESCRIPTION declares.
exports <- sub(
  "^export\\((.*)\\)$",
  "\\1",
  grep("^export\\(", readLines("NAMESPACE"), value = TRUE)
)
deps <- read.dcf("DESCRIPTION", fields = c("Depends", "Imports", "Suggests"))
deps <- trimws(unlist(strsplit(
  gsub("\\([^)]*\\)", "", paste(na.omit(deps), collapse = ",")),
  ","
)))
deps <- setdiff(deps[nzchar(deps)], "R")

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

# A link to a path in the repository, once rewritten; an issue or a pull
# request is not one, and neither is a link into a leaf that has a page,
# which stays where it is.
pointer <- sprintf(
  "\\]\\(https://github[.]com/duckdb/duckdb-r/(blob|tree)/main/(?!(%s)/README[.]md)",
  paste(gsub(".", "[.]", names(leaf_topics), fixed = TRUE), collapse = "|")
)

# What a link points at: the web, a leaf that has a page, a place in the
# leaf itself or in such a leaf, or the repository. `dir` is the leaf the
# link is written in.
link_kind <- function(target, dir) {
  if (grepl("^[a-z]+:", target)) {
    return(list(kind = "web"))
  }
  anchor <- if (grepl("#", target, fixed = TRUE)) {
    sub("^[^#]*", "", target)
  } else {
    ""
  }
  path <- if (startsWith(target, "#")) {
    file.path(dir, "README.md")
  } else {
    repo_path(sub("#.*$", "", target), dir)
  }
  leaf <- sub("/(README\\.md)?$", "", path)
  if (leaf %in% names(leaf_topics)) {
    # A help page has no anchors, and a link to the page it is on leads
    # nowhere, so both go to the leaf on GitHub.
    if (leaf == dir || nzchar(anchor)) {
      return(list(
        kind = "leaf",
        url = sprintf("%s/blob/main/%s/README.md%s", github, leaf, anchor)
      ))
    }
    return(list(kind = "page", topic = leaf_topics[[leaf]]))
  }
  kind <- if (endsWith(path, "/") || dir.exists(path)) "tree" else "blob"
  list(
    kind = "repo",
    handbook = startsWith(path, "handbook/"),
    url = sprintf("%s/%s/main/%s%s", github, kind, sub("/$", "", path), anchor)
  )
}

# "is <leaf>'s" and "as <leaf> says" read as "documented in <link>".
documented_in <- function(before, link, after) {
  if (grepl("\\b(is|are) $", before) && startsWith(after, "'s")) {
    paste0(before, "documented in ", link, substring(after, 3))
  } else if (grepl("\\bas $", before) && startsWith(after, " says")) {
    paste0(before, "documented in ", link, substring(after, 6))
  }
}

# Rewrite the links of a text, the last first so that earlier positions hold.
# `body` drops the pointers into the repository that can go without leaving a
# gap; outside the body, they become links to GitHub.
rewrite_links <- function(text, dir, body) {
  m <- gregexpr("\\[([^]]*)\\]\\(([^)]*)\\)", text, perl = TRUE)[[1]]
  if (m[[1]] < 0) {
    return(text)
  }
  starts <- attr(m, "capture.start")
  lengths <- attr(m, "capture.length")
  for (i in rev(seq_along(m))) {
    from <- m[[i]]
    to <- from + attr(m, "match.length")[[i]] - 1
    link_text <- substr(text, starts[i, 1], starts[i, 1] + lengths[i, 1] - 1)
    target <- substr(text, starts[i, 2], starts[i, 2] + lengths[i, 2] - 1)
    before <- substr(text, 1, from - 1)
    after <- substr(text, to + 1, nchar(text))
    k <- link_kind(target, dir)
    if (k$kind == "web") {
      next
    }
    if (k$kind == "page") {
      page_link <- sprintf("[%s]", k$topic)
      documented <- documented_in(before, page_link, after)
      if (!is.null(documented)) {
        text <- documented
      } else if (endsWith(before, "(") && startsWith(after, ")")) {
        text <- paste0(before, "see ", page_link, after)
      } else {
        text <- paste0(before, page_link, after)
      }
      next
    }
    url_link <- sprintf("[%s](%s)", link_text, k$url)
    documented <- if (k$kind == "repo" && k$handbook) {
      documented_in(before, paste("the handbook's", url_link), after)
    }
    if (k$kind == "leaf") {
      text <- paste0(before, url_link, after)
    } else if (body && grepl("(,\\s*|\\s+)(pinned by|set in) $", before)) {
      text <- paste0(sub("(,\\s*|\\s+)(pinned by|set in) $", "", before), after)
    } else if (body && endsWith(before, "(") && startsWith(after, ")")) {
      text <- paste0(sub("\\s*\\($", "", before), substring(after, 2))
    } else if (!is.null(documented)) {
      text <- documented
    } else {
      text <- paste0(before, url_link, after)
    }
  }
  text
}

# --- one page ------------------------------------------------------------

# Paragraphs and list items are kept whole, as runs of lines between blank
# lines, so that one naming this script can be left out whole.
paragraphs <- function(lines) {
  groups <- cumsum(!nzchar(lines))
  keep <- nzchar(lines)
  unname(split(lines[keep], groups[keep]))
}

# A block's sentences, as runs of lines: a sentence ends a line, in a full
# stop, a full stop closing a bold run-in, or a colon opening a list.
sentences <- function(block) {
  ends <- grepl("([.:]|[.]\\*\\*)$", block)
  groups <- c(0, cumsum(ends)[-length(block)])
  unname(split(block, factor(groups, levels = unique(groups))))
}

# A section, for the page: its links rewritten, and a
# sentence still pointing into the repository moved out, into `moved`.
moved <- character()
for_page <- function(block, dir) {
  text <- rewrite_links(paste(block, collapse = "\n"), dir, body = TRUE)
  block <- strsplit(text, "\n", fixed = TRUE)[[1]]
  if (!any(grepl(pointer, block, perl = TRUE))) {
    return(block)
  }
  parts <- sentences(block)
  keep <- list()
  for (j in seq_along(parts)) {
    s <- parts[[j]]
    if (!any(grepl(pointer, s, perl = TRUE))) {
      keep <- c(keep, list(s))
    } else if (j == 1) {
      stop(
        "a sentence opening its entry points into the repository; ",
        "rephrase it in the leaf: ",
        s[[1]],
        call. = FALSE
      )
    } else {
      moved <<- c(moved, sub("^\\s+", "", s))
    }
  }
  unlist(keep)
}

# The first mention of a function with a help page links to it.
link_functions <- function(lines) {
  seen <- character()
  pattern <- "(?<!\\[)`((\\w+)::)?([A-Za-z.][\\w.]*)\\(\\)`"
  for (i in seq_along(lines)) {
    m <- gregexpr(pattern, lines[[i]], perl = TRUE)[[1]]
    if (m[[1]] < 0) {
      next
    }
    starts <- attr(m, "capture.start")
    lengths <- attr(m, "capture.length")
    edits <- list()
    for (j in seq_along(m)) {
      pkg <- substr(lines[[i]], starts[j, 2], starts[j, 2] + lengths[j, 2] - 1)
      fun <- substr(lines[[i]], starts[j, 3], starts[j, 3] + lengths[j, 3] - 1)
      call <- if (nzchar(pkg)) paste0(pkg, "::", fun) else fun
      has_page <- if (nzchar(pkg)) {
        pkg %in% deps
      } else {
        fun %in% exports || grepl("^db[A-Z]", fun)
      }
      if (!has_page || call %in% seen) {
        next
      }
      seen <- c(seen, call)
      from <- m[[j]]
      to <- from + attr(m, "match.length")[[j]] - 1
      edits <- c(edits, list(list(from = from, to = to, call = call)))
    }
    for (e in rev(edits)) {
      lines[[i]] <- paste0(
        substr(lines[[i]], 1, e$from - 1),
        sprintf("[%s()]", e$call),
        substr(lines[[i]], e$to + 1, nchar(lines[[i]]))
      )
    }
  }
  lines
}

render <- function(page) {
  moved <<- character()
  source_file <- file.path(page$leaf, "README.md")
  lines <- readLines(source_file, warn = FALSE)
  lines <- lines[-grep("^# ", lines)[[1]]]

  blocks <- paragraphs(lines)
  blocks <- Filter(function(b) !startsWith(b[[1]], "*To deepen:"), blocks)
  blocks <- Filter(function(b) !any(grepl(self, b, fixed = TRUE)), blocks)

  heads <- vapply(blocks, `[[`, character(1), 1)
  sections <- which(startsWith(heads, "## "))
  limits <- which(heads == "## Limitations")
  if (length(limits) != 1 || limits != max(sections)) {
    stop(
      source_file,
      " needs a `## Limitations` section, and last",
      call. = FALSE
    )
  }
  opening <- blocks[seq_len(sections[[1]] - 1)]
  body <- blocks[sections[[1]]:(limits - 1)]

  # The description is the leaf's opening sentence; the rest of the opening
  # says where the page stands in the repository, and closes the page.
  first <- opening[[1]]
  sentence_end <- which(endsWith(first, "."))[[1]]
  # On the page, the leaf's opening sentence says what the page documents,
  # and a pointer to the other page follows it.
  description <- first[seq_len(sentence_end)]
  description[[1]] <- paste0(
    "This page documents ",
    tolower(substr(description[[1]], 1, 1)),
    substring(description[[1]], 2)
  )
  description <- c(description, page$see)
  reference <- c(
    sprintf(
      "The limitations are listed in the handbook, in [`%s/`](%s/blob/main/%s/README.md).",
      sub("^handbook/", "", page$leaf),
      github,
      page$leaf
    ),
    "",
    first[-seq_len(sentence_end)],
    unlist(opening[-1])
  )

  as_lines <- function(blocks) unlist(lapply(blocks, function(b) c(b, "")))
  body <- as_lines(lapply(body, function(b) {
    # A leaf's sections are the page's sections, one level up.
    sub("^### ", "## ", sub("^## ", "# ", for_page(b, page$leaf)))
  }))
  if (length(moved)) {
    reference <- c(reference, "", moved)
  }
  reference <- strsplit(
    rewrite_links(paste(reference, collapse = "\n"), page$leaf, body = FALSE),
    "\n",
    fixed = TRUE
  )[[1]]

  # The page leaves the limitations to the handbook,
  # so a breadcrumb to them links there, wherever it stands.
  crumbs <- function(x) {
    gsub(
      "limitation (below)",
      sprintf(
        "[limitation](%s/blob/main/%s/README.md#limitations)",
        github,
        page$leaf
      ),
      x,
      fixed = TRUE
    )
  }
  description <- crumbs(description)
  body <- crumbs(body)
  reference <- crumbs(reference)
  from_leaf <- c(description, body, reference)
  below <- grep("(below)", from_leaf, fixed = TRUE, value = TRUE)
  if (length(below)) {
    stop(
      source_file,
      ": a breadcrumb other than \"a limitation (below)\" points below, ",
      "where the page has nothing: ",
      below[[1]],
      call. = FALSE
    )
  }
  named <- grep("\\bLimitations\\b", from_leaf, value = TRUE)
  if (length(named)) {
    stop(
      source_file,
      ": a sentence names the Limitations section, which the page does not have; ",
      "point to it with \"a limitation (below)\" instead: ",
      named[[1]],
      call. = FALSE
    )
  }

  details <- c(body, "# Limitations and reference", "", reference)
  all <- link_functions(c(description, "", details))
  # Roxygen reads @ as a tag.
  # Rd reads % as a comment, but markdown roxygen escapes it already:
  # escaping it here as well writes \\% into the Rd,
  # which renders a backslash and drops the rest of the line.
  all <- gsub("@", "@@", all, fixed = TRUE)
  description <- all[seq_along(description)]
  details <- all[-seq_len(length(description) + 1)]

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
