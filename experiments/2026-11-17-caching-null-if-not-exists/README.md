# The external file cache and `FILE_FLAGS_NULL_IF_NOT_EXISTS`

*What it measures:* whether the engine's `FileSystem::OpenFile()` returns the null handle that `FILE_FLAGS_NULL_IF_NOT_EXISTS` promises
for a file that does not exist, when the flags also ask for the external file cache through a caching mode.
Each run opens a missing local file, a missing `http://` path and a missing `s3://` path,
under `NO_CACHING`, `CACHE_REMOTE_ONLY` and, for the local file, `ALWAYS_CACHE`.

*When and on what:* 2026-11-17, Linux x86_64 with 4 cores, Ubuntu 24.04, g++ through ccache, Python 3 with moto 5.2.5,
which [`run.sh`](run.sh) pins.
Two engines, each named by the version and source_id it reports at run time:

* v2.0.0, source_id `d54cbbe3df`: upstream's prebuilt `libduckdb` of that release,
  installed by [`scripts/install-libduckdb.sh`](/scripts/install-libduckdb.sh) from `main` at 73ead8b,
  and compiled against the headers vendored there.
  httpfs `77392a7207`, which is what `INSTALL httpfs` fetched for v2.0.0 that day;
  the script does not pin it, so a rerun gets whatever upstream serves for v2.0.0 then.
* v2.1.0-dev92210, source_id `09456f1ce0`: the engine vendored on `main-green` at 8edee523,
  compiled into a shared library by [`engine.mk`](engine.mk) with the flags the package's `src/Makevars` passes it,
  at `-O1 -DNDEBUG`.
  No prebuilt exists for a `-dev` build, and no httpfs either.

