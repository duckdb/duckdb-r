# Fast paths

Linking a prebuilt `libduckdb` instead of compiling the vendored DuckDB
sources: the `DUCKDB_R_USE_SYSTEM_LIB` opt-in, the commit-match guard
that keeps it honest, and the claims it cannot support.

A clean source install compiles the whole vendored DuckDB tree and
takes many minutes
([`source-build/`](/handbook/build/source-build/)).
With the opt-in set, only the glue translation units in `src/` are
compiled and everything else is resolved from an already-built shared
library, which brings `R CMD INSTALL .` down to seconds.
It is meant for interactive iteration, coding-agent sessions, and CI —
never for a tarball that someone else installs.
Linux and macOS only; `configure` refuses any other platform.

## Setting it up

Install a `libduckdb` matching the vendored sources once,
then set the variable in every shell that builds or tests the package:

```sh
sudo scripts/install-libduckdb.sh              # into /usr/local
# or: scripts/install-libduckdb.sh --prefix "$HOME/.local"

export DUCKDB_R_USE_SYSTEM_LIB=1
export MAKEFLAGS="-j$(nproc)"

R CMD INSTALL . --no-byte-compile
R -q -e 'pkgload::load_all()'
R -q -e 'testthat::test_local()'
```

[`scripts/install-libduckdb.sh`](/scripts/install-libduckdb.sh) reads
`DUCKDB_VERSION` and `DUCKDB_SOURCE_ID` out of the vendored
`src/duckdb/src/function/table/version/pragma_version.cpp`,
picks the platform archive (`linux-amd64`, `linux-arm64`,
`osx-universal`),
and installs the shared library plus `duckdb.h` and `duckdb.hpp`
under `<prefix>/lib` and `<prefix>/include`.
`--version` (or `DUCKDB_R_LIB_VERSION`) overrides the version,
`--url` (or `DUCKDB_R_LIB_URL`) the whole download URL;
`sudo` is invoked only when the prefix is not writable.

`configure` finds the library through `DUCKDB_R_LIB_DIR` first,
then `pkg-config --variable=libdir duckdb`,
then the usual system directories,
and aborts with instructions if none of them holds a `libduckdb`.

The loop is not limited to `R CMD INSTALL`.
`pkgload::load_all()` and `devtools::load_all()` — and therefore
`testthat::test_local()`, which loads the package the same way —
compile through the same `configure` and `src/Makevars`, so they honor
the opt-in identically.
With `ccache` warm, a no-op `load_all()` and a `load_all()` after
editing one glue file both finish in seconds rather than the minutes a
vendored build takes.
The suite itself is [`testing/suite/`](/handbook/testing/suite/)'s topic.

## What is swapped, and what is not

Only the *implementation* is swapped.
The glue keeps compiling against the **vendored headers** in
`src/duckdb/src/include/`,
because it reaches into internal DuckDB C++ headers —
templates such as `GenericExecutor`, the Arrow integration,
core-functions extension internals —
and a large share of those are absent from the amalgamated `duckdb.hpp`
that ships with a `libduckdb` release.
The comment block at the top of `configure` records that reasoning,
and `configure` is where the header tree is wired up.

Mechanically, `configure` writes `src/Makevars.system-lib`,
which `src/Makevars` includes:
it empties `SOURCES` and sets
`PKG_LIBS=-L<dir> -lduckdb -Wl,-rpath,<dir>`.
The file is git-ignored, and the rest of the build is untouched.
Because of that rpath, moving or deleting the library after installing
breaks the installed package at load time.

Under `R CMD check` the package is first tarballed by `R CMD build`,
which compresses `src/duckdb/` into `src/duckdb.tar.xz`;
`configure` extracts it again before compiling, so the headers are there.

## The commit-match guard

Compiling against vendored internal headers while linking a foreign
implementation is only safe if both were built from the same upstream
commit, so `configure` hard-fails otherwise.
It reads `DUCKDB_SOURCE_ID` from the vendored `pragma_version.cpp`
and looks for that commit hash inside the installed
`libduckdb.so` / `libduckdb.dylib` with `strings`
(missing `strings` is itself a hard error — install `binutils`).
The comparison uses the first ten hex characters:
DuckDB truncates the hash to ten in the binary,
while the vendored file sometimes carries eleven.

