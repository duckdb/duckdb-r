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
#> policy baseline | duckdb 1.5.5.9026 | DuckDB 1.5.5 | local zone Etc/UTC
print(out, right = FALSE)
#>    policy   col              tz_out           session          verdict   back            
#> 1  baseline UTC              UTC              UTC              ok        UTC             
#> 2  baseline <empty>          UTC              UTC              refused   <NA>            
#> 3  baseline <absent>         UTC              UTC              refused   <NA>            
#> 4  baseline America/New_York UTC              UTC              refused   <NA>            
#> 5  baseline UTC              <empty>          UTC              refused   <NA>            
#> 6  baseline <empty>          <empty>          UTC              relabeled <absent>        
#> 7  baseline <absent>         <empty>          UTC              ok        <absent>        
#> 8  baseline America/New_York <empty>          UTC              refused   <NA>            
#> 9  baseline UTC              America/New_York UTC              refused   <NA>            
#> 10 baseline <empty>          America/New_York UTC              refused   <NA>            
#> 11 baseline <absent>         America/New_York UTC              refused   <NA>            
#> 12 baseline America/New_York America/New_York UTC              ok        America/New_York
#> 13 baseline UTC              UTC              Etc/UTC          ok        UTC             
#> 14 baseline <empty>          UTC              Etc/UTC          refused   <NA>            
#> 15 baseline <absent>         UTC              Etc/UTC          refused   <NA>            
#> 16 baseline America/New_York UTC              Etc/UTC          refused   <NA>            
#> 17 baseline UTC              <empty>          Etc/UTC          refused   <NA>            
#> 18 baseline <empty>          <empty>          Etc/UTC          relabeled <absent>        
#> 19 baseline <absent>         <empty>          Etc/UTC          ok        <absent>        
#> 20 baseline America/New_York <empty>          Etc/UTC          refused   <NA>            
#> 21 baseline UTC              America/New_York Etc/UTC          refused   <NA>            
#> 22 baseline <empty>          America/New_York Etc/UTC          refused   <NA>            
#> 23 baseline <absent>         America/New_York Etc/UTC          refused   <NA>            
#> 24 baseline America/New_York America/New_York Etc/UTC          ok        America/New_York
#> 25 baseline UTC              UTC              America/New_York ok        UTC             
#> 26 baseline <empty>          UTC              America/New_York refused   <NA>            
#> 27 baseline <absent>         UTC              America/New_York refused   <NA>            
#> 28 baseline America/New_York UTC              America/New_York refused   <NA>            
#> 29 baseline UTC              <empty>          America/New_York refused   <NA>            
#> 30 baseline <empty>          <empty>          America/New_York relabeled <absent>        
#> 31 baseline <absent>         <empty>          America/New_York ok        <absent>        
#> 32 baseline America/New_York <empty>          America/New_York refused   <NA>            
#> 33 baseline UTC              America/New_York America/New_York refused   <NA>            
#> 34 baseline <empty>          America/New_York America/New_York refused   <NA>            
#> 35 baseline <absent>         America/New_York America/New_York refused   <NA>            
#> 36 baseline America/New_York America/New_York America/New_York ok        America/New_York
cat("\ntally:\n")
#> 
#> tally:
print(table(out$verdict))
#> 
#>        ok   refused relabeled 
#>         9        24         3
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
#>  pillar        1.11.1     2025-09-17 [1] RSPM
#>  reprex        2.1.1      2024-07-06 [1] RSPM
#>  rlang         1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown     2.32       2026-09-01 [1] RSPM
#>  sessioninfo   1.2.4      2026-06-04 [1] RSPM
#>  vctrs         0.7.3      2026-04-11 [1] RSPM
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
