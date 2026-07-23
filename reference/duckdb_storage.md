# DuckDB file-system usage: storage locations and how they are resolved

**\[experimental\]**

DuckDB writes several distinct kinds of data to the file system. This
page catalogs every such location and documents the policy the duckdb R
package uses to choose them. By default the package never creates
anything in your home directory on its own: downloaded extensions and
stored secrets go under the R session's temporary directory unless a
`~/.duckdb` directory already exists (or you point the package somewhere
explicitly).

`duckdb_storage_status()` reports where each location currently
resolves.

## Usage

``` r
duckdb_storage_status()
```

## Value

`duckdb_storage_status()` returns a data frame (class
`"duckdb_storage_status"`) with one row per kind of state and columns
`kind`, `source`, and `directory`; its print method renders a readable
summary when the result is auto-printed.

## Details

`duckdb_storage_status()` reports the directory the package would
currently use for downloaded extensions and for persisted secrets, and
which tier of the resolution above chose it. It has no side effects: it
never prompts and never creates a directory, so an as-yet-uncreated
`~/.duckdb` is reported as the per-session temporary default.

## Kinds of on-disk state

- Home directory:

  The base DuckDB uses to expand a leading `~` and to derive default
  sub-locations. DuckDB setting: `home_directory`. The package does not
  set this: doing so would also redirect `~` in user SQL (e.g.
  `COPY ... TO '~/out.csv'`). The extension and secret locations below
  are pointed at the resolved home root directly instead.

- Extension binaries:

  Downloaded `*.duckdb_extension` files (e.g. `spatial`, `httpfs`,
  `h3`). DuckDB setting: `extension_directory`. A re-usable cache placed
  at `<home>/extensions`, where `<home>` is resolved as described below.

- Stored secrets:

  Persisted credentials under `stored_secrets`. DuckDB setting:
  `secret_directory`. Placed at `<home>/stored_secrets`, the same
  `<home>`.

- Temporary / spill files:

  Out-of-core intermediates for sorts, hash joins, and similar
  operations. DuckDB settings: `temp_directory`,
  `max_temp_directory_size`. For an in-memory (`:memory:`) database
  DuckDB's own default spills to `.tmp` in the current working
  directory, so the package overrides it with a
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) sub-directory by
  default. This is a separate setting from the extension/secret home
  (see below).

- Logs and profiling output:

  Written only when a path is explicitly configured (DuckDB settings
  `log_query_path`, `http_logging_output`, profiling output). They
  default to *off*, so nothing is written without the user asking, and
  the user chooses where it goes.

