# Changelog

## duckdb 1.5.3.9900

### vendor

- Update vendored sources (tag v1.5.4) to
  <duckdb/duckdb@08e34c447bae34eaee3723cac61f2878b6bdf787>.

  Date: 2026-06-16 10:51:13 +0200

- Update vendored sources to
  <duckdb/duckdb@08e34c447bae34eaee3723cac61f2878b6bdf787>.

  Fix more geom stats
  (<https://redirect.github.com/duckdb/duckdb/pull/23295>) bump iceberg
  (<https://redirect.github.com/duckdb/duckdb/pull/23277>)

- Update vendored sources to
  <duckdb/duckdb@3569177e6d7a0fbabeb0548f93cfceae482a5fd4>.

  Date: 2026-06-15 10:34:22 +0200

  \[Dev\]\[Parquet\]\[VARIANT\] Fix problem with re-use of cached
  transform data for differently shredded files
  (<https://redirect.github.com/duckdb/duckdb/pull/23234>)

- Update vendored sources to
  <duckdb/duckdb@7f9baa98a7758e346c239e4f76bf80bc5ca21c19>.

  Date: 2026-06-15 09:35:19 +0200

  Fix NULL propagation for date parts of infinite dates
  (<https://redirect.github.com/duckdb/duckdb/pull/23254>)

- Update vendored sources to
  <duckdb/duckdb@8504862f65667309f92abac01d56c783651111de>.

  Date: 2026-06-15 09:32:31 +0200

  Backport loop in sleep_ms
  (<https://redirect.github.com/duckdb/duckdb/pull/23245>)

- Update vendored sources to
  <duckdb/duckdb@69ddc5ed89ca9549e2d0a2e4fe6161b642f4247a>.

  Date: 2026-06-15 09:31:53 +0200

  Trim the system heap in the allocator flush path on jemalloc builds
  (<https://redirect.github.com/duckdb/duckdb/pull/23253>) Bump iceberg
  for v1.5.4 (<https://redirect.github.com/duckdb/duckdb/pull/23225>)
  Fix gzip compression write overflow
  (<https://redirect.github.com/duckdb/duckdb/pull/23232>) Add explicit
  `-dark-mode` and `-light-mode` options to the CLI, and improve
  terminal background color detection
  (<https://redirect.github.com/duckdb/duckdb/pull/23246>) Bump vortex
  to 275ac230e1d9afd08926b6989ec2467f92fae6e3
  (<https://redirect.github.com/duckdb/duckdb/pull/23263>)

- Update vendored sources to
  <duckdb/duckdb@6f26bb802200cb9550c7e7e2edb52a4105c7e100>.

  Date: 2026-06-13 14:43:28 +0200

  Cherry picks on variegata
  (<https://redirect.github.com/duckdb/duckdb/pull/23262>) \[Dev\] Add
  missing `ORDER BY ALL` or `rowsort` to merge into tests
  (<https://redirect.github.com/duckdb/duckdb/pull/23258>)

- Update vendored sources to
  <duckdb/duckdb@4d8c29780d60962a9f237c4c734ef2d4b4905e85>.

  Date: 2026-06-12 15:33:04 +0200

  Remove checked_array_iterator from fmt dep (1.5)
  (<https://redirect.github.com/duckdb/duckdb/pull/23238>)

- Update vendored sources to
  <duckdb/duckdb@72e0d6a30931c6d484686736d7db2370d397dd86>.

  Date: 2026-06-12 10:28:05 +0200

  Fix VARIANT shredding, avoid including empty object keys
  (<https://redirect.github.com/duckdb/duckdb/pull/23213>)

- Update vendored sources to
  <duckdb/duckdb@4422100672c347be842f98fe14e7e62bc4ec5df2>.

  Date: 2026-06-12 08:35:26 +0200

  Variant fixes (<https://redirect.github.com/duckdb/duckdb/pull/23195>)
  Hopefully fix timeouts on `v1.5-variegata`
  (<https://redirect.github.com/duckdb/duckdb/pull/23224>) Bump httpfs
  for variegata (<https://redirect.github.com/duckdb/duckdb/pull/23215>)
  Bump DuckLake (<https://redirect.github.com/duckdb/duckdb/pull/23226>)
  bump delta & unity for 1.5.4
  (<https://redirect.github.com/duckdb/duckdb/pull/23212>) Bump quack no
  patches (<https://redirect.github.com/duckdb/duckdb/pull/23210>)
  parquet: initialize `ParquetReader::rows_read`
  (<https://redirect.github.com/duckdb/duckdb/pull/23205>) \[Dev\] Fix
  “environment variable already defined” error in sqllogictest when
  `test_env` is used
  (<https://redirect.github.com/duckdb/duckdb/pull/21305>)

- Update vendored sources to
  <duckdb/duckdb@b5dcfd62ec55be6b0e3f1288c60320faa50ed7f3>.

  Date: 2026-06-11 08:56:17 +0200

  Zero the inlined buffer in string_t’s length-only constructor
  (<https://redirect.github.com/duckdb/duckdb/pull/23201>)

- Update vendored sources to
  <duckdb/duckdb@6c0622c1050587a2a3a8558464a40415bfcffaf3>.

  Date: 2026-06-11 08:54:28 +0200

  Fix crash when storage path is not set
  (<https://redirect.github.com/duckdb/duckdb/pull/23174>)

- Update vendored sources to
  <duckdb/duckdb@748c0ddf195097c7d5b167f06b7b1c4f63122ef8>.

  Date: 2026-06-11 08:52:56 +0200

  Bump quack to 9ac6521f712812cc6f2e58815ef0a6c85c5e06e0
  (<https://redirect.github.com/duckdb/duckdb/pull/23178>) Out-of-line
  `SelectionData` destructor to silence g++-16 `-Warray-bounds`
  (<https://redirect.github.com/duckdb/duckdb/pull/23204>)

- Update vendored sources to
  <duckdb/duckdb@0ba37b0f9eb348091f4f8f81260a3370c8da49e4>.

  Date: 2026-06-11 08:33:11 +0200

  Add hardening to many DuckDB/Parquet decompression/deserializing paths
  (<https://redirect.github.com/duckdb/duckdb/pull/23100>)

- Update vendored sources to
  <duckdb/duckdb@92ac1c75140109557cfb5b2112bc4762d8f5e3ee>.

  Date: 2026-06-11 08:27:45 +0200

  Fix selection vector use in Arrow extension callbacks
  (<https://redirect.github.com/duckdb/duckdb/pull/23190>) Initialize
  `TransactionContext::invalidation_policy` and `auto_rollback`
  (<https://redirect.github.com/duckdb/duckdb/pull/23203>) Initialize
  all `BaseStatistics` members and zero `stats_union`
  (<https://redirect.github.com/duckdb/duckdb/pull/23202>)

- Update vendored sources to
  <duckdb/duckdb@8f2825a19f3509727c1c5ef104729a5f706324ad>.

  Date: 2026-06-11 08:21:14 +0200

  \[Dev\] Fix variant shredding analysis logic discrepancy with shredded
  writing (<https://redirect.github.com/duckdb/duckdb/pull/23194>)

- Update vendored sources to
  <duckdb/duckdb@e36f5ab9af0438a279f754180327bab02660d9b0>.

  Date: 2026-06-11 08:16:29 +0200

  Replace ARTConflictType::TRANSACTION with fatal exception
  (<https://redirect.github.com/duckdb/duckdb/pull/23193>) bump iceberg
  (<https://redirect.github.com/duckdb/duckdb/pull/23192>)

- Update vendored sources to
  <duckdb/duckdb@49e41bc38cf10361bd7a2a9ce752f17be98dabe6>.

  Date: 2026-06-10 17:07:00 +0200

  Fix: guard againt null row group reorder stats
  (<https://redirect.github.com/duckdb/duckdb/pull/23189>)

- Update vendored sources to
  <duckdb/duckdb@962a9241a866681eb2de77aa5c24c86974d3e0eb>.

  Date: 2026-06-10 15:20:12 +0200

  Backport to variegata some isolated fixes
  (<https://redirect.github.com/duckdb/duckdb/pull/23175>)

- Update vendored sources to
  <duckdb/duckdb@877f9a08f1cb09757d8bcb9f8861310cc65e231b>.

  Date: 2026-06-10 15:14:19 +0200

  Merge v1.4-andium into v1.5-variegata
  (<https://redirect.github.com/duckdb/duckdb/pull/23171>) Bump aws
  extension (<https://redirect.github.com/duckdb/duckdb/pull/23170>)

- Update vendored sources to
  <duckdb/duckdb@2a534abeda80d4fa08cc8333e6b4e64a4e884317>.

  Date: 2026-06-10 15:13:54 +0200

  Minor fixes (<https://redirect.github.com/duckdb/duckdb/pull/23162>)

- Update vendored sources to
  <duckdb/duckdb@2115a294b17d4d138dfbdb9ec11c51d35f75ea89>.

  Date: 2026-06-10 09:45:32 +0200

  Expose bytes to parquet variant function
  (<https://redirect.github.com/duckdb/duckdb/pull/23057>)

- Update vendored sources to
  <duckdb/duckdb@ea229c4dc457c26f1700ae6d8d57066e68b69ee1>.

  Date: 2026-06-10 09:00:47 +0200

  Fix native geometry parquet stats pruning and add
  `OPERATOR_ROW_GROUPS_SCANNED` to parquet reader
  (<https://redirect.github.com/duckdb/duckdb/pull/23140>) Update
  Postgres, SQLite and ODBC in 1.5
  (<https://redirect.github.com/duckdb/duckdb/pull/23172>) Upgrade
  ducklake for release
  (<https://redirect.github.com/duckdb/duckdb/pull/23182>)

- Update vendored sources to
  <duckdb/duckdb@894e3727d194d72295d10aa971798de10a82e657>.

  Date: 2026-06-09 14:53:37 +0200

  Fix RowGroup assertion
  (<https://redirect.github.com/duckdb/duckdb/pull/23155>)

  ## Conflicts:

  ## DESCRIPTION

- Update vendored sources to
  <duckdb/duckdb@b9196d397dd252c3e72bbd62be1be8e79f7cef75>.

  Date: 2026-06-09 14:53:20 +0200

  Fix <https://redirect.github.com/duckdb/duckdb/pull/21931>: avoid
  trying to bind an expression that doesn’t exist in `UNPIVOT`
  (<https://redirect.github.com/duckdb/duckdb/pull/23156>) Fix json
  argument order affecting result
  (<https://redirect.github.com/duckdb/duckdb/pull/23144>) Allow array
  type for array_to_json
  (<https://redirect.github.com/duckdb/duckdb/pull/23129>)

- Update vendored sources to
  <duckdb/duckdb@4f8d9cb5d4661d98c33ff428ef632dc0fe6f8c96>.

  Date: 2026-06-09 09:13:46 +0200

  Clarify BIGNUM C API data is big endian
  (<https://redirect.github.com/duckdb/duckdb/pull/23127>)

- Update vendored sources to
  <duckdb/duckdb@07866eb051fda03d148fb40fa9cb188363606119>.

  Date: 2026-06-09 09:13:37 +0200

  Internal <https://redirect.github.com/duckdb/duckdb/pull/9375>: PRAGMA
  enum NULL (<https://redirect.github.com/duckdb/duckdb/pull/23146>)

- Update vendored sources to
  <duckdb/duckdb@b4eeb55d58fdf26395efcb11ee830a48dec31955>.

  Date: 2026-06-09 08:34:13 +0200

  \[v1.5\] Backport external file cache fix
  (<https://redirect.github.com/duckdb/duckdb/pull/23132>) Fix:
  ignore_errors silently accepting invalid json
  (<https://redirect.github.com/duckdb/duckdb/pull/23137>)

- Update vendored sources to
  <duckdb/duckdb@238d1f1ae4e02b732678f02de6dc1e571f1b2b3b>.

  Date: 2026-06-08 20:14:49 +0200

  Fix windows last modification timestamp
  (<https://redirect.github.com/duckdb/duckdb/pull/23136>) Reject NULL
  json key (<https://redirect.github.com/duckdb/duckdb/pull/23116>)

- Update vendored sources to
  <duckdb/duckdb@2478e35c7ac9281e493dec56b2c8e09b42d5084f>.

  Date: 2026-06-08 13:14:53 +0200

  fix(adbc): fill metadata of GetObjects
  (<https://redirect.github.com/duckdb/duckdb/pull/23110>)

- Update vendored sources to
  <duckdb/duckdb@a6fce56cf7d2e2c0ca7831b7d8db10413cdb269b>.

  Date: 2026-06-07 11:19:11 +0200

  Fix Parquet thrift byte order on windows + relax geometry stats
  pruning (<https://redirect.github.com/duckdb/duckdb/pull/23095>)

- Update vendored sources to
  <duckdb/duckdb@fcfa67b7c42f025567133fc98f062b4b531bdc22>.

  Date: 2026-06-07 11:15:56 +0200

  v1.5-variegata: bump extensions
  (<https://redirect.github.com/duckdb/duckdb/pull/23089>) Bump vortex
  in variegata (<https://redirect.github.com/duckdb/duckdb/pull/23096>)
  Bump lance in variegata
  (<https://redirect.github.com/duckdb/duckdb/pull/23094>)

- Update vendored sources to
  <duckdb/duckdb@082b80b696847fa40419e035d76aa9f02bee2e74>.

  Date: 2026-06-06 09:07:29 +0200

  Merge v1.4-andium into v1.5-variegata, and add storage versions v1.4.5
  and v1.5.4 (<https://redirect.github.com/duckdb/duckdb/pull/23082>)

- Update vendored sources to
  <duckdb/duckdb@9fd94dac874e3bb382fe6cf8c6b71d675811e656>.

  Date: 2026-06-05 12:47:16 +0200

  fix(adbc): implement ADBC 1.1.0 Rich Error Metadata API
  (<https://redirect.github.com/duckdb/duckdb/pull/23073>)

- Update vendored sources to
  <duckdb/duckdb@be167b09f1d1e5e4d9814a03082a0f90d10cbc6b>.

  Date: 2026-06-04 14:19:18 +0200

  Fix VARIANT cast reading wrong rows under a filter
  (<https://redirect.github.com/duckdb/duckdb/pull/23031>) Rename
  emscripten action in v1.5
  (<https://redirect.github.com/duckdb/duckdb/pull/23044>)

- Update vendored sources to
  <duckdb/duckdb@40721d5609648df8bf00671e2094ccee8d142c0b>.

  Date: 2026-06-03 14:07:45 +0200

  Merge Into: Avoid recursively binding in the ProjectionBinder
  (<https://redirect.github.com/duckdb/duckdb/pull/23022>)

- Update vendored sources to
  <duckdb/duckdb@cdfe7bf954245f77420afca6d19013da8b468bb6>.

  Date: 2026-06-03 12:35:44 +0200

  In the optimistic writer always start a new row group after merging
  (<https://redirect.github.com/duckdb/duckdb/pull/22997>)

- Update vendored sources to
  <duckdb/duckdb@936e23eaf579f5c8732ae3490b1e1cff4820eaa0>.

  Date: 2026-06-03 07:36:07 +0200

  MERGE INTO: only consider target table when binding `WHEN NOT MATCHED`
  and source table when binding `WHEN NOT MATCHED BY TARGET`
  (<https://redirect.github.com/duckdb/duckdb/pull/23014>)

- Update vendored sources to
  <duckdb/duckdb@ac79ba69fe32d1bd612964daf08d3777837e331d>.

  Date: 2026-06-02 17:56:56 +0200

  Normalize db_type to lowercase on ATTACH, apply extension aliases on
  compare (<https://redirect.github.com/duckdb/duckdb/pull/22758>)

- Update vendored sources to
  <duckdb/duckdb@810a15558f1cd411b4a38b8e84ba74c1a724409f>.

  Date: 2026-06-02 17:42:10 +0200

  Fix case-insensitive column match in INSERT … SELECT ON CONFLICT
  (<https://redirect.github.com/duckdb/duckdb/pull/22825>)

- Update vendored sources to
  <duckdb/duckdb@6367663157416c79e64875d96156d80059f2dc07>.

  Date: 2026-06-02 08:53:20 +0200

  Add avro and unity_catalog to extension list
  (<https://redirect.github.com/duckdb/duckdb/pull/22948>)

- Update vendored sources to
  <duckdb/duckdb@b7373fb7590fd7dcd1a9362d598f6e847c59c3b4>.

  Date: 2026-06-02 08:39:39 +0200

  Fix partial column metadata reuse bug
  (<https://redirect.github.com/duckdb/duckdb/pull/22994>)

- Update vendored sources to
  <duckdb/duckdb@f0c930c615f6d2efc3b15241bad0e6d68b0fe008>.

  Date: 2026-06-01 09:13:22 +0200

  fix(adbc): support `StatementExecuteSchema` of ADBC 1.1.0
  (<https://redirect.github.com/duckdb/duckdb/pull/22965>)

- Update vendored sources to
  <duckdb/duckdb@91e5d92c16fce5042ead343a4a7950318ae26e65>.

  Date: 2026-05-29 21:03:44 +0200

  Make url a value, not a const ref
  (<https://redirect.github.com/duckdb/duckdb/pull/22953>) Bump Julia to
  v1.5.3 (<https://redirect.github.com/duckdb/duckdb/pull/22804>)

- Update vendored sources to
  <duckdb/duckdb@257dbeecb9d395951d616c99803b3772a62628ed>.

  Date: 2026-05-29 14:56:07 +0200

  Rowgroup index append
  (<https://redirect.github.com/duckdb/duckdb/pull/22940>)

- Update vendored sources to
  <duckdb/duckdb@7505fef25c46c334da03fe132c59cfb1a9a2dcd4>.

  Date: 2026-05-29 08:51:23 +0200

  Fix alias propagation when replacement scan is wrapped in SubqueryRef
  (<https://redirect.github.com/duckdb/duckdb/pull/22852>) Update vortex
  extension (<https://redirect.github.com/duckdb/duckdb/pull/22930>)

- Update vendored sources to
  <duckdb/duckdb@4dac4343d654d967afb9bc057c3b3638158cd00b>.

  Date: 2026-05-28 10:02:33 +0200

  Validate width/scale in duckdb_create_decimal_type and
  duckdb_create_decimal
  (<https://redirect.github.com/duckdb/duckdb/pull/22905>)

- Update vendored sources to
  <duckdb/duckdb@64e1c5e9347902cd462f1e445766ab4ed104bf82>.

  Date: 2026-05-28 10:02:01 +0200

  Use non-deleted row count in `RowGroupReorderer`
  (<https://redirect.github.com/duckdb/duckdb/pull/22911>)

- Update vendored sources to
  <duckdb/duckdb@635155a8522632cafb2ba36189f46569ebba8b23>.

  Date: 2026-05-28 08:51:25 +0200

  Add vacuum_rebuild_indexes as an (experimental) ATTACH option
  (<https://redirect.github.com/duckdb/duckdb/pull/22690>) Check for
  `nullptr` expressions in deserialized JSON
  (<https://redirect.github.com/duckdb/duckdb/pull/22906>)

- Update vendored sources to
  <duckdb/duckdb@c0765cea1fee6de532b825a456430623969ef262>.

  Date: 2026-05-27 14:47:49 +0200

  Fix geometry stats checkpointing when no changes are detected
  (<https://redirect.github.com/duckdb/duckdb/pull/22882>)

- Update vendored sources to
  <duckdb/duckdb@d53c7e81239969ce35a39ce4340e23140b931024>.

  Date: 2026-05-27 10:40:27 +0200

  Use committed row count in `RowGroupReorderer`
  (<https://redirect.github.com/duckdb/duckdb/pull/22884>) Fix: JSON add
  list type check
  (<https://redirect.github.com/duckdb/duckdb/pull/22862>) Fix json_keys
  with wildcard paths
  (<https://redirect.github.com/duckdb/duckdb/pull/22855>)

- Update vendored sources to
  <duckdb/duckdb@cd3b2ad3eeb918620262802fa7d12705b308a25e>.

  Date: 2026-05-26 10:17:37 +0200

  \[Backport\] Column-level metadata loading and serialization
  (<https://redirect.github.com/duckdb/duckdb/pull/22768>)

- Update vendored sources to
  <duckdb/duckdb@9e4f3003f71f5dd1399543930b63cfae2adb0684>.

  Date: 2026-05-26 10:07:17 +0200

  Issue <https://redirect.github.com/duckdb/duckdb/pull/22791>: Window
  Self-Join Limits
  (<https://redirect.github.com/duckdb/duckdb/pull/22844>) Fix: check if
  `ParseFormatSpecifier` returns unrecognized format
  (<https://redirect.github.com/duckdb/duckdb/pull/22850>)

- Update vendored sources to
  <duckdb/duckdb@655dfabf9411dbca9e127960c34e00087e15ebc5>.

  Date: 2026-05-26 09:57:49 +0200

  Internal <https://redirect.github.com/duckdb/duckdb/pull/9438>: TopN
  Window Projections
  (<https://redirect.github.com/duckdb/duckdb/pull/22851>)

- Update vendored sources to
  <duckdb/duckdb@66a1ae56f7a094d6664d949c9fe87caf62f54466>.

  Date: 2026-05-26 09:42:51 +0200

  fix progress bar output and crash when piping SQL
  (<https://redirect.github.com/duckdb/duckdb/pull/22836>)

- Update vendored sources to
  <duckdb/duckdb@9a64d338f2fa1d3c1d43c016b09c538b529dd397>.

  Date: 2026-05-22 23:21:40 +0200

  Fix `WindowSelfJoinOptimizer` ignore exception
  (<https://redirect.github.com/duckdb/duckdb/pull/22800>) Remove
  time-out waiting for terminal background color
  (<https://redirect.github.com/duckdb/duckdb/pull/22838>)

- Update vendored sources to
  <duckdb/duckdb@6e9cdf83f975253739349d95894376c237968b29>.

  Date: 2026-05-22 09:18:06 +0200

  Render MAP values as valid SQL in Value::ToSQLString()
  (<https://redirect.github.com/duckdb/duckdb/pull/22815>)

- Update vendored sources to
  <duckdb/duckdb@ebdadcc66174e02ab11302354c61a31c958000bb>.

  Date: 2026-05-22 09:13:08 +0200

  Fix double free and memory leak in Arrow GeoArrow CRS serialization
  (<https://redirect.github.com/duckdb/duckdb/pull/21854>)

- Update vendored sources to
  <duckdb/duckdb@f6cf717afbeccc47d0c4aecaf7785a6ffd294a31>.

  Date: 2026-05-20 20:03:07 +0200

  Set query text on PIVOT MultiStatement sub-statements at construction
  (<https://redirect.github.com/duckdb/duckdb/pull/22769>)

- Update vendored sources to
  <duckdb/duckdb@db52b80730acf504a4cf25b066ed9368b0f53a2e>.

  Date: 2026-05-20 07:52:19 +0200

  Fix `TemporaryFileManager` reported size to reflect live blocks
  (<https://redirect.github.com/duckdb/duckdb/pull/22767>)

### Bug fixes

- Use memcmp in StringValueComparison to silence valgrind
  ([\#2349](https://github.com/duckdb/duckdb-r/issues/2349)).

- Silence valgrind errors in TransactionContext and BaseStatistics
  ([\#1](https://github.com/duckdb/duckdb-r/issues/1),
  [\#2](https://github.com/duckdb/duckdb-r/issues/2),
  [\#2348](https://github.com/duckdb/duckdb-r/issues/2348)).

### Features

- Support writing `MAP` columns via
  [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  and
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  ([\#2354](https://github.com/duckdb/duckdb-r/issues/2354)).

#### arrow

- Add opt-in streaming flag for Arrow result conversion
  ([\#2355](https://github.com/duckdb/duckdb-r/issues/2355)).

- Implement DBI Arrow API with dbSendQueryArrow() and streaming
  ([\#2347](https://github.com/duckdb/duckdb-r/issues/2347)).

### Chore

- Repair hand-written patch files so GNU patch can apply them.

  - Drop all-zero index lines from patches 0036-0038: GNU patch treats
    an all-zero old blob hash as file creation and refuses to apply the
    patch onto an existing file.
  - Fix the new-side line count of the hunk in patch 0038 (13, not 14).
  - Replace invented context (banner comments not present in the source)
    in the first hunk of patch 0037 with the actual surrounding lines.

  <https://claude.ai/code/session_01GQmwQa48K7BVDnKjMwrNJv>

- Collect revdep problems.

- Cleanup.

- Build-ignore plan directory.

### Continuous integration

- Update ccache-action reference.

- Bump action version.

- Skip tests on Windows and macOS.

### Testing

- Refactor example conditions to use the
  [`simulate_duckdb()`](https://r.duckdb.org/reference/backend-duckdb.md)
  helper ([\#2359](https://github.com/duckdb/duckdb-r/issues/2359)).

- Simplify CRAN guard: auto-enable tests on GitHub Actions
  ([\#2358](https://github.com/duckdb/duckdb-r/issues/2358)).

- Add CRAN guards to prevent heavy C++ engine tests on CRAN
  ([\#2353](https://github.com/duckdb/duckdb-r/issues/2353)).

### Uncategorized

- Merge tag ‘v1.5.3’.

- Update to DuckDB v1.5.3, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.5.3> for details.

- Add secret directory configuration, package startup message, and
  consolidation support via new experimental
  [`duckdb_consolidate_secrets()`](https://r.duckdb.org/reference/duckdb_consolidate_secrets.md)
  ([\#2305](https://github.com/duckdb/duckdb-r/issues/2305),
  [\#2340](https://github.com/duckdb/duckdb-r/issues/2340)).

- Add native `VARIANT` ([@thohan88](https://github.com/thohan88),
  [\#2313](https://github.com/duckdb/duckdb-r/issues/2313)) and
  `TIME WITH TIME ZONE`
  ([\#1807](https://github.com/duckdb/duckdb-r/issues/1807),
  [\#2336](https://github.com/duckdb/duckdb-r/issues/2336)) data type
  support.

- Add `is_distinct_from()` / `is_not_distinct_from()` dbplyr
  translations for compatibility with upcoming dbplyr 2.6.0
  ([\#2326](https://github.com/duckdb/duckdb-r/issues/2326),
  [\#2332](https://github.com/duckdb/duckdb-r/issues/2332)).

- Avoid rchk error in `RownamesDuplicate()`
  ([\#2290](https://github.com/duckdb/duckdb-r/issues/2290),
  [\#2291](https://github.com/duckdb/duckdb-r/issues/2291)).

- Bump minimum R version requirement to 4.2.0
  ([\#2233](https://github.com/duckdb/duckdb-r/issues/2233),
  [\#2334](https://github.com/duckdb/duckdb-r/issues/2334)).

- Store downloaded extensions inside the duckdb package install
  directory ([\#2327](https://github.com/duckdb/duckdb-r/issues/2327)).

- Add comprehensive test coverage for `MAP` type reading
  ([\#2342](https://github.com/duckdb/duckdb-r/issues/2342)).

- Switching to development version.

## duckdb 1.5.3

### Features

- Update to DuckDB v1.5.3, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.5.3> for details.

- Add secret directory configuration, package startup message, and
  consolidation support via new experimental
  [`duckdb_consolidate_secrets()`](https://r.duckdb.org/reference/duckdb_consolidate_secrets.md)
  ([\#2305](https://github.com/duckdb/duckdb-r/issues/2305),
  [\#2340](https://github.com/duckdb/duckdb-r/issues/2340)).

- Add native `VARIANT` ([@thohan88](https://github.com/thohan88),
  [\#2313](https://github.com/duckdb/duckdb-r/issues/2313)) and
  `TIME WITH TIME ZONE`
  ([\#1807](https://github.com/duckdb/duckdb-r/issues/1807),
  [\#2336](https://github.com/duckdb/duckdb-r/issues/2336)) data type
  support.

- Add `is_distinct_from()` / `is_not_distinct_from()` dbplyr
  translations for compatibility with upcoming dbplyr 2.6.0
  ([\#2326](https://github.com/duckdb/duckdb-r/issues/2326),
  [\#2332](https://github.com/duckdb/duckdb-r/issues/2332)).

### Bug fixes

- Avoid rchk error in `RownamesDuplicate()`
  ([\#2290](https://github.com/duckdb/duckdb-r/issues/2290),
  [\#2291](https://github.com/duckdb/duckdb-r/issues/2291)).

### Chore

- Bump minimum R version requirement to 4.2.0
  ([\#2233](https://github.com/duckdb/duckdb-r/issues/2233),
  [\#2334](https://github.com/duckdb/duckdb-r/issues/2334)).

- Store downloaded extensions inside the duckdb package install
  directory ([\#2327](https://github.com/duckdb/duckdb-r/issues/2327)).

### Testing

- Add comprehensive test coverage for `MAP` type reading
  ([\#2342](https://github.com/duckdb/duckdb-r/issues/2342)).

## duckdb 1.5.2

CRAN release: 2026-04-13

### Bug fixes

- Update to DuckDB v1.5.2, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.5.2> for details.

- Fix compiler warning on recent clang on macOS.

### Features

- Use `TRY_CAST()` instead of `CAST()` in dplyr SQL translation for type
  conversion functions
  ([\#2230](https://github.com/duckdb/duckdb-r/issues/2230),
  [\#2231](https://github.com/duckdb/duckdb-r/issues/2231)).

### Chore

- Use `R_getRegisteredNamespace()` in R 4.6.

### Documentation

- Describe branching strategy
  ([\#2280](https://github.com/duckdb/duckdb-r/issues/2280),
  [\#2281](https://github.com/duckdb/duckdb-r/issues/2281)).

### Testing

- Use explicit default duckdb connection for arrow tests
  ([\#2301](https://github.com/duckdb/duckdb-r/issues/2301)).

- Rework arrow tests, prepare for compatibility with dbplyr 2.6.0
  ([\#2300](https://github.com/duckdb/duckdb-r/issues/2300)).

## duckdb 1.5.1

CRAN release: 2026-03-26

### Bug fixes

- Update to DuckDB v1.5.1, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.5.1> for details.

### Features

- `GEOMETRY` columns can be returned, either as BLOBs (default) or as wk
  objects (via the wk package) using `dbConnect(geometry = "wk")`
  ([\#2278](https://github.com/duckdb/duckdb-r/issues/2278),
  [\#2279](https://github.com/duckdb/duckdb-r/issues/2279)).

### Chore

- Fix `-Wdeprecated` compiler warnings
  ([\#2295](https://github.com/duckdb/duckdb-r/issues/2295),
  [\#2296](https://github.com/duckdb/duckdb-r/issues/2296)) and
  protection buglet
  ([\#2294](https://github.com/duckdb/duckdb-r/issues/2294)).

- Use `gtar` when available to suppress Apple extended attribute
  warnings on Linux
  ([\#2227](https://github.com/duckdb/duckdb-r/issues/2227),
  [\#2228](https://github.com/duckdb/duckdb-r/issues/2228)).

## duckdb 1.5.0

CRAN release: 2026-03-14

### Features

- Update to DuckDB v1.5.0, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.5.0> for details.

- Support `descending` and `nulls_first` in `expr_window()` and
  `rel_order()`
  ([\#2074](https://github.com/duckdb/duckdb-r/issues/2074),
  [\#2075](https://github.com/duckdb/duckdb-r/issues/2075)).

### Bug fixes

- The dbplyr translation of
  [`as.numeric()`](https://rdrr.io/r/base/numeric.html) and
  [`as.double()`](https://rdrr.io/r/base/double.html) uses `DOUBLE`
  instead of `NUMERIC`
  ([\#2023](https://github.com/duckdb/duckdb-r/issues/2023),
  [\#2031](https://github.com/duckdb/duckdb-r/issues/2031)).

### Testing

- Update to testthat edition 3.

### Internal

- Avoid `ATTRIB()` for compatibility with R 4.6, materialize ALTREP row
  names to integer sequence with full ALTREP methods
  ([\#2034](https://github.com/duckdb/duckdb-r/issues/2034)).

## duckdb 1.4.4

CRAN release: 2026-01-28

### Features

- Update to DuckDB v1.4.4, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.4.4> for details.

- Add operator expressions ([@toppyy](https://github.com/toppyy),
  [\#1828](https://github.com/duckdb/duckdb-r/issues/1828)).

### Chore

- Bump vendored cpp11 to v0.5.3.

### Documentation

- Add alternative installation method to README
  ([@szarnyasg](https://github.com/szarnyasg),
  [\#1819](https://github.com/duckdb/duckdb-r/issues/1819)).

## duckdb 1.4.3

CRAN release: 2025-12-10

### Features

- Update to DuckDB v1.4.3, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.4.3> for details.

- Add `str_ilike()` support
  ([@edward-burn](https://github.com/edward-burn),
  [\#1810](https://github.com/duckdb/duckdb-r/issues/1810),
  [\#1811](https://github.com/duckdb/duckdb-r/issues/1811)).

### Bug fixes

- Fail with non-UTF8-encoded strings during data frame scan instead of
  attempting to reencode
  ([\#1795](https://github.com/duckdb/duckdb-r/issues/1795)).

- Avoid inclusion of raw error message in the output.

- Fix translation of
  [`quantile()`](https://rdrr.io/r/stats/quantile.html) to use DuckDB’s
  native `QUANTILE_CONT()` syntax
  ([\#1734](https://github.com/duckdb/duckdb-r/issues/1734),
  [\#1735](https://github.com/duckdb/duckdb-r/issues/1735)).

### Testing

- Remove redundant R version checks from tests
  ([\#1815](https://github.com/duckdb/duckdb-r/issues/1815),
  [\#1816](https://github.com/duckdb/duckdb-r/issues/1816)).

## duckdb 1.4.2

CRAN release: 2025-11-17

- Update to DuckDB v1.4.2, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.4.2> for details.

## duckdb 1.4.1

CRAN release: 2025-10-16

- Update to DuckDB v1.4.1, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.4.1> for details.

### Features

- Add support for wildcards in
  [`tbl_file()`](https://r.duckdb.org/reference/backend-duckdb.md) paths
  ([\#1614](https://github.com/duckdb/duckdb-r/issues/1614),
  [@rplsmn](https://github.com/rplsmn)).

- Add `n_distinct(..., na.rm = TRUE)` support for multiple passed
  columns ([@lschneiderbauer](https://github.com/lschneiderbauer),
  [\#1588](https://github.com/duckdb/duckdb-r/issues/1588)).

### Bug fixes

- Fix Valgrind error.

### Testing

- Ensure be able to install duckdb extensions on release version
  ([@eitsupi](https://github.com/eitsupi),
  [\#1586](https://github.com/duckdb/duckdb-r/issues/1586)).

## duckdb 1.4.0

CRAN release: 2025-09-18

- Update to DuckDB v1.4.0, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.4.0> for details.

### Features

- New experimental
  [`sql_query()`](https://r.duckdb.org/reference/sql_query.md),
  [`sql_exec()`](https://r.duckdb.org/reference/sql_query.md), and
  [`default_conn()`](https://r.duckdb.org/reference/default_conn.md) to
  simplify the most important operations for interactive use
  ([\#1564](https://github.com/duckdb/duckdb-r/issues/1564)).

- [`tbl_file()`](https://r.duckdb.org/reference/backend-duckdb.md)
  allows omitting the `src` argument, falling back to the default
  connection.

- Full support for deep structs generated by `struct_pack()` for ALTREP
  ([\#1545](https://github.com/duckdb/duckdb-r/issues/1545)).

### Bug fixes

- Fix progress display for fractional progress values
  ([\#1499](https://github.com/duckdb/duckdb-r/issues/1499),
  [\#1505](https://github.com/duckdb/duckdb-r/issues/1505)).

- Extensions can be installed again.

## duckdb 1.3.3

CRAN release: 2025-09-10

- Update to the current v1.3-ossivalis branch, see
  <https://github.com/duckdb/duckdb/tree/v1.3-ossivalis> for details.

### Bug fixes

- Fix timezone conversion for invalid timestamps with
  `tz_out_convert = "force"`
  ([\#1474](https://github.com/duckdb/duckdb-r/issues/1474)).

- Substitute invalid UTF-8 characters in error messages to avoid a
  failure when reporting the error.

- Fix index calculation for retrieval of arrays
  ([\#1473](https://github.com/duckdb/duckdb-r/issues/1473)).

- Fix conversion for retrieval of large enums.

- Fix compiler error in debug build
  ([@joakimlinde](https://github.com/joakimlinde),
  [\#1368](https://github.com/duckdb/duckdb-r/issues/1368)).

### Features

- Add rich ErrorData-based error handling with structured error
  information
  ([\#1479](https://github.com/duckdb/duckdb-r/issues/1479)).

- Safeguard against deadlocks when accidentally issuing queries from the
  progress bar handler or other callbacks
  ([\#1475](https://github.com/duckdb/duckdb-r/issues/1475)).

- [`dbGetInfo()`](https://dbi.r-dbi.org/reference/dbGetInfo.html) gets
  the version from a hard-coded value and not from a DuckDB query
  ([\#1481](https://github.com/duckdb/duckdb-r/issues/1481)).

- Package uses two cores by default for compilation
  ([\#1478](https://github.com/duckdb/duckdb-r/issues/1478)).

### Documentation

- Document vendoring process and main/next branch relationship
  ([\#1488](https://github.com/duckdb/duckdb-r/issues/1488)).

### Testing

- Add `local_con()` test fixture for cleaner DuckDB connection
  management ([\#1476](https://github.com/duckdb/duckdb-r/issues/1476)).

## duckdb 1.3.2

CRAN release: 2025-07-09

### Features

- Update to duckdb v1.3.2, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.3.2> for details.

## duckdb 1.3.1

CRAN release: 2025-06-23

### Features

- Update to duckdb v1.3.1, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.3.1> for details.

### Bug fixes

- Correct dbplyr translations for `str_starts()` and `str_ends()`
  ([\#1182](https://github.com/duckdb/duckdb-r/issues/1182),
  [\#1247](https://github.com/duckdb/duckdb-r/issues/1247)).

- Fix multiarch build on R 4.1 for Windows.

## duckdb 1.3.0

CRAN release: 2025-06-02

### Features

- Update to duckdb v1.3.0, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.3.0> for details.

- Add ingestion of matrices
  ([@joakimlinde](https://github.com/joakimlinde),
  [\#1150](https://github.com/duckdb/duckdb-r/issues/1150)).

### Chore

- Fix rchk ([\#1173](https://github.com/duckdb/duckdb-r/issues/1173)).

- Fix compiler warning ([@joakimlinde](https://github.com/joakimlinde),
  [\#1172](https://github.com/duckdb/duckdb-r/issues/1172)).

### Testing

- Skip timing tests on CRAN.

## duckdb 1.2.2

CRAN release: 2025-04-29

### Features

- Update to duckdb v1.2.2, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.2.2> for details.

- Add support for duckdb arrays in R
  ([@joakimlinde](https://github.com/joakimlinde),
  [\#102](https://github.com/duckdb/duckdb-r/issues/102),
  [\#1090](https://github.com/duckdb/duckdb-r/issues/1090)). To enable,
  connect with `dbConnect(duckdb(), array = "matrix")`
  ([@joakimlinde](https://github.com/joakimlinde),
  [\#1125](https://github.com/duckdb/duckdb-r/issues/1125)).

- Support fractional seconds in `TIME` and `INTERVAL` data
  ([\#1109](https://github.com/duckdb/duckdb-r/issues/1109)).

- The `autoload_known_extensions` configuration option is now enabled by
  default ([\#582](https://github.com/duckdb/duckdb-r/issues/582),
  [\#1084](https://github.com/duckdb/duckdb-r/issues/1084),
  [\#1134](https://github.com/duckdb/duckdb-r/issues/1134)).

- Mention column name for conversion errors
  ([\#1108](https://github.com/duckdb/duckdb-r/issues/1108)).

### Chore

- Require R \>= 4.1
  ([\#1087](https://github.com/duckdb/duckdb-r/issues/1087),
  [\#1133](https://github.com/duckdb/duckdb-r/issues/1133)).

- Types exposed through ALTREP are the same as through DBI
  ([\#1111](https://github.com/duckdb/duckdb-r/issues/1111)), including
  `STRUCT`. This enables support more types in upcoming duckplyr
  versions.

- Perform optional checks for ALTREP compatibility in `rel_from_df()`
  and `expr_constant()`
  ([\#1117](https://github.com/duckdb/duckdb-r/issues/1117)).

- Perform time zone conversion in the C++ layer where possible, to
  support ALTREP
  ([\#1130](https://github.com/duckdb/duckdb-r/issues/1130)).

- Improve developer experience:
  [`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html)
  now works, source files are rebuilt if header files change, configure
  clangd ([\#1128](https://github.com/duckdb/duckdb-r/issues/1128)).

- Add dots with checks to unexported functions
  ([\#1115](https://github.com/duckdb/duckdb-r/issues/1115)).

- Clean up edge case for fetching zero rows
  ([\#1104](https://github.com/duckdb/duckdb-r/issues/1104)).

- Avoid test for timings on CRAN
  ([\#1101](https://github.com/duckdb/duckdb-r/issues/1101)).

### Documentation

- Tweak README.

## duckdb 1.2.1

CRAN release: 2025-03-14

### Features

- Update to duckdb v1.2.1, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.2.1> for details.

### Bug fixes

- `dbExecute(con, "CALL ...")` no longer attempts to access the
  resulting data frame. Use `dbGetQuery(con, "CALL ...")` to access the
  data ([\#1062](https://github.com/duckdb/duckdb-r/issues/1062),
  [\#1080](https://github.com/duckdb/duckdb-r/issues/1080)).

- Fix support for the connections pane in RStudio and Positron
  ([@dfalbel](https://github.com/dfalbel),
  [\#1063](https://github.com/duckdb/duckdb-r/issues/1063)).

### Internal

- New `rel_to_view()`
  ([\#1075](https://github.com/duckdb/duckdb-r/issues/1075)).

- New internal `AltrepDataframeRelation`, used with
  `rel_from_altrep_df(wrap = TRUE)`
  ([\#949](https://github.com/duckdb/duckdb-r/issues/949),
  [\#1072](https://github.com/duckdb/duckdb-r/issues/1072)).

- Try relational materialization only once
  ([\#1066](https://github.com/duckdb/duckdb-r/issues/1066)).

### Chore

- Update vendored cpp11 to 0.5.2
  ([\#1068](https://github.com/duckdb/duckdb-r/issues/1068)).

- Avoid calls to non-API R functions.

## duckdb 1.2.0

CRAN release: 2025-02-20

### Breaking changes

- Breaking change: Remove substrait API: `duckdb_get_substrait()`,
  `duckdb_get_substrait_json()`, `duckdb_prepare_substrait()`,
  `duckdb_prepare_substrait_json()` ([@pdet](https://github.com/pdet),
  [\#1021](https://github.com/duckdb/duckdb-r/issues/1021)).

### Features

- Update to duckdb v1.2.0, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.2.0> for details.

- Progress is shown for slow operation. This is on by default in
  interactive mode and can be controlled by setting the
  `"duckdb.progress_display"` option to a logical scalar
  ([\#199](https://github.com/duckdb/duckdb-r/issues/199),
  [\#951](https://github.com/duckdb/duckdb-r/issues/951),
  [@meztez](https://github.com/meztez)).

- Add translation for [`median()`](https://rdrr.io/r/stats/median.html)
  ([@toppyy](https://github.com/toppyy),
  [\#993](https://github.com/duckdb/duckdb-r/issues/993),
  [\#1011](https://github.com/duckdb/duckdb-r/issues/1011)).

- Floor sub-day precision date before casting to int
  ([@toppyy](https://github.com/toppyy),
  [\#517](https://github.com/duckdb/duckdb-r/issues/517),
  [\#981](https://github.com/duckdb/duckdb-r/issues/981)).

- Set value returned by `PRAGMA user_agent` to r-dbi
  ([\#707](https://github.com/duckdb/duckdb-r/issues/707),
  [@elefeint](https://github.com/elefeint)).

### Bug fixes

- Remove unconditional use of `CPPHTTPLIB_USE_POLL` to support
  compilation with R 4.0 and R 4.1 again
  ([@Antonov548](https://github.com/Antonov548),
  [\#1043](https://github.com/duckdb/duckdb-r/issues/1043)).

- Support reading from multiple Parquet files again
  ([\#1015](https://github.com/duckdb/duckdb-r/issues/1015),
  [\#1024](https://github.com/duckdb/duckdb-r/issues/1024)).

- Fix translation for `add_days()` and `add_years()` clock functions
  ([\#976](https://github.com/duckdb/duckdb-r/issues/976),
  [@IoannaNika](https://github.com/IoannaNika)).

## duckdb 1.1.3-2

CRAN release: 2025-01-24

### Bug fixes

- Make `cleanup` truly idempotent
  ([\#612](https://github.com/duckdb/duckdb-r/issues/612),
  [\#940](https://github.com/duckdb/duckdb-r/issues/940)).

### Chore

- Sync vendoring script with igraph
  ([\#936](https://github.com/duckdb/duckdb-r/issues/936)).

### Features

- Limit automatic materialization by number of rows or number of cells
  ([\#1017](https://github.com/duckdb/duckdb-r/issues/1017)).

- New internal `rapi_rel_to_csv()`,`rapi_rel_to_table()`, and
  `rapi_rel_insert()`; `rapi_rel_to_parquet()` gains `options` argument
  ([\#867](https://github.com/duckdb/duckdb-r/issues/867)).

### Testing

- Skip tests that are about to fail.

- Sync tests.

## duckdb 1.1.3-1

CRAN release: 2024-12-08

### Features

- With `duckdb(environment_scan = TRUE)`, data frame objects are
  available as views in duckdb SQL queries
  ([\#140](https://github.com/duckdb/duckdb-r/issues/140),
  [\#164](https://github.com/duckdb/duckdb-r/issues/164)).

- Update vendored cpp11 to 0.5.1
  ([\#636](https://github.com/duckdb/duckdb-r/issues/636)).

### Bug fixes

- Make `./cleanup` script reentrant
  ([@Antonov548](https://github.com/Antonov548),
  [\#612](https://github.com/duckdb/duckdb-r/issues/612),
  [\#634](https://github.com/duckdb/duckdb-r/issues/634)).

- Fix installation of extensions
  ([\#623](https://github.com/duckdb/duckdb-r/issues/623)).

- Fix rchk and UB errors
  ([\#635](https://github.com/duckdb/duckdb-r/issues/635)).

- Avoid loading rlang during startup
  ([\#601](https://github.com/duckdb/duckdb-r/issues/601)).

### Documentation

- Mention `xz` requirement in `DESCRIPTION`.

## duckdb 1.1.3

CRAN release: 2024-11-21

### Features

- Update to duckdb v1.1.3, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.1.3> for details.

- New `duckdb.materialize_callback` option, supersedes `get_last_rel()`
  ([\#589](https://github.com/duckdb/duckdb-r/issues/589)).

- New `rel_explain_df()` and `rel_tostring()`
  ([\#587](https://github.com/duckdb/duckdb-r/issues/587)).

- Handle empty child values for list constants
  ([\#186](https://github.com/duckdb/duckdb-r/issues/186),
  [@romainfrancois](https://github.com/romainfrancois)).

### Chore

- Undef `TRUE` and `FALSE`
  ([\#595](https://github.com/duckdb/duckdb-r/issues/595)).

- Remove `enable_materialization` argument to `rel_from_altrep_df()` in
  favor of creating a new data frame when needed
  ([\#588](https://github.com/duckdb/duckdb-r/issues/588)).

- Flip argument order for `expr_comparison()`
  ([\#585](https://github.com/duckdb/duckdb-r/issues/585)).

- Keep `cleanup` files to accommodate different build scenarios
  ([\#536](https://github.com/duckdb/duckdb-r/issues/536)).

## duckdb 1.1.2

CRAN release: 2024-10-30

### Features

- Update to duckdb v1.1.2, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.1.2> for details.

### Features

- Long-running queries can now be canceled immediately with Ctrl + C
  (terminal) or Escape (RStudio IDE and Workbench)
  ([\#514](https://github.com/duckdb/duckdb-r/issues/514),
  [\#515](https://github.com/duckdb/duckdb-r/issues/515)).

- Add `col.types` argument to
  [`duckdb_read_csv()`](https://r.duckdb.org/reference/duckdb_read_csv.md)
  ([\#445](https://github.com/duckdb/duckdb-r/issues/445),
  [@eli-daniels](https://github.com/eli-daniels)).

- Rethrow errors with rlang if installed
  ([\#522](https://github.com/duckdb/duckdb-r/issues/522)).

- Improve error message for parsing erros during statement extraction
  (tidyverse/duckplyr#219,
  [\#521](https://github.com/duckdb/duckdb-r/issues/521)).

### Bug fixes

- Avoid RStudio IDE crashes when ending session with open objects
  ([\#520](https://github.com/duckdb/duckdb-r/issues/520)).

- `rfuns` extension: `%in%` works correctly as part of a `&` conjunction
  ([\#528](https://github.com/duckdb/duckdb-r/issues/528)).

### Internal

- New interal APIs: `rapi_get_last_rel_mat()`,
  `rapi_rel_to_altrep(allow_materialization = TRUE)`,
  `rapi_rel_from_altrep_df(enable_materialization)`
  ([\#526](https://github.com/duckdb/duckdb-r/issues/526)).

- xz-compress duckdb sources in the tarball
  ([\#530](https://github.com/duckdb/duckdb-r/issues/530)).

- `rfuns` extension: Fix signedness.

## duckdb 1.1.1

CRAN release: 2024-10-16

### Features

- Update to duckdb v1.1.1, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.1.1> for details.

- Add comparison expression to relational API
  ([@toppyy](https://github.com/toppyy),
  [\#457](https://github.com/duckdb/duckdb-r/issues/457)).

- Temporarily change `max_expression_depth` during ALTREP evaluation
  ([\#101](https://github.com/duckdb/duckdb-r/issues/101),
  [\#460](https://github.com/duckdb/duckdb-r/issues/460)).

- Add `temporary` argument to
  [`duckdb_read_csv()`](https://r.duckdb.org/reference/duckdb_read_csv.md)
  ([@ThomasSoeiro](https://github.com/ThomasSoeiro),
  [\#223](https://github.com/duckdb/duckdb-r/issues/223)).

### Chore

- Update vendored extension sources to
  <hannes/duckdb-rfuns@20cde009b51b9355e6041b72b87105c6b45793fe>.

- Remove warnings for uninitialized variables.

## duckdb 1.1.0

CRAN release: 2024-09-24

### Features

- Update to duckdb v1.1.0, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.1.0> for details.

- Upgrade vendored cpp11 to 0.5.0.

## duckdb 1.0.0-2

CRAN release: 2024-07-19

### Features

- Reduce the package installation size on macOS
  ([\#185](https://github.com/duckdb/duckdb-r/issues/185)).

## duckdb 1.0.0-1

CRAN release: 2024-07-09

### Bug fixes

- Upgrade vendored cpp11 to 0.4.7 to fix compilation with R-devel.

- Support `dplyr::tbl(conn, I(...))`.

## duckdb 1.0.0

CRAN release: 2024-06-13

### Bug fixes

- Update to duckdb v1.0.0, see
  <https://github.com/duckdb/duckdb/releases/tag/v1.0.0> for details.

## duckdb 0.10.3

### Features

- Update to duckdb v0.10.3, see
  <https://github.com/duckdb/duckdb/releases/tag/v0.10.3> for details.
- Support fetching `MAP` type
  ([\#61](https://github.com/duckdb/duckdb-r/issues/61),
  [\#165](https://github.com/duckdb/duckdb-r/issues/165)).
- Add dbplyr translations for
  [`clock::date_count_between()`](https://clock.r-lib.org/reference/date_count_between.html)
  ([@edward-burn](https://github.com/edward-burn),
  [\#163](https://github.com/duckdb/duckdb-r/issues/163),
  [\#166](https://github.com/duckdb/duckdb-r/issues/166)).
- [`round()`](https://rdrr.io/r/base/Round.html) duckdb translation uses
  `ROUND_EVEN()` instead of `ROUND()`
  ([@lschneiderbauer](https://github.com/lschneiderbauer),
  [\#146](https://github.com/duckdb/duckdb-r/issues/146),
  [\#157](https://github.com/duckdb/duckdb-r/issues/157)).
- New `sort` argument to `rel_order()`
  ([@toppyy](https://github.com/toppyy),
  [\#168](https://github.com/duckdb/duckdb-r/issues/168)).
- Add dbplyr translations for
  [`clock::add_days()`](https://clock.r-lib.org/reference/clock-arithmetic.html),
  [`clock::add_years()`](https://clock.r-lib.org/reference/clock-arithmetic.html),
  [`clock::get_day()`](https://clock.r-lib.org/reference/clock-getters.html),
  [`clock::get_month()`](https://clock.r-lib.org/reference/clock-getters.html),
  and
  [`clock::get_year()`](https://clock.r-lib.org/reference/clock-getters.html)
  ([@edward-burn](https://github.com/edward-burn),
  [\#153](https://github.com/duckdb/duckdb-r/issues/153)).

### Bug fixes

- Correct usage of `win_current_group()` instead of
  `win_current_order()` in SQL translation
  ([@lschneiderbauer](https://github.com/lschneiderbauer),
  [\#173](https://github.com/duckdb/duckdb-r/issues/173),
  [\#175](https://github.com/duckdb/duckdb-r/issues/175)).

## duckdb 0.10.2

CRAN release: 2024-05-01

### Features

- Update to duckdb v0.10.2, see
  <https://github.com/duckdb/duckdb/releases/tag/v0.10.2> for details.
- The `"difftime"` class is now mapped to the `INTERVAL` data type
  ([\#151](https://github.com/duckdb/duckdb-r/issues/151)).
- Use latest tests from DBItest
  ([\#148](https://github.com/duckdb/duckdb-r/issues/148)).
- Implement
  [`n_distinct()`](https://dplyr.tidyverse.org/reference/n_distinct.html)
  for multiple arguments using duckdb structs
  ([@lschneiderbauer](https://github.com/lschneiderbauer),
  [\#110](https://github.com/duckdb/duckdb-r/issues/110),
  [\#122](https://github.com/duckdb/duckdb-r/issues/122)).
- Include rfuns extension (hannes/duckdb-rfuns#78,
  [\#144](https://github.com/duckdb/duckdb-r/issues/144)).
- Map `NA` to `SQLNULL`
  ([\#143](https://github.com/duckdb/duckdb-r/issues/143)).

### Bug fixes

- `rel_sql(rel, "{{sql}}")` works even on a read-only database
  ([@Tmonster](https://github.com/Tmonster),
  [\#138](https://github.com/duckdb/duckdb-r/issues/138)).
- Avoid `R CMD check` warning regarding `SETLENGTH()` and
  `SET_TRUELENGTH()`
  ([\#145](https://github.com/duckdb/duckdb-r/issues/145)).

## duckdb 0.10.1

CRAN release: 2024-04-02

### Features

- Update to duckdb v0.10.1, see
  <https://github.com/duckdb/duckdb/releases/tag/v0.10.1> for details.
- Fix shutdown semantics for the driver object created by
  [`duckdb()`](https://r.duckdb.org/reference/duckdb.md). A database
  file is closed (and available to be opened from another session) after
  the last connection that uses this file calls
  [`dbDisconnect()`](https://dbi.r-dbi.org/reference/dbDisconnect.html)
  . The `shutdown` argument to
  [`dbDisconnect()`](https://dbi.r-dbi.org/reference/dbDisconnect.html)
  or the [`duckdb_shutdown()`](https://r.duckdb.org/reference/duckdb.md)
  functions are no longer necessary. Two database connections from the
  same R session can access the same file concurrently in read-write
  mode ([\#124](https://github.com/duckdb/duckdb-r/issues/124)).

### Bug fixes

- Don’t run tests that invoke re2 by default
  ([\#121](https://github.com/duckdb/duckdb-r/issues/121),
  [\#127](https://github.com/duckdb/duckdb-r/issues/127)).

- Fix compilation for R 4.0 and R 4.1, regression introduced in v0.10.0.
  Using `librstrtmgr.a` from UCRT build of rtools40
  ([\#130](https://github.com/duckdb/duckdb-r/issues/130)).

### Internal

- The C++ core is now vendored commit by commit, once every five
  minutes. Vendoring stops if `R CMD check` fails or if a previously
  unreleased tag is reached.

- New maintainer: Kirill Müller.

### Continuous integration

- Add rhub2 workflow.

## duckdb 0.10.0

CRAN release: 2024-03-13

### Bug fixes

- [`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) works
  again when a Parquet or CSV file is passed instead of a table name
  ([\#38](https://github.com/duckdb/duckdb-r/issues/38),
  [\#91](https://github.com/duckdb/duckdb-r/issues/91)).

- [`DBI::dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
  correctly quotes identifiers that start with a digit
  ([\#67](https://github.com/duckdb/duckdb-r/issues/67),
  [\#92](https://github.com/duckdb/duckdb-r/issues/92)).

- Align the argument order of
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  with the DBI specs ([@eitsupi](https://github.com/eitsupi),
  [\#43](https://github.com/duckdb/duckdb-r/issues/43),
  [\#49](https://github.com/duckdb/duckdb-r/issues/49)).

### Features

- New [`tbl_file()`](https://r.duckdb.org/reference/backend-duckdb.md)
  and [`tbl_query()`](https://r.duckdb.org/reference/backend-duckdb.md)
  to explicitly access tables and queries as dbplyr lazy tables
  ([\#96](https://github.com/duckdb/duckdb-r/issues/96)). The `cache`
  argument to [`tbl()`](https://dplyr.tidyverse.org/reference/tbl.html)
  and to the new functions must be named.

- Initial ALTREP support for `LIST` logical type
  ([@romainfrancois](https://github.com/romainfrancois),
  [\#77](https://github.com/duckdb/duckdb-r/issues/77)).

- Update core to duckdb v0.10.0
  ([\#90](https://github.com/duckdb/duckdb-r/issues/90)).

- New private `rel_to_parquet()` to write a relation to parquet
  ([@Tmonster](https://github.com/Tmonster),
  [\#46](https://github.com/duckdb/duckdb-r/issues/46)).

### Chore

- Change directory location for extensions and secrets for v.0.10.0
  release ([@Tmonster](https://github.com/Tmonster),
  [\#73](https://github.com/duckdb/duckdb-r/issues/73)).

- Remove last instance of `default_connection()`
  ([\#50](https://github.com/duckdb/duckdb-r/issues/50)).

### Documentation

- Add list of contributors
  ([\#2](https://github.com/duckdb/duckdb-r/issues/2),
  [\#94](https://github.com/duckdb/duckdb-r/issues/94)).

- Use pkgdown BS5 ([@maelle](https://github.com/maelle),
  [\#31](https://github.com/duckdb/duckdb-r/issues/31),
  [\#70](https://github.com/duckdb/duckdb-r/issues/70)) with DuckDB logo
  ([\#76](https://github.com/duckdb/duckdb-r/issues/76),
  [@romainfrancois](https://github.com/romainfrancois)).

- Link to R documentation page.

- Include `NEWS.md` on CRAN
  ([\#48](https://github.com/duckdb/duckdb-r/issues/48),
  [@olivroy](https://github.com/olivroy)).

### Testing

- Add csv reading test for `duckdb_read_csv(na.strings = )`
  ([@Tmonster](https://github.com/Tmonster),
  [\#10](https://github.com/duckdb/duckdb-r/issues/10)).

- Fix snapshot tests.

- Tweak tests for compatibility with v0.10.0
  ([\#84](https://github.com/duckdb/duckdb-r/issues/84)).

## duckdb 0.9.2-1

CRAN release: 2023-11-28

- Fix compiler warning on R-devel
  ([\#45](https://github.com/duckdb/duckdb-r/issues/45)).

## duckdb 0.9.2

CRAN release: 2023-11-17

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.9.2>.

- Add dbplyr translation for
  [`prod()`](https://rdrr.io/r/base/prod.html)
  ([\#40](https://github.com/duckdb/duckdb-r/issues/40),
  [@m-muecke](https://github.com/m-muecke)).

## duckdb 0.9.1-1

CRAN release: 2023-10-30

- Fix LTO checks on CRAN.

## duckdb 0.9.1

CRAN release: 2023-10-13

- See blog post at
  <https://duckdb.org/2023/09/26/announcing-duckdb-090.html>.

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.9.1>.

- Move sources to <https://github.com/duckdb/duckdb-r>
  ([@krlmlr](https://github.com/krlmlr)).

- Add ADBC integration with the adbcdrivermanager package
  (duckdb/duckdb#8172, [@paleolimbot](https://github.com/paleolimbot)).

- Full support of lists and structs in R (duckdb/duckdb#8503,
  [@krlmlr](https://github.com/krlmlr)).

## duckdb 0.8.1-3

CRAN release: 2023-09-01

- Internal changes to support the duckplyr package.

## duckdb 0.8.1-2

CRAN release: 2023-08-25

- Compatibility with dbplyr.

- Internal changes to support the duckplyr package.

## duckdb 0.8.1-1

CRAN release: 2023-07-17

- Fix CRAN checks.

## duckdb 0.8.1

CRAN release: 2023-06-16

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.8.1>.

## duckdb 0.8.0

CRAN release: 2023-05-23

- See blog post at
  <https://duckdb.org/2023/05/17/announcing-duckdb-080.html>.

## duckdb 0.7.1-1

CRAN release: 2023-03-01

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.7.1>.

## duckdb 0.7.0

CRAN release: 2023-02-14

- See blog post at
  <https://duckdb.org/2023/02/13/announcing-duckdb-070.html>.

## duckdb 0.6.2

CRAN release: 2023-01-16

- New `duckdb_prepare_substrait_json()`.

## duckdb 0.6.1

CRAN release: 2022-12-08

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.6.1>.

## duckdb 0.6.0

CRAN release: 2022-11-25

- See blog post at
  <https://duckdb.org/2022/11/14/announcing-duckdb-060.html>.

## duckdb 0.5.1

CRAN release: 2022-09-20

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.5.1>.

## duckdb 0.5.0

CRAN release: 2022-09-05

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.5.0>.

## duckdb 0.4.0

CRAN release: 2022-06-21

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.4.0>.

## duckdb 0.3.4-1

CRAN release: 2022-06-13

- Minor changes for CRAN compatibility.

## duckdb 0.3.4

CRAN release: 2022-06-05

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.3.4>.

## duckdb 0.3.3

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.3.3>.

## duckdb 0.3.2

CRAN release: 2022-02-07

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.3.2>.

## duckdb 0.3.1

CRAN release: 2021-11-16

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.3.1>.

## duckdb 0.3.0

CRAN release: 2021-10-08

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.3.0>.

- See release notes at
  <https://github.com/duckdb/duckdb/releases/tag/v0.2.9>.

## duckdb 0.2.8

CRAN release: 2021-08-02

This preview release of DuckDB is named “Ceruttii” after a [long-extinct
relative of the present-day Harleqin
Duck](https://en.wikipedia.org/wiki/Harlequin_duck#Taxonomy)
(Histrionicus Ceruttii). Binary builds are listed below. Feedback is
very welcome.

Note: Again, this release introduces a backwards-incompatible change to
the on-disk storage format. We suggest you use the EXPORT DATABASE
command with the old version followed by IMPORT DATABASE with the new
version to migrate your data. See the
[documentation](https://duckdb.org/docs/sql/statements/export) for
details.

#### SQL

- \#2064: `RANGE`/`GENERATE_SERIES` for timestamp + interval
- \#1905: Add `PARQUET_METADATA` and `PARQUET_SCHEMA` functions
- \#2059, [\#1995](https://github.com/duckdb/duckdb-r/issues/1995),
  [\#2020](https://github.com/duckdb/duckdb-r/issues/2020) &
  [\#1960](https://github.com/duckdb/duckdb-r/issues/1960): Window
  `RANGE` framing, `NTH_VALUE` and other improvements

#### APIs

- Many Arrow integration improvements
- Many ODBC driver improvements
- \#1815: Initial version: SQLite UDF API
- \#2001: Support DBConfig in C API

#### Engine

- \#1975, [\#1876](https://github.com/duckdb/duckdb-r/issues/1876) &
  [\#2009](https://github.com/duckdb/duckdb-r/issues/2009): Unified row
  layout for sorting, aggregate & joins
- \#1930 & [\#1904](https://github.com/duckdb/duckdb-r/issues/1904):
  List Storage
- \#2050: CSV Reader/Casting Framework Refactor & add support for
  `TRY_CAST`
- \#1950: Add Constant Segment Compression to Storage
- \#1957: Add pipe/stream file system

## duckdb 0.2.7

CRAN release: 2021-06-14

This preview release of DuckDB is named “Mollissima” after the Common
Eider (Somateria mollissima). Binary builds are listed below. Feedback
is very welcome.

Note: This release introduces a backwards-incompatible change to the
on-disk storage format. We suggest you use the EXPORT DATABASE command
with the old version followed by IMPORT DATABASE with the new version to
migrate your data. See the documentation for details.

Major changes:

SQL - [\#1847](https://github.com/duckdb/duckdb-r/issues/1847): Unify
catalog access functions, and provide views for common PostgreSQL
catalog functions -
[\#1822](https://github.com/duckdb/duckdb-r/issues/1822):
Python/JSON-Style Struct & List Syntax -
[\#1862](https://github.com/duckdb/duckdb-r/issues/1862):
[\#1584](https://github.com/duckdb/duckdb-r/issues/1584) Implementing
`NEXTAFTER` for float and double -
[\#1860](https://github.com/duckdb/duckdb-r/issues/1860): `FIRST`
implementation for nested types -
[\#1858](https://github.com/duckdb/duckdb-r/issues/1858): `UNNEST` table
function & array syntax in parser -
[\#1761](https://github.com/duckdb/duckdb-r/issues/1761): Issue
[\#1746](https://github.com/duckdb/duckdb-r/issues/1746): Moving
`QUANTILE`

APIs

- \#1852, [\#1840](https://github.com/duckdb/duckdb-r/issues/1840),
  [\#1831](https://github.com/duckdb/duckdb-r/issues/1831),
  [\#1819](https://github.com/duckdb/duckdb-r/issues/1819) and
  [\#1779](https://github.com/duckdb/duckdb-r/issues/1779): Improvements
  to Arrow Integration
- \#1843: First iteration of ODBC driver
- \#1832: Add visualizer extension
- \#1803: Converting Nested Types to native python
- \#1773: Add support for key/value style configuration, and expose this
  in the Python API

Engine - [\#1808](https://github.com/duckdb/duckdb-r/issues/1808):
Row-Group Based Storage -
[\#1842](https://github.com/duckdb/duckdb-r/issues/1842): Add
(Persistent) Struct Storage Support -
[\#1859](https://github.com/duckdb/duckdb-r/issues/1859): Read and write
atomically with offsets -
[\#1851](https://github.com/duckdb/duckdb-r/issues/1851): Internal Type
Rework - [\#1845](https://github.com/duckdb/duckdb-r/issues/1845):
Nested join payloads -
[\#1813](https://github.com/duckdb/duckdb-r/issues/1813): Aggregate Row
Layout - [\#1836](https://github.com/duckdb/duckdb-r/issues/1836): Join
Row Layout - [\#1804](https://github.com/duckdb/duckdb-r/issues/1804):
Use Allocator class in buffer manager and add a test for a custom
allocator usage

## duckdb 0.2.6

CRAN release: 2021-05-09

This preview release of DuckDB is named “Jamaicensis” after the
[blue-billed Ruddy Duck (Oxyura
jamaicensis)](https://en.wikipedia.org/wiki/Ruddy_duck). Binary builds
are listed below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the
on-disk storage format. We suggest you use the EXPORT DATABASE command
with the old version followed by IMPORT DATABASE with the new version to
migrate your data. See the documentation for details.

Also note: Due to changes in the internal storage
([\#1530](https://github.com/duckdb/duckdb-r/issues/1530)), databases
created with this release wil require somewhat more disk space. This is
transient as we are working hard to finalise the on-disk storage format.

Major changes:

Engine - [\#1666](https://github.com/duckdb/duckdb-r/issues/1666):
External merge sort,
[\#1580](https://github.com/duckdb/duckdb-r/issues/1580): Parallel scan
of ordered result and
[\#1561](https://github.com/duckdb/duckdb-r/issues/1561): Rework
physical ORDER BY -
[\#1520](https://github.com/duckdb/duckdb-r/issues/1520) &
[\#1574](https://github.com/duckdb/duckdb-r/issues/1574): Window
function computation parallelism -
[\#1540](https://github.com/duckdb/duckdb-r/issues/1540): Add table
functions that take a subquery parameter -
[\#1533](https://github.com/duckdb/duckdb-r/issues/1533): Using vectors,
instead of column chunks as lists -
[\#1530](https://github.com/duckdb/duckdb-r/issues/1530): Store null
values separate from main data in a Validity Segment

SQL - [\#1568](https://github.com/duckdb/duckdb-r/issues/1568):
Positional Reference Operator `#1` etc. -
[\#1671](https://github.com/duckdb/duckdb-r/issues/1671): `QUANTILE`
variants and [\#1685](https://github.com/duckdb/duckdb-r/issues/1685):
Temporal quantiles -
[\#1695](https://github.com/duckdb/duckdb-r/issues/1695): New Timestamp
Types `TIMESTAMP_NS`, `TIMESTAMP_MS` and `TIMESTAMP_NS` -
[\#1647](https://github.com/duckdb/duckdb-r/issues/1647): Add support
for UTC offset timestamp parsing to regular timestamp conversion -
[\#1659](https://github.com/duckdb/duckdb-r/issues/1659): Add support
for `USING` keyword in `DELETE` statement -
[\#1638](https://github.com/duckdb/duckdb-r/issues/1638),
[\#1663](https://github.com/duckdb/duckdb-r/issues/1663),
[\#1621](https://github.com/duckdb/duckdb-r/issues/1621) &
[\#1484](https://github.com/duckdb/duckdb-r/issues/1484): Many changes
arount `ARRAY` syntax -
[\#1610](https://github.com/duckdb/duckdb-r/issues/1610): Add support
for `CURRVAL` -
[\#1544](https://github.com/duckdb/duckdb-r/issues/1544): Add `SKIP` as
an option to `READ_CSV` and `COPY`

APIs - [\#1525](https://github.com/duckdb/duckdb-r/issues/1525): Add
loadable extensions support -
[\#1711](https://github.com/duckdb/duckdb-r/issues/1711): Parallel Arrow
Scans - [\#1569](https://github.com/duckdb/duckdb-r/issues/1569):
Map-style UDFs for Python API -
[\#1534](https://github.com/duckdb/duckdb-r/issues/1534): Extensible
Replacement Scans & Automatic Pandas Scans and
[\#1487](https://github.com/duckdb/duckdb-r/issues/1487): Automatically
use parquet or CSV scan when using a table name that ends in `.parquet`
or `.csv` - [\#1649](https://github.com/duckdb/duckdb-r/issues/1649):
Add a QueryRelation object that can be used to convert a query directly
into a relation object,
[\#1665](https://github.com/duckdb/duckdb-r/issues/1665): Adding
from_query to python api -
[\#1550](https://github.com/duckdb/duckdb-r/issues/1550): Shell: Add
support for Ctrl + arrow keys to linenoise, and make Ctrl+C terminate
the current query instead of the process -
[\#1514](https://github.com/duckdb/duckdb-r/issues/1514): Using `ALTREP`
to speed up string column transfer to R -
[\#1502](https://github.com/duckdb/duckdb-r/issues/1502): R:
implementation of Rstudio connection-contract tab

## duckdb 0.2.5

CRAN release: 2021-03-16

This preview release of DuckDB is named “Falcata” after the Falcated
Duck (Mareca falcata). Binary builds are listed below. Feedback is very
welcome.

Note: This release introduces a backwards-incompatible change to the
on-disk storage format. We suggest you use the EXPORT DATABASE command
with the old version followed by IMPORT DATABASE with the new version to
migrate your data. See the documentation for details.

Major Changes:

Engine - [\#1356](https://github.com/duckdb/duckdb-r/issues/1356):
**Incremental Checkpointing** -
[\#1422](https://github.com/duckdb/duckdb-r/issues/1422): Optimize Top N
Implementation

SQL - [\#1406](https://github.com/duckdb/duckdb-r/issues/1406),
[\#1372](https://github.com/duckdb/duckdb-r/issues/1372),
[\#1387](https://github.com/duckdb/duckdb-r/issues/1387): Many, many new
aggregate functions -
[\#1460](https://github.com/duckdb/duckdb-r/issues/1460): `QUANTILE`
aggregate variant that takes a list of quantiles &
[\#1346](https://github.com/duckdb/duckdb-r/issues/1346): Approximate
Quantiles - [\#1461](https://github.com/duckdb/duckdb-r/issues/1461):
`JACCARD`, [\#1441](https://github.com/duckdb/duckdb-r/issues/1441)
`LEVENSHTEIN` & `HAMMING` distance scalar function -
[\#1370](https://github.com/duckdb/duckdb-r/issues/1370): `FACTORIAL`
scalar function and ! postfix operator -
[\#1363](https://github.com/duckdb/duckdb-r/issues/1363):
`IS (NOT) DISTINCT FROM` -
[\#1385](https://github.com/duckdb/duckdb-r/issues/1385): `LIST_EXTRACT`
to get a single element from a list -
[\#1361](https://github.com/duckdb/duckdb-r/issues/1361): Aliases in the
`HAVING` clause (fixes issue
[\#1358](https://github.com/duckdb/duckdb-r/issues/1358)) -
[\#1355](https://github.com/duckdb/duckdb-r/issues/1355): Limit clause
with non constant values

APIs: - [\#1430](https://github.com/duckdb/duckdb-r/issues/1430) &
[\#1424](https://github.com/duckdb/duckdb-r/issues/1424): **DuckDB WASM
builds** - [\#1419](https://github.com/duckdb/duckdb-r/issues/1419):
Exporting the appender api to C -
[\#1408](https://github.com/duckdb/duckdb-r/issues/1408): Add blob
support to C API -
[\#1432](https://github.com/duckdb/duckdb-r/issues/1432),
[\#1459](https://github.com/duckdb/duckdb-r/issues/1459) &
[\#1456](https://github.com/duckdb/duckdb-r/issues/1456): Progress Bar -
[\#1440](https://github.com/duckdb/duckdb-r/issues/1440): Detailed
profiler.

## duckdb 0.2.4

CRAN release: 2021-02-02

This preview release of DuckDB is named “Jubata” after the [Australian
Wood Duck](https://en.wikipedia.org/wiki/Australian_wood_duck)
(Chenonetta jubata). Binary builds are listed below. Feedback is very
welcome.

Note: This release introduces a backwards-incompatible change to the
on-disk storage format. We suggest you use the EXPORT DATABASE command
with the old version followed by IMPORT DATABASE with the new version to
migrate your data. See the documentation for details.

Major changes: SQL -
[\#1231](https://github.com/duckdb/duckdb-r/issues/1231): Full Text
Search extension -
[\#1309](https://github.com/duckdb/duckdb-r/issues/1309): Filter Clause
for Aggregates -
[\#1195](https://github.com/duckdb/duckdb-r/issues/1195): `SAMPLE`
Operator - [\#1244](https://github.com/duckdb/duckdb-r/issues/1244):
`SHOW` select queries -
[\#1301](https://github.com/duckdb/duckdb-r/issues/1301): `CHR` and
`ASCII` functions &
[\#1252](https://github.com/duckdb/duckdb-r/issues/1252): Add `GAMMA`
and `LGAMMA` functions

Engine - [\#1211](https://github.com/duckdb/duckdb-r/issues/1211):
(Mostly) Lock-Free Buffer Manager -
[\#1325](https://github.com/duckdb/duckdb-r/issues/1325): Unsigned
Integer Types Support -
[\#1229](https://github.com/duckdb/duckdb-r/issues/1229): Filter Pull Up
Optimizer - [\#1296](https://github.com/duckdb/duckdb-r/issues/1296):
Optimizer that removes redundant `DELIM_GET` and `DELIM_JOIN`
operators - [\#1219](https://github.com/duckdb/duckdb-r/issues/1219):
`DATE`, `TIME` and `TIMESTAMP` rework: move to epoch format &
microsecond support

Clients - [\#1287](https://github.com/duckdb/duckdb-r/issues/1287) and
[\#1275](https://github.com/duckdb/duckdb-r/issues/1275): Improving JDBC
compatibility -
[\#1260](https://github.com/duckdb/duckdb-r/issues/1260): Rework client
API and prepared statements, and improve DuckDB -\> Pandas conversion -
[\#1230](https://github.com/duckdb/duckdb-r/issues/1230): Add support
for parallel scanning of pandas data frames -
[\#1256](https://github.com/duckdb/duckdb-r/issues/1256): JNI appender -
[\#1209](https://github.com/duckdb/duckdb-r/issues/1209): Write shell
history to file when added to allow crash recovery, and fix crash when
.importing file with invalid -
[\#1204](https://github.com/duckdb/duckdb-r/issues/1204): Add support
for blobs to the R API and
[\#1202](https://github.com/duckdb/duckdb-r/issues/1202): Add blob
support to the python api

Parquet - [\#1314](https://github.com/duckdb/duckdb-r/issues/1314):
Refactor and nested types support for Parquet Reader

## duckdb 0.2.3

CRAN release: 2020-12-12

This preview release of DuckDB is named “Serrator” after the
Red-breasted merganser (Mergus serrator). Binary builds are listed
below. Feedback is very welcome.

Note: This release introduces a backwards-incompatible change to the
on-disk storage format. We suggest you use the EXPORT DATABASE command
with the old version followed by IMPORT DATABASE with the new version to
migrate your data. See the documentation for details.

Major changes:

SQL: - [\#1179](https://github.com/duckdb/duckdb-r/issues/1179):
Interval Cleanup & Extended `INTERVAL` Syntax -
[\#1147](https://github.com/duckdb/duckdb-r/issues/1147): Add exact
`MEDIAN` and `QUANTILE` functions -
[\#1129](https://github.com/duckdb/duckdb-r/issues/1129): Support scalar
functions with `CREATE FUNCTION` -
[\#1137](https://github.com/duckdb/duckdb-r/issues/1137): Add support
for (`NOT`) `ILIKE`, and optimize certain types of `LIKE` expressions

Engine - [\#1160](https://github.com/duckdb/duckdb-r/issues/1160):
Perfect Aggregate Hash Tables -
[\#1133](https://github.com/duckdb/duckdb-r/issues/1133): Statistics
Rework & Statistics Propagation -
[\#1144](https://github.com/duckdb/duckdb-r/issues/1144): Common
Aggregate Optimizer,
[\#1143](https://github.com/duckdb/duckdb-r/issues/1143): CSE Optimizer
and [\#1135](https://github.com/duckdb/duckdb-r/issues/1135): Optimizing
expressions in grouping keys -
[\#1138](https://github.com/duckdb/duckdb-r/issues/1138): Use
predication in filters -
[\#1071](https://github.com/duckdb/duckdb-r/issues/1071): Removing
string null termination requirement

Clients - [\#1112](https://github.com/duckdb/duckdb-r/issues/1112): Add
DuckDB node.js API -
[\#1168](https://github.com/duckdb/duckdb-r/issues/1168): Add support
for Pandas category types -
[\#1181](https://github.com/duckdb/duckdb-r/issues/1181): Extend
DuckDB::LibraryVersion() to output dev version in format `0.2.3-devXXX`
& [\#1176](https://github.com/duckdb/duckdb-r/issues/1176): Python
binding: Add module attributes for introspecting DuckDB version

Parquet Reader: -
[\#1183](https://github.com/duckdb/duckdb-r/issues/1183): Filter
pushdown for Parquet reader -
[\#1167](https://github.com/duckdb/duckdb-r/issues/1167): Exporting
Parquet statistics to DuckDB -
[\#1162](https://github.com/duckdb/duckdb-r/issues/1162): Add support
for compression codec in Parquet writer &
[\#1163](https://github.com/duckdb/duckdb-r/issues/1163): Add ZSTD
Compression Code and add ZSTD codec as option for Parquet export -
[\#1103](https://github.com/duckdb/duckdb-r/issues/1103): Add object
cache and Parquet metadata cache

## duckdb 0.2.2

CRAN release: 2020-11-03

This is a preview release of DuckDB. Starting from this release,
releases get named as well. Names are chosen from species of ducks (of
course). We start with “Clypeata”.

*Note*: This release introduces a backwards-incompatible change to the
on-disk storage format. We suggest you use the `EXPORT DATABASE` command
with the old version followed by `IMPORT DATABASE` with the new version
to migrate your data. See the
[documentation](https://duckdb.org/docs/sql/statements/export) for
details.

Binary builds are listed below. Feedback is very welcome. Major changes:

SQL - [\#1057](https://github.com/duckdb/duckdb-r/issues/1057): Add
PRAGMA for enabling/disabling optimizer & extend output for query
graph - [\#1048](https://github.com/duckdb/duckdb-r/issues/1048): Allow
CTEs in subqueries (including CTEs themselves) and
[\#987](https://github.com/duckdb/duckdb-r/issues/987): Allow CTEs in
CREATE VIEW statements -
[\#1046](https://github.com/duckdb/duckdb-r/issues/1046): Prettify
Explain/Query Profiler output -
[\#1037](https://github.com/duckdb/duckdb-r/issues/1037): Support FROM
clauses in UPDATE statements -
[\#1006](https://github.com/duckdb/duckdb-r/issues/1006): STRING_SPLIT
and STRING_SPLIT_REGEX SQL functions -
[\#1000](https://github.com/duckdb/duckdb-r/issues/1000): Implement MD5
function - [\#936](https://github.com/duckdb/duckdb-r/issues/936): Add
GLOB support to Parquet & CSV readers -
[\#899](https://github.com/duckdb/duckdb-r/issues/899): Table functions
information_schema_schemata() and information_schema_tables() and
[\#903](https://github.com/duckdb/duckdb-r/issues/903): Add table
function information_schema_columns()

Engine - [\#984](https://github.com/duckdb/duckdb-r/issues/984):
Parallel grouped aggregations and
[\#1045](https://github.com/duckdb/duckdb-r/issues/1045): Some
performance fixes for aggregate hash table -
[\#1008](https://github.com/duckdb/duckdb-r/issues/1008): Index Join -
[\#991](https://github.com/duckdb/duckdb-r/issues/991): Local Storage
Rework: Per-morsel version info and flush intermediate chunks to the
base tables - [\#906](https://github.com/duckdb/duckdb-r/issues/906):
Parallel scanning of single Parquet files and
[\#982](https://github.com/duckdb/duckdb-r/issues/982): ZSTD Support in
Parquet library -
[\#883](https://github.com/duckdb/duckdb-r/issues/883): Unify Table
Scans with Table Functions -
[\#873](https://github.com/duckdb/duckdb-r/issues/873): TPC-H
Extension - [\#884](https://github.com/duckdb/duckdb-r/issues/884):
Remove NFC-normalization requirement for all data and add COLLATE NFC

Client - [\#1001](https://github.com/duckdb/duckdb-r/issues/1001):
Dynamic Syntax Highlighting in Shell -
[\#933](https://github.com/duckdb/duckdb-r/issues/933): Upgrade shell.c
to 3330000 - [\#918](https://github.com/duckdb/duckdb-r/issues/918): Add
in support for Python datetime types in bindings -
[\#950](https://github.com/duckdb/duckdb-r/issues/950): Support dates
and times output into arrow -
[\#893](https://github.com/duckdb/duckdb-r/issues/893): Support for
Arrow NULL columns

## duckdb 0.2.1

CRAN release: 2020-09-10

This is a preview release of DuckDB. Binary builds are listed below.
Feedback is very welcome. Major changes:

Engine - [\#770](https://github.com/duckdb/duckdb-r/issues/770): Enable
Inter-Pipeline Parallelism -
[\#835](https://github.com/duckdb/duckdb-r/issues/835): Type system
updates with [\#779](https://github.com/duckdb/duckdb-r/issues/779):
`INTERVAL` Type, [\#858](https://github.com/duckdb/duckdb-r/issues/858):
Fixed-precision `DECIMAL` types &
[\#819](https://github.com/duckdb/duckdb-r/issues/819): `HUGEINT` type -
[\#790](https://github.com/duckdb/duckdb-r/issues/790): Parquet write
support

API - [\#866](https://github.com/duckdb/duckdb-r/issues/866): Initial
Arrow support - [\#809](https://github.com/duckdb/duckdb-r/issues/809):
Aggregate UDF support with
[\#843](https://github.com/duckdb/duckdb-r/issues/843): Generic
`CreateAggregateFunction()` &
[\#752](https://github.com/duckdb/duckdb-r/issues/752):
`CreateVectorizedFunction()` using only template parameters

SQL - [\#824](https://github.com/duckdb/duckdb-r/issues/824): `strftime`
and `strptime` - [\#858](https://github.com/duckdb/duckdb-r/issues/858):
`EXPORT DATABASE` and `IMPORT DATABASE` -
[\#832](https://github.com/duckdb/duckdb-r/issues/832): read_csv(\_auto)
improvements: optional parameters, configurable sample size, line number
info

## duckdb 0.2.0

This is a preview release of DuckDB. Binary builds are listed below.
Feedback is very welcome.

SQL: - [\#730](https://github.com/duckdb/duckdb-r/issues/730):
`FULL OUTER JOIN` Support -
[\#732](https://github.com/duckdb/duckdb-r/issues/732): Support for
`NULLS FIRST`/`NULLS LAST` -
[\#698](https://github.com/duckdb/duckdb-r/issues/698): Add
implementation of the `LEAST`/`GREATEST` functions -
[\#772](https://github.com/duckdb/duckdb-r/issues/772): Implement `TRIM`
function and add optional second parameter to `RTRIM`/`LTRIM`/`TRIM` -
[\#771](https://github.com/duckdb/duckdb-r/issues/771): Extended Regex
Options

Clients: - Python:
[\#720](https://github.com/duckdb/duckdb-r/issues/720): Making Pandas
optional and add support for PyPy - C++:
[\#712](https://github.com/duckdb/duckdb-r/issues/712): C++ UDF API

## duckdb 0.1.9

This is a preview release of DuckDB. Binary are listed below. Feedback
is very welcome. Major changes: New [website](https://duckdb.org/)
[woo-ho](https://www.youtube.com/watch?v=H9cmPE88a_0)!

Engine - [\#653](https://github.com/duckdb/duckdb-r/issues/653): Parquet
reader integration

SQL - [\#685](https://github.com/duckdb/duckdb-r/issues/685): Case
insensitive binding of column names -
[\#662](https://github.com/duckdb/duckdb-r/issues/662): add `EPOCH_MS`
function and test cases

Clients - [\#681](https://github.com/duckdb/duckdb-r/issues/681): JDBC
Read-only mode for and
[\#677](https://github.com/duckdb/duckdb-r/issues/677) duplicate()\`
method to allow multiple connections to same database

## duckdb 0.1.8

This is a preview release of DuckDB. Feedback is very welcome.

SQL - SQL functions `IF` and `IFNULL`
[\#644](https://github.com/duckdb/duckdb-r/issues/644) - SQL string
functions `LEFT` [\#620](https://github.com/duckdb/duckdb-r/issues/620)
and `RIGHT` [\#631](https://github.com/duckdb/duckdb-r/issues/631) -
[\#641](https://github.com/duckdb/duckdb-r/issues/641): `BLOB` type
support - [\#640](https://github.com/duckdb/duckdb-r/issues/640): `LIKE`
escape support

Clients - [\#627](https://github.com/duckdb/duckdb-r/issues/627):
Insertion support for Python relation API

## duckdb 0.1.7

This is the sixth preview release of DuckDB. Feedback is very welcome.
Binary builds are available as well.

SQL - [Add / remove columns, change default values & column
type](https://duckdb.org/docs/sql/statements/alter_table)
[\#612](https://github.com/duckdb/duckdb-r/issues/612) - [Collation
support](https://duckdb.org/docs/sql/expressions/collations) - CSV
sniffer `READ_CSV_AUTO` for dialect, data type and header detection
[\#582](https://github.com/duckdb/duckdb-r/issues/582) - `SHOW` &
`DESCRIBE` Tables
[\#501](https://github.com/duckdb/duckdb-r/issues/501) - String function
`CONTAINS` [\#488](https://github.com/duckdb/duckdb-r/issues/488) -
String functions `LPAD` / `RPAD`, `LTRIM` / `RTRIM`, `REPEAT`, `REPLACE`
& `UNICODE` [\#597](https://github.com/duckdb/duckdb-r/issues/597) - Bit
functions `BIT_LENGTH`, `BIT_COUNT`, `BIT_AND`, `BIT_OR`, `BIT_XOR` &
`BIT_AGG` [\#608](https://github.com/duckdb/duckdb-r/issues/608)

Engine - `LIKE` optimization rules
[\#559](https://github.com/duckdb/duckdb-r/issues/559) - Adaptive
filters in table scans
[\#574](https://github.com/duckdb/duckdb-r/issues/574) - ICU Extension
for extended Collations & Extension Support
[\#594](https://github.com/duckdb/duckdb-r/issues/594) - Extended zone
map support in scans
[\#551](https://github.com/duckdb/duckdb-r/issues/551) - Disallow
NaN/INF in the system
[\#541](https://github.com/duckdb/duckdb-r/issues/541) - Use UTF
Grapheme Cluster Breakers in Reverse and Shell
[\#570](https://github.com/duckdb/duckdb-r/issues/570)

Clients - Relation API for C++
[\#509](https://github.com/duckdb/duckdb-r/issues/509) and Python
[\#598](https://github.com/duckdb/duckdb-r/issues/598) - Java (TM) JDBC
(R) Client for DuckDB
[\#492](https://github.com/duckdb/duckdb-r/issues/492)
[\#520](https://github.com/duckdb/duckdb-r/issues/520)
[\#550](https://github.com/duckdb/duckdb-r/issues/550)

## duckdb 0.1.6

This is the fifth preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
<http://download.duckdb.org/alias/v0.1.6/>

SQL - [\#455](https://github.com/duckdb/duckdb-r/issues/455) Table
renames `ALTER TABLE tbl RENAME TO tbl2` -
[\#457](https://github.com/duckdb/duckdb-r/issues/457) Nested list type
can be created using `LIST` aggregation and unpacked with the new
`UNNEST` operator -
[\#463](https://github.com/duckdb/duckdb-r/issues/463) `INSTR` string
function, [\#477](https://github.com/duckdb/duckdb-r/issues/477)
`PREFIX` string function,
[\#480](https://github.com/duckdb/duckdb-r/issues/480) `SUFFIX` string
function

Engine - [\#442](https://github.com/duckdb/duckdb-r/issues/442)
Optimized casting performance to strings -
[\#444](https://github.com/duckdb/duckdb-r/issues/444) Variable return
types for table-producing functions -
[\#453](https://github.com/duckdb/duckdb-r/issues/453) Rework aggregate
function interface -
[\#474](https://github.com/duckdb/duckdb-r/issues/474) Selection vector
rework - [\#478](https://github.com/duckdb/duckdb-r/issues/478) UTF8 NFC
normalization of all incoming strings -
[\#482](https://github.com/duckdb/duckdb-r/issues/482) Skipping table
segments during scan based on min/max indices

Python client - [\#451](https://github.com/duckdb/duckdb-r/issues/451)
`date` / `datetime` support -
[\#467](https://github.com/duckdb/duckdb-r/issues/467) `description`
field for cursor -
[\#473](https://github.com/duckdb/duckdb-r/issues/473) Adding
`read_only` flag to `connect` -
[\#481](https://github.com/duckdb/duckdb-r/issues/481) Rewrite of Python
API using `pybind11`

R client - [\#468](https://github.com/duckdb/duckdb-r/issues/468)
Support for prepared statements in R client -
[\#479](https://github.com/duckdb/duckdb-r/issues/479) Adding automatic
CSV to table function `read_csv_duckdb` -
[\#483](https://github.com/duckdb/duckdb-r/issues/483) Direct scan
operator for R `data.frame` objects

## duckdb 0.1.5

This is the fourth preview release of DuckDB. Feedback is very welcome.
Note: The v0.1.4 version was skipped because of a Python packaging
issue.

Binary builds can be found here:
<http://download.duckdb.org/rev/59f8907b5d89268c158ae1774d77d6314a5c075f/>

Major changes: - [\#409](https://github.com/duckdb/duckdb-r/issues/409)
Vector Overhaul - [\#423](https://github.com/duckdb/duckdb-r/issues/423)
Remove individual vector cardinalities -
[\#418](https://github.com/duckdb/duckdb-r/issues/418) `DATE_TRUNC` SQL
function - [\#424](https://github.com/duckdb/duckdb-r/issues/424)
`REVERSE` SQL function -
[\#416](https://github.com/duckdb/duckdb-r/issues/416) Support for
`SELECT table.* FROM table` -
[\#414](https://github.com/duckdb/duckdb-r/issues/414) STRUCT types in
query execution - [\#431](https://github.com/duckdb/duckdb-r/issues/431)
Changed internal string representation -
[\#433](https://github.com/duckdb/duckdb-r/issues/433) Rename internal
type `index_t` to `idx_t` -
[\#439](https://github.com/duckdb/duckdb-r/issues/439) Support for
temporary structures in read-only mode -
[\#440](https://github.com/duckdb/duckdb-r/issues/440) Builds on Solaris
& OpenBSD

*Note*: This release contains a bug in the Python API that leads to
crashes when fetching strings to NumPy/Pandas
[\#447](https://github.com/duckdb/duckdb-r/issues/447)

## duckdb 0.1.3

This is the third preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
<http://download.duckdb.org/rev/59f8907b5d89268c158ae1774d77d6314a5c075f/>

Major changes: \* [\#388](https://github.com/duckdb/duckdb-r/issues/388)
Major updates to shell \*
[\#390](https://github.com/duckdb/duckdb-r/issues/390) Unused Column &
Column Lifetime Optimizers \*
[\#402](https://github.com/duckdb/duckdb-r/issues/402) String and
compound keys in indices/primary keys \*
[\#406](https://github.com/duckdb/duckdb-r/issues/406) Adaptive
reordering of filter expressions

## duckdb 0.1.2

This is the third preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
<http://download.duckdb.org/rev/6fcb5ef8e91dcb3c9b2c4ca86dab3b1037446b24/>

## duckdb 0.1.1

This is the second preview release of DuckDB. Feedback is very welcome.
Binary builds can be found here:
<http://download.duckdb.org/rev/2e51e9bae7699853420851d3d2237f232fc2a9a8/>

## duckdb 0.1.0

This is the first preview release of DuckDB. Feedback is very welcome.

Binary builds can be found here:
<http://download.duckdb.org/rev/c1cbc9d0b5f98a425bfb7edb5e6c59b5d10550e4/>
