<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# duckdb 1.99.99.9001

## Bug fixes

- A failed `EXPLAIN ANALYZE` no longer suppresses the next query's profile (#2904).

### build

- Ship the `MAKEFLAGS` helper in the tarball, and refuse a value that is not `-jN` (#2678).

- A failed `EXPLAIN ANALYZE` no longer suppresses the next query's profile (#2904).

- A failed `EXPLAIN ANALYZE` no longer suppresses the next query's profile (#2904).

- A failed `EXPLAIN ANALYZE` no longer suppresses the next query's profile (#2904).

- An R error from an ALTREP column under a data frame scan's bind no longer leaves the session busy (#2909).

### series

- Act on the review of the pre-vendoring stack (#2927).

### each

- Defer a commit the leg deadline kills instead of failing it (#2921).

### vendor

- Re-stamp a commit upstream tagged after it was vendored, and start a new-born green below the flavor commits (#2917).

### series

- Hold back release notes written without a version bump (#2914).

- An R error from an ALTREP column under a data frame scan's bind no longer leaves the session busy (#2909).

- A failed `EXPLAIN ANALYZE` no longer suppresses the next query's profile (#2904).

## Features

- Preserve DuckDB's structured error fields through the rethrow (#2714).

### rcc

- Add `rcc-drop.sh`, for verdicts the job decided rather than the tree (#2916).

### series

- Vendor each commit once, onto a strand a forward rebases (#2910).

### series

- Cut over by archive pull requests, and keep the names static (#2906).

### series

- Forward a series from its `-dev`, so a forward keeps what the series proved (#2905).

### series

- Fold a fix into the landing commit that introduced its defect (#2903).

### series

- Keep a series' tests `main`'s through a rewind, the carry and the landing (#2900).

### series

- Land a line on `main` as its vendor commits alone, and park v1.5 on its own baseline (#2898).

## Chore

### series

- Release duckdb from v2.0-cyanoptera.

  `main` now takes the v2.0 line, so the CRAN row of `scripts/series.yaml` tracks it.
  The `duckdb.dev` and `duckdb.2.0.dev` rows and the `releases_from: v1.5-variegata` park declaration stay as they are.

  The tables derived from the declaration are regenerated with `scripts/series-table.R` and by rendering `README.Rmd`:
  the series cell of the `duckdb` row in `README.md`, `.github/README.md` and `handbook/branches/flavors/README.md` moves from `v1.5-variegata` to `v2.0-cyanoptera`.
  `scripts/pull-config.sh --check` finds the mirror rules unchanged.

## Documentation

### plan

- Record that the verdict store stays, and D6 is declined (#2922).

### series-forward

- Push the four refs once, and allow `main`'s newer patches in the tree check (#2915).

### skills

- Split the loop and forward playbooks from their references (#2913).

### series

- Review the process documentation cover to cover, and draw the mechanisms (#2907).

### ci

- Move the flavor-guard comment to its step (#2919).

## Refactoring

### series

- Read the engine's names from one configuration file (#2918).

## Testing

### progress

- Ask the engine whether it reports progress while a stream is read (#2859).

- Describe a column of NULLs as the integer column it arrives as (#2911).

- Skip the tuple test only on an engine without `struct_values()` (#2923).

- Refuse a tuple holding a column R cannot hold before the statement runs (#2912).

- Describe a column of NULLs as the integer column it arrives as (#2911).

- Pin that a statement finalized in the materialize callback of a scan does not deadlock (#2908).

- Pin Arrow streaming, results after disconnect, window defaults, empty output names and case-sensitive names (#2901).

## vendor

- Update vendored sources to duckdb/duckdb@0f5ff0a9d6ac54a00d90485778fdc897047954cf.

  Date: 2026-10-14 12:21:00 +0000

  Show HTTP requests and execution markers in samply profiler (https://redirect.github.com/duckdb/duckdb/pull/26904)

  Landing v2 (finding 7): `handbook/architecture/glue/objects/` and `handbook/usage/integrations/` describe the v2.0 engine: an Arrow result that holds its own client context, a prepared statement that holds it only weakly, the open results the glue ends before a statement, and a self-scan of a stream that fails rather than waits.

  Landing v6 (restack): `NEWS.md` is main's; the landing's release notes sit in the fledge commit of its base, so this commit no longer touches the file.
  Unflavored-from: 17304a0b765bbe04c36cbdd19a1892728265a77a

- Update vendored sources to duckdb/duckdb@21c47e59b599b297c0e4b82958031587a3f78332.

  Date: 2026-10-14 12:14:02 +0000

  Stop at the last child in the cascaded levels of MergeSortTree::SelectNth (https://redirect.github.com/duckdb/duckdb/pull/26954)

  Unflavored-from: d5fa0c353580a7641a737e354c125f3d12f933e6

- Update vendored sources to duckdb/duckdb@566bf622b6e60abf6a42db1f0e584b4db6dd20b4.

  Date: 2026-10-14 11:46:07 +0000

  Group approved PEG parser PRs (https://redirect.github.com/duckdb/duckdb/pull/27111)

  Unflavored-from: d30d783d9e02e53741b4e6f0272616ed8257daa7

- Update vendored sources to duckdb/duckdb@de4593ef3db3a4000560594af4909742e5f613a6.

  Date: 2026-10-14 10:59:01 +0000

  Restore bloom filter pushdown for external hash joins (https://redirect.github.com/duckdb/duckdb/pull/26959)

  Unflavored-from: 6154f85e04a3d20911f1888d532e68c96689394f

- Update vendored sources to duckdb/duckdb@9a14b398ea5609e10a6f4f30ca0aec4aaa34f50d.

  Date: 2026-10-14 10:44:52 +0000

  Skip rewriting LogicalPlanStatement's delim joins to CTEs (https://redirect.github.com/duckdb/duckdb/pull/26563)

  Unflavored-from: 0a22052a9202b8c2507d6772eb28823bf5c37a41

- Update vendored sources to duckdb/duckdb@44647bad7c3a8dc069a33915264b8fe0b70d3fcd.

  Date: 2026-10-14 10:37:05 +0000

  Release pin handles when finalizing the pin state of a collection without segments (SIGSEGV in ~GroupedAggregateHashTable after OOM) (https://redirect.github.com/duckdb/duckdb/pull/27212)

  Unflavored-from: e218c44b6e6e8bffbf75ea1d40488d3961c2e444

- Update vendored sources to duckdb/duckdb@4c07884e6c3350975d3cf252dc0f9a428467b9f5.

  Date: 2026-10-14 10:35:12 +0000

  Monotone preimage: keep TIMESTAMP bounds inside the convertible range (EXPLAIN failed with "Date out of range") (https://redirect.github.com/duckdb/duckdb/pull/27082)

  Unflavored-from: f26710fa86e692a08c271297ec9ffbbaa8fd3dc0

- Update vendored sources to duckdb/duckdb@f702a1f801062fc28e5e1570988573012c3af4be.

  Date: 2026-10-14 11:21:13 +0200

  Skip windows arm64 and macOS amd64 extensions CI jobs temporarily (https://redirect.github.com/duckdb/duckdb/pull/27141)

  Unflavored-from: 49c5b3051c6dd9f1de9338ee2f9850748ea0213b

- Update vendored sources to duckdb/duckdb@8d68e6f9d887761bf4e4ff6ace906ca6de79d90d.

  Date: 2026-10-14 07:54:44 +0000

  Export single MARK comparisons with native NULL semantics (https://redirect.github.com/duckdb/duckdb/pull/27118)

  Unflavored-from: fe0c8a3e30513af3c770705b22f631da2e261362

- Update vendored sources to duckdb/duckdb@2c384ca660aad5f125717900fb0ee8db427d279e.

  Date: 2026-10-14 07:49:19 +0000

  Preserve nested collations in SQL expression export (https://redirect.github.com/duckdb/duckdb/pull/27161)

  Unflavored-from: a8a442edcbeeb3f674abee622a34c63270994f2e

- Update vendored sources to duckdb/duckdb@39fc80c3d34ffd4e12d4db94e62cc24d1d05e525.

  Date: 2026-10-14 07:45:04 +0000

  Allocate the window partition, order and filter masks through the buffer allocator (https://redirect.github.com/duckdb/duckdb/pull/26981)

  Unflavored-from: a0387d7f740e7c35c3405e77951c1707a4162926

- Update vendored sources to duckdb/duckdb@d5a439db0d9924bb783f6be39afb63c72d5e855a.

  Date: 2026-10-14 09:19:48 +0200

  Reduce benchmark query durations to ~300-500 ms and limit to 7 GiB memory (https://redirect.github.com/duckdb/duckdb/pull/27177)

  Unflavored-from: d8b9f07f122dd50a1bfed6dc876c09a8050d8279

- Update vendored sources to duckdb/duckdb@f1844083656b160c3eab1953c4b575e2bca20320.

  Date: 2026-10-14 06:04:58 +0000

  Use an invalid JSON path type in the binder error test (https://redirect.github.com/duckdb/duckdb/pull/27164)

  Unflavored-from: 3e657ad1211a11ab343fcebf7f15219f1f532b47

- Update vendored sources to duckdb/duckdb@d4355d01c59362d57036ad377735dd5340276a5b.

  Date: 2026-10-13 16:32:57 +0200

  Fix extension CI failures: ducklake musl timeout, libmariadb Windows build (https://redirect.github.com/duckdb/duckdb/pull/27115)

  Unflavored-from: d4b1973ed809b6e856c665b3192085ab1ee9566a

- Update vendored sources to duckdb/duckdb@c5c5adc80da2491e6c5ecbb8d07f84301207dc17.

  Date: 2026-10-13 13:03:57 +0000

  Clone the master branch sqllogictest (https://redirect.github.com/duckdb/duckdb/pull/27083)

  Unflavored-from: 1233433a5a8b0f38c01448b23cb9a049ff01850a

- Update vendored sources to duckdb/duckdb@10ed856cf02036da7e99e1571b90a35540c2b42a.

  Date: 2026-10-13 12:32:22 +0000

  Dict-surviving hash join: reserve a NULL slot for FULL/RIGHT joins on the build side (https://redirect.github.com/duckdb/duckdb/pull/26911) (https://redirect.github.com/duckdb/duckdb/pull/26926)

  Unflavored-from: 9ab1a256dc32a049e63cf039d23335066afd8736

- Update vendored sources to duckdb/duckdb@2b1a604fb0c26487f9ab988bffe5edd124de4754.

  Date: 2026-10-13 09:35:21 +0000

  Parser: Multiple named constraints now allowed (https://redirect.github.com/duckdb/duckdb/pull/26406)
  Unflavored-from: 6576b3ddf6940f1b6f91fb51645dda90eafc37be

- Update vendored sources to duckdb/duckdb@f6ecb5f6e651e40b4434a5f7f2588676790e6d42.

  Date: 2026-10-13 07:53:12 +0000

  \[VARIANT\] Disable `VARIANT::JSON` cast pushdown combined with extract (https://redirect.github.com/duckdb/duckdb/pull/26998)

  Unflavored-from: 1c7cbc4593ee8e0b1b2e0d945f55c4bfa3824ac5

- Update vendored sources to duckdb/duckdb@d1a9116982dd368571983912c3345e1fa1980359.

  Date: 2026-10-13 07:37:58 +0000

  Avoid full-plan sweeps in compressed materialization (https://redirect.github.com/duckdb/duckdb/pull/26964)

  Unflavored-from: b5f27101a2f92b3cdaff555a5f5bb8f3f6978b53

- Update vendored sources to duckdb/duckdb@939d6af0c505c26eff6d8ee0579f026b784d89e6.

  Date: 2026-10-13 07:35:11 +0000

  Write enum_range directly into the result vector (https://redirect.github.com/duckdb/duckdb/pull/26971)

  Unflavored-from: bc5712e30f76e47b1c8f56509b1fc12bf8dadfac

- Update vendored sources to duckdb/duckdb@ef437b6ae7f246156e4751436678f5d01048432f.

  Date: 2026-10-13 07:34:09 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/11336: TIMESTAMP_TZ_NS Formatting (https://redirect.github.com/duckdb/duckdb/pull/26975)

  Unflavored-from: 2845605e9c1e5f9e2be8b7c3abcdf48008fc8a72

- Update vendored sources to duckdb/duckdb@08849d13efb005792147f0f0ca8872f481277f51.

  Date: 2026-10-13 07:27:07 +0000

  Fix three parquet scan regressions found in the DuckLake benchmarks (https://redirect.github.com/duckdb/duckdb/pull/26960)

  Unflavored-from: 1088ad60f9e26bbdb3f9eb2c80428e77cbe7542d

- Update vendored sources to duckdb/duckdb@57eff1742dfb706c19d9a8a7c45e46b7cb7cc34f.

  Date: 2026-10-13 11:16:12 +0200

  Improve fast test coverage from 89.6% to 90.2% (https://redirect.github.com/duckdb/duckdb/pull/27062)

  Unflavored-from: 144af99feec5d9550683c8511e30c03c0d2e5630

- Update vendored sources to duckdb/duckdb@4a541bcbc7622c24772bfa92b13221017a72d269.

  Date: 2026-10-13 11:15:45 +0200

  Bump mysql and aws to solve windows build issue (https://redirect.github.com/duckdb/duckdb/pull/26930)

  Unflavored-from: 3ae0983ab3ac14986992e9f7ed78c423de5c85b5

- Update vendored sources to duckdb/duckdb@1006feaf67b922946be9628e124bb951e6bde5cb.

  Date: 2026-10-13 11:15:33 +0200

  Fix async write queue task cancellation lifetime (https://redirect.github.com/duckdb/duckdb/pull/27077)

  Unflavored-from: 1473a251904afeafbbf5aa1d9a70d378038529c2

- Update vendored sources to duckdb/duckdb@b423c8a89cf9a1ccc5480174ec8ac1c7a45b8ed0.

  Date: 2026-10-13 07:06:45 +0000

  Reuse Parquet statistics metadata and guard initial prefetch (https://redirect.github.com/duckdb/duckdb/pull/26905)

  Unflavored-from: 917ac1ea73a3c8fc44c075ec118370af3d6679e1

- Update vendored sources to duckdb/duckdb@469826fbe4c580637c1551f1f0a2ea461483118e.

  Date: 2026-10-13 08:20:20 +0000

  Replace std::call_once with an exception-safe OnceFlag and run the 400003-row parallel CTE scan only on 64-bit (https://redirect.github.com/duckdb/duckdb/pull/27066)

  Unflavored-from: a29e060adaf00e2fc428f013d40a30f254012ea7

- Update vendored sources to duckdb/duckdb@b771d2cd3303842ff9a151f37a265cabd6a9ab0c.

  Date: 2026-10-13 07:03:18 +0000

  Support INSERT, UPDATE, DELETE and MERGE INTO in EXPLAIN (SQL) (https://redirect.github.com/duckdb/duckdb/pull/26958)

  Unflavored-from: 80f698348066056b9c4c3d4cc59aaba11c300433

- Update vendored sources to duckdb/duckdb@91e650acc228f3cbfd5f1b663e960e6e3a09a0c8.

  Date: 2026-10-13 07:02:59 +0000

  Evaluate each candidate pair once in greedy join ordering (https://redirect.github.com/duckdb/duckdb/pull/26965)

  Unflavored-from: 8facd52b14629b93591f887889ac90925220a9e1

- Update vendored sources to duckdb/duckdb@4000cb9629655c451db16d53e474991f4b28f1c9.

  Date: 2026-10-13 07:02:28 +0000

  Bind constant ICU date parts to their unary overloads (https://redirect.github.com/duckdb/duckdb/pull/26918)

  Unflavored-from: 21df6e31b54b3e92882eece055c65697d05bfcbd

- Update vendored sources to duckdb/duckdb@3f331f402fb64f653df5ee6680f2f7192639cc95.

  Date: 2026-10-13 07:00:44 +0000

  Backport https://redirect.github.com/duckdb/duckdb/pull/26419 (https://redirect.github.com/duckdb/duckdb/pull/27044)

  Unflavored-from: 850d2e5e59b3c5e6f7e42838b59418d3390a176d

- Update vendored sources to duckdb/duckdb@7ddb9c45e5252e15380c408ac1f23fcdfef3b559.

  Date: 2026-10-13 05:38:17 +0000

  Reload a destroyable CSV buffer that was evicted between the in-memory check and the pin (https://redirect.github.com/duckdb/duckdb/pull/26934)

  Unflavored-from: c8d410a282b088e4c6e4c3530a05fbc21ad51030

- Update vendored sources to duckdb/duckdb@f3f540d757c32be46f35beab77f15e8d958cf603.

  Date: 2026-10-13 05:36:43 +0000

  Bump extensions and remove some patches (https://redirect.github.com/duckdb/duckdb/pull/26925)

  Unflavored-from: 52fa191d1d98007d051779dfbb2991ee680c7831

- Update vendored sources to duckdb/duckdb@14215e09024d293c912aa595404bbe4fe680449d.

  Date: 2026-10-13 03:45:10 +0000

  Many-core bottleneck/regression fixes (https://redirect.github.com/duckdb/duckdb/pull/26967)

  Unflavored-from: 93d04a58e5dbf165d125523584a67d86932b72dd

- Update vendored sources to duckdb/duckdb@c65ca930b9fe39b2e8d8ed8821018dca650965f4.

  Date: 2026-10-12 18:02:10 +0000

  Shrink the retained JSON auto-detect buffer and allocate it through the buffer allocator (https://redirect.github.com/duckdb/duckdb/pull/26938)

  Unflavored-from: bd507d7baecb8add6a4272a8b0d7c8b6644c7a4d

- Update vendored sources to duckdb/duckdb@b554c96b5d77bb03238d3aa958063869ef97548f.

  Date: 2026-10-12 17:01:19 +0000

  Re enable some skipped tests (https://redirect.github.com/duckdb/duckdb/pull/26939)

  Unflavored-from: 8eaabaa1e41d23a63b4d2c967971b5ec814ed024

- Update vendored sources to duckdb/duckdb@0ace7ac615e557077ab6dca98ed7f62a96923318.

  Date: 2026-10-12 16:34:16 +0000

  Multuple nightly CI fixes (https://redirect.github.com/duckdb/duckdb/pull/26943)

  Unflavored-from: 7c967159552256a58b458861eddb4b4bc235eec1

- Update vendored sources to duckdb/duckdb@aee817a9ff6430253ce516e6c2554a34709e5974.

  Date: 2026-10-12 15:42:21 +0000

  Fix two nightly clang tidy errors (https://redirect.github.com/duckdb/duckdb/pull/26921)

  Unflavored-from: c608da8c2e39c3e6635f200dcda2fbf091350235

- Update vendored sources to duckdb/duckdb@07c6e7d4dabdf4dd76277d62a9f2735cb61ca43a.

  Date: 2026-10-12 15:23:15 +0000

  Fix aggregate spill transitions and source hash table cleanup (https://redirect.github.com/duckdb/duckdb/pull/26929)

  Unflavored-from: 1a29ce512a7d5c801e1863b1e1978ed2439d1aad

- Update vendored sources to duckdb/duckdb@45ebff1561d80c7694e5e8eced6654055d80eb19.

  Date: 2026-10-12 15:19:54 +0000

  Add a way to visit operators without projection remapping (https://redirect.github.com/duckdb/duckdb/pull/26799)

  Unflavored-from: a6e40716025ff5b1e8e36c4f7780ea3a024ec853

- Update vendored sources to duckdb/duckdb@a246557cb61a2766faefb8bc15facbb577278836.

  Date: 2026-10-12 15:19:25 +0000

  Track large allocations in the buffer manager and drop memory that was never needed (https://redirect.github.com/duckdb/duckdb/pull/26919)

  Unflavored-from: 0bbd2cc48fee9d9ce710e050dbf04b086c790856

- Update vendored sources to duckdb/duckdb@266e8abbc0c16c21e3a3d03088f9c8bbdd00dd6b.

  Date: 2026-10-12 14:03:51 +0000

  Fix external hash join dropping rows via stale Bloom filter pushdown (https://redirect.github.com/duckdb/duckdb/pull/25718)

  Unflavored-from: 9736743687c3b0302be1c5790852497ce9cf2c14

- Update vendored sources to duckdb/duckdb@bba7360bc2ba224343f8556bc86f3d0a97c00bca.

  Date: 2026-10-12 13:53:44 +0000

  Round-trip null-safe MARK comparison conjunctions (https://redirect.github.com/duckdb/duckdb/pull/26917)

  Unflavored-from: 553f032e6d477d77fcef201777cffcd0fe87840b

- Update vendored sources to duckdb/duckdb@67aab9bd28f9471bb35107b00049ce5607200997.

  Date: 2026-10-12 13:47:07 +0000

  Fix unsigned division behavior problem + build warnings (https://redirect.github.com/duckdb/duckdb/pull/26679)

  Unflavored-from: 5c02d1aa8981967680ad87219449f4d7b7b8496c

- Update vendored sources to duckdb/duckdb@476755ebfad8fa1816d9c70ac24a4d22d58b937d.

  Date: 2026-10-12 13:27:40 +0000

  Skip quadratic CTE tests in the hash-zero configuration (https://redirect.github.com/duckdb/duckdb/pull/26913)

  Unflavored-from: f197916e644ea2a6771e375d61ba1c88b4e9ac2c

- Update vendored sources to duckdb/duckdb@0836feb22756378a2dffaa8dd3018b55a81c9908.

  Date: 2026-10-12 13:08:17 +0000

  Fix single-file `COPY` async write parallelism (https://redirect.github.com/duckdb/duckdb/pull/26912)

  Unflavored-from: e97e83779d53627852b5a5e5f31c09bdcac55f07

- Update vendored sources to duckdb/duckdb@57e9273ac3176c1cb764006d835d1f8b81851b77.

  Date: 2026-10-12 12:04:19 +0000

  Do not plan a nested loop join without a comparison condition (https://redirect.github.com/duckdb/duckdb/pull/26898)

  Unflavored-from: c18d48d5f3f3758d5dd92492f2cf9fdd381c9246

- Update vendored sources to duckdb/duckdb@a35df0c56a388e153da3ef0f74ac6e8caad59a90.

  Date: 2026-10-12 11:25:24 +0000

  Fix stack overflow in ToString for deeply nested types (https://redirect.github.com/duckdb/duckdb/pull/26888)

  Unflavored-from: 39b7e99ecb16496c898a63b425d39ece4ca58672

- Update vendored sources to duckdb/duckdb@68e09e8700d37e497894265c841eee73b34565a6.

  Date: 2026-10-12 11:25:12 +0000

  Fold constant function arguments while binding (https://redirect.github.com/duckdb/duckdb/pull/26795)

  Unflavored-from: 85b26ce9aa84a94ffbd4eb65dd1f58f6e2ff4746

- Update vendored sources to duckdb/duckdb@87ef6e10b6f7b1325e9c66154feb54b06c2445ba.

  Date: 2026-10-12 10:04:46 +0000

  Support explicit bound output schemas in Parquet scans (https://redirect.github.com/duckdb/duckdb/pull/26827)

  Unflavored-from: 0095eccdd81d3ae98db5a446b1af99bd090a0631

- Update vendored sources to duckdb/duckdb@6a1e9af005f66c5739e223fd237331ab3bae5c59.

  Date: 2026-10-12 09:35:41 +0000

  Uncached parallel reads and compressed regression fix (https://redirect.github.com/duckdb/duckdb/pull/26127)

  Unflavored-from: d74ed383eba4b87a6bb0335b7e8a9407eb21785e

- Update vendored sources to duckdb/duckdb@ef482d6cc50ee85f7415a598bce6d0adfea39f16.

  Date: 2026-10-12 09:29:06 +0000

  Avoid copying table statistics when reusing checkpoint metadata (https://redirect.github.com/duckdb/duckdb/pull/26835)

  Unflavored-from: 8c6b3a66393e7561f156b0dc08d6970b3d4a6ceb

- Update vendored sources to duckdb/duckdb@b9917eca9ab6be28cfed585a575869b2d95f8074.

  Date: 2026-10-12 09:28:31 +0000

  Cast a fixed-size ARRAY to LIST when the unnest rewriter builds a LogicalUnnest (https://redirect.github.com/duckdb/duckdb/pull/26845)

  Unflavored-from: 3bdb10ffc9d3c29c4a2f22e9594b01eb53ca8a10

- Update vendored sources to duckdb/duckdb@88ecd0a49d7d3d838e002b2fbc0ce91ccf74110e.

  Date: 2026-10-12 09:01:26 +0000

  Keep a cast to JSON out of the variant_extract pushdown into a shredded scan (https://redirect.github.com/duckdb/duckdb/pull/26867)

  Unflavored-from: 900b8938bb3ab2c7a5446a58ed184f957c0fbfc2

- Update vendored sources to duckdb/duckdb@a4b3c78905e13e538f84ecfdf80c435a5582766c.

  Date: 2026-10-12 09:01:17 +0000

  \[C-API-V2\] Add back `statement_add_collection` and more misc APIs (https://redirect.github.com/duckdb/duckdb/pull/26886)

  Unflavored-from: fcbffa45d843c1d48e1dd9636a4d605fba1bec48

- Update vendored sources to duckdb/duckdb@9214377b52bc6dc83f60fee68cbef31e1af5c099.

  Date: 2026-10-12 08:59:07 +0000

  Run first_last_nested_vectors.test on one thread (https://redirect.github.com/duckdb/duckdb/pull/26857)

  Unflavored-from: 9fd1bad6cde026afdc75b9262a31df8c9eb691eb

- Update vendored sources to duckdb/duckdb@664aafa2713caaf046dee56d11acaf4f2871fb5e.

  Date: 2026-10-12 08:58:33 +0000

  Do not let a failing rollback escape ClientContext's destructor (https://redirect.github.com/duckdb/duckdb/pull/26869)

  Unflavored-from: 2acd6bf7158746190557d8928ed27c786fadba68

- Update vendored sources to duckdb/duckdb@13970f13b60f3ed2636f868d485ed5be1f8d30ca.

  Date: 2026-10-12 08:57:35 +0000

  Merge ready-to-merge PRs (3) (https://redirect.github.com/duckdb/duckdb/pull/26798)

  Unflavored-from: ec4874cded041343e6448d61d4f25c53f948e84e

- Update vendored sources to duckdb/duckdb@2658ef961f670f932eac08a451bc57acb47f0148.

  Date: 2026-10-12 08:57:26 +0000

  Merge ready-to-merge PRs (2) (https://redirect.github.com/duckdb/duckdb/pull/26735)

  Unflavored-from: 1d64a60822ef9a7e060ed15506862e1c91f58844

- Update vendored sources to duckdb/duckdb@5c5f5b7fe7a7cd24aed2094135300274a759e92d.

  Date: 2026-10-12 11:37:21 +0000

  Use namespace runners for benchmarks and summary CI job (https://redirect.github.com/duckdb/duckdb/pull/26894)

  Unflavored-from: 4d8bee8ceb4bbcb95a77701d716ff29f2ea0653b

- Update vendored sources to duckdb/duckdb@45f4fdf3153c89cd38fdf6fb20b95646a466c5ac.

  Date: 2026-10-12 08:33:14 +0000

  Link tpch statically in the Extension updating test build (https://redirect.github.com/duckdb/duckdb/pull/26819)

  Unflavored-from: 37a7951a829bf15e694cbd9472a1a2a01e9538a5

- Update vendored sources to duckdb/duckdb@238c9ca7d6d960172ad65d0be5d3961eaad30f25.

  Date: 2026-10-12 08:08:37 +0000

  Preserve signed zero in Parquet dictionaries (https://redirect.github.com/duckdb/duckdb/pull/26876)

  Unflavored-from: 1d603c65540d274b24aa3db58741572348db302e

- Update vendored sources to duckdb/duckdb@aceb4059f4ec8f0f3545101f2ab4213953521f10.

  Date: 2026-10-12 08:07:58 +0000

  Parquet writer: count a NULL struct inside a list once in the leaf null_count (https://redirect.github.com/duckdb/duckdb/pull/26846)

  Unflavored-from: e0cf112a39ae33bab8d135bee9c7aca8ebbfb269

- Update vendored sources to duckdb/duckdb@52121cd4770d527b96908ec74de4eaa6c05780da.

  Date: 2026-10-12 08:06:26 +0000

  COPY (FORMAT BLOB): reject a COMPRESSION option given without a value (https://redirect.github.com/duckdb/duckdb/pull/26868)

  Unflavored-from: fbd957e47f1b61992bad6010ed116f4764220523

- Update vendored sources to duckdb/duckdb@4d747310f38a71bb8bbb4c650e7d38f597abe402.

  Date: 2026-10-12 07:46:59 +0000

  \[ADBC\] Eagerly materialize metadata calls and synchronize get_next (https://redirect.github.com/duckdb/duckdb/pull/26752)

  Unflavored-from: 749fe4b9f19a1508574fc0c4288e42213249c774

- Update vendored sources to duckdb/duckdb@d74962148b619d9117fddca5a69f5cf6e09d24bc.

  Date: 2026-10-12 07:44:15 +0000

  Parquet reader: count each column chunk once when sizing a row group's prefetch (https://redirect.github.com/duckdb/duckdb/pull/26826)

  Unflavored-from: ef9b289e27879d9d905f4771962e87711f8e70e8

- Update vendored sources to duckdb/duckdb@08369a3570296694b08496168451462c552bd4c9.

  Date: 2026-10-12 07:33:23 +0000

  struct_update: resolve the updated fields at bind time instead of reading argument aliases (https://redirect.github.com/duckdb/duckdb/pull/26844)

  Unflavored-from: 97a540b7ea01d166b443c540bb162eec26edcfaa

- Update vendored sources to duckdb/duckdb@10deb255063aa0b17d88f2e00f7afe1d1ad8c17d.

  Date: 2026-10-12 07:32:47 +0000

  Speed up prepare CI job (https://redirect.github.com/duckdb/duckdb/pull/26837)

  Unflavored-from: d2dc4884886cdd63fc7b55dca1997991a36199bc

- Update vendored sources to duckdb/duckdb@d91c829986f3b736c8c8fef14dfc76e895c890b7.

  Date: 2026-10-12 10:25:42 +0200

  Join order regression fixes (https://redirect.github.com/duckdb/duckdb/pull/26812)

  Unflavored-from: aa243d6e696a8db55b7783d4c2f46c36efff15b5

- Update vendored sources to duckdb/duckdb@4b5449558e31b60dc69f7f5fdb05f1e6261dfcf1.

  Date: 2026-10-12 07:30:49 +0000

  Preserve collations in exported aggregate states (https://redirect.github.com/duckdb/duckdb/pull/26862)

  Unflavored-from: c600b2ed5ff321942f1cb16851e5aef2aa37e13a

- Update vendored sources to duckdb/duckdb@e96cfaf8a06e455bf830094e32edf1cb56611724.

  Date: 2026-10-12 07:14:30 +0000

  Format and highlight EXPLAIN (SQL) output (https://redirect.github.com/duckdb/duckdb/pull/26288)

  Unflavored-from: 23c5a44fa7be1ff81e8ab99e49f8580650eed9b6

- Update vendored sources to duckdb/duckdb@732db0da44857fc3263b43b512bf77fd68bbd79f.

  Date: 2026-10-12 06:54:49 +0000

  Task scheduler threads should use a ConsumerToken to improve query execution fairness (https://redirect.github.com/duckdb/duckdb/pull/26809)

  Unflavored-from: 6c88b0647bfdb318a2fa6994079e8c499e435a77

- Update vendored sources to duckdb/duckdb@c851fba9769ddfeb134ce9e7d657dc47605b5a76.

  Date: 2026-10-12 06:40:27 +0000

  Do not let GroupedAggregateHashTable's destructor throw while destroying states (https://redirect.github.com/duckdb/duckdb/pull/26847)

  Unflavored-from: 6dcd92e11469aa61dbd585e3ab01dd70c80fcc6e

- Update vendored sources to duckdb/duckdb@1d678d1c1c72db9f8ee8c05e0ffd0cb4b1ddcda0.

  Date: 2026-10-12 06:38:31 +0000

  Partitioned COPY: do not count rows of the next partition into a ROW_GROUP_SIZE_BYTES batch (https://redirect.github.com/duckdb/duckdb/pull/26854)

  Unflavored-from: 10854ddb78de4a457afd7a0f53b93bb9c09a3d25

- Update vendored sources to duckdb/duckdb@680ab38121d688a0ddd0952b180f34b4b742accb.

  Date: 2026-10-12 06:25:21 +0000

  Destroy the inner aggregate state of ordered aggregates when finalizing throws (https://redirect.github.com/duckdb/duckdb/pull/26631)

  Unflavored-from: 6717202fe2d6be60c4146ce0439862e1feda325e

- Update vendored sources to duckdb/duckdb@bb08efdbe53477591ec4e9efc6e168728886ab39.

  Date: 2026-10-12 06:25:08 +0000

  Report failures from the ICU casts from VARCHAR to TIMESTAMPTZ and TIMETZ (https://redirect.github.com/duckdb/duckdb/pull/26629)

  Unflavored-from: e4d70a83e345aa765b86df37f8adec0376e4bb83

- Update vendored sources to duckdb/duckdb@501eb7e5754654da152cc80ee4a9e41d87454e2d.

  Date: 2026-10-12 06:24:31 +0000

  Destroy the right-part segment tree states when evaluating EXCLUDE window frames (https://redirect.github.com/duckdb/duckdb/pull/26759)

  Unflavored-from: f64f5bef9000d85e8f25de2a4471e9840806ef97

- Update vendored sources to duckdb/duckdb@9024254f4319eacaedf9dda8b2eb0b38691458ec.

  Date: 2026-10-12 05:39:22 +0000

  HttpUtil: properly guard file access on install (https://redirect.github.com/duckdb/duckdb/pull/26821)
  Unflavored-from: 7d013af530706f0c8cb685a635576c1014bf54e2

- Update vendored sources to duckdb/duckdb@c7a433735469acd93f3dc2154a1153fa72d95af7.

  Date: 2026-10-12 05:09:23 +0000

  Fix ORDER BY turning -0.0 into 0.0 for FLOAT/DOUBLE columns (https://redirect.github.com/duckdb/duckdb/pull/25540)

  Unflavored-from: 2b1926d5e15e0258456bf68963013cabae7a150a

- Update vendored sources to duckdb/duckdb@77640f9903b8feb2db53a0adb12f1d7139addde0.

  Date: 2026-10-12 05:08:33 +0000

  Preserve union_value member names in SQL export (https://redirect.github.com/duckdb/duckdb/pull/26861)

  Unflavored-from: f8704daeeecfd5e8f2ac3474715629c1ba3c9f4b

- Update vendored sources to duckdb/duckdb@7a28cd2561afdfeb566ca7df391fd14fdc5de157.

  Date: 2026-10-12 05:03:42 +0000

  Fix wrong column bindings when promoting a never-matching ANTI join (https://redirect.github.com/duckdb/duckdb/pull/26058)

  Unflavored-from: c29a24428e650f5f0d84d84849b9f3b6d51ff611

- Update vendored sources to duckdb/duckdb@09997c99db66293a145784f33a21ab8c494bc80b.

  Date: 2026-10-12 05:02:40 +0000

  Bump extension merged (https://redirect.github.com/duckdb/duckdb/pull/26866)

  Unflavored-from: d5b4120117ca0322d1dac1598985bfff311a9521

- Update vendored sources to duckdb/duckdb@6252031c70849a7ef8758a14012e2146762ddc25.

  Date: 2026-10-11 23:06:35 +0000

  Allow SQL export with typed subtree replacements (https://redirect.github.com/duckdb/duckdb/pull/26843)

  Unflavored-from: ef9316a2cd5277c245a22f0d4233dcefbb83bcc1

- Update vendored sources to duckdb/duckdb@bca7bac6d47317699d533754d3563cc06803564d.

  Date: 2026-10-11 22:45:18 +0000

  `[C-API-V2]` Log-sink support (https://redirect.github.com/duckdb/duckdb/pull/26872)

  Unflavored-from: be7e21c5a16cbcca2b03c0b8060072413220462c

- Update vendored sources to duckdb/duckdb@bea0d7753493ee630206bd6aa3fda101495f8877.

  Date: 2026-10-11 21:19:45 +0000

  `[C-API-V2]` Part 5? `PRAGMA`/`MACRO`/`SET <custom_option>` and more! (https://redirect.github.com/duckdb/duckdb/pull/26863)

  Unflavored-from: cc10d665c31d67041407a7d12d4ae4f4b8aea649

- Update vendored sources to duckdb/duckdb@047541acd5571e5b42124ee99585477e419b5e74.

  Date: 2026-10-11 21:02:43 +0000

  bump spatial for 2.0 (https://redirect.github.com/duckdb/duckdb/pull/26810)

  Unflavored-from: 8213ada5b4771c97543869e695da393a62b4cfa3

- Update vendored sources to duckdb/duckdb@32414d25269cd0d135e0d3691d6e5e8e96613ef2.

  Date: 2026-10-11 14:28:26 +0000

  \[C-API-V2\] Break-out common functionality + (https://redirect.github.com/duckdb/duckdb/pull/26820)

  Unflavored-from: adbe3660f36148505c80969462ccc1ed5c323649

- Update vendored sources to duckdb/duckdb@d8b295d88e365598d736b0125598430ce5213c1f.

  Date: 2026-10-10 10:26:42 +0000

  Skip windows_amd64 extension builds on pull requests instead of allow failure (https://redirect.github.com/duckdb/duckdb/pull/26831)

  Unflavored-from: e9ad3a390ef053ac70699b78db2fe81f2151cb1e

- Update vendored sources to duckdb/duckdb@fb4eca13824ffcff040ab9904f97502782762001.

  Date: 2026-10-10 06:35:17 +0000

  Keep fallible predicates below projections during filter pullup (https://redirect.github.com/duckdb/duckdb/pull/26807)

  Unflavored-from: b496b101ce6545d11e2647cefc9f6448a35a5de7

- Update vendored sources to duckdb/duckdb@6b6099a3e9787f1b32c59fab61fcdd1d3bc835cd.

  Date: 2026-10-09 19:44:32 +0000

  Allow windows_amd64 extension build failures on pull requests (https://redirect.github.com/duckdb/duckdb/pull/26822)

  Unflavored-from: 99471f6056ba3226aee4e142d5fd4294e2f826ea

- Update vendored sources to duckdb/duckdb@3350530b4b15b66ae2ba5bf78232b318cbc605eb.

  Date: 2026-10-09 17:04:41 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/25857: Parquet TIMESTAMP_NS (https://redirect.github.com/duckdb/duckdb/pull/26503)

  Unflavored-from: adb091f38d4133b523a550fc478084ffc0183e24

- Update vendored sources to duckdb/duckdb@802322ebceaa77e19de9930084a07f869b31290f.

  Date: 2026-10-09 16:57:01 +0000

  Improve parser robustness (https://redirect.github.com/duckdb/duckdb/pull/26771)

  Unflavored-from: d489b9e89b6b14c826e63dffe710d3f16888aefe

- Update vendored sources to duckdb/duckdb@4c9af167559a3ab650b9fe9df7fbcaa2e5f68f26.

  Date: 2026-10-09 16:47:54 +0000

  Fold TableFunctionBinder::DisableSQLValueFunctions into IdentifierConversionPolicy (https://redirect.github.com/duckdb/duckdb/pull/26407)

  Unflavored-from: f0bda1fa78778db4aa355017f567457825119ad0

- Update vendored sources to duckdb/duckdb@a5cc75154cc35866a32fc542382981d86d87f279.

  Date: 2026-10-09 15:28:12 +0000

  Fix unbounded type nesting depth (https://redirect.github.com/duckdb/duckdb/pull/26269)

  Unflavored-from: a6c17b7c35ebaa4b947aab085134a0c85c8cb152

- Update vendored sources to duckdb/duckdb@03d617a1c4d518c00b9cb6a1dd032f6b18ef535e.

  Date: 2026-10-09 14:15:42 +0000

  Bound the async backlog budget by the memory limit (https://redirect.github.com/duckdb/duckdb/pull/25183)

  Unflavored-from: 99c9f10985b8e894030bc8b242602145c38a68a2

- Update vendored sources to duckdb/duckdb@ebdd502d92dc1fe8f7756e0198836facaa834420.

  Date: 2026-10-09 12:41:33 +0000

  \[async results\] Error Submit / Query when the connection holds an open result (https://redirect.github.com/duckdb/duckdb/pull/26747)

  Landing v2 (finding 1): this commit refuses any statement on a connection while a result is open there, and a streamed Arrow result is one. The glue keeps `main`'s behaviour instead: it tracks the open Arrow results by client context (`ROpenResult`), and before it starts a statement there, in `rapi_prepare()`, `rapi_execute()`, the relational API, registration and ALTREP materialization, it ends them with `EndOpenResults()`, so their next read reports that another statement invalidated them (`src/arrow_export.cpp`).

  Landing v3 (findings 23 and 24): `Invalidated()` asks the glue's own mark alone, so a real interrupt or timeout reads as such; `EndOpenResults()` ends results under `open_results_lock` and `Untrack()` takes it before reading the context, so a release on another thread waits rather than freeing a result being ended; a source is tracked once `Initialize()` succeeded, and `ROpenResult` is neither copied nor moved (`src/arrow_export.cpp`, `src/include/rapi.hpp`, with a test).

  Unflavored-from: 95e33619c5dad92c013f761d7233e3b117f3b6eb

- Update vendored sources to duckdb/duckdb@17bb9c9988713abf57db5385e7294c847ac00e9b.

  Date: 2026-10-09 12:21:42 +0000

  Fix CTAS excessive temp usage (https://redirect.github.com/duckdb/duckdb/pull/25707)

  Unflavored-from: 35efd9fd1e1ba76262ce3ced1adfdfa390d9b0ca

- Update vendored sources to duckdb/duckdb@9747eff59592bc05498793af45d2a83d555f6eee.

  Date: 2026-10-09 11:22:20 +0000

  Regression fixes (https://redirect.github.com/duckdb/duckdb/pull/26791)

  Unflavored-from: 42f11692cb0c65b47d598f2dc419cf0f73d6e32b

- Update vendored sources to duckdb/duckdb@26b5b59d3e3b43706301d3a507bfe1c053faaf69.

  Date: 2026-10-09 09:42:28 +0000

  \[Secrets\] Add missing initialization of `persist_type` to `DEFAULT` (https://redirect.github.com/duckdb/duckdb/pull/26796)

  Unflavored-from: 399f527ecb5bf6a4f48975eb0ad4f29326a6937e

- Update vendored sources to duckdb/duckdb@8239f2515f1d01023eae35b6c6a25baed33d911e.

  Date: 2026-10-09 09:28:23 +0000

  GZIP OOB footer fix (https://redirect.github.com/duckdb/duckdb/pull/26499)

  Unflavored-from: 7b39a1458dc2549220b1e0d35c24a4dd70ab9c98

- Update vendored sources to duckdb/duckdb@34cc77ec3c23e6505eb0a59e42d075380a1f70a7.

  Date: 2026-10-09 09:25:07 +0000

  Deserializer sets window expression type (https://redirect.github.com/duckdb/duckdb/pull/26555)

  Unflavored-from: 09a93d775b08052118147383a8224fc473e44ebc

- Update vendored sources to duckdb/duckdb@181df00daa59d20f5c4433eeb89d0eaea73c5157.

  Date: 2026-10-09 09:24:36 +0000

  Provide `EXTENSION_NAME` to in-tree extensions (https://redirect.github.com/duckdb/duckdb/pull/26576)

  Unflavored-from: d8213a4fca7c2c8c54106947e9db1d7e6b15c6d2

- Update vendored sources to duckdb/duckdb@64f184a1d9c7e01c373c59ce1273623f87580ef1.

  Date: 2026-10-09 09:24:34 +0000

  Skip WAL block/size tests under the 16kB block size config (https://redirect.github.com/duckdb/duckdb/pull/26794)

  Unflavored-from: 82b648eb82ecfbaf2da5dddc29e27939cd6cc18c

- Update vendored sources to duckdb/duckdb@c29eca15a2f119e9c9d958fcd54542ba9171da76.

  Date: 2026-10-09 08:41:23 +0000

  TPC-H and TPC-DS generators: no environment, file or process access of their own (https://redirect.github.com/duckdb/duckdb/pull/26734)

  Unflavored-from: 99bc40bdfb41a60f364da8cdfd0ac71123e7ad40

- Update vendored sources to duckdb/duckdb@6825f59b976b3ff34c60343b79ba92fa7b0913b8.

  Date: 2026-10-09 08:39:59 +0000

  Use clang-cl for extension windows CI jobs (https://redirect.github.com/duckdb/duckdb/pull/26772)

  Unflavored-from: 1d4105279e8930efcc44db0169c78889e5b3fca1

- Update vendored sources to duckdb/duckdb@b15358c371daf10dad799a43b6167f6ccdce84d8.

  Date: 2026-10-09 08:36:17 +0000

  Support canonical ANY signatures in aggregate-state SQL (https://redirect.github.com/duckdb/duckdb/pull/26783)

  Unflavored-from: 7ac782c1e744aab20ff638f0a1c39382f1d0ad33

- Update vendored sources to duckdb/duckdb@f52439586a7adc3dae3bc2e66538447de313c607.

  Date: 2026-10-09 08:10:06 +0000

  Enable DUCKDB_NEW_EXTENSION_BUILD by default (https://redirect.github.com/duckdb/duckdb/pull/26521)

  Unflavored-from: 8af6d6826fd1cb7b865fd96a6de5fb3f84271404

- Update vendored sources to duckdb/duckdb@19aaa05603aec5d4136134cbd6e26dce91cedb75.

  Date: 2026-10-09 08:07:32 +0000

  Two fixes for alpha release CI (https://redirect.github.com/duckdb/duckdb/pull/26792)

  Unflavored-from: 564bf1ed62565f6f17bbe9c3f9551d7fac47a538

- Update vendored sources to duckdb/duckdb@690d113c24dad3b37529c1518354bcbe00d8ffbc.

  Date: 2026-10-09 08:01:32 +0000

  Use telemetry-based adaptive HT growing for aggregates (https://redirect.github.com/duckdb/duckdb/pull/26166)

  Unflavored-from: 93d67e486aad1e3c88bfe3b05f9cd19c4a3c1089

- Update vendored sources to duckdb/duckdb@9be551d9d05db959f19384585c708ebf423e6e51.

  Date: 2026-10-09 08:00:30 +0000

  Track explicit BEGIN across statements in StatementIterator (https://redirect.github.com/duckdb/duckdb/pull/26659)

  Unflavored-from: ac3aa126b9eeaf3eeb89823ea5cad164bbfb37ff

- Update vendored sources to duckdb/duckdb@c13558408522ddac671764bf06483138541278ed.

  Date: 2026-10-09 06:14:15 +0000

  Fix zero-column SQL export and outer-join cardinality (https://redirect.github.com/duckdb/duckdb/pull/26575)

  Unflavored-from: 5ac0a87573d32514814318d5e796451b2daec887

- Update vendored sources to duckdb/duckdb@44d0629672f6a77a5e51cf04526697c961b73648.

  Date: 2026-10-09 06:13:52 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/25701: Virtual Pushdown OOB (https://redirect.github.com/duckdb/duckdb/pull/26590)

  Unflavored-from: ed65969e6827e13ab96cb3150f740e29cffe983d

- Update vendored sources to duckdb/duckdb@621ebda4e8f60143bd377cf1430a24e267c99668.

  Date: 2026-10-09 06:12:55 +0000

  Make optional_idx constructors constexpr (https://redirect.github.com/duckdb/duckdb/pull/26770)

  Unflavored-from: b139b3b3c495e564126b6fdedf854ee268e77fc0

- Update vendored sources to duckdb/duckdb@5d3ea2478236956726020c6e7b02d45d636ba0f8.

  Date: 2026-10-09 06:12:22 +0000

  Load require extension directly without copying the binary (https://redirect.github.com/duckdb/duckdb/pull/26776)

  Unflavored-from: d0aead70a0f186411fe20166ef36a19815e38c8c

- Update vendored sources to duckdb/duckdb@c3503255bb0722295fd692bb4aad743bcc0e13e4.

  Date: 2026-10-09 06:10:55 +0000

  \[MultiFileReader\] Fixes to the column mapper for pushed down extract expressions (https://redirect.github.com/duckdb/duckdb/pull/26777)

  Unflavored-from: e451bb5734c476eac06dac87575e1aab472173aa

- Update vendored sources to duckdb/duckdb@16d25ab8972cd1adc21609900c151a99c8fbdd8b.

  Date: 2026-10-09 06:09:56 +0000

  Make the BLOB to BIT cast a try-cast so TRY_CAST returns NULL on an empty BLOB (https://redirect.github.com/duckdb/duckdb/pull/26761)

  Unflavored-from: 59c60a88370571b10c9ef6cff33a860f120a9444

- Update vendored sources to duckdb/duckdb@4edd76a16a7ddf93ed98a6ae114758896c6c1847.

  Date: 2026-10-09 05:32:31 +0000

  Avoid shredding colliding VARIANT keys (https://redirect.github.com/duckdb/duckdb/pull/24553)

  Unflavored-from: ccea5207d2e82f13741aa94e3a510886069e3a59

- Update vendored sources to duckdb/duckdb@0e2107f5556457ffbec0c68c5ac7dd0eaad6a6b7.

  Date: 2026-10-09 05:29:01 +0000

  Fix shredded VARIANT cast skipping overflow checks (https://redirect.github.com/duckdb/duckdb/pull/25836)

  Unflavored-from: 8bc2d7cb4e3559505d014cf2b2c6c7adf0e70323

- Update vendored sources to duckdb/duckdb@92792ebe8c13cf94f2c4eef71e4805bec859f059.

  Date: 2026-10-08 19:11:23 +0000

  Add pr tracker workflows (https://redirect.github.com/duckdb/duckdb/pull/26767)

  Unflavored-from: 3c2cc57c03dee538affce6cec9643fab69bbe591

- Update vendored sources to duckdb/duckdb@9edd75338e9679da15a435bcba40f52fe341a276.

  Date: 2026-10-08 18:30:40 +0000

  Fix assertion failure in DynamicFilter with nullable columns (https://redirect.github.com/duckdb/duckdb/pull/26699)

  Unflavored-from: 245b3ff1d53db9f933a2ecec5c8f3b515b7b1c6d

- Update vendored sources to duckdb/duckdb@e4531611d9209dc3e67d81207ad2b54f4aee3faa.

  Date: 2026-10-08 18:03:44 +0000

  Fix spurious checksum failures caused by stale block handles racing in-place metadata block rewrites (https://redirect.github.com/duckdb/duckdb/pull/26716)

  Unflavored-from: b0563921a17794e4661a574e3fb6fde9033921d6

- Update vendored sources to duckdb/duckdb@8cd7a642f0e5e73203eb77e1c542970a0a915830.

  Date: 2026-10-08 17:50:15 +0000

  Reject duplicate keys at insert time while a checkpoint runs (https://redirect.github.com/duckdb/duckdb/pull/26750)

  Unflavored-from: 376e3b689d66fe2d9449eeb21d3f6a2f50d12c8c

- Update vendored sources to duckdb/duckdb@cb78397be62e4842c148ae7d2172354a7580b962.

  Date: 2026-10-08 16:13:35 +0000

  Merge ready-to-merge PRs (https://redirect.github.com/duckdb/duckdb/pull/26680)

  Unflavored-from: 6e6fea8844dba36cf0ed2c9304756b044634e4ec

- Update vendored sources to duckdb/duckdb@2fc24d0cbde8fc90c9a4776bc21f55f230143eab.

  Date: 2026-10-08 15:32:36 +0000

  Allow to tweak (with the possibility of reverting) behaviour from https://redirect.github.com/duckdb/duckdb/pull/26096 (https://redirect.github.com/duckdb/duckdb/pull/26266)

  Unflavored-from: 23ca1357a5efcfbc3e661bd25a98d4a64fb89f4c

- Update vendored sources to duckdb/duckdb@11a8745b39203672dd27fe77f33c2daf381b9bb9.

  Date: 2026-10-08 14:13:56 +0000

  chore: remove delta patches (applied/landed) (https://redirect.github.com/duckdb/duckdb/pull/26610)
  Unflavored-from: 36dbcc0d8f7e8392ff20a33db2bbcc79eb142dca

- Update vendored sources to duckdb/duckdb@42d15ef8e0b84f3364cf507b40ebc37487299747.

  Date: 2026-10-08 14:13:43 +0000

  Determine the return type when folding a function call with a typed NULL argument (https://redirect.github.com/duckdb/duckdb/pull/26553)

  Unflavored-from: 889d12bf25654e0478f3f4ae0d95d7bbcfe9ad7e

- Update vendored sources to duckdb/duckdb@dda11d1d662ae586dda493fffafcd5fb3976d8c8.

  Date: 2026-10-08 13:48:25 +0000

  Improve skip counts and start tests from next config if slots available (https://redirect.github.com/duckdb/duckdb/pull/26732)

  Unflavored-from: 6d6a1f707ab347e1f3dda845932087318b28afc1

- Update vendored sources to duckdb/duckdb@908bb04b0bc49dc8fd653686ab29f086e121b834.

  Date: 2026-10-08 13:08:02 +0000

  Add `AGENTS.md` instructions for lldb scripts (https://redirect.github.com/duckdb/duckdb/pull/26525)

  Unflavored-from: 9cca04a3faaa4dddb772b682ee423392a1d4ffa3

- Update vendored sources to duckdb/duckdb@baadb10b42b006700f13b1f1a9ee0d1058295fc9.

  Date: 2026-10-08 12:54:12 +0000

  fix pooled scan states still holding segment pins after being returned to pool (https://redirect.github.com/duckdb/duckdb/pull/26723)

  Unflavored-from: b3639ad4dff6da02fe82130cd553fb4cec6039ac

- Update vendored sources to duckdb/duckdb@72491dc73ec5558470e96567958b2498f951f591.

  Date: 2026-10-08 12:25:32 +0000

  Make `UnboundIndex` non-final (https://redirect.github.com/duckdb/duckdb/pull/26535)

  Unflavored-from: 34f6c685778c113ce6545781ff73a3125862de24

- Update vendored sources to duckdb/duckdb@37f03e0d467ba097fdfc55042d11a24f41eaa386.

  Date: 2026-10-08 12:22:12 +0000

  C API v2: pass the file to single-file functions together with its open options, and describe files through `get_bind_info` (https://redirect.github.com/duckdb/duckdb/pull/26584)

  Unflavored-from: 0b18305a15e61d806bdc5db19e2df0f1dcd6f8d2

- Update vendored sources to duckdb/duckdb@890ac5bffb35af5602006bfede2dfb49b591c68a.

  Date: 2026-10-08 12:11:38 +0000

  Add Arrow result to stable C++ API (https://redirect.github.com/duckdb/duckdb/pull/26729)

  Unflavored-from: b12901d35508c3f9331518b4a7258453fb32b116

- Update vendored sources to duckdb/duckdb@d1c34561ea8f07addb36fd5d1e9e1d31e67200e8.

  Date: 2026-10-08 12:06:33 +0000

  Fix nightly clang tidy errors (https://redirect.github.com/duckdb/duckdb/pull/26683)

  Unflavored-from: f50f79072f7978d9af54d50e33485da8078adf23

- Update vendored sources to duckdb/duckdb@da64eeaf7c85e929abc46df59ad6c8b8b46b9cfa.

  Date: 2026-10-08 11:58:47 +0000

  Add query location to ExtractStatements errors (https://redirect.github.com/duckdb/duckdb/pull/26663)

  Unflavored-from: 95a56d9607c6e367465bd09fc5ec6000597b3579

- Update vendored sources to duckdb/duckdb@9383c4746861b176c8b33038d3323c8d197866c6.

  Date: 2026-10-08 11:48:09 +0000

  \[Backport\] Fix missing bitmap update for fixed size buffers (https://redirect.github.com/duckdb/duckdb/pull/26731)

  Unflavored-from: 15b33f473b31838f246d7a1c8502e3ba695f54d7

- Update vendored sources to duckdb/duckdb@851571a1273061347ad31aa20d35df787922cf18.

  Date: 2026-10-08 11:46:30 +0000

  Fix storage leak on checkpoint data race (https://redirect.github.com/duckdb/duckdb/pull/26722)

  Unflavored-from: 696966d885aafe1b093e8ba78f4f0ed5fbc91dfa

- Update vendored sources to duckdb/duckdb@ff5d46691d6fad01525c2030deea75fbb01eed89.

  Date: 2026-10-08 11:31:49 +0000

  Fixup CopyToFile to correctly rename also for opfs://file.db (https://redirect.github.com/duckdb/duckdb/pull/26559)

  Unflavored-from: 048dbd725b4e300ea4128fc264c49d3e648bd9e1

- Update vendored sources to duckdb/duckdb@1f5aa76e59513c0dca9af23d786f70a32947ed95.

  Date: 2026-10-08 11:27:05 +0000

  Fix confusing `COPY` warning (https://redirect.github.com/duckdb/duckdb/pull/26546)

  Unflavored-from: 1081c0c0f8d4ee6ca38c6ad0d2345803bbeb3f90

- Update vendored sources to duckdb/duckdb@2c76ab0f14f0056a5fb2431297aef06affc6a2dc.

  Date: 2026-10-08 10:47:56 +0000

  Remove index-name-based constraint uniqueness check (https://redirect.github.com/duckdb/duckdb/pull/26509)

  Unflavored-from: 8a9a4fd0818f765dc62a1f41a1e0cf9503751ae1

- Update vendored sources to duckdb/duckdb@0dc65ff31fe1236ad8f47f947f2d5ef6cabe1e92.

  Date: 2026-10-08 10:46:33 +0000

  Drop the monotone annotation from exp(): libm exp is not monotone (https://redirect.github.com/duckdb/duckdb/pull/26592)

  Unflavored-from: 171d41d93f6478c347f525583bee05c102b31120

- Update vendored sources to duckdb/duckdb@308e8821e06a15c2c0a45c8ac4becf5f1b8f6a90.

  Date: 2026-10-08 10:34:09 +0000

  Estimate the ASOF join cardinality before planning its children (https://redirect.github.com/duckdb/duckdb/pull/26301)

  Unflavored-from: 245bed0eb679d5eed39ebba7aaa610f69513dc52

- Update vendored sources to duckdb/duckdb@f5cd3b0d3c31d0635dd6d622fc530d205e68d891.

  Date: 2026-10-08 09:02:50 +0000

  Move ADBC to arrow format (https://redirect.github.com/duckdb/duckdb/pull/26704)

  Unflavored-from: 4c3dee7682d298393ca322e7c94ea2ab387a1907

- Update vendored sources to duckdb/duckdb@885af2ba9fbbae68d77d467c888d340150795223.

  Date: 2026-10-08 08:50:10 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/25701: Streaming Window UNION (https://redirect.github.com/duckdb/duckdb/pull/26588)

  Unflavored-from: 1f1d9b08ea70a9ee2de9f50e963c3296b57e0a97

- Update vendored sources to duckdb/duckdb@f2f9329721f3d7228296c07f40c3cac72243a6df.

  Date: 2026-10-08 11:41:03 +0200

  Remove double quotes from error message (https://redirect.github.com/duckdb/duckdb/pull/26666)

  Unflavored-from: f7fb99a4bcfcf497e7af4d4aad35ca745b95213b

- Update vendored sources to duckdb/duckdb@72d330366ac7aaee0e09b50aeedf02cbb29adf88.

  Date: 2026-10-08 08:33:28 +0000

  Add legacy_parser extension (https://redirect.github.com/duckdb/duckdb/pull/26479)

  Unflavored-from: 57e14785368a28e52eef658cc124e3e019331b3d

- Update vendored sources to duckdb/duckdb@bdb047de5a1ef1d7f2f3bf8f85d21ccc2be3309c.

  Date: 2026-10-08 08:18:49 +0000

  Split up `ScalarFunction::bind` into `resolve_types` and `bind` (https://redirect.github.com/duckdb/duckdb/pull/26548)

  Unflavored-from: 8525be6664bb60a7e3fb0973bfa4d9e07fcd3c05

- Update vendored sources to duckdb/duckdb@26e63077ac75b8221f905e49154f6e6cfd0b0a9e.

  Date: 2026-10-08 07:05:02 +0000

  \[Copy\] Add entries to `RETURN_STATS` for structs and lists (https://redirect.github.com/duckdb/duckdb/pull/26538)

  Unflavored-from: 82e5b94edd607c30f0fa1f69857539f81754cae6

- Update vendored sources to duckdb/duckdb@fc101c337b57bce1729d2261b98c4c8d9ba1749f.

  Date: 2026-10-08 06:05:26 +0000

  Fix CI (https://redirect.github.com/duckdb/duckdb/pull/26728)

  Unflavored-from: f54327466a8f50c3d40b9397974ae3f48976910e

- Update vendored sources to duckdb/duckdb@079dbd66bd7fd978e8ff9ce03174e7cf5b5da648.

  Date: 2026-10-08 05:10:09 +0000

  \[async results\] Roll back on closing the result (https://redirect.github.com/duckdb/duckdb/pull/26314)

  Unflavored-from: 762c7d827b82f683037870684f088db80722f09f

- Update vendored sources to duckdb/duckdb@53d30031051018f6c5e0a07bc35abe3d7fe1c7ce.

  Date: 2026-10-07 22:12:07 +0000

  Fix lost crs and type mismatch on deserializing shredded geo column (https://redirect.github.com/duckdb/duckdb/pull/26518)

  Unflavored-from: 79487beeb45267415a7b21c83de28be5e74015a1

- Update vendored sources to duckdb/duckdb@15e295c6629a0f9a4d81b5eeaf133e0d4eba26e1.

  Date: 2026-10-07 21:44:17 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10930: Backport FILL Extrapolation (https://redirect.github.com/duckdb/duckdb/pull/26504)

  Unflavored-from: 9f218733acd45f01aea6f0adc2705d094a73b185

- Update vendored sources to duckdb/duckdb@a55098af7a165b9d77d61981391da1dc0e4cbe00.

  Date: 2026-10-07 21:26:13 +0000

  Fall back to the backup extension servers when extensions.duckdb.org or community-extensions.duckdb.org is unavailable (https://redirect.github.com/duckdb/duckdb/pull/26523)

  Unflavored-from: d3f49ca6304de6cedcf20a686991c5c95085d213

- Update vendored sources to duckdb/duckdb@359db66d9cc31dd280d5b8b037b529091d6199b1.

  Date: 2026-10-07 21:25:59 +0000

  Accept backtick-quoted identifiers as an alternative to double quotes (https://redirect.github.com/duckdb/duckdb/pull/26519)

  Unflavored-from: 7b11bff0577a58782e27a7254801d1c93d0086b8

- Update vendored sources to duckdb/duckdb@71fee15fd500abef74fae84cdada3d9ad193b409.

  Date: 2026-10-07 20:27:49 +0000

  Fix string stats merge (https://redirect.github.com/duckdb/duckdb/pull/26656)

  Unflavored-from: c8c20609edb1fcc9fc7455f228c47dc8ac3fe0e0

- Update vendored sources to duckdb/duckdb@e97da7f82c9b6283a6033103be3ac7ad17f545c9.

  Date: 2026-10-07 20:06:51 +0000

  Add a column_statistics option to multi-file scans (https://redirect.github.com/duckdb/duckdb/pull/26516)

  Unflavored-from: d5ab6e0f366ad8bb68acc373977af46fef20eb94

- Update vendored sources to duckdb/duckdb@6afcb082657ebae0911f7b1887a8743afa525355.

  Date: 2026-10-07 17:50:39 +0000

  Fixup so that avro is compatible with clang-cl (https://redirect.github.com/duckdb/duckdb/pull/26698)

  Unflavored-from: 9a5fdec5e4c86fe708baa673a56eca39ff528c1c

- Update vendored sources to duckdb/duckdb@4fbae437b223047ba34e15222f269a2f6b364afc.

  Date: 2026-10-07 15:35:21 +0000

  Redact HTTP headers and urls in duckdb_logs (https://redirect.github.com/duckdb/duckdb/pull/26522)

  Unflavored-from: 8001d35b6d5607cc16710247e97f105278a70997

- Update vendored sources to duckdb/duckdb@e09c16e3d043ecadd22eb26775f783019edc3ec2.

  Date: 2026-10-07 15:04:45 +0000

  Report an error when querying non-queryable log storage (https://redirect.github.com/duckdb/duckdb/pull/26486)

  Unflavored-from: a6fb8b7fdb14a180724aded3ee68b25ac6c2e5d6

- Update vendored sources to duckdb/duckdb@e64b6a6b738edba0ef6620c2d468f0f872980d6b.

  Date: 2026-10-07 15:03:47 +0000

  Limit recursion depth in `json_structure` (https://redirect.github.com/duckdb/duckdb/pull/26079)

  Unflavored-from: cfe94efc131ab461611b8cf6173cc91bc8c25212

- Update vendored sources to duckdb/duckdb@d58ce106373cb5e224c734f5613060ab9841e127.

  Date: 2026-10-07 14:23:25 +0000

  PEG matcher: skip sub-matchers that cannot start at the current token (FIRST set) (https://redirect.github.com/duckdb/duckdb/pull/26451)

  Unflavored-from: cd98519e29df3a9fbc0d96e5ba584fcdc4721a07

- Update vendored sources to duckdb/duckdb@05b133e6dbcf36354b1283647876e580371e3a7a.

  Date: 2026-10-07 20:04:59 +0200

  Allocate the parser's per-statement data from arenas (https://redirect.github.com/duckdb/duckdb/pull/26037)

  Unflavored-from: 3e03e913c138263e0b716edcbc4ee8a537d6c729

- Update vendored sources to duckdb/duckdb@c13e2e415ad6adaadd6989c7f4b65ada785c0a35.

  Date: 2026-10-07 19:59:34 +0200

  Stabilize partitioned_write_backpressure test (https://redirect.github.com/duckdb/duckdb/pull/26677)

  Unflavored-from: 7c18fc8a5087bc1c6c0765714728ad2330c0f8ba

- Update vendored sources to duckdb/duckdb@3fc556b779c76304e1a14c474661272092d3ca41.

  Date: 2026-10-07 14:07:51 +0000

  \[Build\] Fix linking for extension builds (https://redirect.github.com/duckdb/duckdb/pull/26463)

  Unflavored-from: 204b497bea0352d0323efed93b8688ca058d0a5d

- Update vendored sources to duckdb/duckdb@b76acf72d73612b7b746dde5c832b61bdd273c4a.

  Date: 2026-10-07 16:19:42 +0200

  Fix storage leak for blocks freed while still in use (https://redirect.github.com/duckdb/duckdb/pull/26638)

  Unflavored-from: 9f0797081ced879b485dd8bb30302019191a1f99

- Update vendored sources to duckdb/duckdb@a11f21edffa8e2c29eee585b949b5cc563a09eb6.

  Date: 2026-10-07 16:19:17 +0200

  Fix out-of-bound access for column segment (https://redirect.github.com/duckdb/duckdb/pull/26645)

  Unflavored-from: 9bbde0b6640c7a06200e0e6eaf3664f823794a6b

- Update vendored sources to duckdb/duckdb@270f7aec6e582d134f6dfa8c493759870f29a622.

  Date: 2026-10-07 16:07:02 +0200

  Use clang-cl for windows CI jobs (https://redirect.github.com/duckdb/duckdb/pull/26533)

  Unflavored-from: d6f457e586db3d1fb434d50b6bfcb2cc3e7cc7d4

- Update vendored sources to duckdb/duckdb@57c755a991d44bc967bed33f451a00375e76c346.

  Date: 2026-10-07 11:21:55 +0000

  \[Parquet\] Fix disabling `VARIANT` shredding in `COPY` (https://redirect.github.com/duckdb/duckdb/pull/26462)

  Unflavored-from: fb3e95161ab12ea8148a81b554804f44533396f4

- Update vendored sources to duckdb/duckdb@13d1d8f56a82b3413055819eb90d0b0e68b5c847.

  Date: 2026-10-07 09:17:36 +0000

  Make IsDuckTable actually overridable in practice (https://redirect.github.com/duckdb/duckdb/pull/26570)

  Unflavored-from: 66c72686e8107ac962b38778daf15da41f75c82e

- Update vendored sources to duckdb/duckdb@fae064976651b898166dbbe3fef14b55dbc29c7d.

  Date: 2026-10-07 10:31:49 +0200

  Stabilize parquet_prefetch_tracked_memory test (https://redirect.github.com/duckdb/duckdb/pull/26653)

  Unflavored-from: ad1e00582efeecbf24f53a918ae49adc292bb8b0

- Update vendored sources to duckdb/duckdb@67ec9ec6880c160ec687c83db8264be0192a0ecf.

  Date: 2026-10-07 10:31:30 +0200

  \[Dev\] Fix randomly failing `mode_tpch.test_slow` (https://redirect.github.com/duckdb/duckdb/pull/26541)

  Unflavored-from: cdcf9a1851323fca2234a7c34260327b0a4155d1

- Update vendored sources to duckdb/duckdb@fa93ada028b1258926e827be7af3627979093d47.

  Date: 2026-10-07 09:53:14 +0200

  Merge v1.5-variegata into v2.0-cyanoptera (https://redirect.github.com/duckdb/duckdb/pull/26527)

  Unflavored-from: 2725faa68570c972dba0c4f2ef7eec93b8c8ccbf

- Update vendored sources to duckdb/duckdb@14aab908c611ac3ea83ecd20ddb8f0736ab6e375.

  Date: 2026-10-07 09:52:56 +0200

  Fix copying from a constant vector at an offset beyond the standard vector size (https://redirect.github.com/duckdb/duckdb/pull/26524)

  Unflavored-from: 6c00305cb86d054f52a02a85ea25b5ec0445b727

- Update vendored sources to duckdb/duckdb@5c0c6bfa8a37abcb139b07f68b77b379c24f447c.

  Date: 2026-10-07 09:52:39 +0200

  Correctly handle failing member casts in UNION TRY_CAST (https://redirect.github.com/duckdb/duckdb/pull/26495)

  Unflavored-from: 8ff87f984d7d8e71c62569712d250339dfd83e41

- Update vendored sources to duckdb/duckdb@2cb6d711aa45c4ee26599ca63052f4342d4f2c87.

  Date: 2026-10-07 09:52:22 +0200

  Cast the buffered argument columns of an ordered to_aggregate_state to the signature types (https://redirect.github.com/duckdb/duckdb/pull/26490)

  Unflavored-from: 759c22132b5daa1a8f59478a4fca57c5737c2667

- Update vendored sources to duckdb/duckdb@20e85c44440699e2c3825ae8b5b20e59df7e2608.

  Date: 2026-10-07 09:51:18 +0200

  Validate VARIANT decimal scale and range (https://redirect.github.com/duckdb/duckdb/pull/26484)

  Unflavored-from: bafee4dc59e0cfd6704f24fab847253781e4754e

- Update vendored sources to duckdb/duckdb@86be5722eefdca644f9d848de58ee3d9feb7bbf2.

  Date: 2026-10-07 00:09:55 +0000

  Fix https://redirect.github.com/duckdb/duckdb/pull/26433: Do not drop filter when LIKE/ILIKE pattern is NULL (https://redirect.github.com/duckdb/duckdb/pull/26469)

  Unflavored-from: a36dd9d297c5be9ead61424af0f5ff6f2e739943

- Update vendored sources to duckdb/duckdb@d05e1133a451ea2e4ef44696837abb2c67d4d7bd.

  Date: 2026-10-06 19:29:10 +0000

  Report malformed WKT as a cast error in TRY_CAST to GEOMETRY (https://redirect.github.com/duckdb/duckdb/pull/26497)

  Unflavored-from: f773cdaca29efca54389f9f9fdf1053305e92368

- Update vendored sources to duckdb/duckdb@5070de3585e846718fac121b5b149f4236e6a58a.

  Date: 2026-10-06 10:36:05 +0000

  Fix struct_contains / struct_position with mixed numeric member types (https://redirect.github.com/duckdb/duckdb/pull/26238)

  Unflavored-from: 164f79ae0ebb23a988e9f9fe7757a47139456be8

- Update vendored sources to duckdb/duckdb@6cde342a9e3822f721d529f592b627fdda594bd2.

  Date: 2026-10-06 10:05:09 +0000

  Count pushed-down files in multi-file wrapper and patch postgres_scanner catalog cache race (https://redirect.github.com/duckdb/duckdb/pull/26472)

  Unflavored-from: 63162d16609d621bbb6ecc99d0bdc74bcf145d09

- Update vendored sources to duckdb/duckdb@1a779c5c43100f162d19237e3cf3e64f36bc3485.

  Date: 2026-10-06 08:31:38 +0000

  Recursive -\> iterative refactor for `json_merge_patch` + added a stack template (https://redirect.github.com/duckdb/duckdb/pull/26487)

  Unflavored-from: ca4f5627fe954b3a951fd33c938340f968e2d3fd

- Update vendored sources to duckdb/duckdb@1d1bfa1f2e914f208360b535bb3b6109e7e03b14.

  Date: 2026-10-06 08:19:17 +0000

  Fix named WINDOW lost when a subquery precedes its reference (https://redirect.github.com/duckdb/duckdb/pull/26439)

  Unflavored-from: 155abeca04283f71fa6fc1ce4f185d3b314018e0

- Update vendored sources to duckdb/duckdb@ba0e9bf5ae45e01ded3efe6c06daf8a464f1fbff.

  Date: 2026-10-06 08:17:41 +0000

  Range-check the time zone offset in ICU TIMETZ conversions (https://redirect.github.com/duckdb/duckdb/pull/26493)

  Unflavored-from: b3983eb5ca70824f7ab7bc6ee1def61a1bdfc76f

- Update vendored sources to duckdb/duckdb@5203ac4dc72bbcb70fdecaacba98331a9ec18687.

  Date: 2026-10-06 08:08:10 +0000

  Validate counts when importing an approx_top_k state (https://redirect.github.com/duckdb/duckdb/pull/26511)

  Unflavored-from: 0c873bce8e7d7e91c3e1e3b16e55309059e0d212

- Update vendored sources to duckdb/duckdb@df47ba32d99dd0f4cb21ae4bded9f1105bb9be42.

  Date: 2026-10-06 08:07:45 +0000

  Fix data corruption when dropping a column whose name contains a dot (https://redirect.github.com/duckdb/duckdb/pull/26514)

  Unflavored-from: 0a38c7b1091a03d396f086e82b4b17e71dab9da7

- Update vendored sources to duckdb/duckdb@2b76188311fb55017564d8699ade29740b5aeb91.

  Date: 2026-10-06 08:03:39 +0000

  Prevent creation of unnamed structs in favor of tuples (https://redirect.github.com/duckdb/duckdb/pull/26501)

  Unflavored-from: edeb18ce7f71639194f6466550544a3b02f48c5b

- Update vendored sources to duckdb/duckdb@e909c8d1762a46ec86af31cfe5a3d8a7a0d145b6.

  Date: 2026-10-06 09:39:39 +0200

  Tpch dbgen fidelity (https://redirect.github.com/duckdb/duckdb/pull/26431)

  Unflavored-from: 2ed8c7bfa2712e42e7c580e32c36d5d3eef37a29

- Update vendored sources to duckdb/duckdb@d7d18caa5a7786be57c08addba6d0711d8d64841.

  Date: 2026-10-06 07:09:38 +0000

  IEJoin: split the right payload from the right columns of the merged chunk (https://redirect.github.com/duckdb/duckdb/pull/26467)
  Unflavored-from: 1a0690b359aee9ded6baf3843d7edc5e88482c1b

- Update vendored sources to duckdb/duckdb@8a5220b83b5d2e4334abe5ca284394ccb598e64d.

  Date: 2026-10-06 06:50:44 +0000

  Check that the ORDER BY 'order' field of to_aggregate_state is a string (https://redirect.github.com/duckdb/duckdb/pull/26512)

  Unflavored-from: 363f3aaced3d4a57119b08342482caa734953e5d

- Update vendored sources to duckdb/duckdb@7ae341818cd52154f4f11eaae6d805a702dab2f2.

  Date: 2026-10-06 06:31:51 +0000

  Upload unittest binary in release artifact (https://redirect.github.com/duckdb/duckdb/pull/26339)

  Unflavored-from: 89ea2cc909b44aa92b7451b5b089fd7d901bd344

- Update vendored sources to duckdb/duckdb@fdcb8a05d630d9dfbbd134532879bb0d49a44911.

  Date: 2026-10-06 05:54:17 +0000

  fix parquet double conversion for decimal with precision over 38 (https://redirect.github.com/duckdb/duckdb/pull/25058)

  Unflavored-from: 3cbad102acdddcd9edbbc49512aaef698ab6d399

- Update vendored sources to duckdb/duckdb@f44ad7d7fb5aec3059bfd049957f0c5c0a18c944.

  Date: 2026-10-06 05:35:56 +0000

  Respect `ROW_GROUP_SIZE_BYTES` (https://redirect.github.com/duckdb/duckdb/pull/25060)

  Unflavored-from: 628c275ea2447a44d546b086317dcc9e3c578cbb

- Update vendored sources to duckdb/duckdb@064c154cee216e4f1a7104ad6a207d8b44765df3.

  Date: 2026-10-06 04:44:12 +0000

  Fix multi-source pipeline detection (https://redirect.github.com/duckdb/duckdb/pull/26480)

  Unflavored-from: 9030e73cfa8c83f3007a7bebcbd266cf94965e5f

- Update vendored sources to duckdb/duckdb@e4ddfbf139d01d05aea33b6ed1ad28b3c5196d11.

  Date: 2026-10-06 02:23:12 +0000

  Static type info fix (https://redirect.github.com/duckdb/duckdb/pull/26475)

  Unflavored-from: 71ac64e1902bcfd284b5abfb9fd1f819b81dbfce

- Update vendored sources to duckdb/duckdb@987920ef4ef88c1d65b36207e02171cfc27a6a86.

  Date: 2026-10-06 02:21:45 +0000

  Add geometry \<-\> blob (wkb) cast (https://redirect.github.com/duckdb/duckdb/pull/26464)

  Unflavored-from: a792aebdf95e8c8b960c0900e63f55ff77a53f4a

- Update vendored sources to duckdb/duckdb@edb4739fc8a748b1a2f3983f7d1cc112e0ae4696.

  Date: 2026-10-06 02:12:27 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/26365: ICU Interval Negation (https://redirect.github.com/duckdb/duckdb/pull/26505)

  Unflavored-from: 9d58363fc370fc66e43ced860f1bda384c9e0e18

- Update vendored sources to duckdb/duckdb@6af6666ae4f8611618a79e546681b5e18b7d0e81.

  Date: 2026-10-06 02:00:56 +0000

  Mark single-argument ICU date part functions as fallible (https://redirect.github.com/duckdb/duckdb/pull/26496)

  Unflavored-from: 5f91f5c33af2fc12128ed447970d03198daa6cf9

- Update vendored sources to duckdb/duckdb@456c18f5f91130024ff9835d33c761d40c0c149f.

  Date: 2026-10-06 01:36:18 +0000

  Get consecutive list before compressing in Parquet (https://redirect.github.com/duckdb/duckdb/pull/26481)

  Unflavored-from: 5b3f2bab763949918bf076c69ac099013639f5d7

- Update vendored sources to duckdb/duckdb@cfd656a1d68f2753d447b52149658799685a0e90.

  Date: 2026-10-06 01:31:29 +0000

  Validate deserialized types (https://redirect.github.com/duckdb/duckdb/pull/26488)

  Unflavored-from: 75ef84b0403e015c1324c25df5ee565cf2e04f3e

- Update vendored sources to duckdb/duckdb@885cc4a723dcc6d49d974c2023c4dbeef8e376db.

  Date: 2026-10-06 00:50:41 +0000

  Verify regex results are valid UTF-8, and handle invalid UTF-8 in string functions (https://redirect.github.com/duckdb/duckdb/pull/26485)

  Unflavored-from: 57c0643a0d26d225f017fb9eac6fd975e3cc17de

- Update vendored sources to duckdb/duckdb@f0f549e7cfe37c507a060c7e7f533539b31adc15.

  Date: 2026-10-06 00:45:51 +0000

  Fix null dereference in PIVOT IN list with zero-argument row() (https://redirect.github.com/duckdb/duckdb/pull/26443)

  Unflavored-from: a00f3ecb582c92ba40581340559e2b8217ee47cf

- Update vendored sources to duckdb/duckdb@08bb78c866b745aa780dab99a77bc4beeaae4083.

  Date: 2026-10-06 00:40:37 +0000

  Throw in LPAD, RPAD and TRANSLATE when the result exceeds the maximum string size (https://redirect.github.com/duckdb/duckdb/pull/26482)

  Unflavored-from: 5ecd6ace2c8f21e70de360885b18b9aa99446c09

- Update vendored sources to duckdb/duckdb@ae89a5f2af20764cd8ad12a799414b5d3e373aa7.

  Date: 2026-10-06 00:38:54 +0000

  Fix enum_range_boundary crash when the first argument is an untyped NULL (https://redirect.github.com/duckdb/duckdb/pull/26428)

  Unflavored-from: 76feb5a541bc510af7bc4e624d2be8ceaa45802f

- Update vendored sources to duckdb/duckdb@b5f61531e1069af826cfbf8e735b69e6ba904087.

  Date: 2026-10-06 00:37:11 +0000

  Validate TIME range when decoding binary Variant values and harden FormatTwoDigits (https://redirect.github.com/duckdb/duckdb/pull/26483)

  Unflavored-from: 98fe8c6f8d626af27938c20b84a965436b9e402c

- Update vendored sources to duckdb/duckdb@99f2ee58102c3a13d77a8c6e351fdc2b7b5d7a73.

  Date: 2026-10-06 00:31:35 +0000

  More various grammar fixes (https://redirect.github.com/duckdb/duckdb/pull/26477)

  Unflavored-from: 04cbed2c4cb308be4b346aa3bd4a4bd2ecf7860a

- Update vendored sources to duckdb/duckdb@4c6461bf7694f830e65368a1b07a6b8032a6efc3.

  Date: 2026-10-06 00:30:19 +0000

  Fix substring_grapheme returning the full string for negative offsets before the start of the string (https://redirect.github.com/duckdb/duckdb/pull/26476)

  Unflavored-from: c762913e3eca0b43dc3729cdfb07c51fb111de5a

- Update vendored sources to duckdb/duckdb@2a0741ce9edfe508e53abb22fe26766258a03270.

  Date: 2026-10-06 00:27:51 +0000

  Shell: buffer pending input (https://redirect.github.com/duckdb/duckdb/pull/26470)
  Unflavored-from: 3ebf8b2c7aa01d04f891c493dbe292d6c39555eb

- Update vendored sources to duckdb/duckdb@970649f524cad1f9bf003ddad1f1436a326d1629.

  Date: 2026-10-06 00:27:40 +0000

  Bound partitioned COPY buffering during active flushes (https://redirect.github.com/duckdb/duckdb/pull/25913)

  Unflavored-from: 053a99455756c6c2468dd1c3bb042004781509ea

- Update vendored sources to duckdb/duckdb@13f60176c10ea0ee65cfd06ccda00d73c23286dd.

  Date: 2026-10-06 00:27:06 +0000

  Request huge pages for the join hash table entry array (https://redirect.github.com/duckdb/duckdb/pull/25869)

  Unflavored-from: 9df24663afd41a5b0e3aac1397e8d88e344d259f

- Update vendored sources to duckdb/duckdb@36265ef34dd6cda47dad3561cfd10da84200f332.

  Date: 2026-10-05 23:30:17 +0000

  Fix CREATE OR REPLACE TABLE leaving stale foreign key references (https://redirect.github.com/duckdb/duckdb/pull/26068)

  Unflavored-from: 4e640d46e478eca32558eb37b16f76a2b1822833

- Update vendored sources to duckdb/duckdb@46e658503fce27854e6c0496ed7177620665c576.

  Date: 2026-10-05 20:47:14 +0000

  Apply collations to struct and tuple fields (https://redirect.github.com/duckdb/duckdb/pull/25427)

  Unflavored-from: 489e281e8c68d9df326c7355f49a33a55400e7f0

- Update vendored sources to duckdb/duckdb@96df096fb00184f615770231fcb61884c97d77eb.

  Date: 2026-10-05 19:25:20 +0000

  Fix per-row separator handling in parse_path (https://redirect.github.com/duckdb/duckdb/pull/26438)

  Unflavored-from: efc23db8813d0d0d4b819f08b9a72e4cdcd8069d

- Update vendored sources to duckdb/duckdb@b99031e62d00e4dc0082411e759dac5ac3727ea9.

  Date: 2026-10-05 19:03:16 +0000

  Error on empty WKB input (https://redirect.github.com/duckdb/duckdb/pull/26461)

  Unflavored-from: 5244b67639c5169d4e17c6518f32439a26d32e5e

- Update vendored sources to duckdb/duckdb@467b20d48a487c2e35829fa2c7dfd8cced994c8a.

  Date: 2026-10-05 18:38:19 +0000

  Add optimizer tests (https://redirect.github.com/duckdb/duckdb/pull/26459)

  Unflavored-from: 7e5f291cebc6cb0b217d12a566fd2472dfcccc3f

- Update vendored sources to duckdb/duckdb@ca990ac66eaec3c1ae3bfbf82d9b06e9c48a04bd.

  Date: 2026-10-05 16:01:26 +0000

  Fix int32 overflow in timezone(INTERVAL, TIMETZ) offset (https://redirect.github.com/duckdb/duckdb/pull/26458)

  Unflavored-from: cded8ba5337d41b4bb6eeb6e764f20a692c8976f

- Update vendored sources to duckdb/duckdb@bf0a287472704642357869254d93b2cfbe506ee8.

  Date: 2026-10-05 15:11:06 +0000

  Assign runtime OIDs to constraint-backed indexes (https://redirect.github.com/duckdb/duckdb/pull/26080)

  Unflavored-from: 90f9236a31d5041a38038f036b99a32bd58a115f

- Update vendored sources to duckdb/duckdb@30b9eafaf497ffe2d7222aea20bb3732ca92673e.

  Date: 2026-10-05 14:39:05 +0000

  Fix correlated HAVING empty input handling (https://redirect.github.com/duckdb/duckdb/pull/25478)

  Unflavored-from: 15ffaf29b73f65924addbf3b2bbcc0535c817f7d

- Update vendored sources to duckdb/duckdb@183ff1704d4531ae61acf53fd66e9b7a13e13535.

  Date: 2026-10-05 14:21:24 +0000

  Fix Parquet RETURN_STATS min/max for TIMETZ (https://redirect.github.com/duckdb/duckdb/pull/26164)

  Unflavored-from: 5586cfbebf06da3ea1afa07645ace7a9d0b19ccc

- Update vendored sources to duckdb/duckdb@2cda6db14be6fb82baac2fa7c33d7d50ffced442.

  Date: 2026-10-05 13:57:42 +0000

  Propagate stats for all NULL row group for all type cast (https://redirect.github.com/duckdb/duckdb/pull/25590)

  R-side fix (CI tooling, `clean` gate):
  roxygen2 8.1.1.9000 on the runners rewrites `Config/roxygen2/version`,
  so every commit still carrying 8.1.0.9000 failed `gate clean` with only that diff
  (snapshots, check and pkgdown passed).
  Folded here: `Config/roxygen2/version: 8.1.1.9000`, the same change `main` carries
  as 98ab97a8b4 (chore: Auto-update from GitHub Actions), whose port above this commit
  was green and is now empty.

  Unflavored-from: 38c1ff6b448f04ab0d5e969b56620a2d84ec2f90

- Update vendored sources to duckdb/duckdb@0121e60ad5cbc1b98e943125749efb6300fb55e9.

  Date: 2026-10-05 13:54:02 +0000

  Preserve projection selections when rewriting logical children (https://redirect.github.com/duckdb/duckdb/pull/26304)

  Unflavored-from: 59bce74361e1dd18d5ae37552ed1af2340524529

- Update vendored sources to duckdb/duckdb@8da8e69522b4f6da1e22c40ae35aa93a951879d8.

  Date: 2026-10-05 13:41:56 +0000

  Fix two flaky tests and race condition in DirectFileReader read_text() (https://redirect.github.com/duckdb/duckdb/pull/26384)

  Unflavored-from: a26c7244e30d09e9215f3d049e78080cf14c9f0d

- Update vendored sources to duckdb/duckdb@2b87ae078df345adced1a4b919f2c8c585f8e88f.

  Date: 2026-10-05 13:29:25 +0000

  Fix memory setting casting (https://redirect.github.com/duckdb/duckdb/pull/26413)

  Unflavored-from: a02393e8a804ed8d8c8b327ca082e1537a2e9d6e

- Update vendored sources to duckdb/duckdb@7340600c3758426b5d903025f61dc8d234c05845.

  Date: 2026-10-05 13:18:37 +0000

  Fix conversions at the lower `TIMESTAMP_NS` boundary (https://redirect.github.com/duckdb/duckdb/pull/26411)

  Unflavored-from: 64b6eb572786eed64eb902daa01f133be1b3e521

- Update vendored sources to duckdb/duckdb@59002e8c87a8872027d3d4417133f1569bb4bb27.

  Date: 2026-10-05 13:18:19 +0000

  Do not treat ATTACH paths as remote files when an explicit storage TYPE is given (https://redirect.github.com/duckdb/duckdb/pull/26410)

  Unflavored-from: 293db5299fa02af009816ae9c83c1b33390f2ecb

- Update vendored sources to duckdb/duckdb@a255be5543080eee201b752eef420e711f6ea012.

  Date: 2026-10-05 16:48:02 +0200

  Fix assertion trigger in list_grade_up/list_sort on non-LIST arguments (https://redirect.github.com/duckdb/duckdb/pull/26471)

  Unflavored-from: 814aa035568ea2f54b1761ac6f0c562a48e28077

- Update vendored sources to duckdb/duckdb@683fd0764a1eb6968a4d7bba825b59fd3a40a09b.

  Date: 2026-10-05 12:46:06 +0000

  Fix checkpoint corrupting -0.0 into 0.0 for FLOAT/DOUBLE columns (https://redirect.github.com/duckdb/duckdb/pull/25592)

  Unflavored-from: 379598caebbfee1f4a1d6b1acb68aec627c15aaa

- Update vendored sources to duckdb/duckdb@354605a9df80f1ddc66e594d615c953e31fa2bed.

  Date: 2026-10-05 12:45:37 +0000

  Fix OOB read and leak in GZIP string decompression (https://redirect.github.com/duckdb/duckdb/pull/26077)

  Unflavored-from: 8903b66a3f04c30f805bb93044130ef7ee65c935

- Update vendored sources to duckdb/duckdb@4989d99e51f75a65553cb84f75d0a0a933acbdd1.

  Date: 2026-10-05 12:44:23 +0000

  Fix segfault in common subplan optimizer with nested repeated subplans (https://redirect.github.com/duckdb/duckdb/pull/26440)

  Unflavored-from: 1ac0fd88c7f7b3ba54c6ca1c2e0d8b3faf79ff8f

- Update vendored sources to duckdb/duckdb@723c28faf55024dc15c0a00ca1ab86fec4d4bfe3.

  Date: 2026-10-05 12:04:25 +0000

  Prevent outer-join NULL constraints from propagating through LIMIT and TOP_N by using isolated optimizer visitors (https://redirect.github.com/duckdb/duckdb/pull/24904)

  Unflavored-from: aafcd9a6f27934ddea29dd0ae4680fdfcb56c762

- Update vendored sources to duckdb/duckdb@72f5057d2b52c7d9dd20fb032282ead14b13c05c.

  Date: 2026-10-05 11:51:34 +0000

  Reject SET/DROP NOT NULL,SET DEFAULT,ALTER TYPE on nested struct fields (https://redirect.github.com/duckdb/duckdb/pull/25479)

  Unflavored-from: 5b7c8f8c12d9b9e5c107ba4bfaa4d102616a3e09

- Update vendored sources to duckdb/duckdb@c87f41d540beaf80ba9e9f650ef62b3effce77d6.

  Date: 2026-10-05 11:28:29 +0000

  Remove redundant CMake CMP00xx policy settings (https://redirect.github.com/duckdb/duckdb/pull/25238)

  Unflavored-from: fe2ec592c77d88795261d9a6fe47bc6bea3dd471

- Update vendored sources to duckdb/duckdb@d180863ea62a86fff0c6fb5aa80e61a42028161b.

  Date: 2026-10-05 11:27:19 +0000

  Parser: index reserved keywords (https://redirect.github.com/duckdb/duckdb/pull/26354)
  Unflavored-from: df18441bdfc86165902b406fdb1cf08cd2e7e6c6

- Update vendored sources to duckdb/duckdb@4af9740da47e908b29efc52570de8ca2115ab6cb.

  Date: 2026-10-05 11:12:13 +0000

  fix non-flat state vector handling in c-api aggregate code (https://redirect.github.com/duckdb/duckdb/pull/26455)

  Unflavored-from: 39fba7e9946dc67ca916ddcc9342bac9cfc8666d

- Update vendored sources to duckdb/duckdb@9285103bfd44ec68b491289510d91b8e7e7a7884.

  Date: 2026-10-05 10:54:46 +0000

  Fix duplicate table filter cardinality estimation (https://redirect.github.com/duckdb/duckdb/pull/25193)

  Unflavored-from: 8c315e23b3fee72e781246e82a7f0a91c1b81e11

- Update vendored sources to duckdb/duckdb@c50e2e9d45dd7c930de732d9184c211d361c15ab.

  Date: 2026-10-05 10:33:22 +0000

  fix type propagation when extension operator is missing types (https://redirect.github.com/duckdb/duckdb/pull/26457)

  Unflavored-from: 0a9be260fe83232618ad11f7cc68979c6e33dc6c

- Update vendored sources to duckdb/duckdb@584e140a2bf8f71aaeadffb929770554f640d766.

  Date: 2026-10-05 09:10:41 +0000

  \[ReadAhead\] Allow calling `SupportsReadAhead` without bind data (https://redirect.github.com/duckdb/duckdb/pull/26412)

  Unflavored-from: 04def1cdb145d4d27497cae7e26615ab2318b044

- Update vendored sources to duckdb/duckdb@db0ecec124f697710036513a29e9f93a0f8577d0.

  Date: 2026-10-05 09:00:29 +0000

  Shell: DUCKDB_AGENT_MODE=1/0 forces agent mode on or off (https://redirect.github.com/duckdb/duckdb/pull/26416)
  Unflavored-from: 60184711d0589654a18561adcf4e63f0663bcd27

- Update vendored sources to duckdb/duckdb@27eb3aab49de5ba0e83046db2dfedd02f4fb6d3c.

  Date: 2026-10-05 09:00:00 +0000

  Tpch dbgen speedups (https://redirect.github.com/duckdb/duckdb/pull/26429)

  Unflavored-from: e2c09ee6191085553e8725da975713d948b9867e

- Update vendored sources to duckdb/duckdb@7acff72e504aadaedb96f0e7eee4ec9d79c6088a.

  Date: 2026-10-05 08:35:04 +0000

  Support ifnull() via function chaining syntax (https://redirect.github.com/duckdb/duckdb/pull/11907) (https://redirect.github.com/duckdb/duckdb/pull/25137)

  Unflavored-from: e606388b58f0872b44b6ce9de4a67bf7e816409b

- Update vendored sources to duckdb/duckdb@12808d0acaaf63b66af15031a23c385a06ad9e3d.

  Date: 2026-10-05 08:26:45 +0000

  Backport: Fix captured column selection in list_reduce (https://redirect.github.com/duckdb/duckdb/pull/26450)
  Unflavored-from: 84150d474b89d0896b8fb857788550e31083b278

- Update vendored sources to duckdb/duckdb@99637c4b7ee52648a346159f55a800c3977dc734.

  Date: 2026-10-05 08:08:46 +0000

  Switch to remote workflows for trackers (https://redirect.github.com/duckdb/duckdb/pull/26453)

  Unflavored-from: 089dfcfb187b0fb2c2b207261d6e33a3975ab695

- Update vendored sources to duckdb/duckdb@eb0d9df48ee5341ea4ede1a3cba93251cce571df.

  Date: 2026-10-05 08:05:44 +0000

  Fix internal error for MERGE NOT MATCHED BY SOURCE UPDATE RETURNING (https://redirect.github.com/duckdb/duckdb/pull/24536)

  Unflavored-from: 6ffbe75c257c04098d8faba2320caee5575c5146

- Update vendored sources to duckdb/duckdb@1f4c63fac227c35259c611768326de4859926543.

  Date: 2026-10-05 07:53:03 +0000

  Count transaction-local rows when sizing a table scan (https://redirect.github.com/duckdb/duckdb/pull/26383)

  Unflavored-from: 3d5c267ba7f313ffb3d37620e9f9e3357e8a738b

- Update vendored sources to duckdb/duckdb@8d5382912945103f1cabc111f8c04edb13ee4ecb.

  Date: 2026-10-05 06:00:29 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10971: Small Binary Holistics (https://redirect.github.com/duckdb/duckdb/pull/26426)

  Unflavored-from: 3b7681c9d68e8561fb3f75219614c929c273f4b7

- Update vendored sources to duckdb/duckdb@80e17fc252edd6d9e9b090ae00a1100daef4876a.

  Date: 2026-10-04 13:59:56 +0000

  Change `LogicalType` to be an intrusive shared pointer (and update V2-C-API) (https://redirect.github.com/duckdb/duckdb/pull/26355)

  Unflavored-from: 612c87c23f5cd3beb6c6b84283aaae1439a80274

- Update vendored sources to duckdb/duckdb@91c26febd3fc1096cbe81868aa8c6e3e66aa3400.

  Date: 2026-10-04 13:28:34 +0000

  Parser: DESTROY, REGISTER and RESOURCES are (unreserved) keywords (https://redirect.github.com/duckdb/duckdb/pull/26414)
  Unflavored-from: 8333625e32d17972883ab81bcc1d5466d9830234

- Update vendored sources to duckdb/duckdb@35a0672703d894dc2703d56b6acdcc637ab0ee17.

  Date: 2026-10-04 13:20:15 +0000

  Fix crash on empty ENUM columns (https://redirect.github.com/duckdb/duckdb/pull/26405)

  Unflavored-from: 31b06a0b1dab9e0a5b854fdd267fa9b52c326c7a

- Update vendored sources to duckdb/duckdb@b387863fdce8c84e38de95d61ca24bcab9fd6348.

  Date: 2026-10-04 13:19:14 +0000

  fix(parser): Preserve CTE metadata when copying (https://redirect.github.com/duckdb/duckdb/pull/26422)

  Unflavored-from: fdd13e11b75219961245df2dc699f8ad2226dcf7

- Update vendored sources to duckdb/duckdb@d0dc9793b50eaadf4a2c980035bf28d7768bf787.

  Date: 2026-10-04 13:18:49 +0000

  Fix statistics propagation root lifetime after operator replacement (https://redirect.github.com/duckdb/duckdb/pull/26421)

  Unflavored-from: c5e18e3b7aa011c1bc218a55cbc6dbde2e758a11

- Update vendored sources to duckdb/duckdb@fc9d6e93409a2dc412b658cade45b963371cd033.

  Date: 2026-10-02 16:32:05 +0000

  Export the state of approx_count_distinct (https://redirect.github.com/duckdb/duckdb/pull/26331)

  Unflavored-from: d4bd57ac99a499612666d435dd167c5d2d080da7

- Update vendored sources to duckdb/duckdb@d682a951712e14cd04b10282b098358e23b6c803.

  Date: 2026-10-02 16:31:41 +0000

  Use Hash instead of MurmurHash in shell renderer (https://redirect.github.com/duckdb/duckdb/pull/26400)

  Unflavored-from: 6d298f04ffebd7e47d9e414390c49794f5122366

- Update vendored sources to duckdb/duckdb@fc737273d935697f4356bd840cebe85d417448a6.

  Date: 2026-10-02 16:31:17 +0000

  Add more tests to the hash zero skip list (https://redirect.github.com/duckdb/duckdb/pull/26399)

  Unflavored-from: 330aa8dfd94e95a0fe324fc8460a815c4275a886

- Update vendored sources to duckdb/duckdb@00b3e22708565db10d503149eba175e0b73f87f3.

  Date: 2026-10-02 16:30:48 +0000

  Add nan_count to Parquet RETURN_STATS and fix has_nan across row groups (https://redirect.github.com/duckdb/duckdb/pull/26307)

  Unflavored-from: d3539d304bde938cded6f3f45a207d3cda060a65

- Update vendored sources to duckdb/duckdb@cca2abb384d4794a3dc134c5f25e7623b7f6ef87.

  Date: 2026-10-02 16:30:25 +0000

  Fix monotonicity metadata for interval date parts (https://redirect.github.com/duckdb/duckdb/pull/26398)

  Unflavored-from: be313856ec1db6be2d6301aebe6f547cefa87339

- Update vendored sources to duckdb/duckdb@1f101d0d426af95ac64d2989baaf601e4213273d.

  Date: 2026-10-02 16:27:36 +0000

  Reject NULL arguments in add_parquet_key (https://redirect.github.com/duckdb/duckdb/pull/26396)

  Unflavored-from: b5d647d8cebbd679b399dbf1b6742179182b6f42

- Update vendored sources to duckdb/duckdb@e51840d54e2c877d83b6b94bf6111504eca3f341.

  Date: 2026-10-02 16:23:05 +0000

  Fix crash in EXPLAIN MERGE INTO ... RETURNING with optimizer disabled (https://redirect.github.com/duckdb/duckdb/pull/26312)

  Unflavored-from: ad65c426f1cb6c14f10306296e35585211cc8b9d

- Update vendored sources to duckdb/duckdb@44dc1e0ddf72a5499d4fbeceb29198bea331041a.

  Date: 2026-10-02 16:13:23 +0000

  Fix invalid compression type to disable (https://redirect.github.com/duckdb/duckdb/pull/26055)

  Unflavored-from: d55bf9ead952eccd4de963b0284dbffc062bc3c5

- Update vendored sources to duckdb/duckdb@ee60ebede004bacf1e1b307bc4a12ce2111296d3.

  Date: 2026-10-02 13:57:20 +0000

  Increase test coverage for extension/ (https://redirect.github.com/duckdb/duckdb/pull/26320)

  Unflavored-from: 9002c0a9a6dc370f66d14c48b8579bf804a03c95

- Update vendored sources to duckdb/duckdb@fd486f1656e481addf8df6e1ad78b822b2ce0fe5.

  Date: 2026-10-02 13:57:12 +0000

  Fix BIGNUM cast dropping bits on large integers (https://redirect.github.com/duckdb/duckdb/pull/25939) (https://redirect.github.com/duckdb/duckdb/pull/25944)

  Unflavored-from: 7ce32de6a5d637e7acf39246ec3f38dca4e7bce2

- Update vendored sources to duckdb/duckdb@a35967a254830f2cf4a6739b413169a8920c6eb3.

  Date: 2026-10-02 12:59:42 +0000

  Fix https://redirect.github.com/duckdb/duckdb/pull/26156: push struct field extracts into union_by_name scan statis… (https://redirect.github.com/duckdb/duckdb/pull/26348)

  Unflavored-from: e5742f7fbb57bda6cf42964fc5649aab6467980d

- Update vendored sources to duckdb/duckdb@7cf04ef32b7de57d339c8ab41def2ec5b33bfffb.

  Date: 2026-10-02 12:58:30 +0000

  Reject NULL for timezone and calendar (https://redirect.github.com/duckdb/duckdb/pull/26393)

  Unflavored-from: efa35bab5bf3b03a76d5446dcfb9f50af1b0a014

- Update vendored sources to duckdb/duckdb@3363c469d1784f2a1d32941f2216cd9a6149ad64.

  Date: 2026-10-02 12:58:17 +0000

  Fix INT64_MIN offset overflow in streaming LEAD/LAG (https://redirect.github.com/duckdb/duckdb/pull/26392)

  Unflavored-from: 8ed5b789adb95bf4bd853b1961626958f25b4d46

- Update vendored sources to duckdb/duckdb@67dc38ce474d6c2b4c418dbfecb9679e0eda25bf.

  Date: 2026-10-02 12:46:24 +0000

  Use CompressionSegmentReader for FSST (legacy) (https://redirect.github.com/duckdb/duckdb/pull/26290)

  Unflavored-from: 10405060500d5033f00d9e70ac3ca351008238a5

- Update vendored sources to duckdb/duckdb@3b668557d313838a4602f51b88bb6f1df667d487.

  Date: 2026-10-02 12:46:08 +0000

  Fix heap use-after-free on failed recursive CTE pipeline build (https://redirect.github.com/duckdb/duckdb/pull/26295)

  Unflavored-from: 2db61a88cc905ecd52a8a04bb41614228fdee903

- Update vendored sources to duckdb/duckdb@da7674c5086f3931d60b6395633b3018713e9f11.

  Date: 2026-10-02 12:45:53 +0000

  LegacyDyanmicFilter: :ToExpression returns dynamic expression (https://redirect.github.com/duckdb/duckdb/pull/26293)
  Unflavored-from: 4b09fcfe0967f176b3d68a9857eb12ed034f2255

- Update vendored sources to duckdb/duckdb@a524e64c2fb4f2cae89e4c74ad75e82e6c302062.

  Date: 2026-10-02 12:45:16 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/11098: 2026e Time Zones (https://redirect.github.com/duckdb/duckdb/pull/26297)

  Unflavored-from: 476dd86bf68990eac6ee303892d47e8b9af09130

- Update vendored sources to duckdb/duckdb@8686f429d7ec6a434c62bde9306127fee030af37.

  Date: 2026-10-02 12:42:20 +0000

  Guard against LIMIT + OFFSET overflow in correlated subqueries (https://redirect.github.com/duckdb/duckdb/pull/26386)

  Unflavored-from: f9e7b326a73fa609114982f2451b863f37a32c6f

- Update vendored sources to duckdb/duckdb@f18edc1b6279a0eeeec47d3164ecd9993fb39969.

  Date: 2026-10-02 12:41:25 +0000

  reject nan quantile parameter (https://redirect.github.com/duckdb/duckdb/pull/26389)

  Unflavored-from: 2855a7dca562c5f1caef3217fc91b1a4043e6eb0

- Update vendored sources to duckdb/duckdb@83e79cec057d36da06f0ee686b072fefb998974d.

  Date: 2026-10-02 12:41:11 +0000

  \[Dev\] Fix gaps in support to transition to the new extension build system (https://redirect.github.com/duckdb/duckdb/pull/26390)

  Unflavored-from: 03d8e3ca11813ff8c901dbe140855dcfdf5bd782

- Update vendored sources to duckdb/duckdb@20b5e848c64c5c096994cdd33f1d661eb5e41b6b.

  Date: 2026-10-02 12:40:43 +0000

  WIP: Support creating multi-file reader functions from the v2 C API and the C++ API (https://redirect.github.com/duckdb/duckdb/pull/26254)
  Unflavored-from: 3e50efa823ca3d5d208ff3a00f741d3b6d46c06e

- Update vendored sources to duckdb/duckdb@9133a94855dcfd788cf02a22130a868694197128.

  Date: 2026-10-02 12:29:54 +0000

  Fix uncommitted data recovered accidentally (https://redirect.github.com/duckdb/duckdb/pull/25931)

  Unflavored-from: e652f23c5a1d33a0c3e5b4b03167a8a3c2b53f2d

- Update vendored sources to duckdb/duckdb@66df740833a31d749be02f47dbae82d179b59bfd.

  Date: 2026-10-02 12:28:13 +0000

  Expose reusable core helpers for DuckLake (https://redirect.github.com/duckdb/duckdb/pull/26322)

  Unflavored-from: 6897c497e7ad0536000b1094b9ec32856fd1be68

- Update vendored sources to duckdb/duckdb@1b932368795a73bf06d2d3966b15f86b211e9a7a.

  Date: 2026-10-02 12:26:57 +0000

  Fix home directory expansion in file access checks (https://redirect.github.com/duckdb/duckdb/pull/26082)

  Unflavored-from: a4acd7ef9642e407251cad0cd0b3018d9ad08226

- Update vendored sources to duckdb/duckdb@31d224cacf7790f24b287493aa287941239089d9.

  Date: 2026-10-02 12:26:41 +0000

  Fix inline constraint indexes after table constraints (https://redirect.github.com/duckdb/duckdb/pull/26178)

  Unflavored-from: aa2ccd970183d109890dade7dea6f9fc70209dd0

- Update vendored sources to duckdb/duckdb@77088b9bfdb27ab058e940eae4960f9a5226ee85.

  Date: 2026-10-02 12:26:05 +0000

  Validate enum size and element count during deserialization (https://redirect.github.com/duckdb/duckdb/pull/26187)

  Unflavored-from: 8289619876287e5a92f27f1265d8694805e67bb6

- Update vendored sources to duckdb/duckdb@2f453f294b0c6f3c55d0d009e6aad9ae8e6780ff.

  Date: 2026-10-02 11:50:07 +0000

  Fix clang tidy isses on 2.0 branch (https://redirect.github.com/duckdb/duckdb/pull/26378)

  Unflavored-from: 225c17c019738517120b736db03a46e583cce7ad

- Update vendored sources to duckdb/duckdb@84c5ea636c592b256f2995d4295eb0c39849de52.

  Date: 2026-10-02 11:49:44 +0000

  Fix in mapping of legacy table filters (https://redirect.github.com/duckdb/duckdb/pull/26385)

  Unflavored-from: 1115b3f14ef2e9c202fd48a9c0a558938bd0eb8c

- Update vendored sources to duckdb/duckdb@f903f27b11cd16b9c47ecd27c6a4e70e0a5158f3.

  Date: 2026-10-02 11:48:35 +0000

  Count deleted transaction-local rows atomically (https://redirect.github.com/duckdb/duckdb/pull/26382)

  Unflavored-from: 5fe696450cf3e4a994921dd1c03b3cfc37eb5d7f

- Update vendored sources to duckdb/duckdb@0cacb1e3573bd473d9d487e66741fd30eddfa012.

  Date: 2026-10-02 11:31:47 +0000

  Add tests for src/common, function and execution code (https://redirect.github.com/duckdb/duckdb/pull/26346)

  Unflavored-from: 50378695a3b39f14a139f7eacb0cd02d6608167c

- Update vendored sources to duckdb/duckdb@870503f14481980a9a30121ab8db98ac72f36c6d.

  Date: 2026-10-02 11:31:26 +0000

  Parser alter column collate (https://redirect.github.com/duckdb/duckdb/pull/26345)

  Unflavored-from: f78e752d4d067e6aa3942c0e4c0ef4a285c70a69

- Update vendored sources to duckdb/duckdb@2debc343745f22b4a8dfd96b8cc907b6935302c9.

  Date: 2026-10-02 11:30:55 +0000

  Add back fetch-by-rowid fallback for DELETEs (https://redirect.github.com/duckdb/duckdb/pull/26342)

  Unflavored-from: f25fc0562ec49c2780c23f9805a20bf9b0ca4a64

- Update vendored sources to duckdb/duckdb@ce9558ad80efcdc011f3749cffa211228bd8d859.

  Date: 2026-10-02 10:44:26 +0000

  add duckdb-aws-glue to core builds/pipelines (https://redirect.github.com/duckdb/duckdb/pull/26338)

  Unflavored-from: 1b9a498a6757b12e33aa12e6e3f4a711aaf64edf

- Update vendored sources to duckdb/duckdb@22f18a77e80fe47712cc566368eadad66a8f6554.

  Date: 2026-10-02 10:44:12 +0000

  Compress type last item be ENUM_SIZE (https://redirect.github.com/duckdb/duckdb/pull/26337)

  Unflavored-from: 15bf8d8c242610c8f82ab48b07fc89d31f85aadb

- Update vendored sources to duckdb/duckdb@7264a9f0e5b487358100f408826b8ae9e868b031.

  Date: 2026-10-02 10:41:43 +0000

  Fix various grammar issues (https://redirect.github.com/duckdb/duckdb/pull/26326)

  Unflavored-from: 82520176079dd0cf91464c23aad8a9f1934bd44e

- Update vendored sources to duckdb/duckdb@ceab6fbb492d91c7721ddfa0824e0300f3b1718c.

  Date: 2026-10-02 10:39:31 +0000

  Improve console detection on Windows (https://redirect.github.com/duckdb/duckdb/pull/26344)

  Unflavored-from: 9ad87982a601e371c58847869a939d2b4685330f

- Update vendored sources to duckdb/duckdb@d5dde05dfd4e7696789ec7826c4b20744fbde8a4.

  Date: 2026-10-02 10:38:32 +0000

  \[AUTOMATED_BUMP\] Bump: avro (https://redirect.github.com/duckdb/duckdb/pull/26294)

  Unflavored-from: c098facb7df2e8332890d1562fbffc6e56c0ed91

- Update vendored sources to duckdb/duckdb@3b71ca1fc73190840b2c513932cc48561ee7984c.

  Date: 2026-10-02 08:59:36 +0000

  Prioritize merge queue and OnPR jobs (https://redirect.github.com/duckdb/duckdb/pull/26329)

  Unflavored-from: 747c6cbc982c18223486f75d3d18fd28be47247c

- Update vendored sources to duckdb/duckdb@d10d016564445aec71c21a7fafd9037b056b599e.

  Date: 2026-10-02 08:59:18 +0000

  Track release line latest alpha version (branch v2.0) (https://redirect.github.com/duckdb/duckdb/pull/26351)

  Unflavored-from: 8c481e5be82cfc20e6590a05e5a26b332a8d8259

- Update vendored sources to duckdb/duckdb@b9c0a815fd71b971f962aa4fab21101b762619a8.

  Date: 2026-10-02 08:58:36 +0000

  Fixup LTO linking for httplib and loadable_extensions (https://redirect.github.com/duckdb/duckdb/pull/26316)

  Unflavored-from: a487a78ff10a8666c59c12277b6b3eceb608dcb5

- Update vendored sources to duckdb/duckdb@2866f801f73d3da323991c2b833e3449b93ac7a1.

  Date: 2026-10-01 18:52:46 +0000

  Drop all blocks of an external file that changed (https://redirect.github.com/duckdb/duckdb/pull/26267)

  Unflavored-from: 6e8ce3d9a892d173ff9cd726d500e1ef341744f3

- Update vendored sources to duckdb/duckdb@489a45586acd1e9bba7c82099eecabc8acba28fe.

  Date: 2026-10-01 15:05:03 +0000

  Push join-derived key restrictions into correlation CTEs (https://redirect.github.com/duckdb/duckdb/pull/26158)

  Unflavored-from: 8dae6a1e26a1dbc6963ad39b69f1cc6686564e3d

- Update vendored sources to duckdb/duckdb@1b909e3d1c4ee44771809935067d5194de351f0b.

  Date: 2026-10-01 15:01:46 +0000

  Resolve nested schema references in views against the view's catalog (https://redirect.github.com/duckdb/duckdb/pull/26253)

  Unflavored-from: 8dbb7b26f22a71ff15862871d6f312d9e1f39ae0

- Update vendored sources to duckdb/duckdb@ff9e8d05729bc2502df9ddec679ec5ce095de4f0.

  Date: 2026-10-01 14:44:11 +0000

  approx_quantile: never let the digest allocate at finalize time (https://redirect.github.com/duckdb/duckdb/pull/26333)

  Unflavored-from: 0a01897adf6db6f011ee833c6b9e105a2ab67c15

- Update vendored sources to duckdb/duckdb@754cb6c8bdaf8f18e4a12a706accbd4cee0169e8.

  Date: 2026-10-01 14:35:11 +0000

  Parser: Foreign key references actions are now order agnostic (https://redirect.github.com/duckdb/duckdb/pull/26330)
  Unflavored-from: 16acac3f4a6e59a6afa7d51fa33eb5d4eb242be1

- Update vendored sources to duckdb/duckdb@35e46672d1abdc7fb22dbc3354375f07bd54491e.

  Date: 2026-10-01 14:26:02 +0000

  Update Postgres, MySQL and SQLite (https://redirect.github.com/duckdb/duckdb/pull/26324)

  Unflavored-from: 54f0339859fc166855b6259adb113d7cc749c7d1

- Update vendored sources to duckdb/duckdb@17c7ca513f6dda00f1617b648de571e89828f142.

  Date: 2026-10-01 11:54:53 +0000

  Shell: agent mode - render for AI coding agents when one is detected (https://redirect.github.com/duckdb/duckdb/pull/26167)
  Unflavored-from: 8dd4cb742a9cb48989dbb22441b5b63821439cf6

- Update vendored sources to duckdb/duckdb@56877f95633888f0c3373b76b5d49a8d487f3834.

  Date: 2026-10-01 11:53:25 +0000

  Lower parser benchmark sample duration to ~300ms (https://redirect.github.com/duckdb/duckdb/pull/26325)

  Unflavored-from: 2954eb0e9032dcd170ab41bb06eea687c609770f

- Update vendored sources to duckdb/duckdb@51b99e487546b246b869c9b3b023d7cd46d94f15.

  Date: 2026-10-01 11:50:58 +0000

  Add `ASYMMETRIC` syntax back (https://redirect.github.com/duckdb/duckdb/pull/26226)

  Unflavored-from: 9ac8866337e48829c42171c3aa25eac671da694f

- Update vendored sources to duckdb/duckdb@0f9fd40715aa24ff1ea245e8e42c0955f9018c0a.

  Date: 2026-10-01 11:50:37 +0000

  `SOME` can be used as substitute for `ANY` (https://redirect.github.com/duckdb/duckdb/pull/26128)

  Unflavored-from: 9e521b661d594d7de82dd961bdcab1c3008faa0b

- Update vendored sources to duckdb/duckdb@a60977c6f836be51de4ae64ddcfd73e6415ec038.

  Date: 2026-10-01 11:18:46 +0000

  Add casts from TIMESTAMPTZ_NS to TIMESTAMP_MS, TIMESTAMP_S and DATE (https://redirect.github.com/duckdb/duckdb/pull/26284)

  Unflavored-from: 0b3eb72380e7cdc684496a0e400711c129cfd3de

- Update vendored sources to duckdb/duckdb@fb6723bfc1b0dc156a1e502f84e6355372a70c0c.

  Date: 2026-10-01 10:42:24 +0000

  cardinality() accepts lists and arrays (https://redirect.github.com/duckdb/duckdb/pull/26282)

  Unflavored-from: 9c3ecdad55c7a53515afedb37407030a2a77754b

- Update vendored sources to duckdb/duckdb@3c695531278046f0e6bde34eaf03526200f025d0.

  Date: 2026-10-01 10:39:30 +0000

  Fix stale join projection map during projection placement (https://redirect.github.com/duckdb/duckdb/pull/26252)

  Unflavored-from: 84d73a33d86e155d74e8459cbc1b7b04821a3c85

- Update vendored sources to duckdb/duckdb@47d289984c2f0d29c969a7be341ace13c0ab920f.

  Date: 2026-10-01 10:39:08 +0000

  approx_quantile: let the t-digest buffers grow on demand (https://redirect.github.com/duckdb/duckdb/pull/26281)

  Unflavored-from: 98749db19952c2732e5cdbabcb9b6f741c483163

- Update vendored sources to duckdb/duckdb@02d756412295001911ba84054968d5ce25c655aa.

  Date: 2026-10-01 08:08:42 +0000

  Inlined grammar per line (https://redirect.github.com/duckdb/duckdb/pull/26303)

  Unflavored-from: 2dbbfe0f80104868556b2336843e98e41099b6a9

- Update vendored sources to duckdb/duckdb@3af3323817bcff278ee593e0f1b81a0319a58ad5.

  Date: 2026-10-01 07:41:52 +0000

  Reconstruct supported grouped MARK joins in EXPLAIN (SQL) (https://redirect.github.com/duckdb/duckdb/pull/26236)

  Unflavored-from: 437f8a0ee4418c63fe0702ed524325d854e501a6

- Update vendored sources to duckdb/duckdb@0937e2d872a7cc5e837d580b2460fc458104a5bc.

  Date: 2026-10-01 07:31:30 +0000

  only copy strings into the update heap for effective updates (https://redirect.github.com/duckdb/duckdb/pull/26291)

  Unflavored-from: a0936a0f6038e2525b866e6f860a54e1bfcddeb0

- Update vendored sources to duckdb/duckdb@097ee1d34acbbfe1d1c2a0fbc32be787c02c7a8a.

  Date: 2026-09-30 17:32:53 +0000

  Use CompressionSegmentReader for Dictionary (https://redirect.github.com/duckdb/duckdb/pull/26228)

  Unflavored-from: ca3abca1a6e386707f52ad7718c7ac94558cdcf5

- Update vendored sources to duckdb/duckdb@ba2fad6fd8f080ae3062835dbe621573724bdcc5.

  Date: 2026-09-30 16:22:50 +0000

  Flush the allocator when freed memory could push RSS past the limit (https://redirect.github.com/duckdb/duckdb/pull/26246)

  Unflavored-from: 0156c4fb3f9e38de79c34a48595cb1083efc32cf

- Update vendored sources to duckdb/duckdb@628d7c6db7c9dd373dc0c8ad6e355441611848ac.

  Date: 2026-09-30 16:20:41 +0000

  Implicit casts from TIMESTAMP_S and TIMESTAMP_MS to timestamps with time zone (https://redirect.github.com/duckdb/duckdb/pull/26285)

  Unflavored-from: 3a5c301cf3247fce7d07a7e8e4bf12785645748f

- Update vendored sources to duckdb/duckdb@91c9ce54dd8dff858ef123f63aee69e323e37641.

  Date: 2026-09-30 15:28:29 +0000

  Allow ORDER BY expressions over the result of a set operation (https://redirect.github.com/duckdb/duckdb/pull/26286)

  Unflavored-from: b9151e50864ab44dfb77f62225012195de67c18e

- Update vendored sources to duckdb/duckdb@3bcb3d955262d17f5a541de0671ed3a6e01b6699.

  Date: 2026-09-30 14:35:28 +0000

  Chained `IS` expressions (https://redirect.github.com/duckdb/duckdb/pull/26232)

  Unflavored-from: 33de3d6aa79f1200365f7951b5ed950e30853eb6

- Update vendored sources to duckdb/duckdb@7fb68627fd223b7cd06d37b83059e571fa5f994a.

  Date: 2026-09-30 13:52:39 +0000

  Compose compatible SQL export scopes (https://redirect.github.com/duckdb/duckdb/pull/26251)

  Unflavored-from: b84d38a10566f122e851f8c97727a0b55925f677

- Update vendored sources to duckdb/duckdb@561522aea03e400bd20adc64fcc63e78b8721f3f.

  Date: 2026-09-30 12:10:51 +0000

  Move `read_parquet` to the multi-file table function wrapper (https://redirect.github.com/duckdb/duckdb/pull/25987)

  Unflavored-from: 837fa88c6308cc4588e6d96fec8dc62497ab8d80

- Update vendored sources to duckdb/duckdb@028c980193d8115cff19d86e2e73e716376bf03f.

  Date: 2026-09-30 11:31:18 +0000

  Require rebind for bind_operator plans whose scans cannot use the statement cache (https://redirect.github.com/duckdb/duckdb/pull/26278)

  Unflavored-from: b57e906def8f91c5079c94b84d6c10f65364d490

- Update vendored sources to duckdb/duckdb@ab3c3d12092f1d8b064a1a63eda87220861a8cec.

  Date: 2026-09-30 10:37:30 +0000

  To be investigated windows arm64 problem, discard failures for now (https://redirect.github.com/duckdb/duckdb/pull/26276)

  Unflavored-from: 0735bf7ddcc83ad7b6d3e4d34e342692efa979b6

- Update vendored sources to duckdb/duckdb@52821d5003f97584a46769c1eec0d32e0d9fc116.

  Date: 2026-09-30 10:36:11 +0000

  Client context split (https://redirect.github.com/duckdb/duckdb/pull/26258)

  Unflavored-from: 66d2588046a58dc3c016a11710712c0ad1910619

- Update vendored sources to duckdb/duckdb@8c781bbe895f06d12e1e65f24b88cc8addc93d93.

  Date: 2026-09-30 10:28:30 +0000

  \[AUTOMATED_BUMP\] Bump multiple extensions (https://redirect.github.com/duckdb/duckdb/pull/26277)

  Unflavored-from: a3494b638fede0078633ad4c39032f3d4b84560c

- Update vendored sources to duckdb/duckdb@a2af0a7bbae3e6fb17c99a1102a41df7b338d66e.

  Date: 2026-09-30 08:59:45 +0000

  \[C-API-V2\] Unify function argument binding (https://redirect.github.com/duckdb/duckdb/pull/26264)

  Unflavored-from: e5578f1741e199eea996def659076271f6aa99bb

- Update vendored sources to duckdb/duckdb@842a431f58bba2047b76e67d4536562b9a6e8b04.

  Date: 2026-09-30 08:27:21 +0000

  More tests (https://redirect.github.com/duckdb/duckdb/pull/26244)

  Unflavored-from: 3da533f7da25685cb0cd6c9d1d7e5451d04b1676

- Update vendored sources to duckdb/duckdb@40058fd9eefba3735e183fb59783f6c9b7a41324.

  Date: 2026-09-30 08:01:08 +0000

  Fix chained `IN` predicate (https://redirect.github.com/duckdb/duckdb/pull/26255)

  Unflavored-from: 19a6d649b4ff199ccfffbf8d5f86822a0c4a16cd

- Update vendored sources to duckdb/duckdb@14c2f7ddc906c319d14b0149c86ce2615cf2987d.

  Date: 2026-09-30 08:00:36 +0000

  Don't `DONT_LINK`, make selection of statically loaded extensions explicit (https://redirect.github.com/duckdb/duckdb/pull/26189)

  Unflavored-from: e2d57f9cc184bf1d806d987aee39c13e9c52e822

- Update vendored sources to duckdb/duckdb@e091a79d435a2d9914c0131d8e51829b20045ba6.

  Date: 2026-09-30 07:55:23 +0000

  Drop ORDER BY keys that follow a unique prefix (https://redirect.github.com/duckdb/duckdb/pull/25878)

  Unflavored-from: c8a0e775b4c961dd510716350730839cce59f9c5

- Update vendored sources to duckdb/duckdb@96063b9e39749cc0f087bb11501d7edbee527957.

  Date: 2026-09-29 18:55:42 +0000

  Fix flaky test (https://redirect.github.com/duckdb/duckdb/pull/26265)

  Unflavored-from: bd029860d558d8d616e8bba74bdc28fc7dce9f2f

- Update vendored sources to duckdb/duckdb@f0b535509e281cb65d4c0c5fbb0b167486d17694.

  Date: 2026-09-29 16:12:05 +0000

  Bump aws extension (https://redirect.github.com/duckdb/duckdb/pull/26263)

  Unflavored-from: 8af096d1d7f20da40006ae36185e06d7a6933b95

- Update vendored sources to duckdb/duckdb@5f2aa376f2831d70873f840d44dd1b8c89888b8e.

  Date: 2026-09-29 15:57:08 +0000

  Fix cleanup of unfinalized COPY files (https://redirect.github.com/duckdb/duckdb/pull/26124)

  Unflavored-from: 4d951660174a31b4a0ccdce507ee7b8bdbdef282

- Update vendored sources to duckdb/duckdb@3593e0cee40d4b9cc833bf49a569f4e5135685c4.

  Date: 2026-09-29 15:05:49 +0000

  Fixup passing down attach_info.path for CONNECT (https://redirect.github.com/duckdb/duckdb/pull/26262)

  Unflavored-from: 62e4b14e1fc7729f36e8da1ed61fd8fcbbe8301d

- Update vendored sources to duckdb/duckdb@8b3c3b7dbf40f491c52792c582cd0681de4bd359.

  Date: 2026-09-29 15:05:35 +0000

  Fix fast int64_t sum path overflow (https://redirect.github.com/duckdb/duckdb/pull/26011)

  Unflavored-from: 4855c575972691f3b58de627a738adc3e83afdbd

- Update vendored sources to duckdb/duckdb@052c74aa57b9048ddf28eb96f48b0d0a79550725.

  Date: 2026-09-29 14:31:14 +0000

  Fix storage leak after checkpoint failure (https://redirect.github.com/duckdb/duckdb/pull/26193)

  Unflavored-from: 68a7ca2cc8629d8d07d30d9853c8adadcd05b469

- Update vendored sources to duckdb/duckdb@edc7f73805077be21b60b9e456db668cf0adbe8f.

  Date: 2026-09-29 13:54:44 +0000

  Remove unused unscented Kalman filter (https://redirect.github.com/duckdb/duckdb/pull/26183)

  Unflavored-from: 97940390e64dbfecfb3b19a1dd680b189b50e75c

- Update vendored sources to duckdb/duckdb@6a60c658db33442a5593b38dc9df19500d7ee99b.

  Date: 2026-09-29 13:46:38 +0000

  Fix assertion in VARCHAR to MAP TRY_CAST with null keys or missing values (https://redirect.github.com/duckdb/duckdb/pull/26223)

  Unflavored-from: 4378f4d9150d40e825b36158908ee787a02c358f

- Update vendored sources to duckdb/duckdb@4c41601366f3d672b7723e69cf6bf0645468000b.

  Date: 2026-09-29 13:44:02 +0000

  Fix out-of-bound access for strptime (https://redirect.github.com/duckdb/duckdb/pull/26222)

  Unflavored-from: d234cdb58d2e9f3e066e22464066e095b13e69cc

- Update vendored sources to duckdb/duckdb@b9a089e88c3cd8413db79a47584ff7a3c027aa34.

  Date: 2026-09-29 13:43:34 +0000

  Fix CSV rejects table cache key collision (https://redirect.github.com/duckdb/duckdb/pull/26224)

  Unflavored-from: d9b374c99596c4aea626a78e7a3a90b5a66c6653

- Update vendored sources to duckdb/duckdb@8969aef7636729ae83f715730839b16af091794e.

  Date: 2026-09-29 13:34:32 +0000

  Keep update chains intact when an update or its cleanup throws (https://redirect.github.com/duckdb/duckdb/pull/26227)

  Unflavored-from: 3cf88a29df22d2c7a80fe172d011766c0b0927a9

- Update vendored sources to duckdb/duckdb@cb63b6d32bdff362b01e04f003b41d9e22c560ea.

  Date: 2026-09-29 13:32:21 +0000

  Add options to `CREATE SCHEMA` and support for `ALTER SCHEMA` statements (https://redirect.github.com/duckdb/duckdb/pull/26078)

  Unflavored-from: 3302cbae75734651d39ffb5f0f3a1684ed633c04

- Update vendored sources to duckdb/duckdb@c5cfd0b2f54cfa63889705dbcdc76b77f26c0357.

  Date: 2026-09-29 13:22:06 +0000

  Fix off by one power of ten overflow in IntegerDecimalCastOperation (https://redirect.github.com/duckdb/duckdb/pull/26237)

  Unflavored-from: e2d66566f479eb0ab6016d658b5ac28ef41a7882

- Update vendored sources to duckdb/duckdb@89b1c146308bd9e55b35469d9270e78234a63f16.

  Date: 2026-09-29 12:40:26 +0000

  Fix use-after-free when statistics propagation removes a root LIMIT (https://redirect.github.com/duckdb/duckdb/pull/26245)

  Unflavored-from: 5a71262845433b9454a2d22aa753608a5a74db50

- Update vendored sources to duckdb/duckdb@565d6b9bddf114b6e01da0f6322e93cce1bb9dca.

  Date: 2026-09-29 11:54:18 +0000

  Cache the byte ranges that are read instead of aligned 2 MiB blocks (https://redirect.github.com/duckdb/duckdb/pull/26096)

  Unflavored-from: 10b3727b86a1f19e0efb6f4d97d0a4d0ef7d120e

- Update vendored sources to duckdb/duckdb@39cd4c56947ae78bbfdc28cf6c63008a9c3860a6.

  Date: 2026-09-29 11:53:37 +0000

  Fix date timestamp infinity comparison (https://redirect.github.com/duckdb/duckdb/pull/26225)

  Unflavored-from: 20f6bbfddd550da12233971cc267951b89fbd3ca

- Update vendored sources to duckdb/duckdb@a6e1966f29181632d8c9090c36280d18e2369cef.

  Date: 2026-09-29 11:52:13 +0000

  Fix parsing of single `FOLLOWING` window frame bounds (https://redirect.github.com/duckdb/duckdb/pull/26235)

  Unflavored-from: 8f75c1eb45cad24cc4f74d4881d41c63c6725f3f

- Update vendored sources to duckdb/duckdb@dc03688ccce76c7f343379b1c74105d610ed09ba.

  Date: 2026-09-29 11:31:14 +0000

  Connect passthrough (https://redirect.github.com/duckdb/duckdb/pull/25990)

  Unflavored-from: 68e6fa5d48ae4619b6982a8abc394a270c91a03e

- Update vendored sources to duckdb/duckdb@9a858c32529d2a478a41da3a968eaf72b5d81da3.

  Date: 2026-09-29 09:43:37 +0000

  Enable jemalloc for linux arm64 (https://redirect.github.com/duckdb/duckdb/pull/26249)

  Unflavored-from: 2daa532c337c44053feaf68e8118c15c55cf72ff

- Update vendored sources to duckdb/duckdb@f00a187d3c33ff0b0a98a37d4287c6237258dd8d.

  Date: 2026-09-29 09:34:59 +0000

  Keep the schema dependency when altering a catalog entry (https://redirect.github.com/duckdb/duckdb/pull/25906)

  Unflavored-from: a07be27d5590dab66e5a03b6a8766b2996e3cdb6

- Update vendored sources to duckdb/duckdb@d591bb1da2de3cb12329c75aff2c31bebe922b59.

  Date: 2026-09-28 15:46:56 +0000

  \[C-API-V2\] Don't pass structs by value, and add table-function order-preservation flag (https://redirect.github.com/duckdb/duckdb/pull/26230)

  Unflavored-from: 1afb4a554e394f569e0b8a04cf6fe3922cc9c99e

- Update vendored sources to duckdb/duckdb@3cbf892064f86eeab03195be9d37c31372c68d61.

  Date: 2026-09-28 13:45:46 +0000

  Collapse single-operand precedence levels in the parser (https://redirect.github.com/duckdb/duckdb/pull/26090)

  Unflavored-from: 9473580280a71a2175d6ab7b6ea5a6cda73e6f05

- Update vendored sources to duckdb/duckdb@e305d725d69ca9702fed1fd17f0c85561260fd8c.

  Date: 2026-09-28 13:45:17 +0000

  Skip tests that crash on windows arm64 in CI (https://redirect.github.com/duckdb/duckdb/pull/26229)

  Unflavored-from: 2a9f504c199522a5eda462df5d2ed5c3b14f8984

- Update vendored sources to duckdb/duckdb@eec99a127e1dc809bfbe55ffc8475c827629cf98.

  Date: 2026-09-28 12:10:13 +0000

  Use `FunctionSignature` in table/pragma functions (https://redirect.github.com/duckdb/duckdb/pull/26091)

  R-side fix

  `TableFunction` now carries a `FunctionSignature` instead of its own
  `vector<LogicalType> arguments` and `named_parameter_type_map_t named_arguments`,
  which moves both halves of `r_dataframe_scan`'s named parameters.
  Declaring them is `GetSignature().AddKeywordOnly(<name>, <type>, <default>)` now
  that the `named_parameters` member is gone, one call per parameter.
  The default is what makes a keyword-only parameter optional:
  declared without one, `r_dataframe_scan(POINTER)` matches no overload at all,
  which is every `rel_from_df()` and every ALTREP relation,
  320 of the 445 test failures this commit first reported.
  All three take `Value::BOOLEAN(false)`,
  the value the `get_*_param()` helpers already return for a parameter the caller omits.
  Reading them takes `named_argument_map_t`, the `InsertionOrderPreservingMap` that
  `TableFunctionBindInput::named_parameters` is now typed as,
  in place of `named_parameter_map_t`;
  it offers the same `find()`, `end()` and `->second`,
  so only the three helper signatures and the `DataFrameScanBindData` constructor's
  parameter type change.
  `Connection::TableFunction()` still takes `named_parameter_map_t`,
  so `relational.cpp` and `altrepdataframe_relation.cpp` are untouched,
  but `register.cpp` is not: the caller's side of the same unification broke.
  Named arguments now go through the ordinary overload resolution,
  where an `INTEGER_LITERAL` no longer reaches a `BOOLEAN` keyword-only parameter,
  and `Value`'s `bool` constructor is `explicit` while its `int32_t` one is not --
  so `parameter_map["integer64"] = true` had always built an `INTEGER_LITERAL`,
  and every `duckdb_register()` now fails to bind `r_dataframe_scan` at all.
  The three named parameters are built with `Value::BOOLEAN()`,
  which is what the engine's own callers pass and what the signature declares.

  Both halves were verified on this tree before the push:
  `testthat::test_local()` reports 5746 passing and nothing failing,
  where the same run without them reported the 320 unnamed-call errors
  and left `tests/testthat/_snaps/array.md` drifted onto the bind error,
  which is what failed the `clean` gate beside `check`.

  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01UcpS5XNuFCdf3Hcbw74uCV

  Carried from `origin/v2.0-cyanoptera-dev` at 41dae60415:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: e7757ad6d614e244ac7336289b6f3d21f9559f90

- Update vendored sources to duckdb/duckdb@c2ef9c4016ee0802204cad021f83b0f99357820e.

  Date: 2026-09-28 10:52:36 +0000

  Honor the record-batch validity bitmap in the v2 Arrow importer (https://redirect.github.com/duckdb/duckdb/pull/25790)

  Unflavored-from: c8e0c58fc8a1ebbd453311e4e886983373ebc938

- Update vendored sources to duckdb/duckdb@09eb7f7004cb682d877c4e50ac0f296f4a0fc8e4.

  Date: 2026-09-28 07:43:47 +0000

  Export optimized logical plans as executable SQL with EXPLAIN (SQL) (https://redirect.github.com/duckdb/duckdb/pull/26062)

  R-side fix

  The SQL exporter this commit vendors builds constant list and struct values
  from a fully qualified function name --
  `make_uniq<FunctionExpression>(QualifiedName("system", "main", "list_value"), ...)`
  where the call took the bare name before
  (`src/parser/expression/value_expression.cpp`) --
  so a `ParsedExpression` printed by the glue now names the catalog and schema too.
  `tests/testthat/_snaps/relational.md` takes the new rendering,
  `CAST("system".main.list_value() AS INTEGER[])`,
  as CI computed it on snapshot-3c8b5974695dbddd105ad26bec087c3cb5ce79d0-rcc-smoke-null.

  Carried from `origin/v2.0-cyanoptera-dev` at 9f1554a063:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: acd10dae12127b9c99afffc0b9503ee9e1cffcf4

- Update vendored sources to duckdb/duckdb@adb27ebebf9c42b4241351cda3d7e9eb3bc4d442.

  Date: 2026-09-28 07:13:32 +0000

  Reject trailing root geometries in WKB (https://redirect.github.com/duckdb/duckdb/pull/24559)

  Unflavored-from: 6d01449aa8d045515b3d733544a2026529a9dc1a

- Update vendored sources to duckdb/duckdb@a9eef271b5de65f068f53b0c33621200a0307084.

  Date: 2026-09-28 07:07:23 +0000

  Preserve recursive CTE join-order restrictions through projections (https://redirect.github.com/duckdb/duckdb/pull/26094)

  Unflavored-from: 58ec340305cb5955691326d0266003ded48452c2

- Update vendored sources to duckdb/duckdb@b3ebf405e7e6fae6da125b97a40d084022497b76.

  Date: 2026-09-28 07:01:46 +0000

  Tests for OOB vector issue in `map` function (https://redirect.github.com/duckdb/duckdb/pull/26145)

  Unflavored-from: d75b623edf96f9d1a63ad4ba3a53955af1794421

- Update vendored sources to duckdb/duckdb@3f9f0a17e6f8e2d3cfd8bba4a672f8c109d5d7d4.

  Date: 2026-09-27 18:22:01 +0000

  Fix ordering comparison of equal fixed-size arrays (https://redirect.github.com/duckdb/duckdb/pull/26208)

  R-side fix

- Update vendored sources to duckdb/duckdb@d8a1bd4f4fbccdf3d22d8f1fe27a94c11c805d0a.

  Date: 2026-09-25 18:48:24 +0000

  Add TIMESTAMPTZ to TIMESTAMPTZ_NS cast (https://redirect.github.com/duckdb/duckdb/pull/25346)

  R-side fix

- Update vendored sources to duckdb/duckdb@e5bc7c2c76f578b321ecf0f51b15e2751174896f.

  Date: 2026-09-25 17:23:37 +0000

  Add support for shredded vector serialization, and clean-up vector serialization by moving to vector buffers (https://redirect.github.com/duckdb/duckdb/pull/26169)

  Unflavored-from: c7b8d3dbbd471a86d9cfefd40c2a32f88da43c18

- Update vendored sources to duckdb/duckdb@c75cd0b28a2f8539c4ac964d2df84e9bfba2c348.

  Date: 2026-09-25 17:03:20 +0000

  Fix NO CYCLE sequences returning INT64_MIN after overflow (https://redirect.github.com/duckdb/duckdb/pull/26168)

  Unflavored-from: 302ed2ec97e2d0a033aaf8df811be0408b3a6a99

- Update vendored sources to duckdb/duckdb@ee5065f7199fb7378f43b0f881989ef132ccf1af.

  Date: 2026-09-25 15:56:32 +0000

  Move Chimp fetch to heap (https://redirect.github.com/duckdb/duckdb/pull/26165)

  Unflavored-from: d72c505e10f5f8f0ee470b97c45577f665bda18c

- Update vendored sources to duckdb/duckdb@380a19ed0bca0fa96044b167b4bd1609f2aa2326.

  Date: 2026-09-25 15:10:55 +0000

  Add HyperLogLog or exact-hash dependent tests to the hash zero skiplist (https://redirect.github.com/duckdb/duckdb/pull/26152)

  Unflavored-from: 2a2f919706a2181ed8453543e1b9bbc38124b2d5

- Update vendored sources to duckdb/duckdb@f686814f0eea93c5aeb1a37ee55c8160fa109e9c.

  Date: 2026-09-25 14:48:58 +0000

  Restore grouped MARK semantics when binding explicit joins (https://redirect.github.com/duckdb/duckdb/pull/26061)

  Unflavored-from: 236fe26b887224ff3eed2370a4f05bfe7e8aab27

- Update vendored sources to duckdb/duckdb@9b410b06b42620b55f6647f5e27e8c69646f8703.

  Date: 2026-09-25 14:11:58 +0000

  Increase test coverage for parquet, parser and C++ API (https://redirect.github.com/duckdb/duckdb/pull/26120)

  Unflavored-from: e9e9050afcffa2f6fb77f5878112704c6f2a9251

- Update vendored sources to duckdb/duckdb@6b98c64b851b6289a9d2125bdb6ff3795c752001.

  Date: 2026-09-25 13:48:43 +0000

  EXPLAIN SQL prerequisites (https://redirect.github.com/duckdb/duckdb/pull/26117)

  Unflavored-from: c88817e8a7f5196fecee78f5bc13de425ac0d86c

- Update vendored sources to duckdb/duckdb@9c2fa47c255aed50216db54d8bdefe1f641fd965.

  Date: 2026-09-25 13:48:28 +0000

  Try to use prebuilt duckdb archive files in extension build jobs (https://redirect.github.com/duckdb/duckdb/pull/26123)

  Unflavored-from: e11a5a3f9332fe593a5d1c76e9e114f81305bbf1

- Update vendored sources to duckdb/duckdb@209e98f4f2e3142b73f574d01b4440606d9bf5d8.

  Date: 2026-09-25 11:55:00 +0000

  \[Dev\] Replacing boilerplate repeated code with a generic `StringUtil::Join` (https://redirect.github.com/duckdb/duckdb/pull/26140)

  Unflavored-from: 812b7ceae0324fca78572726dda4f9e6fd860edc

- Update vendored sources to duckdb/duckdb@ca15f79c32c52c4b51df81f11cf915311db950d1.

  Date: 2026-09-25 07:15:05 +0000

  Multi-file scans: wait on a condition variable for async file opens instead of yield-spinning (https://redirect.github.com/duckdb/duckdb/pull/26149)

  Unflavored-from: 52b6e9e6085963dc53d51177759a4b80b76ca463

- Update vendored sources to duckdb/duckdb@9d283094ac3038fdfa4bf3ff92efe47b307fb846.

  Date: 2026-09-24 21:39:20 +0000

  Fix out-of-bounds read in CSV projection with escaped extra column (https://redirect.github.com/duckdb/duckdb/pull/26100)

  Unflavored-from: daa732c411aa31dc5cff29ab789268f4e7c07379

- Update vendored sources to duckdb/duckdb@e42ed0ce893f34bc47f0fc3063d9600e4e5dc59b.

  Date: 2026-09-24 21:09:46 +0000

  Open DuckDB databases passing ClientContext, that makes so that settings (`http_proxy`!) and logger works appropriately (https://redirect.github.com/duckdb/duckdb/pull/26136)

  Unflavored-from: e8536ad8c7a6e39019c9c2aabc88787915fed947

- Update vendored sources to duckdb/duckdb@59b9412aec77de035f72e8ab57dce052b43c6dc7.

  Date: 2026-09-24 21:09:04 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10968: Segment Tree Boundaries (https://redirect.github.com/duckdb/duckdb/pull/26142)

  Unflavored-from: 0a1d4ef32c6ade3ff3fc0b373cdd5f0cc2d672dc

- Update vendored sources to duckdb/duckdb@45205755e6004110843d9397731d418fee2e5aa8.

  Date: 2026-09-24 21:06:35 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10792: TimeZone 2026d Merge (https://redirect.github.com/duckdb/duckdb/pull/26108)

  Unflavored-from: 201b27d9c215effc75a08529d2a7a28f6b4b2ca3

- Update vendored sources to duckdb/duckdb@cb71e7ffdf9139a4592230e6dc1522ddba20276b.

  Date: 2026-09-24 21:04:26 +0000

  Fix prefix `~` precendence (https://redirect.github.com/duckdb/duckdb/pull/26122)

  Unflavored-from: 3daa5afac35864dfe90479c147fe42d6f79cc00d

- Update vendored sources to duckdb/duckdb@94a1664bb83253fe097d6f7d298e1eb16034339f.

  Date: 2026-09-24 20:55:05 +0000

  Map legacy table filter keys in deserialization (https://redirect.github.com/duckdb/duckdb/pull/26125)

  Unflavored-from: cc5963ab16b48d117b325e8149dd3db1dbc14d0b

- Update vendored sources to duckdb/duckdb@fbfbefa03d06c22f49c03f9d3e559baca8c469b5.

  Date: 2026-09-24 19:54:27 +0000

  Fix division by zero in CSV reader when max_line_size overflows the buffer size (https://redirect.github.com/duckdb/duckdb/pull/26131)

  Unflavored-from: 39cbc2073fd42dbb3355ffdfae6d05e790b2ddc9

- Update vendored sources to duckdb/duckdb@3df252bd2fc7fc857089892889f62cf73e967b0d.

  Date: 2026-09-24 19:54:14 +0000

  Fix 64-byte VARIANT strings written as empty short strings to Parquet (https://redirect.github.com/duckdb/duckdb/pull/26130)

  Unflavored-from: 3bdd4523f62e24cbba42b2025da40322d97b0550

- Update vendored sources to duckdb/duckdb@fa546fbac8ac0324f9d56d2b4c03a7f531ddadd8.

  Date: 2026-09-24 19:54:01 +0000

  Fix double quoted in error messages (https://redirect.github.com/duckdb/duckdb/pull/26129)

  Unflavored-from: ceb6a8d0db3e8db4d619eb62378e2f3484e2009f

- Update vendored sources to duckdb/duckdb@41297c4dc8b5ef5cc0005ac75e3e6c59fa2807f0.

  Date: 2026-09-24 19:46:55 +0000

  Fix remote pushdown bump quack (https://redirect.github.com/duckdb/duckdb/pull/26133)

  Unflavored-from: 5e734e89ab33b2cfb88ad7aef4ecc45d9ea6fb70

- Update vendored sources to duckdb/duckdb@7edf3d7f24eb229a0b61ee0e6b4b87965673a259.

  Date: 2026-09-24 19:46:31 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10701: Calendar Hash Zero (https://redirect.github.com/duckdb/duckdb/pull/26138)

  Unflavored-from: 57c4eaa9410864f4482d0228f1384ef0da682f88

- Update vendored sources to duckdb/duckdb@be600297343f15d7c4aafecaefe82ba4180571d5.

  Date: 2026-09-24 19:43:13 +0000

  Strenghten replacement scans / query to handle nested namespaces and paths more properly (https://redirect.github.com/duckdb/duckdb/pull/26139)

  Unflavored-from: 50a41b49b576a90c5ecd574f64f108dda09a6062

- Update vendored sources to duckdb/duckdb@0e216757fac8cfb24d1e1791861af695602b8589.

  Date: 2026-09-24 19:40:14 +0000

  Don't mask with genuine error with InterruptException (https://redirect.github.com/duckdb/duckdb/pull/25902)

  Unflavored-from: 4be7a0fe7f41f0f2a4b064b7394f4d1c29215733

- Update vendored sources to duckdb/duckdb@27ab1ec087ca0d23d93c2893faf550ac8d11d889.

  Date: 2026-09-24 14:14:59 +0000

  bump httpfs (https://redirect.github.com/duckdb/duckdb/pull/26126)

  Unflavored-from: d7b85dc78f0daabd3d9bedc70923e44c82b8c8a1

- Update vendored sources to duckdb/duckdb@0b9cba250c61c02cca9b3939e4a2a2e739340279.

  Date: 2026-09-24 12:43:27 +0000

  Use CompressionSegmentReader for Patas and Chimp decompression (https://redirect.github.com/duckdb/duckdb/pull/26034)

  Unflavored-from: 6d783e7324467d21a44456e880ecfe3d3bbf8989

- Update vendored sources to duckdb/duckdb@feab3c8e2bfe35fce1f08aa2289f0ab3df9898ef.

  Date: 2026-09-24 12:33:40 +0000

  Bump Postgres, MySQL and SQLite (https://redirect.github.com/duckdb/duckdb/pull/26119)

  Unflavored-from: 676f1b1f8c0813c96b22bcf006dcb052aa0f14e0

- Update vendored sources to duckdb/duckdb@c912e7b17ca4f6b3c2c4f444cf8aec562cc05620.

  Date: 2026-09-24 12:31:51 +0000

  Use CompressionSegmentReader for uncompressed strings (https://redirect.github.com/duckdb/duckdb/pull/25352)

  Unflavored-from: 47dee91844e4d2b991221adefe7fe58297828169

- Update vendored sources to duckdb/duckdb@3f59160bb2d74e22ea53b346afbf204ec1b3de4f.

  Date: 2026-09-24 10:50:29 +0000

  \[MultiFileReader\] Make missing mapping-candidate a recoverable error (https://redirect.github.com/duckdb/duckdb/pull/26116)

  Unflavored-from: 248d9f0b0a3eaa5711f3ea603fdfcb55ebd61966

- Update vendored sources to duckdb/duckdb@233847abfaa328922d08bfd0768b133ffcc88ce4.

  Date: 2026-09-24 08:32:18 +0000

  Add fetch next without value (https://redirect.github.com/duckdb/duckdb/pull/25694)

  Unflavored-from: 3ccf5117c9999742567766d0d28709586ad83d54

- Update vendored sources to duckdb/duckdb@12633c226f827d4328a83e820d3d6a3f16195207.

  Date: 2026-09-24 06:34:36 +0000

  Improve test coverage and revert uv.lock (https://redirect.github.com/duckdb/duckdb/pull/26101)

  Unflavored-from: 3d0608ef6d835da1025902675f45b4916e8a0a3b

- Update vendored sources to duckdb/duckdb@f2241a97fb9ba64b4deb460af439d8bbd64cf1b1.

  Date: 2026-09-24 06:33:38 +0000

  Dont deploy on arm64 compat, retry rclone if missing (https://redirect.github.com/duckdb/duckdb/pull/26115)

  Unflavored-from: 2fc85478c82b4d33b0d3a0f7da78778fd2705228

- Update vendored sources to duckdb/duckdb@94d7b64072504260f534690b21f0fbb8dae6326e.

  Date: 2026-09-23 18:33:50 +0000

  Deprecate vacuum index rebuild fallback setting (https://redirect.github.com/duckdb/duckdb/pull/26089)

  Unflavored-from: 5d8bd9b6d553f341d792edaf453abf494020e8f0

- Update vendored sources to duckdb/duckdb@f9174a0485f4520a5d3541e3103823d2a79ca78e.

  Date: 2026-09-23 18:33:23 +0000

  Route aws-sdk-cpp to vcpkg-duckdb-ports in merged vcpkg manifest (https://redirect.github.com/duckdb/duckdb/pull/26086)

  Unflavored-from: 8e47ab0f8f5e2b6d414474106fbd9ed4bc1c1194

- Update vendored sources to duckdb/duckdb@3b5d27bdb737a661a83b312fe045e3acc03fc05d.

  Date: 2026-09-23 16:32:11 +0000

  \[Serialization\] Fix backwards-compatibility issue surrounding `has_[de]serialize` and add test (https://redirect.github.com/duckdb/duckdb/pull/26093)

  Unflavored-from: 0523dbc8d8e1da979233e1fde1d7a9bd530fa966

- Update vendored sources to duckdb/duckdb@2d1cf59ca522dab2ff45655996aa81ed63d2f16b.

  Date: 2026-09-23 14:31:26 +0000

  Allow nested partition paths for `PARTITION_PATH` option in COPY TO FILE (https://redirect.github.com/duckdb/duckdb/pull/26081)

  Unflavored-from: b47fa93a2c529caa7dabc883b96bfb04bfb31338

- Update vendored sources to duckdb/duckdb@3be8ad691023faba804b9b0e97475caae0ef3d4c.

  Date: 2026-09-23 14:29:07 +0000

  Create optimized (LTO) version of static libs (https://redirect.github.com/duckdb/duckdb/pull/26073)

  Unflavored-from: 043804f67a2d7ef6821acb65f9bc7a393640d1e2

- Update vendored sources to duckdb/duckdb@23b7d92e89b654f77082c5b56cb38b28e6073f62.

  Date: 2026-09-23 14:25:45 +0000

  Validate UTF-8 in C API v2 identifiers (https://redirect.github.com/duckdb/duckdb/pull/26088)

  Unflavored-from: b9742534c76e317c5e04e1f8d23b511750d25a65

- Update vendored sources to duckdb/duckdb@eb620c77f811ba00b7ff4febc4ac8dc9bef9b451.

  Date: 2026-09-23 13:01:38 +0000

  Fix stack overflow in LIKE with many % wildcards (https://redirect.github.com/duckdb/duckdb/pull/26074)

  Unflavored-from: e6e9b29d3e03aa1b73eb0e967e78b674132185f3

- Update vendored sources to duckdb/duckdb@2ede5e91572577e72731ca98b4bc95de7abf74cb.

  Date: 2026-09-23 12:55:36 +0000

  Add `@` operator (second attempt) (https://redirect.github.com/duckdb/duckdb/pull/25736)

  Unflavored-from: 6bea48424cba8efc5f85f4e03238589ad3e86119

- Update vendored sources to duckdb/duckdb@795e1c1090a52bbac5d2d3b298bd26670d85122b.

  Date: 2026-09-23 07:57:40 +0000

  Add two new parser benchmarks (https://redirect.github.com/duckdb/duckdb/pull/26015)

  Unflavored-from: eb061ab86e36a95a870c88fb3691fb16d80b7e34

- Update vendored sources to duckdb/duckdb@339e74a5ce543a72547672c99045d730cf5aca57.

  Date: 2026-09-23 07:57:32 +0000

  Memoize the grammar rules that are actually re-entered (https://redirect.github.com/duckdb/duckdb/pull/26024)

  Unflavored-from: 5b2e190f43d41d1c9ad08f1b3b2504ca9f25d54a

- Update vendored sources to duckdb/duckdb@1a4835bb8ad831b179b24718d35d8730b747244f.

  Date: 2026-09-23 04:18:44 +0000

  Modularize library linking (https://redirect.github.com/duckdb/duckdb/pull/25814)

  Unflavored-from: dcfa9a5f708aaeec655c9a4e54d7bab1d4eae70e

- Update vendored sources to duckdb/duckdb@5bf7843f06f20b3881b7769e1caa42c772dda267.

  Date: 2026-09-23 04:17:12 +0000

  fix: bind named table function parameters via contextual cast (https://redirect.github.com/duckdb/duckdb/pull/26018)
  Unflavored-from: b67bcca5226ab0fa4bcccd677086f53fdccb8255

- Update vendored sources to duckdb/duckdb@a626a4acdac6dd32a4c400305dc54d2e8fe4f85c.

  Date: 2026-09-23 03:46:17 +0000

  Enable pruning through floating identities (https://redirect.github.com/duckdb/duckdb/pull/25775)
  Fix problems with pre-commit hook (https://redirect.github.com/duckdb/duckdb/pull/24513)
  Use custom stacks to probe the minimum thread stack size (https://redirect.github.com/duckdb/duckdb/pull/26012)

  Unflavored-from: 10d498d1f26ecf680329c57b6b9874b50e493959

- Update vendored sources to duckdb/duckdb@c4296ec69832f232f7efb6b717ac554cf3597e26.

  Date: 2026-09-23 01:33:01 +0000

  Use tracked allocator for JSON parsing in the cast to VARIANT (https://redirect.github.com/duckdb/duckdb/pull/25217)

  Unflavored-from: 7e2f0e020698d3b193bcd4022054cc1f8faecbd2

- Update vendored sources to duckdb/duckdb@8297805e6f2c2ceec5b8fe944178d290c6b1fec0.

  Date: 2026-09-23 01:00:12 +0000

  Fix operator progress reporting (https://redirect.github.com/duckdb/duckdb/pull/26013)
  Fix new extension build patching (https://redirect.github.com/duckdb/duckdb/pull/26014)

  Unflavored-from: 4434d5e939d9288fa052845ad9e76b382255db42

- Update vendored sources to duckdb/duckdb@65a6fb1c39add4a52673a89e4bd7e1180a68e4b4.

  Date: 2026-09-23 00:59:00 +0000

  Bump multiple extensions (https://redirect.github.com/duckdb/duckdb/pull/26016)

  Unflavored-from: 83315001cb741f858525330c1204152c818d3e55

- Update vendored sources to duckdb/duckdb@c14b8d88a602a142332839ceba105c2167bbba91.

  Date: 2026-09-23 00:58:08 +0000

  Allow accessing profiler query tree under lock (https://redirect.github.com/duckdb/duckdb/pull/26022)
  Internal https://redirect.github.com/duckdb/duckdb/pull/10926: v2.0.0 TimeZone 2026d (https://redirect.github.com/duckdb/duckdb/pull/26038)

  Unflavored-from: a3723b17e1a48407719f394b8dd4c8f429d52be3

- Update vendored sources to duckdb/duckdb@35a7edc58f8a4584387b1a255482879c690571b9.

  Date: 2026-09-23 00:54:17 +0000

  Fix segfault on failed transaction commit cleanup (https://redirect.github.com/duckdb/duckdb/pull/26019)

  Unflavored-from: 66cc70d059c3925f009567b24cf29f24acaa65b7

- Update vendored sources to duckdb/duckdb@5d05cd9d05470d619882e2ce12be26c44b1c5566.

  Date: 2026-09-23 00:53:45 +0000

  Fix truncation of the allocation size in approx_top_k (https://redirect.github.com/duckdb/duckdb/pull/26029)

  Unflavored-from: 160af7e0c5bfd229180f0f13ebe55c940bcea923

- Update vendored sources to duckdb/duckdb@d7776176d3fc38c56f24ee3b6fea1cce1ea02e0f.

  Date: 2026-09-23 00:52:58 +0000

  Fix use-after-free of join-pushed table filters during read-ahead teardown (https://redirect.github.com/duckdb/duckdb/pull/26033)

  Unflavored-from: 0a0aad588384bf8f9bc6f08d25dc5a9c0cee87f9

- Update vendored sources to duckdb/duckdb@6844d1bd8b80cc6637b4fe9411419a154f80ad39.

  Date: 2026-09-22 17:53:22 +0000

  Use UUID internal names for read_duckdb attachments + CONNECT (https://redirect.github.com/duckdb/duckdb/pull/26032)

  Unflavored-from: 7f4dda4a5e39174fbc074fb6a976a20dcc4bdab6

- Update vendored sources to duckdb/duckdb@bfccbfbf38a77558c9c5ba4e624121cee6eac054.

  Date: 2026-09-22 16:31:39 +0000

  Second attempt at `*args` and `**kwargs` (https://redirect.github.com/duckdb/duckdb/pull/25991)

  Unflavored-from: b7d7ec4903c21042eff927b72537bf8bb9b5509c

- Update vendored sources to duckdb/duckdb@e366461e30fb95d68c0d53a50f050dd0b043fc71.

  Date: 2026-09-22 12:27:04 +0000

  fix list of struct cast with quoted closing brace (https://redirect.github.com/duckdb/duckdb/pull/25985)

  Unflavored-from: 1a7caaca27f4594d1a85855ec577af77105eabf2

- Update vendored sources to duckdb/duckdb@6889e6a57017bddb7633b8b5c5a85e683ba972d6.

  Date: 2026-09-22 11:06:19 +0000

  Fix positional column references in macro arguments (https://redirect.github.com/duckdb/duckdb/pull/26010)
  Fixup run_tests.py to propagate skipped tests in all cases (https://redirect.github.com/duckdb/duckdb/pull/26005)

  Unflavored-from: b772bd10ce42202a4d0f5addc67ca722d878476c

- Update vendored sources to duckdb/duckdb@d4e72566aa8dcb35fc727e2a5ced8e9a2f6d8143.

  Date: 2026-09-22 08:42:46 +0000

  Pin the StatementType count in the C API (https://redirect.github.com/duckdb/duckdb/pull/26003)
  Run codecov/osx for default branch (https://redirect.github.com/duckdb/duckdb/pull/25977)

  Unflavored-from: 627be0ab3edded0786e47f1382516499b6028e71

- Update vendored sources to duckdb/duckdb@4d95776fd7774793d7d4a8d47eca9f6d9089da09.

  Date: 2026-09-22 07:49:59 +0000

  Cleanup an arrow stream if the result cancelled or the connection was closed (https://redirect.github.com/duckdb/duckdb/pull/26002)

  Unflavored-from: 658342d1e522381ed395a6432f798e4fc1da5b43

- Update vendored sources to duckdb/duckdb@2931a9165ce626cf4d7b824d9cbe7ce32c5f09af.

  Date: 2026-09-22 07:36:00 +0000

  Add more autoloadable log types (https://redirect.github.com/duckdb/duckdb/pull/25993)

  Unflavored-from: aba40389f58d7353c06d5cbd72dd695c3bf06cb8

- Update vendored sources to duckdb/duckdb@2b5b29ef7167cb6f7da79bbd75f060cd455a3e0a.

  Date: 2026-09-22 07:35:42 +0000

  Fix UNIQUE constraint support for ALTER TABLE ADD COLUMN (https://redirect.github.com/duckdb/duckdb/pull/25543)

  Unflavored-from: 894a7201e6e05f8f85ce3221aca255b176875e58

- Update vendored sources to duckdb/duckdb@e0fd17cf23a713d536d246d8fc2f3784eebc388f.

  Date: 2026-09-21 19:46:44 +0000

  Add progress verification, and a progress verification test config (https://redirect.github.com/duckdb/duckdb/pull/25983)

  Unflavored-from: e2b97c11f62efbf2d174aba4108a73f5dfa299ab

- Update vendored sources to duckdb/duckdb@febd818edaa604b4c61018cb5da0b52e36934fc6.

  Date: 2026-09-21 19:09:01 +0000

  Let ResultArrowArrayStreamWrapper stream again (https://redirect.github.com/duckdb/duckdb/pull/25989)

  R-side fix

- Update vendored sources to duckdb/duckdb@4e273cde68966025427c520e38afeaebae30d364.

  Date: 2026-09-21 18:36:33 +0000

  Added connection_progress_get to the capi v2 (https://redirect.github.com/duckdb/duckdb/pull/25984)

  Unflavored-from: 7650433ee4c6c8fa3e46afd98a60dec0985b509f

- Update vendored sources to duckdb/duckdb@03458f462d4b5326ab5b23a81789d5ab6dfeb181.

  Date: 2026-09-21 18:35:30 +0000

  Capi make set target optional v2.0 branch (https://redirect.github.com/duckdb/duckdb/pull/25982)
  \[Tester\] `require-env-not <name>` without arguments (https://redirect.github.com/duckdb/duckdb/pull/25981)

  Unflavored-from: e9e622d51e4962b320ae6b43500b42d971a2ec82

- Update vendored sources to duckdb/duckdb@9edd680391e838aeb6983ce8012538b6b7e2a9fa.

  Date: 2026-09-21 17:35:55 +0000

  Fix enum casts swallowing nested conversion failures (https://redirect.github.com/duckdb/duckdb/pull/25788)

  Unflavored-from: d2c7fddf36e00bc50d5f0c765aa77f7bc4c14f0c

- Update vendored sources to duckdb/duckdb@1dd152877777640e94154dbcadb4eb29308cfef1.

  Date: 2026-09-21 17:20:45 +0000

  Bump quack + run quack tests (https://redirect.github.com/duckdb/duckdb/pull/25978)

  Unflavored-from: 889e49e7b06e73993d1cb6c8d04ab3d9f6b85835

- Update vendored sources to duckdb/duckdb@396fd33c8a5e18d1ba10f25350915120e11083ff.

  Date: 2026-09-21 13:13:05 +0000

  Restore quoted identifier in some places (https://redirect.github.com/duckdb/duckdb/pull/25895)
  Bump httpfs to latest version (https://redirect.github.com/duckdb/duckdb/pull/25976)

  Unflavored-from: 346092ccadf6d6ec0441f46bb18e6cff134b01aa

- Update vendored sources to duckdb/duckdb@c1c7653bc0afb7c81a884310c7ac8891d3140dfb.

  Date: 2026-09-21 12:38:29 +0000

  Remove hard-coded options in OpenFileInfo parsing (https://redirect.github.com/duckdb/duckdb/pull/25975)

  Unflavored-from: e2bb93826bf8954610d8f53aeff34db4fe892477

- Update vendored sources to duckdb/duckdb@fdb234404c4696b8a221d31cffce175d75314938.

  Date: 2026-09-21 12:31:50 +0000

  Report buffered outer-join source progress (https://redirect.github.com/duckdb/duckdb/pull/25761)

  Unflavored-from: 5db0e8ee5810f41dec3698d54f4b9eae2f9fcd3f

- Update vendored sources to duckdb/duckdb@549c3c83fbefedd5fdf5426e8dbeaa4dc8fc56f2.

  Date: 2026-09-21 12:28:26 +0000

  Report positional join source progress (https://redirect.github.com/duckdb/duckdb/pull/25759)

  Unflavored-from: 262596b34013f5dae69b5aded40e558842ad9409

- Update vendored sources to duckdb/duckdb@b3c9c4dd987b135e2e5d64f402bb6e73ed955d21.

  Date: 2026-09-21 12:28:16 +0000

  Report progress for repeat and repeat_row (https://redirect.github.com/duckdb/duckdb/pull/25757)

  Unflavored-from: 575e5522246efb423b97b6ce5cde9208b7bcfe12

- Update vendored sources to duckdb/duckdb@8c975ccf8bf1453de3111103d1345d82474ad246.

  Date: 2026-09-21 12:28:01 +0000

  Report LIMIT_PERCENT source progress (https://redirect.github.com/duckdb/duckdb/pull/25756)

  Unflavored-from: d3b1119eaa380d3712bcad500b27a1183f1bf737

- Update vendored sources to duckdb/duckdb@a3bcfbfe8c4e049bc02d5be89eefffe64eefb3e1.

  Date: 2026-09-21 12:27:49 +0000

  Report piecewise merge join source progress (https://redirect.github.com/duckdb/duckdb/pull/25755)

  Unflavored-from: 535f1437088b98fc3bdbf8415db402578e952d8f

- Update vendored sources to duckdb/duckdb@af1f1e7d0847449e936e0444b464db1c61bc9cb3.

  Date: 2026-09-21 12:27:38 +0000

  Report perfect-hash aggregate source progress (https://redirect.github.com/duckdb/duckdb/pull/25750)

  Unflavored-from: 69c91a6e0c30421657f0adce99418093c55b9e24

- Update vendored sources to duckdb/duckdb@238f5a5ee2cef48cd5883c8df4836eb7a604566e.

  Date: 2026-09-21 12:27:26 +0000

  Report limited distinct source progress (https://redirect.github.com/duckdb/duckdb/pull/25749)

  Unflavored-from: 7c86ea2f1d09f3ce9046e9282de53a01bcf910f9

- Update vendored sources to duckdb/duckdb@7539608991907c1bcf5f64f6fb6f766de5581696.

  Date: 2026-09-21 12:27:04 +0000

  Report Top-N source progress (https://redirect.github.com/duckdb/duckdb/pull/25748)

  Unflavored-from: 24f7b87f5c3a81d3e059467b82c31103496d2967

- Update vendored sources to duckdb/duckdb@ace2451f528c902fb6ab02a8cbd4b491343f3f3a.

  Date: 2026-09-21 12:25:28 +0000

  Report reservoir sample source progress (https://redirect.github.com/duckdb/duckdb/pull/25754)

  Unflavored-from: 646672e5610ad52e2e2e9be92e5601699e14922f

- Update vendored sources to duckdb/duckdb@a44519f7c0bd951edbb22ce4af5287c959ddf9dc.

  Date: 2026-09-21 12:24:26 +0000

  Improve WAL replay error propagation (https://redirect.github.com/duckdb/duckdb/pull/25768)

  Unflavored-from: a622178e6530791dc3ffafbec8af765352111563

- Update vendored sources to duckdb/duckdb@738c60dfcba2b6bbce51d786fa236ebe5ec49ac2.

  Date: 2026-09-21 12:12:01 +0000

  Avoid an out of line comparison call in the floating point min/max aggregate (https://redirect.github.com/duckdb/duckdb/pull/25927)
  Add `uv.lock` to `gitignore` (C API V2 gen) (https://redirect.github.com/duckdb/duckdb/pull/25974)

  Unflavored-from: 2848bce701e799575677d633d401887fda8b694c

- Update vendored sources to duckdb/duckdb@462aae9021a9d54b62617978c6f4d6beea59bd75.

  Date: 2026-09-21 11:41:16 +0000

  Save one GET request in parquet read (https://redirect.github.com/duckdb/duckdb/pull/25963)

  Unflavored-from: 0dd31feba12adfa091bc42e08e195d0fd0b083ed

- Update vendored sources to duckdb/duckdb@c491d132165f91e492e0feee3d4dbe2b74dffd9a.

  Date: 2026-09-21 11:31:32 +0000

  Fix index entry loss during shutdown checkpoint (https://redirect.github.com/duckdb/duckdb/pull/25771)

  Unflavored-from: 32ef8d0e7dbccd3850635f0c3c7218332638b1e4

- Update vendored sources to duckdb/duckdb@94bc505bcc7fc2deb245cbbb5b7a86d58b729c51.

  Date: 2026-09-21 11:18:48 +0000

  Fix missing table scan filters in EXPLAIN (https://redirect.github.com/duckdb/duckdb/pull/25863)

  Unflavored-from: 208c002789b62dbc76a405cab0f94b36054eb82f

- Update vendored sources to duckdb/duckdb@aa6c6d98ccf4b72ff8e547773ffa95b29c4ee72d.

  Date: 2026-09-21 10:59:16 +0000

  Let a checkpoint ignore deletes that committed above its bound (https://redirect.github.com/duckdb/duckdb/pull/25970)

  Unflavored-from: 236cfce88cb9ff78b26445e2875114be01985cd0

- Update vendored sources to duckdb/duckdb@0a07565cc754581c12168459c4a1173f1b612a8a.

  Date: 2026-09-21 10:45:51 +0000

  Fix `read_blob` / `read_text` against pseudo-filesystem (https://redirect.github.com/duckdb/duckdb/pull/25893)

  Unflavored-from: b191627295e0e23de99f173bfffe5c898ec173b0

- Update vendored sources to duckdb/duckdb@b386de390ebd9589fbae25e771d440ce07eb1227.

  Date: 2026-09-21 10:42:24 +0000

  Propagate stats through secure views if there's only projections over columns (https://redirect.github.com/duckdb/duckdb/pull/25969)

  Unflavored-from: 119039a7f9b773762adb6e3e2f6aaf385548f52d

- Update vendored sources to duckdb/duckdb@9df2b4738b2aa032bf131974f379d2c5291f2121.

  Date: 2026-09-21 09:29:46 +0000

  Fix index identification during WAL serialization (https://redirect.github.com/duckdb/duckdb/pull/25881)

  Unflavored-from: 6130c9f9108a37cbe53f992dd6a900be660c14c5

- Update vendored sources to duckdb/duckdb@fece4143738e2b1d05a851d5c5dc036838aff8ec.

  Date: 2026-09-21 09:24:45 +0000

  \[Transaction\] Honor the `current_transaction_invalidation_policy` in the `ErrorResult` constructor function (https://redirect.github.com/duckdb/duckdb/pull/25329)

  Unflavored-from: 58474e4ca480473fd8bff553e4e7a940c1acfd48

- Update vendored sources to duckdb/duckdb@0a8aa20da21109870295206b2268b8fa4873136c.

  Date: 2026-09-21 09:17:42 +0000

  Fix gzip short-read buffer overflow (https://redirect.github.com/duckdb/duckdb/pull/25905)

  Unflavored-from: f83b4a4505795536f989925e80caf821aeacd7ea

- Update vendored sources to duckdb/duckdb@7e1c37c0e96182c8f00843274043a0e7d2f0287e.

  Date: 2026-09-21 08:17:36 +0000

  Fix reverse order when reverting failed commits (https://redirect.github.com/duckdb/duckdb/pull/25933)
  Enhance cli .timer precision (https://redirect.github.com/duckdb/duckdb/pull/25741)

  Unflavored-from: 0f6eece5b6ea2dd209ce1be8a5a5a6338ac5e952

- Update vendored sources to duckdb/duckdb@210c1413053ceb58fd54986e9e1b9a8eeeb5427c.

  Date: 2026-09-21 08:15:32 +0000

  Stream window functions only when volatile arguments run once per row (https://redirect.github.com/duckdb/duckdb/pull/25953)

  Unflavored-from: 33a7d1c3d9176e4cda59738d174decd25606a1ee

- Update vendored sources to duckdb/duckdb@a3af2c456524eb34fb756dcd443093d6353024b1.

  Date: 2026-09-21 08:11:21 +0000

  Fix nan handling for stats calculation (https://redirect.github.com/duckdb/duckdb/pull/25767)

  Unflavored-from: 5ff6bc67d2bc1d304fd9f3ad5da8f8b0a24c2daa

- Update vendored sources to duckdb/duckdb@7a42e9a906c1001a36dacf445a44c337139dbfa4.

  Date: 2026-09-21 08:02:17 +0000

  Fix `PARTITION_PATH` for disabled local filesystem, fix NULL remapping in MultiFileReader (https://redirect.github.com/duckdb/duckdb/pull/25908)

  Unflavored-from: 0a495d05d6fd879cd27b2a7f296fe227510105ee

- Update vendored sources to duckdb/duckdb@80e2703281b334b893d22014094ffea20eff8c32.

  Date: 2026-09-21 07:49:10 +0000

  Rebind empty result columns when deep copying a plan (https://redirect.github.com/duckdb/duckdb/pull/25947)
  Remove restrictive paths filter on Main.yml run (https://redirect.github.com/duckdb/duckdb/pull/25800)

  Unflavored-from: 92f0865a0cd382575c0369aac87a2127a26fe1df

- Update vendored sources to duckdb/duckdb@1b6ed95435df7ad9da6037ac0153f404f0482206.

  Date: 2026-09-21 07:48:40 +0000

  Fix unpinned blocks without tempdir permanently dropped (https://redirect.github.com/duckdb/duckdb/pull/25959)

  Unflavored-from: f89db3b0c670baa51cf8c5152f887b5e8b5fee41

- Update vendored sources to duckdb/duckdb@b48c4270901ba66525f9a52359f121943b14d1df.

  Date: 2026-09-21 07:45:40 +0000

  Order VARIANT object keys consistently across renderings (https://redirect.github.com/duckdb/duckdb/pull/25960)

  Unflavored-from: a232a2fb5d857e869cfced9e716cc8430e2c2fdb

- Update vendored sources to duckdb/duckdb@360d6e742df57690ade9bf0a84bd4c1955748f9e.

  Date: 2026-09-21 07:43:58 +0000

  \[Parser\] Preserve user-provided ordering of grammar extensions (https://redirect.github.com/duckdb/duckdb/pull/25958)

  Unflavored-from: 5c7227193dd993fb72b68472d4590b02796cb88f

- Update vendored sources to duckdb/duckdb@c90c7bcdf549ab8db08f4f6f6997e270a1592711.

  Date: 2026-09-21 07:43:42 +0000

  Do not use an index scan when a sample was pushed into the table scan (https://redirect.github.com/duckdb/duckdb/pull/25957)
  \[Tester\] Extend `require-env` to take a list of accepted values, add `require-env-not` (https://redirect.github.com/duckdb/duckdb/pull/25950)

  Unflavored-from: 1e1a6718ed355888243aa75d0855b78900b43502

- Update vendored sources to duckdb/duckdb@3384f526efeb0f2375b43e67ce99fd38a15b518b.

  Date: 2026-09-21 07:42:10 +0000

  Reset the streaming window argument vector between chunks (https://redirect.github.com/duckdb/duckdb/pull/25949)

  Unflavored-from: 874b0c23dcdb7ce3a3750bf111ecdc6046b1f67a

- Update vendored sources to duckdb/duckdb@1e05869befb4fa15c42e70433387fb8819746c86.

  Date: 2026-09-21 07:35:22 +0000

  backport bugfix from 25474 (https://redirect.github.com/duckdb/duckdb/pull/25938)

  Unflavored-from: fc473e23f6de633022015550c1d70f972177ca57

- Update vendored sources to duckdb/duckdb@dfbe2a6d06dc95cc9a746a588d96df3d38262773.

  Date: 2026-09-21 07:35:11 +0000

  Extract IE join preparation and candidate enumeration for reuse (https://redirect.github.com/duckdb/duckdb/pull/25936)
  \[Tester\] Rewrite the `TestResultHelper::CheckStatementResult` method (https://redirect.github.com/duckdb/duckdb/pull/25934)

  Unflavored-from: 1a7c3b5433650ff7adde67427a08d4d6714119b7

- Update vendored sources to duckdb/duckdb@d37c97c6a3727e5570c0cc507d40cecb1240ac12.

  Date: 2026-09-21 06:51:10 +0000

  Keep a SQL NULL row NULL when casting VARIANT to JSON (https://redirect.github.com/duckdb/duckdb/pull/25954)

  Unflavored-from: 64482bf161734511517e741753c96c102c11e8b4

- Update vendored sources to duckdb/duckdb@4f7173bd98dced0a0c9a8dd6d0929db04e351e45.

  Date: 2026-09-21 06:49:00 +0000

  Support VARIANT over the Arrow interface (arrow.parquet.variant) (https://redirect.github.com/duckdb/duckdb/pull/24157)

  Unflavored-from: c002a8a5eee1228228e3e3c8834eb31fd191b8b1

- Update vendored sources to duckdb/duckdb@bcff50365875c455f6c402c06838007f0ced9ca7.

  Date: 2026-09-21 06:48:45 +0000

  Fix individual UTF-8 validation bypass in DELTA_LENGTH_BYTE_ARRAY decoder (https://redirect.github.com/duckdb/duckdb/pull/25853)

  Unflavored-from: 4b3cd9a7c788601b19a62a96cf5c1b4ff3731be8

- Update vendored sources to duckdb/duckdb@114c56196df18aab7a96a03fc7a3c52bb451a991.

  Date: 2026-09-21 06:48:08 +0000

  Fix the non-unity build (https://redirect.github.com/duckdb/duckdb/pull/25912)

  Unflavored-from: 92aaf2f302a3c364310aca85b23e959469725eec

- Update vendored sources to duckdb/duckdb@9513eb9400286e44073478f616b45c90b1037f9c.

  Date: 2026-09-21 06:47:07 +0000

  Merge `v1.5-variegata` into `v2.0-cyanoptera` (https://redirect.github.com/duckdb/duckdb/pull/25915)

  Unflavored-from: 704dd54fd2ef8e17e076b2efd18f742953fc52af

- Update vendored sources to duckdb/duckdb@ffbc5ed2c4d1ab1824a1df2978d969aea24bf72f.

  Date: 2026-09-21 06:46:54 +0000

  Avoid truncating allocation size (https://redirect.github.com/duckdb/duckdb/pull/25952)

  Unflavored-from: 62de38808cded745ce919e9ab9b268de155faa8d

- Update vendored sources to duckdb/duckdb@bdd42afc245c278198fa94cddec7087e77acf7c0.

  Date: 2026-09-20 09:47:21 +0000

  Expose throttled retry counts from HTTPRetryBudget (https://redirect.github.com/duckdb/duckdb/pull/25907)

  Unflavored-from: a3a94c1985972fa8ea89226be470bdd38a371c05

- Update vendored sources to duckdb/duckdb@3a604ab6d4d66910ad91bf7669c0b5f648a00190.

  Date: 2026-09-19 14:56:05 +0000

  5812 fix qualified count star (https://redirect.github.com/duckdb/duckdb/pull/25222)

  Unflavored-from: 6c1cbeda0acc3592c5b94ea385627a9e362e7433

- Update vendored sources to duckdb/duckdb@40cad2f5c9fd265a9e5fbc97d2aa38cc86ac13b1.

  Date: 2026-09-18 16:41:01 +0000

  Bind sort-key decoding directly from logical types (https://redirect.github.com/duckdb/duckdb/pull/25802)

  Unflavored-from: 51997b1c83c5424ba8d3d92d71f91c606c463f15

- Update vendored sources to duckdb/duckdb@c67000443782244349a7d41d0d73ee579d9429e9.

  Date: 2026-09-18 16:02:38 +0000

  Rename "database instance" and "db" to just "instance" in the C API V2 (https://redirect.github.com/duckdb/duckdb/pull/25910)

  Unflavored-from: cca7e136d312c9b363af721702b0ade47279f4ee

- Update vendored sources to duckdb/duckdb@cd44d6604bf6ce67d4d91b7353c76f08ee16e8e9.

  Date: 2026-09-18 15:42:30 +0000

  \[Variant\] Stat propagation fixes for extract fast-path (https://redirect.github.com/duckdb/duckdb/pull/25904)

  Unflavored-from: 7b433778102eaea09e02898c4cfb3626c32de1ec

- Update vendored sources to duckdb/duckdb@fcfd2971d243e5447c557910ceea173d29fd58b1.

  Date: 2026-09-18 13:55:11 +0000

  Preserve complete predicates in nested-loop MARK, SEMI and ANTI joins (https://redirect.github.com/duckdb/duckdb/pull/25848)

  Unflavored-from: be51d905cb2679b025c7447fefb2c39080a6a617

- Update vendored sources to duckdb/duckdb@8b7ff474078d2bff3a4c3ecc70fcf2a5d384f11e.

  Date: 2026-09-18 13:32:59 +0000

  Preserve correlation domain dependencies for CTE filter pushdown (https://redirect.github.com/duckdb/duckdb/pull/25838)
  Register statically linked CAPI_V2 extensions on the config (https://redirect.github.com/duckdb/duckdb/pull/25890)

  Unflavored-from: f2aaf149addc1d6f2b8fd34be8e700cdb89de620

- Update vendored sources to duckdb/duckdb@fcc110ac6db61b0317755eb100bd7a6a0c1f6494.

  Date: 2026-09-18 13:23:25 +0000

  Fix overflow in the day cascade of INTERVAL \* double (https://redirect.github.com/duckdb/duckdb/pull/25837)

  Unflavored-from: 3bd23cb7fe681c2516f91e83ac4f416d6cf48dc0

- Update vendored sources to duckdb/duckdb@7369a61dbc16b3e7efb826b909b0c3a5f7acfad5.

  Date: 2026-09-18 13:18:22 +0000

  Fix improper INTERNAL exception for optimistic write (https://redirect.github.com/duckdb/duckdb/pull/25896)

  Unflavored-from: 6c090b6eecbca1b4f013499fb76615d3599800b2

- Update vendored sources to duckdb/duckdb@393f596de20aba208349c86ab30a893950260df3.

  Date: 2026-09-18 12:19:21 +0000

  Fix Parquet Variant shredding REQUIRED field/element groups (https://redirect.github.com/duckdb/duckdb/pull/25891)

  Unflavored-from: 18d0e73269a4d3f76ad186d79029667883458ea8

- Update vendored sources to duckdb/duckdb@f26190781c2a9dbf08bb4d1fa0e522f92e203b0e.

  Date: 2026-09-18 11:34:40 +0000

  Optimize conflict manager rowid insertion (https://redirect.github.com/duckdb/duckdb/pull/25652)

  Unflavored-from: 11483105e0c467556cd45184ff9815498c9f32f2

- Update vendored sources to duckdb/duckdb@63da6e56475153da3d923c27e9a0610f93242033.

  Date: 2026-09-18 11:32:29 +0000

  Update projection column by correct index in expression pushdown optimizers (https://redirect.github.com/duckdb/duckdb/pull/25431)

  Unflavored-from: fa3160e797e6fbcb5a766b7a4ef6566b623cfc4a

- Update vendored sources to duckdb/duckdb@5c877933e1abd9d9afa3acf59e8f3a8f2f346f59.

  Date: 2026-09-18 09:30:49 +0000

  Retain SQL invocation information through binding and optimization (https://redirect.github.com/duckdb/duckdb/pull/25720)

  Unflavored-from: 14536f74c9ac787c172f8c2e3e3cda7c38e8c61f

- Update vendored sources to duckdb/duckdb@a77021724c9736f0fe3291a47fe670d643f05ce5.

  Date: 2026-09-18 09:27:54 +0000

  Parse generic operators using longest matching tokens (https://redirect.github.com/duckdb/duckdb/pull/25729)

  Unflavored-from: d65fcaacad297e6a96fd5af9da3aa8c5b345074d

- Update vendored sources to duckdb/duckdb@369ca2b4b9d6dd38c61ec80b38c86c8b5b84c5ed.

  Date: 2026-09-18 09:13:21 +0000

  Fix storage block leak with failed checkpoint (https://redirect.github.com/duckdb/duckdb/pull/25889)

  Unflavored-from: 187bba4fcfd94cffd56bc16ed2cd4e3ffedfb3cd

- Update vendored sources to duckdb/duckdb@87e2103ce2b41487656a0177dfe08372ae3112e9.

  Date: 2026-09-18 09:10:23 +0000

  Tidy up settings, rename one, deprecate some, flag missing debug settings as debug (https://redirect.github.com/duckdb/duckdb/pull/25864)

  Unflavored-from: 5fa43494e2ee1f8d7392d9ea64e3c24904d4fd98

- Update vendored sources to duckdb/duckdb@8be2324d0c62b379eef0e91529d378a5f29259e5.

  Date: 2026-09-18 08:48:12 +0000

  \[Parser\] Dialect-agnostic keyword categories (https://redirect.github.com/duckdb/duckdb/pull/25797)

  Unflavored-from: 5bd75dd7484cd1c8d30588ecdacce39c2cc983ef

- Update vendored sources to duckdb/duckdb@d5a16bfd084a5f820114522d6879cd10057fe075.

  Date: 2026-09-18 08:19:37 +0000

  Parquet: write and use nan_count statistics (https://redirect.github.com/duckdb/duckdb/pull/25747)
  Unflavored-from: 2c6b0b7d1e7340ad7419fcf4aa75aaa891692081

- Update vendored sources to duckdb/duckdb@08ca77a34c19872c6286d60dcabc3e5f4c19a630.

  Date: 2026-09-18 08:06:31 +0000

  Size the HTTP client pool for async I/O and allow runtime tuning (https://redirect.github.com/duckdb/duckdb/pull/25862)

  Unflavored-from: 29a003e525ec1252ccd32ca4a1b65bde385f9774

- Update vendored sources to duckdb/duckdb@19fe89df4b9ec99b95b9421a5baba0ca2adbf1a3.

  Date: 2026-09-18 07:52:25 +0000

  Add Vector::Reference to duckdb::cxx (https://redirect.github.com/duckdb/duckdb/pull/25868)

  Unflavored-from: 8393bb816e282ed3c8b704d06f36d60bebfd767c

- Update vendored sources to duckdb/duckdb@275350da912bf93aea5b1896d46241a867db13a5.

  Date: 2026-09-18 07:47:40 +0000

  Compute a TIMESTAMP time of day without signed overflow (https://redirect.github.com/duckdb/duckdb/pull/25877)

  Unflavored-from: eaa2c3c1ff002467c0383f873cc6d255fb437fc8

- Update vendored sources to duckdb/duckdb@5269dacac09b1da2782c670148f2b8d92df0bcc3.

  Date: 2026-09-18 07:45:28 +0000

  Fix missing reset for `OptimisticWriteCollection` (https://redirect.github.com/duckdb/duckdb/pull/25724)

  Unflavored-from: f85fa389fff762cb6f0cbb34a1a1a586723b75b3

- Update vendored sources to duckdb/duckdb@55621334e51b405238ed99094ed89b632aee0b6f.

  Date: 2026-09-18 07:44:57 +0000

  Fix orphand block on reverted commit (https://redirect.github.com/duckdb/duckdb/pull/25821)

  Unflavored-from: a273ebdbe79244c49a0f30d7da92e394c8433ed7

- Update vendored sources to duckdb/duckdb@afc9a632625d197fcffa4895be18a7b8d665252d.

  Date: 2026-09-18 07:43:26 +0000

  Fix buffer pool evicting object cache entries (https://redirect.github.com/duckdb/duckdb/pull/25871)

  Unflavored-from: 1bad758b15a4e66532110756d4152e3bb234b0eb

- Update vendored sources to duckdb/duckdb@a5a4928bd7bf1da723ae23f7a117ae7dfb47dfa5.

  Date: 2026-09-18 07:42:03 +0000

  Prune row group for shared prefix for case functions (https://redirect.github.com/duckdb/duckdb/pull/25531)

  Unflavored-from: fd8adca7b0800c23ef5caf75d0eb0e3e28db75bd

- Update vendored sources to duckdb/duckdb@d1ddea56f6e9fc82ff12181e7172ca52e3d9ee1e.

  Date: 2026-09-18 07:38:03 +0000

  \[MultiFileReader\] Fix bug with extract-pushdown information being lost in the global-\>local mapping (https://redirect.github.com/duckdb/duckdb/pull/25840)

  Unflavored-from: d5c263a60b9d9c636c4cead8853879716d829891

- Update vendored sources to duckdb/duckdb@21960a43851e572278ff4b5907b0fe27ccdf9396.

  Date: 2026-09-18 07:37:42 +0000

  \[Windowing\] Fix bug in window expressions with a shared sort expression (https://redirect.github.com/duckdb/duckdb/pull/25842)
  \[Testing\] Make the `--input-file` compatible with `--test-dir` (https://redirect.github.com/duckdb/duckdb/pull/25852)

  Unflavored-from: f9274107094b2611492299508dd85b92e8c6af6b

- Update vendored sources to duckdb/duckdb@0e965cf3988ec76489354ad2b4a6d4a2ebd1202c.

  Date: 2026-09-18 07:17:29 +0000

  Remove DUCKDB_BUILD_LOADABLE_EXTENSION (https://redirect.github.com/duckdb/duckdb/pull/25803)

  Unflavored-from: f638f543026be21bcb8031c77147fbdb38f6bafb

- Update vendored sources to duckdb/duckdb@24bb5a473ec4cb1970e3b54e649eaf2cce163893.

  Date: 2026-09-18 07:14:05 +0000

  Re-fix fsync implementation (https://redirect.github.com/duckdb/duckdb/pull/25784)

  Unflavored-from: 1f0097d837d3c7369ae6158328d7df042268c52a

- Update vendored sources to duckdb/duckdb@1c2b1bcb10620f513623b81cd692adbcebfecd49.

  Date: 2026-09-18 07:02:49 +0000

  Fix Lambda invoke expression property propagation (https://redirect.github.com/duckdb/duckdb/pull/24934)

  Unflavored-from: 112a24ee17e0512d1ddbb8050d9541b6c944cec2

- Update vendored sources to duckdb/duckdb@d3ff03c222abc5139a29090ab1a4888f046fa6bf.

  Date: 2026-09-18 07:02:33 +0000

  \[async results\] ResultFormats 1/3: Introduce a ResultUnit (https://redirect.github.com/duckdb/duckdb/pull/25723)
  \[Second try\] Disable issue mirroring to internal (https://redirect.github.com/duckdb/duckdb/pull/25861)
  Remove `-Wexit-time-destructors` compilation option (https://redirect.github.com/duckdb/duckdb/pull/25818)

  Unflavored-from: d6a9eeab45232754ac6c4769e3fa3502bfffbe94

- Update vendored sources to duckdb/duckdb@020c37da17cde26fb4783e8a18c8f124ab4c4d7f.

  Date: 2026-09-17 20:04:58 +0000

  Add a V2 CAPI UTF-8 validator and checked/unsafe string construction to the stable C++ API (https://redirect.github.com/duckdb/duckdb/pull/25851)

  Unflavored-from: f0b45e8c632878056f60a528786eb2c700c0ff1a

- Update vendored sources to duckdb/duckdb@1c5b270388e567bcda0ab2617ec2decbe70126d9.

  Date: 2026-09-17 15:24:44 +0000

  Migrate `read_csv` to `TableFunctionMultiFileWrapper` (https://redirect.github.com/duckdb/duckdb/pull/25793)

  Unflavored-from: 2dde1473572a9d6a745961b6ba2805af6dc07971

- Update vendored sources to duckdb/duckdb@3b6011aa06686d40e05e127ed0a6d23e9c63c030.

  Date: 2026-09-17 15:15:04 +0000

  Improve memory limit setting (https://redirect.github.com/duckdb/duckdb/pull/25833)

  Unflavored-from: 2eff3ba4b51806e0d341f5d1715ac3a1f80433e3

- Update vendored sources to duckdb/duckdb@53581e550a60ba8eb56192f7b16db69c1f310ae0.

  Date: 2026-09-17 14:41:48 +0000

  C-API-V2: Rework database handling (https://redirect.github.com/duckdb/duckdb/pull/25751)
  Unflavored-from: 98cf16ebcacabf759de65eb884dea9eed9fe028c

- Update vendored sources to duckdb/duckdb@a06ee776824bd87e14afa5696528685b37f5943d.

  Date: 2026-09-17 14:06:28 +0000

  Duckdb Copy To File PARTITION_PATH Option (https://redirect.github.com/duckdb/duckdb/pull/25846)

  Unflavored-from: 448cc834d0ae7fbcdda1b29b3da3cd6f68b36c63

- Update vendored sources to duckdb/duckdb@b8b46f3e2231dfec03b79717f3ff561cde5ee337.

  Date: 2026-09-17 14:05:12 +0000

  PinColumnOrder for CTE rewrites, avoiding follow up optimizations to scramble them (https://redirect.github.com/duckdb/duckdb/pull/25839)
  Disable issue mirroring to internal (https://redirect.github.com/duckdb/duckdb/pull/25856)

  Unflavored-from: c8123cfe7bd68631fef92498b421817d8407779f

- Update vendored sources to duckdb/duckdb@7674d1ef273c7e0cd97c6a8fccfd66aa7508be3d.

  Date: 2026-09-17 13:47:47 +0000

  Preserve expression result types through copies and rewrites (https://redirect.github.com/duckdb/duckdb/pull/25733)

  Unflavored-from: f334d5b25f1ab5338c09f487cf01e21f9bdfd3ec

- Update vendored sources to duckdb/duckdb@62ee922db30b5d7243ae5579d942cc9efb6928d7.

  Date: 2026-09-17 11:56:27 +0000

  Reduce local filesystem syscalls to get file stats (https://redirect.github.com/duckdb/duckdb/pull/25820)

  Unflavored-from: a78c2e4e6778ee3542039c894bec1eed9d762214

- Update vendored sources to duckdb/duckdb@c3409462c1c6db15f50fba3759d877b7f605c3ac.

  Date: 2026-09-17 11:06:21 +0000

  \[Arrow\]\[Dev\] For `arrow_scan`, use `TableFunctionInfo` to carry the `ArrowScanFactory` (https://redirect.github.com/duckdb/duckdb/pull/25726)

  R-side fix

- Update vendored sources to duckdb/duckdb@2c3fe8600ff79c152cc284620fceae3e0a882343.

  Date: 2026-09-17 10:26:26 +0000

  \[C API v2\] Table function partition callbacks (https://redirect.github.com/duckdb/duckdb/pull/25805)

  Unflavored-from: a85b48067069a393c3e8194d476a4575715b4342

- Update vendored sources to duckdb/duckdb@31212eaffaf9bd13a61df1198e4a5632ea6afed0.

  Date: 2026-09-17 09:52:38 +0000

  C API V2 PR1 remaining review feedback (https://redirect.github.com/duckdb/duckdb/pull/25732)

  Unflavored-from: 234c0868867738bda1268514572f44cc069163d5

- Update vendored sources to duckdb/duckdb@616632de3c3e71db9ae640816a91c87abe677938.

  Date: 2026-09-17 09:20:32 +0000

  Bump VSS (https://redirect.github.com/duckdb/duckdb/pull/25794)

  Unflavored-from: 62c0b9b046cac599ca3bbab76335a5e70dcab911

- Update vendored sources to duckdb/duckdb@a8aa07933b705cbe833dfe6ba9334b899dc76dd5.

  Date: 2026-09-17 09:20:25 +0000

  Optimize keyword matching for the PEG parser (https://redirect.github.com/duckdb/duckdb/pull/25527)

  Unflavored-from: 24d563f123eb4105320dc244e8ce18d7036627f2

- Update vendored sources to duckdb/duckdb@394f547866f67b1e224aa7bed475119f1144c86b.

  Date: 2026-09-17 08:51:41 +0000

  Extract scalar join operands only when they are independently evaluable (https://redirect.github.com/duckdb/duckdb/pull/25807)

  Unflavored-from: e0b4b603924bf8a5578e8fc1376f3135fb51d71a

- Update vendored sources to duckdb/duckdb@8aae2b52b605292ec77489e320b7b0ded1c64b19.

  Date: 2026-09-16 19:30:20 +0000

  Fix unquoted dotted filename in grammar (https://redirect.github.com/duckdb/duckdb/pull/25798)
  Update DuckLake in 2.0 (https://redirect.github.com/duckdb/duckdb/pull/25799)
  Let's have .mode trash actually Drain results (instead of terminating early) (https://redirect.github.com/duckdb/duckdb/pull/25796)

  Unflavored-from: ed20c5207b07455fa8b096bf016791dd6bf1b0e9

- Update vendored sources to duckdb/duckdb@f44fb68ea02984dc9bd050bea73eae2661c8e8ee.

  Date: 2026-09-16 14:45:09 +0000

  Name function params (again) (https://redirect.github.com/duckdb/duckdb/pull/25739)

  Unflavored-from: ae5b1826f76a338410f0b24c389356f96d550b2d

- Update vendored sources to duckdb/duckdb@ae89f04e9214d51982aa61c48dbe0d48f41857d3.

  Date: 2026-09-16 13:59:36 +0000

  \[MultiFileReader\] Fail if two incompatible nested types are detected in the `MultiFileColumnMapper` (https://redirect.github.com/duckdb/duckdb/pull/24433)

  Unflavored-from: 3f7e1f6fce67c2ab9e5bba0fae2aa1a786fbe50b

- Update vendored sources to duckdb/duckdb@e91aed0e032300bf80692b54a5a90c617342cff3.

  Date: 2026-09-16 12:11:50 +0000

  Fix temporary file truncation (https://redirect.github.com/duckdb/duckdb/pull/25773)

  Unflavored-from: 177acb52e1dcaa01e8b671b83bc18155412dc1aa

- Update vendored sources to duckdb/duckdb@c759e0c773617fb4734f8413fed18fdc457468a9.

  Date: 2026-09-16 11:45:48 +0000

  Fix shredded VARIANT cast reading the wrong struct child (https://redirect.github.com/duckdb/duckdb/pull/25792)
  Bump vcpkg to 2026.06.24 (https://redirect.github.com/duckdb/duckdb/pull/25094)
  Fix the interrupted QueryAppender test race (https://redirect.github.com/duckdb/duckdb/pull/25743)

  Unflavored-from: 1eb573d9c8043dec5d7cae112fa8153534a6c2df

- Update vendored sources to duckdb/duckdb@0854aa80a5fb064255953db1764f833179183912.

  Date: 2026-09-16 09:02:52 +0000

  fix parquet v2 value count mismatch for nulls in a list that fills a page (https://redirect.github.com/duckdb/duckdb/pull/25752)
  Shell Extension: only set last result if a query is triggered on the ShellState's connection (https://redirect.github.com/duckdb/duckdb/pull/25782)

  Unflavored-from: e7821cb0607d963cb46a6f7fa20aeb5aeba7c55d

- Update vendored sources to duckdb/duckdb@3886b04f3bb381af7c0508f7bdfe4be6d866a391.

  Date: 2026-09-16 08:37:08 +0000

  Fix temp files size report (https://redirect.github.com/duckdb/duckdb/pull/25772)

  Unflavored-from: 4acedeab9cc45f15a13edce679f92017865f5fe9

- Update vendored sources to duckdb/duckdb@fd8b4fa58e45bdee730501989a30273350722347.

  Date: 2026-09-16 08:35:50 +0000

  Prune unused window outputs while preserving local volatile expressions (https://redirect.github.com/duckdb/duckdb/pull/25770)

  Unflavored-from: 398fb627af7ad20c2b63c817f647e138487fe691

- Update vendored sources to duckdb/duckdb@1e0f4f5fdcf052eeec02c7762d06921d4c99eace.

  Date: 2026-09-16 08:31:04 +0000

  Avoid one heap allocation on string decompression (https://redirect.github.com/duckdb/duckdb/pull/25769)

  Unflavored-from: d9f69e68658533ad5c340100424df0d0f801224f

- Update vendored sources to duckdb/duckdb@cdb0429ca6f4d8c01cf7d1a0b144cf3b95f01b46.

  Date: 2026-09-16 08:24:50 +0000

  Fix ALP compression incorrect stats persistence (https://redirect.github.com/duckdb/duckdb/pull/25765)
  Improve benchmark runner and CLI/extension binary sizes (https://redirect.github.com/duckdb/duckdb/pull/25779)

  Unflavored-from: 7d6cf0e3e1d7480c3492df9a170b54788838d0c9

- Update vendored sources to duckdb/duckdb@2e8afdb739a26c47a85ed38f423f459ab4d48911.

  Date: 2026-09-16 08:10:02 +0000

  Fix uint32_t blob offset overflow when casting oversized rows to VARIANT (https://redirect.github.com/duckdb/duckdb/pull/25181)

  Unflavored-from: 9d4b94c2c3f58f8caf2773b780daaa2f302ae8be

- Update vendored sources to duckdb/duckdb@60799c7eb5ce72e678ee09e4d6b53b6eeca3ecd6.

  Date: 2026-09-16 08:06:47 +0000

  Report INSERT source progress (https://redirect.github.com/duckdb/duckdb/pull/25753)
  Fix flaky test for encrypted temp file test (https://redirect.github.com/duckdb/duckdb/pull/25764)

  Unflavored-from: 9715ea32e200e7858e4b6fe56bf84f77553086fd

- Update vendored sources to duckdb/duckdb@c5445c6d858430a6e1fa8631b37c0891da78a5e7.

  Date: 2026-09-16 08:04:27 +0000

  Remove recursive matcher and old generated parser code (https://redirect.github.com/duckdb/duckdb/pull/25717)

  Unflavored-from: 8459de30175f0d4cdf705d93035cf159b1da1c2f

- Update vendored sources to duckdb/duckdb@48edc2adb83cadc84e1e52fc0e976f277f0c706f.

  Date: 2026-09-16 08:00:29 +0000

  Reduce stack usage in clustered aggregate (https://redirect.github.com/duckdb/duckdb/pull/25613)

  Unflavored-from: 40949236f43cbbe8db579df14cdb8ba34fdacbf1

- Update vendored sources to duckdb/duckdb@f05c6e5d9e89bf9f40f2959e8c70c1df927e3637.

  Date: 2026-09-16 07:56:17 +0000

  Propagate expression stats for all NULL constant row group (https://redirect.github.com/duckdb/duckdb/pull/25607)

  Unflavored-from: e8f952b4453b3616a4f82e2d81803c50e41fcdd5

- Update vendored sources to duckdb/duckdb@2ab56695598f6320b2254b0fc8ecf9fd76f6218f.

  Date: 2026-09-16 07:55:34 +0000

  Add warning for losing precision when casting `DECIMAL` for `VALUES` clause (https://redirect.github.com/duckdb/duckdb/pull/25692)

  Unflavored-from: 14a13938b95c0e4d6585a6e24e91d14fb097ae27

- Update vendored sources to duckdb/duckdb@de9bb21a23821f0b42531b065405005529f5ffbd.

  Date: 2026-09-16 07:54:27 +0000

  Fix RLE encoding for floating point values (https://redirect.github.com/duckdb/duckdb/pull/25709)
  Fix STRUCT-\>JSON parallel cast race condition (https://redirect.github.com/duckdb/duckdb/pull/25415) (https://redirect.github.com/duckdb/duckdb/pull/25722)

  Unflavored-from: 921c7694eacdfc0215abe8213a01b14c2ca8bf61

- Update vendored sources to duckdb/duckdb@5778929b968d80bd7f17b603a7efb938b24ab872.

  Date: 2026-09-16 07:53:21 +0000

  fix: ungrouped aggregate operand progress reporting (https://redirect.github.com/duckdb/duckdb/pull/25744)
  Unflavored-from: c3fa207a46fc3cbe61e9fa07c312a3c4b3cff7a1

- Update vendored sources to duckdb/duckdb@44926c2dcee4924c05cedd12c414d1df04cf3a50.

  Date: 2026-09-16 07:47:23 +0000

  Fix: Keep views working when their database is attached under a different alias (https://redirect.github.com/duckdb/duckdb/pull/25735)
  Internal https://redirect.github.com/duckdb/duckdb/pull/10791: v1.5.6 TimeZone 2026c (https://redirect.github.com/duckdb/duckdb/pull/25746)

  Unflavored-from: c86005f5302cd29266b9f932d787580f819349ed

- Update vendored sources to duckdb/duckdb@a836ab3860d1010f4727365cfe92bcce9931b272.

  Date: 2026-09-16 03:35:19 +0000

  Fix progress credit for materialized CTEs and completed hash joins (https://redirect.github.com/duckdb/duckdb/pull/25738)

  Unflavored-from: 76124e50ca240ac1b57f2dd032fa5c2e058c5bde

- Update vendored sources to duckdb/duckdb@02e71e5e97cad7d51518eb67b161a36204cb9ac5.

  Date: 2026-09-16 03:33:35 +0000

  Fix OOB read in SortedAggregateBindData reconstruction (https://redirect.github.com/duckdb/duckdb/pull/25281) (https://redirect.github.com/duckdb/duckdb/pull/25640)

  Unflavored-from: 7084cff1525e16677cc83ae7a2288e0b873cbf7b

- Update vendored sources to duckdb/duckdb@9fa260d417d7c3ee96363a340b129eceddb043b6.

  Date: 2026-09-16 01:36:29 +0000

  fix: Initialize Parquet reader progress counter to zero to improve progress reporting (https://redirect.github.com/duckdb/duckdb/pull/25734)
  Unflavored-from: 8c142b29701bfccf1f7f4abfd9c6d02d4b973618

- Update vendored sources to duckdb/duckdb@88d549313ff3e91e6ebfdd404c195f9b3bc89505.

  Date: 2026-09-15 22:16:37 +0000

  Utf8Proc: :Analyze: check 32 bytes per iteration while the input is ASCII (https://redirect.github.com/duckdb/duckdb/pull/25721)
  Unflavored-from: c82d5e9929a7591dafbe4953c548d274c1b1a6d1

- Update vendored sources to duckdb/duckdb@d45a40e27f43c45909f08ebc0f248b9c99ce0578.

  Date: 2026-09-15 17:12:39 +0000

  Fix dropped table storage leak (https://redirect.github.com/duckdb/duckdb/pull/25712)

  Unflavored-from: c08e868ffb9711cec014048d06908406ad90b0dc

- Update vendored sources to duckdb/duckdb@172d6d1fa4d840fa033c860e46fb094728f8dab5.

  Date: 2026-09-15 17:00:55 +0000

  Fix spilled temp block file report (https://redirect.github.com/duckdb/duckdb/pull/25605)

  Unflavored-from: d3ad98bfe97e9c8a63beee64215fc4a17609a41c

- Update vendored sources to duckdb/duckdb@bf3ff7014e20f7bff82548444b434685804385b6.

  Date: 2026-09-15 16:58:22 +0000

  Fix invalid memory access on optimistic write during scan (https://redirect.github.com/duckdb/duckdb/pull/25674)

  Unflavored-from: 0568719fa758796642ee27caa30ef49887af887b

- Update vendored sources to duckdb/duckdb@28d91e9331bb402286539b0bc253b91e3c8f5f87.

  Date: 2026-09-15 16:51:36 +0000

  Faster string_t optimized CompareInlineBytes (for stats writer) (https://redirect.github.com/duckdb/duckdb/pull/25715)

  Unflavored-from: 78deb0f1e99b00e73f4e94697f5b8f0d911060f7

- Update vendored sources to duckdb/duckdb@64394c4390ae8ebf5c7df6119e07e0ef7118ed72.

  Date: 2026-09-15 16:37:44 +0000

  Fix use-after-free when multiple filters are pushed into one scan (https://redirect.github.com/duckdb/duckdb/pull/25524)

  Unflavored-from: 362b59f51b3dd27624009aeee2b952a147c10bea

- Update vendored sources to duckdb/duckdb@9d1c184645b0ebeae6cff28421fd4985b7a3f3fc.

  Date: 2026-09-15 16:37:23 +0000

  convert recursion to stack-based transversal of variant to parquet (https://redirect.github.com/duckdb/duckdb/pull/24980)

  Unflavored-from: 6b89b0c0cab548b0c3c2e44d2511b23d8451cd37

- Update vendored sources to duckdb/duckdb@ad858523aeb0d916916b1757b70c8d25a960d4fa.

  Date: 2026-09-15 16:34:51 +0000

  Rename new division setting to `error_on_division_by_zero` (https://redirect.github.com/duckdb/duckdb/pull/25332)

  Unflavored-from: 5bafbb5afbb738b8937a80fbb17468c858452a91

- Update vendored sources to duckdb/duckdb@b1942a192b000eddcb4dc385e889647ef3f5275f.

  Date: 2026-09-15 16:25:53 +0000

  \[async results\] Add a unified QueryResult type (https://redirect.github.com/duckdb/duckdb/pull/25477)

  R-side fix

- Update vendored sources to duckdb/duckdb@3be6bed0cc1f6137de2451245285aa13d73b41ae.

  Date: 2026-09-15 11:04:34 +0000

  Fix cardinality for descending generate_series (https://redirect.github.com/duckdb/duckdb/pull/25691)

  Unflavored-from: 897b815debd553e8a12f47b5a2ebb059927fc5f6

- Update vendored sources to duckdb/duckdb@8eec2fe29c3b82cd2435a993285e2afff965d6c2.

  Date: 2026-09-15 11:01:11 +0000

  EXTERNAL RESOURCE: allow first class externally managed resources (SQL syntax on top of table functions) (https://redirect.github.com/duckdb/duckdb/pull/23736)

  Unflavored-from: 517a36aeb44b6207dee54e068cbcccc41df7afea

- Update vendored sources to duckdb/duckdb@899d90637abbf0657430d334bd3342b4e95cd354.

  Date: 2026-09-15 10:40:02 +0000

  Fix index block data loss on `VACUUM` (https://redirect.github.com/duckdb/duckdb/pull/25711)
  More Sqllogictest cleanup /2 (https://redirect.github.com/duckdb/duckdb/pull/25489)

  Unflavored-from: 98abf66b7618277d7fbb2cc209a5bcccec062979

- Update vendored sources to duckdb/duckdb@4b1dfb8453cf100bab85cf99a8486c7e8b72a38c.

  Date: 2026-09-15 08:26:51 +0000

  Fix MAX on hive partition column after file pruning (https://redirect.github.com/duckdb/duckdb/pull/25629) (https://redirect.github.com/duckdb/duckdb/pull/25690)

  Unflavored-from: 98e2c5825e20f040df5de89a6a953dddc3a84d73

- Update vendored sources to duckdb/duckdb@9deb5cececfca905228c82d79c3dded7ba6fce25.

  Date: 2026-09-15 06:59:33 +0000

  Repeat rows bug (https://redirect.github.com/duckdb/duckdb/pull/25696)

  Unflavored-from: aee4cac371d3ad16ac5c84747c4768ed0b831d75

- Update vendored sources to duckdb/duckdb@ef853aebf803cc4f7738ffc34859227f5ebb6437.

  Date: 2026-09-15 06:57:19 +0000

  Enable bugprone-exception-escape and run clang-tidy in NightlyTests (https://redirect.github.com/duckdb/duckdb/pull/25687)

  Unflavored-from: 6ab20f866e8da484bd4d9f4e64aa63665c0a1569

- Update vendored sources to duckdb/duckdb@38c5eebcb09d8d315fdd2875e778d710ebd5f9d1.

  Date: 2026-09-15 06:54:58 +0000

  Add sql tokenizer to C API (https://redirect.github.com/duckdb/duckdb/pull/25609)

  Unflavored-from: b604a4a57cecc07207a8c1aa74ef52eec9907896

- Update vendored sources to duckdb/duckdb@42a45ba315db0c5754745d27bb1039b994222b17.

  Date: 2026-09-15 06:53:42 +0000

  Preserve identifiers, CTE separators and VARIANT payloads in generated SQL (https://redirect.github.com/duckdb/duckdb/pull/25685)

  Unflavored-from: ff7f478934b2bf6656f14e5eeb281db0b0375538

- Update vendored sources to duckdb/duckdb@8065a54e5cea3cda21c8c6a4ef921bcdbc16dd9c.

  Date: 2026-09-15 06:53:32 +0000

  Parallelize invariant recursive builds with small frontiers (https://redirect.github.com/duckdb/duckdb/pull/25683)

  Unflavored-from: 789921a47d1d7e9ef14472a9a9b1f570765fd9ca

- Update vendored sources to duckdb/duckdb@196d6b552a5f1df70866498c590cccd9f881b156.

  Date: 2026-09-15 06:35:22 +0000

  fix: Preserve tags when copying index catalog entries (https://redirect.github.com/duckdb/duckdb/pull/25666)
  Unflavored-from: 02b5827dba0797ce3c0a16acb3e05940d19450e7

- Update vendored sources to duckdb/duckdb@26e02b8f8a7bc339a25494c3e8261b276d41fd98.

  Date: 2026-09-15 06:30:01 +0000

  Keep a block in the eviction queue when its spill to the temporary directory fails (https://redirect.github.com/duckdb/duckdb/pull/25688)
  Json strip nulls vuln (https://redirect.github.com/duckdb/duckdb/pull/25697)

  Unflavored-from: be5dc5eeede2d8c41e75d132a293f918db5c2fc7

- Update vendored sources to duckdb/duckdb@3e0f8b61a349f8d2d20fe95a375b0f94b978dcff.

  Date: 2026-09-14 19:00:17 +0000

  Fix integer truncation in ArgMinMaxValueAssign leading to heap buffer overflow (https://redirect.github.com/duckdb/duckdb/pull/25576) (https://redirect.github.com/duckdb/duckdb/pull/25662)

  Unflavored-from: 9f585c6ac5b11dadf9a70c73a2f0c9fb1d1cfd9e

- Update vendored sources to duckdb/duckdb@b5e62e55fcff2a9e3f1647a173fde8e274c6a97e.

  Date: 2026-09-14 18:27:50 +0000

  Bind planner and executor builtins through the catalog (https://redirect.github.com/duckdb/duckdb/pull/25602)

  Unflavored-from: f8c25aea8c536e904cdbdfe8e83908bbd8f20582

- Update vendored sources to duckdb/duckdb@30d1a49777e33d4aa0db10951a649fc345a71d5f.

  Date: 2026-09-14 14:42:45 +0000

  Support the euclidian operator `<->` (https://redirect.github.com/duckdb/duckdb/pull/25682)

  Unflavored-from: 9c0781490b2fc12ac544bf2e1256ccc1dcfe398d

- Update vendored sources to duckdb/duckdb@51c3bde5390293121d4397e380a53cf5114440b9.

  Date: 2026-09-14 11:41:46 +0000

  Fix DISTINCT column pruning state leaking into sibling inputs (https://redirect.github.com/duckdb/duckdb/pull/25675)

  Unflavored-from: 57ad86003b0f52e6f6b7f46374cbe5e1ca8255af

- Update vendored sources to duckdb/duckdb@b46bf95b25947adf7fb32d46b22305dccb81dd0a.

  Date: 2026-09-14 11:34:45 +0000

  Implement consistent `MoveFile` behavior for all platforms (https://redirect.github.com/duckdb/duckdb/pull/25608)

  Unflavored-from: 43a2e78ac5adbe2c998d40966a3516173ff89b66

- Update vendored sources to duckdb/duckdb@c23016872c0970d5bce226a19d2b1a86e7309b4d.

  Date: 2026-09-14 11:34:21 +0000

  Fix foreign key constraint violation error message (https://redirect.github.com/duckdb/duckdb/pull/25589)

  Unflavored-from: 2622678e6dc586888da875aa8c6f02d8cb837337

- Update vendored sources to duckdb/duckdb@d489b0203013c9bd7fbde640a68fefebeb27567a.

  Date: 2026-09-14 11:33:25 +0000

  patch debug and deprecated settings (https://redirect.github.com/duckdb/duckdb/pull/25526)

  Unflavored-from: 6b7e6f4b07713b9f8798f36bc9f3c23b0d0b1eec

- Update vendored sources to duckdb/duckdb@1968176af0699a1818340f7c13b0a585b29118d4.

  Date: 2026-09-14 10:59:17 +0000

  Skip parse/plan/optimize for Connection::BeginTransaction/Commit/Rollback (https://redirect.github.com/duckdb/duckdb/pull/25547)

  Unflavored-from: 77fd5931670524c943e356acb6b7a5b8d3f6c95f

- Update vendored sources to duckdb/duckdb@cdc9628ffa6273b5be4ac459935288669b0130b9.

  Date: 2026-09-14 10:58:02 +0000

  Fix missing encryption header size in temporary file manager (https://redirect.github.com/duckdb/duckdb/pull/25586)

  Unflavored-from: 3c0afb0fc148801f3d272c3a9b110e04135ae20d

- Update vendored sources to duckdb/duckdb@48dccd545853394703ef8f0959074fecf4e22315.

  Date: 2026-09-14 10:45:19 +0000

  Fix dangling pointer in RemoveUnusedColumns filter collection (https://redirect.github.com/duckdb/duckdb/pull/25430) (https://redirect.github.com/duckdb/duckdb/pull/25634)

  Unflavored-from: 4a1bd7e1e05baf5c5eb647a4c8ca032a7c3f6d58

- Update vendored sources to duckdb/duckdb@f22f55a29a08c3381e05c1805b3b2be0940eec8c.

  Date: 2026-09-14 10:43:58 +0000

  Improve exception message for cast failure (https://redirect.github.com/duckdb/duckdb/pull/25630)

  Unflavored-from: 04616ab785104b1b563092506cec903701ed5b19

- Update vendored sources to duckdb/duckdb@3ff20c3b174558fb09114eb6d0a7a3d98ed9f9d1.

  Date: 2026-09-14 10:39:22 +0000

  Improve exception message for unsupported seq rename (https://redirect.github.com/duckdb/duckdb/pull/25628)

  Unflavored-from: 6b680b0db6bdabffb8cd6561dc32b7bec3c4abe4

- Update vendored sources to duckdb/duckdb@36f46fd79819f5da5261a7c0d2f2f5365aedb791.

  Date: 2026-09-14 10:38:57 +0000

  Fix fetch row implementation for chimp compression (https://redirect.github.com/duckdb/duckdb/pull/25637)

  Unflavored-from: 01c1f66ef07c353e5887c89a631a7189956af0e7

- Update vendored sources to duckdb/duckdb@dee7ed975e641ac18b6311a6835e992505d71734.

  Date: 2026-09-14 10:38:23 +0000

  Fix `USING COMPRESSION` for `ALTER TABLR ADD COLUMN` (https://redirect.github.com/duckdb/duckdb/pull/25678)

  Unflavored-from: ce20247b0e08c7883239ded6f2d781ded90b5d08

- Update vendored sources to duckdb/duckdb@bc56d1562290d114bd204f8cdc3e21247a72c0aa.

  Date: 2026-09-14 09:18:28 +0000

  fix(capi): handle dictionary columns across Arrow importer chunks (https://redirect.github.com/duckdb/duckdb/pull/25619)
  Format the main CMakeLists.txt through the standard channel (https://redirect.github.com/duckdb/duckdb/pull/25645)

  Unflavored-from: 3fe8e4c301cd02a865d415cd1946d763d678aace

- Update vendored sources to duckdb/duckdb@9acc8d90ba7873123b17d953a14cb25582465125.

  Date: 2026-09-14 09:08:38 +0000

  Fix header handling in CSV minimal sniff (https://redirect.github.com/duckdb/duckdb/pull/25638)

  Unflavored-from: 8bb154eb948308359fbc89031eef878e8036cf99

- Update vendored sources to duckdb/duckdb@192cc1670e6b7bda27ee4eb875cebb3fea9e6a28.

  Date: 2026-09-14 09:07:28 +0000

  Fix filter pushdown for table in-out functions (https://redirect.github.com/duckdb/duckdb/pull/25650)

  Unflavored-from: 376d2ccc12e2a50dcdf1185ffb249d913108f8d8

- Update vendored sources to duckdb/duckdb@d82ddd80820f2bf4653e65caaa47cebc090f1469.

  Date: 2026-09-14 09:05:43 +0000

  Reduce one access syscall on local filesystem (https://redirect.github.com/duckdb/duckdb/pull/25653)

  Unflavored-from: 4a486cea3aac4a161d1418239a07a7bf7b9c8854

- Update vendored sources to duckdb/duckdb@fb7a5fb749a6dac0fc3cb3f76c08c4ec41358223.

  Date: 2026-09-14 09:01:16 +0000

  Use checkpoint's transaction to bind indexes (https://redirect.github.com/duckdb/duckdb/pull/25660)
  Add parser microbenchmarks (https://redirect.github.com/duckdb/duckdb/pull/25617)

  Unflavored-from: 6582e1b027c3abca5883d4d0feb666554e0f9207

- Update vendored sources to duckdb/duckdb@2284ca3c9087baf5e0a6e37b4f4d7fe4b3cdb7c2.

  Date: 2026-09-14 09:00:06 +0000

  Fix variant stats merge (https://redirect.github.com/duckdb/duckdb/pull/25659)

  Unflavored-from: 1857210e8e3659346ae52f17c3f9c54eefdd1aec

- Update vendored sources to duckdb/duckdb@ead2df641ce60cfce32f4903a98a7f59c4491e1f.

  Date: 2026-09-14 08:55:22 +0000

  Fix temporary file spill (https://redirect.github.com/duckdb/duckdb/pull/25672)

  Unflavored-from: 320aa297a93e52b01bf5bdb56447eec7ddb61681

- Update vendored sources to duckdb/duckdb@c3a85939a4b9c65704e0866bd052701c1b77b30a.

  Date: 2026-09-14 08:54:33 +0000

  Fix filter pushdown through projections before delim CTE conversion (https://redirect.github.com/duckdb/duckdb/pull/25676)

  Unflavored-from: 6f585fad88a9dfff51f9f07c785e43cd576887be

- Update vendored sources to duckdb/duckdb@25f29f229d2323a5457a80e848c76ea6060ffba7.

  Date: 2026-09-14 08:52:57 +0000

  Do not traverse window and aggregate children twice in filter pushdown (https://redirect.github.com/duckdb/duckdb/pull/25673)

  Unflavored-from: 3d387865cf73f3ba7c927b9952ba0787e77552be

- Update vendored sources to duckdb/duckdb@7f7d8d165852803747aaa4808742ee3c5c10f885.

  Date: 2026-09-14 08:20:17 +0000

  \[Parser\] Add `DialectExtension` extension API (https://redirect.github.com/duckdb/duckdb/pull/25508)

  Unflavored-from: 64ec2c23066d2f3cf00f89bbd7eb3a96d7c8ac54

- Update vendored sources to duckdb/duckdb@436820e4ffb5c6aa021d8c1a823ca8a0fbc02e24.

  Date: 2026-09-14 08:14:59 +0000

  TaskExecution API improvements, fixing up some users (https://redirect.github.com/duckdb/duckdb/pull/25644)

  Unflavored-from: f2862a0aea52100fba8153916e5ffb4c108bac39

- Update vendored sources to duckdb/duckdb@e86fafc5f5be157d8301a57e608d73c4d199da41.

  Date: 2026-09-14 08:10:58 +0000

  CopyToFile/1: Count a partitioned COPY local into its sink state under the global lock (https://redirect.github.com/duckdb/duckdb/pull/25641)

  Unflavored-from: 08c393e51ab47ed5d80e4afdc05d0763848ff96e

- Update vendored sources to duckdb/duckdb@7e2461558bd507167d42ad61756b95ed1c78f333.

  Date: 2026-09-14 08:10:35 +0000

  CopyToFile/2: Remove the partitioned COPY straggler guard that could never fire (https://redirect.github.com/duckdb/duckdb/pull/25642)

  Unflavored-from: 32e332ad8a36bc34e2ba6cfd9ccf253d8e393d36

- Update vendored sources to duckdb/duckdb@ce55cc7a074b6f6c22e7afcc49a586523bdcbeb4.

  Date: 2026-09-14 08:09:45 +0000

  CopyToFile/3: Check that a partitioned COPY state is finalized once and never blocks (https://redirect.github.com/duckdb/duckdb/pull/25643)

  Unflavored-from: 946687cc3c65ad5fed99249a35444e94f19c7e5c

- Update vendored sources to duckdb/duckdb@d673cf9ab4b08a06162e0af8667a42442c345c6d.

  Date: 2026-09-14 08:09:28 +0000

  Fix temp file deadloop (https://redirect.github.com/duckdb/duckdb/pull/25627)

  Unflavored-from: b4566cb0582b9371c91515be2f6cd72b29741dc0

- Update vendored sources to duckdb/duckdb@09ba309740c759c7138be2a01095c4ebaaa6ebdf.

  Date: 2026-09-14 08:09:13 +0000

  Fix non standard vector size CI run (https://redirect.github.com/duckdb/duckdb/pull/25677)

  Unflavored-from: d9fb35ebd7f11574c6aa0c69a2d21c70f68bb628

- Update vendored sources to duckdb/duckdb@9ad9489dfaa14ef4ccc833478a01398942e3d34c.

  Date: 2026-09-14 06:34:44 +0000

  Add parse-time statement metadata (https://redirect.github.com/duckdb/duckdb/pull/25612)

  Unflavored-from: 29285da6f226c7d1957152e20edae94b9c335ffc

- Update vendored sources to duckdb/duckdb@714b5904e607eecf40ce5abcc21e308c34ad4142.

  Date: 2026-09-14 06:12:50 +0000

  Bump extensions, on top of https://redirect.github.com/duckdb/duckdb/pull/25610 (https://redirect.github.com/duckdb/duckdb/pull/25625)

  Unflavored-from: cecfd5de01b0f217c19f61331c63c1fcacef3fba

- Update vendored sources to duckdb/duckdb@adc85ffff9ba08866d3928bb055ac509578d6ebf.

  Date: 2026-09-14 06:12:20 +0000

  Let's not do UB within StringUtil::TryParseFormattedBytes (https://redirect.github.com/duckdb/duckdb/pull/25614)

  Unflavored-from: 174fa8fa49a20497892b4c70109075910c3ebac9

- Update vendored sources to duckdb/duckdb@376bc5b58d837e862dd7abfe9b296c391faca0bb.

  Date: 2026-09-14 05:46:42 +0000

  C API V1: mark extension scalar functions as fallible by default (https://redirect.github.com/duckdb/duckdb/pull/25664)

  Unflavored-from: 7676d29fd07993e703f89b28aa4736e2785c7b7b

- Update vendored sources to duckdb/duckdb@9ec1c819b51694e8ac61fe887a762f37f6864e91.

  Date: 2026-09-14 05:43:37 +0000

  Name function params v2 (https://redirect.github.com/duckdb/duckdb/pull/25572)

  Unflavored-from: eb4817d0a930aeb6946330a1c91e7a42895b63a8

- Update vendored sources to duckdb/duckdb@10de9573794001c649621013bdd93553b54e00c9.

  Date: 2026-09-11 19:14:29 +0000

  Simplify filters when entire enum domain is present in IN clause (https://redirect.github.com/duckdb/duckdb/pull/24706)

  Unflavored-from: dc4687be2726c3b72a6b89915c26d3fcea188c80

- Update vendored sources to duckdb/duckdb@70e7a857595b5872842b6ec242ac79c182e58dde.

  Date: 2026-09-11 11:47:50 +0000

  Keep variable-size projections below joins (https://redirect.github.com/duckdb/duckdb/pull/24914)

  Unflavored-from: ba0696a56087cab805bcb88eb1876e635e647933

- Update vendored sources to duckdb/duckdb@5e9508026e1bbbd28f25863c33cfb03500063f81.

  Date: 2026-09-11 11:25:14 +0000

  Add structural SQL export for bound expressions (https://redirect.github.com/duckdb/duckdb/pull/25260)

  Unflavored-from: d91f969c91b4632e9dd7d4fc59e7cedae033e9ec

- Update vendored sources to duckdb/duckdb@b0902cf85e66858edff0616595c43625528755e9.

  Date: 2026-09-11 11:05:12 +0000

  Fix validity mask bounds during append rollback (https://redirect.github.com/duckdb/duckdb/pull/25505)

  Unflavored-from: e9ad87a0dc2693458a7239d91ba5d674b23ac70b

- Update vendored sources to duckdb/duckdb@fc4002c6e36f1e2d17d7c5b1a604777d69238d2b.

  Date: 2026-09-11 11:04:15 +0000

  Fix correlated CTE reference bindings by column identity (https://redirect.github.com/duckdb/duckdb/pull/25558)

  Unflavored-from: 58aa955b3e8789f254c0609ed4509de01481e9a7

- Update vendored sources to duckdb/duckdb@b325f89971f1fd64fc8551f7baece71ff28b16cb.

  Date: 2026-09-11 11:00:20 +0000

  Generalize multi-column expression pruning (https://redirect.github.com/duckdb/duckdb/pull/25294)

  Unflavored-from: e6946577994d301a77ee9542cdbd61299844a831

- Update vendored sources to duckdb/duckdb@88902aaa3972216c928c8e79a89217a413be414c.

  Date: 2026-09-11 09:17:24 +0000

  Propagate expression stats for constant row group (https://redirect.github.com/duckdb/duckdb/pull/25591)

  Unflavored-from: 7d1a71ba25668735decadde0d390ac33d3a3cd3f

- Update vendored sources to duckdb/duckdb@d41e527b18f0ec8180d03a304683be3d2ca5da29.

  Date: 2026-09-11 08:49:17 +0000

  Fix variant validity (https://redirect.github.com/duckdb/duckdb/pull/25594)

  Unflavored-from: 5fb1a534793ed14cea0ad1ac9be73069fc21fc6a

- Update vendored sources to duckdb/duckdb@0c3f3b8e7a39414be5dabee2f94952e22a82b64f.

  Date: 2026-09-11 08:19:08 +0000

  Fix column pruning of sibling inputs beside materialized CTEs (https://redirect.github.com/duckdb/duckdb/pull/25561)
  Cleanup deprecated loop iterator (https://redirect.github.com/duckdb/duckdb/pull/25584)

  Unflavored-from: d64b83144410ff7387e1af2619019b7e0408e17c

- Update vendored sources to duckdb/duckdb@20ba427580e4217efae2c5a03a4755c48c353c56.

  Date: 2026-09-11 08:06:09 +0000

  Fix async readahead deadlock in parquet multi file scan (https://redirect.github.com/duckdb/duckdb/pull/25600)

  Unflavored-from: 1fa6f7ff2de0da8a52936f9f76c91ca010cbc630

- Update vendored sources to duckdb/duckdb@f2eede3f7ec968d67bece08bb9ba4752f5e6dd51.

  Date: 2026-09-11 08:03:26 +0000

  Drain pending tasks in the TaskExecutor destructor (https://redirect.github.com/duckdb/duckdb/pull/25557)
  Fix outdated paths in AGENTS.md (https://redirect.github.com/duckdb/duckdb/pull/25598)

  Unflavored-from: 7e6a0e097fbdd0c92b6a5176d4c922158775476d

- Update vendored sources to duckdb/duckdb@f60316b6abfd9074f553e9e880b85171c747f867.

  Date: 2026-09-10 20:47:15 +0000

  Set unary arg property for last_day function (https://redirect.github.com/duckdb/duckdb/pull/25492)

  Unflavored-from: ac3a31330fffe018c921fb9c84b42f046ffd1877

- Update vendored sources to duckdb/duckdb@39ec07729f71f907887f86f479ebe26a85972509.

  Date: 2026-09-10 15:59:44 +0000

  \[2.0\] Report the real storage version when opening a v2.0+ database file (https://redirect.github.com/duckdb/duckdb/pull/25574)

  Unflavored-from: 1af1f7e042481df0d48ef169ee948a64aafa5494

- Update vendored sources to duckdb/duckdb@673b4d9d548485b43aecb94976a40153cceb8232.

  Date: 2026-09-10 15:35:47 +0000

  Bound the unselected prefix range key lookup by the filter count (https://redirect.github.com/duckdb/duckdb/pull/25378)

  Unflavored-from: bf3957d6d8ae703fe43a4a4404d70db23331aa5e

- Update vendored sources to duckdb/duckdb@4765395f683111f66e0e3e50d0547ec33be18bf3.

  Date: 2026-09-10 15:22:46 +0000

  Fix row_number gaps in vector-sized parallel scans (https://redirect.github.com/duckdb/duckdb/pull/25555)

  Unflavored-from: 4abd6f635a8b2e5d1318ef5129ee974b5e854aa6

- Update vendored sources to duckdb/duckdb@494f5c6c03e390d14caa5ac8114f7831edb03916.

  Date: 2026-09-10 15:14:01 +0000

  Initial implementation of `variant_group_object` processing function (https://redirect.github.com/duckdb/duckdb/pull/25049)

  Unflavored-from: 341f48b1fd98c2572ad0fcc615bd4d60e73e41cb

- Update vendored sources to duckdb/duckdb@81bc275dd617edf26d402d712859c5ccd9884e04.

  Date: 2026-09-10 13:53:55 +0000

  Make float or double depending on precision (https://redirect.github.com/duckdb/duckdb/pull/25523)

  Unflavored-from: 56e0ce32e1d1b9c1e538810d7d789e22a5d28fd7

- Update vendored sources to duckdb/duckdb@6faa4bb1671f7916ff668ba95f7b5a8505467d0e.

  Date: 2026-09-10 13:18:59 +0000

  Bind optimizer-introduced builtins through the catalog (https://redirect.github.com/duckdb/duckdb/pull/25472)

  Unflavored-from: 6732ab9b8d7c2d60910bbc254f7b8f7dd08daa85

- Update vendored sources to duckdb/duckdb@aa072baf0d993f29d273b95bdc3dc7da8171311b.

  Date: 2026-09-10 12:35:56 +0000

  Fix integer overflow in suffix() for 2GB+ suffixes (https://redirect.github.com/duckdb/duckdb/pull/25534)

  Unflavored-from: 54100defc82eaf3506db7af407d60aa918cc8d2b

- Update vendored sources to duckdb/duckdb@0c59dbb0109c5d81e3ae12642f0600fa934304fa.

  Date: 2026-09-10 12:23:39 +0000

  Improved caching behavior in MAD (https://redirect.github.com/duckdb/duckdb/pull/25484)

  Unflavored-from: 74f0a4072500fc902a1dae9d28458baec73dba30

- Update vendored sources to duckdb/duckdb@ed8592347a1bdf90c7074c810d8dc6e052171a3e.

  Date: 2026-09-10 12:17:07 +0000

  Improve exception message (https://redirect.github.com/duckdb/duckdb/pull/25563)

  Unflavored-from: 025c9f91c81cd2baf126cc7fc2329d977bd4319f

- Update vendored sources to duckdb/duckdb@3631aeb23a27a1da9de57f06ff142be9e2d13dda.

  Date: 2026-09-10 12:16:44 +0000

  Specify node256 leaf method as `const` (https://redirect.github.com/duckdb/duckdb/pull/25566)

  Unflavored-from: 8b8aff5796e965eac271feed329502fd570acc64

- Update vendored sources to duckdb/duckdb@351b4669209916fbe0095541942ddac6bf19bcff.

  Date: 2026-09-10 12:16:03 +0000

  Address a few compilation warnings (https://redirect.github.com/duckdb/duckdb/pull/25562)

  Unflavored-from: c302bf5804d11a7288b978e1d4a4a72f8fc6df62

- Update vendored sources to duckdb/duckdb@ddb3a18f017d7eebec6ce2e73ef3861f4f99f4d2.

  Date: 2026-09-10 12:15:39 +0000

  Fix external file cache spill (https://redirect.github.com/duckdb/duckdb/pull/25551)

  Unflavored-from: ca16769df27926b76bb6bf3e2248efa37fef10d0

- Update vendored sources to duckdb/duckdb@eeedb176e8cc2eea048ff1d74046686c9f7aa911.

  Date: 2026-09-10 12:15:00 +0000

  Prune boolean function filters with statistics (https://redirect.github.com/duckdb/duckdb/pull/25550)

  Unflavored-from: c97b9fdf50efca9467214d53b0ec660e6951b192

- Update vendored sources to duckdb/duckdb@0691eeb9d699640f272ab4e52a7aaf2ec8afe85c.

  Date: 2026-09-10 12:11:16 +0000

  Support triggers on custom table catalog entries (https://redirect.github.com/duckdb/duckdb/pull/25539)

  Unflavored-from: a02b1aed56662835000c1700ab9a7332a1500a9a

- Update vendored sources to duckdb/duckdb@758b9254d86eefe6c7ea3ba23527b3ffeb2ccdcc.

  Date: 2026-09-10 12:09:59 +0000

  Fix WAL replay crash for failed table rename (https://redirect.github.com/duckdb/duckdb/pull/25549)

  Unflavored-from: 1c79f6ae3a1dd714833ced52fbd48762fa39b6f6

- Update vendored sources to duckdb/duckdb@bd4ca57b660677febe62f0a133a80adff8a52a83.

  Date: 2026-09-10 12:02:34 +0000

  Prune row group for contains on inexact stats (https://redirect.github.com/duckdb/duckdb/pull/25538)
  Create isolated directories for compared versions in test_runner.py (https://redirect.github.com/duckdb/duckdb/pull/25469)

  Unflavored-from: d50b87735fc2ab2a97284c94f7b651039fb00fab

- Update vendored sources to duckdb/duckdb@2036aef4ea18641eec5baa97983905aeff9e57b0.

  Date: 2026-09-10 11:51:58 +0000

  Run CSV Byte skipping over 64 bytes (https://redirect.github.com/duckdb/duckdb/pull/25425)

  Unflavored-from: 4165e458f008fbcc398a5ef6f7d1e919bd3203ff

- Update vendored sources to duckdb/duckdb@25e1a71fb216b92d0e92a28de16423aefafd0f51.

  Date: 2026-09-10 11:51:08 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/25476: Nanosecond TIMEZONE (https://redirect.github.com/duckdb/duckdb/pull/25483)

  Unflavored-from: ce37b51328ad7762eba267891cbffbbd995e0a90

- Update vendored sources to duckdb/duckdb@be79c10546622c03b9e5035666a0681731ce458b.

  Date: 2026-09-10 11:47:36 +0000

  \[Dev\] annotated `IndexLock` (https://redirect.github.com/duckdb/duckdb/pull/25518)
  Merge extensions into main workflow, fix versioning and skip some tests (https://redirect.github.com/duckdb/duckdb/pull/25568)

  Unflavored-from: 03de7f230a25e66e92eb81fa2fbc9852a023a68b

- Update vendored sources to duckdb/duckdb@08f1df68944e8ad8f1a8134d8857b43030a75ae8.

  Date: 2026-09-10 11:43:29 +0000

  \[ART\] Fix oversized Node256Leaf validity mask allocation (https://redirect.github.com/duckdb/duckdb/pull/25459)

  Unflavored-from: b6f089e50f7905676bcb01f1e25eb3155ede9cfa

- Update vendored sources to duckdb/duckdb@5d301b9da69e73b568413908d20b1f0e77e81524.

  Date: 2026-09-10 11:32:12 +0000

  Seven independent fixes (https://redirect.github.com/duckdb/duckdb/pull/25552)

  Unflavored-from: e1d30b0d443de7768c4f6cb800ed350d7d49d705

- Update vendored sources to duckdb/duckdb@a56c4229affdefb768a45e2c9cddb62646ca4f74.

  Date: 2026-09-10 09:31:04 +0000

  Fix dangling CTE scope reference in the PEG transformer (https://redirect.github.com/duckdb/duckdb/pull/25190)

  Unflavored-from: 6140dcf0fa63e6a5ca680174113b3dc1ec85be93

- Update vendored sources to duckdb/duckdb@44d8772ee12a71c40d2bc18a925c1cbfc07c7d01.

  Date: 2026-09-10 07:50:54 +0000

  Replace `Value` with new `Literal` class in `ConstantExpression` (https://redirect.github.com/duckdb/duckdb/pull/25473)

  R-side fix

- Update vendored sources to duckdb/duckdb@7b76e0f91a15e776148c44f94b9d7b4eeb26f3a0.

  Date: 2026-09-10 07:40:20 +0000

  Fix BETWEEN to follow SQL three-valued logic for NULL bounds (https://redirect.github.com/duckdb/duckdb/pull/25394)

  Unflavored-from: 86acc7d6829533cd4b0ff51f9739498041da98d4

- Update vendored sources to duckdb/duckdb@28e82efa666ec9aa1867999cc2cc1ab6e5ef52d3.

  Date: 2026-09-10 07:32:10 +0000

  Merge `variegata` into `cyanoptera` (https://redirect.github.com/duckdb/duckdb/pull/25541)

  Unflavored-from: 1b3063a496ec283935786220ee9d9dd43c403f12

- Update vendored sources to duckdb/duckdb@f2895015f7041a3830cd793d3d212e9549f50624.

  Date: 2026-09-10 07:31:48 +0000

  Move more includes from src/include to cpp files (https://redirect.github.com/duckdb/duckdb/pull/25485)
  Store latest alpha version of a commit in duckdb-staging (https://redirect.github.com/duckdb/duckdb/pull/25516)

  Unflavored-from: fea7f29ebd31d627cf6c48704e36d7cd6a14200b

- Update vendored sources to duckdb/duckdb@4e94455c4f5eb6c9a9b7ed800d88ad2515d72eb8.

  Date: 2026-09-10 07:20:23 +0000

  Generate stable transform result type names without RTTI (https://redirect.github.com/duckdb/duckdb/pull/25513)

  Unflavored-from: 78fe5789065f25730154bad2b07db7aa21a36c97

- Update vendored sources to duckdb/duckdb@668f94740b280bf44c7c081df664ae1eb310c090.

  Date: 2026-09-10 00:30:29 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/24307: Negative PRECEDING FOLLOWING (https://redirect.github.com/duckdb/duckdb/pull/25446)

  Unflavored-from: 2fd9d76e53622d1fad688c1633293fc95096e957

- Update vendored sources to duckdb/duckdb@5bc472154d1bf38a5acea8423a96d95d5c7ed8d4.

  Date: 2026-09-09 23:49:14 +0000

  Flush blockallocator when TaskScheduler gets destroyed (https://redirect.github.com/duckdb/duckdb/pull/25522)

  Unflavored-from: c2cad1aab6d07f943fac8d77b58862b16ae8f8d1

- Update vendored sources to duckdb/duckdb@cc7e7bac7fcb6e0994359965a87ac4f6a96f2e17.

  Date: 2026-09-09 23:48:30 +0000

  Register 'if' as catalog macro (https://redirect.github.com/duckdb/duckdb/pull/24633) (https://redirect.github.com/duckdb/duckdb/pull/25514)

  Unflavored-from: 1dbe5697b51e059e569e95368c7d4299ac95f9f3

- Update vendored sources to duckdb/duckdb@516be109ab65ebb828b38aa851fe36727a22364a.

  Date: 2026-09-09 22:29:10 +0000

  feat: Add duckdb_secret_type_parameters system view (https://redirect.github.com/duckdb/duckdb/pull/22564)

  R-side fix

- Update vendored sources to duckdb/duckdb@4d53565b0bac4f32c951ac3fc3b51a31f8b158ce.

  Date: 2026-09-09 18:51:29 +0000

  Add `TableFunctionMultiFileWrapper` which allows a single-file-read table function to become a multi-file-read function, and migrate `read_json` to it (https://redirect.github.com/duckdb/duckdb/pull/25471)

  Unflavored-from: 649d14f24591f02d79727a67f6029c7fe2a5fbeb

- Update vendored sources to duckdb/duckdb@6ee2305dc786e2429c85eb971f8854f5a9807149.

  Date: 2026-09-09 18:48:52 +0000

  \[ASYNC-IO\] Read-Ahead for DuckDB Tables (https://redirect.github.com/duckdb/duckdb/pull/25095)

  Unflavored-from: abc885f07698db8004d6c5636302b8625d2421f2

- Update vendored sources to duckdb/duckdb@d284e73077242e64c235c5cbd90028422460193b.

  Date: 2026-09-09 16:00:27 +0000

  Fix assertion failure for non-overwriting existing parquet directory (https://redirect.github.com/duckdb/duckdb/pull/25498)

  Unflavored-from: 3e013eb67e09db45ce24d2d183baab9bb8d0ce88

- Update vendored sources to duckdb/duckdb@6125e6bc3d1f712c6540f23792b393f5248f2c4b.

  Date: 2026-09-09 15:39:25 +0000

  Fix wal replay (https://redirect.github.com/duckdb/duckdb/pull/25511)

  Unflavored-from: cca9a3d32476ecd8e78691dcfcab40bdcf1170a0

- Update vendored sources to duckdb/duckdb@68a4dd9782218332a1d8f5d35b2193a317dc2ac7.

  Date: 2026-09-09 11:45:24 +0000

  Fix cache freshness exclusiveness (https://redirect.github.com/duckdb/duckdb/pull/25195)

  Unflavored-from: b75e191a7f40f74048f38a8fc60b0c20bf426456

- Update vendored sources to duckdb/duckdb@881c8fe2c70ca17a22d755025e885e5114f7b11e.

  Date: 2026-09-09 11:30:25 +0000

  Fix out-of-bounds write in TRY per-row retry (https://redirect.github.com/duckdb/duckdb/pull/25481)

  Unflavored-from: 2144b30f2aed87e0607315eb724655721b7be059

- Update vendored sources to duckdb/duckdb@254bf53d277ee815dcaa40dd04999b087b8f6e84.

  Date: 2026-09-09 11:12:38 +0000

  Compare nested children with distinct semantics for = and \<\> (https://redirect.github.com/duckdb/duckdb/pull/25495)

  Unflavored-from: 6c7f9ab17f5016b50f2d02303c82824bd732f7e3

- Update vendored sources to duckdb/duckdb@858a8dcd8a45779b577fbfe571a47a2272b5a6ed.

  Date: 2026-09-09 11:03:00 +0000

  Prevent out-of-bounds check for empty map in `PIVOT` (https://redirect.github.com/duckdb/duckdb/pull/25475)

  Unflavored-from: a3533d0680a42c9917a0f6cd0ba1f74ec89176dd

- Update vendored sources to duckdb/duckdb@513302aa8029d328e76eb4a2c59b89d2d6ee9d96.

  Date: 2026-09-09 10:48:41 +0000

  Fix foreign key SQL (https://redirect.github.com/duckdb/duckdb/pull/25500)

  Unflavored-from: 1dc701e21041d01859d77473cfcdf418c93541fa

- Update vendored sources to duckdb/duckdb@bfc125e6c0c2ff1019032e04e1634aacdfed8bb6.

  Date: 2026-09-09 10:23:46 +0000

  Simplify boolean comparisons with FALSE (https://redirect.github.com/duckdb/duckdb/pull/25493)

  Unflavored-from: 41aedadcc43055afcc4d2258bbf4b0d6889ebd3a

- Update vendored sources to duckdb/duckdb@d00613000e553ea0f15d4ed1c15cf2e36187a85c.

  Date: 2026-09-09 10:23:40 +0000

  Specify unary arg property for round_even function (https://redirect.github.com/duckdb/duckdb/pull/25491)

  Unflavored-from: 702d539940e809b46c02ee309513039a65ca1759

- Update vendored sources to duckdb/duckdb@3579aad362c37d38b649f8e8b0174514207e8f99.

  Date: 2026-09-09 10:23:38 +0000

  Fix row-group pruning for string NOT IN predicates (https://redirect.github.com/duckdb/duckdb/pull/25486)

  Unflavored-from: 88b58f1ff8c97e5987daa006d2f5346b2f187eb2

- Update vendored sources to duckdb/duckdb@7074015a34d7b487c04173ad9ba9576f0b15b5b7.

  Date: 2026-09-09 10:23:35 +0000

  Fix primary key accepting transaction-local NULL (https://redirect.github.com/duckdb/duckdb/pull/25468)

  Unflavored-from: cd268ab257127f18e943c1c2b9bb0e257c2c978b

- Update vendored sources to duckdb/duckdb@a0315f712c64627fde0f77879730f28a4e9c8c46.

  Date: 2026-09-09 10:23:15 +0000

  Fix ALTER TABLE ALTER column USING NULL (https://redirect.github.com/duckdb/duckdb/pull/25413)
  Test GCC 11 compatibility in a PR CI run (https://redirect.github.com/duckdb/duckdb/pull/25506)

  Unflavored-from: 4ede0e72abde0579df0192c8f4064c597c567cc0

- Update vendored sources to duckdb/duckdb@bd77495e4b98772224948c57320bc1aa25ad9bfc.

  Date: 2026-09-09 10:22:52 +0000

  Fix ALTER TABLE ADD COLUMN with NOT NULL constraint (https://redirect.github.com/duckdb/duckdb/pull/25411)

  Unflavored-from: db0d196104e488548dff59c23f0aaac690213940

- Update vendored sources to duckdb/duckdb@c330d4e580ae39294411745775712abb8926a46c.

  Date: 2026-09-09 10:22:42 +0000

  Fix Top-N window elimination binding regressions (https://redirect.github.com/duckdb/duckdb/pull/25267)
  Use ninja 1.13 to fix CI, and show (alpha) version in CI run name (https://redirect.github.com/duckdb/duckdb/pull/25504)

  Unflavored-from: 57b3a15d61102d9917084f7567ce3cb0e8de6470

- Update vendored sources to duckdb/duckdb@cacd0f22b3d3c4b3dbe698ba83c0dff6e0f2f879.

  Date: 2026-09-09 11:27:11 +0200

  `HTTPRetryState` (https://redirect.github.com/duckdb/duckdb/pull/25507)

  Unflavored-from: 9c6afad6c19a7936cb8ff7b94e0dc050795c8be3

- Update vendored sources to duckdb/duckdb@e38958eb19dab6c7fe11f51c447f909b27082a1c.

  Date: 2026-09-09 08:06:27 +0000

  Reuse `MatcherProcess` with `ArenaAllocator` (https://redirect.github.com/duckdb/duckdb/pull/25437)

  Unflavored-from: 2b528b2e6e7f3d23e62770b8af5e527ecb8cf497

- Update vendored sources to duckdb/duckdb@43f897e5f3446bde2b36cef5dc137eea14211fd9.

  Date: 2026-09-08 20:30:23 +0000

  Prune row group for `map_contains_value` (https://redirect.github.com/duckdb/duckdb/pull/25234)

  Unflavored-from: f78a20aabd8fef52e68d02691fc5405ac4f2652f

- Update vendored sources to duckdb/duckdb@f75bf764116781575b7b50989b71b7d48b0399af.

  Date: 2026-09-08 19:27:25 +0000

  Add support for directly pushing OpenFileInfo into the MultiFileReader list from SQL (https://redirect.github.com/duckdb/duckdb/pull/25436)

  Unflavored-from: f1f93a4affbaa770a947131ac797973241306a6a

- Update vendored sources to duckdb/duckdb@ddeb97618a192418b883d3eff7772d90e651903e.

  Date: 2026-09-08 19:25:58 +0000

  Make setting aliases work by name instead of by index to avoid unnecessary merge conflicts when changing settings (https://redirect.github.com/duckdb/duckdb/pull/25466)

  Unflavored-from: 2c5a4b4edd6be1deac8a79af96e08bdfda2fc1b2

- Update vendored sources to duckdb/duckdb@52f06e072a084ff86d601b53087086d0a8e9cdd6.

  Date: 2026-09-08 19:21:18 +0000

  Enable filter pushdown into secure views (https://redirect.github.com/duckdb/duckdb/pull/25462)

  Unflavored-from: 726166f5e0eba7b051dba063b10d7ef50492ba89

- Update vendored sources to duckdb/duckdb@12246a539a6703dfe52b42216a75156ef7bd886e.

  Date: 2026-09-08 18:31:44 +0000

  Error on byte mismatch when writing to local file system (https://redirect.github.com/duckdb/duckdb/pull/25465)

  Unflavored-from: e5d73201a4e781eeabc95acb452caa76707f4da1

- Update vendored sources to duckdb/duckdb@6d1282a5fb69b600a1b87e9afe786398bf2ae706.

  Date: 2026-09-08 16:13:33 +0000

  Fix WAL replay on logical/physical id misuse (https://redirect.github.com/duckdb/duckdb/pull/25455)

  Unflavored-from: c9497bffd16b8357e4d715af1b2895d5d0fcbad2

- Update vendored sources to duckdb/duckdb@f2f8a3d474bd51f99ef849267b15ab23621489d2.

  Date: 2026-09-08 15:20:27 +0000

  Hardening `HTTPTransportManager`: make proxy part of key (https://redirect.github.com/duckdb/duckdb/pull/25463)

  Unflavored-from: 3ce759b31252e204cbe4d9e3f9248156c967f249

- Update vendored sources to duckdb/duckdb@d408d4ce13b43ef7e65c018398f0fa7a5842364f.

  Date: 2026-09-08 13:48:27 +0000

  Fix missing includes for non-unity build (https://redirect.github.com/duckdb/duckdb/pull/25435)

  Unflavored-from: 3ff1724cb25acf4d14d917c2bed66f35b31aed20

- Update vendored sources to duckdb/duckdb@0ea54858e1a6d456a3fc68e0c295c0e74547e8bc.

  Date: 2026-09-08 11:05:32 +0000

  \[Parser\] Rework the transformer logic to make recursive/iterative share the same flow (https://redirect.github.com/duckdb/duckdb/pull/25419)

  Unflavored-from: 43b43a5ca174fe16949ccd90421ffb3cfa619e69

- Update vendored sources to duckdb/duckdb@b967d4b614b089176dba0ecb6dfe20d838a5a21c.

  Date: 2026-09-08 10:31:06 +0000

  Temp file: avoid races via naming convention with slots (https://redirect.github.com/duckdb/duckdb/pull/24811)

  Unflavored-from: e965c7295f88d436d31f9940c365528b872156df

- Update vendored sources to duckdb/duckdb@cd4f722bce1a136bb848d93443b995d41607b264.

  Date: 2026-09-08 10:17:17 +0000

  Test C++ 23 standard in one CI job (https://redirect.github.com/duckdb/duckdb/pull/25441)

  Unflavored-from: 5130ec7d1be6ab3ca442392d206df2f86272d35f

- Update vendored sources to duckdb/duckdb@85198580409c24b6702c2a5a38b98ed2c7f7b87e.

  Date: 2026-09-08 09:36:20 +0000

  Experiment: Remove manually unrolled memory routines (https://redirect.github.com/duckdb/duckdb/pull/25380)
  Unflavored-from: 942a428b9a8080844174b2b1c98019bdbfbbb16f

- Update vendored sources to duckdb/duckdb@f6eeef7a5ee00fde490d99324ed2b9ea1668d886.

  Date: 2026-09-08 09:35:42 +0000

  Fix NOT NULL constraint verification after transaction-local deletes (https://redirect.github.com/duckdb/duckdb/pull/25453)

  Unflavored-from: de0db866b12364098cdc82b61026abd5df9d1ae2

- Update vendored sources to duckdb/duckdb@2bdb562a2e7cb2a80bb23bdf8f0a2bf28ceb11d8.

  Date: 2026-09-08 09:27:37 +0000

  planner: merge transaction-local statistics into table-\>GetStatistics (https://redirect.github.com/duckdb/duckdb/pull/25277)
  Increase stack size on Linux with musl libc (https://redirect.github.com/duckdb/duckdb/pull/25390)

  Unflavored-from: 05d30812c5edd65c85f63fc314823cc5699b5254

- Update vendored sources to duckdb/duckdb@bade309c1c5ded881fec74cbc94ac14048ad0107.

  Date: 2026-09-08 08:52:31 +0000

  Fix compiler warnings (variable unused or method) (https://redirect.github.com/duckdb/duckdb/pull/25356)

  Unflavored-from: 09177f839114db25ba010467d2245d77e88b6dc3

- Update vendored sources to duckdb/duckdb@dbd80ab69ce6f39213f794969384ab9ded38cfd6.

  Date: 2026-09-08 08:52:08 +0000

  Return an input error for invalid regex split patterns (https://redirect.github.com/duckdb/duckdb/pull/25375)

  Unflavored-from: 5f3b4467a8270409ebd30771ab2eb9e63fcb8f00

- Update vendored sources to duckdb/duckdb@ed385454442e17e56f22449df87d2c3069dbe375.

  Date: 2026-09-08 08:39:51 +0000

  Remove `LogicalType` from parsed `CastExpression` (https://redirect.github.com/duckdb/duckdb/pull/25424)

  Unflavored-from: 000f81e9a064526a1019f5d98f643450ee719b6d

- Update vendored sources to duckdb/duckdb@00ef652a20e20bc47ab2dbf78cb43fbeb5d22cd3.

  Date: 2026-09-08 08:35:55 +0000

  Fix remap_struct leaving rows uninitialized for constant MAP/LIST input (https://redirect.github.com/duckdb/duckdb/pull/25438)

  Unflavored-from: 1b601b4b1cff890ae12682a52e50944b02a74347

- Update vendored sources to duckdb/duckdb@8c061ed3daf0b992ba1597007074627240871962.

  Date: 2026-09-08 08:35:35 +0000

  Fix out-of-bounds write on empty CSV line with duplicate empty nullstr (https://redirect.github.com/duckdb/duckdb/pull/25440)

  Unflavored-from: 1a7ff0070143cd8ba6050301355d83175e271f90

- Update vendored sources to duckdb/duckdb@92afc0d8fed1173496077b72ce3ab6a284e15b27.

  Date: 2026-09-08 08:33:42 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/25048: VARIANT Cast Overrides (https://redirect.github.com/duckdb/duckdb/pull/25450)

  Unflavored-from: 08f590319bd58c83395b8dd0bf918beae74c0fc6

- Update vendored sources to duckdb/duckdb@a86336cd55b9ff255d57df3824948d6aaf03b7b9.

  Date: 2026-09-08 07:58:15 +0000

  Fix unbounded index leak (https://redirect.github.com/duckdb/duckdb/pull/25385)
  Bump 10 extensions, remove 10 patches (https://redirect.github.com/duckdb/duckdb/pull/25449)

  Unflavored-from: 80c27981305f7039bf00654ccdc9ba8688d83918

- Update vendored sources to duckdb/duckdb@816a3eb2d512ce359efb40d9319f6db59788422a.

  Date: 2026-09-08 07:52:26 +0000

  Merge variegata into 2.0-cyanoptera (https://redirect.github.com/duckdb/duckdb/pull/25405)

  Unflavored-from: 393412e87ed43f1eb1d29828d3967ffc51374313

- Update vendored sources to duckdb/duckdb@9849add833a58a1e0d084ab7132b4ebf7d8f6041.

  Date: 2026-09-08 07:52:10 +0000

  Avoid GetFileDescriptorLimit throwing InternalException (https://redirect.github.com/duckdb/duckdb/pull/25447)

  Unflavored-from: 6ce013ef9d8a153be3e113939c16946ae5d41bf6

- Update vendored sources to duckdb/duckdb@ffdf46b6d21e5ca0c5bb4cc968dd040c32ad7ecb.

  Date: 2026-09-08 07:51:56 +0000

  Bump httpfs, remove patches (https://redirect.github.com/duckdb/duckdb/pull/25445)
  Publish alpha only on default branch, use consistent static/shared libs artifact names (https://redirect.github.com/duckdb/duckdb/pull/25434)

  Unflavored-from: c974874875f9915ecb1010c267df74f04a58cd95

- Update vendored sources to duckdb/duckdb@6d04e4cbe42044d5d2bb1657a3cd21ffe3c24355.

  Date: 2026-09-08 07:20:55 +0000

  Fix tdigest data race (https://redirect.github.com/duckdb/duckdb/pull/25460)

  Unflavored-from: 88dc11ba81f84494d133c28c47e4d44be9f69dfd

- Update vendored sources to duckdb/duckdb@070ce1f695bb17ef68f1fdd5ba20cad4a3ac6646.

  Date: 2026-09-07 21:40:03 +0000

  Prevent volatile predicates from being pushed below window operators (https://redirect.github.com/duckdb/duckdb/pull/24874)

  Unflavored-from: c5a1edb8e64bbd320c6e1061e161769d2218a8bd

- Update vendored sources to duckdb/duckdb@1ea4954d1c5bed74df5f528123dca9269aa8791b.

  Date: 2026-09-07 17:29:53 +0000

  Fix trailing '%' wildcards ignoring the ESCAPE character (https://redirect.github.com/duckdb/duckdb/pull/25422)

  Unflavored-from: 0a6aae4b289153c7c8e91dfcc54fb48b840e4f16

- Update vendored sources to duckdb/duckdb@08ab73dcd448550f359b9844d4b2910b82a7ec9b.

  Date: 2026-09-07 16:32:25 +0000

  `ArenaAllocator` for `MatchFrames` (https://redirect.github.com/duckdb/duckdb/pull/25421)

  Unflavored-from: 281a5e4e549f67ad392ca7af4f84ee590ef309f5

- Update vendored sources to duckdb/duckdb@49f3c372ba936be1c2c1a7d07323cbe4cf492a58.

  Date: 2026-09-07 16:05:14 +0000

  Fix concurrent write to same file name (https://redirect.github.com/duckdb/duckdb/pull/25429)

  Unflavored-from: 23b80200e49e2faa3c13f3ebf650713be3de4e53

- Update vendored sources to duckdb/duckdb@94c8a84d64577067309daf20362202c213394e8b.

  Date: 2026-09-07 15:13:41 +0000

  Remove Scans for column references in removed expressions (https://redirect.github.com/duckdb/duckdb/pull/25327)

  Unflavored-from: 6ee29f576bdd94b149ca2b25a26b1922d58c4d8e

- Update vendored sources to duckdb/duckdb@2ee8e431fe74d19a403ef262cb1fb666536d627c.

  Date: 2026-09-07 15:02:37 +0000

  Add `DUCKDB_API` to `ExternalFileCacheUtil::GetCacheValidationMode` (https://redirect.github.com/duckdb/duckdb/pull/25426)

  Unflavored-from: 844aee2d12bd928ab15936f6f4c81ee111ad839d

- Update vendored sources to duckdb/duckdb@e62fb8059e7aa1aa4a147bd9fd26f46c9eebd661.

  Date: 2026-09-07 14:25:58 +0000

  Fix task executor regression (https://redirect.github.com/duckdb/duckdb/pull/25418)

  Unflavored-from: 68bad287e5c510866930d8ed8f2746543d6f8d06

- Update vendored sources to duckdb/duckdb@6d622ce708b806f51be32543bb3e291c5121ec0c.

  Date: 2026-09-07 12:34:47 +0000

  `HTTPTransportManager` (https://redirect.github.com/duckdb/duckdb/pull/25358)

  Unflavored-from: e6fe135998068a18e0cdd2f51b071b064be8106f

- Update vendored sources to duckdb/duckdb@de6a4203c17e9c5973629ee50cfa405fc2c328b6.

  Date: 2026-09-07 12:31:57 +0000

  Fix `PIVOT` allowing optional parenthesis (https://redirect.github.com/duckdb/duckdb/pull/25420)

  Unflavored-from: fca6515a49b3c2a70def2ef9ea8f7959a14c3836

- Update vendored sources to duckdb/duckdb@f7cbbed63738480cac98e70da9776ae854d9a0ce.

  Date: 2026-09-07 11:31:48 +0000

  Preserve GROUPING() bindings in the ordered-list aggregate rewrite (https://redirect.github.com/duckdb/duckdb/pull/24535)
  Update compression tests for extension runs (https://redirect.github.com/duckdb/duckdb/pull/25372)

  Unflavored-from: 4d3842761125305cd8409d50100d16cba127f6ab

- Update vendored sources to duckdb/duckdb@e45ab0f26c658bdffbe5e54b9fb8fcd3cd88a08d.

  Date: 2026-09-07 10:41:24 +0000

  add debug and deprecated settings (https://redirect.github.com/duckdb/duckdb/pull/25330)

  Unflavored-from: 65b011fa9ed7c7a64e45df15b35a23d4c8e61b4f

- Update vendored sources to duckdb/duckdb@cd8b915e99d23f1cd09a487e021e60b56ba072a0.

  Date: 2026-09-07 09:11:25 +0000

  Fix foreign key constrain check (https://redirect.github.com/duckdb/duckdb/pull/25387)

  Unflavored-from: f3d5addc298a70d4fdbbc78dc52dcade6945386a

- Update vendored sources to duckdb/duckdb@0aeaaf360bcb7b2d866a6eed0b6923adb0c24537.

  Date: 2026-09-07 08:57:04 +0000

  Leverage bloom filter for parquet MAP type (https://redirect.github.com/duckdb/duckdb/pull/25239)

  Unflavored-from: c334732a9cf1097a21de77c252ef07c2fa231901

- Update vendored sources to duckdb/duckdb@728402e61b814498836153cca9181aa4f1461ffc.

  Date: 2026-09-07 08:56:15 +0000

  Support string type for multicolumn pushdown (https://redirect.github.com/duckdb/duckdb/pull/25233)

  Unflavored-from: 98699358599e9f395d575b231cda0640da85ccfd

- Update vendored sources to duckdb/duckdb@09aaddad5e61a51f6bdadbee1a7eb0bd33df13cb.

  Date: 2026-09-07 08:14:22 +0000

  Track intra-dependencies in Pipeline (https://redirect.github.com/duckdb/duckdb/pull/25367)

  Unflavored-from: 33a3efe6bd7a034364852526444f86e915bb1eb6

- Update vendored sources to duckdb/duckdb@78767ca14961325a64da24e3b9331224c2ed5477.

  Date: 2026-09-07 07:44:09 +0000

  Fix INTERNAL bind error for UNNEST comma join with CAST filter (https://redirect.github.com/duckdb/duckdb/pull/25348)

  Unflavored-from: 681c5da9968c1992268d8c69c3816b538d992d8e

- Update vendored sources to duckdb/duckdb@1c832a351bf426c2c03d6a56936072e3a82b497a.

  Date: 2026-09-07 07:24:08 +0000

  Fix missing `deleted_index`assignment on local table storage when table schema change (https://redirect.github.com/duckdb/duckdb/pull/25400)

  Unflavored-from: 7b595776a61752bc3ac56926e54c0093b80649c7

- Update vendored sources to duckdb/duckdb@eb364821c3e4016c00c66abefb4fbcc7e400c006.

  Date: 2026-09-07 07:16:39 +0000

  Improve filter propagation result for string-result functions (https://redirect.github.com/duckdb/duckdb/pull/25237)

  Unflavored-from: 6cbb7358ebde0febaba933bf742cb8e016a3baed

- Update vendored sources to duckdb/duckdb@59ae0c6fb3f29369cfd0df124c76e9232181ef86.

  Date: 2026-09-07 07:16:12 +0000

  Fix parallel CSV reader duplicate rows with \r\r\n line endings (https://redirect.github.com/duckdb/duckdb/pull/25232)

  Unflavored-from: f3392d3e3cfba8e23da06d591cd9a1d9fef71015

- Update vendored sources to duckdb/duckdb@5aee32f9e667c1e4b70dbb58203f4ab75ab77501.

  Date: 2026-09-07 07:15:52 +0000

  Improve parquet bloom filter pruning for IN operator on NULL (https://redirect.github.com/duckdb/duckdb/pull/25225)

  Unflavored-from: ce5e16403c80c136dfb6b395b118a869064a7690

- Update vendored sources to duckdb/duckdb@2c6ec25a447f6a95fc1cefb2411c7f5e3437265d.

  Date: 2026-09-07 07:15:39 +0000

  Profiler enable disable (https://redirect.github.com/duckdb/duckdb/pull/25220)

  Unflavored-from: f8ef29c8f9f92840c38d05ac0f56964ce1c18415

- Update vendored sources to duckdb/duckdb@52a6368d41f6166cc6cdc511e48ff3eb0ef5203a.

  Date: 2026-09-07 07:05:33 +0000

  Report missing prepared statement parameters in declaration order (https://redirect.github.com/duckdb/duckdb/pull/25299) (https://redirect.github.com/duckdb/duckdb/pull/25336)

  Unflavored-from: 1717fb95e54604ad6695d4ec8ee7965bfac4113f

- Update vendored sources to duckdb/duckdb@487155f6ef3404adb64340e9dd87caac10386bdb.

  Date: 2026-09-07 07:04:13 +0000

  Fix crash casting a UNION to a UNION with a VARIANT member (https://redirect.github.com/duckdb/duckdb/pull/25369)

  Unflavored-from: 312414794fd354c71978655840f86d903cb93142

- Update vendored sources to duckdb/duckdb@18934f90cbae3c3ad4ff19ad23031cacf066e4eb.

  Date: 2026-09-07 07:02:46 +0000

  Make decimal division round to even (https://redirect.github.com/duckdb/duckdb/pull/25362)
  Print failed test name correctly and stack trace for crashing tests (https://redirect.github.com/duckdb/duckdb/pull/25364)

  Unflavored-from: 6079e5e70caf53ff69f6bbeb519a0124cbc0c1d1

- Update vendored sources to duckdb/duckdb@31151d40e6906f2056db8a2c45b336b153c9f871.

  Date: 2026-09-07 07:01:43 +0000

  Properly transform qualified columns in rename/exclude (https://redirect.github.com/duckdb/duckdb/pull/25370)

  Unflavored-from: e1fabc75c882aecc3792c6441aa1f1cb7032768f

- Update vendored sources to duckdb/duckdb@ae4bc674cfad7b3a48ad63ec310e4609caddcbf4.

  Date: 2026-09-07 06:55:50 +0000

  Add shared SWAR word primitives (https://redirect.github.com/duckdb/duckdb/pull/25374)

  Unflavored-from: fbc58790a9bcf47f9d02d080fb584c9f04f7646b

- Update vendored sources to duckdb/duckdb@d3af6349f274ffabbbd63f32c61f9523e09f4d4f.

  Date: 2026-09-07 06:55:18 +0000

  Fix chained function calls on case-insensitive column matches (https://redirect.github.com/duckdb/duckdb/pull/25376)
  Bump CI images to replace samurai with ninja (https://redirect.github.com/duckdb/duckdb/pull/25386)

  Unflavored-from: 1a65e4d4223f2f3ef04cbcb2659e8188b03b6430

- Update vendored sources to duckdb/duckdb@71ec7fc9b9c3e23d2c6d65ef9a7ebdcda919564e.

  Date: 2026-09-07 06:49:45 +0000

  Tidy snapshot handling in the transaction manager (https://redirect.github.com/duckdb/duckdb/pull/25389)

  Unflavored-from: 30694df5ced87ea0fa2cd3d5028cc0b0e949a602

- Update vendored sources to duckdb/duckdb@48fecd2aa29d0e9de3ae4f151a73ac29243b00c9.

  Date: 2026-09-07 06:43:07 +0000

  Fix primary key update to NOT NULL (https://redirect.github.com/duckdb/duckdb/pull/25397)

  Unflavored-from: 1379df7dae82bca27cab6ef318d343d5e47bc22e

- Update vendored sources to duckdb/duckdb@de39b9f95d8402cda736df035434544f41df0a8f.

  Date: 2026-09-07 06:22:20 +0000

  \[Parser\] Rework `Matcher` logic to make recursive/iterative share the same flow (https://redirect.github.com/duckdb/duckdb/pull/25363)

  Unflavored-from: 2938ec4f8e4feb16dd1eec3893aa534ba34411ce

- Update vendored sources to duckdb/duckdb@ef1ffd499ef443571d1705787906c968a62a9757.

  Date: 2026-09-07 06:13:23 +0000

  \[Catalog\] Make `TableCatalogEntry` column-related methods virtual, remove `ColumnList` ownership (https://redirect.github.com/duckdb/duckdb/pull/25371)

  Unflavored-from: fc619405a8d71608b8b7b9e0f2100842fda3d632

- Update vendored sources to duckdb/duckdb@e3946f2327a3cc622e1ec7fe71d51de49f93e61d.

  Date: 2026-09-04 13:50:35 +0000

  State the snapshot visibility rule once (https://redirect.github.com/duckdb/duckdb/pull/25187)

  Unflavored-from: 104f5b688e9df0b43ca58e500013b333502186da

- Update vendored sources to duckdb/duckdb@23ff70c0e3c896df45635352b0ed97b07c1e4b81.

  Date: 2026-09-04 13:38:59 +0000

  Fix bind for summarize for stdin (https://redirect.github.com/duckdb/duckdb/pull/25353)

  Unflavored-from: f93b81dfb2e245d28d3b0a80b60bebf1df545ef6

- Update vendored sources to duckdb/duckdb@3e3d2a823526b5b7f482b921260de20c0d1be338.

  Date: 2026-09-04 13:37:59 +0000

  Add helpful error for alter table drop constraint (https://redirect.github.com/duckdb/duckdb/pull/25354)

  Unflavored-from: 3afc1d39cd02340ec62940b87365096ce1d5efdd

- Update vendored sources to duckdb/duckdb@28b6d8d1595ab19f866271e4dcb409eaeb7a6a9d.

  Date: 2026-09-04 13:37:25 +0000

  Avoid rebuilding sorted aggregate sort specifications during execution (https://redirect.github.com/duckdb/duckdb/pull/25359)

  Unflavored-from: f1dc655a92f279a2e44c57a2223124faddabb56a

- Update vendored sources to duckdb/duckdb@11b9ab23ab7f4ba2ca3a900631236ca6796f3609.

  Date: 2026-09-04 12:15:13 +0000

  Fix indexed updates with generated columns (https://redirect.github.com/duckdb/duckdb/pull/25321)

  Unflavored-from: 5cbc397ef5c8a786c90ced87243e49ce7177ca4f

- Update vendored sources to duckdb/duckdb@78c3d686b6bf0f89eba3c609f2a03b162b52748c.

  Date: 2026-09-04 11:50:45 +0000

  Fix delete index row ID alignment after deduplication (https://redirect.github.com/duckdb/duckdb/pull/25337)

  Unflavored-from: fc89fcd0725c426fd6c7021e43777de5d5b93503

- Update vendored sources to duckdb/duckdb@6e99d09918afe0e83579490daccda33823f96cdf.

  Date: 2026-09-04 11:32:00 +0000

  Fix misuse for physical and logical ID for `INSERT OR REPLACE` (https://redirect.github.com/duckdb/duckdb/pull/25323)

  Unflavored-from: 5336d3d8a4762f0ddf3107bd4237b9603e1a8c10

- Update vendored sources to duckdb/duckdb@6d8e98ebeac50aeb52196c888979f01434900c98.

  Date: 2026-09-04 11:08:08 +0000

  Preserve empty-set results of zero-returning aggregates in correlated subqueries (https://redirect.github.com/duckdb/duckdb/pull/24514)

  Unflavored-from: 68165d7319ac81fffb949c36f58264e18aae7a89

- Update vendored sources to duckdb/duckdb@777f71c6fa7468ceb564dda9644966b5e25d942f.

  Date: 2026-09-04 11:03:51 +0000

  fix: list_sort orders INTERVALs consistently with comparison/ORDER BY (https://redirect.github.com/duckdb/duckdb/pull/25142)
  Unflavored-from: 8dc31a5b64f3591717e306520d00fe53ce69b4e7

- Update vendored sources to duckdb/duckdb@e10e48bf4c297af36a8c96206df5d5d0de052191.

  Date: 2026-09-04 11:02:13 +0000

  C-API-V2: Part 3 (https://redirect.github.com/duckdb/duckdb/pull/25340)
  Unflavored-from: 46af04db3c25f5fbdb8a813e676f398701652389

- Update vendored sources to duckdb/duckdb@45c329a1bfd1f02fa1ad97e073715c701381cac6.

  Date: 2026-09-04 10:55:09 +0000

  Fix stale column_count in LateMaterialization for stacked filters (https://redirect.github.com/duckdb/duckdb/pull/25351)
  \[Backport\] Add issue tracker workflow (https://redirect.github.com/duckdb/duckdb/pull/25350)

  Unflavored-from: bc6b0b4944612336155ac5e040db944aafe2828e

- Update vendored sources to duckdb/duckdb@a8a894f19bb7b41c7ea24d62ff9b4ef7b6f0b534.

  Date: 2026-09-04 09:34:36 +0000

  Fix Substring Clamping Issue (https://redirect.github.com/duckdb/duckdb/pull/25286)

  Unflavored-from: 7f390c97b3afbc029040450f02aaed4890d0ddcd

- Update vendored sources to duckdb/duckdb@79469d161a61de178d8cae745c901cbc9ba3cc15.

  Date: 2026-09-04 09:05:37 +0000

  \[Parser\] Add `GrammarExtension` extension API (https://redirect.github.com/duckdb/duckdb/pull/24919)

  Unflavored-from: 8e4011d3a32207534c90d977bf8d1ef86b97d4c0

- Update vendored sources to duckdb/duckdb@60f14bef7ca173a1f34da017be8f949297f053e1.

  Date: 2026-09-04 08:50:04 +0000

  Test PostgreSQL nested comparison semantics in the deliminator (https://redirect.github.com/duckdb/duckdb/pull/24546)

  Unflavored-from: d625c74de40cd2dce012a3a19b73d53f5aa9e92e

- Update vendored sources to duckdb/duckdb@4cf463ea1a6c93e7fa62051a68c552805fefed64.

  Date: 2026-09-04 08:47:28 +0000

  Make round_even exact for DECIMAL (https://redirect.github.com/duckdb/duckdb/pull/25197)
  \[async results\] Enable stream drain benchmarks (https://redirect.github.com/duckdb/duckdb/pull/25288)

  Unflavored-from: 3deb2419c325e346e7df332ae6861c123afd8c54

- Update vendored sources to duckdb/duckdb@96daaad7f06aec73726ab10b949c21ffe04c4663.

  Date: 2026-09-04 08:38:25 +0000

  Improve star bind error message (https://redirect.github.com/duckdb/duckdb/pull/24088)

  Unflavored-from: cda3fc2c40c913ad3dec8dae60bbdaee123f2695

- Update vendored sources to duckdb/duckdb@8f31745bb91b91988fd45b52dc0b724264f4bd5b.

  Date: 2026-09-04 08:37:56 +0000

  Use CompressionSegmentReader for RLE (https://redirect.github.com/duckdb/duckdb/pull/25263)
  Use group matrix for build/test job split of extensions (https://redirect.github.com/duckdb/duckdb/pull/24769)

  Unflavored-from: ed6f735d3e8e7556e763d3634d9fa17fcc1cb14f

- Update vendored sources to duckdb/duckdb@c2f5210946d0826d2cca527079e59177006bd6a7.

  Date: 2026-09-03 22:28:17 +0000

  Merge `v1.5-variegata` into `v2.0-cyanoptera` (https://redirect.github.com/duckdb/duckdb/pull/25317)

  Unflavored-from: 8f7d3c148512fc0d946ffe3474ce9c311e618078

- Update vendored sources to duckdb/duckdb@3ce229ab2616612eef60fc2489fb312a31e40d6f.

  Date: 2026-09-03 21:10:19 +0000

  \[Dev\] aggregate_state fuzzing fixes (https://redirect.github.com/duckdb/duckdb/pull/25098)

  Unflavored-from: 82b62933492e98018f7d47ea3e1bfad718cecd4f

- Update vendored sources to duckdb/duckdb@7f675f4d10e28e93d44005366164f134cfade072.

  Date: 2026-09-03 18:41:47 +0000

  Decouple string scan states (https://redirect.github.com/duckdb/duckdb/pull/25322)

  Unflavored-from: b573424083e7d3c7e8adef4fece428ed33f9f28e

- Update vendored sources to duckdb/duckdb@613d9045911c733179ece454db771a3cf6a1beb2.

  Date: 2026-09-03 17:29:26 +0000

  Fix adding `UNIQUE` constraint on `ALTER TABLE` (https://redirect.github.com/duckdb/duckdb/pull/25303)

  Unflavored-from: 26284872fda3d429ffc6d624b22bfc6268b7c2de

- Update vendored sources to duckdb/duckdb@62f883bbc2ac583776df8493326025f88d0bfe6b.

  Date: 2026-09-03 17:29:15 +0000

  Check key uniqueness on topk import (https://redirect.github.com/duckdb/duckdb/pull/25291)
  Bump VSS (https://redirect.github.com/duckdb/duckdb/pull/25311)

  Unflavored-from: d62f01da10e06be6058fbfd9da46a45ca6848558

- Update vendored sources to duckdb/duckdb@e867fcfb4fc5b993a5e6f0f8bfa7a835595364f1.

  Date: 2026-09-03 14:49:58 +0000

  Fixup compilation when DEBUG vs D_ASSERT are not the same (https://redirect.github.com/duckdb/duckdb/pull/25316)
  Create static libs for windows amd64/arm64 (https://redirect.github.com/duckdb/duckdb/pull/25312)
  Json normalize fix (https://redirect.github.com/duckdb/duckdb/pull/25230)
  Save cache for workflow_dispatch events (https://redirect.github.com/duckdb/duckdb/pull/25308)

  Unflavored-from: 30073cc62aed42ba3432296c21bad2c7078e12d7

- Update vendored sources to duckdb/duckdb@b19f5b1e169dbd53c0967963a8db2cd6615935fb.

  Date: 2026-09-03 13:16:09 +0000

  Fix checkpoint delta revert (https://redirect.github.com/duckdb/duckdb/pull/24755)
  \[async results\] Add drain mode param to interpreted_benchmark's resultmode (https://redirect.github.com/duckdb/duckdb/pull/25287)

  Unflavored-from: 7d950376aa49cf5e45cd63242e945c056ebebf12

- Update vendored sources to duckdb/duckdb@c320e476426f6eee9d5eadd08090329aed5218fb.

  Date: 2026-09-03 11:58:43 +0000

  Flip the switch to heap based parser (https://redirect.github.com/duckdb/duckdb/pull/25262)

  Unflavored-from: 1aa18b02c76cc575a20b6d593018a8edc3a12083

- Update vendored sources to duckdb/duckdb@732b12c070a510ddf17e842a2687d094e40e3e89.

  Date: 2026-09-03 11:27:27 +0000

  \[Storage\] Add `byte_size` to `DataPointer` (https://redirect.github.com/duckdb/duckdb/pull/25176)

  Unflavored-from: e52bbdb0ceaf663e029592e4038a099aa2b9a94a

- Update vendored sources to duckdb/duckdb@ef02dbf5ce171a390e123695463165d0e4fa6bb1.

  Date: 2026-09-03 11:23:05 +0000

  Add ProcessUtil: OS dependent informations about process id & co (https://redirect.github.com/duckdb/duckdb/pull/25265)

  Unflavored-from: eb126918621abf7d5b9c7f1b38ea8800b5f3b273

- Update vendored sources to duckdb/duckdb@c90022de22ac8f12bce360815536bb8c648d1812.

  Date: 2026-09-03 10:57:06 +0000

  Fix TopN window elimination with ROW_NUMBER argument ordering (https://redirect.github.com/duckdb/duckdb/pull/24346)

  Unflavored-from: 86796eda2bd23931bacbf61fc3e00dd2edc14508

- Update vendored sources to duckdb/duckdb@a34fdf494cda45c1e5df2daafca09c76c11e0b4e.

  Date: 2026-09-03 10:56:39 +0000

  Fix PiecewiseMergeJoin arbitrary predicate candidate indexing (https://redirect.github.com/duckdb/duckdb/pull/25152)

  Unflavored-from: 9141183c6ed05f4b1616631142c95316a977e1f8

- Update vendored sources to duckdb/duckdb@6790309fde14c0d9875aff05266ddabae870793d.

  Date: 2026-09-03 10:52:11 +0000

  Fix statistics propagation for window aggregate functions (https://redirect.github.com/duckdb/duckdb/pull/23663) (https://redirect.github.com/duckdb/duckdb/pull/24030)

  Unflavored-from: ad92cce7c5b67b7bfcccb9df6fd8bc1ea68e8aaa

- Update vendored sources to duckdb/duckdb@9c21294d984dfe9a1da5d055b5fce3e8a0d634b2.

  Date: 2026-09-03 07:21:20 +0000

  Fixes to allow compiling with LLVM 23 cxx library (https://redirect.github.com/duckdb/duckdb/pull/25284)

  Unflavored-from: dc92dd06a05dfa1c62a9807ba244c429b9e830f3

- Update vendored sources to duckdb/duckdb@f4500cb89d8bb184b68a12c4eac411fae1b2c842.

  Date: 2026-09-03 07:21:04 +0000

  More fixes LLVM 23 (https://redirect.github.com/duckdb/duckdb/pull/25289)
  Document new vector API in `AGENTS.md` (https://redirect.github.com/duckdb/duckdb/pull/25309)

  Unflavored-from: dfeb528a9719e9fb7d0593d501bf595c741d2999

- Update vendored sources to duckdb/duckdb@69dda846af6950a3046910bf5663e9a004a447b8.

  Date: 2026-09-03 07:20:36 +0000

  Reject empty NULLSTR lists in CSV writer (https://redirect.github.com/duckdb/duckdb/pull/25290)

  Unflavored-from: 86af42a573d768eb95bdee8d0d382dca4d692fb4

- Update vendored sources to duckdb/duckdb@da4ac3937de34390de5d031b15a92b4de336598a.

  Date: 2026-09-03 07:20:12 +0000

  Bump Postgres scanner (https://redirect.github.com/duckdb/duckdb/pull/25296)

  Unflavored-from: 4e72927ff98b6295fcda0f3c7084c9b2e382bf75

- Update vendored sources to duckdb/duckdb@1724690c13c681ec1311f4c2befac9133d6f853a.

  Date: 2026-09-03 07:01:30 +0000

  Remove redundant LIMIT using maximum cardinality (https://redirect.github.com/duckdb/duckdb/pull/24160)

  Unflavored-from: 3a0bc4930375902f3027b9a45d4d1412777d40b5

- Update vendored sources to duckdb/duckdb@ee95013f175bea7aa813f56c86fea983db6bc8e5.

  Date: 2026-09-02 21:55:44 +0000

  Restructure MERGE INTO to no longer have internal operators and to instead create pipelines with merge sources that do the various merge actions (https://redirect.github.com/duckdb/duckdb/pull/25228)

  Unflavored-from: c480eb1d0ce9dd21c8425f129f864f0bcdbb7a49

- Update vendored sources to duckdb/duckdb@b06888e99efe1ce964513e66dee259ac5a3dbc31.

  Date: 2026-09-02 21:25:25 +0000

  Don't let terminal matchers have a separate frame (https://redirect.github.com/duckdb/duckdb/pull/25254)
  Add C API v2 headers to static/shared tarballs (https://redirect.github.com/duckdb/duckdb/pull/25264)

  Unflavored-from: 88a21826163813b23faf3b8f1eef4b61dbd7c554

- Update vendored sources to duckdb/duckdb@10ba1a72097d9d7839489f2ea0849e476dbe891b.

  Date: 2026-09-02 19:15:01 +0000

  Implement hex/binary string cast for HUGEINT/UHUGEINT (https://redirect.github.com/duckdb/duckdb/pull/25252)

  Unflavored-from: 0e488c1ab1609ee4f4c5f6fd2e58805dfe664f10

- Update vendored sources to duckdb/duckdb@8f8a798bb36433acbe7970e353f73d4ce2f9fd69.

  Date: 2026-09-02 18:46:31 +0000

  Fix reservoir_quantile for DECIMAL types (preserve precision and supp… (https://redirect.github.com/duckdb/duckdb/pull/24488)

  Unflavored-from: 961cd8ce29fc022c44891f24eab3cebe9a3c3c0d

- Update vendored sources to duckdb/duckdb@8376810481763bf3ff652ab40d001827e58b2cd3.

  Date: 2026-09-02 16:24:18 +0000

  enable auto-loading of extensions via their log types/messages (https://redirect.github.com/duckdb/duckdb/pull/25251)
  Use override value before constructing new release version (https://redirect.github.com/duckdb/duckdb/pull/25259)

  Unflavored-from: 273c222ca1a350e398bf3812ea0f489d6ff3c684

- Update vendored sources to duckdb/duckdb@8a81c8498737ccca5f176816fef8d6dc0d89b056.

  Date: 2026-09-02 15:49:05 +0000

  Set nullability for a few functions (https://redirect.github.com/duckdb/duckdb/pull/25240)

  Unflavored-from: 1e18793bcfbc01007aba35a153eab1e786470f71

- Update vendored sources to duckdb/duckdb@9360e4a8b9d5ccdbefaffd0e2eeb6cbdaffda273.

  Date: 2026-09-02 15:48:48 +0000

  Remove and deprecate several settings (https://redirect.github.com/duckdb/duckdb/pull/25224)

  Unflavored-from: 34ba775fe0228f95241364ecdd8777717fe39f90

- Update vendored sources to duckdb/duckdb@29b52d88f324e45f99449536d9a6a4061ecadcbb.

  Date: 2026-09-02 15:29:09 +0000

  CSV Encoding Fixes (https://redirect.github.com/duckdb/duckdb/pull/25100)

  Unflavored-from: ac0f542069c8bf8a338593da54e54862dfaf3294

- Update vendored sources to duckdb/duckdb@4374d9378c1a777d5bad97aefdd2e4cb47ab1633.

  Date: 2026-09-02 15:01:10 +0000

  Fix infinite loop in equi_width_bins (https://redirect.github.com/duckdb/duckdb/pull/25258)
  JSON Deep Merge Fix (https://redirect.github.com/duckdb/duckdb/pull/24984)

  Unflavored-from: d218c091e337534b744ef6f3f6adb3da62f6f1f7

- Update vendored sources to duckdb/duckdb@c831825b63e9dd5ad9555137f469a611bb80ea03.

  Date: 2026-09-02 13:05:30 +0000

  \[Parquet\]\[Read\] Add an optional 'children' field to the `SCHEMA` parameter (https://redirect.github.com/duckdb/duckdb/pull/25014)

  Unflavored-from: 7b8a6e13196a5618de21816282a21c98de9eb98e

- Update vendored sources to duckdb/duckdb@f931913e6b03beaf75df0f56695900f765dab426.

  Date: 2026-09-02 12:39:38 +0000

  Use CompressionSegmentReader for ALP and ALPRD (https://redirect.github.com/duckdb/duckdb/pull/25218)

  Unflavored-from: 0f0670706278383eba8f55913b06c52c891387b1

- Update vendored sources to duckdb/duckdb@916aeeb64b0bd2e0f172266ac485daa929a4af98.

  Date: 2026-09-02 11:17:19 +0000

  Do not assume NULL columns on right side of LEFT JOIN (https://redirect.github.com/duckdb/duckdb/pull/25211)

  Unflavored-from: 8b7962b46afe7bcc8e5ae15f4757b23aba82ffa8

- Update vendored sources to duckdb/duckdb@41ddcf2480b7f69ac37764cbeeac7af4391c11fc.

  Date: 2026-09-02 11:15:13 +0000

  Prune multi-column interval comparisons (https://redirect.github.com/duckdb/duckdb/pull/25194)
  Add new `AGENTS.md` file for creating extension patches (https://redirect.github.com/duckdb/duckdb/pull/25229)

  Unflavored-from: b0190dbfca3a2c9daf43024b504220dd429a5f97

- Update vendored sources to duckdb/duckdb@f055e15597e1538d78e58e0d443ceeee8827e919.

  Date: 2026-09-02 11:16:59 +0200

  Fix `flatten` function validity (https://redirect.github.com/duckdb/duckdb/pull/25242)

  Unflavored-from: 56e344a02260cd58be0ab869b1fa9c84d0806e8e

- Update vendored sources to duckdb/duckdb@a00803f7687ca3d7188d417216e288c5c4b22b58.

  Date: 2026-09-02 07:37:52 +0000

  Add support for type constructor signatures and overloads (https://redirect.github.com/duckdb/duckdb/pull/25210)

  Unflavored-from: 4f8844ded13ebb312cab50ccfe269a160cda0387

- Update vendored sources to duckdb/duckdb@f3fa738d811caba7d97a8e461d15ee306b0291a4.

  Date: 2026-09-02 07:29:11 +0000

  Rework `ExpressionBinder` to use single-pass scope resolution (https://redirect.github.com/duckdb/duckdb/pull/25221)

  Unflavored-from: 5302a96ee0c7d9991e86980f133ad6322a3c8180

- Update vendored sources to duckdb/duckdb@15c5bddb86142c315afb0d3cf29d17bf14f0b504.

  Date: 2026-09-02 07:23:42 +0000

  Improve support for deeply nested qualified names (\>4 entries) in the parser layer (https://redirect.github.com/duckdb/duckdb/pull/25070)

  Unflavored-from: 577c09d61c9bef10bc20a4f5753acc3558c13ebd

- Update vendored sources to duckdb/duckdb@4a0d6fdecbf8363d15a2d8132338a346f9225957.

  Date: 2026-09-01 15:30:44 +0000

  Validate LIST offsets before use (https://redirect.github.com/duckdb/duckdb/pull/25212)

  Unflavored-from: 9c2356e9eac007c9d33720823a3221138233accd

- Update vendored sources to duckdb/duckdb@fb922caa6d8baf560d282918a72eeb2624e9caea.

  Date: 2026-09-01 15:21:57 +0000

  Improve IN operator propagation result (https://redirect.github.com/duckdb/duckdb/pull/25219)

  Unflavored-from: d77eb814c300e1fdd6ee6157bc54a5ffb46ef9d8

- Update vendored sources to duckdb/duckdb@7bc11f6b69f9c6cb6d8279024142f1fd11ce8b92.

  Date: 2026-09-01 14:35:19 +0000

  Special handling for block comments after an operator (https://redirect.github.com/duckdb/duckdb/pull/25177)

  Unflavored-from: c8ab250cf7d21f7f3db9124475f6e43b8d04997e

- Update vendored sources to duckdb/duckdb@522ae99f3fe2e9d6cceadb7f691f8fd2b2739659.

  Date: 2026-09-01 13:40:18 +0000

  Heap-based matcher (https://redirect.github.com/duckdb/duckdb/pull/25204)
  fix(cmake): Stop CMake configure on FATAL_ERROR messages (https://redirect.github.com/duckdb/duckdb/pull/25203)

  Unflavored-from: f8efca50927ef325e13196be29bfbe2391bf2206

- Update vendored sources to duckdb/duckdb@1582849bf9e35de3fa3c330935ede5ce598e28a3.

  Date: 2026-09-01 13:34:43 +0000

  Fix the profiler for the parser (https://redirect.github.com/duckdb/duckdb/pull/25215)

  Unflavored-from: 25aa6f7f722df2df2abb9ffa65e0fae651233c0a

- Update vendored sources to duckdb/duckdb@e198179d46332e279c8f84bb51710c66be80f9e2.

  Date: 2026-09-01 11:56:43 +0000

  Fix wrong results of TopN dynamic filter pushdown through a cast on the sort key (https://redirect.github.com/duckdb/duckdb/pull/25159)

  Unflavored-from: 6a91c0108304884656b6c9e3ab50efb2229bc94c

- Update vendored sources to duckdb/duckdb@6d7abb1090e1079f252b15ba0366310bb87d8582.

  Date: 2026-09-01 11:49:41 +0000

  C-API-V2: Part 2: Add `Scalar/AggregateFunction`, `ColumnDataCollection` and buffer managed datachunk constructor/copy (https://redirect.github.com/duckdb/duckdb/pull/25184)
  Unflavored-from: 936cbe427439c1d09610c7a15feb82067accdeb9

- Update vendored sources to duckdb/duckdb@c38d7e0739a7377f0c3f9eb8f4b7b87b000db433.

  Date: 2026-09-01 10:52:26 +0000

  Allow bypassing HTTP client cache (https://redirect.github.com/duckdb/duckdb/pull/25207)

  Unflavored-from: 5e3304b6a9d0a2880becce84b7bd28ae527beb5d

- Update vendored sources to duckdb/duckdb@ee7d48d88308ddbc72b14498ad3e5492f6034c54.

  Date: 2026-09-01 09:19:20 +0000

  Reduce keyed recursive UNION update overhead (https://redirect.github.com/duckdb/duckdb/pull/24908)

  Unflavored-from: f3b07d1ff0a75e4c13c9d6bcd8072c01e5e595e9

- Update vendored sources to duckdb/duckdb@e7bc9c130bbf1fd927c0d98757c89782be12078f.

  Date: 2026-09-01 09:14:26 +0000

  Fix integer underflow in NTILE with argument ordering on future-only frames (https://redirect.github.com/duckdb/duckdb/pull/24933)

  Unflavored-from: 41296b4842f3842d4eb8efd38f8b8cb959407048

- Update vendored sources to duckdb/duckdb@14bdca980d51933f718f7cbc590c5b0526b891d2.

  Date: 2026-09-01 07:47:27 +0000

  \[Overflow\] Use `TryMultiplyOperator` in `arg_max` and check with `NextPowerOfTwo` before multiplying (https://redirect.github.com/duckdb/duckdb/pull/25097)

  Unflavored-from: 1319d31909807f2265932c09c161fb4edfb209f4

- Update vendored sources to duckdb/duckdb@a257f6cff161e87e72b1507f3d140f3273647d6c.

  Date: 2026-09-01 07:43:04 +0000

  \[Dev\] Use `PhysicalResultCollector::IsStreaming` rather than just the hint if streaming is allowed (https://redirect.github.com/duckdb/duckdb/pull/25179)

  Unflavored-from: 1d477d3a77219ff556731acbdde9a6d759105290

- Update vendored sources to duckdb/duckdb@1b3c92a18881286356dd526dcbe5408d675d5e63.

  Date: 2026-09-01 07:37:32 +0000

  Fix COMMENT ON COLUMN when a remote catalog is attached (https://redirect.github.com/duckdb/duckdb/pull/25185)

  Unflavored-from: aa77244534975b31ff259d20474ad0a9a194db25

- Update vendored sources to duckdb/duckdb@84742e9260cda6c2dce7ba222617171312e482e0.

  Date: 2026-09-01 07:34:19 +0000

  Fix: Do not produce invalid UTF8 from printf's %c conversion (https://redirect.github.com/duckdb/duckdb/pull/25189)
  Unflavored-from: 8e83e43440fca5c6ba37630e012e0e00132ca0fd

- Update vendored sources to duckdb/duckdb@b82f19b24e1a8217109af2c406e7ff54058d97e2.

  Date: 2026-09-01 07:22:37 +0000

  Prune row group for boolean type under all NULL cases (https://redirect.github.com/duckdb/duckdb/pull/25200)

  Unflavored-from: 3e60a6e2dbf8d45817a0ac73f309cb0b570a673b

- Update vendored sources to duckdb/duckdb@f94f62df7a6a8cbabd07e9d3cdcd81686aeff8de.

  Date: 2026-09-01 07:21:38 +0000

  Cleanup unused else branch (https://redirect.github.com/duckdb/duckdb/pull/25201)

  Unflavored-from: 24deabe51989103423a409dc5e5e32021812183c

- Update vendored sources to duckdb/duckdb@79ba699ed0ca33b7d9c26b4ed2d00d2b37b39242.

  Date: 2026-09-01 07:21:11 +0000

  \[Parser\] Replace `PEGToken` with `PEGExpression` (https://redirect.github.com/duckdb/duckdb/pull/25198)

  Unflavored-from: b92a63335ecf51ec3a631291926e348f79cc6e24

- Update vendored sources to duckdb/duckdb@0c2112c567819ae5a44e72e6fbee798cbdf7238c.

  Date: 2026-09-01 07:16:11 +0000

  Check simple load and autoload of extensions (https://redirect.github.com/duckdb/duckdb/pull/25147)
  Simplify release versioning for 2.x releases (https://redirect.github.com/duckdb/duckdb/pull/25180)

  Landing v2 (finding 15): the engine is DuckDB 2.0 from here on, so `probe_table()` relaxes the invalidation policy from DuckDB 2.0, as on `main` (`R/dbExistsTable__duckdb_connection_ANY.R`).

  Unflavored-from: 0fb9b35a5955e475ff7003ba0edfaadb22a4c748

- Update vendored sources to duckdb/duckdb@197a59970b8ea5fcbf261aecfe68aed36e2da002.

  Date: 2026-09-01 07:08:13 +0000

  Reject `CREATE TEMPORARY INDEX` / `TRIGGER`, inherit trigger temporariness (https://redirect.github.com/duckdb/duckdb/pull/25119)

  Unflavored-from: e988e1ae79f01bde4c719fe47bb2bb2ecfbe76fb

- Update vendored sources to duckdb/duckdb@84e2f64b8e0bad7cc7cbc7bb4f6ad756daa63cf0.

  Date: 2026-09-01 05:50:58 +0000

  Add support for `duckdb -serve` and `duckdb -connect` to the CLI (https://redirect.github.com/duckdb/duckdb/pull/25068)

  Unflavored-from: 4d80f52f737a80f9c3ce04a9b30cd1979f67b90c

- Update vendored sources to duckdb/duckdb@ab1f4f735b1cce57c121cc61612fccc27b946aea.

  Date: 2026-09-01 05:37:53 +0000

  Fix PRAGMA enable_progress_bar and enable_progress_bar_print NULL han… (https://redirect.github.com/duckdb/duckdb/pull/24946)

  Unflavored-from: 35a857e14a3a1d63b3b0b7b3826450e4bd22dcb3

- Update vendored sources to duckdb/duckdb@886669ab126430bdcf56d010a0202cb72b26d937.

  Date: 2026-09-01 05:36:45 +0000

  Support more types for multicolumn pushdown (https://redirect.github.com/duckdb/duckdb/pull/25087)
  Fix symbol checks for linux arm64 CLI on main (different with Clang) (https://redirect.github.com/duckdb/duckdb/pull/25186)

  Unflavored-from: 26e86be39bbc5dcd1bc1a609f9bf0a924d56072e

- Update vendored sources to duckdb/duckdb@eb8fa58a36dbcb08d3a9421ea59d8d525c07d5c8.

  Date: 2026-08-31 20:29:58 +0000

  Forbid `CREATE TEMPORARY SCHEMA` that currently is thrown away (https://redirect.github.com/duckdb/duckdb/pull/25118)

  Unflavored-from: 666fc6d3baffba48cc1d810edd971b49ac96e306

- Update vendored sources to duckdb/duckdb@f5b42f79cec7e95f9edd14f830a63f8989a73b32.

  Date: 2026-08-31 16:38:12 +0000

  bump iceberg, regenerate extension entries (https://redirect.github.com/duckdb/duckdb/pull/25178)

  Unflavored-from: 57e8f59073fc5c14dbd1b451344de0ffa8f9fc59

- Update vendored sources to duckdb/duckdb@53be7c03c8009563484148ee8515edb0175d49da.

  Date: 2026-08-31 16:30:37 +0000

  Remove redundant condition in GetMatchingBinding ( /src/planner/bind_context.cpp ) (https://redirect.github.com/duckdb/duckdb/pull/25117)

  Unflavored-from: 590c83a908c17470987107471afcec6c3b0b027e

- Update vendored sources to duckdb/duckdb@605cdf985c313a0e0480e133fdc4da5a83342c53.

  Date: 2026-08-31 16:20:31 +0000

  Move SigV4 signing logic from httpfs into core (https://redirect.github.com/duckdb/duckdb/pull/25141)
  Use namespace runners and reduce OSX CI runs (https://redirect.github.com/duckdb/duckdb/pull/25182)

  Unflavored-from: 101eb1ef843f7b4a62fe0cced085621ab9302c1f

- Update vendored sources to duckdb/duckdb@492b0a30fe7491f6e8bd817ec769c8b9482f4b77.

  Date: 2026-08-31 13:28:34 +0000

  Added duckdb_v2_vector_get_logical_type to the C V2 API (https://redirect.github.com/duckdb/duckdb/pull/25052)

  Unflavored-from: f1ade23a5fc80a17f8ed2f8247c86b4aad85311f

- Update vendored sources to duckdb/duckdb@48ef058edf78fbb4bfd49a6287589a1b3efd54ab.

  Date: 2026-08-31 12:54:37 +0000

  Propagate comparison for INTERVAL type (https://redirect.github.com/duckdb/duckdb/pull/25090)

  Unflavored-from: 14a0180df7ec248c9037d9e61a2357be6e297fce

- Update vendored sources to duckdb/duckdb@4015290d757ad90196960bf25a36315daac72adb.

  Date: 2026-08-31 12:54:09 +0000

  Propagate stats for TIME_NS type from parquet (https://redirect.github.com/duckdb/duckdb/pull/25157)

  Unflavored-from: 6332e443575b49284bdce1e636ff1079f5ff7a96

- Update vendored sources to duckdb/duckdb@4fc09ee3030b420bd9752a5beabebb803c1cff19.

  Date: 2026-08-31 12:47:34 +0000

  Prune row group for boolean column expression filter (https://redirect.github.com/duckdb/duckdb/pull/25144)

  Unflavored-from: a27770314d3c845b69e963ecbd81791c6ddad459

- Update vendored sources to duckdb/duckdb@146e27a0bc928c27eb15cf6da86be66028433dd3.

  Date: 2026-08-31 12:33:16 +0000

  Allow max_memory to be set as a percentage (https://redirect.github.com/duckdb/duckdb/pull/25171)

  Unflavored-from: 85f92e251a2b7bb62da459dfc1be4fdb2a910dd6

- Update vendored sources to duckdb/duckdb@d9b894eb836cc8a2c4289ad160736753594566f0.

  Date: 2026-08-31 12:13:04 +0000

  \[Dev\]\[Parser\] Generate `PEGKeywordHelper` from `ParsedGrammar` (https://redirect.github.com/duckdb/duckdb/pull/24867)

  Unflavored-from: c418008cb57639da026e3d851137fb15089a3f0b

- Update vendored sources to duckdb/duckdb@2f41a3469a9e05e5268e00e640d1a2ceb119af9f.

  Date: 2026-08-31 11:36:08 +0000

  Remove the duplicated value argument from optimizer-generated constant_or_null() (https://redirect.github.com/duckdb/duckdb/pull/25175)

  Unflavored-from: 65add8ac31e0d8059a50da7218bc4aa0a0d1b797

- Update vendored sources to duckdb/duckdb@5487690ea6ccbe1dd499d2a818bc79cdab18508e.

  Date: 2026-08-31 10:57:39 +0000

  Keep NULL-keyed rows in top-N window elimination when ROW_NUMBER orders by a nullable expression (https://redirect.github.com/duckdb/duckdb/pull/23677) (https://redirect.github.com/duckdb/duckdb/pull/25134)

  Unflavored-from: 7eb6ab206b09008b5156d58d19fb44dbbea075b1

- Update vendored sources to duckdb/duckdb@ca3bc0c897b9a1df192597369d2bdd7d6a012eb7.

  Date: 2026-08-31 10:33:46 +0000

  Change Concat_ws to accept lists (https://redirect.github.com/duckdb/duckdb/pull/25099)

  Unflavored-from: cdaf581ae3f7d096919729c6d843ec127b8676a5

- Update vendored sources to duckdb/duckdb@7e7a4969ab6f2af22526f2ecf3d90449b1c48e8c.

  Date: 2026-08-31 10:08:28 +0000

  Allow integral types in variant_extract via cast to UINTEGER (https://redirect.github.com/duckdb/duckdb/pull/25031)

  Unflavored-from: b154749af1cd4cd8fde727e365e6929f9c3ef897

- Update vendored sources to duckdb/duckdb@8c813ca680e2a71e296b42b41dce9e54686d25d8.

  Date: 2026-08-31 09:28:12 +0000

  Update httplib (https://redirect.github.com/duckdb/duckdb/pull/25091)

  R-side fix:

  `patch/0012-httplib-rand.patch` is retired here.

  The patch replaced `std::rand()` in `detail::random_string()`
  with R's `unif_rand()`,
  because `R CMD check --as-cran` flags a system RNG entry point
  in compiled code.
  This commit bumps httplib from 0.27.0 to 0.53.1
  and rewrites `httplib.hpp` wholesale,
  and the new `random_string()` seeds a `std::mt19937`
  from `std::random_device` instead of calling `std::rand()`.
  No `std::rand` or `srand` call remains anywhere under `src/duckdb/`,
  so the entry point the patch existed to remove is gone from upstream's
  own code.

  Re-rooting was not available:
  the patch neither applies nor reverses against the rewritten file
  (`vendor-one.sh`'s `PATCH BROKEN` exit),
  and the two lines it edited no longer exist in that shape.
  So its effect is now upstream's, reached by different means,
  which is what retiring a `patch/` entry means.

  The rewritten file was also read for the other entry points
  `R CMD check` flags: its 29 `exit(` hits are all `detail::scope_exit`,
  and it contains no `fprintf(stderr`, `std::cerr` or `abort(`.

  Unflavored-from: ff593129165d61b2cdd77d7bf25e129034f5acb7

- Update vendored sources to duckdb/duckdb@7f78ec0b3090cb6a5d8488c8dc61e752cc22cc28.

  Date: 2026-08-31 09:06:07 +0000

  Bump Postgres, MySQL and SQLite (https://redirect.github.com/duckdb/duckdb/pull/25131)

  Unflavored-from: 7a7e1013ee721c200a2d1ea896c0ac63956e0cc7

- Update vendored sources to duckdb/duckdb@06094e14c8534f4fe53d431cd5eaa0ec9bca404c.

  Date: 2026-08-31 08:56:24 +0000

  Fix incorrect column expansion (https://redirect.github.com/duckdb/duckdb/pull/25096)

  Unflavored-from: 066bc41b58750e13a5349284e1d549f3529436f9

- Update vendored sources to duckdb/duckdb@db8c4233ba566227dc14935b1935623778a975b1.

  Date: 2026-08-31 08:47:02 +0000

  Fix overflowing interval ago negation (https://redirect.github.com/duckdb/duckdb/pull/25120)

  Unflavored-from: 9e6dd9014875ac1f293545a0516ec0e73f3fe3b4

- Update vendored sources to duckdb/duckdb@a9e701449e46ad9dbc9006518a1328ecd2948d79.

  Date: 2026-08-31 08:42:07 +0000

  Fix `round` overflow (https://redirect.github.com/duckdb/duckdb/pull/25125)

  Unflavored-from: 5602f41496a821dca4ab5b3c35d940d3f0c02ee9

- Update vendored sources to duckdb/duckdb@7f3e74d011f0f30a91b18e1929abf383e2d4f535.

  Date: 2026-08-31 08:39:00 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10580: Streaming Window States (https://redirect.github.com/duckdb/duckdb/pull/25114)

  Unflavored-from: e3fb43769b70a96de987fa6ba5d748f82b01ac6e

- Update vendored sources to duckdb/duckdb@8208d47949bab0210c5b44b74f13904bc2fe5390.

  Date: 2026-08-31 08:37:52 +0000

  Propagate stats for CASE expression (https://redirect.github.com/duckdb/duckdb/pull/25128)

  Unflavored-from: d24dcc735ad73bfc457fb72433397a940ce7e001

- Update vendored sources to duckdb/duckdb@262ca01b644d796a210aa365cbb2cf1f0f105fac.

  Date: 2026-08-31 08:04:05 +0000

  Simplify NULL in predicate-root ORs (https://redirect.github.com/duckdb/duckdb/pull/25160)

  Unflavored-from: d27282dab0b72b337e5625f012d8a377bef17613

- Update vendored sources to duckdb/duckdb@173106cb93d1159e0530a7425842881348caf658.

  Date: 2026-08-31 07:51:27 +0000

  Prune row groups for column-constant OR (https://redirect.github.com/duckdb/duckdb/pull/24963)

  Unflavored-from: 994b0afb31e463b3ee05048893bd1a6869ea87c3

- Update vendored sources to duckdb/duckdb@678fc2f9ec3139f904ca1937c0482255911d5fc9.

  Date: 2026-08-31 07:49:28 +0000

  Maintain distinct statistics on ALTER TYPE and ADD COLUMN (https://redirect.github.com/duckdb/duckdb/pull/24996)

  Unflavored-from: 176714a3e2604b6a0c6a49d5a909dddc2c29e30d

- Update vendored sources to duckdb/duckdb@58551021343c987188592f45b1beeac73924ffd0.

  Date: 2026-08-31 07:48:34 +0000

  Add reusable logical plan column binding verification (https://redirect.github.com/duckdb/duckdb/pull/25045)

  Unflavored-from: c40af1863992e7cbf94b842e0f726fd3822f011a

- Update vendored sources to duckdb/duckdb@d11eafc993253c6fda8918b47b5fcc3508ac1792.

  Date: 2026-08-31 07:46:57 +0000

  Update mbedtls to 3.6.7. Update diff and python script (https://redirect.github.com/duckdb/duckdb/pull/25051)

  Unflavored-from: a779f3004c252a4dbd1cf6e6659327b7e255c690

- Update vendored sources to duckdb/duckdb@b18b93b7beb34ddec419f65d67c715a4f521853b.

  Date: 2026-08-31 07:46:29 +0000

  Use CompressionSegmentReader for validity and bitpacking (https://redirect.github.com/duckdb/duckdb/pull/24911)
  Decouple the sqllogictest runner from Catch behind a TestReporter (https://redirect.github.com/duckdb/duckdb/pull/25093)

  Unflavored-from: b57028913171d37624cb0160905aeceddab60c90

- Update vendored sources to duckdb/duckdb@1386ff2e701ee90a40abd3fee72a837d3a638297.

  Date: 2026-08-31 07:42:07 +0000

  Do not reuse blocks freed by a checkpoint until its header is durable (https://redirect.github.com/duckdb/duckdb/pull/25106)

  Unflavored-from: c5e4316b1b2a030428edd70756fb74d21edb8a39

- Update vendored sources to duckdb/duckdb@f58fff813694875f96ff254444b243527b50d3b9.

  Date: 2026-08-31 07:30:50 +0000

  Address compilation warning (https://redirect.github.com/duckdb/duckdb/pull/25105)

  Unflavored-from: 59b39efecea76b4cca62bc5a30e2ee6149207cf0

- Update vendored sources to duckdb/duckdb@b1dfd3b5ad82e3f6dd88e9ab591053a54de7cbc6.

  Date: 2026-08-31 07:30:40 +0000

  Check size for strptime (https://redirect.github.com/duckdb/duckdb/pull/25104)

  Unflavored-from: 974834681bfabb8725e989175bd9f245c5f74c08

- Update vendored sources to duckdb/duckdb@613e50f274bdf14af3b5ceaec48c71a2d90de6c6.

  Date: 2026-08-31 07:25:03 +0000

  Fix crash in Top-N with LIMIT 0 (https://redirect.github.com/duckdb/duckdb/pull/24794) (https://redirect.github.com/duckdb/duckdb/pull/25101)
  Internal https://redirect.github.com/duckdb/duckdb/pull/10579: .manual Light Mode (https://redirect.github.com/duckdb/duckdb/pull/25102)

  Unflavored-from: 4cd2587e9555fe3bafdf2947555f002671922714

- Update vendored sources to duckdb/duckdb@f784cbb754e6e289e1e69e2407268323d6e8e2e0.

  Date: 2026-08-31 07:19:35 +0000

  Issuehttps: //redirect.github.com/duckdb/duckdb/pull/25071: Interval Colon Overflow (https://redirect.github.com/duckdb/duckdb/pull/25116)
  Unflavored-from: c01c0a839434be878016be033e22989107dbcd2a

- Update vendored sources to duckdb/duckdb@da0a07befd42a0fada11d44a2ae5f5c56088545e.

  Date: 2026-08-31 07:17:20 +0000

  Fix signed integer overflow via negation of INT64_MIN interval microseconds (https://redirect.github.com/duckdb/duckdb/pull/25138)

  Unflavored-from: 1b51016eb9d829fb3041c0ca8db960ad29822b1c

- Update vendored sources to duckdb/duckdb@0c7ab0d114e740bd0c4ad0aeb4a3ecfbce9893ae.

  Date: 2026-08-31 07:13:02 +0000

  Fix out-of-bounds path offset for file:// URIs without a path (https://redirect.github.com/duckdb/duckdb/pull/25151)

  Unflavored-from: 14f8dbd1d7556a018ea6390f6a4270ba7f7d534d

- Update vendored sources to duckdb/duckdb@a46abc251201529eb59e0632ae7379bcba372dbe.

  Date: 2026-08-31 07:09:51 +0000

  Propagate stats for sum aggregation function (https://redirect.github.com/duckdb/duckdb/pull/25146)

  Unflavored-from: 18b6cb9af376373014755da4a168e2ad64cadc81

- Update vendored sources to duckdb/duckdb@e0b375a9a0d52c40803e989ca030d05c99d56299.

  Date: 2026-08-31 07:08:50 +0000

  Do not corrupt the transaction lists when an allocation fails (https://redirect.github.com/duckdb/duckdb/pull/25149)

  Unflavored-from: 5cc1a2035a72c1529ed31f356a7c8a72e0d272d5

- Update vendored sources to duckdb/duckdb@edd0259ec0a6e1b1269e7a86e042504f1fdddc84.

  Date: 2026-08-31 07:06:34 +0000

  Remove `BoundExpression` (https://redirect.github.com/duckdb/duckdb/pull/25150)
  Enable LTO for linux release and glibc CLI builds in CI (https://redirect.github.com/duckdb/duckdb/pull/25126)

  Unflavored-from: 71756b3e5485eccb1e5d9dbf0df46967037da1f3

- Update vendored sources to duckdb/duckdb@3d889e43d625390cc4025a61484391ab7f659bfe.

  Date: 2026-08-31 06:51:57 +0000

  Fix use-after-free on EXECUTE of prepared table functions that bind a catalog entry (https://redirect.github.com/duckdb/duckdb/pull/25153)

  Unflavored-from: f742c6b3adca676141a581b30dc0d0ffb3bbb4e8

- Update vendored sources to duckdb/duckdb@7d7fa4996bd5e34cf32cff1b55d23c0442a3f551.

  Date: 2026-08-31 06:50:25 +0000

  Propagate numeric stats for unsigned integers (https://redirect.github.com/duckdb/duckdb/pull/25154)

  Unflavored-from: 5164772f3cbacd1c6a8d217ba422ee800297c603

- Update vendored sources to duckdb/duckdb@20856e03dfc9495a38a40bff12e698010f322061.

  Date: 2026-08-31 06:49:44 +0000

  Fix distinct comparisons in index value extraction (https://redirect.github.com/duckdb/duckdb/pull/25156)

  Unflavored-from: 7bf0967ac9f40d5f805d8f54f8adbaebe994885a

- Update vendored sources to duckdb/duckdb@bc7b2e5d763b5b066928016f3d32bf83d189576e.

  Date: 2026-08-31 06:46:10 +0000

  \[Dev\] Check the result of calling `weak_ptr::lock` in `StreamQueryResult` creation (https://redirect.github.com/duckdb/duckdb/pull/25161)

  Unflavored-from: b53187092e68d5b9068682a1e1225d7729e207f2

- Update vendored sources to duckdb/duckdb@8616efa9da9921b9111fe46373af7936a5d96d16.

  Date: 2026-08-28 17:48:55 +0000

  ISSUE-21492: Optimizer: fold `struct_extract(struct_pack(...))` for table subscripts (https://redirect.github.com/duckdb/duckdb/pull/25059)
  Run osx workflow in main CI based on changed files (https://redirect.github.com/duckdb/duckdb/pull/25073)

  Unflavored-from: fc1769240a969d2f1d999a413edd98293fa42a95

- Update vendored sources to duckdb/duckdb@5d2a3013d29b85bb1be0eb9beb47f690600557c4.

  Date: 2026-08-28 12:29:48 +0000

  Validate block allocation sizes and validity masks (https://redirect.github.com/duckdb/duckdb/pull/25076)

  Unflavored-from: d069039ba5a9a9b64e58b07d4b8af4944cefea24

- Update vendored sources to duckdb/duckdb@a408c9fa12df118bdfba152cc92266347ebb72f2.

  Date: 2026-08-28 12:22:19 +0000

  `Index` lifetime refactor (https://redirect.github.com/duckdb/duckdb/pull/23570)

  Unflavored-from: d6497c60b39e7ba0e2810e21c5553c4a3158f3e2

- Update vendored sources to duckdb/duckdb@ea5ea0414a430c08ec7bbe342e8827fe4adcf347.

  Date: 2026-08-28 12:21:32 +0000

  Prune row group for `list_position` function (https://redirect.github.com/duckdb/duckdb/pull/25079)
  tighten rclone ext push, avoid pre-PUT HEAD call (https://redirect.github.com/duckdb/duckdb/pull/25080)
  Expand on https://redirect.github.com/duckdb/duckdb/pull/25006, type recursion is also needed (https://redirect.github.com/duckdb/duckdb/pull/25077)

  Unflavored-from: f7fe2b9d61887ab185cb1473224217ed8bc51f0f

- Update vendored sources to duckdb/duckdb@e3260d603d67bb942c83f2a78ae94113db6e4eec.

  Date: 2026-08-28 09:23:34 +0000

  External Extension Repositories (https://redirect.github.com/duckdb/duckdb/pull/24777)

  Unflavored-from: 1bf62fbc489a2d2149ad947a774724a7fac23073

- Update vendored sources to duckdb/duckdb@3f8ec96b1a21cf6a466f834efc31203b2ceab68d.

  Date: 2026-08-28 08:04:51 +0000

  Fix foreign key side effects in `CREATE TABLE IF NOT EXISTS` (https://redirect.github.com/duckdb/duckdb/pull/25044)

  Unflavored-from: 42347ebb34580c86508de72e3bcb6c2189103c19

- Update vendored sources to duckdb/duckdb@f41b3d57953cfb0338f1784d63af6903e56cbb8a.

  Date: 2026-08-28 08:01:53 +0000

  \[CAPI\]\[Extension\] Improve inline docs of extension loading API (V1 and V2) (https://redirect.github.com/duckdb/duckdb/pull/25055)
  Merge static libs jobs into Linux, macOS and Windows release CI jobs (https://redirect.github.com/duckdb/duckdb/pull/25067)

  Unflavored-from: a5201b9db6e9a6e57c564bea3048d456969b44ea

- Update vendored sources to duckdb/duckdb@39fd06fbbf60b5b58ad7113ae1328f7c2bbd8eaf.

  Date: 2026-08-28 07:30:28 +0000

  FinalizeScan() for MultiFileReader (https://redirect.github.com/duckdb/duckdb/pull/25036)

  Unflavored-from: 969a673245182e29b58c538813c5d28ac7cf77bb

- Update vendored sources to duckdb/duckdb@9bc2de59ad8248af18f2e462ed8f90dacb69494d.

  Date: 2026-08-28 07:28:32 +0000

  Prune segment on FALSE_OR_NULL (https://redirect.github.com/duckdb/duckdb/pull/25064)

  Unflavored-from: 01447c5c56c7f13552ef52a888c62c89fcc426d2

- Update vendored sources to duckdb/duckdb@89f942c62536ee1add2a4c991298d9e4ce28782e.

  Date: 2026-08-28 07:20:53 +0000

  Prune row group on FALSE_OR_NULL (https://redirect.github.com/duckdb/duckdb/pull/25063)

  Unflavored-from: 7382feb92a2423d133658359a859b5530332cfae

- Update vendored sources to duckdb/duckdb@53c33180ba7dd1c2a86df3cc5680adfef49029dd.

  Date: 2026-08-28 07:20:12 +0000

  Prune numeric comparison for NOTEQUAL / DISTINCT_FROM operation (https://redirect.github.com/duckdb/duckdb/pull/25061)
  Use clang for most CI jobs (https://redirect.github.com/duckdb/duckdb/pull/25053)

  Unflavored-from: afd8e3da9be8377cfa8d55a4fb3d2f54d519f96e

- Update vendored sources to duckdb/duckdb@126dd29c098af0034a5d0322ab18c55c55ec443a.

  Date: 2026-08-27 17:58:02 +0000

  Do not retry non-idempotent HTTP requests (https://redirect.github.com/duckdb/duckdb/pull/25047)

  Unflavored-from: b2f2d67ed1ed6493fb64b9ba0e21025f1030a05b

- Update vendored sources to duckdb/duckdb@98b6abb501a9ac08fa6897540a52303466099417.

  Date: 2026-08-27 15:05:12 +0000

  Avoid overwriting streaming NTH_VALUE result on NULL rows (https://redirect.github.com/duckdb/duckdb/pull/24861)

  Unflavored-from: cb3ba0a0eb002644796c34afb2b54c68c2682036

- Update vendored sources to duckdb/duckdb@dbec108456d3b9f914b137dabb390e3e9b1d5a33.

  Date: 2026-08-27 13:39:51 +0000

  Propagate stats for aggregate functions (https://redirect.github.com/duckdb/duckdb/pull/24997)

  Unflavored-from: 0f6cfdd76e6df265597da727a5f089683775b48c

- Update vendored sources to duckdb/duckdb@000493d52db02b61befd587483fc9f7a81c93eb0.

  Date: 2026-08-27 13:39:27 +0000

  Prune row group for `list_contains` function (https://redirect.github.com/duckdb/duckdb/pull/24876)

  Unflavored-from: 2040d68206b386c87934948af6cf8fab9064d419

- Update vendored sources to duckdb/duckdb@7ea45a710c8ac6e44c616f54a2cf898d1f7f3f9e.

  Date: 2026-08-27 13:30:32 +0000

  Avoid reconstructing CountZeros lookup tables (https://redirect.github.com/duckdb/duckdb/pull/25032)

  Unflavored-from: 59e614ee1c3f81eafec5f316f7cc73268f6b9ee5

- Update vendored sources to duckdb/duckdb@d7dcda12034a3d0d2c5f844a318471643d7506fb.

  Date: 2026-08-27 11:36:54 +0000

  Fix https://redirect.github.com/duckdb/duckdb/pull/25018: Throw user-facing error when thread settings are NULL (https://redirect.github.com/duckdb/duckdb/pull/25021)

  Unflavored-from: 7cd112890a75a40fcbe9257659de00d314262d1d

- Update vendored sources to duckdb/duckdb@73ee3f2d46fc790ae2c98a6505dc8462e6245b7e.

  Date: 2026-08-27 11:21:21 +0000

  Adjacent string fixes (https://redirect.github.com/duckdb/duckdb/pull/25034)

  Unflavored-from: 0e396e80ac796cbb1257792ab5f7c22abc312f80

- Update vendored sources to duckdb/duckdb@18ba43ac96f5efcee07fc630a8509aa4b2b85a2c.

  Date: 2026-08-27 11:14:32 +0000

  \[Dev\] Fix unity build + remove third-party include from public-facing header (https://redirect.github.com/duckdb/duckdb/pull/25043)

  Unflavored-from: 7ad52ce3e711a776996f827945fb0f16fa3e0dad

- Update vendored sources to duckdb/duckdb@5af93a8f3d18cc79bbff380af09965d2cec4d619.

  Date: 2026-08-27 11:05:23 +0000

  \[Dev\] Fix `PhysicalIEJoin` out-of-bounds access on `completed` (https://redirect.github.com/duckdb/duckdb/pull/25042)

  Unflavored-from: bc318e3e607a09d7142b1f5438055ae6cbbfe950

- Update vendored sources to duckdb/duckdb@6de3fba3572c013134019d9b127d085b15b97e7c.

  Date: 2026-08-27 10:46:56 +0000

  Propagate column renames to trigger UPDATE OF lists (https://redirect.github.com/duckdb/duckdb/pull/24578)
  Unify linux release builds (https://redirect.github.com/duckdb/duckdb/pull/25023)
  Add value-level tests for window self-join ROWS framing (close https://redirect.github.com/duckdb/duckdb/pull/21592) (https://redirect.github.com/duckdb/duckdb/pull/24164)

  Unflavored-from: 5cd48aea4d4748a8cdd29d43ebce7c17a5e35cbf

- Update vendored sources to duckdb/duckdb@465353c94cb921025472eb9e70f26a12fc2104a8.

  Date: 2026-08-27 07:50:34 +0000

  Fix with argument ordering to correctly handle frames that exclude the current row (https://redirect.github.com/duckdb/duckdb/pull/24875)

  Unflavored-from: 1dfc5d6ebc4ac41f658a37e92a8637095c068453

- Update vendored sources to duckdb/duckdb@09e9d402b5f94aaa8bc0c64d83a93f6216f26ff3.

  Date: 2026-08-27 07:50:08 +0000

  Fix incorrect filtered MAD window results by correctly counting rows across excluded subframes (https://redirect.github.com/duckdb/duckdb/pull/24847)

  Unflavored-from: eef22b49cdeee56a458ac76a5655545edcfd9124

- Update vendored sources to duckdb/duckdb@2756f0265561e29caea8750fb373e6fa1c9b79bf.

  Date: 2026-08-27 07:47:58 +0000

  Fix COUNT(x) still reading the counted column after the COUNT(\*) rewrite (https://redirect.github.com/duckdb/duckdb/pull/24607)

  Unflavored-from: 4b0cf7c592457d1be33a4c47410494de87c0fc25

- Update vendored sources to duckdb/duckdb@d99587345c05f20e036ff9088f0f0f69b775e410.

  Date: 2026-08-26 12:37:50 +0000

  Preserve filter rewrites across pushdown and statistics propagation (https://redirect.github.com/duckdb/duckdb/pull/24907)

  Unflavored-from: 260376173df09029b613e957eb68e6aa61c85541

- Update vendored sources to duckdb/duckdb@7110bfecb1476267410160d17154069f2700c7f2.

  Date: 2026-08-26 11:27:34 +0000

  Resolve decimal to double cast benchmark regression (https://redirect.github.com/duckdb/duckdb/pull/24922)

  Unflavored-from: 2a1efd333469fc6f47b74269d95282ad20412346

- Update vendored sources to duckdb/duckdb@6ebca1a8818e30f012f4befcfc3df34afcd860aa.

  Date: 2026-08-26 11:24:42 +0000

  Clean up files created by `COPY` if query aborts (https://redirect.github.com/duckdb/duckdb/pull/24840)

  Unflavored-from: 60a6b1bda2beb4c1275b586b5e08946b380ede33

- Update vendored sources to duckdb/duckdb@0e7758579156be5ac6b00a0d980f106326612a30.

  Date: 2026-08-26 09:31:05 +0000

  Fix typed NULL value stringification bug that loses type information (https://redirect.github.com/duckdb/duckdb/pull/25002)
  Use -march=haswell for windows_amd64_mingw (GCC 10 breaks) (https://redirect.github.com/duckdb/duckdb/pull/25029)
  Fix mixed path separators for extension/loader in amalgamation (https://redirect.github.com/duckdb/duckdb/pull/25025)

  Unflavored-from: 84c19655efc8be08136931c1c72bcc11839d92fd

- Update vendored sources to duckdb/duckdb@3c7c8b2b7f111afad7badb60bf705c420bdefa0b.

  Date: 2026-08-26 07:38:03 +0000

  Preserve selected domains during delim join rewriting (https://redirect.github.com/duckdb/duckdb/pull/24915)

  Unflavored-from: 97eff1f1063e6c7f8930c591aa8c107bf229eea5

- Update vendored sources to duckdb/duckdb@33e8fa9c3c8426e1446d61b1dafdc3f051673dab.

  Date: 2026-08-26 07:34:16 +0000

  Prune row group for no-op replace (https://redirect.github.com/duckdb/duckdb/pull/24044)

  Unflavored-from: 812016ea5f2079f2f895b40f6e33cf9bb396ea49

- Update vendored sources to duckdb/duckdb@3286754ae9bea04519d43d466e7acc1da50e0cbc.

  Date: 2026-08-26 06:57:32 +0000

  Fix ALTER TYPE dropping concurrently committed updates (https://redirect.github.com/duckdb/duckdb/pull/25008)

  Unflavored-from: d9a83d7c3ee9e610e0a89d107f4fe6a5253dcdf4

- Update vendored sources to duckdb/duckdb@de5c0281d57c1cdcdb250d8ae8d774da74e18fc4.

  Date: 2026-08-26 06:46:11 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10514: AsOf Progress (https://redirect.github.com/duckdb/duckdb/pull/25020)
  Internal https://redirect.github.com/duckdb/duckdb/pull/10417: AsOf Hive Partitioning (https://redirect.github.com/duckdb/duckdb/pull/25016)

  Unflavored-from: bebaeb1b47100b3121f0def3059b3ea6b74e6b62

- Update vendored sources to duckdb/duckdb@350d1a68e4aeca70409e70958273b3f1d0d27a85.

  Date: 2026-08-26 05:41:42 +0000

  Fix wrong results when constant folding MAX_INT (https://redirect.github.com/duckdb/duckdb/pull/24998)
  Upload latest alpha version file to staging bucket (https://redirect.github.com/duckdb/duckdb/pull/24894)

  Unflavored-from: 1407caa1603934351eb964ef5e90f41126401fed

- Update vendored sources to duckdb/duckdb@f1c54da78bf9918465c2603a20879184291082f0.

  Date: 2026-08-25 14:34:17 +0000

  Correctly handle nested schemas in remote pushdown optimizer (https://redirect.github.com/duckdb/duckdb/pull/25009)
  \[JSON\] Fix `DECIMAL` value roundtrip bug that was caused by lossy `json_read` behavior (https://redirect.github.com/duckdb/duckdb/pull/25006)

  Unflavored-from: 83b3bf0f5b18c1341f4f6bc5af81a49101e21672

- Update vendored sources to duckdb/duckdb@5efbc8a5db517d6ae8256b133e47e03f6a5cbe84.

  Date: 2026-08-25 14:08:54 +0000

  Raise an error on integer division by zero instead of returning NULL (https://redirect.github.com/duckdb/duckdb/pull/25004)

  Unflavored-from: cc4e3070087287d14a58b7bb5e458712137c9824

- Update vendored sources to duckdb/duckdb@6944b828b99f1e4ff836c25c1416f0254363f932.

  Date: 2026-08-25 12:49:15 +0000

  \[Dev\]\[Parser\] Fix `MatchParseResult` regression (https://redirect.github.com/duckdb/duckdb/pull/25007)

  Unflavored-from: b0dac942129b3f9ead0c7b70f5b1e0473053cb11

- Update vendored sources to duckdb/duckdb@95697fa642c7ccd4514284ef0d7cdd2e82667d48.

  Date: 2026-08-25 11:52:34 +0000

  In nested schema resolution - avoid hardcoding the DuckDB catalog (https://redirect.github.com/duckdb/duckdb/pull/25005)

  Unflavored-from: 1864e7f8f6b278ed64d8b212e11fb7c108624f5b

- Update vendored sources to duckdb/duckdb@b574a596f05110f706aba188a69233813f51ee25.

  Date: 2026-08-25 11:38:15 +0000

  Allow extension to register custom compression filesystem (https://redirect.github.com/duckdb/duckdb/pull/24968)

  Unflavored-from: baabcce4492d126e27fd6b6daa836ed2e418c3e0

- Update vendored sources to duckdb/duckdb@db193c5dd93847ac31ca45e5b92bfd4ffee6395e.

  Date: 2026-08-25 11:01:15 +0000

  Use unchecked casts for proven integer ranges (https://redirect.github.com/duckdb/duckdb/pull/24916)

  Unflavored-from: 9d6e59b79d03e0898a36ad93de0a99f8a90db9ed

- Update vendored sources to duckdb/duckdb@eea3e0c600b965239660a77dbb416ece04f2312a.

  Date: 2026-08-25 10:50:22 +0000

  Prune row groups for length()/char_length() filters via code-point lower bound (https://redirect.github.com/duckdb/duckdb/pull/24999)

  Unflavored-from: 3a60bb42c4bfd1c20b277e260bcda9bc4ba4ebb9

- Update vendored sources to duckdb/duckdb@a0f16b1dbae92acadf0b97120785c31d2c8102f7.

  Date: 2026-08-25 10:13:45 +0000

  Optimize StringUtil::Replace (https://redirect.github.com/duckdb/duckdb/pull/24990)

  Unflavored-from: a9b5956625f5bdaa09cd42b4a389492cb7246d7a

- Update vendored sources to duckdb/duckdb@2dc513f35986a5d8a3c4885e98fa2ca664cf2a1a.

  Date: 2026-08-25 09:20:40 +0000

  Avoid busyloop on task cancellation (https://redirect.github.com/duckdb/duckdb/pull/24544)

  Unflavored-from: c6c13b5779b98235d71bd9c1d22910b6238afa88

- Update vendored sources to duckdb/duckdb@0656b54398aec122dd136a80fead87c97829054a.

  Date: 2026-08-25 08:44:53 +0000

  Fix COPY FROM with statement triggers (https://redirect.github.com/duckdb/duckdb/pull/23896)

  Unflavored-from: b3ca1abdd2d3f82d3dbcdd99995148b7d0e14efc

- Update vendored sources to duckdb/duckdb@721479585fb6d907866d52587592c6458298916d.

  Date: 2026-08-25 08:20:17 +0000

  Implement date time row group pruning (https://redirect.github.com/duckdb/duckdb/pull/24943)

  Unflavored-from: 7231a5bd6660a5676e5b88307434b20c5cebb790

- Update vendored sources to duckdb/duckdb@3e994341644dbd9e50adb23f496b8aba7ba6e088.

  Date: 2026-08-25 08:20:04 +0000

  Prune row group for string contains on equal strings (https://redirect.github.com/duckdb/duckdb/pull/24940)

  Unflavored-from: 5606c22d6d80148599e74b22047e971f43e8ec7a

- Update vendored sources to duckdb/duckdb@721f57a9a4d391b97b9626e4d390cbd998556541.

  Date: 2026-08-25 08:13:28 +0000

  Try -march x86-64-v3 for CLI and v2 for extensions (https://redirect.github.com/duckdb/duckdb/pull/24391)

  Unflavored-from: 1c7307b26de0ef74a61b31381006867ed4138d4f

- Update vendored sources to duckdb/duckdb@c949e7ae0accd78e9731d3042d38b215575ebad8.

  Date: 2026-08-25 08:05:31 +0000

  Propagate stats for `left` function to prune row group (https://redirect.github.com/duckdb/duckdb/pull/24951)

  Unflavored-from: bae949b0fbedc757f98200cdb36c4aca5bb5c74e

- Update vendored sources to duckdb/duckdb@8c4d17a0d81f376a10bf2db9e7054e1a7626fa35.

  Date: 2026-08-25 08:05:18 +0000

  Prune row group for prefix functions (https://redirect.github.com/duckdb/duckdb/pull/24953)

  Unflavored-from: 90a78d36eac9ddfbc8c569efacc1492ecacc8368

- Update vendored sources to duckdb/duckdb@44d8622a70dbb419bc7b03fa0c867a3ff6586f89.

  Date: 2026-08-25 08:05:00 +0000

  Propagate case conversion stats for row group prune (https://redirect.github.com/duckdb/duckdb/pull/24954)

  Unflavored-from: 7999c8de3307404e77f4a052043cee75dd333114

- Update vendored sources to duckdb/duckdb@53f415c52055948f427c3491b28ded61c337cf53.

  Date: 2026-08-25 08:04:46 +0000

  Propagate stats for coalesce operator (https://redirect.github.com/duckdb/duckdb/pull/24958)

  Unflavored-from: 93611095dc26650b25afd69850a7218ffab9c96b

- Update vendored sources to duckdb/duckdb@88aef8e4b68b44fd1a9b8274d7f24e9d855934bf.

  Date: 2026-08-25 08:04:30 +0000

  Propagate stats for devision operator (https://redirect.github.com/duckdb/duckdb/pull/24959)

  Unflavored-from: a8316bcb36c0abbdc38c23aad7f812beca42957b

- Update vendored sources to duckdb/duckdb@c59308b487abc1d29d958c9e19b39e95e704471e.

  Date: 2026-08-25 07:52:25 +0000

  Allow TablaAliasColon for subqueries (https://redirect.github.com/duckdb/duckdb/pull/24524)

  Unflavored-from: 028445cf6f8c93ead910dfdc3f2bce9e04991dee

- Update vendored sources to duckdb/duckdb@e04de9a2e7bc430c90f1f8024ad2e76032be8ba7.

  Date: 2026-08-25 07:48:22 +0000

  Fix trigger dependency tracking so DROP TABLE respects trigger bodies (https://redirect.github.com/duckdb/duckdb/pull/24591)

  Unflavored-from: 9d0c43a764dd0be039c9fe4be6cf184a2a8cff9f

- Update vendored sources to duckdb/duckdb@b929b8640f8722144bc0474dae4277148240a57e.

  Date: 2026-08-25 07:47:11 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10417: AsOf Hive Partitioning (https://redirect.github.com/duckdb/duckdb/pull/24891)

  Unflavored-from: f9efb1490a464d0f5dcf1c9d019ce8e68a71bfa3

- Update vendored sources to duckdb/duckdb@b9694071496e57998cf03268f1ce1859ad87fb6e.

  Date: 2026-08-25 07:03:01 +0000

  Dont remove lambda expressions from functions (https://redirect.github.com/duckdb/duckdb/pull/24970)

  Unflavored-from: 3b1b03c7cf44be8dc706823b09599b97416269fa

- Update vendored sources to duckdb/duckdb@73bf1c60a7ccb9bef5a437700684da032f235c9c.

  Date: 2026-08-25 06:58:21 +0000

  \[Serialization\]\[Parquet\]\[Variant\] Fix bug related to `ShreddingType` equality operator (https://redirect.github.com/duckdb/duckdb/pull/24982)

  Unflavored-from: 9002993dc6dc8ff2aeee8260a4441f8249d7b0ac

- Update vendored sources to duckdb/duckdb@de5edf51ebcc66861905c4dceb10353ab33bcac7.

  Date: 2026-08-25 06:57:09 +0000

  Propagate stats for timestamp conversion (https://redirect.github.com/duckdb/duckdb/pull/24995)

  Unflavored-from: 1abdc85023d6b489ae62ce826fd81086ff6ceb34

- Update vendored sources to duckdb/duckdb@aeb4437f53bdab757c7cda16204224c5cfe09d7a.

  Date: 2026-08-25 06:56:02 +0000

  Fix TIMETZ formatting (https://redirect.github.com/duckdb/duckdb/pull/24988)

  Unflavored-from: 1b12c9fe91eec24cd0f353bbed3fccf5a892a93a

- Update vendored sources to duckdb/duckdb@541e8a2797ff2e6f430793a4e4919de38ca40ffd.

  Date: 2026-08-25 06:55:32 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/24449: MINMAX Constant N (https://redirect.github.com/duckdb/duckdb/pull/24986)

  Unflavored-from: bd57e6e7235f48c9c7e7834c5213833c9ca0cef3

- Update vendored sources to duckdb/duckdb@169987abf3fcf2d4726af3784968e96c0cc84182.

  Date: 2026-08-25 06:53:44 +0000

  GetDefaultSchema returns optional (https://redirect.github.com/duckdb/duckdb/pull/24979)

  Unflavored-from: 246725f207dbbedcff03b60303af0cb814fac744

- Update vendored sources to duckdb/duckdb@a7501a2c32de2dc6c126148f90c4d4c9f33036aa.

  Date: 2026-08-25 06:46:34 +0000

  Mark `last_day` function fallible (https://redirect.github.com/duckdb/duckdb/pull/24974)

  Unflavored-from: ee8f9b70a4a5880e9f59bded71dc5857d51bba3f

- Update vendored sources to duckdb/duckdb@94342607abc11b7e12cefd4aabec727b2c02c068.

  Date: 2026-08-25 06:46:21 +0000

  Fix `Value::ToSQLString` nested type round-tripping (https://redirect.github.com/duckdb/duckdb/pull/24975)

  Unflavored-from: cd229db5b9ca5c6992aa19afda18768cbda48cf2

- Update vendored sources to duckdb/duckdb@6c4585d9aa4179810707b1d25868917b6520e284.

  Date: 2026-08-25 06:44:31 +0000

  Unify `Match` and `MatchParseResult` (https://redirect.github.com/duckdb/duckdb/pull/24912)

  Unflavored-from: 4fb3108244313f00aebb75b9622084a4764aa7b0

- Update vendored sources to duckdb/duckdb@224ce6a723c9b7ac24278b9cb01d38e5a1d5daf2.

  Date: 2026-08-25 05:53:47 +0000

  \[ASYNC I/O\] Read Ahead Refactor (https://redirect.github.com/duckdb/duckdb/pull/24778)

  Unflavored-from: 8bddf2a5108aaa1e1d15d4fb80fe766013b5c5d0

- Update vendored sources to duckdb/duckdb@6a3a26ffa866fcfccb74bbc1a9780b00a9ba082d.

  Date: 2026-08-24 15:58:21 +0000

  Arena allocate per-group buffers in bitstring_agg, bit_and/bit_or/bit_xor, and mode (https://redirect.github.com/duckdb/duckdb/pull/24855)

  Unflavored-from: 0629d3c5333a7ceecdb6372e6446d24f01246e7f

- Update vendored sources to duckdb/duckdb@e3b83ab494b94761932aa66d750e149584b18a02.

  Date: 2026-08-24 15:31:26 +0000

  Fix INTERNAL error when the invoke() lambda throws (https://redirect.github.com/duckdb/duckdb/pull/24668)

  Unflavored-from: 842011c8905a854952dee60054c4d8ebd29208c9

- Update vendored sources to duckdb/duckdb@9cef2c4b667a835e2b33a2856a5f24ddb5fb6c06.

  Date: 2026-08-24 14:30:53 +0000

  Add CompressionSegmentReader for fixed-size uncompressed segments (https://redirect.github.com/duckdb/duckdb/pull/24895)

  Unflavored-from: 1df9c4c7c89b1c0fbc28f177190790cd13c05639

- Update vendored sources to duckdb/duckdb@51f10049d7979db09cbf4238ab0307ced75092b6.

  Date: 2026-08-24 12:47:41 +0000

  Allocation connected bugs (https://redirect.github.com/duckdb/duckdb/pull/24893)

  Unflavored-from: 7d63e678fd620d75b938d8932846db0e63ac077c

- Update vendored sources to duckdb/duckdb@282b70bf86a4651eba8c2c191a792144f122949a.

  Date: 2026-08-24 11:38:10 +0000

  Honor the comment option when quoting CSV output (https://redirect.github.com/duckdb/duckdb/pull/23669)

  Unflavored-from: 50f72980af46db16200ec8e5f7cb006d3a241d25

- Update vendored sources to duckdb/duckdb@974e8faaacd8814aaa44538125dd7c924df2f664.

  Date: 2026-08-24 11:07:56 +0000

  Add overload: regexp_extract('string', 'pattern', 'options') (https://redirect.github.com/duckdb/duckdb/pull/24857)

  Unflavored-from: cb69365e31a0e45a7bde762ed50298707ec73d5e

- Update vendored sources to duckdb/duckdb@585c0649042179150720d4ababc45ca8c8089887.

  Date: 2026-08-24 10:55:04 +0000

  \[Parquet Stats\] Return parquet string stats exactness (https://redirect.github.com/duckdb/duckdb/pull/24886)

  Unflavored-from: c92bd22778e2d7766fa388884071eaa45e2a6cf1

- Update vendored sources to duckdb/duckdb@650864b74a92c0517756b81251bf5ebd6b5e0ee0.

  Date: 2026-08-24 10:51:43 +0000

  Preserve projection maps during column pruning (https://redirect.github.com/duckdb/duckdb/pull/24909)

  Unflavored-from: f9e78c1d37f65885057089da4f88ef4126afe015

- Update vendored sources to duckdb/duckdb@a2b9723cabd0c4db532fca0d70daa19f44447de7.

  Date: 2026-08-24 09:54:27 +0000

  C-API-V2: Part 1 (https://redirect.github.com/duckdb/duckdb/pull/24702)
  Use main container in more CI jobs (https://redirect.github.com/duckdb/duckdb/pull/24917)
  Fix async writer flaky test (https://redirect.github.com/duckdb/duckdb/pull/24952)

  Unflavored-from: 020e7b2b36c20d5d6fa42937fd76ab1f559725c1

- Update vendored sources to duckdb/duckdb@9d360460a41d7b01e6db2cc18d32718c6c7c3274.

  Date: 2026-08-24 07:41:27 +0000

  Parquet writer: write ColumnMetaData.encoding_stats (https://redirect.github.com/duckdb/duckdb/pull/24957)
  Allow some archs like musl to fail (for alpha releases) (https://redirect.github.com/duckdb/duckdb/pull/24928)
  re-enable art prefix test (https://redirect.github.com/duckdb/duckdb/pull/24930)

  Unflavored-from: fdb324999937b8504ec6f645fe03c9ff813c2af3

- Update vendored sources to duckdb/duckdb@1c0bb585969ea2fd25f73d415419fb93b0d2953e.

  Date: 2026-08-24 06:51:44 +0000

  Avoid plan-time partial precomputation when not complete (https://redirect.github.com/duckdb/duckdb/pull/24962)

  Unflavored-from: 8a9be01dba0c788028460762a8c9a2a6ae506a95

- Update vendored sources to duckdb/duckdb@125fec2e3a2b14b6539e16e33162b6ed6a995915.

  Date: 2026-08-24 06:50:29 +0000

  Abandon() and any_abandoned (https://redirect.github.com/duckdb/duckdb/pull/24947)

  Unflavored-from: dd87a45294fc4257805b784094df2dc24b87e5af

- Update vendored sources to duckdb/duckdb@0f0ab22b31311bef6943ed6622f2d1f790ce8754.

  Date: 2026-08-24 06:50:04 +0000

  Make `FunctionSet` and `Bound*Function` contain `shared_ptr<const Function>`s (https://redirect.github.com/duckdb/duckdb/pull/24964)

  R-side fix:

  A `FunctionSet`'s overloads are now immutable and shared, so neither
  mutating one in place nor calling a `Function` member through the
  returned handle compiles any more.

  `rapi_startup()` marked `arrow_scan`'s overloads
  `INITIALIZE_ON_SCHEDULE` by looping over `functions.functions` and
  assigning to each; that vector now holds `shared_ptr<const TableFunction>`. Upstream's replacement for exactly this is
  `FunctionSet::ApplyToFunctions()`, which copies each overload, applies
  the callback, and puts the modified copy back.

  `binary_dispatch()`'s error message called `ToString()` on the result of
  `GetFunctionByArguments()`, which now returns
  `shared_ptr<const ScalarFunction>` rather than a reference; dereference
  it.

  Carried from `origin/main-dev` at bbcee30b0:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Carried from `origin/v2.0-cyanoptera-dev` at a83c0b78b1:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 2138b79a8ff35349fb4b0de95f96acd3e2416330

- Update vendored sources to duckdb/duckdb@044a04a7cd39e6e8235f756597ae42dde084e5e5.

  Date: 2026-08-20 17:13:42 +0000

  Make `preserve_identifier_case` a three-state setting (https://redirect.github.com/duckdb/duckdb/pull/24375)

  Unflavored-from: 65621edcf4ef36317b377f7ad6db6b357c641c6f

- Update vendored sources to duckdb/duckdb@207586679841e4c310254deff10064362f5c97de.

  Date: 2026-08-20 17:06:51 +0000

  Restore static linking behaviour for C API (https://redirect.github.com/duckdb/duckdb/pull/24913)

  Unflavored-from: 8ecb6216f5c19dc4eb1b5e5eafde567d6b0c0801

- Update vendored sources to duckdb/duckdb@1c79cb15f515b02e65e8b07a4e0f155987d4d231.

  Date: 2026-08-20 16:57:47 +0000

  Fix qualified name APIs to correctly handle nested schemas (https://redirect.github.com/duckdb/duckdb/pull/24910)

  Unflavored-from: 557b2f0d935b3c17002066138e3ed4afd40f9f4d

- Update vendored sources to duckdb/duckdb@c04478b3576f08747a6b23fa549a8f89ccf1f8c6.

  Date: 2026-08-20 16:09:08 +0000

  ARM64 portability hardening: mechanical UB fixes without behavior change (https://redirect.github.com/duckdb/duckdb/pull/24884)

  Unflavored-from: 90132a701f6f312bb7228409af8a82f793411975

- Update vendored sources to duckdb/duckdb@df64b342372e225a74a83e66b5c7d530b097ff1c.

  Date: 2026-08-20 12:52:45 +0000

  Use Identifier for CSV/JSON column names in the COPY FROM bind path (https://redirect.github.com/duckdb/duckdb/pull/24839)

  Unflavored-from: 8a85a8852278e6234635a5697df4c6d5d59fcb73

- Update vendored sources to duckdb/duckdb@07194a2ca5b522aaf17ec1ca1a47b0e899a8e0a7.

  Date: 2026-08-20 12:47:47 +0000

  \[Dev\]\[Parser\] Add `ParsedGrammar` intermediate to `CompiledGrammar` creation (https://redirect.github.com/duckdb/duckdb/pull/24866)

  Unflavored-from: 3170af3fd8a7497d7e70b721cde4a88322e1034e

- Update vendored sources to duckdb/duckdb@ef367297c8096a95d91561e2c9888e8136678c1d.

  Date: 2026-08-20 11:56:13 +0000

  Add ToString SQLIdentifier::ToString for Identifier too (https://redirect.github.com/duckdb/duckdb/pull/24851)

  Unflavored-from: 28dcdc4719643c9da512715ae82fcf43bc15e505

- Update vendored sources to duckdb/duckdb@daf1098317959db9a983e0a7450ff455751d21ad.

  Date: 2026-08-20 11:07:50 +0000

  Checkpoint on detach description correction (https://redirect.github.com/duckdb/duckdb/pull/24887)

  Unflavored-from: d027640da556c66e01f0b01c5f9d0b091b679394

- Update vendored sources to duckdb/duckdb@2942c26fd7ed08b228b8bb9ef866c446439f351f.

  Date: 2026-08-20 09:54:01 +0000

  Add utf8_validation (strict, ignore, replace) to Parquet reader (https://redirect.github.com/duckdb/duckdb/pull/24743)

  Unflavored-from: 57f82eba703742d204d59fb39476f50d1138dc9d

- Update vendored sources to duckdb/duckdb@f065b389dc2d5e6d24fa5351bcc6e5ca029e92b3.

  Date: 2026-08-20 09:51:23 +0000

  Support SHOW (https://redirect.github.com/duckdb/duckdb/pull/23732)

  Unflavored-from: 71b63e0c47fb037683adb4338547e2a7079a6326

- Update vendored sources to duckdb/duckdb@c85c253088411e3fa958f594e043276d2c541473.

  Date: 2026-08-20 09:34:43 +0000

  Prune row groups with cross-column comparisons (https://redirect.github.com/duckdb/duckdb/pull/24805)
  Use container in regression CI jobs (https://redirect.github.com/duckdb/duckdb/pull/24889)

  Unflavored-from: 7fda20c43801cee2900eed6ea627ed5297221b57

- Update vendored sources to duckdb/duckdb@d7a4366603f70515b3dcedef169a311df914e39b.

  Date: 2026-08-20 06:59:54 +0000

  Remove default database (https://redirect.github.com/duckdb/duckdb/pull/24837)

  Unflavored-from: c1c24bd793337114481fd30bd7820803920ee534

- Update vendored sources to duckdb/duckdb@1db14f362be8fb4bc0af98cc40230e9de296b059.

  Date: 2026-08-20 06:59:16 +0000

  Fix top_n_window_elimination late materialization corrupting try-cast and nested-cast payloads (https://redirect.github.com/duckdb/duckdb/pull/24846)

  Unflavored-from: acf2440ce5c6ee20940e854cbcd1f7d1061cb671

- Update vendored sources to duckdb/duckdb@1eac65e7887762e639fcc61294d3f6e5425f8702.

  Date: 2026-08-20 06:51:08 +0000

  Don't narrow a pushed-down filter constant to the file's physical type (https://redirect.github.com/duckdb/duckdb/pull/24901)

  Unflavored-from: d2967203e3f5f2f439338b83ddb38fdcb2e7b9c3

- Update vendored sources to duckdb/duckdb@39b9f743512856d413c4c2c2f3dd89f37484dd20.

  Date: 2026-08-20 06:44:24 +0000

  Always quote identifiers in error messages (https://redirect.github.com/duckdb/duckdb/pull/24878)

  Unflavored-from: b8e8d88dfc0e1c69e1ce007bb3d65c127eb4b6b0

- Update vendored sources to duckdb/duckdb@8995d9aa3d1e23d72feaa708d5d25e7f3dfb58ef.

  Date: 2026-08-20 08:56:15 +0200

  Fix percentile_cont/disc(0) with descending order (https://redirect.github.com/duckdb/duckdb/pull/24896)

  Unflavored-from: a9556761cd07ca5efa4fcc844865636903b90f1c

- Update vendored sources to duckdb/duckdb@b4df67e3873e832a867cfd00c39cf0fbbdfb93f6.

  Date: 2026-08-20 06:41:29 +0000

  Fix pathological scan memory for NULLs trailing an overflow string (https://redirect.github.com/duckdb/duckdb/pull/24897) (https://redirect.github.com/duckdb/duckdb/pull/24898)

  Unflavored-from: e9cb6907881e01f04a56435a67013a258a4576ed

- Update vendored sources to duckdb/duckdb@cdde3ddae3913fba0a6dbaa3c6410c130deaf984.

  Date: 2026-08-20 05:46:06 +0000

  Give USING KEY ... UNION changed-key delta semantics (https://redirect.github.com/duckdb/duckdb/pull/24647)

  Unflavored-from: c5c46443ef50525c3da27cc1e5bf274798f8b485

- Update vendored sources to duckdb/duckdb@12b1b3ca222a3d7a25875178695d2943d52ebafa.

  Date: 2026-08-20 05:45:13 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/24826: Stale MODE Ties (https://redirect.github.com/duckdb/duckdb/pull/24890)

  Unflavored-from: 1e8938fe97ebeac0f1310a4fde4eb08f2c836299

- Update vendored sources to duckdb/duckdb@ce512b864cc354d05c1b0ff672ecd38e586db523.

  Date: 2026-08-19 14:38:02 +0200

  Add multiplicity-aware combine support and fix LIST state combination (https://redirect.github.com/duckdb/duckdb/pull/24817)

  Unflavored-from: 23a7c79a880cb60df4f4e8c7033d76c6eb9ec333

- Update vendored sources to duckdb/duckdb@e21f8ce26cb401f99060e78ee99cb067ded4903e.

  Date: 2026-08-19 13:29:01 +0200

  No rtti build (https://redirect.github.com/duckdb/duckdb/pull/24858)

  Unflavored-from: 422e2293b96e8d00bcec7a614a765dbf5714e289

- Update vendored sources to duckdb/duckdb@b650700af56589d6e02a297ba2831baa4e115cf0.

  Date: 2026-08-19 13:23:18 +0200

  Assorted bugfixes tied to conversion errors (https://redirect.github.com/duckdb/duckdb/pull/24860)

  Unflavored-from: 2eb058972f5d1ea01508f039f6b9f1195c3d2fff

- Update vendored sources to duckdb/duckdb@e700f37c172fdb7612076adf037fbadadcc31db2.

  Date: 2026-08-19 12:27:37 +0200

  Fix non-constant map switch bug (https://redirect.github.com/duckdb/duckdb/pull/24868)

  Unflavored-from: d2bbf1dc2677773033e87beb2d102dc7ed1bb39d

- Update vendored sources to duckdb/duckdb@d86f53cac5cb7d2ba8f9a414bf90d73df439415a.

  Date: 2026-08-19 12:27:07 +0200

  Keep the list_aggregate bind data unambiguous (https://redirect.github.com/duckdb/duckdb/pull/24856)

  Unflavored-from: f4a8d5b2223b489b64e5f2daf9085774f71b00bc

- Update vendored sources to duckdb/duckdb@9b69a2d305c3bc56d6c8f2eabd0014bd26850227.

  Date: 2026-08-19 09:14:33 +0000

  Parallelize merge of small collections in PhysicalInsert (https://redirect.github.com/duckdb/duckdb/pull/24584)

  Unflavored-from: be59b6a853ce4e40492d9741440ad19ab2266846

- Update vendored sources to duckdb/duckdb@326202015f4e5ed031c898ab1bc0860cd614cac1.

  Date: 2026-08-19 11:19:55 +0200

  fix geometry row group pruning with nulls/empty (on main) (https://redirect.github.com/duckdb/duckdb/pull/24849)

  Unflavored-from: fefe439c587f2df4c0252b8882f05173f5fd36ba

- Update vendored sources to duckdb/duckdb@e20aeb78111d3cf7df99563498c4e2ed2dd58eee.

  Date: 2026-08-19 11:06:41 +0200

  Remote Pushdown Optimizer: Add support for `CREATE`, `ALTER`, `DROP` and `MERGE INTO` (https://redirect.github.com/duckdb/duckdb/pull/24854)

  Unflavored-from: 0cb581074015d8b616247df4600b9efd3b29a31c

- Update vendored sources to duckdb/duckdb@305f615be8a56970056061af44ebbdefe0ec2f40.

  Date: 2026-08-19 07:56:29 +0000

  \[Dev\]\[Parser\] Add `optional_ptr<ClientContext>` to `ParserCache::GetMatcher` (https://redirect.github.com/duckdb/duckdb/pull/24865)

  Unflavored-from: 0744ed65c2e85ac94df78d9b1f4e08dfeed87a05

- Update vendored sources to duckdb/duckdb@c99ade5cb6028a4ae0a3d71ef1fd97f4c2154931.

  Date: 2026-08-18 15:05:42 +0000

  Add support for `SECURE` views (https://redirect.github.com/duckdb/duckdb/pull/24842)

  Unflavored-from: 669a6342b7a1c32c6638495347c96dc8d7ce5ba7

- Update vendored sources to duckdb/duckdb@5b405a928831c3c76bc5119361b47671f160a67f.

  Date: 2026-08-18 13:49:50 +0000

  \[Dev\]\[Parser\] Move `Matcher` implementations + `MatcherFactory` to separate files (https://redirect.github.com/duckdb/duckdb/pull/24838)
  Auto-detect ISO-8601 timestamps with offsets as TIMESTAMPTZ in JSON (https://redirect.github.com/duckdb/duckdb/pull/24171)
  Use compressed tarballs for CLI and shared libraries (https://redirect.github.com/duckdb/duckdb/pull/24773)

  Unflavored-from: 463d65bcadcdf171243c8396489d02f25508ac5e

- Update vendored sources to duckdb/duckdb@a9ddce5a2ff36ee40aed4e38d0e76d7b5218e0eb.

  Date: 2026-08-18 11:26:49 +0000

  Publish linked extensions on the config, so an extension can load them too (https://redirect.github.com/duckdb/duckdb/pull/24823)

  Unflavored-from: d3c981762bf54a0af8828c920a8cb1e6c314b55b

- Update vendored sources to duckdb/duckdb@8360b0dbe590ab62ce6163d3cf512e7a6a1f4ff6.

  Date: 2026-08-18 11:15:16 +0000

  Add 'connection' secret storage, for connection scoped contexts (https://redirect.github.com/duckdb/duckdb/pull/23527)

  Unflavored-from: 2474fd1b3150c9d5362a5eeca508680c8862455f

- Update vendored sources to duckdb/duckdb@3be83b480fe0c05b35ddf3a5458ba50ce3f2b389.

  Date: 2026-08-18 10:18:25 +0000

  Prune map extraction row group (https://redirect.github.com/duckdb/duckdb/pull/24836)

  Unflavored-from: 937370378325295f801bf8c4c9522a05562d3cae

- Update vendored sources to duckdb/duckdb@c04239dd35661386d551bf1540233c4a74933041.

  Date: 2026-08-18 10:17:35 +0000

  Resolve partition columns for non-pushdown table functions (https://redirect.github.com/duckdb/duckdb/pull/24557)

  Unflavored-from: 4ba4f97435b0466e9b813fc22bd55046b8d9cc6b

- Update vendored sources to duckdb/duckdb@663605dd8c99b9774c0f107572a5bb06af1c53af.

  Date: 2026-08-18 10:17:17 +0000

  Do not push down an extract on an already extracted column (https://redirect.github.com/duckdb/duckdb/pull/24660)

  Unflavored-from: 97ecaaf70f1b9eeb13b3eac0f6bd94d8e1496601

- Update vendored sources to duckdb/duckdb@32165d3616aab31b347bb2c2d3cd5cf998e33402.

  Date: 2026-08-18 10:15:28 +0000

  Allow deserializing a parquet scan whose files were all pruned away (https://redirect.github.com/duckdb/duckdb/pull/24834)

  Unflavored-from: 7050cf6a28ce07511670a175874ee2f19de5d37c

- Update vendored sources to duckdb/duckdb@31ead595df696ed3726e7eb16335ac90627e2caa.

  Date: 2026-08-18 09:54:40 +0000

  Optionally spill evicted external file cache blocks to the temporary directory (https://redirect.github.com/duckdb/duckdb/pull/24062)

  Unflavored-from: 3984e5374eb9e150736c8794741a3626c983eea0

- Update vendored sources to duckdb/duckdb@1dd5e7d2e11689da3c92d36b71f683636845a001.

  Date: 2026-08-18 09:08:15 +0000

  Fix duckbox rendering of case-sensitive ENUM types (https://redirect.github.com/duckdb/duckdb/pull/24735)

  Unflavored-from: 8c24f5fee06c91d9fc3b07fd2dadde132b398926

- Update vendored sources to duckdb/duckdb@29e21fe71e07411fada27c2b9bf518d0a2473489.

  Date: 2026-08-18 09:03:53 +0000

  Validate encryption key before parquet metadata cache leveraged (https://redirect.github.com/duckdb/duckdb/pull/24721)

  Unflavored-from: 4ec6791b556140b94fddaad3ae9a30e9a54eba07

- Update vendored sources to duckdb/duckdb@cd6b42dd5a198ced4f68fab753036d7e5df231cd.

  Date: 2026-08-18 08:31:50 +0000

  Fix Parquet interval millisecond overflow (https://redirect.github.com/duckdb/duckdb/pull/24821)

  Unflavored-from: 6aa97fb1f16f05effcbd32cebc3939835667253a

- Update vendored sources to duckdb/duckdb@61e00e80cc6c1fa640a4f3d359fc4314be25e340.

  Date: 2026-08-18 08:11:01 +0000

  Preserve case-sensitive VARIANT fields during shredding (https://redirect.github.com/duckdb/duckdb/pull/24716)

  Unflavored-from: 69971da12eddc6f752f462abbe8dd64dd17b02d9

- Update vendored sources to duckdb/duckdb@a1353f264bc4dd9adb1962716057f57d7302a527.

  Date: 2026-08-18 08:03:43 +0000

  Fix join order reconstruction for cross products spanning three or more relations (https://redirect.github.com/duckdb/duckdb/pull/24786)
  Do not assert which of three equal intervals becomes the group key (https://redirect.github.com/duckdb/duckdb/pull/24832)

  Unflavored-from: bc52007bc61f1de2a927e20321e102a2685add84

- Update vendored sources to duckdb/duckdb@8d9012ade964f59694d95d1f482fa0fe741f9606.

  Date: 2026-08-18 07:34:46 +0000

  Erase `Function::EraseArgument` (https://redirect.github.com/duckdb/duckdb/pull/24594)

  Unflavored-from: a478aae950159c6f8b622f567e003e4611bbce05

- Update vendored sources to duckdb/duckdb@8cbdaba6acb50db7780d22a65dd131584d472262.

  Date: 2026-08-18 07:27:23 +0000

  A fix to common_subplan_optimizer (https://redirect.github.com/duckdb/duckdb/pull/24824)

  Unflavored-from: 2a3dde6ca344318406bb175aa0ee779ae86f291d

- Update vendored sources to duckdb/duckdb@c9f226a2d4b3b9f74ac448cff20ec0e037fff75d.

  Date: 2026-08-18 07:22:37 +0000

  Fix partitioned COPY losing rows on **HIVE_DEFAULT_PARTITION** collision (https://redirect.github.com/duckdb/duckdb/pull/24816)

  Unflavored-from: fb721c3b465dde9e69342149efefb3e178fd7567

- Update vendored sources to duckdb/duckdb@dbfee7ae8b74c3f919e3ad218718adcc655f5e76.

  Date: 2026-08-18 07:22:24 +0000

  \[Dev\]\[Parser\] `Identifier` match logic clean up (https://redirect.github.com/duckdb/duckdb/pull/24812)

  Unflavored-from: 50d016a8806be78547c04143b5c44f22b01bf459

- Update vendored sources to duckdb/duckdb@1112e8ea0345edd96e5d2312d9fd75d2621352de.

  Date: 2026-08-18 07:22:00 +0000

  Cast to common argument types for unpivot_list (https://redirect.github.com/duckdb/duckdb/pull/24819)

  Unflavored-from: d93aa8eb44e96912ebe3065adf40d15715a1fc0a

- Update vendored sources to duckdb/duckdb@c284a07cce798db9987af570249855898fb5145d.

  Date: 2026-08-18 07:19:31 +0000

  Reset default database after detachment (https://redirect.github.com/duckdb/duckdb/pull/24822)

  Unflavored-from: 452ae3e3f9cb563b3c0db9e014383809031a034f

- Update vendored sources to duckdb/duckdb@0024da969a6b6221ad1c77cb0b5535867d5aaa52.

  Date: 2026-08-18 06:59:04 +0000

  Initial boilerplate for `DialectExtension` (https://redirect.github.com/duckdb/duckdb/pull/24801)

  Unflavored-from: d708bad6bb34355a4d61283b03b3b3fac595f946

- Update vendored sources to duckdb/duckdb@e1838132346409a415a8d64666eb30399a252599.

  Date: 2026-08-18 06:58:39 +0000

  \[Dev\]\[Parser\] Preliminary work for overridable/extensible `MatcherFactory` (https://redirect.github.com/duckdb/duckdb/pull/24818)

  Unflavored-from: 68825416bc45f4c168b5beec86a299cdf97fd04f

- Update vendored sources to duckdb/duckdb@f23d7a7c8a8f59fd4c7070301df8c674e9f19369.

  Date: 2026-08-18 06:52:31 +0000

  Do not use file statistics for overridden hive partitioning columns (https://redirect.github.com/duckdb/duckdb/pull/24752)

  Unflavored-from: 21af5388cc5b7929596167e1c288569d20b40662

- Update vendored sources to duckdb/duckdb@1a9bad7361a0c85c2267e85ec60831d5913f4545.

  Date: 2026-08-18 09:00:35 +0200

  Flush and fsync optimistically written blocks before the WAL lock at commit (https://redirect.github.com/duckdb/duckdb/pull/24193)

  Unflavored-from: a1bf2221bfa52b886cd1ac8d0134159f41e99485

- Update vendored sources to duckdb/duckdb@11dc00c898535281d454593997e49f50d5185df6.

  Date: 2026-08-17 13:42:14 +0000

  Fix precision loss in FLOAT to DECIMAL casts (https://redirect.github.com/duckdb/duckdb/pull/24814)

  Unflavored-from: b8e49c719697caba51f1792ef2aed1f0cebed8d0

- Update vendored sources to duckdb/duckdb@7a61069345a657711a3277b92a8d39f12b2f5ba5.

  Date: 2026-08-17 12:38:02 +0000

  Unify and optimize scalar executor infrastructure (https://redirect.github.com/duckdb/duckdb/pull/24564)
  update security.md (https://redirect.github.com/duckdb/duckdb/pull/24815)
  Add agent instruction for time limiting queries (https://redirect.github.com/duckdb/duckdb/pull/24649)
  Expand multi-file UNION columns for Parquet nested remap (https://redirect.github.com/duckdb/duckdb/pull/24172)
  Fix ICU calendar differences across era boundaries (https://redirect.github.com/duckdb/duckdb/pull/24756)

  Unflavored-from: 974d0d2fd078ecfe6eaee0801ee8006bd8195b87

- Update vendored sources to duckdb/duckdb@d601ccf3f356fbf090335c63839d4fd546690205.

  Date: 2026-08-17 08:59:01 +0000

  Make External Pipeline Input Dependency-Aware (https://redirect.github.com/duckdb/duckdb/pull/24754)

  Unflavored-from: 59296b0129e3d1144e3f0a46eb00bda86b658864

- Update vendored sources to duckdb/duckdb@2bc58f8681f4328b2408ea5b7ededda26b1462cd.

  Date: 2026-08-17 08:44:38 +0000

  Fix checkpoint Analyze handling for explicit compression method (https://redirect.github.com/duckdb/duckdb/pull/24429)

  Unflavored-from: 6479fc5dcbcba36b3ba76b5aae6146dac5eac265

- Update vendored sources to duckdb/duckdb@b72829332bd7c85adc11b200a98acfeede2db851.

  Date: 2026-08-17 08:43:54 +0000

  Handle infinite dates in timestamp comparison optimization (https://redirect.github.com/duckdb/duckdb/pull/24669)

  Unflavored-from: f5612a4615da68b6ee70ed66449012aa9cda4428

- Update vendored sources to duckdb/duckdb@bcd78db0ec4559ab7b75f56d96742132ef7c92df.

  Date: 2026-08-17 08:43:50 +0000

  Prune row groups when an IN-list covers the whole zonemap rangend add (https://redirect.github.com/duckdb/duckdb/pull/24521)

  Unflavored-from: 642b30c267226e3c9b1906a5c62eb9098bfd52f8

- Update vendored sources to duckdb/duckdb@f886d38c6b4bab1a48aeee25c9a5d6c241c0d04e.

  Date: 2026-08-17 08:35:57 +0000

  Prune segment for nested types on validity check (https://redirect.github.com/duckdb/duckdb/pull/24768)

  Unflavored-from: efab5a3f231f0eda7ecb6823800411b50c68fdb6

- Update vendored sources to duckdb/duckdb@5639a711decb8dcc2e096a33cac0af4d7283918e.

  Date: 2026-08-17 07:47:30 +0000

  Use \_\_restrict actually in MacOS (https://redirect.github.com/duckdb/duckdb/pull/24681)

  Unflavored-from: eb12f414f1d029468c6cfe5fbc87bd4a5fecea73

- Update vendored sources to duckdb/duckdb@ef7487bb2e2e80bd6b8acfe54b5e6a1ac2a0a72a.

  Date: 2026-08-17 07:42:39 +0000

  Fix case restoration for mismatched case column references (https://redirect.github.com/duckdb/duckdb/pull/24776)

  Unflavored-from: 263d6423bdf84b09ccb1ee94b8ee0be257b937f2

- Update vendored sources to duckdb/duckdb@e99bbaefdf5c2c073c11acf5cbb8d8b5a37b32c7.

  Date: 2026-08-17 07:24:27 +0000

  Don't dlopen an extension that is already linked in (https://redirect.github.com/duckdb/duckdb/pull/24800)

  Unflavored-from: cb282b1f456ce98267cd1ccefe93187377e0231f

- Update vendored sources to duckdb/duckdb@2b299d492317b0a748ecb645117a0ab7f907a8d5.

  Date: 2026-08-17 07:00:32 +0000

  Fix unused residual collection consuming must-apply cost predicates (https://redirect.github.com/duckdb/duckdb/pull/24784)

  Unflavored-from: 4035163fe1527aea74ab03757f02f6ff538abd9b

- Update vendored sources to duckdb/duckdb@4f3f4f7deb0bea319b4fff06856cd15d4050637e.

  Date: 2026-08-17 06:58:00 +0000

  Fold trivial any-joins back into cross products (https://redirect.github.com/duckdb/duckdb/pull/24788)

  Unflavored-from: 2bae279dfaedac02995be153e86478b4fd58d615

- Update vendored sources to duckdb/duckdb@d8518516d22040fad8245b35774e721ebdc32bca.

  Date: 2026-08-17 06:46:15 +0000

  Bump duckdb-httpfs to main and shrink its patch (https://redirect.github.com/duckdb/duckdb/pull/24803)

  Unflavored-from: 55c87e9c17108f2e8e22131c65421a46e13c23d4

- Update vendored sources to duckdb/duckdb@1eb322c6202194244c428e8685d32020f1900e9e.

  Date: 2026-08-17 06:43:21 +0000

  \[Dev\] Refactor `BaseTokenizer`, and rename to `Tokenizer` (https://redirect.github.com/duckdb/duckdb/pull/24772)

  Unflavored-from: 8222e01c23c1d0668f19ad07d07ce2f3e4ee97dc

- Update vendored sources to duckdb/duckdb@ebde857610449e936dbd76240c5c074ff7cdac8a.

  Date: 2026-08-17 06:43:13 +0000

  Add typed_value column to duckdb_settings() (https://redirect.github.com/duckdb/duckdb/pull/24774)

  Unflavored-from: 4b7de72070e263d712940b82695a876df787381c

- Update vendored sources to duckdb/duckdb@caf6a16b55951c06447d8db992831c70806a2f08.

  Date: 2026-08-17 06:42:30 +0000

  Fix `PARTITION BY` syntax for `COPY TO` on multiple columns (https://redirect.github.com/duckdb/duckdb/pull/24770)

  Unflavored-from: 2a0f8cd6a06bbd7f5f8fd736e0539f4790ec9652

- Update vendored sources to duckdb/duckdb@ffe141b41e7d901853c43b397128aba673ccacde.

  Date: 2026-08-17 05:56:35 +0000

  Fix ASOF join over EXCEPT ALL / INTERSECT ALL children (https://redirect.github.com/duckdb/duckdb/pull/24760)

  Unflavored-from: 13a6182f84e5801b5133a357ac85ed169a81c4b1

- Update vendored sources to duckdb/duckdb@f8e1c96a535d54c6a2785a0b13c6fcdb148c067b.

  Date: 2026-08-14 15:21:26 +0000

  Add support for GeoJSON in the `json` extension (https://redirect.github.com/duckdb/duckdb/pull/24646)

  R-side fix

- Update vendored sources to duckdb/duckdb@fa977d419cd13e13931fc1e3ddfb7cbcae67f625.

  Date: 2026-08-14 14:21:38 +0000

  EXTERNAL RESOURCE: give the create params their own grammar rule (https://redirect.github.com/duckdb/duckdb/pull/24771)

  Unflavored-from: 4eb51954faac70ae3d187d4ea9e1200046473a4d

- Update vendored sources to duckdb/duckdb@6b8c8cc71b1e20bdbdb77eb9c1c231fd71bed5b8.

  Date: 2026-08-14 12:05:45 +0000

  Propagate stats in materialized CTEs and array distance/similarity functions (https://redirect.github.com/duckdb/duckdb/pull/24600)

  Unflavored-from: d93f269975b893d494661d27fb2137046ed501c7

- Update vendored sources to duckdb/duckdb@79564c68e41a5f80b06be5c1a2eb8721718cab9d.

  Date: 2026-08-14 10:55:00 +0000

  Buffer managed indexes, Pt.2 (https://redirect.github.com/duckdb/duckdb/pull/23605)

  Unflavored-from: fc19392ceafec27a28d3f743de011f1463ddb852

- Update vendored sources to duckdb/duckdb@ee70755b281239e0bb3e667ca9f160705cf85aad.

  Date: 2026-08-14 10:51:27 +0000

  \[ASYNC-IO\] On Demand ASYNC IO for native DuckDB Tables (https://redirect.github.com/duckdb/duckdb/pull/24654)

  Unflavored-from: 2fbdaae7bbb0058cf109d9e5f3364d5581c23839

- Update vendored sources to duckdb/duckdb@31974c79b732d71204cbfd54f07f39d6ba5fd01f.

  Date: 2026-08-14 10:50:27 +0000

  \[Sequence\] Disable parallel insert for tables with column(s) with `nextval(...)` in them (https://redirect.github.com/duckdb/duckdb/pull/24724)

  Unflavored-from: 86ff9c267eb8d795a1a3c542101c9fc5ae4e1e25

- Update vendored sources to duckdb/duckdb@48c958a5be450a41b6e75c2ba1a23f4509727fb7.

  Date: 2026-08-14 08:48:57 +0000

  Compare window partitions as sets (https://redirect.github.com/duckdb/duckdb/pull/24685)

  Unflavored-from: 7f1dae9189c57270694f696a08fda19739e67ef8

- Update vendored sources to duckdb/duckdb@35e2c4edb1b5cc03e61bc418f55a540f59154928.

  Date: 2026-08-14 07:50:20 +0000

  Fix list_reduce raising INTERNAL error when its lambda throws (https://redirect.github.com/duckdb/duckdb/pull/24663)

  Unflavored-from: 44cdbf414c153a293d2888669f8112e70809e4ed

- Update vendored sources to duckdb/duckdb@514669fced0201e759543eb933421da3837c14d0.

  Date: 2026-08-14 07:45:27 +0000

  Fix `INTERNAL Error`: Mark `regexp_full_match` as fallible (https://redirect.github.com/duckdb/duckdb/pull/24701)

  Unflavored-from: 2163387ee22317891fd5e018714ef11e167a86ad

- Update vendored sources to duckdb/duckdb@d83473e8603d09dab28a6861d0f89f05814861a7.

  Date: 2026-08-14 07:45:02 +0000

  Fix interval comparison when carrying left leaves a negative field (https://redirect.github.com/duckdb/duckdb/pull/24704)
  Fix schema conflict in TPC-H `dbgen` (https://redirect.github.com/duckdb/duckdb/pull/24712)

  Unflavored-from: f2d421e9b4e9d98b14832041599e6bb05c85ab17

- Update vendored sources to duckdb/duckdb@93824850d2c1afd62ffbacde40e6536bf8f3ddd3.

  Date: 2026-08-14 07:41:54 +0000

  Fix NULL dynamic ROWS window frame boundaries (https://redirect.github.com/duckdb/duckdb/pull/24727)

  Unflavored-from: 0cacdcbc1e07eaf5d51b85359d8c2974790813ea

- Update vendored sources to duckdb/duckdb@718aba0cbec72ebdd3d008a1037f4456e7024e48.

  Date: 2026-08-14 07:36:12 +0000

  Prune row group for greatest/least with same boundary (https://redirect.github.com/duckdb/duckdb/pull/24015)

  Unflavored-from: 8cbbb837ef24b796346a2d53cf2df4420200753c

- Update vendored sources to duckdb/duckdb@147bab90c6372adee655af88072d1d7158c66da6.

  Date: 2026-08-14 07:30:12 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10053: Postgres Nested Semantics (https://redirect.github.com/duckdb/duckdb/pull/24504)
  Add test case for incorrect `EXPLAIN FORMAT` (https://redirect.github.com/duckdb/duckdb/pull/24656)

  Unflavored-from: 82fb1d134c6f9404a18c3db33b1cb43360706381

- Update vendored sources to duckdb/duckdb@4e49852876cac99aaac88918fb47c5182ae402db.

  Date: 2026-08-14 06:47:32 +0000

  Remove unused function (https://redirect.github.com/duckdb/duckdb/pull/24734)

  Unflavored-from: 3b99ceecda02f4cedd0e05e2cc54679ff2b49911

- Update vendored sources to duckdb/duckdb@d1a58bfc1360e28e5dd03b6653f63d3486cd45da.

  Date: 2026-08-14 06:33:32 +0000

  Fix dictionary validity checks in Parquet variant shredding (https://redirect.github.com/duckdb/duckdb/pull/24718)

  Unflavored-from: 651b9cf2a12cfaf4d81eb8e0084c16017078aa61

- Update vendored sources to duckdb/duckdb@9b2df4e674bb36fa792d8b74837c07967f60ec02.

  Date: 2026-08-14 06:31:53 +0000

  Prune struct segment (https://redirect.github.com/duckdb/duckdb/pull/24726)

  Unflavored-from: b858147d2d7097ae1102dad6305cea432c20f891

- Update vendored sources to duckdb/duckdb@fbcefbb8ef8fff9e5d981c264e658afb880f1999.

  Date: 2026-08-14 06:29:26 +0000

  Use IO exception for invalid variant input (https://redirect.github.com/duckdb/duckdb/pull/24763)
  bump azure && remove the patch (https://redirect.github.com/duckdb/duckdb/pull/24732)

  Unflavored-from: 9f4015473728e4cbfa5c6cf9b3d1f1e57e982228

- Update vendored sources to duckdb/duckdb@bb272bcb0e23ba9b29fc59f69b3a95a587a6892c.

  Date: 2026-08-14 06:28:24 +0000

  Fix stale table statistics in prepared statements (https://redirect.github.com/duckdb/duckdb/pull/24696)
  Add guards to TPC-H and TPC-DS generators (https://redirect.github.com/duckdb/duckdb/pull/24664)

  Unflavored-from: 11ea9787b25f598084c17c120a554a40ee9ef65a

- Update vendored sources to duckdb/duckdb@320017c1115b3d83eeae46437a943c781a4877dc.

  Date: 2026-08-14 06:26:18 +0000

  Buffer managed indexes, Pt. 1 (https://redirect.github.com/duckdb/duckdb/pull/21458)

  Unflavored-from: 68fd47f21f44728d59787bfe03670d0a3f6e22cd

- Update vendored sources to duckdb/duckdb@a9f869b6a776643a0e2e143f5de14a23cca0b984.

  Date: 2026-08-13 18:25:53 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/24455: ApproxTopK Constant Binding (https://redirect.github.com/duckdb/duckdb/pull/24673)

  Unflavored-from: 66b84fe461352125083c46e1eb00ac9a9993b833

- Update vendored sources to duckdb/duckdb@43ecd7f909a05724ef10f520da15f6ff060ac2e6.

  Date: 2026-08-13 11:56:57 +0000

  Make `Value` immutable (https://redirect.github.com/duckdb/duckdb/pull/24746)

  Unflavored-from: f73b510eb02c9311e8e6e329c6e2385ab8b9809e

- Update vendored sources to duckdb/duckdb@840649a3f55ff664d8fb3cfe2800be6b2aa9c4d0.

  Date: 2026-08-13 11:42:32 +0000

  Rewrite mode and entropy as multi-stage aggregates (https://redirect.github.com/duckdb/duckdb/pull/24359)

  Unflavored-from: 6f1a58801cfb98b2747878990db3d304c2289f55

- Update vendored sources to duckdb/duckdb@c2040e3d8ff8b130408d6d2b0ebdd770090fa6f5.

  Date: 2026-08-13 11:28:09 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/24455: Windowed Distinct MODE (https://redirect.github.com/duckdb/duckdb/pull/24674)

  Unflavored-from: 4b83d0787e1fd1ff9293db502f04656fcef6c9ed

- Update vendored sources to duckdb/duckdb@c54cb2c29b2fda8c78d278e62629bce08291daad.

  Date: 2026-08-13 11:25:03 +0000

  Fix indexed DELETE column resolution (https://redirect.github.com/duckdb/duckdb/pull/24203)

  Unflavored-from: c44a75d9a7dbf51709d915eb85e5d06c568e0019

- Update vendored sources to duckdb/duckdb@1c75d17a7a4fe49676b2733d627a2e3fe53b0438.

  Date: 2026-08-13 10:51:16 +0000

  Spill aggregate states when the aggregation goes external (https://redirect.github.com/duckdb/duckdb/pull/24499)

  Unflavored-from: c1567505d79c6ab5cf1dd84b85e913402d5f488f

- Update vendored sources to duckdb/duckdb@3bdf63a5958e833a7caed1fc103cb588ab92d51e.

  Date: 2026-08-13 10:43:52 +0000

  Fix missing catalog dependency registration for index_key (https://redirect.github.com/duckdb/duckdb/pull/24249)

  Unflavored-from: 90770d21889c73f7099306245461b9e377bf16a3

- Update vendored sources to duckdb/duckdb@c6f7f3e2502c0a5141f339cb208ba21f770d6661.

  Date: 2026-08-13 08:18:49 +0000

  Fix clang tidy errors in json variant cast file (https://redirect.github.com/duckdb/duckdb/pull/24723)

  Unflavored-from: b838e15e480d9f271c4841299855fafc8e3a1012

- Update vendored sources to duckdb/duckdb@586dd96fafe516ef7d33a7ddc3383fdbf4e84819.

  Date: 2026-08-13 08:08:27 +0000

  Fix an issue where a collated null caused crashes in groups (https://redirect.github.com/duckdb/duckdb/pull/24730)

  Unflavored-from: 3c7a08743f5774a506d23bcfbedff0eb3d6c64e0

- Update vendored sources to duckdb/duckdb@d23669a3237de5b761abcb2345bdfc09b28b7c07.

  Date: 2026-08-13 07:33:54 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/24450: DatePart Binary Doubles (https://redirect.github.com/duckdb/duckdb/pull/24573)

  R-side fix

- Update vendored sources to duckdb/duckdb@5366dc3925ce0f981c2110cf4bf8e39fa1dd6fde.

  Date: 2026-08-12 14:26:03 +0000

  Fix race condition in reclaiming file cache blocks (https://redirect.github.com/duckdb/duckdb/pull/24729)

  Unflavored-from: e429016f7e9002cac0a31ccda134c3fed0c488a8

- Update vendored sources to duckdb/duckdb@ca9bf23600423863cf23c2762dee0b4c54945e42.

  Date: 2026-08-12 14:03:24 +0000

  Fix recursive outer nested loop join state reuse (https://redirect.github.com/duckdb/duckdb/pull/24700)

  Unflavored-from: a97dbd603758279ff0fa2a8fdeee9a54da1ec7fc

- Update vendored sources to duckdb/duckdb@782f2f8229180d6d82d15320c1938ac566ea8710.

  Date: 2026-08-12 14:03:02 +0000

  Fix correlation detection for nested dependent joins (https://redirect.github.com/duckdb/duckdb/pull/24683)
  Issue https://redirect.github.com/duckdb/duckdb/pull/24617: ICU TRY_CAST Throws (https://redirect.github.com/duckdb/duckdb/pull/24705)

  Unflavored-from: 47f19b5edcaa98fa68bcef404bcf2316ec9c0964

- Update vendored sources to duckdb/duckdb@7e14bd24e03f5b5c30b8f3af79a8fbb15dce8320.

  Date: 2026-08-12 09:16:53 +0000

  Add Aggregate Reuse Optimizer to reduce redundant aggregation across joins (https://redirect.github.com/duckdb/duckdb/pull/24543)
  Omit external extensions because both are manually disabled (https://redirect.github.com/duckdb/duckdb/pull/24658)
  bump aws and delete patches (https://redirect.github.com/duckdb/duckdb/pull/24682)

  Unflavored-from: 609c3609f40410e620fab28b7aabd3728119ebba

- Update vendored sources to duckdb/duckdb@cb6ac6f04e8c55d582e28a63b1731e9047408db4.

  Date: 2026-08-12 08:47:39 +0000

  \[Extension\] Add mapping in `extension_entries.hpp` for Storage Extensions (https://redirect.github.com/duckdb/duckdb/pull/24684)

  Unflavored-from: f2528c28bd1e8394b801eb0c392209701b3c7afe

- Update vendored sources to duckdb/duckdb@2828abd8a5759763f426ca1632cc237be8ff27c4.

  Date: 2026-08-11 18:31:45 +0000

  Fix: `RANK/PERCENT_RANK/CUME_DIST` peers when the argument `ORDER BY` is a prefix of the window `ORDER BY` (https://redirect.github.com/duckdb/duckdb/pull/24693)
  Removed patches for delta. updated sha (https://redirect.github.com/duckdb/duckdb/pull/24699)
  Disable flaky FSST test (https://redirect.github.com/duckdb/duckdb/pull/24688)
  Fixup test_not_distinct_index_scan.test to actually be forced to be a Sequence Scan (vs optimized after checkpoint Column Data Scan) (https://redirect.github.com/duckdb/duckdb/pull/24671)
  Re-enable five stale mode-skips, including two fuzzer regression tests (https://redirect.github.com/duckdb/duckdb/pull/24392)

  Unflavored-from: 8c3e7519f6146b023c3ac70da5032f64ffc075f8

- Update vendored sources to duckdb/duckdb@22226bba7f8b3fa32b9b1c0777c2caf048cb4cef.

  Date: 2026-08-10 13:58:21 +0000

  Reject filename and Hive partition collisions (https://redirect.github.com/duckdb/duckdb/pull/24555)

  Unflavored-from: d847505135374b2c08fac209678f233587f49650

- Update vendored sources to duckdb/duckdb@5c23c10fcf442f359c5072c025d9df1f981b4adc.

  Date: 2026-08-10 13:11:52 +0000

  Allow fitting integer literals as typed macro defaults (https://redirect.github.com/duckdb/duckdb/pull/24548)

  Unflavored-from: c1e9a063e9587963d44f6017ac0ac5db17c76791

- Update vendored sources to duckdb/duckdb@f9f8cfaedb707b38616b99e6668c5d4b0cab9d02.

  Date: 2026-08-10 12:40:09 +0000

  Fixhttps: //redirect.github.com/duckdb/duckdb/pull/24303 date_trunc comparisons with infinite timestamps (https://redirect.github.com/duckdb/duckdb/pull/24409)
  Unflavored-from: b38dcbac19082b8eb664d8943a047ed031438398

- Update vendored sources to duckdb/duckdb@0f57b74ce5290043dec4e362c95d8c3fab3d9b27.

  Date: 2026-08-10 12:12:15 +0000

  Fixes (https://redirect.github.com/duckdb/duckdb/pull/24115) : Use single-column ART index scan for IS NOT DISTINCT FROM (https://redirect.github.com/duckdb/duckdb/pull/24146)

  Unflavored-from: 579959f5e5bccfc939b0db3c16ad0760d4ce7424

- Update vendored sources to duckdb/duckdb@088395a48262c0fbdb3dac4aedb6fa1abbebdd53.

  Date: 2026-08-10 12:07:02 +0000

  Bugfix connected to round-tripping identifiers (https://redirect.github.com/duckdb/duckdb/pull/24370)

  Unflavored-from: cebb530a910202775cfd74bf377fbe6b00e74042

- Update vendored sources to duckdb/duckdb@624fcfa3af5998267dca0c42a27801de543fa2a0.

  Date: 2026-08-10 12:06:44 +0000

  Fix INTERNAL error from EXPLAIN (FORMAT) and EXPLAIN (FORMAT default) (https://redirect.github.com/duckdb/duckdb/pull/24369)

  Unflavored-from: 621559f4c020d1df95a593794bfcae513c0c519c

- Update vendored sources to duckdb/duckdb@46ae6e6c4e46b7a659af62ad2fc252b1e34f9921.

  Date: 2026-08-10 11:54:01 +0000

  Fix CREATE SEQUENCE throwing INTERNAL error on NULL option values (https://redirect.github.com/duckdb/duckdb/pull/24614)

  Unflavored-from: 36e9ca51c7169bd89fde761fa359da321c0bfd2e

- Update vendored sources to duckdb/duckdb@ac5c6d11c3b0915fcc0fa43080d31893269d6448.

  Date: 2026-08-10 11:52:47 +0000

  Initial implementation of `variant_extract_string` processing function (https://redirect.github.com/duckdb/duckdb/pull/24060)

  Unflavored-from: d6b37222818dd6d39216debba340ee98bf6d059f

- Update vendored sources to duckdb/duckdb@527057024b1258d97af8564b266b203dc2a7ed9f.

  Date: 2026-08-10 11:50:28 +0000

  Add bounds check for roaring container_count (https://redirect.github.com/duckdb/duckdb/pull/23796)

  Unflavored-from: bc3bed92048525bd4ac903dbeb4fcf94c613ba3c

- Update vendored sources to duckdb/duckdb@bbfc4587c6f4257e90230359fbfcd68f5ea689f3.

  Date: 2026-08-10 11:46:21 +0000

  Fix external file cache seek when uncache read (https://redirect.github.com/duckdb/duckdb/pull/24585)

  Unflavored-from: 20d221e9790c0a383d5042749bba4d020f2287b5

- Update vendored sources to duckdb/duckdb@14b0c94b3a64d4655ff92dbe957959a098bb836f.

  Date: 2026-08-10 11:20:02 +0000

  Make configs and secrets use Identifiers (https://redirect.github.com/duckdb/duckdb/pull/24589)

  R-side fix

  Upstream now types configuration option names as `duckdb::Identifier`
  rather than `std::string`,
  and promoting a runtime string to an identifier is deliberately explicit.
  `rapi_startup()` passes user-supplied option names straight through,
  so wrap the key in `Identifier(key)` at the call site.

  Carried from main-build e9765272636e4ae2f731d383fce3cdcaa98f4c91,
  which answered the same upstream commit.

  Carried from `origin/v2.0-cyanoptera-dev` at 6f097497b9:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 666939ecf6fd02e680c5b6ba3eb6fe20873d92a3

- Update vendored sources to duckdb/duckdb@db98709cc2cb41efe5a46bb795f689f5b54f7805.

  Date: 2026-08-10 08:38:11 +0000

  fix: avoid int64 overflow in generic InterpolateOperator for fill() (https://redirect.github.com/duckdb/duckdb/pull/24571)
  Require 16GB RAM for string_agg overflow test (https://redirect.github.com/duckdb/duckdb/pull/24643)

  Unflavored-from: 8144e8692dce8ad002ba536ddd2e2867abe5a984

- Update vendored sources to duckdb/duckdb@db7c305514d47a8b4cc6a7ba4360ba48a6b7e40c.

  Date: 2026-08-10 07:15:40 +0000

  Fix grouped printf formats for signed integer arguments (https://redirect.github.com/duckdb/duckdb/pull/24601)

  Unflavored-from: 021c5f5b0a8bbe5f09e88e6a3bae967605b625e7

- Update vendored sources to duckdb/duckdb@fe10486cf77c09deaac43c4d93ff0702c8466928.

  Date: 2026-08-10 06:57:10 +0000

  Fix UB for ALP (https://redirect.github.com/duckdb/duckdb/pull/24640)

  Unflavored-from: caad5bf9c0fd85977a61f63333b0a054dfe05170

- Update vendored sources to duckdb/duckdb@d0a0440b2007ae1f30e930dd68f2aea04ff66773.

  Date: 2026-08-10 06:55:29 +0000

  Add data_page_size_limit option to Parquet COPY (https://redirect.github.com/duckdb/duckdb/pull/24645)

  Unflavored-from: a52594b5ae0206405a3d98e25340ed56372edc0f

- Update vendored sources to duckdb/duckdb@70bae435a6031cbec08b453d5f31ed1a1371288c.

  Date: 2026-08-10 06:48:54 +0000

  Fix `DECIMAL` syntax silently accepting non-integral parameters (https://redirect.github.com/duckdb/duckdb/pull/24606)

  Unflavored-from: fd0334977bc98b5129c8a789a871d09855ef2a10

- Update vendored sources to duckdb/duckdb@e500d77864fe565f90e68f06d729c25b11e775c5.

  Date: 2026-08-07 13:50:28 +0000

  Recursive runtime invocation metrics (https://redirect.github.com/duckdb/duckdb/pull/24565)

  Unflavored-from: 8f831808a41dd136a6d5341d53482c06c6520ae7

- Update vendored sources to duckdb/duckdb@77f5ade1072541d255ca1f5e4ec07b6158ed721b.

  Date: 2026-08-07 13:44:46 +0000

  Parallelize ordered buffered CTE scans (https://redirect.github.com/duckdb/duckdb/pull/24361)
  Replace benchmark TPC-DS with SF=10, fix mold version check (https://redirect.github.com/duckdb/duckdb/pull/24567)

  Unflavored-from: 1171739c17425cf9d1cb64e3e08a3fa9b787c437

- Update vendored sources to duckdb/duckdb@25828b381adbfcc48e6a47d9dfc7a5179b0b7d19.

  Date: 2026-08-07 13:43:01 +0000

  Add CIEndsWith and Identifier::EndsWith (https://redirect.github.com/duckdb/duckdb/pull/24566)

  Unflavored-from: 1ada32642f8d882cd6557a3c44340998d0b0aa70

- Update vendored sources to duckdb/duckdb@171ed92fbb7b35b1d886c3fb6ef17f98b75696a6.

  Date: 2026-08-07 13:32:07 +0000

  Make SetDefaultDatabase take an Identifer (https://redirect.github.com/duckdb/duckdb/pull/24583)

  Unflavored-from: a7df141d5507b5943d73094f27fe0f6072c448b8

- Update vendored sources to duckdb/duckdb@68c5b90adb9af685802a56cb3331c618975d9c68.

  Date: 2026-08-07 10:52:01 +0000

  Fix heap overflow in `string_agg` (https://redirect.github.com/duckdb/duckdb/pull/24582)

  Unflavored-from: ef2cd71a408570c4755ced1a4515b0763e81d101

- Update vendored sources to duckdb/duckdb@e85c4d27d7a1264d83b7c42e0f6508cd0a45a112.

  Date: 2026-08-07 08:48:10 +0000

  Fix NULL handling in ASOF join prefix comparisons (https://redirect.github.com/duckdb/duckdb/pull/24199)

  Unflavored-from: db0376c3fa6b602d6751d4fa67c37380c85bec7d

- Update vendored sources to duckdb/duckdb@223903d5885a32488f57b57c87d48acb6d8398da.

  Date: 2026-08-07 10:21:33 +0200

  Internal https://redirect.github.com/duckdb/duckdb/pull/10053: IEJoin Key Reset (https://redirect.github.com/duckdb/duckdb/pull/24572)

  Unflavored-from: 9922a75ae1489ecd233492321421a008d1626c4f

- Update vendored sources to duckdb/duckdb@efcd7906c2bae482c2c89fee985c887be912b6a0.

  Date: 2026-08-07 07:59:36 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/10187: Volatile Window Inputs (https://redirect.github.com/duckdb/duckdb/pull/24577)

  Unflavored-from: 19c9fe8893cf72add9671a0facce66aa0dc8d459

- Update vendored sources to duckdb/duckdb@76dd1e7d6f89f2a4c92d958b356aca0ec550ec71.

  Date: 2026-08-06 14:29:04 +0000

  Terminate the dead end chain when the build side uses dictionary emission (https://redirect.github.com/duckdb/duckdb/pull/24539)

  Unflavored-from: 74a64cc781f519ff2cc918dca72333f45ca9fc95

- Update vendored sources to duckdb/duckdb@73f332835a76e478c8fbd62db06fc339b327c908.

  Date: 2026-08-06 12:53:23 +0000

  Use logical ordering for VARIANT min/max (https://redirect.github.com/duckdb/duckdb/pull/24531)

  Unflavored-from: 8b418f4344f7385f61ace13bfa4cb8f6e8fb4372

- Update vendored sources to duckdb/duckdb@1da80a4a3adef9053fb665864734debf1407a521.

  Date: 2026-08-06 12:51:23 +0000

  Compress fully-visible partial deletes into a bitmask (https://redirect.github.com/duckdb/duckdb/pull/24336)
  Iterative benchmark runs and make report easier to understand (https://redirect.github.com/duckdb/duckdb/pull/24503)

  Unflavored-from: bbbe49fb660301e1225719f235110ec82b849c4c

- Update vendored sources to duckdb/duckdb@ff4fd138db1512c01bc48b9bcb1b0f072e8c574e.

  Date: 2026-08-06 09:51:34 +0000

  Fix NUL escape handling in `LIKE`/`ILIKE` operators (https://redirect.github.com/duckdb/duckdb/pull/24550)

  Unflavored-from: 815ccb1cd77cf90b8e7efc691afd7289beeb1a93

- Update vendored sources to duckdb/duckdb@91680c2ec1d8d2c3958f2d110f43317d71a481e6.

  Date: 2026-08-06 09:23:57 +0000

  Preserve regex semantics for collated strings (https://redirect.github.com/duckdb/duckdb/pull/24558)

  Unflavored-from: 40877d4eb6f3402b013718808b38ff05d678cb48

- Update vendored sources to duckdb/duckdb@66f3728f5468ace860a092aa31f7120eded9ebd6.

  Date: 2026-08-06 09:20:24 +0000

  Produce valid JSON for fractional VARIANT decimals (https://redirect.github.com/duckdb/duckdb/pull/24554)
  bump avro and remove patches (https://redirect.github.com/duckdb/duckdb/pull/24545)

  Unflavored-from: 6cf0dd33ad288d94f96fa34da750ebee10ac5be0

- Update vendored sources to duckdb/duckdb@89df4911a45806a1eb28eac7af1e8798b467efd1.

  Date: 2026-08-06 07:19:16 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/24288: Join Predicate Binding (https://redirect.github.com/duckdb/duckdb/pull/24526)

  Unflavored-from: 7ce4c1b85c80d0ad94f5b1277e0865baf94f6a76

- Update vendored sources to duckdb/duckdb@033322be146ad99bacfda3616148badd4ce474b2.

  Date: 2026-08-05 15:37:36 +0000

  `COPY` with `ORDER_BY` without `PARTITION_BY` (https://redirect.github.com/duckdb/duckdb/pull/24525)

  Unflavored-from: 3ad6dc2c7641030d26bc3af40f1d1891a115f878

- Update vendored sources to duckdb/duckdb@759c3dfd40f9d4833b86ca587f1789b4c10772e9.

  Date: 2026-08-05 15:27:13 +0000

  fix: incorrect join order of joins without ON clause (https://redirect.github.com/duckdb/duckdb/pull/24228)
  Unflavored-from: 48f66f78cab87013395f89673fa8a92677047888

- Update vendored sources to duckdb/duckdb@4a900ff05cbb788eca32f414548aec1ed55a6154.

  Date: 2026-08-05 15:25:00 +0000

  Scan the full child span for Arrow ListView arrays (https://redirect.github.com/duckdb/duckdb/pull/24483)

  Unflavored-from: c0ae5ca319e6df8ddbe18cfba0eec19c84d6966c

- Update vendored sources to duckdb/duckdb@4e695a9b79ae6a7bf97d8ca2be3ed58637c3a53d.

  Date: 2026-08-05 15:18:48 +0000

  Return Identifier from GetDefaultSchema/Table/TableSchema (https://redirect.github.com/duckdb/duckdb/pull/24498)

  Unflavored-from: c42b369778e63cfc19a2d35c1bbac5dc01ff089e

- Update vendored sources to duckdb/duckdb@4707f29641218680d35cbb384d2f3b95f3fddca1.

  Date: 2026-08-05 15:18:32 +0000

  Maintain better compatibility with older DuckDB versions in SETOF returning functions (https://redirect.github.com/duckdb/duckdb/pull/24501)

  Unflavored-from: 225e85203faa5e96e62c08a6d0a8f852775012e9

- Update vendored sources to duckdb/duckdb@89cc4bb95bf05fc1b5933699342eba37a04f3f98.

  Date: 2026-08-05 15:18:01 +0000

  Improved tokenization for nested comments (https://redirect.github.com/duckdb/duckdb/pull/24522)

  Unflavored-from: 630b0703b5bbafb4f3566d564119b7d50c51607e

- Update vendored sources to duckdb/duckdb@8ea7d9fcaecb7113f06e83e6915341c30da84744.

  Date: 2026-08-05 15:02:20 +0000

  Fix escape strings being incorrectly tokenized (https://redirect.github.com/duckdb/duckdb/pull/24519)
  Kill process group when retrying hanged command in CI (https://redirect.github.com/duckdb/duckdb/pull/24523)

  Unflavored-from: e39b7d0a6cf19ec3871fc8a7b281b889c60bd3cb

- Update vendored sources to duckdb/duckdb@3359f6bb448a65b95759add290b89ab986afed13.

  Date: 2026-08-05 14:57:22 +0000

  Take `vector<Identifier>` in the table function bind callbacks (https://redirect.github.com/duckdb/duckdb/pull/24278)

  R-side fix:

  `table_function_bind_t` now hands back `vector<Identifier>`
  rather than `vector<string>`,
  so the column names a table function returns
  resolve case-insensitively like every other binding name.

  `DataFrameScanBind()` is the one glue call site.
  Take `vector<Identifier> &names`,
  and promote each data frame column name to an `Identifier` explicitly,
  as the type requires —
  the same explicit promotion `rel_from_table_function()` already does
  for its named parameters.

  Carried from `origin/v2.0-cyanoptera-dev` at 3451ad694a:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 4696a70477753558ca9b5063990cb7db4171fc4e

- Update vendored sources to duckdb/duckdb@3197fc6ca91486d9259c0d53992e2303b07ff5bb.

  Date: 2026-08-05 13:55:43 +0000

  Bump httpfs version (https://redirect.github.com/duckdb/duckdb/pull/24518)
  improve `PartitionedExecution` coverage (https://redirect.github.com/duckdb/duckdb/pull/24520)

  Unflavored-from: e12321747125491bdaa008876825b219b927b2f7

- Update vendored sources to duckdb/duckdb@58c019320e250a7b369efd756f84c6dfd68bedcb.

  Date: 2026-08-05 12:50:36 +0000

  Add reusable relation statistics extraction (https://redirect.github.com/duckdb/duckdb/pull/24512)

  Unflavored-from: 2213f339cb2aa03910e6ac4b4240a5c61e30571c

- Update vendored sources to duckdb/duckdb@043e1894425b49984c5010f253589e5d9c5fdde4.

  Date: 2026-08-05 12:13:41 +0000

  Add checked cast helper to `HTTPUtil` (https://redirect.github.com/duckdb/duckdb/pull/24517)

  Unflavored-from: a0606b86f713518865347b1431c634e090e7e515

- Update vendored sources to duckdb/duckdb@4ea700575c3b7560667284fa6d09a68ce90882a0.

  Date: 2026-08-05 12:02:45 +0000

  Fix compilation on Windows (https://redirect.github.com/duckdb/duckdb/pull/24334)

  Unflavored-from: 7a85a8a395375832c0500e4d298b15bb586cf085

- Update vendored sources to duckdb/duckdb@a82e24d90b706c6b9bea33bca03dbee0ed3f0cb8.

  Date: 2026-08-05 11:58:20 +0000

  Fix stale projection ids in LogicalGet after pushdown extract (https://redirect.github.com/duckdb/duckdb/pull/24484)

  Unflavored-from: d1609b9746b15845f6f265a133f5fdc4db43faef

- Update vendored sources to duckdb/duckdb@9bde766b24fa4124ab46b6342d95f42d732aa770.

  Date: 2026-08-05 11:33:24 +0000

  Fix histogram overflow counts with duplicate bins (https://redirect.github.com/duckdb/duckdb/pull/24486)

  Unflavored-from: 8e9dcf6f7763e5618b917c2120504f01c937d728

- Update vendored sources to duckdb/duckdb@c5e9d42afda96865a4b2f3e50496ce6b301a3144.

  Date: 2026-08-05 11:32:22 +0000

  Fix projected types for missing columns (https://redirect.github.com/duckdb/duckdb/pull/24508)

  Unflavored-from: c6f3edb178aabc0e8458d924a0a8b1083d0ce8d5

- Update vendored sources to duckdb/duckdb@0202739a68cf183b45b0a15cc12b8c75b85d4ee7.

  Date: 2026-08-05 09:52:00 +0000

  Propagate Parquet expression reader statistics (https://redirect.github.com/duckdb/duckdb/pull/24505)
  Split linux test configs in more CI jobs (https://redirect.github.com/duckdb/duckdb/pull/24510)

  Unflavored-from: cb67093333d7e0f619f78811c0d1e633bc742845

- Update vendored sources to duckdb/duckdb@b9ae72d13fb93afcb7ee978352b4a3ecee726833.

  Date: 2026-08-05 09:50:52 +0000

  Avoid array with brackets creating an extra demension (https://redirect.github.com/duckdb/duckdb/pull/24515)

  Unflavored-from: 8d76d0f553403e0cefedc46962fdf8d58c346883

- Update vendored sources to duckdb/duckdb@f9db03428a3b4d9002084576c8367ce3be76756b.

  Date: 2026-08-05 09:50:32 +0000

  Fix quantile hugeint precision (https://redirect.github.com/duckdb/duckdb/pull/24511)

  Unflavored-from: 595830fa585895414de1e1584b95624c0c22efed

- Update vendored sources to duckdb/duckdb@193754bd447ed9cdd30c95c6631f06412af327a1.

  Date: 2026-08-05 09:49:33 +0000

  Fix dedimal width overflow (https://redirect.github.com/duckdb/duckdb/pull/24509)

  Unflavored-from: 2300470f2970d7dd795e22ef652cd127466443d5

- Update vendored sources to duckdb/duckdb@f9e0566246e9ed4b2ff10921056b5b2323e0c9a3.

  Date: 2026-08-05 09:47:18 +0000

  Skip unnecessary payloads during WAL checkpoint prescan (https://redirect.github.com/duckdb/duckdb/pull/24434)

  Unflavored-from: 55a73173995f4b66831437e4b3a5baa1682567c2

- Update vendored sources to duckdb/duckdb@0289ca4035f298bc3000ce5ff525239dd36a48ac.

  Date: 2026-08-05 09:43:24 +0000

  Rewrite IS DISTINCT FROM NULL (https://redirect.github.com/duckdb/duckdb/pull/24411)

  Unflavored-from: bc5c79ffa36021b1c6b082a51dd1f168a429bc77

- Update vendored sources to duckdb/duckdb@03bded90172b61f99544b715ae8c8f136a645396.

  Date: 2026-08-05 09:06:50 +0000

  Fix FIRST_VALUE streaming eligibility for framed windows (https://redirect.github.com/duckdb/duckdb/pull/24497)

  Unflavored-from: b4bba14b94180b1327b4f299bdf93e962578fc31

- Update vendored sources to duckdb/duckdb@978e67093eec28032110f53921dba66dfd89ddf9.

  Date: 2026-08-05 09:03:55 +0000

  Compress FSST input directly instead of copying it in 511-byte chunks (https://redirect.github.com/duckdb/duckdb/pull/24496)

  Unflavored-from: a34060c7980ca102f093777c61eb6dde634f3003

- Update vendored sources to duckdb/duckdb@e813349d2a577ef6d2634459ea7359395fae5f3b.

  Date: 2026-08-05 08:53:19 +0000

  Initial implementation of `variant_group_array` processing function (https://redirect.github.com/duckdb/duckdb/pull/24347)

  Unflavored-from: 9c10cf0baed6bc7c15d31397028db1c45699fcf9

- Update vendored sources to duckdb/duckdb@a886b21067bbb887158cfaefd5bac6055f331d70.

  Date: 2026-08-05 08:52:46 +0000

  Check entry type before cast (https://redirect.github.com/duckdb/duckdb/pull/24487)
  Improve the performance of timezone function (https://redirect.github.com/duckdb/duckdb/pull/24437)

  Unflavored-from: 19202caef017172b3bf89f03b911ca33fc93aaef

- Update vendored sources to duckdb/duckdb@47b20f12564950999ad5cfbaa18ef84d1f5efc20.

  Date: 2026-08-04 14:52:14 +0000

  Throw an internal error when functions are incorrectly labeled as infallible, and fix this for many functions (https://redirect.github.com/duckdb/duckdb/pull/24389)

  Unflavored-from: cd2ff48c48a1da50ae0b62b30bd1da283afdbb47

- Update vendored sources to duckdb/duckdb@7255424293982d7ec53b0d72b73a4b56c1c4ce0c.

  Date: 2026-08-04 14:37:22 +0000

  Add `SET SCHEMA` grammar support (https://redirect.github.com/duckdb/duckdb/pull/23709)

  Unflavored-from: 2386265d9561b5946557e6c247ef2289b0a00103

- Update vendored sources to duckdb/duckdb@163581a5692c15e17adffa8e078848e7359e5b4f.

  Date: 2026-08-04 14:23:07 +0000

  Concurrent non-positional writes (https://redirect.github.com/duckdb/duckdb/pull/24500)

  Unflavored-from: 444416b5fa2831f7b0076cdb57e8fada2cf904cd

- Update vendored sources to duckdb/duckdb@a0128bc399a705fce32b59919b1d2f2faede3837.

  Date: 2026-08-04 13:46:32 +0000

  Fix VARIANT field extraction in index fetch (https://redirect.github.com/duckdb/duckdb/pull/24428)
  Switch Calendar / TZ code from using `double` to using `int64_t` (https://redirect.github.com/duckdb/duckdb/pull/24471)

  Unflavored-from: 07b571cf6ac37489a28a72c85089bbf28d048f23

- Update vendored sources to duckdb/duckdb@c1a755440949e17d6a04802906b5b69a11eba25c.

  Date: 2026-08-04 13:35:12 +0000

  Propagate validity statistics through `lower` and `upper` (https://redirect.github.com/duckdb/duckdb/pull/24478)

  Unflavored-from: fa839d1428182bf1faaf19d92b0db5ffe2b371d6

- Update vendored sources to duckdb/duckdb@7d1a147c97741225a458ac32b6d6702aa5cf7788.

  Date: 2026-08-04 13:12:55 +0000

  Preserve trailing UTF-8 bytes in StringUtil::RTrim (https://redirect.github.com/duckdb/duckdb/pull/24482)
  Only enable mold --icf=safe when the linker supports it (https://redirect.github.com/duckdb/duckdb/pull/24492)

  Unflavored-from: 4c79f4aff744446a19ad8016dc7c25fbd97e0e0e

- Update vendored sources to duckdb/duckdb@d7bdd9354856b1f35aeb8d82b608f0b8d0a36f81.

  Date: 2026-08-04 09:20:16 +0000

  Cast to common argument types for array_value (https://redirect.github.com/duckdb/duckdb/pull/24490)

  Unflavored-from: 25de5c0e0989f57f68c27525ba8a47f40bd7b76a

- Update vendored sources to duckdb/duckdb@5b65610e944ce3d31a1b44b55924d009c4c148bd.

  Date: 2026-08-04 09:19:42 +0000

  Check time bucker operation overflow (https://redirect.github.com/duckdb/duckdb/pull/24489)

  Unflavored-from: 07bdce21d8ceeb6cd159ec1a8cfa045b18540d2b

- Update vendored sources to duckdb/duckdb@f7792a42b70a883f2254ece5899b94a13603f283.

  Date: 2026-08-04 09:18:50 +0000

  Improve string literal casting (https://redirect.github.com/duckdb/duckdb/pull/24436)

  Unflavored-from: 4f7de3b37c3ed5755fa15249372761f1b321d5e8

- Update vendored sources to duckdb/duckdb@3fe7ba2e9ec5f976f849e6d86c003d28d65833cd.

  Date: 2026-08-04 09:17:03 +0000

  Preserve recursive CTE parallelism at high thread counts (https://redirect.github.com/duckdb/duckdb/pull/24466)

  Unflavored-from: 3aa5c2b5dd038aa6561ccbb83ad61f48f35d2350

- Update vendored sources to duckdb/duckdb@4f8561b975bcb492c931e1f991c2d9e3b74d7270.

  Date: 2026-08-04 09:14:49 +0000

  Fix crash in enum_first/enum_last on empty ENUM types (https://redirect.github.com/duckdb/duckdb/pull/24480)
  unittest: allow require-env for passed-through variables (https://redirect.github.com/duckdb/duckdb/pull/24459)
  Add null check for `json_execute_serialized` (https://redirect.github.com/duckdb/duckdb/pull/24470)

  Unflavored-from: b79ca8aca909314ed2e795094c5ca23aba582348

- Update vendored sources to duckdb/duckdb@d38be889cc62bef0b833878c596c16b984eb49fc.

  Date: 2026-08-03 17:54:21 +0000

  Optimize LRU cache (https://redirect.github.com/duckdb/duckdb/pull/24472)

  Unflavored-from: cd8c59890bf5d552e52c536b708704e8c36132aa

- Update vendored sources to duckdb/duckdb@30bd04fa20ba0289f349503165f5861b3f7d423f.

  Date: 2026-08-03 15:47:37 +0000

  Fix integer underflow in VariantMetadata (https://redirect.github.com/duckdb/duckdb/pull/24469)

  Unflavored-from: 1e15ef5ac4fc03a4644dce1e97b5a3fab1280fba

- Update vendored sources to duckdb/duckdb@b9c30a952114d4fc2c9360bc185a6de71684ea78.

  Date: 2026-08-03 15:44:41 +0000

  Use a bitmask instead of modulo when decoding bitpacked hugeints (https://redirect.github.com/duckdb/duckdb/pull/24468)

  Unflavored-from: bea9327725f8873d8942385f51d705e7b09d5746

- Update vendored sources to duckdb/duckdb@05119df7eaa8f4d489330fef9176a50d08f8f950.

  Date: 2026-08-03 15:42:18 +0000

  Fix two wrong-results bugs in the expression rewriter (https://redirect.github.com/duckdb/duckdb/pull/24368)
  Remove `icu` dependency, instead implement TimeZone and Calendar functionality ourselves (https://redirect.github.com/duckdb/duckdb/pull/24463)

  Unflavored-from: b05eb5eb293cdb1bb29c63588e213dfa232f7a15

- Update vendored sources to duckdb/duckdb@26bbfb1cce34703e7c92d015fd0adadbc6b2b160.

  Date: 2026-08-03 15:05:54 +0000

  Unify C-API symbol versioning (on main) (https://redirect.github.com/duckdb/duckdb/pull/24435)

  Unflavored-from: 55944a94b05730f6340d5367faaca97edde63725

- Update vendored sources to duckdb/duckdb@e83107b03b9ff1bbc05f376b964b130e4b8cbdab.

  Date: 2026-08-03 13:31:54 +0000

  Optimize `BLOB` sort key construction by using vectorize-friendly code (https://redirect.github.com/duckdb/duckdb/pull/24432)
  add debug_ds extension to the benchmark runner (https://redirect.github.com/duckdb/duckdb/pull/24430)
  Use smaller instance for extension load/install checks and skip a ducklake test on musl (https://redirect.github.com/duckdb/duckdb/pull/24426)

  Unflavored-from: 3c397aa10dde1620f68a76e185315db5eeec998f

- Update vendored sources to duckdb/duckdb@4d8e583592bf21d12110693fa0e8d96415ef5725.

  Date: 2026-08-03 09:34:59 +0000

  Add a warning when using OFFSET on result set without defined ordering (https://redirect.github.com/duckdb/duckdb/pull/24354)
  EXTERNAL RESOURCES: Unskip discovery tests now that the dependency landed (https://redirect.github.com/duckdb/duckdb/pull/24371)

  Unflavored-from: a1ec3cc94b970babc2e7bf1c50a9d743c72b91e8

- Update vendored sources to duckdb/duckdb@84f8cebb118d47912a0605ceffe6ba0f27896a70.

  Date: 2026-08-03 07:39:16 +0000

  Prune row group for IN operator and parquet read (https://redirect.github.com/duckdb/duckdb/pull/24374)

  Unflavored-from: 91ec2ae086aa85f542783203d5e140fb29d4f504

- Update vendored sources to duckdb/duckdb@50b69da54702877590b9cd2168c258ba0c3ae806.

  Date: 2026-08-03 07:32:26 +0000

  Propagate parquet min/max len if possible (https://redirect.github.com/duckdb/duckdb/pull/24384)

  Unflavored-from: 6a2726832d871541d9a4fbbcc16fcfdc181ae3a8

- Update vendored sources to duckdb/duckdb@149ded80a01b998a0af016885f63d7ef158ec7ba.

  Date: 2026-08-03 07:31:43 +0000

  Range check float =\> int casts on the rounded value (https://redirect.github.com/duckdb/duckdb/pull/24393)

  Unflavored-from: 098f3a655e42bc55028ac4e7f459b8fd981aa584

- Update vendored sources to duckdb/duckdb@ff89fb7f6e32f6ea475beea3349f1073b590a95b.

  Date: 2026-08-03 07:30:46 +0000

  Checks inline - throws out of line (https://redirect.github.com/duckdb/duckdb/pull/24404)

  Unflavored-from: 632a22da284fff9aa9cc5c2a7e3bebb3ea3f0381

- Update vendored sources to duckdb/duckdb@a18cb8d19f357360d8a7cbec9da861f0b7dabfa1.

  Date: 2026-08-03 07:29:30 +0000

  Reject invalid imported approx_quantile states (https://redirect.github.com/duckdb/duckdb/pull/24425)

  Unflavored-from: 39a6daeabe6be5bed4f38618c85e0047f8c4aa63

- Update vendored sources to duckdb/duckdb@b3062a5e82f50d77ff6e1006a36f645a79bc4936.

  Date: 2026-08-03 07:29:10 +0000

  Fix monotonic clock usage (https://redirect.github.com/duckdb/duckdb/pull/24423)

  Unflavored-from: d7635f8d5c28f3268666a6893c8caf53c6811f50

- Update vendored sources to duckdb/duckdb@e9f097ca795935df0437183e0695a41fa9470335.

  Date: 2026-08-03 07:28:36 +0000

  Reject non-integer index for variant (https://redirect.github.com/duckdb/duckdb/pull/24420)
  remove flaky test (https://redirect.github.com/duckdb/duckdb/pull/24408)

  Unflavored-from: d90b67ff21125e80f69b0e9f9c75b5eebc72f729

- Update vendored sources to duckdb/duckdb@6a57167d95285122b7cc02c267ac6afdea672707.

  Date: 2026-08-03 07:10:04 +0000

  Implement collations without ICU dependency (https://redirect.github.com/duckdb/duckdb/pull/24403)

  Unflavored-from: 0edaa84f7851b50f1c2528f88b5f98df8d57db59

- Update vendored sources to duckdb/duckdb@1f3f362601a95ab9f1a0d48b0950f5d359dca827.

  Date: 2026-08-02 19:03:00 +0000

  Trim sort key layout specializations under `SMALLER_BINARY` (https://redirect.github.com/duckdb/duckdb/pull/24394)

  Unflavored-from: 4b9af834b82ed318f95e40384f6220693d70e3b7

- Update vendored sources to duckdb/duckdb@5bb2025d2e201e7dbb9a168a6743bb868c72aa56.

  Date: 2026-08-02 08:18:53 +0000

  Make `BaseQueryResult` members private, and turn names into `vector<Identifier>` (instead of `vector<string>`) (https://redirect.github.com/duckdb/duckdb/pull/24357)
  Regenerate iceberg 0003 patch against the bumped pin (https://redirect.github.com/duckdb/duckdb/pull/24397)

  R-side fix:

  `BaseQueryResult::type`, `types` and `names` became private,
  and `names` became `vector<Identifier>` rather than `vector<string>`.
  Upstream migrated its own call sites to the public accessors
  in the same change.

  Take each member through its accessor —
  `GetResultType()`, `GetTypes()`, `GetNames()` —
  in `statement.cpp`, `relational.cpp` and `reltoaltrep.cpp`.

  Where a single name is wanted as a `string`,
  read it through `Identifier::GetIdentifierName()`,
  which hands back the raw value with its original casing;
  the conversion is explicit by design,
  because it discards the case-insensitive semantics
  the identifier type carries.

  Where a whole `vector<string>` is wanted —
  `StringsToSexp()` and the two `ArrowConverter::ToArrowSchema()` calls —
  use upstream's own `IdentifiersToStrings()` helper,
  which is what its C API does at the equivalent call site.

  Carried from `origin/v2.0-cyanoptera-dev` at 8dcbc11a86:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 15775a49f71d840110888f05e40bbce131500c71

- Update vendored sources to duckdb/duckdb@44200a30882062bb547a11672d35c282a715def5.

  Date: 2026-08-01 08:53:23 +0000

  Prune row groups for Parquet INTERVAL columns with bloom filters (https://redirect.github.com/duckdb/duckdb/pull/24277)

  Unflavored-from: 1ca5b271a2d124a241b27b79f142f3d533b2006e

- Update vendored sources to duckdb/duckdb@7a7094d500eef07f7447dccf6184450f4f5e68e0.

  Date: 2026-08-01 08:34:18 +0000

  Fix fill() interpolation for large DOUBLE ordering spans (https://redirect.github.com/duckdb/duckdb/pull/24179)

  Unflavored-from: 60345bcb329d67a841477a78eb2ebbfb3084e117

- Update vendored sources to duckdb/duckdb@66a9a69298971824eeb584a3e1c85a735630cc0a.

  Date: 2026-08-01 08:34:00 +0000

  bump iceberg (https://redirect.github.com/duckdb/duckdb/pull/24264)

  Unflavored-from: 5948e728d475223b80ef21eb1fa61818b7cf6b2d

- Update vendored sources to duckdb/duckdb@81fcce7fa76a320dc65be54cb0825e5315ac6f5b.

  Date: 2026-08-01 08:33:29 +0000

  Initial implementation of `variant_contains` processing function (https://redirect.github.com/duckdb/duckdb/pull/24343)

  Unflavored-from: 43de748534cc904aebb5c2c18e9afdf28527d995

- Update vendored sources to duckdb/duckdb@585a9aa3ab6b9f27844ead5bd3a6e9bc5f9d0e3e.

  Date: 2026-08-01 08:26:34 +0000

  Check meaningless suffix characters after parsing (https://redirect.github.com/duckdb/duckdb/pull/24390)

  Unflavored-from: 4c4ec4265b0d10a0cd2c70b07f403dbb9f9aa5bf

- Update vendored sources to duckdb/duckdb@75b4721f7d7825206b202ef6f153d72cf3c2d863.

  Date: 2026-08-01 08:19:59 +0000

  Fix ranking functions over empty or reversed frames (https://redirect.github.com/duckdb/duckdb/pull/24348)

  Unflavored-from: 9889d4963e0ab1eea2f5521fd5a49044e66a8df4

- Update vendored sources to duckdb/duckdb@4ce07600d8b39ee8845fa145fcf74b317d202913.

  Date: 2026-08-01 08:18:21 +0000

  Reset batch indexes between recursive CTE iterations (https://redirect.github.com/duckdb/duckdb/pull/24358)

  Unflavored-from: e31be762c1adfa51d9c287c76880fc550bc07661

- Update vendored sources to duckdb/duckdb@2861adb9aaf197c346df9280ceea44cd5bc75c9c.

  Date: 2026-08-01 08:16:22 +0000

  Use unimplemented exception over internal one (https://redirect.github.com/duckdb/duckdb/pull/24388)
  Remove multi-benchmark support and split CTE jobs (https://redirect.github.com/duckdb/duckdb/pull/24356)

  Unflavored-from: 9e75526b9f94dd79212714d63cb06d78656a52e7

- Update vendored sources to duckdb/duckdb@c0e88dd32ac436c64f29c7e0183591f543451b2a.

  Date: 2026-08-01 08:15:12 +0000

  \[ASYNC I/O\] Refactor in preparation for ASYNC in native files (https://redirect.github.com/duckdb/duckdb/pull/24360)

  Unflavored-from: fa18348872deb7cf781d4b17d6eacc0f81431b79

- Update vendored sources to duckdb/duckdb@b30b181cca8eb93b5eda20f735314576329c5e43.

  Date: 2026-08-01 08:07:41 +0000

  Restructure `DUCKDB_SMALLER_BINARY` into a preprocessor macro that allows granular attribution (https://redirect.github.com/duckdb/duckdb/pull/24364)

  Unflavored-from: 6be13fa7fd4b1947cd7f7aae2a5fa2c472cf7faa

- Update vendored sources to duckdb/duckdb@aff2b1ec3fed9df4ca9beed6dcdb133437971125.

  Date: 2026-08-01 08:06:25 +0000

  Fix wrong results and an out-of-bounds read in the LIST-\>ARRAY cast (https://redirect.github.com/duckdb/duckdb/pull/24367)

  Unflavored-from: 8e3676f9209875346495ff2bf0d5624c270ed018

- Update vendored sources to duckdb/duckdb@ea1ad0938422ea752252eeb2d1af1b3d1b05df8a.

  Date: 2026-08-01 08:03:45 +0000

  Fix false corruption error when reading FSST string segments for Clickbench Q11 (https://redirect.github.com/duckdb/duckdb/pull/24365)
  Un-skip 75 stale entries across 15 test configs (https://redirect.github.com/duckdb/duckdb/pull/24372)

  Unflavored-from: c243d65d5cb05793400f6e9748bfa529a458c793

- Update vendored sources to duckdb/duckdb@7a48de3dbced38de8511a478d134745102b26a4f.

  Date: 2026-08-01 08:02:38 +0000

  Fix export with quoted string (https://redirect.github.com/duckdb/duckdb/pull/24382)
  test harness: LOCAL\_{TEMP,DATA}\_DIR, add --env-passthrough, remote temp-dir fixes (https://redirect.github.com/duckdb/duckdb/pull/24355)

  Unflavored-from: e9ab48752ce4569d2a6cf67a1fd5314d1c6ab336

- Update vendored sources to duckdb/duckdb@48663f5c6527094d85a9a9c6d91fbbfa093e9899.

  Date: 2026-07-31 12:50:25 +0000

  Fix failed checkpoint marker recovery (https://redirect.github.com/duckdb/duckdb/pull/24260)

  Unflavored-from: d14733535926d74f13d2ed45bcc0e6f8e4d0de94

- Update vendored sources to duckdb/duckdb@fdd976343ea187ba79eecb1dbc10964b1f7231c0.

  Date: 2026-07-31 12:49:55 +0000

  Use `Identifier` for COPY and scan option names (https://redirect.github.com/duckdb/duckdb/pull/24269)

  R-side fix:

  `Relation::WriteParquet()` and `Relation::WriteCSV()` now take
  `identifier_map_t<vector<Value>>` for their COPY options.
  Return that map type from `ListToVectorOfValue()`,
  which exists only to feed those two calls,
  and promote each R name to an `Identifier` explicitly,
  as the type requires.
  Option-name lookup stays case-insensitive:
  `Identifier` compares and hashes case-insensitively,
  just as `case_insensitive_map_t` did.

  Carried from `origin/v2.0-cyanoptera-dev` at 736b795a68:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 94966bfdfa078a28a664198cf3fca0f82ed03b09

- Update vendored sources to duckdb/duckdb@4708cacdc18bb98ad6750454a35bbcf0d48f3b79.

  Date: 2026-07-31 12:47:37 +0000

  Split main extensions to lower CI critical path (https://redirect.github.com/duckdb/duckdb/pull/24345)

  Unflavored-from: 4637c5af3b448b0d334bf47159c7f12fc060b2d9

- Update vendored sources to duckdb/duckdb@bf753f906d774f05e60a4f55bb0470b0d7435e2c.

  Date: 2026-07-31 12:41:21 +0000

  Make all `PreparedStatement` members private (https://redirect.github.com/duckdb/duckdb/pull/24351)

  R-side fix:

  `PreparedStatement::error` became private,
  so `rapi_prepare()` can no longer read the member directly.
  Upstream migrated its own call sites to the public accessors
  in the same change.
  Take the error through `GetErrorObject()`,
  which hands back the same `ErrorData`
  and keeps the type and extra info that `rapi_error_with_context()`
  reports.

  Carried from `origin/v2.0-cyanoptera-dev` at 9349fff534:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 261d3d2934af15d7dd32e1ffeba9b53e59dc28a2

- Update vendored sources to duckdb/duckdb@f37a4ec984a849c482da482cd1344d34b57d19e8.

  Date: 2026-07-31 12:34:02 +0000

  Prune parquet row group for IS NOT DISTINCT FROM (https://redirect.github.com/duckdb/duckdb/pull/24338)

  Unflavored-from: aa6b8bde96414b6b4d80518df2562dac1cab7533

- Update vendored sources to duckdb/duckdb@1b44b05a044bbef5baae5af69303ef9f575d552d.

  Date: 2026-07-31 12:32:55 +0000

  Avoid mutating input buffers in decode(..., 'replace') (https://redirect.github.com/duckdb/duckdb/pull/24353)
  \[Bug\] Fix issue with worker thread yielding in Async I/O (https://redirect.github.com/duckdb/duckdb/pull/24352)

  Unflavored-from: 74a2b03c7e6b8ea46afaad11b130aa4442873e59

- Update vendored sources to duckdb/duckdb@a913be2d963c05229052b992fe4c389c94ccad40.

  Date: 2026-07-31 11:35:49 +0000

  Harden recursive CTE execution and optimize `USING KEY` joins (https://redirect.github.com/duckdb/duckdb/pull/24031)

  Unflavored-from: 18c8bbfbe0fb19a649eda132739bbeed6474ead0

- Update vendored sources to duckdb/duckdb@5cb1335d60a330830f62768ef39c4e760b66df2c.

  Date: 2026-07-31 11:33:46 +0000

  Fix: segfauly in url_decode with TRY() on dictionary-encoded columns (https://redirect.github.com/duckdb/duckdb/pull/24332)
  Unflavored-from: 4a33eb8d3ae2ee38f50baba95f180c29e05eec75

- Update vendored sources to duckdb/duckdb@22535309603770e24704c8b2e16de2065e27d7ff.

  Date: 2026-07-31 09:00:50 +0000

  Make `AtClause::Unit()` return an `Identifier` (https://redirect.github.com/duckdb/duckdb/pull/24236)
  Optimize unittest startup and reduce fast test runtime (https://redirect.github.com/duckdb/duckdb/pull/24331)

  Unflavored-from: c921c2268f83e81450c463035e2ffc66b03750ac

- Update vendored sources to duckdb/duckdb@cb37aee0a5946fe08e8525460184dbddf81a5ca6.

  Date: 2026-07-31 09:00:10 +0000

  Nested schemas: support the remaining catalog entry types (https://redirect.github.com/duckdb/duckdb/pull/24322)
  Skip flaky CTE order preservation test (https://redirect.github.com/duckdb/duckdb/pull/24340)

  Unflavored-from: 817acd99003e246362fefbd233a239d451dc692a

- Update vendored sources to duckdb/duckdb@0bd0677eecebbb292cce047d258049701aeaaa51.

  Date: 2026-07-31 08:17:07 +0000

  Bump httpfs (https://redirect.github.com/duckdb/duckdb/pull/24325)

  Unflavored-from: ca8ea47e9df899aea719dd3a700b37210971747b

- Update vendored sources to duckdb/duckdb@c47eae1cd5700a11c8c4ffb774fa46e1555ff208.

  Date: 2026-07-30 15:19:04 +0000

  Avoid passing in `const string &query` in ClientContext methods, instead get the string from the SQLStatement (https://redirect.github.com/duckdb/duckdb/pull/24324)
  Remove deprecated workflow dispatch calls (https://redirect.github.com/duckdb/duckdb/pull/24323)

  Unflavored-from: 7a4c2188d327821ed9d8b3fca2a100d6da7c153d

- Update vendored sources to duckdb/duckdb@484f07c6f0675f4bfbd7c140b98bde59c3832264.

  Date: 2026-07-30 11:57:33 +0000

  Propagate ARRAY statistics through LIST casts (https://redirect.github.com/duckdb/duckdb/pull/24290)
  Enable mold implicitly for linux release builds (https://redirect.github.com/duckdb/duckdb/pull/24230)

  Unflavored-from: 084c9303f92805d1ad3655da90e578f5c0dbd20a

- Update vendored sources to duckdb/duckdb@0f96a2efc5986b7dea4f3978d83373f981cb87d1.

  Date: 2026-07-30 11:48:01 +0000

  Handle hive NULL in string format (https://redirect.github.com/duckdb/duckdb/pull/24318)

  Unflavored-from: bd68f6ac194edc5452dcd2ecff193419a2fbbe4a

- Update vendored sources to duckdb/duckdb@76361ce4fbdb143af81faab4d89b70255bb22388.

  Date: 2026-07-30 09:05:26 +0000

  Reconstruct in-memory index for read-only database (https://redirect.github.com/duckdb/duckdb/pull/24105)

  Unflavored-from: 336a2254fe06fe14edfa5f4a65edcf4ba24aca29

- Update vendored sources to duckdb/duckdb@7becbbfed86ff04946fb657ba8eaa4303db2b579.

  Date: 2026-07-30 08:29:35 +0000

  Add batch index support to PhysicalColumnDataScan (https://redirect.github.com/duckdb/duckdb/pull/24084)

  Unflavored-from: be3f7395cb8cf33b0bc7f5976ea951bb07ab01ac

- Update vendored sources to duckdb/duckdb@e9b0786fe163147178f600070ccb8508a5493745.

  Date: 2026-07-30 08:06:22 +0000

  Push down safe ILIKE prefix ranges (https://redirect.github.com/duckdb/duckdb/pull/24063)

  Unflavored-from: 1de8e455be90abc83c1348f2bc95d11463753fb0

- Update vendored sources to duckdb/duckdb@2909a842aab3957d4412481cc60801a4a7fdb60c.

  Date: 2026-07-30 07:30:33 +0000

  Bump FTS extension to latest main (https://redirect.github.com/duckdb/duckdb/pull/24095)

  Unflavored-from: 6853b60a8fdc82f97d7d6e30f7311956a4538623

- Update vendored sources to duckdb/duckdb@f4c89d9a6b78232d97b0ab224534e0f6b28ef776.

  Date: 2026-07-30 07:23:44 +0000

  Do not export temp catalog (https://redirect.github.com/duckdb/duckdb/pull/24300)

  Unflavored-from: 3d5dac436914683e9efbbd335774b92fbdf4edaa

- Update vendored sources to duckdb/duckdb@3ba0b64f4d0746800e9b811ba5d3006f1d15f21a.

  Date: 2026-07-30 07:22:04 +0000

  Fix encrytion util access (https://redirect.github.com/duckdb/duckdb/pull/24312)

  Unflavored-from: eedb006d9e5b69840a0d4f0396f6b6332f57234a

- Update vendored sources to duckdb/duckdb@68f45797960f782c3ad6d2a6db6de999e5fdb196.

  Date: 2026-07-30 07:21:33 +0000

  Fix https://github.com/duckdb/duckdb/discussions/24315 (https://redirect.github.com/duckdb/duckdb/pull/24316)

  Unflavored-from: fe9061bbf7b67bf903d007aa84dbaead83a3df5c

- Update vendored sources to duckdb/duckdb@56b0c8f6b2326a11267b199b0b34969efefd7c47.

  Date: 2026-07-30 05:56:20 +0000

  Deduplicate JSON object keys in VARIANT casts (https://redirect.github.com/duckdb/duckdb/pull/24041)

  Unflavored-from: 045220d2e5dd64af76c8b83520d603b54515eddc

- Update vendored sources to duckdb/duckdb@349c6f8db4e1475f69d7d5717489fd10135ea3bc.

  Date: 2026-07-30 05:36:56 +0000

  Fix struct field with default renaming (https://redirect.github.com/duckdb/duckdb/pull/24211)

  Unflavored-from: eac1d9d9c42540ae28869099d5c4f49e3237c45c

- Update vendored sources to duckdb/duckdb@d54e4f6a20c75e4cf1bdd7bbecb24bd08a62a491.

  Date: 2026-07-29 18:55:27 +0000

  Merge `v1.5-variegata` into main (https://redirect.github.com/duckdb/duckdb/pull/24275)
  Only define EXT_VERSION\_ for the sources that read it (https://redirect.github.com/duckdb/duckdb/pull/24248)

  R-side fix

- Update vendored sources to duckdb/duckdb@2c9e51aa33dd07e928edae66304430aeb038edd7.

  Date: 2026-07-29 15:07:36 +0000

  Re-enable MERGE for composite row ids (https://redirect.github.com/duckdb/duckdb/pull/24271)

  Unflavored-from: 5ab1b73e7035b1e3afc810a9e0c1725ccdf392d1

- Update vendored sources to duckdb/duckdb@11db31f8cec6e003d3d369c4b71579d4d7fd824d.

  Date: 2026-07-29 13:54:02 +0000

  Allow passing an Identifier to SQLQuotedIdentifier directly (https://redirect.github.com/duckdb/duckdb/pull/24274)

  Unflavored-from: 571bdda854109819419fa3a08b569cc8da167a26

- Update vendored sources to duckdb/duckdb@b5e4f5bec063ca68dff4cb63c697034fe2faeedd.

  Date: 2026-07-29 13:13:13 +0000

  Rework `PreparedStatement` in the C++ API to no longer hold state, and to instead unify with `PREPARE, EXECUTE, DEALLOCATE` workflows (https://redirect.github.com/duckdb/duckdb/pull/24273)

  R-side fix

- Update vendored sources to duckdb/duckdb@7b6b4c1a586d0504b7e8d26a1f7059dba6ed4f1f.

  Date: 2026-07-29 11:52:52 +0000

  Re-enable clangd-tidy check in CI (https://redirect.github.com/duckdb/duckdb/pull/24242)

  Unflavored-from: a44719829743b812847fee11462321d4aa2b5f07

- Update vendored sources to duckdb/duckdb@1258e9cdac24368125dc57ad154012323a7c768f.

  Date: 2026-07-29 11:22:58 +0000

  Leverage bloom filter to prune parquet struct (https://redirect.github.com/duckdb/duckdb/pull/24266)

  Unflavored-from: f8eaa8f70483d8649a4b8a68dec22deae4218cf4

- Update vendored sources to duckdb/duckdb@455ad5acca1ea7f020a3669da218df500731eb2b.

  Date: 2026-07-29 11:14:10 +0000

  \[MultiFileReader\] Add optional `extra_columns` to `MultiFileReaderData` (https://redirect.github.com/duckdb/duckdb/pull/24234)

  Unflavored-from: 9c14a584b91362df8bed1c57dd5c25e26ba9761a

- Update vendored sources to duckdb/duckdb@af479510a40dd78139af8990994471c3e6709f14.

  Date: 2026-07-29 11:07:21 +0000

  Add a `StartsWith` helper to `Identifier` (https://redirect.github.com/duckdb/duckdb/pull/24267)

  Unflavored-from: 5b9b99f5a8fb56e0cc83fa4fd26c3a45c1d18a83

- Update vendored sources to duckdb/duckdb@af1b4a9bd28532cbb0c09b58f8aa037b889f126d.

  Date: 2026-07-29 08:08:23 +0000

  CSV: remove unreachable type check (https://redirect.github.com/duckdb/duckdb/pull/24219)
  Remove unintended files (https://redirect.github.com/duckdb/duckdb/pull/24262)

  Unflavored-from: dd66e777f056bc87f3aada7c83e945de65a8f30e

- Update vendored sources to duckdb/duckdb@2f68fcbd52984a6793cfd86a8c7109dc8f3ec0a3.

  Date: 2026-07-29 07:36:42 +0000

  Fix https://redirect.github.com/duckdb/duckdb/pull/23979 (https://redirect.github.com/duckdb/duckdb/pull/24235)
  Bump bwc-test-utils to latest main (https://redirect.github.com/duckdb/duckdb/pull/24229)

  Unflavored-from: e7a2df8e3ab6d4671089206a7b52b5b40832900a

- Update vendored sources to duckdb/duckdb@6668f9ed157be547e9524064d2628a7054c792b4.

  Date: 2026-07-29 07:19:44 +0000

  Add `Value::GetValue<Identifier>()` (https://redirect.github.com/duckdb/duckdb/pull/24238)

  Unflavored-from: 2871aebf829e772136c37dd2d3391ef691bb89c5

- Update vendored sources to duckdb/duckdb@9f32ea718b5ab98cd8263ab7ba58d2d9f9a584a2.

  Date: 2026-07-29 07:19:05 +0000

  Fix table filter canonicalization in common subplan optimizer (https://redirect.github.com/duckdb/duckdb/pull/24258)

  Unflavored-from: d580dd13f36a5982a011d2038a41ad7115110eeb

- Update vendored sources to duckdb/duckdb@e5d6787a684fd90084704edbc412049760304a8f.

  Date: 2026-07-29 06:54:41 +0000

  Prune row group for parquet LIST type with bloom filter (https://redirect.github.com/duckdb/duckdb/pull/24150)

  Unflavored-from: b07d1a2232b0d43aee8797d48a46c1fb849388a7

- Update vendored sources to duckdb/duckdb@82f44b5f97767ab9d37aaa6e9c14d9d0d1ca6dc4.

  Date: 2026-07-29 06:54:26 +0000

  Fix rowid row group prune (https://redirect.github.com/duckdb/duckdb/pull/24100)
  Fix errors in microbenchmarks (https://redirect.github.com/duckdb/duckdb/pull/24227)

  Unflavored-from: 0a7df52bb8a77e787a4fe8fb4eb64fc9e618f386

- Update vendored sources to duckdb/duckdb@d268a65b240e5cfc67f939058b87c6b34d3472d1.

  Date: 2026-07-28 15:16:20 +0000

  EXTERNAL RESOURCES: SQL surface for CREATE / DESTROY / SHOW / REGISTER (https://redirect.github.com/duckdb/duckdb/pull/24056)

  Unflavored-from: 308cccbd843c10f7f458e57710970dbfcadf1b23

- Update vendored sources to duckdb/duckdb@f91908958d7c7d0ac6161c02e7b593900ae6eaa6.

  Date: 2026-07-28 14:25:19 +0000

  Feature: Implement Extremum Rewrite for ANY Inequalities (https://redirect.github.com/duckdb/duckdb/pull/24090)
  Unflavored-from: 5d69182b011eced8afc695c6bb69b5fec2379245

- Update vendored sources to duckdb/duckdb@61884b46a9efc34058945e4d98650191f67cb461.

  Date: 2026-07-28 13:32:57 +0000

  Make sure dictionary vectors don't contain invalid values (https://redirect.github.com/duckdb/duckdb/pull/24223)

  Unflavored-from: 2c7b741262efc4586e884bfa08d605d78192791f

- Update vendored sources to duckdb/duckdb@607b1015dc7b394803240d0fb517876def488926.

  Date: 2026-07-28 12:46:40 +0000

  Bump avro, aws, iceberg (https://redirect.github.com/duckdb/duckdb/pull/24026)

  Unflavored-from: 70b9d450663737582a654652c03ca092ddb40f44

- Update vendored sources to duckdb/duckdb@263480d0b918bf563b9e8a30b6e633008ac4dd11.

  Date: 2026-07-28 11:29:31 +0000

  \[MultiFileReader\] Add column indexes to `DynamicFilterPushdown` parameters (https://redirect.github.com/duckdb/duckdb/pull/24226)

  Unflavored-from: a6e51e75d40e9ededfc8c62e6f56a161253204c2

- Update vendored sources to duckdb/duckdb@56467371979b83a8b6eda77955eebd8ffb92bdb0.

  Date: 2026-07-28 11:00:00 +0000

  EXTERNAL RESOURCES: Improved interface for listing arbitrary ones (https://redirect.github.com/duckdb/duckdb/pull/24024)
  Fix bench runs (https://redirect.github.com/duckdb/duckdb/pull/24224)

  Unflavored-from: bd45ee754be5e4672cc54f56028f32af8502d733

- Update vendored sources to duckdb/duckdb@77e66df575f616d595866025f92b146cde0626b6.

  Date: 2026-07-28 10:39:00 +0000

  \[WIP\] Add support for querying from nested schemas (https://redirect.github.com/duckdb/duckdb/pull/24222)

  Unflavored-from: e4b1ae3b9410bf76c9ca5fdcd42e2a5a522528d2

- Update vendored sources to duckdb/duckdb@8956cec9b8abee050174f86fe733193ce5af2af8.

  Date: 2026-07-28 09:27:21 +0000

  Correlated non-`INNER` joins (https://redirect.github.com/duckdb/duckdb/pull/23658)
  Override git hash in release cli (https://redirect.github.com/duckdb/duckdb/pull/24216)

  R-side fix

- Update vendored sources to duckdb/duckdb@8d5682bb00ae05b1ed6c5a7c0b749cef6bb7f693.

  Date: 2026-07-28 09:02:18 +0000

  Define UPDATE ... FROM and MERGE behavior for multi-matched target rows (https://redirect.github.com/duckdb/duckdb/pull/24058)

  Unflavored-from: 1e21e4ce0ff47b66af908109df985a68c6203299

- Update vendored sources to duckdb/duckdb@de050d084a9ba13017d81f2718a274d2e4576ce7.

  Date: 2026-07-28 09:01:31 +0000

  Add `NEAREST BY` join support (https://redirect.github.com/duckdb/duckdb/pull/24137)

  Unflavored-from: 188d467d8a928b66209369544445fd96fdb8877d

- Update vendored sources to duckdb/duckdb@41412ad2adec9ca7e4e6b4e75c3843bd7e6ff2b8.

  Date: 2026-07-28 08:53:15 +0000

  Make `COPY` usable in CTEs (https://redirect.github.com/duckdb/duckdb/pull/24217)
  Fix NightlyTests (https://redirect.github.com/duckdb/duckdb/pull/24198)

  Unflavored-from: e4d81fd0aeb258e7ba55f24064ffa341feeb4ce7

- Update vendored sources to duckdb/duckdb@438f2be21145dc4f7435843c9693167c75c6c309.

  Date: 2026-07-28 08:44:06 +0000

  push down scalar functions for queries with LIMIT (https://redirect.github.com/duckdb/duckdb/pull/24122)

  Unflavored-from: a3aff42078dace33c3ba04a34db729632906d514

- Update vendored sources to duckdb/duckdb@c01790ebd50ed3d8a6a4a9dd0d19c923574435e3.

  Date: 2026-07-28 08:35:12 +0000

  Parquet: validate flat column value counts (https://redirect.github.com/duckdb/duckdb/pull/24104)
  Unflavored-from: ff5ac663f3750d0ec2d801b590f8c27dc68642bd

- Update vendored sources to duckdb/duckdb@20180ceb03c3de71b9f3bd9a894d1f7bc11948f9.

  Date: 2026-07-28 08:22:07 +0000

  Perf regression: ValidateDictionaryIndex in hot loop and shared_ptr access (https://redirect.github.com/duckdb/duckdb/pull/24014)

  Unflavored-from: 002e540044ef20f7d8356d883e4645925176cc12

- Update vendored sources to duckdb/duckdb@c06001429c37a4991032a0bd5b038d1f4ca1cbea.

  Date: 2026-07-28 08:19:11 +0000

  Add support for `enable_optimistic_write` setting which disables optimistic writing (https://redirect.github.com/duckdb/duckdb/pull/24194)

  Unflavored-from: 53fc4cd19734c99fe429938a7e321e8be59ada97

- Update vendored sources to duckdb/duckdb@09b10345f1ba32103e922e76e3d903d05646f8ec.

  Date: 2026-07-28 08:18:41 +0000

  Connect + detach race and add missing InvokeCloseIfLastReference's (https://redirect.github.com/duckdb/duckdb/pull/24202)

  Unflavored-from: 9bbd610b61e90a12e84cb6f285e33b26e590f9b2

- Update vendored sources to duckdb/duckdb@852c9f23c4a5ac606d8cc3db0b3d5a537131c3bf.

  Date: 2026-07-28 08:10:32 +0000

  Skip Parquet bloom pruning for NaN (https://redirect.github.com/duckdb/duckdb/pull/23944)

  Unflavored-from: 2389b5141f1b135c91332128174c4ca2725f2cbe

- Update vendored sources to duckdb/duckdb@22c9d7f677e331608f9154d87ec2d087cb4a362b.

  Date: 2026-07-28 08:09:26 +0000

  Throw on HUGEINT SUM/AVG overflow in aggregate Combine (https://redirect.github.com/duckdb/duckdb/pull/24168)

  Unflavored-from: c9be8a6c3f4df9223fb2e7b9a607f2eb242f6901

- Update vendored sources to duckdb/duckdb@a33f37c884e2c40840781832f3dc41ff561da3dc.

  Date: 2026-07-28 08:09:07 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9925: Tiny Buffer Suballocation (https://redirect.github.com/duckdb/duckdb/pull/24124)

  Unflavored-from: d152ce75beb93a7be58bf9a32bb4825d34aefcdc

- Update vendored sources to duckdb/duckdb@e0692f2bf6fe5c6f68e376d8c3e244380a4152ec.

  Date: 2026-07-28 08:05:24 +0000

  Automatically promote `DECIMAL` past the `BIGINT` boundary (https://redirect.github.com/duckdb/duckdb/pull/24185)
  Alternate benchmark runs for old and new (https://redirect.github.com/duckdb/duckdb/pull/24184)

  Unflavored-from: 99bbebae300e877884d859ab5518f2eb8957dd76

- Update vendored sources to duckdb/duckdb@531911608719cd03b723051b8cb3b3e81cf3e03b.

  Date: 2026-07-27 17:57:43 +0000

  \[Parquet\] Add BYTE_STREAM_SPLIT support for INT32 and INT64 (https://redirect.github.com/duckdb/duckdb/pull/24175)
  Fix quoting around extension semantic version pattern (https://redirect.github.com/duckdb/duckdb/pull/24176)

  Unflavored-from: b3d1c1d4f5ed8381f14398577463df42b299c101

- Update vendored sources to duckdb/duckdb@c42f367da90773a2779f1a57cd2c71c7b13088ab.

  Date: 2026-07-27 11:43:20 +0000

  Fix validity column update check in zonemap (https://redirect.github.com/duckdb/duckdb/pull/24181)
  Windows CLI: opt into the Segment Heap via application manifest (~2.2x faster multi-threaded materialization) (https://redirect.github.com/duckdb/duckdb/pull/24036)

  Unflavored-from: f07fa2e68e99188623e558137c48c1ce6cc414b3

- Update vendored sources to duckdb/duckdb@b7ed657449badd2c1b2e8eb470114042ed582fd3.

  Date: 2026-07-27 09:13:38 +0000

  Fix Mark Join Null Handling (https://redirect.github.com/duckdb/duckdb/pull/22683)

  Unflavored-from: 97edc91fb0eb7778f9f0275b686b283faba940ba

- Update vendored sources to duckdb/duckdb@66617082ef32967a04234b16762ed433bfc4b15a.

  Date: 2026-07-27 07:37:08 +0000

  Fix INSTEAD OF triggers being silently accepted on base tables (https://redirect.github.com/duckdb/duckdb/pull/24163)

  Unflavored-from: 0216e94a4e18a369458e606a159bbdc9f83e7d84

- Update vendored sources to duckdb/duckdb@7316202df1f856f339e2442a05dfdada231b1fec.

  Date: 2026-07-24 18:53:02 +0000

  Arena allocate the memory for each aggregate state in TDigest (https://redirect.github.com/duckdb/duckdb/pull/24125)
  Make benchmark runner output/regressions easier to read (https://redirect.github.com/duckdb/duckdb/pull/24134)

  Unflavored-from: c9df2933fa56d7cbac474de452fd5c4523bd6817

- Update vendored sources to duckdb/duckdb@985a76e2f9a6b81aa80c091a09a5eaca1471fa67.

  Date: 2026-07-24 18:49:37 +0000

  \[main\] Replace the C API spec and code generation (https://redirect.github.com/duckdb/duckdb/pull/24135)
  Replace old lambda syntax in micro-extended benchmark (https://redirect.github.com/duckdb/duckdb/pull/24129)
  \[main\] Remove Julia client in favor of duckdb/DuckDB.jl (https://redirect.github.com/duckdb/duckdb/pull/24126)

  Unflavored-from: 3492b4109ce7d622ca9d74590f8b35323fac103e

- Update vendored sources to duckdb/duckdb@9ef1a9939a0e2feb9951435601fbb74b7ff8ff28.

  Date: 2026-07-24 11:46:53 +0000

  Prune row group via castable types (https://redirect.github.com/duckdb/duckdb/pull/24074)

  Unflavored-from: 629a724b86ff09613209b97cde1dd41c421af447

- Update vendored sources to duckdb/duckdb@b97d697b0291f647878b176ea5afb4c94e56a935.

  Date: 2026-07-24 11:46:15 +0000

  Parallelize `UNION ALL` branches when `preserve_insertion_order` is false (https://redirect.github.com/duckdb/duckdb/pull/24117)

  Unflavored-from: f98b452059d92a08b93dbaa89fc3d3dcfd161fe7

- Update vendored sources to duckdb/duckdb@b828a31972e725756c827f686448559d19a752b3.

  Date: 2026-07-24 11:19:34 +0000

  unbound index buffering refactor (https://redirect.github.com/duckdb/duckdb/pull/24038)

  Unflavored-from: 489651900454a60b0b3e8db609b425ff84823042

- Update vendored sources to duckdb/duckdb@b8744e15781d500e032c70c023fdb1f1e40e2a26.

  Date: 2026-07-24 09:29:14 +0000

  Optimize row group pruning for substr (https://redirect.github.com/duckdb/duckdb/pull/23990)
  Set OVERRIDE_GIT_DESCRIBE in extensions.yml (https://redirect.github.com/duckdb/duckdb/pull/24106)

  Unflavored-from: 46a3d465890679704025d744425d40b513c74477

- Update vendored sources to duckdb/duckdb@8806a9f8638cf876f979762a8161c83a02ea9bc6.

  Date: 2026-07-23 12:53:45 +0000

  Bump DuckLake (https://redirect.github.com/duckdb/duckdb/pull/24082)

  Unflavored-from: dd5b191f7398178eec8377c31167cc022f6173e4

- Update vendored sources to duckdb/duckdb@9fdc1696a610f0f76e4ad8c557514ccb6915ff2b.

  Date: 2026-07-23 12:05:56 +0000

  Default vacuuming in the presence of indexes (https://redirect.github.com/duckdb/duckdb/pull/23653)
  Fix warnings and support alpha release version in extensions (https://redirect.github.com/duckdb/duckdb/pull/24083)

  Unflavored-from: 148ddd7b32e6405a920f8349f58b60a5d2bbd547

- Update vendored sources to duckdb/duckdb@b95e49bf7a04ce517ce9632327eb4345030993a9.

  Date: 2026-07-23 10:12:57 +0000

  Rewrite DISTINCT aggregates as CTEs (https://redirect.github.com/duckdb/duckdb/pull/24055)

  Unflavored-from: 3845aa67fa47727eed72205e55eef0fea0a7a9d3

- Update vendored sources to duckdb/duckdb@71145c7b2726c29c46a2c8af71ebf7ea8051c22f.

  Date: 2026-07-23 09:35:41 +0000

  \[WIP\] Add support for inserting data into tables in nested schemas (https://redirect.github.com/duckdb/duckdb/pull/24076)

  Unflavored-from: 6d3ae8c320810487384c5ec7a790a9f016f7283b

- Update vendored sources to duckdb/duckdb@34f2a32f08e9c454205f1ce45a4e9fa38adf4f53.

  Date: 2026-07-23 07:08:47 +0000

  Convert `BoundCastExpression` into a `BoundFunctionExpression` (https://redirect.github.com/duckdb/duckdb/pull/24008)

  Unflavored-from: 12e81392c2a60fa6a0b15e20001c7d26540ed993

- Update vendored sources to duckdb/duckdb@5ca47af3d30eb1f92852aa120e9dda2230701247.

  Date: 2026-07-23 07:02:37 +0000

  Add SetVal (https://redirect.github.com/duckdb/duckdb/pull/24061)

  Unflavored-from: ac7d8c1acd32e0e5858ed3e3c598069b18b52b71

- Update vendored sources to duckdb/duckdb@09ebf16ebf55c4d1b05ac41ec1b06f790d8f2284.

  Date: 2026-07-23 09:01:47 +0200

  Fix monotonicity annotations for floating-point numeric functions (https://redirect.github.com/duckdb/duckdb/pull/24046)

  Unflavored-from: 6fd0b18a77676df4eb59b25c6d0e5f32092062f8

- Update vendored sources to duckdb/duckdb@c97bd8b96e0481b9e58d491f4fcd8599fccd65fb.

  Date: 2026-07-22 15:06:00 +0000

  Bump httpfs on `main` and remove patches (https://redirect.github.com/duckdb/duckdb/pull/24059)

  Unflavored-from: 3885650708b50a873f7279a5aa533318069554b1

- Update vendored sources to duckdb/duckdb@59808d29554a5a5bc01400c964c64166e118dbc7.

  Date: 2026-07-22 14:46:21 +0000

  Packrat parsing stack overflow fix (https://redirect.github.com/duckdb/duckdb/pull/23705)

  Unflavored-from: 13ff4193a45064d3052fdec0372f982f37854d64

- Update vendored sources to duckdb/duckdb@f9fc037d90adb0af1b07adf3b980952817528b0d.

  Date: 2026-07-22 14:45:37 +0000

  Throw descriptive error for chained operators (https://redirect.github.com/duckdb/duckdb/pull/23863)

  Unflavored-from: db3576b43d3f9d44902ff3a9bc7c19793a960227

- Update vendored sources to duckdb/duckdb@eea72333dfd55b2392a42e0af4c5254366ab8317.

  Date: 2026-07-22 14:28:42 +0000

  Storage: validate deprecated FSST metadata (https://redirect.github.com/duckdb/duckdb/pull/24016)
  Unflavored-from: 2ef471ab7c9d8b832901352ed243493ededc7153

- Update vendored sources to duckdb/duckdb@108f39420c688d2c193e627059bff5ed0f7db448.

  Date: 2026-07-22 14:28:16 +0000

  Pass bind data to aggregate state size/init callbacks and batch state init (https://redirect.github.com/duckdb/duckdb/pull/24028)

  Unflavored-from: 054d32964b89a42f02a07427185b934a5200f22b

- Update vendored sources to duckdb/duckdb@60a71522daeb5fdc70973659ad0e3688c230c48a.

  Date: 2026-07-22 14:27:55 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/23927: Nested Inequality NULLS (https://redirect.github.com/duckdb/duckdb/pull/24037)
  Use fixed length for commit sha abbreviation (https://redirect.github.com/duckdb/duckdb/pull/24057)

  Unflavored-from: 4c4a1f25a8255ee004a18f0772191c31edd9c597

- Update vendored sources to duckdb/duckdb@929a0e336b2dfdc2653b5c833bd76af189f29c37.

  Date: 2026-07-22 13:18:50 +0000

  Shrink the in-memory footprint of deleted rows (https://redirect.github.com/duckdb/duckdb/pull/23964)

  Unflavored-from: 16fefb7ffb93193e9a187480a20758d2f2c93bc0

- Update vendored sources to duckdb/duckdb@f9c46ac8055849fe4b8895d2a86c921d32227030.

  Date: 2026-07-22 12:49:44 +0000

  Add assert_true macro (https://redirect.github.com/duckdb/duckdb/pull/24019)

  Unflavored-from: 9df9b2a5fc88fb0d20ab45167f5f96c851c5654a

- Update vendored sources to duckdb/duckdb@eaf91f6763752c7489738ea6c9063d25f19fb91f.

  Date: 2026-07-22 11:41:57 +0000

  Fix bloom filter pruning for DECIMAL types (https://redirect.github.com/duckdb/duckdb/pull/23919)

  Unflavored-from: 627e7e36f196bd26dde811ea4bab495adc29534a

- Update vendored sources to duckdb/duckdb@3305afbcb08c39a056ad9c098754df57d07bcbe0.

  Date: 2026-07-22 08:14:47 +0000

  Fix date parsing (https://redirect.github.com/duckdb/duckdb/pull/23939)

  Unflavored-from: 51b5859e2246363fe228d4d17b45c0a9e0ebddc6

- Update vendored sources to duckdb/duckdb@887c6c504579d9d9ce69b279eaa45f949afbf132.

  Date: 2026-07-22 08:14:21 +0000

  Support bloom filter for NOT DISTINCT FROM for parquet (https://redirect.github.com/duckdb/duckdb/pull/24005)

  Unflavored-from: 79c3afd38d53d113e03013bd74e186542b1d174c

- Update vendored sources to duckdb/duckdb@57982437ad5f1222b6bab7ad64ff0744ec488a89.

  Date: 2026-07-22 08:13:29 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9937: AsOf Cardinality Estimates (https://redirect.github.com/duckdb/duckdb/pull/24029)
  Use optimized checkout action and simplify CI workflows (https://redirect.github.com/duckdb/duckdb/pull/24035)

  Unflavored-from: 60a3ec118bb18ec9831c35679adb305888faea39

- Update vendored sources to duckdb/duckdb@21aca0424f1faf78b593b1e6fbfdd4846624c987.

  Date: 2026-07-21 15:37:24 +0000

  Add accessor to get constant function arguments (https://redirect.github.com/duckdb/duckdb/pull/24025)
  Add explicit user agent to avoid r2's 403 forbidden (https://redirect.github.com/duckdb/duckdb/pull/24032)

  Unflavored-from: 6ca91d4a7d49e28f2139bcf0dad366fd16eff557

- Update vendored sources to duckdb/duckdb@8d15d0be8d94fc389a47d09a5e3e89094239874d.

  Date: 2026-07-21 14:15:00 +0000

  Optimize GLOB using string stats for row group pruning (https://redirect.github.com/duckdb/duckdb/pull/23920)
  Call release dispatch in summary for (pre)releases (https://redirect.github.com/duckdb/duckdb/pull/24023)

  Unflavored-from: f60f2dd2852d3e746f8db61c750ddf6f99646f5a

- Update vendored sources to duckdb/duckdb@b55763c3ff67bdcb2bceb1ecc0cfa2e7ac4244dd.

  Date: 2026-07-21 13:32:19 +0000

  Initial implementation of `variant_type` processing function (https://redirect.github.com/duckdb/duckdb/pull/23286)
  Parse constant JSON paths once at bind time (https://redirect.github.com/duckdb/duckdb/pull/24002)

  Unflavored-from: 906b89a2adea944841e95c023a4195e11d3cf062

- Update vendored sources to duckdb/duckdb@2ccd606370f73cb8255303a542d80714efaaad42.

  Date: 2026-07-21 12:29:34 +0000

  \[ASYNC I/O\] CSV Read Ahead (https://redirect.github.com/duckdb/duckdb/pull/24022)

  Unflavored-from: 71f82bc639709796733145e4179011fb4e237d43

- Update vendored sources to duckdb/duckdb@55eeda55052b705a88b3f6bba70e781212fd6063.

  Date: 2026-07-21 11:53:11 +0000

  Fix missing trigger assignments on schema evolution (https://redirect.github.com/duckdb/duckdb/pull/23855)

  Unflavored-from: 7647643e81c9be90b0698ca4d22f7faee2d4440b

- Update vendored sources to duckdb/duckdb@3badb56f71becdf7059bf4ab32e01eed27c14405.

  Date: 2026-07-21 11:43:48 +0000

  Propagate statistics for power expressions (https://redirect.github.com/duckdb/duckdb/pull/23922)

  Unflavored-from: 1483b4937fbce1cd06bfeebefa091cc88d61572a

- Update vendored sources to duckdb/duckdb@1956d1b975089f3979114c24ef2afff45c4b4c13.

  Date: 2026-07-21 11:32:02 +0000

  StorageLock: wait on a condition variable instead of busy-spinning (https://redirect.github.com/duckdb/duckdb/pull/24009)
  Unflavored-from: ce656cfac0427d5bc74ca11d3b6c673aa5e00682

- Update vendored sources to duckdb/duckdb@713fb7d8e97bcbcd64a68bc0a74a9a289ebdcf5a.

  Date: 2026-07-21 11:30:24 +0000

  Prune parquet row group for equal between (https://redirect.github.com/duckdb/duckdb/pull/24011)

  Unflavored-from: 9a049f6d69b0fcff1c09203d3e875548a0beabf1

- Update vendored sources to duckdb/duckdb@7f4cbcef3662eb933c9bfcddfd43a0f25523247f.

  Date: 2026-07-21 10:30:05 +0000

  \[ASYNC I/O\] Add on-demand ASYNC I/O for the CSV Reader (https://redirect.github.com/duckdb/duckdb/pull/23961)

  Unflavored-from: f3507865be91e4760a71d70c31af94dafec716a2

- Update vendored sources to duckdb/duckdb@275ed39b61048d122cf654c788ac0bf75a45d3d2.

  Date: 2026-07-21 10:06:13 +0000

  Support OLD transition table for AFTER UPDATE triggers (https://redirect.github.com/duckdb/duckdb/pull/23840)

  Unflavored-from: 48fe9178acc49d259b06dd23e6c5e5107442a906

- Update vendored sources to duckdb/duckdb@c5763aeb32504fcba46ecbe2ad5d2c95ed26748e.

  Date: 2026-07-21 09:55:43 +0000

  Apply bloom filter for parquet UUID type (https://redirect.github.com/duckdb/duckdb/pull/24018)

  Unflavored-from: ff73f3f47ebb4a1376a01fc7850be7cc2aa241ff

- Update vendored sources to duckdb/duckdb@b0bb8c90c7e50f96616fffa24cdee55ee21491a6.

  Date: 2026-07-21 09:49:02 +0000

  EXTERNAL RESOURCES: external resources via table functions (https://redirect.github.com/duckdb/duckdb/pull/23910)

  Unflavored-from: 0c5bff5700f9344c6354eccc1af8681e87d63b8a

- Update vendored sources to duckdb/duckdb@f1aa4b86ea317208fceb1fc5ab60da2d6672df59.

  Date: 2026-07-21 09:37:39 +0000

  Prune row group for empty string concatenation (https://redirect.github.com/duckdb/duckdb/pull/23992)
  Improve pretty printing for logging to CLI (https://redirect.github.com/duckdb/duckdb/pull/23912)

  Unflavored-from: a7546f0c13f8b9e94da8a5846bfc37d2285c34c4

- Update vendored sources to duckdb/duckdb@86ff3a07cdbc7fc7d1739c07d2a88f0ff1a9c731.

  Date: 2026-07-21 08:49:57 +0000

  Fix TIME_NS read/write with parquet (https://redirect.github.com/duckdb/duckdb/pull/23958)
  Reduce test time (2+ sec) for some fast tests (https://redirect.github.com/duckdb/duckdb/pull/23974)

  Unflavored-from: 8e7a6f62fd9f98ad659adc536c587428e1703f94

- Update vendored sources to duckdb/duckdb@bd0f9ea2e6fc54e9b24a160013e5c348dda73107.

  Date: 2026-07-21 08:20:02 +0000

  \[MultiFileReader\]\[Parquet\] Add `variant_extract` pushdown (https://redirect.github.com/duckdb/duckdb/pull/22478)

  Unflavored-from: 22bbb73835d2c87b628ea241d42ff5a84ddeaa89

- Update vendored sources to duckdb/duckdb@28a5f19724cc5810b5ad3289114ac23c3bc0b6bb.

  Date: 2026-07-21 08:18:45 +0000

  Add `lttb` aggregate function (https://redirect.github.com/duckdb/duckdb/pull/23660)

  Unflavored-from: 1ee5e4bcd8cc19849adcf0b3aad9f52cbc5e31df

- Update vendored sources to duckdb/duckdb@fa9fe15b120d7e76bb81599bdad6ba99bda2b73e.

  Date: 2026-07-21 08:15:10 +0000

  Fix extra semicolon on export (https://redirect.github.com/duckdb/duckdb/pull/23977)

  Unflavored-from: 0468c9c54602b2100add0e3ebc9ffb46568a2254

- Update vendored sources to duckdb/duckdb@249695c21bdc3ca274be36e383c61fc7f7a14f12.

  Date: 2026-07-21 07:49:20 +0000

  Skip win32 tests (if requested) in CI and consider alpha version as a (pre)release (https://redirect.github.com/duckdb/duckdb/pull/23960)
  Bump Postgres extension on main (https://redirect.github.com/duckdb/duckdb/pull/23968)

  Unflavored-from: 3960cdecde4f2c64ca47b3f4411fc624e5c207c1

- Update vendored sources to duckdb/duckdb@583951ea73bdbf804312d6110b0e6572911b067f.

  Date: 2026-07-21 07:42:31 +0000

  Fix remote pushdown arguments post function binding rework (https://redirect.github.com/duckdb/duckdb/pull/23973)

  Unflavored-from: 0821a42b75cd8c6fb950d8e99b1298cb37adf874

- Update vendored sources to duckdb/duckdb@a387bda31d23b72a0fec04f7d70fe3e44cc10ae4.

  Date: 2026-07-21 07:14:50 +0000

  Add verify compression to test FSST without regressing relassert (https://redirect.github.com/duckdb/duckdb/pull/23967)

  Unflavored-from: e82b7d5cc401cbfbb45a4b516f571a81093c6246

- Update vendored sources to duckdb/duckdb@9ebdd1ee5279885dd2a89d4ac8f37034c05de203.

  Date: 2026-07-20 21:05:38 +0000

  Capi add allocation handlers (https://redirect.github.com/duckdb/duckdb/pull/23945)

  Unflavored-from: 7e80cd046fc1be898f1c4e362166e9b90d4e50e2

- Update vendored sources to duckdb/duckdb@53fba4b92e2588c3e4db8798691f558aebbbcf0c.

  Date: 2026-07-20 19:55:33 +0000

  Add monotonicity properties to scalar math functions (https://redirect.github.com/duckdb/duckdb/pull/23926)

  Unflavored-from: af5768b710c6166d67c64abc0c9abe80727588c6

- Update vendored sources to duckdb/duckdb@ede913885ac8a23bb2111b45590b72c94d580c23.

  Date: 2026-07-20 18:02:59 +0000

  Fix SEMI/ANTI join mishandling duplicate equality keys with residual predicate (https://redirect.github.com/duckdb/duckdb/pull/23952)

  Unflavored-from: 6c36813e96c8dd41deffce948202ba48cb9d3ef9

- Update vendored sources to duckdb/duckdb@b98263558bf0afb1f0eac0d559a0a6604bbd688c.

  Date: 2026-07-20 14:55:32 +0000

  Add streaming fanout execution for materialized CTEs (https://redirect.github.com/duckdb/duckdb/pull/23750)

  Unflavored-from: 8f3ec80ed37bdd036faed2b565d1525a7e095462

- Update vendored sources to duckdb/duckdb@6c88f9f84cda7d502c954f6354e910bd29f56a41.

  Date: 2026-07-20 13:50:22 +0000

  \[WIP\] Add support for creating and dropping tables in nested schemas (https://redirect.github.com/duckdb/duckdb/pull/23809)

  Unflavored-from: 0126f0ce79bfab5c93c54d3525f8e1c9e7dbb003

- Update vendored sources to duckdb/duckdb@4c6a2a69ffb5b61eb87b3321d18c8cc05a1737c8.

  Date: 2026-07-20 11:55:46 +0000

  Simplify boolean wrappers around comparisons (https://redirect.github.com/duckdb/duckdb/pull/23948)

  Unflavored-from: 6159efb555f214713df51303e7ba4b1132d7a42c

- Update vendored sources to duckdb/duckdb@e85aef5b2458ea8e3604c716a143634ac2f53d66.

  Date: 2026-07-20 11:55:05 +0000

  Prune date type for parquet (https://redirect.github.com/duckdb/duckdb/pull/23915)

  Unflavored-from: f469bbff7c49169a04d690804313f37e6fccec01

- Update vendored sources to duckdb/duckdb@18ec4b3e4bb22d7fb30e4bb20cc4eaa0a4453c70.

  Date: 2026-07-20 11:53:41 +0000

  Add LoongArch64 support with 16KB page size (https://redirect.github.com/duckdb/duckdb/pull/19962)

  Unflavored-from: 038a98a36455e96fddd0fa3961c1a455bead41ca

- Update vendored sources to duckdb/duckdb@fe9c57ff4fb658c12ef07cfd7884437f23baf26e.

  Date: 2026-07-20 11:35:47 +0000

  \[Secret\] Add `TRANSACTION` persist-type for SECRET, added to the `MetaTransaction` (https://redirect.github.com/duckdb/duckdb/pull/23882)

  Unflavored-from: 13215aa59fce3dce3557996f50d8d1ccab721a49

- Update vendored sources to duckdb/duckdb@a9c8920301d28783432fb024edce73a69d6ffb60.

  Date: 2026-07-20 11:18:14 +0000

  Implement stats for INTERVAL type (https://redirect.github.com/duckdb/duckdb/pull/23923)

  Unflavored-from: eb1882a5d3e4919e259b70e241bf17259a54e421

- Update vendored sources to duckdb/duckdb@c9d5c9cb6d75a79e92fe78d31f31720b2ce3c1fd.

  Date: 2026-07-20 10:58:53 +0000

  Implement stats callback for sign (https://redirect.github.com/duckdb/duckdb/pull/23904)

  Unflavored-from: 7c960f3babf2c2e62e0eaccb77716b8dcf35e2d7

- Update vendored sources to duckdb/duckdb@13217c91c30b626148999d5b46c705a235859b20.

  Date: 2026-07-20 10:45:24 +0000

  Optimizer: restrict equal-or-null rewrite to predicates (https://redirect.github.com/duckdb/duckdb/pull/23947)
  Unflavored-from: 2a9213599fbc04420651b1d765a0c008ab764018

- Update vendored sources to duckdb/duckdb@08cb7a49e91f14edc6dfa8b497268eabc6533f8d.

  Date: 2026-07-20 08:55:24 +0000

  In TableDescription, resolve catalog, schema, and table names through the catalog (https://redirect.github.com/duckdb/duckdb/pull/23866)
  Add more missing includes (https://redirect.github.com/duckdb/duckdb/pull/23893)
  Fix recursive file read in shell (https://redirect.github.com/duckdb/duckdb/pull/23942)

  Unflavored-from: aebdaa068e1a3fbce2aa173447dbe09f12fc0095

- Update vendored sources to duckdb/duckdb@476a357325dc411affac1722900e2ed086e11546.

  Date: 2026-07-20 08:33:07 +0000

  Add NOT conjunction simplification rule (https://redirect.github.com/duckdb/duckdb/pull/23886)

  Unflavored-from: 4b64866943f77102902215f9b8b7dfb03df88b15

- Update vendored sources to duckdb/duckdb@14f11423fcc991ad66080bb56fe0b00cb74148ff.

  Date: 2026-07-20 08:32:39 +0000

  storage: validate metadata block indexes (https://redirect.github.com/duckdb/duckdb/pull/23950)
  Internal https://redirect.github.com/duckdb/duckdb/pull/9925: TimeZone 2026c Update (https://redirect.github.com/duckdb/duckdb/pull/23928)

  Unflavored-from: 8adac01e7926677760c601adc9946af38f4f0cb0

- Update vendored sources to duckdb/duckdb@6975e262d07fffe89e2fed8d4cb372e12c038734.

  Date: 2026-07-20 08:22:20 +0000

  Support CTAs for GetTableNames API (https://redirect.github.com/duckdb/duckdb/pull/23760)
  Fix staged install check and alpha release versioning (https://redirect.github.com/duckdb/duckdb/pull/23897)

  Unflavored-from: 0b77ddd88808beb38de44f2e60d380f092e6ef08

- Update vendored sources to duckdb/duckdb@bda0e15d48f37269a56f5687bbc8625db4f4efb9.

  Date: 2026-07-20 08:17:16 +0000

  Rewrite `instr` function to prefix if possible (https://redirect.github.com/duckdb/duckdb/pull/23931)

  Unflavored-from: 560add0a9c4413a67ed28dfadede8fa0fc8c690d

- Update vendored sources to duckdb/duckdb@8bffc9d0a8b80d807defa065082c3a336ad0a929.

  Date: 2026-07-20 08:16:07 +0000

  Expose destructors, so they are callable module boundaries (https://redirect.github.com/duckdb/duckdb/pull/23954)

  Unflavored-from: 3653add79cf2c2b25f88852d34e9c611eb7547ae

- Update vendored sources to duckdb/duckdb@4dce06fd911a78acc2411e2de84393837e72802e.

  Date: 2026-07-20 07:39:00 +0000

  Add missing AOC benchmark queries and fix LEFT JOIN issue (https://redirect.github.com/duckdb/duckdb/pull/23895)

  Unflavored-from: 899b5c6078035d08f7767960bf227f205d141f17

- Update vendored sources to duckdb/duckdb@b43ad6a94264d2084679053b47b56de33a23230d.

  Date: 2026-07-20 07:38:14 +0000

  Handle row group pruning with NULL (https://redirect.github.com/duckdb/duckdb/pull/23902)

  Unflavored-from: 31c7417c2e8f3eecf259815b2b7653584177c76c

- Update vendored sources to duckdb/duckdb@d3e276efa7bfa99a371175f3a31b556637d111de.

  Date: 2026-07-20 07:37:37 +0000

  Prune row group for `strlen` function via string length stats (https://redirect.github.com/duckdb/duckdb/pull/23873)

  Unflavored-from: e02a15a72d5f4abf33be81f3b9bd452d85cf6368

- Update vendored sources to duckdb/duckdb@a82c23c5ac9123e5e1efe3800bd173f3054daab1.

  Date: 2026-07-20 07:37:24 +0000

  Add missing row group prune via pruned string min (https://redirect.github.com/duckdb/duckdb/pull/23871)

  Unflavored-from: 6fe60ce51fbd81d383fb2311528bb9ceea6dbb19

- Update vendored sources to duckdb/duckdb@117e1a46be1c903c5a36ee3c881c125597f93c60.

  Date: 2026-07-17 23:15:37 +0000

  \[ASYNC IO\] CSV Reader Refactor (https://redirect.github.com/duckdb/duckdb/pull/23868)

  Unflavored-from: 9ea45a5d2b952942850b1e675c85d08bc19eb312

- Update vendored sources to duckdb/duckdb@a7378a20fd7505773ebe76c06bc2b77a2d7ef184.

  Date: 2026-07-17 16:26:47 +0000

  `SHOW ALL` make `TABLES` optional (https://redirect.github.com/duckdb/duckdb/pull/23845)

  Unflavored-from: 0110886981fecca553b7da448f1b0532d7193f74

- Update vendored sources to duckdb/duckdb@37b7f2c180b2e25cd89af3d679d69882385ac340.

  Date: 2026-07-17 11:36:05 +0000

  Use output column name in EXPLAIN for ORDER BY and TOP N (https://redirect.github.com/duckdb/duckdb/pull/23801)

  Unflavored-from: 2ec80019780022047a8fb8105a6160249501204a

- Update vendored sources to duckdb/duckdb@e26f8d251f85142c7a5f7aa67c213831d33710a3.

  Date: 2026-07-17 10:58:44 +0000

  Rewrite `substring`, `substr`, `array_slice`, `list_slice`, `s[:]` for `VARCHAR` to prefix (https://redirect.github.com/duckdb/duckdb/pull/23869)

  Unflavored-from: 511d5f6c8127ff8a04a74e9440ee5e171bef0ac8

- Update vendored sources to duckdb/duckdb@7560f8256d70d36d8f0185222567939c48d78257.

  Date: 2026-07-17 09:20:25 +0000

  Fix file handle lifecycle for external file cache with async IO (https://redirect.github.com/duckdb/duckdb/pull/23881)

  Unflavored-from: 5ffc43e11bc3b9df8d0d0aeb44ae47c90ef4d1ea

- Update vendored sources to duckdb/duckdb@63244c085191dc50ba8c1adda331da7a4fc44190.

  Date: 2026-07-17 09:14:12 +0000

  Prune row group for suffix function with string stats (https://redirect.github.com/duckdb/duckdb/pull/23878)

  Unflavored-from: 58f7f82863a2dbaf80bd557a65d9c7b1fcae2a43

- Update vendored sources to duckdb/duckdb@2e271c62820d8ade347f7b45e5466ea0dac31f9f.

  Date: 2026-07-17 09:13:57 +0000

  Prune row group for `contains` via string stats (https://redirect.github.com/duckdb/duckdb/pull/23876)

  Unflavored-from: d11c57c3c4ef4b5044f4038fca096c89aa03653d

- Update vendored sources to duckdb/duckdb@bc123bc8762aa9e48e069d6261c3d577d340d13f.

  Date: 2026-07-17 08:48:54 +0000

  Optimize stats writer for DICT_FSST (https://redirect.github.com/duckdb/duckdb/pull/23846)

  Unflavored-from: 3947951edb0eaeabec64e8563120cb4995563a87

- Update vendored sources to duckdb/duckdb@d60c509f778cda14ff80e07f9f7656791527115f.

  Date: 2026-07-17 08:38:49 +0000

  Cache Vector::size (https://redirect.github.com/duckdb/duckdb/pull/23851)

  Unflavored-from: d3e24e2c3cc764de466602106ce368d4ad467b4a

- Update vendored sources to duckdb/duckdb@302c1a9bc5d731a8297b6c9077606a987fad532c.

  Date: 2026-07-17 08:37:52 +0000

  Implement TRY_CAST for time-related types (https://redirect.github.com/duckdb/duckdb/pull/23708)

  Unflavored-from: 68c582e2134713ae15889fa21a18f68877647408

- Update vendored sources to duckdb/duckdb@dac56bb380866c31c82586e7ea78b7b53eef3fcf.

  Date: 2026-07-17 08:36:59 +0000

  Fix `median` for INTERVAL type (https://redirect.github.com/duckdb/duckdb/pull/23701)
  Add regression test to ensure default DICT_FSST (https://redirect.github.com/duckdb/duckdb/pull/23847)

  Unflavored-from: e477aaf627ab38459bdf72595bfc27a8753d8a98

- Update vendored sources to duckdb/duckdb@d2b2ed34841061977e036ee35eaba37339d57d55.

  Date: 2026-07-16 11:28:06 +0000

  Storage: validate dictionary bitpacking width (https://redirect.github.com/duckdb/duckdb/pull/23827)
  Unflavored-from: 5583e9de2f4cb99c8e3385a2540933ba6a782ff5

- Update vendored sources to duckdb/duckdb@9b4d33a3d03ecff20201259d015da7db23da63a7.

  Date: 2026-07-16 11:08:11 +0000

  Defer setting cardinality set for appender (https://redirect.github.com/duckdb/duckdb/pull/23850)

  Unflavored-from: b9bed5d69c403a0d3fe851ee13e12c46df74e494

- Update vendored sources to duckdb/duckdb@79f50ef2633d05a9736b68bf9c34295189c1302c.

  Date: 2026-07-16 12:56:07 +0200

  Preserve NULL semantics in CTE deliminator (https://redirect.github.com/duckdb/duckdb/pull/23753)

  Unflavored-from: 328a721c1f0bea5dbeefa0db76e8edca376aba2e

- Update vendored sources to duckdb/duckdb@ce80890a0edd337fb850543f15c32c74106f785b.

  Date: 2026-07-16 10:32:10 +0000

  Inline Value::IsNan (https://redirect.github.com/duckdb/duckdb/pull/23852)
  Fix for new extension build when used from within extensions (https://redirect.github.com/duckdb/duckdb/pull/23862)

  Unflavored-from: 01b426e3c98263c9edcd1b7c189f85af670adf60

- Update vendored sources to duckdb/duckdb@37b956757a1b7b7b2e01559475508feb05ea2311.

  Date: 2026-07-16 09:25:26 +0000

  Add json_set(), json_insert(), json_replace() and json_remove() scalar functions (https://redirect.github.com/duckdb/duckdb/pull/23786)

  Unflavored-from: a8efdf2e4e04efc784036a064d49024bafd61009

- Update vendored sources to duckdb/duckdb@bb36e31f40401750d80ca7303bab49f137728abd.

  Date: 2026-07-16 08:58:51 +0000

  Improve pruning via string stats (https://redirect.github.com/duckdb/duckdb/pull/23728)

  Unflavored-from: b93a8c0b29bf9c9b5f688582fea9a693b1be25ab

- Update vendored sources to duckdb/duckdb@c34ce3712d030418f73ac6495e7d1d9e3236d5e5.

  Date: 2026-07-16 08:55:34 +0000

  Row-group pruning on boolean columns via NumericStats zonemap (https://redirect.github.com/duckdb/duckdb/pull/23726)

  Unflavored-from: d26f63db7b7cc3753fc67bf245dafa1576289f1d

- Update vendored sources to duckdb/duckdb@7c0fa265df67f4d8ed5cc4f94910c5677d127afd.

  Date: 2026-07-15 14:43:26 +0000

  Support `ANALYSE` where we support `ANALYZE` (https://redirect.github.com/duckdb/duckdb/pull/23843)

  Unflavored-from: 37a990b99ff4011df2c2a5c322e5a75ea1208cca

- Update vendored sources to duckdb/duckdb@2193b552c5d156186d1f2c2639deb844a6e69842.

  Date: 2026-07-15 13:37:30 +0000

  Add guard to prevent exception in `test_vector_types` (https://redirect.github.com/duckdb/duckdb/pull/23831)

  Unflavored-from: 6a4a064143b5f65482a24a2520ef6db7bc7d5bd6

- Update vendored sources to duckdb/duckdb@a12c6ab87e5fb20b50dc4c3b9a53d452e1247636.

  Date: 2026-07-15 13:35:13 +0000

  Fix Parquet bloom filter pruning for blobs (https://redirect.github.com/duckdb/duckdb/pull/23829)

  Unflavored-from: 7982d6fcad03cc1036392d50882bc2225ea6a310

- Update vendored sources to duckdb/duckdb@3c96c66afe31e101f0dd443ac1128ccc4acc881e.

  Date: 2026-07-15 13:13:20 +0000

  Validate catalog entry read (https://redirect.github.com/duckdb/duckdb/pull/23836)

  Unflavored-from: 08eb4f31cf126587e1455002f07805ca2e0dcd76

- Update vendored sources to duckdb/duckdb@9861ae7559f358705f8bc8fd2890422906aaa79c.

  Date: 2026-07-15 13:11:44 +0000

  Fix epoch_ns for infinity timestamp (https://redirect.github.com/duckdb/duckdb/pull/23834)
  Implement TIMESTAMP_NS -\> TIMESTAMPTZ_NS (https://redirect.github.com/duckdb/duckdb/pull/23832)

  Unflavored-from: daf8063f0f330b50895918b26c83ea197d4eb73c

- Update vendored sources to duckdb/duckdb@79546723fe00f47a2b604da8fdac670a6b17d1ef.

  Date: 2026-07-15 12:54:22 +0000

  Enable DICT_FSST by default (https://redirect.github.com/duckdb/duckdb/pull/23733)

  Unflavored-from: 948ec96ddb3d45dff906d2ce75634bfc5a1aa32c

- Update vendored sources to duckdb/duckdb@51088b726dbcb18c38639c163ff8e08cb0f5805a.

  Date: 2026-07-15 12:34:48 +0000

  More missing includes breaking non-unity builds (https://redirect.github.com/duckdb/duckdb/pull/23837)

  Unflavored-from: 5673349fc225a601da45523d28933b695b070a3a

- Update vendored sources to duckdb/duckdb@341df0483c8e468e6a4405baf3139dd9167403e1.

  Date: 2026-07-15 12:28:43 +0000

  Fix canonical bindings for nested common subplans (https://redirect.github.com/duckdb/duckdb/pull/23839)

  Unflavored-from: ccba6f691a94bb298273459cb9eca9ae9a3727f2

- Update vendored sources to duckdb/duckdb@642f86f6993d7cc072219eb065e5beeafbd255b1.

  Date: 2026-07-15 11:03:17 +0000

  Parquet: validate bloom filter payload length (https://redirect.github.com/duckdb/duckdb/pull/23826)
  Unflavored-from: 4832902e0ddd24045ccec59295a4cd415468d430

- Update vendored sources to duckdb/duckdb@d8cf949c689ce71d41854d2590a36d53d1539654.

  Date: 2026-07-15 11:02:45 +0000

  Expression filter handle NOT IN NULL (https://redirect.github.com/duckdb/duckdb/pull/23825)

  Unflavored-from: f4ba6577bbaf2ffc3bde03f9885896b1534b3094

- Update vendored sources to duckdb/duckdb@b89472c1174292b195ee64678436bf47ab4ce464.

  Date: 2026-07-15 10:38:50 +0000

  Bump aws, adding cloudformation listing and resource type (https://redirect.github.com/duckdb/duckdb/pull/23830)

  Unflavored-from: 7f4c61a4ade006ff593cc9f7eb2e7ed19d0321a2

- Update vendored sources to duckdb/duckdb@5a06216cbac11414a48eda43c6e262e2f3d8aec3.

  Date: 2026-07-15 09:20:46 +0000

  Fix quoting rules in QualifiedName::ParseComponents (https://redirect.github.com/duckdb/duckdb/pull/23798)

  Unflavored-from: 693a909865b6e22a8b78f2eeff12f7c3d101dfca

- Update vendored sources to duckdb/duckdb@697e15a3f52bb2a5dcac804e829a65128cdcf1c8.

  Date: 2026-07-15 08:48:54 +0000

  Fix: reset empty_range in the TIMESTAMP range() table function (https://redirect.github.com/duckdb/duckdb/pull/23811)
  Unflavored-from: 80cb6fa6feeac39a50e15c2c8367303231629615

- Update vendored sources to duckdb/duckdb@323b1113205bdacd1104c3d65ff9008081d2e74a.

  Date: 2026-07-15 08:42:06 +0000

  Add missing include (https://redirect.github.com/duckdb/duckdb/pull/23812)
  Fix timestamp_tz_ns_t -\> timestamp_ns_t conversion deadloop (https://redirect.github.com/duckdb/duckdb/pull/23817)

  Unflavored-from: 6f89e638f1e476f5a4a595f592df98df2d2faddc

- Update vendored sources to duckdb/duckdb@d7253e8e57d46530a4bda264d3eb3f98764ba910.

  Date: 2026-07-15 08:26:14 +0000

  Handle infinite timestamp for parquet timestamp (https://redirect.github.com/duckdb/duckdb/pull/23822)

  Unflavored-from: ffbc03a8d070044b543f88dbc9cea57240f20ec8

- Update vendored sources to duckdb/duckdb@0244deecd3331d1aa5f5011726dc0272d3f91215.

  Date: 2026-07-15 08:24:24 +0000

  Fix DICT_FSST filter (https://redirect.github.com/duckdb/duckdb/pull/23815)

  Unflavored-from: d0a1f5e76e2fc124029c64ed27f8da71c95ab271

- Update vendored sources to duckdb/duckdb@5244a93440670b34ea85f5238d2076c1d97dd1b5.

  Date: 2026-07-15 07:39:30 +0000

  Build fix (https://redirect.github.com/duckdb/duckdb/pull/23814)

  Unflavored-from: b5f776481ec39f3717a64a1d3fc7981f99fac2bf

- Update vendored sources to duckdb/duckdb@da3d58bbb1628e6e703106f2a0eb6d3910437951.

  Date: 2026-07-14 16:26:35 +0000

  Add external resource type registry + SQL level (and C++ level) `create_external_resource` (https://redirect.github.com/duckdb/duckdb/pull/23731)
  SQLLogic Tester: Add support for `init_sqllogic` / `cleanup_sqllogic` which allows for running sqllogictest statements before and after a test in test configs (https://redirect.github.com/duckdb/duckdb/pull/23807)

  Unflavored-from: 6617a093d6f093fdbb2c719d7c8cfb11b8a989dd

- Update vendored sources to duckdb/duckdb@aa5e982a47f029fa865b72282c1c6218e847e5fd.

  Date: 2026-07-14 13:42:26 +0000

  Add binom function (https://redirect.github.com/duckdb/duckdb/pull/23764)

  Unflavored-from: 42a50e58e0bfebb5015e144ec2b1b105299514ae

- Update vendored sources to duckdb/duckdb@4d66b224ad60a7bdc3fd1f380fa36ae869275f3c.

  Date: 2026-07-14 13:37:19 +0000

  Bugfix: ALTER TYPE rewrite could materialize stale values when another transaction pinned an older snapshot (https://redirect.github.com/duckdb/duckdb/pull/23791)
  Unflavored-from: 30b95bae857252553211165673b61752be3fb4f8

- Update vendored sources to duckdb/duckdb@7eaa6a2ffbc699ff366026860192c27895ff8861.

  Date: 2026-07-14 13:37:04 +0000

  Storage: validate dictionary string indexes (https://redirect.github.com/duckdb/duckdb/pull/23630)
  Unflavored-from: ef8cbb51b5cd37d0348c4b487bd3dc97b7d3466b

- Update vendored sources to duckdb/duckdb@ceb0ce270c0a27c35c32bc7b2409a99c99f03b1c.

  Date: 2026-07-14 13:00:46 +0000

  Fix IsComplete for Decimal (https://redirect.github.com/duckdb/duckdb/pull/23802)

  Unflavored-from: 5c8985b81da9ad938a4b84d4b44318c08017603b

- Update vendored sources to duckdb/duckdb@b1b9cf5405d69dadd580dcba4162089e76db58b3.

  Date: 2026-07-14 12:16:09 +0000

  Validity fixes for reading arrow into a dictionary vector (https://redirect.github.com/duckdb/duckdb/pull/23797)

  Unflavored-from: 1785c688873a423c960373730528d3a1f414b2d1

- Update vendored sources to duckdb/duckdb@d107e0cfd6832654075130e8c9dd8cb88a904fef.

  Date: 2026-07-14 11:55:31 +0000

  Accumulate probe match count thread-locally (https://redirect.github.com/duckdb/duckdb/pull/23771)

  Unflavored-from: 9290e16aac79c6ce6d947e7e1acfd01d90b44f31

- Update vendored sources to duckdb/duckdb@931f27e0559723f8a2eb92294fba75dae16a2cef.

  Date: 2026-07-14 11:46:16 +0000

  Bump azure, delta, unity_catalog extensions to main/HEAD (https://redirect.github.com/duckdb/duckdb/pull/23799)

  Unflavored-from: 379aa8f9be638221ed4edc3a54de05aecd745b51

- Update vendored sources to duckdb/duckdb@1f5faa492363371b47014fbe9821727335165650.

  Date: 2026-07-14 11:03:24 +0000

  fix: VARCHAR to DECIMAL scientific-notation rounding truncation (https://redirect.github.com/duckdb/duckdb/pull/23773)
  Unflavored-from: 8448cb8cc84fdbb3846f779f8417cd25ef0e5954

- Update vendored sources to duckdb/duckdb@5c9ccc28d3472bcfb64b9120ee3a1fa9df042dc8.

  Date: 2026-07-14 10:53:22 +0000

  Propagate stats for floating points for `abs` function (https://redirect.github.com/duckdb/duckdb/pull/23747)

  Unflavored-from: 7e9e9ecdc7d5d2758e9afd3e0fef4e0075cd99f2

- Update vendored sources to duckdb/duckdb@b884574a000ed7722c4e4c322c92b31eec4a5390.

  Date: 2026-07-14 10:52:18 +0000

  Fix/lambda interrupt check (https://redirect.github.com/duckdb/duckdb/pull/23706)

  Unflavored-from: 482b1d15798c0660ed6bd4fd4f7bd112beecd916

- Update vendored sources to duckdb/duckdb@a2306d682e413bb8c756652a4a8c3bda1d7a42f7.

  Date: 2026-07-14 10:46:08 +0000

  Fix external file cache crash on insertion (https://redirect.github.com/duckdb/duckdb/pull/23779)
  Fix CLI JSON rendering for nested VARIANT (https://redirect.github.com/duckdb/duckdb/pull/23765)

  Unflavored-from: 248463d2a2f12b5d3de55dd5f78370d41a4d4b12

- Update vendored sources to duckdb/duckdb@8a305666d11d9114bb2f2032c446c085b97e9510.

  Date: 2026-07-14 09:24:39 +0000

  Fix INTERNAL error casting pre-epoch TIMESTAMP_NS to TIME_NS (https://redirect.github.com/duckdb/duckdb/pull/23781)
  Fixup some bugs in recent dsdgen parallelization work (https://redirect.github.com/duckdb/duckdb/pull/23761)

  Unflavored-from: 91cdc62450f41445d0c29eecd8a0309ceb23a027

- Update vendored sources to duckdb/duckdb@2d37959922e5bbafc558dd84ef1bce08ffc73b31.

  Date: 2026-07-14 08:22:41 +0000

  Remove patches, bump postgres to include CONNECT fixes (redshift + DDL fixing return) (https://redirect.github.com/duckdb/duckdb/pull/23777)
  Avoid CI failing randomly depending on CI machine config (https://redirect.github.com/duckdb/duckdb/pull/23783)
  Propagate architecture flags to C dependencies when compiling with NATIVE_ARCH=1 (https://redirect.github.com/duckdb/duckdb/pull/23784)

  Unflavored-from: 65548aa6beec535896cfebb0edfebc65cd898b41

- Update vendored sources to duckdb/duckdb@71f0c7a0bf10f60087b7bd42f524ae556c5a1967.

  Date: 2026-07-13 10:24:22 +0000

  Convert TIMETZ to UTC on parquet write (https://redirect.github.com/duckdb/duckdb/pull/23767)

  Unflavored-from: 434bbdf18ce703be7a00cf40ed3cf80ae0a64f51

- Update vendored sources to duckdb/duckdb@2009475939c7b5ada2e55cc74843339bd9be79e3.

  Date: 2026-07-10 21:42:17 +0000

  Split up `LogicalSimple` into separate classes (https://redirect.github.com/duckdb/duckdb/pull/23756)

  Unflavored-from: 23d676d42433ee4b60e491bb09a93a585fb43748

- Update vendored sources to duckdb/duckdb@5fe0b50a22a7c36ddb36dcc71c3a9b8752c53981.

  Date: 2026-07-10 20:54:39 +0000

  Preserve verbatim ATTACH path via AttachedDatabase::GetOriginalPath() (https://redirect.github.com/duckdb/duckdb/pull/23759)
  Partial revert of https://redirect.github.com/duckdb/duckdb/pull/23649, this can still be triggered explicitly (https://redirect.github.com/duckdb/duckdb/pull/23755)

  Unflavored-from: 0fce671526e9c3ddff86d99093903a3e19579711

- Update vendored sources to duckdb/duckdb@2a69e7771733b9b42b931bd5dd459ce2c3f71ca6.

  Date: 2026-07-10 16:22:01 +0000

  Bump Iceberg (https://redirect.github.com/duckdb/duckdb/pull/23754)
  delta/uc ext: update ref, remove patches (https://redirect.github.com/duckdb/duckdb/pull/23711)

  Unflavored-from: a53e82bedded7641bf94b96a26b3496e54bf9b07

- Update vendored sources to duckdb/duckdb@86cc0b4b980afa845d6ad90910e0ee869e019509.

  Date: 2026-07-10 13:42:05 +0000

  Push down scalar functions to file readers (https://redirect.github.com/duckdb/duckdb/pull/23528)

  Unflavored-from: fefca15904ce88e070b618f03c79e4ae102b7d22

- Update vendored sources to duckdb/duckdb@d5f52d115738af6198d4ca6eddad5c4d293151ac.

  Date: 2026-07-10 13:35:38 +0000

  Implement stats propagation callback for `prefix` (https://redirect.github.com/duckdb/duckdb/pull/23749)

  Unflavored-from: 10c25916e814a2291d793a2ad68bdb7efb7c9d2b

- Update vendored sources to duckdb/duckdb@5e032a2b33449cad430d588bb743ea154b96e656.

  Date: 2026-07-10 12:52:41 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9890: ENUM::VARCHAR Compare Constant (https://redirect.github.com/duckdb/duckdb/pull/23751)

  Unflavored-from: 2d631f8954eb3a983ea3e3199f571bb3b3da6cbb

- Update vendored sources to duckdb/duckdb@6c0c1a68cd64d60202b438c125ad9d886e1e3ade.

  Date: 2026-07-10 08:24:05 +0000

  Make DataChunk::size() and optional_idx accessors inlineable (https://redirect.github.com/duckdb/duckdb/pull/23738)

  Unflavored-from: 5e81a415a0c093561cfa6f894d6712bf27183ef3

- Update vendored sources to duckdb/duckdb@3ea25ffc3ca8e3d3d5f0c2eb177f3d5038ad04dc.

  Date: 2026-07-09 22:23:40 +0000

  Fix BETWEEN (https://redirect.github.com/duckdb/duckdb/pull/23699)

  Unflavored-from: 6cf08bb1f79462ccf342047c0abbce4162ef63f0

- Update vendored sources to duckdb/duckdb@f6fe71497b47ec0bf06b9c40d34e8470c354541c.

  Date: 2026-07-09 14:57:51 +0000

  Move type pushdown after filter pushdown, don't push it filter is present (https://redirect.github.com/duckdb/duckdb/pull/23734)

  Unflavored-from: 4e9f2163f905cee41ee03a813cefd32878d3a6e0

- Update vendored sources to duckdb/duckdb@c523bc547f590dc03526d9d5262e289f64aa5c60.

  Date: 2026-07-09 14:44:24 +0000

  Collect exact rowgroup stats when possible (https://redirect.github.com/duckdb/duckdb/pull/23557)

  Unflavored-from: 5382ff36e95aad5cb1b0c5c40ce4f8fc2deecb4a

- Update vendored sources to duckdb/duckdb@c5481653bb6edc5b24b6dc94d3dcdeeb567034b3.

  Date: 2026-07-09 13:07:41 +0000

  \[Async I/O\] Read Ahead Interface + Parquet (https://redirect.github.com/duckdb/duckdb/pull/23662)
  APPLY_PATCHES back in mysql_scanner, postgres_scanner, sqlite_scanner and sqlsmith (https://redirect.github.com/duckdb/duckdb/pull/23717)

  Unflavored-from: 23c79d0bf060afec9398174fbdc4b904ac8c243f

- Update vendored sources to duckdb/duckdb@985b2f2515adf44ea65dd4239c7bfb30981b94dc.

  Date: 2026-07-08 13:48:25 +0000

  Round decimal strings consistently when casting VARCHAR to BIGNUM (https://redirect.github.com/duckdb/duckdb/pull/23689)
  Improve TPC-DS dsdgen progress reporting and generation performance (https://redirect.github.com/duckdb/duckdb/pull/23696)

  Unflavored-from: c1e78c874255c81c9370deb3250166753e52754e

- Update vendored sources to duckdb/duckdb@4c4243e09cac76267267adc1fb667a67b311590e.

  Date: 2026-07-08 12:10:49 +0000

  Cleanup include graph (https://redirect.github.com/duckdb/duckdb/pull/23579)

  R-side fix

- Update vendored sources to duckdb/duckdb@b3b5144b551743b36021ddf66d28f8f3f8214f61.

  Date: 2026-07-08 11:26:37 +0000

  Storage: reject invalid DICT_FSST symbol tables (https://redirect.github.com/duckdb/duckdb/pull/23627)
  Unflavored-from: da627f29cff022a5d07ff144d9a11e66e1b7fd27

- Update vendored sources to duckdb/duckdb@9544a2aa7d251a9ae4c57ace6c5bfedb654b6abe.

  Date: 2026-07-08 09:37:34 +0000

  Fix duplicate MAP entries (https://redirect.github.com/duckdb/duckdb/pull/23695)
  Add `.manual` to shell (https://redirect.github.com/duckdb/duckdb/pull/23636)

  Unflavored-from: a9d6389142d71b270efc4fb3cda0e5e71c720f3b

- Update vendored sources to duckdb/duckdb@d5a681ff2dd3035012551d1965bd3052d0c75f52.

  Date: 2026-07-08 08:55:48 +0000

  Skip compression detection when specified (https://redirect.github.com/duckdb/duckdb/pull/23612)

  Unflavored-from: 483628af916ee4f9998be54214335b0a2f46fba0

- Update vendored sources to duckdb/duckdb@976bcd29b7fa08c1326008a2ad67dfb760e01941.

  Date: 2026-07-08 08:42:36 +0000

  Task executor use notification to block wait completion (https://redirect.github.com/duckdb/duckdb/pull/23690)

  Unflavored-from: 2ce5dfd7e46813066622b7227229e4b4f7299180

- Update vendored sources to duckdb/duckdb@f03ad6c066a5d230f6d0d8c76e1d19edcd797c26.

  Date: 2026-07-08 08:34:13 +0000

  Check staged extensions in CI (https://redirect.github.com/duckdb/duckdb/pull/23671)

  Unflavored-from: 97ed7467fe5995fad985105d0720b38c82bf992a

- Update vendored sources to duckdb/duckdb@ba0b3490c09dc00e99b15bc0bcc978dce7a9db45.

  Date: 2026-07-08 08:33:33 +0000

  Fix TRY_CAST throw exception for floating point (https://redirect.github.com/duckdb/duckdb/pull/23684)

  Unflavored-from: 314d4385d3e1aaf1a3d0d01108a35821e2e8db57

- Update vendored sources to duckdb/duckdb@17f347db2cb77f504b4228b7ecc1232b0eeac389.

  Date: 2026-07-08 08:33:16 +0000

  Fix TRY_CAST throw exception for interval type (https://redirect.github.com/duckdb/duckdb/pull/23682)

  Unflavored-from: 74ccdd9dbf056019487ab99686615846083a02b4

- Update vendored sources to duckdb/duckdb@447e0be35f8e9520a1af903eb4ccccb96d2127e9.

  Date: 2026-07-08 08:32:50 +0000

  Add `make parser-grammar` and check for diff in CI (https://redirect.github.com/duckdb/duckdb/pull/23666)
  fix hanging test runner (https://redirect.github.com/duckdb/duckdb/pull/23673)

  Unflavored-from: 908789a14852bf49ad0953fe8587b44a665fc83e

- Update vendored sources to duckdb/duckdb@b319eef5ae2dcf37c396d394c131a783f0761857.

  Date: 2026-07-08 07:28:03 +0000

  Fix ROW_NUMBER() OVER () over read_duckdb returning file-local row numbers (https://redirect.github.com/duckdb/duckdb/pull/23667)
  unittest: support harnessed (unit)test: add controls for TEMP_DIR (and related) (https://redirect.github.com/duckdb/duckdb/pull/23574)

  Unflavored-from: 5f5c960dc2e616ca76e2fce52b581464ba93eedd

- Update vendored sources to duckdb/duckdb@a1aacc73df5da3c856da77163da6073dbf24a14c.

  Date: 2026-07-07 14:54:35 +0000

  Improve TPC-H dbgen progress reporting, ETA stability, and generation performance (https://redirect.github.com/duckdb/duckdb/pull/23665)

  Unflavored-from: b479c8a70e96e90a6e3236c328fc4fec0fc1abb2

- Update vendored sources to duckdb/duckdb@792f4e60e5b73db15d5cf1b6c69ba00ecc8a6e4c.

  Date: 2026-07-07 14:29:34 +0000

  Prefetch DuckDB header on attach to cut redundant reads (https://redirect.github.com/duckdb/duckdb/pull/23613)

  Unflavored-from: ab25e3384df2cdd6e9dc2be8d13285ff5b06e1ff

- Update vendored sources to duckdb/duckdb@0e78670c9d3c168089a08b96dd77514b1b02965e.

  Date: 2026-07-07 12:29:21 +0000

  Monotone preimage (https://redirect.github.com/duckdb/duckdb/pull/23610)

  Unflavored-from: 8474649b05a1066da8a613862e5ce61df2bc9cf2

- Update vendored sources to duckdb/duckdb@122a66431d117a4859d69033c8b7c343993f1a8f.

  Date: 2026-07-07 11:16:41 +0000

  Implement unary minus rule (https://redirect.github.com/duckdb/duckdb/pull/23608)

  Unflavored-from: 0e04bad9518c1313b3d82242e40415917b0c9145

- Update vendored sources to duckdb/duckdb@7f9261aa6ab60f41a1649cf0385f5976aee06b22.

  Date: 2026-07-07 11:02:05 +0000

  Monotone stats pruning (https://redirect.github.com/duckdb/duckdb/pull/23609)

  Unflavored-from: 022cc94d1b40dab9b8ccc83465f8d74053bef14a

- Update vendored sources to duckdb/duckdb@23717c6d33806054346beeed0629178772027843.

  Date: 2026-07-07 10:50:02 +0000

  Propagate stats for least/greatest (https://redirect.github.com/duckdb/duckdb/pull/23618)

  Unflavored-from: 95d5123543a6a00d32055a4be62e48b19db4ece6

- Update vendored sources to duckdb/duckdb@6a13a469a201c8e66b52b7510aaa6cd19445cfe3.

  Date: 2026-07-07 10:41:57 +0000

  Convert left function to prefix comparison (https://redirect.github.com/duckdb/duckdb/pull/23624)

  Unflavored-from: 305ff1c67ef8b158a3e8af4c9bcc56a930c16d53

- Update vendored sources to duckdb/duckdb@ef1b2c03b014e98128b8bf1a8303278ec131eef8.

  Date: 2026-07-07 10:29:10 +0000

  Fix named window inheriting from an earlier window in the same WINDOW clause (https://redirect.github.com/duckdb/duckdb/pull/23569)

  Unflavored-from: a87885ec15380952a4f0c11db12db418e22b3265

- Update vendored sources to duckdb/duckdb@296c9727d89a916cc9b2495c767326fba0f1aece.

  Date: 2026-07-07 10:10:46 +0000

  Pushdown prefix query (https://redirect.github.com/duckdb/duckdb/pull/23604)

  Unflavored-from: 54a93042e3df297cb66911c233cf65398167705e

- Update vendored sources to duckdb/duckdb@dfb621a3f83a058c954857c0f1ea2eadda4cb140.

  Date: 2026-07-07 10:02:01 +0000

  Fix string length stats propagation (https://redirect.github.com/duckdb/duckdb/pull/23615)

  Unflavored-from: e7c74e0e31160e1c47721e58e39772f493f5c870

- Update vendored sources to duckdb/duckdb@c6fe8fcc62dc3b847e53fa34a03e498b29e87b71.

  Date: 2026-07-07 09:59:01 +0000

  fix negative count over reversed window frames (https://redirect.github.com/duckdb/duckdb/pull/23637)

  Unflavored-from: 32ff3ecdf81554459ba7ce09a2f4c61107ce30ce

- Update vendored sources to duckdb/duckdb@8fe2a9bf21fcb3b8e466bad181bf234fcc59bc39.

  Date: 2026-07-07 09:16:07 +0000

  Introduce debug filesystem (https://redirect.github.com/duckdb/duckdb/pull/23473)

  Unflavored-from: 7707dde82043d7af68644eba0d964b346d4a2dd6

- Update vendored sources to duckdb/duckdb@c9df4bdedcd3d4cd505d5c73f586e1838ba7d7bc.

  Date: 2026-07-07 08:39:55 +0000

  Fix missing traversal for (correlated) subqueries in non-inner join conditions (https://redirect.github.com/duckdb/duckdb/pull/23599)

  Unflavored-from: 1bf353d52d406b5b2ea0f39a2b6e347e2ed56b33

- Update vendored sources to duckdb/duckdb@fc2148bb2c38f1f3ffe0005008b20def6010c73f.

  Date: 2026-07-07 08:36:37 +0000

  Packrat parsing (https://redirect.github.com/duckdb/duckdb/pull/23646)

  Unflavored-from: aaa7f6db762739bac6f714652e548dd799a4fac1

- Update vendored sources to duckdb/duckdb@fd418d309f904147686de3d4894c6a24cf2e13fe.

  Date: 2026-07-07 08:35:25 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/23640: Window Value EXCLUDE (https://redirect.github.com/duckdb/duckdb/pull/23650)

  Unflavored-from: 92df8d1ddef4610dcda82e52e7c194ca68d4ff96

- Update vendored sources to duckdb/duckdb@1202b06ac30fb846de29d0a93e0fb1fddd8e0c06.

  Date: 2026-07-07 08:35:04 +0000

  Revive https://redirect.github.com/duckdb/duckdb/pull/23561 (https://redirect.github.com/duckdb/duckdb/pull/23657)
  Create alpha releases on main CI run (https://redirect.github.com/duckdb/duckdb/pull/23649)
  Use all hardware threads during benchmarks (https://redirect.github.com/duckdb/duckdb/pull/23643)

  Unflavored-from: 573ffb988711949ff6bbc62ae041970bd0136f7e

- Update vendored sources to duckdb/duckdb@c40da9ff39c905e55f1b450ae130b704bc689d0d.

  Date: 2026-07-06 19:18:19 +0000

  Fix check in clustered aggregation (https://redirect.github.com/duckdb/duckdb/pull/23647)

  Unflavored-from: 9cf31455d7840bedf6dadbcc90ad611df187ab7d

- Update vendored sources to duckdb/duckdb@aee41bf43803d4a13efd9a865b648ca7a566f4dd.

  Date: 2026-07-06 14:54:55 +0000

  Heap-based transformer (Trampoline) script (https://redirect.github.com/duckdb/duckdb/pull/23578)

  Unflavored-from: 3fd4283780dfc37c97de0de58f073972f59ad72a

- Update vendored sources to duckdb/duckdb@ed1dc328d27a1eff5d96ede0dfc1d2fdc29c6067.

  Date: 2026-07-06 14:47:17 +0000

  Fix regressions caused by Expression Table Filter Rework (https://redirect.github.com/duckdb/duckdb/pull/23642)

  Unflavored-from: fc87abcbdc9c8db04380c6a807576e8768c9b92c

- Update vendored sources to duckdb/duckdb@36c64ee8b5a9c96276efa983eff6b41a7cc63102.

  Date: 2026-07-06 14:40:39 +0000

  Fix TRY_CAST to BIGNUM for invalid strings (https://redirect.github.com/duckdb/duckdb/pull/22450)

  Unflavored-from: 4a1ee5a0f4cc3a0343cc8eecbc888fd16c07458e

- Update vendored sources to duckdb/duckdb@3d93cff2d3d97723881cebf3040d4dedbaf8dcd0.

  Date: 2026-07-06 14:28:20 +0000

  Allow `UNNEST` in `GROUP BY` (https://redirect.github.com/duckdb/duckdb/pull/23644)
  Detect regressions in PRs using larger TPC-H and TPC-DS benchmarks (https://redirect.github.com/duckdb/duckdb/pull/23638)
  Address test warning (https://redirect.github.com/duckdb/duckdb/pull/23620)

  Unflavored-from: 2d43604810817072aac869d734bda8dc032141d9

- Update vendored sources to duckdb/duckdb@f7436f51dfb00b9d83e4abc3f0e48f1d7b992d8b.

  Date: 2026-07-06 11:16:41 +0000

  Bump Postgres, MySQL and SQLite (https://redirect.github.com/duckdb/duckdb/pull/23621)

  Unflavored-from: b5e6af3393a7348e7225fd1dac580f1befd0c58e

- Update vendored sources to duckdb/duckdb@63d055be5cf40e6c035ea00071fc6ad0584504e7.

  Date: 2026-07-06 11:16:16 +0000

  Fix row group pruning based on rowid filters (https://redirect.github.com/duckdb/duckdb/pull/23628)
  unittest: emit event w/ stats for harnesses (pytest) (https://redirect.github.com/duckdb/duckdb/pull/23572)

  Unflavored-from: c568ad7593be83595a47505caa4c513fecafb11b

- Update vendored sources to duckdb/duckdb@c8f10d010a0b385d17c93f47f706f779f9fa09ec.

  Date: 2026-07-06 10:54:28 +0000

  Fix stats collection for dictionary encoding (https://redirect.github.com/duckdb/duckdb/pull/23634)
  bump sqlsmith (https://redirect.github.com/duckdb/duckdb/pull/23632)
  Disable function coverage in report to remove 5k HTML pages (https://redirect.github.com/duckdb/duckdb/pull/23600)
  Add parquet as ducklake dep (https://redirect.github.com/duckdb/duckdb/pull/23598)

  Unflavored-from: 593ff96c6922f6c7faa0956c956302f488029559

- Update vendored sources to duckdb/duckdb@3a3c412af5b55b6d4e33686732a8110b9bf03542.

  Date: 2026-07-03 13:12:09 +0000

  Configurable approximate join order threshold (https://redirect.github.com/duckdb/duckdb/pull/23530)
  Add regression test for foreign key violation message (https://redirect.github.com/duckdb/duckdb/pull/23584)

  Unflavored-from: d51bcb0c02dc857220524522d8ab0a3b46197540

- Update vendored sources to duckdb/duckdb@aac31c21646666263580f1ee90fa0ee1a8e614a0.

  Date: 2026-07-03 13:00:14 +0000

  Make `chains_longer_than_one` in `JoinHashTable` an `atomic` (https://redirect.github.com/duckdb/duckdb/pull/23597)

  Unflavored-from: d21528665a11ad0ebce50300a4486924180c124e

- Update vendored sources to duckdb/duckdb@6c08fd7693b338b1be5049cdf2f70ff7a278487f.

  Date: 2026-07-03 12:23:25 +0000

  Fix ART iterator crash on empty table close range scan (https://redirect.github.com/duckdb/duckdb/pull/23064) (https://redirect.github.com/duckdb/duckdb/pull/23573)

  Unflavored-from: 9b8d1c2d61f30d36fbbfb087bc6670481e8f4e11

- Update vendored sources to duckdb/duckdb@c01dc9373b9468797d83d73439a5b397397c7ba0.

  Date: 2026-07-03 11:26:55 +0000

  Propagate client context for stats fetch (https://redirect.github.com/duckdb/duckdb/pull/23582)

  Unflavored-from: 34d3c7130cfd1d7c1f28edf0e29c7dcbb9e9b938

- Update vendored sources to duckdb/duckdb@2a58fdcd17366bb1ad29f255ede3bce3065193ca.

  Date: 2026-07-03 11:22:08 +0000

  Improve connect integration (https://redirect.github.com/duckdb/duckdb/pull/23576)

  Unflavored-from: 7e4bc7c8ccedd688c62ac409e59db514744fe820

- Update vendored sources to duckdb/duckdb@ac62d7c180c6bec21d65befb4919ad2c7b955cda.

  Date: 2026-07-03 06:55:33 +0000

  Optimizer: use UTF-8 successor for LIKE prefix pushdown (https://redirect.github.com/duckdb/duckdb/pull/23559)
  Unflavored-from: 7b15a8dcd202032a2e54d19f9e0d83069b06035b

- Update vendored sources to duckdb/duckdb@74f2d7e0fddb8dac66a620fa97db60e644bec922.

  Date: 2026-07-03 06:53:43 +0000

  Implement `CONNECT '<uri>' [(OPTS...)]` as ephemeral attach (https://redirect.github.com/duckdb/duckdb/pull/23555)

  Unflavored-from: 5f68980acf787dcfc37d0bb7a709302cc20d9738

- Update vendored sources to duckdb/duckdb@a81547b43c56c671a7ad1a636f83886713efdd8a.

  Date: 2026-07-02 12:40:50 +0000

  \[MultiFileReader\] Add virtual `GetMetadata` function (https://redirect.github.com/duckdb/duckdb/pull/23571)

  Unflavored-from: d95eb5abd02ad1a056442ff7cd8093eb5927a9d1

- Update vendored sources to duckdb/duckdb@1da5b6c8cf6ce50ff8089aa59eb028bae8044f08.

  Date: 2026-07-02 07:57:38 +0000

  Add ClientContext::BindStatement (https://redirect.github.com/duckdb/duckdb/pull/23526)
  Codename 'Cyanoptera' (https://redirect.github.com/duckdb/duckdb/pull/23056)

  Unflavored-from: 71ee8738ae776869b215ce4fc1d52205cd8fad57

- Update vendored sources to duckdb/duckdb@f5befa6d2e71e48330a621f36ff1cf75f2dfc91c.

  Date: 2026-07-02 06:54:53 +0000

  Fix typo in UNNEST error message (https://redirect.github.com/duckdb/duckdb/pull/23532) "at lease" → "at least" (https://redirect.github.com/duckdb/duckdb/pull/23538)

  Unflavored-from: 7a8a90c6efcf235cc374c07ad58055135515bed1

- Update vendored sources to duckdb/duckdb@e2c3fdec113c8ca261463ad8046eab8bd8b93759.

  Date: 2026-07-02 06:09:50 +0000

  Don't allow empty identifiers (https://redirect.github.com/duckdb/duckdb/pull/23553)

  Landing v2 (finding 14): the engine refuses an empty identifier again, so `rapi_unregister_df()` leaves the empty name to it, as before position 340 (`src/register.cpp`).

  Unflavored-from: 87497b866c7fc142cee7821cc5d2b12b0ac88761

- Update vendored sources to duckdb/duckdb@d46fc2373c495eac7669d83c5a136f71ad7bd247.

  Date: 2026-07-02 06:08:30 +0000

  Bump aws to cloudformation_create_stack (https://redirect.github.com/duckdb/duckdb/pull/23558)

  Unflavored-from: 7d8eb4cb28a899356272bacda6e65e238e25fd34

- Update vendored sources to duckdb/duckdb@2bafa77b22ed8761d6461d60d920355935fa7ad7.

  Date: 2026-07-02 06:08:07 +0000

  Polish, no reference but ClientContext& (https://redirect.github.com/duckdb/duckdb/pull/23554)

  Unflavored-from: e5a6d56f4ebbf6e0649d51ec3aa19c6ed926dcab

- Update vendored sources to duckdb/duckdb@546f74fa597d444f7fc1f13b4baa3844fab1d16c.

  Date: 2026-07-02 06:06:56 +0000

  Fold empty list contains filters to EMPTY_RESULT (https://redirect.github.com/duckdb/duckdb/pull/23543)

  Unflavored-from: 44995433c213552f3ec9767c19ab598f72d3ee6a

- Update vendored sources to duckdb/duckdb@d51ae42235b5a68782154edd114755b341b505de.

  Date: 2026-07-02 06:06:08 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/18039: Nested Comparison Semantics (https://redirect.github.com/duckdb/duckdb/pull/23539)

  Unflavored-from: 1907e022ed9c9e4abbab8db0f1d24c643663262b

- Update vendored sources to duckdb/duckdb@d9a775e4c03b23ecb3784f879196aa81adf0ac1c.

  Date: 2026-07-01 17:29:19 +0000

  Dont special-case geometry stats pruning, pass child stats to filter callback (https://redirect.github.com/duckdb/duckdb/pull/23540)

  Unflavored-from: c90a75d0060e8f3db339464ccae9dfef9d7b81f6

- Update vendored sources to duckdb/duckdb@46a4e337b8496d1b01a32744f5bad9e6f59e4b74.

  Date: 2026-07-01 14:26:53 +0000

  Rewrite `LEFT` to `ANTI` if there is a `IS NULL` filter on the null-extended side (https://redirect.github.com/duckdb/duckdb/pull/23550)

  Unflavored-from: 213f487ca12c66d4f3b13dbee442444b740a5301

- Update vendored sources to duckdb/duckdb@939917fd390c52568c0bd50997e618affe9c295d.

  Date: 2026-07-01 13:59:53 +0000

  Add `FETCH FIRST/NEXT` syntax (https://redirect.github.com/duckdb/duckdb/pull/23533)

  Unflavored-from: f5f046ac3f4ca29a7e19081bc32421d13749777b

- Update vendored sources to duckdb/duckdb@0103fc59f2ba68dd46b4494ddaf40cdcc91db8fd.

  Date: 2026-07-01 13:58:56 +0000

  Add windows_undefs to a multi-file reader header (https://redirect.github.com/duckdb/duckdb/pull/23541)

  Unflavored-from: f522e7b4d90e4ebfb59ff65cbea60d9c5a2d07ca

- Update vendored sources to duckdb/duckdb@6159b2960e694d9bac1c14825fbeb0f041b9d65c.

  Date: 2026-07-01 13:57:44 +0000

  Rename columns to original names before passing to reader if they were aliased (https://redirect.github.com/duckdb/duckdb/pull/23548)

  Unflavored-from: 7864680ee789bc32ff9a72956ed986377c35fc1b

- Update vendored sources to duckdb/duckdb@50ca1c74dc753e41d6551d238a1f7accb307b102.

  Date: 2026-07-01 13:25:08 +0000

  Add helper iterators around SQLStatements (either from the parser or post pre-processing) (https://redirect.github.com/duckdb/duckdb/pull/23291)
  Address test warning (https://redirect.github.com/duckdb/duckdb/pull/23546)

  Unflavored-from: f0d891e4600d6b41d47a3d39ff07e49ae18285c0

- Update vendored sources to duckdb/duckdb@7cda6703b46c490f0b709283f0aac49964764d46.

  Date: 2026-07-01 12:15:51 +0000

  Don't push down CAST if there's a TRY_CAST (https://redirect.github.com/duckdb/duckdb/pull/23535)

  Unflavored-from: 399178018beb4490dfe1981aa372ddf31f9e9298

- Update vendored sources to duckdb/duckdb@3cb65aa794b4c985a98493f188fb58db79a370f8.

  Date: 2026-06-30 14:42:16 +0000

  Add ICU date_diff support for TIMESTAMPTZ_NS (https://redirect.github.com/duckdb/duckdb/pull/23302)

  Unflavored-from: 853e54e5b80b63e262ab772fda80a0ee8ee0742b

- Update vendored sources to duckdb/duckdb@cb5d12dbf2b6d8263fa1af45f3987befa8abbf8c.

  Date: 2026-06-30 12:21:38 +0000

  Fix FORCE INSTALL being ignored by new PEG parser (https://redirect.github.com/duckdb/duckdb/pull/23524)
  make unittest cli/config parsing lenient with lists (https://redirect.github.com/duckdb/duckdb/pull/23525)

  Unflavored-from: 870bc989bff1e5ec3437759fd0fbb65409508d48

- Update vendored sources to duckdb/duckdb@6b765a3891f664426b06229a56aa345283e17fa5.

  Date: 2026-06-30 12:11:29 +0000

  Allow more expressions in PositionExpression (https://redirect.github.com/duckdb/duckdb/pull/23523)

  Unflavored-from: 9ea16fdf8f273a947e7b79dbc976f24a0c860e79

- Update vendored sources to duckdb/duckdb@cc76d1dcdea770de7193b804cfb30c7f1158a6f4.

  Date: 2026-06-30 12:01:25 +0000

  Fuzzer pivot issue with `ConstructConstantFromExpression` (https://redirect.github.com/duckdb/duckdb/pull/23511)

  Unflavored-from: e4980b270c02326c575d1ea2e482039b87275d09

- Update vendored sources to duckdb/duckdb@c11b39376edff885d45b39c2a998e69c428f3843.

  Date: 2026-06-30 11:45:12 +0000

  Bump aws extension, remove deprecated function (https://redirect.github.com/duckdb/duckdb/pull/23503)

  Unflavored-from: e2c3f4292c264b098156a8f8af6f7d25230ff17f

- Update vendored sources to duckdb/duckdb@2daa4fc9a48c638d10dcc613b1ed15d56c66f5b0.

  Date: 2026-06-30 09:22:25 +0000

  Add eager aggregation to PartialAggregatePushdown (https://redirect.github.com/duckdb/duckdb/pull/23506)
  Upload codecov as github artifacts (https://redirect.github.com/duckdb/duckdb/pull/23509)

  R-side fix

- Update vendored sources to duckdb/duckdb@8172ed013a31a32aa27f54df2b9055aa78914031.

  Date: 2026-06-30 08:17:06 +0000

  bound multi-byte reads in UTF8ToCodepoint (https://redirect.github.com/duckdb/duckdb/pull/23459)

  Unflavored-from: 7447b386ff2342a65e96cf9321957427e66c24ea

- Update vendored sources to duckdb/duckdb@10d6a343137e396db3adf38a6dffa4ec56e3a73e.

  Date: 2026-06-30 06:02:02 +0000

  autocheckpoint error propagation (https://redirect.github.com/duckdb/duckdb/pull/23510)

  Unflavored-from: 5c1b5ce3cb63cbac9a498aa33c83caf1d361a669

- Update vendored sources to duckdb/duckdb@c6730abe654e5135c9e50bc9c26758f423c098f9.

  Date: 2026-06-29 13:55:54 +0000

  Add error handling around `export` option (https://redirect.github.com/duckdb/duckdb/pull/23508)

  Unflavored-from: fea7df1f3714943052aa23732c85c67e4c79cf62

- Update vendored sources to duckdb/duckdb@32ab69470ecb48486960082849ffd58bf701c779.

  Date: 2026-06-29 16:05:29 +0200

  Collect source-based code coverage for fast tests (https://redirect.github.com/duckdb/duckdb/pull/23486)

  Unflavored-from: 62f00741dcd834f1e6457728122a4d15f6db4bd4

- Update vendored sources to duckdb/duckdb@0f0cd4fb67f2d467773ce09a8212c44a63ca8f5e.

  Date: 2026-06-29 11:42:33 +0000

  Add `LogicalType::TUPLE` (https://redirect.github.com/duckdb/duckdb/pull/23465)

  R-side fix

- Update vendored sources to duckdb/duckdb@de1413abfb336ad60c65f7c746a4f55cbbf42e66.

  Date: 2026-06-29 11:36:27 +0000

  Httplib backport security issues (https://redirect.github.com/duckdb/duckdb/pull/23440)

  Unflavored-from: 79c1cece48a9bfaa16f9b5b313f6ac7bc34ba835

- Update vendored sources to duckdb/duckdb@b0944869b2a7fde8e43acf1ea002d55517dec70a.

  Date: 2026-06-29 11:17:10 +0000

  Fix test runner encoding problem and format julia code on main (https://redirect.github.com/duckdb/duckdb/pull/23505)

  Unflavored-from: 0d51193bbbd22b4fa464ff5bc71d23239effa7ca

- Update vendored sources to duckdb/duckdb@3c472fd5c6dd7fa730b26849f66b48d2f4a43b42.

  Date: 2026-06-29 10:54:03 +0000

  Make sure chunks are tightly packed when bypassing the sort (https://redirect.github.com/duckdb/duckdb/pull/23502)

  Unflavored-from: 6811aa18398744570d6b99dc1fa2f609245cdf68

- Update vendored sources to duckdb/duckdb@ea01d9ff8cbfd0cab2b95c2ca37330c0f7d5db09.

  Date: 2026-06-29 09:23:29 +0000

  Fix DISTINCT window aggregate ordering (https://redirect.github.com/duckdb/duckdb/pull/23491)

  Unflavored-from: 1431d99a87101f2e82a104da6873c41217a419b9

- Update vendored sources to duckdb/duckdb@9206a1d85bf111c1270fd9ceecf37dd502070a06.

  Date: 2026-06-29 09:17:39 +0000

  Allow non-"list" LIST child name in remap_struct (https://redirect.github.com/duckdb/duckdb/pull/23437)

  Unflavored-from: a81d96084205056ff261668d78235e8cb9df423d

- Update vendored sources to duckdb/duckdb@8f754e06709809425ed7a04a808ca21e0c0df14d.

  Date: 2026-06-29 08:40:17 +0000

  Improve cache memory estimation on filepath cache object (https://redirect.github.com/duckdb/duckdb/pull/23482)

  Unflavored-from: 1c3c04dcd0d57dbc384a170bb56946191d585014

- Update vendored sources to duckdb/duckdb@c6d95afc1fe3b7eeec1fb211ce260794264c24ae.

  Date: 2026-06-29 08:29:04 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9813: dtime_t Type Safety (https://redirect.github.com/duckdb/duckdb/pull/23493)

  R-side fix

- Update vendored sources to duckdb/duckdb@6a946ffa6f08344d5f2cb547ebb9f0460f3a4f32.

  Date: 2026-06-29 08:18:58 +0000

  Fix JSON COPY date/time formatting for nested values (https://redirect.github.com/duckdb/duckdb/pull/23329)

  Unflavored-from: dc25449b0c5094f40fff98a47ccbae8c5409e054

- Update vendored sources to duckdb/duckdb@51822788e2a6f13bf7fdee763290e4ea7fe1d0a5.

  Date: 2026-06-29 08:11:20 +0000

  Make LogicalGet SupportSerialization check more robust (https://redirect.github.com/duckdb/duckdb/pull/23476)

  Unflavored-from: 01cdcb1d90d4e9326d6af801032e1e9589f08695

- Update vendored sources to duckdb/duckdb@5e5e9c06c9425ef883db886b1f0568be9c206511.

  Date: 2026-06-29 07:47:46 +0000

  Query Profiler: Rework `FORMAT HTML` to an interactive display, and add `.web` and `FORMAT WEB` to automatically open in a web browser (https://redirect.github.com/duckdb/duckdb/pull/23494)

  R-side fix

- Update vendored sources to duckdb/duckdb@ce431923305bff838c951e324f694d56006a9fba.

  Date: 2026-06-28 19:36:37 +0000

  \[WIP\] Add support for dropping nested schemas (https://redirect.github.com/duckdb/duckdb/pull/23497)

  Unflavored-from: 29fb90c4ddacd3252932127f745bd135ad37757e

- Update vendored sources to duckdb/duckdb@29ec18cf005e4b60bd6a5f2ee5cec0a1d7bb4040.

  Date: 2026-06-28 14:31:14 +0000

  Fix time duration calculation (https://redirect.github.com/duckdb/duckdb/pull/23293)

  Unflavored-from: 8205ad671f22e6bbe8382ae77f74079cb379acc3

- Update vendored sources to duckdb/duckdb@12820f7fcf67818535af55f64a155cc8bc594db7.

  Date: 2026-06-28 12:47:40 +0000

  Generate WAL serialization code, instead of manually writing it (https://redirect.github.com/duckdb/duckdb/pull/23495)

  Unflavored-from: d285ab41c06a458bfaceb05ef2fd706e47885966

- Update vendored sources to duckdb/duckdb@47370ca84fca39c1920ca80f82e8750c5c1458fe.

  Date: 2026-06-28 09:33:11 +0000

  \[WIP\] Add support for creating nested schemas (https://redirect.github.com/duckdb/duckdb/pull/23492)

  Unflavored-from: c71e666de9100197d2a67b288e633c216cdca976

- Update vendored sources to duckdb/duckdb@958bef9a6b9cd1f29dd67679559608d23c20498d.

  Date: 2026-06-27 09:34:35 +0000

  Make `QualifiedName` immutable and instead override the entire qualified name when modified (https://redirect.github.com/duckdb/duckdb/pull/23490)

  Unflavored-from: 458896149ce6f20c8f1ead293ce33518c4079243

- Update vendored sources to duckdb/duckdb@8df6b97ee34a1d3bd222654f8c065cead59169a0.

  Date: 2026-06-27 09:32:25 +0000

  Rework `query_tree` profiler renderer - and add syntax highlighting to it in the CLI (https://redirect.github.com/duckdb/duckdb/pull/23475)

  R-side fix

- Update vendored sources to duckdb/duckdb@355ac86fd7c81114b8ed436f93ea50147dfca74c.

  Date: 2026-06-27 06:02:28 +0000

  Attached database invalidation scope (https://redirect.github.com/duckdb/duckdb/pull/23468)

  Unflavored-from: aa2829c8fc2a08feabdc9a6f8193f502923b6db5

- Update vendored sources to duckdb/duckdb@ef2e34b472086a27474e7598a1b62656d35a9ec0.

  Date: 2026-06-26 21:13:09 +0000

  Avoid using `INVALID_CATALOG` / `DEFAULT_SCHEMA` in identifiers in `QualifiedName` (https://redirect.github.com/duckdb/duckdb/pull/23488)

  Unflavored-from: 16c02d5dc9b0f7b602dc5cb66848a5a3e094cf53

- Update vendored sources to duckdb/duckdb@0ca254aa803e4c10067893505d292e105efca271.

  Date: 2026-06-26 19:37:31 +0000

  More `QualifiedName` clean-up, preserve `QualifiedName` as much as possible (https://redirect.github.com/duckdb/duckdb/pull/23487)

  Unflavored-from: 8fe8371a8561fb10b4e4f2be13de89e12ae44137

- Update vendored sources to duckdb/duckdb@e8dccfd50587137bffa0f0236709541776200782.

  Date: 2026-06-26 17:43:09 +0000

  Transformer trampoline skeleton (https://redirect.github.com/duckdb/duckdb/pull/23414)

  Unflavored-from: 32db54b91d4827a3717c5dec67186a9f3b979b89

- Update vendored sources to duckdb/duckdb@98b29def37963f684e37d85b9fc90139d9221c5b.

  Date: 2026-06-26 17:19:59 +0000

  Fix partial join filter pushdown through projections (https://redirect.github.com/duckdb/duckdb/pull/23484)

  Unflavored-from: d1ddfccf0140aea4526358b683e3571d0fa2c2d2

- Update vendored sources to duckdb/duckdb@6d4f532842315892660dda48f30abef8fcbbc718.

  Date: 2026-06-26 19:08:11 +0200

  Push `QualifiedName` into `EntryLookupInfo` in Catalog look-ups, and use QualifiedName directly in more places (https://redirect.github.com/duckdb/duckdb/pull/23478)

  R-side fix

- Update vendored sources to duckdb/duckdb@a0aec37cfa52f3df63d4804c6b43e07a6b8b5870.

  Date: 2026-06-26 14:05:35 +0000

  Optimize flat contiguous string appends to `ColumnDataCollection` (https://redirect.github.com/duckdb/duckdb/pull/23485)

  Unflavored-from: f63faaba017be8a555c8ca128d16124cec3ffac6

- Update vendored sources to duckdb/duckdb@e1cf6abc4df59dcc0a948a545b166baf63204663.

  Date: 2026-06-26 12:54:36 +0000

  Finalize hash groups early in `PartitionedCopy` (https://redirect.github.com/duckdb/duckdb/pull/23481)

  Unflavored-from: a00aaa7702b60f3e01936b9bd2db541c52a9edf4

- Update vendored sources to duckdb/duckdb@4f6deb492697802acb134cc9b7b9a9944dd47456.

  Date: 2026-06-26 11:26:48 +0000

  Push down type casts to file readers (https://redirect.github.com/duckdb/duckdb/pull/22788)

  Unflavored-from: cf611924515bd1d28057a6c6e0a1bae6cde08eef

- Update vendored sources to duckdb/duckdb@6667908af266f13589b4e0e8acfc612d98af5b62.

  Date: 2026-06-26 10:35:24 +0000

  \[ASYNC I/O\] Refactor Multifile Scan for Read Ahead (https://redirect.github.com/duckdb/duckdb/pull/23472)

  Unflavored-from: ddea9265b9169d56f64f9421bafb9a49fe955383

- Update vendored sources to duckdb/duckdb@cf25a9aec3c5cf8a462e26b08285cc33c418031c.

  Date: 2026-06-26 10:33:29 +0000

  Add I/O metrics test harness, and fix many places where the `QueryContext` was not passed in correctly (https://redirect.github.com/duckdb/duckdb/pull/23477)

  Unflavored-from: 576c1730c74c50f3ee5decb7e10e6226d08645df

- Update vendored sources to duckdb/duckdb@d9fdc2f20b12704a1bb9080045180fd9a6c9ddaa.

  Date: 2026-06-26 08:53:28 +0000

  Fix eviction node memleak when external file cache disabled (https://redirect.github.com/duckdb/duckdb/pull/23444)

  Unflavored-from: 0bc73fb59f6cb9bba33437664b2a8f031dd5a083

- Update vendored sources to duckdb/duckdb@38a6582f1ce9321244423008d4be14bbdb37ab87.

  Date: 2026-06-26 08:49:09 +0000

  More `QualifiedName`, and preserve qualified names as much as possible instead of going back to catalog/schema/name (https://redirect.github.com/duckdb/duckdb/pull/23474)

  Unflavored-from: 6762c6d31d0635f786dcc6eaf95926e323527809

- Update vendored sources to duckdb/duckdb@fd552a8c8724adfd91dcdb4d67cc4000294d5308.

  Date: 2026-06-26 07:06:48 +0000

  fix integer overflow when sizing the DELTA_BYTE_ARRAY length buffer (https://redirect.github.com/duckdb/duckdb/pull/23420)

  Unflavored-from: 0956f143c0af3ffacd6201bab34dbc965b084027

- Update vendored sources to duckdb/duckdb@226834707327348fb44edd0dffadcae6813a1dfa.

  Date: 2026-06-26 06:35:39 +0000

  Copy table_filters to LHS scan in late materialization (https://redirect.github.com/duckdb/duckdb/pull/23453)

  Unflavored-from: fb983124576cac48ef218f06a16c1ec365ae0cf7

- Update vendored sources to duckdb/duckdb@e5d22ec99733c9079abd665634fa4cfbd5af3cd5.

  Date: 2026-06-26 05:28:25 +0000

  Add a JSON API and use that instead of calling `yyjson` directly (https://redirect.github.com/duckdb/duckdb/pull/23466)

  Unflavored-from: 4762b69955f50c1ea6fe91e24fdbb99397ffc79f

- Update vendored sources to duckdb/duckdb@9099f17e0e6bb2bb289e9d284c5b2078f63dbe59.

  Date: 2026-06-26 05:28:16 +0000

  Move `BaseTableRef` to `QualifiedName` (https://redirect.github.com/duckdb/duckdb/pull/23471)

  Unflavored-from: 85c157ccef28bbda3f4e1f6ad89300d98ba0c513

- Update vendored sources to duckdb/duckdb@65d2610cf55a4cf87692ee69586923c84aa7fe15.

  Date: 2026-06-26 04:14:21 +0000

  Optimize single-key hash group partitioning performance (https://redirect.github.com/duckdb/duckdb/pull/23449)

  Unflavored-from: e151545d1466070bcbb6420b47e19bd2f4dd5d1d

- Update vendored sources to duckdb/duckdb@06eb6b6858c6d568f5fe62855f53c386f13c98c7.

  Date: 2026-06-25 21:02:44 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/23441: Distinct Self Join (https://redirect.github.com/duckdb/duckdb/pull/23446)

  Unflavored-from: d4ebde0e13638e28f70e18611b9a738ed6288499

- Update vendored sources to duckdb/duckdb@59fb348859f7ec756e6819c144ba5f33bb434af7.

  Date: 2026-06-25 19:49:52 +0000

  Make profiling printers pluggable through a `ProfilerExtension`, and use this in the CLI to add syntax highlighting to `EXPLAIN (ANALYZE)` output (https://redirect.github.com/duckdb/duckdb/pull/23470)

  R-side fix

- Update vendored sources to duckdb/duckdb@26a38d783b763ba39efeeaf9aa6660db3a91102c.

  Date: 2026-06-25 19:47:01 +0000

  Add `QualifiedName` usage to CreateInfo (https://redirect.github.com/duckdb/duckdb/pull/23467)

  Unflavored-from: 755b4b2a7b1d35ed008e8cd425fdfc9751d84b02

- Update vendored sources to duckdb/duckdb@4771f0227b32c7ec3b9cc61bdc400b5aca3851f4.

  Date: 2026-06-25 17:51:59 +0000

  fix: raise error on invalid `regexp_replace` replacement strings (https://redirect.github.com/duckdb/duckdb/pull/23422)
  Unflavored-from: 53e2659611932cae47d15c1310943b29049fe0f7

- Update vendored sources to duckdb/duckdb@acb131cf7d1becaaf35d5b7ae244aa4fc1cb49e5.

  Date: 2026-06-25 17:51:23 +0000

  Refactor Multi-File Scan for ASYNC I/O (https://redirect.github.com/duckdb/duckdb/pull/23419)

  Unflavored-from: 481c6c708f4146d516fd8f0bfbef1fc286101c66

- Update vendored sources to duckdb/duckdb@69496c8342353c6b57537b1b18799cd3cc236fa2.

  Date: 2026-06-25 16:44:51 +0000

  Add a fast path for reading all-NULL columns in Parquet (https://redirect.github.com/duckdb/duckdb/pull/23464)

  Unflavored-from: f5bb9f786f11c420753ca4544d6c4bc8eb39f41e

- Update vendored sources to duckdb/duckdb@b24a25ef5577a6482355773bb6c2542e321e82f8.

  Date: 2026-06-25 16:30:24 +0000

  Add `QualifiedName` usage to `DropInfo` / `AlterInfo` / `CopyInfo` (https://redirect.github.com/duckdb/duckdb/pull/23460)

  Unflavored-from: e0c55bb8fd5f8cf248042302d1e480b5bd6a65c5

- Update vendored sources to duckdb/duckdb@101806141ebb215eefee21bf32777dea005a9510.

  Date: 2026-06-25 15:23:44 +0000

  Implement cryptographic hash functions in `EncryptionUtil` (https://redirect.github.com/duckdb/duckdb/pull/23461)

  Unflavored-from: f22ebb848b208d0245787317a449e9f92dd01a58

- Update vendored sources to duckdb/duckdb@f9abb0f2d361915af60223ed3f937cc211a3bfcb.

  Date: 2026-06-25 14:18:40 +0000

  Make regex operators match PostgreSQL behaviour (https://redirect.github.com/duckdb/duckdb/pull/23432)

  Unflavored-from: c5e1ca5b09dc059b1c9a2ffa64ae79c2d3287852

- Update vendored sources to duckdb/duckdb@464b647e189de96096dc3afae1ed62c1224adc63.

  Date: 2026-06-25 13:52:03 +0000

  Emit shredded vectors from Parquet when reading variant columns (https://redirect.github.com/duckdb/duckdb/pull/23454)

  Unflavored-from: f00d1e6417eb2bc7939639ab2f03c4e8f4a2cb01

- Update vendored sources to duckdb/duckdb@aecf55d4c16c82b2c6ced435734132db789218ad.

  Date: 2026-06-25 13:05:39 +0000

  Preserve original chunk cardinality in TryProbeConstant (https://redirect.github.com/duckdb/duckdb/pull/23431)

  Unflavored-from: 482785d73f5834893990f33ea4ff2eade39cc1d6

- Update vendored sources to duckdb/duckdb@8205af4f4b112eeb195a89fd2a9f5e88bd940eed.

  Date: 2026-06-25 13:03:40 +0000

  Add `QualifiedName` usage to Function/Type/Window expression, and add hash / equality (https://redirect.github.com/duckdb/duckdb/pull/23455)

  Unflavored-from: 78ac8c5d328b1b79a676f58f3c4a361ced1b8067

- Update vendored sources to duckdb/duckdb@8f74bccd00ca9cc5b8257bff29942ed8f62e4ae4.

  Date: 2026-06-25 12:53:29 +0000

  Clear stale projection maps after CTE rewrite pass (https://redirect.github.com/duckdb/duckdb/pull/23456)

  Unflavored-from: 3a4a19e898955a99723fc5729f4aec10543e0160

- Update vendored sources to duckdb/duckdb@d73a0be615911dfb9e64ad94492786513aa52fe9.

  Date: 2026-06-25 11:54:51 +0000

  Add support for partial shredded stats emission for parquet variants (https://redirect.github.com/duckdb/duckdb/pull/23439)
  Sort unordered delete return IDs to stabilize test (https://redirect.github.com/duckdb/duckdb/pull/23450)
  Bump postgres_scanner, remove patches (https://redirect.github.com/duckdb/duckdb/pull/23451)

  Unflavored-from: 9e4634f32bd11618392c49ebe868d67ddeb8f707

- Update vendored sources to duckdb/duckdb@c028854da4348b4d32731e460b75973364f79b74.

  Date: 2026-06-25 10:15:20 +0000

  Support AFTER DELETE FOR EACH ROW triggers with OLD.col references (https://redirect.github.com/duckdb/duckdb/pull/23452)

  Unflavored-from: 698e2e5ec51522149c798c12b139c64bb055bc49

- Update vendored sources to duckdb/duckdb@8abfd3a6ea6658d7dabed08f3d4dc9aafe8f7740.

  Date: 2026-06-25 08:12:51 +0000

  Add dictionary-aware cache operator (https://redirect.github.com/duckdb/duckdb/pull/23447)

  Unflavored-from: f42a255e99771f255d706c1c8069dbb000519ea4

- Update vendored sources to duckdb/duckdb@584a1c96490c8fadc45d2be858c7d9705e069915.

  Date: 2026-06-25 06:52:24 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9375: TIME_BUCKET For TIME (https://redirect.github.com/duckdb/duckdb/pull/23411)

  Unflavored-from: cbc4cd92dbeef854397b1e750b446d85ec28a738

- Update vendored sources to duckdb/duckdb@0361de441a122f11fe07c40ce4531cd58f5eaf7a.

  Date: 2026-06-24 10:52:33 +0000

  fix out-of-bounds read in substring with negative offset (https://redirect.github.com/duckdb/duckdb/pull/23429)

  Unflavored-from: 90f882d9bc76fe5d6a797c430a77919bf59b6531

- Update vendored sources to duckdb/duckdb@2585b5e90fecabbcd7cc95e9bd0088dfd212cd5f.

  Date: 2026-06-24 10:38:31 +0000

  Fix type inconsistency for thread count variables (https://redirect.github.com/duckdb/duckdb/pull/23438)

  Unflavored-from: 339f9889c50754203ec2afc8ad7ffe368b150ec0

- Update vendored sources to duckdb/duckdb@59d4b6c678b51b6d79fbe9c60d1db24f70129a8a.

  Date: 2026-06-24 10:24:51 +0000

  Test and fix single-thread async draining (https://redirect.github.com/duckdb/duckdb/pull/23436)

  Unflavored-from: b23731b868b9870b9a2cef8dde4e123a76bb5623

- Update vendored sources to duckdb/duckdb@3518c60315dfa631c97280603af3f9b9b8f09f77.

  Date: 2026-06-24 09:01:45 +0000

  fix: skip deduplication for volatile aggregates and window expressions (https://redirect.github.com/duckdb/duckdb/pull/23413)
  Unflavored-from: deba3d58f3388cdda81f00a15bb202a4435fa600

- Update vendored sources to duckdb/duckdb@b980d824d1eb91d10452ef64731ea29782ee32fa.

  Date: 2026-06-24 08:21:08 +0000

  Clean async tasks after schedule (https://redirect.github.com/duckdb/duckdb/pull/23410)

  Unflavored-from: 28daf5299732fe78682fb48060f3ffcc5f0193b7

- Update vendored sources to duckdb/duckdb@4a2bfe526627bf4d6f9a1a23138bd00671c3e6f8.

  Date: 2026-06-24 08:07:51 +0000

  Skip caching when no version metadata available (https://redirect.github.com/duckdb/duckdb/pull/23427)

  Unflavored-from: dad20228d40e61b0eef696d08546033b95d4df30

- Update vendored sources to duckdb/duckdb@eaa1f4222fd6b3dba94bf639c1c5eaa328acfb01.

  Date: 2026-06-24 08:05:52 +0000

  Fix stale projection maps in ProjectionPullup (https://redirect.github.com/duckdb/duckdb/pull/23424)

  Unflavored-from: d587549a84607971d451bee33831561a83cfea61

- Update vendored sources to duckdb/duckdb@3c5da8274896a38cb53128bf45627684a577356a.

  Date: 2026-06-24 07:29:02 +0000

  check for interrupt state in ExecuteTaskInternal (https://redirect.github.com/duckdb/duckdb/pull/23379)

  Unflavored-from: f8d52f7d6f605d6d59a7593d4dd68605d7ba054e

- Update vendored sources to duckdb/duckdb@53b829b8f0ea2bce3e874769d181f665d2dbf412.

  Date: 2026-06-24 07:28:32 +0000

  Add managed async task queue (https://redirect.github.com/duckdb/duckdb/pull/23404)

  Unflavored-from: 16f87ee54f948e75e0e82bc74eaf33408b2593f1

- Update vendored sources to duckdb/duckdb@ab0bbae99a355c7b1ffc7594155eefbb7fde3aa9.

  Date: 2026-06-24 07:21:05 +0000

  Fix client ctx ref cycle (https://redirect.github.com/duckdb/duckdb/pull/23372)
  Use github script to add member label and move PR to draft (https://redirect.github.com/duckdb/duckdb/pull/23417)

  Unflavored-from: 88af7c1ba37b66d87bc96d8fdb5f5be8d4960783

- Update vendored sources to duckdb/duckdb@27a0d53c91fae8bbc9286c232441a3eb366ad1da.

  Date: 2026-06-24 06:08:02 +0000

  Fix connection_id regression in EndQueryInternal logging (https://redirect.github.com/duckdb/duckdb/pull/21884)

  Unflavored-from: d7b3b744cd1c31175335e5d6fef40281ecebebdc

- Update vendored sources to duckdb/duckdb@e884eef8ddaa9434dc33715b1aaa7fec29f8eb4b.

  Date: 2026-06-23 13:08:41 +0000

  `PhysicalCopyToFile` async fixes and improvements (https://redirect.github.com/duckdb/duckdb/pull/23418)

  Unflavored-from: 2d0693d6ad265012f19711b973c6d62d214d24e2

- Update vendored sources to duckdb/duckdb@da40609cca538f0bb25864854c89e5c0cf38247c.

  Date: 2026-06-23 12:14:42 +0000

  Feature/ilike constant pattern fastpath (https://redirect.github.com/duckdb/duckdb/pull/23406)

  Unflavored-from: 9bceeaa2bdcb46099341a39f2459ab2a52ca6473

- Update vendored sources to duckdb/duckdb@3a0e82f9129d0bf9dc0999e5c29ab5e5366412e2.

  Date: 2026-06-23 10:39:47 +0000

  Infer geometry type based on WKB string stats (https://redirect.github.com/duckdb/duckdb/pull/23394)

  Unflavored-from: c14d662985de18f56f8d93516024ead4ed32019f

- Update vendored sources to duckdb/duckdb@7e582917177dcb12221061a00b621c2910388bee.

  Date: 2026-06-23 08:12:47 +0000

  Add dictionary surviving hash join (https://redirect.github.com/duckdb/duckdb/pull/23360)

  Unflavored-from: 45698d7ccae30e9d62dd60416843f8e95d5d1313

- Update vendored sources to duckdb/duckdb@0fa37b4a4c485eb79e5a3f7374704be347a7344b.

  Date: 2026-06-23 07:48:41 +0000

  Rework parquet variant reading to use `ParquetVariantIterator` and remove `VariantValue` class (https://redirect.github.com/duckdb/duckdb/pull/23399)

  Unflavored-from: c53d819e740091381849a44dafc6d88bd4ed05e0

- Update vendored sources to duckdb/duckdb@e5901e0bba1d4214e932b99f188d710d16401d80.

  Date: 2026-06-23 06:54:54 +0000

  Merge `v1.5-variegata` into main (https://redirect.github.com/duckdb/duckdb/pull/23403)

  Unflavored-from: 7db161b5b75ed2a72485452b777ef60764be1c21

- Update vendored sources to duckdb/duckdb@ababb622f71f2ed49ff891fe3332bcd2679980a7.

  Date: 2026-06-22 13:34:26 +0000

  Add support for pushing collations into lists using `lambda_transform`, and add support for collations to `list_contains / list_position` (https://redirect.github.com/duckdb/duckdb/pull/23400)
  Replace slow 'dd bs=1' calls and verify extensions concurrently (https://redirect.github.com/duckdb/duckdb/pull/23402)
  Enable parser tools (bison) for musl main extensions (https://redirect.github.com/duckdb/duckdb/pull/23401)

  Unflavored-from: 40788f6ba929bc8701f1e5ef4268bc7fbaf7436c

- Update vendored sources to duckdb/duckdb@16a5aec84d49715a946fe2c8bbd779ac11ca07d7.

  Date: 2026-06-22 08:48:59 +0000

  Add support for compressed materialization for geometry points (https://redirect.github.com/duckdb/duckdb/pull/23393)

  Unflavored-from: 81a582edd3cce1a14938c3e24c765a0128ca147c

- Update vendored sources to duckdb/duckdb@bb6a0e9fa152712a452da28d8db6fb6e9ec1127f.

  Date: 2026-06-22 08:46:24 +0000

  Fix metadata reader offset advancement (https://redirect.github.com/duckdb/duckdb/pull/23392)
  Add Parquet variant of JSONBench (https://redirect.github.com/duckdb/duckdb/pull/23397)

  Unflavored-from: 4a45a750819c5cf4252634ea71a3c4a4917efa08

- Update vendored sources to duckdb/duckdb@05c4d1cf87a4e8da0863941084c3f7130c46dd8d.

  Date: 2026-06-22 07:36:25 +0000

  Fix sleep overflow (https://redirect.github.com/duckdb/duckdb/pull/23395)
  CLI: mode .trash should not force result materialization (https://redirect.github.com/duckdb/duckdb/pull/23377)

  Unflavored-from: 7bf59374e0a14ba0eae2644291291a06e453885c

- Update vendored sources to duckdb/duckdb@10d022e84e8c799e009b0e8603d77f9ee74241fe.

  Date: 2026-06-20 09:06:42 +0000

  Allow triggering internal join types (https://redirect.github.com/duckdb/duckdb/pull/23339)
  Clean up examples folder (https://redirect.github.com/duckdb/duckdb/pull/23378)

  Unflavored-from: 88a55a7f532bc0df49267e9c0bbe3a114e96e3e7

- Update vendored sources to duckdb/duckdb@22b2fa962182659793f9544806ea551995f67461.

  Date: 2026-06-20 08:56:31 +0000

  Add support for state export to ordered aggregates (https://redirect.github.com/duckdb/duckdb/pull/23376)
  \[SqllogicTester\] Add `--stdin` option to read statements from stdin (https://redirect.github.com/duckdb/duckdb/pull/23381)

  Unflavored-from: 48efccdc6178844dea6b8cc79700a67623c7067d

- Update vendored sources to duckdb/duckdb@4733afd5817342faf7ae339cfc4910520b72d86d.

  Date: 2026-06-19 20:03:02 +0000

  Make list aggregate append work on batches of rows instead of per rows and implement cluster update function (https://redirect.github.com/duckdb/duckdb/pull/23380)

  Unflavored-from: b3725c0907656b04e629e9c69d0c3c0a0c334f84

- Update vendored sources to duckdb/duckdb@fc93963efdd884c575f02e1650ca76a3dfdd396e.

  Date: 2026-06-19 08:25:02 +0000

  In variant_extract correctly traverse child stats during stats propagation (https://redirect.github.com/duckdb/duckdb/pull/23361)

  Unflavored-from: 076ccc01ff06da58d5a3bdebab682fb17ff40983

- Update vendored sources to duckdb/duckdb@3a99aa241cf150ca69ec58e635cfe2a4839dce88.

  Date: 2026-06-19 08:24:57 +0000

  Use the new `VariantIterator` to unshred instead of first decomposing into `VariantValue` followed by re-constructing the variant (https://redirect.github.com/duckdb/duckdb/pull/23359)

  Unflavored-from: 39bb04f4d5b26152fcb598c1b4d3095f2738cba3

- Update vendored sources to duckdb/duckdb@2bfea2aa198bc1fcd4486707e7b8c1562aa6a67c.

  Date: 2026-06-18 15:05:33 +0000

  `CompressedMaterialization` and `JoinFilterPushdown` for `VARIANT` (https://redirect.github.com/duckdb/duckdb/pull/23356)

  Unflavored-from: 77eebfd6a424a2f743b729d921f3000391225bf0

- Update vendored sources to duckdb/duckdb@f8def180bf6c1384c34fae718c652635a9004534.

  Date: 2026-06-18 14:46:43 +0000

  Allow table functions to propagate the query return type (https://redirect.github.com/duckdb/duckdb/pull/23358)

  Unflavored-from: 7dfc9b9b4009e1b9bbd50c37d7ea09dbab97f314

- Update vendored sources to duckdb/duckdb@8beaa8ad0797a9e99a0e2091678b39d12965bb5b.

  Date: 2026-06-18 14:46:29 +0000

  Fix leak on pending query close (https://redirect.github.com/duckdb/duckdb/pull/23344)

  Unflavored-from: bc80e6050208fa141a0223a614383d5a0396e451

- Update vendored sources to duckdb/duckdb@f42b13c366e5fd2a109f481e773873dafac08c74.

  Date: 2026-06-18 13:37:19 +0000

  New `debug_local_file_system_delay_ms` setting and asynchronous file initialization/finalization (https://redirect.github.com/duckdb/duckdb/pull/23353)
  Quote special object keys in json_each/json_tree fullkey and path (https://redirect.github.com/duckdb/duckdb/pull/23206)

  Unflavored-from: 78de99a29267cf4e6a58cd5ec7ec4e9be5e3701f

- Update vendored sources to duckdb/duckdb@4f9669e21384ce81d73a4e57ff96fefcbfce2379.

  Date: 2026-06-18 12:20:57 +0000

  Remove `TransformEnum` (https://redirect.github.com/duckdb/duckdb/pull/23355)

  Unflavored-from: 5d70c6ff4cd0c4852db3b7e78c1d0317ed921fd6

- Update vendored sources to duckdb/duckdb@be9ed0575a259d2ab5f7ae24801560d98133e9d0.

  Date: 2026-06-18 12:06:09 +0000

  Nicer variable syntax (https://redirect.github.com/duckdb/duckdb/pull/21194)
  Support submodules in extensions patching process (https://redirect.github.com/duckdb/duckdb/pull/23191)

  Unflavored-from: 99cd85eaed1a8332fc70da88ebb1d34519e0e9dd

- Update vendored sources to duckdb/duckdb@17ba7dd2b6bd0f1212ab7da93b63726eb8ddaf8a.

  Date: 2026-06-18 10:33:12 +0000

  Deprecate Implicit Table-Function Identifier String Conversion (https://redirect.github.com/duckdb/duckdb/pull/23350)

  Unflavored-from: a75f2167be0606d9993d4773f946097ae1d01770

- Update vendored sources to duckdb/duckdb@738d229e6b4c4722083d18ddf7caede4a45a658e.

  Date: 2026-06-18 09:10:43 +0000

  Propagate stats in `structured type -> variant` casts (https://redirect.github.com/duckdb/duckdb/pull/23347)

  Unflavored-from: d7bf91d4ff862864b0c665566f3380074bcb31fc

- Update vendored sources to duckdb/duckdb@d364ca088905edacea4f245ae13b7f2a945990a8.

  Date: 2026-06-18 09:10:39 +0000

  Fix state export finalize with non-zero offset, and update list of skipped tests (https://redirect.github.com/duckdb/duckdb/pull/23349)

  Unflavored-from: 6e117a49a926db6b336b96b51b9644fc45fb78d1

- Update vendored sources to duckdb/duckdb@01d5f26a578aa1d5d657fe059a424e07fd203886.

  Date: 2026-06-18 07:42:05 +0000

  Add `shredded_vector` option to `debug_verify_vector` (https://redirect.github.com/duckdb/duckdb/pull/23343)

  Unflavored-from: 2d2cab7b506f85817b1b779b18df271e0630586f

- Update vendored sources to duckdb/duckdb@8b45c419195d23394f6929214c44c9bb2f7e1212.

  Date: 2026-06-18 07:42:00 +0000

  Support AFTER INSERT FOR EACH ROW triggers (https://redirect.github.com/duckdb/duckdb/pull/23284)

  Unflavored-from: 96cbdd6a3f078bce9260a78117d3b55b9576de6e

- Update vendored sources to duckdb/duckdb@f401652abf68009662f211c4351fadd5dbdc4b73.

  Date: 2026-06-18 07:30:28 +0000

  Clean-up VariantIterator API and unify it with vector iterator infrastructure (https://redirect.github.com/duckdb/duckdb/pull/23346)
  AGENTS.md: Drop in-process (https://redirect.github.com/duckdb/duckdb/pull/23345)

  Unflavored-from: dbce1e1ec30f7b3774af1b68e16bbff3242806e9

- Update vendored sources to duckdb/duckdb@801f7fa8190f38614bccd7e23b28fd739b0822b4.

  Date: 2026-06-17 19:59:51 +0000

  Propagate shredded stats through `variant_comparator` (https://redirect.github.com/duckdb/duckdb/pull/23336)

  Unflavored-from: 131b6ddc97c8aace602ad710dab06eed569983a9

- Update vendored sources to duckdb/duckdb@38e33b31957033aa18757eed407122bd6ac2c4ec.

  Date: 2026-06-17 17:40:51 +0000

  Fix uninitialized TransactionContext::invalidation_policy and auto_rollback members (https://redirect.github.com/duckdb/duckdb/pull/23321)

  Unflavored-from: e1fb13e4b76aca0bdcbf6adcbe7f4690a876d5c2

- Update vendored sources to duckdb/duckdb@1dd26e8959520c5dbae3ec54fe3d466446c29e43.

  Date: 2026-06-17 17:40:35 +0000

  Allow empty STRUCT types (https://redirect.github.com/duckdb/duckdb/pull/23273)

  R-side fix

- Update vendored sources to duckdb/duckdb@9ee1f9cfc6a20865371b7d5c2cd786808b9fcd34.

  Date: 2026-06-17 17:25:20 +0000

  Add invoke scalar function (https://redirect.github.com/duckdb/duckdb/pull/23185)

  Unflavored-from: ec14e03974287ca39f41b5347da1aee73a5e458a

- Update vendored sources to duckdb/duckdb@fe871ebf45d777c97950cfe3e07a1a77a45f1503.

  Date: 2026-06-17 14:02:20 +0000

  Step 6: Flip the switch and have delim join as CTEs by default (https://redirect.github.com/duckdb/duckdb/pull/23333)
  Report in check_peg_parser parse errors (https://redirect.github.com/duckdb/duckdb/pull/22975)

  Unflavored-from: f51cff3a7ca6d56a26f58c1d50eb21ac5b3686e1

- Update vendored sources to duckdb/duckdb@a3a69d2b9aec46b65e628e06e9ff486d9bb1b620.

  Date: 2026-06-17 13:17:59 +0000

  \[Parquet\] Fix corrupted file invalidating the database (https://redirect.github.com/duckdb/duckdb/pull/23331)

  Unflavored-from: fe0a95cdf45026371cff860db1309c2f3304f4e4

- Update vendored sources to duckdb/duckdb@6e8c465771a6a1c4be4d02f11d0a17a57df660e0.

  Date: 2026-06-17 12:02:09 +0000

  Use optional semantic values for generated transformer rules (https://redirect.github.com/duckdb/duckdb/pull/23332)

  Unflavored-from: b6c22dd2a0ed6d6c04664fc52650b3970fd0aa9c

- Update vendored sources to duckdb/duckdb@7ada856c4f5fcbedef0580dbc2bdc7027f6b053e.

  Date: 2026-06-17 12:01:34 +0000

  Handle exceptions thrown while recovering from a failed commit (https://redirect.github.com/duckdb/duckdb/pull/23298)
  CMake: Set the extension base directory to the duckdb module dir (https://redirect.github.com/duckdb/duckdb/pull/23328)

  Unflavored-from: e459d35ef6b6110a050b0ec710b8c3bc91fb0af2

- Update vendored sources to duckdb/duckdb@18b593788d6ebd548bcf55b18cc8f3e15d5fb4c3.

  Date: 2026-06-17 08:19:46 +0000

  Avoid unnecessary call to ToUnifiedFormat in ColumnSegment filter (https://redirect.github.com/duckdb/duckdb/pull/23324)

  Unflavored-from: d84f6131126f60d11eb3a16ef8cc5551c6fd90fa

- Update vendored sources to duckdb/duckdb@0829fb2304c8959a55c537ebd7302b737c18fa66.

  Date: 2026-06-17 07:41:30 +0000

  Add export/import callbacks for aggregates with non-standard state, and support `approx_top_k` / `approx_quantile` (https://redirect.github.com/duckdb/duckdb/pull/23304)

  Unflavored-from: 16affd6d75773087ff027667cc93afa3fca54fca

- Update vendored sources to duckdb/duckdb@9dff8aa0e15fb61b0185e78ab3573086cd531d60.

  Date: 2026-06-17 06:20:49 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9655: Test Vector DOUBLE\[3\] (https://redirect.github.com/duckdb/duckdb/pull/23320)

  Unflavored-from: 2ae5c687ff8f980f62e3a4770e0a4b6c3d1e114f

- Update vendored sources to duckdb/duckdb@6d8f71fefa350d469aefa062dd1638bcde0189ba.

  Date: 2026-06-16 19:24:54 +0000

  Remove specialized variant comparison code (https://redirect.github.com/duckdb/duckdb/pull/23319)

  Unflavored-from: d9b220dc1c7252bd2911a1eeb76d63b0cfcca335

- Update vendored sources to duckdb/duckdb@8f06e19fe778b522756af3b949bac16fa82748e6.

  Date: 2026-06-16 17:57:52 +0000

  Add `VariantIterator` which allows traversal of variant values without unshredding (https://redirect.github.com/duckdb/duckdb/pull/23317)

  Unflavored-from: 6ca0c83c90fa36a55ceb13042812afdee1ee466c

- Update vendored sources to duckdb/duckdb@4dd446c80526846ea7ce04a8b562368040e95d27.

  Date: 2026-06-16 16:20:03 +0000

  Auto generate transform `expression.gram` (Part 8) (https://redirect.github.com/duckdb/duckdb/pull/23310)

  Unflavored-from: c645a18bfd5d93cddb6810367143a6078045b368

- Update vendored sources to duckdb/duckdb@c80f7d5c85714112c64c177f7a72e3fe5b2beb1b.

  Date: 2026-06-16 16:15:32 +0000

  Allow slicing of shredded vectors, and fix issue with shredded vectors being fed into `StructVector::GetEntries` (https://redirect.github.com/duckdb/duckdb/pull/23312)

  Unflavored-from: baa2d07e488b94a014074e2399fb7e1f50ecc784

- Update vendored sources to duckdb/duckdb@98aaa03e7fcc3f4377f6c06f93e51eea07b2702e.

  Date: 2026-06-16 15:57:30 +0000

  \[Dev\] Refactor `MultiFileReader::GetVirtualColumnExpression` and `BaseFileReader::expression_map` (https://redirect.github.com/duckdb/duckdb/pull/22928)

  Unflavored-from: 6d2cf0c5c7f313518136c073df4c06b595ccd1cb

- Update vendored sources to duckdb/duckdb@9206146f46597b972f0ec9f48670b430d6b3efe9.

  Date: 2026-06-16 15:53:10 +0000

  Pass `ParserOptions` in default macro generation (https://redirect.github.com/duckdb/duckdb/pull/23288)

  Unflavored-from: 76053de485fbe7536931b67e470bcf6b6e099c9b

- Update vendored sources to duckdb/duckdb@692c3f82eee396021dccafcad317cce1c41aed8c.

  Date: 2026-06-16 17:52:15 +0200

  Add missing import / fix non-unity builds (https://redirect.github.com/duckdb/duckdb/pull/23308)

  Unflavored-from: abee33f4e1619373796ab42021e9f40869c516e9

- Update vendored sources to duckdb/duckdb@db450569652b7cd4ef7d2c4004b42570fd9d41b7.

  Date: 2026-06-16 17:50:33 +0200

  Add `variant_comparator` which ensures variants are ordered / compared in the same manner as native DuckDB values (https://redirect.github.com/duckdb/duckdb/pull/23307)

  Unflavored-from: dcd91f99c453bfc2a2bd69f13d4d44ba9bcf92dc

- Update vendored sources to duckdb/duckdb@84b53fe286bc65e5fe1bedbc2e0dde4fdea52e9f.

  Date: 2026-06-16 15:02:04 +0000

  Simplify subquery planning for provably single-row subqueries (https://redirect.github.com/duckdb/duckdb/pull/23306)
  Fix flaky `AsyncFileWriter` test (https://redirect.github.com/duckdb/duckdb/pull/23309)

  Unflavored-from: fac7094a3823d146a3aa1c939db4ff16a05b5cf2

- Update vendored sources to duckdb/duckdb@15d3f23bdf1f2cfdb73517d8a462fc2029d9e5cd.

  Date: 2026-06-16 12:54:08 +0000

  Add Parquet ASYNC I/O for local files (https://redirect.github.com/duckdb/duckdb/pull/23290)

  Unflavored-from: 6af53bf16ff426ac6a35ee4468a1e9ad2717175b

- Update vendored sources to duckdb/duckdb@514c5a0b6800d9aefb82d0c76272364d30fb3a46.

  Date: 2026-06-16 12:17:09 +0000

  \[Variant\] Fix crash for variant_extract on non-object shredded column (https://redirect.github.com/duckdb/duckdb/pull/23303)

  Unflavored-from: 116bf532cf5ff0b150e6f48b6116343a7ba9b503

- Update vendored sources to duckdb/duckdb@68d73b7c3a85a8907909cf6d4b6533f83a45496d.

  Date: 2026-06-16 10:32:40 +0000

  Fix flaky `AsyncFileWriter` test (https://redirect.github.com/duckdb/duckdb/pull/23300)
  Remove stale PR workflow (https://redirect.github.com/duckdb/duckdb/pull/23301)

  Unflavored-from: 4d30d0c616b11ec4db3482e90efb8b8f92777324

- Update vendored sources to duckdb/duckdb@03780f1afe1c03cc41b984984596e5306fac62fe.

  Date: 2026-06-16 11:33:05 +0200

  Add setting: SET dialect_compatibility_mode='spark' (https://redirect.github.com/duckdb/duckdb/pull/23251)

  Unflavored-from: 407803865dddea0be8d864840ed086ab458a594a

- Update vendored sources to duckdb/duckdb@c0e638960ede3fd380e2c577905b5dd5c50b22d6.

  Date: 2026-06-16 11:30:14 +0200

  Step 5: Make Mark to Semi join conversion more stable (https://redirect.github.com/duckdb/duckdb/pull/23296)

  Unflavored-from: 619c960194b6bc5766802444e221fa1da8d28c14

- Update vendored sources to duckdb/duckdb@6ca23878c5ed422a73010238cd9fc68f6266ef86.

  Date: 2026-06-16 07:58:02 +0000

  Async Parquet Writes (https://redirect.github.com/duckdb/duckdb/pull/23283)

  Unflavored-from: 1bc9c897122d3dcf00391f27a8eca5a4c4f3f3e3

- Update vendored sources to duckdb/duckdb@58a70740ba6b526578cb43c18374a43a0e14733f.

  Date: 2026-06-16 07:39:47 +0000

  Optimize rollup / cube / grouping sets queries by folding them into CTEs to allow for cascading aggregation (https://redirect.github.com/duckdb/duckdb/pull/23287)

  Unflavored-from: bb6a756e5df47d20329cfe06914d4e9ab2d75a6a

- Update vendored sources to duckdb/duckdb@82bb0f111b1bda2a262844c697cd23365cad0018.

  Date: 2026-06-15 17:00:23 +0000

  Add support for `quantile`, `median`, `mad` to aggregate state export (https://redirect.github.com/duckdb/duckdb/pull/23285)

  Unflavored-from: 682a51533558504f6bc7ad0fd3d67e21f4f810c1

- Update vendored sources to duckdb/duckdb@a07f9f35c3c84c507f6c5b72ee461ecba108a80c.

  Date: 2026-06-15 15:13:28 +0000

  Dead node counting fixes (https://redirect.github.com/duckdb/duckdb/pull/23289)

  Unflavored-from: 90c0c7061d67dd072345d23b0b378ea3ee88fb2a

- Update vendored sources to duckdb/duckdb@93427fc85d86f62fb28f947762e8abc0d1d48a74.

  Date: 2026-06-15 14:06:14 +0000

  Commits on top of PR https://redirect.github.com/duckdb/duckdb/pull/20859 (https://redirect.github.com/duckdb/duckdb/pull/23282)

  Unflavored-from: 79320e5ef21dbcc0df0ecfad28f4ff5470dec28b

- Update vendored sources to duckdb/duckdb@f4a6b66a0f232832eb4de946ec7a6224d1634b04.

  Date: 2026-06-15 12:18:01 +0000

  \[Variant\] Implement `SetVectorType` for `ShreddedVectorBuffer` (https://redirect.github.com/duckdb/duckdb/pull/23280)

  Unflavored-from: 8e5bb5b50b12ff127035c5501e4036bb1098b41f

- Update vendored sources to duckdb/duckdb@475abe6cbe6f36d00a6315830f188a89f5dbef2e.

  Date: 2026-06-15 11:55:51 +0000

  Add setting `force_update_to_del_and_insert ` which forces updates to always be converted to delete and inserts (https://redirect.github.com/duckdb/duckdb/pull/23281)

  Unflavored-from: 9f82d9a57e06b3181ab38820b3899dfe48023d7e

- Update vendored sources to duckdb/duckdb@35b8279eba9992e4d9a4a470fcfada39c63be921.

  Date: 2026-06-15 11:35:27 +0000

  Remove redundancies in join filter creation (https://redirect.github.com/duckdb/duckdb/pull/23250)

  Unflavored-from: 9c30db63126c017a731ab7ecc6d0d67311481efc

- Update vendored sources to duckdb/duckdb@72e5a0f30cc2fd35ab729e7d0623afcb0eaa2c6f.

  Date: 2026-06-15 11:22:52 +0200

  Add support for `string_agg` to export its state by making separators part of the signature (https://redirect.github.com/duckdb/duckdb/pull/23271)

  Unflavored-from: e70fb17cf49b0af34446ce511d931f53eb4b3c80

- Update vendored sources to duckdb/duckdb@96b848d4532832ddabacf7fd7ba0079bc173f564.

  Date: 2026-06-15 10:27:14 +0200

  fix out-of-bounds read in strict time parsing (https://redirect.github.com/duckdb/duckdb/pull/23266)

  Unflavored-from: e2beffa98a54d866e91f85ca55994a164aad13a8

- Update vendored sources to duckdb/duckdb@61e2e648be41315ec5cd3ea9743fb7d7c7ff3f2f.

  Date: 2026-06-15 10:12:44 +0200

  Add `init_local_state_finalize` callback to aggregate functions which allows them to create a `FunctionLocalState` that is persisted across `Finalize` calls, and use this to speed up ordered aggregates (https://redirect.github.com/duckdb/duckdb/pull/23270)

  Unflavored-from: 7e1feda5e8dc883fc5ee3e6ba74b46d24dbc4fa2

- Update vendored sources to duckdb/duckdb@f8f27ba8a45300e2011c7d579946437ae6aab969.

  Date: 2026-06-14 11:46:54 +0000

  Parquet: add expression stats pruning for arithmetic filters (https://redirect.github.com/duckdb/duckdb/pull/23264)
  Unflavored-from: f37563344a94ce9c6d9437c2bf7e3ee77e3b8e0d

- Update vendored sources to duckdb/duckdb@81d30ff05dbe9a3c695b5a35833cefb3839010ed.

  Date: 2026-06-14 11:25:05 +0000

  Fix null sentinel for keys in dict vector (Arrow) (https://redirect.github.com/duckdb/duckdb/pull/22648)
  Add comment policy for bots (https://redirect.github.com/duckdb/duckdb/pull/23272)

  Unflavored-from: 7f73b25bf44833c2d55a03a7bdbf7eb94b559c04

- Update vendored sources to duckdb/duckdb@50b082360abed0892bb8c7a8b3821c034a40b7f3.

  Date: 2026-06-14 13:36:54 +0200

  Remove UnaryAggregateDestructor, and instead fold it into UnaryAggregate (https://redirect.github.com/duckdb/duckdb/pull/23268)

  Unflavored-from: 7d6975099ae9636e308db43d749330374a3726a3

- Update vendored sources to duckdb/duckdb@6a4a6e50cfcb009cb133aff8fd668adc61a080f2.

  Date: 2026-06-14 11:03:16 +0000

  Transform type literals into unbound logical types (https://redirect.github.com/duckdb/duckdb/pull/23237)

  Unflavored-from: aef06084cce42b16137a950fd4385f675460a633

- Update vendored sources to duckdb/duckdb@1a9b24990015fc113cbd7214122971e2e58f4a0c.

  Date: 2026-06-14 11:01:45 +0000

  Consistent ordering for gen files in package_build (https://redirect.github.com/duckdb/duckdb/pull/23267)

  Unflavored-from: f39f64c887f42a59440b55dd0713a389bbd95e51

- Update vendored sources to duckdb/duckdb@52197c0e2a07046fa7689b4381438e8c90d8bc5d.

  Date: 2026-06-14 08:48:00 +0000

  \[Dev\] Resolve `DEFAULT`s for INSERT/UPDATE/MERGE_INTO at bind-time rather than plan-time (https://redirect.github.com/duckdb/duckdb/pull/23033)

  Unflavored-from: 1500cbec5edfd2bc6e52ce20edc9afd977997fea

- Update vendored sources to duckdb/duckdb@ad9adef37d8d80e13314cf51ab31d73f16d217c9.

  Date: 2026-06-14 08:32:52 +0000

  Add `vertex_extract` function to get coordinates out of point-geometries (https://redirect.github.com/duckdb/duckdb/pull/23252)

  Unflavored-from: beb85988299015536e28ad9fba269727d6417d46

- Update vendored sources to duckdb/duckdb@3c674058bef51c27ce93d168d138a8cc14500285.

  Date: 2026-06-14 08:32:02 +0000

  Add support for static linking C-API extensions (https://redirect.github.com/duckdb/duckdb/pull/22251)
  Add `JSONBench` to the benchmark suite (https://redirect.github.com/duckdb/duckdb/pull/23265)

  Unflavored-from: dc35a8b56c0dcbcac1bdf5261931acc8ed801bea

- Update vendored sources to duckdb/duckdb@d667af106441a3822e0e01551b9bd633e0be1e80.

  Date: 2026-06-12 15:22:09 +0000

  Unify quantile `update/combine` callbacks with the list aggregate (https://redirect.github.com/duckdb/duckdb/pull/23247)

  Unflavored-from: 1e5ee64f0244356f9b880b700c1e920fa61555ca

- Update vendored sources to duckdb/duckdb@86ef95f6e94c90719936fdb0167017002fafc191.

  Date: 2026-06-12 13:26:01 +0000

  Auto generate `select.gram` (https://redirect.github.com/duckdb/duckdb/pull/23236)

  Unflavored-from: 85fec6360382cadd76312e8300ae928519eda094

- Update vendored sources to duckdb/duckdb@88f26ae0a394baeb1861ca8a6b81abb829c27bb9.

  Date: 2026-06-12 11:04:16 +0000

  Pluggable combine types rules (https://redirect.github.com/duckdb/duckdb/pull/23173)

  Unflavored-from: 7433b11c190c3e2e4c3046cca9557faf8b701888

- Update vendored sources to duckdb/duckdb@b1473f4aa25b3f1ad813cd60c44d1526702db682.

  Date: 2026-06-12 10:58:38 +0000

  Rework ordered aggregates to use the `list` infrastructure (https://redirect.github.com/duckdb/duckdb/pull/23231)

  Unflavored-from: baa05998339f64460938bb9e545047ca0941e016

- Update vendored sources to duckdb/duckdb@af7ee0fe277b3fcecbe89293c7c91c78d3c66f3b.

  Date: 2026-06-12 10:57:46 +0000

  Step 4: Make unnest rewriter recognize CTE-based plans (https://redirect.github.com/duckdb/duckdb/pull/23240)

  Unflavored-from: 1ec448d2739a087973a2fa9d06a3fa6bbe765f21

- Update vendored sources to duckdb/duckdb@2704267c3f89968c652bced3d60549105ac286ed.

  Date: 2026-06-12 06:41:00 +0000

  Add `decimal_average` aggregate function (https://redirect.github.com/duckdb/duckdb/pull/23097)

  Unflavored-from: 40e2cc3e9853f906cb9ae544facbb8d738268a89

- Update vendored sources to duckdb/duckdb@d8f343577c04ab84c32c19f201e1082ea6fa8ade.

  Date: 2026-06-11 17:30:32 +0000

  Rework `quantile` to use `list` infrastructure and add support for `string_agg` / `quantile` to export state (https://redirect.github.com/duckdb/duckdb/pull/23228)

  Unflavored-from: ae88748ccd3dd49ef95932d708f980a0ee07ddbf

- Update vendored sources to duckdb/duckdb@0d81b05759198489f84f40809a0ee2f211410d84.

  Date: 2026-06-11 16:52:50 +0000

  Unify `ProfilerPrintFormat` and `ExplainFormat` , remove special casing and move towards pluggable tree renderers (https://redirect.github.com/duckdb/duckdb/pull/23222)

  R-side fix

- Update vendored sources to duckdb/duckdb@0cd9e82950be5affb1a7096943d1481c3320914c.

  Date: 2026-06-11 15:37:43 +0000

  Add row group count to parquet RETURN_STATS (https://redirect.github.com/duckdb/duckdb/pull/23218)

  Unflavored-from: e2cd41ae2829a93df167b38af985b29cb2d9d41f

- Update vendored sources to duckdb/duckdb@e855f1f96fcbf53714a7c766718bcb7274c4b9a0.

  Date: 2026-06-11 13:58:42 +0000

  Initial implementation of `variant_array_length` processing function (https://redirect.github.com/duckdb/duckdb/pull/23167)

  Unflavored-from: 2b18c777645d9b1c48358f3e5ce8f025b643b2a3

- Update vendored sources to duckdb/duckdb@71221719b56f39e9499e9afaa4f9e9e0fdb24501.

  Date: 2026-06-11 11:12:35 +0000

  Expand aggregate state export to work with lists (`StateListType`) and sort keys (`StateSortKey`), and add aggregate state export to `list`, `any_value/first/last`, `arg_min/arg_max` (https://redirect.github.com/duckdb/duckdb/pull/23199)
  Remove special formatting code for main CMakeLists.txt (https://redirect.github.com/duckdb/duckdb/pull/23211)

  Unflavored-from: 60e4267d382399d717c009077e3940589200a690

- Update vendored sources to duckdb/duckdb@ce97c00fe2e84ffac2d73988ef58973b03b9035b.

  Date: 2026-06-11 07:39:35 +0000

  RETURNING support for tables with triggers (https://redirect.github.com/duckdb/duckdb/pull/23153)

  Unflavored-from: d812c544d039468897f82dc54d389de7132c6be8

- Update vendored sources to duckdb/duckdb@73a804ef72ea1d1935b12c6432bd634887fe91ea.

  Date: 2026-06-11 08:33:43 +0200

  Allow `MERGE INTO` in triggers (https://redirect.github.com/duckdb/duckdb/pull/23179)

  Unflavored-from: 67527f6dd012b7a5c90284d1e127ab597daaef43

- Update vendored sources to duckdb/duckdb@ff62f2bc89a2f899fc18652f4d7a4be2258f8fbd.

  Date: 2026-06-10 17:26:32 +0200

  Step 3: Make duplicate eliminator optimizer logic work for CTE rewrite (https://redirect.github.com/duckdb/duckdb/pull/23187)
  Move to tidy-check diff again (https://redirect.github.com/duckdb/duckdb/pull/23196)

  Unflavored-from: d864e425777a27f59c46ca04f091f2e319e23d4d

- Update vendored sources to duckdb/duckdb@3cba407d73add582b3bc8e2dad8a6b37947d0867.

  Date: 2026-06-10 13:08:15 +0200

  Make `Identifier` a class instead of using string everywhere (https://redirect.github.com/duckdb/duckdb/pull/23161)

  Carried from `origin/v2.0-cyanoptera-dev` at d62603eada:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Landing v2 (finding 9): `RType::operator==()` compares struct field names and factor levels exactly, with `GetIdentifierName()` (`src/types.cpp`), since an `Identifier` compares case-insensitively.

  Unflavored-from: 4273f3f8d7c578da88bfb2b0fa552ddee47d52af

- Update vendored sources to duckdb/duckdb@60279d26a7090e17a06a134b8f650c573033552a.

  Date: 2026-06-10 07:06:47 +0000

  Aggregate States: add `OptionalStateType<T>` to aggregate states (https://redirect.github.com/duckdb/duckdb/pull/23186)

  Unflavored-from: 16207779b910a9e5a13b436b54f13f7e4b8a301c

- Update vendored sources to duckdb/duckdb@fc966e1f0bc61886ed6328c6e2fda31cc2d125e2.

  Date: 2026-06-10 05:38:52 +0000

  Bump MySQL and Postgres (https://redirect.github.com/duckdb/duckdb/pull/23181)

  Unflavored-from: b7d7f2499a3a0b2e25b7e4a768596c24f8654294

- Update vendored sources to duckdb/duckdb@66de9035b1db8e3bf269a41107d51b0c0fed6b35.

  Date: 2026-06-09 19:50:05 +0000

  Support scalar-wrapped aggregate macros in window (https://redirect.github.com/duckdb/duckdb/pull/23050)

  Unflavored-from: bda9784d91acb56b02b82a3e07210b6fa97da6c5

- Update vendored sources to duckdb/duckdb@7950f1a9e087da52e821f4ef98e1fab46c5a6224.

  Date: 2026-06-09 19:32:16 +0000

  Remove deprecated settings 'enable_http_logging' and 'http_logging_output' (https://redirect.github.com/duckdb/duckdb/pull/23169)

  Unflavored-from: bbba796fc3db6fe3304f18e54e5e87476a9aa438

- Update vendored sources to duckdb/duckdb@3e403a6bd6a7d6d767b0f7e2deb569710e06a74e.

  Date: 2026-06-09 19:31:05 +0000

  Allow aggregate states to be scalars, and clean-up aggregate state (de)serialization code (https://redirect.github.com/duckdb/duckdb/pull/23168)

  Unflavored-from: dac6c71a5cfc4610cb927040d91af26854049a67

- Update vendored sources to duckdb/duckdb@49db7a008df8bd6d45055d996673b5dd554b3a64.

  Date: 2026-06-09 15:20:23 +0000

  Fix ORDER BY true/false bypassing non-integer literal validation (https://redirect.github.com/duckdb/duckdb/pull/23105)

  Unflavored-from: ed7fad5da8526878a799b5319c9dff2f9152796b

- Update vendored sources to duckdb/duckdb@b9d080c0a4cd47aa01c200e4a66ab23ee432aa84.

  Date: 2026-06-09 15:02:35 +0000

  PEG/3: Peeling statements stacked (https://redirect.github.com/duckdb/duckdb/pull/23032)

  Unflavored-from: 12dfae850aef796c56e8b10185a1eff89bf2f972

- Update vendored sources to duckdb/duckdb@f67e8a27411c4217a4f6a71e133c5dc17d6edcf7.

  Date: 2026-06-09 14:56:50 +0000

  Parquet Reader with Async I/O (https://redirect.github.com/duckdb/duckdb/pull/23142)

  Unflavored-from: eecf5549b14936a9eb0342fa095c1d386258a402

- Update vendored sources to duckdb/duckdb@9976d5ebc1cc8df49867e3fa0d143220d58e8619.

  Date: 2026-06-09 14:56:28 +0000

  Fold complement operations when NO_NULLs (https://redirect.github.com/duckdb/duckdb/pull/23165)

  Unflavored-from: aace73b8eebdfc03125c29578dfa6056a72c98ea

- Update vendored sources to duckdb/duckdb@07b42a37db0328cb50717cbf7a1d22ce8fa569f7.

  Date: 2026-06-09 13:14:51 +0000

  Aggregate States: Allow state layout types to be defined as template members in the actual state, instead of requiring a separate function (https://redirect.github.com/duckdb/duckdb/pull/23164)

  Unflavored-from: e26a13652651cf1ed1ae8981c55af02395b2a317

- Update vendored sources to duckdb/duckdb@299408623e398bc4072e0233a7c1d6ebddf7a68e.

  Date: 2026-06-09 12:27:33 +0000

  BinaryExecutor: unrolled path, also there perform blind store on selection vector (https://redirect.github.com/duckdb/duckdb/pull/23166)
  Unflavored-from: ebd9bc9c2e48f5513e0bb53a26be77c17f1b3af5

- Update vendored sources to duckdb/duckdb@e4405411bc6d8079620af2402f070d63f5b1ed17.

  Date: 2026-06-09 12:20:06 +0000

  Add file_row_group_number virtual column to the Parquet reader (https://redirect.github.com/duckdb/duckdb/pull/23157)

  Unflavored-from: 870581e70e47095f0f2af61267d3c22ce7bb2828

- Update vendored sources to duckdb/duckdb@a1b15369632272057b66760add094816eb807243.

  Date: 2026-06-09 11:00:51 +0000

  Fix update merge path of varchar (https://redirect.github.com/duckdb/duckdb/pull/23163)

  Unflavored-from: a94194fdcee500b680794fedac535deac90be9b4

- Update vendored sources to duckdb/duckdb@a7b16c6f323b405d9cfce9b1d6867df21687b19f.

  Date: 2026-06-08 21:14:10 +0000

  Rework aggregate states - make aggregate states use extension type info, and fully deprecate legacy aggregate states (https://redirect.github.com/duckdb/duckdb/pull/23134)

  Unflavored-from: 7444fa84370b05828f2a5e6514c17d5e01681c2b

- Update vendored sources to duckdb/duckdb@018b2a4a49d16ee4a12febd1f96889872df70678.

  Date: 2026-06-08 17:07:23 +0000

  Extract combine rules into functions (https://redirect.github.com/duckdb/duckdb/pull/23131)

  Unflavored-from: a31f1036e06715e0b98d51e8149efc7301550097

- Update vendored sources to duckdb/duckdb@edcb9aa42b12d490c9b28ae20385364cf3bc1afe.

  Date: 2026-06-08 16:41:20 +0000

  Extend `RemotePushdownOptimizer` to be more flexible w.r.t. unsupported remote catalog operations, and integrate with MySQL (https://redirect.github.com/duckdb/duckdb/pull/23135)

  Unflavored-from: 65bfc5c551e416eb4a7062455168bcd0a719758a

- Update vendored sources to duckdb/duckdb@31654258b1e491ac19ba2dd2c937420249dd834d.

  Date: 2026-06-08 15:55:56 +0000

  \[Parquet\]\[Dev\] Fix prefetching error on skipped column (https://redirect.github.com/duckdb/duckdb/pull/23138)

  Unflavored-from: ef9dd31fa040f93f5d8a6f54cdb856dfc6700d67

- Update vendored sources to duckdb/duckdb@50efed0faf3ae107f95d616e69f78648b9720732.

  Date: 2026-06-08 14:32:15 +0000

  Leonid/before triggers (https://redirect.github.com/duckdb/duckdb/pull/23119)

  Unflavored-from: c5ef27cac126c7e9df88aba558be6f0e6f72fb37

- Update vendored sources to duckdb/duckdb@bd6af0e45229cb2832c36ba3092f89a9f10bc628.

  Date: 2026-06-08 13:56:21 +0000

  Use min/max as a proxy for distinct count if estimates are absent (https://redirect.github.com/duckdb/duckdb/pull/23133)

  Unflavored-from: 904ee8ffb308a90a2fd1cde2acb27a999a6be10d

- Update vendored sources to duckdb/duckdb@eb314bd9ddc55602f1d793fd781fe1602e6ec4ba.

  Date: 2026-06-08 12:41:27 +0000

  Add debug verification mode for verifying that functions have the correct NULL flags (verify_functions) - instead of only running this in debug mode (https://redirect.github.com/duckdb/duckdb/pull/23123)

  Unflavored-from: fb6692acbe649542ab5b49fe6b953797340ece62

- Update vendored sources to duckdb/duckdb@43e5f369d4944d1eb6640df4835df2f6b270e755.

  Date: 2026-06-08 11:14:32 +0000

  Fix correlated joinside regression (https://redirect.github.com/duckdb/duckdb/pull/23128)

  Unflavored-from: 1724a1390bc489a119c8121763775f10ba8796cb

- Update vendored sources to duckdb/duckdb@3bafe7a84c9b467ef65a23c278961332c6f5f597.

  Date: 2026-06-08 08:31:06 +0000

  Rework pr22857: fix external file cache memleak (https://redirect.github.com/duckdb/duckdb/pull/23052)

  Unflavored-from: de5f879ecac8cbf9fcd351ecd537b7ae01e6f098

- Update vendored sources to duckdb/duckdb@d7b51fbc7d2cc1ba81847d6ecfc25a524e2247ab.

  Date: 2026-06-07 12:32:37 +0000

  Aggregates: Make `StateInitialize` zero-initialize by default if no Initialize method is provided (https://redirect.github.com/duckdb/duckdb/pull/23112)
  Unflavored-from: 94c950f62efb5344961070aac7622e87edd1c080

- Update vendored sources to duckdb/duckdb@8a3a51774de1a6788c5f1753c6024bf279470c5c.

  Date: 2026-06-07 09:26:13 +0000

  Fetch co-located rows in batch (https://redirect.github.com/duckdb/duckdb/pull/22871)

  Unflavored-from: 796be6356346174227cbd55668289d0cefa4dfc0

- Update vendored sources to duckdb/duckdb@0325fd2f2e68a0a0d14a991bd51559e4fd45ef9e.

  Date: 2026-06-07 09:24:25 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9579: ENUM IN empty (https://redirect.github.com/duckdb/duckdb/pull/23074)
  @smvv's Extension signing (https://redirect.github.com/duckdb/duckdb/pull/23108)

  Unflavored-from: dba4c31844fc23dd04624e9944b7f0931af8287e

- Update vendored sources to duckdb/duckdb@bd6dc64c06bea81e66adfaf0d70cbf1164ba3c22.

  Date: 2026-06-06 15:18:44 +0000

  Step2: Push DELIM filters into CTE rewrite (https://redirect.github.com/duckdb/duckdb/pull/23101)
  Unflavored-from: 334024e7067a484d7b8b9ea38975cb5d3d1607d3

- Update vendored sources to duckdb/duckdb@c37a4f5b27480f0236bd3333218b713ca16ad6e5.

  Date: 2026-06-06 12:35:56 +0000

  Rework `string_agg` to operate on a `string_t` directly (https://redirect.github.com/duckdb/duckdb/pull/23107)

  Unflavored-from: 957c8bf565f9f2104606f9e02a53a30b289c9216

- Update vendored sources to duckdb/duckdb@cfd562efe84bc4e354512d7d228eada1f671ce8a.

  Date: 2026-06-06 09:20:48 +0000

  loop in sleep_ms (https://redirect.github.com/duckdb/duckdb/pull/23021)

  Unflavored-from: 6bcfbecc627e29ea00cf29a53ea59102b6916681

- Update vendored sources to duckdb/duckdb@d9cfa516640a9aa7fec6aed147080ff1a3afd9c4.

  Date: 2026-06-06 07:06:50 +0000

  Remove templating from type combines (https://redirect.github.com/duckdb/duckdb/pull/23106)

  Unflavored-from: 7781c56e16a4f08622c94d205b5a3b77f70639ee

- Update vendored sources to duckdb/duckdb@7b77b875dbc27e558b770ee83f94c60e42aed7d1.

  Date: 2026-06-05 19:40:30 +0000

  Keep track of the exact row groups that were flushed instead of just assuming the last row group was unflushed (https://redirect.github.com/duckdb/duckdb/pull/23103)

  Unflavored-from: c7d0fa6b178370b6d5b1b82914b6c20e688b099d

- Update vendored sources to duckdb/duckdb@2db048e09292dd5b1f57c3c8b9479ee5bac26e9a.

  Date: 2026-06-05 13:32:05 +0000

  Step 1: Remove duplicate-eliminated joins and replace them with materialized CTEs (https://redirect.github.com/duckdb/duckdb/pull/23098)

  Unflavored-from: f8839084c47858b1b1fee8c5fe45f6c47dba2e29

- Update vendored sources to duckdb/duckdb@478ecc06742c81477b7e63c855e9ada243d6b6c7.

  Date: 2026-06-05 10:56:01 +0000

  PEG/2: Restructure top level `Program` definition (https://redirect.github.com/duckdb/duckdb/pull/23029)

  Unflavored-from: ae52f6c1916420b03eabf24a58c7ab4e6a32cc81

- Update vendored sources to duckdb/duckdb@f52184f91d82123627d266f873fde3dbbde9ab3d.

  Date: 2026-06-05 10:47:32 +0000

  Make HTTP 502 responses retryable (https://redirect.github.com/duckdb/duckdb/pull/23036)

  Unflavored-from: 1d84e23ffbf5b0bcc061f5c7c6085adce77af1b4

- Update vendored sources to duckdb/duckdb@1e4c7d354cd18cb504ffa1802ee1cb170635ca04.

  Date: 2026-06-05 10:46:37 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/23059: Dead WindowExpression Code (https://redirect.github.com/duckdb/duckdb/pull/23078)

  Unflavored-from: 3a67fd01b9fbd9abef73eeb3e4c0d786251826bc

- Update vendored sources to duckdb/duckdb@0d469549a8e4efc470d8cd3e86e7c3eb6f5b1cdb.

  Date: 2026-06-05 10:46:14 +0000

  Add `decimal_division` scalar function (https://redirect.github.com/duckdb/duckdb/pull/23069)

  Unflavored-from: 2fcb8944169ceadaa444380a68e561d03e767f57

- Update vendored sources to duckdb/duckdb@89268bef04192ccc33f838c4d7473a72eceff636.

  Date: 2026-06-05 10:37:52 +0000

  Fix strict-prototypes warnings (https://redirect.github.com/duckdb/duckdb/pull/23086)

  Unflavored-from: dd4f04ff6f3e2fb23196935664065b1e3a74b4e9

- Update vendored sources to duckdb/duckdb@4f977ad8ec04679aea2b9dee3c05b8d86beaaf5a.

  Date: 2026-06-05 10:36:37 +0000

  Zero-initialize in FIRST/ANY_VALUE (https://redirect.github.com/duckdb/duckdb/pull/23083)
  Improve test output and highlight functions in stack trace (https://redirect.github.com/duckdb/duckdb/pull/23079)
  Fix CMake flag for linux_arm64_musl builds (https://redirect.github.com/duckdb/duckdb/pull/21161)
  Point to correct paths on parser README.md (https://redirect.github.com/duckdb/duckdb/pull/23087)

  Unflavored-from: fbe9fe289596d8ed05d521d6e2b6e9f248b26e39

- Update vendored sources to duckdb/duckdb@19de9b115d784708c60cff607a1b6c0c8c04de61.

  Date: 2026-06-05 08:33:45 +0000

  use StringUtil::CharacterToLower in strptime parser (https://redirect.github.com/duckdb/duckdb/pull/23048)

  Unflavored-from: fc292016b134106ba9ed196b78cc4940f4f68631

- Update vendored sources to duckdb/duckdb@81c18bf5101a88b52d95deda37a0eaffe26f38c7.

  Date: 2026-06-05 07:29:16 +0000

  Aggregate State Export: Add support for aggregates that have a `FunctionData` (https://redirect.github.com/duckdb/duckdb/pull/23080)
  docs: create `AGENTS.md` and link from `CLAUDE.md` (https://redirect.github.com/duckdb/duckdb/pull/23077)

  Unflavored-from: fbbb2c95d6effdb020b232e08f22ccd7450f3b31

- Update vendored sources to duckdb/duckdb@0ce48ae355b2358414808c95216d8b79f8ee111d.

  Date: 2026-06-04 19:30:48 +0000

  Remove several unnecessary calls to `SetChildCardinality` (https://redirect.github.com/duckdb/duckdb/pull/23067)

  Unflavored-from: 9a2037780a6a59d53803b2f24cda4ca231468028

- Update vendored sources to duckdb/duckdb@d8f427feab1e97c3bacf1eee5564ba46ad3ac3aa.

  Date: 2026-06-04 19:02:30 +0000

  Add aggregate state export verification setting and config file (https://redirect.github.com/duckdb/duckdb/pull/23072)

  Unflavored-from: aa2382dbb7ced2e0d669a0d3639c11495788207e

- Update vendored sources to duckdb/duckdb@11cd0579306e009067743b263c7f56196aed1625.

  Date: 2026-06-04 16:28:36 +0000

  Generate transformer part 6 (https://redirect.github.com/duckdb/duckdb/pull/23070)

  Unflavored-from: 8bfeb3674bcbf73d0ea5cfd241ee4815d28fa72c

- Update vendored sources to duckdb/duckdb@deb59fc8e0a37d19d5e393168dd9738d242e4d3d.

  Date: 2026-06-04 16:19:08 +0000

  Support named/default arguments for window functions too (https://redirect.github.com/duckdb/duckdb/pull/23059)

  Unflavored-from: dce9fdb826d20906591e7a39726461051b65fc1e

- Update vendored sources to duckdb/duckdb@03540434cf9968f813526e3ee23214aea9e413dd.

  Date: 2026-06-04 14:44:54 +0000

  Fix race condition in partitioned copy (https://redirect.github.com/duckdb/duckdb/pull/23068)

  Unflavored-from: cdd4f7a862ffaa77b37c0cfc0bc922703a9d5211

- Update vendored sources to duckdb/duckdb@7e9b527cf8ef0c97c4a9cdfba3d1ef6d0bae320c.

  Date: 2026-06-04 14:16:13 +0000

  remove assert in DataTable::RemoveFromIndexes (https://redirect.github.com/duckdb/duckdb/pull/23066)

  Unflavored-from: 34224e7fd24dcedcff556596e261ebc6fbfc119f

- Update vendored sources to duckdb/duckdb@9d8ec97092fdd0b4d7cbf711f3b9a15d2a48cbff.

  Date: 2026-06-04 14:11:00 +0000

  Initial implementation of `variant_exists` processing function (https://redirect.github.com/duckdb/duckdb/pull/22879)
  CLI: Make .schema indent by default and add syntax highlighting, and add `--no-indent/--no-format` to revert to the old single-line formatting (https://redirect.github.com/duckdb/duckdb/pull/23065)

  Unflavored-from: 4ca0def8f5c086d80ce8daa47cd1ef7e15af6955

- Update vendored sources to duckdb/duckdb@d4fbf92ae9865974e49600ecd7e1e5a5d3448349.

  Date: 2026-06-04 13:41:18 +0000

  Refactor of Parquet Scan for ASYNC I/O (https://redirect.github.com/duckdb/duckdb/pull/23061)

  Unflavored-from: 423f09b31b0bc41e3f2d238a135afdbf0e429cda

- Update vendored sources to duckdb/duckdb@03e1afd6d5758c2630f47d2c11913f1d082762d8.

  Date: 2026-06-04 13:40:13 +0000

  \[Bug\] Fix string-heap copy for updates mixing NULL and non-NULL values (https://redirect.github.com/duckdb/duckdb/pull/23060)
  Add build/\*/test/run alias and improve test runner output (https://redirect.github.com/duckdb/duckdb/pull/23055)

  Unflavored-from: f39136a872d36ef611f3f1dd79d78616b6ada9c7

- Update vendored sources to duckdb/duckdb@2c375649937a4092b1f390be2e9bc6e1baeb5821.

  Date: 2026-06-04 12:53:37 +0000

  Implement file rotation for partitioned copy (https://redirect.github.com/duckdb/duckdb/pull/23062)

  Unflavored-from: 0a74a76138bccf70098a89deea4d498dc67f4729

- Update vendored sources to duckdb/duckdb@53cd06eeb67e1024c59216e84b3abd770c52fd89.

  Date: 2026-06-04 09:34:13 +0000

  Fix top-n window elimination dropping value-transforming payloads (https://redirect.github.com/duckdb/duckdb/pull/22892)

  Unflavored-from: 6a90f4341acf0f6c88af86f87580b2fc71043353

- Update vendored sources to duckdb/duckdb@d5bb9ca2c24376ebd444ca4267fa5457698aaca8.

  Date: 2026-06-04 08:56:36 +0000

  Left join cost/cardinality improvements (https://redirect.github.com/duckdb/duckdb/pull/23038)

  Unflavored-from: c465aad1fd84800d9edb83b04a0bc1b81a7968e4

- Update vendored sources to duckdb/duckdb@b9b51baf91e88c3cc19eb6ac874809f68fc8d356.

  Date: 2026-06-04 08:51:02 +0000

  \[minor\] Update exception message (https://redirect.github.com/duckdb/duckdb/pull/22545)

  Unflavored-from: 385fa2738c01848f3954c1a51ad82d68b484e2e0

- Update vendored sources to duckdb/duckdb@b4c90a78c45d3014afc3eec69fa4df18a32817e8.

  Date: 2026-06-04 08:46:31 +0000

  Delayed Partition Flushing (https://redirect.github.com/duckdb/duckdb/pull/23037)

  Unflavored-from: a2615e7d9b67bdebec0edc2c4a71b145362cc959

- Update vendored sources to duckdb/duckdb@4c8c90db44fbfcee96ee299d1c5940781b73210a.

  Date: 2026-06-04 08:25:16 +0000

  Avoid join filter pushdown below limits (https://redirect.github.com/duckdb/duckdb/pull/22963)
  Rename emscripten action in main (https://redirect.github.com/duckdb/duckdb/pull/23043)
  Normalize version number in CMake version config (https://redirect.github.com/duckdb/duckdb/pull/22939)

  Unflavored-from: e2764f168ff699a18803419090000a7c85a0595d

- Update vendored sources to duckdb/duckdb@d0c8617200b5b6363e839c7c505d5e2b9504a2eb.

  Date: 2026-06-04 08:23:43 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9434: ENUM IN STRING_LITERAL (https://redirect.github.com/duckdb/duckdb/pull/22959)

  Unflavored-from: edd3c7b0cca9adc8d42c7ef77d7430665ad9d654

- Update vendored sources to duckdb/duckdb@d1434e02ce600258cbd6f1c8e44c3825fdb6830d.

  Date: 2026-06-04 06:15:31 +0000

  Merge `v1.5-variegata` into main (https://redirect.github.com/duckdb/duckdb/pull/23039)

  Unflavored-from: d38cfdbe9308989e99795f0acf5bf29d082fe79b

- Update vendored sources to duckdb/duckdb@11ee25cd67a260bd629671fa8176a8781e623bc5.

  Date: 2026-06-03 17:58:44 +0000

  Unify named arguments + default arguments for `(Scalar/Aggregate/Window)Functions` (https://redirect.github.com/duckdb/duckdb/pull/22941)
  Retry db init/load command atomically in cost plan runner (https://redirect.github.com/duckdb/duckdb/pull/23040)
  Isolate .tmp/ to avoid concurrent test temp-spill data corruption (https://redirect.github.com/duckdb/duckdb/pull/23047)

  Unflavored-from: 12d69a436f33118e36dad7704e7b2bcab503cb17

- Update vendored sources to duckdb/duckdb@e888287b695d002d33885375340b5f6aafd88652.

  Date: 2026-06-03 17:26:33 +0000

  Use buffer allocator to track memory management - Parquet Prefetch (https://redirect.github.com/duckdb/duckdb/pull/23026)

  Unflavored-from: 8f3658418bb24be2f3f1e6c6ca5c58dec6de320c

- Update vendored sources to duckdb/duckdb@4820e7a55708e709d386da7e14418a18e06c416f.

  Date: 2026-06-03 19:29:15 +0200

  Populate is_generated and generation_expression in information_schema.columns (https://redirect.github.com/duckdb/duckdb/pull/22757)
  Tests rely on exact hash function (https://redirect.github.com/duckdb/duckdb/pull/23035)

  Unflavored-from: df6e0ba5589c3a60e9fd97ffdda805b9aacec8dd

- Update vendored sources to duckdb/duckdb@e56006f65b5ad8b805f3785cc303bb34ecb04c0e.

  Date: 2026-06-03 14:15:28 +0000

  Fix skewness() test failure and stabilize main CI (https://redirect.github.com/duckdb/duckdb/pull/23030)
  CLI: Add support for `shell_history()` function and `.history` command (https://redirect.github.com/duckdb/duckdb/pull/23034)

  Unflavored-from: b0a3785c99e5dd1111b0ccdb237f0362af7594e5

- Update vendored sources to duckdb/duckdb@be587a70ee5eae815e333ca121d39b6905f34535.

  Date: 2026-06-03 13:26:01 +0000

  Bump MySQL (https://redirect.github.com/duckdb/duckdb/pull/23023)

  Unflavored-from: 12acb57cac7535646632dd403c79539bdc38ec7a

- Update vendored sources to duckdb/duckdb@736c353997f474f4121d384a1c3d83e8b94b57a2.

  Date: 2026-06-03 13:20:26 +0000

  Add expression stats pruning for arithmetic filters (https://redirect.github.com/duckdb/duckdb/pull/22819)

  Unflavored-from: 90ff02a9bc387efd3070b8d1ff97d1b020bb7c8d

- Update vendored sources to duckdb/duckdb@24532c32916234e9f4cf1d52adf29f33b6068bcc.

  Date: 2026-06-03 11:35:53 +0000

  Fix file log CSV writer state and header after truncate_duckdb_logs (https://redirect.github.com/duckdb/duckdb/pull/22646)
  AI Policy (https://redirect.github.com/duckdb/duckdb/pull/23025)

  Unflavored-from: 7e87a728c28035edb445e578e0b310a4eb834e7c

- Update vendored sources to duckdb/duckdb@b0d333dbd9dc54fbf37cfcf6cc18e7b27cbecacf.

  Date: 2026-06-03 10:54:23 +0000

  Async Thread Pool / Task Queue (https://redirect.github.com/duckdb/duckdb/pull/23002)

  Unflavored-from: 4dc4686b49d939443eb2b7001a513dc77f17fee1

- Update vendored sources to duckdb/duckdb@c726f9e3b80b610a2125a0317a39399dedecdc12.

  Date: 2026-06-03 10:39:09 +0000

  Reapply: Enable jemalloc heap profiling with the libgcc unwinder (https://redirect.github.com/duckdb/duckdb/pull/23005)
  Reduce test runner log output (https://redirect.github.com/duckdb/duckdb/pull/23015)
  support `partition_by` for JSON writes (https://redirect.github.com/duckdb/duckdb/pull/22993)

  Unflavored-from: 52c60d0d8483b854ac13677de29a9aa44a9f885a

- Update vendored sources to duckdb/duckdb@7e889c9168401b116b0b0ed3fc90634776a91059.

  Date: 2026-06-03 07:51:51 +0000

  Parse short timestamp times with UTC suffixes (https://redirect.github.com/duckdb/duckdb/pull/22922)

  Unflavored-from: d4459451bc040cad5a7e10c70655a3ad9d64dceb

- Update vendored sources to duckdb/duckdb@7594f5a2d37b3f9f5c7d51ad9cf3d5aafd73ea5d.

  Date: 2026-06-03 07:45:20 +0000

  Deprecate `DataChunk::SetCardinality`, add `DataChunk::CheckCardinality`, and make `DataChunk::count` an `optional_idx` (https://redirect.github.com/duckdb/duckdb/pull/23016)

  Unflavored-from: 0d1855cc70861fd83c2a3d83bfd912e49f249f86

- Update vendored sources to duckdb/duckdb@457b1aceeaa9b656aa12791df61dfb82d7451624.

  Date: 2026-06-03 07:26:42 +0000

  Join filter mirroring (https://redirect.github.com/duckdb/duckdb/pull/23009)

  Unflavored-from: 1f5327db29c7dd0153e6820501b268eb5403f367

- Update vendored sources to duckdb/duckdb@9ddf2e47203038eadab10735d0b5f301893c724e.

  Date: 2026-06-03 08:24:00 +0200

  Change scope of max execution time (https://redirect.github.com/duckdb/duckdb/pull/23018)

  Unflavored-from: bd673846590213e4ff82f13a1202664639519d2b

- Update vendored sources to duckdb/duckdb@28ede7f5f6e5dba3d36b2ea75fa707ffd1091787.

  Date: 2026-06-02 20:14:03 +0000

  Remove LimitPercentModifier, inline into LimitModifier (https://redirect.github.com/duckdb/duckdb/pull/23011)

  Unflavored-from: e07d1f04d2bc4c18ef3afeab2f6c174c9c1b1a77

- Update vendored sources to duckdb/duckdb@ac3b2f2b5ba9414b6a7a26c7380b1c2cc80ff8dd.

  Date: 2026-06-02 16:57:12 +0000

  Fix BIT comparison ordering for unequal lengths (https://redirect.github.com/duckdb/duckdb/pull/22923)

  Unflavored-from: 8a6e31acb9574d52ef30dcec86824fc1196198a0

- Update vendored sources to duckdb/duckdb@998141cb23ea81a1780231cb2d1ff194fd0b569f.

  Date: 2026-06-02 16:02:22 +0000

  Fix skewness() returning garbage instead of NULL for zero-variance input (https://redirect.github.com/duckdb/duckdb/pull/21871)

  Unflavored-from: 12d5824dd337ea5542c28d5acf317b9a0402b0a9

- Update vendored sources to duckdb/duckdb@4fa71d3142d877e1775c53074dfc0ecf2eea6cca.

  Date: 2026-06-02 15:53:05 +0000

  Fix fuzzer issues (https://redirect.github.com/duckdb/duckdb/pull/22808)
  Fix iceberg (https://redirect.github.com/duckdb/duckdb/pull/23013)

  Unflavored-from: 55933f4aafcca2a9ff4cc32a4b039a6181270586

- Update vendored sources to duckdb/duckdb@7bacf4a248656d5a442c4fac4b6ada1e91423e5a.

  Date: 2026-06-02 18:55:45 +0200

  Remote Pushdown Optimizer: for now skip pushdown on remote functions (https://redirect.github.com/duckdb/duckdb/pull/23012)

  Unflavored-from: d6d707a922f859161cab4e028b59fecc692e685b

- Update vendored sources to duckdb/duckdb@b04fc89a2c42aa8a61514a27b4985173c857cfe9.

  Date: 2026-06-02 15:50:54 +0000

  use StringUtil::CharacterIsDigit in Bignum::VarcharFormatting (https://redirect.github.com/duckdb/duckdb/pull/22960)

  Unflavored-from: a319b4a70b2e953a932ec934f73b76485a6240d7

- Update vendored sources to duckdb/duckdb@136cda05d5da2b29c33a95f7a5c287f31b59b5c3.

  Date: 2026-06-02 15:43:27 +0000

  MultiFileReader allow_empty (https://redirect.github.com/duckdb/duckdb/pull/22771)

  Unflavored-from: 4905f8998ddebcfcfcb8555ba87190330d80d847

- Update vendored sources to duckdb/duckdb@9a8c4617d9d71e46c3dc6034447deea72b4a01c2.

  Date: 2026-06-02 15:14:21 +0000

  Move `BoundParameterExpression`, `BoundReferenceExpression`, `BoundSubqueryExpression`, `BoundUnnestExpression`, `BoundWindowExpression` members to private and use accessors (https://redirect.github.com/duckdb/duckdb/pull/23006)

  Unflavored-from: 3dbcc9400ccc77c06630eeeb3025565e2c13d214

- Update vendored sources to duckdb/duckdb@95f5b421113e3bfb27169aeb8b1a1c75226ef017.

  Date: 2026-06-02 14:37:09 +0000

  \[Dev\] Bump iceberg+avro extensions (https://redirect.github.com/duckdb/duckdb/pull/22907)

  Unflavored-from: f50b0d5c9d2c25adfc4446c939f67da69828eed8

- Update vendored sources to duckdb/duckdb@c6939ad61f41956491dd85e17d8b04b6055a21e6.

  Date: 2026-06-02 13:36:27 +0000

  Make casts extensible for CASE expression (https://redirect.github.com/duckdb/duckdb/pull/23007)

  Unflavored-from: 9c071b0b0bc5cba2f95cedc30149fac8a7fb02d5

- Update vendored sources to duckdb/duckdb@5abb2594a2bf3878838a44fd1c4b138c7d478521.

  Date: 2026-06-02 13:03:15 +0000

  Add setting to allows to get compile time STANDARD_VECTOR_SIZE from SQL (https://redirect.github.com/duckdb/duckdb/pull/22978)

  Unflavored-from: 37794f6d3acf4801eafc3ba2508b910336331378

- Update vendored sources to duckdb/duckdb@5422a51c5c45901d40d27e773469a5bc80f085d8.

  Date: 2026-06-02 12:45:33 +0000

  Parquet Prefetch - CostModel for defining column gaps (https://redirect.github.com/duckdb/duckdb/pull/23003)

  Unflavored-from: bf4ba58e4e3f200814d774523bc2b2886d3e8acc

- Update vendored sources to duckdb/duckdb@7dcfd4b97e354832a2c1c7bc77b76e73033f7652.

  Date: 2026-06-02 12:42:08 +0000

  Let AsyncExecutionTask always notify blocked pipeline when a task throws (https://redirect.github.com/duckdb/duckdb/pull/23001)

  Unflavored-from: 40b12f8be171d02462f61fc9c6eb6e3a6cd268a6

- Update vendored sources to duckdb/duckdb@0d46559fa127c7f21ffa289baeae180df87d535b.

  Date: 2026-06-02 12:41:08 +0000

  Allow gaps in rowids (https://redirect.github.com/duckdb/duckdb/pull/22822)
  Improve test runner (https://redirect.github.com/duckdb/duckdb/pull/23004)

  Unflavored-from: 874a6499f66cee682435b61baa82ecc40d08543f

- Update vendored sources to duckdb/duckdb@4fc395cacbf00f7a0608961d8fb360f4ff4d41ca.

  Date: 2026-06-02 11:31:32 +0000

  Support multiple triggers per table event (https://redirect.github.com/duckdb/duckdb/pull/22998)

  Unflavored-from: 8f75c11afb2f0166e1ccb56ba9b44001b29ca899

- Update vendored sources to duckdb/duckdb@17997b74e7e0117b0116012db152689d291d8918.

  Date: 2026-06-02 11:26:08 +0000

  Add support for `MMAP` and `DIRECT_IO` I/O modes (https://redirect.github.com/duckdb/duckdb/pull/22988)

  Unflavored-from: 0846bcaee3e30209513bd1a650a099f2c438c4ae

- Update vendored sources to duckdb/duckdb@632fec837d6020ae6ad54777e57337f14b4d2b68.

  Date: 2026-06-02 10:36:04 +0000

  `CONNECT`: CLI prompt, implement for `postgres` and add `Supports(RemoteCapability::<X>)` (https://redirect.github.com/duckdb/duckdb/pull/22950)

  Unflavored-from: 246b34511cc11ab0f58060ad0ce8dd4dc03ee74f

- Update vendored sources to duckdb/duckdb@29efe5f61ca8a25ebe7e91f52300abd1fddad65d.

  Date: 2026-06-02 09:02:43 +0000

  use StringUtil char helpers in geometry WKT parsers (https://redirect.github.com/duckdb/duckdb/pull/22996)

  Unflavored-from: 170d5fd79eb5c2844a08ffc4f1f73bb7436c012c

- Update vendored sources to duckdb/duckdb@6c4baf23e76d3261df70466322a23fc39fa6291a.

  Date: 2026-06-02 09:02:37 +0000

  Move MergeStatement into `MergeQueryNode` (https://redirect.github.com/duckdb/duckdb/pull/22999)

  Unflavored-from: c2eb2f869c95221120d54ae5389ea5cbebadb5c3

- Update vendored sources to duckdb/duckdb@a81697c0e2f8697633aa98942cf16fc5e801eb79.

  Date: 2026-06-02 08:42:34 +0000

  Fix external file cache disablement (https://redirect.github.com/duckdb/duckdb/pull/22961)
  change sqllogictest branch (https://redirect.github.com/duckdb/duckdb/pull/22989)

  Unflavored-from: ed05d754e1e5aac4f2ef006a50868a28a55fd2f4

- Update vendored sources to duckdb/duckdb@e421d4ba5685764d33c0209af5d79ebd05981d56.

  Date: 2026-06-02 08:11:37 +0000

  Move `BoundConjunctionExpression`, `BoundConstantExpression`, `BoundExpandedExpression`, `BoundFunctionExpression`, `BoundLambdaExpression`, `BoundLambdaRefExpression`, `BoundOperatorExpression` members to private and use accessors (https://redirect.github.com/duckdb/duckdb/pull/22985)

  R-side fix

- Update vendored sources to duckdb/duckdb@ce4f87dde64a29405eb1b8dbd54d653a5a007104.

  Date: 2026-06-02 06:52:53 +0000

  Make compression availability checks complete (https://redirect.github.com/duckdb/duckdb/pull/20828)
  testing: add new fuzz harness to be consumed by OSS-Fuzz (https://redirect.github.com/duckdb/duckdb/pull/22958)

  Unflavored-from: d86aaf3dd701bf2d0b4c23c0cc4988ffab5d20f0

- Update vendored sources to duckdb/duckdb@0ab53eb3c3d025acb5909c3f4485b47b1a9271ee.

  Date: 2026-06-02 06:38:03 +0000

  Harden create sort key encode/decode (https://redirect.github.com/duckdb/duckdb/pull/22987)

  Unflavored-from: 4c244cf9921569557d5d8ffabbfb4ce65139bdbb

- Update vendored sources to duckdb/duckdb@dc525b4913b7918b6cac57cdc5f6ee3620a73104.

  Date: 2026-06-02 06:17:49 +0000

  Allow `OPERATOR` to be qualified (https://redirect.github.com/duckdb/duckdb/pull/22981)
  Retry all errors in plan cost runner (https://redirect.github.com/duckdb/duckdb/pull/22977)
  Use lint-ci action in duckdb main pipeline (https://redirect.github.com/duckdb/duckdb/pull/22982)

  Unflavored-from: 8a8305e2b58a12e222aafda29eaf44f76b93e0de

- Update vendored sources to duckdb/duckdb@0a8a19486d7177e74df8c886ef78fd4d49fb1f0e.

  Date: 2026-06-01 14:06:35 +0000

  Auto generate transformer part 5 (https://redirect.github.com/duckdb/duckdb/pull/22984)
  Fix OSX release error: 'fmt/format.h' file not found (https://redirect.github.com/duckdb/duckdb/pull/22983)

  Unflavored-from: 6ea16f5fa4adb70524cf7c62b1ba018a82d272f4

- Update vendored sources to duckdb/duckdb@300d0ae838451017df0ceea7d2ff9434ed8b132d.

  Date: 2026-06-01 11:30:35 +0000

  Add default de/serialization for cte_map (https://redirect.github.com/duckdb/duckdb/pull/22784)

  Unflavored-from: fb886c6bd2bc3b063905803e856cfb11588fe8f0

- Update vendored sources to duckdb/duckdb@5013ea6077186dfbfa162a0af62e9d9501475f31.

  Date: 2026-06-01 10:26:57 +0000

  Require parallel access for shared handle in external file cache (https://redirect.github.com/duckdb/duckdb/pull/22979)

  Unflavored-from: 71f3c657f5968598dea79bcf15fc90498f39e575

- Update vendored sources to duckdb/duckdb@e88f952d470a35ffd8264987e7ee470c02fea9c1.

  Date: 2026-06-01 07:08:30 +0000

  Make `BoundAggregateExpression`, `BoundCaseExpression`, `BoundCastExpression`, `BoundColumnRefExpression` members private (https://redirect.github.com/duckdb/duckdb/pull/22964)

  Unflavored-from: 347113f9529ceeb2fc5462ee47f547ce2bc59f99

- Update vendored sources to duckdb/duckdb@bbd990d55458620be783f90da2b3d92ace15c834.

  Date: 2026-05-29 19:04:17 +0000

  Fix SetVectorType for VectorStructBuffer (https://redirect.github.com/duckdb/duckdb/pull/22954)

  Unflavored-from: 93c3cff12ae3860d52e219cacc42f121fb58b58e

- Update vendored sources to duckdb/duckdb@9233f7dbdb94ba632b6388ec22c64546eb6839ae.

  Date: 2026-05-29 13:23:52 +0000

  Fix small-build dictionary emission activation gate (https://redirect.github.com/duckdb/duckdb/pull/22843)

  Unflavored-from: 321c09dfe265012d1c2513473cbdb3fba9292ca5

- Update vendored sources to duckdb/duckdb@d27176517926110763ff1b89de23c9282fec8be9.

  Date: 2026-05-29 08:52:21 +0000

  Fix hang in PartitionedCopyState with regression test (https://redirect.github.com/duckdb/duckdb/pull/22944)
  Verify CLI major version is non-zero on main (https://redirect.github.com/duckdb/duckdb/pull/22935)

  Unflavored-from: eedb379b5eece79a9d68c7d53be44c0e86ecf305

- Update vendored sources to duckdb/duckdb@8abc1bed591b448c32e1a77a9aa700516bd2d217.

  Date: 2026-05-29 07:21:11 +0000

  Implement `CONNECT <attached_db_name>` and `DISCONNECT`, and opt-in in `quack` (https://redirect.github.com/duckdb/duckdb/pull/22878)

  Unflavored-from: 8b982892102516a670a43889d5ca4bdfe447e357

- Update vendored sources to duckdb/duckdb@a504c24a473f758b2e7da812bd76d670bb479673.

  Date: 2026-05-29 09:11:38 +0200

  `LEFT` Join Reordering (https://redirect.github.com/duckdb/duckdb/pull/22929)
  Bump SQLite (https://redirect.github.com/duckdb/duckdb/pull/22945)
  Test Runner: Allow for variable expansion also in "set variable", and allow for grabbing variables from any connection (https://redirect.github.com/duckdb/duckdb/pull/22943)

  Unflavored-from: dbb78b772de70331f925d851e367788919274cba

- Update vendored sources to duckdb/duckdb@7ce0f734aa98a902671f8e038cfd467b9819baae.

  Date: 2026-05-28 20:08:49 +0000

  Make `FunctionExpression`, `LambdaExpression`, `LambdaRefExpression`, `SubqueryExpression`, `WindowExpression` members private (https://redirect.github.com/duckdb/duckdb/pull/22942)

  Unflavored-from: 5c4fe94f4439044920bc7f176df5703c3efd0313

- Update vendored sources to duckdb/duckdb@a966898d86b58ce31dc4955897f8d3f99db1bd83.

  Date: 2026-05-28 16:37:37 +0000

  Support `EXCEPT` syntax (https://redirect.github.com/duckdb/duckdb/pull/22933)

  Unflavored-from: 335276ab02a7ab4f9de3ff3cbaf4c766fac7192e

- Update vendored sources to duckdb/duckdb@3f0e765bee5ad9f0649a6c3b5822768ed612737b.

  Date: 2026-05-28 16:37:11 +0000

  Move enable_optimizer to a generic setting (https://redirect.github.com/duckdb/duckdb/pull/22936)
  Add workflow to mirror open issues labeled PR submitted for more than 10 days (https://redirect.github.com/duckdb/duckdb/pull/22563)

  Unflavored-from: d7b1f4c261aebce6aa9110bd47c9b0d755c39be3

- Update vendored sources to duckdb/duckdb@f92093b6d8d3e33089676f2a637aff9d88156477.

  Date: 2026-05-28 13:46:02 +0000

  Auto generate transformer part 4 (https://redirect.github.com/duckdb/duckdb/pull/22932)

  Unflavored-from: c1d15a5a1287d5f727e7f4616394a8e123c47764

- Update vendored sources to duckdb/duckdb@f6e9d4e4263f71e24f2b5893144b2f8b41d9c26f.

  Date: 2026-05-28 13:37:57 +0000

  Add constant and dictionary optimization to select path in execute function (https://redirect.github.com/duckdb/duckdb/pull/22926)

  Unflavored-from: dd76f9a0c5f80c0b23c4cfe9b3a0645099146ca8

- Update vendored sources to duckdb/duckdb@49d072448b8364cc6aa7cb6ce1477ec59160b446.

  Date: 2026-05-28 13:37:33 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9053: Unbound DECIMAL Literals (https://redirect.github.com/duckdb/duckdb/pull/22919)

  Unflavored-from: 3338233ce807301e0397fa2de2c2765f93315bca

- Update vendored sources to duckdb/duckdb@58c91a0a927157faf5ff583a19c53bff7841b925.

  Date: 2026-05-28 13:10:29 +0000

  Split \_\_comparison function into dedicated functions (https://redirect.github.com/duckdb/duckdb/pull/22934)

  Unflavored-from: 1dfe16bacd0f33967193c0fb126453969ba9f3f4

- Update vendored sources to duckdb/duckdb@1c4dceb062a7b63e99ab72ddacea056239bffb97.

  Date: 2026-05-28 13:04:54 +0000

  Make `ColumnRefExpression`, `ConjunctionExpression`, `OperatorExpression`, `ParameterExpression`, `PositionalReferenceExpression`, `StarExpression` members private (https://redirect.github.com/duckdb/duckdb/pull/22931)

  Unflavored-from: c7414a51ff9cbf4ee8c8962ddd95f826626f5367

- Update vendored sources to duckdb/duckdb@d5c49208e0b17161a57345434b2c65dad23443fb.

  Date: 2026-05-28 12:48:01 +0000

  Improve qualified types support in grammar (https://redirect.github.com/duckdb/duckdb/pull/21784)
  Add support for includes and variables in sqllogic test files (https://redirect.github.com/duckdb/duckdb/pull/22927)
  Remove default ignore error messages in test runner (https://redirect.github.com/duckdb/duckdb/pull/22925)

  Unflavored-from: 00c49187075c07a0a235e11209372a6473252b3f

- Update vendored sources to duckdb/duckdb@0345756e7dc898b367ef189dfcd3eb6929d65771.

  Date: 2026-05-28 08:49:19 +0000

  Add the `RemotePushdownOptimizer` - a pre-bind optimizer that analyzes a parse tree and pushes down SQL directly into remote catalogs (https://redirect.github.com/duckdb/duckdb/pull/22914)
  Retry cost runner (https://redirect.github.com/duckdb/duckdb/pull/22913)

  Unflavored-from: 1885023ae373698d211f0dd10a7d0a66159dad7a

- Update vendored sources to duckdb/duckdb@ce9ef57838ab9b87cd9b3d86634e1d90662c597b.

  Date: 2026-05-28 08:03:10 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8953: Uncorrelated STRUCT Sizes (https://redirect.github.com/duckdb/duckdb/pull/22918)
  Update Labs URL (https://redirect.github.com/duckdb/duckdb/pull/22909)
  Change paths-ignore to paths in CI workflows (https://redirect.github.com/duckdb/duckdb/pull/22916)

  Unflavored-from: 8472d7b29ba6f3836c2c377a5523f0ecf47be949

- Update vendored sources to duckdb/duckdb@1ce496bb2e3e20ae1299e0d75f1d4a3b33cc3332.

  Date: 2026-05-28 07:07:16 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9307: Window Batching (https://redirect.github.com/duckdb/duckdb/pull/22794)

  Unflavored-from: 35a28e1446889f56fcc4a0ad1af3170af6afb564

- Update vendored sources to duckdb/duckdb@811109f4448b35e6252bb45e0af545e4c655ae23.

  Date: 2026-05-27 16:57:02 +0000

  Make `CastExpression` / `CollateExpression` members private (https://redirect.github.com/duckdb/duckdb/pull/22917)

  Unflavored-from: f6c5c421fe5ab3afa50ef3833904310ba440d9e4

- Update vendored sources to duckdb/duckdb@b15e38cbd5554dc28e082d1dbda963626cdf6413.

  Date: 2026-05-27 15:26:44 +0000

  remove some stray-but-consequential duckdb.h includes (https://redirect.github.com/duckdb/duckdb/pull/22902)

  Unflavored-from: 50efc1d64079260e76d3394f839f50334c3d3dc8

- Update vendored sources to duckdb/duckdb@d535c203a92fb5be4cdf4225c2b12f971ebae357.

  Date: 2026-05-27 17:03:19 +0200

  Add AFTER DELETE trigger with REFERENCING OLD TABLE AS support (https://redirect.github.com/duckdb/duckdb/pull/22912)

  Unflavored-from: cc4bf0187e224faa76d2c791c059f91f282d81aa

- Update vendored sources to duckdb/duckdb@915de76dc3bf94c8d4211f382757e19b64c67694.

  Date: 2026-05-27 14:25:20 +0000

  Use atomic for CatalogEntry-\>parent to fix data race (https://redirect.github.com/duckdb/duckdb/pull/22910)

  Unflavored-from: b4d76557c7f178cfd09b21579a2e24cd82597dcb

- Update vendored sources to duckdb/duckdb@8ca82ad60b5015e620337cbf9eddc79c64af098e.

  Date: 2026-05-27 13:00:48 +0000

  Make `CaseExpression` members private and move behind getters (https://redirect.github.com/duckdb/duckdb/pull/22901)

  Unflavored-from: 4b894e007cea4800559ba32321cc4f498263e0d4

- Update vendored sources to duckdb/duckdb@d3722ec772c390fa56bcb4bd50e0f404b7d0f8ae.

  Date: 2026-05-27 14:59:36 +0200

  Pass INPUT_TYPE and STATE_TYPE to fix windows compilation (https://redirect.github.com/duckdb/duckdb/pull/22887)
  Mark json_deserialize_sql as fallible (https://redirect.github.com/duckdb/duckdb/pull/22900)

  Unflavored-from: a6453eb9a4413a36fdace82f02bc0368e19c1cec

- Update vendored sources to duckdb/duckdb@e598697dacf4acaea0dd52dc0a6b931dc76f78ce.

  Date: 2026-05-27 10:51:43 +0000

  Allow substring with only `for` or `from` (https://redirect.github.com/duckdb/duckdb/pull/22891)
  Add threadsan config and update test loop counts (https://redirect.github.com/duckdb/duckdb/pull/22908)
  Add test stabilization reruns to run_tests (https://redirect.github.com/duckdb/duckdb/pull/22904)
  Bump vss extension and remove applied patches (https://redirect.github.com/duckdb/duckdb/pull/22903)

  Unflavored-from: b6e2a7a7b1d52c393b8ace06c23b27ec54801802

- Update vendored sources to duckdb/duckdb@a73d9d9df28b61bdcc15adbfe38a5a0cad138321.

  Date: 2026-05-27 09:31:58 +0000

  Add AFTER INSERT trigger with REFERENCING NEW TABLE AS support (https://redirect.github.com/duckdb/duckdb/pull/22759)

  Unflavored-from: 3eedf97130d87cef1ef5d1c0e6be254ea3bfd2d1

- Update vendored sources to duckdb/duckdb@1b8a881973d91aabba5205bfa2b93fe319025ef4.

  Date: 2026-05-27 09:25:37 +0000

  Make pow IEEE 754 compliant (https://redirect.github.com/duckdb/duckdb/pull/22753)

  Unflavored-from: 096f1eb6cadee3943f928775a26de1b51b93e2ee

- Update vendored sources to duckdb/duckdb@847e85c91eae5c40f996f66af345367daffb06a0.

  Date: 2026-05-27 08:54:38 +0000

  pb/few-groups-aggr-opt-followup (https://redirect.github.com/duckdb/duckdb/pull/22671)

  Unflavored-from: d58ee3c07018773b7208c633858936ca410f5f1f

- Update vendored sources to duckdb/duckdb@cf522d4a3a6c8f1635028ae0622f755db8cbe86a.

  Date: 2026-05-27 07:48:18 +0000

  Fix forward declaration: unqiue_ptr has constexpr dtor after 23 (https://redirect.github.com/duckdb/duckdb/pull/22895)

  Unflavored-from: 84f2119624a88b334d6271ed5882075be0af4feb

- Update vendored sources to duckdb/duckdb@6b5a80b7728c8c3134582eb641f03446f434059e.

  Date: 2026-05-27 07:48:05 +0000

  Fix out-of-bounds write in decode ignore mode (https://redirect.github.com/duckdb/duckdb/pull/22885)

  Unflavored-from: d29de5aa2e099a2ad0c58d7261d3609a4a03907d

- Update vendored sources to duckdb/duckdb@90ff388ec54fb8d1307567b48cba701c2e5696f4.

  Date: 2026-05-27 07:07:43 +0000

  Fix decimal to floating point rounding (https://redirect.github.com/duckdb/duckdb/pull/22874)

  Unflavored-from: cb58da0ef4e3e4fa691a8a1d77c2ec4cd0b58d5c

- Update vendored sources to duckdb/duckdb@adf0c6ac72d7c675faeb19ba6c6619555e45a2e1.

  Date: 2026-05-27 06:09:52 +0000

  Fix miscount of pinned row handles and allocator row blocks (https://redirect.github.com/duckdb/duckdb/pull/22832)
  Test runner: allow to run without changing HOME (https://redirect.github.com/duckdb/duckdb/pull/22854)

  Unflavored-from: 29a3de6daf789ec812a5ca44238352761e7776ef

- Update vendored sources to duckdb/duckdb@c32c8fa63aa314c8454b305a8dcc4508a4faa92e.

  Date: 2026-05-27 05:58:45 +0000

  Support empty string casts to BIT (https://redirect.github.com/duckdb/duckdb/pull/22888)

  Unflavored-from: c4275a7d9a2e57f17dfb2ef96e630eefdfc75c25

- Update vendored sources to duckdb/duckdb@74015770eb03f134d4a0b3074fd093cb7547e971.

  Date: 2026-05-27 05:58:19 +0000

  Fix Parquet TIMETZ metadata (https://redirect.github.com/duckdb/duckdb/pull/22886)

  Unflavored-from: fd1f1546bda3749feb2a809d293c6fedfdc3e0df

- Update vendored sources to duckdb/duckdb@4be2c83e41136b98075646bca3a123efde60cb7a.

  Date: 2026-05-27 05:51:09 +0000

  `COMMENT ON` aliased view column (https://redirect.github.com/duckdb/duckdb/pull/22881)

  Unflavored-from: c71cfd7118c82866c2d1724ee7437cbfa27e2d2c

- Update vendored sources to duckdb/duckdb@83b2a2aff789410b7410797dc78ad73d6da209f7.

  Date: 2026-05-27 05:42:22 +0000

  Auto generate util functions (`Copy`, `Equals`, `Hash`, `Iterate`) for ParsedExpressions (https://redirect.github.com/duckdb/duckdb/pull/22880)
  Remove build_extensions and no longer used script (https://redirect.github.com/duckdb/duckdb/pull/22876)

  Unflavored-from: 061be979c122602980cba8348df876141d8150c3

- Update vendored sources to duckdb/duckdb@fd9677916354b934ad4923ab671e443abe1ad941.

  Date: 2026-05-26 12:25:32 +0000

  Reject MERGE clauses that follow an unconditional clause of the same condition (https://redirect.github.com/duckdb/duckdb/pull/22839)

  Unflavored-from: 8334ccda62746d4e2b86c12ab0c2d4830d9ce286

- Update vendored sources to duckdb/duckdb@7c55bc1be322ff492895b1b5de1d9ccecacc0744.

  Date: 2026-05-26 11:54:46 +0000

  Add support for large integer values for CSV (https://redirect.github.com/duckdb/duckdb/pull/22802)
  Re-enable all explicitly disabled tests on musl (https://redirect.github.com/duckdb/duckdb/pull/22877)

  Unflavored-from: 18825d52ffae18b0293b5f590cbc98f01c78d464

- Update vendored sources to duckdb/duckdb@28a1d85be662f29ac67e242dc70f65fb66b3e537.

  Date: 2026-05-26 10:33:57 +0000

  Fix MERGE condition binding for row alias comparisons (https://redirect.github.com/duckdb/duckdb/pull/22459)

  Unflavored-from: b754b29d081670efb8c077155f86e6d22cf055cb

- Update vendored sources to duckdb/duckdb@ba7f4f33ca7cdde6d46a52d4cd1acb32c83a27dc.

  Date: 2026-05-26 09:27:47 +0000

  Bump default storage to `v2.0.0` (https://redirect.github.com/duckdb/duckdb/pull/22875)
  Bump HTTPFS (https://redirect.github.com/duckdb/duckdb/pull/22833)
  Remove unused third_party/snowball (https://redirect.github.com/duckdb/duckdb/pull/22772)

  Unflavored-from: ee78b8e39fc9d8375f716d4b77780bab8cdf68f2

- Update vendored sources to duckdb/duckdb@2c29839e715b117cddfb1e860ca058c30351be1b.

  Date: 2026-05-26 08:16:22 +0000

  Fix jemalloc packaging for JDBC/ODBC (https://redirect.github.com/duckdb/duckdb/pull/22811)
  Fix JSON create functions for VARIANT input (https://redirect.github.com/duckdb/duckdb/pull/22873)
  Add quack to issue template (https://redirect.github.com/duckdb/duckdb/pull/22842)
  Remove unused delta files and link to duckdb-delta repository (https://redirect.github.com/duckdb/duckdb/pull/22735)

  Folds in the `scripts/rconfigure.py` fix that drops the bundled jemalloc
  sources from the object list.
  Upstream started emitting the jemalloc tree into the source list here
  (https://redirect.github.com/duckdb/duckdb/pull/22811),
  and the R package never enables jemalloc,
  so the tree both fails to compile and fails to link.
  `main-dev` carries the same fix, folded into its own vendor commit for this
  upstream commit; it has not been forward-ported to the package `main` yet.

  Unflavored-from: 86bdf055aefff2e35a0f28971ef7206e7ea5874e

- Update vendored sources to duckdb/duckdb@2ed23562084dcfa862f7e861978aceb1de1fb840.

  Date: 2026-05-26 07:53:21 +0000

  Add copy argument validation (https://redirect.github.com/duckdb/duckdb/pull/22870)

  Unflavored-from: 6205b598bfe52d136e42aa190f6e5e97b1afd020

- Update vendored sources to duckdb/duckdb@932e831ce75bd4b6edd1d9e1f9136da6f52bf634.

  Date: 2026-05-22 21:20:41 +0000

  Make `GetSQLValueFunction` pluggable through a planner extension (https://redirect.github.com/duckdb/duckdb/pull/22840)

  Unflavored-from: 230918e8f1600251caa5e541d51c7b4242860cf7

- Update vendored sources to duckdb/duckdb@80554e9433d6dd2dd3808b56f9898246fc25e365.

  Date: 2026-05-22 16:14:20 +0000

  Parquet Prefetch Strategy (https://redirect.github.com/duckdb/duckdb/pull/22497)

  Unflavored-from: 082fa931e7759001b6116263cbbb7c6f94f72ecc

- Update vendored sources to duckdb/duckdb@bf7aea41c20e012ebab6d176df13ecd61b53785a.

  Date: 2026-05-22 15:00:05 +0000

  Initial implementation of `variant_keys` processing function (https://redirect.github.com/duckdb/duckdb/pull/22724)

  Unflavored-from: ee949f8c8f4cacef6fd9029c81b86434b246a4fd

- Update vendored sources to duckdb/duckdb@ac9ee65709843e56db9960835d54a7265e494bfd.

  Date: 2026-05-22 13:03:31 +0000

  Allow collation for VARCHAR alias column types (e.g. CHAR, BPCHAR, STRING, TEXT) (https://redirect.github.com/duckdb/duckdb/pull/22834)

  Unflavored-from: e1d86f3311a7c8a23ef64ab1a3c31cdb4b1f2311

- Update vendored sources to duckdb/duckdb@1ec6c21c238e10e401f5c12f67c50bf4b7e92017.

  Date: 2026-05-22 11:51:58 +0000

  Explicitly set an extension schema (https://redirect.github.com/duckdb/duckdb/pull/22480)

  Unflavored-from: 4c29889ea8289c8f95fe4f9c00fac8bf95bc0bce

- Update vendored sources to duckdb/duckdb@b5c60cccb2707cae5ec6087933f56fa5ee2e3926.

  Date: 2026-05-22 10:31:15 +0000

  Parallelize pragma_storage_info, and move block scanning to the physical execution (https://redirect.github.com/duckdb/duckdb/pull/22778)

  Unflavored-from: 3ce03447ca9e26f5e98e0f1030995d9c625c3051

- Update vendored sources to duckdb/duckdb@ca6e0a1c7b97dffec162192b2f0812313c073956.

  Date: 2026-05-22 08:29:37 +0000

  \[Dev\] Fix the case where `PhysicalCopyToFile` has no child operators (https://redirect.github.com/duckdb/duckdb/pull/22814)

  Unflavored-from: 978616351b9bf6f7155193fdf481f5d89fb2f320

- Update vendored sources to duckdb/duckdb@4002ad86e56c0dde081e019e53d5295aaba18a4e.

  Date: 2026-05-22 08:13:20 +0000

  Auto generate transformer (Part 3) (https://redirect.github.com/duckdb/duckdb/pull/22821)

  Unflavored-from: 165797ef31f00bbaec3d6981d03a885d67c334a8

- Update vendored sources to duckdb/duckdb@9474cf3e544179deae5d4eaddba6d6b9a8ae063f.

  Date: 2026-05-22 08:07:34 +0000

  Don't allow identifiers to start with numbers (https://redirect.github.com/duckdb/duckdb/pull/22803)

  Unflavored-from: d39bbcd16bcad1d94cf44105fba759725e3503be

- Update vendored sources to duckdb/duckdb@9bb775ced78b731fc388eb0fbb12e0d1477240aa.

  Date: 2026-05-22 08:06:43 +0000

  Throw error if last token is unterminated string or quoted identifier (https://redirect.github.com/duckdb/duckdb/pull/22805)
  adjust CI build filter from 500:1 -\> 50:1 lines emitted (https://redirect.github.com/duckdb/duckdb/pull/22807)
  Fix some issues found on the (nightly) main CI run (https://redirect.github.com/duckdb/duckdb/pull/22812)
  Fix NULL format option on json copy (https://redirect.github.com/duckdb/duckdb/pull/22831)

  Unflavored-from: 9eeaf35d6d80544c9b527b7aad8a908d7bfa3682

- Update vendored sources to duckdb/duckdb@dc9dea3e73786bc706b5e090afa9772677a4b8fc.

  Date: 2026-05-21 14:05:12 +0000

  Optimize TryAddDictionaryGroups (https://redirect.github.com/duckdb/duckdb/pull/22813)

  Unflavored-from: c94d6fd58e2e088bfa508740e6418cc41ad30d67

- Update vendored sources to duckdb/duckdb@2f774b74754fe44c895ae80c2254b79eac0f3f68.

  Date: 2026-05-21 13:32:39 +0000

  Support long paths on Windows (https://redirect.github.com/duckdb/duckdb/pull/20983)
  Run more core extensions with sanitizers in CI (https://redirect.github.com/duckdb/duckdb/pull/22689)

  Unflavored-from: 504bf85c73f8c809042fedfcfa163543b9d7c2cb

- Update vendored sources to duckdb/duckdb@05bc1b711c98c5ecef797cf5538e21e543e74f34.

  Date: 2026-05-21 12:42:16 +0000

  Unify storage version and serialization version (https://redirect.github.com/duckdb/duckdb/pull/22754)
  Use detect-runners action in prepare (https://redirect.github.com/duckdb/duckdb/pull/22809)

  Unflavored-from: 1a25b2307f8e412ac7786f7aceb477d30db196c0

- Update vendored sources to duckdb/duckdb@59c06fb868e0bb5efbf6750b5be1fe3f36103a00.

  Date: 2026-05-21 12:31:43 +0000

  Try to INSTALL and LOAD for test auto-load mode == none (https://redirect.github.com/duckdb/duckdb/pull/22498)

  Unflavored-from: ae344fd1a4cef0ac8c95ef08b4beca728b29fe8a

- Update vendored sources to duckdb/duckdb@9cbdcaaa41c439df8c434541b191841886d1738b.

  Date: 2026-05-21 08:50:05 +0000

  Remove redundant part lock guard for sort_key_payload_state (https://redirect.github.com/duckdb/duckdb/pull/22801)

  Unflavored-from: 1dcccf912dc74de1c5a3ce753b95c9dde733295b

- Update vendored sources to duckdb/duckdb@eb90869f574e7ab88099bb79a5b61a0460d83c2a.

  Date: 2026-05-21 05:38:37 +0000

  Add compressed probing hash join (https://redirect.github.com/duckdb/duckdb/pull/22789)
  Upgrade to windows-2025-vs2026 explicitly (https://redirect.github.com/duckdb/duckdb/pull/22763)

  Unflavored-from: 5504017bf83abefce8a2dcb9961725f0bbf3b8f5

- Update vendored sources to duckdb/duckdb@40103dc2cd6dc9b559d4f2ee6de2c1b3e4b39bcd.

  Date: 2026-05-20 15:37:40 +0000

  \[Dev\] Fix behavior for the `force_full_download` open-file-info option, with the new workings of the ExternalFileCache (https://redirect.github.com/duckdb/duckdb/pull/22787)

  Unflavored-from: 65af6cf827be58b989e2bf596d9ddae49e258dfc

- Update vendored sources to duckdb/duckdb@a72d7fa927cc188f6c92333eacdf58cf061dd2f9.

  Date: 2026-05-20 18:03:00 +0200

  Merge `v1.5-variegata` into main (https://redirect.github.com/duckdb/duckdb/pull/22751)

  Unflavored-from: c5a86f8acf1096870904d8dd23aba06145c7b6da

- Update vendored sources to duckdb/duckdb@0df3448588c64dccaab3ce8c3198d83b371f5dbb.

  Date: 2026-05-20 13:46:15 +0000

  Make CTE inlining of correlated CTEs more stable (https://redirect.github.com/duckdb/duckdb/pull/22783)
  Retry clangd error 'ValueError: Invalid header end' (https://redirect.github.com/duckdb/duckdb/pull/22785)

  Unflavored-from: 2e10a019e73349df67235c1f4ed35119ec5bb598

- Update vendored sources to duckdb/duckdb@f7129c44f090e6a3ff7c21b688d97036b70c4c92.

  Date: 2026-05-20 13:10:06 +0000

  Support qualified drop schema and drop index with reserved keywords (https://redirect.github.com/duckdb/duckdb/pull/22786)
  Bump spatial extension and remove applied patches (https://redirect.github.com/duckdb/duckdb/pull/22777)
  Keep log group open on detected regression (https://redirect.github.com/duckdb/duckdb/pull/22781)
  Print one-line test summary after log group (https://redirect.github.com/duckdb/duckdb/pull/22780)

  Unflavored-from: 5facc1038268bfcfab7cb2857aa3edc01c49a80b

- Update vendored sources to duckdb/duckdb@61fa2628d3b77b65eb3765bbf40a5f991395a04e.

  Date: 2026-05-20 08:43:22 +0000

  Refactor / rework how metrics are gathered and emitted in the `QueryProfiler` (https://redirect.github.com/duckdb/duckdb/pull/22765)

  Unflavored-from: b5e24f8fb1dbd7da57289e10241ab5aab4ae31f7

- Update vendored sources to duckdb/duckdb@a38741d539f2ccc060fbb3906d7a0a1246934e23.

  Date: 2026-05-20 08:24:11 +0000

  Fix tablefilter unification issues (https://redirect.github.com/duckdb/duckdb/pull/22645)

  Unflavored-from: 2fdfd7d2b0c4eed6a444fc5c6817c8674e9adab9

- Update vendored sources to duckdb/duckdb@b6bf617a1f514aa3bd754aa12f19500e5496e485.

  Date: 2026-05-19 20:04:05 +0000

  Follow-up fix: use CheckExecuteCount instead of getting count of non-const member (https://redirect.github.com/duckdb/duckdb/pull/22770)
  Add codeql jobs for c++, python and actions to NightlyTests.yml (https://redirect.github.com/duckdb/duckdb/pull/22650)

  Unflavored-from: ac37eea8fd7ba4626223a7f88c706a5c603e7cd8

- Update vendored sources to duckdb/duckdb@432ebc264453eb869296f4fb57e6f7d5d27403a6.

  Date: 2026-05-19 14:18:26 +0000

  Column Segment Clean-up (https://redirect.github.com/duckdb/duckdb/pull/22760)

  Unflavored-from: e8c8ea693acbc906bcecda1c0e2134b310ff9c64

- Update vendored sources to duckdb/duckdb@798ae1a0625aeadbbddacf2dbeafbf1139dbf999.

  Date: 2026-05-19 13:38:55 +0000

  Auto generate transformer (Part 2/N) (https://redirect.github.com/duckdb/duckdb/pull/22756)

  Unflavored-from: 3960822ecc37226a76c80dee4db107c81761ee93

- Update vendored sources to duckdb/duckdb@262d358413e1536e971c1c9c624bc691917dd217.

  Date: 2026-05-19 13:06:45 +0000

  Break early when getting cgroupv1 CPU entry (https://redirect.github.com/duckdb/duckdb/pull/22746)

  Unflavored-from: 2a02c0772677114038843ab18c499ff6e9980e06

- Update vendored sources to duckdb/duckdb@c06588b9d82b57e955001028a10a38b6588aae68.

  Date: 2026-05-19 11:44:17 +0000

  `CompressedMaterialization` casts (https://redirect.github.com/duckdb/duckdb/pull/22755)

  Unflavored-from: 20dd7f5f7b9988e40bd4ca8fffe091501ec8a2be

- Update vendored sources to duckdb/duckdb@9995bd99230ac7f60cc6fd3e27a90f2e006175cd.

  Date: 2026-05-19 07:17:36 +0000

  Column-level metadata loading and serialization (https://redirect.github.com/duckdb/duckdb/pull/22333)

  Unflavored-from: c7d70b0f8beb004d2848fe1489b1d42808a4d0de

- Update vendored sources to duckdb/duckdb@6683916b150613135102898a6a54bedbc39b054c.

  Date: 2026-05-19 06:37:50 +0000

  Add `CONNECT` / `DISCONNECT` statement scaffolding (https://redirect.github.com/duckdb/duckdb/pull/22732)

  Unflavored-from: 55029cb7e54c9025e2f5c803724d24556385bfab

- Update vendored sources to duckdb/duckdb@e1420a3c2529996d0eccb93d550648268b64406c.

  Date: 2026-05-19 05:56:50 +0000

  Close FD on fcntl error (https://redirect.github.com/duckdb/duckdb/pull/22747)

  Unflavored-from: a54302319e6c8821b4bdc453de8f60ac2c9e78be

- Update vendored sources to duckdb/duckdb@88a0b62d40f75bdc59127aea735768cb25f1cb3a.

  Date: 2026-05-19 05:55:34 +0000

  Be careful at midnight (https://redirect.github.com/duckdb/duckdb/pull/22678)

  Unflavored-from: e7fc18ed84f47a1c5d68c4c2b293747090e06e4c

- Update vendored sources to duckdb/duckdb@30b7c8ca2c707a4a172dd5e41a2831059c7ec5de.

  Date: 2026-05-18 19:14:08 +0000

  Fix numeric stats serde (https://redirect.github.com/duckdb/duckdb/pull/22684)

  Unflavored-from: 564e877334d3c2f32d79b515d85310050531d418

- Update vendored sources to duckdb/duckdb@d01333a71fcc51a20941c1168a98aea436c0958d.

  Date: 2026-05-18 16:32:59 +0000

  Vector API: Remove `idx_t count` from many functions, and pass in `const Vector &` where possible (https://redirect.github.com/duckdb/duckdb/pull/22695)
  Bump delta (https://redirect.github.com/duckdb/duckdb/pull/22739)

  Unflavored-from: 6c948698c393c3697e2ac73cc9ac89e23d32b9f5

- Update vendored sources to duckdb/duckdb@e96d1117829db4e313a63e4b91e4eab0d1cb27fe.

  Date: 2026-05-18 13:40:55 +0000

  Optimizer: Rewrite contains \[large list\] to a hash join (https://redirect.github.com/duckdb/duckdb/pull/22525)
  Unflavored-from: 67069a13af1a7141e4ff251e57876587957009a5

- Update vendored sources to duckdb/duckdb@ec5d4ce5ada0c13e39c726fa5a101d6801919b8c.

  Date: 2026-05-18 13:40:41 +0000

  Fix/eviction queue purge correctness (https://redirect.github.com/duckdb/duckdb/pull/22680)

  R-side fix:

  The rewritten `EvictionQueue::PurgeIteration` enqueues in bulk through an
  explicit producer token,
  and GCC now inlines `ExplicitProducer::enqueue_bulk` into it.
  The explicit-token enqueue paths in the vendored concurrent queue
  dereference `token.producer` without a null check,
  unlike their implicit-producer siblings,
  so the compiler cannot prove the atomic object is not at address zero
  and emits a false-positive

  atomic_base.h: warning: '... \_\_atomic_load_8(...)' writing 8 bytes
  into a region of size 0 overflows the destination \[-Wstringop-overflow=\]

  which `R CMD check` reports as a significant warning and the `check` gate
  turns into a failure.

  Add the same null guard the implicit-producer overloads already use.
  This fixes the warning at the source --
  no diagnostic pragma and no `-Wno-...` override, both of which CRAN
  discourages --
  and makes the explicit-token enqueue paths as robust as the rest of the
  queue API.
  Added as `patch/0034` so vendoring reapplies it,
  and applied to the vendored tree to keep the committed sources
  consistent.

  Adapted from `claude/r-cmd-check-atomic-overflow-2pm38d`.

  Unflavored-from: 846857e1a23ae09230ec7230b9adb28a6a32a55b

- Update vendored sources to duckdb/duckdb@93f211149b60c957c8e1faef6e494f99a8272609.

  Date: 2026-05-18 13:40:25 +0000

  Fix adaptive segment allocation resetting after checkpoint (https://redirect.github.com/duckdb/duckdb/pull/22725)

  Unflavored-from: 8ce7d6c93ad070d091a4ec2610d1fa90abcf4834

- Update vendored sources to duckdb/duckdb@402e3f93d1a11dd6412d283bc0ba000262c87752.

  Date: 2026-05-18 13:40:08 +0000

  Clean-up Compression methods: Move a lot of duplicated code to `CompressionState` / `StandardCompressionState`, and generalize `StatsWriter` (https://redirect.github.com/duckdb/duckdb/pull/22721)

  Unflavored-from: ed6126b5fef6eaf920d4215a81da5c929a8c63af

- Update vendored sources to duckdb/duckdb@87d9bc361bb0a8fa39cc750e1a0210dde13b1865.

  Date: 2026-05-18 13:39:50 +0000

  Compact UpdateInfo allocation to reduce transaction memory (https://redirect.github.com/duckdb/duckdb/pull/22702)

  Unflavored-from: a9ed5a203662776ecd61b7682c8f9949482ee2c3

- Update vendored sources to duckdb/duckdb@3527a98456f954fc970e6a070faa9dea4c034341.

  Date: 2026-05-18 09:27:29 +0000

  Push partial aggregates below joins (https://redirect.github.com/duckdb/duckdb/pull/22572)

  Unflavored-from: 448bec39732e4bad9b3131ef83cb763203404bac

- Update vendored sources to duckdb/duckdb@2a9dda051ad43e2b96f9e5e485c41b9f7dc18201.

  Date: 2026-05-18 07:15:10 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/7613: IEJoin MARK Joins (https://redirect.github.com/duckdb/duckdb/pull/22675)

  Unflavored-from: ac82a99de9a4303297c56b5151c9d1820cf1dc00

- Update vendored sources to duckdb/duckdb@a51c47e01800cf5698b755ec17f752507920b876.

  Date: 2026-05-18 07:03:05 +0000

  Rework expression rewriter to make it bottom-up and iterative (https://redirect.github.com/duckdb/duckdb/pull/22626)

  Unflavored-from: 8e17a8bbbcf6c030c6c4ce1ed6988f73926246e5

- Update vendored sources to duckdb/duckdb@c1c1eb029d6500300c350e8e672f2c1238140b5a.

  Date: 2026-05-17 16:47:01 +0000

  Improve IsValid decision for parquet metadata cache (https://redirect.github.com/duckdb/duckdb/pull/22705)

  Unflavored-from: c8270d31c49345be4784842ab42f04384e5b5297

- Update vendored sources to duckdb/duckdb@c4e422bbe4107620764addc1d316a3170d4c2426.

  Date: 2026-05-17 14:43:12 +0000

  Rework / Extend `StringStats` in DuckDB Storage Layer (https://redirect.github.com/duckdb/duckdb/pull/22692)

  Unflavored-from: 8b57fe693c10d9cf05f11777b87ca0dd9c64e630

- Update vendored sources to duckdb/duckdb@76232a4907c8439098791cc9660d6d9e9398f1e1.

  Date: 2026-05-16 11:37:05 +0000

  Remove checked_array_iterator from third_party/fmt (https://redirect.github.com/duckdb/duckdb/pull/22706)

  Unflavored-from: 906f21dbe3beea32778c396a98fe678b6ee5b7b0

- Update vendored sources to duckdb/duckdb@366f83377a86a6b43411813ada047161f3aa6b4a.

  Date: 2026-05-16 10:37:38 +0000

  Make members of `BetweenExpression` private (https://redirect.github.com/duckdb/duckdb/pull/22707)

  Unflavored-from: 25fe842c0e8e278e77c28a32bf6882f92f2c9ae7

- Update vendored sources to duckdb/duckdb@71e017aaeedad2fbe91dd1f56bff6500bd21e2ee.

  Date: 2026-05-16 09:13:02 +0000

  Fix parquet stats for enum types (https://redirect.github.com/duckdb/duckdb/pull/22658)
  Add make targets to run test configs easily (https://redirect.github.com/duckdb/duckdb/pull/22696)
  Bump ducklake extension and remove merged patches (https://redirect.github.com/duckdb/duckdb/pull/22699)

  Unflavored-from: 7508f783cbe7c92dec6302b9259bafc94c8607ed

- Update vendored sources to duckdb/duckdb@366bf3e893983922e9e6b6864dce2a03fa2aca22.

  Date: 2026-05-15 16:47:41 +0000

  `OVERLAY()` string function (https://redirect.github.com/duckdb/duckdb/pull/22456)

  Unflavored-from: 37a25f8b3006137d5cc0aeef6468d23bc122c4d6

- Update vendored sources to duckdb/duckdb@594b65d1ad58793ce83b27959c6a780ced2221c7.

  Date: 2026-05-15 15:20:49 +0000

  Postgres Compatibility For SETOF Returning Functions (https://redirect.github.com/duckdb/duckdb/pull/22694)
  Parse mode skip/require reasons once and summarize (https://redirect.github.com/duckdb/duckdb/pull/22681)

  Unflavored-from: 9944796d37f1a7a22ac775ef798e9bd13391e88a

- Update vendored sources to duckdb/duckdb@ccebfa6092c01d5af8c45e6a985250c76eb7b22b.

  Date: 2026-05-15 11:21:03 +0000

  Flip lambda syntax default: `x -> x + 1` now gives an error by default (https://redirect.github.com/duckdb/duckdb/pull/22682)
  Remove unused workflow, fix rclone command and bwc test parser (https://redirect.github.com/duckdb/duckdb/pull/22685)

  Unflavored-from: a4196c44b7abd2af5f5a2926183fbe5233660545

- Update vendored sources to duckdb/duckdb@60e81d3a94a8b4b1429a1182f4787e1ef1244053.

  Date: 2026-05-15 08:16:14 +0000

  Optimize Recursive CTE Performance (https://redirect.github.com/duckdb/duckdb/pull/22211)

  Unflavored-from: 024b8603d8f0e225d73563aef19b4c41b26e1972

- Update vendored sources to duckdb/duckdb@6dd33fcd90f633872340322a9d2401ea826eab56.

  Date: 2026-05-15 07:42:25 +0000

  Parquet ApplyPendingSkips really skip decode (https://redirect.github.com/duckdb/duckdb/pull/22664)
  No typo fix PRs please (https://redirect.github.com/duckdb/duckdb/pull/22668)

  Unflavored-from: 9e046bfa59a059f4e6f9047ad0251455117135cd

- Update vendored sources to duckdb/duckdb@2cda70b1eb522ea29831904613b29a7eda1f333e.

  Date: 2026-05-14 11:17:21 +0000

  Follow-up fixes to StringStatsRework (https://redirect.github.com/duckdb/duckdb/pull/22665)

  Unflavored-from: 62961f6fc2e379c9618c200b304ba8aaf078ad69

- Update vendored sources to duckdb/duckdb@389ca4e74ac8cbd636b18e06932442ce159ad62f.

  Date: 2026-05-14 09:54:22 +0000

  Rework `StringStats` to be more independent from the string stats we use in storage, and introduce `StringStatsType` which signifies if stats are truncated (https://redirect.github.com/duckdb/duckdb/pull/22649)

  Unflavored-from: 92c42cd7623c44db8ae51c291dde726e3357645e

- Update vendored sources to duckdb/duckdb@f3ac21506bfd3c2b2c2243eb692ea8180f7bc773.

  Date: 2026-05-14 08:41:49 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9197: Timestamp Cleanup (https://redirect.github.com/duckdb/duckdb/pull/22604)

  Unflavored-from: c7d6579a46f67bf0bc7494116dc2ebab6558e437

- Update vendored sources to duckdb/duckdb@2957fd1e3fd608a6b03fd63795aea3cb7abad40f.

  Date: 2026-05-14 07:03:37 +0000

  Partial aggregate precomputation from row group statistics (https://redirect.github.com/duckdb/duckdb/pull/21831)
  Add optional reason to 'mode skip' in tests (https://redirect.github.com/duckdb/duckdb/pull/22625)

  Unflavored-from: dffb91920746c9a7d83684ec0c0b91347146665d

- Update vendored sources to duckdb/duckdb@487b830a526a0d359264916ef03ece579a61ea54.

  Date: 2026-05-13 14:05:11 +0000

  Partitioned/Sorted writes (https://redirect.github.com/duckdb/duckdb/pull/22620)
  Add member label to PR (https://redirect.github.com/duckdb/duckdb/pull/22643)

  Unflavored-from: 1fcca275a6ae55283dff65589e69bc60f32ca967

- Update vendored sources to duckdb/duckdb@bb47248ae3b13fa822ec0c7e9d8e357e691d0294.

  Date: 2026-05-13 13:18:02 +0000

  Skip colref projection pullup over LOGICAL_DISTINCT (https://redirect.github.com/duckdb/duckdb/pull/22606)

  Unflavored-from: 3741ad6dcdba08c00aa1fd063f18e97f746d3836

- Update vendored sources to duckdb/duckdb@24beac617063a0a521f594ac24aa4252dff6aec5.

  Date: 2026-05-13 11:59:56 +0000

  Enable compressed materialization for grouping sets (https://redirect.github.com/duckdb/duckdb/pull/22285)

  Unflavored-from: 0552e8d1ac915fbac5937e96027b78cf08b4b06a

- Update vendored sources to duckdb/duckdb@c518cf52c2ce2b0742cfee512a2df9250602bbff.

  Date: 2026-05-13 11:59:22 +0000

  Prefer filtered build sides for join filter pushdown (https://redirect.github.com/duckdb/duckdb/pull/22298)

  Unflavored-from: 1c5356710f6ee2abf6737451fb35469b74a63a0f

- Update vendored sources to duckdb/duckdb@997c2427680e7c0981e312743d27a6c61785ac9e.

  Date: 2026-05-13 10:45:27 +0000

  Clustered Aggregation (https://redirect.github.com/duckdb/duckdb/pull/22230)

  Unflavored-from: af4b38ab8478dc486993cc9da24a7db3b588a947

- Update vendored sources to duckdb/duckdb@88b5dbcea4b00eebe9743b0b0717878272250c18.

  Date: 2026-05-13 10:21:49 +0000

  Unify remaining TableFilters with ExpressionFilter (https://redirect.github.com/duckdb/duckdb/pull/22617)
  Show skipped test reasons in test runner (https://redirect.github.com/duckdb/duckdb/pull/22618)
  Omit third_party/ and platform binary for EXTENSION_CONFIG_BUILD=true (https://redirect.github.com/duckdb/duckdb/pull/22615)
  Speed up arrow test by directly using relations to query (https://redirect.github.com/duckdb/duckdb/pull/22599)

  R-side fix

- Update vendored sources to duckdb/duckdb@8c97808ba27eda0115517deb4969541bdc8c8c86.

  Date: 2026-05-13 06:51:10 +0000

  \[Follow-up\] Add adaptive transient segment allocation (https://redirect.github.com/duckdb/duckdb/pull/22542)

  R-side fix

  Adaptive transient segment allocation raises what the buffer manager has
  to keep pinned while an in-memory table is being created,
  so the spill test's 80 MB limit no longer leaves room
  for the 256 KiB block the statement asks for next:

      Out of Memory Error: could not allocate block of size 256.0 KiB
      (76.1 MiB/76.2 MiB used)

  Raise the limit to 128 MB.
  Measured against this commit's engine,
  80 MB is the only value in 80/100/128/160/200/256 MB that fails,
  and every value that passes still creates the spill directory --
  the result is about 160 MB,
  so 128 MB keeps the statement dependent on temporary storage,
  which is what the test is about.

  Carried from `origin/v2.0-cyanoptera-dev` at 2a4fbc6b02:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 1e0c684fbaa5310d1b7f19bd548ba95f30ca5065

- Update vendored sources to duckdb/duckdb@3dd09a1d539f1632c358ecca61bfbe959d7e2ef3.

  Date: 2026-05-12 19:42:32 +0000

  Binder re-organization and cleanup, change the way we push `ExpressionBinder` for subqueries (https://redirect.github.com/duckdb/duckdb/pull/22597)

  Unflavored-from: 68130ddc0b172a8ad79358787691c322b1713af2

- Update vendored sources to duckdb/duckdb@5ba4285f97fbe2488d0ca5aa8908cfb449513b88.

  Date: 2026-05-12 18:16:35 +0000

  Add support for variables in sqllogictest loops, rewrite parallel CSV test to be a sqllogictest, and add `rejects_line_size_limit` option to CSV reader (https://redirect.github.com/duckdb/duckdb/pull/22601)
  Explicitly handle `nan/inf/-inf` in JSON serializer and deserializer (https://redirect.github.com/duckdb/duckdb/pull/22598)

  Unflavored-from: b0c35aaffcce0f9d2609ee0330d660b166f8e4cc

- Update vendored sources to duckdb/duckdb@de53d9e07c75a28d472355ffffd13698ae61e628.

  Date: 2026-05-12 13:43:31 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9226: Timestamp TimeZone Parsing (https://redirect.github.com/duckdb/duckdb/pull/22577)

  Unflavored-from: 4beb911d475d4ee6a0fd2644e54327b2123f249b

- Update vendored sources to duckdb/duckdb@3b0042b0c8226332b52e5e860064829654a56083.

  Date: 2026-05-12 13:39:45 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9178: Strong Timestamp Casting (https://redirect.github.com/duckdb/duckdb/pull/22531)

  Unflavored-from: a04ac092297a8ce8d47def9fc8a4a40bbc5342b1

- Update vendored sources to duckdb/duckdb@a2c92fbc173fb8bcc0a749dfa46b56137add19f8.

  Date: 2026-05-12 13:36:24 +0000

  Move FSST compression headers to common header (https://redirect.github.com/duckdb/duckdb/pull/22593)

  Unflavored-from: 62453bc5dcd8d271a821882ec68bd28dc67f3077

- Update vendored sources to duckdb/duckdb@1ba45922fcb430bba46c3609243532da831c6ba4.

  Date: 2026-05-12 12:43:50 +0000

  Adding extension aliasing (https://redirect.github.com/duckdb/duckdb/pull/22454)

  Unflavored-from: 3d2b308561686974b07afa3806fee7b91309e18c

- Update vendored sources to duckdb/duckdb@4ed57b656907262590544ea582f6bbc1416e5934.

  Date: 2026-05-12 12:43:28 +0000

  Fix duckdb fuzzer issues (https://redirect.github.com/duckdb/duckdb/pull/22589)

  Unflavored-from: fb87b59cd86e014e05bb0e64500669c665fdc03a

- Update vendored sources to duckdb/duckdb@6320f3003cb8c99a07e708f30b2b2336506d0d41.

  Date: 2026-05-12 08:35:54 +0000

  Fix fuzzer issue on empty subscript expression (https://redirect.github.com/duckdb/duckdb/pull/22566)
  Add libatomic for missing \_\_atomic_is_lock_free (https://redirect.github.com/duckdb/duckdb/pull/22569)

  Unflavored-from: ffcb2f1da67f4d9fbaabfc05fc3bd6c0f521be2a

- Update vendored sources to duckdb/duckdb@118193c9c6761fe713d93bcce24dadc562d09c9c.

  Date: 2026-05-12 08:30:40 +0000

  Auto-generate part of transformer (Part 1/N) (https://redirect.github.com/duckdb/duckdb/pull/22555)
  Add libduckdb_static.a to build artifact in CI (https://redirect.github.com/duckdb/duckdb/pull/22562)

  Unflavored-from: c6cc9317365ca67798b2ab70c0488a3a9650e79d

- Update vendored sources to duckdb/duckdb@a697a1c97629c3fb8af5c1fb8ecd4b40ee2605e3.

  Date: 2026-05-11 08:15:47 +0000

  Move `debug_verify_column_bindings` and `debug_verification_projection` to settings and test configs (https://redirect.github.com/duckdb/duckdb/pull/22553)
  Fix bwc test jobs (https://redirect.github.com/duckdb/duckdb/pull/22529)

  Unflavored-from: d17c100769446a3298b413899d419642df98f4b0

- Update vendored sources to duckdb/duckdb@01eda16d6e3a6648accda27230b9e30edd8b9703.

  Date: 2026-05-10 06:32:23 +0000

  Keep stats at unsigned integer cast (https://redirect.github.com/duckdb/duckdb/pull/22537)

  Unflavored-from: ef067c27e3d251f6326a192377ec9d1e313e4873

- Update vendored sources to duckdb/duckdb@ae0aec232abb91f18667cc0a6af82a34dfc20bcf.

  Date: 2026-05-09 10:31:16 +0000

  Convert `BoundComparisonExpression` into a `BoundFunctionExpression` (https://redirect.github.com/duckdb/duckdb/pull/22514)

  Carried from `origin/v2.0-cyanoptera-dev` at 5914f919d2:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: dc150e40a5626829e692f4533265c4d190fbab0d

- Update vendored sources to duckdb/duckdb@8f11e1d409ae81a0617ff751f1eade8f946f0cdf.

  Date: 2026-05-08 17:42:04 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9096: Strong Timestamp Typing (https://redirect.github.com/duckdb/duckdb/pull/22489)
  Add test_utils to linux-release and use 30s apt timeout (https://redirect.github.com/duckdb/duckdb/pull/22526)

  Unflavored-from: b40a4d72ecf53b167fea4e0e7561866d2b11a480

- Update vendored sources to duckdb/duckdb@aeb931a72c484d009629273a1dc7d38114b479f0.

  Date: 2026-05-08 11:35:33 +0000

  Adapt Hive-partitioned write flushing to number of partitions (https://redirect.github.com/duckdb/duckdb/pull/22505)

  Unflavored-from: dbc1ffed4b51c148d075135565cb1e83e5c0be49

- Update vendored sources to duckdb/duckdb@fcbec4544d15ccaef39dd7961533bfad8c427b7a.

  Date: 2026-05-08 08:49:12 +0000

  Fixed the issue that `size_on_disk` was inflated (https://redirect.github.com/duckdb/duckdb/pull/22522)

  Unflavored-from: 86a5d107ccddfe2c5a61b279f3effc3977dfcd52

- Update vendored sources to duckdb/duckdb@bd97e059a484151805d6af464c360e1382a47c1f.

  Date: 2026-05-08 08:43:19 +0000

  Vector API: Remove count parameter for vector iterators - these instead iterate over all values in the vector (i.e. default to `.size()`) (https://redirect.github.com/duckdb/duckdb/pull/22510)

  Unflavored-from: b1c73c3c2b65303d59d15e8ccc02da25801161a4

- Update vendored sources to duckdb/duckdb@43b4d55aeba22203fb8f00c46d699ba663a9e4cd.

  Date: 2026-05-08 10:41:46 +0200

  Fix nightly tests and ignore very slow tests for HASH_ZERO=1 (https://redirect.github.com/duckdb/duckdb/pull/22509)

  Unflavored-from: a637e88c305a6115a9bb8e614f520c117902131f

- Update vendored sources to duckdb/duckdb@0929f580c838801485ac58864a232a58c63981a6.

  Date: 2026-05-07 14:38:27 +0000

  Use simple update for aggregate states if groups are constant (https://redirect.github.com/duckdb/duckdb/pull/22481)
  Use 2m timeout and make apt more verbose in CI (https://redirect.github.com/duckdb/duckdb/pull/22507)

  Unflavored-from: a670b53fc235f3e3de89328671e77eddbfbca3b0

- Update vendored sources to duckdb/duckdb@67a0a733f12119424dddee68aed6ad271792ec42.

  Date: 2026-05-06 16:18:32 +0000

  Add comparison execution fast path (https://redirect.github.com/duckdb/duckdb/pull/22496)

  Unflavored-from: 49f9f10f2e212d4da596eaec602c68d86f1a63e5

- Update vendored sources to duckdb/duckdb@839b3a774cce5f1dca62ec016054e19e19674e0b.

  Date: 2026-05-06 14:04:35 +0000

  Deprecate `count` variants of `Flatten`, `ToUnifiedFormat`, `ToString`, `Print` (https://redirect.github.com/duckdb/duckdb/pull/22493)

  R-side fix

- Update vendored sources to duckdb/duckdb@3bea18e9978c05040ec7457b71c003e9b570e7a6.

  Date: 2026-05-06 13:09:15 +0000

  Enhance interval type parsing precision and PostgreSQL compatibility. (https://redirect.github.com/duckdb/duckdb/pull/22130)
  Reduce compile log output and remove old test runner (https://redirect.github.com/duckdb/duckdb/pull/22491)
  bump duckdb-sqlsmith (https://redirect.github.com/duckdb/duckdb/pull/22494)
  Fix vsize = 2 issue in JSON create (https://redirect.github.com/duckdb/duckdb/pull/22492)

  Unflavored-from: bc51beb602813d9742ac88c5758b393709dd0cd6

- Update vendored sources to duckdb/duckdb@63d32ec47d9e52deb6b7d3ba6af10904b9aa0747.

  Date: 2026-05-06 12:17:50 +0000

  Deprecate `BoundBetweenExpression` and implement between as a `BoundFunctionExpression` (https://redirect.github.com/duckdb/duckdb/pull/22490)

  Unflavored-from: f35aa71beb38c6689ccaf4f6af73b70e6680897c

- Update vendored sources to duckdb/duckdb@b3ed0d5191465b8e10fc1dc74fe1880e26e4ca45.

  Date: 2026-05-05 19:17:29 +0000

  Make vector / chunk verification togglable with `debug_verification_mode` setting, instead of enabling in debug mode (https://redirect.github.com/duckdb/duckdb/pull/22485)

  Unflavored-from: 71faa473f323b34b850e701b6ac5a9113333f5c4

- Update vendored sources to duckdb/duckdb@6b6e3e6a5530bc08faf0a1402aa8d85743199379.

  Date: 2026-05-05 19:17:24 +0000

  Make BoundBetweenExpression members private and add accessors (https://redirect.github.com/duckdb/duckdb/pull/22486)

  Unflavored-from: b9aa2085747a5ccf99ae41f82386615038662d3c

- Update vendored sources to duckdb/duckdb@f27553563e2b04a8a324ba04ff9507c48802f9fc.

  Date: 2026-05-05 17:41:34 +0000

  Introduce checked integer numeric util class (https://redirect.github.com/duckdb/duckdb/pull/22457)

  Unflavored-from: 3d6957ffdf96d5421ce2c0b4a2fdfd10bd241170

- Update vendored sources to duckdb/duckdb@c3d4868dfa431c60e52e58f744eaf2ac371d5875.

  Date: 2026-05-05 15:33:40 +0000

  Vector API: No longer require a count in `ToUnifiedFormat` (https://redirect.github.com/duckdb/duckdb/pull/22482)

  Unflavored-from: f0fd28646a6773128c640dce56f17969072b2cc8

- Update vendored sources to duckdb/duckdb@8404a926e0ded7b4e25f8a7c3e22e973c39e6b5f.

  Date: 2026-05-05 13:29:31 +0000

  date_trunc avoid decomposition (https://redirect.github.com/duckdb/duckdb/pull/22449)

  Unflavored-from: 96b90461d7a162c0ad88ba6c6c71f5bba311e641

- Update vendored sources to duckdb/duckdb@56a318827db8e5191b06f753883abfd318ab283f.

  Date: 2026-05-05 13:28:37 +0000

  Bump DuckLake, remove patches, load tests (https://redirect.github.com/duckdb/duckdb/pull/22360)

  Unflavored-from: 1a86b0f53450508c2d2bce755a03d122eaeb0948

- Update vendored sources to duckdb/duckdb@c5dfe3ebbe55adc6466d72802ea97b3c5211f3c9.

  Date: 2026-05-05 11:50:16 +0000

  Convert more code to using vector writers, remove legacy UDF API in Connection (https://redirect.github.com/duckdb/duckdb/pull/22477)

  Unflavored-from: 8a6f65453c65a5ce9283ea63dc8bd0b4d7c9fd21

- Update vendored sources to duckdb/duckdb@46ea1f02b5bb61e755e9ecdc5ec774db85837ec7.

  Date: 2026-05-05 10:15:10 +0000

  Remove `Flatten` in many code paths and use more vector iterators / writers (https://redirect.github.com/duckdb/duckdb/pull/22473)

  Unflavored-from: 08284e560cb5a0b0592b6635e0b52de1d180e658

- Update vendored sources to duckdb/duckdb@59b02b756b2c63723be7b53b4b4061f8acae602a.

  Date: 2026-05-05 07:55:36 +0000

  Fix crash on truncated UTF-8 string statistics (https://redirect.github.com/duckdb/duckdb/pull/22447)
  Remove unused ccache and fix julia CI (https://redirect.github.com/duckdb/duckdb/pull/22472)

  Unflavored-from: 28524b5766bfb42d80735b3ea0a94577558dc8d5

- Update vendored sources to duckdb/duckdb@751630025fc7dd605a97fd877ce1781125c78ffb.

  Date: 2026-05-05 07:03:36 +0000

  Make `Vector::Flatten()` no longer require a count and instead use the vectors' count, and fix several more vector sizes (https://redirect.github.com/duckdb/duckdb/pull/22467)

  Unflavored-from: 20c51d85390e7b229e079357291e9a8d809f5878

- Update vendored sources to duckdb/duckdb@bcb0c9c5306ccf1cf5c952ea9027740d2587edc0.

  Date: 2026-05-04 20:07:46 +0000

  Encapsulate `ConstantExpr` and make it ... constant 🥁 (immutable) (https://redirect.github.com/duckdb/duckdb/pull/22463)

  Unflavored-from: 26bc2c65fe2d4d5381291803bd067b40da38cf1c

- Update vendored sources to duckdb/duckdb@0162338aec036404e01dbea3b75f3ae1f52f3ad7.

  Date: 2026-05-04 20:07:12 +0000

  \[Parquet\]\[Variant\] Fix ability to disable shredding of VARIANT columns (https://redirect.github.com/duckdb/duckdb/pull/22464)

  Unflavored-from: a039f33635b74322ed81f5d935f3d3102b021bac

- Update vendored sources to duckdb/duckdb@261427db23a975bc3842c25f807e1b9ab4cff21e.

  Date: 2026-05-04 14:43:11 +0000

  Disable tpcds temporarily to fix main CI (https://redirect.github.com/duckdb/duckdb/pull/22455)

  Unflavored-from: 0c33e1b8ed9f04405350a6f5ba579e4d2bf31ca1

- Update vendored sources to duckdb/duckdb@4710e689cfdd9b6d8373d194871c9f9768d7aae2.

  Date: 2026-05-04 13:53:41 +0000

  \[Parquet\] Create `ParquetWriterOptions` to hold the parquet writer options (https://redirect.github.com/duckdb/duckdb/pull/22462)

  Unflavored-from: d8d0438a78194cb807e829eadcaced69ff62b940

- Update vendored sources to duckdb/duckdb@4d5a2246bb69cf892b9d1e01bf3b98c09eb86e99.

  Date: 2026-05-04 13:21:00 +0000

  Make external file cache size tunable (https://redirect.github.com/duckdb/duckdb/pull/21700)

  Unflavored-from: b6a732b386f982cd5ae912023f2462c2501e59f4

- Update vendored sources to duckdb/duckdb@61edc90ffa4ca5977aaec1971ec9595e15ab7dd6.

  Date: 2026-05-04 13:19:05 +0000

  Re-apply Window Self Join Optimizer Fix (https://redirect.github.com/duckdb/duckdb/pull/22460)

  Unflavored-from: 77c6580a9112d9f4acd5801b2392600e5a12db69

- Update vendored sources to duckdb/duckdb@7d31e7e557ec5002698fdccf755872ede1bfacf4.

  Date: 2026-05-04 12:56:54 +0000

  Remove several instances of `UnifiedVectorFormat` and replace with new Vector iterators (https://redirect.github.com/duckdb/duckdb/pull/22458)

  Unflavored-from: 3dd2be20480f1d9759451794cb82233602dd2441

- Update vendored sources to duckdb/duckdb@bca135e67f8a803b29ae97a53a72702009c28d0d.

  Date: 2026-05-04 10:42:15 +0000

  \[MultiFileReader\]\[Parquet\] Support pushdown of `struct_extract` expression to the scan (https://redirect.github.com/duckdb/duckdb/pull/22266)

  Unflavored-from: f990b1a0190ab1a7ab2de6a822247db61fe4c897

- Update vendored sources to duckdb/duckdb@82ee5951f23a14e44e497926b9f23ae782d7aade.

  Date: 2026-05-04 10:31:12 +0000

  Fix for slice-derived caching (https://redirect.github.com/duckdb/duckdb/pull/22426)

  Unflavored-from: 75f64eef56069e27ab791b33def3060e7a54cff9

- Update vendored sources to duckdb/duckdb@22e98952f83c80fc20e9ba2af29e57569999ebcd.

  Date: 2026-05-04 09:07:09 +0000

  Split `(Bound)Function` inheritance and introduce `Function(Signature/Parameter)` (https://redirect.github.com/duckdb/duckdb/pull/22428)

  Carried from `origin/v2.0-cyanoptera-dev` at 2253fbe61d:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 57382f1e20938abcfa95ce14ffd7c881db3362d6

- Update vendored sources to duckdb/duckdb@53efe54b52a9ed0ab79f76f68cd173da987b0f91.

  Date: 2026-05-04 08:09:38 +0000

  Add support for writing dynamic lists using both `FlatVector::Writer<VectorListType<...>>` and `FlatVector::Writer<list_entry_t>` (https://redirect.github.com/duckdb/duckdb/pull/22453)

  Unflavored-from: 7ea8bcb7aee9fc6e3f124bc240bc3725bac2b4c7

- Update vendored sources to duckdb/duckdb@1c0f8ace6ddac1ecbed945ecbfb68e4ce68de256.

  Date: 2026-05-04 06:53:06 +0000

  Make multi-file scan's filter pushdown skip files instead of opening them (https://redirect.github.com/duckdb/duckdb/pull/22263)

  Unflavored-from: d086eea1d92aac484a152f00c335d79227d321a6

- Update vendored sources to duckdb/duckdb@24c543706576db08a78bd59490d6164b5bef392d.

  Date: 2026-05-04 06:44:54 +0000

  Improved `FILE_SIZE_BYTES` / `ROW_GROUPS_PER_FILE` (https://redirect.github.com/duckdb/duckdb/pull/22423)

  R-side fix

- Update vendored sources to duckdb/duckdb@6be1980b1e1b82f15553802bcc76aad270008ec1.

  Date: 2026-05-03 20:35:24 +0000

  Make vector verification use the vector's size instead of pushing in the size, and fix various vector size issues (https://redirect.github.com/duckdb/duckdb/pull/22451)

  Unflavored-from: bfe82def4b173cff25370abe9892662402db4553

- Update vendored sources to duckdb/duckdb@d51a82e25e5ac9059b9e8f3c10b690defa4a97dc.

  Date: 2026-05-03 19:19:11 +0000

  Disallow negate operator for unsigned input (https://redirect.github.com/duckdb/duckdb/pull/22441)

  Unflavored-from: d056b12a99151cd67b0f7707476bd9ede76128a5

- Update vendored sources to duckdb/duckdb@a660fcb74db9308c74cda62c21626dc12bcdb7db.

  Date: 2026-05-03 19:16:07 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8947: Builtin Window Batching (https://redirect.github.com/duckdb/duckdb/pull/22430)

  Unflavored-from: 42e1a482abaf9a4a1a8b18ae3d4a370bf48d6b07

- Update vendored sources to duckdb/duckdb@9ef0d7741b719d425682b69cb7dd6b76ca7aaaa7.

  Date: 2026-05-03 19:15:39 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8974: Nanosecond Timestamp TimeZone (https://redirect.github.com/duckdb/duckdb/pull/22412)

  R-side fix:

  Upstream adds the `TIMESTAMP_TZ_NS` logical type,
  so `test_all_types()` returns one more column
  and the `types` snapshot no longer matches.

  Accept the drifted snapshot:
  a `$timestamp_tz_ns` entry between `$time_tz` and `$float`,
  holding the type's minimum, maximum and NULL
  rendered as UTC timestamps.
  The change is an addition only --
  no existing entry moves or disappears --
  so it reads exactly as the engine change this commit vendors.

  Taken from `snapshot-34764927b8ca6fe6e095abbe1e239561062a1912-rcc-smoke-null`,
  the branch the `snapshots` gate published for this commit.

  Carried from `origin/v2.0-cyanoptera-dev` at c62e6c31ed:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  R-side fix (carry):

  The carry above applied the base twin's `TIMESTAMP_TZ_NS` case in
  `duckdb_r_transform()` on top of the one this commit's buffer twin
  already carries, which gives a duplicate `case` label and a reference to
  `nanosecond_coercion_warning`, a `std::once_flag` the forward's glue no
  longer declares: `install` failed.
  Drop the carried copy and keep the buffer's, which warns through
  `cpp11::warning()` like the `TIMESTAMP_NS` case above it.

  Landing v2 (finding 8): `TIMESTAMP_TZ_NS` is labeled with the session `TimeZone`, like `TIMESTAMP_TZ`, in `duckdb_r_decorate()` (`src/transform.cpp`); `test-timezone.R` checks it without icu.

  Landing v2 (finding 8): the test reads its `TIMESTAMPTZ_NS` value from a string, since without icu the engine cannot cast a `TIMESTAMPTZ` to it until later (`tests/testthat/test-timezone.R`).

  Landing v4 (review): `test_all_types()`'s snapshot excludes `timestamp_tz_ns` like `timestamp_ns`, since reading either fires the once-per-process nanosecond warning, which reached the snapshot only when this file ran first.

  Unflavored-from: 7a55a6e1dd06fe36ff875fa287519001e235b5a9

- Update vendored sources to duckdb/duckdb@a989f48bb6ae60375b6fd1383df73ce68daa6a4a.

  Date: 2026-05-03 19:15:17 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9027: ICU 78.3 Update (https://redirect.github.com/duckdb/duckdb/pull/22434)

  Unflavored-from: 00271fa3ba2e49f99514ae16eb470ce857d22e3a

- Update vendored sources to duckdb/duckdb@69f965661b0ae1208771f7740d437d263bea8266.

  Date: 2026-05-03 10:21:39 +0000

  Add support for writing list types using `FlatVector::Writer<VectorListType<...>>` and use it in the geometry methods (https://redirect.github.com/duckdb/duckdb/pull/22446)

  Unflavored-from: 870c0e0d574f480c293bd878870efcd709965616

- Update vendored sources to duckdb/duckdb@5c6f30a655b3b56bf5a2056f170faf97f7c62295.

  Date: 2026-05-02 18:40:17 +0000

  Add support for writing struct types using `FlatVector::Writer<VectorStructType<...>>` and use it in the geometry methods (https://redirect.github.com/duckdb/duckdb/pull/22443)

  Unflavored-from: 1919bc7bbe0aefc074d2737b92849c119c5e5a06

- Update vendored sources to duckdb/duckdb@bd7c7a2e533ae1b4a3e6b8f2cab4e8459d90d9c2.

  Date: 2026-05-02 11:06:56 +0000

  Use FlatVector Writer in geometry conversion functions (https://redirect.github.com/duckdb/duckdb/pull/22440)

  Unflavored-from: 8c266b61cb3fffe13d5307f8266cb2e3f7ae6c4d

- Update vendored sources to duckdb/duckdb@89f51782ee12353646ff98d525d95de8ed498a8e.

  Date: 2026-05-01 14:26:20 +0000

  Allow TypeName keywords to be used properly (https://redirect.github.com/duckdb/duckdb/pull/22421)
  Fix typo in env var for linux-relassert CI job (https://redirect.github.com/duckdb/duckdb/pull/22419)

  Unflavored-from: 11436ac12270f6a63d286b0b0c9748009b585b9b

- Update vendored sources to duckdb/duckdb@2d3868df17bab6a95ed4eaff97adf81d4e39b9eb.

  Date: 2026-05-01 14:24:18 +0000

  Add support for Vector::Values\<VectorListType\<...\>\> allowing iteration over lists with a fixed (known) schema (https://redirect.github.com/duckdb/duckdb/pull/22422)
  Ignore queue branch for push and merge tidy check jobs (https://redirect.github.com/duckdb/duckdb/pull/22424)

  Unflavored-from: 11c1f5894f18e6db52edf3e9349352a794e98cf9

- Update vendored sources to duckdb/duckdb@7a6be3c62ba713b33076d04128aef0f7d6e9c14d.

  Date: 2026-05-01 11:25:01 +0000

  Add support for `Vector::Values<VectorStructType<...>>` allowing iteration over structs with a fixed (known) schema (https://redirect.github.com/duckdb/duckdb/pull/22417)

  Unflavored-from: 285e9f35532b593302af3708fa75b38c813a8588

- Update vendored sources to duckdb/duckdb@51c97af7580b240597ea9ac1192c4cd44e23dd72.

  Date: 2026-05-01 08:03:45 +0000

  Fix tidy error performance-move-const-arg (https://redirect.github.com/duckdb/duckdb/pull/22416)

  Unflavored-from: f36faf4fd060f764a17e9888c20dbe10f2fcdf09

- Update vendored sources to duckdb/duckdb@8799409a78c3fccf750eff8ab7f3aca61f74b5d1.

  Date: 2026-05-01 07:04:26 +0000

  Add `TableFunctionParallelism` enum and `parallelize_sequential_sources` setting (https://redirect.github.com/duckdb/duckdb/pull/21807)

  Unflavored-from: e7e45ecbc60995ecfba1e7ca9a0c11a02369435d

- Update vendored sources to duckdb/duckdb@bea13c1574f372e4f78837548f5fda48c19bea5a.

  Date: 2026-05-01 05:55:18 +0000

  Optimize regexp_replace for anchored capture-then-truncate patterns (https://redirect.github.com/duckdb/duckdb/pull/22284)

  Unflavored-from: 80af4bf86e5c7e6be8f002435c78fa4cf0c5a090

- Update vendored sources to duckdb/duckdb@0a804241610526b3dc7f56a56db1302fb72122c1.

  Date: 2026-05-01 05:53:26 +0000

  Add `ArgProperties` for stats forward-bounds (https://redirect.github.com/duckdb/duckdb/pull/22384)

  Unflavored-from: 40ce8fafe21cd3a68574b3515fe8a5aa765a82ec

- Update vendored sources to duckdb/duckdb@a47ad6db06cca0cf9fff116722f6baab75021cbb.

  Date: 2026-04-30 20:30:45 +0000

  VectorBuffer: :SetVectorSize - Set vector size of children for structs / arrays (https://redirect.github.com/duckdb/duckdb/pull/22407)
  Unflavored-from: 39da8560c670731ac20185f1c6d1cb2e3a389f72

- Update vendored sources to duckdb/duckdb@aec1efc17612797cf84627a63d321e6a246966fe.

  Date: 2026-04-30 19:39:03 +0000

  Make `FileBuffer` internals private, and make an explicit distinction between `GetData` and `GetDataMutable` (https://redirect.github.com/duckdb/duckdb/pull/22404)

  Unflavored-from: fdb5ec8562041ba71af9836337cbfde8f6cb07bd

- Update vendored sources to duckdb/duckdb@b67d8525f3d97aeea662dc2882f1caaad8809720.

  Date: 2026-04-30 16:42:06 +0000

  Executors: replace `ExecuteWithNulls` with returning an `optional<X>` (https://redirect.github.com/duckdb/duckdb/pull/22400)
  Add note in `CLAUDE.md` to not use `const_cast` (https://redirect.github.com/duckdb/duckdb/pull/22401)

  Carried from `origin/v2.0-cyanoptera-dev` at 48ed071413:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 8e26d7a8092b987d131131ae59b15f89ab7de23c

- Update vendored sources to duckdb/duckdb@3ff79ea07cf07f05ecd49766ac266a7934e43cd3.

  Date: 2026-04-30 14:37:01 +0000

  Add small-build-side dictionary emission for hash joins (https://redirect.github.com/duckdb/duckdb/pull/22340)
  Do not perform more operations than copying for r2 buckets (https://redirect.github.com/duckdb/duckdb/pull/22396)

  Unflavored-from: 5f4bb3457292c68dd1c6e2f0f5539ba9af54b06f

- Update vendored sources to duckdb/duckdb@5776358ab2acc5c5e947d9bde80334db38edd92d.

  Date: 2026-04-30 13:31:13 +0000

  Add variadic executor that replaces senary / septenary executors and is used internally in the ternary executor (https://redirect.github.com/duckdb/duckdb/pull/22397)

  Unflavored-from: b4a1985c3bdb11ceb36c17182949782cc829ac26

- Update vendored sources to duckdb/duckdb@799ed6495bd7610a12ee88780a20eb8ee8d0cf95.

  Date: 2026-04-30 12:35:15 +0000

  Fix validity map bisect underflow (https://redirect.github.com/duckdb/duckdb/pull/22393)

  Unflavored-from: ae047750cced4e69bde12f79ce60582e1da54985

- Update vendored sources to duckdb/duckdb@5cc4ee49c2e272d1e5d2bf373625b05f7ca0dbd1.

  Date: 2026-04-30 12:30:05 +0000

  Fix vector size issue in extensions (https://redirect.github.com/duckdb/duckdb/pull/22391)

  Unflavored-from: c9066d5c69a6bc14f8dce1c1707d11ab2fbb5373

- Update vendored sources to duckdb/duckdb@a28d95d5b4cd82eb8170ddeaf5da7b8506e626d0.

  Date: 2026-04-30 12:15:40 +0000

  Parquet statistics support UUID, BOOLEAN (https://redirect.github.com/duckdb/duckdb/pull/22389)

  Unflavored-from: 8933804f5ac1470a45df3c155bae7e51c9036ad0

- Update vendored sources to duckdb/duckdb@08a90c88ae1af2354d80346948147d26543a3ff3.

  Date: 2026-04-30 12:02:58 +0000

  Switch to using `std::optional` (https://redirect.github.com/duckdb/duckdb/pull/22390)
  bump azure extension to be c++17 compatible (https://redirect.github.com/duckdb/duckdb/pull/22387)

  Unflavored-from: af6ae60e23dd9e44ac9c8db4edf0f44a13031c1c

- Update vendored sources to duckdb/duckdb@5cf406000e83bba04e17af638ddf38b7ba30c0ee.

  Date: 2026-04-30 09:53:29 +0000

  Add bounds checks for ALPRD scan sizes before memcpy (https://redirect.github.com/duckdb/duckdb/pull/22348)

  Unflavored-from: 8025d04c753777c0240e608b906a5ed7dcd47028

- Update vendored sources to duckdb/duckdb@cd2ef3919f0ec8aeee7fe8eae2819f95565ba299.

  Date: 2026-04-30 09:40:47 +0000

  Fix hidden merge conflict (https://redirect.github.com/duckdb/duckdb/pull/22388)

  Folded, because it does not build on its own:
  duckdb/duckdb@a61e6e000bdf16f19e3b375467144269cae9fb84

  Fix duckdb_param_type returning INVALID for nested casts (https://redirect.github.com/duckdb/duckdb/pull/22281)

  That commit reads the protected member `Expression::return_type`
  from `AddCastToTypeInternal()`
  in `src/planner/expression/bound_cast_expression.cpp`,
  so compilation of `ub_src_planner_expression.cpp` fails.
  The commit above is upstream's own repair,
  going through `GetReturnType()` instead.
  Vendored as one commit
  so the broken tree never stands alone on the chain.

  Unflavored-from: a3fe2790ab9904f7025b7dab8a1fbd0787eb37ef

- Update vendored sources to duckdb/duckdb@ca97226bd855d0f3e5d1856ad6ae890907954ecd.

  Date: 2026-04-30 08:20:49 +0000

  Make `Vector` sizes mandatory, and add verification pass to `DataChunk::Verify` that verifies all children have the same size as the DataChunk (https://redirect.github.com/duckdb/duckdb/pull/22377)

  Carried from `origin/v2.0-cyanoptera-dev` at 6d2db20007:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: ae603a902da0f37971ec7451e37609f7e4b036ba

- Update vendored sources to duckdb/duckdb@d5b10deeb01f78d430c034f2a712c39f435973b4.

  Date: 2026-04-30 08:16:19 +0000

  Handle blocks with no rows correctly. Fixes https://redirect.github.com/duckdb/duckdb/pull/22352 (https://redirect.github.com/duckdb/duckdb/pull/22373)

  Unflavored-from: 889b0395ac2e98b1459520ebcc357ca0d9a74e73

- Update vendored sources to duckdb/duckdb@975c86c9e4c5cfb185236c516c2754c39a07b086.

  Date: 2026-04-30 08:12:13 +0000

  Trust parquet stats for fixed-width missing exactness flag files (https://redirect.github.com/duckdb/duckdb/pull/22383)

  Unflavored-from: 82262d5f55dd2104315bb291e9ff12b696de7c5c

- Update vendored sources to duckdb/duckdb@d8ab8dc7e46fed2a95a0cc06b32cc0d675a2bd1b.

  Date: 2026-04-30 08:10:07 +0000

  `GROUPING()`/`GROUPING_ID()` with no args uses all `GROUP BY` columns by default (https://redirect.github.com/duckdb/duckdb/pull/22370)
  Limit choco output, and show rclone command (https://redirect.github.com/duckdb/duckdb/pull/22385)

  Unflavored-from: ab44945c24c8240127b8a51bd1da4b3fb0c19ceb

- Update vendored sources to duckdb/duckdb@0cc19d1b1e156d8e1f6d189c7806a1729d9489d8.

  Date: 2026-04-30 07:44:34 +0000

  Use Clang++ and clangd version 20 in CI (https://redirect.github.com/duckdb/duckdb/pull/22371)

  Unflavored-from: 53e555724ab7ad65bddbb8c20ffbf814ba6a4ba4

- Update vendored sources to duckdb/duckdb@eda181313f8a474693db27352ba0edea5ecfebc7.

  Date: 2026-04-30 06:37:06 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/9075: TimeZone Offset Parsing (https://redirect.github.com/duckdb/duckdb/pull/22379)

  Unflavored-from: 229675aa0d959fc0cea73600635e45a736975437

- Update vendored sources to duckdb/duckdb@ae64b51a089a1c2fcab0d8f045e101b87980f204.

  Date: 2026-04-29 20:17:35 +0000

  Deprecate `KeywordHelper::Write[Optionally]Quoted` - and improve support for `SQLString` and `SQLIdentifier` instead (https://redirect.github.com/duckdb/duckdb/pull/22374)

  Unflavored-from: 6871c670fdb691d12aff5b721ce6bd3c35a778f2

- Update vendored sources to duckdb/duckdb@793b055a4f9d5194e339c670733b660be0123901.

  Date: 2026-04-29 17:05:32 +0000

  Avoid `DefaultExpression` greedily consuming `NOT NULL` constraint (https://redirect.github.com/duckdb/duckdb/pull/22365)
  Use -mcpu=native on aarch64 when compiling with `NATIVE_ARCH=1` (https://redirect.github.com/duckdb/duckdb/pull/22369)
  Fix nightly tests (https://redirect.github.com/duckdb/duckdb/pull/22368)
  Add type hints to the grammar (https://redirect.github.com/duckdb/duckdb/pull/22372)

  Unflavored-from: e666f21a2d3e04f878ea2067fbf45f46cc155d2e

- Update vendored sources to duckdb/duckdb@27f124639697b20be9aa32a3b9bec6f9c8613ad7.

  Date: 2026-04-29 14:14:00 +0000

  `PartitionedExecution` optimizer (https://redirect.github.com/duckdb/duckdb/pull/22336)
  Replace awscli s3 uploads with rclone (https://redirect.github.com/duckdb/duckdb/pull/22265)

  Unflavored-from: 6a26944256c01fadf7e9e1574b39912d6c47d0d6

- Update vendored sources to duckdb/duckdb@ef62fce4a46444c8de1906c270998582463f7783.

  Date: 2026-04-29 13:59:05 +0000

  Enable clang for linux-relassert CI jobs (https://redirect.github.com/duckdb/duckdb/pull/22224)

  Unflavored-from: f83c7714f49a70520364c755c5e0643c312cd70f

- Update vendored sources to duckdb/duckdb@5e39297cf6cc18942688a32ff68aa11c4cb1103e.

  Date: 2026-04-29 13:50:35 +0000

  Move `PEGTransformerFactory` into `ParserCache` (https://redirect.github.com/duckdb/duckdb/pull/22358)

  Unflavored-from: 8950c4f66412fc68b5ab53d973c91070994374de

- Update vendored sources to duckdb/duckdb@9f4f2d7dc34d5a151555274ccd979d095c3f3bb9.

  Date: 2026-04-29 13:46:06 +0000

  ISSUE-22267: Fix correlated EXISTS decorrelation with derived table (https://redirect.github.com/duckdb/duckdb/pull/22296)
  Reject running unittest without run_tests.py in CI workflows (https://redirect.github.com/duckdb/duckdb/pull/22366)

  Unflavored-from: 7ab8ffc74e669447e54bf5c40684093cfef64f7f

- Update vendored sources to duckdb/duckdb@20cf1029f0cce589444bfa60ab545634762d4db8.

  Date: 2026-04-29 12:20:29 +0000

  Deprecate `PRAGMA enable_verification` and friends, move `verify_serializer` to separate option and verification run (https://redirect.github.com/duckdb/duckdb/pull/22361)

  Unflavored-from: 770e2789bd164ba815dd19c8762d176b8cd62dea

- Update vendored sources to duckdb/duckdb@aef61d6db6ad8f57f51bb923bbbf4848929cdc0c.

  Date: 2026-04-29 11:58:34 +0000

  Flat struct_map list to get the correct size (https://redirect.github.com/duckdb/duckdb/pull/22346)

  Unflavored-from: 7948582e1f2e00bc557870e7ef792cfd39417fad

- Update vendored sources to duckdb/duckdb@a41ee3817550a758764fedaecf8ba59d2c112ca5.

  Date: 2026-04-29 10:32:24 +0000

  Protect `(Base)Expression` members (https://redirect.github.com/duckdb/duckdb/pull/22351)
  fix for uninitialized variable error (https://redirect.github.com/duckdb/duckdb/pull/22357)

  Carried from `origin/v2.0-cyanoptera-dev` at bcf279b9eb:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 2956f96afadc27a146ce04935a67703cecd06a53

- Update vendored sources to duckdb/duckdb@1c673f9aba343a9b37e009c56214b8d0622f1023.

  Date: 2026-04-29 09:15:43 +0000

  Fix three performance-move-const-arg issues on main (https://redirect.github.com/duckdb/duckdb/pull/22356)

  Unflavored-from: cf7e2d6d0b58ad0cc52a581a92acb3043e1385c7

- Update vendored sources to duckdb/duckdb@367fcd1fa7c8cd28fc19bd3f782480756a394153.

  Date: 2026-04-29 08:54:55 +0000

  Move prepared and explain statement verification runs to statement verification, remove old client verify code (https://redirect.github.com/duckdb/duckdb/pull/22354)

  Unflavored-from: 035d6e2b67439f685766543e3993f5ea91297b8a

- Update vendored sources to duckdb/duckdb@94addef607689b9449e14eac21e3dbae985844ca.

  Date: 2026-04-29 07:40:32 +0000

  Collapse FD-derived GROUP BY groups (https://redirect.github.com/duckdb/duckdb/pull/22294)

  Unflavored-from: 3b6d8d0d6664d037797cb4035a75a7157301731b

- Update vendored sources to duckdb/duckdb@1d0327d85bd2e600038be8f08fabafe13fca5eef.

  Date: 2026-04-29 07:21:53 +0000

  Move `verify_fetch_row`, `verify_external`, `enable_caching_operators` and `disable_optimizer` out of `enable_verification` and into dedicated runs (https://redirect.github.com/duckdb/duckdb/pull/22350)

  Unflavored-from: e0f92ae482da9ce3889cedf68862047ad9f4b85d

- Update vendored sources to duckdb/duckdb@0cc5e1471c5b898918a65da70eea91b27ef822f8.

  Date: 2026-04-28 20:22:59 +0000

  Introduce `Bound(Scalar/Aggregate/Window)` functions (https://redirect.github.com/duckdb/duckdb/pull/22342)

  Unflavored-from: 84563a05e473b99e2b2a3104c136af511f9fe10c

- Update vendored sources to duckdb/duckdb@469d87ed15253f9710414a3898d77917fd0d2690.

  Date: 2026-04-28 19:58:40 +0000

  Move (de)serialization verification to statement verifiers, and remove unnecessary verifiers / verification tests (https://redirect.github.com/duckdb/duckdb/pull/22349)

  Unflavored-from: de93e5e01c3ecc35c50793a2a4f318e1c83aab93

- Update vendored sources to duckdb/duckdb@760010a4eaf5b6a7b37f2ea272ffcb18573a2851.

  Date: 2026-04-28 18:21:38 +0000

  Move stats verification to dedicated `debug_verify_stats` toggle and remove from `query_verification_enabled` (https://redirect.github.com/duckdb/duckdb/pull/22345)

  Unflavored-from: cfeded67e6f151f0712d8ad2823513b305d7c7e4

- Update vendored sources to duckdb/duckdb@b6f522779b96715952e44316295327f15ae5f1d4.

  Date: 2026-04-28 16:45:25 +0000

  Add `debug_verify_statement` setting which splits off some verification from `PRAGMA enable_verification` (https://redirect.github.com/duckdb/duckdb/pull/22334)

  Unflavored-from: 1f9323564e8fa45f44db357fd4e236b1f15983ba

- Update vendored sources to duckdb/duckdb@b80e6e6fff919a33cbb398fba9472cc2dcee6b12.

  Date: 2026-04-28 14:41:34 +0000

  Fix add column if not exists for PEG parser (https://redirect.github.com/duckdb/duckdb/pull/22338)

  Unflavored-from: b0283d54626e7a4ffda09627961f3ea45f776c92

- Update vendored sources to duckdb/duckdb@e1908d74ce66d1a8d76025f45e663bc6d302c33e.

  Date: 2026-04-28 14:40:56 +0000

  Add OPTIONS to HTTPUtil and httpfs (https://redirect.github.com/duckdb/duckdb/pull/22335)
  Skip sporadically broken test for now (https://redirect.github.com/duckdb/duckdb/pull/22337)
  Error when CMAKE_CXX_STANDARD is explicit and less than 17 (https://redirect.github.com/duckdb/duckdb/pull/22329)
  Improve CLAUDE.md for parser (https://redirect.github.com/duckdb/duckdb/pull/22331)
  Removed unused scripts (https://redirect.github.com/duckdb/duckdb/pull/22332)

  Unflavored-from: 174c17a9f6b032d0a842f91cefc659f5beb6f6cc

- Update vendored sources to duckdb/duckdb@d556890d4c1b8db75e39d7ee173941a3656f9e39.

  Date: 2026-04-28 12:32:49 +0000

  Remove `BaseScalarFunction` (https://redirect.github.com/duckdb/duckdb/pull/22318)
  apply avro patches (https://redirect.github.com/duckdb/duckdb/pull/22330)

  Unflavored-from: 4f426e708a480a6deb15d09abd619021280f70da

- Update vendored sources to duckdb/duckdb@d0da365fe335d801c03b8cd508cc705acec7fe1a.

  Date: 2026-04-28 12:04:22 +0000

  Fix some threading issues in `PhysicalCopyToFile` (https://redirect.github.com/duckdb/duckdb/pull/22322)
  Add `CLAUDE.md` (https://redirect.github.com/duckdb/duckdb/pull/22326)
  CLI: PostBind hook to determine if \_ might be used in query, if not, reclaim memory early (https://redirect.github.com/duckdb/duckdb/pull/22290)

  Unflavored-from: c0b9d6e32e9a839d241f8cf20e194ec245fce343

- Update vendored sources to duckdb/duckdb@16fab311be6a341f1f2b0ce62851617cafce6804.

  Date: 2026-04-28 09:25:12 +0000

  Fix copy parquet from table with nullable columns (https://redirect.github.com/duckdb/duckdb/pull/22183)

  Unflavored-from: a2c8ca172661e47d7264b9db6b210e61aa4370cc

- Update vendored sources to duckdb/duckdb@df67373b3ba47a76a2330935b1474deda7856198.

  Date: 2026-04-28 08:09:50 +0000

  Preserve CREATE INDEX WITH options across checkpoint reload (https://redirect.github.com/duckdb/duckdb/pull/22317)

  Unflavored-from: 3a3a6ee6e5d7c798da37fa292e72992129a14782

- Update vendored sources to duckdb/duckdb@7a2ef35732b53482c40e5fef2083b304c4122817.

  Date: 2026-04-28 07:16:31 +0000

  ISSUE-22235: Fix timetz casting offset (https://redirect.github.com/duckdb/duckdb/pull/22259)
  \[avro\] bump for C++17 and apply patches (https://redirect.github.com/duckdb/duckdb/pull/22273)

  Unflavored-from: 922e98d0b52604894a325207796c4f0a5381dcce

- Update vendored sources to duckdb/duckdb@d8196b7ab2f52bd1fe906406b42cfef30a8746f2.

  Date: 2026-04-28 07:15:46 +0000

  Move function callbacks/properties into separate structs (https://redirect.github.com/duckdb/duckdb/pull/22272)

  Unflavored-from: f910d2f354a4858a2db721f28f5e804b690c8de8

- Update vendored sources to duckdb/duckdb@5df2a10dbf3fc235b48d756f92c40a077bb85611.

  Date: 2026-04-28 07:15:08 +0000

  Optimize Limited Distinct (https://redirect.github.com/duckdb/duckdb/pull/21056)

  Unflavored-from: 227ea7ab8a554d30cc3bad5d1c6df3c810a6f697

- Update vendored sources to duckdb/duckdb@ff2cd933f0ddb2404929f6bea9183a848ceeab6d.

  Date: 2026-04-28 07:07:32 +0000

  Skip late-materialization when projection columns are all already required by the scan (https://redirect.github.com/duckdb/duckdb/pull/22306)

  Unflavored-from: 88034affbce35d4f7f987940d422664d69972735

- Update vendored sources to duckdb/duckdb@3914ad4d9c028041639c24b13238a7965985f732.

  Date: 2026-04-28 07:00:31 +0000

  Pull up projections with non-colref expressions (https://redirect.github.com/duckdb/duckdb/pull/21776)

  Unflavored-from: 10e077447ae6c2b80cad51a010dac3df4b4b8b0a

- Update vendored sources to duckdb/duckdb@5a54cfa5e6db1fde18e858e3451306639ddb4eca.

  Date: 2026-04-28 06:59:10 +0000

  AFTER trigger firing for INSERT/UPDATE/DELETE (FOR EACH STATEMENT) (https://redirect.github.com/duckdb/duckdb/pull/22095)
  Internal https://redirect.github.com/duckdb/duckdb/pull/9011: Time Zone 2026b (https://redirect.github.com/duckdb/duckdb/pull/22310)
  TPC-DS: Fix log-scaled table row counts at non-standard SF (https://redirect.github.com/duckdb/duckdb/pull/22299)

  Unflavored-from: 0a98463603c78d6e070fe2d03d8419b02bfa8e5d

- Update vendored sources to duckdb/duckdb@3a156d92ff28b5034af468a8d6c1f415a1e5a8d4.

  Date: 2026-04-28 06:15:51 +0000

  Fix: Move count setting in FSSTVector out of loop (https://redirect.github.com/duckdb/duckdb/pull/22309)
  Unflavored-from: 80b5eb4b72aacb31dd75368afba74a66bc9cf238

- Update vendored sources to duckdb/duckdb@0da6e1e84c60c0d5aebd35d7758fcdb0f8bb6eb7.

  Date: 2026-04-27 08:46:00 +0000

  Cleanup usage of Vector APIs to improve propagation of vector sizes (https://redirect.github.com/duckdb/duckdb/pull/22293)
  Fix sporadic test failure in CI: set temp dir before setting temp dir encryption (https://redirect.github.com/duckdb/duckdb/pull/22287)
  Fix tpcds extension to generate data matching tpcds tools (https://redirect.github.com/duckdb/duckdb/pull/21746)

  Unflavored-from: c80550f4cb023e203ce1604ba147f7c7f9c247f9

- Update vendored sources to duckdb/duckdb@1a6ef3ef783176e68ab17cd6550a50f089329ae3.

  Date: 2026-04-25 15:59:54 +0000

  Merge `v1.5-variegata` into main (https://redirect.github.com/duckdb/duckdb/pull/22283)

  Unflavored-from: 7b1ea023d5567cbf00953e7d36d66f07d2389fe5

- Update vendored sources to duckdb/duckdb@8140496820f36735571d385bd1f2048f9db2e230.

  Date: 2026-04-25 13:11:08 +0000

  \[WIP\] Replace PostgreSQL parser with PEG-based parser (https://redirect.github.com/duckdb/duckdb/pull/22194)

  R-side fix

- Update vendored sources to duckdb/duckdb@2c8396dc11105f928bd00df6f782df9d0b3277e1.

  Date: 2026-04-25 11:24:44 +0000

  Correctly handle quoting of type (https://redirect.github.com/duckdb/duckdb/pull/22237)
  Make test more flexible (https://redirect.github.com/duckdb/duckdb/pull/22271)

  Unflavored-from: 70591fd66d57b3ff07f69a182375d77baf1aef88

- Update vendored sources to duckdb/duckdb@a1b9a37e49e16263ea7c4e7e1a9fbd595aa9e39c.

  Date: 2026-04-24 14:59:57 +0000

  Require methods that create a `ConstantVector` (e.g. `ConstantVector::SetNull`, `Vector::Reference(Value &)`)) to provide a `count` (https://redirect.github.com/duckdb/duckdb/pull/22268)
  Allow extending format checks for downstream extension usage (https://redirect.github.com/duckdb/duckdb/pull/22270)

  Carried from `origin/v2.0-cyanoptera-dev` at 1f9e0ed95f:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 038f6b01aa8d67e8b96d8bc2e454ce201fa91dcd

- Update vendored sources to duckdb/duckdb@fcc945398a0ebea86d19835c84942e50aebda4df.

  Date: 2026-04-24 11:45:03 +0000

  Defer commit drop side effects until after flush commit (https://redirect.github.com/duckdb/duckdb/pull/22198)

  Unflavored-from: 195a096fce16aaae23e904cf2b10d84a86e9fcb2

- Update vendored sources to duckdb/duckdb@d521a441f400090191fd1e32a7d1c6cff4ce7639.

  Date: 2026-04-24 11:41:26 +0000

  Don't copy input parameters for StartsWith (https://redirect.github.com/duckdb/duckdb/pull/22257)
  Trim ccache on ccache v3 (used in manylinux image) (https://redirect.github.com/duckdb/duckdb/pull/22264)
  Fix symbols in linux-debug and remove extension copies (https://redirect.github.com/duckdb/duckdb/pull/22246)

  Unflavored-from: 129aef6dedebf73a3b0357a1f556e1d3e96b68d0

- Update vendored sources to duckdb/duckdb@0631f3459b668f453d50b5b76a6b9d611fac6a3e.

  Date: 2026-04-24 10:48:07 +0000

  Preserve lazily loaded column metadata through `CHECKPOINT`, `ADD COLUMN` and `DROP COLUMN` (https://redirect.github.com/duckdb/duckdb/pull/22255)

  Unflavored-from: d0dec222228b933754b49020f560abcf28d047f8

- Update vendored sources to duckdb/duckdb@dda3fdafef0e1e7156395d3c1449e6d60310c475.

  Date: 2026-04-24 05:10:25 +0000

  Clean-up Vector::Append and unify Vector::Reserve / Vector::Resize (https://redirect.github.com/duckdb/duckdb/pull/22254)

  Unflavored-from: 0cfb458db3e297d34a5a6a46e06952047e76ab2a

- Update vendored sources to duckdb/duckdb@56e3415154956011fe8008a51d2578042ab09ba3.

  Date: 2026-04-24 05:09:37 +0000

  \[Parquet\]\[Dev\] Replace `root_reader` with the decomposed `column_readers` vector (https://redirect.github.com/duckdb/duckdb/pull/22247)

  Unflavored-from: 644f0b6202d815e3763a86ef41ea7a07b356efc5

- Update vendored sources to duckdb/duckdb@5af191ce52b9869e77a9c0faa1b15e9c273d889e.

  Date: 2026-04-23 18:03:38 +0000

  Checkpoint new row group instead of old row group in `RowGroupCollection::Checkpoint` (https://redirect.github.com/duckdb/duckdb/pull/22249)

  Unflavored-from: d4bba37d8ce2d9af55844fee3e8150c94df0ccb6

- Update vendored sources to duckdb/duckdb@04cd23231e63dfe52564f2ca00eeed3d85219542.

  Date: 2026-04-23 17:36:04 +0000

  Implement optimized Slice(offset, count) for dictionary vectors, and add method to DataChunk (https://redirect.github.com/duckdb/duckdb/pull/22252)
  Set `temp_file_encryption` setting outside of loop (https://redirect.github.com/duckdb/duckdb/pull/22250)

  Unflavored-from: 1c0a5a01676059ffabfd300509b31709c957dba5

- Update vendored sources to duckdb/duckdb@c04e0e41288fff392d46b09a7c3b76f1f9676a76.

  Date: 2026-04-23 14:13:44 +0000

  Add aggregate_window_batch_t — batched variant of the window callback (https://redirect.github.com/duckdb/duckdb/pull/22143)
  Use merge-base for linux-base build, and test with GCC 12 (https://redirect.github.com/duckdb/duckdb/pull/22243)

  Unflavored-from: f774afb90bde0fc03dd8692368061a7e6420aed4

- Update vendored sources to duckdb/duckdb@5af66d401f734b31d415f61227e8a39a8118250c.

  Date: 2026-04-23 13:45:32 +0000

  Local Cache for adaptive filters in multi-file readers (https://redirect.github.com/duckdb/duckdb/pull/22197)
  Fix GCC 12 issue and use ref for consistent checkouts (https://redirect.github.com/duckdb/duckdb/pull/22240)

  Unflavored-from: a7965405dc947610f9691e165312b7b4681536f8

- Update vendored sources to duckdb/duckdb@15c40aa7d503fefe60bd9bc5409f24f8b4dce871.

  Date: 2026-04-23 10:37:41 +0000

  Add `count_t` and `capacity_t` types and use in certain Vector interfaces (https://redirect.github.com/duckdb/duckdb/pull/22236)

  Unflavored-from: 8ff3f95d2cf0ea6fdf1c0eb2b30a96ada4740e28

- Update vendored sources to duckdb/duckdb@02ef6f6ee5a208cce1b7e9e83f72e1de9401e0af.

  Date: 2026-04-23 09:46:22 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8975: Streaming Value Cleanup (https://redirect.github.com/duckdb/duckdb/pull/22227)

  Unflavored-from: eb1979beb3192293fce15e0d201e527ac6fa7b15

- Update vendored sources to duckdb/duckdb@90b36cf9f942a0fdd88830be71b0775d8f2d03d1.

  Date: 2026-04-23 09:32:16 +0000

  Hive-partitioned Write Rework (https://redirect.github.com/duckdb/duckdb/pull/22225)

  Unflavored-from: 6c95243076d7fd53fe214fefd0b6c4a38bec9ce3

- Update vendored sources to duckdb/duckdb@159eddc1a211c9799baa15b8a1b56e1961d22e26.

  Date: 2026-04-23 09:11:24 +0000

  Make the `BLOCK_START` header public in the `SingleFileBlockManager` (https://redirect.github.com/duckdb/duckdb/pull/22233)

  Unflavored-from: 94b8e2b911b063382c1d6ac5e729ed430d19084b

- Update vendored sources to duckdb/duckdb@d3fd01ed3f8b05d006c1d6fa2fa4b92c5edfbb87.

  Date: 2026-04-23 09:06:14 +0000

  \[Parquet\]\[Dev\] Parquet bundle arguments into `ColumnReaderInput` (https://redirect.github.com/duckdb/duckdb/pull/22234)

  Unflavored-from: 3fe0cceb93e22a197d2bb770ac84100d2d5e5f9d

- Update vendored sources to duckdb/duckdb@7dc6e32aaf84e1c50a4f4f5071e6022c534f1155.

  Date: 2026-04-23 08:18:30 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/7385: ICU Unity Builds (https://redirect.github.com/duckdb/duckdb/pull/22175)

  Unflavored-from: e2b9608e6029393be9e9d29b2c3ad3bce0bd55f2

- Update vendored sources to duckdb/duckdb@65da6863b0785d14c80ba0f37734e88ce2f5468e.

  Date: 2026-04-23 08:11:34 +0000

  Fix compile errors (https://redirect.github.com/duckdb/duckdb/pull/22231)
  Move statement splitting responsibility to the peg grammar (https://redirect.github.com/duckdb/duckdb/pull/21953)

  Unflavored-from: 5cfcddd56b3e231dceb664ba3b8e33cd09495550

- Update vendored sources to duckdb/duckdb@96568069a87b16c06106334de3b39cb6e020dbea.

  Date: 2026-04-23 07:20:42 +0000

  Remove dictionary size in VectorBuffer, instead use child-vector size (https://redirect.github.com/duckdb/duckdb/pull/22229)
  Improve error message with mismatching VALUES lists (https://redirect.github.com/duckdb/duckdb/pull/22228)

  Unflavored-from: f978fc23dba567e44c3f6140cfd200fea54d129a

- Update vendored sources to duckdb/duckdb@4bbfea6f6efcfce5560885be62dca7820d38499f.

  Date: 2026-04-22 20:31:56 +0000

  Prefer using `Vector::Append(Value)` instead of `DataChunk::SetValue()` in various table functions (https://redirect.github.com/duckdb/duckdb/pull/22223)

  Unflavored-from: dff79cc64a53ab449b7e3dcaa32602a815d59c21

- Update vendored sources to duckdb/duckdb@5ad744a6d01f00e55e7eeab1fac72fbecf0ae19a.

  Date: 2026-04-22 15:58:12 +0000

  Removing the amalgamation build, so long (https://redirect.github.com/duckdb/duckdb/pull/22217)

  Unflavored-from: dc5cf22a078e10abaf63a5fc4b02fd8e4942ddb4

- Update vendored sources to duckdb/duckdb@1ca6727c76eca474faf551b7bfefbdcc41fbcc28.

  Date: 2026-04-22 14:15:20 +0000

  Protect function members (https://redirect.github.com/duckdb/duckdb/pull/22219)

  Unflavored-from: 4cc89da6a47b5884b92ed9639b5095ba67d5eac5

- Update vendored sources to duckdb/duckdb@800231adf96ae331cfa07efa3dad3bd25c6848db.

  Date: 2026-04-22 13:35:24 +0000

  Remove ListVectors' `child_size` and use the child vectors' size instead (https://redirect.github.com/duckdb/duckdb/pull/22212)

  Unflavored-from: 121881506084a68872d4611d890c1e790bae6364

- Update vendored sources to duckdb/duckdb@0e32808df4d23e74c8afcb226aea36574addd58b.

  Date: 2026-04-22 13:09:14 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8893: Window Callback Cleanup (https://redirect.github.com/duckdb/duckdb/pull/22201)

  Unflavored-from: 007a5f919ca499656a7a3268389bdb129cddfa5d

- Update vendored sources to duckdb/duckdb@ebca63c833f466efd30edab887f633765fa9bfcd.

  Date: 2026-04-22 12:06:35 +0000

  Detect typos in code using typos-cli (https://redirect.github.com/duckdb/duckdb/pull/22190)
  Merge InvokeCI into Main workflow (https://redirect.github.com/duckdb/duckdb/pull/22214)

  Unflavored-from: 9c603b93fde9accd13caa042b718d59ed2a064cc

- Update vendored sources to duckdb/duckdb@fb019db70c447eb2013ce94e0da400c66b580ad3.

  Date: 2026-04-22 11:53:32 +0000

  Unify struct filter with expression filter (https://redirect.github.com/duckdb/duckdb/pull/22207)

  Unflavored-from: 4ef2aca56448a5b666c9ae0ad08498912d086252

- Update vendored sources to duckdb/duckdb@27a2f193b8dbc73f5eaa85519471e489ec6d7f0e.

  Date: 2026-04-22 11:51:28 +0000

  Parquet skip page scan (https://redirect.github.com/duckdb/duckdb/pull/22188)

  Unflavored-from: 6d38938a85388d0ec42a6e0d21d9f35b742a7564

- Update vendored sources to duckdb/duckdb@4505a5d248618dc8491503f2e8271b9476328785.

  Date: 2026-04-22 11:01:51 +0000

  Fix union type casting rules (https://redirect.github.com/duckdb/duckdb/pull/20706)

  Unflavored-from: 5a9d62254c7d368ddef1cd0860ad1111d5f27fe7

- Update vendored sources to duckdb/duckdb@ef12d4395984eb67ca85a1f71d6fd0c5be520101.

  Date: 2026-04-22 09:01:35 +0000

  Fix various `clang` warnings (https://redirect.github.com/duckdb/duckdb/pull/22213)

  Unflavored-from: 55105e792dddbd5ad1194b83f8f60f81c56a3bc4

- Update vendored sources to duckdb/duckdb@316a5ae99ea924d187354b207d0236f3c95419f7.

  Date: 2026-04-22 09:00:42 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8961: Streaming Nth Value (https://redirect.github.com/duckdb/duckdb/pull/22200)

  Unflavored-from: dd3271a190ff8b4a7c4214697c328d01320192af

- Update vendored sources to duckdb/duckdb@4e9c91e1c1dc65fe58db919ed5ab439f6bb15ce4.

  Date: 2026-04-22 08:21:01 +0000

  Add support for deferred binding of views in the SQL layer (https://redirect.github.com/duckdb/duckdb/pull/22199)

  Unflavored-from: f8790d235f218aca6395a3fa67ebda3b33db6611

- Update vendored sources to duckdb/duckdb@37dfe19b6ec5bc58bbfe8f2fbfbcc8b133d13eeb.

  Date: 2026-04-22 08:04:16 +0000

  Fix memory limit reset (https://redirect.github.com/duckdb/duckdb/pull/22208)

  Unflavored-from: f6d27bc2017f32541795842c8fc98a05638aa55c

- Update vendored sources to duckdb/duckdb@19925dce89f9b48e206264593c8a1920eaeed673.

  Date: 2026-04-22 07:57:55 +0000

  GCC 12 could not convert unique_ptr result (https://redirect.github.com/duckdb/duckdb/pull/22210)

  Unflavored-from: cc2f5952f55446ac3804c13673b735eda116de5c

- Update vendored sources to duckdb/duckdb@56404c3203ddd794c6d0852320d8cf3bcbd886f1.

  Date: 2026-04-22 07:08:20 +0000

  Vector Rework: Add append methods to `Vector`, and remove `source_offset` from ListAppend (https://redirect.github.com/duckdb/duckdb/pull/22205)
  fix failures summary in test runner (https://redirect.github.com/duckdb/duckdb/pull/22196)

  Unflavored-from: ca8da1087c6fb4a8fc4e638293435684bcf64976

- Update vendored sources to duckdb/duckdb@8169730ac0b5f51268190f95460bf8255aedfeee.

  Date: 2026-04-21 15:06:03 +0000

  Move `VectorOperations::Copy()` to `VectorBuffer`, and make `Resize` resize vector buffers in-place again (restoring old behavior) (https://redirect.github.com/duckdb/duckdb/pull/22195)
  Add `DUCKDB_FORMAT_SKIP_FETCH ` environment variable to skip fetching new changes from main in make format-main (https://redirect.github.com/duckdb/duckdb/pull/22192)

  Unflavored-from: 8603a77751f28bbd1a6d214d983510a189c1b97c

- Update vendored sources to duckdb/duckdb@c9541072a04c9efc4f9df11f2ca9f097ba334232.

  Date: 2026-04-21 13:49:35 +0000

  Rework `FlatVector::Writer` to push values into the result vector, instead of allowing random access (https://redirect.github.com/duckdb/duckdb/pull/22193)

  Unflavored-from: 596fcd805804198a95877728b57e3d07d1302c04

- Update vendored sources to duckdb/duckdb@c188fa18e988a40094977e341b8188009fe9b224.

  Date: 2026-04-21 13:28:54 +0000

  \[Fix\] Allow DDL after DML within the same transaction (https://redirect.github.com/duckdb/duckdb/pull/22093)

  Unflavored-from: 49b037754d27b270324dab8d110f65723f3d43cd

- Update vendored sources to duckdb/duckdb@07fb8d5f46c207439f5193f711fdc56a6dd8fe0a.

  Date: 2026-04-21 12:38:14 +0000

  seq.currval() can only be called after seq.nextval() (https://redirect.github.com/duckdb/duckdb/pull/21796)

  Unflavored-from: a6f54ffed770bd4ee25c55bb0dcf3d9134cbd09d

- Update vendored sources to duckdb/duckdb@5a8630acb7713e1fd1436fe7d26da2519627bab1.

  Date: 2026-04-21 11:32:43 +0000

  Allow multiple DML statements in a single WITH clause (https://redirect.github.com/duckdb/duckdb/pull/21997)

  Unflavored-from: 21e96ce889570442537cae88580be7e577b09d54

- Update vendored sources to duckdb/duckdb@f397bc6d9798bec89d5f58988ad12602b4712070.

  Date: 2026-04-21 11:27:51 +0000

  Unify null filter with expression filter (https://redirect.github.com/duckdb/duckdb/pull/22182)

  Unflavored-from: 7c83361879988b29f13f6fe4dd52ebeb23a1b68e

- Update vendored sources to duckdb/duckdb@bd0e1eeb52454e2300e9b4670ddd043c16e92963.

  Date: 2026-04-21 10:43:56 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8571: Window Streaming APIs (https://redirect.github.com/duckdb/duckdb/pull/22173)

  Unflavored-from: c1479fa67ee0c5f78701ffd642a7aab6c87e3b92

- Update vendored sources to duckdb/duckdb@3cd75bce1817dacf0b7afd09a13541bc6876c594.

  Date: 2026-04-21 09:56:16 +0000

  Fix GCC-12 build and notify external repo CI jobs (https://redirect.github.com/duckdb/duckdb/pull/22184)
  fix loop iterator deprecation warning for httpfs extension (https://redirect.github.com/duckdb/duckdb/pull/22168)

  Unflavored-from: 0a08b7b336559f01dae250f6b2a263f83012a598

- Update vendored sources to duckdb/duckdb@2076dd79b5da1a11405fb2b5d2ed27471c791279.

  Date: 2026-04-21 07:51:29 +0000

  OR predicate selectivity for join ordering (https://redirect.github.com/duckdb/duckdb/pull/21895)

  Unflavored-from: 517d88d068af228ad2404b45bb37607c84a7a61b

- Update vendored sources to duckdb/duckdb@f9d17f0eb7a6f90586dbf08910910f766eb1b29c.

  Date: 2026-04-20 15:04:13 +0000

  Add a capacity to `SelectionVector` (https://redirect.github.com/duckdb/duckdb/pull/22166)

  Unflavored-from: 0f69c6cd022caf966ca33fb090422319cd8da6ef

- Update vendored sources to duckdb/duckdb@fc2d22317e874f9de91294468c3450270233632f.

  Date: 2026-04-20 14:13:51 +0000

  Unify in filter with expression filter (https://redirect.github.com/duckdb/duckdb/pull/22165)

  Unflavored-from: e3b64522317c25899440a2c698cfa3dcaf8c253c

- Update vendored sources to duckdb/duckdb@6cb7e8c21257fc959a01d40135cb3cef6f4e810d.

  Date: 2026-04-20 14:13:11 +0000

  Refactor Query Decorrelation (https://redirect.github.com/duckdb/duckdb/pull/22162)
  Add support for octal and hexadecimal sequences in peg parser (https://redirect.github.com/duckdb/duckdb/pull/22163)

  Unflavored-from: 654af3d71a2f90992e5dcdb61111c896dfff72be

- Update vendored sources to duckdb/duckdb@84dc4405aacd46ce2919fb495d4a55671bfe9653.

  Date: 2026-04-20 11:18:43 +0000

  Fix several warnings that pop up with newer clang version (https://redirect.github.com/duckdb/duckdb/pull/22158)
  Try clangd-tidy in CI (https://redirect.github.com/duckdb/duckdb/pull/21745)
  Improve clangd checks and fix InvokeCI -\> notify call (https://redirect.github.com/duckdb/duckdb/pull/22161)

  Unflavored-from: cd51ac1aa7b463683af344342f4bdc9252b8e668

- Update vendored sources to duckdb/duckdb@1304d3ce269a7890fbfe302a3be9e00cfbe3ae1d.

  Date: 2026-04-20 10:19:42 +0000

  Deprecate `ListVector::GetEntry`, add `ListVector::GetChild` and `ListVector::GetChildMutable` (https://redirect.github.com/duckdb/duckdb/pull/22157)

  Carried from `origin/v2.0-cyanoptera-dev` at df94db1d874:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 4cfe480efc9eefef6c1ed8fbee3438447fa5b0ad

- Update vendored sources to duckdb/duckdb@f75d07f70c4058a655520ad3b74dd3aa9d99279f.

  Date: 2026-04-20 10:19:27 +0000

  Unify constant filter with expression filter (https://redirect.github.com/duckdb/duckdb/pull/22005)

  Carried from `origin/v2.0-cyanoptera-dev` at eb395814752:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 087b76c12f3b5dcc90cc9dace2044f354f134e59

- Update vendored sources to duckdb/duckdb@793b11c39381e4669fc5fbf46f9966af2caec0de.

  Date: 2026-04-20 08:24:18 +0000

  Implement DROP TRIGGER end-to-end (https://redirect.github.com/duckdb/duckdb/pull/21889)

  Unflavored-from: 0b300336976f8045d4b0b66867dff523692b1449

- Update vendored sources to duckdb/duckdb@e6079ec1d0ffcec926c63422ccd126891ef2ba81.

  Date: 2026-04-20 07:50:08 +0000

  Move ConstantVector::Reference to dedicated function, unify with ConstantVector::SetNull (https://redirect.github.com/duckdb/duckdb/pull/22156)

  Unflavored-from: 48b4ba352f1cadf07f28766117b034e9342c66b6

- Update vendored sources to duckdb/duckdb@bf5740c1f7955233dff926cb29cdb2d9684ac375.

  Date: 2026-04-20 07:28:56 +0000

  Fix TRY_CAST debug assertion failure for MAP (https://redirect.github.com/duckdb/duckdb/pull/22152)
  PEG script verify grammar (https://redirect.github.com/duckdb/duckdb/pull/22140)

  Unflavored-from: 1a5539bca75f67b5f4d2a1c39c7862f58b323432

- Update vendored sources to duckdb/duckdb@ccbb21804fadd42262c434ad80fcaa01a7705e87.

  Date: 2026-04-20 07:20:52 +0000

  Improve metric script and json for script that generates metric docs (https://redirect.github.com/duckdb/duckdb/pull/22129)

  Unflavored-from: b6d29df872c46097e77e075abbc96f0d5748096e

- Update vendored sources to duckdb/duckdb@dbb69b9f8772151019860a485523f4b0b6edb1aa.

  Date: 2026-04-20 06:57:15 +0000

  Extend ieee_floating_point_ops to math domain functions (https://redirect.github.com/duckdb/duckdb/pull/21803)

  Unflavored-from: 8b7d30eec0846006b639cb5562e77f596f0ddfc1

- Update vendored sources to duckdb/duckdb@01f1038e3c74eebb3702ecec3f952a518d40f147.

  Date: 2026-04-20 06:46:13 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8876: Window Function Evaluate (https://redirect.github.com/duckdb/duckdb/pull/22078)

  Unflavored-from: 1fb711c38a898cafa00d92e6c42572b97a2b4c8d

- Update vendored sources to duckdb/duckdb@e64b98f66712b9674897bb27f7f417e5e88fb4be.

  Date: 2026-04-17 16:12:54 +0000

  Remove capacity from `DataChunk` (https://redirect.github.com/duckdb/duckdb/pull/22123)

  Unflavored-from: 05b752f93482eae0793d00e8c5efa3337f2edcf8

- Update vendored sources to duckdb/duckdb@4c33885280489ecb71ed02bb416805c4ce1509d6.

  Date: 2026-04-17 11:56:14 +0000

  When resizing a list vector, keep the original child Vector in the new buffer (https://redirect.github.com/duckdb/duckdb/pull/22134)
  Use boolean type for input parameters in InvokeCI (https://redirect.github.com/duckdb/duckdb/pull/22131)

  Unflavored-from: 7b2f847d69edc59993377f39790705d4f9dccf51

- Update vendored sources to duckdb/duckdb@e42cf280a01d6e6ff723c2cafeaa0902f4cc1296.

  Date: 2026-04-17 10:50:07 +0000

  Fix typo: entrys -\> entries (https://redirect.github.com/duckdb/duckdb/pull/22127)
  Fix broken main, fail CI early, and avoid breaking CI on main (https://redirect.github.com/duckdb/duckdb/pull/22117)

  Unflavored-from: b549ba5ba1c318c364d6957be9d48c48f44e38af

- Update vendored sources to duckdb/duckdb@e5bb211e551378d0d5708f361db67d43c7263176.

  Date: 2026-04-16 21:00:36 +0000

  Make `FlatVector::Validity` return a `const ValidityMask &`, and add `FlatVector::ValidityMutable` which returns a mutable reference (https://redirect.github.com/duckdb/duckdb/pull/22122)

  Carried from `origin/v2.0-cyanoptera-dev` at d5ecbdc0389:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 0d4f655039ca7f1e6014dc5380e81cc1a9e8ffce

- Update vendored sources to duckdb/duckdb@aea659614788b0d227fc7d683649e6a48674588e.

  Date: 2026-04-16 19:19:12 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8920: Window Value Mutex (https://redirect.github.com/duckdb/duckdb/pull/22120)

  Unflavored-from: 50a9aeb859aeeabf831362c15ce36914599a7726

- Update vendored sources to duckdb/duckdb@7fb94e16bb4d1a052a6e7136000b553fc8d5d8f7.

  Date: 2026-04-16 18:30:56 +0000

  Set max cardinality for table functions when provided cardinality is exact (https://redirect.github.com/duckdb/duckdb/pull/22077)

  Unflavored-from: 6de0ed76944e58887e7a73e3c81ae85598e07ad8

- Update vendored sources to duckdb/duckdb@46f3377d0ce6ace419e3da27b62b1437c9e099f7.

  Date: 2026-04-16 18:30:50 +0000

  Remove friend classes from `Vector` (https://redirect.github.com/duckdb/duckdb/pull/22118)

  Unflavored-from: cff07660388b5ad9dcafb6ed94c2890c6883a8d0

- Update vendored sources to duckdb/duckdb@e6982159518564f774f91021621045a99956fe26.

  Date: 2026-04-16 16:48:19 +0000

  Fix https://redirect.github.com/duckdb/duckdb/pull/21904 MERGE INTO invalid column reference not rejected (https://redirect.github.com/duckdb/duckdb/pull/22018)

  Unflavored-from: 9e6e26f3e355d072b3493ce21ce056a7c94723e3

- Update vendored sources to duckdb/duckdb@aba9aab95d27f89491496c6eb531cfd260f8587e.

  Date: 2026-04-16 16:37:12 +0000

  Add a sel_count and capacity to the DictionaryBuffer (https://redirect.github.com/duckdb/duckdb/pull/22116)
  PEG parser sample bug (https://redirect.github.com/duckdb/duckdb/pull/22114)

  Unflavored-from: ad806d352d4173c5411a041d86bb148c0d27b32f

- Update vendored sources to duckdb/duckdb@f94c93c841cf7aac7bb200e9a3bc70a2bc041681.

  Date: 2026-04-16 15:53:06 +0000

  Move callbacks in Cast / Tuple Data Gather behind a function call (https://redirect.github.com/duckdb/duckdb/pull/22112)

  Unflavored-from: c1132bf4637716147330f620d3627ba068c7c297

- Update vendored sources to duckdb/duckdb@7d25e20a979ce2acef3f9e772a97ca0a324da64d.

  Date: 2026-04-16 14:39:12 +0000

  If the input to a function or cast is NULL, automatically emit a constant NULL instead of calling the function - as long as the function has `DEFAULT_NULL_HANDLING` (https://redirect.github.com/duckdb/duckdb/pull/22113)
  PEG parser change `optional_ptr` to references (https://redirect.github.com/duckdb/duckdb/pull/22111)

  Unflavored-from: 171676dc0c579465e90c8e2d1fea2e7356b8530d

- Update vendored sources to duckdb/duckdb@4d0108e1077f6226dce24f657d52fee31f2e4204.

  Date: 2026-04-16 07:49:27 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8912: FILL Range Cursor (https://redirect.github.com/duckdb/duckdb/pull/22102)

  Unflavored-from: a6e05b54db3b024b9cff7f9b9233b7a8d3526912

- Update vendored sources to duckdb/duckdb@486c0e6580828f2e75e31fa1c0749cb4a4ed2cd4.

  Date: 2026-04-15 17:31:39 +0000

  Merge `v1.5-variegata` into main (https://redirect.github.com/duckdb/duckdb/pull/22087)

  R-side fix: accept the drifted `tests/testthat/_snaps/types.md`.

  The merge adds a `geometry` column to `test_all_types()`
  (`src/function/table/system/test_all_types.cpp`): `POINT EMPTY` for the
  min row and a thirteen-element `GEOMETRYCOLLECTION` for the max row,
  built to cover empty and non-empty variants of every geometry kind. The
  R side has no GEOMETRY mapping, so both arrive as WKB blobs and the
  `test_all_types()` snapshot grows a `$geometry` entry.

  The drift is purely additive — 36 inserted lines, nothing removed or
  changed — and reads as the engine change this commit carries: the first
  element is a point with two NaN coordinates (`POINT EMPTY`), the second
  a collection header announcing thirteen members, matching the WKT
  literal upstream added one for one.

  Snapshot taken from `snapshot-76ecaf241-rcc-smoke-null`, which CI
  computed from the failing run. The identical insertion showed on all 31
  commits from here to the branch tip against the same blob, and nothing
  in that range touches the file, so the fix belongs here.

  Carried from `origin/v2.0-cyanoptera-dev` at 86093aa6036:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 4913c8300b10768a4a9f0e0ee2b23412d422b5c2

- Update vendored sources to duckdb/duckdb@e54cc78e319c33594ad4bb8db8f464f78d99c636.

  Date: 2026-04-15 17:29:25 +0000

  Fix bignum constant casting (https://redirect.github.com/duckdb/duckdb/pull/22084)
  Write merged vcpkg.json to build dir (build/reldebug/vcpkg.json), always write vcpkg.json, and clean-up Makefile by unifying the various builds (https://redirect.github.com/duckdb/duckdb/pull/22090)

  Unflavored-from: 55f04d69d684e83309d4925b364734305a0c9eae

- Update vendored sources to duckdb/duckdb@f964d38dbcab6ec3849db6f39a98c5d0daa5849b.

  Date: 2026-04-15 16:06:11 +0000

  Use `FlatVector::Writer` in more places, rename to `VectorWriter` and place in separate include file (https://redirect.github.com/duckdb/duckdb/pull/22091)

  Unflavored-from: 1ec412bec598e11838b91e3a8f72171eec4a3f7a

- Update vendored sources to duckdb/duckdb@33cdee99c96dcd90197f497129e67399bfed9426.

  Date: 2026-04-15 10:39:46 +0000

  fix: Don't override return_type for CTAS (https://redirect.github.com/duckdb/duckdb/pull/22045)
  Unflavored-from: 054acc59434b1daeca8d4bfe47413c820c775a0f

- Update vendored sources to duckdb/duckdb@1558c992b1c059a4dd410f52c4fa512fe0119ac2.

  Date: 2026-04-15 09:15:03 +0000

  fix: only set chains_longer_than_one when extending chains (https://redirect.github.com/duckdb/duckdb/pull/22039)
  Unflavored-from: 8a4a3d99de10053e13a2cc693b24b0c683adc390

- Update vendored sources to duckdb/duckdb@bdb65ece8cb0d8686e78b019539652ecd626011a.

  Date: 2026-04-14 20:34:29 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8851: Window Sink Finalize (https://redirect.github.com/duckdb/duckdb/pull/22072)

  Unflavored-from: 1157f121568caf86cbeaa09ebe30350021179df4

- Update vendored sources to duckdb/duckdb@7c4a09d272c7e0057564c320feb79385a7b827ca.

  Date: 2026-04-14 18:21:00 +0000

  Add `capacity` field to FlatVector VectorBuffers (https://redirect.github.com/duckdb/duckdb/pull/22071)

  Unflavored-from: eaf9e4792f752d0111a383b2f13e33e6b83cc80d

- Update vendored sources to duckdb/duckdb@3ab2ba3d828d77989e20e4acc115e80283f06fac.

  Date: 2026-04-14 18:20:43 +0000

  Use TrySubtract in external file cache timestamp computation (https://redirect.github.com/duckdb/duckdb/pull/22074)

  Unflavored-from: 46946d9fe2a2055debe11c6d16cff2093c157666

- Update vendored sources to duckdb/duckdb@5a1e54e3d48cf7fd8469a04ea60f8ae325564f4b.

  Date: 2026-04-14 14:19:11 +0000

  Rename `VectorValueIterator` to `VectorIterator`, add assert when `GetValue()` is used on a value that is `NULL`, and add `GetValueUnsafe()` (https://redirect.github.com/duckdb/duckdb/pull/22068)

  Unflavored-from: 8621e63e0d9847c51ec51daa094f5178dd84eae3

- Update vendored sources to duckdb/duckdb@b5a61793270a135aae2c4323072bf79811d62dce.

  Date: 2026-04-14 14:18:41 +0000

  Rewrite GLOB matcher from recursive matching to iterative one (https://redirect.github.com/duckdb/duckdb/pull/22062)
  CLI: when tab completing, complete until the longest prefix of all matches in case of conflicts (https://redirect.github.com/duckdb/duckdb/pull/22066)

  Unflavored-from: 40a13c35955d71f1bdeb8b90c5de3bbd84f27e4c

- Update vendored sources to duckdb/duckdb@5da870b1ee45dff4264fae02eaed82f70709e560.

  Date: 2026-04-14 13:11:43 +0000

  Fix some afl++ fuzzer crashes (https://redirect.github.com/duckdb/duckdb/pull/22055)
  Revamp extension build / patching system for better local development, enabled when `DUCKDB_NEW_EXTENSION_BUILD=1` is defined (https://redirect.github.com/duckdb/duckdb/pull/22063)

  Unflavored-from: 9162aae918497027997ef0afca37d7e968243e0e

- Update vendored sources to duckdb/duckdb@1c4ecd8138ae0c63c73957a411e65484301bb300.

  Date: 2026-04-14 10:44:06 +0000

  Clean-up in FlatVector / ConstantVector headers (https://redirect.github.com/duckdb/duckdb/pull/22052)
  Fix compile worker message and improve Windows builds (https://redirect.github.com/duckdb/duckdb/pull/21955)
  \[CLI\] Suggest '.last' only when PAGER is active (https://redirect.github.com/duckdb/duckdb/pull/22053)

  Unflavored-from: b6d04b7e723fc84ec70ac1b1880ddd51b52bf53b

- Update vendored sources to duckdb/duckdb@1136c7f27b8b8b4395312b17eadfd9e6e3406f33.

  Date: 2026-04-14 08:09:33 +0000

  BoxRendererContext: make usage of BoxRenderer independent of ClientContext (https://redirect.github.com/duckdb/duckdb/pull/21738)
  Unflavored-from: fcd2cde438fdbf5d46cf43cc2b6473bc75be60ff

- Update vendored sources to duckdb/duckdb@a8d81658f2829741472cacf788c0ac72c4d61cb7.

  Date: 2026-04-14 05:59:31 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8850: Window Function Local (https://redirect.github.com/duckdb/duckdb/pull/22047)

  Unflavored-from: 7f865a4b6651780bff6c07ffca635aa91efbb591

- Update vendored sources to duckdb/duckdb@77421460bea4fe6cf5a6a796f391b985caeb3d9b.

  Date: 2026-04-14 05:56:24 +0000

  Expose query string to the optimizer (https://redirect.github.com/duckdb/duckdb/pull/22046)

  Unflavored-from: a36198d36ae4c204b5a13d59944a874c2d20af72

- Update vendored sources to duckdb/duckdb@4e23aac8ca0d8ee1acced066ad23f90273f1c8ff.

  Date: 2026-04-14 05:51:01 +0000

  Fix and improve adbc (https://redirect.github.com/duckdb/duckdb/pull/22026)

  Unflavored-from: 8d3f5233041b652aee65f11e8d3768bc17a3b561

- Update vendored sources to duckdb/duckdb@27f53474b36204d4be4d4bb6a9039fa2461e507c.

  Date: 2026-04-13 20:41:09 +0000

  Wrap Scalar/Aggr/Window function bind callback parameters (https://redirect.github.com/duckdb/duckdb/pull/22034)

  Carried from `origin/v2.0-cyanoptera-dev` at 3980c999fc3:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 417af0f584eb14ce3a1ce07ab659934224b5b3c6

- Update vendored sources to duckdb/duckdb@bea4530f6c98aa1cbfebc73cc472fb1d67d3907e.

  Date: 2026-04-13 20:25:52 +0000

  PEG parser fuzzer issues (https://redirect.github.com/duckdb/duckdb/pull/21987)
  Support skip_tests in Main and called workflows (https://redirect.github.com/duckdb/duckdb/pull/22038)

  Unflavored-from: a3ac3ef4e8e66253f3a1384f9e6f1a3bd3b7f09d

- Update vendored sources to duckdb/duckdb@0a2b21b58c84e410da54a4fb36bcba71e3413ef0.

  Date: 2026-04-13 15:10:35 +0000

  Move vector iterator to getters (https://redirect.github.com/duckdb/duckdb/pull/22035)

  Unflavored-from: a5fbcf6f29663781d50687ca1edef5dc0d26fceb

- Update vendored sources to duckdb/duckdb@b5ed9c59bfc8528c6e1a35d363a802fcaaa403c8.

  Date: 2026-04-13 12:43:06 +0000

  Move vector function implementations into `VectorBuffer` (https://redirect.github.com/duckdb/duckdb/pull/22030)

  Unflavored-from: 0c07456991263c7150a8852c8ee7b5f03b05091b

- Update vendored sources to duckdb/duckdb@921a372ae0b1455c754f107935a704c19c8939de.

  Date: 2026-04-13 10:42:16 +0000

  Revert "fix issue https://redirect.github.com/duckdb/duckdb/pull/21890 for internal binding error" (https://redirect.github.com/duckdb/duckdb/pull/22031)

  Unflavored-from: 80dc33e7a3d2259be3fe15c7be4c3ffe03781706

- Update vendored sources to duckdb/duckdb@32aa681a2c51fbf2cdc24c3c9ec1cdbdcbecd4e9.

  Date: 2026-04-13 10:35:36 +0000

  Add HasMinMax for StringStats (https://redirect.github.com/duckdb/duckdb/pull/22008)

  Unflavored-from: ce4f721d098e5db8e5d72b543b5a0e316da9e6ff

- Update vendored sources to duckdb/duckdb@7156f9cdbb0827d7aca9e1988c0abc480929efce.

  Date: 2026-04-13 10:35:11 +0000

  fix: Add missing properties in CreateViewInfo::Copy (https://redirect.github.com/duckdb/duckdb/pull/22010)
  Add few slow tests (https://redirect.github.com/duckdb/duckdb/pull/22028)

  Unflavored-from: 6cd10ea2ba9741b673a4512a3713e335d27a2418

- Update vendored sources to duckdb/duckdb@dc1b42d0adafc839c7836e739b3a42e084bcd7a8.

  Date: 2026-04-13 09:02:19 +0000

  Add single-pass probe for LEFT JOIN with unique right-side keys (https://redirect.github.com/duckdb/duckdb/pull/22009)

  Unflavored-from: c773b66216c450e7698f755208f91d5f0cd23383

- Update vendored sources to duckdb/duckdb@fc4d0159f1408fc3068f6a3ec1eb1c71df13c863.

  Date: 2026-04-13 07:26:22 +0000

  Apply include-what-you-use on extensions/parquet (https://redirect.github.com/duckdb/duckdb/pull/21977)

  Unflavored-from: a589ad918ca45e5d57bb4e20eabfb666c561336c

- Update vendored sources to duckdb/duckdb@cf079e6ab996ecebc76ad540550cd21428b8b529.

  Date: 2026-04-13 06:51:42 +0000

  fix issue https://redirect.github.com/duckdb/duckdb/pull/21890 for internal binding error (https://redirect.github.com/duckdb/duckdb/pull/21913)

  Unflavored-from: 9cd3f24499b8eb608b7614c33fb20e5349eed42f

- Update vendored sources to duckdb/duckdb@dcf98e23f27cd82dd955112a8ffb88af43a5211b.

  Date: 2026-04-13 06:18:14 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8863: LIST ORDER Optimization (https://redirect.github.com/duckdb/duckdb/pull/22017)

  Unflavored-from: da40c2d1bf2b71da3a5642460748cfcabe523d9f

- Update vendored sources to duckdb/duckdb@94ad5759010ff9acddb62e80f9fa98a168f87b25.

  Date: 2026-04-13 06:18:03 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8862: Window Function NULLS (https://redirect.github.com/duckdb/duckdb/pull/22012)

  Unflavored-from: 9f4ce879e3b57e2a9a33b455421c510d6d501e3f

- Update vendored sources to duckdb/duckdb@fc553552af581fbc84851da6f96fa315d4133729.

  Date: 2026-04-10 13:12:56 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8696: Window Function Sharing (https://redirect.github.com/duckdb/duckdb/pull/21999)

  Unflavored-from: 91930f6e45f55694cd51d432ba897b1c54f63be8

- Update vendored sources to duckdb/duckdb@4a7c45228fe4b57db28a96345d80ade59fc9221f.

  Date: 2026-04-10 12:46:41 +0000

  Fix hex string literal not being converted to blob (https://redirect.github.com/duckdb/duckdb/pull/22006)

  Unflavored-from: 40b7fc30e55dafd2d169fa8dbcf193e5cd315d49

- Update vendored sources to duckdb/duckdb@b24f2023b50b95e9172d7a01b96b12e8c5f66848.

  Date: 2026-04-09 21:27:35 +0000

  Move `VectorType` from the `Vector` into the `VectorBuffer` (https://redirect.github.com/duckdb/duckdb/pull/21996)

  Unflavored-from: 7b54940489013061d723cf4b369a907d131c0a80

- Update vendored sources to duckdb/duckdb@04478f84cc8872ac233714aaaae36f268faa15fd.

  Date: 2026-04-09 18:19:54 +0000

  Remove constructor that allows for creation of uninitialized vectors, and add an enum instead of using a bool for initialization (https://redirect.github.com/duckdb/duckdb/pull/21995)

  Unflavored-from: 612debd3797df18c503c7383c647b7d3e26e53d8

- Update vendored sources to duckdb/duckdb@111e91b87f41ffdbccd833979481bcab2ce5c82f.

  Date: 2026-04-09 15:56:20 +0000

  Add support for `VectorOperations::Comparator` - and rework comparisons and `DISTINCT FROM` code to use this (https://redirect.github.com/duckdb/duckdb/pull/21991)

  Unflavored-from: aeaf4c363a2e88920b31e9c957705c5f3607274d

- Update vendored sources to duckdb/duckdb@1e32b3f4b4855f146c2d3473bc7a068e8645211f.

  Date: 2026-04-09 13:25:49 +0000

  Make `FlatVector::GetData` return a `const` ptr, and add `FlatVector::GetDataMutable` (https://redirect.github.com/duckdb/duckdb/pull/21978)

  Carried from `origin/v2.0-cyanoptera-dev` at df5824b4730:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 3b5bc170f9a91945c328666f0c56aecebf65fc8d

- Update vendored sources to duckdb/duckdb@161b7454005b8e5bb6d68e5ae59b548928f83b9f.

  Date: 2026-04-09 10:16:47 +0000

  Push `row_number() OVER ()` into table scans to allow for better performance / parallelism (https://redirect.github.com/duckdb/duckdb/pull/21971)

  Unflavored-from: 0ddbbeb3b5e7ee6d742791b7babfdddf07b4215c

- Update vendored sources to duckdb/duckdb@38c6ea131e2c0baaed6dfdf10257ad6446756bd2.

  Date: 2026-04-09 09:52:31 +0000

  Use correct size in struct to variant to unified format (https://redirect.github.com/duckdb/duckdb/pull/21980)

  Unflavored-from: 73e6f587d8bfc82735a542900f2ff3ab2b43e513

- Update vendored sources to duckdb/duckdb@a217efdc04b26f12769966accb7ae52812353a5c.

  Date: 2026-04-09 09:13:45 +0000

  Issue https://redirect.github.com/duckdb/duckdb/pull/21908: Window Macro Expansion (https://redirect.github.com/duckdb/duckdb/pull/21963)
  Internal https://redirect.github.com/duckdb/duckdb/pull/8821: GenerateFunction WINDOW_FUNCTION_ENTRY (https://redirect.github.com/duckdb/duckdb/pull/21961)
  Issue template: Add new extensions (https://redirect.github.com/duckdb/duckdb/pull/21957)

  Unflavored-from: 16a78c8fd5585af36a0ade908363cb55a6278acc

- Update vendored sources to duckdb/duckdb@79f229b738d1a2e58e26ff7b17e5a834afa381ba.

  Date: 2026-04-09 06:07:37 +0000

  Make it so that STRUCT vectors themselves cannot be DICTIONARY vectors anymore (https://redirect.github.com/duckdb/duckdb/pull/21964)

  Unflavored-from: b3a554839de9c34245c5faae5037fb25c672ed4a

- Update vendored sources to duckdb/duckdb@7aec8a59555c61145ca1cb08189758886a9a1129.

  Date: 2026-04-08 19:08:40 +0000

  Fix bugs in ArrowQueryResult (https://redirect.github.com/duckdb/duckdb/pull/21852)

  Unflavored-from: 5c4db8c9921b1c206302dd50a9849e6e19239c4f

- Update vendored sources to duckdb/duckdb@1a5cb5f2e006fca5c812ac7b81f0446d82c103a9.

  Date: 2026-04-08 18:24:01 +0000

  Internal https://redirect.github.com/duckdb/duckdb/pull/8696: Window Function Binding (https://redirect.github.com/duckdb/duckdb/pull/21818)

  Unflavored-from: 47c33107d41a536bf042cd797f86edc58e467f64

- Update vendored sources to duckdb/duckdb@ffba8dd136fb18ea81e28d9166c58878c177aa88.

  Date: 2026-04-08 18:23:16 +0000

  Multiple minor fixes (https://redirect.github.com/duckdb/duckdb/pull/21920)

  Unflavored-from: d93181eeba61e24ed40dad8e36b633dc446fd134

- Update vendored sources to duckdb/duckdb@baaf7c11460fc547b745319c0933a6521e5eb85d.

  Date: 2026-04-08 18:23:03 +0000

  Add select hook to ScalarFunction (https://redirect.github.com/duckdb/duckdb/pull/21914)

  Unflavored-from: a5b112ffa62af1b8e8980e109295652db599fb1a

- Update vendored sources to duckdb/duckdb@e2c0cc600f7a638903d19252c6d0c7bf74c42964.

  Date: 2026-04-08 18:22:47 +0000

  Fix wrong cast in expression_heuristics.cpp (https://redirect.github.com/duckdb/duckdb/pull/21956)
  Improve vcpkg caching (https://redirect.github.com/duckdb/duckdb/pull/21951)
  Use simpler checkout logic (https://redirect.github.com/duckdb/duckdb/pull/21948)

  Unflavored-from: a5a9abb89d298b149e176ed759d5195eaa880909

- Update vendored sources to duckdb/duckdb@6db90820c4675dcb37cb13b034050dde130ce592.

  Date: 2026-04-08 07:49:01 +0000

  Vector: Move `ValidityMask` into `VectorBuffer` (https://redirect.github.com/duckdb/duckdb/pull/21935)
  Run slow tests in CI if `run_slow_tests` is true (https://redirect.github.com/duckdb/duckdb/pull/21926)
  MacOS: codesign debug / reldebug binaries on MacOS to allow debugging (https://redirect.github.com/duckdb/duckdb/pull/21930)
  CI fix (https://redirect.github.com/duckdb/duckdb/pull/21928)

  Unflavored-from: c295e5e9ed76593f5a2d5e00bac4aa83016c707b

- Update vendored sources to duckdb/duckdb@934a971d188e29338dbfac2b9da9ba425648a4b3.

  Date: 2026-04-07 16:52:56 +0000

  Fix TRY_CAST from BIT to small integer types throwing instead of returning NULL (https://redirect.github.com/duckdb/duckdb/pull/21901)

  Unflavored-from: 3ae9d1a120afe4cc908142c5f26e688a5e0fbde7

- Update vendored sources to duckdb/duckdb@8234eb43938abcc383a5ce0951cf46aad14d3a41.

  Date: 2026-04-07 13:39:18 +0000

  Avoid using `StringVector::AddString` as much as possible - use the `StringHeap` directly instead (https://redirect.github.com/duckdb/duckdb/pull/21921)

  Unflavored-from: 27eebffd8083e58ecd92dad2452dbea10a470741

- Update vendored sources to duckdb/duckdb@796be006a5ca0aa55f8f9720f088789a554b6bc3.

  Date: 2026-04-07 11:32:13 +0000

  Fix InstallFromHttpUrl unconditionally decompressing response as gzip (https://redirect.github.com/duckdb/duckdb/pull/21875)

  Unflavored-from: eb380c356bce7e06c349b86f154d748153543bae

- Update vendored sources to duckdb/duckdb@07e8327d8192737b94a92187005fb332f2079947.

  Date: 2026-04-07 10:52:06 +0000

  Fix move assignment for buffer pool reservation (https://redirect.github.com/duckdb/duckdb/pull/21918)

  Unflavored-from: 49410f8f3f66312b436a43d2b16b2c3c68e1f2d1

- Update vendored sources to duckdb/duckdb@b8cc33bbc9fc22d5a56f8544257df83241a91a09.

  Date: 2026-04-07 10:47:48 +0000

  Fix double evicted data decrement (https://redirect.github.com/duckdb/duckdb/pull/21917)

  Unflavored-from: 317d3ae4dd2bc2da77ef37dc457d5018fb517b5c

- Update vendored sources to duckdb/duckdb@f2dcb1f76f13bd9b431c578e23dc885fa46f1d0e.

  Date: 2026-04-07 10:42:56 +0000

  Fix column data allocator (https://redirect.github.com/duckdb/duckdb/pull/21911)
  Use prepare, linux-release, linux-debug and linux-base jobs. (https://redirect.github.com/duckdb/duckdb/pull/21812)

  Unflavored-from: fc5653b10b19d8b577dddd212ca07962e6d2b509

- Update vendored sources to duckdb/duckdb@48837b3d3f9b89b2a8f7795a9278acc505025339.

  Date: 2026-04-07 10:30:14 +0000

  Prefix Range Filter VARCHAR support (https://redirect.github.com/duckdb/duckdb/pull/21756)

  Unflavored-from: 84d67baae9ca577c44d251a9e9fb25d73b0ebb1d

- Update vendored sources to duckdb/duckdb@48163c9b4cf4ace0c2ae93ea3f7017f8168d7f46.

  Date: 2026-04-06 20:26:59 +0000

  Fix copy-paste typo: sequence dependency error message says "index" (https://redirect.github.com/duckdb/duckdb/pull/21892)
  Fix three inverted-condition bugs in CLI shell (https://redirect.github.com/duckdb/duckdb/pull/21857)

  Unflavored-from: 50556f6c1fb102228e7a929aab308e6c5f6b0bff

- Update vendored sources to duckdb/duckdb@8bab0d69c1478d1b0e842fe245f69db0cbfe5d99.

  Date: 2026-04-06 19:21:49 +0000

  Fix the issue of lost LOGs after truncate duckdb_logs (https://redirect.github.com/duckdb/duckdb/pull/21830)

  Unflavored-from: c398e8b66a570b2d589cff4c37ee9024e96bf1f1

- Update vendored sources to duckdb/duckdb@c74d4c2e3d2f2ed846ca3092bb21da5421fa0410.

  Date: 2026-04-06 18:58:37 +0000

  Add support for DML statements (INSERT/UPDATE/DELETE) as CTE bodies (https://redirect.github.com/duckdb/duckdb/pull/21634)

  Unflavored-from: 97f4cddf72814bd3a38614d05bd19854b5804468

- Update vendored sources to duckdb/duckdb@9475ec34f43531019353fd8e2ad4487eb7f703a7.

  Date: 2026-04-06 18:56:46 +0000

  Expose column tags via duckdb_columns() (https://redirect.github.com/duckdb/duckdb/pull/21794)

  Unflavored-from: a4fe81acb8d9326c735aff852d560af872fdf301

- Update vendored sources to duckdb/duckdb@90628df28564545e9f4716b9dbfc7bb5b292ad21.

  Date: 2026-04-06 12:19:54 +0200

  Update documentation links from docs/stable to docs/current (https://redirect.github.com/duckdb/duckdb/pull/21838)

  Unflavored-from: aecc784d0218345d3885d584689bf229811c1e4f

- Update vendored sources to duckdb/duckdb@7cdf8e69816023afa04d4071cfa95bdb0d7d1c3a.

  Date: 2026-04-06 10:16:30 +0000

  Fix parquet metadata type casting (https://redirect.github.com/duckdb/duckdb/pull/21894)

  Unflavored-from: c4dd2fd302151b8a4775a66274f6cf108c26b6af

- Update vendored sources to duckdb/duckdb@04a450b2cb29134a0a8c11afe137e468ad08564a.

  Date: 2026-04-06 08:37:35 +0000

  Fix more compilation warnings (https://redirect.github.com/duckdb/duckdb/pull/21839)

  Unflavored-from: 73af45266eed0e7dc64bc22342673ba9d2742641

- Update vendored sources to duckdb/duckdb@f3f983e44dc7d7dd0ff5070fd9c5ef56e323d87a.

  Date: 2026-04-06 08:35:53 +0000

  Fix DROP SECRET IF EXISTS throwing IOException when using FROM storage (https://redirect.github.com/duckdb/duckdb/pull/21877)

  Unflavored-from: c46dde3ff27925ac17a81fe3bba195f9c1ab4085

- Update vendored sources to duckdb/duckdb@d233d6dbcdbb54bb24a8bc5981b4892cc0f5cc36.

  Date: 2026-04-06 08:35:35 +0000

  Fix filter propagation: distinguish ALWAYS_FALSE from FALSE_OR_NULL (https://redirect.github.com/duckdb/duckdb/pull/21859)

  Unflavored-from: 832f22b443f0366cca4c8e3d7a5ba6e767dddb02

- Update vendored sources to duckdb/duckdb@b370e52093416935fbda67925e6b6f3924f93db4.

  Date: 2026-04-06 08:33:57 +0000

  Fix qualified alias method calls in HAVING/WHERE/QUALIFY (https://redirect.github.com/duckdb/duckdb/pull/21865)

  Unflavored-from: c4c65507263cfe66a38f7c5e655c1ca3c87c9186

- Update vendored sources to duckdb/duckdb@c60104433160fe4c4db38b46bb9d44d11d73347f.

  Date: 2026-04-06 08:26:27 +0000

  Remove unused `ArrowArrayStreamWrapper::number_of_rows` member (https://redirect.github.com/duckdb/duckdb/pull/21855)

  Unflavored-from: 484060d4528cc4d181d914167cdb09e807890e0a

- Update vendored sources to duckdb/duckdb@f231f91a61430afbb0a97aa3d61372d290626a2b.

  Date: 2026-04-06 08:12:48 +0000

  Fix null pointer dereference in profiler ToString for HTML/graphviz/mermaid formats (https://redirect.github.com/duckdb/duckdb/pull/21887)

  Unflavored-from: 3b6d18c2fa12a44c930e53716642fcf502c1ab21

- Update vendored sources to duckdb/duckdb@4f313ac3238e4eb945e8a30d446d8fbb30090874.

  Date: 2026-04-06 08:12:23 +0000

  Fix out-of-bounds read in list_where when boolean mask is longer than input list (https://redirect.github.com/duckdb/duckdb/pull/21879)

  Unflavored-from: 337a6d5cf7a47dc4108faf7b5fd913d4dd42e32c

- Update vendored sources to duckdb/duckdb@538d289feaab26a6f599c7d0e79a50b6722955b9.

  Date: 2026-04-05 21:39:23 +0000

  Remove shadowed event member and unused names from ArrowBatchTask (https://redirect.github.com/duckdb/duckdb/pull/21856)

  Unflavored-from: 15a2f52d12665b1702acee641e69d0dd5bf6a065

- Update vendored sources to duckdb/duckdb@7acab0a835d6a1027e46662d81face50754f4b40.

  Date: 2026-04-05 21:37:34 +0000

  Preserve table sample in InitializeAddConstraint (https://redirect.github.com/duckdb/duckdb/pull/21858)

  Unflavored-from: 8a17108c7d1734bd7daef6fe7556adfdb7a08086

- Update vendored sources to duckdb/duckdb@1ebc8603db31188ac247e78b4bf9455a56bd71d2.

  Date: 2026-04-05 21:27:33 +0000

  Fix atanh(-1) returning +inf instead of -inf (https://redirect.github.com/duckdb/duckdb/pull/21878)

  Unflavored-from: 70d364172a0786d54baf917386eeb6fdd025e58c

- Update vendored sources to duckdb/duckdb@4ce9d50f97e30208f4f78d28a9b54b63a93d1696.

  Date: 2026-04-05 21:24:28 +0000

  Fix datediff overflow for week and microsecond parts with extreme dates (https://redirect.github.com/duckdb/duckdb/pull/21882)
  Fix autocomplete fuzzy suggestion limit comparing string length instead of result count (https://redirect.github.com/duckdb/duckdb/pull/21883)

  Unflavored-from: de6b8b047e5989d79d003dd0f6f54ad0913fc15a

- Update vendored sources to duckdb/duckdb@e859c25d67ef1b8662d69cfd579745723f5e28f5.

  Date: 2026-04-05 21:20:17 +0000

  Fix SYSTEM_PEAK_BUFFER_MEMORY profiler metric accumulating instead of tracking peak (https://redirect.github.com/duckdb/duckdb/pull/21886)

  Unflavored-from: 8ebdc7b3fe55cabf10424e5246fd4b333d738bfd

- Update vendored sources to duckdb/duckdb@d83ed3f6c9e4de1980318bdb52c842d8319e0b8a.

  Date: 2026-04-04 18:29:08 +0000

  When using `FlatVector::Writer<string_t>` - automatically copy strings to the result vector (instead of needing them to be copied manually) (https://redirect.github.com/duckdb/duckdb/pull/21816)
  Compute CI jobs and save_cache dynamically (https://redirect.github.com/duckdb/duckdb/pull/21799)

  Unflavored-from: fcb437833fba28cc062dbc878e356c37ea4ceff2

- Update vendored sources to duckdb/duckdb@2bdd7b54b18a99a31f4bdba240cfaede0b7fbee4.

  Date: 2026-04-03 14:16:01 +0200

  Internal https://redirect.github.com/duckdb/duckdb/pull/8500: Window Function Binding (https://redirect.github.com/duckdb/duckdb/pull/21562)

  Landing v2 (finding 3): `rapi_expr_window()` passes `lag()` and `lead()` the default offset of 1 before a default given without an offset, which the engine would otherwise read as the offset (`src/relational.cpp`).

  Unflavored-from: 27c2b478f584e2ff4b6e2449d93142c1af54f479

- Update vendored sources to duckdb/duckdb@b8158436f8e5c6788a2894dde9bb8d52f5bf178e.

  Date: 2026-04-03 14:08:43 +0200

  Add `FlatVector::Writer<T>(result, count)` method to standardize writing to a flat vector (https://redirect.github.com/duckdb/duckdb/pull/21808)

  Unflavored-from: 2d96721dcde21d395d9ef5cebebb3d33efc2b719

- Update vendored sources to duckdb/duckdb@d01e34213eade220c103643bdd8447de8eaa6029.

  Date: 2026-04-03 13:14:10 +0200

  \[minor\] Fix compilation warning (https://redirect.github.com/duckdb/duckdb/pull/21806)

  Unflavored-from: bee0ef06c0f3ae72244443babc238ce5aaa410c9

- Update vendored sources to duckdb/duckdb@af66da7d6cb98a933e6f08390ba3661a15a54818.

  Date: 2026-04-03 08:43:27 +0200

  Fix CSV assertion failure for CSV type deduction incompatibility (https://redirect.github.com/duckdb/duckdb/pull/21778)

  Unflavored-from: 8db35e14598e815130aea6367db926e742ee4dbc

- Update vendored sources to duckdb/duckdb@c33978978a8690ad04a7c86ec504b73b3867a05d.

  Date: 2026-04-02 21:43:46 +0200

  Add helper method for ConstantVector::SetNull (https://redirect.github.com/duckdb/duckdb/pull/21798)
  Oss-Fuzz: add harness for csv/json targets (https://redirect.github.com/duckdb/duckdb/pull/21790)

  Unflavored-from: cf208746531b9999897efca598599a09ee4d1745

- Update vendored sources to duckdb/duckdb@76d344c96482f96811429b9a6bdd9fd454b3d8bf.

  Date: 2026-04-02 17:31:49 +0200

  Rework vector buffers to remove the `auxiliary` buffer and move everything into a single `VectorBuffer` (https://redirect.github.com/duckdb/duckdb/pull/21786)

  Unflavored-from: 75221e9f838c367be26882ef9993ea43e58b93dd

- Update vendored sources to duckdb/duckdb@73f63c4377ec42ab41a361dd28a8977d4a152315.

  Date: 2026-04-02 17:29:47 +0200

  Add json_strip_nulls() to recursively remove null-valued keys (https://redirect.github.com/duckdb/duckdb/pull/21748)
  \[CI\] More new test string CI fixes (https://redirect.github.com/duckdb/duckdb/pull/21782)
  Use changed tests from prepare in smoke tests (https://redirect.github.com/duckdb/duckdb/pull/21789)

  Unflavored-from: 9f8bbe0540d9304e12f662998e66b008a5930831

- Update vendored sources to duckdb/duckdb@aab96e0ee27c23c6db2011ffdcb552a60a32c50f.

  Date: 2026-04-02 16:16:53 +0200

  Add casts to pushed down join filters (https://redirect.github.com/duckdb/duckdb/pull/21791)
  \[Profiling\] Add schema to metric_type.json (https://redirect.github.com/duckdb/duckdb/pull/21196)
  Use ccache for windows/wasm, and merge some CI jobs (https://redirect.github.com/duckdb/duckdb/pull/21770)

  Unflavored-from: fc0f9685aefa1d2fe440a967dc735cf6debb1544

- Update vendored sources to duckdb/duckdb@61a034689cc167747be4856c120dc77266c5b697.

  Date: 2026-04-02 14:13:04 +0200

  Remove all_profiling_output() (https://redirect.github.com/duckdb/duckdb/pull/21785)

  Unflavored-from: c0b5dad41c5098103fb9c8b739de4c4aaf7429a9

- Update vendored sources to duckdb/duckdb@1c8323b70d8799296348bb0f874a1be6a07155a0.

  Date: 2026-04-02 13:38:52 +0200

  Add expression as DatabasePath argument to ATTACH (https://redirect.github.com/duckdb/duckdb/pull/21693)

  Unflavored-from: 2fcdf1ffcadd892313c0a53a4eba022cc2b4ec95

- Update vendored sources to duckdb/duckdb@cb84acb669e53855bcf561c5d7fba818b20dd722.

  Date: 2026-04-02 12:58:45 +0200

  Fix CSV string value scanner access out-of-bound (https://redirect.github.com/duckdb/duckdb/pull/21780)

  Unflavored-from: b91d3497d5605e8b5e16004148e8190c34d8c54d

- Update vendored sources to duckdb/duckdb@417a23935657bbea4d64273911ae8d14556c6e2d.

  Date: 2026-04-02 11:22:26 +0200

  Return inf/nan instead of throwing for stddev/variance overflow (https://redirect.github.com/duckdb/duckdb/pull/21673)

  Unflavored-from: 3a67a00223dca4b0e51244cbc3b05763d1f0de7e

- Update vendored sources to duckdb/duckdb@e5b1c039dce33342ad5dbfb25f2f48d8efa96cd8.

  Date: 2026-04-02 09:51:07 +0200

  Add catalog storage and introspection for CREATE TRIGGER (https://redirect.github.com/duckdb/duckdb/pull/21438)

  Unflavored-from: f76b934c4dbcddd153624f83d61c3da9c61f197f

- Update vendored sources to duckdb/duckdb@7cdebc820e305c44bf4ac03ccff023a6c80f2071.

  Date: 2026-04-01 18:42:37 +0200

  Merge `v1.5-variegata` into main (https://redirect.github.com/duckdb/duckdb/pull/21768)
  \[Nightly Fix\] Move result and use new string syntax in inet and httpfs (https://redirect.github.com/duckdb/duckdb/pull/21767)
  Stabilize main workflow (https://redirect.github.com/duckdb/duckdb/pull/21765)

  Unflavored-from: 3bd86a86f94bd70f8281e4d03cae5d882f6fb9f7

- Update vendored sources to duckdb/duckdb@b0d5c17945f72d46f2dd9ec189f1902790fffdcd.

  Date: 2026-04-01 13:34:05 +0200

  Allow ALTER TABLE ... RENAME TO on views (https://redirect.github.com/duckdb/duckdb/pull/21759)
  Merge external extension batches back into 1 (https://redirect.github.com/duckdb/duckdb/pull/21741)

  Unflavored-from: 4f08dc3e6c2e45317fa32f957db01bc73fcc8f9f

- Update vendored sources to duckdb/duckdb@b149638b584179a4b15bbc9eecbbbc51d51c330d.

  Date: 2026-04-01 10:51:13 +0200

  FIX https://redirect.github.com/duckdb/duckdb/pull/21506 UNNEST ARRAY type functionality (https://redirect.github.com/duckdb/duckdb/pull/21672)
  Improve some CI jobs (https://redirect.github.com/duckdb/duckdb/pull/21736)

  Unflavored-from: 69d7bbe59c5517c04b8264582bf2760f1718b40f

- Update vendored sources to duckdb/duckdb@ebc4a240c790f3dd426d347679beed1a585fb306.

  Date: 2026-03-31 17:08:38 +0200

  Add call to SetEstimatedCardinality in more physical operators (https://redirect.github.com/duckdb/duckdb/pull/21737)

  Unflavored-from: e7b55b8cfb2961b48c0f325b861ce65e2afbd311

- Update vendored sources to duckdb/duckdb@70ae43c16db87e66badaf9b52261fe5cb5136c60.

  Date: 2026-03-31 15:39:59 +0200

  chore: add extension_name to `duckdb_functions` and `duckdb_types` (https://redirect.github.com/duckdb/duckdb/pull/20752)
  Unflavored-from: 965718e1522383c28dd87d33567d9b04fcbbc127

- Update vendored sources to duckdb/duckdb@9baded7249f1ae3b15ca453997f8d07cc87eb6b1.

  Date: 2026-03-31 13:01:05 +0200

  Add json_merge_patch_diff() -- compute RFC 7396 merge patch from two documents (https://redirect.github.com/duckdb/duckdb/pull/21668)

  Unflavored-from: a7d1d79c918512abe9483b54f5fd1c6fa33ae5ca

- Update vendored sources to duckdb/duckdb@5dcf752260ddfd93ab176bfd6c993ab4c78f6031.

  Date: 2026-03-31 12:34:19 +0200

  Always (approximately) sort when creating an ART index (https://redirect.github.com/duckdb/duckdb/pull/21706)

  Unflavored-from: 963d18f187c8a319a8c056f95b8ec72a8404edf9

- Update vendored sources to duckdb/duckdb@14daeaf2307e2b68ea0203cad28f5e3f88a01095.

  Date: 2026-03-31 12:34:05 +0200

  Re-enable row-level filtering for `SelectivityOptionalFilter` (https://redirect.github.com/duckdb/duckdb/pull/21704)
  Consistently use `{TEST_VAR}` for all test variables (loop indexes, `__TEST_DIR__`, environment variables) - and print a deprecated warning on the old syntax (https://redirect.github.com/duckdb/duckdb/pull/21728)

  Unflavored-from: d35aac0c778b76ed2df9769e3cf4328f0481ce07

- Update vendored sources to duckdb/duckdb@c7958ceeeb44be926215f20fe919ab6b0383cbf2.

  Date: 2026-03-31 10:33:57 +0200

  Add support for formatting SQL statements to the CLI (https://redirect.github.com/duckdb/duckdb/pull/21725)
  Merge code quality CI jobs into main workflow (https://redirect.github.com/duckdb/duckdb/pull/21723)
  Internal https://redirect.github.com/duckdb/duckdb/pull/7738: Semi HashJoin Fix (https://redirect.github.com/duckdb/duckdb/pull/21724)

  Unflavored-from: 4d4de882832afd060351766dcc833039ed4fc7cd

- Update vendored sources to duckdb/duckdb@7f943f0565cdd3528a6638f592ce35a928e2b0d9.

  Date: 2026-03-30 20:08:33 +0200

  Merge `v1.5-variegata` into main (https://redirect.github.com/duckdb/duckdb/pull/21720)
  Use correct ccache keys for linux release and CLI jobs (https://redirect.github.com/duckdb/duckdb/pull/21713)

  Unflavored-from: b97285293bcfeb58f158b23ecf10fa32b3e7798f

- Update vendored sources to duckdb/duckdb@a5396921b36b0babe6c8092674c754ad9a938b55.

  Date: 2026-03-30 12:49:35 +0200

  Fix remaining clang-tidy issues on main (https://redirect.github.com/duckdb/duckdb/pull/21705)
  Run compatibilty storage tests in parallel (https://redirect.github.com/duckdb/duckdb/pull/21328)

  Unflavored-from: ce7fb2fe83700be0154fa7492fa92791358a36b1

- Update vendored sources to duckdb/duckdb@eb90dc6379c723ed2f2a47ec182464c7d1987dd6.

  Date: 2026-03-30 09:51:23 +0200

  Prevent timestamp operation out-of-range for external file cache (https://redirect.github.com/duckdb/duckdb/pull/21681)

  Unflavored-from: d63136610e7281bb27a4d278d9a133308d103e19

- Update vendored sources to duckdb/duckdb@524d1c0d1de5d1f77e9165b126a862ee5b16cb68.

  Date: 2026-03-30 09:50:06 +0200

  Remove duplicate code (https://redirect.github.com/duckdb/duckdb/pull/21684)

  Unflavored-from: c32a8a629b2c918e8ab4bcf1aad9674fbee8836e

- Update vendored sources to duckdb/duckdb@9a48abd9136717545d4c28772536df56272e60fe.

  Date: 2026-03-30 09:49:11 +0200

  Extend TopN dynamic filter pushdown to FLOAT and DOUBLE (https://redirect.github.com/duckdb/duckdb/pull/21689)
  Fix workflow lint issue (https://redirect.github.com/duckdb/duckdb/pull/21702)
  Fix shell expansion issue in draft PR workflow (https://redirect.github.com/duckdb/duckdb/pull/21701)

  Unflavored-from: 7ffe0c7852dc35b0857968a3058df11160dc7503

- Update vendored sources to duckdb/duckdb@e6de16f8abcad9f1ee1f687b3ba32818498a0988.

  Date: 2026-03-28 17:34:28 +0100

  Rename `ValidityMask::AllValid` to `ValidityMask::CannotHaveNull` (https://redirect.github.com/duckdb/duckdb/pull/21679)

  Carried from `origin/v2.0-cyanoptera-dev` at 3a60a96fbb:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: a6a97a2701981c273da4a23390612781738583f3

- Update vendored sources to duckdb/duckdb@9cb0937984f38c2b33919aef36157a2f3140c6ee.

  Date: 2026-03-28 15:05:37 +0100

  Handle constant vector optimization at the expression executor level instead of inside every function (https://redirect.github.com/duckdb/duckdb/pull/21674)

  Unflavored-from: 8276cbe7323b6f7e4bb6353da55dc186abf18683

- Update vendored sources to duckdb/duckdb@730748c6f99c1f403806c3ba09864218603b8b45.

  Date: 2026-03-28 09:58:30 +0100

  \[Fix\] to https://redirect.github.com/duckdb/duckdb/pull/18259 WAL replay failure (https://redirect.github.com/duckdb/duckdb/pull/21608)

  Unflavored-from: 83c657bbcc0bd39115a7718acd3c769fdb8bb427

- Update vendored sources to duckdb/duckdb@bc023aea4560cd8f1ca6d35d1b4ce1d716e925c4.

  Date: 2026-03-28 09:46:18 +0100

  Optimize `TemplatedMergeJoinComplexBlocks` in `PhysicalPieceWiseMergeJoin` (https://redirect.github.com/duckdb/duckdb/pull/21667)

  Unflavored-from: 7c420498ee51c94f27443f1c112662c9292a7fd6

- Update vendored sources to duckdb/duckdb@9575d227bc216d628dcb888336e3c1f811e7b8c7.

  Date: 2026-03-27 19:29:13 +0100

  Fix race condition: successful COMMIT incorrectly reported as interrupted (https://redirect.github.com/duckdb/duckdb/pull/21616)

  Unflavored-from: 3f16af4938b5ae1f5af84619c2211372d15c9040

- Update vendored sources to duckdb/duckdb@ea2c86420a8adb9a8dc1aeac3ddad24fb5854d90.

  Date: 2026-03-27 19:23:14 +0100

  Fix a few class construction UB (https://redirect.github.com/duckdb/duckdb/pull/21670)

  Unflavored-from: da8f25263bf5de3b041d836272ce21e8daaa7431

- Update vendored sources to duckdb/duckdb@bafce912d6409aef952813196b2ad6ac3071cf2f.

  Date: 2026-03-27 19:19:05 +0100

  Add iterator helpers over vectors, instead of requiring manually calling `ToUnifiedFormat` (https://redirect.github.com/duckdb/duckdb/pull/21666)
  .git pre-commit hook for `make format-fix` (https://redirect.github.com/duckdb/duckdb/pull/21665)

  Unflavored-from: da8d77f24d19801094a3c4f9dbfa496dd8138c04

- Update vendored sources to duckdb/duckdb@de2ea52101cb0592348c17c994dada24c45d5282.

  Date: 2026-03-27 19:17:32 +0100

  Unify `LocalFileSystem::GetVersionTag` to use `FileMetadata`, and change Windows ListFiles so that we can compute version tags without additional system calls (https://redirect.github.com/duckdb/duckdb/pull/21664)

  Unflavored-from: b0494485ade4f043bfdc483e47c532af4db8b361

- Update vendored sources to duckdb/duckdb@5270ec54ad3e60bea19783ef5123675994fbcddf.

  Date: 2026-03-27 14:37:28 +0100

  Add ubigint_t class which does checked arithmetic, and use it in list_resize (https://redirect.github.com/duckdb/duckdb/pull/21659)

  Unflavored-from: 3fa9807c361a7c62abd0cd425a85f80724a090a1

- Update vendored sources to duckdb/duckdb@8d147eac19a416048315600770eaf7c51adb25c0.

  Date: 2026-03-27 12:29:56 +0100

  Fix all tidy errors (https://redirect.github.com/duckdb/duckdb/pull/21647)
  Cleanup the build (https://redirect.github.com/duckdb/duckdb/pull/21620)
  Use test runner in all windows CI jobs (https://redirect.github.com/duckdb/duckdb/pull/21648)

  Unflavored-from: bb0fb1ce834e26fb4c382988c31a75138ee3784a

- Update vendored sources to duckdb/duckdb@cfc2db18aba7bdd9a11bcd109ffa6e810ba53b79.

  Date: 2026-03-27 10:09:30 +0100

  Invalid input exception for corrupted encrypted parquet files (https://redirect.github.com/duckdb/duckdb/pull/21646)

  Unflavored-from: 6c97bdbed6bef1417681a7bf0f7e16a8a1a9ffd1

- Update vendored sources to duckdb/duckdb@09a0093cb5d250ca8e5d7ae45d1090c602f8e516.

  Date: 2026-03-27 10:03:59 +0100

  Fix crash in `Vector::Resize` for STRUCT types (https://redirect.github.com/duckdb/duckdb/pull/21644)
  Lint workflows and fix existing lint errors/warnings (https://redirect.github.com/duckdb/duckdb/pull/21643)

  Unflavored-from: 93ced1c1c7664165515748ed4fb4b559acf68f9f

- Update vendored sources to duckdb/duckdb@21a84a7608d5e8476a5f5b1a9c512ea2b6bff412.

  Date: 2026-03-26 15:08:51 +0100

  Vector API: Make `ToUnifiedFormat` const, and make the data pointer within the `UnifiedVectorFormat` a `const_data_ptr` (https://redirect.github.com/duckdb/duckdb/pull/21631)

  Unflavored-from: 7e208204291c83982e0daa2f763c2f4339c4448a

- Update vendored sources to duckdb/duckdb@8c0256f401679c33e366f52eff70c21f2c539d39.

  Date: 2026-03-26 13:02:04 +0100

  BoxRenderer: Adding ColumnDataCollectionRenderInterface abstraction (https://redirect.github.com/duckdb/duckdb/pull/21624)
  Re-enable Win32 and MinGW jobs in CI (https://redirect.github.com/duckdb/duckdb/pull/21619)

  Unflavored-from: d3960f8500bf670a34cc2590733560877e5a9803

- Update vendored sources to duckdb/duckdb@c38024fd15ecc2a28a37647db81807a311423c1d.

  Date: 2026-03-26 10:14:00 +0100

  Implement block-aligned read and cache for external file cache (https://redirect.github.com/duckdb/duckdb/pull/21395)
  \[autocomplete\] Use AutoCompleteCatalogProvider abstraction (https://redirect.github.com/duckdb/duckdb/pull/21621)

  Unflavored-from: 998869fe31f7b3ec0c1eb76b203b853e9b0a11a2

- Update vendored sources to duckdb/duckdb@8d114b711c191c2b5ba80b72a09bb4bc36aec700.

  Date: 2026-03-25 16:50:09 +0100

  checkpoint_on_detach 3-valued setting (https://redirect.github.com/duckdb/duckdb/pull/21570)

  Unflavored-from: 876e1cf760f02c671b4368f2aa6c6cb427c8d2f1

- Update vendored sources to duckdb/duckdb@5029f0f94563c4012118d65b749f9500d9a822d9.

  Date: 2026-03-25 16:48:17 +0100

  Fix FK reference resolution for external catalogs (https://redirect.github.com/duckdb/duckdb/pull/21607)
  Fix some nightly run errors (https://redirect.github.com/duckdb/duckdb/pull/21613)
  Merge Linux cli CI jobs into main (https://redirect.github.com/duckdb/duckdb/pull/21614)

  Unflavored-from: 9e1ad4fa2afbd67bffb040ecb4ea82307b524590

- Update vendored sources to duckdb/duckdb@44f79e1161fbf170d019beb553773ebc49731144.

  Date: 2026-03-25 15:25:35 +0100

  Vector: make `Flatten` work for `const` vectors, and remove implicit sort-of-copy constructor (https://redirect.github.com/duckdb/duckdb/pull/21612)

  Carried from `origin/v2.0-cyanoptera-dev` at aac0b6310e:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: 4e458798c1d7b1b2fcacaa2105c3d3cd97befd92

- Update vendored sources to duckdb/duckdb@005055af1f7d133d35839b45a413025258811d83.

  Date: 2026-03-25 15:19:04 +0100

  Run windows amd64 CI job on namespace runner (https://redirect.github.com/duckdb/duckdb/pull/21557)

  Unflavored-from: 10b0ce058406ffd3cb80f4bcf64821e8f807df08

- Update vendored sources to duckdb/duckdb@7d8ff05a294126c1ef41a9e1d3e2e2906b0d7b75.

  Date: 2026-03-25 13:52:27 +0100

  Refactor InsertStatement as thin wrapper over InsertQueryNode (https://redirect.github.com/duckdb/duckdb/pull/21596)

  Unflavored-from: 2d85d1b356209b7cf6c3c83e4389493bb3674955

- Update vendored sources to duckdb/duckdb@2b227bfeb219991ea4ae809598ab7be242c7e85d.

  Date: 2026-03-25 10:06:39 +0100

  Add json_normalize() and json_deep_merge() scalar functions (https://redirect.github.com/duckdb/duckdb/pull/21531)

  Unflavored-from: 5d8092284aacd96dd20706c22844d30959a92943

- Update vendored sources to duckdb/duckdb@cc56eec77b4b83e1a9bfef9653a0e6fc25733b8a.

  Date: 2026-03-25 08:13:25 +0100

  Fix off-by-one error in PropagateStatistics for date_part (https://redirect.github.com/duckdb/duckdb/pull/21606)

  Unflavored-from: 752f5be35c493c610a851c22f34a21a56f4a225f

- Update vendored sources to duckdb/duckdb@32cd03e1d7c3ace2bbabfd4b9fe23bf52cfc4de6.

  Date: 2026-03-25 07:58:39 +0100

  Move data from Vector into VectorBuffer (https://redirect.github.com/duckdb/duckdb/pull/21597)
  Exclude slow tests from debug verification (https://redirect.github.com/duckdb/duckdb/pull/21587)
  Fix GCC compile flags on reconfigure (https://redirect.github.com/duckdb/duckdb/pull/21376)
  Pass runners to extension jobs and reuse linux build (https://redirect.github.com/duckdb/duckdb/pull/21575)

  Unflavored-from: 3f5ba0b37614776326685edee09bf2bbf37c18c4

- Update vendored sources to duckdb/duckdb@be74a3d86cfe0b12fedbe6f9fdc92ead767bd628.

  Date: 2026-03-24 17:34:22 +0100

  Refactor DeleteStatement as thin wrapper over DeleteQueryNode (https://redirect.github.com/duckdb/duckdb/pull/21556)

  Unflavored-from: 0ccc5458bdec00af3f3be9df340f1ba66c82f566

- Update vendored sources to duckdb/duckdb@7fe6d721edede464c6aac41d9ca8547d8016ee9a.

  Date: 2026-03-24 13:10:00 +0100

  Fix wasm build: use **EMSCRIPTEN** instead of deprecated EMSCRIPTEN (https://redirect.github.com/duckdb/duckdb/pull/21576)

  Unflavored-from: 282d00696264622752fd7eaefe353556a5e63bf9

- Update vendored sources to duckdb/duckdb@c95182706de3a00114b2c47d3c025c9184151ccc.

  Date: 2026-03-24 09:57:42 +0100

  Fix cardinality estimation for uncommitted rows (https://redirect.github.com/duckdb/duckdb/pull/21573)

  Unflavored-from: eb22e851c8f1837d3dbc78d4d93739b6f8472a0c

- Update vendored sources to duckdb/duckdb@3c9066ad59b6bc8540d76ed762b42a744b179551.

  Date: 2026-03-23 20:42:16 +0100

  Re-organize vectors: move various vector methods to different files (https://redirect.github.com/duckdb/duckdb/pull/21563)

  Unflavored-from: 6f7d5f573a39ebae04994ebeb6dd409efbfe3e98

- Update vendored sources to duckdb/duckdb@3ac07aebe5e6334e5bc3e90f3352eb4dca9c9026.

  Date: 2026-03-23 20:42:00 +0100

  Merge v1.5-variegata into main (https://redirect.github.com/duckdb/duckdb/pull/21555)

  R-side fix

- Update vendored sources to duckdb/duckdb@4a4693fb98736c345a0e9d221bdd6041e5a7a2fa.

  Date: 2026-03-23 18:09:24 +0100

  Fix Parquet dictionary index bit widths (https://redirect.github.com/duckdb/duckdb/pull/21532)
  Fix linux base and extension deployment on main (https://redirect.github.com/duckdb/duckdb/pull/21554)

  Unflavored-from: a12395616bdbf0177f37cfec861bae912a267a17

- Update vendored sources to duckdb/duckdb@a4e17f2b89e8d18c0aa58f886fc880fb7cc82bb3.

  Date: 2026-03-23 15:58:34 +0100

  Checkpoint transactions (https://redirect.github.com/duckdb/duckdb/pull/21382)

  Unflavored-from: 068431452578d70648f05f5e56b76cedee8b245c

- Update vendored sources to duckdb/duckdb@a107a6dc0b8e720a080d7ce8dfb4c6680b708838.

  Date: 2026-03-23 15:17:34 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/8472: Window Catalog Entries (https://redirect.github.com/duckdb/duckdb/pull/21446)

  Unflavored-from: 583c63eb407eb0f790425d9c41df644e1a53d85a

- Update vendored sources to duckdb/duckdb@7c8d66f07a23d613ce276b4a448802c2dc9df6be.

  Date: 2026-03-23 14:34:43 +0100

  Fix typos in comments: overriden, initalize (https://redirect.github.com/duckdb/duckdb/pull/21543)

  Unflavored-from: a4c0e338559ff61751dfd2254896c95b26a638f8

- Update vendored sources to duckdb/duckdb@16354bb092236534702633831fb2b18c56baea8f.

  Date: 2026-03-23 13:34:29 +0100

  Refactor UpdateStatement as thin wrapper over UpdateQueryNode (https://redirect.github.com/duckdb/duckdb/pull/21524)

  Unflavored-from: 7bb75e5df98ca09ac7ecf9e9c5dac247c094ea28

- Update vendored sources to duckdb/duckdb@0be6883a44154b2b6b89ecfe6df292925efe9c10.

  Date: 2026-03-23 10:46:50 +0100

  Attempt to fix encryption config initialization on parquet reader (https://redirect.github.com/duckdb/duckdb/pull/21548)

  Unflavored-from: 95ee76e7d47547287aa249a9caa30f3afb32fdbc

- Update vendored sources to duckdb/duckdb@7e7ee2bdd7be363c44e8943c30c25386e0acab1d.

  Date: 2026-03-22 08:42:31 +0100

  Make StructVector have the same layout as DataChunk (vector) (https://redirect.github.com/duckdb/duckdb/pull/21534)

  Carried from `origin/v2.0-cyanoptera-dev` at d4e4bb726f:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: de3451313efb29d4f4e58827ad25fd96d3609e7d

- Update vendored sources to duckdb/duckdb@b51395d299506d442b42279e09307176bf3f766f.

  Date: 2026-03-21 09:57:22 +0100

  Move vector types / vector buffer types to different headers (https://redirect.github.com/duckdb/duckdb/pull/21526)

  Carried from `origin/v2.0-cyanoptera-dev` at 1f84348354:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: dce1e022e02ee773323f872aac0d621d28ad4dc0

- Update vendored sources to duckdb/duckdb@e31cb5d54776a9c8ace2a0eec3e08ab2a4c5f54d.

  Date: 2026-03-21 09:57:14 +0100

  Make JSON copy to file no longer bind twice (https://redirect.github.com/duckdb/duckdb/pull/21522)
  Use the parser to provide better annotations for the tokenizer (https://redirect.github.com/duckdb/duckdb/pull/21523)

  Unflavored-from: 2f406b1e330fe778a6fabc04ee8db8c6fafd2ca6

- Update vendored sources to duckdb/duckdb@8e8d04c25271db88ddb5d4526b8944d9ac5fa318.

  Date: 2026-03-20 15:02:43 +0100

  Fix WAL replay with function-based DEFAULT (https://redirect.github.com/duckdb/duckdb/pull/21516)

  Unflavored-from: b084225dc98557d124bfcc02d71e4de6976039ea

- Update vendored sources to duckdb/duckdb@41b6b19290c811c7259a9c1ed6e9f7351f53d809.

  Date: 2026-03-20 14:43:15 +0100

  Move `PhysicalCopyToFile` logic over to Prepare/Flush Batch API (https://redirect.github.com/duckdb/duckdb/pull/21480)

  Unflavored-from: a7abc58e65dac780769e70ea3a26e51599c0468a

- Update vendored sources to duckdb/duckdb@f90c2a1a0466561740abb15081ea7ae8b3167cd8.

  Date: 2026-03-20 14:18:23 +0100

  Add DROP TRIGGER parsing support (PEG parser) (https://redirect.github.com/duckdb/duckdb/pull/21434)

  Unflavored-from: a497aaa686f24a9eec8dc50086e7488a0dd2ee06

- Update vendored sources to duckdb/duckdb@dbc32af758b7fe35f3368b1d97bed93e77d19499.

  Date: 2026-03-20 13:49:45 +0100

  Rework DefaultMacro to just use the macro definition, instead of decomposing it into separate parts (https://redirect.github.com/duckdb/duckdb/pull/21510)
  bump duckdb-sqlsmith (https://redirect.github.com/duckdb/duckdb/pull/21483)

  Unflavored-from: 868b8bf8357a888d61ffc07bdadb35a870047612

- Update vendored sources to duckdb/duckdb@2d0e197f893af79c5282c967f99444b977298426.

  Date: 2026-03-20 12:50:52 +0100

  Use **COUNTER** for setting index to avoid merge conflicts between PRs that both add settings (https://redirect.github.com/duckdb/duckdb/pull/21509)

  Unflavored-from: a3426b9a91140bf1dc1b78e56712b382b961e74d

- Update vendored sources to duckdb/duckdb@9c4e82ecae0104f7ae2ac3a9fdef2a20b9439357.

  Date: 2026-03-20 12:50:45 +0100

  For CREATE VIEW IF NOT EXISTS - skip binding the view if the view already exists (https://redirect.github.com/duckdb/duckdb/pull/21513)

  Unflavored-from: 1df96dbdbb1bd7e6b2e8e1cb67dc1f9c8c8bd113

- Update vendored sources to duckdb/duckdb@6d899570410ff19f7630f2aca1bbefae7e8e49a2.

  Date: 2026-03-20 08:35:47 +0100

  Enable filters on pushdown extract (https://redirect.github.com/duckdb/duckdb/pull/21498)

  Unflavored-from: d5fab54bd40130cfb416544a9fcb3cde09008c34

- Update vendored sources to duckdb/duckdb@ee6e77c3a4a9d6aa31468587194abc9f7634999f.

  Date: 2026-03-19 19:02:13 +0100

  Fix hidden merge conflict in table filter code (https://redirect.github.com/duckdb/duckdb/pull/21497)

  Carried from `origin/v2.0-cyanoptera-dev` at 27460b2a35:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: c79537576018511b4c4ed2b469cd3e9d0351bc57

- Update vendored sources to duckdb/duckdb@56b667fbd6e5fddd6f4c8f3c4960c49a9341e0b9.

  Date: 2026-03-19 11:31:35 +0100

  introducing TryPushdownRelaxedFilter (https://redirect.github.com/duckdb/duckdb/pull/21350)
  Internal https://redirect.github.com/duckdb/duckdb/pull/8474: ICU Version 77-1 (https://redirect.github.com/duckdb/duckdb/pull/21476)

  Unflavored-from: d590376ae864d797ee292788b2ac6e2a5a7e0300

- Update vendored sources to duckdb/duckdb@1225c919a2a8e4aab33f30486c60fb9efaf3873f.

  Date: 2026-03-19 08:47:53 +0100

  Merge v1.5-variegata into main (https://redirect.github.com/duckdb/duckdb/pull/21449)
  Create SECURITY.md (https://redirect.github.com/duckdb/duckdb/pull/21396)

  Unflavored-from: 57b57b0c783a44604bb81d323db257956c576e8e

- Update vendored sources to duckdb/duckdb@08fa4cfcbe75bf13a148fde50be631ff7a9d359c.

  Date: 2026-03-18 22:21:07 +0100

  Distribute work partition-wise when inserting into `JoinHashTable` (https://redirect.github.com/duckdb/duckdb/pull/21456)

  Unflavored-from: b0e60e609186b3794a498ae84d75079c477249ee

- Update vendored sources to duckdb/duckdb@9cccebbb9f0670619e3b68c76759c390d952ea58.

  Date: 2026-03-18 22:20:24 +0100

  Internal issue 7738 follow-up (https://redirect.github.com/duckdb/duckdb/pull/21463)

  Unflavored-from: c003085f4e225d41a046dda717ef35fe4c2bdd08

- Update vendored sources to duckdb/duckdb@2fcf41263859f3430a73ed6ef8155e4124ff0390.

  Date: 2026-03-18 15:59:12 +0100

  Parquet: support for writing timestamps as INT96 (https://redirect.github.com/duckdb/duckdb/pull/21454)
  Unflavored-from: 1cd2b230b522416792f15716506776b89aa50b32

- Update vendored sources to duckdb/duckdb@376cb731d34122262308eaf3ecc7781862f8eab5.

  Date: 2026-03-18 14:02:30 +0100

  Allow input plan stealing through TableFunctionBindInput (https://redirect.github.com/duckdb/duckdb/pull/21309)
  Fix strip_p/lower call order in generate_grammar.py keyword sorting (https://redirect.github.com/duckdb/duckdb/pull/21423)

  Unflavored-from: d9dcb6cc546e189b2a0135f6a3d78bce1d91fdc3

- Update vendored sources to duckdb/duckdb@f65481bfe96352b4f676bb0e235f2e153d20a25d.

  Date: 2026-03-18 09:43:11 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/7612: ANTI IEJoin Predicates (https://redirect.github.com/duckdb/duckdb/pull/21413)

  Unflavored-from: ac8d153462d545f031225cbe79544e19a0d4c761

- Update vendored sources to duckdb/duckdb@af918e4bd6d4b0cbcd55bdbe0cb07b55c2a0da64.

  Date: 2026-03-18 09:42:36 +0100

  Parquet: make isAdjustedToUTC configurable for timestamps without timezone (https://redirect.github.com/duckdb/duckdb/pull/20976)
  Unflavored-from: 56d0889f1e5b51cdd5e93be82fc562fe045b009d

- Update vendored sources to duckdb/duckdb@ff4f70eeee83cfd3dae6577fc9b2b448d5fbdb35.

  Date: 2026-03-17 20:44:51 +0100

  Extend Join Pushdown with Prefix Range Filter (https://redirect.github.com/duckdb/duckdb/pull/21279)

  Unflavored-from: c168da05326afd119780de816e099c160e1675e8

- Update vendored sources to duckdb/duckdb@764ab0d49a3ebe66d628eb55d1d613259603591b.

  Date: 2026-03-17 16:54:53 +0100

  Add parsing support for `CREATE TRIGGER` statements (https://redirect.github.com/duckdb/duckdb/pull/21265)

  Unflavored-from: 0a5a804a41f430963ff6de945184ef3fbab6ed1f

- Update vendored sources to duckdb/duckdb@e3509341f681c4cb6f2c22d1f0f4b653ed20644d.

  Date: 2026-03-16 08:44:06 +0100

  Bumping C++ Standard to 17 (https://redirect.github.com/duckdb/duckdb/pull/21310)
  automate clangd/compile_commands.json gen via builds (https://redirect.github.com/duckdb/duckdb/pull/21377)
  Fine grained retry for CI commands (https://redirect.github.com/duckdb/duckdb/pull/21368)
  Split regression tests into 4 roughly even jobs (https://redirect.github.com/duckdb/duckdb/pull/21341)

  Unflavored-from: a39a25fc9acb466825b6f06f33e8b79e457a9d82

- Update vendored sources to duckdb/duckdb@e44cd46461d1e52741260236f2b974e34fe2eede.

  Date: 2026-03-13 13:50:53 +0100

  Add approx count and kurtosis aggregate functions with struct-based aggregate state export (https://redirect.github.com/duckdb/duckdb/pull/21076)
  Enable profiling in jemalloc (https://redirect.github.com/duckdb/duckdb/pull/21063)

  Unflavored-from: ddd002f93ed62eb8728f8e15d3694e02ca1a9bad

- Update vendored sources to duckdb/duckdb@3045f344fc8fb8cc7e562c675eafb2686981db13.

  Date: 2026-03-12 21:37:55 +0100

  Reduce number of linux builds (https://redirect.github.com/duckdb/duckdb/pull/21307)
  bwc: ignore indented comments in exclusion list parser (https://redirect.github.com/duckdb/duckdb/pull/21327)

  Unflavored-from: c40ad47bf3125c4fc830dddddab9d81a4d318573

- Update vendored sources to duckdb/duckdb@55b94c48018e1571ae6c513769bf49cd00b63bd4.

  Date: 2026-03-12 10:04:22 +0100

  Merge variegata in main + revert MAIN_BRANCH_VERSIONING (so now it's back to regular) (https://redirect.github.com/duckdb/duckdb/pull/21317)

  Landing v2 (finding 16): the engine reserves the block allocator pool only once a size is set (duckdb/duckdb@55b94c4801), so `patch/0043-Reserve-the-block-allocator-pool-without-accounting-it.patch` goes.

  Unflavored-from: 5e3e5383cef409580656fda01c30409e2eae1eb3

- Update vendored sources to duckdb/duckdb@b32b8c2c325f43c9a0a92fa809cb01fc2a308e85.

  Date: 2026-03-12 09:43:29 +0100

  Turn projection index from an idx_t into a dedicated class (`ProjectionIndex`) (https://redirect.github.com/duckdb/duckdb/pull/21313)

  Unflavored-from: 6ec7c8618b2c383daa7d8f5567f7ab6485822eaa

- Update vendored sources to duckdb/duckdb@f67dbe06340395a401938e22d8042b7d500f29de.

  Date: 2026-03-12 09:22:52 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/7722: SEMI IEJoin Predicates (https://redirect.github.com/duckdb/duckdb/pull/21294)

  Unflavored-from: 57a9442175fd7afb5e545d5e0a30bbda7b9f3dbd

- Update vendored sources to duckdb/duckdb@e198172ae0bb31a4c4523d95492d0e3e417369ca.

  Date: 2026-03-12 08:59:49 +0100

  Unify linux builds part two (https://redirect.github.com/duckdb/duckdb/pull/21240)

  Unflavored-from: 1dbd9844e5b675350fe985bb2f256cd8b5a5466a

- Update vendored sources to duckdb/duckdb@9efda1742f402e4902e8845c2dbb57ba6f85e5b6.

  Date: 2026-03-11 17:57:42 +0100

  Merge v1.5-variegata into main (https://redirect.github.com/duckdb/duckdb/pull/21291)
  \[Julia\] Add ARRAY type reading (https://redirect.github.com/duckdb/duckdb/pull/21226)
  \[Julia\] Add BLOB support (https://redirect.github.com/duckdb/duckdb/pull/21225)
  Remove skip_compiled assertion from unittest binary (https://redirect.github.com/duckdb/duckdb/pull/21264)
  Fix powerpc spin-wait instruction for Apple case (https://redirect.github.com/duckdb/duckdb/pull/21256)

  Unflavored-from: bccc36a28c35335fc600ca16e6924be1382ffa8b

- Update vendored sources to duckdb/duckdb@ef55f2bb415faeed13617c7a98686367b465c940.

  Date: 2026-03-10 13:51:11 +0100

  \[Profiling\] Rename `custom_profiling_settings` to `configure_profiling` (https://redirect.github.com/duckdb/duckdb/pull/21156)

  Unflavored-from: d39a462d7ede6df2502e10123029ed2cee39d610

- Update vendored sources to duckdb/duckdb@6a90e723845cf8983edd0147bdada748a3c6fdb3.

  Date: 2026-03-10 13:50:37 +0100

  Zero trimmed ranges under verifier flags to make Trim() observable (https://redirect.github.com/duckdb/duckdb/pull/21203)
  Fix test flag: --autoloading available, not --autoloading=available (https://redirect.github.com/duckdb/duckdb/pull/21257)

  Unflavored-from: 52fdc8961247adc656f13741d0f59bc23b4a8f12

- Update vendored sources to duckdb/duckdb@55dcffd4b7891d49a419d426faaef302c8a1dad0.

  Date: 2026-03-10 10:58:54 +0100

  Extract struct state roundtrip verification into VerifyStructStateRoundtrip (https://redirect.github.com/duckdb/duckdb/pull/21221)

  Unflavored-from: f7eaa3f0ab49b20ad50f4cbb1818b9a37c1a7093

- Update vendored sources to duckdb/duckdb@53d894793d4c990faef2ac50b52ad2fbfc0f2cf0.

  Date: 2026-03-10 10:20:56 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/7611: IESemiJoin Tail Comparisons (https://redirect.github.com/duckdb/duckdb/pull/21251)

  Unflavored-from: 5cf991bd917d6a271ea8ea2a7949ae34185f1abf

- Update vendored sources to duckdb/duckdb@f36fa3e64722c12e8ed0148066b3660980b4e7b4.

  Date: 2026-03-10 09:39:44 +0100

  add structured Path objects, update joinpath: normalize, support url/net/windows (https://redirect.github.com/duckdb/duckdb/pull/20292)
  Prepare Main workflow for unifying linux builds (https://redirect.github.com/duckdb/duckdb/pull/21217)

  Unflavored-from: 0afd8b67f68c5c853925c67179efc7d5482ab4bd

- Update vendored sources to duckdb/duckdb@3d63e1d1197a6f7413da25d040ab7b5fdebdbdaf.

  Date: 2026-03-09 15:39:37 +0100

  Turn table index from an `idx_t` into a dedicated class (`TableIndex`) (https://redirect.github.com/duckdb/duckdb/pull/21231)
  Notify stale PRs after 30 days, close after 30 (https://redirect.github.com/duckdb/duckdb/pull/21237)

  Unflavored-from: 88bdb9dc2afe558a7e9bbb5f067e60aaf29f04cb

- Update vendored sources to duckdb/duckdb@ca60c6a04a5560d5a47d2db34c83406dfd6709fe.

  Date: 2026-03-09 13:13:16 +0100

  Fix the alias column cannot be found in the try function(FIX ISSUE 21004). (https://redirect.github.com/duckdb/duckdb/pull/21065)
  Improve test runner (https://redirect.github.com/duckdb/duckdb/pull/21211)
  Add expression statement support to the PEG parser (https://redirect.github.com/duckdb/duckdb/pull/21049)

  Unflavored-from: 5dd2415771a37005dac958890fa5b6e5f8470862

- Update vendored sources to duckdb/duckdb@58b80f5120cd9da7fb9cc40b43eddcea8e0992ae.

  Date: 2026-03-09 11:20:11 +0100

  Rewrite List Comprehension Expressions (https://redirect.github.com/duckdb/duckdb/pull/21025)

  Unflavored-from: d5e7e74a97ce6d08340d8469696e35cee04ed190

- Update vendored sources to duckdb/duckdb@6b01ae1ad597c715cf43a4188e502c979e806e91.

  Date: 2026-03-09 11:19:18 +0100

  Relax list_reduce Signature Restrictions (https://redirect.github.com/duckdb/duckdb/pull/21032)

  Unflavored-from: 413c35bd4434e76903e75440ca18b20e20b62739

- Update vendored sources to duckdb/duckdb@3fc818b5a177208f6a51315937a6d6f65f3dac0f.

  Date: 2026-03-09 09:43:41 +0100

  Add SQLNULL support to the parquet writer (https://redirect.github.com/duckdb/duckdb/pull/20961)

  Unflavored-from: d9543c2aa03fded0fe31d6f5d11bb8ce88515ad2

- Update vendored sources to duckdb/duckdb@03ea0f215462def9c8c90a095b43e861537bf07f.

  Date: 2026-03-09 09:14:32 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/7568: AsOf Simple Joins (https://redirect.github.com/duckdb/duckdb/pull/21230)

  Unflavored-from: d26933bebb50cf5c92a60518eec3b22068bb35c5

- Update vendored sources to duckdb/duckdb@64d587331ca224e0d6cb96b4197e8707768946c1.

  Date: 2026-03-09 08:53:04 +0100

  Support `min/max`, `stddev` and `covar` in struct-based aggregate states (https://redirect.github.com/duckdb/duckdb/pull/20973)

  Unflavored-from: b75fd9fefb6f070fa469e447a6244cbacf076b91

- Update vendored sources to duckdb/duckdb@a976318e692d271414a7fc36fd1f63ac64bd8e8b.

  Date: 2026-03-09 08:43:12 +0100

  Clean-up `TableFilterSet` by making all members private and adding functions to access them (https://redirect.github.com/duckdb/duckdb/pull/21229)

  Carried from `origin/v2.0-cyanoptera-dev` at 596f0d1cee:
  the test-side fix folded there for this same upstream commit,
  so the forward starts from what the base series proved.

  Unflavored-from: a05ec4255c5c5f6b036548322386a0e2c6583087

- Update vendored sources to duckdb/duckdb@b88a6f89abeab43691cb6097c7f856ebf33b941f.

  Date: 2026-03-08 19:20:49 +0100

  Enable variant extract pushdown also for functions with table filters - just pull up the table filters out of the scan again (https://redirect.github.com/duckdb/duckdb/pull/21223)

  Unflavored-from: e9c918ef698a4f774ecc5f077cfdf4a0e4504ffd

- Update vendored sources to duckdb/duckdb@1d9a0e0c489b744c80f18b0de989836795d5382b.

  Date: 2026-03-08 13:12:18 +0100

  Outer join simplification (https://redirect.github.com/duckdb/duckdb/pull/21219)
  Internal https://redirect.github.com/duckdb/duckdb/pull/7691: 2026a Time Zones (https://redirect.github.com/duckdb/duckdb/pull/21205)

  Unflavored-from: 997b577535197f239a9c9a92d23c6d6844b865db

- Update vendored sources to duckdb/duckdb@8871676886fe0da7e6c0841d8b368812ed6eae76.

  Date: 2026-03-08 12:30:43 +0100

  Improve variant extract pushdown so that it correctly works for nested structs, and enable variant extract pushdown for `VARIANT` (https://redirect.github.com/duckdb/duckdb/pull/21220)

  Unflavored-from: e2521ebf9c18170a77355c6d488146a2c7eb8d85

- Update vendored sources to duckdb/duckdb@93dcbd2f7dd35ed3765d51eac635fd2b42851882.

  Date: 2026-03-07 17:34:48 +0100

  Use shredded vectors for STRUCT -\> Variant casts, and for `variant_extract` (https://redirect.github.com/duckdb/duckdb/pull/21212)
  Use test runner in more CI jobs of main (https://redirect.github.com/duckdb/duckdb/pull/21181)

  Unflavored-from: c7dac514f55c9f5b06f1768fb0ed1369ce24a39c

- Update vendored sources to duckdb/duckdb@6e211da91657a94803c465fd0ce585f4c6754b54.

  Date: 2026-03-05 09:57:05 +0100

  Use shredded vectors for casts from primitive \<\> variant (https://redirect.github.com/duckdb/duckdb/pull/21182)
  Make linux-debug CI job faster (https://redirect.github.com/duckdb/duckdb/pull/21139)
  Use parallel test runner (https://redirect.github.com/duckdb/duckdb/pull/21152)
  Disable automated converting PR to draft on sync (https://redirect.github.com/duckdb/duckdb/pull/21179)

  Unflavored-from: ebfbce8d287d909cd2bd25773787816dfb7f681b

- Update vendored sources to duckdb/duckdb@5e52773a7fe662413f58ed5f44d1f01af38f1221.

  Date: 2026-03-04 10:47:24 +0100

  Rewrite `AVG(x) -> SUM(x) / COUNT(x)` and generalize `SumRewriterOptimizer` to `AggregateFunctionRewriter` (https://redirect.github.com/duckdb/duckdb/pull/21149)

  Unflavored-from: ac9842e0dd6ca4f9ad3c44c52db41979987cbb74

- Update vendored sources to duckdb/duckdb@f0460fc7634f05de05ffe862d91be715c421f629.

  Date: 2026-03-04 09:40:45 +0100

  Fix parallelization of Bernoulli and system sampling (https://redirect.github.com/duckdb/duckdb/pull/21127)

  Unflavored-from: 4d2c0f1bf369b737459b3b651e2ee0fc28cf31eb

- Update vendored sources to duckdb/duckdb@9056f735f30563281d9e66df47e8e0d32a710d1c.

  Date: 2026-03-04 09:21:43 +0100

  Merge v1.5 into main (https://redirect.github.com/duckdb/duckdb/pull/21155)

  Unflavored-from: 769f940c7d204396a272d2d00ba3480ab9fc3afb

- Update vendored sources to duckdb/duckdb@527b021228a732afd21afa6be9130463d27b3ffa.

  Date: 2026-03-04 09:12:45 +0100

  Add struct-based state export for covar_pop and var_pop (https://redirect.github.com/duckdb/duckdb/pull/21138)

  Unflavored-from: 25c85a4b13468d2038435814233b67786b9d9897

- Update vendored sources to duckdb/duckdb@cefac92a5d3a7bbbe27bee97df68080323be8f1b.

  Date: 2026-03-03 10:57:35 +0100

  Switch connection creation order (https://redirect.github.com/duckdb/duckdb/pull/21136)

  Unflavored-from: a7fe7feaf5f1bd0abc9ee1d53b4e2a436dd7cf6d

- Update vendored sources to duckdb/duckdb@ccd55bcc749d70752c95f5b141f47a21544758e0.

  Date: 2026-03-03 10:48:25 +0100

  Fix type promotion for negation of minimum integer values in prepared… (https://redirect.github.com/duckdb/duckdb/pull/21130)
  Parallellize smoke tests better and add more test runner flags (https://redirect.github.com/duckdb/duckdb/pull/21141)
  Run swift and windows CI after linux-debug (https://redirect.github.com/duckdb/duckdb/pull/21140)

  Unflavored-from: df26654d7771827cdfe490968b0567b6d92c54a8

- Update vendored sources to duckdb/duckdb@4f3b9f29ebc561828b9376eaa0d1cf9c3935a5ab.

  Date: 2026-03-03 08:52:07 +0100

  Explicitly define regr count as uint64_t (https://redirect.github.com/duckdb/duckdb/pull/21128)

  Unflavored-from: 70aa950c86dd3c3d5514959d15200bbef87abdce

- Update vendored sources to duckdb/duckdb@b26b9f6f3c4a7376f13a87dae278a101673ce55a.

  Date: 2026-03-02 13:43:14 +0100

  \[minor\] Address some compile warning (https://redirect.github.com/duckdb/duckdb/pull/21132)
  \[CLI\] Add .about metadata command (https://redirect.github.com/duckdb/duckdb/pull/21122)

  Unflavored-from: 889c9fd13404ab0d93fa729a538c69858c2d1fa4

- Update vendored sources to duckdb/duckdb@4ae08d01058f966630e1ab8cadd28a309b123a03.

  Date: 2026-03-02 12:37:03 +0100

  \[ART\] Index Key Function (https://redirect.github.com/duckdb/duckdb/pull/20220)

  Unflavored-from: d99421187a4e65df9c3f19b8f14468542463ed09

- Update vendored sources to duckdb/duckdb@fc08963d2eabc87c2d8369c3065978fe88e6dd88.

  Date: 2026-03-02 11:27:51 +0100

  \[ART\] Add lines to ART pretty printer (https://redirect.github.com/duckdb/duckdb/pull/20353)

  Unflavored-from: a80d3818929bb6402b35ba6c2dc2c3089cd812c9

- Update vendored sources to duckdb/duckdb@7300522cf07177f30a511bd720dcd8c4e6fdf59e.

  Date: 2026-03-02 10:24:18 +0100

  Integrate csv file handle with cache filesystem (https://redirect.github.com/duckdb/duckdb/pull/21101)
  Run small subset of unit tests for linux-debug as smoke tests (https://redirect.github.com/duckdb/duckdb/pull/21095)
  Try namespace runners for linux-debug (https://redirect.github.com/duckdb/duckdb/pull/21045)

  Unflavored-from: e3c2268a1faccab022816d56fe2048b5ec6f09a9

- Update vendored sources to duckdb/duckdb@83ae79e5b7a60820d3fe163e8c60de300fd0c8d1.

  Date: 2026-02-27 14:55:49 +0100

  Perfect Hash Join Pushdown (https://redirect.github.com/duckdb/duckdb/pull/21105)
  Remove indirect extensions workflow and use its main branch (https://redirect.github.com/duckdb/duckdb/pull/21093)

  Unflavored-from: ec7ae9a3b46ce0386e792211d8806a7c77c54cfb

- Update vendored sources to duckdb/duckdb@8c56048c85fdece49952fb749d1964bee522420a.

  Date: 2026-02-27 10:18:29 +0100

  \[Memory\] duckdb_eviction_queues function + dead node counting fixes (https://redirect.github.com/duckdb/duckdb/pull/20975)

  Unflavored-from: dd99553f16b186a8f88161afe0cafc04b825709f

- Update vendored sources to duckdb/duckdb@fec6d95286a282fbe1d3309aa115d66e10a8666d.

  Date: 2026-02-27 09:08:59 +0100

  Convert regression aggregates to struct-based state export (https://redirect.github.com/duckdb/duckdb/pull/21094)

  Unflavored-from: 8875babd78db8a38674b3389a4b8c74e10e82a3a

- Update vendored sources to duckdb/duckdb@9dc3e3e5dd34453bce22b50a6da4a57fff4d3a33.

  Date: 2026-02-27 09:06:05 +0100

  Parallel DELETE ... RETURNING (sink and source) (https://redirect.github.com/duckdb/duckdb/pull/21075)
  Use CI stages for jobs to reduce CI workload (https://redirect.github.com/duckdb/duckdb/pull/21092)
  Investigate ccache hit rate (https://redirect.github.com/duckdb/duckdb/pull/21085)

  Unflavored-from: df67c66422b5285fe9c908521bc857efa9a9519e

- Update vendored sources to duckdb/duckdb@4fec0a9f60a8504e727708225f6af88e04efce3a.

  Date: 2026-02-26 15:35:55 +0100

  Fix few sast issies (https://redirect.github.com/duckdb/duckdb/pull/20934)

  Unflavored-from: cd88ca9b1c3437a4f4967918a88c7ce6342c4d9d

- Update vendored sources to duckdb/duckdb@83034ccbba3102a18af4973fe9b1eec01d9c76fc.

  Date: 2026-02-26 12:49:41 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/7540: Distribute Window Bounds (https://redirect.github.com/duckdb/duckdb/pull/21033)

  Unflavored-from: 70ed6deb1901bfdbb161b72e0bb6e790129ab0b8

- Update vendored sources to duckdb/duckdb@eb0d4cde364d18d839ed8d6bc13c24ee826f030e.

  Date: 2026-02-26 12:49:01 +0100

  Issue https://redirect.github.com/duckdb/duckdb/pull/20916: APPROX_COUNT_DISTINCT Error Rate (https://redirect.github.com/duckdb/duckdb/pull/20999)

  Unflavored-from: 11503124f16906940bb2ffb9dff7f787abf55bed

- Update vendored sources to duckdb/duckdb@01c8810a173787347a2acbaaf0c0e02d104a79d1.

  Date: 2026-02-26 10:55:21 +0100

  Allow projection removal optimization below `SEMI` Joins (https://redirect.github.com/duckdb/duckdb/pull/21078)
  Optimize GitHub CI cache utilization (https://redirect.github.com/duckdb/duckdb/pull/21066)

  Unflavored-from: b3ad114f868a3f83a925645efed77011596b5bf1

- Update vendored sources to duckdb/duckdb@fbeb7936352b2d32ad8562f19eab8fdfcf430e61.

  Date: 2026-02-25 10:47:16 +0100

  Allow deeper optimization below column order dependent operators (https://redirect.github.com/duckdb/duckdb/pull/21064)

  Unflavored-from: 811c5a491b7036c4875f08c61b8d14934c88850f

- Update vendored sources to duckdb/duckdb@9a2135fff6dcd64550cf870dcc6b4ec31b332c42.

  Date: 2026-02-25 10:31:32 +0100

  Add support for Parquet round-tripping of struct-based aggregate states (https://redirect.github.com/duckdb/duckdb/pull/21048)

  Unflavored-from: a6f7e22f87b908378085b4b00e7d88c487381bd7

- Update vendored sources to duckdb/duckdb@fef308b41541ceec275fa29965c226b978e47763.

  Date: 2026-02-25 10:27:35 +0100

  Initial PR for thread annotation (https://redirect.github.com/duckdb/duckdb/pull/21059)
  Reduce CI workload by re-ordering linux CI jobs (https://redirect.github.com/duckdb/duckdb/pull/21060)

  Unflavored-from: ba9f90c1dc80b315832db0628bb48d21e692bd92

- Update vendored sources to duckdb/duckdb@b90abc129856cc22a747208e058adbf9cebda595.

  Date: 2026-02-25 10:04:37 +0100

  Use binary search replace loop in update_segment.cpp (https://redirect.github.com/duckdb/duckdb/pull/20974)

  Unflavored-from: 7e090f362c75cda8911e47f13238fdec67963908

- Update vendored sources to duckdb/duckdb@76b9e9b885a693f6fc58e729f11daeb43d2ef872.

  Date: 2026-02-25 09:03:49 +0100

  Convert bool_and and bit operations aggregates to struct-based state (https://redirect.github.com/duckdb/duckdb/pull/21043)
  Reduce CI workload caused by Julia workflow runs (https://redirect.github.com/duckdb/duckdb/pull/21054)

  Unflavored-from: db74bba2e6db4ed728a8a35785b56568aa64044d

- Update vendored sources to duckdb/duckdb@2924d790543649f701191c6f0dede42bccf738f1.

  Date: 2026-02-24 14:45:28 +0100

  Fix aggregate hashtable leak (https://redirect.github.com/duckdb/duckdb/pull/21052)

  Unflavored-from: ed6eb2067b4da587072d46b933ac59c5f09eabfc

- Update vendored sources to duckdb/duckdb@491c2a84fd149436b99741aa2cbbb152f865bb65.

  Date: 2026-02-24 08:31:17 +0100

  Fix missing query location in table macro bind errors (https://redirect.github.com/duckdb/duckdb/pull/20910)

  Unflavored-from: 52b316e4e7ec2c1f8017be1d2e06a5c95ee7834f

- Update vendored sources to duckdb/duckdb@88277463aa86b998f241a0cd0f87ea647e749576.

  Date: 2026-02-23 19:31:53 +0100

  Merge V1.5 -\> Main (https://redirect.github.com/duckdb/duckdb/pull/21028)

  Unflavored-from: f7228461ef7756bf37bc8ca497c987f4bf636cb4

- Update vendored sources to duckdb/duckdb@95d25a8f212244841d546a209292909c9c51b717.

  Date: 2026-02-23 15:31:34 +0100

  Add Recursive Struct-Based State Export Support for `corr` Aggregate Function (https://redirect.github.com/duckdb/duckdb/pull/21015)
  Remove hardcoded list of exclude_archs for extensions (https://redirect.github.com/duckdb/duckdb/pull/21027)

  Unflavored-from: 07c3a60532561544c5ceff11dba28cf881c0a370

- Update vendored sources to duckdb/duckdb@cce6a1fe9906f8a03e386a2b659e2180012933a8.

  Date: 2026-02-23 14:05:48 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/6979: Window SelfJoin OrderBy (https://redirect.github.com/duckdb/duckdb/pull/21021)

  Unflavored-from: e072c8de7f0fac203b76dae918bd5214804bdfd1

- Update vendored sources to duckdb/duckdb@cdf6f76ee4a4f867112a9ee98a29edd1d575dbd7.

  Date: 2026-02-23 09:19:14 +0100

  Convert product aggregate to struct-based state (https://redirect.github.com/duckdb/duckdb/pull/21016)

  Unflavored-from: 467e0a95f981fc552fa141ce8a44d33f1f74443f

- Update vendored sources to duckdb/duckdb@3670f06fbdcba7dd567eb6a394c7dba30b348588.

  Date: 2026-02-23 08:50:36 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/7263: IEJoin Memory Footprint (https://redirect.github.com/duckdb/duckdb/pull/21022)

  Unflavored-from: 9291e7fc3bb124017db9ec53e2719395ec331e7b

- Update vendored sources to duckdb/duckdb@f961e485d6ed4e62a0a839e902a8242dbba1dbe9.

  Date: 2026-02-20 09:13:34 +0100

  Throw on export of self-referencing foreign keys (https://redirect.github.com/duckdb/duckdb/pull/20895)

  Unflavored-from: b263984045f210f996022d4bfc4bc027e0f38149

- Update vendored sources to duckdb/duckdb@3b7e40132e82aa9dc3935956cd381cceddb111ab.

  Date: 2026-02-19 17:03:57 +0100

  Fix class/struct warnings. (https://redirect.github.com/duckdb/duckdb/pull/20996)

  Unflavored-from: f1d05a60988ca575a36d0a3cb314116f1a683bbe

- Update vendored sources to duckdb/duckdb@75bfce4b83a42ece221cab47a001569dd129592e.

  Date: 2026-02-19 16:33:32 +0100

  \[minor\] Update autoload exception comment (https://redirect.github.com/duckdb/duckdb/pull/20903)
  clarify running local CI for PRs, and other pain points (https://redirect.github.com/duckdb/duckdb/pull/20929)

  Unflavored-from: 5b2030dbdd1b323dd74ca416002ba6cae28f5e98

- Update vendored sources to duckdb/duckdb@b9514a12f6bacf2e30fb1ceabe5820e1dfeffd2c.

  Date: 2026-02-19 16:14:10 +0100

  Convert first, last, and any_value aggregates to struct-based state (https://redirect.github.com/duckdb/duckdb/pull/20984)

  Unflavored-from: fb31d1aa9e818bde8dc35e041bc28115c4e648b0

- Update vendored sources to duckdb/duckdb@7ca142de462a3d0189cab33fdf3b46879f69db3a.

  Date: 2026-02-19 12:16:37 +0100

  Remove redundant projections (https://redirect.github.com/duckdb/duckdb/pull/20967)

  Unflavored-from: 10ad0d01cd949289503d831016754c8816723889

- Update vendored sources to duckdb/duckdb@d5298fa47c635acb9925840fba31e8cfa53f4c27.

  Date: 2026-02-19 10:08:41 +0100

  CVE-2026-22776 fix patch (https://redirect.github.com/duckdb/duckdb/pull/20992)

  Unflavored-from: b20a2d4481fd1c3fa1e72f21531dcf6ab7bbca97

- Update vendored sources to duckdb/duckdb@9092e4458d8d22fab585a1161c38982a0c83eaec.

  Date: 2026-02-18 13:32:19 +0100

  Feature/etgarsh/aggregate state export/aggregate combine (https://redirect.github.com/duckdb/duckdb/pull/20963)

  Unflavored-from: 22cd332e39b695ff63e809b9a18e88d699d1e9fa

- Update vendored sources to duckdb/duckdb@28e04ed429032465db4d411b33337b8312f18320.

  Date: 2026-02-17 08:22:38 +0100

  Convert count aggregate to struct-based state (https://redirect.github.com/duckdb/duckdb/pull/20971)

  Unflavored-from: d9c70e5f2b72fe3f318bf47782fa5aba08a67826

- Update vendored sources to duckdb/duckdb@a25cf616168140dacaf360cb6981bd8dd0323b3a.

  Date: 2026-02-16 14:03:32 +0100

  Loop tightening in `AggregateStateCombine` for SIMD friendly vectorized execution (https://redirect.github.com/duckdb/duckdb/pull/20904)

  Unflavored-from: e9c5a6b29e3f2af4ed7591e10466d90b75da6c2f

- Update vendored sources to duckdb/duckdb@51f369047ee81e4bfc265942cd929e58f018952f.

  Date: 2026-02-16 10:42:04 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/6540: Join Condition Cardinalities (https://redirect.github.com/duckdb/duckdb/pull/20936)

  Unflavored-from: ce69f290d81385a75e9c4d22c3153e99fd516ece

- Update vendored sources to duckdb/duckdb@45f590f968aad82fe6d3a6165af2edaf8a2d7965.

  Date: 2026-02-16 09:13:30 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/7316: Window Function Catalog (https://redirect.github.com/duckdb/duckdb/pull/20935)

  Unflavored-from: 422325e1b96619fb2b8a4da8c5bb49debada73b6

- Update vendored sources to duckdb/duckdb@3b6058b87c40ae542ee657e480b9745fd11d74d9.

  Date: 2026-02-16 08:37:15 +0100

  Implement conversion between UUID and UHUGEINT (https://redirect.github.com/duckdb/duckdb/pull/20940)

  Unflavored-from: e3cc94d2d1475cc5672c31b90decdce06d9f7657

- Update vendored sources to duckdb/duckdb@5c4f75c96fc76913a77efaf575323f5bcf7ec8a0.

  Date: 2026-02-13 09:16:22 +0100

  Physical Insert - avoid double constraint verification (https://redirect.github.com/duckdb/duckdb/pull/20913)

  Unflavored-from: 939b0e5ec3f8524f6ab680eace4b65e927306140

- Update vendored sources to duckdb/duckdb@64c6ef7c92cc902f89eb699cc2f97acb0d5952b2.

  Date: 2026-02-13 09:12:10 +0100

  Optimize parquet bitpack skip (https://redirect.github.com/duckdb/duckdb/pull/20920)

  Unflavored-from: 72e84e5bda3282b867fc72ebb8a6559116903488

- Update vendored sources to duckdb/duckdb@f975be713af033ce5d6eb1a42e0b8d3ea275e52e.

  Date: 2026-02-13 08:50:10 +0100

  Add support for `VectorType::SHREDDED`, which allows shredded variants to be emitted from storage and executed on (https://redirect.github.com/duckdb/duckdb/pull/20912)

  Unflavored-from: 13a0ed049d8ae437860b8b3693fc7d9c754ec99d

- Update vendored sources to duckdb/duckdb@e2be44ff8f750f8408d07ca773fa9962d4d2660a.

  Date: 2026-02-12 15:14:28 +0100

  Attempt IWYU for `storage` directory (https://redirect.github.com/duckdb/duckdb/pull/20603)

  Unflavored-from: 7207b087bbf6d4a2e52697b8654f63ee98e5fcce

- Update vendored sources to duckdb/duckdb@5e999859ec27cdac8a255fce98beb0d0a5037e1f.

  Date: 2026-02-12 09:56:44 +0100

  Feature: \[Table Filter\] Allow extensions to customize table filtering logic (https://redirect.github.com/duckdb/duckdb/pull/20633)
  Unflavored-from: 724a83ddaa985ec8a4ea4b06fcfe87f4af0a8c33

- Update vendored sources to duckdb/duckdb@6e2bc0115dde934bab734c995fa53a493aab2b32.

  Date: 2026-02-12 09:53:30 +0100

  Rename `GetQueryMaxMemory` to `OperatorMemoryLimit` (https://redirect.github.com/duckdb/duckdb/pull/20902)

  Unflavored-from: 387933f7f5ad4f25b3561d5931435b982cae9178

- Update vendored sources to duckdb/duckdb@830f49f391e089bceaf4bff771b88f879261fc93.

  Date: 2026-02-12 09:53:23 +0100

  Fix internal error: Propagate bound columns from TRY() binder for GROUP BY validation (https://redirect.github.com/duckdb/duckdb/pull/20900)
  Exclude test with `USING KEY` for PEG Parser (https://redirect.github.com/duckdb/duckdb/pull/20915)

  Unflavored-from: 7ab06e201e0fd2db89f1823847b6dd210f8f8376

- Update vendored sources to duckdb/duckdb@344094eb0359a187834a7d402cfd03780e5630ed.

  Date: 2026-02-11 15:20:12 +0100

  Optimize `ExportAggregateFinalize` for SIMD loop transformation (https://redirect.github.com/duckdb/duckdb/pull/20716)

  Unflavored-from: 2249fd885707836bbee657b6c119782c5e1f56fa

- Update vendored sources to duckdb/duckdb@86155c88cb2eddc6568e87e7bba18398d82b6963.

  Date: 2026-02-11 09:43:44 +0100

  WIP: Support struct-based aggregate state in `sum` aggregate function (https://redirect.github.com/duckdb/duckdb/pull/20809)
  Shell: normalize .duckdbrc path separators when printing loading message (https://redirect.github.com/duckdb/duckdb/pull/20763)
  Unflavored-from: 430bbfb645d81d3b139ea5e87c94a65ff8fc1de3

- Update vendored sources to duckdb/duckdb@0193e5ea839c11c81e9aa3fd23a2726c36f2a136.

  Date: 2026-02-11 07:53:02 +0100

  Add missed throw (https://redirect.github.com/duckdb/duckdb/pull/20891)

  Unflavored-from: beb3b8b55e984f72e61bf9d09d6180c885ff184e

- Update vendored sources to duckdb/duckdb@c1bbc6ad386eddd5bc2cff4022dfe94fea9a6730.

  Date: 2026-02-11 07:51:40 +0100

  Merge v1.5-variegata into main (https://redirect.github.com/duckdb/duckdb/pull/20893)
  Fix test issue with `approx_count_distinct` in `USING KEY` (https://redirect.github.com/duckdb/duckdb/pull/20876)

  R-side fix

- Update vendored sources to duckdb/duckdb@06b181a6b6f46053879f3a767b2c2c4d7162f5a3.

  Date: 2026-02-10 22:05:29 +0100

  Fix deserialization for new string serialization method (https://redirect.github.com/duckdb/duckdb/pull/20887)

  Unflavored-from: 9934846813b0ce0a11a07ddf45323087a7baa67e

- Update vendored sources to duckdb/duckdb@4f69cd8780fe5154c90974de38ed9f03303a88a3.

  Date: 2026-02-10 22:03:28 +0100

  scalar: list: remove redundant clear() calls (https://redirect.github.com/duckdb/duckdb/pull/20890)
  Unflavored-from: 0bebe2d1da807bacd93643f02504cefe5824a9ca

- Update vendored sources to duckdb/duckdb@d8447696893510848a131bec263c373678c7b3fa.

  Date: 2026-02-10 09:20:26 +0100

  Respect affinity mask of main process when pinning (https://redirect.github.com/duckdb/duckdb/pull/20826)
  Internal https://redirect.github.com/duckdb/duckdb/pull/7360: ICU ARM Patch (https://redirect.github.com/duckdb/duckdb/pull/20879)

  Unflavored-from: 59a6a87245918c350c8e4b732a4651d2b498f4db

- Update vendored sources to duckdb/duckdb@81b4d9211987ec4950128c7c1a8e9a83ee037218.

  Date: 2026-02-09 15:53:10 +0100

  Add DELETE RETURNING virtual columns support (https://redirect.github.com/duckdb/duckdb/pull/20774)
  Internal https://redirect.github.com/duckdb/duckdb/pull/7360: ICU 74-2 Update (https://redirect.github.com/duckdb/duckdb/pull/20861)

  Unflavored-from: 01fb5c0c871769d529d7b6460c0436bb91a8e7a9

- Update vendored sources to duckdb/duckdb@a3b24bab251b471a733a6249bf3c4203024af3e3.

  Date: 2026-02-09 13:27:12 +0100

  \[ART\] ConstNodeHandles (https://redirect.github.com/duckdb/duckdb/pull/20612)

  Unflavored-from: 48f4497c9a81c1fc19ce5972f0c6b2ddaa7d91d7

- Update vendored sources to duckdb/duckdb@4d2790c561591254c795ca94655306add735d723.

  Date: 2026-02-09 13:25:24 +0100

  Improve tokenizer of new parser and use for highlighting (https://redirect.github.com/duckdb/duckdb/pull/20171)

  Unflavored-from: 7b1ee05747c095cbaefeb37c482541f948c10934

- Update vendored sources to duckdb/duckdb@2d55a05d4d3cfc021ab87e1778bc1cf6ae055243.

  Date: 2026-02-09 09:53:29 +0100

  Structured aggregate states with nested exported `AGGREGATED_STATE` types (https://redirect.github.com/duckdb/duckdb/pull/20572)

  Unflavored-from: 60943130e39cd8017559637c0d639210731af4ef

- Update vendored sources to duckdb/duckdb@d51ff002bf631372f69208717a846698b2a0782a.

  Date: 2026-02-09 09:45:32 +0100

  Honor the desired serialization version set in the config in `DataChunk`'s, `LogicalOperator`'s `Verify` functions (https://redirect.github.com/duckdb/duckdb/pull/20784)
  Add EXPORT_STATE handling in PEG Transformer (https://redirect.github.com/duckdb/duckdb/pull/20681)

  Unflavored-from: 893a1c8acaa13b7a7f561c126d3b5c4c75a65793

- Update vendored sources to duckdb/duckdb@d428120d5cd6e5efbe18f3c308c07c86590b15eb.

  Date: 2026-02-09 09:14:32 +0100

  Turn stats into a variant, and return variant from `stats` and as part of `pragma_storage_info` (https://redirect.github.com/duckdb/duckdb/pull/20858)

  Unflavored-from: ea5dced912faece3752672b9d8b5d7e8f9f45564

- Update vendored sources to duckdb/duckdb@848dc0ebc935ecb46ad8a9c670901beaa4c6d40e.

  Date: 2026-02-09 08:58:37 +0100

  Optimized calculate the number of bytes to skip directly in file decode_utils.hpp (https://redirect.github.com/duckdb/duckdb/pull/20849)

  Unflavored-from: d9f7924d1c9629319b5e1082626c994f7813db5b

- Update vendored sources to duckdb/duckdb@f0823e79fa1abb6130220afe1c000e02c199df66.

  Date: 2026-02-07 12:02:46 +0100

  Support Hexadecimal String Cast to BITSTRING (https://redirect.github.com/duckdb/duckdb/pull/20750)

  Unflavored-from: bd16d98a79602d989825b4d9a67a7f249d9211f7

- Update vendored sources to duckdb/duckdb@e7a878c979eb0abb22025b5088ff2572bebd3a06.

  Date: 2026-02-07 12:00:27 +0100

  Internal https://redirect.github.com/duckdb/duckdb/pull/7335: Join Condition Statistics (https://redirect.github.com/duckdb/duckdb/pull/20832)

  Unflavored-from: 10f7b49e7b3222e27b46a4e154e110ff5c9c8243

- Update vendored sources to duckdb/duckdb@cb9e7c2193963670f358682fb369c17ead60e90c.

  Date: 2026-02-06 14:08:49 +0100

  Optimizing String Serialization (https://redirect.github.com/duckdb/duckdb/pull/20808)

  Unflavored-from: 3ae651a337cc5d3bc7963ae3e26bc1657db4aa97

- Update vendored sources to duckdb/duckdb@6b441dd39844b1b303c403623452e2810ef0e195.

  Date: 2026-02-06 12:28:43 +0100

  Feature: `USING KEY` with aggregation (https://redirect.github.com/duckdb/duckdb/pull/19481)
  Unflavored-from: cb8cc230b2b5c34686968bbbcf94dc0d8fbae782

- Update vendored sources to duckdb/duckdb@146a201c6f171256231b0c701eceb2c0396e1a30.

  Date: 2026-02-06 09:14:36 +0100

  Issue https://redirect.github.com/duckdb/duckdb/pull/20672: Update ICU to 72-1 (https://redirect.github.com/duckdb/duckdb/pull/20764)
  Add a benchmark with deeply nested macros to test for regressions (https://redirect.github.com/duckdb/duckdb/pull/20801)
  Bump Julia to v1.4.4 (https://redirect.github.com/duckdb/duckdb/pull/20796)

  Unflavored-from: bbb01d3e4270e087f315f84f4e1f0fe6554a1126

- Update vendored sources to duckdb/duckdb@65a9de8b235643d31bd44df1d3ca1d94864949b9.

  Date: 2026-02-03 15:59:00 +0100

  PhysicalEmptyResult should support partitioning (https://redirect.github.com/duckdb/duckdb/pull/20742)
  Allow linked_libs to be included statically in bundle target (https://redirect.github.com/duckdb/duckdb/pull/20365)

  Unflavored-from: 35dec9f220283ed49c6160b7f26a4dc9bc098095

- Update vendored sources to duckdb/duckdb@e5fb0a7eab6bc6fd7f26bd5b8cd74c3441f3895b.

  Date: 2026-02-02 10:33:47 +0100

  Add operator_memory_limit setting for per-connection memory budgets (https://redirect.github.com/duckdb/duckdb/pull/20219)

  Unflavored-from: b02654de7b45bf20569eb83c0637a8f9645b4965

- Update vendored sources to duckdb/duckdb@5a115ef952e7b471b523a7cd20fe4512be870933.

  Date: 2026-01-31 16:55:04 +0100

  Merge V1.5 -\> Main (https://redirect.github.com/duckdb/duckdb/pull/20729)

  Unflavored-from: 7f37b493390921abb2d926ef55db172dc439203d

- Update vendored sources to duckdb/duckdb@c87733c87b41704b22f97ea2ba97c0f7d30c0974.

  Date: 2026-01-29 12:01:42 +0100

  Optimize DELETE by scanning indexed columns at bind time (https://redirect.github.com/duckdb/duckdb/pull/20682)

  Unflavored-from: 30e10f734bf1deec8c03d700f587a49bcedd7bc0

- Update vendored sources to duckdb/duckdb@691346559f7b7230394a41b64e5e0400799d3214.

  Date: 2026-01-29 09:32:27 +0100

  Fix correlated scalar subqueries involving CTEs and derived tables (https://redirect.github.com/duckdb/duckdb/pull/20368)

  Unflavored-from: 98dea58abef9e65e36f8da1c06c2414b6b2314a9

- Update vendored sources to duckdb/duckdb@6bd11755cdefa8a8eb38fba1bbaa1f77eb62816d.

  Date: 2026-01-28 09:55:16 +0100

  Fix compiler warnings on `main` (https://redirect.github.com/duckdb/duckdb/pull/20687)

  Unflavored-from: b4cfdd12bd662d21f7a7a8b8feef61b863dd19f9

- Update vendored sources to duckdb/duckdb@42ba8038ab9df47f8839b78ac957b2821c5d8c67.

  Date: 2026-01-27 10:40:44 +0100

  Add support for residual predicates in hash joins (https://redirect.github.com/duckdb/duckdb/pull/20327)
  Skip aggregate state type test in PEG strict mode (CI fix) (https://redirect.github.com/duckdb/duckdb/pull/20673)

  Unflavored-from: 81f0aedd2d1a0412a09a7f6977bdec63fdd4962a

- Update vendored sources to duckdb/duckdb@47c227d7d8662586b0307d123c03b25c0db3d515.

  Date: 2026-01-26 21:09:40 +0100

  Optimize MERGE INTO DELETE RETURNING by passing columns through from scan (https://redirect.github.com/duckdb/duckdb/pull/20636)

  Unflavored-from: 12ef4611e5b8626c5fa7ea57ec71d599e2ed9a64

- Update vendored sources to duckdb/duckdb@d621ef9f7667e766d59cf89fe5df4f5e9f7cca49.

  Date: 2026-01-26 20:59:17 +0100

  Expose LIMIT and OFFSET in EXPLAIN output for LIMIT operators (https://redirect.github.com/duckdb/duckdb/pull/20660)

  Unflavored-from: e795518e2acc2cb0cf6961899ed59dda31bc4465

- Update vendored sources to duckdb/duckdb@6e9da2f81ce85d4a5e2fead9304501b0b745803b.

  Date: 2026-01-26 20:48:15 +0100

  Merge v1.5-variegata into main (https://redirect.github.com/duckdb/duckdb/pull/20663)
  Update copyright year (https://redirect.github.com/duckdb/duckdb/pull/20674)

  Unflavored-from: 9df3a659c88cc11ef4362187533ca782099ed4c1

- Update vendored sources to duckdb/duckdb@fe2bf27ede584f9586dab6d1b0de34ef73a8d8ae.

  Date: 2026-01-26 10:49:45 +0100

  Expose logical state layout for AGGREGATE_STATE (https://redirect.github.com/duckdb/duckdb/pull/20482)

  Unflavored-from: 7095885a44253413feda719681ca6c854d289a3e

- Update vendored sources to duckdb/duckdb@ada11940c2aea3e2d21ef620a0cfa2697914a47b.

  Date: 2026-01-26 09:23:59 +0100

  Add max_execution_time setting for per-connection query time limit (https://redirect.github.com/duckdb/duckdb/pull/20585)

  Unflavored-from: 178746ef920036903f8f203690990eb6998544be

- Update vendored sources to duckdb/duckdb@1c27c54f27bea397d18d86f7c0d6a9f1d4aa85f8.

  Date: 2026-01-24 13:37:45 +0100

  Merge 1.5 -\> Main (https://redirect.github.com/duckdb/duckdb/pull/20644)
  chore(shell): Fix comment inconsistencies and typos (https://redirect.github.com/duckdb/duckdb/pull/20574)
  update azure ref for main (https://redirect.github.com/duckdb/duckdb/pull/20624)

  Restores `tests/testthat/test-variant.R`, which the seed commit dropped.
  The VARIANT layout this engine produces decodes as the test expects again;
  this is the first commit of the walk where the file passes,
  established by running it against every commit before it.

  Unflavored-from: fa42aa904f710c11657f4e55bd6e9ba64b8ee927

- Update vendored sources to duckdb/duckdb@9612b5bea5a6df924daf5ce696d6992df2483bfe.

  Date: 2026-01-20 09:31:04 +0100

  Support generated columns in DELETE RETURNING optimization (https://redirect.github.com/duckdb/duckdb/pull/20578)

  Unflavored-from: 30dac1de53e8132bd4f0366e3b5d981f72596012

- Update vendored sources to duckdb/duckdb@1c62e11b8201923466431e7d109a6ba8b3710c7b.

  Date: 2026-01-15 10:17:36 +0100

  Replace magic number with `DConstants::INVALID_INDEX` in `DBConfig` (https://redirect.github.com/duckdb/duckdb/pull/20510)

  Unflavored-from: 317586f7e154ca8ea855d4565b11782b60eee0c4

- Update vendored sources to duckdb/duckdb@175069fd8cbe850313e0e02bb8e69c763285dbc4.

  Date: 2026-01-14 08:12:19 +0100

  Optimize DELETE RETURNING by passing columns through from scan (https://redirect.github.com/duckdb/duckdb/pull/20485)

  Unflavored-from: c3b811ecb38df4fdda79c461a68cb9af7d6a90f4

- Update vendored sources to duckdb/duckdb@a83f5f359d3c2fc20e86f69d6563144110f21618.

  Date: 2026-01-13 08:20:05 +0100

  Merge v1.5-variegata into main (https://redirect.github.com/duckdb/duckdb/pull/20488)

  Unflavored-from: dab17ead9bf36440fa8a1fab3547a74bbe239cbb

- Update vendored sources to duckdb/duckdb@5438deaaac9860b37985be4943326e390fa5087a.

  Date: 2026-01-12 09:30:52 +0100

  Expose ArenaAllocator from PlanGenerator (https://redirect.github.com/duckdb/duckdb/pull/20447)

  Unflavored-from: 3164011153e8dea8f93228a89a2e8ffa2f1c4b7a

- Update vendored sources to duckdb/duckdb@48bdbbebe4403a086d6fb202a97b6658e136c65c.

  Date: 2026-01-08 08:39:19 +0100

  \[Optimizer\] Support NOT elimination (https://redirect.github.com/duckdb/duckdb/pull/20394)

  Unflavored-from: d0a65a15507f989054a12206c9956b8fede9a86b

- Update vendored sources to duckdb/duckdb@2617272f9f899c173a2fab2548e3258de1067511.

  Date: 2026-01-07 16:01:15 +0100

  Fix file opener propagation (https://redirect.github.com/duckdb/duckdb/pull/20414)

  Unflavored-from: 9b02d223a49f1830bc5c6baa6678183501f5a708

- Update vendored sources to duckdb/duckdb@1f37984c7318b5a9c6cf864bc8ba75c4f4969cd5.

  Date: 2026-01-07 14:52:27 +0100

  feat(adbc): support the experimental `adbc.ingest.target_catalog` option and improve ingest name resolution (https://redirect.github.com/duckdb/duckdb/pull/20369)

  Unflavored-from: 388f108fc81766871aba60f0fbb07e499153c1a6

## Uncategorized

- Vendor: Update vendored sources to duckdb/duckdb@cf40962988623345ce9441197637830f3ca022e4.

- Vendor: Update vendored sources to duckdb/duckdb@75b5fe997addb4eece1519928944d2eef43e6220.

- Vendor: Update vendored sources to duckdb/duckdb@6899f9e656cd3e27112f2900fdedc35f0f2d2a35.

- Vendor: Update vendored sources to duckdb/duckdb@b879d4d7706c0cf280813893eec9de2daa28718c.

- Vendor: Update vendored sources to duckdb/duckdb@f0c4f5089807823118b11f7c44561926c317ddea.

- Vendor: Update vendored sources to duckdb/duckdb@e9cac8082fc9c9d6fcbff08af2239d49f157eaae.

- Vendor: Update vendored sources to duckdb/duckdb@d9805c32f791b09c29b1d3843ef7fb72f077a543.

- Vendor: Update vendored sources to duckdb/duckdb@5e66dad275e117531786fd9dddf4b75f4763873a.

- Vendor: Update vendored sources to duckdb/duckdb@e52b120071dcc6781c816517c09cbd48ad4808bd.

- Vendor: Update vendored sources to duckdb/duckdb@40ff740ca2852a1436d65625a523f2628bc1b535.

- Vendor: Update vendored sources to duckdb/duckdb@35cc2ec3fc1d678d07182e0e106e2ef3d104dbe1.

- Duckdb/duckdb@53b8c9c41ed086951f697955979829b70ccfdeaf.

- Duckdb/duckdb@a746aee54602646edd284de29915f3c48f080fe7.

- Duckdb/duckdb@f4718b921c4981fb8185d9f98c8526ec7ecda235.

- Duckdb/duckdb@743c2acb15a356a16076c8b22212d6aeda65471d.

- Duckdb/duckdb@2dc155af2b6891ee1cda8cebce4730c1c7a024ee.

- Duckdb/duckdb@e5e55724351d5f921bbcc8d86b0fd9b1e44ad691.

- Vendor: Update vendored sources to duckdb/duckdb@a2044776bc62f3a054ed5cfed6b5132f2e51fa4c.


# duckdb 1.5.6.9005

## Breaking changes

- The vendored engine is a development snapshot of DuckDB v2.0, `2.0.0-dev87994` (duckdb/duckdb@0f5ff0a9d6).

- `EXPLAIN` renders its plan in a more compact layout, with operators named like `Dummy Scan` rather than `DUMMY_SCAN`, and `rel_explain()`'s HTML output is an interactive document.

- An error's `LINE` context underlines the whole offending token, not just its first character.

- `dbBind()` on a `dbSendQuery()` result after `dbDisconnect()` fails with "Attempting to execute a prepared statement after its connection was closed!" rather than running the statement again; `dbFetch()` still returns its rows.

- A query that scans an Arrow stream on the stream's own connection fails with the invalidation error rather than waiting for good.

- `SELECT NULL` has the `NULL` type: the Arrow route hands it on as a null array, format `n`, rather than `int32`, and `CREATE TABLE AS` makes a `NULL`-typed column of it.

- The progress display is quiet past an Arrow stream's first batch.

- A `SELECT` that writes, one calling `nextval()` for instance, runs to completion before `dbSendQueryArrow()` returns rather than streaming.

- A relational constant renders with a cast that keeps its type: `expr_constant(-42)` prints as `CAST(-42.0 AS DOUBLE)` rather than `-42.0`, and an empty typed list as `CAST("system".main.list_value() AS INTEGER[])` rather than `[]`.

- `rel_to_csv()` and `rel_to_parquet()` refuse an empty file name with "`file_name` must be a non-empty string." rather than the engine's I/O error.

## Bug fixes

- `dbExistsTable()` leaves an open transaction usable with DuckDB 2.0 (#2892, #2893).

- Run the tests behind `TEST_RE2` everywhere but in R-hub's runs, and fix what they caught in `duckdb_read_csv()` and `dbExistsTable()` (#2896).

## Features

- `TIMESTAMP_TZ_NS` columns read as `POSIXct`, labeled with the session `TimeZone` like `TIMESTAMPTZ`.

- `TUPLE` columns read as data frames whose columns are named `element1`, `element2`, ... rather than left unnamed, and an empty `STRUCT` as a data frame without columns.

### series

- Stamp a green commit with upstream's alpha version, so `INSTALL` finds its extensions (#2897).


# duckdb 1.5.6.9004

## Bug fixes

- A `POSIXct` or `difftime` halfway between two microseconds writes rounded to even, as `dbQuoteLiteral()` quotes it (#2887).

### series

- Keep a zero fifth version component through the `ours-version` merge driver (#2886).

## Features

### series

- Carry `patch/` entries onto the buffer as part of porting (#2660).


# duckdb 1.5.6.9003

## Chore

- Auto-update from GitHub Actions (#2884).


# duckdb 1.5.6.9002

## Bug fixes

### series-advance

- Look a carry's twin up above the forward's green (@krlmlr, #2877).

### series-advance

- Compile the glue after a carry that touches it (@krlmlr, #2880).

## Documentation

### series-loop

- Record how to resolve the cpp11 binding conflict a port brings (#2851).

### series-loop

- Record the cpp11 include path the buffers still generate (#2847).


# duckdb 1.5.6.9001

## Features

### series

- Rebuild the rewind at the foot of a forward, gate the glue, and mirror `-dev` without its flavor (@krlmlr, #2875).

## Continuous integration

- Key the build caches by architecture (@krlmlr, #2876).


# duckdb 1.5.6.9000

## Bug fixes

### series

- Read `main` from the canonical repository, not the fork's mirror (#2865).

## Uncategorized

- Merge remote-tracking branch 'upstream/cran-1.5.6'.


# duckdb 1.5.6

## Features

- Update to DuckDB v1.5.6, see <https://github.com/duckdb/duckdb/releases/tag/v1.5.6> for details.

- New experimental `to_arrow_stream()` streams a dbplyr table on DuckDB into Arrow batch by batch,
  where `arrow::to_arrow()` materializes the whole result first (#2803).

- A `duckdb_error` condition carries the fields DuckDB attaches to an error:
  `error_type`, `raw_message`, `extra_info` and `context`, see `?duckdb_error` (#2714).
  Errors raised by the package itself point at the calling function (#2637).

- A database instance is cached under the path the engine resolves,
  so different spellings of one file and symlinks to it share one instance,
  and a lower-case Windows drive letter resolves on that drive (#2627).

- The dbplyr backend translates `clock::date_build()` and `difftime()` (#2621).

- An Arrow query result exposes its schema, and an empty batch, before the first fetch (#2781).

## Compatibility

- The dbplyr backend needs dbplyr 2.6.0 or later, and warns when an older dbplyr is loaded (#2605).

- The installed package no longer ships the cpp11 headers under `include/` (#2649).

- The package compiles without warnings on the clang 23 and R-devel check flavors (#2617, #2698).

- `duckdb()` and `dbConnect()` fail instead of silently ignoring settings a cached database instance cannot apply:
  a different `read_only`, a differing `config` entry, or `home`, `shared_home`, `allow_extensions` or `environment_scan`.
  `dbConnect(drv, dbdir)` also fails when `drv` already owns a different database file.
  Call `duckdb_shutdown()` first, or pass the settings to the `duckdb()` call that creates the instance (#2641).

## Bug fixes

### Crashes and hangs

- A data frame parameter binds one struct per row instead of crashing R (#2818).

- A list column of data frames or factors no longer crashes or hangs a parallel scan (#2834),
  and lazy (ALTREP) vectors inside struct, matrix and list columns are materialized on R's thread before a scan reads them (#2582).

- Writing a named list with an empty value under `map = "list_of"` no longer crashes (#2866).

- Converting `VARIANT` values to R no longer exposes intermediate objects to the garbage collector (#2750, #2753).

- The progress display keeps its R callback alive and calls it only on R's thread (#2828),
  and prints at most every half second (#2844).

- Opening a database whose previous instance is still held by a connection or an unfinished result
  no longer spins at full CPU, it reports that the database is still in use (#2759).

- A failure inside a lazy data frame's ALTREP method no longer strips `duckdb_error` from later errors
  or leaves a partly converted column behind (#2829),
  and an error raised while such a method runs no longer calls into R (#1796, #1797).

### Types and time zones

- `TIMESTAMPTZ` columns take their `tzone` attribute from the session's `TimeZone` setting, also in lazy relations,
  and stay in UTC when the icu extension is not available (#184, #2401).

- `dbQuoteLiteral()` keeps the sub-second part of a `POSIXct` value (#2646, #2763).

- `integer64` columns and parameters are always written as `BIGINT`, whatever the `bigint` setting (#2819).

- Integer-backed `Date` and `difftime` columns keep their `NA` values,
  and a data frame column with several fields writes as `STRUCT` (#2808).

- A table whose columns R cannot hold is still found and listed,
  and a query returning such a column fails before it runs, naming the column (#2808).

### Connections and storage

- An in-memory database spills to its own directory below `tempdir()` out of the box,
  created only when a query spills and removed when the instance shuts down.
  An on-disk database keeps DuckDB's `<dbdir>.tmp` default, as the DuckDB CLI does (#2562).

- `~/.duckdb` is no longer created for a session that only looks interactive, such as one with `options(rlang_interactive = TRUE)`.
  Without a person to answer the prompt, the per-session directory is used (#2550).

- A database path is normalized only as far as it resolves,
  so a path that cannot be resolved is handed to the engine rather than refused (#455, #2623),
  and a `dbdir` that cannot be created is reported against the user's call (#2822).

- A `dbdir` that an extension handles, such as a URL, is no longer treated as a file (#2641).

- `dbIsValid()` on a driver no longer opens the database (#2754).

### Queries and results

- A `PRAGMA` runs after the statements before it in one query string (@t-kalinowski, #2792).
  Its expansion no longer leaves a transaction open or refuses a `LOAD` halfway, and an empty one can end a query (#2845).

- `dbListFields()` and `dbAppendTable()` read the columns of a table named by `Id()` correctly (#2848).

- `dbClearResult()` frees the unread results of a multi-row bind at once, not at the next garbage collection (#2784, #2825),
  and ends the query of an Arrow stream that was not read to the end (#2793).

### Arrow

- Reading an Arrow stream that another statement invalidated is an error, not the end of the stream (#2775),
  and an Arrow stream keeps its connection's client context alive (#2790).

- `dbFetchArrowChunk()` builds the final empty chunk for `LIST` and `INTERVAL` columns (#2774),
  and each `dbFetchArrowChunk()` and `dbFetchArrow()` call uses its own `chunk_size` (#2791).

- `duckdb_fetch_arrow()` and `duckdb_fetch_record_batch()` refuse a cleared result, as the other result methods do (#2785, #2821).

## Performance

- Release the ALTREP query result after materialization and transformation (@toppyy, #1027).

- The list of valid time zones is read once per session, and again when `TZDIR` changes (#2786, #2810).

## Documentation

- New reference pages `?duckdb_types` and `?duckdb_types_arrow` catalog every DuckDB type in and out of R,
  through R vectors and through Arrow, geometry included (#2836, #2837, #2850, #2861).

- The new reference page `?duckdb_memory` and the help pages for fetching and writing data describe the memory a query takes (#2666).

- `?duckdb` describes what keeps a database instance open and the limitations known today (#2823, #2849).

- The connection's help page describes how a string holding several statements runs (#2835).

- The README states the package's goals and non-goals (#2731).


# duckdb 1.5.5

## Features

- Update to DuckDB v1.5.5, see <https://github.com/duckdb/duckdb/releases/tag/v1.5.5> for details.

- Disable extensions on libc++ Linux builds, with startup message and load error (#1107, #2414).

- Rework how extensions and secrets choose their on-disk location, replacing the
  package-library extension cache attempted across 1.5.4.1 through 1.5.4.3.
  Both now share a single "home" root, resolved fresh for every `duckdb()` driver.
  An interactive prompt in `duckdb()` and messages in non-interactive sessions guide the process.
  See `?duckdb_storage` for details. (#2396, #2398).

## Bug fixes

- Support `OR` and `IN` predicates pushed down to registered Arrow tables (#2410).

- Error instead of crashing when calling `duckdb_fetch_arrow()` on an Arrow result that has been consumed with `duckdb_fetch_record_batch()` (#2406).

- Fix edge case in computation of `r_base::min`/`r_base::max`/`r_base::sum` aggregates (#2404, #2405).

- Honor the `na.rm` argument of `r_base` aggregates in SQL queries (#2407).

## Documentation

- Document database-instance caching and driver reuse (#2399).


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

## Continuous integration

- Create `~/.duckdb` so CI exercises the shared storage path (#2417).

- Install `tzdata-legacy` for legacy time zones like `PST8PDT` (#2409).

## Documentation

- Document all S4 class slots; deprecate the legacy connection slots (#2416).

- Document database-instance caching and driver reuse (#2399).

## Testing

- Cover extensions env-var semantics and lock message wording (#2418).

- Skip DBItest timestamp roundtrip tests when `PST8PDT` is unresolvable (#2408).

## Uncategorized

- Ci: Harden `format-suggest` against `pull_request_target` pwn requests (#93).


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