- Database file, WAL, and checkpoints:

  Chosen by the user through the `dbdir` argument of
  [`duckdb()`](https://r.duckdb.org/reference/duckdb.md). The package
  does not manage these.

## Resolving the home directory

Extensions and secrets share one *home* root, resolved fresh on every
call to [`duckdb()`](https://r.duckdb.org/reference/duckdb.md) that
creates a new database driver object. The first source that yields a
value wins:

1.  the `home` argument to
    [`duckdb()`](https://r.duckdb.org/reference/duckdb.md);

2.  the `duckdb.home` R option, e.g.
    `options(duckdb.home = "/path/to/duckdb")`;

3.  the `DUCKDB_R_HOME` environment variable;

4.  `~/.duckdb`, if that directory already exists – the location shared
    with the DuckDB CLI and other clients;

5.  In interactive sessions only, the package offers to create
    `~/.duckdb` once: answer "yes" to create and use it, "no" to fall
    through to the temporary directory below, or cancel the prompt to
    abort with an error.

6.  Otherwise a per-session sub-directory of
    [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

The extension cache is then `<home>/extensions` and the secret store is
`<home>/stored_secrets`.

Because the decision is remade on every new driver object, creating
`~/.duckdb` (or setting the option/variable) takes effect immediately
for drivers created afterwards. Existing drivers are unaffected.

The `shared_home` argument of
[`duckdb()`](https://r.duckdb.org/reference/duckdb.md) overrides this
resolution: `shared_home = TRUE` uses (and creates) `~/.duckdb`, and
`shared_home = FALSE` forces a per-session
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) even if `~/.duckdb`
already exists.

## Per-location reference

|  |  |  |  |
|----|----|----|----|
| Kind | DuckDB setting | How to set it | Default |
| Home | `home_directory` | – | left untouched (not set) |
| Extensions | `extension_directory` | `home` arg / `duckdb.home` / `DUCKDB_R_HOME` (as `<home>/extensions`) | [`tempdir()`](https://rdrr.io/r/base/tempfile.html) sub-directory (set) |
| Stored secrets | `secret_directory` | like extensions (`<home>/stored_secrets`) | [`tempdir()`](https://rdrr.io/r/base/tempfile.html) sub-directory (set) |
| Temp/spill | `temp_directory` | `duckdb.temp_directory` / `DUCKDB_R_TEMP_DIRECTORY` | [`tempdir()`](https://rdrr.io/r/base/tempfile.html) sub-directory (set) |
| Logs | `log_query_path` | DuckDB setting | disabled (off) |

"set" means [`duckdb()`](https://r.duckdb.org/reference/duckdb.md) sets
the value explicitly in the database config. The home directory is left
untouched so that `~` in user SQL keeps its usual meaning. An
`extension_directory` / `secret_directory` / `temp_directory` passed
directly in the `config` list is always honored and takes precedence
over the resolution above.

## Messages

- Storage-location message:

  When the package picked the location itself (a per-session
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html), or an existing
  `~/.duckdb`), [`duckdb()`](https://r.duckdb.org/reference/duckdb.md)
  emits an informational message describing where extensions and secrets
  are going and how to change it. It is throttled by session type: in an
  **interactive** session at most once every eight hours (a human can
  act on it); in a **non-interactive** session up to 60 times, after
  which it goes silent for good, so a long-running or automated process
  is not reminded forever. The message is suppressed entirely when you
  chose the location yourself – the `home` or `shared_home` argument,
  the `duckdb.home` option, or the `DUCKDB_R_HOME` environment variable.
  Non-interactively it covers both the temporary directory and an
  existing `~/.duckdb`; interactively it is issued only when the user
  opts out of creating `~/.duckdb`. It is also suppressed once you have
  made any explicit `home` or `shared_home` choice earlier in the
  session: having set the location explicitly once, you have seen how,
  so later auto-resolved calls stay quiet.

### Silencing the message

Make the choice explicit and it is no longer announced. Pass
`shared_home` to [`duckdb()`](https://r.duckdb.org/reference/duckdb.md)
– `TRUE` to keep extensions and secrets under `~/.duckdb`, `FALSE` to
accept a per-session temporary directory. Alternatively, point `home`
(or the `duckdb.home` option / `DUCKDB_R_HOME` variable) at a location
of your choice. As a last resort, use
[`suppressMessages()`](https://rdrr.io/r/base/message.html):

    # Explicit arguments:
    con <- dbConnect(duckdb(shared_home = FALSE))
    con <- dbConnect(duckdb(home = "/path/to/duckdb"))

    # As a fallback:
    con <- suppressMessages(dbConnect(duckdb()))

    # With configuration:
    Sys.setenv(DUCKDB_R_HOME = "/path/to/duckdb")
    con <- dbConnect(duckdb())
    options(duckdb.home = "/path/to/duckdb")
    con <- dbConnect(duckdb())

## Use by other packages

Packages that use duckdb inherit this policy:

- duckdb never writes outside
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) on its own during
  checks. In a non-interactive session (which all `R CMD check` runs
  are) it uses [`tempdir()`](https://rdrr.io/r/base/tempfile.html) by
  default unless a `~/.duckdb` already exists, and it never *creates*
  `~/.duckdb` unless requested. So a package that merely opens a
  database needs no special handling.

- Downloading and installing an extension is the caller's
  responsibility. Ensure that all tests involving extensions are skipped
  if the download fails. For robust testing on CRAN and other platforms,
  ensure that the extensions your package uses can be downloaded and
  installed. Run the check in a subprocess to avoid crashing the main R
  process if the extension is incompatible with the platform. To force a
  throwaway cache in your own tests, connect with an explicit home:

    tempdir_for_tests <- withr::local_tempdir()
    con <- DBI::dbConnect(duckdb::duckdb(home = tempdir_for_tests))

## See also

[`duckdb()`](https://r.duckdb.org/reference/duckdb.md) for the `home`
and `shared_home` arguments.

## Examples

``` r
duckdb_storage_status()
#> DuckDB storage locations:
#>   extensions      [session]  /tmp/Rtmp9PM0QG/duckdb/extensions
#>   stored_secrets  [session]  /tmp/Rtmp9PM0QG/duckdb/stored_secrets
```
