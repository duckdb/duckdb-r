# Source build

How a source tree becomes an installed shared library:
`configure`, the Makevars assembly, and the tarball round trip.

```sh
export MAKEFLAGS="-j$(nproc)"
R CMD INSTALL . --no-byte-compile
```

The first build compiles the whole vendored engine — tens of minutes;
an agent driving it must not cancel it.
An edit-test loop should not use this build at all:
[`fast-paths/`](/handbook/build/fast-paths/README.md)
turns the same command into seconds.

**Two stages.**
`R CMD INSTALL` runs `./configure` (`configure.win` on Windows),
then `make` in `src/` driven by `src/Makevars`.
`configure` computes no compiler flags;
it writes small include fragments that `src/Makevars` picks up —
`Makevars.rstrtmgr`, then either `Makevars.system-lib` for the fast path
or a `Makevars.duckdb` copied from `src/include/from-tar.mk`
when `DUCKDB_R_PREBUILT_ARCHIVE` names an archive that extracts,
and from `src/include/to-tar.mk` when it does not
(`to-tar-win.mk` on Windows).
It deletes a stale `Makevars.system-lib` first,
so a plain install can never silently stay on the fast path.

**The tarball carries the vendored tree as `src/duckdb.tar`.**
`R CMD build` runs `cleanup` (`cleanup.win` on Windows), which packs `src/duckdb/` into an uncompressed tar and deletes the tree,
and `configure` unpacks it again, which is how a tarball built by `R CMD build` compiles under `R CMD check`.
The archive keeps the vendored paths longer than 100 bytes out of the package's own file list,
where `R CMD check` would note them as non-portable.
The `.tar.gz` that `R CMD build` writes compresses it,
and nothing compresses it twice: an xz-compressed archive needs `xz` on every host that installs from source
([#2939](https://github.com/duckdb/duckdb-r/issues/2939)).

**`cleanup.win` turns line endings to LF before it packs.**
`R CMD build` rewrites the C, C++ and Fortran sources under `src/` to LF itself, but only after `cleanup` has run,
so it no longer sees the files inside the archive,
and `R CMD check` inspects them once `configure` has unpacked them during the install.
`cleanup.win` converts the same file names, `\.([cfh]|cc|cpp|hpp)$`, with `dos2unix` where there is one and `sed` otherwise.

**Only the first build is the whole engine.**
Object files stay in `src/` beside the sources they were compiled from,
so a second `R CMD INSTALL .` in the same tree is `make` deciding
almost everything is current — seconds, and nothing at all recompiles
for a change confined to `R/` or `man/`
([#22](https://github.com/duckdb/duckdb-r/issues/22#issuecomment-1747137315)).
Nothing survives the tarball round trip, though:
`R CMD build` writes a fresh tree and `R CMD check` installs from it,
so a check pays for every object again
unless ccache holds them across the extraction
([`configuration/`](/handbook/build/configuration/README.md))
or the fast path leaves it nothing to compile.

**`.dd` files in `src/` stay in version control, and a build refreshes one only when its source moved.**
`src/include/deps.mk` includes one per glue object and carries a `%.dd: %.d` rule
that normalizes a compiler dependency file — keeping the local prerequisites,
dropping absolute, `duckdb/` and `../` paths, and sorting what is left.
Nothing here produces the `.d` it consumes because nothing has to:
R's own `Makeconf` ships `.cpp.d`, which runs `$(CXX) -M $(ALL_CPPFLAGS)`,
and make builds the `.d` as a chained intermediate and deletes it again within the run.
`-M` rather than `-MM` is why the filter has system paths to drop at all.
`.gitignore` covers `/src/*.d`, that intermediate, and not `*.dd`.

**What gates the rule is an mtime, and a checkout never trips it.**
git writes `connection.cpp` and `connection.dd` in the same pass,
so the `.dd` is never older than its source and make never asks for the `.d`.
The rule fires when someone edits a glue `.cpp` and builds in that same tree,
and then it rewrites that one `.dd` and leaves the tree dirty —
which matters because [`scripts/vendor-one.sh`](/scripts/vendor-one.sh) refuses to start on a dirty tree.

So a change that moves headers without touching a single glue `.cpp` leaves every `.dd` stale,
and nothing says so: a header a `.dd` omits is a header whose edit rebuilds nothing —
make relinks the object it already had, as under the unity build below,
and the install succeeds without the change in it.
Vendoring cpp11 under `src/vendor/` was exactly that change.
Regenerate them by touching the glue sources and building,
and read a large diff as the include graph having moved rather than as noise.

**An edit under `src/duckdb/` does not rebuild itself.**
The engine compiles as a unity build: a file such as
`src/main/db_instance_cache.cpp` is `#include`d into `ub_src_main.cpp`,
and make's prerequisite is the unity file, not the sources it gathers.
`Config/build/never-clean` in `DESCRIPTION` then keeps the objects
across installs.
So editing a vendored source marks nothing out of date — the build
relinks the object it already had, succeeds, and installs a library
without the change in it.
Delete the containing `src/duckdb/ub_*.o` before rebuilding, and confirm
the result rather than the exit status:
`strings` the installed library for something the edit added.
The failure is silent in both directions, which is what makes it
expensive: a fix appears not to work, and a mistake appears not to
break anything.

*To deepen: absorb the Windows differences and the
`configure` step order from the scripts; drain
[#2234](https://github.com/duckdb/duckdb-r/issues/2234)'s
build half.*
