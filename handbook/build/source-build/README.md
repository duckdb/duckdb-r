# Source build

How a source tree becomes an installed shared library:
what `configure` writes before `make` starts,
how `src/Makevars` assembles the object list,
how the `.dd` dependency files stay honest,
and how the tree folds into a tarball and unfolds again.

## Bootstrap

A source build needs R with its development headers and a C++17 compiler —
on Debian or Ubuntu, `r-base`, `r-base-dev`, and `build-essential` —
and a library R may write to,
which on a bare container means creating one (`~/R/library`)
and pointing `.libPaths()` at it from `~/.Rprofile`.

```sh
export MAKEFLAGS="-j$(nproc)"
R CMD INSTALL . --no-byte-compile
```

The first build compiles the whole vendored engine:
tens of minutes, and an agent driving it must not cancel it —
set the timeout generously.
An edit-build-test loop should not use this build at all;
[`build/fast-paths/`](/handbook/build/fast-paths/README.md)
links a prebuilt libduckdb and turns the same command into seconds.
The knobs — `MAKEFLAGS`, `ccache`, `DUCKDB_R_PREBUILT_ARCHIVE`, `UserNM` —
belong to
[`build/configuration/`](/handbook/build/configuration/README.md);
what they plug into is here.

## Two stages

`R CMD INSTALL` runs `./configure` (`configure.win` on Windows) first,
then `make` in `src/`, driven by `src/Makevars` (`src/Makevars.win`).

`configure` computes no compiler flags.
Its whole job is to write three small `Makevars.*` fragments
that `src/Makevars` includes unconditionally,
and to restore `src/duckdb/` if it arrived compressed.
Every flag is already in the generated `src/Makevars`.

## What `configure` writes

The script runs under `set -ex`,
so every command is echoed and the first failure aborts the install.
In order:

1. **`MAKEFLAGS`**, only if unset:
   `scripts/setup-makeflags.R` proposes a `-jN` value,
   and `configure` exports it,
   echoing that `NOT_CRAN` or `MAKEFLAGS` overrides the choice.
2. **`src/Makevars.rstrtmgr`** — `DUCKDB_RSTRTMGR=1`
   and an empty `DUCKDB_RSTRTMGR_LIB`.
   The Windows Restart Manager is a Windows concern;
   off Windows the file is written for completeness,
   and only reaches the compiler as
   `-DDUCKDB_RSTRTMGR=$(DUCKDB_RSTRTMGR)`.
3. **`src/Makevars.system-lib` is deleted.**
   A stale one left by an earlier fast-path build would keep `SOURCES`
   empty and `-lduckdb` set,
   so a plain `R CMD INSTALL .` would silently stay on the fast path
   and produce a package that resolves DuckDB symbols from the system
   library — a different extension set and a different autoinstall
   default — while looking like a vendored build.
4. **The fast path exits here.**
   With `DUCKDB_R_USE_SYSTEM_LIB` set to `1` or `true`,
   `configure` writes `Makevars.system-lib` and returns;
   steps 5 and 6 never run.
5. **`src/Makevars.duckdb`** — a copy of `include/from-tar.mk`
   if `$DUCKDB_R_PREBUILT_ARCHIVE` names an existing file
   *and* `tar -xm -f` unpacked it, otherwise `include/to-tar.mk`.
6. **`src/duckdb/`** — extracted from `src/duckdb.tar.xz` if that file
   is present, with `gtar` preferred over `tar`
   when both `gtar` and `xz` are available.

