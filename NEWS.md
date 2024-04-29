<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# duckdb 0.10.1.9002

## Bug fixes

- `rel_sql(rel, "{{sql}}")` works even on a read-only database (@Tmonster, #138).

- Avoid `R CMD check` warning regarding `SETLENGTH()` and `SET_TRUELENGTH()` (#145).

- Fix vendoring script without arguments, align.

## Features

- Use latest tests from DBItest (#148).

- Implement `n_distinct()` for multiple arguments using duckdb structs (@lschneiderbauer, #110, #122).

- Include rfuns extension (hannes/duckdb-rfuns#78, #144).

- Map `NA` to `SQLNULL` (#143).

## Chore

- Update vendored sources (tag v0.10.2) to duckdb/duckdb@1601d94f94a7e0d2eb805a94803eb1e3afbbe4ed.

- Update vendored sources to duckdb/duckdb@1601d94f94a7e0d2eb805a94803eb1e3afbbe4ed.

  Merge pull request duckdb/duckdb#11681 from Maxxen/bump-vss
  Merge pull request duckdb/duckdb#11682 from Mytherin/shellutf8

- Update vendored sources to duckdb/duckdb@d7d6f9830ed14d50f27c0ff4a45e5938c7ae22f3.

  Merge pull request duckdb/duckdb#11678 from Mytherin/pivotcaseinsensitivity

- Update vendored sources to duckdb/duckdb@1253581f091b4617cba10e573f25eb5c5626253d.

  Merge pull request duckdb/duckdb#11676 from Mytherin/hivetypesautocast

- Update vendored sources to duckdb/duckdb@f67f77c604296427b1dbfd666afb47bcc24afc87.

  Merge pull request duckdb/duckdb#11674 from Mytherin/issue11484

- Update vendored sources to duckdb/duckdb@e9c94226867a68e2d747e4c309412a2acb2ca0a3.

  Merge pull request duckdb/duckdb#11675 from pdet/decimal_auto
  Merge pull request duckdb/duckdb#11672 from carlopi/fix_version_remote

- Update vendored sources to duckdb/duckdb@49ea721f39c9d2029212919cb620609ae9927401.

  Merge pull request duckdb/duckdb#11665 from Mytherin/unionbynametypes

- Update vendored sources to duckdb/duckdb@5960154dcce5a1119eb0abcabb40c1ffa5733989.

  Merge pull request duckdb/duckdb#11670 from Mytherin/fixissue11542

- Update vendored sources to duckdb/duckdb@3c7ad7001e271f32b11bb233143d1e03df2a47b1.

  Merge pull request duckdb/duckdb#11671 from Mytherin/valgrindfix
  Merge pull request duckdb/duckdb#11653 from pdet/adbc_py9

- Update vendored sources to duckdb/duckdb@846ef2c59a6723b601bcdc9ee236b73b402d29c5.

  Merge pull request duckdb/duckdb#11668 from Mytherin/issue11467

- Update vendored sources to duckdb/duckdb@9934420aec07701ff9c3701226fbc1a15b2ac0a5.

  Merge pull request duckdb/duckdb#11667 from Mytherin/issue11469

- Update vendored sources to duckdb/duckdb@5bcfd7434790fabb0ea99998abb78e3a31bad47a.

  Merge pull request duckdb/duckdb#11663 from zmbc/include-falloc

- Update vendored sources to duckdb/duckdb@9a3cc6aecb460fe0755febaf48e095406c3a2e62.

  Merge pull request duckdb/duckdb#11616 from pdet/multiple_nullstr
  Merge pull request duckdb/duckdb#11662 from carlopi/patches
  Merge pull request duckdb/duckdb#11658 from chrisiou/support-gzipped-files

- Update vendored sources to duckdb/duckdb@f37773d43c201fd1013364190357f9a101452832.

  Merge pull request duckdb/duckdb#11659 from Maxxen/initialize-unknown-index-on-lookup

- Update vendored sources to duckdb/duckdb@7b8f79469443760ab76e103211175a732789d085.

  Merge pull request duckdb/duckdb#11656 from Tishj/statement_copy_verification

- Update vendored sources to duckdb/duckdb@076daa998f351130195d4920e03facd876235aaa.

  Merge pull request duckdb/duckdb#11655 from Mytherin/limitbatchinsertthreads

- Update vendored sources to duckdb/duckdb@22cdf0a7f9208f32903b081a1b9bf2284b57f6dc.

  Merge pull request duckdb/duckdb#11465 from Tishj/fix_duckdb_sequences_last_value

- Update vendored sources to duckdb/duckdb@4476a915db79cfb142acc5f3362d9069093b5877.

  Merge pull request duckdb/duckdb#11645 from wangxiaoying/ec0
  Merge pull request duckdb/duckdb#11652 from carlopi/no_macos_codesign_extensions

- Update vendored sources to duckdb/duckdb@acfcf5185f4557a15a518ed9e822a498534a1d2d.

  Merge pull request duckdb/duckdb#11650 from Maxxen/bump-spatial

- Update vendored sources to duckdb/duckdb@ee9802db9ff339c3b1e6d45944508c3672d2e023.

  Merge pull request duckdb/duckdb#11648 from Mytherin/fuzzerissues3
  Merge pull request duckdb/duckdb#11646 from Mause/bugfix/jdbc-parameter-types

- Update vendored sources to duckdb/duckdb@38dd6c56d814b76cd382bf274a2c53b8a5380c9a.

  Merge pull request duckdb/duckdb#11642 from Mytherin/fuzzerissues2

- Update vendored sources to duckdb/duckdb@b2d51518c83685ce3777295ad0e091e6fbc14a04.

  Merge pull request duckdb/duckdb#11630 from pdet/gz_buffers
  Merge pull request duckdb/duckdb#11635 from motherduckdb/flo/fix-scripts-path-cmake

- Update vendored sources to duckdb/duckdb@e0c4d9c4dcb08573dba54df18a460ad8606ac9a0.

  Merge pull request duckdb/duckdb#11631 from pdet/recursive
  Merge pull request duckdb/duckdb#11628 from carlopi/fix_extension_config
  Merge pull request duckdb/duckdb#11629 from carlopi/metadata_fix

- Update vendored sources to duckdb/duckdb@c54063a9a56747e7a57bba93a4ba7d05eb86306e.

  Merge pull request duckdb/duckdb#11614 from Maxxen/add-vss
  Merge pull request duckdb/duckdb#11490 from carlopi/docker_scripts
  Merge pull request duckdb/duckdb#11626 from carlopi/upload_pyodide

- Update vendored sources to duckdb/duckdb@5277974b7e15e4ccc3a8a5a04b0d9bce8f397600.

  Merge pull request duckdb/duckdb#11462 from Tishj/create_index_to_string

- Update vendored sources to duckdb/duckdb@ec84e37ae1b81f67b52f9289c48e5d9fd9a1b3d1.

  Merge pull request duckdb/duckdb#11515 from carlopi/extension_metadata

- Update vendored sources to duckdb/duckdb@55607c05dffda52ca0fea42994632e26d2aa167d.

  Merge pull request duckdb/duckdb#11619 from carlopi/checked_dyn_casts
  Merge pull request duckdb/duckdb#11531 from cpcloud/pyodide

- Update vendored sources to duckdb/duckdb@8116e65f1c86be9eecdb78f17b686de6244b54ae.

  Merge pull request duckdb/duckdb#11618 from joellubi/adbc-getobjects-no-filter
  Merge pull request duckdb/duckdb#11623 from Tishj/modular_extension_entries_generation

- Update vendored sources to duckdb/duckdb@9e97aa38b7f3bb2e52b778ffdd09789d4eafde93.

  Merge pull request duckdb/duckdb#11622 from Mytherin/fuzzerissues
  Merge pull request duckdb/duckdb#11610 from guenp/guenp/fix-timestamp-is-date

- Update vendored sources to duckdb/duckdb@b9199653c3acc0e627c55b99724c636b13f80a7d.

  Merge pull request duckdb/duckdb#11613 from Mytherin/ossfuzz

- Update vendored sources to duckdb/duckdb@e5f45238740e8c8fef3d22ee61f6b7faf950c05d.

  Merge pull request duckdb/duckdb#11601 from Tmonster/fix_topn_placement

- Update vendored sources to duckdb/duckdb@41419f3df6a04af9c46098de92f6511916a276aa.

  Merge pull request duckdb/duckdb#11512 from pdet/rejects_tables_2.0

- Update vendored sources to duckdb/duckdb@6598220b953b0be8a612ea1a9d5c1bd85c5379c8.

  Merge pull request duckdb/duckdb#11273 from pdet/dont_store_single

- Update vendored sources to duckdb/duckdb@f16b6a3bc6a23d4a1221c08496721d665d220199.

  Merge pull request duckdb/duckdb#11551 from Maxxen/initialize-unknown-index-on-lookup
  Merge pull request duckdb/duckdb#11600 from chrisiou/support-gzipped-files

- Update vendored sources to duckdb/duckdb@25f4fdc9d09be54ee24738642afa4f90cb452225.

  Merge pull request duckdb/duckdb#11604 from carlopi/bump_oot

- Update vendored sources to duckdb/duckdb@b9aadb70595025c9cfc62e6ab76bdbf51fcc9df7.

  Merge pull request duckdb/duckdb#11587 from Mytherin/usequotes
  Merge pull request duckdb/duckdb#11595 from carlopi/fix_lzma_again

- Update vendored sources to duckdb/duckdb@43b8f8bb510da48bf3a0c41acb3f5f9d338646a6.

  Merge pull request duckdb/duckdb#11585 from Mytherin/dbgenreadonly
  Merge pull request duckdb/duckdb#11593 from carlopi/remove_github_pat
  Merge pull request duckdb/duckdb#11577 from szarnyasg/update-issue-template2
  Merge pull request duckdb/duckdb#11592 from Mytherin/drafttoken

- Update vendored sources to duckdb/duckdb@52c0b23fd04d59599756b597cd78ef74606e73a3.

  Merge pull request duckdb/duckdb#11580 from Mytherin/unneststructcleanup
  Merge pull request duckdb/duckdb#11576 from szarnyasg/reprox-labels
  Merge pull request duckdb/duckdb#11575 from Mytherin/permissions
  Merge pull request duckdb/duckdb#11423 from guenp/guenp/fix-sqlgetinfo-1750-unknown-attribute
  Merge pull request duckdb/duckdb#11382 from guenp/guenp/ignore-pq-driver-key

- Update vendored sources to duckdb/duckdb@b8533afc3db47e090651c8967cc1e0c94035113f.

  Merge pull request duckdb/duckdb#11461 from lnkuiper/parquet_dict_early_out
  Merge pull request duckdb/duckdb#11137 from Tishj/sqllogic_parser
  Merge pull request duckdb/duckdb#11095 from Tishj/python_struct_child_count_mismatch
  Merge pull request duckdb/duckdb#10382 from jzavala-gonzalez/python-write-csv-options

- Update vendored sources to duckdb/duckdb@7c0c66d5f7cceaaa6ebd6f2e513dc9fc3a5a550d.

  Merge pull request duckdb/duckdb#11267 from Tishj/uncompressed_storage_asserts

- Update vendored sources to duckdb/duckdb@cc3547d753cb6feaa6e613dad5bb4aaf47763bab.

  Merge pull request duckdb/duckdb#11558 from Maxxen/bugfixes
  Merge pull request duckdb/duckdb#11532 from Tmonster/run_new_micro_benchmarks_to_check_for_improvement

- Update vendored sources to duckdb/duckdb@2e6f74803b63c0c2679c6f6603d292b04a68c31e.

  Merge pull request duckdb/duckdb#11528 from lnkuiper/radixht_tasks_main
  Merge pull request duckdb/duckdb#11553 from carlopi/fix_assets_to_staging
  Merge pull request duckdb/duckdb#11556 from carlopi/fix_github_token

- Update vendored sources to duckdb/duckdb@b4408a8aab9f5658e971c67530a62326767ce1ec.

  Merge pull request duckdb/duckdb#11546 from Tishj/client_properties_timezone
  Merge pull request duckdb/duckdb#11547 from Tishj/c_enum_integrity_ci_fix

- Update vendored sources to duckdb/duckdb@b1f580c298fa5f1ca641d0f43a3588ccae7e6cd4.

  Merge pull request duckdb/duckdb#11544 from Maxxen/bugfixes

- Update vendored sources to duckdb/duckdb@b4c28bf4afa53bd56732e23f7a54a8cdeaf4fa24.

  Merge pull request duckdb/duckdb#11519 from hawkfish/try-from-time
  Merge pull request duckdb/duckdb#11530 from lnkuiper/json_scan_assertion

- Update vendored sources to duckdb/duckdb@ba2b8a318d6b151e24094f9ac848aab37a7fea39.

  Merge pull request duckdb/duckdb#11525 from samansmink/fix-timeout-async-ci

- Update vendored sources to duckdb/duckdb@0e3a51a627fecf6f401b759df273ca2ead038755.

  Merge pull request duckdb/duckdb#11270 from Tishj/initialize_with_garbage

- Update vendored sources to duckdb/duckdb@32c1c67529fa8f62a49c69b3b7685d516cf234ca.

  Merge pull request duckdb/duckdb#11496 from hawkfish/nested-nulls

- Update vendored sources to duckdb/duckdb@03c8e7a287b0fd83bd4062913cc7be1d91871bef.

  Merge pull request duckdb/duckdb#11513 from carlopi/fix_re2
  Merge pull request duckdb/duckdb#11522 from Mytherin/issueworkflow
  Merge pull request duckdb/duckdb#11509 from szarnyasg/bump-stale-bot

- Update vendored sources to duckdb/duckdb@9c9c2ca52bb1206418c826e7d85a7b798f579017.

  Merge pull request duckdb/duckdb#11495 from lnkuiper/cm_sp_integration

- Update vendored sources to duckdb/duckdb@bb65caca6d8e331c23ffc381cc17be06c870b144.

  Merge pull request duckdb/duckdb#11506 from Mytherin/decimalmodulo

- Update vendored sources to duckdb/duckdb@6c3a94cd4130f0d11718673887a85862931f8d96.

  Merge pull request duckdb/duckdb#11446 from joellubi/fix-adbc-getobjects-schema
  Merge pull request duckdb/duckdb#11468 from Tishj/python_time_df_convert
  Merge pull request duckdb/duckdb#11508 from rdavis120/main

- Update vendored sources to duckdb/duckdb@5316fd4da6aa2b8ea1257497a05b1e5350b65a01.

  Merge pull request duckdb/duckdb#11401 from motherduckdb/flo/copy-database-serialization

- Update vendored sources to duckdb/duckdb@2eecda939ad41e484c225b7cb0d70244d96711ff.

  Merge pull request duckdb/duckdb#11498 from Mytherin/issue11444

- Update vendored sources to duckdb/duckdb@925698598e6601552c0ada78b684a330216b7127.

  Merge pull request duckdb/duckdb#11497 from Mytherin/issue11445
  Merge pull request duckdb/duckdb#11488 from patmaddox/conditional-iutf8

- Update vendored sources to duckdb/duckdb@dfaac6862994c4775369f1472cf748ff139ad5ee.

  Merge pull request duckdb/duckdb#11247 from taniabogatsch/fix-fuzzer

- Update vendored sources to duckdb/duckdb@8d9e71ffe9f29caad73f57aa21eed7af57da2b23.

  Merge pull request duckdb/duckdb#11486 from carlopi/fix_extension_builds

- Update vendored sources to duckdb/duckdb@4b72786f3c42127d891ace4606d30d6c3b4054da.

  Merge pull request duckdb/duckdb#11408 from Tishj/logical_dependency

- Update vendored sources to duckdb/duckdb@5345a494c7d2d9f69f3d2486c66c191e67a93474.

  Merge pull request duckdb/duckdb#11464 from Tishj/arrow_invalid_struct

- Update vendored sources to duckdb/duckdb@0b4caed8bcd253fced268da739933ecbff104199.

  Merge pull request duckdb/duckdb#11478 from duckdb/revert-11402-bind-create-index-on-binder

- Update vendored sources to duckdb/duckdb@4da84ddf5645e33a2ae8f67b5883e2ed1446c319.

  Merge pull request duckdb/duckdb#11466 from Mytherin/moreoptionalidx

- Update vendored sources to duckdb/duckdb@4842b8204c5f0bd06c2a7d03c7e09d366066e756.

  Merge pull request duckdb/duckdb#11470 from Mytherin/deletememoryusage
  Merge pull request duckdb/duckdb#11476 from carlopi/fix_lzma
  Merge pull request duckdb/duckdb#11432 from guenp/guenp/add-escape-to-filter
  Merge pull request duckdb/duckdb#11378 from lnkuiper/read_json_defer_allocation

- Update vendored sources to duckdb/duckdb@2be8c43ca39a48545da675f6f1092ca38f8cf627.

  Merge pull request duckdb/duckdb#11458 from hannes/zapabortre2

- Fix patch.

- Update vendored sources to duckdb/duckdb@310e11f214deddbdcd3cfe8dde7f55903e6f3098.

  Merge pull request duckdb/duckdb#11358 from pdet/substrait_adbc

- Update vendored sources to duckdb/duckdb@acc5e79b453b0a76292cb039bc8305bd9fd28fb3.

  Merge pull request duckdb/duckdb#11402 from philippmd/bind-create-index-on-binder

- Update vendored sources to duckdb/duckdb@13f272413770a83e3dec808f35beca31bd0fe38d.

  Merge pull request duckdb/duckdb#11399 from kryonix/cte_fix
  Merge pull request duckdb/duckdb#11459 from carlopi/skip_ccache_r

- Update vendored sources to duckdb/duckdb@f41419fa88585f929bd818d287c0e91f67a59482.

  Merge pull request duckdb/duckdb#11443 from huachaohuang/patch-1

- Update vendored sources to duckdb/duckdb@6a6a1028f192cb8eaec39fdf0e6caedf60634287.

  Merge pull request duckdb/duckdb#11456 from bodand/main
  Merge pull request duckdb/duckdb#11447 from Mytherin/editshell
  Merge pull request duckdb/duckdb#11452 from Mytherin/windowsunicoderead

- Update vendored sources to duckdb/duckdb@a4be579474c7a92e29b54f8a0e72cadc103ecf96.

  Merge pull request duckdb/duckdb#11454 from quentingodeau/hotfix/opener-propagation

- Update vendored sources to duckdb/duckdb@f0c47c1c5d3ec1414729301d1b095555da66824b.

  Merge pull request duckdb/duckdb#11429 from motherduckdb/ddb-databases-readonly

- Update vendored sources to duckdb/duckdb@472271c0bb853ce54edd62d35c6080323a9f3389.

  Merge pull request duckdb/duckdb#11436 from Mytherin/improvelateralerror

- Update vendored sources to duckdb/duckdb@afef088bd1e0020449f78de9df058361be5ea151.

  Merge pull request duckdb/duckdb#11437 from Mytherin/virtualdestructor

- Update vendored sources to duckdb/duckdb@86e0f9ed812b5427b0b66893fb16ce528c4a9d31.

  Merge pull request duckdb/duckdb#11418 from pdet/newline_csv

- Update vendored sources to duckdb/duckdb@04a66604fa0861b3e3ee6e80a2540b37d355ca57.

  Merge pull request duckdb/duckdb#11428 from hawkfish/quantile-orderby

- Update vendored sources to duckdb/duckdb@903f14e91d5687b6fcd7cef3325be7b2912963ed.

  Merge pull request duckdb/duckdb#11424 from Mytherin/constglobals

- Update vendored sources to duckdb/duckdb@e6929cf46eda7a12f55f0fe04bb475913b48d9eb.

  Merge pull request duckdb/duckdb#11414 from Mytherin/constcast

- Update vendored sources to duckdb/duckdb@5d1baa5e0ee18ab41da74fc4a21e63ebbbf4f32e.

  Merge pull request duckdb/duckdb#11415 from szarnyasg/remove-redundant-defaults
  Merge pull request duckdb/duckdb#11421 from Mause/bugfix/jdbc-one-index-bytes
  Merge pull request duckdb/duckdb#11420 from szarnyasg/stale-prs

- Update vendored sources to duckdb/duckdb@43677ea475937ca3a2f634770ce764b352ac8e69.

  Merge pull request duckdb/duckdb#11405 from Maxxen/more-serialization

- Update vendored sources to duckdb/duckdb@af1ba841a5f7640c775f84b51f6fa4f68800de76.

  Merge pull request duckdb/duckdb#11400 from pdet/preference_fsspec

- Update vendored sources to duckdb/duckdb@62d1fb0c5a0306425c4b150c93a367d740f231f2.

  Merge pull request duckdb/duckdb#11397 from motherduckdb/readonly-db

- Update vendored sources to duckdb/duckdb@57d4ea684ee1dc93568dae36c588696a7adebc58.

  Merge pull request duckdb/duckdb#11396 from hawkfish/struct-casts
  Merge pull request duckdb/duckdb#11394 from oomojola/patch-1

- Update vendored sources to duckdb/duckdb@efcbee2d1b2dc89a4aad28e626fde2dd542cdef0.

  Merge pull request duckdb/duckdb#11392 from hawkfish/timestampns-invertible

- Update vendored sources to duckdb/duckdb@91af200d565638573ab0828f88e9e66b02aae5e3.

  Merge pull request duckdb/duckdb#11390 from hawkfish/negative-ranges
  Merge pull request duckdb/duckdb#11357 from jingshi-ant/patch-1

- Update vendored sources to duckdb/duckdb@5425ef0a12fc9d3659ed6549df3e668ca9ea75fb.

  Merge pull request duckdb/duckdb#11360 from lnkuiper/fix_10022

- Fix generated Makevars.win.

- Update vendored sources to duckdb/duckdb@9b8e5b607e5ccf978b9899da0c5b71ef376acac5.

  Merge pull request duckdb/duckdb#11356 from kindred77/master-fix-build-issue-on-win32-remove-unnecessary-modification

- Update vendored sources to duckdb/duckdb@d4c2eca71b00c896e397796054871707f9b2c02b.

  Merge pull request duckdb/duckdb#11372 from hawkfish/respect-ignore-nulls

- Update vendored sources to duckdb/duckdb@beb5fbfd8eccc1069dc99a259be460bf8202983c.

  Merge pull request duckdb/duckdb#11369 from motherduckdb/flo/fix-pg-defs

- Update vendored sources to duckdb/duckdb@60e89a404e46e2e8a463554d1a1e9c68a048c95b.

  Merge pull request duckdb/duckdb#11376 from Mytherin/clangtidyfixes
  Merge pull request duckdb/duckdb#11379 from samansmink/fix-https-ci-macos
  Merge pull request duckdb/duckdb#11368 from pfarndt/blob-fix
  Merge pull request duckdb/duckdb#11366 from szarnyasg/readme-logo

- Update vendored sources to duckdb/duckdb@0465529666ef63a17cb1b7c3ce9141d2d10c0506.

  Merge pull request duckdb/duckdb#11343 from Mytherin/s3attach

- Update vendored sources to duckdb/duckdb@ecfe10291e741ce3e5338a221625e808528c326e.

  Merge pull request duckdb/duckdb#11252 from hannes/re2upgrade
  Merge pull request duckdb/duckdb#11355 from szarnyasg/remove-issue-labeling-workflow
  Merge pull request duckdb/duckdb#11342 from carlopi/fix_staged_releases
  Merge pull request duckdb/duckdb#11341 from szarnyasg/iss11339

- Add patch for re2 update.

- Update vendored sources to duckdb/duckdb@7935b7cbbb5cd82d51677fb3ed3c0c5167e5e030.

  Merge pull request duckdb/duckdb#11347 from hawkfish/iejoin-scan
  Merge pull request duckdb/duckdb#11346 from carlopi/fix_regression
  Merge pull request duckdb/duckdb#11345 from Tmonster/fix_duckdb_r_script

- Update vendored sources to duckdb/duckdb@f4f6e719fabb765deab2c26033ff27e37467f083.

  Merge pull request duckdb/duckdb#11326 from Mause/bugfix/arrow-union

- Update vendored sources to duckdb/duckdb@1faa754431d655d88947edeb9b870bb7cccdc525.

  Merge pull request duckdb/duckdb#11313 from pdet/more_predictable_dialect

- Update vendored sources to duckdb/duckdb@35de27646546b4948e4d5a641d49103ce4bcffb5.

  Merge pull request duckdb/duckdb#11340 from lnkuiper/fix_11280

- Update vendored sources to duckdb/duckdb@cc8af5035c703f3d26653448a0d915e5cff2faef.

  Merge pull request duckdb/duckdb#11327 from Tishj/attach_sequence_fix

- Update vendored sources to duckdb/duckdb@8ef134fa0e855ad0cd9d03af0f8907a6adab8718.

  Merge pull request duckdb/duckdb#11321 from hawkfish/distinct-sorted-aggs

- Update vendored sources to duckdb/duckdb@9dd19695bfd8c5c5ef71018bd60fedf82dcafd49.

  Merge pull request duckdb/duckdb#11329 from Mytherin/relassertscanfail

- Update vendored sources to duckdb/duckdb@4f80905a76f715244ad94461702eb933346a336a.

  Merge pull request duckdb/duckdb#11325 from Mytherin/issue11284
  Merge pull request duckdb/duckdb#11333 from carlopi/fixup_py_upload2
  Merge pull request duckdb/duckdb#11328 from Mytherin/issue11319
  Merge pull request duckdb/duckdb#11324 from Mytherin/windowscli

- Update vendored sources to duckdb/duckdb@5d065f3a19e4ae1ff8d1f465ac5211de88cb172d.

  Merge pull request duckdb/duckdb#11314 from Mytherin/positionprepare

- Update vendored sources to duckdb/duckdb@f339e3ccc4606c9baf8b6a581cf22febdb15c14a.

  Merge pull request duckdb/duckdb#11315 from Mytherin/issue11294

- Update vendored sources to duckdb/duckdb@54e26a013bacd665b657890c8d064af20712c399.

  Merge pull request duckdb/duckdb#11318 from Mytherin/issue11283

- Update vendored sources to duckdb/duckdb@8a7e07bd54bda01b03d5723c7d81e1c11e7399f2.

  Merge pull request duckdb/duckdb#11309 from Mytherin/updatenullrefrollback

- Update vendored sources to duckdb/duckdb@69f4cabfea2c7564049f3371bd3f24efbc0b49ef.

  Merge pull request duckdb/duckdb#11320 from hawkfish/timestamp-timestamptz
  Merge pull request duckdb/duckdb#11308 from carlopi/fixup_py_upload

- Update vendored sources to duckdb/duckdb@dd214c292f45ccb7db7d1712f416be684d2a4bb5.

  Merge pull request duckdb/duckdb#11317 from Mytherin/issue11281

- Update vendored sources to duckdb/duckdb@bf050db984add97e1ef3143460c9c7a9950d5f3f.

  Merge pull request duckdb/duckdb#11316 from Mytherin/issue11293

- Update vendored sources to duckdb/duckdb@ef62c27528b726c0777b8f42b10b0c75d017e2d3.

  Merge pull request duckdb/duckdb#11306 from Maxxen/bugfixes

- Update vendored sources to duckdb/duckdb@9bc963f1a44fbb0248c1c6d11f97b1b22b156b64.

  Merge pull request duckdb/duckdb#11297 from Mytherin/tryopenfile2

- Update vendored sources to duckdb/duckdb@aeefca06cb4e1be507c7c7137547e703312cdb0f.

  Merge pull request duckdb/duckdb#11304 from hannes/generatorstypeinferece
  Merge pull request duckdb/duckdb#11303 from lnkuiper/je_mallctl_exception

- Update vendored sources to duckdb/duckdb@2f58548f84103e18ea9ccfcab28de75714fecddd.

  Merge pull request duckdb/duckdb#10878 from kryonix/materialized_insert
  Merge pull request duckdb/duckdb#11295 from lnkuiper/json_stuff

- Update vendored sources to duckdb/duckdb@e25ca7519cc87e4b353b7c9dd6c3acd71a918bf8.

  Merge pull request duckdb/duckdb#11215 from jkub/buffer_manager_override
  Merge pull request duckdb/duckdb#11291 from carlopi/spatial_rtools

- Update vendored sources to duckdb/duckdb@61bbb0e5b934bc875a9aa9cbd4bc817f41818e14.

  Merge pull request duckdb/duckdb#11286 from lnkuiper/fuzzer_stuff

- Update vendored sources to duckdb/duckdb@2626cb2b1cf497b9dbf929133c761c1e1e48331b.

  Merge pull request duckdb/duckdb#11203 from quentingodeau/feature/buffer-writer

- Update vendored sources to duckdb/duckdb@cf02e63b37a2ef348ca4a0ac29aa030114844c01.

  Merge pull request duckdb/duckdb#11258 from jkub/fs_trim_support
  Merge pull request duckdb/duckdb#11268 from lnkuiper/shell_json
  Merge pull request duckdb/duckdb#11271 from lnkuiper/json_stuff

- Update vendored sources to duckdb/duckdb@cac258298126aad61785493643c79de649700284.

  Merge pull request duckdb/duckdb#11276 from pdet/error_handler_csv
  Merge pull request duckdb/duckdb#11129 from Tmonster/fix_plan_cost_runner_regression

- Update vendored sources to duckdb/duckdb@5f74399a0e7a93609546ecc86b2ae9285dffcb7d.

  Merge pull request duckdb/duckdb#11233 from hawkfish/asof-pushdown
  Merge pull request duckdb/duckdb#11265 from Mytherin/terminalmissingincludes

- Update vendored sources to duckdb/duckdb@16938041baa047e77378aff013acde6a6d863c52.

  Merge pull request duckdb/duckdb#11220 from hannes/parquetlz4

- Update vendored sources to duckdb/duckdb@85a8b95db69a10135e3d8489f63ede1215add0ba.

  Merge pull request duckdb/duckdb#11248 from taniabogatsch/fix-fuzzer-select
  Merge pull request duckdb/duckdb#11255 from Tishj/pytype_transaction

- Update vendored sources to duckdb/duckdb@e2b1ed87b123b75dfc06f4bba0afc2c0dd7323c4.

  Merge pull request duckdb/duckdb#11257 from pdet/sniff_csv_ignore
  Merge pull request duckdb/duckdb#11256 from szarnyasg/README-update
  Merge pull request duckdb/duckdb#11242 from maiadegraaf/verify_vector_map

- Update vendored sources to duckdb/duckdb@9bc0ac5523be437335d5702b3c20570d15c3eb39.

  Merge pull request duckdb/duckdb#11243 from Mytherin/hexunhexblob
  Merge pull request duckdb/duckdb#11245 from carlopi/pin_r

- Update vendored sources to duckdb/duckdb@5dc0930c5a9de55635f73d102d798fbcef3587bf.

  Merge pull request duckdb/duckdb#11236 from Mytherin/threadconstructorfailed

- Update vendored sources to duckdb/duckdb@e2cecdd43f28cad341a41dcf9342be80c5ae070a.

  Merge pull request duckdb/duckdb#11231 from Mytherin/bitverify

- Update vendored sources to duckdb/duckdb@7f4b66bb47a711c7cbddf2764120bd2fe75e2301.

  Merge pull request duckdb/duckdb#11222 from hannes/cleanupfsst
  Merge pull request duckdb/duckdb#11192 from szarnyasg/ask-for-mwe
  Merge pull request duckdb/duckdb#11135 from binste/add_missing_type_hints

- Update vendored sources to duckdb/duckdb@60489faad5d14cf2dac3c98e62099fbc49571c6b.

  Merge pull request duckdb/duckdb#11139 from tiagokepe/master

- Update vendored sources to duckdb/duckdb@24daa36256aa1122e5a8ec2aa5ba8426efcbe80e.

  Merge pull request duckdb/duckdb#11223 from maiadegraaf/verify_vector_flatten
  Merge pull request duckdb/duckdb#11225 from Mytherin/juliabumpandfix

- Apply patches during vendoring.

## Continuous integration

- Move caching of duckdb prebuilt archive.

- More careful patching.

- Better tag detection.

- Add R version to cache key.

- Logic.

- Fix vendoring.

## Uncategorized

- Merge branch 'cran-0.10.1'.


# duckdb 0.10.1.9001

- Merge branch 'cran-0.10.1'.


# duckdb 0.10.1.9000

- Merge branch 'cran-0.10.1'.


# duckdb 0.10.1

## Features

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

 - [Many Arrow integration improvements](https://github.com/duckdb/duckdb/pulls?q=is%3Apr+is%3Aclosed+arrow)
 - [Many ODBC driver improvements](https://github.com/duckdb/duckdb/pulls?q=is%3Apr+is%3Aclosed+odbc)
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
New [website](http://duckdb.org/) [woo-ho](https://www.youtube.com/watch?v=H9cmPE88a_0)!

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
