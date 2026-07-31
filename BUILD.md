# Building and installing the duckdb R package

This document owns the build system:
the `configure` scripts, the makefile fragments under `src/`,
every environment variable that changes what gets compiled,
and the three ways to get an installed package.
For the branch model see [`BRANCHES.md`](BRANCHES.md),
for the test suite [`AGENTS.md`](AGENTS.md),
for vendoring [`scripts/VENDORING.md`](scripts/VENDORING.md).

The package compiles roughly 1700 vendored C++ files
plus 15 glue translation units.
Almost everything below exists to avoid paying for the first number.

## Choosing a build

| Path | Cold | Incremental | Use it for |
|---|---|---|---|
| **Vendored source** — `R CMD INSTALL .` | 10–15 min | minutes | anything that must match what ships; the CRAN artifact; **all engine-configuration questions** |
| **System libduckdb** — `DUCKDB_R_USE_SYSTEM_LIB=1` | ~90 s | ~4 s | glue and R-level iteration, `load_all()`, `test_local()`, docs, agent sessions |
| **Published binary** — CRAN / r-universe / P3M | seconds | — | reproducing a user report against a released build |

The middle path is the default for interactive work
and the one CI uses for most matrix entries.
Its one hard limit is [§ The fast path is not the package](#the-fast-path-is-not-the-package);
read that before trusting any result it produces.

## Vendored source build

```sh
export MAKEFLAGS="-j$(nproc)"      # configure does this for you if unset
R CMD INSTALL .
```

`configure` (and `configure.win`) run before compilation and:

1. set `MAKEFLAGS` from `scripts/setup-makeflags.R` when it is unset,
   so a plain `R CMD INSTALL .` still builds in parallel;
2. write `src/Makevars.rstrtmgr`, selecting the bundled `librstrtmgr.a`
   on R >= 4.2 (Windows only; older R lacks it);
3. extract `src/duckdb.tar.xz` when building from a tarball
   (see [Tarball layout](#tarball-layout));
4. choose between `src/include/from-tar.mk` and `src/include/to-tar.mk`
   depending on `DUCKDB_R_PREBUILT_ARCHIVE`;
5. write `src/Makevars.system-lib` when `DUCKDB_R_USE_SYSTEM_LIB` is set.

Configure ccache for repeated builds.
It is strictly better than `DUCKDB_R_PREBUILT_ARCHIVE` locally;
the archive exists for CI, where the cache key is explicit.

### `UserNM=true`

`UserNM=true R CMD INSTALL .` saves 10–20 s
by pointing R's `nm` at `true`.

**Never export it for `R CMD check`.**
`tools:::check_so_symbols` uses `$UserNM` to scan the built `.so`;
blinding that scan makes the check report
"Found no calls to `R_registerRoutines`, `R_useDynamicSymbols`"
and fail a package that registers its routines correctly.
It is not worth carrying into CI at all.

## System libduckdb (the fast path)

```sh
# One-time, matching the vendored DuckDB version
sudo scripts/install-libduckdb.sh              # to /usr/local
# or: scripts/install-libduckdb.sh --prefix "$HOME/.local"

# In every shell that builds or tests the package
export DUCKDB_R_USE_SYSTEM_LIB=1
export MAKEFLAGS="-j$(nproc)"

R CMD INSTALL . --no-byte-compile
R -q -e 'pkgload::load_all()'                  # ~1 s warm
R -q -e 'testthat::test_local()'
```

`pkgload::load_all()` / `devtools::load_all()` honor the variable too,
so `testthat::test_local()` gets the same speedup.

**What it actually swaps.**
The glue still compiles against the **vendored headers**
in `src/duckdb/src/include/`:
the amalgamated `duckdb.hpp` shipped with libduckdb releases
is missing about 37 of the 71 internal headers the glue needs
(templates like `GenericExecutor`, the Arrow integration,
core-functions extension internals).
Only the *implementation* is swapped, at link and run time.

**The commit guard.**
That is safe only if the vendored sources and the installed library
were built from the same commit.
`configure` extracts `DUCKDB_SOURCE_ID` from the vendored
`src/duckdb/src/function/table/version/pragma_version.cpp`,
greps for it inside the shared library,
and aborts with a clear error if it is absent.
Re-run `scripts/install-libduckdb.sh` after every vendoring bump.

`scripts/install-libduckdb.sh` resolves the version from the same file:
tagged versions come from the GitHub release assets,
development snapshots (e.g. `v1.5.4-dev157`) from the DuckDB nightly
staging bucket keyed by `DUCKDB_SOURCE_ID`.
If it reports a `-dev` snapshot with no published prebuilt,
drop `DUCKDB_R_USE_SYSTEM_LIB` and build from source.

**Not for `R CMD build`.**
The opt-in applies to `R CMD INSTALL .` only:
the resulting installation depends on libduckdb being present at runtime.
The installed `duckdb.so` carries an rpath pointing at the libduckdb directory,
so do not move libduckdb after installing.

**In CI**, `.github/workflows/custom/before-install/action.yml`
defaults all Linux/macOS builds to the fast path, except:

* the `krlmlr/duckdb-r` fork, which hosts the vendoring pipeline
  and must always build from source;
* any matrix entry that pins `DUCKDB_R_USE_SYSTEM_LIB` itself
  through the generic `env` field in `.github/versions-matrix.R`.
  That file carries a dedicated "vendored build" entry
  (`DUCKDB_R_USE_SYSTEM_LIB=0`) so one regular matrix build
  still compiles the bundled sources — the artifact that ships to CRAN.

### The fast path is not the package

`DUCKDB_R_USE_SYSTEM_LIB=1` links the **release** `libduckdb`,
which is not configured the way this package configures the engine.
Two differences are known and both are user-visible:

| | Vendored build (what ships) | Release libduckdb (fast path) |
|---|---|---|
| Statically linked extensions | `parquet`, `core_functions` | also `icu`, `json`, `autocomplete` |
| `autoinstall_known_extensions` | `false` | `true` |
| `autoload_known_extensions` | `true` | `true` |

Both follow from `src/Makevars.in`, which compiles with
`-DDUCKDB_EXTENSION_PARQUET_LINKED -DDUCKDB_EXTENSION_CORE_FUNCTIONS_LINKED`
and defines `DUCKDB_EXTENSION_AUTOLOAD_DEFAULT`
but **not** `DUCKDB_EXTENSION_AUTOINSTALL_DEFAULT`
(see `src/duckdb/src/include/duckdb/main/settings.hpp`,
where each setting's default is `#if defined(...) && ...`).

So:

> **Never verify engine configuration under `DUCKDB_R_USE_SYSTEM_LIB`.**
> Anything guarded by a `-D` in `src/Makevars.in` —
> linked extensions, autoload and autoinstall defaults, the allocator —
> must be checked against a vendored build.
> Glue and R-level behavior may use the fast path freely.

`duckdb_extensions()` under the fast path will happily report `icu`
as statically linked, which the shipped package does not have.

#### Switching between modes

`configure` writes `src/Makevars.system-lib` when the opt-in is active,
and `src/Makevars.in` picks it up with a plain `include`.
That file empties `SOURCES` and sets `PKG_LIBS=-lduckdb`.

Switching modes in a tree that has already built the other way
has two traps, in opposite directions:

**Fast path leaking into a vendored build.**
Nothing removes `Makevars.system-lib` once it exists,
so unsetting `DUCKDB_R_USE_SYSTEM_LIB` is *not* enough:
the next build keeps emptying `SOURCES` and linking `-lduckdb`
while still appearing to compile the vendored sources,
because make goes on building the objects it no longer links.
That is how one arrives at a confidently wrong answer about
the extension set. Delete the file by hand when leaving the fast path.
(duckdb/duckdb-r#2446 makes `configure` do it.)

**A stale shared object surviving the switch.**
`src/duckdb.so` depends on `$(OBJECTS)`.
With `SOURCES` empty, `OBJECTS` is just the 15 glue objects,
so a `duckdb.so` left over from a vendored build is *newer* than all of them
and make relinks nothing: the fast path silently installs the vendored library.
Nothing detects this, because the result is a correct package —
just not the one you asked for, and not in the seconds you expected.

So when switching modes, clear both:

```sh
rm -f src/Makevars.system-lib src/duckdb.so src/*.o
```

**Checking which mode produced a package** — the reliable test is the
installed shared object, not the environment variable:

```sh
ldd  <lib>/duckdb/libs/duckdb.so | grep libduckdb   # Linux
otool -L <lib>/duckdb/libs/duckdb.so | grep duckdb  # macOS
```

A vendored build has no `libduckdb` dependency and is an order of magnitude
larger (roughly 850 MB unstripped, versus 50 MB for the fast path).

## Published binaries

For reproducing a user's report rather than testing local changes,
install a published build instead of compiling anything.
[`README.md`](README.md) owns those instructions —
CRAN, the Posit Public Package Manager, and r-universe —
and states them under the right package name for each flavor,
which is why they are not repeated here.
See [`BRANCHES.md`](BRANCHES.md#r-package-flavors) for what each flavor tracks.

## Documentation builds

Regenerating `man/*.Rd` needs the exact roxygen2 version pinned in
`DESCRIPTION`'s `Config/roxygen2/version`, which is routinely a development
version and therefore not on CRAN. It installs from r-universe:

```r
install.packages("roxygen2", repos = c("https://r-lib.r-universe.dev", "https://cloud.r-project.org"))
```

roxygen2 loads the package to evaluate inline chunks,
so it needs a built package —
combine it with the fast path and the loop is about 90 seconds cold,
seconds warm:

```sh
export DUCKDB_R_USE_SYSTEM_LIB=1 MAKEFLAGS="-j$(nproc)"
R -q -e 'roxygen2::roxygenize()'
```

A mismatched roxygen2 version rewrites every `.Rd` file,
which is why CI pins it and why the diff is worth checking before committing.
Note that inline chunks are evaluated in the package's own namespace:
a hard-coded package name in a roxygen block silently de-evaluates
every other chunk in the same block —
see [`AGENTS.md`](AGENTS.md#never-hard-code-the-package-name).

## Build knobs

Environment variables read by `configure` / `configure.win` / `scripts/rconfigure.py`:

| Variable | Effect |
|---|---|
| `MAKEFLAGS` | parallel compilation; set from `scripts/setup-makeflags.R` when unset |
| `DUCKDB_R_USE_SYSTEM_LIB` | link a system libduckdb instead of compiling the vendored tree (Linux/macOS) |
| `DUCKDB_R_PREBUILT_ARCHIVE` | path to a `.tar` of object files; consumed via `from-tar.mk`, produced via `to-tar.mk` |
| `DUCKDB_R_LIB_VERSION`, `DUCKDB_R_LIB_URL` | override version / URL for `scripts/install-libduckdb.sh` |
| `UserNM` | R's `nm`; `true` speeds installs, breaks `R CMD check` |
| `DUCKDB_R_EXTENSIONS` | extra extensions to link statically, beyond `parquet` and `core_functions` |
| `DUCKDB_BUILD_UNITY` | unity-build group size (default 20) |
| `DUCKDB_DEBUG_MOVE` | adds `-DDUCKDB_DEBUG_MOVE` |
| `DUCKDB_PATH` | location of the `duckdb` clone for `scripts/vendor.sh` (default `../duckdb`) |
| `_R_SHLIB_STRIP_`, `R_STRIP_SHARED_LIB` | `src/install.libs.R` strips the shared library on Linux when both are set |

## Generated build files

`scripts/rconfigure.py` regenerates these from a DuckDB checkout
during vendoring; they are committed, not built at install time.

| File | Contents |
|---|---|
| `src/Makevars`, `src/Makevars.win` | rendered from `src/Makevars.in`; carry `PKG_CPPFLAGS`, `PKG_LIBS`, include paths |
| `src/include/sources.mk` | `SOURCES` — every vendored object file, including the unity `ub_*.o` groups |
| `src/include/glue.mk` | `GLUE` — the 15 glue object files |
| `src/CMakeLists.txt` | for IDE/clangd integration only; not used by `R CMD INSTALL` |

Hand-maintained:

| File | Contents |
|---|---|
| `src/Makevars.in` | the template: `CXX_STD`, `PKG_CPPFLAGS` with the `-D` flags that configure the engine |
| `src/include/deps.mk` | the `%.dd: %.d` rule that filters compiler dependency files |
| `src/include/from-tar.mk`, `to-tar.mk`, `to-tar-win.mk` | prebuilt-object-archive plumbing |
| `src/install.libs.R` | copies (and optionally strips) the shared library into the installed package |

### `.dd` files

`src/*.dd` are dependency-tracking files:
which glue sources must rebuild when a local header changes.
**Keep them in version control.**
They are generated by the `%.dd: %.d` rule in `src/include/deps.mk`,
which filters compiler-generated `.d` files down to local `include/` dependencies,
and should change only when a `.cpp` gains an `#include` of a local header.

If a build regenerates them with system paths (`/opt/R/...`)
or `../inst/include/...` entries, that is spurious —
revert with `git checkout -- src/*.dd`.
The historical cause was a filter in `deps.mk` using `^  ` (exactly two spaces)
where compiler continuation lines have only one; it now uses `^ *`.

## Tarball layout

`R CMD build` runs `cleanup`, which `tar cvJf`s `src/duckdb`
into `src/duckdb.tar.xz` and removes the directory,
keeping the tarball under CRAN's size limit.
`configure` extracts it again at install time,
which is why the fast path still finds the vendored headers
when running under `R CMD check`.

`cleanup` is a no-op if `src/duckdb.tar.xz` already exists,
and skips compression entirely when `xz` is unavailable
(so a machine that cannot expand the archive never creates one).
`SystemRequirements: xz` in `DESCRIPTION` records the dependency.

## Formatting

```sh
make format-check     # python3 scripts/format.py --all --check
make format-changes   # fix files changed since HEAD
```

Requires `cmake-format`: `pip3 install cmake-format`.
`.github/workflows/format-suggest.yaml` posts the same output
as review suggestions on pull requests.

## C++ warning policy

**Do not suppress warnings** with `#pragma clang diagnostic ignored`
or `-Wno-*`. CRAN rejects packages that silence warnings
rather than fixing the underlying issue.

Fix the root cause. For vendored code in `src/duckdb/`,
add a patch file in `patch/` that corrects the source
(see [`scripts/VENDORING.md`](scripts/VENDORING.md)).

Example: `-Wdeprecated-declarations` from `char_traits<T>` for non-char `T`
in libc++ was fixed by changing the `std_string_view` alias in
`src/duckdb/third_party/fmt/include/fmt/core.h`
to a struct that only provides `std::basic_string_view<Char>`
for standard char types.

Cosmetic warnings from vendored code are a different case:
patching the engine for `-Wunused-function` noise
costs drift on every vendor run and buys nothing,
so those go upstream instead.
