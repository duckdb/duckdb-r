``` r
# The same round trips, but with nobody calling `SET TimeZone`.
#
# grid.R sets the session zone in every cell, which is what a caller who
# knows about it would do. This is the other half: what the defaults do, and
# whether the answer moves with the machine's TZ. run-defaults.sh supplies
# POLICY; the machine zones are covered by spawning one process each, because
# icu reads the zone once, when it loads.
ZONES <- c("UTC", "Etc/UTC", "Europe/Zurich")

suppressMessages(library(duckdb))
options(width = 200)

rel_from_df <- duckdb:::rel_from_df
rel_to_altrep <- duckdb:::rel_to_altrep

policy <- Sys.getenv("POLICY", "shipped")
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

verdict_of <- function(out, df) {
  if (inherits(out, "error")) {
    return(c("refused", NA_character_))
  }
  same_label <- identical(attr(out$a, "tzone"), attr(df$a, "tzone"))
  same_instant <- isTRUE(all.equal(as.numeric(out$a), INSTANT))
  v <- if (!same_instant) {
    "wrong-instant"
  } else if (same_label) {
    "ok"
  } else {
    "relabeled"
  }
  c(v, label_of(out$a))
}

cell <- function(col, tz_out) {
  df <- data.frame(a = make_col(col))
  con <- suppressMessages(dbConnect(duckdb(), timezone_out = tz_out))
  on.exit(dbDisconnect(con, shutdown = TRUE))

  session <- dbGetQuery(con, "SELECT current_setting('TimeZone') AS tz")$tz
  rel <- verdict_of(
    tryCatch(rel_to_altrep(rel_from_df(con, df)), error = function(e) e),
    df
  )
  dbi <- verdict_of(
    tryCatch(
      {
        dbWriteTable(con, "t", df)
        dbReadTable(con, "t")
      },
      error = function(e) e
    ),
    df
  )

  data.frame(
    policy = policy,
    TZ = Sys.getenv("TZ"),
    col = label_of(df$a),
    tz_out = if (nzchar(tz_out)) tz_out else "<empty>",
    session = session,
    rel = rel[[1]],
    rel_back = rel[[2]],
    dbi = dbi[[1]],
    dbi_back = dbi[[2]]
  )
}

grid <- expand.grid(
  col = c("UTC", "empty", "absent", "America/New_York"),
  tz_out = c("UTC", "", "America/New_York"),
  stringsAsFactors = FALSE
)

if (nzchar(Sys.getenv("DUCKDB_R_ZONE_CHILD"))) {
  out <- do.call(rbind, Map(cell, grid$col, grid$tz_out))
  rownames(out) <- NULL
  print(out, right = FALSE)
} else {
  for (zone in ZONES) {
    cat(
      system2(
        "Rscript",
        "defaults-grid.R",
        env = c(
          paste0("TZ=", zone),
          paste0("POLICY=", policy),
          "DUCKDB_R_ZONE_CHILD=1"
        ),
        stdout = TRUE,
        stderr = TRUE
      ),
      sep = "\n"
    )
  }
}
#>    policy  TZ  col              tz_out           session rel       rel_back         dbi       dbi_back
#> 1  shipped UTC UTC              UTC              UTC     ok        UTC              ok        UTC     
#> 2  shipped UTC <empty>          UTC              UTC     refused   <NA>             relabeled UTC     
#> 3  shipped UTC <absent>         UTC              UTC     refused   <NA>             relabeled UTC     
#> 4  shipped UTC America/New_York UTC              UTC     refused   <NA>             relabeled UTC     
#> 5  shipped UTC UTC              <empty>          UTC     refused   <NA>             ok        UTC     
#> 6  shipped UTC <empty>          <empty>          UTC     relabeled <absent>         relabeled UTC     
#> 7  shipped UTC <absent>         <empty>          UTC     ok        <absent>         relabeled UTC     
#> 8  shipped UTC America/New_York <empty>          UTC     refused   <NA>             relabeled UTC     
#> 9  shipped UTC UTC              America/New_York UTC     refused   <NA>             ok        UTC     
#> 10 shipped UTC <empty>          America/New_York UTC     refused   <NA>             relabeled UTC     
#> 11 shipped UTC <absent>         America/New_York UTC     refused   <NA>             relabeled UTC     
#> 12 shipped UTC America/New_York America/New_York UTC     ok        America/New_York relabeled UTC     
#>    policy  TZ      col              tz_out           session rel       rel_back         dbi       dbi_back
#> 1  shipped Etc/UTC UTC              UTC              Etc/UTC ok        UTC              relabeled Etc/UTC 
#> 2  shipped Etc/UTC <empty>          UTC              Etc/UTC refused   <NA>             relabeled Etc/UTC 
#> 3  shipped Etc/UTC <absent>         UTC              Etc/UTC refused   <NA>             relabeled Etc/UTC 
#> 4  shipped Etc/UTC America/New_York UTC              Etc/UTC refused   <NA>             relabeled Etc/UTC 
#> 5  shipped Etc/UTC UTC              <empty>          Etc/UTC refused   <NA>             relabeled Etc/UTC 
#> 6  shipped Etc/UTC <empty>          <empty>          Etc/UTC relabeled <absent>         relabeled Etc/UTC 
#> 7  shipped Etc/UTC <absent>         <empty>          Etc/UTC ok        <absent>         relabeled Etc/UTC 
#> 8  shipped Etc/UTC America/New_York <empty>          Etc/UTC refused   <NA>             relabeled Etc/UTC 
#> 9  shipped Etc/UTC UTC              America/New_York Etc/UTC refused   <NA>             relabeled Etc/UTC 
#> 10 shipped Etc/UTC <empty>          America/New_York Etc/UTC refused   <NA>             relabeled Etc/UTC 
#> 11 shipped Etc/UTC <absent>         America/New_York Etc/UTC refused   <NA>             relabeled Etc/UTC 
#> 12 shipped Etc/UTC America/New_York America/New_York Etc/UTC ok        America/New_York relabeled Etc/UTC 
#>    policy  TZ            col              tz_out           session       rel       rel_back         dbi       dbi_back     
#> 1  shipped Europe/Zurich UTC              UTC              Europe/Zurich ok        UTC              relabeled Europe/Zurich
#> 2  shipped Europe/Zurich <empty>          UTC              Europe/Zurich refused   <NA>             relabeled Europe/Zurich
#> 3  shipped Europe/Zurich <absent>         UTC              Europe/Zurich refused   <NA>             relabeled Europe/Zurich
#> 4  shipped Europe/Zurich America/New_York UTC              Europe/Zurich refused   <NA>             relabeled Europe/Zurich
#> 5  shipped Europe/Zurich UTC              <empty>          Europe/Zurich refused   <NA>             relabeled Europe/Zurich
#> 6  shipped Europe/Zurich <empty>          <empty>          Europe/Zurich relabeled <absent>         relabeled Europe/Zurich
#> 7  shipped Europe/Zurich <absent>         <empty>          Europe/Zurich ok        <absent>         relabeled Europe/Zurich
#> 8  shipped Europe/Zurich America/New_York <empty>          Europe/Zurich refused   <NA>             relabeled Europe/Zurich
#> 9  shipped Europe/Zurich UTC              America/New_York Europe/Zurich refused   <NA>             relabeled Europe/Zurich
#> 10 shipped Europe/Zurich <empty>          America/New_York Europe/Zurich refused   <NA>             relabeled Europe/Zurich
#> 11 shipped Europe/Zurich <absent>         America/New_York Europe/Zurich refused   <NA>             relabeled Europe/Zurich
#> 12 shipped Europe/Zurich America/New_York America/New_York Europe/Zurich ok        America/New_York relabeled Europe/Zurich
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
