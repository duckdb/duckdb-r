<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# duckdb 1.5.4.9013

## Continuous integration

- Run on Ubuntu 26.04.

- Align workflows with template.


# duckdb 1.5.4.9012

## Bug fixes

- Silence storage message for GeoTox's transitive use (temporary) (#2397).

- Silence storage message for GeoTox's transitive use (temporary) (#2397).

## Features

- Stop announcing storage location after an explicit choice (#2398).

## Chore

- Results for revdepchecks, second run.

- Results for revdepchecks.

## Documentation

- Branching strategy: release-process state machine + series invariants (#2367).

- Document database-instance caching and driver reuse (#2399).

- Only show 60 messages in non-interactive mode, works for GeoTox.

## Testing

- Bump DBItest.


# duckdb 1.5.4.9011

## Features

- Resolve extension/secret storage under `~/.duckdb` or `tempdir()` (#2396).

## Chore

- Results for revdepchecks.

## Continuous integration

- Align Windows builds.

- Align vendoring scripts.

## vendor

- Update vendored sources (tag v1.5.5) to duckdb/duckdb@d8cdaa33fda8df955cc76ef58a280f68f4cd43fa.

  Date: 2026-07-21 13:03:22 +0200

  Bump httpfs (https://redirect.github.com/duckdb/duckdb/pull/24003)

- Update vendored sources to duckdb/duckdb@0b9ca135652107c7dccfe398662267b449097c61.

  Date: 2026-07-21 10:33:44 +0200

  Add missing statement types to capi (https://redirect.github.com/duckdb/duckdb/pull/23407)
  Bump lance pin to upstream ethnum fix, drop local patch (https://redirect.github.com/duckdb/duckdb/pull/23969)

- Update vendored sources to duckdb/duckdb@96e5ae96d283e1cba4c551a2d61877ec1aa18121.

  Date: 2026-07-21 09:15:35 +0200

  Fix OSX ci (https://redirect.github.com/duckdb/duckdb/pull/23963)
  Bump DuckLake (https://redirect.github.com/duckdb/duckdb/pull/23962)

- Update vendored sources to duckdb/duckdb@1d8a8ea65f52c66476dfb5850b7083dd87647d1f.

  Date: 2026-07-20 13:43:10 +0200

  Expose destructors, so they are callable module boundaries (https://redirect.github.com/duckdb/duckdb/pull/23953)
  Bump extensions for v1.5.5: quack, httpfs and aws (https://redirect.github.com/duckdb/duckdb/pull/23892)

- Update vendored sources to duckdb/duckdb@4a11fb2555db746a6bfbc9bafc1018d7638369fa.

  Date: 2026-07-20 10:15:28 +0200

  \[v1.5 backport\] Fix: reset empty_range in the TIMESTAMP range() table function (https://redirect.github.com/duckdb/duckdb/pull/23879)
  Bump Postgres extension for 1.5 (https://redirect.github.com/duckdb/duckdb/pull/23930)

- Update vendored sources to duckdb/duckdb@e14c3db18700c8f730a3421f6b96a8655d7662c4.

  Date: 2026-07-17 18:28:49 +0200

  Fix concurrent ALTER and INSERT crash (https://redirect.github.com/duckdb/duckdb/pull/23861)

- Update vendored sources to duckdb/duckdb@d8e8cd9aea5a98f4b4766a8e9d6c48bd4741935a.

  Date: 2026-07-17 09:41:10 +0200

  TryLookupEntry now uses default schema as fallback (https://redirect.github.com/duckdb/duckdb/pull/23790)

- Update vendored sources to duckdb/duckdb@1b68da1dc15069f4b5ed9766b55170bc923830cd.

  Date: 2026-07-16 16:01:17 +0200

  \[DependencyManager\] Fix ALTER dependency preservation (https://redirect.github.com/duckdb/duckdb/pull/23808)

- Update vendored sources to duckdb/duckdb@65cc13cdeeebe53781dcc8dad15a0ac764ad25a8.

  Date: 2026-07-16 10:56:27 +0200

  \[v1.5\] Backport two more fixes (https://redirect.github.com/duckdb/duckdb/pull/23841)

- Update vendored sources to duckdb/duckdb@6daa70e0e87a5f3f20e58a37d447d2b7fec3abe7.

  Date: 2026-07-15 11:12:58 +0200

  backport https://redirect.github.com/duckdb/duckdb/pull/22198 (https://redirect.github.com/duckdb/duckdb/pull/23810)
  \[variegata\] Bump quack to 8e715ebb (https://redirect.github.com/duckdb/duckdb/pull/23820)

- Update vendored sources to duckdb/duckdb@7adf7a70bb9a8755d1c3f86aaf52430ff66227b2.

  Date: 2026-07-15 10:49:49 +0200

  Fix swapped min/max for multi-row-group 128-bit DECIMAL in RETURN_STATS (https://redirect.github.com/duckdb/duckdb/pull/23693)

- Update vendored sources to duckdb/duckdb@76d5b0bda1be609960e19ac5db46acd7248c2faa.

  Date: 2026-07-15 10:49:31 +0200

  bound alp/alprd exception positions to vector size (https://redirect.github.com/duckdb/duckdb/pull/23778)

- Update vendored sources to duckdb/duckdb@925680abaace84aca8ed9f5cf51f5ac969e8f153.

  Date: 2026-07-15 10:37:02 +0200

  \[v1.5\] Backport a few fix PRs for v1.5.5 release (https://redirect.github.com/duckdb/duckdb/pull/23804)

- Update vendored sources to duckdb/duckdb@61d4d2f92af6ae2ca606f28b1540f1156af49fdb.

  Date: 2026-07-14 20:34:53 +0200

  Fix for malformed JSON when rendering via duckbox (https://redirect.github.com/duckdb/duckdb/pull/23803)
  bump iceberg (https://redirect.github.com/duckdb/duckdb/pull/23735)

- Update vendored sources to duckdb/duckdb@1a0b2bd02fab6e0af46e9bd4939fd3ce4e0cee97.

  Date: 2026-07-14 18:50:41 +0200

  Bump extensions in preparation for v1.5.5 (https://redirect.github.com/duckdb/duckdb/pull/23794)
  Bump azure, unity_catalog extensions to v1.5-variegata HEAD (https://redirect.github.com/duckdb/duckdb/pull/23800)

- Update vendored sources to duckdb/duckdb@983f81bd2dbf3e3eebbaf4b7e2fb04ab1bb058aa.

  Date: 2026-07-14 12:44:23 +0200

  Add HTTPUtil::ShouldRetry(request, response) retry-classification hook (https://redirect.github.com/duckdb/duckdb/pull/23793)

- Update vendored sources to duckdb/duckdb@d6d9cdaacaaa2ee7d0bca3e2faf0899b367b89ca.

  Date: 2026-07-14 10:56:00 +0200

  Fix segfault in external hash aggregate when radix bits grow after going external (https://redirect.github.com/duckdb/duckdb/pull/23757)

- Update vendored sources to duckdb/duckdb@f2677bfbf76214821f72538c65a8472355e89c98.

  Date: 2026-07-14 00:26:19 -0700

  Bump Postgres, MySQL and SQLite in 1.5 (https://redirect.github.com/duckdb/duckdb/pull/23780)
  Fix lance build on Rust 1.97: patch its Cargo.lock to ethnum 1.5.3 (https://redirect.github.com/duckdb/duckdb/pull/23770)

- Update vendored sources to duckdb/duckdb@1bc78bf4686dae282adebcd75f2a0c28e2e7e85b.

  Date: 2026-07-13 03:20:58 -0700

  Correctly promote `SUGGEST_NEW` to `REQUIRE_NEW` for variant / geometry columns (https://redirect.github.com/duckdb/duckdb/pull/23763)
  Include extension header in libduckdb archives (https://redirect.github.com/duckdb/duckdb/pull/23752)

- Update vendored sources to duckdb/duckdb@f13d14e616a7d88d66a01f0588bae66b55af9add.

  Date: 2026-07-09 15:20:59 -0700

  Fix DROP COLUMN corrupting per-column metadata block bookkeeping (https://redirect.github.com/duckdb/duckdb/pull/23714)

- Update vendored sources to duckdb/duckdb@ce4ba75ed83af354465ce46a4ffe0a78670f3d74.

  Date: 2026-07-09 14:06:05 +0200

  Issue https://redirect.github.com/duckdb/duckdb/pull/23664: RANGE ZERO (https://redirect.github.com/duckdb/duckdb/pull/23710)

- Update vendored sources to duckdb/duckdb@b8cd3225ee801cb835e8d8578cc89153816e9888.

  Date: 2026-07-08 15:47:38 +0200

  fix(adbc): support the ADBC Statistics API (https://redirect.github.com/duckdb/duckdb/pull/23230)

- Update vendored sources to duckdb/duckdb@42040d6df4aa410f7fa05e77e1d0ac45e53fa675.

  Date: 2026-07-08 11:21:49 +0200

  backport https://redirect.github.com/duckdb/duckdb/pull/23573 (https://redirect.github.com/duckdb/duckdb/pull/23672)

- Update vendored sources to duckdb/duckdb@b155d6f63cea14e0dfacb1cb795d5266024303e6.

  Date: 2026-07-07 16:11:56 +0200

  Bump HTTPFS (https://redirect.github.com/duckdb/duckdb/pull/23648)

- Update vendored sources to duckdb/duckdb@bd77d596392f567d1d8cc18d45874c78b145d3d3.

  Date: 2026-07-07 11:27:33 +0200

  Fixed unsafe iteration when parent is `NULL` in string cast (https://redirect.github.com/duckdb/duckdb/pull/23593)

- Update vendored sources to duckdb/duckdb@4af19ec15497a6c7ac86ca5c04ef3796a0596fe7.

  Date: 2026-07-07 10:34:36 +0200

  Issue https://redirect.github.com/duckdb/duckdb/pull/23641: CUME_DIST Underflow (https://redirect.github.com/duckdb/duckdb/pull/23651)

- Update vendored sources to duckdb/duckdb@b7eba810936b3aac911928ab14d3e3a267e56854.

  Date: 2026-07-06 12:53:34 +0200

  backport https://redirect.github.com/duckdb/duckdb/pull/23548 to v1.5 (https://redirect.github.com/duckdb/duckdb/pull/23587)

- Update vendored sources to duckdb/duckdb@ffbe20ddf05a745d95c6bb2ff4432656ac80bd11.

  Date: 2026-07-06 12:35:54 +0200

  Bump version map to include v1.5.5 (https://redirect.github.com/duckdb/duckdb/pull/23629)

- Update vendored sources to duckdb/duckdb@2707468686ef077eed7d3e04a4d01752d4ed3403.

  Date: 2026-07-03 13:34:50 +0200

  \[v1.5\] Quickfix `ALTER TABLE ADD COLUMN IF NOT EXISTS ... DEFAULT` regression (https://redirect.github.com/duckdb/duckdb/pull/23507)

- Update vendored sources to duckdb/duckdb@599574338bfac54f5a8f993e710fd6eaf53270a0.

  Date: 2026-07-03 10:22:12 +0200

  fix out-of-bounds read on empty byte array decimals (https://redirect.github.com/duckdb/duckdb/pull/23567)

- Update vendored sources to duckdb/duckdb@9a8e50ddeeb66c543db4d5312ab80bccf280f887.

  Date: 2026-07-03 10:21:56 +0200

  Fix filter combiner not pruning unsatisfiable bounds (https://redirect.github.com/duckdb/duckdb/pull/23563)

- Update vendored sources to duckdb/duckdb@c23ca53615cdee0eee8c1a2a1622077116df04de.

  Date: 2026-07-03 10:21:41 +0200

  \[variegata\] Bump extensions (https://redirect.github.com/duckdb/duckdb/pull/23562)

- Update vendored sources to duckdb/duckdb@97f93aba21cc2fa3883da6e74e551a59ba64f020.

  Date: 2026-07-03 08:54:46 +0200

  Fix/capi scalar bind subquery crash (https://redirect.github.com/duckdb/duckdb/pull/23566)

- Update vendored sources to duckdb/duckdb@4e7493b0a76bcfb72b07e407ad86077fdded0e89.

  Date: 2026-07-02 10:09:51 +0200

  \[ADBC\] Add support for duckdb:// URI scheme in URI option (https://redirect.github.com/duckdb/duckdb/pull/21293)
  Merge v1.4 into v1.5 (https://redirect.github.com/duckdb/duckdb/pull/23560)

- Update vendored sources to duckdb/duckdb@60bc9708b5aaaf404131b4f0f70d68db2d8f7dd0.

  Date: 2026-07-02 08:07:23 +0200

  fix out-of-bounds read in dictionary string decompression (https://redirect.github.com/duckdb/duckdb/pull/23549)
  Issue https://redirect.github.com/duckdb/duckdb/pull/23500: JSON TIMESTAMP_TZ Formatting (https://redirect.github.com/duckdb/duckdb/pull/23513)

- Update vendored sources to duckdb/duckdb@8c893b6a8ad80d19eb6c50ce11d875c89b01e78b.

  Date: 2026-07-01 14:27:47 +0200

  Fix arrow type extension bugs (https://redirect.github.com/duckdb/duckdb/pull/23534)

- Update vendored sources to duckdb/duckdb@39391b92ca9ef97e56d20311c93fbe6fc5b16f88.

  Date: 2026-07-01 13:57:29 +0200

  Backport https://redirect.github.com/duckdb/duckdb/pull/23468 and https://redirect.github.com/duckdb/duckdb/pull/23510 (https://redirect.github.com/duckdb/duckdb/pull/23529)

- Update vendored sources to duckdb/duckdb@da9f597c751364e7da87aa3852a5fa60643a0264.

  Date: 2026-06-30 14:03:31 +0200

  \[v1.5\] Fix min/max aggregate stats when row groups filtered (https://redirect.github.com/duckdb/duckdb/pull/23517)

- Update vendored sources to duckdb/duckdb@87ba47bbcd90895469e96d74e6e0e2abf84c9174.

  Date: 2026-06-29 10:42:57 +0200

  \[v1.5\] Backport PR https://redirect.github.com/duckdb/duckdb/pull/23444: fix eviction node memleak when external fi… (https://redirect.github.com/duckdb/duckdb/pull/23479)

- Update vendored sources to duckdb/duckdb@fe1ea2865f8b2fab434ec256010719e5f42b2918.

  Date: 2026-06-29 10:10:12 +0200

  Enabled `ALP` and `ALP_RD` for storage version v1.5.0 and up when using smaller block sizes (https://redirect.github.com/duckdb/duckdb/pull/23483)

- Update vendored sources to duckdb/duckdb@db41de85b1b3360600c2ed7eb2c1627b35dff426.

  Date: 2026-06-29 09:13:19 +0200

  Issue https://redirect.github.com/duckdb/duckdb/pull/23457: Ordered FIRST_VALUE Framing (https://redirect.github.com/duckdb/duckdb/pull/23499)

- Update vendored sources to duckdb/duckdb@fda2906db545de8921dd939ccbdc79e35b666f1e.

  Date: 2026-06-26 22:20:43 +0200

  Improve rle corruption error messages (https://redirect.github.com/duckdb/duckdb/pull/23480)

- Update vendored sources to duckdb/duckdb@dc72a8dc06e1c0b84bbdb6db438d17f9ee058ab5.

  Date: 2026-06-26 10:51:41 +0200

  \[v1.5\] No cache if file doesn't contain version information (https://redirect.github.com/duckdb/duckdb/pull/23434)

- Update vendored sources to duckdb/duckdb@24649101adce4fb71bfa920d3c7c1f1333df42c2.

  Date: 2026-06-25 19:51:38 +0200

  Fix false RLE corruption error (https://redirect.github.com/duckdb/duckdb/pull/23458)

- Update vendored sources to duckdb/duckdb@6352fbb168f267f8690abd6e76e4bf1daa43e8df.

  Date: 2026-06-25 11:08:11 +0200

  Use correct start time when verifying dependencies (https://redirect.github.com/duckdb/duckdb/pull/23430)

- Update vendored sources to duckdb/duckdb@152ff5079832659296600facb42ad92558c3b115.

  Date: 2026-06-23 10:58:19 +0200

  Issue https://redirect.github.com/duckdb/duckdb/pull/23383: Common Aggregate CTEs (https://redirect.github.com/duckdb/duckdb/pull/23409)

- Update vendored sources to duckdb/duckdb@15d896e750ceb1380551783c94b195f0328f09bc.

  Date: 2026-06-23 08:34:54 +0200

  fix out-of-bounds read in string to struct cast (https://redirect.github.com/duckdb/duckdb/pull/23384)
  fix out-of-bounds read in json path ReadKey lookahead (https://redirect.github.com/duckdb/duckdb/pull/23371)

- Update vendored sources to duckdb/duckdb@2cc5cda9dab17d55b5d3dabdb7f54cfd23ca634e.

  Date: 2026-06-22 16:43:49 +0200

  Add additional guards to `DICT_FSST` to prevent exception during compression with small block size (https://redirect.github.com/duckdb/duckdb/pull/23341)
  Bump Julia to v1.5.4 (https://redirect.github.com/duckdb/duckdb/pull/23398)

- Update vendored sources to duckdb/duckdb@c4770ecba48065b691843da2e6eb9f91e3fea77b.

  Date: 2026-06-19 22:02:50 +0200

  Propagate lambda bindings into `try` operator (https://redirect.github.com/duckdb/duckdb/pull/23375)

- Update vendored sources to duckdb/duckdb@600f2242eb52f32a6af6fbe668eb6c0687dcc128.

  Date: 2026-06-19 13:02:53 +0200

  \[MultiFileReader\] Prevent NULL MAP keys because of (likely missing) default value (https://redirect.github.com/duckdb/duckdb/pull/23354)
  \[Dev\] Fix recursion issue with `scripts/lldb/pointer_print` (https://redirect.github.com/duckdb/duckdb/pull/23362)

- Update vendored sources to duckdb/duckdb@d8d71422f8b9d45cb0de6f68beeac4de81fc9fec.

  Date: 2026-06-19 10:24:30 +0200

  Register `oid` of dependencies in the `DependencyManager` so that we can track if an object was re-created with the same name (https://redirect.github.com/duckdb/duckdb/pull/23348)

- Update vendored sources to duckdb/duckdb@4abd06ce01db60bc9ea8d65c99e65a6666b77377.

  Date: 2026-06-18 16:08:08 +0200

  Fix deadlock in `TemporaryMemoryManager` (https://redirect.github.com/duckdb/duckdb/pull/23351)

- Update vendored sources to duckdb/duckdb@5e09cde1ebae9dab1f8a6bb30be33b046a80a863.

  Date: 2026-06-18 12:36:16 +0200

  parquet: reject DATA_PAGE_V2 pages with inconsistent compressed_page_size (https://redirect.github.com/duckdb/duckdb/pull/23279)
  Dispatch Rust nightly build (https://redirect.github.com/duckdb/duckdb/pull/23352)

- Update vendored sources to duckdb/duckdb@d7ed3ca53fffb187a8768a4630883aeac05bbb3f.

  Date: 2026-06-18 08:05:02 +0200

  Show transport errors in HTTP log (https://redirect.github.com/duckdb/duckdb/pull/23327)

- Update vendored sources to duckdb/duckdb@f134ccacff2e6d752df3d5a4db9f01e2f01ed87e.

  Date: 2026-06-17 19:38:41 +0200

  Add request body length to http logs (https://redirect.github.com/duckdb/duckdb/pull/23316)
  bump unity to include backfill fix (https://redirect.github.com/duckdb/duckdb/pull/23326)

- Update vendored sources to duckdb/duckdb@044589684474e8e58f98fb76213cfad67d9abe3d.

  Date: 2026-06-17 15:13:27 +0200

  Correctly get typed value stats for fully shredded variants (https://redirect.github.com/duckdb/duckdb/pull/23325)
  bump iceberg again (https://redirect.github.com/duckdb/duckdb/pull/23311)
  Add support for test config extending (https://redirect.github.com/duckdb/duckdb/pull/23145)
  \[Dev\] Add LLDB scripts to help with debugging (https://redirect.github.com/duckdb/duckdb/pull/23297)


# duckdb 1.5.4.9010

## Chore

- Switch to dev version.


# duckdb 1.5.4.9009

- Switching to development version.


# duckdb 1.5.4.4

- Merge branch 'cran-1.5.4.3'.


# duckdb 1.5.4.3

## Bug fixes

- Remove the package-library extension storage option. The `duckdb_extension_storage()` function no longer accepts `"library"` (#2390).


# duckdb 1.5.4.2

## Bug fixes

- Fix shared on-disk storage path on Windows (#2385).

# duckdb 1.5.4.1

## Features

- DuckDB's on-disk storage locations now follow a unified policy. By
  default nothing is written outside the R session's temporary directory, with
  one exception: the extension cache is placed in the package library when it
  is writable and falls back to the temporary directory otherwise. Each location can be redirected through the `config` argument of
  `duckdb()`, an R option, or an environment variable. Configure the location for extensions and
  secrets with the new `duckdb_extension_storage()` and `duckdb_secret_storage()`,
  inspect the resolved locations with `duckdb_storage_status()`, and see
  `?duckdb_storage` for the full resolution policy (#2370, #2372, #2377).

  These functions replace the experimental `duckdb_consolidate_secrets()`
  introduced in 1.5.4.


# duckdb 1.5.4

## Features

- Update to DuckDB v1.5.4, see <https://github.com/duckdb/duckdb/releases/tag/v1.5.4> for details.

- Support writing `MAP` columns via `dbAppendTable()` and `dbWriteTable()` (#2354).

- Add native `VARIANT` (@thohan88, #2313) and `TIME WITH TIME ZONE` (#1807, #2336) data type support.

- Implement DBI Arrow API with `dbSendQueryArrow()` and streaming (#2347, #2355).

- Store downloaded extensions inside the duckdb package install directory (#2327).

- Add secret directory configuration, package startup message, and consolidation support via new experimental `duckdb_consolidate_secrets()` (#2305, #2340).

## Compatibility

- Add `is_distinct_from()` / `is_not_distinct_from()` dbplyr translations for compatibility with upcoming dbplyr 2.6.0 (#2326, #2332).

- Bump minimum R version requirement to 4.2.0 (#2233, #2334).

## Testing

- Add CRAN guards to prevent heavy C++ engine tests on CRAN (#2353, #2358).

- Add comprehensive test coverage for `MAP` type reading (#2342).


# duckdb 1.5.3

## Features

- Update to DuckDB v1.5.3, see <https://github.com/duckdb/duckdb/releases/tag/v1.5.3> for details.

- Add secret directory configuration, package startup message, and consolidation support via new experimental `duckdb_consolidate_secrets()` (#2305, #2340).

- Add native `VARIANT` (@thohan88, #2313) and `TIME WITH TIME ZONE` (#1807, #2336) data type support.

- Add `is_distinct_from()` / `is_not_distinct_from()` dbplyr translations for compatibility with upcoming dbplyr 2.6.0 (#2326, #2332).

## Bug fixes

- Avoid rchk error in `RownamesDuplicate()` (#2290, #2291).

## Chore

- Bump minimum R version requirement to 4.2.0 (#2233, #2334).

- Store downloaded extensions inside the duckdb package install directory (#2327).

## Testing

- Add comprehensive test coverage for `MAP` type reading (#2342).


# duckdb 1.5.2

## Bug fixes

- Update to DuckDB v1.5.2, see <https://github.com/duckdb/duckdb/releases/tag/v1.5.2> for details.

- Fix compiler warning on recent clang on macOS.

## Features

- Use `TRY_CAST()` instead of `CAST()` in dplyr SQL translation for type conversion functions (#2230, #2231).

## Chore

- Use `R_getRegisteredNamespace()` in R 4.6.

## Documentation

- Describe branching strategy (#2280, #2281).

## Testing

- Use explicit default duckdb connection for arrow tests (#2301).

- Rework arrow tests, prepare for compatibility with dbplyr 2.6.0 (#2300).


# duckdb 1.5.1

## Bug fixes

- Update to DuckDB v1.5.1, see <https://github.com/duckdb/duckdb/releases/tag/v1.5.1> for details.

## Features

- `GEOMETRY` columns can be returned, either as BLOBs (default) or as wk objects (via the wk package) using `dbConnect(geometry = "wk")` (#2278, #2279).

## Chore

- Fix `-Wdeprecated` compiler warnings (#2295, #2296) and protection buglet (#2294).

- Use `gtar` when available to suppress Apple extended attribute warnings on Linux (#2227, #2228).


# duckdb 1.5.0

## Features

- Update to DuckDB v1.5.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.5.0> for details.

- Support `descending` and `nulls_first` in `expr_window()` and `rel_order()` (#2074, #2075).

## Bug fixes

- The dbplyr translation of `as.numeric()` and `as.double()` uses `DOUBLE` instead of `NUMERIC` (#2023, #2031).

## Testing

- Update to testthat edition 3.

## Internal

- Avoid `ATTRIB()` for compatibility with R 4.6, materialize ALTREP row names to integer sequence with full ALTREP methods (#2034).


# duckdb 1.4.4

## Features

- Update to DuckDB v1.4.4, see <https://github.com/duckdb/duckdb/releases/tag/v1.4.4> for details.

- Add operator expressions (@toppyy, #1828).

## Chore

- Bump vendored cpp11 to v0.5.3.

## Documentation

- Add alternative installation method to README (@szarnyasg, #1819).


# duckdb 1.4.3

## Features

- Update to DuckDB v1.4.3, see <https://github.com/duckdb/duckdb/releases/tag/v1.4.3> for details.

- Add `str_ilike()` support (@edward-burn, #1810, #1811).

## Bug fixes

- Fail with non-UTF8-encoded strings during data frame scan instead of attempting to reencode (#1795).

- Avoid inclusion of raw error message in the output.

- Fix translation of `quantile()` to use DuckDB's native `QUANTILE_CONT()` syntax (#1734, #1735).

## Testing

- Remove redundant R version checks from tests (#1815, #1816).


# duckdb 1.4.2

- Update to DuckDB v1.4.2, see <https://github.com/duckdb/duckdb/releases/tag/v1.4.2> for details.


# duckdb 1.4.1

- Update to DuckDB v1.4.1, see <https://github.com/duckdb/duckdb/releases/tag/v1.4.1> for details.

## Features

- Add support for wildcards in `tbl_file()` paths (#1614, @rplsmn).

- Add `n_distinct(..., na.rm = TRUE)` support for multiple passed columns (@lschneiderbauer, #1588).

## Bug fixes

- Fix Valgrind error.

## Testing

- Ensure be able to install duckdb extensions on release version (@eitsupi, #1586).


# duckdb 1.4.0

- Update to DuckDB v1.4.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.4.0> for details.

## Features

- New experimental `sql_query()`, `sql_exec()`, and `default_conn()` to simplify the most important operations for interactive use (#1564).

- `tbl_file()` allows omitting the `src` argument, falling back to the default connection.

- Full support for deep structs generated by `struct_pack()` for ALTREP (#1545).

## Bug fixes

- Fix progress display for fractional progress values (#1499, #1505).

- Extensions can be installed again.


# duckdb 1.3.3

- Update to the current v1.3-ossivalis branch, see <https://github.com/duckdb/duckdb/tree/v1.3-ossivalis> for details.

## Bug fixes

- Fix timezone conversion for invalid timestamps with `tz_out_convert = "force"` (#1474).

- Substitute invalid UTF-8 characters in error messages to avoid a failure when reporting the error.

- Fix index calculation for retrieval of arrays (#1473).

- Fix conversion for retrieval of large enums.

- Fix compiler error in debug build (@joakimlinde, #1368).

## Features

- Add rich ErrorData-based error handling with structured error information (#1479).

- Safeguard against deadlocks when accidentally issuing queries from the progress bar handler or other callbacks (#1475).

- `dbGetInfo()` gets the version from a hard-coded value and not from a DuckDB query (#1481).

- Package uses two cores by default for compilation (#1478).

## Documentation

- Document vendoring process and main/next branch relationship (#1488).

## Testing

- Add `local_con()` test fixture for cleaner DuckDB connection management (#1476).


# duckdb 1.3.2

## Features

- Update to duckdb v1.3.2, see <https://github.com/duckdb/duckdb/releases/tag/v1.3.2> for details.


# duckdb 1.3.1

## Features

- Update to duckdb v1.3.1, see <https://github.com/duckdb/duckdb/releases/tag/v1.3.1> for details.

## Bug fixes

- Correct dbplyr translations for `str_starts()` and `str_ends()` (#1182, #1247).

- Fix multiarch build on R 4.1 for Windows.


# duckdb 1.3.0

## Features

- Update to duckdb v1.3.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.3.0> for details.

- Add ingestion of matrices (@joakimlinde, #1150).

## Chore

- Fix rchk (#1173).

- Fix compiler warning (@joakimlinde, #1172).

## Testing

- Skip timing tests on CRAN.


# duckdb 1.2.2

## Features

- Update to duckdb v1.2.2, see <https://github.com/duckdb/duckdb/releases/tag/v1.2.2> for details.

- Add support for duckdb arrays in R (@joakimlinde, #102, #1090). To enable, connect with `dbConnect(duckdb(), array = "matrix")` (@joakimlinde, #1125).

- Support fractional seconds in `TIME` and `INTERVAL` data (#1109).

- The `autoload_known_extensions` configuration option is now enabled by default (#582, #1084, #1134).

- Mention column name for conversion errors (#1108).

## Chore

- Require R \>= 4.1 (#1087, #1133).

- Types exposed through ALTREP are the same as through DBI (#1111), including `STRUCT`. This enables support more types in upcoming duckplyr versions.

- Perform optional checks for ALTREP compatibility in `rel_from_df()` and `expr_constant()` (#1117).

- Perform time zone conversion in the C++ layer where possible, to support ALTREP (#1130).

- Improve developer experience: `pkgload::load_all()` now works, source files are rebuilt if header files change, configure clangd (#1128).

- Add dots with checks to unexported functions (#1115).

- Clean up edge case for fetching zero rows (#1104).

- Avoid test for timings on CRAN (#1101).

## Documentation

- Tweak README.


# duckdb 1.2.1

## Features

- Update to duckdb v1.2.1, see <https://github.com/duckdb/duckdb/releases/tag/v1.2.1> for details.

## Bug fixes

- `dbExecute(con, "CALL ...")` no longer attempts to access the resulting data frame. Use `dbGetQuery(con, "CALL ...")` to access the data (#1062, #1080).

- Fix support for the connections pane in RStudio and Positron (@dfalbel, #1063).

## Internal

- New `rel_to_view()` (\#1075).

- New internal `AltrepDataframeRelation`, used with `rel_from_altrep_df(wrap = TRUE)` (#949, #1072).

- Try relational materialization only once (#1066).

## Chore

- Update vendored cpp11 to 0.5.2 (#1068).

- Avoid calls to non-API R functions.


# duckdb 1.2.0

## Breaking changes

- Breaking change: Remove substrait API: `duckdb_get_substrait()`, `duckdb_get_substrait_json()`, `duckdb_prepare_substrait()`, `duckdb_prepare_substrait_json()` (@pdet, #1021).

## Features

- Update to duckdb v1.2.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.2.0> for details.

- Progress is shown for slow operation. This is on by default in interactive mode and can be controlled by setting the `"duckdb.progress_display"` option to a logical scalar (#199, #951, @meztez).

- Add translation for `median()` (@toppyy, #993, #1011).

- Floor sub-day precision date before casting to int (@toppyy, #517, #981).

- Set value returned by `PRAGMA user_agent` to r-dbi (#707, @elefeint).

## Bug fixes

- Remove unconditional use of `CPPHTTPLIB_USE_POLL` to support compilation with R 4.0 and R 4.1 again (@Antonov548, #1043).

- Support reading from multiple Parquet files again (#1015, #1024).

- Fix translation for `add_days()` and `add_years()` clock functions (#976, @IoannaNika).


# duckdb 1.1.3-2

## Bug fixes

- Make `cleanup` truly idempotent (#612, #940).

## Chore

- Sync vendoring script with igraph (#936).

## Features

- Limit automatic materialization by number of rows or number of cells (#1017).

- New internal `rapi_rel_to_csv()`,`rapi_rel_to_table()`, and `rapi_rel_insert()`; `rapi_rel_to_parquet()` gains `options` argument (#867).

## Testing

- Skip tests that are about to fail.

- Sync tests.


# duckdb 1.1.3-1

## Features

- With `duckdb(environment_scan = TRUE)`, data frame objects are available as views in duckdb SQL queries (#140, #164).

- Update vendored cpp11 to 0.5.1 (#636).

## Bug fixes

- Make `./cleanup` script reentrant (@Antonov548, #612, #634).

- Fix installation of extensions (#623).

- Fix rchk and UB errors (#635).

- Avoid loading rlang during startup (#601).

## Documentation

- Mention `xz` requirement in `DESCRIPTION`.


# duckdb 1.1.3

## Features

- Update to duckdb v1.1.3, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.3> for details.

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()` (#589).

- New `rel_explain_df()` and `rel_tostring()` (#587).

- Handle empty child values for list constants (#186, @romainfrancois).

## Chore

- Undef `TRUE` and `FALSE` (#595).

- Remove `enable_materialization` argument to `rel_from_altrep_df()` in favor of creating a new data frame when needed (#588).

- Flip argument order for `expr_comparison()` (#585).

- Keep `cleanup` files to accommodate different build scenarios (#536).


# duckdb 1.1.2

## Features

- Update to duckdb v1.1.2, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.2> for details.

## Features

- Long-running queries can now be canceled immediately with Ctrl + C (terminal) or Escape (RStudio IDE and Workbench) (#514, #515).

- Add `col.types` argument to `duckdb_read_csv()` (#445, @eli-daniels).

- Rethrow errors with rlang if installed (#522).

- Improve error message for parsing erros during statement extraction (tidyverse/duckplyr#219, #521).

## Bug fixes

- Avoid RStudio IDE crashes when ending session with open objects (#520).

- `rfuns` extension: `%in%` works correctly as part of a `&` conjunction (#528).

## Internal

- New interal APIs: `rapi_get_last_rel_mat()`, `rapi_rel_to_altrep(allow_materialization = TRUE)`, `rapi_rel_from_altrep_df(enable_materialization)` (#526).

- xz-compress duckdb sources in the tarball (#530).

- `rfuns` extension: Fix signedness.


# duckdb 1.1.1

## Features

- Update to duckdb v1.1.1, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.1> for details.

- Add comparison expression to relational API (@toppyy, #457).

- Temporarily change `max_expression_depth` during ALTREP evaluation (#101, #460).

- Add `temporary` argument to `duckdb_read_csv()` (@ThomasSoeiro, #223).

## Chore

- Update vendored extension sources to hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe.

- Remove warnings for uninitialized variables.


# duckdb 1.1.0

## Features

- Update to duckdb v1.1.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.1.0> for details.

- Upgrade vendored cpp11 to 0.5.0.


# duckdb 1.0.0-2

## Features

- Reduce the package installation size on macOS (#185).


# duckdb 1.0.0-1

## Bug fixes

- Upgrade vendored cpp11 to 0.4.7 to fix compilation with R-devel.

- Support `dplyr::tbl(conn, I(...))`.


# duckdb 1.0.0

## Bug fixes

- Update to duckdb v1.0.0, see <https://github.com/duckdb/duckdb/releases/tag/v1.0.0> for details.


# duckdb 0.10.3

## Features

- Update to duckdb v0.10.3, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.3> for details.
- Support fetching `MAP` type (#61, #165).
- Add dbplyr translations for `clock::date_count_between()` (@edward-burn, #163, #166).
- `round()` duckdb translation uses `ROUND_EVEN()` instead of `ROUND()` (@lschneiderbauer, #146, #157).
- New `sort` argument to `rel_order()` (@toppyy, #168).
- Add dbplyr translations for `clock::add_days()`, `clock::add_years()`, `clock::get_day()`, `clock::get_month()`, and `clock::get_year()` (@edward-burn, #153).

## Bug fixes

- Correct usage of `win_current_group()` instead of `win_current_order()` in SQL translation (@lschneiderbauer, #173, #175).


# duckdb 0.10.2

## Features

- Update to duckdb v0.10.2, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.2> for details.
- The `"difftime"` class is now mapped to the `INTERVAL` data type (#151).
- Use latest tests from DBItest (#148).
- Implement `n_distinct()` for multiple arguments using duckdb structs (@lschneiderbauer, #110, #122).
- Include rfuns extension (hannes/duckdb-rfuns#78, #144).
- Map `NA` to `SQLNULL` (#143).

## Bug fixes

- `rel_sql(rel, "{{sql}}")` works even on a read-only database (@Tmonster, #138).
- Avoid `R CMD check` warning regarding `SETLENGTH()` and `SET_TRUELENGTH()` (#145).


# duckdb 0.10.1

## Features

- Update to duckdb v0.10.1, see <https://github.com/duckdb/duckdb/releases/tag/v0.10.1> for details.
- Fix shutdown semantics for the driver object created by `duckdb()`. A database file is closed (and available to be opened from another session) after the last connection that uses this file calls `dbDisconnect()` . The `shutdown` argument to `dbDisconnect()` or the `duckdb_shutdown()` functions are no longer necessary. Two database connections from the same R session can access the same file concurrently in read-write mode (#124).

## Bug fixes

- Don't run tests that invoke re2 by default (#121, #127).

- Fix compilation for R 4.0 and R 4.1, regression introduced in v0.10.0. Using `librstrtmgr.a` from UCRT build of rtools40 (#130).

## Internal

- The C++ core is now vendored commit by commit, once every five minutes. Vendoring stops if `R CMD check` fails or if a previously unreleased tag is reached.

- New maintainer: Kirill Müller.

## Continuous integration

- Add rhub2 workflow.


# duckdb 0.10.0

## Bug fixes

- `dplyr::tbl()` works again when a Parquet or CSV file is passed instead of a table name (#38, #91).

- `DBI::dbQuoteIdentifier()` correctly quotes identifiers that start with a digit (#67, #92).

- Align the argument order of `dbWriteTable()` with the DBI specs (@eitsupi, #43, #49).

## Features

- New `tbl_file()` and `tbl_query()` to explicitly access tables and queries as dbplyr lazy tables (#96). The `cache` argument to `tbl()` and to the new functions must be named.

- Initial ALTREP support for `LIST` logical type (@romainfrancois, #77).

- Update core to duckdb v0.10.0 (#90).

- New private `rel_to_parquet()` to write a relation to parquet (@Tmonster, #46).

## Chore

- Change directory location for extensions and secrets for v.0.10.0 release (@Tmonster, #73).

- Remove last instance of `default_connection()` (#50).

## Documentation

- Add list of contributors (#2, #94).

- Use pkgdown BS5 (@maelle, #31, #70) with DuckDB logo (#76, @romainfrancois).

- Link to R documentation page.

- Include `NEWS.md` on CRAN (#48, @olivroy).

## Testing

- Add csv reading test for `duckdb_read_csv(na.strings = )` (@Tmonster, #10).

- Fix snapshot tests.

- Tweak tests for compatibility with v0.10.0 (#84).

# duckdb 0.9.2-1

- Fix compiler warning on R-devel (#45).


# duckdb 0.9.2

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.9.2>.

- Add dbplyr translation for `prod()` (#40, @m-muecke).


# duckdb 0.9.1-1

- Fix LTO checks on CRAN.


# duckdb 0.9.1

- See blog post at <https://duckdb.org/2023/09/26/announcing-duckdb-090.html>.

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.9.1>.

- Move sources to <https://github.com/duckdb/duckdb-r> (@krlmlr).

- Add ADBC integration with the adbcdrivermanager package (duckdb/duckdb#8172, @paleolimbot).

- Full support of lists and structs in R (duckdb/duckdb#8503, @krlmlr).

# duckdb 0.8.1-3

- Internal changes to support the duckplyr package.

# duckdb 0.8.1-2

- Compatibility with dbplyr.

- Internal changes to support the duckplyr package.

# duckdb 0.8.1-1

- Fix CRAN checks.

# duckdb 0.8.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.8.1>.

# duckdb 0.8.0

- See blog post at <https://duckdb.org/2023/05/17/announcing-duckdb-080.html>.

# duckdb 0.7.1-1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.7.1>.

# duckdb 0.7.0

- See blog post at <https://duckdb.org/2023/02/13/announcing-duckdb-070.html>.

# duckdb 0.6.2

- New `duckdb_prepare_substrait_json()`.

# duckdb 0.6.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.6.1>.

# duckdb 0.6.0

- See blog post at <https://duckdb.org/2022/11/14/announcing-duckdb-060.html>.

# duckdb 0.5.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.5.1>.

# duckdb 0.5.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.5.0>.

# duckdb 0.4.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.4.0>.

# duckdb 0.3.4-1

- Minor changes for CRAN compatibility.

# duckdb 0.3.4

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.4>.

# duckdb 0.3.3

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.3>.

# duckdb 0.3.2

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.2>.

# duckdb 0.3.1

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.1>.

# duckdb 0.3.0

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.3.0>.

- See release notes at <https://github.com/duckdb/duckdb/releases/tag/v0.2.9>.

# duckdb 0.2.8

This preview release of DuckDB is named "Ceruttii" after a [long-extinct relative of the present-day Harleqin Duck](https://en.wikipedia.org/wiki/Harlequin_duck#Taxonomy) (Histrionicus Ceruttii).
Binary builds are listed below. Feedback is very welcome.

Note: Again, this release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the [documentation](https://duckdb.org/docs/sql/statements/export) for details.

### SQL

 - #2064: `RANGE`/`GENERATE_SERIES` for timestamp + interval
 - #1905: Add `PARQUET_METADATA` and `PARQUET_SCHEMA` functions
 - #2059, #1995, #2020 & #1960: Window `RANGE` framing, `NTH_VALUE` and other improvements

### APIs

 - Many Arrow integration improvements
 - Many ODBC driver improvements
 - #1815: Initial version: SQLite UDF API
 - #2001: Support DBConfig in C API

### Engine

 - #1975, #1876 & #2009: Unified row layout for sorting, aggregate & joins
 - #1930 & #1904: List Storage
 - #2050: CSV Reader/Casting Framework Refactor & add support for `TRY_CAST`
 - #1950: Add Constant Segment Compression to Storage
 - #1957: Add pipe/stream file system





# duckdb 0.2.7

This preview release of DuckDB is named "Mollissima" after the Common Eider (Somateria mollissima).
 Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:

SQL
 - #1847: Unify catalog access functions, and provide views for common PostgreSQL catalog functions
 - #1822: Python/JSON-Style Struct & List Syntax
 - #1862: #1584 Implementing `NEXTAFTER` for float and double
 - #1860: `FIRST` implementation for nested types
 - #1858: `UNNEST` table function & array syntax in parser
 - #1761: Issue #1746: Moving `QUANTILE`

APIs

 - #1852, #1840, #1831, #1819 and #1779: Improvements to Arrow Integration
 - #1843: First iteration of ODBC driver
 - #1832: Add visualizer extension
 - #1803: Converting Nested Types to native python
 - #1773: Add support for key/value style configuration, and expose this in the Python API

Engine
 - #1808: Row-Group Based Storage
 - #1842: Add (Persistent) Struct Storage Support
 - #1859: Read and write atomically with offsets
 - #1851: Internal Type Rework
 - #1845: Nested join payloads
 - #1813: Aggregate Row Layout
 - #1836: Join Row Layout
 - #1804: Use Allocator class in buffer manager and add a test for a custom allocator usage





# duckdb 0.2.6

This preview release of DuckDB is named "Jamaicensis" after the [blue-billed Ruddy Duck (Oxyura jamaicensis)](https://en.wikipedia.org/wiki/Ruddy_duck). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Also note: Due to changes in the internal storage (#1530), databases created with this release wil require somewhat more disk space. This is transient as we are working hard to finalise the on-disk storage format.

Major changes:

Engine
 - #1666: External merge sort, #1580: Parallel scan of ordered result and #1561: Rework physical ORDER BY
 - #1520 & #1574: Window function computation parallelism
 - #1540: Add table functions that take a subquery parameter
 - #1533: Using vectors, instead of column chunks as lists
 - #1530: Store null values separate from main data in a Validity Segment

SQL
 - #1568: Positional Reference Operator `#1` etc.
 - #1671: `QUANTILE` variants and #1685: Temporal quantiles
 - #1695: New Timestamp Types `TIMESTAMP_NS`, `TIMESTAMP_MS` and `TIMESTAMP_NS`
 - #1647: Add support for UTC offset timestamp parsing to regular timestamp conversion
 - #1659: Add support for `USING` keyword in `DELETE` statement
 - #1638, #1663, #1621 & #1484: Many changes arount `ARRAY` syntax
 - #1610: Add support for `CURRVAL`
 - #1544: Add `SKIP` as an option to `READ_CSV` and `COPY`

APIs
 - #1525: Add loadable extensions support
 - #1711: Parallel Arrow Scans
 - #1569: Map-style UDFs for Python API
 - #1534: Extensible Replacement Scans & Automatic Pandas Scans and #1487: Automatically use parquet or CSV scan when using a table name that ends in `.parquet` or `.csv`
 - #1649: Add a QueryRelation object that can be used to convert a query directly into a relation object, #1665: Adding from_query to python api
 - #1550: Shell: Add support for Ctrl + arrow keys to linenoise, and make Ctrl+C terminate the current query instead of the process
 - #1514: Using `ALTREP` to speed up string column transfer to R
 - #1502: R: implementation of Rstudio connection-contract tab





# duckdb 0.2.5

This preview release of DuckDB is named "Falcata" after the Falcated Duck (Mareca falcata). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major Changes:

Engine
 - #1356: **Incremental Checkpointing**
 - #1422: Optimize Top N Implementation

SQL
 - #1406, #1372, #1387: Many, many new aggregate functions
 - #1460: `QUANTILE` aggregate variant that takes a list of quantiles &  #1346: Approximate Quantiles
 - #1461: `JACCARD`, #1441 `LEVENSHTEIN` & `HAMMING` distance  scalar function
 - #1370: `FACTORIAL` scalar function and ! postfix operator
 - #1363: `IS (NOT) DISTINCT FROM`
 - #1385: `LIST_EXTRACT` to get a single element from a list
 - #1361: Aliases in the `HAVING` clause (fixes issue #1358)
 - #1355: Limit clause with non constant values

APIs:
 - #1430 & #1424: **DuckDB WASM builds**
 - #1419: Exporting the appender api to C
 - #1408: Add blob support to C API
 - #1432,  #1459 & #1456: Progress Bar
 - #1440: Detailed profiler.






# duckdb 0.2.4

This preview release of DuckDB is named "Jubata" after the [Australian Wood Duck](https://en.wikipedia.org/wiki/Australian_wood_duck) (Chenonetta jubata). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:
SQL
 - #1231: Full Text Search extension
 - #1309: Filter Clause for Aggregates
 - #1195: `SAMPLE` Operator
 - #1244: `SHOW` select queries
 - #1301: `CHR` and `ASCII` functions & #1252: Add `GAMMA` and `LGAMMA` functions

Engine
 - #1211: (Mostly) Lock-Free Buffer Manager
 - #1325: Unsigned Integer Types Support
 - #1229: Filter Pull Up Optimizer
 - #1296: Optimizer that removes redundant `DELIM_GET` and `DELIM_JOIN` operators
 - #1219: `DATE`, `TIME` and `TIMESTAMP` rework: move to epoch format & microsecond support

Clients
 - #1287 and #1275: Improving JDBC compatibility
 - #1260: Rework client API and prepared statements, and improve DuckDB -> Pandas conversion
 - #1230: Add support for parallel scanning of pandas data frames
 - #1256: JNI appender
 - #1209: Write shell history to file when added to allow crash recovery, and fix crash when .importing file with invalid
 - #1204: Add support for blobs to the R API and #1202: Add blob support to the python api

Parquet
 - #1314: Refactor and nested types support for Parquet Reader



# duckdb 0.2.3

This preview release of DuckDB is named "Serrator" after the Red-breasted merganser (Mergus serrator). Binary builds are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the EXPORT DATABASE command with the old version followed by IMPORT DATABASE with the new version to migrate your data. See the documentation for details.

Major changes:

SQL:
 - #1179: Interval Cleanup & Extended `INTERVAL` Syntax
 - #1147: Add exact `MEDIAN` and `QUANTILE` functions
 - #1129: Support scalar functions with `CREATE FUNCTION`
 - #1137: Add support for (`NOT`) `ILIKE`, and optimize certain types of `LIKE` expressions

Engine
 - #1160: Perfect Aggregate Hash Tables
 - #1133: Statistics Rework & Statistics Propagation
 - #1144: Common Aggregate Optimizer, #1143: CSE Optimizer and #1135: Optimizing expressions in grouping keys
 - #1138: Use predication in filters
 - #1071: Removing string null termination requirement

Clients
 - #1112: Add DuckDB node.js API
 - #1168: Add support for Pandas category types
 - #1181: Extend DuckDB::LibraryVersion() to output dev version in format `0.2.3-devXXX` & #1176: Python binding: Add module attributes for introspecting DuckDB version

Parquet Reader:
 - #1183: Filter pushdown for Parquet reader
 - #1167: Exporting Parquet statistics to DuckDB
 - #1162: Add support for compression codec in Parquet writer &  #1163: Add ZSTD Compression Code and add ZSTD codec as option for Parquet export
 - #1103: Add object cache and Parquet metadata cache











# duckdb 0.2.2

This is a preview release of DuckDB.
Starting from this release, releases get named as well. Names are chosen from species of ducks (of course). We start with "Clypeata".

*Note*: This release introduces a backwards-incompatible change to the on-disk storage format. We suggest you use the `EXPORT DATABASE` command with the old version followed by `IMPORT DATABASE` with the new version to migrate your data. See the [documentation](https://duckdb.org/docs/sql/statements/export) for details.

Binary builds are listed below. Feedback is very welcome. Major changes:

SQL
 - #1057: Add PRAGMA for enabling/disabling optimizer & extend output for query graph
 - #1048: Allow CTEs in subqueries (including CTEs themselves) and #987: Allow CTEs in CREATE VIEW statements
 - #1046: Prettify Explain/Query Profiler output
 - #1037: Support FROM clauses in UPDATE statements
 - #1006: STRING_SPLIT and STRING_SPLIT_REGEX SQL functions
 - #1000: Implement MD5 function
 - #936: Add GLOB support to Parquet & CSV readers
 - #899: Table functions information_schema_schemata() and information_schema_tables() and #903: Add table function information_schema_columns()

Engine
 - #984: Parallel grouped aggregations and #1045: Some performance fixes for aggregate hash table
 - #1008: Index Join
 - #991: Local Storage Rework: Per-morsel version info and flush intermediate chunks to the base tables
 - #906: Parallel scanning of single Parquet files and #982: ZSTD Support in Parquet library
 - #883: Unify Table Scans with Table Functions
 - #873: TPC-H Extension
 - #884: Remove NFC-normalization requirement for all data and add COLLATE NFC

Client
 - #1001: Dynamic Syntax Highlighting in Shell
 - #933: Upgrade shell.c to 3330000
 - #918: Add in support for Python datetime types in bindings
 - #950: Support dates and times output into arrow
 - #893: Support for Arrow NULL columns


# duckdb 0.2.1

This is a preview release of DuckDB. Binary builds are listed below. Feedback is very welcome. Major changes:

Engine
 - #770: Enable Inter-Pipeline Parallelism
 - #835: Type system updates with #779: `INTERVAL` Type,  #858: Fixed-precision `DECIMAL` types & #819: `HUGEINT` type
 - #790: Parquet write support

API
 - #866: Initial Arrow support
 - #809: Aggregate UDF support with #843: Generic `CreateAggregateFunction()` & #752: `CreateVectorizedFunction()` using only template parameters

SQL
 - #824: `strftime` and `strptime`
 - #858: `EXPORT DATABASE` and `IMPORT DATABASE`
 - #832: read_csv(_auto) improvements: optional parameters, configurable sample size, line number info



# duckdb 0.2.0

This is a preview release of DuckDB. Binary builds are listed below. Feedback is very welcome.

SQL:
 - #730: `FULL OUTER JOIN` Support
 - #732: Support for `NULLS FIRST`/`NULLS LAST`
 - #698: Add implementation of the `LEAST`/`GREATEST` functions
 - #772: Implement `TRIM` function and add optional second parameter to `RTRIM`/`LTRIM`/`TRIM`
 - #771: Extended Regex Options

Clients:
 - Python: #720: Making Pandas optional and add support for PyPy
 - C++: #712: C++ UDF API





# duckdb 0.1.9

This is a preview release of DuckDB. Binary are listed below. Feedback is very welcome. Major changes:
New [website](https://duckdb.org/) [woo-ho](https://www.youtube.com/watch?v=H9cmPE88a_0)!

Engine
 - #653: Parquet reader integration

SQL
 - #685: Case insensitive binding of column names
 - #662: add `EPOCH_MS` function and test cases

Clients
 - #681: JDBC Read-only mode for and #677 duplicate()` method to allow multiple connections to same database



# duckdb 0.1.8

This is a preview release of DuckDB. Feedback is very welcome.

SQL
 - SQL functions `IF` and `IFNULL` #644
 - SQL string functions `LEFT` #620 and `RIGHT` #631
 - #641: `BLOB` type support
 - #640: `LIKE` escape support

Clients
 - #627: Insertion support for Python relation API



# duckdb 0.1.7

This is the sixth preview release of DuckDB. Feedback is very welcome.
Binary builds are available as well.

SQL
- [Add / remove columns, change default values & column type](https://duckdb.org/docs/sql/statements/alter_table) #612
- [Collation support](https://duckdb.org/docs/sql/expressions/collations)
- CSV sniffer `READ_CSV_AUTO` for dialect, data type and header detection #582
- `SHOW` & `DESCRIBE` Tables #501
- String function `CONTAINS`  #488
- String functions `LPAD` / `RPAD`, `LTRIM` / `RTRIM`, `REPEAT`, `REPLACE` & `UNICODE` #597
- Bit functions `BIT_LENGTH`, `BIT_COUNT`, `BIT_AND`, `BIT_OR`, `BIT_XOR` & `BIT_AGG` #608

Engine
- `LIKE` optimization rules #559
- Adaptive filters in table scans #574
- ICU Extension for extended Collations & Extension Support #594
- Extended zone map support in scans #551
- Disallow NaN/INF in the system #541
- Use UTF Grapheme Cluster Breakers in Reverse and Shell #570

Clients
- Relation API for C++ #509 and Python #598
 - Java (TM) JDBC (R) Client for DuckDB #492 #520 #550



# duckdb 0.1.6

This is the fifth preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here: http://download.duckdb.org/alias/v0.1.6/

SQL
- #455 Table renames `ALTER TABLE tbl RENAME TO tbl2`
- #457 Nested list type can be created using `LIST` aggregation and unpacked with the new `UNNEST` operator
- #463 `INSTR` string function, #477 `PREFIX` string function, #480 `SUFFIX` string function

Engine
- #442 Optimized casting performance to strings
- #444 Variable return types for table-producing functions
- #453 Rework aggregate function interface
- #474 Selection vector rework
- #478 UTF8 NFC normalization of all incoming strings
- #482 Skipping table segments during scan based on min/max indices

Python client
- #451 `date` / `datetime` support
- #467 `description` field for cursor
- #473 Adding `read_only` flag to `connect`
- #481 Rewrite of Python API using `pybind11`

R client
- #468 Support for prepared statements in R client
- #479 Adding automatic CSV to table function `read_csv_duckdb`
- #483 Direct scan operator for R `data.frame` objects



# duckdb 0.1.5

This is the fourth preview release of DuckDB. Feedback is very welcome. Note: The v0.1.4 version was skipped because of a Python packaging issue.

Binary builds can be found here:
http://download.duckdb.org/rev/59f8907b5d89268c158ae1774d77d6314a5c075f/

Major changes:
 - #409 Vector Overhaul
 - #423 Remove individual vector cardinalities
 - #418 `DATE_TRUNC` SQL function
 - #424 `REVERSE` SQL function
 - #416 Support for `SELECT table.* FROM table`
 - #414 STRUCT types in query execution
 - #431 Changed internal string representation
 - #433 Rename internal type `index_t` to `idx_t`
 - #439 Support for temporary structures in read-only mode
 - #440 Builds on Solaris & OpenBSD


*Note*: This release contains a bug in the Python API that leads to crashes when fetching strings to NumPy/Pandas #447


# duckdb 0.1.3

This is the third preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/59f8907b5d89268c158ae1774d77d6314a5c075f/

Major changes:
  * #388 Major updates to shell
  * #390 Unused Column & Column Lifetime Optimizers
  * #402 String and compound keys in indices/primary keys
  * #406 Adaptive reordering of filter expressions



# duckdb 0.1.2

This is the third preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/6fcb5ef8e91dcb3c9b2c4ca86dab3b1037446b24/


# duckdb 0.1.1

This is the second preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
http://download.duckdb.org/rev/2e51e9bae7699853420851d3d2237f232fc2a9a8/


# duckdb 0.1.0

This is the first preview release of DuckDB. Feedback is very welcome.

Binary builds can be found here: http://download.duckdb.org/rev/c1cbc9d0b5f98a425bfb7edb5e6c59b5d10550e4/
