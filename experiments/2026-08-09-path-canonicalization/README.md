# Path canonicalization: what the engine knows that R does not

*What it measures:* what DuckDB reports as a database's path once it has
opened it, how that compares to R's `normalizePath()` for the same
spelling, and whether the two ever disagree —
the facts a driver cache keyed on the path depends on
([`usage/connections/`](/handbook/usage/connections/README.md)).
Nine questions, asked identically on three platforms:
canonicalization of spellings for a database that does not exist yet
and one that does, symlinks, case, Windows separators and short names,
a parent directory that cannot be read
([#455](https://github.com/duckdb/duckdb-r/issues/455)'s shape),
whether anything canonicalizes without creating a database,
read-only attach, and cost.

*When and on what:* 2026-08-09,
`ubuntu-latest`, `macos-latest` and `windows-latest` GitHub runners,
R 4.6.1 with DBI and duckdb 1.5.5 (engine v1.5.5) installed from CRAN —
no source build, because the questions are about path semantics
and a released binary answers them as well.
Method: [`probe.R`](probe.R), run by a scratch workflow that installs
the two packages and nothing else
([#2626](https://github.com/duckdb/duckdb-r/pull/2626), which drops
every other workflow so the matrix stays a couple of minutes, and is
not meant to merge); runs
[31324405357](https://github.com/duckdb/duckdb-r/actions/runs/31324405357)
and, with the storage advisory silenced,
[31324600995](https://github.com/duckdb/duckdb-r/actions/runs/31324600995).
Re-running it means restoring that workflow.
The closing section reads the vendored engine sources rather than
measuring, and cites them.

*What it supports:* the normalization bullet in
[`usage/connections/`](/handbook/usage/connections/README.md),
and the decision on whether the driver cache key should come from
`normalizePath()` or from the engine.

## The two canonicalizers agreed everywhere

Every spelling, every platform, `agree=TRUE`: the string DuckDB reports
and the string `normalizePath()` returns were byte-identical.
That covers `..`, doubled separators, a trailing separator, a relative
path, `./`, and — on Windows — backslashes, forward slashes, mixed
separators, either drive-letter case, and an 8.3 short name.
Five spellings of one database collapsed to one key on all three.

The Windows answers matter most, because that is where the two could
have differed and did not:

* DuckDB reports Windows paths **backslash-separated**, which is
  `normalizePath()`'s default (`winslash = "\\"`).
  Adopting the engine's string changes nothing a caller sees in
  `drv@dbdir` or `dbGetInfo()$dbname`.
* `C:\Users\RUNNER~1\AppData\Local\Temp\RTMPSW~1\probe\s5\w.duckdb`
  came back expanded to the long, case-correct
  `C:\Users\runneradmin\AppData\Local\Temp\RtmpSWIRcr\probe\s5\w.duckdb`
  from both.
* A UNC path (`\\localhost\C$\...`) was left as it stood by both,
  identically.

**Case.** On the two case-insensitive filesystems (Windows, macOS) a
database created as `Case.duckdb` and asked for as `case.duckdb`
produced one key from both canonicalizers — the on-disk spelling.

**Symlinks.** Resolved on all three, directory and file alike, by both.
The Windows runner could create them, so this is measured rather than
skipped.

**The key does not change when the database appears.** Section 2's
answer for an existing database equals section 1's for the same path
before it existed, on all three platforms.

## The #455 shape was not reproducible on a runner

On POSIX, no permission configuration separates the two.
With euid 501 (macOS) and the unprivileged Linux runner:

* mode `0311` — search, no read: `normalizePath(mustWork = TRUE)`
  succeeds, DuckDB succeeds.
* mode `0611` — read, no search: `normalizePath(mustWork = TRUE)`
  **fails**, and DuckDB fails too, with `Permission denied`.

That is the expected POSIX result: resolving a path needs search
permission, and so does opening the file, so nothing is denied to one
and granted to the other.

On Windows, `icacls /deny <user>:(RD)` on a directory above the file
applied cleanly and `normalizePath(mustWork = TRUE)` still succeeded —
the runner account is an administrator, so the deny did not bite.
The shape #455 reports was therefore neither reproduced nor refuted
here.

## What the engine actually does

Read from the vendored sources rather than measured.
`LocalFileSystem::CanonicalizePath()`
([`local_file_system.cpp:1456`](/src/duckdb/src/common/local_file_system.cpp))
makes the path absolute, then walks *up* from the full path trying
`TryCanonicalizeExistingPath()` on each prefix, and appends the
components it had to drop:

* POSIX (`:810`): `realpath()`.
* Windows (`:1369`): `CreateFileW` with **zero** desired access —
  "No access needed, just query" — then
  `GetFinalPathNameByHandleW(..., FILE_NAME_NORMALIZED)`, stripping the
  `\\?\` prefixes.

Two consequences.
A database that does not exist yet needs nothing created: the deepest
existing ancestor canonicalizes and the rest is appended, separators
included.
And the Windows implementation asks for *traverse* on the directories
above, where R's `normalizePath()` uses `GetLongPathNameW`, which must
*enumerate* each one.
A share that grants traverse and refuses listing is exactly the
configuration #455 describes.

`FileSystem::CanonicalizePath` is declared `DUCKDB_API virtual`
([`file_system.hpp:321`](/src/duckdb/src/include/duckdb/common/file_system.hpp)),
so it is reachable from the glue without an instance, a connection, or
SQL.

## Nothing cheaper canonicalizes

`glob()` returns a symlinked directory resolved but leaves `..`
untouched, and returns no rows for a path that does not exist.
`parse_path()` is string splitting.
Through the SQL surface, `ATTACH` is the only canonicalizer.

## Two engine refusals worth knowing

* Read-only attach of a database that does not exist fails and creates
  nothing.
* **A zero-byte file is not a valid database.** The engine refuses it:
  `exists, but it is not a valid DuckDB database file!`.
  The placeholder the package writes today is exactly that, which makes
  deleting it load-bearing rather than tidy.

## Cost

Milliseconds per call, run 31324405357, with run 31324600995's Linux
figures in parentheses — the spread across two runs is runner noise, and
the ratios are the point:

* Linux: 26.4 (34) throwaway instance + attach + detach; 7.4 (2.9)
  attach + detach on a connection already open; 0.2 (0.4)
  `file.create()` + `normalizePath()` + `unlink()`.
* macOS: 18.1; 1.7; 0.2.
* Windows: 47; 10; 2.

The engine's canonicalization is not what costs — standing up an
instance to reach it is.
