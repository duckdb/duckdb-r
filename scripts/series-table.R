#!/usr/bin/env Rscript
# Write the flavor tables from scripts/series.yaml.
#
# Two tables said the same thing by hand and drifted: the root README's
# `Flavors` table and handbook/branches/flavors/'s. A new series had to be
# announced in both, in two pull requests more than once, and
# scripts/pull-config.sh derived the fork's mirror rules by regular expression
# over the *rendered* README -- which is how a badge moving to another
# repository silently changed what the fork was told to mirror.
#
# So the flavors are declared once and the tables are generated.
# `README.Rmd` calls flavor_table() from a chunk, so the root README and
# `.github/README.md` get theirs at render time and carry no markers of their
# own. The handbook's is a plain `.md`, so this script splices it between
# `<!-- flavors:begin -->` and `<!-- flavors:end -->`; everything outside them
# is prose nobody generates.
#
# Usage: series-table.R [--check]
#   --check   rewrite nothing; exit 1 when the handbook table is out of date.
#
# Sourced rather than run, it defines the helpers and writes nothing.

series_decl <- function(root = NULL) {
  if (is.null(root)) {
    root <- tryCatch(
      dirname(dirname(normalizePath(sub(
        "^--file=",
        "",
        grep("^--file=", commandArgs(), value = TRUE)[[1]]
      )))),
      error = function(e) "."
    )
  }
  yaml::read_yaml(file.path(root, "scripts", "series.yaml"))
}

SHIELDS <- "https://img.shields.io"

cran_badge <- function(flavor) {
  url <- paste0(
    "https%3A%2F%2Fpackagemanager.posit.co%2F__api__%2Frepos%2Fcran%2Fpackages%2F",
    flavor
  )
  sprintf(
    "[![CRAN](%s/badge/dynamic/json?url=%s&query=%%24.version&label=CRAN&color=green)](https://cran.r-project.org/package=%s)",
    SHIELDS,
    url,
    flavor
  )
}

runiv_badge <- function(flavor) {
  url <- paste0(
    "https%3A%2F%2Fduckdb.r-universe.dev%2Fapi%2Fpackages%2F",
    flavor
  )
  sprintf(
    "[![r-universe](%s/badge/dynamic/json?url=%s&query=%%24.Version&label=r-universe&color=green)](https://duckdb.r-universe.dev/%s)",
    SHIELDS,
    url,
    flavor
  )
}

diff_badge <- function(repo, base, head, label, color) {
  sprintf(
    "[![%s](%s/github/commits-difference/%s?base=%s&head=%s&label=%s&color=%s)](https://github.com/%s/compare/%s...%s)",
    label,
    SHIELDS,
    repo,
    base,
    head,
    gsub(" ", "%20", label),
    color,
    repo,
    base,
    head
  )
}

progress <- function(f) {
  out <- vapply(
    f$badges,
    function(b) {
      switch(
        b,
        cran = cran_badge(f$flavor),
        "r-universe" = runiv_badge(f$flavor)
      )
    },
    character(1)
  )
  if (identical(f$kind, "dev")) {
    s <- f$series
    # *ahead* is counted where both its refs live: the release branch is the
    # canonical repository's, and `<S>-green` is mirrored there for r-universe
    # (handbook/branches/mirrors/). The other two need `<S>-dev` and
    # `<S>-build`, which only the fork has.
    out <- c(
      out,
      diff_badge(
        "duckdb/duckdb-r",
        f$releases_from,
        paste0(s, "-green"),
        "ahead",
        "green"
      ),
      diff_badge(
        "krlmlr/duckdb-r",
        paste0(s, "-green"),
        paste0(s, "-dev"),
        "in flight",
        "yellow"
      ),
      diff_badge(
        "krlmlr/duckdb-r",
        paste0(s, "-build-base"),
        paste0(s, "-build"),
        "buffered",
        "blue"
      )
    )
  }
  paste(out, collapse = " ")
}

flavor_table <- function(decl = series_decl()) {
  rows <- vapply(
    decl$flavors,
    function(f) {
      sprintf(
        "| `%s` | [`%s`](https://github.com/duckdb/duckdb/tree/%s) | %s | %s |",
        f$flavor,
        f$upstream,
        f$upstream,
        f$kind,
        progress(f)
      )
    },
    character(1)
  )
  paste(
    c("| Flavor | Series | Kind | Progress |", "|---|---|---|---|", rows),
    collapse = "\n"
  )
}

handbook_table <- function(decl = series_decl()) {
  rows <- vapply(
    decl$flavors,
    function(f) {
      kind <- if (identical(f$kind, "CRAN")) {
        "CRAN, also r-universe"
      } else {
        paste0(f$kind, ", r-universe")
      }
      sprintf(
        "| `%s` | %s | `%s` | `%s` |",
        f$flavor,
        kind,
        f$publishes_from,
        f$upstream
      )
    },
    character(1)
  )
  paste(
    c(
      "| Flavor | Kind | Published from | Upstream series |",
      "|---|---|---|---|",
      rows
    ),
    collapse = "\n"
  )
}

# The series only the package archives still have. A list rather than rows:
# they carry no flavor, no refs and no badges, so a row would be four empty
# columns. A line lands here when it stops being served -- `v1.4-andium` will,
# once it is demoted from LTS.
# Everything before `v1.1-eatoni`, in one bullet that is not declared and never
# moves: upstream cut no release branch until 1.1, so these lines have no branch
# to name one by and none to link to. 1.0.0 was "Snow Duck" (Anas nivis).
TAIL <- "- `v1.0-nivis` and earlier (no upstream release branch)"

archived_list <- function(decl = series_decl()) {
  a <- decl$archived
  if (!length(a)) {
    return("")
  }
  bullets <- vapply(
    a,
    function(x) {
      sprintf(
        "- [`%s`](https://github.com/duckdb/duckdb/tree/%s) (%s)",
        x$upstream,
        x$upstream,
        x$cut
      )
    },
    character(1)
  )
  paste(
    c(
      "Upstream keeps every release branch it ever cut.",
      "The following series are only available in the package archives:",
      "",
      bullets,
      TAIL
    ),
    collapse = "\n"
  )
}

BEGIN <- "<!-- flavors:begin -->"
END <- "<!-- flavors:end -->"

splice <- function(path, block, check) {
  s <- readLines(path, warn = FALSE)
  b <- which(s == BEGIN)
  e <- which(s == END)
  if (length(b) != 1L || length(e) != 1L || e <= b) {
    message(path, ": no ", BEGIN, " .. ", END, " markers")
    return(1L)
  }
  new <- c(
    s[seq_len(b)],
    strsplit(block, "\n", fixed = TRUE)[[1]],
    s[e:length(s)]
  )
  if (identical(new, s)) {
    return(0L)
  }
  if (check) {
    message(path, ": table is out of date")
    return(1L)
  }
  writeLines(new, path)
  message("wrote ", path)
  0L
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  check <- "--check" %in% args
  if (length(setdiff(args, "--check"))) {
    message("usage: series-table.R [--check]")
    quit(status = 2L)
  }
  decl <- series_decl()
  rc <- splice(
    "handbook/branches/flavors/README.md",
    paste(handbook_table(decl), archived_list(decl), sep = "\n\n"),
    check
  )
  if (check && rc == 0L) {
    message("the handbook flavor table matches scripts/series.yaml")
  }
  quit(status = rc)
}