*What it supports:* the engine bug met while working on [#2977](https://github.com/duckdb/duckdb-r/issues/2977),
where a change to `DirectFileReader::Scan` opened a missing `s3://` path with these flags and `CACHE_REMOTE_ONLY`.
No handbook leaf leans on it yet; it is the reproducer an upstream report or a patch under [`patch/`](/patch/) would cite.

## Method

[`repro.cpp`](repro.cpp) opens one database in memory, runs the SQL statements it is given (`LOAD httpfs`, an S3 secret),
and calls `FileSystem::GetFileSystem(*con.context).OpenFile(path, flags)` inside a transaction, with
`FILE_FLAGS_READ | FILE_FLAGS_DIRECT_IO | FILE_FLAGS_NULL_IF_NOT_EXISTS` and the caching mode it is given.
It prints whether the call returned a null handle, a handle, or threw, and the first line of what it threw.
Neither SQL nor the C API sets a caching mode together with `FILE_FLAGS_NULL_IF_NOT_EXISTS`, so the program uses the C++ API.

[`run.sh`](run.sh) checks out both commits as detached worktrees, installs or compiles both engines, compiles the program against each,
starts `python3 -m http.server` and a moto S3 server with an empty bucket, and runs every variant on both engines.
`NO_CACHING` is the control.

## Findings

Every variant, with its verdict per engine:

* **Missing local file, `ALWAYS_CACHE`:** throws on both engines.
* **Missing `http://` and `s3://` path, `CACHE_REMOTE_ONLY`, httpfs loaded:** throws on v2.0; not run on v2.1, which has no httpfs.
* **Missing local file, `CACHE_REMOTE_ONLY`:** null handle on both, because the wrapper sends a local path past the cache.
* **The control, `NO_CACHING`:** null handle for every path on both engines that could open it.

Verdicts:

* **v2.0.0 (`d54cbbe3df`): reproduces**, locally and against both servers.
* **v2.1.0-dev92210 (`09456f1ce0`): reproduces** with the local file; the remote variants were not run.

The local file under `ALWAYS_CACHE` is the minimal reproducer: it needs no server and no extension.
On both engines the call fails inside `OpenFile()` itself, not on first use.

From the run on v2.0, `<work>` standing for the scratch directory;
[`transcript.txt`](transcript.txt) is the whole run, both engines and every variant:

```
--- v2.0, local, none
engine: v2.0.0 d54cbbe3df
open: <work>/www/missing.bin, caching mode none
OpenFile returned: null handle
exit status: 0
--- v2.0, local, always
engine: v2.0.0 d54cbbe3df
open: <work>/www/missing.bin, caching mode always
OpenFile threw: INTERNAL Error: Attempted to dereference shared_ptr that is NULL!
exit status: 1
--- v2.0, local, remote
engine: v2.0.0 d54cbbe3df
open: <work>/www/missing.bin, caching mode remote
OpenFile returned: null handle
exit status: 0
--- v2.0, http, none
engine: v2.0.0 d54cbbe3df
loaded: httpfs 77392a7207
open: http://127.0.0.1:8765/missing.bin, caching mode none
OpenFile returned: null handle
exit status: 0
--- v2.0, s3, none
engine: v2.0.0 d54cbbe3df
loaded: httpfs 77392a7207
open: s3://bucket/missing.bin, caching mode none
OpenFile returned: null handle
exit status: 0
--- v2.0, http, remote
engine: v2.0.0 d54cbbe3df
loaded: httpfs 77392a7207
open: http://127.0.0.1:8765/missing.bin, caching mode remote
OpenFile threw: INTERNAL Error: Attempted to dereference shared_ptr that is NULL!
exit status: 1
--- v2.0, s3, remote
engine: v2.0.0 d54cbbe3df
loaded: httpfs 77392a7207
open: s3://bucket/missing.bin, caching mode remote
OpenFile threw: INTERNAL Error: Attempted to dereference shared_ptr that is NULL!
exit status: 1
```

From the run on v2.1, the remote variants cut to their first one, since all four stop at `INSTALL httpfs` the same way:

```
--- v2.1, local, none
engine: v2.1.0-dev92210 09456f1ce0
open: <work>/www/missing.bin, caching mode none
OpenFile returned: null handle
exit status: 0
--- v2.1, local, always
engine: v2.1.0-dev92210 09456f1ce0
open: <work>/www/missing.bin, caching mode always
OpenFile threw: INTERNAL Error: Attempted to dereference shared_ptr that is NULL!
exit status: 1
--- v2.1, local, remote
engine: v2.1.0-dev92210 09456f1ce0
open: <work>/www/missing.bin, caching mode remote
OpenFile returned: null handle
exit status: 0
--- v2.1, http, none
engine: v2.1.0-dev92210 09456f1ce0
setup failed: INSTALL httpfs: HTTP Error: Failed to download extension "httpfs" at URL "http://extensions.duckdb.org/09456f1ce0/linux_amd64/httpfs.duckdb_extension.gz" (HTTP 404)
```

Both servers logged a `HEAD /…/missing.bin` answered with 404, so the remote variants did reach them.

## Where the null comes from

The engine appends a stack trace to the internal error, which `repro.cpp` prints whole when `REPRO_TRACE` is set.
[`trace.txt`](trace.txt) keeps each frame's function for the local file under `ALWAYS_CACHE`, on both engines.
Both run, innermost first, through `ThrowNullSharedPtrDereference`, `CachingFileHandle::GetFileHandle`,
the `CachingFileHandle` constructor, `CachingFileSystemWrapper::OpenFileExtended` and `VirtualFileSystem::OpenFileExtended`.
Line numbers are v2.0's, with v2.1's in parentheses, under `src/duckdb/src/`:

* `common/virtual_file_system.cpp` L192 (L233):
  any caching mode other than `NO_CACHING` routes the open through a `CachingFileSystemWrapper`.
  The check for a null handle, L200 (L241), comes after the wrapper has returned,
  so it only helps when the wrapper can return null.
* `storage/external_file_cache/caching_file_system_wrapper.cpp` L140 to L142 (unchanged): when `ShouldUseCache(path)` holds,
  which is always under `ALWAYS_CACHE` and for a remote path under `CACHE_REMOTE_ONLY`,
  it wraps `caching_file_system.OpenFile(path, flags, opener)` in a `CachingFileHandleWrapper` unconditionally;
  nothing on that branch can return null.
* `storage/external_file_cache/caching_file_system.cpp`, the `CachingFileHandle` constructor at L285 (L307):
  it calls `GetFileHandle()` at once when the cache is disabled,
  when validation is on (`validate_external_file_cache` defaults to `VALIDATE_ALL`),
  or, L299 to L307 (L321 to L329), when the path has no cached blocks.
  A missing file never has cached blocks, so with validation off it still fails inside `OpenFile()`.
  Only a path whose blocks are already cached defers the call until a read or a metadata query needs the file,
  which this record does not run.
* `CachingFileHandle::GetFileHandle()`, L327 (L349):
  `file_system.OpenFile(path, flags | FILE_FLAGS_PARALLEL_ACCESS, opener)` honours the flag,
  and the local file system or httpfs returns null for the missing file.
  L329 (L351) then calls `GetValidationInfo(file_system, *file_handle)`,
  and dereferencing the null `shared_ptr` throws the internal error.

What v2.1 changes against v2.0 in `storage/external_file_cache/` and `common/virtual_file_system.cpp`:

* `common/virtual_file_system.cpp`: how a compression is found from a file's name;
  `VirtualFileSystem::OpenFileExtended()` now tells that lookup whether the file is opened for writing,
  at L248 to L252, after the check for a null handle.
* `caching_file_system.cpp`: how uncached read buffers are allocated,
  and new queries on `CachingFileHandle` for cached blocks and cached ranges.
* `external_file_cache.cpp`: a cached file's memory, which reserves block metadata as blocks are added and dropped
  instead of estimating it for the whole file,
  which small blocks a read may absorb into a larger one, now also larger ones within given ranges,
  and whether a range is available in memory or in a temporary file.

None of it touches `CachingFileSystemWrapper::OpenFileExtended()`, the `CachingFileHandle` constructor or `GetFileHandle()`,
and the local run on v2.1 fails the same way.

## Replicating

From a clone of this repository, `experiments/2026-11-17-caching-null-if-not-exists/run.sh [WORK]`,
which prints what `transcript.txt` holds, with the scratch directory spelled out where the transcript writes `<work>`.
`trace.txt` comes from `REPRO_TRACE=1 <work>/repro-<version> <work>/www/missing.bin always`, cut to each frame's function.
It adds two detached worktrees, one per engine commit, to the clone;
remove them with `git worktree remove` when done.
The v2.1 engine takes about eight minutes on 4 cores with a cold ccache.
The script needs network access to GitHub, PyPI and extensions.duckdb.org, and ports 8765 and 5555 free.
It relies on 8edee523 still being reachable from `main-green`.
