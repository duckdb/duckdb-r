# Windows extension coverage, and which class crosses the toolchain

*What it measures:* which prebuilt-extension artifacts DuckDB's
repositories serve the platforms R's Windows toolchains ask for,
and whether the `windows_arm64` (MSVC) artifact that *does* exist
can be hand-loaded into R's mingw build —
that is, whether
[#2425](https://github.com/duckdb/duckdb-r/issues/2425)
has a user-side escape.

*When and on what:* repository probes 2026-08-05,
HTTP HEAD against `extensions.duckdb.org` ([`probe.sh`](probe.sh));
install and load runs 2026-08-04 and 2026-08-05
on `windows-11-arm` GitHub runners —
R release, DuckDB 1.5.5, package built from source —
each question asked of two builds:
as built (`windows_arm64_mingw`)
and pinned to the MSVC platform name
(`-DDUCKDB_CUSTOM_PLATFORM=windows_arm64`).
Method and logs:
[krlmlr/duckdb-r#114](https://github.com/krlmlr/duckdb-r/pull/114)
(`INSTALL icu`; runs 30927023956 and 30930493513) and
[krlmlr/duckdb-r#116](https://github.com/krlmlr/duckdb-r/pull/116)
(`INSTALL odbc_scanner FROM community`, run 30931665169;
the manual fetch-and-load of `icu`, run 30967881866;
the same for `odbc_scanner`, run 30987274175).

*What it supports:* the Windows and platform-coverage bullets in
[`usage/extensions/`](/handbook/usage/extensions/README.md).

## What the core repository serves

`extensions.duckdb.org/<version>/<platform>/<name>.duckdb_extension.gz`,
HTTP status for `icu`:

| | `windows_amd64_mingw` | `windows_arm64_mingw` | `windows_arm64` |
|---|---|---|---|
| v1.4.1 | 200 | 404 | 404 |
| v1.4.3 | 200 | 404 | 200 |
| v1.5.5 | 200 | 404 | 200 |

The arm64 story: DuckDB covers the architecture (since 1.4.3),
but only as the MSVC build —
`windows_arm64_mingw` is not in the upstream distribution matrix at all,
was considered and shelved with no timeline
([duckdb/duckdb#21727](https://github.com/duckdb/duckdb/pull/21727),
confirmed in
[#2425](https://github.com/duckdb/duckdb-r/issues/2425#issuecomment-5181680038)).

And within `windows_amd64_mingw`, coverage is per extension
(v1.5.5, same probe):

```
postgres_scanner   404
spatial            200
excel              200
icu                200
httpfs             200
```

`postgres_scanner` exists as `windows_amd64` (MSVC, 200) —
the toolchain flavor, not the architecture, is what is missing,
exactly as on arm64.

## What the community repository serves

`INSTALL odbc_scanner FROM community`, from R, on both builds
(run 30931665169): HTTP 404 under `windows_arm64_mingw`
*and* under `windows_arm64`.
The community repository publishes no arm64 Windows build of
`odbc_scanner` under either name,
so the C-API extension class —
the one whose version check is "equal or higher"
and which resolves no host symbols —
cannot rescue the platform for lack of artifacts.

## Whether the MSVC artifact loads by hand: the C++-ABI class

The obstacle course, in order:

1. `INSTALL icu` on the pinned build fetches the `windows_arm64` file,
   and its `LOAD` dies with an access violation —
   the job ends with no R error to read
   (#114, run 30930493513).
2. On the as-built flavor the same file is refused by metadata first:
   *"The file was built for the platform 'windows_arm64', but we can
   only load extensions built for platform 'windows_arm64_mingw'."*
3. `SET allow_extensions_metadata_mismatch = true` does not lift the
   refusal: in `ExtensionHelper::LoadExtensionInternal`
   (`src/duckdb/src/main/extension/extension_load.cpp`)
   that setting is consulted only when `allow_unsigned_extensions`
   is also on, and the engine refuses to *enable* that one once the
   database is running
   (`AllowUnsignedExtensionsSetting::OnSet`,
   `src/duckdb/src/main/settings/custom_settings.cpp`) —
   `SET` can never reach the branch.
4. Both hatches do open together as driver config,
   which is applied at startup:
   `duckdb(config = list(allow_unsigned_extensions = "true",
   allow_extensions_metadata_mismatch = "true"))`.
   The load then reaches the binary itself.

The final leg (run 30967881866) fetches the `windows_arm64` file by
hand (10,575,466 bytes, 32,176,662 unpacked), gunzips it,
and `LOAD`s it by path in a subprocess,
hatches open, on both builds — subprocess, because step 1 predicts the
answer is an exit code, not an error message:

On both builds the subprocess prints its platform, reaches `LOAD`,
and dies there — exit status 5, no R error for `try()` to catch,
nothing after the `LOAD` line runs.
On the pinned build the file's metadata *matches* the host's platform
string, so no hatch even stood between `LOAD` and the binary:
same death.
This is the failure that took the whole job as an access violation
(0xC0000005) when the same file arrived via `INSTALL`
(#114, run 30930493513); the subprocess turns it into a printed
status.

## Whether the MSVC artifact loads by hand: the C-API class

`odbc_scanner` is built against the C API
(`ExtensionABIType::C_STRUCT`,
`src/duckdb/src/include/duckdb/main/extension.hpp`):
the host passes the API in as a function-pointer struct,
the extension imports nothing from the host's export table,
and its version check is "equal or higher" rather than exact.
The core repository begins serving it at v1.5.5,
MSVC platforms only
(probed 2026-08-05: `windows_arm64` 200, `windows_amd64` 200,
both `*_mingw` names 404, and 404 across the board at v1.4.3).

Run 30987274175 repeats the fetch-and-load with
`windows_arm64/odbc_scanner.duckdb_extension.gz`
(242,866 bytes, 579,606 unpacked), same hatches, same subprocess:

On both builds the load succeeds and the extension registers —
`LOAD` returns, `duckdb_extensions()` reports `loaded = TRUE`
(extension_version 274a330734),
and `duckdb_functions()` counts 11 `odbc` functions,
so registration ran through the C API into the catalog.
Subprocess exit status 0, both legs.
Both hatches are needed on the as-built leg even though the file is
signed: the metadata error throws from the signed branch,
so only `allow_unsigned_extensions` opens the path to the mismatch
setting.
An actual ODBC round-trip is beyond the runner (no DSN);
what is proven is load, catalog entry, and function registration.

**What it shows.**
Coverage gaps are toolchain-flavor gaps, not architecture gaps,
on x86_64 and arm64 alike,
and the community repository does not fill them.
Across the toolchain boundary the extension class decides:
a C++-ABI artifact binds host symbols and kills the process,
a C-API artifact takes the API as a struct and loads.
So [#2425](https://github.com/duckdb/duckdb-r/issues/2425) has a
narrow, documentable escape —
hand-load an MSVC C-API extension by path, hatches open —
that widens exactly as fast as upstream moves extensions to the
C API, while `INSTALL` stays a 404 until the repository grows the
platform directory.
