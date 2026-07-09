# Configure where DuckDB stores extensions and secrets

**\[experimental\]**

Choose where the duckdb R package keeps downloaded extensions and
persisted secrets, by writing a small marker file that records the
choice:

- `duckdb_extension_storage()` – set or move the extension cache
  (default: a per-session temporary directory).

- `duckdb_secret_storage()` – set or move the secret store (default: a
  per-session temporary directory).

- `duckdb_storage_status()` – report where each currently resolves.

These functions move the cache and secret store to a location that
survives across sessions; the same locations can also be set without a
marker by overriding with options and environment variables. The full
policy is documented in
[duckdb_storage](https://r.duckdb.org/reference/duckdb_storage.md).

## Usage

``` r
duckdb_extension_storage(
  location = c("session", "user", "shared"),
  ...,
  migrate = TRUE,
  conflict = "error"
)

duckdb_secret_storage(
  location = c("session", "user", "shared"),
  ...,
  migrate = TRUE,
  conflict = "error"
)

duckdb_storage_status()
```

## Arguments

- location:

  The destination root (not a path), one of:

  - `"session"` – the per-session temporary directory; the default, and
    the opt-out (removes the marker, reverting to a per-session
    location).

  - `"user"` –
    [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

  - `"shared"` – `~/.duckdb`, shared with the DuckDB CLI and Python
    client.

  To use an arbitrary directory, set the option or environment variable
  instead (see
  [duckdb_storage](https://r.duckdb.org/reference/duckdb_storage.md)).

- ...:

  These dots are for future extensions and must be empty.

- migrate:

  If `TRUE` (the default), move the already-cached files from the
  current location into the new one. Ignored when `location` is
  `"session"`: opting out never moves files into the per-session
  directory.

- conflict:

  How to resolve a name collision during migration: `"error"` (the
  default) aborts and lists the collisions without moving anything;
  `"ours"` lets the files being relocated overwrite the destination;
  `"theirs"` keeps the destination files and drops the colliding
  sources.

## Value

The `*_storage()` functions are called for their side effect (writing or
removing a marker, and optionally migrating files) and return the
resolved directory invisibly. `duckdb_storage_status()` returns a data
frame (class `"duckdb_storage_status"`) with one row per kind of state
and columns `kind`, `source`, and `directory`; its print method renders
a readable summary when the result is auto-printed.

## Details

`duckdb_extension_storage()` and `duckdb_secret_storage()` write (or
remove) the marker for that one kind of state, so the two can be
configured independently. `duckdb_storage_status()` reports where each
kind currently resolves and which tier of the resolution policy chose
it. The new location takes effect for connections opened afterwards;
existing connections are unaffected.

There is no `ask` argument: calling a `*_storage()` function is itself
the consent to write outside the temporary directory.

## See also

[duckdb_storage](https://r.duckdb.org/reference/duckdb_storage.md) for
the storage policy these functions implement.
