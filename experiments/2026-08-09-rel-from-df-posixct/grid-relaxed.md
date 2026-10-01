``` r
# One policy's worth of the rel_from_df() POSIXct grid.
#
# For every (column tzone x timezone_out x session TimeZone) cell, hand the
# column to rel_from_df() and read it back with rel_to_altrep(), and record
# which of four things happened:
#
#   ok            accepted, and the data frame comes back unchanged
#   relabeled     accepted, same instant, different `tzone` -- the silent one
#   refused       the strict check rejected the column
#   wrong-instant accepted and the value moved (nothing should produce this)
#
# POLICY names the build; run.sh sets it. See README.md.
suppressMessages(library(duckdb))
options(width = 200)

rel_from_df <- duckdb:::rel_from_df
rel_to_altrep <- duckdb:::rel_to_altrep

policy <- Sys.getenv("POLICY", "shipped")

# One instant, four ways of labeling it in R. "absent" is what `Sys.time()`
# returns; "empty" is what `as.POSIXct()` leaves behind. Both mean "local".
INSTANT <- 1745781814.84963

make_col <- function(label) {
  switch(
    label,
    absent = structure(INSTANT, class = c("POSIXct", "POSIXt")),
    empty = structure(INSTANT, class = c("POSIXct", "POSIXt"), tzone = ""),
    structure(INSTANT, class = c("POSIXct", "POSIXt"), tzone = label)
  )
}

label_of <- function(x) {
  z <- attr(x, "tzone")
  if (is.null(z)) {
    "<absent>"
  } else if (!nzchar(z)) {
    "<empty>"
  } else {
    z
  }
}

cell <- function(col, tz_out, session) {
  df <- data.frame(a = make_col(col))
  # The storage-location notice is an `inform()`, not an option
  con <- suppressMessages(dbConnect(duckdb(), timezone_out = tz_out))
  on.exit(dbDisconnect(con, shutdown = TRUE))
  dbExecute(con, paste0("SET TimeZone = '", session, "'"))

  out <- tryCatch(rel_to_altrep(rel_from_df(con, df)), error = function(e) e)

  if (inherits(out, "error")) {
    verdict <- "refused"
    back <- NA_character_
  } else {
    back <- label_of(out$a)
    same_label <- identical(attr(out$a, "tzone"), attr(df$a, "tzone"))
    same_instant <- isTRUE(all.equal(as.numeric(out$a), INSTANT))
    verdict <- if (!same_instant) {
      "wrong-instant"
    } else if (same_label) {
      "ok"
    } else {
      "relabeled"
    }
  }

  data.frame(
    policy = policy,
    col = label_of(df$a),
    tz_out = if (nzchar(tz_out)) tz_out else "<empty>",
    session = session,
    verdict = verdict,
    back = back
  )
}

grid <- expand.grid(
  col = c("UTC", "empty", "absent", "America/New_York"),
  tz_out = c("UTC", "", "America/New_York"),
  session = c("UTC", "Etc/UTC", "America/New_York"),
  stringsAsFactors = FALSE
)

out <- do.call(rbind, Map(cell, grid$col, grid$tz_out, grid$session))
rownames(out) <- NULL

cat(
  "policy",
  policy,
  "| duckdb",
  as.character(packageVersion("duckdb")),
  "| DuckDB",
  duckdb:::get_duckdb_version(),
  "| local zone",
  Sys.timezone(),
  "\n\n"
)
#> policy relaxed | duckdb 1.5.5.9026 | DuckDB 1.5.5 | local zone Etc/UTC
print(out, right = FALSE)
#>    policy  col              tz_out           session          verdict   back            
#> 1  relaxed UTC              UTC              UTC              ok        UTC             
#> 2  relaxed <empty>          UTC              UTC              relabeled UTC             
#> 3  relaxed <absent>         UTC              UTC              relabeled UTC             
#> 4  relaxed America/New_York UTC              UTC              relabeled UTC             
#> 5  relaxed UTC              <empty>          UTC              ok        UTC             
#> 6  relaxed <empty>          <empty>          UTC              relabeled UTC             
#> 7  relaxed <absent>         <empty>          UTC              relabeled UTC             
#> 8  relaxed America/New_York <empty>          UTC              relabeled UTC             
#> 9  relaxed UTC              America/New_York UTC              ok        UTC             
#> 10 relaxed <empty>          America/New_York UTC              relabeled UTC             
#> 11 relaxed <absent>         America/New_York UTC              relabeled UTC             
#> 12 relaxed America/New_York America/New_York UTC              relabeled UTC             
#> 13 relaxed UTC              UTC              Etc/UTC          relabeled Etc/UTC         
#> 14 relaxed <empty>          UTC              Etc/UTC          relabeled Etc/UTC         
#> 15 relaxed <absent>         UTC              Etc/UTC          relabeled Etc/UTC         
#> 16 relaxed America/New_York UTC              Etc/UTC          relabeled Etc/UTC         
#> 17 relaxed UTC              <empty>          Etc/UTC          relabeled Etc/UTC         
#> 18 relaxed <empty>          <empty>          Etc/UTC          relabeled Etc/UTC         
#> 19 relaxed <absent>         <empty>          Etc/UTC          relabeled Etc/UTC         
#> 20 relaxed America/New_York <empty>          Etc/UTC          relabeled Etc/UTC         
#> 21 relaxed UTC              America/New_York Etc/UTC          relabeled Etc/UTC         
#> 22 relaxed <empty>          America/New_York Etc/UTC          relabeled Etc/UTC         
#> 23 relaxed <absent>         America/New_York Etc/UTC          relabeled Etc/UTC         
#> 24 relaxed America/New_York America/New_York Etc/UTC          relabeled Etc/UTC         
#> 25 relaxed UTC              UTC              America/New_York relabeled America/New_York
#> 26 relaxed <empty>          UTC              America/New_York relabeled America/New_York
#> 27 relaxed <absent>         UTC              America/New_York relabeled America/New_York
#> 28 relaxed America/New_York UTC              America/New_York ok        America/New_York
#> 29 relaxed UTC              <empty>          America/New_York relabeled America/New_York
#> 30 relaxed <empty>          <empty>          America/New_York relabeled America/New_York
#> 31 relaxed <absent>         <empty>          America/New_York relabeled America/New_York
#> 32 relaxed America/New_York <empty>          America/New_York ok        America/New_York
#> 33 relaxed UTC              America/New_York America/New_York relabeled America/New_York
#> 34 relaxed <empty>          America/New_York America/New_York relabeled America/New_York
#> 35 relaxed <absent>         America/New_York America/New_York relabeled America/New_York
#> 36 relaxed America/New_York America/New_York America/New_York ok        America/New_York
cat("\ntally:\n")
#> 
#> tally:
print(table(out$verdict))
#> 
#>        ok relabeled 
#>         6        30
```