On a mismatch the build stops and prints both commits —
the one the headers expect and the one the library reports —
and offers the two ways out:
re-run the install script, or unset the variable and compile the
vendored sources.
That is the routine to remember after every vendoring bump:
the library is stale the moment `src/duckdb/` moves,
and the guard is what turns a silent ABI mismatch into a clear error.

## The fast path proves nothing about the engine

The extension set and the autoload / autoinstall defaults are
properties of the linked library, not of the R glue.
A vendored build compiles the engine with `parquet` and
`core_functions` and with `-DDUCKDB_EXTENSION_AUTOLOAD_DEFAULT`;
a release `libduckdb` links more than that — `icu`, `json`,
`autocomplete` — and comes with a different
`autoinstall_known_extensions` default.
Under `DUCKDB_R_USE_SYSTEM_LIB=1` every engine symbol comes from the
release library, so anything observed about extensions in that mode
describes the release library and not the package that ships.
Engine configuration is therefore **never** verified on the fast path;
check it against a vendored build, and read
[`usage/extensions/`](/handbook/usage/extensions/) for what the package
actually ships.

The failure mode this guards against is real enough that `configure`
removes `src/Makevars.system-lib` on every run:
a file left behind by an earlier fast build keeps emptying `SOURCES`
and adding `-lduckdb`,
so a plain `R CMD INSTALL .` silently stays on the fast path and
produces a package that looks vendored while resolving its symbols —
and its extension set — from the system library.

## In CI

`.github/workflows/custom/before-install/action.yml` defaults every
non-Windows job, smoke test and regular matrix alike, to the fast path,
unless the entry pinned `DUCKDB_R_USE_SYSTEM_LIB` itself or the
repository is `krlmlr/duckdb-r`, which hosts the vendoring pipeline and
must always build from source.
It then runs the install script, and — if no library appeared, which is
how a development snapshot manifests — sets `DUCKDB_R_USE_SYSTEM_LIB=0`
so the job falls back to compiling the vendored tree.
`.github/versions-matrix.R` pins `DUCKDB_R_USE_SYSTEM_LIB=0` on a Linux
and a macOS entry, so the artifact that ships to CRAN is still
built from source on every platform: Windows never takes the fast path
at all.
The workflows themselves are [`operations/ci/`](/handbook/operations/ci/)'s.

## Limits

* **Not for `R CMD build` or for users.**
  The opt-in covers `R CMD INSTALL .` only.
  The resulting installation depends on `libduckdb` staying present at
  the path baked into its rpath,
  and on an exact-commit match that no end user can be asked to
  reproduce, so the package installed from CRAN or from a tarball
  always compiles the vendored sources.
  This is the answer to the standing request for an Arrow-style
  prebuilt-library install
  ([#22](https://github.com/duckdb/duckdb-r/issues/22)):
  the mechanism exists and is used daily, but as a development and CI
  opt-in, not as a distribution channel — the issue stays open for the
  user-facing half.
  The other speed-ups asked for there, `MAKEFLAGS` and `ccache`, are
  build knobs and live in
  [`configuration/`](/handbook/build/configuration/).
* **No prebuilt exists between releases.**
  The install script only resolves tagged versions, from the GitHub
  release assets.
  For a development snapshot such as `v1.5.4-dev157` it reports that no
  matching prebuilt is published and exits without installing anything,
  which is what lets a caller fall back cleanly;
  supply `DUCKDB_R_LIB_URL` if a private build is at hand.
  So on a `-dev` vendoring state the fast path is simply unavailable.
* **Linux and macOS only.**
  `configure` exits with an error on any other platform,
  and CI does not offer the mode on Windows.
* **`scripts/install-duckdb-cli.sh` is not part of this.**
  It fetches the standalone DuckDB CLI matching the vendored sources so
  the CLI-to-R end-to-end tests can run;
  it installs no library and changes no build.
