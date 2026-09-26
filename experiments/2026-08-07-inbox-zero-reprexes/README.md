# Reprexes for the inbox-zero items still open

*What it measures:* what the released package does
when an issue from the "close with evidence", "close upstream", and "close as stale" groups of
[#2522](https://github.com/duckdb/duckdb-r/issues/2522) that is still open is run again,
one reprex per issue, rendered to a transcript that a closing comment can carry whole.
A closed issue needs no reprex here:
its close carries the evidence, and its transcript leaves with it.

*When and on what:* 2026-08-07, Linux x86_64, R 4.5.3,
**duckdb 1.5.5 from CRAN**, the version a reporter would install rather than this repository's development build,
with arrow 25.0.0 and reprex 2.1.1.
[`render.R`](render.R) renders every `issue-*.R` next to it as `.md`;
it sets `DUCKDB_R_HOME` so that 1.5.5's one-time storage-location note (see `?duckdb_storage`) does not open every transcript,
which changes where extensions are cached and nothing else.

*What it supports:* [`operations/triage/`](/handbook/operations/triage/README.md)'s rule that a close cites its evidence.

## Still open

* [#98](issue-0098-register-generic.md): still exactly `duckdb_register()` and `duckdb_register_arrow()`.
  They are not two names for one operation:
  the first calls `as.data.frame()` on its input, the second copies nothing.
  What arrived instead is the DBI Arrow API, which dispatches on the object.
* [#202](https://github.com/duckdb/duckdb-r/issues/202):
  which running work a Ctrl+C stops, in R and in the CLI,
  and why the MotherDuck `ATTACH` in the report behaves differently in the two,
  is [`2026-08-08-interrupt-reach/`](/experiments/2026-08-08-interrupt-reach/README.md).

## Re-running

```r
setwd("experiments/2026-08-07-inbox-zero-reprexes")
Rscript render.R                                  # all of them
Rscript render.R issue-0098-register-generic.R    # or one
```

Every transcript names its own duckdb version,
so a re-run on a later release is a new record rather than an edit of this one.
