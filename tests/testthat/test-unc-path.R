# Windows network (UNC) paths,
# which DuckDB must accept under every spelling R hands out (#2882).
# `local_unc_tempdir()` and `unc_spellings()` in `helper-unc.R`
# provide the directory and the spellings.

test_that("a database on a UNC path opens there under every spelling (#2882)", {
  paths <- local_unc_tempdir()

  for (name in c("backslash", "slash", "mixed", "filepath")) {
    path <- unc_spellings(paths$unc, paste0(name, ".duckdb"))[[name]]

    # The key keeps the server and share rather than rooting them on a drive;
    # an engine error counts as a failure for this spelling only.
    key <- tryCatch(
      path_normalize(path),
      error = function(e) paste("error:", conditionMessage(e))
    )
    expect_match(
      chartr("\\", "/", key),
      "^//localhost/",
      ignore.case = TRUE,
      info = name
    )

    # The driver is shut down before the next spelling,
    # so no file stays locked when the directory is removed.
    err <- tryCatch(
      local({
        drv <- duckdb(path)
        withr::defer(duckdb_shutdown(drv))
        dbDisconnect(dbConnect(drv))
        NULL
      }),
      error = identity
    )
    if (is.null(err)) {
      succeed()
    } else {
      fail(paste0(name, ": ", conditionMessage(err)))
    }
    expect_true(
      file.exists(file.path(paths$dir, paste0(name, ".duckdb"))),
      info = name
    )
  }
})

test_that("a recursive glob below a UNC path finds files under every spelling (#2882)", {
  paths <- local_unc_tempdir()

  con <- local_con()

  # One file at each of two depths, written through the local path.
  dir.create(file.path(paths$dir, "a", "b"), recursive = TRUE)
  for (format in c("csv", "parquet")) {
    dbExecute(
      con,
      sprintf(
        "COPY (SELECT 1 AS x) TO %s (FORMAT %s)",
        dbQuoteString(con, file.path(paths$dir, "a", paste0("one.", format))),
        format
      )
    )
    dbExecute(
      con,
      sprintf(
        "COPY (SELECT 2 AS x) TO %s (FORMAT %s)",
        dbQuoteString(
          con,
          file.path(paths$dir, "a", "b", paste0("two.", format))
        ),
        format
      )
    )
  }

  for (format in c("csv", "parquet")) {
    spellings <- unc_spellings(paths$unc, "**", paste0("*.", format))
    for (name in c("backslash", "slash", "mixed", "filepath")) {
      sql <- sprintf(
        "SELECT sum(x) AS s FROM read_%s(%s)",
        format,
        dbQuoteString(con, spellings[[name]])
      )
      # No file found is an error, which must count as a failure, not a skip.
      res <- tryCatch(dbGetQuery(con, sql)$s, error = conditionMessage)
      expect_equal(res, 3, info = paste(name, format))
    }
  }
})