<sup>Created on 2026-09-26 with [reprex v2.1.1](https://reprex.tidyverse.org)</sup>

<details style="margin-bottom:10px;">

<summary>

Session info
</summary>

``` r
sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.5.3 (2026-03-11)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language (EN)
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       Etc/UTC
#>  date     2026-09-26
#>  pandoc   3.9.0.2 @ /usr/local/bin/ (via rmarkdown)
#>  quarto   1.9.38 @ /usr/local/bin/quarto
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#>  package     * version    date (UTC) lib source
#>  cli           3.6.6      2026-04-09 [1] RSPM
#>  DBI         * 1.3.0      2026-02-25 [1] RSPM
#>  digest        0.6.39     2025-11-19 [1] RSPM
#>  duckdb      * 1.5.5.9026 2026-09-26 [1] local
#>  evaluate      1.0.5      2025-08-27 [1] RSPM
#>  fastmap       1.2.0      2024-05-15 [1] RSPM
#>  fs            2.1.0      2026-04-18 [1] RSPM
#>  glue          1.8.1      2026-04-17 [1] RSPM
#>  htmltools     0.5.9      2025-12-04 [1] RSPM
#>  knitr         1.52       2026-09-06 [1] RSPM
#>  lifecycle     1.0.5      2026-01-08 [1] RSPM
#>  otel          0.2.0      2025-08-29 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.32       2026-09-01 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  withr         3.0.3      2026-06-19 [1] RSPM
#>  xfun          0.60       2026-07-09 [1] RSPM
#>  yaml          2.3.12     2025-12-10 [1] RSPM
#> 
#>  [1] /root/R/x86_64-pc-linux-gnu-library/4.5
#>  [2] /opt/R/4.5.3/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

</details>
