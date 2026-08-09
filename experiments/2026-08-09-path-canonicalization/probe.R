# Which path facts a driver cache can rely on: what DuckDB's own
# canonicalization returns, and where it agrees with R's `normalizePath()`.
#
# Runs against DBI + duckdb as installed from CRAN. No package sources, no
# build. Every section degrades to a printed reason rather than failing, so one
# platform's missing capability does not cost the others their measurements.
#
# Driven by .github/workflows/probe-path-facts.yaml; findings land in README.md.

library(DBI)
library(duckdb)

windows <- .Platform$OS.type == "windows"
sep <- if (windows) "\\" else "/"

con <- dbConnect(duckdb())

root <- file.path(tempdir(), "probe")
dir.create(root, showWarnings = FALSE, recursive = TRUE)
root <- normalizePath(root)

# ---------------------------------------------------------------- utilities

section <- function(...) cat("\n\n### ", ..., "\n\n", sep = "")

note <- function(...) cat("  ", ..., "\n", sep = "")

# Everything here asks a question that a platform may refuse to answer.
try_chr <- function(expr) {
  tryCatch(
    expr,
    error = function(e) paste("ERR:", sub("\n.*", "", conditionMessage(e)))
  )
}

# `ATTACH` takes no bind parameters, so the path goes in as a literal. DuckDB
# follows the SQL standard here: a backslash is not an escape, only `'` is.
sql_string <- function(x) gsub("'", "''", x, fixed = TRUE)

# What DuckDB makes of a path: attach it, ask where it thinks it is, detach.
# Creates the database when it does not exist, which is the case under study.
duckdb_path <- function(path, read_only = FALSE) {
  try_chr({
    opts <- if (read_only) " (READ_ONLY)" else ""
    dbExecute(con, sprintf("ATTACH '%s' AS probe%s", sql_string(path), opts))
    on.exit(try(dbExecute(con, "DETACH probe"), silent = TRUE), add = TRUE)
    dbGetQuery(
      con,
      "SELECT path FROM duckdb_databases() WHERE database_name = 'probe'"
    )$path
  })
}

r_path <- function(path) try_chr(normalizePath(path, mustWork = FALSE))

# The #455 call. "Works" is the only fact wanted; the message is R's.
r_path_strict <- function(path) {
  tryCatch(
    {
      normalizePath(path, mustWork = TRUE)
      "ok"
    },
    error = function(e) "FAILS"
  )
}

# One input spelling, three answers, and whether the two canonicalizers agree.
# `duckdb_path()` runs first and creates the database, so the `mustWork` column
# reports what R says about a file that exists by then -- the state the package
# is in when it makes that call.
compare <- function(label, input) {
  d <- duckdb_path(input)
  r <- r_path(input)
  cat(sprintf("  %-22s %s\n", label, input))
  cat(sprintf("  %-22s %s\n", "  duckdb", d))
  cat(sprintf("  %-22s %s\n", "  normalizePath", r))
  cat(sprintf(
    "  %-22s agree=%s  mustWork=%s\n",
    "",
    identical(d, r),
    r_path_strict(input)
  ))
  invisible(d)
}

# Do several spellings of one database collapse to a single key?
collapses <- function(label, paths) {
  keys <- vapply(paths, duckdb_path, character(1), USE.NAMES = FALSE)
  note(label, ": ", length(unique(keys)), " distinct key(s) from ", length(keys), " spelling(s)")
  for (k in unique(keys)) note("    ", k)
  invisible(keys)
}

cat("# Path canonicalization probe\n\n")
note("platform:      ", R.version$platform)
note("os.type:       ", .Platform$OS.type)
note("R:             ", as.character(getRversion()))
note("duckdb:        ", as.character(packageVersion("duckdb")))
note("engine:        ", dbGetQuery(con, "SELECT version() AS v")$v)
note("tempdir:       ", root)

# --------------------------------------------------- 1. spellings, new file

section("1. Spellings of a database that does not exist yet")

d1 <- file.path(root, "s1")
dir.create(d1, showWarnings = FALSE)

compare("plain", file.path(d1, "a.duckdb"))
compare("dot-dot", file.path(d1, "..", "s1", "b.duckdb"))
compare("doubled separator", paste0(d1, sep, sep, "c.duckdb"))
compare("trailing sep on dir", paste0(d1, sep, "d.duckdb"))

owd <- setwd(d1)
compare("relative", "e.duckdb")
compare("dot-relative", paste0(".", sep, "f.duckdb"))
setwd(owd)

