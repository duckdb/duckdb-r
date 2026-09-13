# DuckDB error conditions

Every error the database engine raises reaches R as a condition of class
`duckdb_error`, carrying DuckDB's own classification alongside the
message. Catch it with
[`tryCatch()`](https://rdrr.io/r/base/conditions.html) or
[`rlang::try_fetch()`](https://rlang.r-lib.org/reference/try_fetch.html)
and branch on the fields rather than on the message text, which is
formatted for display and is not a stable interface.

## Details

The condition is raised against the call that caused it –
[`DBI::dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html),
[`DBI::dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html),
[`DBI::dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html),
[`DBI::dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html), and
the relational API alike – and the fields survive that rethrow.

## Fields

- `error_type`:

  DuckDB's exception type as a string, such as `"BINDER"`, `"PARSER"`,
  `"CONSTRAINT"`, `"CONVERSION"`, `"IO"` or `"OUT_OF_MEMORY"`. This is
  the field to classify on. The set is the engine's and grows with it,
  so treat an unrecognized value as "some other error" rather than
  failing on it.

- `extra_info`:

  A named character vector of whatever else the engine attached to the
  error, for instance the position within the query. Which names appear
  depends on the error, and empty is a normal answer.

- `context`:

  The internal operation that failed, such as `"rapi_prepare"` or
  `"rapi_execute"`. Useful to tell a failure at prepare time from one at
  execution time; the individual names are an implementation detail and
  may change.

- `raw_message`:

  The message as the engine phrased it, without the exception type
  prefix and without the display formatting.

A field the engine did not supply is absent from the condition, so
reading it gives `NULL`. Classification code should therefore treat
`NULL` as "unknown" and keep a fallback branch: an error raised before
the engine is reached, by an R-level check or by a failing callback, is
an ordinary error with none of these fields.

Errors are formatted with bullets when rlang is installed; without it
the message is a single line, and the class and the fields are the same.

## Examples

``` r
con <- dbConnect(duckdb())
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /home/runner/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.

err <- tryCatch(dbGetQuery(con, "SELECT missing_column"), error = identity)
class(err)
#> [1] "duckdb_error" "rlang_error"  "error"        "condition"   
err$error_type
#> [1] "BINDER"
err$context
#> [1] "rapi_prepare"

dbDisconnect(con, shutdown = TRUE)
```
