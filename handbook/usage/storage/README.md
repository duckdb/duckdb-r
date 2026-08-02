# Storage locations

Where the package and the DuckDB engine it embeds write on disk:
the extension cache and the secret store,
how their location is resolved on every new database instance,
how to move it,
and the CRAN policy that produced the design.
Log and profiling output, which the package leaves off, is covered here too.

`?duckdb_storage` is the user-facing surface for the same material.
It ships in the package tarball and is what a user reaches from R;
it is derived from this leaf, not the other way round.

## What is written where

DuckDB writes several distinct kinds of state,
and the package decides only some of them.

| Kind | DuckDB setting | Location | Set by `duckdb()`? |
|---|---|---|---|
| Extension binaries | `extension_directory` | `<home>/extensions` | yes |
| Stored secrets | `secret_directory` | `<home>/stored_secrets` | yes |
| Temporary / spill files | `temp_directory` | a `tempdir()` sub-directory for an in-memory database, DuckDB's own `<db>.tmp` otherwise | in-memory only |
| Home | `home_directory` | — | never |
| Logs, profiling output | `log_query_path`, `http_logging_output` | — | never |
| Database file, WAL, checkpoints | — | the `dbdir` argument | never |

**Extension binaries** are the `*.duckdb_extension` files `INSTALL` downloads.
The package points `extension_directory` at `<home>/extensions`;
the engine then appends the DuckDB version and the platform to that path
and creates the tree on first install,
so a binary lands at
`<home>/extensions/<duckdb-version>/<platform>/<name>.duckdb_extension`.
The version and platform components are why one home
can serve several DuckDB versions without collision.

**Stored secrets** are what `CREATE PERSISTENT SECRET` writes:
one `<name>.duckdb_secret` file per secret under `<home>/stored_secrets`.
Secret files are version-specific,
so a store written by one DuckDB version is not reliably readable by another.

**The home directory** is DuckDB's own `home_directory` setting,
the base it uses to expand a leading `~`.
The package never sets it,
and instead points `extension_directory` and `secret_directory`
at the resolved root directly.
Setting `home_directory` would be both too little and too much:
it does not move the spill directory,
and because it is also the base for `~` in user SQL
it would silently redirect a statement like `COPY ... TO '~/out.csv'`.

**Logs and profiling output** are written only when a path is configured.
The package sets none of these settings,
so nothing is written unless the user asks for it,
and the user chooses where it goes.

Nothing is written into the package library
or into `tools::R_user_dir()`.

## Resolving the home

Extensions and secrets share one *home* root.
It is resolved afresh on every `duckdb()` call that creates a new database
instance, and the first source that yields a value wins:

1. `shared_home = TRUE` — use `~/.duckdb`, creating it if it does not exist,
   with no prompt.
   `shared_home = FALSE` — force a per-session temporary directory
   even if `~/.duckdb` already exists,
   ignoring the option and the environment variable below.
2. the `home` argument to `duckdb()`, a path used as the root as given.
   `home` and `shared_home` cannot be combined; passing both is an error.
3. the `duckdb.home` R option, e.g. `options(duckdb.home = "/path/to/duckdb")`.
   A value that is not a single non-empty string warns and is cleared.
4. the `DUCKDB_R_HOME` environment variable.
5. `~/.duckdb`, if that directory already exists.
6. in an interactive session only, an offer to create `~/.duckdb`, asked at
   most once per session: "yes" creates it and confirms;
   "no" falls through to the temporary directory below and is remembered,
   so the question is not asked again;
   cancelling the prompt aborts with an error whose text is the
   storage-location message, so the way to choose is in front of the user.
7. otherwise a per-session sub-directory of `tempdir()`,
   named after the package.

A `~` in the argument, option, or environment variable is expanded by R.
`~/.duckdb` itself is resolved the way the engine resolves it —
from `USERPROFILE` on Windows and `HOME` elsewhere,
not through R's `path.expand("~")`,
which on Windows points at the user's Documents folder,
where the DuckDB CLI and the Python client never look.
That is what makes `~/.duckdb` genuinely shared with the rest of the
DuckDB ecosystem.

An `extension_directory` or `secret_directory` passed directly in the `config`
list wins over all of this:
the package fills in only the settings the caller did not supply,
and each of the two is decided independently.

Because the decision is remade for each new instance,
creating `~/.duckdb` — or setting the option or the variable — takes effect
immediately for instances created afterwards, and leaves existing ones alone.
The corollary is that a call which *reuses* a cached instance ignores
`home` and `shared_home` entirely,
which for a file-based `dbdir` is the common case
(see [`/handbook/usage/connections/`](/handbook/usage/connections/)).

The per-session root is named after the package,
so the renamed flavors
([`/handbook/branches/flavors/`](/handbook/branches/flavors/))
get separate session caches;
`~/.duckdb`, by contrast, is shared by all of them.