section("1b. Do those spellings collapse to one key?")

g <- file.path(d1, "g.duckdb")
collapses(
  "same database, five spellings",
  c(
    g,
    file.path(d1, "..", "s1", "g.duckdb"),
    paste0(d1, sep, sep, "g.duckdb"),
    gsub("/", sep, g, fixed = TRUE),
    g
  )
)

# ---------------------------------------------- 2. spellings, existing file

section("2. The same, for a database that already exists")

d2 <- file.path(root, "s2")
dir.create(d2, showWarnings = FALSE)
existing <- file.path(d2, "exists.duckdb")
invisible(duckdb_path(existing)) # create it through the engine

compare("plain", existing)
compare("dot-dot", file.path(d2, "..", "s2", "exists.duckdb"))

note("")
note("Does the key change when the database appears? Compare section 1's")
note("`plain` line with this one -- a difference is two cache keys for one")
note("database over its lifetime.")

# ------------------------------------------------------------- 3. symlinks

section("3. Symlinks")

d3 <- file.path(root, "s3")
dir.create(d3, showWarnings = FALSE)

link_dir <- file.path(root, "s3-link")
made <- tryCatch(file.symlink(d3, link_dir), error = function(e) FALSE, warning = function(w) FALSE)
if (isTRUE(made)) {
  compare("through symlinked dir", file.path(link_dir, "h.duckdb"))
} else {
  note("symlinked directory: unavailable on this runner (no privilege)")
}

real <- file.path(d3, "real.duckdb")
invisible(duckdb_path(real))
link_file <- file.path(d3, "link.duckdb")
made <- tryCatch(file.symlink(real, link_file), error = function(e) FALSE, warning = function(w) FALSE)
if (isTRUE(made)) {
  compare("symlinked file", link_file)
  note("resolves to the target? ", identical(duckdb_path(link_file), duckdb_path(real)))
} else {
  note("symlinked file: unavailable on this runner (no privilege)")
}

# ---------------------------------------------------- 4. case-insensitivity

section("4. Case")

d4 <- file.path(root, "s4")
dir.create(d4, showWarnings = FALSE)
mixed <- file.path(d4, "Case.duckdb")
invisible(duckdb_path(mixed)) # created as `Case.duckdb`
lower <- file.path(d4, "case.duckdb")

note("filesystem is case-insensitive: ", file.exists(lower))
compare("created as Case", mixed)
compare("asked as case", lower)
note("same key both ways? ", identical(duckdb_path(mixed), duckdb_path(lower)))

# ------------------------------------------------- 5. Windows spellings

section("5. Windows spellings")

if (!windows) {
  note("not Windows -- skipped")
} else {
  d5 <- file.path(root, "s5")
  dir.create(d5, showWarnings = FALSE)
  back <- gsub("/", "\\", file.path(d5, "w.duckdb"), fixed = TRUE)

  compare("backslashes", back)
  compare("forward slashes", gsub("\\", "/", back, fixed = TRUE))
  compare("mixed separators", sub("\\\\w.duckdb$", "/w.duckdb", back))
  compare("lowercase drive", sub("^([A-Za-z]):", "\\L\\1:", back, perl = TRUE))
  compare("uppercase drive", sub("^([A-Za-z]):", "\\U\\1:", back, perl = TRUE))

  short <- try_chr(utils::shortPathName(d5))
  note("shortPathName(dir): ", short)
  if (!startsWith(short, "ERR:")) {
    compare("8.3 short name", file.path(short, "w.duckdb"))
  }

  unc <- paste0("\\\\localhost\\", sub("^([A-Za-z]):", "\\1$", back))
  note("UNC attempt: ", unc)
  note("  duckdb:        ", duckdb_path(unc))
  note("  normalizePath: ", r_path(unc))

  note("")
  note("normalizePath(winslash = '/') on the plain path:")
  note("  ", try_chr(normalizePath(back, winslash = "/", mustWork = FALSE)))
}

# ------------------------------------------- 6. an unreadable parent (#455)

section("6. A parent directory that cannot be read (the #455 shape)")

d6 <- file.path(root, "s6", "mid", "leaf")
dir.create(d6, showWarnings = FALSE, recursive = TRUE)
mid <- dirname(d6)
target <- file.path(d6, "n.duckdb")

# The file has to exist before the question means anything: `mustWork = TRUE`
# fails on a missing file for reasons that have nothing to do with permissions,
# which is why the package creates a placeholder in the first place. So this
# measures the state the package is actually in at that call.
invisible(duckdb_path(target))

