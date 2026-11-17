# Windows network (UNC) paths, which DuckDB must accept under every spelling R
# hands out: `\\server\share\x`, `//server/share/x`, and the mixed
# `\\server/share/x`. The administrative share `\\localhost\C$` stands in for a
# network drive, so these run on any Windows machine that exposes it (#2882).

test_that("a database on a UNC path opens there under every spelling (#2882)", {
  skip_on_cran()
  skip_if_not(.Platform$OS.type == "windows", "UNC paths are Windows-only")
  dir <- normalizePath(withr::local_tempdir(), winslash = "\\")
  unc <- paste0("\\\\localhost\\", substr(dir, 1, 1), "$", substring(dir, 3))
  skip_if_not(dir.exists(unc), "the administrative share is not reachable")

  slashed <- chartr("\\", "/", substring(unc, 3))
  spellings <- list(
    backslash = paste0(unc, "\\backslash.duckdb"),
    slash = paste0("//", slashed, "/slash.duckdb"),
    mixed = paste0("\\\\", slashed, "/mixed.duckdb")
  )

  for (name in names(spellings)) {
    path <- spellings[[name]]

    # The key keeps the server and share rather than rooting them on a drive.
    expect_match(
      chartr("\\", "/", path_normalize(path)),
      "^//localhost/",
      ignore.case = TRUE,
      info = name
    )

    con <- tryCatch(dbConnect(duckdb(path)), error = identity)
    expect_s4_class(con, "duckdb_connection")
    if (!inherits(con, "error")) {
      dbDisconnect(con, shutdown = TRUE)
    }
    expect_true(
      file.exists(file.path(dir, paste0(name, ".duckdb"))),
      info = name
    )
  }
})

test_that("a recursive glob below a UNC path finds files under every spelling (#2882)", {
  skip_on_cran()
  skip_if_not(.Platform$OS.type == "windows", "UNC paths are Windows-only")
  dir <- normalizePath(withr::local_tempdir(), winslash = "\\")
  unc <- paste0("\\\\localhost\\", substr(dir, 1, 1), "$", substring(dir, 3))
  skip_if_not(dir.exists(unc), "the administrative share is not reachable")

  con <- dbConnect(duckdb())
  withr::defer(dbDisconnect(con, shutdown = TRUE))

  # One file at each of two depths, written through the local path.
  dir.create(file.path(dir, "a", "b"), recursive = TRUE)
  for (format in c("csv", "parquet")) {
    dbExecute(
      con,
      sprintf(
        "COPY (SELECT 1 AS x) TO '%s' (FORMAT %s)",
        file.path(dir, "a", paste0("one.", format)),
        format
      )
    )
    dbExecute(
      con,
      sprintf(
        "COPY (SELECT 2 AS x) TO '%s' (FORMAT %s)",
        file.path(dir, "a", "b", paste0("two.", format)),
        format
      )
    )
  }

  slashed <- chartr("\\", "/", substring(unc, 3))
  spellings <- list(
    backslash = paste0(unc, "\\**\\*."),
    slash = paste0("//", slashed, "/**/*."),
    mixed = paste0("\\\\", slashed, "/**/*.")
  )

  for (name in names(spellings)) {
    for (format in c("csv", "parquet")) {
      sql <- sprintf(
        "SELECT sum(x) AS s FROM read_%s('%s%s')",
        format,
        spellings[[name]],
        format
      )
      # No file found is an error, which must count as a failure, not a skip.
      res <- tryCatch(dbGetQuery(con, sql)$s, error = conditionMessage)
      expect_equal(res, 3, info = paste(name, format))
    }
  }
})