All three fragments are gitignored: a fresh checkout has none of them,
which is why anything that inspects the build without installing
(the vendoring pipeline's glue gate, for instance) runs `./configure`
first.

## Windows

`configure.win` does the same work with three differences.
It runs under `set -e` rather than `set -ex`.
It has no fast path — `DUCKDB_R_USE_SYSTEM_LIB` is Linux and macOS only.
And `Makevars.rstrtmgr` becomes version-dependent:
R 4.2 and later get `DUCKDB_RSTRTMGR=1` and `DUCKDB_RSTRTMGR_LIB=-lrstrtmgr`,
while older R — whose Rtools, the script's comment records,
does not include `librstrtmgr.a` — gets `DUCKDB_RSTRTMGR=0`
and an empty library variable.
The same version test also gates the prebuilt archive,
which does not survive the multiarch builds of R below 4.2;
when the archive is written, `include/to-tar-win.mk` passes
`tar --force-local`, so a path like `C:\...` is not read as a remote host.

The toolchain is not this package's to choose:
a Windows build uses whatever Rtools the installing R ships,
which differs across R versions,
and `configure.win` plus the generated `src/Makevars.win` encode what it
needs — `-DDUCKDB_PLATFORM_RTOOLS=1`, `-lws2_32`, and `-lrstrtmgr`.
A change to the MinGW build that DuckDB's own CI uses for its Windows
binaries therefore does not change how this package compiles
([#2234](https://github.com/duckdb/duckdb-r/issues/2234));
what it changes is which prebuilt artifacts are compatible with the
result, because `-DDUCKDB_PLATFORM_RTOOLS=1` makes the engine report its
platform as `windows_amd64_mingw`
(`src/duckdb/src/include/duckdb/common/platform.hpp`),
and that string is the key extension downloads are fetched under —
[`usage/extensions/`](/handbook/usage/extensions/README.md)'s topic.
The issue stays open because the verdict is coordination with upstream,
not prose.

## What `src/Makevars` assembles

`src/Makevars` and `src/Makevars.win` are generated from
`src/Makevars.in` by `scripts/rconfigure.py` while vendoring, which is
[`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)'s
to run.
`src/Makevars.in` is `.Rbuildignore`d; only the generated files ship.
It carries three placeholders:

* `{{ HEADER }}` — the do-not-edit banner.
* `{{ INCLUDES }}` — the `-I` list for the vendored tree and its bundled
  third-party libraries, plus
  `-DDUCKDB_EXTENSION_<NAME>_LINKED -DDUCKDB_BUILD_LIBRARY`
  for each linked extension (`parquet` and `core_functions` by default),
  plus `-DDUCKDB_PLATFORM_RTOOLS=1` on Windows.
* `{{ LINK_FLAGS }}` — `-lws2_32 $(DUCKDB_RSTRTMGR_LIB)` on Windows.
  Elsewhere no library is needed,
  so `rconfigure.py` deletes the whole `PKG_LIBS=` line.

The generated file is a sequence of includes around one first target:

```make
all: symbols.rds $(SHLIB)
```

`all` has to come first, because the included fragments add a target of
their own (`duckdb.tar`) and make builds the first target it sees.
`symbols.rds` is R's own rule from `share/make/shlib.mk`:
it saves the symbol table of every object,
which is how a forbidden symbol such as `abort` is traced back to the
object that introduced it, and `src/install.libs.R` copies the file next
to the shared library when it exists.

Then, in order:

* `include/glue.mk` — `GLUE`, the objects of the R glue in `src/`.
* `include/sources.mk` — `SOURCES`, the vendored engine's object list,
  regenerated by `rconfigure.py`.
* `Makevars.rstrtmgr`, then `include/deps.mk`, `Makevars.duckdb`, and
  `Makevars.system-lib`.
  The last three have a fallback rule that `touch`es an empty file
  timestamped from the newest `.cpp`;
  the deliberately old timestamp keeps `pkgbuild` from discarding
  existing `.o` files.
  Plain `include` is used rather than `-include`,
  which is a GNU Make extension.
  `Makevars.rstrtmgr` has no such rule,
  so make stops before its first compile line if `configure` never ran.

The tail sets `CXX_STD = CXX17`,
a `PKG_CPPFLAGS` built from `-Iinclude -I../inst/include`,
`-DDUCKDB_DISABLE_PRINT`, `-DDUCKDB_R_BUILD`,
`-DDUCKDB_EXTENSION_AUTOLOAD_DEFAULT`,
`-DDUCKDB_RSTRTMGR=$(DUCKDB_RSTRTMGR)` and the generated include list,
and finally `OBJECTS=$(GLUE) $(SOURCES)`.
The order is load-bearing:
`OBJECTS` is expanded after every include,
so the fast path's empty `SOURCES` — assigned in `Makevars.system-lib`,
included after `include/sources.mk` — wins.

**The prebuilt object archive.**
`include/from-tar.mk` and `include/to-tar.mk` (`to-tar-win.mk` on
Windows) are the two halves of one cache.
Both hang a `duckdb.tar` target off `all`.
`to-tar.mk` depends on `$(SOURCES)` and tars the freshly built object
files into `$DUCKDB_R_PREBUILT_ARCHIVE`, if that variable is set;
`from-tar.mk` — chosen when the archive existed and unpacked cleanly —
only lists the extracted files for diagnostics.
Both then delete `Makevars.duckdb`,
so the next `configure` run decides afresh.
Locally `ccache` does this job better;
the archive earns its keep in CI, where it is keyed by compiler, OS, and
a hash of the `duckdb/src` subtree.

## Dependency files (`.dd`)

`src/include/deps.mk` pulls in one `.dd` per glue object
(`include $(GLUE:.o=.dd)`), and those files are committed.
They exist so that editing a glue header rebuilds the glue objects that
include it, without dragging the vendored tree into the dependency graph.

The `%.dd: %.d` rule filters what the compiler wrote:
prerequisites are split one per line,
every line pointing at an absolute path, into `duckdb/`, or up the tree
with `../` is deleted,
what remains is normalized to two-space indentation
and sorted under `LOCALE=C` below the target line.
Only local `include/` headers survive.

A `.dd` file should change only when a `.cpp` gains a new `#include` of a
local header.
A build that rewrites them with system paths (`/opt/R/...`) or
`../inst/include/...` entries has produced a spurious change:
revert with `git checkout -- src/*.dd`.
That used to happen because the filter matched `^  ` — exactly two
spaces — while compiler continuation lines carry only one;
the rule now matches `^ +`.

## The tarball

`R CMD build` runs the package's `cleanup` script
(`cleanup.win` on Windows).
It compresses `src/duckdb/` into `src/duckdb.tar.xz` and deletes the
directory, so the vendored engine travels as a single xz archive;
both scripts give the reason in a comment —
keeping the tarball under 5000000 bytes, which is what CRAN accepts.
The policy behind that number is
[`operations/releases/cran/`](/handbook/operations/releases/cran/README.md)'s.

The script is careful in three ways:
it does nothing if `src/duckdb.tar.xz` already exists;
it compresses only when `xz` is on the `PATH`,
so a machine that could not expand the archive never creates one;
and in a git checkout it runs `git clean -fdx src` first,
so untracked build output does not end up inside.
`cleanup.win` additionally runs `dos2unix` over the vendored
`.cc`, `.cpp`, `.h`, and `.hpp` files before archiving.

**Never run `R CMD build` in a working tree you still need.**
`cleanup` runs *in place*, on the tree it is invoked in, not on a copy:
`git clean -fdx src` deletes every untracked and ignored file under
`src/` — the `.o` files, `Makevars.duckdb`, a prebuilt archive, the
generated fragments — and `src/duckdb/` itself is then archived and
removed.
The checkout stays valid, and the next `R CMD INSTALL` unpacks the
archive again, but everything that made a rebuild cheap is gone and that
install starts cold.
A tree in the middle of an edit-build-test loop, or one replaying vendor
commits, is exactly the tree not to build a tarball from:
use a scratch clone or a worktree kept for the purpose.

`configure` reverses this at install time,
and that asymmetry is the thing to remember:
in a git checkout `src/duckdb/` is a directory and `configure` leaves it
alone; in a tarball it is `src/duckdb.tar.xz` and `configure` unpacks it
before make runs.

`.Rbuildignore` decides what else does not travel —
`scripts/`, `patch/`, `.github/`, `plan/`, `handbook/`, `AGENTS.md`,
`BRANCHES.md`, and, from the build system itself,
`src/Makevars.in` and `src/include/deps.mk`.
A tarball therefore carries generated `Makevars` files it has no way to
regenerate, and no dependency rules at all;
both are development-only, and `src/Makevars`'s fallback rule for
`include/deps.mk` is what makes their absence harmless.

## `UserNM`

`UserNM=true R CMD INSTALL . --no-byte-compile` is an install-time
shortcut, and only that.
**Never export it for `R CMD check`.**

R takes the `nm` program from `$UserNM`:
`tools:::read_symbols_from_object_file()` reads that variable first and
falls back to `Sys.which("nm")` only when it is empty.
Two things use that reader.
The `symbols.rds` rule during install — which is where the saving comes
from, since `true` no longer walks every object file.
And `tools:::check_so_symbols()` during `R CMD check`,
which scans the built shared library:
pointed at `true` it reads an empty symbol table,
so the check reports
"Found no calls to `R_registerRoutines`, `R_useDynamicSymbols`"
and fails a package that registers its routines correctly.
The shortcut saves a few seconds on this tree,
so it is not worth carrying into CI at all.

## Boundaries

Which sources are vendored, which extensions are linked in, and what
`src/include/sources.mk` contains are decided when `rconfigure.py`
regenerates them —
[`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md).
Skipping the vendored sources entirely is
[`build/fast-paths/`](/handbook/build/fast-paths/README.md),
and every environment variable named above — what it defaults to and
when to set it — is
[`build/configuration/`](/handbook/build/configuration/README.md).
No plan document covers this build;
the files above are the specification.