`duckdb_storage_status()` reports where each kind resolves right now.
It returns one row per kind with the resolved `directory`
and the `source` that chose it,
and it has no side effects — it never prompts and never creates a directory,
so an as-yet-uncreated `~/.duckdb` is reported as the session default.

## Moving the store

Making the choice explicit is the whole interface:
pass `shared_home` or `home` to `duckdb()`,
or set `duckdb.home` or `DUCKDB_R_HOME` before connecting.

```r
con <- dbConnect(duckdb(shared_home = TRUE))    # keep under ~/.duckdb
con <- dbConnect(duckdb(shared_home = FALSE))   # per-session, nothing persists
con <- dbConnect(duckdb(home = "/path/to/duckdb"))
```

Moving the store does not move its contents.
Nothing copies an existing extension cache or secret store
to a newly chosen location:
extensions are simply re-downloaded on demand,
and secrets have to be recreated.

The package creates a directory in exactly one situation —
`~/.duckdb`, when `shared_home = TRUE` or when the interactive prompt is
accepted.
Every other directory in the tree is created by the engine
when it first writes there.

## The connect-time message

When the package picked the location itself,
`duckdb()` says so once, describing where extensions and secrets are going
and how to change it.
It is announced for a per-session temporary directory,
and additionally for an existing `~/.duckdb` in a non-interactive session,
where nobody was asked.

Throttling differs by session type,
because the two audiences can do different things about it.
Interactively the message repeats at most once every eight hours;
a human can act on it, and a gentle cadence fits.
Non-interactively it is shown at most sixty times in a session and then
goes silent for good, the last one saying so —
a long-running or automated process should not be reminded forever.

The message is suppressed whenever the location was chosen rather than
inferred: by `home` or `shared_home`, by the `duckdb.home` option,
or by `DUCKDB_R_HOME`.
It also stays quiet for the rest of the session once any explicit
`home` or `shared_home` choice has been made —
having set the location once, the user has seen how.
`suppressMessages()` works as a last resort,
but silencing it by choosing is the intended route.

## Why the default avoids the home directory

The CRAN Repository Policy says a package should not write in the user's home
filespace, "nor anywhere else on the file system apart from the R session's
temporary directory".
The design follows from that:
the package never *creates* anything in the home directory on its own.

In a non-interactive session — which every `R CMD check` run is —
extensions and secrets go under `tempdir()`
unless `~/.duckdb` already exists or a location was set explicitly.
`~/.duckdb` is only ever created after an explicit interactive confirmation,
or an explicit `shared_home = TRUE`.
A reverse dependency therefore passes checks with no action of its own:
a package that merely opens a database needs no special handling.

A package that uses extensions has more to do, and it is the caller's job:
downloading and installing an extension is not something duckdb does for you.
Skip such tests when the download fails,
and run the check in a subprocess so an extension that is incompatible with
the platform cannot take the main R process down with it.
To force a throwaway cache, connect with an explicit home:

```r
con <- DBI::dbConnect(duckdb(home = withr::local_tempdir()))
```

## Limits

The design is implemented as described above, and no further.
[`/plan/PLAN-storage-locations.md`](/plan/PLAN-storage-locations.md)
carries the intent behind it and is ahead of the code in places;
where the two disagree, the code is what ships.
Specifically, the following are *not* available today:

* **No relocation API.**
  There is no `duckdb_extension_storage()` or `duckdb_secret_storage()`
  function, and no `"session"` / `"user"` / `"shared"` / `"library"`
  location vocabulary.
  The plan lists them as done; neither exists in `R/` or in `NAMESPACE`.
  The `home` and `shared_home` arguments are the whole of the interface.
* **No marker files, and no cache in the package library.**
  The plan's `.duckdb-r-keep` marker scheme and its writability probe
  of the installed library directory were not part of what landed.
  The extension cache is never placed in the package library.
* **No migration.**
  Changing the location leaves the old contents where they are.
* **No warning when an ephemeral cache is actually used.**
  A reactive warning, raised only if the session really wrote something,
  was deferred as too complex to land;
  the connect-time message above is what exists instead.

Three neighbouring topics are owned elsewhere.
Which extensions ship and where an extension is installed *from* belongs to
[`/handbook/usage/extensions/`](/handbook/usage/extensions/).
The spill directory — `temp_directory`, its override via the
`duckdb.temp_directory` option or the `DUCKDB_R_TEMP_DIRECTORY` variable,
and what fills it — belongs to
[`/handbook/usage/memory/`](/handbook/usage/memory/).
The database file itself, its WAL, and its checkpoints are chosen by the
caller through `dbdir` and belong to
[`/handbook/usage/connections/`](/handbook/usage/connections/).
