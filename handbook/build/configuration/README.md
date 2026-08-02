# Configuration

The knobs that change how the package builds:
the environment variables `configure` and `src/Makevars` read,
the settings that live in `~/.R/Makevars` rather than in the environment,
and the variables the vendoring script reads when it *generates*
`src/Makevars`.
What the build then does with them is
[`build/source-build/`](/handbook/build/source-build/README.md)'s topic;
the runtime settings that share the `DUCKDB_R_` prefix are not build knobs
and are listed under [Not build knobs](#not-build-knobs) below.

## Build knobs

Read while the package is being built,
so exporting one before `R CMD INSTALL .`
(or before `pkgload::load_all()`, which builds the same way)
is all it takes.

| Knob | What it does | Default | When to set |
|---|---|---|---|
| `MAKEFLAGS` | Passed to `make`; only `-j` matters here. When it is empty, `configure` fills it in from [`scripts/setup-makeflags.R`](/scripts/setup-makeflags.R) and prints what it chose; when it is set, `configure` prints it and leaves it alone. | `-j` with the smaller of `parallel::detectCores()` and 2, so `-j2` on any multicore box; the cap is lifted when `NOT_CRAN` is truthy | To pin parallelism yourself: `export MAKEFLAGS="-j$(nproc)"` |
| `NOT_CRAN` | Lifts the two-core cap that `scripts/setup-makeflags.R` puts on its guess, per CRAN's policy for checks. Matched case-insensitively against `true`, `1`, `yes`; anything else counts as false. | unset, so the cap applies | A local build that should use every core without your naming a `-j` |
| ccache | Not an environment variable — the compilers are wrapped in `~/.R/Makevars`. Turns a repeat build of the vendored tree from minutes into seconds. | off | Any machine that compiles the vendored tree more than once |
| `UserNM` | Names the `nm` program R uses to build `symbols.rds`, which [`src/Makevars.in`](/src/Makevars.in) puts on the `all:` target. `UserNM=true` skips the sweep. | unset, so R takes `nm` from `PATH` | An install-time shortcut only, never for `R CMD check`; it saves about 10–20 s on this tree |
| `DUCKDB_R_PREBUILT_ARCHIVE` | Path to a `.tar` of the vendored object files. If the file exists and extracts, `configure` uses [`src/include/from-tar.mk`](/src/include/from-tar.mk) and nothing is recompiled; otherwise it uses `to-tar.mk` (`to-tar-win.mk` on Windows), which writes the archive once the objects are built. | unset, so objects are built normally and no archive is written | CI. Locally ccache does the same job better, as `configure`'s own comment says |
| `DUCKDB_R_USE_SYSTEM_LIB` | Links a prebuilt libduckdb instead of compiling the vendored sources — see [`build/fast-paths/`](/handbook/build/fast-paths/README.md). | unset | — |
| `DUCKDB_R_LIB_DIR` | Directory holding `libduckdb.so` / `.dylib`. Read only while the system-lib opt-in is active. | `pkg-config --variable=libdir duckdb`, then `/usr/local/lib`, `/opt/homebrew/lib`, `/usr/lib/x86_64-linux-gnu`, `/usr/lib/aarch64-linux-gnu`, `/usr/lib` | libduckdb sits in a prefix none of those cover |
| `PKG_BUILD_EXTRA_FLAGS` | pkgbuild's knob, so it applies to `pkgload::load_all()` and `devtools`, not to `R CMD INSTALL`. When on, pkgbuild merges `-UNDEBUG -Wall -pedantic -g -O0` over your `~/.R/Makevars`. | `true` (`false` and `missing` are the other accepted values) | `false`, to keep the optimisation settings you configured. CI sets it in [`install/action.yml`](/.github/workflows/install/action.yml) |
| `DUCKDB_R_POISON_ENGINE` | Not read by the build itself: [`before-install/action.yml`](/.github/workflows/custom/before-install/action.yml) reacts to it by appending `CPPFLAGS += -DDUCKDB_R_POISON_ENGINE` to `~/.R/Makevars`, which turns `DUCKDB_R_POISON_GUARD()` in [`src/include/rapi.hpp`](/src/include/rapi.hpp) into an unconditional `cpp11::stop()`. | unset | Only through the matrix entry that carries it ([`operations/ci/matrix/`](/handbook/operations/ci/matrix/README.md)); what it proves is [`testing/guards/`](/handbook/testing/guards/README.md)'s |

**ccache.**
Infer each compiler default with `R CMD config` and prepend `ccache`,
rather than writing `CXX = ccache g++` by hand:
the inferred value carries the flags R selects for that version,
and the versioned `CXX11`…`CXX23` switches deliberately come out bare
because R applies the standard separately through `CXXnnSTD`.
[`install/action.yml`](/.github/workflows/install/action.yml) does exactly
that, and also sets `CCACHE_SLOPPINESS=locale,time_macros`;
[`each.yaml`](/.github/workflows/each.yaml) additionally moves `CCACHE_DIR`
outside the workspace and raises `max_size`, because the shard it runs
wipes the workspace between commits.

**`UserNM`.**
`UserNM=true` is a development shortcut and nothing more.
The same R function serves the install-time `symbols.rds` target *and*
the symbol scan `R CMD check` runs on the built shared object,
so exporting it silently weakens a check —
see [`build/source-build/`](/handbook/build/source-build/README.md)
for what goes wrong.

**`DUCKDB_R_PREBUILT_ARCHIVE`.**
Only the presence of a readable file switches the build to reuse;
setting the variable to a path that does not exist yet is how you ask for
the archive to be *written*.
CI keys the cached archive on the R version, the runner OS, the compiler
version, and a hash of `src/duckdb/`, in
[`after-install/action.yml`](/.github/workflows/custom/after-install/action.yml).
On Windows the reuse branch additionally requires R >= 4.2,
because earlier versions build multiarch.

## Vendoring-time knobs

[`scripts/rconfigure.py`](/scripts/rconfigure.py) generates `src/Makevars`
and `src/include/sources.mk` from `src/Makevars.in` during a vendoring run,
and the results are committed.
Setting one of these at install time therefore does nothing —
they only take effect through a vendoring run
([`operations/vendoring/pipeline/`](/handbook/operations/vendoring/pipeline/README.md)).

| Knob | What it does | Default | When to set |
|---|---|---|---|
| `DUCKDB_R_EXTENSIONS` | Comma-separated extension names appended to the built-in list. Each one contributes `-DDUCKDB_EXTENSION_<NAME>_LINKED`, its include flags, and its sources. Merely defining the variable triggers the append, so an empty value appends an empty name. | `parquet`, `core_functions` — the two statically linked in every build ([`usage/extensions/`](/handbook/usage/extensions/README.md)) | Re-vendoring with a further in-tree extension linked in |
| `DUCKDB_DEBUG_MOVE` | Adds `-DDUCKDB_DEBUG_MOVE` to the generated `PKG_CPPFLAGS`. Triggered by the variable being defined, whatever its value. | unset | Chasing a use-after-move in the engine |
| `DUCKDB_R_LINENR` | Passed on to upstream's `package_build.build_package()` as its `linenr` argument. Any non-empty value is true, including `0` and `false`. | unset, i.e. false | Rarely — what it produces is decided by `package_build.py`, which lives in the DuckDB checkout and not here, so it is not verifiable from this repository |
| `DUCKDB_PATH` | Where the DuckDB checkout is. | `../duckdb` | Set for you by the vendoring scripts |
| `DUCKDB_BUILD_UNITY` | Intended to set the unity-build chunk size — but see below: it does nothing. | 20, always | Never |

`DUCKDB_BUILD_UNITY` is inert.
`rconfigure.py` checks that the variable is defined and then converts a bare
Python name rather than the environment entry,
which raises `NameError` into a bare `except`,
so the default of 20 always survives.
It is listed as it behaves, not as it reads;
making it work is a code change, not a documentation one.

`DUCKDB_R_BINDIR`, `DUCKDB_R_CFLAGS` and `DUCKDB_R_LIBS` are a fourth
vendoring-time knob, taking effect only when all three are set together:
`rconfigure.py` then writes a `src/Makevars` with no sources and link flags
derived from an existing DuckDB installation, and exits before it touches
`src/duckdb/`.
Nothing in this repository sets them, and no CI job exercises the path;
the maintained way to link against a prebuilt engine is
[`build/fast-paths/`](/handbook/build/fast-paths/README.md).

## Not build knobs

Several variables share the `DUCKDB_R_` prefix without touching the build,
and are documented where they act:

* `DUCKDB_R_HOME` and `DUCKDB_R_TEMP_DIRECTORY` —
  [`usage/storage/`](/handbook/usage/storage/README.md)
* `DUCKDB_R_ALLOW_EXTENSIONS` —
  [`usage/extensions/`](/handbook/usage/extensions/README.md)
* `DUCKDB_R_RUN_TESTS` —
  [`testing/suite/`](/handbook/testing/suite/README.md).
  `NOT_CRAN` has a second life there and in `R/s3_register.R`;
  only its effect on `-j` is a build knob
* `DUCKDB_R_LIB_VERSION` and `DUCKDB_R_LIB_URL`, which steer
  `scripts/install-libduckdb.sh` rather than the build —
  [`build/fast-paths/`](/handbook/build/fast-paths/README.md)

Three more are outputs rather than inputs, and setting them by hand achieves
nothing: `DUCKDB_RSTRTMGR`, which `configure` writes into
`src/Makevars.rstrtmgr`, and `DUCKDB_R_PREBUILT_ARCHIVE_GHA_CACHE_KEY` and
`DUCKDB_R_UNRELEASED`, which the CI actions compute for themselves.

There is no knob for the C++ standard, the optimisation level, or the
warning set: `src/Makevars.in` pins `CXX_STD = CXX17` and leaves the rest to
R's own `Makeconf`, which is what a user Makevars overrides.
Nor is there one for suppressing compiler warnings — that is a policy, not a
setting, and it belongs to
[`architecture/glue/`](/handbook/architecture/glue/README.md).
