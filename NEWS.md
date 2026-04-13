<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# duckdb 1.5.2

## vendor

- Update vendored sources (tag v1.5.2) to duckdb/duckdb@8a5851971fae891f292c2714d86046ee018e9737.

  Date: 2026-04-10 14:33:51 +0200

- Update vendored sources to duckdb/duckdb@8a5851971fae891f292c2714d86046ee018e9737.

  Revert "Run ArrowConverter::ToArrowSchema in a transaction" (https://redirect.github.com/duckdb/duckdb/pull/22007)
  Bump httpfs, now with implemented httpfs_connection_caching (opt-in) (https://redirect.github.com/duckdb/duckdb/pull/21982)

- Update vendored sources to duckdb/duckdb@097126790e375c7ebeaface4cd2da8d44e02505d.

  Date: 2026-04-10 06:51:02 +0200

  Bumping DuckLake (https://redirect.github.com/duckdb/duckdb/pull/21989)

- Update vendored sources to duckdb/duckdb@f88ffceef35d2c5475747e475c80972eb79aec2e.

  Date: 2026-04-09 23:28:06 +0200

  bump azure and delta for v1.5.2 (https://redirect.github.com/duckdb/duckdb/pull/21979)

- Update vendored sources to duckdb/duckdb@3ab4d25d019e69f555a36023bf5294ee1de4985a.

  Date: 2026-04-09 20:13:41 +0200

  Json function should be set CanThrow (https://redirect.github.com/duckdb/duckdb/pull/21972)

- Update vendored sources to duckdb/duckdb@0f7eef287ff7a7bf80f02ea363517060323cc496.

  Date: 2026-04-09 20:13:23 +0200

  Attempt to fix invalid memory access (https://redirect.github.com/duckdb/duckdb/pull/21985)

- Update vendored sources to duckdb/duckdb@accc0506cd7478666159451da8735799ecde0c12.

  Date: 2026-04-09 18:36:28 +0200

  MERGE INTO - no need to extract logical get, we already know where it is (https://redirect.github.com/duckdb/duckdb/pull/21984)
  Fix "make clangd" (https://redirect.github.com/duckdb/duckdb/pull/21981)

- Update vendored sources to duckdb/duckdb@ec9059cca4aed04aa5d7c8ad6bc4a171e31560dc.

  Date: 2026-04-09 14:27:05 +0200

  Shred unsigned types in VARIANT when writing to Parquet (https://redirect.github.com/duckdb/duckdb/pull/21973)
  bump avro hash (https://redirect.github.com/duckdb/duckdb/pull/21974)

- Update vendored sources to duckdb/duckdb@64f0eae50bbb324ccf644bb140da7963ce9c874f.

  Date: 2026-04-09 13:17:27 +0200

  Unlock transaction lock during fallback WAL write (https://redirect.github.com/duckdb/duckdb/pull/21969)

- Update vendored sources to duckdb/duckdb@4812536fd84aa9ef5e845dd63968ee6ef13de99f.

  Date: 2026-04-09 11:55:52 +0200

  Make Oids start at 20k to avoid unintended collisions (https://redirect.github.com/duckdb/duckdb/pull/20979)

- Update vendored sources to duckdb/duckdb@78348f6b12b5f2a3c30a68ef7ca1e56727ae7cca.

  Date: 2026-04-09 08:55:16 +0200

  \[Parquet\]\[VARIANT\] Add support for Snowflake-produced shredded VARIANT Parquet files (https://redirect.github.com/duckdb/duckdb/pull/21814)
  bump iceberg (https://redirect.github.com/duckdb/duckdb/pull/21967)
  Bump Postgres (https://redirect.github.com/duckdb/duckdb/pull/21958)

- Update vendored sources to duckdb/duckdb@90e369144a115591007054ca0c7774f848df0cd6.

  Date: 2026-04-09 08:07:49 +0200

  Parquet writer: allow partial variant shredding in Parquet, instead of bailing out when a single struct field does not match (https://redirect.github.com/duckdb/duckdb/pull/21959)

- Update vendored sources to duckdb/duckdb@d13a3403b3ded9035a4ee84e9601138670ae51b5.

  Date: 2026-04-08 21:07:39 +0200

  Bump httpfs to include recent fixes, also adding new no-op setting (https://redirect.github.com/duckdb/duckdb/pull/21949)
  \[Dev\] Bump the `merge_vcpkg_deps` script to bump the baseline of the registry (https://redirect.github.com/duckdb/duckdb/pull/21950)

- Update vendored sources to duckdb/duckdb@16f83ee94b59a71c9bd63e15cde75e2b7968d71a.

  Date: 2026-04-08 21:01:05 +0200

  Make parser override work with parser extensions (https://redirect.github.com/duckdb/duckdb/pull/21761)

- Update vendored sources to duckdb/duckdb@0c06d2a2902f39ef4692d6630fedef110125c669.

  Date: 2026-04-08 20:25:16 +0200

  Fix Arrow union type_ids buffer ignoring chunk_offset (https://redirect.github.com/duckdb/duckdb/pull/21848)
  lance: bump lance-duckdb to 1b4ef68 (https://redirect.github.com/duckdb/duckdb/pull/21944)

- Update vendored sources to duckdb/duckdb@cc8c034da711afbf10a7a40f0669779d49a5f1b1.

  Date: 2026-04-08 20:15:31 +0200

  Fix incorrect results when using `try` within `if` (https://redirect.github.com/duckdb/duckdb/pull/21943)

- Update vendored sources to duckdb/duckdb@0fab542c84ca94657616e519cd679334dcbd86b1.

  Date: 2026-04-08 15:49:18 +0200

  Add HTTPUtil::CloseClient(...) with trivial no-op implementation, and base_url field to HTTPClient (https://redirect.github.com/duckdb/duckdb/pull/21924)

- Update vendored sources to duckdb/duckdb@1f9fe9e2c1eccabc0fda637959c0a52b4f4f44aa.

  Date: 2026-04-08 15:48:11 +0200

  Use `BLOB`, not `VARCHAR` for row group pruning (https://redirect.github.com/duckdb/duckdb/pull/21946)

- Update vendored sources to duckdb/duckdb@ab709835944d3e9f8e33e92758572bccca2c4c5c.

  Date: 2026-04-08 10:23:40 +0200

  Fix invalid memory access when CSV columns less than expected (https://redirect.github.com/duckdb/duckdb/pull/21822)

- Update vendored sources to duckdb/duckdb@e04217a09c51f4ef4311da5663385cddef0f6566.

  Date: 2026-04-08 10:03:20 +0200

  Run ArrowConverter::ToArrowSchema in a transaction (https://redirect.github.com/duckdb/duckdb/pull/21927)

- Update vendored sources to duckdb/duckdb@1ac9faba37e221a855d1bfbdc9d5caea98f58cf8.

  Date: 2026-04-08 09:42:45 +0200

  Improve geometry WKT parsing and add geometry to `test_all_types` v2 (https://redirect.github.com/duckdb/duckdb/pull/21805)

- Update vendored sources to duckdb/duckdb@3a30eb1fe82604dba63ada103e37990ffb3df07d.

  Date: 2026-04-08 09:42:29 +0200

  \[ART\] Fix information loss on index build cast (https://redirect.github.com/duckdb/duckdb/pull/21815)
  Issue https://redirect.github.com/duckdb/duckdb/pull/21907: Invalid Window Macros (https://redirect.github.com/duckdb/duckdb/pull/21929)

- Update vendored sources to duckdb/duckdb@438e3ffc8c3dbfda880f48dfe14ca32f303f096b.

  Date: 2026-04-08 08:21:03 +0200

  Fix common subplan optimizer bug (https://redirect.github.com/duckdb/duckdb/pull/21932)

- Update vendored sources to duckdb/duckdb@be656ba680c791f75f9912e1508772767257d665.

  Date: 2026-04-08 08:19:53 +0200

  Issue https://redirect.github.com/duckdb/duckdb/pull/21905: AGO Overflow Check (https://redirect.github.com/duckdb/duckdb/pull/21936)

- Update vendored sources to duckdb/duckdb@17491eb887600b0bdba5d87771e6e1c3c4749312.

  Date: 2026-04-07 18:52:45 +0200

  Fix in-place update to look only at updated columns (https://redirect.github.com/duckdb/duckdb/pull/21922)

- Update vendored sources to duckdb/duckdb@06960519a8e6b23e443ffa9290a09cba53c7470d.

  Date: 2026-04-07 18:52:17 +0200

  Merge `v1.4-andium` into `v1.5-variegata` (https://redirect.github.com/duckdb/duckdb/pull/21919)

- Update vendored sources to duckdb/duckdb@77547ac548f74d4fed09c3bfc00a1707604e7e8a.

  Date: 2026-04-07 16:33:56 +0200

  Fix is_histogram_other_bin handle null (https://redirect.github.com/duckdb/duckdb/pull/21841)

- Update vendored sources to duckdb/duckdb@54c0a64ad0743a042e253c2c6417d6284c73cd94.

  Date: 2026-04-07 16:33:45 +0200

  Fix CSV process over buffer out-of-bound access (https://redirect.github.com/duckdb/duckdb/pull/21840)

- Update vendored sources to duckdb/duckdb@afb273f2b684fd543a317445954ce417c7761014.

  Date: 2026-04-07 14:27:24 +0200

  vacuum_rebuild_indexes threshold setting (https://redirect.github.com/duckdb/duckdb/pull/21769)

- Update vendored sources to duckdb/duckdb@3445320521d0b44cdd5a5a1d5e85c00557e28280.

  Date: 2026-04-07 13:09:55 +0200

  AddToBeRescheduled: Avoid UB in assigning vs move (https://redirect.github.com/duckdb/duckdb/pull/21912)

- Update vendored sources to duckdb/duckdb@b6dd5b55c5818bee011fdd6f50156985f3bc535b.

  Date: 2026-04-07 12:14:03 +0200

  Bump Postgres, MySQL and SQLite (https://redirect.github.com/duckdb/duckdb/pull/21899)

- Update vendored sources to duckdb/duckdb@5c50ae787e7e2495d622e535dbbfe306627c1466.

  Date: 2026-04-07 10:48:52 +0200

  Issue https://redirect.github.com/duckdb/duckdb/pull/21820: TopN Window Projections (https://redirect.github.com/duckdb/duckdb/pull/21902)

- Update vendored sources to duckdb/duckdb@c241da23ae91f5cc0561a53800f3edddced79472.

  Date: 2026-04-06 22:32:17 +0200

  Fix geometry TextWriter corrupting coordinates in scientific notation (https://redirect.github.com/duckdb/duckdb/pull/21893)

- Update vendored sources to duckdb/duckdb@1518906e3dd39a0de7afe15ccbce7100a69b4b10.

  Date: 2026-04-06 22:26:06 +0200

  Fix case-sensitive default database check allowing detach of default database (https://redirect.github.com/duckdb/duckdb/pull/21863)

- Update vendored sources to duckdb/duckdb@21b84304b624749ee787b0bdeb50c75b595948fe.

  Date: 2026-04-06 10:15:13 +0200

  \[minor\] Fix CreateViewInfo::Copy() not copying names (https://redirect.github.com/duckdb/duckdb/pull/21819)

- Update vendored sources to duckdb/duckdb@1c28760a54a30553d6673da79b4977b6da6c9c56.

  Date: 2026-04-06 10:14:01 +0200

  Fix integer overflow crash in list repeat function (https://redirect.github.com/duckdb/duckdb/pull/21873)

- Update vendored sources to duckdb/duckdb@31883c66b907533ea9d8d554885506ca348475a4.

  Date: 2026-04-06 10:13:12 +0200

  Fix Arrow REE INT64 run_ends using wrong template parameter (https://redirect.github.com/duckdb/duckdb/pull/21847)

- Update vendored sources to duckdb/duckdb@cbc6f2230e53b51aa632b117a9722afa42f2a04f.

  Date: 2026-04-03 18:38:01 +0200

  Fix ADBC data race (https://redirect.github.com/duckdb/duckdb/pull/21800)

- Update vendored sources to duckdb/duckdb@3f2473d69d228f5f344bc07b99c9611164a054de.

  Date: 2026-04-03 10:33:10 +0200

  Add support for reading geometry type to the C-API (https://redirect.github.com/duckdb/duckdb/pull/21763)

- Update vendored sources to duckdb/duckdb@da322c1942b26c5784a63bd885402346f6f84831.

  Date: 2026-04-03 09:27:25 +0200

  Issue https://redirect.github.com/duckdb/duckdb/pull/21682: TopN Window Sets (https://redirect.github.com/duckdb/duckdb/pull/21775)

- Update vendored sources to duckdb/duckdb@eb28a2d78c2914594b7ed88ad785c4cc1841aafc.

  Date: 2026-04-03 09:22:07 +0200

  Fix TopN window elimination with external CTE refs (https://redirect.github.com/duckdb/duckdb/pull/21686)

- Update vendored sources to duckdb/duckdb@3c6acc741122173cb82364109588279c7574f89d.

  Date: 2026-04-03 08:44:56 +0200

  Expose HIDDEN as an ATTACH option (https://redirect.github.com/duckdb/duckdb/pull/21764)
  Bump test utils (https://redirect.github.com/duckdb/duckdb/pull/21795)

- Update vendored sources to duckdb/duckdb@e83a54c84917852e1fa743edf477c62d426f8c10.

  Date: 2026-04-03 08:38:58 +0200

  Bugfixes (https://redirect.github.com/duckdb/duckdb/pull/21793)

- Update vendored sources to duckdb/duckdb@3ac8769726f202b6b9338dcd94f911ffc8a31029.

  Date: 2026-04-03 08:38:38 +0200

  Disable bloom filter pushdown through casts (https://redirect.github.com/duckdb/duckdb/pull/21792)

- Update vendored sources to duckdb/duckdb@310d07d36d08217b5f2150efca6a6b2a12659191.

  Date: 2026-04-02 18:06:37 +0200

  Fix DELETE RETURNING for rows inserted in the same transaction (https://redirect.github.com/duckdb/duckdb/pull/21541)

- Update vendored sources to duckdb/duckdb@f34d3673cfe6087fe4437a44043fe66ce3844f1a.

  Date: 2026-04-02 14:12:38 +0200

  PEG parser strict mode: followup fixes and improvements (https://redirect.github.com/duckdb/duckdb/pull/21709)
  Bump spatial (https://redirect.github.com/duckdb/duckdb/pull/21781)

- Update vendored sources to duckdb/duckdb@10c4e2493ede91d9679e32528984a04c4d3a289e.

  Date: 2026-04-01 18:47:32 +0200

  Use correct error message for name conflicts between table and views (https://redirect.github.com/duckdb/duckdb/pull/21760)

- Update vendored sources to duckdb/duckdb@a0c4c47434bc3b4921b496a2d4038d4b2dba17cc.

  Date: 2026-04-01 13:20:22 +0200

  Re-instantiate dependencies of tables for `ALTER TABLE ... DROP COLUMN` and `ALTER TABLE .. SET DEFAULT` (https://redirect.github.com/duckdb/duckdb/pull/21752)

- Update vendored sources to duckdb/duckdb@086a1b85e774031ea36183c6fa9d14d4a4ad20cb.

  Date: 2026-04-01 10:46:18 +0200

  Fix update plans when deserializing if type no longer supports regular updates (https://redirect.github.com/duckdb/duckdb/pull/21718)

- Update vendored sources to duckdb/duckdb@269baca8ac00813d1c57fbaf12d89242860f4204.

  Date: 2026-04-01 10:20:51 +0200

  \[Variant\] Re-add the removed `variant_legacy_encoding` setting (https://redirect.github.com/duckdb/duckdb/pull/21710)

- Update vendored sources to duckdb/duckdb@f4cfd655152222e0bd268db3df3e88b38877d137.

  Date: 2026-04-01 08:21:11 +0200

  Allow join filter pushdown for NOP collations (https://redirect.github.com/duckdb/duckdb/pull/21742)

- Update vendored sources to duckdb/duckdb@bd5ed38448439501ebefb08364c10f341e541912.

  Date: 2026-04-01 08:20:46 +0200

  Allow join filter pushdown through integral up/down casts (https://redirect.github.com/duckdb/duckdb/pull/21743)

- Update vendored sources to duckdb/duckdb@699249af49001b6f9dd61f5e7b04b817c2373e4d.

  Date: 2026-03-31 20:49:01 +0200

  Fix prepared temp-table INSERT invalidation after DROP (https://redirect.github.com/duckdb/duckdb/pull/21712)
  Add clickbench (https://redirect.github.com/duckdb/duckdb/pull/21730)

- Update vendored sources to duckdb/duckdb@d4bbdda8e7c89c0e61582376617adbacbce6b297.

  Date: 2026-03-31 17:07:51 +0200

  Allow `SET DEFAULT / DROP DEFAULT` for tables that have dependencies (https://redirect.github.com/duckdb/duckdb/pull/21729)
  fix path test warnings (https://redirect.github.com/duckdb/duckdb/pull/21711)

- Update vendored sources to duckdb/duckdb@17dfffb4bbd29ad8c90e29c6d175b585517f6e72.

  Date: 2026-03-31 13:01:53 +0200

  Ignore `NULL`/`__HIVE_DEFAULT_PARTITION__` when detecting types (https://redirect.github.com/duckdb/duckdb/pull/21731)

- Update vendored sources to duckdb/duckdb@16de6a6358c62636217783c1c8eef9ce738e5cde.

  Date: 2026-03-31 10:32:49 +0200

  TopNWindowElimination fixes (https://redirect.github.com/duckdb/duckdb/pull/21663)

- Update vendored sources to duckdb/duckdb@df27220a52561abe4fd97ff834b5e96ccd0ab59e.

  Date: 2026-03-31 10:28:21 +0200

  Fix variant shredding consistency issue (https://redirect.github.com/duckdb/duckdb/pull/21715)
  Add missing test for delta byte array (https://redirect.github.com/duckdb/duckdb/pull/21714)

- Update vendored sources to duckdb/duckdb@59186b09dbb86f9c729be3c0f61d60db03764ee2.

  Date: 2026-03-31 09:40:41 +0200

  Internal https://redirect.github.com/duckdb/duckdb/pull/8657: IEJoin Filter Sides (https://redirect.github.com/duckdb/duckdb/pull/21721)
  Test runner: Support replacement without dollar (`{i}` instead of `${i}`) in loop iterators (https://redirect.github.com/duckdb/duckdb/pull/21708)

- Update vendored sources to duckdb/duckdb@f995d861b91cd0b3e91a7b5d16b2c9bd4ee914a4.

  Date: 2026-03-30 14:30:05 +0200

  Fix stoi crash in Arrow format string parsing for w: and +w: types (https://redirect.github.com/duckdb/duckdb/pull/21692)

- Update vendored sources to duckdb/duckdb@aad9569373f8093853c7268a21f6acbbcaa347f1.

  Date: 2026-03-30 13:20:25 +0200

  Disable regular updates for geometry (https://redirect.github.com/duckdb/duckdb/pull/21641)

- Update vendored sources to duckdb/duckdb@1fca3f5bda1ed608a7e394d733a29573d5348d08.

  Date: 2026-03-30 09:49:21 +0200

  Fix type check in `st_crs` (https://redirect.github.com/duckdb/duckdb/pull/21688)
  Internal https://redirect.github.com/duckdb/duckdb/pull/7568: ASOF SEMI Test (https://redirect.github.com/duckdb/duckdb/pull/21683)

- Update vendored sources to duckdb/duckdb@4b7b860448b156bb2d1d2e499bdf078b8dccf73a.

  Date: 2026-03-28 17:34:10 +0100

  Fix issue with struct filter on missing structs (https://redirect.github.com/duckdb/duckdb/pull/21676)

- Update vendored sources to duckdb/duckdb@5c76aa7388d2983698ac3f4f33cb8f0a7d26175a.

  Date: 2026-03-28 09:47:19 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/8553: Window TopN Except (https://redirect.github.com/duckdb/duckdb/pull/21671)
  CLI: Add .help shortcuts (https://redirect.github.com/duckdb/duckdb/pull/21662)

- Update vendored sources to duckdb/duckdb@9414d79c278820b735ed109a03b2192e15adc01a.

  Date: 2026-03-27 19:23:45 +0100

  Windows: remove prefix from canonical paths (https://redirect.github.com/duckdb/duckdb/pull/21652)
  Infer timestamps with timezone in read_json_auto (https://redirect.github.com/duckdb/duckdb/pull/21660)

- Update vendored sources to duckdb/duckdb@f39075402cc4e4a9ae2b16b0d0dec7e9068d02e0.

  Date: 2026-03-27 19:17:04 +0100

  Avoid throwing an error when failing to bind views in `duckdb_columns` (https://redirect.github.com/duckdb/duckdb/pull/21658)

- Update vendored sources to duckdb/duckdb@427ec890f62ca7ef5ddbe967b36eb30a2629ea2f.

  Date: 2026-03-27 10:10:05 +0100

  Warn instead of error when trying to persist geometry columns with CRS in old storage format (https://redirect.github.com/duckdb/duckdb/pull/21649)

- Update vendored sources to duckdb/duckdb@7a71122029637012d247b4ba13bdc7fc927bfec9.

  Date: 2026-03-27 10:09:08 +0100

  Re-organize WAL replay slightly, and correctly deal with empty checkpoint WAL files in WAL recovery (https://redirect.github.com/duckdb/duckdb/pull/21645)

- Update vendored sources to duckdb/duckdb@9b34451b8672f4c8234cde875bc8726a64cdfeeb.

  Date: 2026-03-27 10:03:21 +0100

  Fix some Parquet fuzzer issues (https://redirect.github.com/duckdb/duckdb/pull/21635)

- Update vendored sources to duckdb/duckdb@9716439083d5936e4415d1585cd08a7d58c614d9.

  Date: 2026-03-27 10:01:50 +0100

  fix(adbc): err use after free (https://redirect.github.com/duckdb/duckdb/pull/21605)
  Fix shell completion enter handling (https://redirect.github.com/duckdb/duckdb/pull/21552)

- Update vendored sources to duckdb/duckdb@57ad923e28c8da9f86c80a7d55d530201a5a389f.

  Date: 2026-03-27 10:01:03 +0100

  Fix cancellation order between pipelines and tasks in CancelTasks (https://redirect.github.com/duckdb/duckdb/pull/21642)
  bump delta and unity_catalog ext refs in v1.5-variegata (https://redirect.github.com/duckdb/duckdb/pull/21640)

- Update vendored sources to duckdb/duckdb@0af4de8529d7224d85d818f5ff70290d209282f3.

  Date: 2026-03-27 10:00:09 +0100

  Bump storage version to `v1.5.2` (https://redirect.github.com/duckdb/duckdb/pull/21638)

- Update vendored sources to duckdb/duckdb@78463ae581a2de6feeab22b8223e99ad4f727d81.

  Date: 2026-03-26 17:50:40 +0100

  Merge v1.4-andium into v1.5-variegata (https://redirect.github.com/duckdb/duckdb/pull/21639)
  Bump Julia to v1.5.1 (https://redirect.github.com/duckdb/duckdb/pull/21637)

- Update vendored sources to duckdb/duckdb@c31c13b5191f290d52fb4a013facf32943e42b0c.

  Date: 2026-03-26 10:15:17 +0100

  Issue https://redirect.github.com/duckdb/duckdb/pull/21592: Window Self-Join Framing (https://redirect.github.com/duckdb/duckdb/pull/21628)

- Update vendored sources to duckdb/duckdb@a10adfe1cfc0eec29ecc5fb00edaa633b2a1ffeb.

  Date: 2026-03-26 08:26:36 +0100

  Fix https://redirect.github.com/duckdb/duckdb/pull/21623: flatten input chunk in TopNHeap::CheckBoundaryValues (https://redirect.github.com/duckdb/duckdb/pull/21629)

- Update vendored sources to duckdb/duckdb@4d195b9091011b15c315a71edf20b53d74bf019a.

  Date: 2026-03-25 19:25:59 +0100

  Make PEG Parser use strict mode in CI (https://redirect.github.com/duckdb/duckdb/pull/21590)
  Windows shell: enable VT100 processing on startup (https://redirect.github.com/duckdb/duckdb/pull/21615)

- Update vendored sources to duckdb/duckdb@7f035faff2c6522652f38c5a13d48563eca7cb0b.

  Date: 2026-03-25 16:45:49 +0100

  fix unpivot serialization (https://redirect.github.com/duckdb/duckdb/pull/21595)
  Fixed an issue where the describe statement did not work correctly in markdown output mode(ISSUE:https://redirect.github.com/duckdb/duckdb/pull/21579) (https://redirect.github.com/duckdb/duckdb/pull/21611)

- Update vendored sources to duckdb/duckdb@0abaf6affbe8ff2cc954ac42980959b2d71d4962.

  Date: 2026-03-25 13:57:11 +0100

  Reduce arg_min_max_n heap preallocation (https://redirect.github.com/duckdb/duckdb/pull/21467)

- Update vendored sources to duckdb/duckdb@187d70c8d8a379afdd7eff1c8b7506986b9f4663.

  Date: 2026-03-25 13:56:15 +0100

  Segfault due to unchecked malloc/realloc, proposed fix to https://redirect.github.com/duckdb/duckdb/pull/21593 (https://redirect.github.com/duckdb/duckdb/pull/21594)

- Update vendored sources to duckdb/duckdb@8dabba981e642385edba005245b10b25adc8ac2d.

  Date: 2026-03-25 08:19:53 +0100

  Fix missing SetSizeAndFinalize in BIGNUM Add for zero result case (https://redirect.github.com/duckdb/duckdb/pull/21465)

- Update vendored sources to duckdb/duckdb@a1c258bffaf4c779ab9c0bcf671bb951c7dc8a6b.

  Date: 2026-03-25 07:58:50 +0100

  CLI: Avoid division by zero when formatting a large result with a non-wide shell (https://redirect.github.com/duckdb/duckdb/pull/21591)

- Update vendored sources to duckdb/duckdb@c23c958a93373335242bf9d852cd20cf2d53cbcf.

  Date: 2026-03-24 19:44:16 +0100

  Simplify the way we determine which row groups to checkpoint during checkpoints (https://redirect.github.com/duckdb/duckdb/pull/21574)
  Bump Julia to `v1.5.0` (https://redirect.github.com/duckdb/duckdb/pull/21588)
  lance: bump lance-duckdb to 4d9ecab (https://redirect.github.com/duckdb/duckdb/pull/21572)

- Update vendored sources to duckdb/duckdb@d319c1ac563652fa43d6ae7f8387a62d65bf8827.

  Date: 2026-03-24 07:48:28 +0100

  TopNWindowElimination Column Binding Fix (https://redirect.github.com/duckdb/duckdb/pull/21564)
  Fix data path in `test/sql/copy/parquet/parquet_no_stats.test` (https://redirect.github.com/duckdb/duckdb/pull/21561)

- Update vendored sources to duckdb/duckdb@158e58902b7a79438c777adba8504abc75b2eb68.

  Date: 2026-03-23 20:41:53 +0100

  \[v1.5-variegata\] Fix https://redirect.github.com/duckdb/duckdb/pull/21514: ASOF join empty right (https://redirect.github.com/duckdb/duckdb/pull/21553)
  PEG grammar fixes: Update extension and allow numeric struct keys (https://redirect.github.com/duckdb/duckdb/pull/21331)
  Fix missing extension static libs in Windows MinGW bundle (https://redirect.github.com/duckdb/duckdb/pull/21559)

- Update vendored sources to duckdb/duckdb@8e4434290eb06c0f6e63eafc45cebd4e2e41be6e.

  Date: 2026-03-23 14:35:02 +0100

  Correctly deal with negative values in `GetPosixVersionTag`, and fix constant `NULL` struct scans after recent fix (https://redirect.github.com/duckdb/duckdb/pull/21549)

- Update vendored sources to duckdb/duckdb@710adf3d0587022701c56f0b83fc60011f57efff.

  Date: 2026-03-21 09:57:35 +0100

  Unify adding suffixes to path in `Path:: AddSuffixToPath` - fix temp directory split bug (https://redirect.github.com/duckdb/duckdb/pull/21527)
  Add setting for limiting the number of threads launched concurrently in the test runner (`max_test_threads`) (https://redirect.github.com/duckdb/duckdb/pull/21520)
  Fix parsing test path to skip (https://redirect.github.com/duckdb/duckdb/pull/21495)
  Fix https://redirect.github.com/duckdb/duckdb/pull/21512: correctly render empty results in .mode json (https://redirect.github.com/duckdb/duckdb/pull/21517)

- Update vendored sources to duckdb/duckdb@0e4246989b825cc5a82434d5daee6ffcbdd59518.

  Date: 2026-03-20 16:03:15 +0100

  Fixing integer overflow in list_resize (https://redirect.github.com/duckdb/duckdb/pull/21515)
  Reduce concurrent thread count in test (https://redirect.github.com/duckdb/duckdb/pull/21511)

- Update vendored sources to duckdb/duckdb@6ff3b4f26cc9a916896f89167922704296ef9b6a.

  Date: 2026-03-20 12:52:52 +0100

  Make some MultiStatements and PRAGMAs Transactional (https://redirect.github.com/duckdb/duckdb/pull/21171)

- Update vendored sources to duckdb/duckdb@4c959e279e1964d2b83ee518e3b92d030a13f2bb.

  Date: 2026-03-20 10:15:04 +0100

  Fix memory leak when reusing PreparedStatement (https://redirect.github.com/duckdb/duckdb/pull/21089) (https://redirect.github.com/duckdb/duckdb/pull/21104)

- Update vendored sources to duckdb/duckdb@0bc00ee4ee8a4b38cfcce75d10c8ca7b3ea79de0.

  Date: 2026-03-20 09:58:49 +0100

  Fixup Write bytes are counted as BYTES_WRITTEN (https://redirect.github.com/duckdb/duckdb/pull/21501)

- Update vendored sources to duckdb/duckdb@58ca1c705c509439d06646b7d46fa7831bbb157e.

  Date: 2026-03-20 08:35:57 +0100

  Add descriptions for vortex and lance (https://redirect.github.com/duckdb/duckdb/pull/21500)

- Update vendored sources to duckdb/duckdb@31ea662805538434b10bb4b914f3343793359265.

  Date: 2026-03-19 22:57:47 +0100

  Correctly revert dictionary size when reverting string appends (https://redirect.github.com/duckdb/duckdb/pull/21489)

## Bug fixes

- Fix compiler warning on recent clang on macOS.

## Features

- Use `TRY_CAST()` instead of `CAST()` in dplyr SQL translation for type conversion functions (#2230, #2231).

## Chore

- Use R_getRegisteredNamespace() in R 4.6.

- Further minimize difference with flavors.

- Avoid spurious changes in `.dd` files.

- More precise ignore rules to avoid vendoring error.

- Record preference.

- Format.

## Continuous integration

- Results from revdepchecks.

- Add more permissions to repo.

- Explicit permissions.

- Avoid starting workflows targeting the fork.

- Align vendoring with igraph.

- Copy LTS infrastructure.

- Fix sed usage.

- Stabilize dev version test.

- Bump versions during vendoring.

- Use links that do not trigger a backlink.

- Fix fledge workflow.

- Fix vendoring.

- Do not run fledge on duckdb non-fork.

## Documentation

- Describe branching strategy (#2280, #2281).

## Testing

- Skip arrow tests for flavors.

- Arrow tests need duckdb package, not a flavor.

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
