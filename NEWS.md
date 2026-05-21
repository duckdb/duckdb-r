<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# duckdb 1.5.2.9900

## vendor

- Update vendored sources (tag v1.5.3) to duckdb/duckdb@14eca11bd9d4a0de2ea0f078be588a9c1c5b279c.

  Date: 2026-05-19 12:31:49 +0200

- Update vendored sources to duckdb/duckdb@14eca11bd9d4a0de2ea0f078be588a9c1c5b279c.

  Return an error if a negative number is passed to the factorial function (https://redirect.github.com/duckdb/duckdb/pull/22731)

- Update vendored sources to duckdb/duckdb@67af30b260d7f0d8ad33092fc8e45a2ee87946c0.

  Date: 2026-05-19 12:31:10 +0200

  RowGroupPruner: treat UNSET LIMIT as unbounded (https://redirect.github.com/duckdb/duckdb/pull/22744)
  Revert "Enable jemalloc heap profiling with the libgcc unwinder" (https://redirect.github.com/duckdb/duckdb/pull/22740)
  Fix .sanitizer-thread-suppressions.txt jemalloc ref (https://redirect.github.com/duckdb/duckdb/pull/22736)

- Update vendored sources to duckdb/duckdb@86b213eedc34a381b04f283688c2caa8f5f194b1.

  Date: 2026-05-18 15:42:53 +0200

  fix: list_zip SEGFAULT with empty / NULL argument (https://redirect.github.com/duckdb/duckdb/pull/22726)

- Update vendored sources to duckdb/duckdb@e7f11df43904c7b53923f66ca3afa0fd86032ba9.

  Date: 2026-05-18 14:56:17 +0200

  bump iceberg again (https://redirect.github.com/duckdb/duckdb/pull/22723)
  Bump quack, fixes quack_serve on wasm (https://redirect.github.com/duckdb/duckdb/pull/22722)

- Update vendored sources to duckdb/duckdb@0a1b8db835b6ac48227d30c56d1aba6af510bb8f.

  Date: 2026-05-18 14:55:37 +0200

  Fix iterator invalidation in ConnectionManager::GetConnectionList (https://redirect.github.com/duckdb/duckdb/pull/22719)
  Fix GCC jemalloc symbol leakage CI failure (https://redirect.github.com/duckdb/duckdb/pull/22729)

- Update vendored sources to duckdb/duckdb@7e8efa63076c87291e8db3dadc2b65663bae4548.

  Date: 2026-05-18 09:20:03 +0200

  Make several storage internals public (https://redirect.github.com/duckdb/duckdb/pull/22718)

- Update vendored sources to duckdb/duckdb@a3e42622fa6c742d5774c4019a543e64e9818a6d.

  Date: 2026-05-18 09:00:52 +0200

  Fix jemalloc thread flush threshold check (https://redirect.github.com/duckdb/duckdb/pull/22670)
  Enable jemalloc heap profiling with the libgcc unwinder (https://redirect.github.com/duckdb/duckdb/pull/22630)

- Update vendored sources to duckdb/duckdb@b25ebaadb665ee38f74b5bbbb309fadc59e096d8.

  Date: 2026-05-17 18:46:55 +0200

  Fix timer lifetime/timing issues (https://redirect.github.com/duckdb/duckdb/pull/22697)
  Bump DuckLake (https://redirect.github.com/duckdb/duckdb/pull/22698)

- Update vendored sources to duckdb/duckdb@54d39a64e8ebc576643dbd8e89917408f29720e6.

  Date: 2026-05-15 22:53:09 +0200

  Fix new jemalloc plumbing (https://redirect.github.com/duckdb/duckdb/pull/22628)

- Update vendored sources to duckdb/duckdb@12b465c3a56adee7f7ccad18e60d8c8c58ea5e54.

  Date: 2026-05-15 18:17:15 +0200

  Fix max file row number (https://redirect.github.com/duckdb/duckdb/pull/22688)

- Update vendored sources to duckdb/duckdb@a5f098cbd7520060d8994e692b18ac49c0a640a1.

  Date: 2026-05-15 14:56:25 +0200

  Add `write_buffer_row_group_memory_limit` setting which controls when to flush row groups based on memory instead of only based on row group count (https://redirect.github.com/duckdb/duckdb/pull/22666)

- Update vendored sources to duckdb/duckdb@fafb148e3bb7decd91e39fcaea80ad84c23e4f35.

  Date: 2026-05-15 09:32:41 +0200

  Fix enum type write to parquet (https://redirect.github.com/duckdb/duckdb/pull/22677)

- Update vendored sources to duckdb/duckdb@2b0cf017e25efd4fe434dddba4eeed5787f477d1.

  Date: 2026-05-15 09:32:16 +0200

  Fix invalid access for file row number (https://redirect.github.com/duckdb/duckdb/pull/22662)
  Bump quack (https://redirect.github.com/duckdb/duckdb/pull/22659)
  Add dummy cmake target for jemalloc (https://redirect.github.com/duckdb/duckdb/pull/22632)

- Update vendored sources to duckdb/duckdb@5066a05e8615c1ac06de018a65043687571d2395.

  Date: 2026-05-14 10:43:02 +0200

  Fix free block for temporary file manageer (https://redirect.github.com/duckdb/duckdb/pull/22616)
  Bump sqlsmith, remove patch (https://redirect.github.com/duckdb/duckdb/pull/22622)
  Bump excel / remove patch (https://redirect.github.com/duckdb/duckdb/pull/22633)

- Update vendored sources to duckdb/duckdb@5c05c5552bb0faa1eebac70d568ee6f4edc6b3d7.

  Date: 2026-05-14 08:27:30 +0200

  optimizer: don't return truncated VARCHAR MIN/MAX from statistics (https://redirect.github.com/duckdb/duckdb/pull/22538)
  bump avro+iceberg+vcpkg-duckdb-ports (https://redirect.github.com/duckdb/duckdb/pull/22621)
  bump aws extension (https://redirect.github.com/duckdb/duckdb/pull/22623)

- Update vendored sources to duckdb/duckdb@885f55812deae3b5b6773fa221b650fb61954e20.

  Date: 2026-05-14 08:26:00 +0200

  Add quack autoloading (https://redirect.github.com/duckdb/duckdb/pull/22631)

- Update vendored sources to duckdb/duckdb@02d05e56481b8f52c2cdad8241c13196fd891011.

  Date: 2026-05-14 08:25:02 +0200

  Add storage informations for v1.5.3 (https://redirect.github.com/duckdb/duckdb/pull/22638)
  Bump lance to 533e0ee6cf419e4be2af3af56182fb04b87978e1 (https://redirect.github.com/duckdb/duckdb/pull/22640)
  Bump DuckLake for release (https://redirect.github.com/duckdb/duckdb/pull/22651)
  parser_tools is apparently now a dependency for postgres (https://redirect.github.com/duckdb/duckdb/pull/22619)

- Update vendored sources to duckdb/duckdb@bcb51f03da803b73ee9822f6c0894ce3dd540946.

  Date: 2026-05-13 11:00:33 +0200

  CUMULATIVE_VACUUM_TIME metric (https://redirect.github.com/duckdb/duckdb/pull/22425)

- Update vendored sources to duckdb/duckdb@41ba031f28d26f320d76b8c2304f4da81e1baca3.

  Date: 2026-05-13 08:52:56 +0200

  bump iceberg (https://redirect.github.com/duckdb/duckdb/pull/22608)

- Update vendored sources to duckdb/duckdb@10296ce48b99eca522ffbea02b44f99997793c1c.

  Date: 2026-05-13 08:52:43 +0200

  Jemalloc is not an extension anymore (https://redirect.github.com/duckdb/duckdb/pull/22603)

- Update vendored sources to duckdb/duckdb@6b290ddbed2d233d35b0b9d1a5ac5ea3f3f30c8b.

  Date: 2026-05-13 08:52:32 +0200

  bump spatial again (https://redirect.github.com/duckdb/duckdb/pull/22602)

- Update vendored sources to duckdb/duckdb@1d9b65aa6c2dcde6fcb842242f12f6eed4dbbe21.

  Date: 2026-05-13 08:52:13 +0200

  Bump AWS extension (https://redirect.github.com/duckdb/duckdb/pull/22600)
  Enable/disable jemalloc linking through BUILD/SKIP_EXTENSIONS (https://redirect.github.com/duckdb/duckdb/pull/22594)

- Update vendored sources to duckdb/duckdb@6af901ce9e94e537ca13e90a801a2deaac8271ba.

  Date: 2026-05-13 08:51:43 +0200

  ARTOperator::Delete return false if rowid not found in nested ART leaf (https://redirect.github.com/duckdb/duckdb/pull/22591)
  Limit parallel linker jobs to avoid out-of-memory errors (https://redirect.github.com/duckdb/duckdb/pull/22588)
  Allow json ts format variation across columns - issue 22103 (https://redirect.github.com/duckdb/duckdb/pull/22559)

- Update vendored sources to duckdb/duckdb@fe0954a4753cf93be69dbdf80a0e826e9193f241.

  Date: 2026-05-12 15:38:16 +0200

  Move Jemalloc into core (https://redirect.github.com/duckdb/duckdb/pull/22558)

- Update vendored sources to duckdb/duckdb@e0cd083dd54312fc1baba09d512fdfd457ee8980.

  Date: 2026-05-12 14:42:16 +0200

  Fix incorrect profiling results when using `LIMIT` (https://redirect.github.com/duckdb/duckdb/pull/22561)

- Update vendored sources to duckdb/duckdb@b5614c8f445f1f079d9dd316a0763e747cc36dc8.

  Date: 2026-05-12 09:39:58 +0200

  Fix for SIGABRT in setting size on zero-capacity vector (https://redirect.github.com/duckdb/duckdb/pull/22571)

- Update vendored sources to duckdb/duckdb@e1ea8bd3dff8bfbcb218229f1ca2150952bbb819.

  Date: 2026-05-12 09:37:08 +0200

  Fix variant selection vector index (https://redirect.github.com/duckdb/duckdb/pull/22573)

- Update vendored sources to duckdb/duckdb@a42060bbab6e86c9889f9185c079d23ad4a8c803.

  Date: 2026-05-12 09:34:57 +0200

  Bump avro, azure, delta, ducklake, spatial, unity_catalog and vortex (https://redirect.github.com/duckdb/duckdb/pull/22554)

- Update vendored sources to duckdb/duckdb@cf73ab40ac218ca992c9ae71703a7f5101890e46.

  Date: 2026-05-12 09:34:14 +0200

  Bump Postgres, MySQL and ODBC (https://redirect.github.com/duckdb/duckdb/pull/22579)
  Bump httpfs and remove patches (https://redirect.github.com/duckdb/duckdb/pull/22556)

- Update vendored sources to duckdb/duckdb@46a672fe7634c694758bbef681e124c593c1e078.

  Date: 2026-05-11 15:41:34 +0200

  Move http_proxy setting to global setting, and use GetEnvVariable('HTTP_PROXY') as default (https://redirect.github.com/duckdb/duckdb/pull/22541)

- Update vendored sources to duckdb/duckdb@497026f559ac41d17804596ca45ef6432cfd6fc1.

  Date: 2026-05-11 14:25:40 +0200

  Fix variant write small decimal (https://redirect.github.com/duckdb/duckdb/pull/22544)

- Update vendored sources to duckdb/duckdb@407ba676d9182701a02fe85efb3f1e33b6cbc3be.

  Date: 2026-05-11 12:58:18 +0200

  ExtensionInstall: Remove use of IsHTTP to IsRemoteFile (https://redirect.github.com/duckdb/duckdb/pull/21900)

- Update vendored sources to duckdb/duckdb@926cc3e52016cc872f128b659bbb6b45a1b7299e.

  Date: 2026-05-11 08:48:59 +0200

  Fix parquet metadata cache validation (https://redirect.github.com/duckdb/duckdb/pull/22547)

- Update vendored sources to duckdb/duckdb@f0e766afcbcaaa3294ac689b2ba2ebd3f226f363.

  Date: 2026-05-11 08:48:33 +0200

  Fix bare numeric interval parsing at end of string on v1.5 (https://redirect.github.com/duckdb/duckdb/pull/22534)
  Test runner: avoid running clean-up routine if there is no database to run it in (https://redirect.github.com/duckdb/duckdb/pull/22540)

- Update vendored sources to duckdb/duckdb@a403fd8acf84f2a2ebcc2b61dd17f725959ca2f2.

  Date: 2026-05-10 08:34:57 +0200

  Fix duck fuzz https://redirect.github.com/duckdb/duckdb/pull/4430 (https://redirect.github.com/duckdb/duckdb/pull/22435)

- Update vendored sources to duckdb/duckdb@19678b66e7d2f9b3a471fbaff9c7c78cf06562ae.

  Date: 2026-05-10 08:29:52 +0200

  Patch httplib by making ThreadPool constructor more solid on pthread_create failures (https://redirect.github.com/duckdb/duckdb/pull/22516)

- Update vendored sources to duckdb/duckdb@6b8d5bc3b05b2a0360e5cb1a67a888c69d401a3c.

  Date: 2026-05-09 11:29:30 +0200

  Fix BlockAllocator invalid memory access (https://redirect.github.com/duckdb/duckdb/pull/22503)

- Update vendored sources to duckdb/duckdb@e1649edb0e0aad006330fb01121de1e900c138eb.

  Date: 2026-05-08 13:22:05 +0200

  Fix RESET my_global_extension_setting to actually be GLOBAL (https://redirect.github.com/duckdb/duckdb/pull/22520)

- Update vendored sources to duckdb/duckdb@c5b5b98e4a7eb63e99bb388989a2d597cd14d232.

  Date: 2026-05-08 10:49:56 +0200

  Avoid 3 instances of idx_t - idx_t \> 0, and avoid unnecessary check on zLine (https://redirect.github.com/duckdb/duckdb/pull/22518)

- Update vendored sources to duckdb/duckdb@8c4336c767fb7011262da76d14865ae0176f8395.

  Date: 2026-05-08 08:29:27 +0200

  Fix enable_logging() silently resetting logging_storage (https://redirect.github.com/duckdb/duckdb/pull/22475)

- Update vendored sources to duckdb/duckdb@2a172f10f417db21cc1b630f45b4615e268b2c7f.

  Date: 2026-05-04 08:46:17 +0200

  Fix eviction size metrics report (https://redirect.github.com/duckdb/duckdb/pull/22452)

  R-side fix

- Update vendored sources to duckdb/duckdb@2b52d7e8426379244bfa26abe952f19d7b41050b.

  Date: 2026-05-01 16:26:54 +0200

  PostgreSQL compatability: in `pg_catalog.pg_database` simulate columns datallowconn, datistemplate (https://redirect.github.com/duckdb/duckdb/pull/22302)

- Update vendored sources to duckdb/duckdb@a34c90c22926670a6e0a9fa9c483b8b137080768.

  Date: 2026-05-01 10:52:07 +0200

  RowGroup Operator metrics: sequentially scanned row groups + total row groups + cumulative counterparts (https://redirect.github.com/duckdb/duckdb/pull/22339)

- Update vendored sources to duckdb/duckdb@3668a8b7d8e04eadb3b97bf50ec03dda26594cbc.

  Date: 2026-05-01 07:55:45 +0200

  Fix double decrement of evicted_data_per_tag in .block read-back (https://redirect.github.com/duckdb/duckdb/pull/22394)

- Update vendored sources to duckdb/duckdb@f34fc4e707488546668b7e1a2045f40a9b2253d3.

  Date: 2026-04-30 17:27:13 +0200

  GetLocalFileSystem improvements (https://redirect.github.com/duckdb/duckdb/pull/21983)

- Update vendored sources to duckdb/duckdb@6aa4a592ed65e39b681440a31ab051f4f9c4edab.

  Date: 2026-04-30 15:43:16 +0200

  Downcasting decimal fix incorrect out of range error (https://redirect.github.com/duckdb/duckdb/pull/22386)

- Update vendored sources to duckdb/duckdb@045e1c237c2b05ee696f2983be3b01f76899268a.

  Date: 2026-04-30 08:39:16 +0200

  Internal https://redirect.github.com/duckdb/duckdb/pull/9003: TIMETZ Parsing Limit (https://redirect.github.com/duckdb/duckdb/pull/22378)
  Enable windows_amd64 for lance extension (https://redirect.github.com/duckdb/duckdb/pull/22367)

- Update vendored sources to duckdb/duckdb@ebe47ec0c7c1ef341012ac363cfc8282f5dbf3d9.

  Date: 2026-04-29 13:09:20 +0200

  Node Handle Scoping fix (https://redirect.github.com/duckdb/duckdb/pull/22344)

- Update vendored sources to duckdb/duckdb@81d70e84d27042d31e31c0223120747702773639.

  Date: 2026-04-28 22:23:39 +0200

  First initialize system, then load extensions (to peek at file to be opened) (https://redirect.github.com/duckdb/duckdb/pull/22341)

- Update vendored sources to duckdb/duckdb@a3365e21c7cf8853cf6e25d9fd2efe0506e0475f.

  Date: 2026-04-28 17:59:14 +0200

  Also redacting bearer token for HTTP secrets (https://redirect.github.com/duckdb/duckdb/pull/22323)

- Update vendored sources to duckdb/duckdb@a595c8108a556914ff1fbbde369ae2df4fd68387.

  Date: 2026-04-28 17:40:23 +0200

  Use batch limit for table scans with filters (https://redirect.github.com/duckdb/duckdb/pull/22315)

- Update vendored sources to duckdb/duckdb@3226146c2c25df5a1f13d58895ac9e70772f67ab.

  Date: 2026-04-28 14:26:14 +0200

  Skip schema analysis even if no shredding for rowgroup (https://redirect.github.com/duckdb/duckdb/pull/21937)

- Update vendored sources to duckdb/duckdb@bfd3b60f833e45974aba237b2d18b41c0d0e3de9.

  Date: 2026-04-28 14:25:25 +0200

  Exception format: accept string literals (https://redirect.github.com/duckdb/duckdb/pull/22314)

- Update vendored sources to duckdb/duckdb@54285de033e4abe200354465e4bdd6c3dcd7c8bb.

  Date: 2026-04-28 11:44:16 +0200

  Bump httpfs (https://redirect.github.com/duckdb/duckdb/pull/22312)
  Fix UTC+HHMM time zone was parsed incorrectly (https://redirect.github.com/duckdb/duckdb/pull/22297)

- Update vendored sources to duckdb/duckdb@4337c06de543a904b98b891dcfb821e9d8141b4d.

  Date: 2026-04-28 09:08:09 +0200

  Allow package builds to choose linked extensions (https://redirect.github.com/duckdb/duckdb/pull/22305)

- Update vendored sources to duckdb/duckdb@ca12adf671f9ff7c292e6bee7608a6e70fef295a.

  Date: 2026-04-26 09:08:41 +0200

  \[v1.5\] Backport ADBC memleak fix on error path (https://redirect.github.com/duckdb/duckdb/pull/22216)

- Update vendored sources to duckdb/duckdb@5909259229afa28a33cee6075dc37fa602477325.

  Date: 2026-04-26 09:08:16 +0200

  Defer Bloom Filter Pushdown until it's done (https://redirect.github.com/duckdb/duckdb/pull/22218)

- Update vendored sources to duckdb/duckdb@f0413bfa84f07975a199013cd87ea04b76eb5fb9.

  Date: 2026-04-25 15:20:22 +0200

  Fix UTC±NN00 cannot be parsed in SQL (https://redirect.github.com/duckdb/duckdb/pull/22244)

- Update vendored sources to duckdb/duckdb@e5cda4269e90eb78f588d84be65d3b4c1267a468.

  Date: 2026-04-24 14:15:45 +0200

  Fix: release ParquetReader when a file is marked SKIPPED in multi-file scan (https://redirect.github.com/duckdb/duckdb/pull/22261)

- Update vendored sources to duckdb/duckdb@327cde95f8851c4c35819705f077ac94d42d9f5e.

  Date: 2026-04-24 07:09:56 +0200

  Correctly use new row group when checkpointing, and avoid incorrectly re-using metadata when targeting older storage versions and row ids have changed (https://redirect.github.com/duckdb/duckdb/pull/22253)
  Bump httpfs to 3139e40a (https://redirect.github.com/duckdb/duckdb/pull/22248)

- Update vendored sources to duckdb/duckdb@c7d9746e53f65141c4a90333b127d3204be344e3.

  Date: 2026-04-23 19:30:34 +0200

  \[Bugfix\] Reset pg_err_pos in pg_parser_init to prevent stale error position leaking (https://redirect.github.com/duckdb/duckdb/pull/22239)

- Update vendored sources to duckdb/duckdb@c5a6bd6a959007c085ae59a169cb631f5672e138.

  Date: 2026-04-22 18:46:00 +0200

  ISSUE-22061: Fix JSON shell output: emit BOOLEAN as true/false, not strings (https://redirect.github.com/duckdb/duckdb/pull/22073)

- Update vendored sources to duckdb/duckdb@0cdd742a2dd18653e6c269e4e2e5d3b7efe074d3.

  Date: 2026-04-22 18:45:26 +0200

  CompressedFile::Close -\> calls Close on its child_handle (https://redirect.github.com/duckdb/duckdb/pull/22149)

- Update vendored sources to duckdb/duckdb@e9ed5ba311172f7bba3bd52601e31269d75c379e.

  Date: 2026-04-22 13:51:44 +0200

  Fix bignum sum Combine to correctly take over memory ownership of state (https://redirect.github.com/duckdb/duckdb/pull/22209)

- Update vendored sources to duckdb/duckdb@62e7f0dddf75559584c862430c642efbdeb1c161.

  Date: 2026-04-22 11:03:11 +0200

  User-facing `enable_caching_operators` setting (https://redirect.github.com/duckdb/duckdb/pull/22191)

- Update vendored sources to duckdb/duckdb@a1fc7abe20d48df3e860d9e895b694ebd902b0cc.

  Date: 2026-04-21 15:23:09 +0200

  Fix union_by_name remap for non-nested parquet columns (https://redirect.github.com/duckdb/duckdb/pull/22177)

- Update vendored sources to duckdb/duckdb@a04d20515f80050ff44d1d6f5f968fa0b07f957d.

  Date: 2026-04-21 10:52:00 +0200

  Fix CSV escape (https://redirect.github.com/duckdb/duckdb/pull/22176)

- Update vendored sources to duckdb/duckdb@12002785c2ddb503b5984dca2521c06a75de0eb5.

  Date: 2026-04-21 10:11:14 +0200

  Fix: Add pg_catalog.pg_collation compatibility view for SQLAlchemy 2.0.45 reflection (https://redirect.github.com/duckdb/duckdb/pull/22160)

- Update vendored sources to duckdb/duckdb@84ada11a172b49f7089a038e262351c35a8419f2.

  Date: 2026-04-21 10:08:28 +0200

  Use the latest storage version for temp storage (https://redirect.github.com/duckdb/duckdb/pull/22169)

- Update vendored sources to duckdb/duckdb@a69c5db54d7859a1f4275b3d5bb95c27efe9e633.

  Date: 2026-04-21 09:43:20 +0200

  Account for ROW_GROUP_SIZE when deciding whether to append to an existing row group (https://redirect.github.com/duckdb/duckdb/pull/22109)

- Update vendored sources to duckdb/duckdb@f0a077649b1d6a881e56f25d1c05ca232b48c868.

  Date: 2026-04-20 21:37:24 +0200

  Fix window self join optimizer (https://redirect.github.com/duckdb/duckdb/pull/22164)

- Update vendored sources to duckdb/duckdb@bfbe1fb8f736fd2f98389a5b42a04f68c0d523a8.

  Date: 2026-04-20 15:46:52 +0200

  Also execute auto-rollback on CLI ClientContext::Query() query (https://redirect.github.com/duckdb/duckdb/pull/22159)

- Update vendored sources to duckdb/duckdb@b7ca2c99e5d62c9f39aee5b9e39e844c72c79e69.

  Date: 2026-04-20 14:22:55 +0200

  \[v1.5 patch\] Attempt to fix cache read (https://redirect.github.com/duckdb/duckdb/pull/22126)

- Update vendored sources to duckdb/duckdb@1f4fa8d125e8500c4d5d6fcc396bff6e62acceeb.

  Date: 2026-04-20 09:24:18 +0200

  fix(adbc): report the table name if the table doesn't exist when appending (https://redirect.github.com/duckdb/duckdb/pull/22146)

- Update vendored sources to duckdb/duckdb@d7662bfbac3c52748781d3432b99bddb2d728e0b.

  Date: 2026-04-20 09:23:24 +0200

  Correctly skip preprocessing PIVOT MultiStatements (https://redirect.github.com/duckdb/duckdb/pull/22141)

- Update vendored sources to duckdb/duckdb@fd11c808ae66f6515cc9b977330d607765907a56.

  Date: 2026-04-20 09:19:50 +0200

  Fix Row Group Pruner Distinct Bug (https://redirect.github.com/duckdb/duckdb/pull/22132)
  Only build plan_serializer when building the main DuckDB library (https://redirect.github.com/duckdb/duckdb/pull/22100)

- Update vendored sources to duckdb/duckdb@fb72e45f6256d96b5f064242795284cf46357072.

  Date: 2026-04-20 08:55:39 +0200

  Internal https://redirect.github.com/duckdb/duckdb/pull/8812: From TIMESTAMPTZ Casts (https://redirect.github.com/duckdb/duckdb/pull/22000)

- Update vendored sources to duckdb/duckdb@00beb59aed8adeb10212d2297942db6162891bc5.

  Date: 2026-04-17 13:29:30 +0200

  fix commit iteration offset bug + relax RemoveFromIndexes assertion (https://redirect.github.com/duckdb/duckdb/pull/22094)
  Bump Julia to v1.5.2 (https://redirect.github.com/duckdb/duckdb/pull/22121)

- Update vendored sources to duckdb/duckdb@a343d23a963ade56acdcd52df1c556dc78e8bce2.

  Date: 2026-04-16 18:50:31 +0200

  Add support for reading `VARIANT` using C API (https://redirect.github.com/duckdb/duckdb/pull/22065)

- Update vendored sources to duckdb/duckdb@8cc999c7b9e1535009934e65365208ecb41ed2f8.

  Date: 2026-04-16 15:52:29 +0200

  Issue https://redirect.github.com/duckdb/duckdb/pull/22096: TopN Window Casts (https://redirect.github.com/duckdb/duckdb/pull/22098)

- Update vendored sources to duckdb/duckdb@ae80e871fa040e1a38600efe01c4d90f86240ceb.

  Date: 2026-04-16 15:10:58 +0200

  Fix empty parquet child schema (https://redirect.github.com/duckdb/duckdb/pull/22105)

- Update vendored sources to duckdb/duckdb@f35db8881aa90254aa92e1e9d5291c89b0a831eb.

  Date: 2026-04-16 09:17:31 +0200

  Row group append (https://redirect.github.com/duckdb/duckdb/pull/22060)

- Update vendored sources to duckdb/duckdb@67fe1eed4f8111d8d7c81541fe8770ab9ce614bd.

  Date: 2026-04-16 09:08:36 +0200

  Coorporative tasks might lead to busy spinning in `TaskExecutor::WorkOnTasks` (https://redirect.github.com/duckdb/duckdb/pull/22092)

- Update vendored sources to duckdb/duckdb@038fb6b79cda3fdb86b67170dca53ab8f375677f.

  Date: 2026-04-15 14:18:14 +0200

  Set `query` field for statements in `ALTER TABLE ... ADD COLUMN ... DEFAULT ...` workaround (https://redirect.github.com/duckdb/duckdb/pull/22057)

- Update vendored sources to duckdb/duckdb@48f850fde1eb1e1e710dce9e08713534e34fd6f6.

  Date: 2026-04-15 08:39:36 +0200

  Add `DISABLE_BUILTIN_HTTPLIB` option (https://redirect.github.com/duckdb/duckdb/pull/22054)
  Avoid handling Ctrl+C during shutdown (state might be already gone) (https://redirect.github.com/duckdb/duckdb/pull/22059)

- Update vendored sources to duckdb/duckdb@6bc307847b51c5571859e2361c610b2a41099300.

  Date: 2026-04-14 15:25:06 +0200

  Fix constant struct args in lateral table in-out functions (https://redirect.github.com/duckdb/duckdb/pull/21827)
  Git-ignore generated extension loader (https://redirect.github.com/duckdb/duckdb/pull/22056)

- Update vendored sources to duckdb/duckdb@531f5f2dd93b32c42f89808f6d6e737d9893684c.

  Date: 2026-04-14 14:54:33 +0200

  Fix `INSERT OR REPLACE BY NAME` regression by excluding conflict columns from `SET` list (https://redirect.github.com/duckdb/duckdb/pull/22049)

- Update vendored sources to duckdb/duckdb@a0a08d511d82b20e5855f8e9e6b01d81d70025b5.

  Date: 2026-04-13 22:24:17 +0200

  Fix DISABLE_EXTENSION_LOAD (https://redirect.github.com/duckdb/duckdb/pull/22019)

- Update vendored sources to duckdb/duckdb@0e8047bc28ae45dc7cc44f9210eff26e82fc8b7c.

  Date: 2026-04-13 22:20:27 +0200

  Add iceberg copy function autoload (https://redirect.github.com/duckdb/duckdb/pull/22037)

- Update vendored sources to duckdb/duckdb@fbe304454a70bdc6a5f70ac2ee0e2a7ad321c7b5.

  Date: 2026-04-13 15:44:00 +0200

  Provide BWC support for join filter pushdowns (https://redirect.github.com/duckdb/duckdb/pull/22029)

- Update vendored sources to duckdb/duckdb@ad406b8695ec4e7c3336ed6b537f32ef5e4ee84f.

  Date: 2026-04-13 14:46:35 +0200

  Fix TIMESTAMPFORMAT being ignored for TIMESTAMPTZ columns in copy to json (https://redirect.github.com/duckdb/duckdb/pull/21992)

- Update vendored sources to duckdb/duckdb@c35abace2fffcc18c8bc8e409c678ab21f40f545.

  Date: 2026-04-13 12:33:55 +0200

  fix: resolve current catalog in ADBC Ingest to avoid temp table shadowing (https://redirect.github.com/duckdb/duckdb/pull/22020)
  DuckLake Bump (https://redirect.github.com/duckdb/duckdb/pull/22014)
  Use DB serialization compatibility for json_serialize_sql (https://redirect.github.com/duckdb/duckdb/pull/22004)

## fledge

- CRAN release v1.5.2 (#2312).

## Bug fixes

- Avoid rchk error in `RownamesDuplicate()` (#2290, #2291).

## Features

- Add support for `TIME WITH TIME ZONE` type in R bindings (#1807, #2336).

- Store downloaded extensions inside the duckdb package install directory (#2327).

- Add native VARIANT data type support (@thohan88, #2313).

- Add `is_distinct_from()` / `is_not_distinct_from()` dbplyr translations for compatibility with dbplyr 2.6.0 (#2326, #2332).

## Chore

- Bump minimum R version requirement to 4.2.0 (#2233, #2334).

- Simplify `ValueToSexp()` (#2333).

- Remove unneeded `.d` file backup.

- Add out-of-line `SelectionData` destructor to fix GCC warnings (#2329).

- Initialize `ParquetReader::rows_read` atomic variable (#2328).

- Add ccache to `.gitignore` and `.Rbuildignore`.

- Revdepcheck results.

- Auto-update from GitHub Actions.

  Run: https://github.com/krlmlr/duckdb-r/actions/runs/25267064493

- Auto-update from GitHub Actions (#2319).

- Next skill iteration.

- Fetch logs from orphan branch.

## Continuous integration

- Clarify rationale for not deploying on schedule.

- Add reference to `/apply-patch` workflow in commit message.

- Clarify handling of broken-\*-dev branches.

- Simplify again.

- Only run fledge on pushes to main.

- Tweak fledge workflow and ccache action.

- Align.

- Cosmetics.

- Bump action versions.

- Install clang-format-21.

- Align fledge workflow.

- Harmonize.

- Success message.

- Fetch all.

- Refine.

- Tweak skill.

- 4x per day.

- Trigger.

- On push.

## Testing

- Add comprehensive test coverage for MAP type reading (#2342).

## Uncategorized

- Refine RCC smoke-fix workflow: per-commit validation and push (#25).

- Merge branch 'main' into krlmlr-main.

- Add workflow to cancel pending RCC dispatch runs (#24).

- Add RCC smoke test fix skill documentation (#22).

- Docs(skill): add rcc-smoke-fix skill modeled on rigraph.

- Iterate over multiple \*-dev branches (main-dev, v1.5-variegata-dev,.

- Forbid edits to vendored sources (src/duckdb/, inst/include/cpp11/,.

- Document longer build times (10-15 min cold) and the .dd.

- Include the same operation-essence preamble, no-log-access caveat,.

- Docs(skill): correct claim about CI promoting fixes to \*-dev.

- Docs(skill): address review feedback on rcc-smoke-fix.

- Replace placeholder status-lookup pseudocode with a concrete.

- Enable `set -o pipefail` around `... | tail -N` so failing.

- Use `rcmdcheck::rcmdcheck()` instead of `R CMD check .` (which is.

- Build-ignore.

- Fix: remove all R CMD check . references from skill.

- Docs(skill): spell out patch/ → vendored cascade; drop transient branches.

- Note that editing `patch/` is expected to produce committable changes.

- Apply-patch instruction added to priority 1.

- Commit step conditionally adds `src/duckdb/` only when `patch/` changed.

- Cherry-pick conflict on `src/duckdb/` softened: rare but possible from.

- Removed all references to out-of-scope transient branches.


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
