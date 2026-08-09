# Whether the fast path could work on Windows

*What it measures:* whether the prebuilt `libduckdb` DuckDB publishes for
Windows could stand in for the vendored sources the way the Linux and
macOS ones do — what its export table contains, and how much of what the
glue resolves from the engine is in there.

*When and on what:* 2026-08-09, against
`libduckdb-windows-amd64.zip` from the DuckDB v1.5.5 release,
the version vendored under `src/duckdb/` that day.
The symbols the glue needs were taken from a fast-path build of this
repository on Linux x86_64, R 4.5.3, GCC 13.
Method: [`probe.sh`](probe.sh),
which re-derives both numbers from the published artifact.

*What it supports:* the Windows limit stated in
[`build/fast-paths/`](/handbook/build/fast-paths/README.md),
and the refusals in
[`scripts/install-libduckdb.sh`](/scripts/install-libduckdb.sh)
and [`configure.win`](/configure.win) that cite it.

## The artifact exists, and cannot be linked

`libduckdb-windows-amd64.zip` carries `duckdb.dll`, an import library
`duckdb.lib`, and the same `duckdb.h` / `duckdb.hpp` the other platforms
ship, so nothing is missing in the sense of a download that fails.
Of the 3547 names the DLL exports:

* 2996 are C++, mangled the MSVC way — `??$Append@C@BaseAppender@duckdb@@QEAAXC@Z`.
* 547 are the plain C API — `duckdb_open`, `duckdb_query`, and the rest.
* 0 are Itanium-ABI names, the form GCC and Clang emit and consume.

R packages on Windows are built by the Rtools MinGW-w64 GCC toolchain,
which emits Itanium names.
The glue calls DuckDB C++ internals rather than the C API
([`architecture/glue/conventions/`](/handbook/architecture/glue/conventions/README.md)),
so every symbol it needs is one the two compilers spell differently,
and the linker resolves none of them.
The C API is the only common surface, and the glue does not use it.

The same toolchain split — DuckDB shipping MSVC where R's Windows build is
mingw — is what
[`2026-08-05-windows-extension-coverage/`](/experiments/2026-08-05-windows-extension-coverage/README.md)
found for prebuilt extensions.
There it costs a platform its extensions; here it costs the fast path
entirely.

## Even matching toolchains, the exports fall short

A second, independent shortfall, which matters because it would survive
any fix to the first.
An ELF `libduckdb.so` exports everything with default visibility — 28173
`duckdb::` symbols on Linux, covering all 288 the glue resolves from the
engine, which is why the fast path works there at all.
A Windows DLL exports only what is marked for export, and DuckDB marks a
tenth as much.

Matching by name — 214 distinct `duckdb::Class::member` the glue calls,
each looked for under MSVC's mangling of that name, signature ignored, so
the count is generous to the DLL:

* 175 have a name in the export table.
* 39 have none, [listed here](absent-from-windows-dll.txt) — among them
  `duckdb::ArrowUtil::FetchChunk`, `duckdb::ClientConfig::GetConfig`, and
  `duckdb::BaseUUID::ToString`, all of them ordinary members of vendored
  engine classes.

So the published DLL is not a build of the same thing with a different
name scheme; it deliberately exposes a smaller surface than the glue
reaches for.
Closing this would take an upstream change to what the Windows build
exports, whichever compiler built it.

## A mingw build exists, and still does not help

The toolchain half is not hypothetical forever: MSYS2 packages
[`mingw-w64-x86_64-duckdb`](https://packages.msys2.org/packages/mingw-w64-x86_64-duckdb),
built by the same compiler family R's Windows packages are, from the
release tarball with `BUILD_SHARED_LIBS=ON`
([its `PKGBUILD`](https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-duckdb/PKGBUILD)).

It does not close the gap, for a reason no amount of packaging effort
reaches: it carried DuckDB 1.4.4 on 2026-08-09, against the v1.5.5 this
tree vendored that day, and the commit-match guard takes only the exact
commit the vendored sources carry
([`build/fast-paths/`](/handbook/build/fast-paths/README.md)).
A downstream repackaging tracks releases at its own pace, so a match
would be a coincidence — and a series vendoring a `-dev` snapshot
between releases has no published release for it to match at all.
Whether its exports reach further than the MSVC DLL's is therefore
untested here; that question only becomes worth asking if the version
gap closes.