round6 <- function(label) {
  note(label)
  note("  normalizePath(mustWork = TRUE):  ", r_path_strict(target))
  note("  normalizePath(mustWork = FALSE): ", r_path(target))
  note("  duckdb:                          ", duckdb_path(target))
}

if (!windows) {
  note("euid: ", try_chr(paste(system2("id", "-u", stdout = TRUE), collapse = "")))
}
round6("baseline, unrestricted")

if (windows) {
  user <- Sys.getenv("USERNAME")
  icacls <- function(...) {
    out <- try_chr(system2("icacls", c(shQuote(mid), ...), stdout = TRUE, stderr = TRUE))
    note("  icacls: ", paste(out, collapse = " | "))
  }

  # Deny "read data / list directory" on a directory above the file, leaving
  # traverse in place: a share the user may reach through but not enumerate.
  icacls("/deny", paste0(shQuote(user), ":(RD)"))
  round6("read denied on the directory above")
  icacls("/remove:d", shQuote(user))
} else {
  # POSIX resolves a path with search permission (+x); read (+r) is only what
  # *listing* needs. So dropping read alone is expected to change nothing --
  # and dropping search denies the file to everyone, canonicalizer or not.
  # Together they say this shape has no POSIX reproduction.
  Sys.chmod(mid, "0311")
  round6("mode 0311 -- search, no read")

  Sys.chmod(mid, "0611")
  round6("mode 0611 -- read, no search")

  Sys.chmod(mid, "0755")
}

# -------------------------------------------------- 7. cheaper alternatives

section("7. Does anything canonicalize without creating a database?")

d7 <- file.path(root, "s7")
dir.create(d7, showWarnings = FALSE)
p7 <- file.path(d7, "p.duckdb")
invisible(duckdb_path(p7))

globbed <- function(x) {
  try_chr({
    got <- dbGetQuery(con, sprintf("SELECT file FROM glob('%s')", sql_string(x)))$file
    if (length(got) == 0) "<no rows>" else got
  })
}
note("glob, plain:    ", globbed(p7))
note("glob, dot-dot:  ", globbed(file.path(d7, "..", "s7", "p.duckdb")))
note("glob, missing:  ", globbed(file.path(d7, "nope.duckdb")))
note("parse_path:     ", try_chr(paste(
  dbGetQuery(con, sprintf("SELECT parse_path('%s') AS p", sql_string(p7)))$p[[1]],
  collapse = " | "
)))

# ------------------------------------------------------------- 8. read-only

section("8. Read-only attach of a database that does not exist")

ro <- file.path(root, "s8-ro.duckdb")
note("read-only, missing: ", duckdb_path(ro, read_only = TRUE))
note("file created?       ", file.exists(ro))

# The placeholder the package writes today is a zero-byte file. Whether the
# engine would accept one decides how the two approaches can be mixed.
empty <- file.path(root, "s8-empty.duckdb")
invisible(file.create(empty))
note("empty file as a db: ", duckdb_path(empty))

# ------------------------------------------------------------------ 9. cost

section("9. Cost")

d9 <- file.path(root, "s9")
dir.create(d9, showWarnings = FALSE)

n <- 10L
t_engine <- system.time(for (i in seq_len(n)) {
  cc <- dbConnect(duckdb())
  dbExecute(cc, sprintf("ATTACH '%s' AS probe", sql_string(file.path(d9, sprintf("e%d.duckdb", i)))))
  dbExecute(cc, "DETACH probe")
  dbDisconnect(cc, shutdown = TRUE)
})[["elapsed"]]

t_attach <- system.time(for (i in seq_len(n)) {
  duckdb_path(file.path(d9, sprintf("a%d.duckdb", i)))
})[["elapsed"]]

t_file <- system.time(for (i in seq_len(n)) {
  f <- file.path(d9, sprintf("f%d.duckdb", i))
  file.create(f)
  normalizePath(f, mustWork = FALSE)
  unlink(f)
})[["elapsed"]]

note("throwaway instance + ATTACH + DETACH: ", round(1000 * t_engine / n, 1), " ms/call")
note("ATTACH + DETACH on an open connection: ", round(1000 * t_attach / n, 1), " ms/call")
note("file.create + normalizePath + unlink:  ", round(1000 * t_file / n, 3), " ms/call")

dbDisconnect(con, shutdown = TRUE)
cat("\n\ndone\n")
